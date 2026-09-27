# ServoArm — Architecture

## System overview
A 24 V DC motor, built from MSL electrical components (Resistor + Inductor + RotationalEMF
+ rotor Inertia), drives an aluminium flat-bar arm in the vertical plane through an ideal
gearbox (N:1). The arm hangs straight down at t = 0 (angle 0) and is moved to horizontal
(90°) and held there by a position controller, carrying a tip payload. Gravity acts.

## Coordinate & sign conventions (SI)
- World origin at the pivot (hole centre). Gravity g = 9.81 m/s² along world −y (down).
- Arm at angle 0 points along −y (straight down). Rotation about +z. Positive angle rotates
  −y toward +x; at 90° the arm points along +x (horizontal). `angle` measured in rad.
- Arm bar spans 300 mm total; pivot is 15 mm from one end, so from the pivot the bar runs
  −15 mm (counterweight) to +285 mm (tip). CoM ≈ 135 mm from the pivot along the arm.
- Payload is a point mass at 280 mm from the pivot along the arm (5 mm short of the tip).

## Domains, MSL packages & components (verified this session)
| Subsystem | MSL component (full path) | Interface / note |
|-----------|---------------------------|------------------|
| Inertial frame | `Modelica.Mechanics.MultiBody.World` | inner world; origin = pivot |
| Pivot joint | `Modelica.Mechanics.MultiBody.Joints.Revolute` (`useAxisFlange=true`, `n={0,0,1}`) | exposes `axis` (Rotational.Flange_a) + `support`; **MultiBody↔Rotational bridge** |
| Arm body | `Modelica.Mechanics.MultiBody.Parts.BodyShape` | m, r_CM, inertia from `CAD/mass_properties.json`; frame_a at pivot, r toward tip |
| Payload | `Modelica.Mechanics.MultiBody.Parts.PointMass` (m=payload.m) | placed at 280 mm along arm (via `Parts.FixedTranslation`) |
| Rotor inertia | `Modelica.Mechanics.Rotational.Components.Inertia` (J = motor.Jr) | motor-shaft side of gear |
| Gearbox | `Modelica.Mechanics.Rotational.Components.IdealGear` (ratio = N) | flange_b → `revolute.axis` |
| Back-EMF / torque | `Modelica.Electrical.Analog.Basic.RotationalEMF` (k = motor.k) | electrical pin ↔ rotational flange |
| Winding R, L | `Modelica.Electrical.Analog.Basic.Resistor`, `.Inductor` | series R–L with RotationalEMF |
| Voltage source | `Modelica.Electrical.Analog.Sources.SignalVoltage` | motor terminal voltage = controller output |
| Ground | `Modelica.Electrical.Analog.Basic.Ground` | return path |
| Current sensor | `Modelica.Electrical.Analog.Sensors.CurrentSensor` | exposes `motor.i` (REQ-04) |
| Angle sensor | `Modelica.Mechanics.MultiBody.Sensors.AngleSensor` (or `revolute.phi`) | exposes `arm.angle` (REQ-01/03/05) |
| Position controller | `Modelica.Blocks.Continuous.LimPID` (anti-windup) | error → voltage command |
| Voltage limit | `Modelica.Blocks.Nonlinear.Limiter` (umax=Vsupply) | ±Vsupply saturation |
| Reference | `Modelica.Blocks.Sources.Step`/`Trapezoid` (+ `FirstOrder`/`SlewRateLimiter` for smooth ref) | 90° command at t = 0.1 s |

**Search evidence (custom-part check):** `openmodelica_search_library` returned
`Modelica.Electrical.Analog.Basic.RotationalEMF` ("Electromotoric force (electric/mechanic
transformer)") and `Modelica.Mechanics.Rotational.Components.IdealGear` ("Ideal gear without
inertia"); `Joints.Revolute` has `useAxisFlange` exposing `axis`/`support`. **No custom
component is required** for the plant. Custom work is limited to the `Controls` sub-package
(controller blocks, signal-only), owned by control-expert.

**Example to start from:** electrical drivetrain `Modelica.Electrical.Machines.Examples.DCMachines.DCPM_Start`
(DC machine structure); multibody structure `Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum`
(World + Revolute + Body layout).

## Interface topology (connect() only)
```
SignalVoltage.v ← controller(+limiter)                [Blocks signal]
SignalVoltage.p ─ Resistor ─ Inductor ─ RotationalEMF.p   [Analog electrical]
SignalVoltage.n ─ Ground ─ RotationalEMF.n
RotationalEMF.flange ─ Inertia(rinertia J=Jr) ─ IdealGear.flange_a
IdealGear.flange_b ─ Revolute.axis                     [Rotational → MultiBody]
Revolute.support ─ (fixed) ; World.frame_b ─ Revolute.frame_a
Revolute.frame_b ─ BodyShape(arm).frame_a ; BodyShape.frame_b ─ FixedTranslation(280mm) ─ PointMass
revolute.phi → AngleSensor → controller feedback
CurrentSensor in series with R/L → motor.i
```

## Incremental build sequence (each step simulable on its own)
1. **Plant (open-loop).** MultiBody arm + payload + Revolute(axis flange) + IdealGear + rotor
   Inertia + RotationalEMF + R/L + SignalVoltage + Ground + sensors. Smoke test: 5 V step;
   arm must swing up and settle back toward hanging (plausible gravity pendulum on a DC motor).
2. **Control (closed-loop).** `Controls` sub-package: smooth reference (no raw step), LimPID
   anti-windup, ±Vsupply limiter; top-level `ServoArm.System` model. Separate loop-cut analysis
   model with top-level input/output for `linearize` at 90° → REQ-06 margins.
3. **Verification.** sim-verifier runs all 5 cases, evaluates REQ-01..06, plots + xlsx.
4. **Tuning (only if a REQ fails).** design-tuner changes ONLY gear ratio N ∈ [20,150]; log in
   `Results/tuning_log.md`; re-verify once.
5. **Comparison + final summary.** data-analyst case table; sysarch REQ matrix + component list.

## Assumptions
- **ASM-1 (ASSUMED):** zero friction/damping, ideal gear (100 % eff., no backlash), ideal motor
  (constant R/L/k, no rotor damping). No natural damping → overshoot/settling from control law.
- **ASM-2 (ASSUMED):** arm is a rigid uniform bar; the Ø8 mm pivot hole reduces mass but its
  inertia contribution is negligible. Reference hand calc: m ≈ 0.2416 kg, CoM = 0.135 m from
  pivot, I_pivot,zz ≈ 6.25e-3 kg·m², I_CoM,zz ≈ 1.85e-3 kg·m².
- **ASM-3 (SOURCED, brief):** payload is a rigid point mass at 280 mm from pivot.
- **ASM-4 (SOURCED, brief):** g = 9.81 m/s² along −y; angle 0 = down, +90° = horizontal (+x), +z axis.
- **ASM-5 (ASSUMED):** controller is a design choice (LimPID anti-windup); only actuator limit is
  ±Vsupply. REQ-06 loop cut at motor-voltage input, output = position error, at the 90° operating point.
- **ASM-6 (ASSUMED):** move command is a 90° step at t = 0.1 s; arm at rest at 0° before that.

## Open questions (carried forward)
- OQ-1 friction/damping (assumed 0) — affects REQ-02/03 margin.
- OQ-2 controller structure/gains — design variable (control-expert).
- OQ-3 N range — requirements at tuned point (N=50 nominal) vs across range.
- OQ-4 REQ-06 loop-cut definition (cut at motor voltage).
- OQ-5 REQ-05 sampled at t=3 s (not true dc-gain).
- OQ-6 explicit hole/counterweight in CAD — YES, modelled explicitly (stage 3).
- OQ-7 hot_winding = R only; L and k held constant.

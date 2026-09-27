# MiniRetraction — Architecture

## System overview
A hinged 0.5 m uniform arm (2 kg) hangs vertically from a pivot. A linear actuator,
pinned to ground 0.3 m horizontally from the hinge (at hinge height) and to the arm
0.15 m below the hinge, retracts to swing the arm up 90° to horizontal. Gravity only.

## Coordinate & sign conventions (SI)
- Hinge at origin O = (0,0,0). Gravity g = 9.81 m/s² along −y.
- Planar motion in the x–y plane; hinge/rotation axis is +z.
- Arm angle φ: 0 = hanging straight down; + = rotating toward +x (toward the ground
  anchor); target horizontal = φ = +π/2 (90°). φ is positive about +z.
- Ground anchor A = (0.3, 0, 0) m. Arm attachment B = 0.15 m along the arm from the
  hinge (when hanging, B = (0, −0.15, 0)).
- Actuator length L(φ) = √(0.1125 − 0.09·sin φ) m → L(0°)=0.3354 m, L(90°)=0.1500 m,
  stroke = 0.1854 m (actuator **retracts** as the arm rises).

## Subsystems & interfaces
| Subsystem | MSL component (intended) | Physical interface |
|-----------|--------------------------|--------------------|
| Inertial frame | `Modelica.Mechanics.MultiBody.World` (inner) | `frame_b` (world origin) |
| Hinge (pivot) | `Joints.Revolute` (n={0,0,1}) | `frame_a`←world, `frame_b`→arm |
| Arm | `Parts.Body` / `BodyShape` (m=2 kg, CoM 0.25 m) | `frame_a`←revolute |
| Arm attachment point | `Parts.FixedTranslation` (0.15 m along −y) | frame at B on the arm |
| Ground anchor | `Parts.FixedTranslation` (0.3 m along +x) | frame at A on ground |
| Actuator (pin-pin telescoping) | `Joints.Revolute` (pin A) + `Joints.Prismatic` (axis along actuator) + `Joints.Revolute` (pin B) | A←ground, B←arm |

**Topology (kinematic loop):** a telescoping actuator is a **revolute–prismatic–revolute** chain
(pin at A, prismatic along the actuator line, pin at B) — a bare prismatic cannot rotate. Loop:
- Arm chain: ground → Revolute(hinge O) → arm → point B (0.15 m along arm).
- Actuator chain: ground → FixedTranslation(+0.3 m, A) → Revolute(A) → Prismatic → Revolute(B).
- Loop closes at B. Fixed link O–A (0.3 m), crank O–B (0.15 m).

## Incremental build sequence (each step simulable on its own)
1. **Kinematics only (this step).** Slider-crank loop; arm angle φ prescribed 0→90°,
   actuator length read out. No forces/inertia dynamics. Verifies REQ-KIN-1..5.
2. **Loads.** Add gravity + arm inertia; quasi-static gravity torque
   (τ_g = m·g·0.25·sin φ, max 4.905 N·m) and the required actuator force per angle.
3. **Actuator + dynamics.** Add an ideal linear actuator force source; drive the
   retraction; verify REQ-T-1 (≤3 s) and REQ-F-1 (|F|≤500 N).
4. **Control + edge cases.** Command/control law (rate/force limits) to satisfy
   REQ-OS-1 (≤95°, no overshoot); run edge cases (heavy_arm, reduced_force).

## Assumptions
- **ASM-1 (ASSUMED):** frictionless joints and actuator (brief specifies none).
- **ASM-2 (ASSUMED):** uniform rigid rod, planar motion; I_hinge = m·L²/3 = 0.1667 kg·m².
- **ASM-3 (ASSUMED):** actuator mass/inertia neglected in dynamics steps.
- **ASM-4 (SOURCED, brief):** g = 9.81 m/s² along −y; φ = 0 down, 90° horizontal (+x).
- **ASM-5 (ASSUMED):** actuator technology unspecified — cold_fluid edge case is
  conditional/hydraulic-only (see OQ-1). Revisit in step 3/4.
- **ASM-6 (ASSUMED):** "0.15 m below the hinge" is measured along the arm from the hinge
  (datum confirmed, OQ-5).
- **ASM-7 (ASSUMED):** final-angle tolerance ±1 %; overshoot limit 95° (=1.6580628 rad).

## Open questions (carried into later steps)
- OQ-1 actuator technology (electric/hydraulic/pneumatic) — decides cold_fluid case.
- OQ-2 control law/command profile — decides overshoot behavior (step 4).
- OQ-3/OQ-4/OQ-5 pin offsets, tolerances, datum — assumed above, confirm with authority.
- OQ-6 frictionless → no natural damping; overshoot control is a design choice, not a REQ.

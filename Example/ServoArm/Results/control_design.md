# ServoArm — Control Design (control-expert, revised stage 6)

## 1. Control objectives (REQ-01..06)
| REQ | Objective | Limit |
|-----|-----------|-------|
| REQ-01 | Arm reaches 89° (1.5533430 rad) within 1.0 s of the t=0.1 s command | ≤ 1.0 s |
| REQ-02 | Overshoot ≤ 5 % of the 90° step (peak ≤ 1.6493361 rad) | ≤ 5 % |
| REQ-03 | phi ∈ [1.5533430, 1.5882496] rad for all t ≥ 1.6 s | ±1° hold |
| REQ-04 | \|i\| ≤ 5 A at all times | ≤ 5 A |
| REQ-05 | \|phi(3 s) − 1.5707963\| ≤ 0.0087266 rad | ≤ 0.5° |
| REQ-06 | Loop-cut at 90°: PM ≥ 45°, GM ≥ 6 dB — nominal AND worst | PM≥45°, GM≥6 dB |

## 2. Plant linearization summary
Plant (`ServoArm.Plant`), linearised about the 90° operating point (verified this session):
- **Poles (open loop, from voltage) at 90°**: nominal `{0, 0, -95.25, -1904.75}` rad/s; worst
  `{0, +1.38e-8, -58.14, -2541.86}` rad/s — two integrators (plant position integrator + PI
  integrator), the back-EMF velocity-damping pole, and the electrical (L/R) pole.
- At exactly 90° the gravity stiffness `d(tau_g)/dphi = M_tip·g·cos(90°)=0`, so the plant is a
  true double-integrator (Type-2 loop). DC velocity gain ≈ 0.4 (rad/s)/V (independent of R_a).
- Worst-case R_a 2.0→2.6 Ω moves the damping pole −95.25 → −58.14 rad/s (weaker back-EMF
  damping), adding phase lag near crossover — the root cause of the original PM failure.

## 3. Structure and reasoning
```
Step(90° @ t=0.1s) ─ SlewRateLimiter(vel 2.2 rad/s) ─ SlewRateLimiter(acc 20 rad/s²) → phi_ref
phi_ref ─┐
         ├─ PID (LimPID, kp, Ti, Td, Nd, wd=1, yMax/yMin=±Vsupply) ─ v ─▶ Plant ─▶ phi
phi_meas ┘                                                  (phi, i exposed)
```
- **Reference generator** (`ReferenceGen`): slew-rate (2.2 rad/s) + acceleration (20 rad/s²)
  limits give a smooth trapezoidal-velocity profile; this keeps the transient current ≤ ~0.7 A
  (REQ-04) and is unchanged from stage 5.
- **Position controller** (`PositionController`): `LimPID` with `controllerType=PID`, `wd=1`
  (derivative on the error, not the measurement). Anti-windup via `yMax/yMin=±Vsupply`.
- **Why PID + wd=1 (the retune).** The original PI (kp=60, Ti=0.08) had worst-case PM 39.6°
  (REQ-06 FAIL). For this Type-2 + slew-limited-reference system the phase-margin lever and the
  overshoot lever fight each other:
  - Increasing `Ti` alone raises PM but *weakens* integral tracking → more corner overshoot
    (Ti=0.15 → worst PM 51.7° but overshoot 5.19%, REQ-02 FAIL).
  - Derivative on the **measurement** (`wd=0`) adds phase lead but its velocity feedback slows the
    forward path → *more* corner overshoot (overshoot 5.23%).
  - Derivative on the **error** (`wd=1`) puts the phase lead in the forward path (better
    deceleration-corner tracking → *less* overshoot) while the loop gain L(s) — and hence PM/GM —
    is unchanged (L(s) is independent of wd). No derivative-kick penalty because the reference is
    slew-limited (smooth). Result: worst PM 48.6° **and** worst overshoot 4.48%.
- **Loop-cut** (`LoopCut`): `u` = position error into the PID, `y` = arm angle, arm initialised at
  90°. `wd=1` makes the linearised `y/u = C(s)·P(s)` include the derivative term (with wd=0 and
  u_m≡0 the D term would be linearised out — the same class of "silently ignored" defect fixed for
  Vsupply). `y/u = C(s)·P(s)` is the loop gain L(s).

## 4. Final gains
| Parameter | Value | Unit | Where |
|-----------|-------|------|-------|
| kp | 60 | V/rad | `System` / `PositionController` / `LoopCut` |
| Ti | 0.08 | s | same |
| Td | 0.008 | s | same |
| Nd | 10 | — | same (D filter pole at Nd/Td = 1250 rad/s) |
| controllerType / wd | PID / 1 (D on error) | — | `PositionController`, `LoopCut` |
| velLimit / accLimit | 2.2 / 20 | rad/s, rad/s² | `ReferenceGen` / `System` |
| Vsupply (output limit) | 24 | V | controller, `Evaluate=false` (see §8) |

`kp`, `Ti`, `Td`, `Vsupply` carry `annotation(Evaluate=false)` (top-level `System` and
`PositionController`/`LoopCut`) so they remain runtime-tunable (see §8).

## 5. Stability margins (REQ-06) — loop cut at 90° (PID, wd=1)
Linearised `ServoArm.Controls.LoopCut` (t_lin = 0), then `openmodelica_frequency_analysis`:

| Case | Gain crossover | **Phase margin** | **Gain margin** (upper ω_pc) | Result |
|------|----------------|------------------|------------------------------|--------|
| nominal | 24.46 rad/s | **57.4°** (tool 417.4° wrapped) | **≈43.7 dB** | **PASS** |
| worst (0.30 kg, 2.6 Ω, 20 V) | 23.58 rad/s | **48.6°** (tool 408.6° wrapped) | **≈49.2 dB** | **PASS** |

- Tool PM is +360° wrapped because the Type-2 loop starts at −180°; unwrapped values are shown.
- Tool GM (−188.8 / −182.7 dB) is the degenerate ω→0 phase crossing (Type-2 artifact). The
  physical GM is at the upper phase crossover (ω_pc ≈ 1525 rad/s nominal, ≈ 1722 rad/s worst),
  computed from L(s) = k(1+Nd)·K_plant·(s+z1)(s+z2)/[s²(s+1250)(s+ω_d)(s+ω_e)] with z1≈−14.1,
  z2≈−100.7. Same cross-checked method as the stage-5 §5 (reproduces the old PI GM 37.1/38.5 dB).

## 6. Nonlinear verification (nominal and worst, stop_time=4 s)
`ServoArm.System` (final files, overrides applied for worst):

| REQ | nominal | worst (0.30 kg, 2.6 Ω, 20 V) | Limit | Result |
|-----|---------|-------------------------------|-------|--------|
| REQ-01 | 89° at 0.7072 s | 0.7073 s | ≤ 1.0 s | **PASS / PASS** |
| REQ-02 | 4.08 % (peak 93.67°) | 4.48 % (peak 94.03°) | ≤ 5 % | **PASS / PASS** |
| REQ-03 | phi ∈ [1.570761, 1.570801] | phi ∈ [1.570789, 1.570810] | [1.553343, 1.588250] | **PASS / PASS** |
| REQ-04 | \|i\| ≤ 0.604 A | \|i\| ≤ 0.662 A | ≤ 5 A | **PASS / PASS** |
| REQ-05 | err ≈ 1.0e-9 rad | err ≈ 2.8e-9 rad | ≤ 0.00873 rad | **PASS / PASS** |

Peak controller output ≈ 7.48 V (worst) — never approaches the 20 V supply limit, so saturation
is not engaged (as expected; the Vsupply fix is a correctness fix, not a results fix).

## 7. Files
- `Example/ServoArm/OpenModelica/ServoArm/Controls/package.mo` — `ServoArm.Controls`
  (`ReferenceGen`, `PositionController` (PID, wd=1), `LoopCut` (PID, wd=1)).
- `Example/ServoArm/OpenModelica/ServoArm/System.mo` — `ServoArm.System` (closed loop; top-level
  params `payload_m`, `Vsupply`, `R_a`, `N`, `L_a`, `k_t`, `J_r`, `kp`, `Ti`, `Td`, `Nd`).
- `Example/ServoArm/Results/control_design.md` — this file.

## 8. Runtime-tunability fix (finding F-1)
`Vsupply` (and the gain/time-constant params) fed `LimPID.yMax/yMin` and were inlined by
OpenModelica, so the `Vsupply=20` override was silently ignored. Added `annotation(Evaluate=false)`
to `Vsupply`, `kp`, `Ti`, `Td` in `System.mo` and `Controls/package.mo` (both `PositionController`
and `LoopCut`). Verified: `openmodelica_simulate` with `Vsupply=20` now shows
`Vsupply = 20`, `controller.Vsupply = 20`, `controller.pid.yMax = 20`, `pid.yMin = −20` in the
result file (nominal stays 24).

## 9. Known limitations
- At exactly 90° the gravity stiffness is zero (degenerate double-integrator); the gain margin is
  reported at the upper phase crossover (§5).
- Tuning is for the nominal point (N=50, payload 0.20 kg); the four edge cases are stage 6.
- Observed (out of scope, flagged to modelica-modeler): the modelled arm-side inertia
  (I_arm_tot ≈ 0.0344 kg·m² at payload 0.20 kg) is ~3× the CAD value (I_pivot ≈ 6.27e-3 kg·m²),
  i.e. the plant BodyShape inertia differs from `CAD/mass_properties.json`. Plant left untouched
  per scope; no requirement outcome depends on this, but it is worth reconciling.

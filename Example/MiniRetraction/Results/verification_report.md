# Verification report — MiniRetraction — `MiniRetraction.Kinematics`

**Timestamp:** 2026-09-27 (session-local; git not used)
**Verifier:** sim-verifier (independent; model not modified)
**Model under test:** `Example/MiniRetraction/OpenModelica/MiniRetraction/package.mo`, class `MiniRetraction.Kinematics`
**Model kind:** planar slider-crank loop, kinematics only (gravity disabled, no forces/masses)
**Requirements source:** `Example/MiniRetraction/Requirements/requirements.yaml`
**Design point:** model defaults (no `Results/parameters.json` exists in this project at run time)
`d_OA=0.3 m`, `r_OB=0.15 m`, `armLen=0.5 m`, `phi_start=0`, `phi_end=π/2`, `swing_time=3 s`

## Tool / settings
| Item | Value |
|---|---|
| `openmodelica_check` | ok — 1285 equations / 1285 variables, 0 errors, 0 warnings |
| `openmodelica_simulate` | ok — initialization + simulation finished successfully |
| tag | `nominal` |
| stop time | 6 s |
| output intervals | 3000 (dt = 0.002 s ≤ 0.005 s, resolves the 3 s swing) |
| overrides | none |
| result file | `.om_build/MiniRetraction_Kinematics/nominal/MiniRetraction.Kinematics_res.mat` |

**Exposed-variable note:** the model exposes underscore names `arm_phi`, `actuator_L`,
`actuator_stroke`, `actuator_L_residual`. The requirements' `criterion.var` fields use
dotted names (`arm.phi`, `actuator.L`, `actuator.stroke`, `actuator.L_residual`); these
were mapped to the exposed variables for measurement. Documentation-only discrepancy, not
a functional failure.

## Requirement results

| REQ | Requirement | Case | Criterion | Measured | Limit | Margin | Result | Evidence |
|-----|-------------|------|-----------|----------|-------|--------|--------|----------|
| REQ-KIN-1 | arm rotates 0°→90°, final φ=π/2 | nominal | final `arm_phi` = 1.5707963, rtol 1 % | 1.5707963267948966 rad | 1.5707963 ± 0.015707963 | 0.999998 | **PASS** | `openmodelica_verify` final on `arm_phi` |
| REQ-KIN-2 | L at φ=0° = 0.3354 m ± 0.001 | nominal | value_at `actuator_L` (t=0) = 0.33541, atol 1e-3 | 0.3354101966249684 m | 0.33541 ± 0.001 | 0.999803 | **PASS** | `openmodelica_verify` value_at t=0 |
| REQ-KIN-3 | L at φ=90° = 0.1500 m ± 0.001 (rtol 6.667e-3) | nominal | final `actuator_L` = 0.15, rtol 6.667e-3 | 0.15 m | 0.15 ± 0.00100005 | 1.000000 | **PASS** | `openmodelica_verify` final on `actuator_L` |
| REQ-KIN-4 | stroke = 0.1854 m (bounds 0.18441–0.18641) | nominal | bounds `actuator_stroke` ∈ [0.18441, 0.18641] | 0.1854101966249685 m | [0.18441, 0.18641] | 0.999803 | **PASS** | `openmodelica_verify` bounds on `actuator_stroke` |
| REQ-KIN-5 | L = √(0.1125 − 0.09·sin φ) ± 0.001 throughout | nominal | bounds `actuator_L_residual` ∈ [−0.001, 0.001] | max abs = 8.327e-16 m | ±0.001 m | ≈1.0 | **PASS** | `openmodelica_verify` bounds on `actuator_L_residual` |

Margin = (limit − |measured − target|) / limit. `openmodelica_verify` returned
`all_pass = true` for all five checks in a single batch.

## Measured trajectories (from `openmodelica_read_results`)
| t (s) | `arm_phi` (rad) | `actuator_L` (m) |
|---|---|---|
| 0.0 | 0.0 | 0.3354101966249684 |
| 0.5 | 0.25952988779914954 | 0.29900441625448354 |
| 1.0 | 0.5213292755982988 | 0.2601480458433846 |
| 2.0 | 1.0449280511965977 | 0.18617207577290723 |
| 2.5 | 1.306727438995747 | 0.1600617523122525 |
| 3.0 | 1.5685268267948966 | 0.15000077259221622 |
| 3.5 | 1.5707963267948968 | 0.15 |
| 6.0 (final) | 1.5707963267948966 | 0.15 |

`actuator_stroke` = 0.1854101966249685 m (constant).
`actuator_L_residual`: min −2.498e-16, max +8.327e-16, final +2.776e-17 m.

`openmodelica_time_to_reach(arm_phi → 1.5707963, rising)` = **3.0108 s** (informational only;
REQ-T-1 is out of scope for this step).

## Physical sanity checks
- **Sign/direction:** `arm_phi` rises monotonically 0 → π/2 and `actuator_L` falls
  monotonically 0.33541 → 0.15 m. Retraction (length decreasing) swings the arm up, as
  intended. **OK.**
- **Endpoint geometry vs closed form:** L(0) = √0.1125 = 0.33541020 m and
  L(π/2) = √0.0225 = 0.15 m, matching DER-1/DER-2 exactly. **OK.**
- **Residual:** `actuator_L_residual` stays at ~1e-16 m (machine precision), confirming the
  model's pinned-pinned geometry equals the closed-form relation at every angle, not only
  the endpoints. **OK.**
- **Conservation / solver:** no NaN or infinity in any monitored variable; the solver
  completed the full 6 s without stalling; the drive holds φ = π/2 after 3 s. A tiny
  numerical overshoot of 1.3e-5 rad (max `arm_phi` = 1.5708096 at t=3.014 s) is present —
  negligible and far inside the 95° envelope, but noted. **OK.**
- **Case sensitivity / edge cases:** the requirements define `heavy_arm`, `reduced_force`,
  `cold_fluid` for the *later dynamics* stage only (REQ-T-1/REQ-F-1/REQ-OS-1). They do not
  exercise the kinematics model (no mass/force/fluid states exist here), so only `nominal`
  is meaningful for the KIN requirements.

## Out of scope (NOT evaluated, NOT failed)
- **REQ-T-1** (retraction time ≤ 3 s) — `later_dynamics`.
- **REQ-F-1** (actuator force ≤ 500 N) — `later_dynamics`.
- **REQ-OS-1** (no overshoot beyond 95°) — `later_dynamics`.

These depend on actuator force/power and a control law that do not exist in the
kinematics-only model. They are deliberately left un-evaluated here.

## Verdict

**VERIFIED** for the in-scope kinematics requirements.

- All five must-REQs **REQ-KIN-1 … REQ-KIN-5** PASS for the `nominal` case, with margins
  ≥ 0.9998 on every check.
- `openmodelica_check` returned ok (no errors/warnings) and the simulation completed
  successfully; every measured number above comes from a tool call in this session.
- REQ-T-1, REQ-F-1, REQ-OS-1 are out of scope for this step and are neither PASS nor FAIL.
- Caveat (documentation, not a requirement failure): requirements use dotted variable names
  while the model exposes underscore names; a mapping must be applied when consuming them.

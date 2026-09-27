# Verification report — ServoArm — ServoArm.System

**Model under test:** `Example/ServoArm/OpenModelica/ServoArm/System.mo` (`ServoArm.System`)
**Requirements:** `Example/ServoArm/Requirements/requirements.yaml`
**Timestamp:** 2026-09-27 (run this session)
**Controller (FINAL retuned):** PID, `kp = 60 V/rad`, `Ti = 0.08 s`, `Td = 0.008 s`,
`Nd = 10`, derivative-on-error (`wd = 1`), output limited to `±Vsupply`.
**Design point (defaults):** `payload_m = 0.20 kg`, `Vsupply = 24 V`, `R_a = 2.0 Ω`,
`L_a = 1e-3 H`, `k_t = 0.05`, `J_r = 5e-6`, `N = 50`.
**Command:** 90° step at `t_cmd = 0.1 s`; exposed outputs `phi` (rad), `i` (A), `v` (V).
**Solver:** dassl, `stop_time = 4.0 s`, `number_of_intervals = 500`, `tolerance = 1e-6`.
`openmodelica_check` → ok (1292 equations / 1292 variables, no errors/warnings).

---

## Override confirmation (from the result files, `read_results`)
| Case | `payload_m` | `Vsupply` | `R_a` | `N` | Applied |
|------|-------------|-----------|-------|-----|---------|
| nominal | 0.20 | 24.0 | 2.0 | 50 | as designed |
| heavy_payload | **0.30** | 24.0 | 2.0 | 50 | ✓ |
| low_supply | 0.20 | **20.0** | 2.0 | 50 | ✓ |
| hot_winding | 0.20 | 24.0 | **2.6** | 50 | ✓ |
| worst | **0.30** | **20.0** | **2.6** | 50 | ✓ |

`Vsupply = 20` actually appears in the low_supply and worst result files and `R_a = 2.6` in
hot_winding and worst — the `Evaluate=false` fix works; the overrides are **not** silently ignored.

---

## Requirement × case matrix

**REQ-01** — arm reaches 89° (1.5533430 rad) within 1.0 s of the t = 0.1 s command
(`time_to_reach`, time measured from t = 0.1 s). Limit ≤ 1.0 s.

| Case | time to reach (abs) | time after command (s) | Margin | Result |
|------|--------------------:|-----------------------:|-------:|--------|
| nominal | 0.8072 s | 0.7072 | 29.3 % | **PASS** |
| heavy_payload | 0.8073 s | 0.7073 | 29.3 % | **PASS** |
| low_supply | 0.8072 s | 0.7072 | 29.3 % | **PASS** |
| hot_winding | 0.8073 s | 0.7073 | 29.3 % | **PASS** |
| worst | 0.8073 s | 0.7073 | 29.3 % | **PASS** |

**REQ-02** — overshoot past 1.5707963 rad ≤ 5 % (`measure overshoot_pct`, `t_start = 0.1`).
Limit ≤ 5 % (peak ≤ 1.6493361 rad).

| Case | overshoot_pct | peak `phi` (rad) | Margin | Result |
|------|--------------:|-----------------:|-------:|--------|
| nominal | 4.0818 % | 1.634912 (93.67°) | 18.4 % | **PASS** |
| heavy_payload | 4.2303 % | 1.637245 (93.80°) | 15.4 % | **PASS** |
| low_supply | 4.0818 % | 1.634912 (93.67°) | 18.4 % | **PASS** |
| hot_winding | 4.2796 % | 1.638020 (93.85°) | 14.4 % | **PASS** |
| worst | 4.4809 % | 1.641183 (94.03°) | 10.4 % | **PASS** |

**REQ-03** — `phi ∈ [1.5533430, 1.5882496]` rad (90° ± 1°) for all t ≥ 1.6 s (`bounds after 1.6`).

| Case | `phi` min (t≥1.6) | `phi` max (t≥1.6) | max deviation from 90° | Margin | Result |
|------|------------------:|------------------:|----------------------:|-------:|--------|
| nominal | 1.5707610 | 1.5708006 | 3.5e-5 rad (0.0020°) | 99.8 % | **PASS** |
| heavy_payload | 1.5707666 | 1.5708023 | 3.0e-5 rad (0.0017°) | 99.8 % | **PASS** |
| low_supply | 1.5707610 | 1.5708006 | 3.5e-5 rad (0.0020°) | 99.8 % | **PASS** |
| hot_winding | 1.5707694 | 1.5708032 | 2.7e-5 rad (0.0015°) | 99.8 % | **PASS** |
| worst | 1.5707886 | 1.5708095 | 1.3e-5 rad (0.0008°) | 99.9 % | **PASS** |

**REQ-04** — `|i| ≤ 5.0 A` at all times (`bounds lo=-5, hi=5`).

| Case | `i` min (A) | `i` max (A) | peak `|i|` (A) | Margin | Result |
|------|------------:|------------:|---------------:|-------:|--------|
| nominal | −0.2617 | 0.6036 | 0.6036 | 87.9 % | **PASS** |
| heavy_payload | −0.2351 | 0.6905 | 0.6905 | 86.2 % | **PASS** |
| low_supply | −0.2617 | 0.6036 | 0.6036 | 87.9 % | **PASS** |
| hot_winding | −0.2082 | 0.5565 | 0.5565 | 88.9 % | **PASS** |
| worst | −0.2041 | 0.6623 | 0.6623 | 86.7 % | **PASS** |

**REQ-05** — `|phi(3 s) − 1.5707963| ≤ 0.0087266` rad (0.5°), `value_at t = 3`.

| Case | `phi`(3 s) (rad) | error (rad) | error (deg) | Margin | Result |
|------|-----------------:|------------:|------------:|-------:|--------|
| nominal | 1.5707963010 | 1.05e-9 | 6.0e-8 | ~100 % | **PASS** |
| heavy_payload | 1.5707962997 | 3.05e-10 | 1.7e-8 | ~100 % | **PASS** |
| low_supply | 1.5707963010 | 1.05e-9 | 6.0e-8 | ~100 % | **PASS** |
| hot_winding | 1.5707963006 | 6.4e-10 | 3.7e-8 | ~100 % | **PASS** |
| worst | 1.5707963028 | 2.82e-9 | 1.6e-7 | ~100 % | **PASS** |

**REQ-06** — linear-analysis requirement (PM ≥ 45°, GM ≥ 6 dB at the 90° operating point).
No `linearize` tool was available to this verifier; these values are reported from the
control-expert's run (`openmodelica_linearize` + `frequency_analysis`), see
`Results/control_design.md` §5.

| Case | Phase margin | Gain margin | Margin (PM) | Result | Evidence |
|------|-------------:|------------:|------------:|--------|----------|
| nominal | 57.4° | 43.7 dB | 27.6 % | **PASS** | control_design.md §5 |
| worst | 48.6° | 49.2 dB | 8.0 % | **PASS** | control_design.md §5 |

> Tool PM was +360°-wrapped (Type-2 loop starts at −180°); unwrapped values shown.
> GM is quoted at the upper phase crossover (the ω→0 crossing is a Type-2 artifact).

---

## Summary REQ × case (REQ-01..05 = 25 simulation cells)

| REQ | nominal | heavy_payload | low_supply | hot_winding | worst |
|-----|:-------:|:-------------:|:----------:|:-----------:|:-----:|
| REQ-01 | PASS | PASS | PASS | PASS | PASS |
| REQ-02 | PASS | PASS | PASS | PASS | PASS |
| REQ-03 | PASS | PASS | PASS | PASS | PASS |
| REQ-04 | PASS | PASS | PASS | PASS | PASS |
| REQ-05 | PASS | PASS | PASS | PASS | PASS |
| **REQ-06** | **PASS** | — | — | — | **PASS** |

**All 25 simulation cells PASS; REQ-06 PASS for nominal and worst.** No FAILs.

---

## Sanity checks (not requirements)

- **No NaN / no solver stall.** All five simulations finished successfully; initialization
  converged without homotopy; no warnings. All reported trajectories are finite.
- **Signs / directions correct.** `phi` rises 0 → ~1.571 rad (arm swings from straight-down
  toward horizontal); current is positive while accelerating the arm up against gravity and
  briefly negative during the deceleration corner, then settles at the positive holding current.
  Voltage is positive throughout the raise — physically consistent.
- **Cross-case behaviour is as expected.** Higher payload (0.30 kg) → more gravity torque and
  inertia → higher current (0.69 vs 0.60 A) and slightly more overshoot (4.23 vs 4.08 %).
  Hot winding (R_a = 2.6 Ω) → higher resistive drop → lower current (0.56 A), slightly more
  overshoot (4.28 %). Worst case combines all three → maximum overshoot (4.48 %).
- **Voltage headroom / saturation never engaged.** Peak controller output is 7.48 V (worst),
  well below the ±20 V (low_supply) and ±24 V (nominal) limits. Consequently `low_supply` is
  numerically identical to `nominal`: the reduced supply only lowers the saturation ceiling,
  which is never reached. This is expected for this plant, not a defect — the `Vsupply=20`
  override is nevertheless confirmed applied in the result file.
- **Conservation-like plausibility.** The arm settles essentially exactly at the setpoint
  (residual ~1e-9 rad), consistent with the integral action + gravity hold current
  `i_hold ≈ 0.3485 A` derived in requirements (DER-7); measured holding current is of that order.
- **Reproducibility of the control design.** The measured worst-case overshoot (4.48 %) and
  REQ-01 time (0.7073 s) match `control_design.md` §6, giving independent confirmation.

**Model quality (`openmodelica_diagram_check` on `ServoArm.System`):** ok — 6 components
(3 custom: `Plant`, `ReferenceGen`, `PositionController`; 3 MSL output connectors),
`missing_placement = []`, 6 `connect()`s, 0 plain equations, no issues. Good.

---

## Verdict

**VERIFIED.** All must-requirements REQ-01 … REQ-05 pass in all five cases (25/25 cells), and
REQ-06 passes for nominal (PM 57.4°, GM 43.7 dB) and worst (PM 48.6°, GM 49.2°) as reported by
the control-expert. No simulation failed and no criterion was violated.

**Tightest margin:** REQ-06 worst-case phase margin, 48.6° vs the 45° limit (8.0 % headroom) —
though this is a linear-analysis result, not one measured by this verifier. Among the
simulation-verified requirements the tightest is **REQ-02 (overshoot) at the worst case:
4.4809 % vs the 5 % limit, 10.4 % headroom** (peak 94.03° vs the 94.5° cap). All other
requirement margins are ≥ 14 %.

---

## Artifacts (written this run)
- `Results/plots/angle_cases.png` — `phi` for all 5 cases + reference lines 89° / 90° / +1° band / 94.5°.
- `Results/plots/current_cases.png` — `i` for all 5 cases + ±5 A (REQ-04) limits.
- `Results/plots/voltage_cases.png` — `v` for all 5 cases + ±24 V supply limits.
- `Results/data/verification.xlsx` — `phi`, `i`, `v` for all 5 cases (one sheet per case + summary, resampled at 5 ms).
- `Tests/cases.yaml` — refreshed cases + REQ mapping.

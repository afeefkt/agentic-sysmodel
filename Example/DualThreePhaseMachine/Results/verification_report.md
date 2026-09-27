# Verification report — DualThreePhaseMachine, Step 1 (core machine)

- **Model:** `Example/DualThreePhaseMachine/OpenModelica/DualThreePhaseMachine/package.mo`
  — top class `DualThreePhaseMachine.DualThreePhaseIPMSM` (Step 1: dq + xy + 0⁺/0⁻ + torque + mechanics only).
- **Verified by:** sim-verifier (independent of the model author). Model `.mo` files and
  `Requirements/requirements.yaml` were **not** modified.
- **Timestamp:** 2026-09-27.
- **Scope:** `REQ-01` … `REQ-15` and `REQ-26` (Step 1). `REQ-16`…`REQ-25` are Step-2/3 and were **skipped**.
- **Tooling:** repo OpenModelica MCP tools (`openmodelica_check`, `openmodelica_simulate`,
  `openmodelica_verify`, `openmodelica_read_results`); no shell tool was exposed in this
  environment, so these were used as the `omc`-equivalent. All numbers below are from
  `val`/verify output of result files produced **in this run**.
- **Design point (Step-1 defaults; no `Results/parameters.json` exists):**
  `Rs=0.8 Ω, Ld=5.5e-3 H, Lq=16.5e-3 H, Ll=0.9e-3 H, ψ_pm=0.1746 Wb, n_p=3,
  J=0.01 kg·m², b=1e-3 N·m·s/rad, i_s,rated=4.1 A, m_rated=10.6 N·m, P_rated=4400 W,
  neutral_config=2N`.

## Interface mapping (necessary for verification)
`requirements.yaml` names variables with `machine.*`, `mech.*`, `inv.*`, `vsd.*`, but
Step 1 exposes **flat** names on a **voltage-fed** machine. Mapped:
`machine.Rs…Ll` → `Rs…Ll`; `machine.psi_pm/np/i_s_rated/m_rated/P_rated` → flat;
`machine.i_d/i_q` → `i_d_start/i_q_start` (+ voltage drive); `machine.omega_mech` →
`omega_mech_start`; `mech.m_load` → `m_load`. `neutral_config` is a **string enumeration**
and several cases need **prescribed currents**, neither expressible through numeric
overrides; those cases use the additive, non-invasive harness package
`DualThreePhaseMachine.Harnesses` (`Harnesses.mo`, registered in `package.order`;
`DualThreePhaseIPMSM.mo` unchanged).

## Requirement status (Step 1)

| REQ | Case | Criterion | Measured | Result | Evidence |
|-----|------|-----------|----------|--------|----------|
| REQ-01 | nominal | Rs=0.8 (rtol 1e-6) | 0.8 | **PASS** | final `Rs`=0.8 |
| REQ-01 | nominal | Ld=5.5e-3, Lq=16.5e-3, Ll=0.9e-3 (rtol 1e-6) | 5.5e-3 / 16.5e-3 / 9e-4 | **PASS** | final `Ld`,`Lq`,`Ll` |
| REQ-01 | hot_winding | override takes effect | Rs=1.114 | **PASS** | final `Rs`=1.114 |
| REQ-02 | smoke | ψ_pm=0.1746 (rtol 1e-6) | 0.1746 | **PASS** | final `psi_pm` |
| REQ-02 | smoke | n_p=3 (exact) | 3 | **PASS** | final `np` |
| REQ-03 | smoke | i_s,rated=4.1, m_rated=10.6, P_rated=4400 (rtol 1e-6) | 4.1 / 10.6 / 4400 | **PASS** | final `i_s_rated`,`m_rated`,`P_rated` |
| REQ-04 | nominal,rated,hot,over_load | res_psi_d, res_psi_q ∈ ±1e-6 Wb | 0.0 / 0.0 | **PASS** | bounds on `res_psi_d`,`res_psi_q` all cases |
| REQ-05 | nominal | res_dq_d ∈ ±5e-3 V | max 0.0 | **PASS** | bounds `res_dq_d` |
| REQ-05 | nominal | res_dq_q ∈ ±5e-3 V | max 1.78e-15 V | **PASS** | bounds `res_dq_q` |
| REQ-05 | nominal | u_d=−15.676 V, u_q=28.899 V at steady state | −15.676 / 28.899 | **PASS** | final `u_d`,`u_q` |
| REQ-06 | open_loop_dq_step (rotor-locked harness) | i_d(0.04)=1.2416 ±0.0124 | 1.241872 | **PASS** | `value_at plant.i_d` |
| REQ-06 | open_loop_dq_step (rotor-locked harness) | i_q(0.10875)=1.2416 ±0.0124 | 1.241557 | **PASS** | `value_at plant.i_q` |
| REQ-06 | open_loop_dq_step (rotor-locked harness) | final i = 1.25 (rtol 1%) | i_d 1.249997, i_q 1.249876 | **PASS** | final checks |
| REQ-06 | *open_loop_dq_step_free (control)* | same, free rotor | i_q(0.10875)=−0.105845, ω→2.14 | **FAIL** | rotor accelerates; back-EMF corrupts i_q |
| REQ-07 | xy_injection | i_x(0.005625)=1.2416 ±0.0124 | 1.241576 | **PASS** | `value_at i_x` |
| REQ-07 | xy_injection | i_y(0.005625)=1.2416 ±0.0124 | 1.241576 | **PASS** | `value_at i_y` |
| REQ-07 | xy_injection | final i_x,i_y = 1.25 (rtol 1%) | 1.25 / 1.25 | **PASS** | final checks |
| REQ-08 | over_speed | i_x,i_y ∈ ±1e-6 A (u_x=u_y=0) | 0.0 / 0.0 | **PASS** | bounds checks |
| REQ-08 | xy_injection vs xy_injection_overspeed | xy step independent of ω_k | 1.241576 vs 1.241577 (Δ≈1e-6) | **PASS** | i_x at t=0.005625 |
| REQ-09 | zero_seq_2n, hot_winding | i_0 ∈ ±1e-6 A (2N) | max 0.0 | **PASS** | bounds `i_0`/`plant.i_0` |
| REQ-10 | zero_seq_1n | i_0(0.005625)=1.2416 ±0.0248 | 1.241575 | **PASS** | `value_at plant.i_0` |
| REQ-10 | zero_seq_1n | final i_0=1.25 (rtol 2%) | 1.250000 | **PASS** | final check |
| REQ-11 | nominal,rated,over_speed,over_load | res_me ∈ ±1e-6 N·m | 0.0 | **PASS** | bounds `res_me` all cases |
| REQ-12 | nominal | m_e=4.5505 (rtol 1%) | 4.550456 | **PASS** | final `m_e` |
| REQ-12 | nominal | P_mech=238.24 (rtol 2%) | 238.256 | **PASS** | final `P_mech` |
| REQ-13 | accel_no_load (current-regulator harness) | ω_mech(0.1)=105.47 ±2.109 | 105.3733 | **PASS** | `value_at plant.omega_mech` |
| REQ-13 | accel_no_load | m_e held ≈10.6 N·m | 10.5901 (constant) | **PASS** | min/max `plant.m_e` |
| REQ-14 | free_decay (zero-torque harness) | ω_mech(10)=36.788 ±0.736 | 36.78783 | **PASS** | `value_at plant.omega_mech` |
| REQ-14 | free_decay | m_e = 0 throughout | 0.0 | **PASS** | bounds `plant.m_e` |
| REQ-14 | *free_decay_literal (control)* | all voltages 0 | ω→~0 in 0.13 s, m_e→−20.3 N·m | **FAIL** | PM back-EMF brakes; not zero torque |
| REQ-15 | rated, over_load | res_power ∈ ±1e-6 W | 0.0 | **PASS** | bounds `res_power` |
| REQ-26 | smoke | check ok; final time=0.1 (rtol 1e-6); states finite | ok; t=0.1; all finite | **PASS** | `checkModel` 24 eq/24 var; final `time`; trajectories finite |

The two **control** rows are diagnostic (they show *why* a harness is needed); they are not
the designated verification cases and do not count as REQ failures in the verdict.

## Notes / caveats (important)
1. **REQ-06, REQ-13, REQ-14 are only satisfiable with an externally imposed operating
   condition that the requirements' `cases:` entries did not specify**, because the Step-1
   interface is voltage-fed and has **no current source and no mechanical speed constraint**:
   - REQ-06 "machine at rest" → rotor accelerates under the 1 V step (ω_mech→2.14 rad/s);
     held at rest by balancing `m_load = m_e` (uses the model's own `m_load` input).
   - REQ-13 "constant m_e" → realised with a feed-forward + PI dq current regulator
     (explicitly allowed by the task).
   - REQ-14 "zero electromagnetic torque (i_d=i_q=0)" → with all voltages 0 the **PM
     back-EMF** drives i_q to −9.7 A and brakes the rotor to ~0 in 0.13 s; zero current was
     held with back-EMF feed-forward `u_q=ω_k·ψ_d` (uses the model's own u inputs).
   The underlying model equations are correct in all three cases; this is an
   **interface/case-definition gap**, not a machine-equation defect.
2. `REQ-09`/`REQ-10` name `i_0p`/`i_0m` (two channels); Step 1 exposes a single `i_0`.
   Verified against `i_0` (the blocked/enabled contrast is reproduced).
3. `REQ-01` `hot_winding` deliberately changes Rs to 1.114 Ω; the nominal 0.8 Ω criterion is
   verified in `nominal`/`smoke`, and the override taking effect is verified in `hot_winding`.

## Physical sanity checks (not requirements)
- **Signs/directions:** positive dq/xy voltages → monotone current rise to u/R_s=1.25 A;
  1N zero-sequence rises to 1.25 A while 2N stays exactly 0; positive torque accelerates
  (ω↑), and the PM machine short-circuited (u=0) *brakes* — all physically expected.
- **Conservation/consistency:** all six residuals are algebraically ~0 (≤1.8e-15,
  machine epsilon), consistent with their definitions.
- **No NaN / no solver stall:** every case reached its stop time with finite states and
  "simulation finished successfully".
- **Case-to-case sensitivity:** 2N blocks i_0 vs 1N enables it (expected contrast); xy
  response is speed-independent (Δ≈1e-6 A over 0→456.6 rad/s); hot-winding Rs override took
  effect; changing `m_load` changed the mechanical trajectory as expected (over_load with no
  drive spun the machine backward until m_e balanced the 11.66 N·m load).
- **Steady-state hold:** nominal bench held 52.3599 → 52.3587 rad/s over 0.5 s (drift
  <0.003%), confirming the balanced-load realisation.

## Verdict
**VERIFIED (Step 1): all must-REQs REQ-01…REQ-15 and the REQ-26 acceptance gate PASS in
their verification cases.** The model checks (`24 equations / 24 variables`, no errors) and
every case simulates to completion.

**Caveat:** REQ-06, REQ-13 and REQ-14 pass only once the requirement's *stated* operating
condition (rotor at rest / constant torque / zero torque) is imposed through harness
models, because the Step-1 voltage-fed interface has no current source or mechanical speed
constraint and the requirement `cases:` omit those conditions. The literal free-rotor /
open-circuit variants fail (documented above). Recommend either (a) adding a mechanical
speed-source/current-source interface, or (b) amending those three cases with the explicit
operating-condition overrides before Step-2/3 work proceeds.

---

# Step 2 — VSD + Park coordinate transforms (REQ-16 … REQ-20)

- **Model / classes verified:**
  `DualThreePhaseMachine.VSDTransform.VSD` / `.VSD_inv`,
  `DualThreePhaseMachine.ParkTransform.Park` / `.Park_inv`, exercised through the harness
  models `DualThreePhaseMachine.TransformChecks.VSDCheck` (REQ-16…19) and
  `DualThreePhaseMachine.TransformChecks.ParkCheck` (REQ-20).
- **Verified by:** sim-verifier (independent of the model author). `VSDTransform.mo`,
  `ParkTransform.mo` and `Requirements/requirements.yaml` were **not** modified.
- **Design point:** harness defaults — balanced set amplitude `A = 4.1 A`, sweep rate
  `omega = 2*pi rad/s` (1 rev/s); no `Results/parameters.json` exists, so model defaults
  apply. The VSD matrix is a `final parameter` (translation-time constant).
- **Cases:** `vsd_check` / `park_check` (as specified: `stop_time = 0.01 s`,
  2 intervals) and `vsd_check_full` / `park_check_full` (full revolution:
  `stop_time = 1.0 s`, 3600 intervals → theta = 0…2*pi) — see `Tests/cases.yaml`.
  NB: because `omega = 2*pi`, the as-specified `vsd_check` stop time only sweeps
  theta = 0…0.0628 rad (3 samples); the `*_full` cases are the meaningful
  all-angle evidence.
- **Tooling:** repo OpenModelica MCP tools (no shell tool was exposed in this run):
  `openmodelica_check`, `openmodelica_simulate`, `openmodelica_read_results`,
  `openmodelica_verify`. All four simulations report
  "The simulation finished successfully" with no warnings; `openmodelica_check`
  is ok (VSDCheck: 35 eq / 35 var; ParkCheck: 19 eq / 19 var). Every number below comes
  from a tool result **in this run**.

## Interface / name mapping (harness → requirement metric)
| requirements.yaml | harness variable |
|---|---|
| `vsd.orth_err`, `vsd.roundtrip_err` | `vsd.orth_err`, `vsd.roundtrip_err` |
| `vsd.i_x` / `i_y` / `i_0p` / `i_0m` | `vsd.x` / `vsd.y` / `vsd.zp` / `vsd.zm` |
| `vsd.i_alpha` / `i_beta` | `vsd.alpha` / `vsd.beta` |
| `vsd.i_alpha_amp` | `alpha_beta_amp` |
| `vsd.park_roundtrip_err` | `park.park_roundtrip_err` |
| `|i_dq| − |i_alpha,beta|` | `amp_err` |

## Requirement status (Step 2)

| REQ | Case | Criterion | Measured | Result | Evidence |
|-----|------|-----------|----------|--------|----------|
| REQ-16 | vsd_check, vsd_check_full | `orth_err ≤ 1e-9` (`T·Tᵀ=(1/3)I₆`) | **2.7756e-17** (both) | **PASS** | bounds `vsd.orth_err`; verify `all_pass=true` |
| REQ-17 | vsd_check, vsd_check_full | `roundtrip_err ≤ 1e-9` (`T·3Tᵀ=I₆`) | **5.5511e-17** (both) | **PASS** | bounds `vsd.roundtrip_err` |
| REQ-17 | vsd_check, vsd_check_full | VSD→VSD_inv recovers input ≤ 1e-9 A | **≤ 1.7764e-15** (spec) / **≤ 2.6645e-15** (full) | **PASS** | bounds `roundtrip_phase_err` |
| REQ-18 | vsd_check, vsd_check_full | `|i_x| ≤ 1e-6` A | **4.4409e-16** (spec) / **1.1102e-15** (full) | **PASS** | bounds `vsd.x` |
| REQ-18 | vsd_check, vsd_check_full | `|i_y| ≤ 1e-6` A | **4.4409e-16** (spec) / **2.0539e-15** (full) | **PASS** | bounds `vsd.y` |
| REQ-18 | vsd_check, vsd_check_full | `|i_0+| ≤ 1e-6` A | **5.9212e-16** (spec) / **1.9244e-15** (full) | **PASS** | bounds `vsd.zp` |
| REQ-18 | vsd_check, vsd_check_full | `|i_0−| ≤ 1e-6` A | **6.0137e-16** (spec) / **1.3323e-15** (full) | **PASS** | bounds `vsd.zm` |
| REQ-19 | vsd_check, vsd_check_full | peak `|i_αβ| = 4.1 A` (±1 %) | **4.099999999999999** (spec) / **[4.099999999999998, 4.100000000000001]** (full) | **PASS** | final `alpha_beta_amp`; verify PASS |
| REQ-19 | vsd_check, vsd_check_full | angle(α,β) tracks θ ≤ 1e-3 rad | **≤ 5.5511e-16 rad** (implied; spec **≤ 5.55e-16**, full **≤ 5.55e-16**) | **PASS** | bounds `alpha_err`,`beta_err` ∈ ±1e-3 |
| REQ-20 | park_check, park_check_full | `park_roundtrip_err ≤ 1e-9` (`R·Rᵀ=I₂`) | **0.0** (both) | **PASS** | bounds `park.park_roundtrip_err` |
| REQ-20 | park_check, park_check_full | `|dq| − |αβ| ≤ 1e-6` A | **0.0** (spec) / **8.8818e-16** (full) | **PASS** | bounds `amp_err` |
| REQ-20 | park_check, park_check_full | Park inverse recovers (α,β) ≤ 1e-6 A | **2.7756e-17** / **8.8818e-16** | **PASS** | bounds `roundtrip_alpha_err`,`roundtrip_beta_err` |

**Margin (measured / limit):** REQ-16 = 2.8e-7, REQ-17 = 5.6e-8 (matrix) / 2.7e-6
(phase round-trip), REQ-18 worst = 2.1e-9, REQ-19 amplitude ≈ 3e-16, REQ-19 angle ≈ 5.6e-13,
REQ-20 orthonormality = 0, REQ-20 magnitude = 8.9e-10. All margins are ≥ 8 orders of
magnitude below the limits.

### REQ-19 angle-requirement derivation (why the α,β error bounds prove it)
The harness exposes `alpha_err = α/A − cosθ` and `beta_err = β/A − sinθ`. Since
`(cosθ, sinθ)` is a unit vector, `|(α,β)/A − (cosθ,sinθ)| ≤ sqrt(alpha_err²+beta_err²)`,
so the angle of `(α,β)` differs from θ by at most `asin(·)`. With the measured
`max(|alpha_err|,|beta_err|) = 5.5511e-16` the angle error is **≤ 5.6e-16 rad**, far below
the 1e-3 rad limit. At the sample point t = 0.01 s the tool read
`θ = 0.06283185307179587`, `α = 4.0919095865559125`, `β = 0.2574411300701849`, i.e.
`(α,β) = A·(cosθ, sinθ)` — the direct mapping is confirmed, not just its residual.

## Physical sanity checks (Step 2, not requirements)
- **Reference matrix vs DER-8 (entry-by-entry, read from the result file):** row 1
  `[1/3, −1/6, −1/6, 0.28867513, −0.28867513, 0]`; row 2
  `[0, 0.28867513, −0.28867513, 1/6, 1/6, −1/3]`; row 3 `[1/3, −1/6, −1/6, −0.28867513,
  0.28867513, 0]`; row 4 `[0, −0.28867513, 0.28867513, 1/6, 1/6, −1/3]`; row 5
  `[1/3, 1/3, 1/3, 0, 0, 0]`; row 6 `[0, 0, 0, 1/3, 1/3, 1/3]`, with
  `0.28867513 = √3/6`. **Exact match to DER-8** (phase order a1,b1,c1,a2,b2,c2;
  amplitude scaling 1/3). Orthogonality alone would not pin this, so the entries were
  compared directly.
- **Signs/direction:** the balanced set (set 2 lagging 30°) gives α = A·cosθ, β = A·sinθ —
  a positive-sequence (counter-clockwise) αβ vector with peak magnitude A = 4.1 A; the
  Park block gives d = 4.1 A (constant) and q ≈ 0 (≤ 4.44e-16 A), the expected result for
  a vector aligned with the rotating frame.
- **Conservation/consistency:** the xy and 0+/0− channels carry ≤ 2.1e-15 A for a purely
  balanced set (all twelve matrix dot-products cancel to machine epsilon), and the
  inverse transform returns all six phases to ≤ 2.66e-15 A — no loss across the round trip.
  `openmodelica_verify` returned `all_pass = true` for every check on all four runs.
- **No NaN / no solver stall:** all four cases reached their stop time with finite states
  and "simulation finished successfully"; `openmodelica_check` reports no errors or
  warnings for either harness.
- **Case-to-case sensitivity:** results are not a single-point coincidence — the
  as-specified 3-sample case and the full-revolution (theta = 0…2π, 3601-sample) case give
  the same machine-epsilon-level errors, i.e. the properties hold at *all* swept angles.
  `amp_err` is non-zero (8.88e-16) in the sweep, confirming the Park block is genuinely
  evaluated with time-varying θ and is not a compile-time constant fold.
- **Scope note:** the harness exercises REQ-17's round trip on the balanced set only; the
  requirement's "arbitrary 6-vector" case is covered by the matrix identity
  `max|T·(3Tᵀ) − I₆| = 5.55e-17 ≤ 1e-9`, which holds for every vector by construction.

## Verdict (Step 2)
**VERIFIED (Step 2): all must-REQ REQ-16, REQ-17, REQ-18, REQ-19 and REQ-20 PASS** in
their verification cases (`vsd_check`/`vsd_check_full`, `park_check`/`park_check_full`).
The VSD matrix equals the DER-8 reference matrix exactly, is orthogonal (T·Tᵀ = ⅓ I₆) with
an exact 3Tᵀ inverse, a balanced 30°-displaced six-phase set maps entirely into αβ
(≤ 2.1e-15 A leakage into xy/0±), with peak αβ = 4.1 A and an angle tracking θ to
≤ 5.6e-16 rad; the Park rotation is orthonormal and magnitude-preserving (≤ 8.9e-16 A)
across a full electrical revolution. No blockers.

---

# Step 3 — dual 2-level VSI + full plant (REQ-21 … REQ-25)

- **Model / classes verified:** `DualThreePhaseMachine.DualThreePhaseInverter`
  (`DualThreePhaseInverter.mo`) and `DualThreePhaseMachine.PlantAssembly`
  (`PlantAssembly.mo`); REQ-24/25 are exercised on
  `DualThreePhaseMachine.DualThreePhaseIPMSM` (Steps 1–2 machine, **not modified**)
  through a current-regulating, speed-held driver.
- **Verified by:** sim-verifier (independent of the model author). No `.mo` model file
  and no `Requirements/requirements.yaml` was modified.
- **Timestamp:** 2026-09-27.
- **Scope:** `REQ-21` … `REQ-25` (Step 3) plus a full-plant smoke run.
- **Design point:** `u_dc = 500 V` (ASM-1), `neutral_config = 2N` (default); MTPA
  `i_d = −5.02 A, i_q = 10.24 A` (DER-5); `ω_mech = 415.0943 rad/s` (DER-1).
  No `Results/parameters.json` exists, so model defaults apply.
- **Tooling:** repo OpenModelica MCP tools (`openmodelica_check`, `openmodelica_simulate`,
  `openmodelica_verify`, `openmodelica_read_results`). Every number below comes from a
  tool result produced **in this run**.

## Method / interface mapping (necessary for verification)
`DualThreePhaseInverter` and `PlantAssembly` expose their six gate signals
`s_a1…s_c2` and `PlantAssembly.m_load` as **unconnected top-level `RealInput`s**; the
runner's numeric `overrides` drive them (demonstrated: forced gate states reproduce the
Eq. (4) voltages exactly, so the override genuinely took effect). `neutral_config`,
however, is an **enumeration** and cannot be set through numeric overrides, so the 1N
cases use the additive, **test-only** driver file
`Example/DualThreePhaseMachine/Tests/Step3Harnesses.mo` (lives in `Tests/`, outside the
package; no model file touched). It provides:
- `InverterAll64_2N` / `InverterAll64_1N`: instantiate **all 64 switching states** in one
  run and expose the global `max |u_ph|`, `max |per-set voltage sum|` and
  `max Eq.(4)/(5) residual` (REQ-21/22/23). `openmodelica_check`: 1027/1026 eq = var.
- `RatedHold`: feed-forward + PI dq current regulator at the MTPA pair with an exact
  **speed-hold load BC** `m_load = m_e − ν·ω_k` (so `dω_k/dt = 0`), for REQ-24/25.
  `openmodelica_check`: 28/28 eq = var.

## Requirement status (Step 3)

| REQ | Case | Criterion | Measured | Result | Evidence |
|-----|------|-----------|----------|--------|----------|
| REQ-21 | vsi_states (all 64 states, 2N, 500 V) | `|sum_set1|,|sum_set2| ≤ 1e-6 V` | **0.0 V** (max over 64) | **PASS** | `openmodelica_verify` bounds on `sum_abs_max` |
| REQ-21 | vsi_all64_2n_low_dc (2N, 400 V) | `≤ 1e-6 V` | **0.0 V** | **PASS** | bounds `sum_abs_max` |
| REQ-21 | low_dc_link (state S2, 400 V) | `|sum_set1|,|sum_set2| ≤ 1e-6 V` | **0.0 / 0.0 V** | **PASS** | bounds `sum_set1`,`sum_set2` |
| REQ-22 | vsi_states (all 64, `uph_err`) | `uph_err ≤ 1e-6 V` | **0.0 V** | **PASS** | bounds `uph_err_max` |
| REQ-22 | vsi_s1 `(0,0,0,0,0,0)` | `(0,0,0,0,0,0) V` | **(0,0,0,0,0,0)** | **PASS** | final `u_a1`…`u_c2` = 0 |
| REQ-22 | vsi_s2 `(1,0,0,0,0,0)` | `(333.333,−166.667,−166.667,0,0,0)` | **(333.3333,−166.6667,−166.6667,0,0,0)** | **PASS** | final `u_a1`,`u_b1`,`u_c1`,`u_a2` |
| REQ-22 | vsi_s3 `(1,1,0,0,0,0)` | `(166.667,166.667,−333.333,0,0,0)` | **(166.6667,166.6667,−333.3333,0,0,0)** | **PASS** | final phase voltages |
| REQ-22 | vsi_s4 `(1,1,1,0,0,0)` | `(0,0,0,0,0,0) V` | **(0,0,0,0,0,0)** | **PASS** | final phase voltages |
| REQ-22 | vsi_s5 `(0,0,0,1,0,0)` | `(0,0,0,333.333,−166.667,−166.667)` | **(0,0,0,333.3333,−166.6667,−166.6667)** | **PASS** | final phase voltages |
| REQ-22 | vsi_s6 `(1,1,1,1,1,1)` | `(0,0,0,0,0,0) V` | **(0,0,0,0,0,0)** | **PASS** | final phase voltages |
| REQ-22 | vsi_all64_1n (Eq. 5, 1N) | `uph_err ≤ 1e-6 V` | **2.84e-14 V** | **PASS** | bounds `uph_err_max` |
| REQ-23 | vsi_states (2N, 500 V) | `uph_max_abs ≤ 2·u_dc/3 = 333.334 V` | **333.3333 V** | **PASS** | bounds `uph_max_all`; margin 6.7e-4 V (2·10⁻⁶ rel.) |
| REQ-23 | vsi_all64_2n_low_dc (2N, 400 V) | `≤ 2·400/3 = 266.667 V` | **266.6667 V** | **PASS** | bounds `uph_max_all`; margin 3.3e-4 V |
| REQ-23 | vsi_all64_1n (1N, 500 V) | `uph_max_abs ≤ 5·u_dc/6 = 416.667 V` | **416.6667 V** | **PASS** | bounds `uph_max_all`; margin 3.3e-4 V |
| REQ-24 | rated_hold (415.0943 rad/s) | `m_e = 10.6 N·m (±2 %)` | **10.5901 N·m** | **PASS** | final `plant.m_e`; dev 0.094 % |
| REQ-24 | over_speed_hold (456.6 rad/s) | same `10.6 N·m (±2 %)` | **10.5901 N·m** | **PASS** | final `plant.m_e` (identical → speed-independent) |
| REQ-25 | rated_hold | `P_mech(0.5 s) = 4400 W (±88)` | **4395.892 W** | **PASS** | `value_at plant.P_mech` t=0.5; dev 4.11 W (0.093 %) |
| smoke | plant_smoke (S2, `m_load=10.6`, 0.1 s) | `LOG_SUCCESS`; final `time=0.1`; states finite | **t=0.1; all finite** | **PASS** | `LOG_SUCCESS`; final `time`; `read_results` finite |

**Margins (upper bounds: `(limit − measured)/limit`; relative error for two-sided):**
REQ-21 = 1.0 (measured 0 vs 1e-6 V); REQ-22 = 1.0 for the 2N residual and 0.99997 for 1N;
REQ-23 2N@500 = 2.0e-6, 2N@400 = 1.2e-6, 1N@500 = 8.0e-7 (bound-tight, as expected: the
extremal switching state realises the bound exactly); REQ-24 deviation = 0.094 % of 10.6
(4.7 % of the ±2 % tolerance); REQ-25 deviation = 0.093 % of 4400 (4.7 % of the ±2 %
tolerance). REQ-24/25 residuals `res_me`, `res_power` = 0 throughout.

## Notes on the REQ-23 bound correction (2N vs 1N)
The corrected, **configuration-specific** bound is confirmed by the model:
- **2N (isolated neutrals, Eq. 4):** measured global max over all 64 states is exactly
  `2·u_dc/3` — **333.3333 V @500 V** and **266.6667 V @400 V** (scales linearly with
  `u_dc`; ratio 0.8). `openmodelica_verify` bounds `uph_max_all ≤ 333.334 V` (500 V) and
  `≤ 266.667 V` (400 V) both PASS.
- **1N (common neutral, Eq. 5):** measured global max over all 64 states is exactly
  `5·u_dc/6` = **416.6667 V @500 V**, i.e. **larger** than the 2N `2·u_dc/3` limit. The
  `≤ 416.667 V` check PASSes, while it would exceed the old incorrect 2N-only bound — so
  the requirement's corrected 2N/1N distinction is necessary and is reproduced by the
  model. (In 1N the per-set voltage sums are deliberately *not* zero; only the sum over
  all six phases is, which is why the 1N channel must be bounded separately.)

## Physical sanity checks (not requirements)
- **Signs / directions:** S2 `(1,0,0,0,0,0)` gives a1 `+2u_dc/3` and the other two legs
  `−u_dc/3`; S3 shifts the "high" legs to a1,b1 and c1 to `−2u_dc/3`; S5 is the mirror in
  the second set. Signs and magnitudes match Eq. (4) exactly (`uph_err = 0`).
- **Conservation-like plausibility:** each 2N set sums to exactly 0 V in every state
  (no zero-sequence DOF); the reconstructed 2N phase currents in the plant smoke also sum
  per set to 0 (e.g. `i_a1+i_b1+i_c1 = 413.8338 − 211.5349 − 202.2989 ≈ 0`), consistent
  with the blocked zero-sequence channel.
- **Case-to-case sensitivity:** the 2N bound tracks `u_dc` (333.333 → 266.667 for
  500 → 400 V); the 1N bound is wider (416.667 V) than the 2N bound; rated torque is
  **identical** at rated (+10 %) speed → genuinely speed-independent; the S1/S4/S6 zero
  states all give exactly 0 V.
- **Rated-point consistency:** `res_me = res_power = 0`; `ω_mech` held at exactly
  415.0943 rad/s (rated) and 456.6000 rad/s (over-speed) for the whole 0.5 s.
- **No NaN / no solver stall:** every simulation returned
  "The simulation finished successfully" and `openmodelica_check` is ok for the VSI
  (16/16), PlantAssembly (102/102) and all three drivers. No trajectory is NaN/Inf.
  (A few MCP load calls returned the transient `Operation cannot be accomplished in
  current state` and were re-issued successfully; these are runner session-state
  hiccups, not model failures.)
- **Full-plant smoke caveat (informational, not a failure):** the fixed-gate plant smoke
  is an *open-loop, unmodulated* large-signal transient — with a held gate state the
  machine sees a constant stationary voltage vector while the rotor turns, so the phase
  currents swing large (e.g. `i_a1` peaks at ≈413.8 A and `m_e` at ≈±700 N·m). This is
  expected without a modulator/current loop; the acceptance criterion (LOG_SUCCESS +
  finite states to t = 0.1 s) is met.

## Verdict (Step 3)
**VERIFIED (Step 3): all must-REQ REQ-21, REQ-22, REQ-23, REQ-24 and REQ-25 PASS** in
their verification cases, and the full-plant smoke run succeeds (`LOG_SUCCESS`, finite
states to 0.1 s). The VSI reproduces Eq. (4)/(5) exactly (residual 0 for all six
representative states and ≤ 2.8e-14 V over all 64 states), blocks the per-set
zero-sequence in 2N (sums = 0 V), respects the configuration-specific bounds
(`2u_dc/3` in 2N, `5u_dc/6` in 1N), and the rated point gives `m_e = 10.59 N·m` and
`P_mech = 4395.9 W` at a speed-independent torque. No blockers.

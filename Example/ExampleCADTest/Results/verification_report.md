# Verification report — ExampleCADTest — Pendulum.SimplePendulum

- **Model under test:** `Pendulum.SimplePendulum`
  (`Example/ExampleCADTest/OpenModelica/Pendulum/package.mo`)
- **Tool:** OpenModelica (via MCP `openmodelica_check` / `openmodelica_simulate` / `openmodelica_read_results` / `openmodelica_time_to_reach` / `openmodelica_verify`)
- **Session date:** 2026-09-27 (git-free; no commit hash used)
- **Design point:** no `Results/parameters.json` exists — nominal/default parameters only:
  `L = 1 m` (FixedTranslation `r = {0,-1.0,0}`), `m = 1 kg` (point mass), gravity default
  (`world` = uniform gravity, g = 9.81 m/s² along −y), `revolute.n = {0,0,1}`,
  `phi(start = 0.1, fixed = true)`.
- **Simulation settings (case `nominal`):**
  - stop time = **10 s**
  - output intervals = **2000** → output grid **0.005 s**
  - tolerance = default (1e-6, not overridden); solver = OpenModelica default (not overridden)
  - overrides = none
  - result file: `.om_build/Pendulum_SimplePendulum/nominal/Pendulum.SimplePendulum_res.mat`
  - status: `check` ok (1006 equations / 1006 variables, no errors or warnings);
    `simulate` ok ("initialization finished successfully", "simulation finished successfully").

## Requirement results

| REQ ID | Requirement | Measured value | Limit / criterion | PASS/FAIL | Evidence (tool) |
|--------|-------------|----------------|-------------------|-----------|-----------------|
| **REQ-T1** | \|angle\| stays below 0.101 rad for the whole simulation | max \|angle\| = **0.100000** (max `angle` = 0.100000 at t = 0 s; min `angle` = −0.09999977 at t = 1.005 s) | \|angle\| < 0.101 rad | **PASS** | `read_results` + `verify` bounds `angle ∈ [−0.101, 0.101]` → PASS. Margin = (0.101 − 0.100)/0.101 = **0.99 %** |
| **REQ-T2** | First time `angle` falls below 0 is 0.50 s ± 2 % (0.49–0.51 s) | t_z = **0.50190947 s** | 0.49 s ≤ t_z ≤ 0.51 s | **PASS** | `time_to_reach` (falling, threshold 0) = 0.5019094729644685 s; margin to upper limit = (0.51 − 0.501909)/0.51 = **1.59 %** |

## Measured quantities and method

- **Maximum |angle|:** `read_results(angle)` reports `max = 0.100000` at `t_max = 0.0 s` and
  `min = −0.0999997735641895` at `t_min = 1.005 s`. Hence max |angle| = **0.100000 rad at t = 0 s**
  (the value at `min` has slightly smaller magnitude). The whole trajectory was checked with a
  bounds check on `angle` over the full 0–10 s window → PASS.
- **First falling zero-crossing (t_z):** `openmodelica_time_to_reach(angle, threshold = 0,
  direction = falling)` = **0.5019094729644685 s**. Method: the tool scans the solver's result grid
  (output grid 0.005 s, solver adaptive steps retained in the `.mat`) for the first crossing.
  Cross-checked by interpolation using `read_results` at-grid values:
  `angle(0.49) = +0.0037272`, `angle(0.50) = +0.0005977`, `angle(0.505) = −0.0009674`,
  `angle(0.51) = −0.0025323`; linear interpolation of the sign change between 0.50 s and 0.505 s
  gives t_z ≈ 0.50 + 0.005·(0.0005977/0.0015651) ≈ **0.5019 s**, consistent with the tool value.
- **Analytic reference (for comparison, not a measured requirement):**
  T/4 = (2π√(L/g))/4 = (2π√(1/9.81))/4 ≈ **0.50154 s** (small-angle). Measured 0.50191 s is
  +0.07 % above it — the expected small amplitude correction for φ₀ = 0.1 rad
  (≈ φ₀²/16 ≈ +0.06 %), so the model's period is physically sound.

## Physical sanity checks (not requirements)

- **No energy created (REQ-T1 spirit):** max |angle| (0.100000) equals the initial displacement
  amplitude 0.1 rad; the opposing extreme is −0.09999977 rad (magnitude ≤ initial). Energy is
  conserved/converted, not amplified. ✔
- **Direction/sign correctness:** `angle` starts at +0.1 rad, decreases monotonically through the
  selected sample points (0.09514 at 0.1 s → 0.07093 at 0.25 s → 0.00373 at 0.49 s), crosses zero
  falling at t_z, reaches the opposite extreme ≈ −0.1 rad near t ≈ 1.0 s — consistent with a
  pendulum released at rest from the +y side under gravity along −y. ✔
- **No NaN/Inf:** all queried samples are finite; the solver reported "simulation finished
  successfully" with no warnings. ✔
- **Solver did not stall:** the run completed the full 10 s stop time (result `t_final = 10.0 s`),
  final angle = 0.099267 rad (≈0.1 rad; 10 s is not an integer number of the ≈2.008 s period, so a
  non-zero residue is expected). ✔
- **Nonlinear periodicity:** minimum at t_min = 1.005 s ≈ T/2 (T ≈ 2.008 s), matching the
  quarter-period half-way symmetry. ✔

## Verdict

**VERIFIED** — both must-requirements PASS on the nominal case:

- REQ-T1: max |angle| = 0.100000 rad < 0.101 rad (margin 0.99 %).
- REQ-T2: first falling zero-crossing t_z = 0.50190947 s, inside 0.49–0.51 s (margin 1.59 % to the
  upper limit).

The model loads/checks/initializes cleanly and the motion is physically consistent (amplitude not
exceeding the initial release angle, correct quarter/half-period timing).

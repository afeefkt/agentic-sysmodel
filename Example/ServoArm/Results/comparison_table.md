# ServoArm — closed-loop comparison table (verified results)

**Model:** `ServoArm.System` (`Example/ServoArm/OpenModelica/ServoArm/System.mo`)
**Result files:** `.om_build/ServoArm_System/<case>/ServoArm.System_res.mat`
**Command:** 0 → 90° step = 1.5707963 rad applied at `t_cmd = 0.1 s`; arm starts at rest at `phi = 0`.
**Run settings:** dassl, `stop_time = 4.0 s`, `number_of_intervals = 500`, `tolerance = 1e-6`.

Metrics measured with `openmodelica_measure` / `openmodelica_compare_cases` / `openmodelica_read_results`:

- **Rise time (10→90 %):** on `phi`, from `t_start = 0.1 s`, reference = setpoint 1.5707963 rad.
- **Overshoot %:** `(peak phi − 1.5707963)/1.5707963 × 100`, peak over `t > 0.1 s`.
- **Settling time to ±1°:** first instant after which `|phi − 1.5707963| ≤ 0.017453 rad` for the rest of the run; implemented as `measure settling_time`, `setpoint = 1.5707963`, `band = 0.017453/1.5707963 = 0.0111109` (fraction-of-step).
- **Peak |current|:** `max(|i|)` over `t > 0.1 s` (from `i` max/min).
- **Steady-state error:** `|phi(t=3 s) − 1.5707963|`, rad.

**Time reference:** rise time and settling time are reported **from the move command at `t_cmd = 0.1 s`** (project convention, `requirements.yaml`). Absolute times = value + 0.1 s (e.g. nominal settling = 0.992 s absolute).

| Case (top-level overrides) | Rise time 10→90 % (s) | Overshoot (%) | Settling to ±1° (s) | Peak \|i\| (A) | SS error @ t=3 s (rad) |
|---|---:|---:|---:|---:|---:|
| nominal `{}` | 0.5457 | 4.082 | 0.8920 | 0.6036 | 1.049e-9 |
| heavy_payload `{payload_m = 0.30}` | 0.5452 | 4.230 | 0.8840 | 0.6905 | 3.047e-10 |
| low_supply `{Vsupply = 20}` | 0.5457 | 4.082 | 0.8920 | 0.6036 | 1.049e-9 |
| hot_winding `{R_a = 2.6}` | 0.5450 | 4.280 | 0.8840 | 0.5565 | 6.432e-10 |
| worst `{payload_m = 0.30, Vsupply = 20, R_a = 2.6}` | 0.5442 | 4.481 | 0.8840 | 0.6623 | 2.820e-9 |

## Notes

- Case overrides confirmed directly from the result files (`payload_m`, `Vsupply`, `R_a` = 0.20/0.30, 24/20, 2.0/2.6 as designed); `N = 50` in all cases.
- **Tightest margin:** REQ-02 (overshoot), worst case — **4.481 % vs the 5 % limit (10.4 % headroom; peak ≈ 94.03° vs the 94.5° cap)**. It is the tightest simulation-verified margin; the linear-analysis REQ-06 worst-case phase margin (48.6° vs 45°, 8.0 % headroom) is tighter but is not a simulation result. All other requirement margins are ≥ 14 %.
- `low_supply` is numerically identical to `nominal`: peak controller output is well below both ±20 V and ±24 V, so the reduced supply limit is never engaged.
- All five cases are finite, settle to within ~1e-9 rad of the 90° setpoint (integral action holds against gravity at `i ≈ 0.348 A`), and comfortably satisfy `|i| ≤ 5 A`.

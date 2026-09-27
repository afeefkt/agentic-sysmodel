---
name: openmodelica-simulation
description: Use when running or troubleshooting OpenModelica simulations — choosing solver, tolerance, stop time and output intervals, run-time parameter overrides, events and stiffness, initialization problems, result files, performance of long or switching simulations.
---

# Running simulations well (OpenModelica 1.27)

## Settings (openmodelica_simulate arguments)
| Setting | Default | Guidance |
|---|---|---|
| `stop_time` | 1.0 | Cover the whole manoeuvre plus the settling time. For a retraction of about 8 s, use 12–20 s |
| `number_of_intervals` | 500 | Output points only (not solver steps). Use more for fast transients or PWM (≥ 5 points per period of interest) |
| `tolerance` | 1e-6 | 1e-6 is a good default. Use 1e-4 for quick sweeps and 1e-8 when verifying tight criteria |
| `overrides` | none | Run-time parameter changes (`-override`) with no recompile. They only work for non-structural, non-`final`, non-evaluated parameters |

Default solver: **dassl** (variable-step BDF, handles stiff systems). It's usually right for physical models. The OM User's Guide lists alternatives (`ida`, explicit Euler, Runge-Kutta, …) in `knowledge/web/omug-solving.md`, and all simulation flags in `knowledge/web/omug-simulation-flags.md`.

## Fast and robust habits
- **Switching models** (PWM inverters) are slow because they create thousands of events. Use averaged sources for sweeps, and switching models only for final ripple checks.
- Many events from `abs`/`if` on continuous variables → smooth them (see modelica-debugging).
- Stiff hydraulics (high bulk modulus, small volumes) is fine for dassl. If it's very slow, check for chattering valves and add hysteresis.
- Keep result files small: request only the needed metrics, and use `data-analyst`/`measure` rather than raw reads.

## Initialization failures
- Check the `messages` from simulate. `LOG_INIT` style failures mean the start values or fixed flags are inconsistent.
- Fix only independent states. For loops, give good start guesses (see modelica-multibody).
- `initial equation der(x)=0` for steady-state starts.

## Result files
- `simulate` returns `result_file` (`.mat`, Dymola v4 format). The analysis tools read it directly.
- Each `tag` gets its own run directory under `.om_build/<model>/<tag>/`. Use distinct tags per case (`nominal`, `cold_fluid`, …) so results don't overwrite each other.

## Reproducibility
Report the stop time, tolerance, solver and overrides with every result, so verification evidence can be re-run.

Source: OpenModelica User's Guide (CC BY 4.0, © OSMC). Chapters in `knowledge/web/omug-*.md`.

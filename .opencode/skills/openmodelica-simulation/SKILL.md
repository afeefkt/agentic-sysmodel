---
name: openmodelica-simulation
description: Use when running or troubleshooting OpenModelica simulations — choosing solver, tolerance, stop time and output intervals, run-time parameter overrides, events and stiffness, initialization problems, result files, performance of long or switching simulations. Also use before linearizing or reading results.
---

# Running simulations well (OpenModelica 1.27)

The repo exposes these through the `openmodelica_simulate` tool. Its key arguments are
`stop_time`, `number_of_intervals`, `tolerance`, `overrides`, and `tag`.

## Settings (openmodelica_simulate arguments)
| Setting | Default | Guidance |
|---|---|---|
| `stop_time` | 1.0 | Cover the whole manoeuvre plus settling. A ~8 s retraction → 12–20 s |
| `number_of_intervals` | 500 | **Output points only**, not solver steps. More for fast transients or PWM (≥ 5 points per period of interest) |
| `tolerance` | 1e-6 | 1e-6 default. 1e-4 for quick sweeps, 1e-8 when verifying tight criteria |
| `overrides` | none | Run-time parameter changes (`-override`) with no recompile. Only for non-structural, non-`final`, non-`protected`, non-evaluated, non-constant-bound parameters |
| `tag` | "run" | Names the run dir; use distinct tags (`nominal`, `cold_fluid`) so parallel cases don't overwrite each other's results |

Default solver: **dassl** (variable-step BDF, stiff, adaptive order 1–5). It's usually
right for physical models. Alternatives and when to use them: `references/solvers-flags.md`.

## Run-time overrides (what can and can't be overridden)
`overrides={"actuator.boreDiameter": 0.05}` becomes `-override=actuator.boreDiameter=0.05`.
- Works only on parameters that are **non-structural, non-`final`, non-`protected`,
  non-evaluated (`annotation(Evaluate=false)`), and have no non-constant binding**.
  Otherwise OpenModelica warns it cannot override the value, and your change is silently
  ignored — the #1 "why didn't my override work" cause.
- Override the **independent** parameter (e.g. the diameter the areas are computed from),
  not the dependent one (the area).
- Cannot combine `-override` and `-overrideFile`; the repo's tool uses `-override`.

## Fast and robust habits
- **Switching models** (PWM inverters) create thousands of events and are slow. Use
  averaged sources for sweeps, switching models only for final ripple checks.
- Chattering → hundreds of state events in a row. `-abortSlowSimulation` aborts on it;
  `-mei` (max event iterations, default 20) bounds event iteration. Fix the cause
  (hysteresis, `noEvent`, regularization) — see `modelica-debugging`.
- Many events from `abs`/`if` on continuous variables → smooth them.
- Stiff hydraulics (high bulk modulus, small volumes) is fine for dassl. If very slow,
  check for chattering valves and add hysteresis.
- Keep result files small: request only needed metrics; use `openmodelica_measure` /
  `openmodelica_read_results` rather than reading raw files.

## Initialization
- `LOG_INIT` / "initialization failed" means start values or `fixed` flags are inconsistent.
- Fix only **independent** states; too many `fixed=true` over-determines initialization.
- `initial equation der(x)=0` gives a steady-state start.
- Debug with `-d=initialization`; only nonlinear iteration variables need `start`.
- For kinematic loops give good `start` guesses (see `modelica-multibody`).

## Result files
- `simulate` returns `result_file` (`.mat`, MATLAB v4 format). Analysis tools read it directly.
- Each `tag` gets its own dir under `.om_build/<model>/<tag>/`. Distinct tags per case.
- Variable names in the `.mat` are the fully-qualified names; use
  `openmodelica_list_variables(result_file, contains=...)` to discover them.

## Reproducibility
Report stop time, tolerance, solver, and overrides with every result so verification
evidence can be re-run. Full solver/flag reference and the omc scripting API:
`references/solvers-flags.md`, `references/scripting-api.md`. Sources: `references/sources.md`.

Source: OpenModelica User's Guide (CC BY 4.0, © OSMC). Chapters in `knowledge/web/omug-*.md`.

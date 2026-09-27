# Solvers and simulation flags (OpenModelica 1.27)

## Solvers (set via `method` / `-s`)
| Solver | Type | Step | Best for |
|---|---|---|---|
| `dassl` (default) | implicit BDF, order 1–5 | variable | general stiff physical models — the safe default |
| `ida` | SUNDIALS BDF, order 1–5, default sparse KLU | variable | large stiff/sparse systems |
| `cvode` | BDF or Adams-Moulton, order 1–12 | variable | stiff systems; "advised for stiff" |
| `gbode` | Runge-Kutta 1–14 | variable | high-accuracy non-stiff |
| `euler` | explicit Euler | **fixed** | debug only; step = (stop−start)/numberOfIntervals |
| `rungekutta` | explicit RK | **fixed** | non-stiff, or to check event-free behaviour |
| `qss` / `symSolver` | special | — | niche (QSS, symbolic) |

Rule of thumb: keep `dassl`. Reach for `ida` when the model is large and sparse, `cvode`
when dassl struggles on a stiff system, and an explicit fixed-step solver only for simple
non-stiff checks.

## Key flags (all available via the `openmodelica_simulate`/`simulate` calls)
- `-stopTime`, `-startTime`, `-stepSize`, `-maxStepSize`, `-initialStepSize`
- `-tolerance` (default 1e-6)
- `-numberOfIntervals` (default 500) — **output** grid, not the internal step size.
- `-noEquidistantTimeGrid` — stop interpolating variable-step output onto an equidistant grid.
- `-abortSlowSimulation` — abort on chattering (many state events in a row).
- `-mei=<n>` — max event iterations (default 20).
- `-iim=symbolic|none` — inline integration method; symbolic is default and homotopy is auto-tried.
- `-d=initialization` — verbose initialization diagnostics.
- `-ls=<name>`, `-nls=<name>` — linear / non-linear algebraic solvers (e.g. `klu`).
- `-override=var1=val1,...` / `-overrideFile=file` — run-time parameter overrides
  (mutually exclusive with each other).

## Initialization in detail
- `initial equation` / `initial algorithm` sections set initial values.
- `x(start=v, fixed=true)` makes the start value a hard initial condition.
- `x(start=v)` (no `fixed`) is only a **guess** for the iteration solver.
- Only **non-linear iteration variables** require `start`; over-specifying `fixed=true`
  yields an over-determined initialization ("failed to solve initialization").
- Omc auto-tries homotopy to converge initialization; if it fails, give better start guesses.

## The `.mat` result file
- Default output is MATLAB **level-4 MAT** (readable by MATLAB/Octave/Scilab/SciPy/DyMat/Dymola).
- Structure: an `Aclass` field (row 4 = `binTrans`/`binNormal`; `binTrans` ⇒ whole matrix
  transposed), `name` and `description` arrays, and `dataInfo`.
- Read via `readSimulationResult` / `readSimulationResultVars`, or SciPy/DyMat. In this
  repo, always use the `openmodelica_*` tools instead of reading raw files.

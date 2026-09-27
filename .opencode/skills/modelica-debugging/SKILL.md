---
name: modelica-debugging
description: Use whenever openmodelica_check or openmodelica_simulate fails — translation errors, unbalanced equations, class not found, initialization failures, singular systems, chattering, slow or stalled simulations, overrides not taking effect.
---

# OpenModelica failure → fix table

Read the diagnostics from the tool. Fix **the first error** only, then check again. Later
errors are often consequences of the first.

| Symptom (diagnostic text) | Likely cause | Fix |
|---|---|---|
| `Class X not found in scope` | Wrong MSL path, or MSL3 names (`Modelica.SIunits`) | `openmodelica_describe_class` on the parent package. Use `Modelica.Units.SI` |
| `Too many equations, over-determined system` | Planar kinematic loop, a double-defined variable, or connect + equation on the same variable | Use `RevolutePlanarLoopConstraint` for one joint per loop. Remove the duplicate equation |
| `Too few equations, under-determined system` | Unconnected input, missing equation for a custom variable, missing `inner world` | Count unknowns vs equations in custom models. Connect or set all inputs |
| `The model is structurally singular` | Algebraic constraint on a state, missing Ground, or a massless chain | Add mass or compliance; add `Electrical.Analog.Basic.Ground`; rethink which variables are states |
| `initialization problem is inconsistent` / `failed to solve initialization` | Too many `fixed=true`, or start values far away (wrong loop branch) | Fix only independent states. Give good `start` guesses for loop joints. Debug with `-d=initialization` |
| `Nonlinear system solver failed at time t` | Discontinuity, sqrt/abs of a negative, or division by ~0 | Regularize (`Δp/(Δp²+ε²)^0.25`, `tanh`), use `max(x, eps)` in divisions |
| Simulation very slow, many events | `abs`/`sign`/`if` on continuous variables causing events | Smooth the functions, or wrap with `noEvent(...)` where physically safe |
| Chattering / thousands of events in a row | Comparator without hysteresis, or regularized function with too-small eps | Add hysteresis (`Logical.Hysteresis`), widen the regularization |
| `Simulation terminated by an assertion` | Physical bound violated (negative volume, joint limits) | Check the stroke limits and initial positions. The assertion text says what |
| Override has no effect | The parameter is `final`, evaluated (`Evaluate=true`), `protected`, **structural**, or has a non-constant binding | Override the independent parameter it's computed from, or edit the default |
| Result variable missing | Aliased or protected, or removed by the optimizer | Expose it as a top-level `Real` with an equation |
| Warning `…default zero start value` | Missing start values for iteration variables | Add a `start=` with a physical value |

## Workflow
1. Make the smallest change that fixes the diagnostic.
2. Don't change physics to silence an error (for example, deleting a load).
3. After 4 failed attempts on the same error, stop and report: the error, what you tried, and your hypothesis.
4. Add any new recurring error and its fix to this table (see `skill-authoring`).

## Useful diagnostics flags (when the message is too terse)
- `-d=initialization` — verbose initialization (see what start values the solver used).
- `-d=stateselection` / `-d=bltdump` — structural/equation details.
- `-lv=LOG_NLS` — nonlinear solver iteration log.
- `-abortSlowSimulation` / `-mei=<n>` — abort on chattering / bound event iterations.

Expanded failure catalog (each row with a concrete worked example): `references/failure-catalog.md`.
Sources: `references/sources.md`.

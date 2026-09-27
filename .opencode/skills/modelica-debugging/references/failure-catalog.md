# Failure catalog (expanded)

Each entry = symptom → root cause → concrete fix. This is the living checklist; add one
row whenever an agent hits a new error (see `skill-authoring`).

## Translation / structural
- **"Too many equations"** — almost always: (a) a planar MultiBody loop missing its
  `RevolutePlanarLoopConstraint`, (b) a `connect` plus an explicit equation on the same
  variable, or (c) a variable assigned in both an equation and an algorithm. Fix by
  removing one equation, not by deleting a load.
- **"Too few equations"** — an unconnected `RealInput`, a `when` without an `elsewhen`/
  `else` that leaves a variable unassigned, or a custom component that declares a variable
  but never constrains it. Count unknowns vs equations in the custom model.
- **"Structurally singular"** — a massless free chain in MultiBody, or an electrical circuit
  without a `Ground` reference. Add mass/compliance or ground.

## Initialization
- **"failed to solve initialization"** — too many `fixed=true` (over-determined) or bad start
  guesses on a loop (wrong assembly branch). Fix only independent states; for loops, nudge
  the `start` guesses to the physically-correct branch.
- **"Scalar system is always singular"** — a redundant initial equation (e.g. `der(x)=0` on a
  state that's algebraically determined). Remove the redundant equation.
- Diagnose with `-d=initialization`, which prints the iteration variables and their values.

## Runtime / solver
- **"Nonlinear system solver failed at time t"** — a discontinuity (sqrt/abs of a negative),
  division by ~0, or a too-stiff switch. Regularize the offending expression or add `noEvent`.
- **Chattering (many events)** — a comparator without hysteresis. Add `Logical.Hysteresis`
  or widen the regularization `eps`. `-abortSlowSimulation` will catch it; `-mei` bounds it.
- **Assertion terminated** — a physical bound (negative chamber volume, joint limit). The
  assertion message names the variable; check initial positions and stroke limits.

## Overrides
- **Override silently ignored** — the parameter is structural (array size, connector count),
  `final`, `protected`, `annotation(Evaluate=true)`, or has a non-constant binding. Override
  the independent parameter it's derived from, or remove the `final`/`Evaluate`.
- **Override changes the wrong thing** — you overrode a dependent parameter. Follow the
  dependency chain to the root parameter.

## Results
- **Variable missing from results** — it's aliased, `protected`, or optimized away. Expose it
  as a top-level `Real` with an equation, or `Real x = component.var;`.
- **Values look stale** — you read the wrong `tag`'s result file (each tag has its own dir).
  Confirm the `result_file` path matches the run you intended.

## Method
1. Read the **first** diagnostic. Later errors are usually fallout.
2. Apply the smallest targeted fix; re-check.
3. Never silence an error by changing physics (deleting a load, removing a constraint).
4. After 4 attempts on the same error, stop and report error + attempts + hypothesis.

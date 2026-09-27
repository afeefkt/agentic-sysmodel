# PID tuning and stability-margin procedure

## The loop-cut analysis model (the reliable way to get GM/PM)
`openmodelica_frequency_analysis` margins are only meaningful for the **open loop** L(s).
To get L(s):

1. Make an analysis model with the controller **in series with the plant**, negative
   feedback broken open:
   - `input Real u;` = the error signal entering the controller (or the actuator command).
   - `output Real y;` = the fed-back measurement.
2. `openmodelica_linearize(file, model, t_lin=<settled time>)` on this model.
3. `openmodelica_frequency_analysis(lin_file, input="u", output="y")`.

This returns gain/phase crossover, gain margin, phase margin, bandwidth. If you instead
linearize the **closed loop**, the "margins" are meaningless — a common mistake.

## PID gains from a target crossover ω_c
Given an identified plant crossover ω_c (target):
- Proportional band: start `k = 1/(plant DC gain)` scaled toward ω_c.
- Integral: `Ti ≈ 3..5 / ω_c` (larger Ti = less aggressive integral).
- Derivative (only if phase lead is needed): `Td ≈ Ti / (5..20)`, always filtered via `Nd`.

Iterate: linearize → read GM/PM → adjust → re-check. Target PM ≥ 45°, GM ≥ 6 dB.

## Anti-windup
- Use `LimPID` with `yMax`/`yMin` (the actuator limits) and `Ni` for back-calculation.
- If using `PI` (unbounded), add a `Nonlinear.Limiter` and feed the limited/unlimited
  difference back into the integrator (back-calculation anti-windup).
- Always compare the controller output against the limited command to detect windup.

## State machine sequencing (doors/locks/retract)
- One `inner StateGraphRoot` per model.
- `InitialStep` → `Transition` (with `condition=`) → `Step` …; use `TransitionWithSignal`
  and `StepWithSignal` when a state must output an actuator command.
- Timeouts: `Transition(condition = time - step.t_entry >= 2.0)` or a `Logical.Timer`.
- Keep sequencing logic in `Controls/`; never mix it into plant equations.

## Metrics to record per case
`openmodelica_measure` gives rise_time, overshoot_pct, settling_time (band 2 %),
steady_state_error (needs `setpoint`), peak_time, max_rate, rms. Compare across cases with
`openmodelica_compare_cases(result_files, variables, metrics)`.

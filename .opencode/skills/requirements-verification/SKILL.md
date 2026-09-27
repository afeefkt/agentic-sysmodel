---
name: requirements-verification
description: Use when writing requirements.yaml, defining verification cases (nominal/edge), evaluating simulation results against requirements, tuning designs against specs, or writing the verification report.
---

# Requirements → simulation evidence

## requirements.yaml schema
```yaml
system: Nose landing gear retraction
references:
  - id: SRC-1
    text: "L-39NG NLG actuator: 220 mm stroke, 21 MPa working pressure (public data)"
requirements:
  - id: REQ-01
    title: Retraction time
    statement: The NLG shall retract from down-locked to up-locked within 8 s.
    rationale: Operational limit after take-off. ASSUMED value.
    source: ASSUMED
    metric: gearAngle
    criterion: {type: time_to_reach, var: gearAngle, threshold: 1.50, direction: rising, max_time: 8.0}
    verification: {method: simulation, cases: [nominal, cold_fluid, degraded_pump]}
    priority: must
  - id: REQ-02
    title: Pressure ceiling
    statement: System pressure shall not exceed 21 MPa.
    source: SRC-1
    metric: p_max_obs
    criterion: {type: bounds, var: actuator.p_A, lo: 0, hi: 21.0e6}
    verification: {method: simulation, cases: [nominal, cold_fluid, degraded_pump, max_aero]}
    priority: must
cases:
  nominal:       {overrides: {}, stop_time: 12}
  cold_fluid:    {overrides: {nu: 5.0e-4}, stop_time: 20, note: "-40 degC viscosity, ASSUMED/SOURCED"}
  degraded_pump: {overrides: {Q_max: 7.0e-5}, stop_time: 20, note: "-30 % flow"}
  max_aero:      {overrides: {v_air: 80}, stop_time: 12}
```

## Mapping criteria to tools
| criterion.type | Tool |
|---|---|
| `bounds` | `openmodelica_verify` with `{"type":"bounds","var","lo","hi","after"}` |
| `final` | `openmodelica_verify` with `{"type":"final","var","expected","rtol"}` |
| `value_at` | `openmodelica_verify` with `{"type":"value_at","var","t","expected"}` |
| `time_to_reach` | `openmodelica_time_to_reach`, then compare `time <= max_time` yourself and state it |
| `overshoot` | `openmodelica_measure` metric `overshoot_pct` (with `setpoint`, `t_start` = step time) ≤ limit |
| `settling_time` | `openmodelica_measure` metric `settling_time` (`band`, e.g. 0.02) ≤ limit. `None` = not settled = FAIL |
| `rate` | `openmodelica_measure` metric `max_rate` ≤ limit |
| `margin` | `openmodelica_linearize` of the loop-cut model, then `openmodelica_frequency_analysis`, and check `gain_margin_db`/`phase_margin_deg` ≥ limit (`None` gain margin = infinite = PASS) |

## Good requirement checklist
- One "shall" per requirement. It must be measurable, with SI units and a verification method.
- `metric` names a variable the model exposes. If it's missing, ask the modeler to expose it; don't estimate it.
- Edge cases are explicit parameter overrides, not prose.
- Margin: report `margin = (limit - measured)/limit` for bounds.

## Verification report format
```
# Verification report — <Project> — <model>
Design point: {...parameters...}
| REQ | Case | Criterion | Measured | Margin | Result | Evidence |
|-----|------|-----------|----------|--------|--------|----------|
Sanity checks: ...
Verdict: VERIFIED / NOT VERIFIED — <reason>
```

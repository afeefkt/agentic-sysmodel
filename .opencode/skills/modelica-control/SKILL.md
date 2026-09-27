---
name: modelica-control
description: Use when designing or modeling controllers, PID/LimPID, anti-windup, feed-forward, limiters, filters, sensors, discrete/sampled control, state machines and sequencing logic (e.g. landing gear door/lock/retract sequence), linearization, loop gain, stability margins, Bode analysis in Modelica/OpenModelica.
---

# Control design in Modelica (MSL 4.x)

## Component-first
- Build controllers from MSL blocks (`LimPID`, `Limiter`, `SlewRateLimiter`, `Feedback`, `Add`, `Gain`, StateGraph) connected with `connect()`, all with Placements (see `modelica-diagram-layout`). Signal lines use `color={0,0,127}`.
- Templates: `Modelica.Blocks.Examples.PID_Controller`, `Modelica.Electrical.Machines.Examples.ControlledDCDrives.SpeedControlledDCPM` (cascaded speed/current loop), `Modelica.StateGraph.Examples.*` (sequencing).
- Motor control: see `modelica-electrical-drives` (ToDQ, FromDQ, DQCurrentController).
- A custom `block` is acceptable for algorithms MSL doesn't have (VSD transform, observers, special modulators). Put it in `Controls/`, with an Icon and connector Placements.
- Catalogs: `knowledge/msl/Blocks.md`, `StateGraph.md`, `Clocked.md`.

Check exact parameters with `openmodelica_describe_class` before use. Paths are relative to `Modelica.Blocks.` unless given in full.

## Building blocks
| Need | Class | Notes |
|---|---|---|
| PID with anti-windup | `Continuous.LimPID` | `controllerType`, `k`, `Ti`, `Td`, `yMax`, `yMin`, `Ni` (anti-windup), `Nd` (D filter), `initType` |
| Simple PI | `Continuous.PI` | no limit, so add a Limiter with anti-windup yourself |
| Saturation | `Nonlinear.Limiter` | `uMax`, `uMin` |
| Rate limit | `Nonlinear.SlewRateLimiter` | `Rising`, `Falling`, `Td` |
| Sensor lag / filter | `Continuous.FirstOrder`, `Continuous.Filter` | `T`, or `filterType`/`order`/`f_cut` |
| Sampling | `Discrete.Sampler`, `Discrete.ZeroOrderHold` | `samplePeriod` |
| Setpoints | `Sources.Step`, `Sources.Ramp`, `Sources.TimeTable`, `Sources.KinematicPTP` | smooth reference profiles |
| Hysteresis switch | `Logical.Hysteresis` | `uLow`, `uHigh` |
| Logic | `Logical.And/Or/Not/Switch/Timer`, `MathBoolean.*` | for interlocks |
| State machine | `Modelica.StateGraph.InitialStep/Step/Transition/TransitionWithSignal`, needs `inner Modelica.StateGraph.StateGraphRoot stateGraphRoot` | sequencing with timeouts |
| Sensors (mech) | `Modelica.Mechanics.Rotational.Sensors.AngleSensor`, `Translational.Sensors.PositionSensor`, `MultiBody.Sensors.*` | bridge physics → signals |
| Actuation (mech) | `Rotational.Sources.Torque`, `Translational.Sources.Force` | signal → physics |

## Interface pattern (keeps plant and control separate)
```
plant sensors ──> Controls.<Controller> ──> actuator command ──> plant
```
Put controllers in a `Controls` sub-package with `RealInput`/`RealOutput` connectors. The top-level model only instantiates and connects them.

## Linearization for loop analysis
- `openmodelica_linearize` needs **top-level** `input Real ...` / `output Real ...`. Make a dedicated analysis model:
  - **plant only**: input = actuator command, output = measurement. Gives the plant poles and DC gain.
  - **loop cut** (for margins): the controller in series with the plant, input = the error signal entering the controller, output = the measurement. This is L(s) for negative feedback, and GM/PM come from this path.
- Linearize at several operating points: `t_lin` (after it settles), or `overrides` of the load or position parameters.
- `openmodelica_frequency_analysis(lin_file, input, output)` → poles, stable, GM, PM, crossover, bandwidth, and optionally a Bode PNG.

## Design rules of thumb
- Crossover ω_c: well below actuator/sensor bandwidth (÷3–5) and well below the sampling rate (ω_s/ω_c > 10–20).
- PM ≥ 45° gives an overshoot of roughly ≤ 20 %. GM ≥ 6 dB.
- Ti around 3–5 / ω_c. Keep derivative action filtered (`Nd` 5–20).
- Known disturbances (gravity, aero moment): add a feed-forward term so the integrator doesn't carry them.
- When the actuator saturates (the pressure relief acts as a force limit), check windup: compare `LimPID` output with the limited command.

## Gotchas
| Symptom | Cause | Fix |
|---|---|---|
| Algebraic loop / nonlinear system at every step | Direct feedthrough controller → plant → sensor with no dynamics | Add a sensor lag or D filter, or use a discrete controller with delay |
| Chattering, thousands of events | Comparator without hysteresis | `Logical.Hysteresis` |
| Huge overshoot after saturation | Integrator windup | `LimPID` with `Ni`, or back-calculation |
| linearize fails: no inputs/outputs | Inputs are inside sub-components | Declare top-level `input`/`output` in the analysis model |
| Margins look absurd | Linearized the closed loop, not L(s) | Cut the loop and linearize the open path |
| StateGraph error: missing root | No `stateGraphRoot` | Add `inner Modelica.StateGraph.StateGraphRoot stateGraphRoot;` |
| Discrete controller acts too early or late | Sampler phase or initial value | Set `startTime`, and initialize discrete states |

## Verification metrics (openmodelica_measure)
rise_time, overshoot_pct, settling_time (band 2 %), steady_state_error (setpoint), max_rate (actuator rate usage), rms (command effort). Compare across cases with `openmodelica_compare_cases`.

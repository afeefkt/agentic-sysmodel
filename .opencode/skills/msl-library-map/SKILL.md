---
name: msl-library-map
description: Use when choosing which Modelica Standard Library (MSL 4.1) packages/components to use for a system — architecture decisions, decomposing a system into physical domains, finding the right base components and the example model to start from (mechanics, multibody, electrical, machines, drives, power electronics, polyphase, thermal, fluid, control, state machines).
---

# MSL 4.1 library map: domain → package → components → example to copy

**Rule:** build from these components with `connect()`. Before writing any custom component, run `openmodelica_search_library` and look at the domain catalog in `knowledge/msl/<Domain>.md`.

| Domain | Package | Key components | Start from example |
|---|---|---|---|
| 1-D rotation | `Modelica.Mechanics.Rotational` | `Components.Inertia/Spring/Damper/IdealGear/Clutch/Brake`, `Sources.Torque/Speed/Position/TorqueStep/QuadraticSpeedDependentTorque`, `Sensors.SpeedSensor/AngleSensor/TorqueSensor` | `Rotational.Examples.First` |
| 1-D translation | `Modelica.Mechanics.Translational` | `Components.Mass/Spring/Damper/SpringDamper/MassWithStopAndFriction/ElastoGap`, `Sources.Force/Position/Speed`, `Sensors.PositionSensor/ForceSensor` | `Translational.Examples.SignConvention`, `.Oscillator` |
| 3-D mechanisms | `Modelica.Mechanics.MultiBody` | `World`, `Parts.Body/BodyShape/FixedTranslation/Fixed`, `Joints.Revolute/Prismatic/RevolutePlanarLoopConstraint`, `Joints.Assemblies.JointRRR/JointRRP/JointSSP`, `Forces.WorldForce/Spring`, `Sensors.*` | `MultiBody.Examples.Elementary.Pendulum`, `.Loops.Engine1a` (slider-crank) |
| Electrical circuits | `Modelica.Electrical.Analog` | `Basic.Resistor/Capacitor/Inductor/Ground`, `Sources.ConstantVoltage/SignalVoltage`, `Sensors.CurrentSensor/VoltageSensor`, `Ideal.IdealClosingSwitch/IdealDiode` | `Analog.Examples.*` |
| Polyphase circuits | `Modelica.Electrical.Polyphase` | `Basic.Star/MultiStar/Resistor/Inductor`, `Sources.SineVoltage/SignalVoltage`, `Sensors.CurrentSensor` (m phases) | `Polyphase.Examples.*` |
| Electric machines (3-phase) | `Modelica.Electrical.Machines` | `BasicMachines.SynchronousMachines.SM_PermanentMagnet`, induction and DC machines, `Utilities.TerminalBox/MultiTerminalBox/ToDQ/FromDQ/DQCurrentController/VfController`, `Sensors.RotorDisplacementAngle/CurrentQuasiRMSSensor` | `Machines.Examples.SynchronousMachines.SMPM_Inverter`, `.SMPM_CurrentSource`, `Machines.Examples.ControlledDCDrives.SpeedControlledDCPM` |
| Machines, any phase count m | `Modelica.Magnetic.FundamentalWave` | `BasicMachines.SynchronousMachines.SM_PermanentMagnet` (param `m`, `Lmd`, `Lmq` → IPMSM saliency) | `FundamentalWave.Examples.BasicMachines.SynchronousMachines.SMPM_Inverter`, `.ComparisonPolyphase` |
| Power electronics | `Modelica.Electrical.PowerConverters` | `DCAC.Polyphase2Level`, `DCAC.SinglePhase2Level`, `DCAC.Control.PWM/SVPWM`, DCDC choppers, rectifiers | `PowerConverters.Examples.DCAC.PolyphaseTwoLevel` |
| Signals and control | `Modelica.Blocks` | `Continuous.LimPID/PI/FirstOrder/Filter`, `Nonlinear.Limiter/SlewRateLimiter`, `Sources.Step/Ramp/TimeTable/KinematicPTP`, `Math.*`, `Logical.Hysteresis/Switch` | `Blocks.Examples.PID_Controller` |
| Sequencing / state machines | `Modelica.StateGraph` | `InitialStep/Step/StepWithSignal/Transition/TransitionWithSignal/StateGraphRoot` | `StateGraph.Examples.*` |
| Sampled / clocked control | `Modelica.Clocked` | clocks, sample/hold, discrete-time blocks | `Clocked.Examples.*` |
| Thermal (lumped) | `Modelica.Thermal.HeatTransfer` | `Components.HeatCapacitor/ThermalConductor/Convection`, `Sources.FixedTemperature/PrescribedHeatFlow` | `HeatTransfer.Examples.*` |
| Thermo-fluid | `Modelica.Fluid` + `Modelica.Media` | pipes, pumps, valves, vessels (heavy: prefer a lumped custom model for hydraulic actuators, see modelica-hydraulic-actuator) | `Fluid.Examples.PumpingSystem`, `.HeatingSystem` |

## How to use it (sysarch and modeler)
1. Split the system into physical domains and their **interfaces** (flange, frame, pin/plug, fluid port, heat port, signal).
2. For each subsystem, choose the package from the table. Check the names with `openmodelica_search_library`.
3. `openmodelica_list_examples(<package>)`, then `openmodelica_get_class_source(<closest example>)`. Start from its components, parameters and **layout**.
4. Write custom components only for true gaps (e.g. a lumped hydraulic cylinder). Record in `architecture.md` which search showed the gap.
5. Full component catalogs, User's Guides and example lists: `knowledge/msl/<Domain>.md` (General, MultiBody, Rotational, Translational, ElectricalAnalog, Polyphase, Machines, FundamentalWave, PowerConverters, Blocks, StateGraph, Clocked, HeatTransfer, Fluid).

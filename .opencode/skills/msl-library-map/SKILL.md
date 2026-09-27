---
name: msl-library-map
description: Use when choosing which Modelica Standard Library (MSL 4.1) packages/components to use for a system — architecture decisions, decomposing a system into physical domains, finding the right base components and the example model to start from (mechanics, multibody, electrical, machines, drives, power electronics, polyphase, thermal, fluid, control, state machines, clocked). Also use before writing any custom component to search MSL for an existing one.
---

# MSL 4.1 library map: domain → package → components → example to copy

The single rule of this repo's modeling workflow: **build every model from MSL components wired with `connect()`; write a custom component only after `openmodelica_search_library` finds nothing suitable, and record that search in `architecture.md`.**

MSL version in use: **4.1.0** (based on Modelica Language Spec 3.6). Units live in `Modelica.Units.SI` — the old MSL 3.x name `Modelica.SIunits` is gone.

## The library-access workflow (do this before writing anything)

1. **Search** — `openmodelica_search_library("<need in words>")`, e.g. `"permanent magnet synchronous machine"`, `"hydraulic cylinder"`, `"prismatic joint"`, `"PID anti windup"`. The index covers names **and** descriptions.
2. **Confirm the class exists and read its parameters** — `openmodelica_describe_class("<full path>")`. Never instantiate a class you have not described this session; it returns parameters, components, connectors, and inherited parameters.
3. **Find a model to copy** — `openmodelica_list_examples("<package>")`, then `openmodelica_get_class_source("<closest example>")` to copy its component structure **and its Placement/Line layout**.
4. **Catalog** — full component lists and User's Guides per domain are in `knowledge/msl/<Domain>.md`.

Full detail: `references/library-access-workflow.md`, `references/example-models.md`, `references/msl-4.1-notes.md`. Sources: `references/sources.md`.

## Domain map

| Domain | Package | Key components | Start from example |
|---|---|---|---|
| 1-D rotation | `Modelica.Mechanics.Rotational` | `Components.Inertia/Spring/Damper/SpringDamper/IdealGear/LossyGear/IdealPlanetary/BearingFriction/Clutch/Brake`, `Sources.Torque/Speed/Position/TorqueStep/QuadraticSpeedDependentTorque`, `Sensors.AngleSensor/SpeedSensor/TorqueSensor` | `Rotational.Examples.First` |
| 1-D translation | `Modelica.Mechanics.Translational` | `Components.Mass/Spring/Damper/SpringDamper/ElastoGap/MassWithStopAndFriction`, `Sources.Force/Position/Speed`, `Sensors.PositionSensor/SpeedSensor/ForceSensor` | `Translational.Examples.Oscillator`, `.SignConvention` |
| 3-D mechanisms | `Modelica.Mechanics.MultiBody` | `World`, `Parts.Body/BodyShape/BodyBox/BodyCylinder/Fixed/FixedTranslation/PointMass`, `Joints.Revolute/Prismatic/Spherical/Universal/Cylindrical/FreeMotion/RevolutePlanarLoopConstraint`, `Joints.Assemblies.JointRRR/JointRRP/JointSSR/JointSSP/JointUSR/JointUSP/JointUPS`, `Forces.WorldForce/Torque/Force/Spring/Damper/LineForceWithMass`, `Sensors.AbsoluteSensor/RelativeSensor/Distance/CutForce` | `MultiBody.Examples.Elementary.DoublePendulum`, `.Loops.PlanarFourbar` (loop), `.Loops.EngineV6_analytic` (JointRRP) |
| Electrical circuits | `Modelica.Electrical.Analog` | `Basic.Ground/Resistor/Capacitor/Inductor/VCV/VCC`, `Ideal.IdealDiode/IdealClosingSwitch`, `Sources.ConstantVoltage/SignalVoltage/SineVoltage`, `Sensors.VoltageSensor/CurrentSensor/PowerSensor` | `Analog.Examples.CauerLowPassAnalog` |
| Polyphase circuits | `Modelica.Electrical.Polyphase` | `Basic.Star/Delta/MultiStar/MultiDelta/Resistor/Inductor/MutualInductor`, `Functions.symmetricOrientation`, `Sources.SineVoltage`, `Sensors.CurrentSensor/PowerSensor/AronSensor` | `Polyphase.Examples.Rectifier` |
| Electric machines (3-phase) | `Modelica.Electrical.Machines` | `BasicMachines.SynchronousMachines.SM_PermanentMagnet/SM_ElectricalExcited/SM_ReluctanceRotor`, `InductionMachines.IM_SquirrelCage/IM_SlipRing`, `DCMachines.DC_PermanentMagnet/DC_ElectricalExcited/DC_SeriesExcited`, `Utilities.TerminalBox/MultiTerminalBox/ToDQ/FromDQ/DQCurrentController/VfController`, `Sensors.RotorDisplacementAngle/CurrentQuasiRMSSensor` | `Machines.Examples.SynchronousMachines.SMPM_VoltageSource` (FOC), `.SMPM_CurrentSource`, `.InductionMachines.IMC_DOL`, `.ControlledDCDrives.SpeedControlledDCPM` |
| Machines, any phase count m | `Modelica.Magnetic.FundamentalWave` | `BasicMachines.SynchronousMachines.SM_PermanentMagnet` (params `m`, `Lmd`, `Lmq`, `Lssigma` → IPMSM saliency), `SymmetricPolyphaseWinding`, `SaliencyCageWinding`, `RotorSaliencyAirGap` | `FundamentalWave.Examples.BasicMachines.SynchronousMachines.SMPM_Inverter`, `.ComparisonPolyphase` |
| Power electronics | `Modelica.Electrical.PowerConverters` | `DCAC.Polyphase2Level`, `DCAC.SinglePhase2Level`, `DCAC.Control.PWM/SVPWM/IntersectivePWM`, `ACDC.DiodeBridge2mPulse/ThyristorBridge2mPulse`, `DCDC.HBridge/ChopperStepDown/ChopperStepUp`, `ACAC.SinglePhaseTriac` | `PowerConverters.Examples.DCAC.PolyphaseTwoLevel.ThreePhaseTwoLevel_PWM` |
| Signals and control | `Modelica.Blocks` | `Continuous.LimPID/PI/Integrator/TransferFunction/StateSpace/FirstOrder/Filter`, `Nonlinear.Limiter/SlewRateLimiter/DeadZone`, `Sources.Constant/Step/Ramp/Sine/CombiTimeTable`, `Math.Gain/Sum/Add/Product/RealFFT`, `Logical.And/Or/Switch/Hysteresis/Timer/RSFlipFlop`, `Discrete.Sampler/ZeroOrderHold/UnitDelay` | `Blocks.Examples.PID_Controller` |
| Sequencing / state machines | `Modelica.StateGraph` | `InitialStep/Step/StepWithSignal/Transition/TransitionWithSignal/Parallel/Alternative/StateGraphRoot` | `StateGraph.Examples.FirstExample`, `.ControlledTanks` |
| Sampled / clocked control | `Modelica.Clocked` | `ClockSignals.Clocks.PeriodicRealClock/PeriodicExactClock/EventClock`, `RealSignals.Sampler.Sample/Hold/SubSample/SuperSample`, `RealSignals.Periodic.PI/TransferFunction/StateSpace` | `Clocked.Examples.SimpleControlledDrive.ClockedWithDiscreteController` |
| Thermal (lumped) | `Modelica.Thermal.HeatTransfer` | `Components.HeatCapacitor/ThermalConductor/ThermalResistor/Convection/BodyRadiation`, `Sources.FixedTemperature/PrescribedTemperature/FixedHeatFlow`, `Sensors.TemperatureSensor/HeatFlowSensor` | `HeatTransfer.Examples.Motor` |
| Thermo-fluid | `Modelica.Fluid` + `Modelica.Media` | `System`, `Vessels.ClosedVolume/OpenTank`, `Pipes.StaticPipe/DynamicPipe`, `Machines.Pump/ControlledPump`, `Valves.ValveIncompressible/ValveCompressible`, `Sources.Boundary_pT/Boundary_ph/MassFlowSource_T`, `Sensors.MassFlowRate/Pressure/Temperature` | `Fluid.Examples.HeatingSystem`, `.PumpingSystem` |

All paths are relative to the package in the left column's second column.

## Choosing a package: the decision points

1. **Split the system into physical domains** and their interfaces (flange, frame, pin/plug, fluid port, heat port, signal). An interface is where two packages meet.
2. **For each subsystem**, pick the package above. When in doubt, search, then describe.
3. **Prefer 1-D over 3-D** when the geometry collapses to an axis (a rotary drivetrain → `Rotational`; a piston → `Translational`). Use `MultiBody` only when 3-D kinematics/loops actually matter.
4. **Machines**: 3-phase → `Machines`; any phase count m (dual three-phase, 6-phase) → `FundamentalWave`. Both are parameter-compatible for the PMSM.
5. **Fluid**: use `Modelica.Fluid`+`Media` only when compressibility, two-phase flow, reverse flow, or multi-substance thermodynamics matter. For a stiff/incompressible hydraulic actuator dominated by inertia, use a lumped custom component instead (see `modelica-hydraulic-actuator`).
6. **Write custom components only for true gaps** (e.g. a lumped hydraulic cylinder). Record the search that showed the gap in `architecture.md`.

## Gotchas that cross all domains

- MSL 4.x: `import SI = Modelica.Units.SI;` — never `Modelica.SIunits`.
- `describe_class` reports **inherited** parameters too (e.g. the machine's phase count `m`, or `Lssigma` declared in the base `Machine`). Read them before assuming a parameter doesn't exist.
- The same component name can exist in both `Machines` and `FundamentalWave` — check which package you imported.
- Copy the layout, not just the code, from the example (`get_class_source` includes Placements and Lines).

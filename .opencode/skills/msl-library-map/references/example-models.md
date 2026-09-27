# Example models to copy from (verified full paths, MSL 4.1.0)

Each is a validated, runnable model. Open it with `openmodelica_get_class_source` and
copy its **component structure and its diagram layout**. Grouped by what it teaches.

## Mechanisms / MultiBody
- `Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum` — two bodies + revolute joints, the minimal skeleton (inner World, Bodies, Joints).
- `Modelica.Mechanics.MultiBody.Examples.Elementary.Pendulum` — one hinge + one body.
- `Modelica.Mechanics.MultiBody.Examples.Loops.PlanarFourbar` — planar closed loop, uses `RevolutePlanarLoopConstraint`.
- `Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic` — analytic loop closure with `Joints.Assemblies.JointRRP`.

## 1-D mechanics
- `Modelica.Mechanics.Rotational.Examples.First` — inertia + ideal gear + source, the minimal rotary chain.
- `Modelica.Mechanics.Translational.Examples.Oscillator` — mass-spring-damper.
- `Modelica.Mechanics.Translational.Examples.SignConvention` — connector sign conventions.

## Electrical
- `Modelica.Electrical.Analog.Examples.CauerLowPassAnalog` — passive circuit with Ground.
- `Modelica.Electrical.Polyphase.Examples.Rectifier` — m-phase wiring and sensors.

## Machines & drives
- `Modelica.Electrical.Machines.Examples.SynchronousMachines.SMPM_VoltageSource` — field-oriented control (FOC) template.
- `Modelica.Electrical.Machines.Examples.SynchronousMachines.SMPM_CurrentSource` — current-fed PMSM (simplest control plant).
- `Modelica.Electrical.Machines.Examples.InductionMachines.IMC_DOL` — induction machine, direct-on-line.
- `Modelica.Electrical.Machines.Examples.ControlledDCDrives.SpeedControlledDCPM` — cascaded speed/current loop.
- `Modelica.Magnetic.FundamentalWave.Examples.BasicMachines.SynchronousMachines.SMPM_Inverter` — m-phase PMSM on an inverter.
- `Modelica.Magnetic.FundamentalWave.Examples.BasicMachines.SynchronousMachines.ComparisonPolyphase` — m-phase comparison.

## Power electronics
- `Modelica.Electrical.PowerConverters.Examples.DCAC.PolyphaseTwoLevel.ThreePhaseTwoLevel_PWM` — inverter + PWM.

## Control / logic
- `Modelica.Blocks.Examples.PID_Controller` — LimPID wiring and anti-windup.
- `Modelica.StateGraph.Examples.FirstExample` — state machine skeleton (InitialStep, Step, Transition, StateGraphRoot).
- `Modelica.StateGraph.Examples.ControlledTanks` — state machine with signal outputs.
- `Modelica.Clocked.Examples.SimpleControlledDrive.ClockedWithDiscreteController` — sampled/clocked control.

## Thermal / fluid
- `Modelica.Thermal.HeatTransfer.Examples.Motor` — lumped thermal network.
- `Modelica.Fluid.Examples.HeatingSystem` — closed fluid circuit.
- `Modelica.Fluid.Examples.PumpingSystem` — pump + pipes.

## How to use one
1. `get_class_source` the closest example.
2. Note which MSL components it instantiates and how it wires them (`connect`).
3. Note its Placements/Lines — reuse the layout rhythm (see `modelica-diagram-layout`).
4. Replace its parts with your subsystem's parts, keeping the same connector types.
5. Keep its initialization and solver-friendly details (start values, `initType`).

within ServoArm;
package Controls
  import SI = Modelica.Units.SI;

  block ReferenceGen
    "Smooth 0 -> angle_ref position reference (slew-rate and acceleration limited; no raw step)"
    parameter SI.Angle angle_ref = 1.5707963 "Commanded arm angle (rad, 90 deg)";
    parameter SI.Time t_cmd = 0.1 "Move command time (s)";
    parameter SI.AngularVelocity velLimit = 2.2 "Maximum reference angular rate (rad/s)";
    parameter SI.AngularAcceleration accLimit = 20 "Maximum reference angular acceleration (rad/s2)";

    Modelica.Blocks.Interfaces.RealOutput phi_ref "Reference arm angle (rad)"
      annotation (Placement(transformation(extent = {{100, -10}, {120, 10}}),
        iconTransformation(extent = {{100, -10}, {120, 10}})));

    Modelica.Blocks.Sources.Step step(height = angle_ref, startTime = t_cmd)
      annotation (Placement(transformation(extent = {{-80, -10}, {-60, 10}})));
    Modelica.Blocks.Nonlinear.SlewRateLimiter vel(
      Rising = velLimit,
      Falling = -velLimit,
      Td = 0.001)
      annotation (Placement(transformation(extent = {{-40, -10}, {-20, 10}})));
    Modelica.Blocks.Nonlinear.SlewRateLimiter acc(
      Rising = accLimit,
      Falling = -accLimit,
      Td = 0.001)
      annotation (Placement(transformation(extent = {{0, -10}, {20, 10}})));
  equation
    connect(step.y, vel.u)
      annotation (Line(points = {{-59, 0}, {-42, 0}}, color = {0, 0, 127}));
    connect(vel.y, acc.u)
      annotation (Line(points = {{-19, 0}, {-2, 0}}, color = {0, 0, 127}));
    connect(acc.y, phi_ref)
      annotation (Line(points = {{21, 0}, {110, 0}}, color = {0, 0, 127}));
    annotation (
      Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127},
          fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
        Line(points = {{-80, -60}, {-30, -60}, {30, 60}, {80, 60}}, color = {0, 0, 127}),
        Text(extent = {{-90, -90}, {90, -60}}, textString = "REF", textColor = {0, 0, 127})}),
      Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}})));
  end ReferenceGen;

  block PositionController
    "PID position controller with anti-windup, output limited to +/-Vsupply"
    parameter Real kp = 60 "Proportional gain (V/rad)" annotation(Evaluate = false);
    parameter SI.Time Ti = 0.08 "Integral time constant (s)" annotation(Evaluate = false);
    parameter SI.Time Td = 0.008 "Derivative time constant (s)" annotation(Evaluate = false);
    parameter Real Nd = 10 "Derivative filter coefficient";
    parameter SI.Voltage Vsupply = 24 "Supply voltage / output saturation limit (V)" annotation(Evaluate = false);

    Modelica.Blocks.Interfaces.RealInput phi_ref "Reference arm angle (rad)"
      annotation (Placement(transformation(extent = {{-140, 30}, {-100, 70}}),
        iconTransformation(extent = {{-140, 30}, {-100, 70}})));
    Modelica.Blocks.Interfaces.RealInput phi_meas "Measured arm angle (rad)"
      annotation (Placement(transformation(extent = {{-140, -70}, {-100, -30}}),
        iconTransformation(extent = {{-140, -70}, {-100, -30}})));
    Modelica.Blocks.Interfaces.RealOutput v "Motor voltage command (V)"
      annotation (Placement(transformation(extent = {{100, -10}, {120, 10}}),
        iconTransformation(extent = {{100, -10}, {120, 10}})));

    Modelica.Blocks.Continuous.LimPID pid(
      controllerType = Modelica.Blocks.Types.SimpleController.PID,
      k = kp,
      Ti = Ti,
      Td = Td,
      Nd = Nd,
      wd = 1,
      yMax = Vsupply,
      yMin = -Vsupply,
      initType = Modelica.Blocks.Types.Init.NoInit)
      annotation (Placement(transformation(extent = {{-30, -10}, {-10, 10}})));
  equation
    connect(phi_ref, pid.u_s)
      annotation (Line(points = {{-120, 50}, {-66, 50}, {-66, 6}, {-32, 6}},
        color = {0, 0, 127}));
    connect(phi_meas, pid.u_m)
      annotation (Line(points = {{-120, -50}, {-66, -50}, {-66, -6}, {-32, -6}},
        color = {0, 0, 127}));
    connect(pid.y, v)
      annotation (Line(points = {{-9, 0}, {110, 0}}, color = {0, 0, 127}));
    annotation (
      Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127},
          fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
        Text(extent = {{-80, 30}, {80, -40}}, textString = "PI", textColor = {0, 0, 127})}),
      Diagram(coordinateSystem(extent = {{-120, -80}, {100, 80}})));
  end PositionController;

  model LoopCut
    "REQ-06 loop-cut: u = position error into the PI controller, y = arm angle;
     arm initialised at the 90 deg operating point (phi=pi/2, w=0) so linearize()
     trims at 90 deg; v_bias keeps the operating point physically consistent"
    import SI = Modelica.Units.SI;
    parameter SI.Mass payload_m = 0.20 "Payload point mass";
    parameter SI.Voltage Vsupply = 24.0 "Supply voltage" annotation(Evaluate = false);
    parameter SI.Resistance R_a = 2.0 "Armature resistance";
    parameter SI.Inductance L_a = 1.0e-3 "Armature inductance";
    parameter SI.ElectricalTorqueConstant k_t = 0.05 "Torque/EMF constant";
    parameter SI.Inertia J_r = 5.0e-6 "Rotor inertia";
    parameter Real N = 50 "Gear ratio";
    parameter Real kp = 60 "Proportional gain (V/rad)" annotation(Evaluate = false);
    parameter SI.Time Ti = 0.08 "Integral time constant (s)" annotation(Evaluate = false);
    parameter SI.Time Td = 0.008 "Derivative time constant (s)" annotation(Evaluate = false);
    parameter Real Nd = 10 "Derivative filter coefficient";
    parameter SI.Voltage v_bias = 0.697 "Holding voltage that trims the arm at ~90 deg (V)";

    Modelica.Blocks.Interfaces.RealInput u "Loop-cut input: position error (rad)"
      annotation (Placement(transformation(extent = {{-160, 30}, {-120, 70}}),
        iconTransformation(extent = {{-160, 30}, {-120, 70}})));
    Modelica.Blocks.Interfaces.RealOutput y "Loop-cut output: arm angle (rad)"
      annotation (Placement(transformation(extent = {{100, -10}, {140, 10}}),
        iconTransformation(extent = {{100, -10}, {140, 10}})));

    ServoArm.Plant plant(
      payload_m = payload_m,
      R_a = R_a,
      L_a = L_a,
      k_t = k_t,
      J_r = J_r,
      N = N)
      annotation (Placement(transformation(extent = {{40, -60}, {100, -20}})));

    Modelica.Blocks.Continuous.LimPID pid(
      controllerType = Modelica.Blocks.Types.SimpleController.PID,
      k = kp,
      Ti = Ti,
      Td = Td,
      Nd = Nd,
      wd = 1,
      yMax = Vsupply,
      yMin = -Vsupply,
      initType = Modelica.Blocks.Types.Init.NoInit)
      annotation (Placement(transformation(extent = {{-50, -10}, {-30, 10}})));
    Modelica.Blocks.Sources.Constant bias(k = v_bias)
      annotation (Placement(transformation(extent = {{-80, -80}, {-60, -60}})));
    Modelica.Blocks.Sources.Constant zero(k = 0)
      annotation (Placement(transformation(extent = {{-110, -30}, {-90, -10}})));
    Modelica.Blocks.Math.Add add
      annotation (Placement(transformation(extent = {{-10, -40}, {10, -20}})));
  initial equation
    plant.revolute.phi = 1.5707963 "Initialize arm at the 90 deg operating point";
    plant.revolute.w = 0;
  equation
    connect(u, pid.u_s)
      annotation (Line(points = {{-140, 50}, {-80, 50}, {-80, 6}, {-52, 6}},
        color = {0, 0, 127}));
    connect(zero.y, pid.u_m)
      annotation (Line(points = {{-89, -20}, {-80, -20}, {-80, -6}, {-52, -6}},
        color = {0, 0, 127}));
    connect(pid.y, add.u1)
      annotation (Line(points = {{-29, 0}, {-20, 0}, {-20, -24}, {-12, -24}},
        color = {0, 0, 127}));
    connect(bias.y, add.u2)
      annotation (Line(points = {{-59, -70}, {-20, -70}, {-20, -36}, {-12, -36}},
        color = {0, 0, 127}));
    connect(add.y, plant.v)
      annotation (Line(points = {{11, -30}, {20, -30}, {20, -44}, {40, -44}},
        color = {0, 0, 127}));
    connect(plant.phi, y)
      annotation (Line(points = {{100, -24}, {110, -24}, {110, 0}, {120, 0}},
        color = {0, 0, 127}));
    annotation (
      Icon(coordinateSystem(extent = {{-140, -100}, {140, 100}}), graphics = {
        Rectangle(extent = {{-140, 100}, {140, -100}}, lineColor = {0, 0, 127},
          fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
        Text(extent = {{-120, 30}, {120, -30}}, textString = "LOOPCUT", textColor = {0, 0, 127})}),
      Diagram(coordinateSystem(extent = {{-160, -100}, {140, 80}})),
      experiment(StopTime = 4));
  end LoopCut;

  annotation (uses(Modelica(version = "4.1.0")));
end Controls;

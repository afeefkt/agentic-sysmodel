within ServoArm;
model System
  "Closed-loop ServoArm: smooth reference + PI position controller + plant"
  import SI = Modelica.Units.SI;

  // ---- Physical / design parameters (top-level, match requirements.yaml cases) ----
  parameter SI.Mass payload_m = 0.20 "Payload point mass";
  parameter SI.Voltage Vsupply = 24.0 "Supply voltage (controller output limit)"
    annotation(Evaluate = false);
  parameter SI.Resistance R_a = 2.0 "Armature resistance";
  parameter SI.Inductance L_a = 1.0e-3 "Armature inductance";
  parameter SI.ElectricalTorqueConstant k_t = 0.05 "Torque/EMF constant";
  parameter SI.Inertia J_r = 5.0e-6 "Rotor inertia";
  parameter Real N = 50 "Gear ratio";

  // ---- Motion command ----
  parameter SI.Angle angle_ref = 1.5707963 "Commanded arm angle (rad, 90 deg)";
  parameter SI.Time t_cmd = 0.1 "Move command time (s)";

  // ---- Controller gains ----
  parameter Real kp = 60 "Proportional gain (V/rad)"
    annotation(Evaluate = false);
  parameter SI.Time Ti = 0.08 "Integral time constant (s)"
    annotation(Evaluate = false);
  parameter SI.Time Td = 0.008 "Derivative time constant (s)"
    annotation(Evaluate = false);
  parameter Real Nd = 10 "Derivative filter coefficient";

  // ---- Reference limits ----
  parameter SI.AngularVelocity velLimit = 2.2 "Max reference angular rate (rad/s)";
  parameter SI.AngularAcceleration accLimit = 20 "Max reference angular acceleration (rad/s2)" annotation(
    Placement(visible = false, transformation(origin = {nan, nan}, extent = {{nan, nan}, {nan, nan}})));

  ServoArm.Plant plant(
    payload_m = payload_m,
    R_a = R_a,
    L_a = L_a,
    k_t = k_t,
    J_r = J_r,
    N = N)
    annotation (Placement(transformation(origin = {20, -8}, extent = {{-10, -50}, {50, -10}})));

  ServoArm.Controls.ReferenceGen refGen(
    angle_ref = angle_ref,
    t_cmd = t_cmd,
    velLimit = velLimit,
    accLimit = accLimit)
    annotation (Placement(transformation(origin = {-16, -4}, extent = {{-80, 20}, {-60, 40}})));

  ServoArm.Controls.PositionController controller(
    kp = kp,
    Ti = Ti,
    Td = Td,
    Nd = Nd,
    Vsupply = Vsupply)
    annotation (Placement(transformation(origin = {-12, -16}, extent = {{-40, -10}, {-20, 10}})));

  Modelica.Blocks.Interfaces.RealOutput phi "Arm angle (rad)"
    annotation (Placement(transformation(origin = {0, 24}, extent = {{100, -10}, {120, 10}}),
      iconTransformation(extent = {{100, -10}, {120, 10}})));
  Modelica.Blocks.Interfaces.RealOutput i "Motor current (A)"
    annotation (Placement(transformation(origin = {2, -8}, extent = {{100, -50}, {120, -30}}),
      iconTransformation(extent = {{100, -50}, {120, -30}})));
  Modelica.Blocks.Interfaces.RealOutput v "Motor voltage command (V)"
    annotation (Placement(transformation(origin = {-110, 86}, extent = {{100, -90}, {120, -70}}),
      iconTransformation(extent = {{100, -90}, {120, -70}})));
equation
  connect(refGen.phi_ref, controller.phi_ref)
    annotation (Line(points = {{-75, 26}, {-54, 26}, {-54, -11}},
      color = {0, 0, 127}));
  connect(plant.phi, controller.phi_meas)
    annotation (Line(points = {{70, -29}, {70, 24}, {-54, 24}, {-54, -21}},
      color = {0, 0, 127}));
  connect(controller.v, plant.v)
    annotation (Line(points = {{-31, -16}, {-17.5, -16}, {-17.5, -52}, {10, -52}},
      color = {0, 0, 127}));
  connect(plant.phi, phi)
    annotation (Line(points = {{70, -29}, {70, 24}, {110, 24}},
      color = {0, 0, 127}));
  connect(plant.i, i)
    annotation (Line(points = {{70, -47}, {70, -48}, {112, -48}},
      color = {0, 0, 127}));
  connect(controller.v, v)
    annotation (Line(points = {{-31, -16}, {-7.5, -16}, {-7.5, 6}, {0, 6}},
      color = {0, 0, 127}));
  annotation (
    Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127},
        fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-90, 30}, {90, -30}}, textString = "System", textColor = {0, 0, 127})}),
    Diagram(coordinateSystem(extent = {{-100, -100}, {120, 60}})),
    experiment(StopTime = 4));
end System;

package Pendulum
  model SimplePendulum
    "Planar pendulum: point mass on a massless 1 m rod, hinged about the z-axis"
    import SI = Modelica.Units.SI;

    inner Modelica.Mechanics.MultiBody.World world
      "Inertial frame; default uniform gravity along -y"
      annotation (Placement(transformation(extent={{-80,-20},{-40,20}})));

    Modelica.Mechanics.MultiBody.Joints.Revolute revolute(
      n = {0, 0, 1},
      phi(start = 0.1, fixed = true))
      "Hinge about the z-axis; starts displaced by 0.1 rad"
      annotation (Placement(transformation(extent={{-20,-20},{0,20}})));

    Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod(r = {0, -1.0, 0})
      "Massless rod of length 1 m directed along -y"
      annotation (Placement(transformation(extent={{20,-20},{40,20}})));

    Modelica.Mechanics.MultiBody.Parts.Body body(
      m = 1,
      r_CM = {0, 0, 0},
      I_11 = 0,
      I_22 = 0,
      I_33 = 0,
      I_21 = 0,
      I_31 = 0,
      I_32 = 0)
      "Point mass of 1 kg at the rod end (zero inertia tensor)"
      annotation (Placement(transformation(extent={{60,-20},{100,20}})));

    Real angle "Angular displacement of the pendulum (revolute angle phi), in rad";

  equation
    angle = revolute.phi;
    connect(world.frame_b, revolute.frame_a) annotation (Line(
      points={{-40,0},{-20,0}},
      color={95,95,95},
      thickness=0.5));
    connect(revolute.frame_b, rod.frame_a) annotation (Line(
      points={{0,0},{20,0}},
      color={95,95,95},
      thickness=0.5));
    connect(rod.frame_b, body.frame_a) annotation (Line(
      points={{40,0},{60,0}},
      color={95,95,95},
      thickness=0.5));
  end SimplePendulum;

  model CompoundPendulum
    "Physical pendulum: aluminium rod (Ø20 mm x 500 mm) with CAD mass properties, hinged about the z-axis at its top end"
    import SI = Modelica.Units.SI;

    inner Modelica.Mechanics.MultiBody.World world
      "Inertial frame; default uniform gravity along -y"
      annotation (Placement(transformation(extent={{-80,-20},{-40,20}})));

    Modelica.Mechanics.MultiBody.Joints.Revolute revolute(
      n = {0, 0, 1},
      phi(start = 0.1, fixed = true))
      "Hinge about the z-axis at the rod top; starts displaced by 0.1 rad"
      annotation (Placement(transformation(extent={{-20,-20},{0,20}})));

    Modelica.Mechanics.MultiBody.Parts.BodyShape bodyShape(
      m = 0.4241150082346221,
      r = {0, -0.25, 0},
      r_CM = {0, -0.25, 0},
      I_11 = 0.008846332213427156,
      I_22 = 2.1205750411731233e-05,
      I_33 = 0.008846332213427146,
      I_21 = 0,
      I_31 = 0,
      I_32 = 0)
      "Aluminium rod (Ø20 mm x 500 mm), CoM 0.25 m below the pivot (r_CM from frame_a); inertia about the CoM (Iyy = axial, Ixx = Izz = transverse)"
      annotation (Placement(transformation(extent={{20,-20},{60,20}})));

    Real angle "Angular displacement of the pendulum (revolute angle phi), in rad";

  equation
    angle = revolute.phi;
    connect(world.frame_b, revolute.frame_a) annotation (Line(
      points={{-40,0},{-20,0}},
      color={95,95,95},
      thickness=0.5));
    connect(revolute.frame_b, bodyShape.frame_a) annotation (Line(
      points={{0,0},{20,0}},
      color={95,95,95},
      thickness=0.5));
  end CompoundPendulum;

  annotation (version = "1.0.0");
end Pendulum;

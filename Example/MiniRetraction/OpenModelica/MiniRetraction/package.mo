package MiniRetraction
  model Kinematics
    "Kinematics-only slider-crank loop: arm hinged at origin, actuator pinned to ground (0.3 m along +x) and to the arm 0.15 m below the hinge. Arm angle phi prescribed 0 -> pi/2; actuator length read out. No forces/masses/gravity."

    import SI = Modelica.Units.SI;
    import MB = Modelica.Mechanics.MultiBody;

    // ---- Design parameters (SI, top-level so the tuner can override) ----
    parameter SI.Length d_OA = 0.3 "Ground anchor A offset from hinge along +x (m)";
    parameter SI.Length r_OB = 0.15 "Arm attachment B offset from hinge along the arm (m)";
    parameter SI.Length armLen = 0.5 "Total arm length (m)";
    parameter SI.Angle phi_start = 0 "Initial arm angle (rad); 0 = hanging straight down";
    parameter SI.Angle phi_end = Modelica.Constants.pi/2 "Target arm angle (rad); horizontal";
    parameter SI.Time swing_time = 3 "Ramp duration of the swing (s)";

    // ---- Inertial frame (kinematics only -> gravity off) ----
    inner MB.World world(gravityType = MB.Types.GravityTypes.NoGravity)
      "Inertial frame; gravity disabled in this step"
      annotation(Placement(transformation(extent = {{-140,50},{-120,70}})));

    // ---- Arm chain: world -> hinge -> B -> tip ----
    MB.Joints.Revolute hinge(
      n = {0,0,1},
      useAxisFlange = true,
      phi(start = phi_start))
      "Hinge at origin O, rotation axis +z (driven)"
      annotation(Placement(transformation(extent = {{-100,50},{-80,70}})));

    MB.Parts.FixedTranslation linkOB(r = {0,-r_OB,0})
      "Massless link hinge -> attachment point B (0.15 m along -y)"
      annotation(Placement(transformation(extent = {{-60,50},{-40,70}})));

    MB.Parts.FixedTranslation linkBTip(r = {0,-(armLen - r_OB),0})
      "Massless link B -> arm tip (0.35 m along -y)"
      annotation(Placement(transformation(extent = {{-20,50},{0,70}})));

    // ---- Actuator chain: world -> A -> pinA -> slider -> pinB -> B ----
    MB.Parts.FixedTranslation linkOA(r = {d_OA,0,0})
      "Massless ground link hinge -> anchor A (0.3 m along +x)"
      annotation(Placement(transformation(extent = {{-100,-50},{-80,-30}})));

    MB.Joints.Revolute pinA(
      n = {0,0,1},
      phi(start = 0))
      "Actuator pin at A (free revolute)"
      annotation(Placement(transformation(extent = {{-60,-50},{-40,-30}})));

    MB.Joints.Prismatic slider(
      n = {-0.89442719,-0.44721360,0},
      s(start = 0.3354102))
      "Telescoping actuator (axis from A toward B at phi=0)"
      annotation(Placement(transformation(extent = {{-20,-50},{0,-30}})));

    MB.Joints.RevolutePlanarLoopConstraint pinB(n = {0,0,1})
      "Actuator pin at B (planar loop constraint to avoid over-constraint)"
      annotation(Placement(transformation(extent = {{20,-10},{40,10}})));

    // ---- Drive: ramp 0 -> pi/2 over swing_time onto the hinge axis ----
    Modelica.Blocks.Sources.Ramp phiRamp(
      height = phi_end - phi_start,
      duration = swing_time)
      "Prescribed arm-angle ramp"
      annotation(Placement(transformation(extent = {{-140,100},{-120,120}})));

    Modelica.Mechanics.Rotational.Sources.Position posSource
      "Rotational position source driving the hinge angle"
      annotation(Placement(transformation(extent = {{-100,100},{-80,120}})));

    // ---- Exposed metrics (read by the verifier) ----
    Real arm_phi = hinge.phi "Arm angle (rad); 0 = down, + toward +x";
    Real actuator_L = slider.s "Actuator length (m)";
    Real actuator_L_residual =
      actuator_L - sqrt(d_OA^2 + r_OB^2 - 2*d_OA*r_OB*sin(arm_phi))
      "Residual vs closed-form L = sqrt(0.1125 - 0.09*sin(phi)) (m)";
    Real actuator_stroke =
      sqrt(d_OA^2 + r_OB^2 - 2*d_OA*r_OB*sin(phi_start))
      - sqrt(d_OA^2 + r_OB^2 - 2*d_OA*r_OB*sin(phi_end))
      "Actuator stroke L(phi_start)-L(phi_end) (m)";

  equation
    // Arm chain
    connect(world.frame_b, hinge.frame_a)
      annotation(Line(points = {{-120,60},{-100,60}}, color = {95,95,95}, thickness = 0.5));
    connect(hinge.frame_b, linkOB.frame_a)
      annotation(Line(points = {{-80,60},{-60,60}}, color = {95,95,95}, thickness = 0.5));
    connect(linkOB.frame_b, pinB.frame_b)      // loop closes at B
      annotation(Line(points = {{-40,60},{-40,30},{40,30},{40,0}}, color = {95,95,95}, thickness = 0.5));
    connect(linkOB.frame_b, linkBTip.frame_a)  // arm continues to the tip
      annotation(Line(points = {{-40,60},{-20,60}}, color = {95,95,95}, thickness = 0.5));

    // Actuator chain
    connect(world.frame_b, linkOA.frame_a)
      annotation(Line(points = {{-120,60},{-120,-40},{-100,-40}}, color = {95,95,95}, thickness = 0.5));
    connect(linkOA.frame_b, pinA.frame_a)
      annotation(Line(points = {{-80,-40},{-60,-40}}, color = {95,95,95}, thickness = 0.5));
    connect(pinA.frame_b, slider.frame_a)
      annotation(Line(points = {{-40,-40},{-20,-40}}, color = {95,95,95}, thickness = 0.5));
    connect(slider.frame_b, pinB.frame_a)
      annotation(Line(points = {{0,-40},{20,-40},{20,0}}, color = {95,95,95}, thickness = 0.5));

    // Drive the hinge angle
    connect(phiRamp.y, posSource.phi_ref)
      annotation(Line(points = {{-120,110},{-100,110}}, color = {0,0,127}));
    connect(posSource.flange, hinge.axis)
      annotation(Line(points = {{-80,110},{-80,70},{-90,70}}, color = {0,0,0}));

    annotation (Diagram(coordinateSystem(extent = {{-160,-140},{140,140}})));
  end Kinematics;

  annotation (version = "1.0.0");
end MiniRetraction;

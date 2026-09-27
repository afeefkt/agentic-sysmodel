within DualThreePhaseMachine;

model PlantAssembly
  "Full plant: dual 2-level VSI -> VSD -> Park -> IPMSM -> Park_inv -> VSD_inv -> phase currents.
   Default configuration 2N (isolated neutrals); 1N (common neutral) is an
   alternate, documented config.
   1N zero-sequence wiring: machine u_0 = zp - zm (differential/circulating
   zero-sequence voltage between the two winding sets)."

  import SI = Modelica.Units.SI;
  import MB = Modelica.Blocks.Interfaces;

  // ===================== Configuration =====================
  parameter SI.Voltage u_dc = 500 "DC-link voltage (passed to inverter)";
  parameter NeutralConfig neutral_config = NeutralConfig.TwoN
    "Neutral configuration (machine + inverter). Default 2N.";

  // ===================== Inputs =====================
  MB.RealInput s_a1 "gate a1 (0/1)";
  MB.RealInput s_b1 "gate b1 (0/1)";
  MB.RealInput s_c1 "gate c1 (0/1)";
  MB.RealInput s_a2 "gate a2 (0/1)";
  MB.RealInput s_b2 "gate b2 (0/1)";
  MB.RealInput s_c2 "gate c2 (0/1)";
  MB.RealInput m_load(unit = "N.m") "mechanical load torque";

  // ===================== Outputs: phase currents =====================
  MB.RealOutput i_a1(unit = "A") "phase a1 current";
  MB.RealOutput i_b1(unit = "A") "phase b1 current";
  MB.RealOutput i_c1(unit = "A") "phase c1 current";
  MB.RealOutput i_a2(unit = "A") "phase a2 current";
  MB.RealOutput i_b2(unit = "A") "phase b2 current";
  MB.RealOutput i_c2(unit = "A") "phase c2 current";

  // ===================== Outputs: phase voltages =====================
  MB.RealOutput u_a1(unit = "V") "phase a1 voltage";
  MB.RealOutput u_b1(unit = "V") "phase b1 voltage";
  MB.RealOutput u_c1(unit = "V") "phase c1 voltage";
  MB.RealOutput u_a2(unit = "V") "phase a2 voltage";
  MB.RealOutput u_b2(unit = "V") "phase b2 voltage";
  MB.RealOutput u_c2(unit = "V") "phase c2 voltage";

  // ===================== Outputs: passthroughs =====================
  MB.RealOutput m_e(unit = "N.m") "electromagnetic torque";
  MB.RealOutput P_mech(unit = "W") "mechanical power";
  MB.RealOutput omega_mech(unit = "rad/s") "mechanical rotor speed";
  MB.RealOutput i_d(unit = "A") "d-axis current";
  MB.RealOutput i_q(unit = "A") "q-axis current";
  MB.RealOutput i_x(unit = "A") "x-axis (harmonic) current";
  MB.RealOutput i_y(unit = "A") "y-axis (harmonic) current";
  MB.RealOutput i_0(unit = "A") "zero-sequence current";

  // ===================== Components =====================
  DualThreePhaseInverter inv(u_dc = u_dc, neutral_config = neutral_config);
  VSDTransform.VSD vsdU "forward VSD (phase voltages -> alpha,beta,x,y,zp,zm)";
  ParkTransform.Park parkU "forward Park (alpha,beta -> d,q) at theta = phi_k";
  DualThreePhaseIPMSM machine(neutral_config = neutral_config);
  ParkTransform.Park_inv parkI "inverse Park (d,q -> alpha,beta)";
  VSDTransform.VSD_inv vsdI "inverse VSD (alpha,beta,x,y,zp,zm -> phase currents)";

equation
  // ---- gates -> inverter ----
  inv.s_a1 = s_a1;
  inv.s_b1 = s_b1;
  inv.s_c1 = s_c1;
  inv.s_a2 = s_a2;
  inv.s_b2 = s_b2;
  inv.s_c2 = s_c2;

  // ---- phase-voltage passthrough ----
  u_a1 = inv.u_a1;
  u_b1 = inv.u_b1;
  u_c1 = inv.u_c1;
  u_a2 = inv.u_a2;
  u_b2 = inv.u_b2;
  u_c2 = inv.u_c2;

  // ---- forward VSD: phase voltages -> subspaces ----
  vsdU.a1 = inv.u_a1;
  vsdU.b1 = inv.u_b1;
  vsdU.c1 = inv.u_c1;
  vsdU.a2 = inv.u_a2;
  vsdU.b2 = inv.u_b2;
  vsdU.c2 = inv.u_c2;

  // ---- forward Park: alpha,beta -> d,q at electrical rotor angle ----
  parkU.alpha = vsdU.alpha;
  parkU.beta = vsdU.beta;
  parkU.theta = machine.phi_k;

  // ---- machine voltage inputs ----
  machine.u_d = parkU.d;
  machine.u_q = parkU.q;
  machine.u_x = vsdU.x;
  machine.u_y = vsdU.y;

  // ---- zero-sequence voltage ----
  if neutral_config == NeutralConfig.TwoN then
    machine.u_0 = 0 "isolated neutrals block the zero-sequence path";
  else
    machine.u_0 = vsdU.zp - vsdU.zm
      "1N: differential (circulating) zero-sequence voltage drives u_0";
  end if;

  // ---- load ----
  machine.m_load = m_load;

  // ---- inverse Park: machine dq currents -> alpha,beta ----
  parkI.d = machine.i_d;
  parkI.q = machine.i_q;
  parkI.theta = machine.phi_k;

  // ---- inverse VSD: subspace currents -> phase currents ----
  vsdI.alpha = parkI.alpha;
  vsdI.beta = parkI.beta;
  vsdI.x = machine.i_x;
  vsdI.y = machine.i_y;
  if neutral_config == NeutralConfig.TwoN then
    vsdI.zp = 0 "2N: zero-sequence current blocked";
    vsdI.zm = 0;
  else
    vsdI.zp = machine.i_0 "1N: circulating zero-seq (set1 +, set2 -)";
    vsdI.zm = -machine.i_0;
  end if;

  // ---- phase-current outputs ----
  i_a1 = vsdI.a1;
  i_b1 = vsdI.b1;
  i_c1 = vsdI.c1;
  i_a2 = vsdI.a2;
  i_b2 = vsdI.b2;
  i_c2 = vsdI.c2;

  // ---- passthroughs ----
  m_e = machine.m_e;
  P_mech = machine.P_mech;
  omega_mech = machine.omega_mech;
  i_d = machine.i_d;
  i_q = machine.i_q;
  i_x = machine.i_x;
  i_y = machine.i_y;
  i_0 = machine.i_0;

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
      Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "PLANT")}),
    Documentation(info = "<html>
<p>Full dual three-phase plant: six gate signals drive a 2-level VSI, whose six
phase voltages are transformed to the VSD subspaces (alpha,beta,x,y,0+,0-), then
the alpha-beta pair is rotated to dq at the electrical rotor angle and fed to the
IPMSM together with x,y and a zero-sequence voltage. The machine dq currents are
rotated back and inverse-VSD-mapped to the six phase currents.</p>
<p><b>Zero-sequence wiring (documented convention):</b></p>
<ul>
<li><b>2N (default):</b> machine <code>u_0 = 0</code>; the VSD
  <code>zp</code>/<code>zm</code> outputs are unused. Phase currents are
  reconstructed from (i_d,i_q,i_x,i_y) with zero-sequence inputs 0.</li>
<li><b>1N:</b> machine <code>u_0 = zp - zm</code> (the differential/circulating
  zero-sequence voltage between the two sets); the circulating zero-sequence
  current is mapped back as <code>zp = +i_0</code>, <code>zm = -i_0</code>
  (set 1 positive, set 2 negative).</li>
</ul>
</html>"));
end PlantAssembly;

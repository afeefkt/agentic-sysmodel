within DualThreePhaseMachine;
model DualThreePhaseIPMSM
  "Core dual three-phase IPMSM: rotating dq + xy + zero-sequence subspaces (Step 1)"

  import SI = Modelica.Units.SI;
  import MB = Modelica.Blocks.Interfaces;

  // ===================== Design parameters (Table I / ASM) =====================
  parameter SI.Resistance Rs = 0.8 "Stator phase resistance";
  parameter SI.Inductance Ld = 5.5e-3 "d-axis magnetising inductance";
  parameter SI.Inductance Lq = 16.5e-3 "q-axis magnetising inductance";
  parameter SI.Inductance Ll = 0.9e-3 "Leakage inductance";
  parameter SI.MagneticFlux psi_pm = 0.1746 "Permanent-magnet flux linkage";
  parameter Integer np = 3 "Pole-pair number";
  parameter SI.Inertia J = 0.01 "Rotor inertia";
  parameter SI.RotationalDampingConstant b = 1.0e-3 "Viscous friction coefficient";
  parameter NeutralConfig neutral_config = NeutralConfig.TwoN "Neutral configuration";
  parameter SI.Current i_s_rated = 4.1 "Rated stator current (Table I)";
  parameter SI.Torque m_rated = 10.6 "Rated electromagnetic torque (Table I)";
  parameter SI.Power P_rated = 4400.0 "Rated mechanical power (Table I)";

  // ===================== Start values (currents/speed start at zero) =====================
  parameter SI.Current i_d_start = 0 "Initial d-axis current";
  parameter SI.Current i_q_start = 0 "Initial q-axis current";
  parameter SI.Current i_x_start = 0 "Initial x-axis current";
  parameter SI.Current i_y_start = 0 "Initial y-axis current";
  parameter SI.Current i_0_start = 0 "Initial zero-sequence current";
  parameter SI.AngularVelocity omega_mech_start = 0 "Initial mechanical rotor speed";
  parameter SI.Angle phi_k_start = 0 "Initial electrical rotor angle";

  // ===================== Derived parameters =====================
  final parameter SI.Inductance Ld_tot = Ld + Ll "Total d-axis inductance (L_l + L_d)";
  final parameter SI.Inductance Lq_tot = Lq + Ll "Total q-axis inductance (L_l + L_q)";
  final parameter SI.Inertia Theta = J/np "Rotor inertia in electrical frame (J/n_p)";
  final parameter SI.RotationalDampingConstant nu = b/np "Viscous friction in electrical frame (b/n_p)";
  final parameter SI.MagneticFlux psi_d_start = psi_pm + Ld_tot*i_d_start "Initial d flux (zero current => psi_pm)";
  final parameter SI.MagneticFlux psi_q_start = Lq_tot*i_q_start "Initial q flux (zero current => 0)";
  final parameter SI.AngularVelocity omega_k_start = np*omega_mech_start "Initial electrical speed";

  // ===================== Electrical inputs =====================
  MB.RealInput u_d(unit = "V") "d-axis voltage";
  MB.RealInput u_q(unit = "V") "q-axis voltage";
  MB.RealInput u_x(unit = "V") "x-axis voltage";
  MB.RealInput u_y(unit = "V") "y-axis voltage";
  MB.RealInput u_0(unit = "V") "zero-sequence voltage";
  MB.RealInput m_load(unit = "N.m") "mechanical load torque";

  // ===================== States (exposed as outputs) =====================
  MB.RealOutput psi_d(unit = "Wb", start = psi_d_start) "d-axis flux linkage";
  MB.RealOutput psi_q(unit = "Wb", start = psi_q_start) "q-axis flux linkage";
  MB.RealOutput i_x(unit = "A", start = i_x_start) "x-axis current";
  MB.RealOutput i_y(unit = "A", start = i_y_start) "y-axis current";
  MB.RealOutput i_0(unit = "A", start = i_0_start) "zero-sequence current";
  MB.RealOutput omega_k(unit = "rad/s", start = omega_k_start) "electrical rotor speed";
  MB.RealOutput phi_k(unit = "rad", start = phi_k_start) "electrical rotor angle";

  // ===================== Derived quantities (exposed as outputs) =====================
  MB.RealOutput i_d(unit = "A") "d-axis current";
  MB.RealOutput i_q(unit = "A") "q-axis current";
  MB.RealOutput omega_mech(unit = "rad/s") "mechanical rotor speed";
  MB.RealOutput m_e(unit = "N.m") "electromagnetic torque";
  MB.RealOutput P_mech(unit = "W") "mechanical power";

  // ===================== Residual outputs =====================
  MB.RealOutput res_psi_d(unit = "Wb") "residual: psi_d - ((L_l+L_d)*i_d + psi_pm)";
  MB.RealOutput res_psi_q(unit = "Wb") "residual: psi_q - ((L_l+L_q)*i_q)";
  MB.RealOutput res_dq_d(unit = "V") "residual: u_d - (R_s*i_d + der(psi_d) - omega_k*psi_q)";
  MB.RealOutput res_dq_q(unit = "V") "residual: u_q - (R_s*i_q + der(psi_q) + omega_k*psi_d)";
  MB.RealOutput res_me(unit = "N.m") "residual: m_e - 1.5*n_p*(psi_d*i_q - psi_q*i_d)";
  MB.RealOutput res_power(unit = "W") "residual: P_mech - m_e*omega_mech";

equation
  // ---- dq flux/current relations (algebraic) ----
  psi_d = Ld_tot*i_d + psi_pm;
  psi_q = Lq_tot*i_q;

  // ---- dq electrical dynamics (flux-linkage states) ----
  der(psi_d) = u_d - Rs*i_d + omega_k*psi_q;
  der(psi_q) = u_q - Rs*i_q - omega_k*psi_d;

  // ---- xy leakage dynamics (current states) ----
  der(i_x) = (u_x - Rs*i_x)/Ll;
  der(i_y) = (u_y - Rs*i_y)/Ll;

  // ---- zero-sequence dynamics ----
  if neutral_config == NeutralConfig.TwoN then
    i_0 = 0 "isolated neutrals block the zero-sequence path";
  else
    der(i_0) = (u_0 - Rs*i_0)/Ll;
  end if;

  // ---- electromagnetic torque ----
  m_e = 1.5*np*(psi_d*i_q - psi_q*i_d);

  // ---- mechanical dynamics ----
  Theta*der(omega_k) = m_e - m_load - nu*omega_k;
  omega_mech = omega_k/np;
  der(phi_k) = omega_k;

  // ---- mechanical power ----
  P_mech = m_e*omega_mech;

  // ---- residuals ----
  res_psi_d = psi_d - (Ld_tot*i_d + psi_pm);
  res_psi_q = psi_q - (Lq_tot*i_q);
  res_dq_d = u_d - (Rs*i_d + der(psi_d) - omega_k*psi_q);
  res_dq_q = u_q - (Rs*i_q + der(psi_q) + omega_k*psi_d);
  res_me = m_e - 1.5*np*(psi_d*i_q - psi_q*i_d);
  res_power = P_mech - m_e*omega_mech;

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
      Text(extent = {{-80, 30}, {80, -30}}, lineColor = {0, 0, 255}, textString = "IPMSM")}),
    Documentation(info = "<html>
<p>Core dual three-phase interior permanent-magnet synchronous machine (ADT-IPMSM) model.</p>
<p>Dynamics follow Eldeeb et al., IEEE PEDS 2017, Eq. (3), neglecting magnetic saturation.</p>
<ul>
<li>dq: flux-linkage states (energy-conversion subspace, back-EMF cross-coupling).</li>
<li>xy: current states (leakage-only harmonic subspace, no back-EMF).</li>
<li>zero-sequence: current state (blocked in 2N, enabled in 1N).</li>
</ul>
</html>"));
end DualThreePhaseIPMSM;

within DualThreePhaseMachine;

model DualThreePhaseInverter
  "Dual three-phase 2-level voltage source inverter (VSI).
   Gate signals s in {0,1}^6 -> phase voltages (relative to the neutral).
   2N (isolated neutrals): Eq. (4), block-diagonal, per-set sum = 0.
   1N (common neutral):     Eq. (5), over all 6 legs, total sum = 0."

  import SI = Modelica.Units.SI;
  import MB = Modelica.Blocks.Interfaces;

  // ===================== DC link / configuration =====================
  parameter SI.Voltage u_dc = 500 "DC-link voltage (ASM-1)";
  parameter NeutralConfig neutral_config = NeutralConfig.TwoN
    "Neutral configuration (2N isolated / 1N common)";

  // ===================== Gate signals (0 = low, 1 = high) =====================
  MB.RealInput s_a1 "gate a1 (0/1)";
  MB.RealInput s_b1 "gate b1 (0/1)";
  MB.RealInput s_c1 "gate c1 (0/1)";
  MB.RealInput s_a2 "gate a2 (0/1)";
  MB.RealInput s_b2 "gate b2 (0/1)";
  MB.RealInput s_c2 "gate c2 (0/1)";

  // ===================== Phase-voltage outputs =====================
  MB.RealOutput u_a1(unit = "V") "phase a1 voltage (set 1)";
  MB.RealOutput u_b1(unit = "V") "phase b1 voltage (set 1)";
  MB.RealOutput u_c1(unit = "V") "phase c1 voltage (set 1)";
  MB.RealOutput u_a2(unit = "V") "phase a2 voltage (set 2)";
  MB.RealOutput u_b2(unit = "V") "phase b2 voltage (set 2)";
  MB.RealOutput u_c2(unit = "V") "phase c2 voltage (set 2)";

  // ===================== Diagnostics =====================
  MB.RealOutput sum_set1(unit = "V") "u_a1+u_b1+u_c1 (0 in 2N)";
  MB.RealOutput sum_set2(unit = "V") "u_a2+u_b2+u_c2 (0 in 2N)";
  MB.RealOutput uph_max_abs(unit = "V") "max |u_ph| over all 6 phases";
  MB.RealOutput uph_err(unit = "V")
    "max residual |u_ph - Eq.(4)/(5) analytic|, ~0 if synthesis correct";

  // ===================== Analytic synthesis matrices (final parameters) =====================
  final parameter Real M2[6, 6] = (u_dc/3) * [
       2, -1, -1,  0,  0,  0;
      -1,  2, -1,  0,  0,  0;
      -1, -1,  2,  0,  0,  0;
       0,  0,  0,  2, -1, -1;
       0,  0,  0, -1,  2, -1;
       0,  0,  0, -1, -1,  2]
    "2N (Eq. 4): block-diagonal synthesis matrix (phase order a1,b1,c1,a2,b2,c2)";

  final parameter Real M1[6, 6] = (u_dc/6) * [
       5, -1, -1, -1, -1, -1;
      -1,  5, -1, -1, -1, -1;
      -1, -1,  5, -1, -1, -1;
      -1, -1, -1,  5, -1, -1;
      -1, -1, -1, -1,  5, -1;
      -1, -1, -1, -1, -1,  5]
    "1N (Eq. 5): common-neutral synthesis matrix (all 6 legs)";

  final parameter Real M[6, 6] = if neutral_config == NeutralConfig.TwoN then M2 else M1
    "active synthesis matrix for the selected neutral configuration";

equation
  // ---- Phase-voltage synthesis (Eq. 4 for 2N, Eq. 5 for 1N) ----
  if neutral_config == NeutralConfig.TwoN then
    // Eq. (4): u_ph,k = (u_dc/3)*(2*s_k - s_j - s_j'), j,j' the other two legs of the SAME set
    u_a1 = (u_dc/3)*(2*s_a1 - s_b1 - s_c1);
    u_b1 = (u_dc/3)*(2*s_b1 - s_a1 - s_c1);
    u_c1 = (u_dc/3)*(2*s_c1 - s_a1 - s_b1);
    u_a2 = (u_dc/3)*(2*s_a2 - s_b2 - s_c2);
    u_b2 = (u_dc/3)*(2*s_b2 - s_a2 - s_c2);
    u_c2 = (u_dc/3)*(2*s_c2 - s_a2 - s_b2);
  else
    // Eq. (5): u_ph,i = (u_dc/6)*(5*s_i - sum_{j<>i} s_j) over all 6 legs
    u_a1 = (u_dc/6)*(5*s_a1 - s_b1 - s_c1 - s_a2 - s_b2 - s_c2);
    u_b1 = (u_dc/6)*(5*s_b1 - s_a1 - s_c1 - s_a2 - s_b2 - s_c2);
    u_c1 = (u_dc/6)*(5*s_c1 - s_a1 - s_b1 - s_a2 - s_b2 - s_c2);
    u_a2 = (u_dc/6)*(5*s_a2 - s_a1 - s_b1 - s_c1 - s_b2 - s_c2);
    u_b2 = (u_dc/6)*(5*s_b2 - s_a1 - s_b1 - s_c1 - s_a2 - s_c2);
    u_c2 = (u_dc/6)*(5*s_c2 - s_a1 - s_b1 - s_c1 - s_a2 - s_b2);
  end if;

  // ---- Diagnostics ----
  sum_set1 = u_a1 + u_b1 + u_c1;
  sum_set2 = u_a2 + u_b2 + u_c2;
  uph_max_abs = max(abs({u_a1, u_b1, u_c1, u_a2, u_b2, u_c2}));
  uph_err = max(abs({u_a1, u_b1, u_c1, u_a2, u_b2, u_c2}
                  - M*{s_a1, s_b1, s_c1, s_a2, s_b2, s_c2}));

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
      Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "VSI")}),
    Documentation(info = "<html>
<p>Dual three-phase 2-level voltage source inverter (VSI), driven by six gate
signals <code>s in {0,1}</code> (phase order a1,b1,c1,a2,b2,c2).</p>
<ul>
<li><b>2N (isolated neutrals), Eq. (4):</b>
  <code>u_ph,k = (u_dc/3)*(2*s_k - s_j - s_j')</code> for the other two legs of
  the same three-phase set. Block-diagonal 6x6; each set's phase voltages sum to
  zero.</li>
<li><b>1N (common neutral), Eq. (5):</b>
  <code>u_ph,i = (u_dc/6)*(5*s_i - sum_{j&lt;&gt;i} s_j)</code> over all six legs.
  Sum over all six phases is zero; per-set sums are not.</li>
</ul>
<p><code>uph_err</code> is the maximum over the six phases of
<code>|u_ph - M*s|</code> where <code>M</code> is the analytic Eq. (4)/(5)
matrix evaluated with the model's own <code>u_dc</code>; it is a self-consistency
check and should be ~0.</p>
</html>"));
end DualThreePhaseInverter;

package Step3Harnesses
  "Additive Step-3 verification drivers for DualThreePhaseMachine.
   This file lives in Tests/ and is NOT part of the plant package: no model
   .mo file is modified. It only provides test drivers so that requirements
   that cannot be expressed through numeric parameter/input overrides can be
   exercised:
     - InverterAll64_2N / InverterAll64_1N: enumerate ALL 64 switching states
       in one simulation (64 inverter instances) and report the global maxima
       of |u_ph|, |per-set voltage sum| and the Eq.(4)/(5) residual.
     - RatedHold: voltage-fed IPMSM with a feed-forward + PI dq current
       regulator (MTPA) and an exact speed-hold load boundary condition, so
       REQ-24 (rated torque) and REQ-25 (rated power) can be evaluated at the
       rated mechanical speed."

  model InverterAll64_2N
    "All 64 switching states, 2N (isolated neutrals). Reports the global
     max |u_ph| (REQ-23), per-set sum (REQ-21) and Eq.(4) residual (REQ-22)."

    parameter Real u_dc = 500 "DC-link voltage";
    // s[k,j] = j-th gate (a1,b1,c1,a2,b2,c2) of state k, k = 0..63
    parameter Real s[64, 6] = {mod(floor(k/2^(j - 1)), 2) for j in 1:6, k in 0:63};

    DualThreePhaseMachine.DualThreePhaseInverter inv[64](
      u_dc = fill(u_dc, 64),
      neutral_config = fill(DualThreePhaseMachine.NeutralConfig.TwoN, 64));

    Real uph_max_all "max |u_ph| over all 64 states";
    Real sum_abs_max "max |per-set voltage sum| over all 64 states";
    Real uph_err_max "max Eq.(4) residual over all 64 states";
  equation
    for k in 1:64 loop
      inv[k].s_a1 = s[k, 1];
      inv[k].s_b1 = s[k, 2];
      inv[k].s_c1 = s[k, 3];
      inv[k].s_a2 = s[k, 4];
      inv[k].s_b2 = s[k, 5];
      inv[k].s_c2 = s[k, 6];
    end for;
  algorithm
    uph_max_all := 0;
    sum_abs_max := 0;
    uph_err_max := 0;
    for k in 1:64 loop
      uph_max_all := max(uph_max_all, inv[k].uph_max_abs);
      sum_abs_max := max(sum_abs_max,
        max(abs(inv[k].sum_set1), abs(inv[k].sum_set2)));
      uph_err_max := max(uph_err_max, inv[k].uph_err);
    end for;
  end InverterAll64_2N;

  model InverterAll64_1N
    "All 64 switching states, 1N (common neutral), Eq.(5). Reports the global
     max |u_ph| (REQ-23 1N bound 5*u_dc/6) and the Eq.(5) residual."

    parameter Real u_dc = 500 "DC-link voltage";
    parameter Real s[64, 6] = {mod(floor(k/2^(j - 1)), 2) for j in 1:6, k in 0:63};

    DualThreePhaseMachine.DualThreePhaseInverter inv[64](
      u_dc = fill(u_dc, 64),
      neutral_config = fill(DualThreePhaseMachine.NeutralConfig.OneN, 64));

    Real uph_max_all "max |u_ph| over all 64 states";
    Real uph_err_max "max Eq.(5) residual over all 64 states";
  equation
    for k in 1:64 loop
      inv[k].s_a1 = s[k, 1];
      inv[k].s_b1 = s[k, 2];
      inv[k].s_c1 = s[k, 3];
      inv[k].s_a2 = s[k, 4];
      inv[k].s_b2 = s[k, 5];
      inv[k].s_c2 = s[k, 6];
    end for;
  algorithm
    uph_max_all := 0;
    uph_err_max := 0;
    for k in 1:64 loop
      uph_max_all := max(uph_max_all, inv[k].uph_max_abs);
      uph_err_max := max(uph_err_max, inv[k].uph_err);
    end for;
  end InverterAll64_1N;

  model RatedHold
    "Voltage-fed IPMSM with feed-forward + PI dq current regulator (MTPA) and
     an exact speed-hold load BC: m_load = m_e - nu*omega_k => d(omega_k)/dt = 0.
     Used for REQ-24 (m_e = 10.6 N.m) and REQ-25 (P_mech = 4400 W)."

    parameter Real omega_mech_ref = 415.0943 "held mechanical speed";
    parameter Real i_d_ref = -5.02 "MTPA d current (DER-5)";
    parameter Real i_q_ref = 10.24 "MTPA q current (DER-5)";
    parameter Real Kp = 1.0;
    parameter Real Ki = 200.0;

    Real e_d = i_d_ref - plant.i_d;
    Real e_q = i_q_ref - plant.i_q;
    Real int_d(start = 0);
    Real int_q(start = 0);

    DualThreePhaseMachine.DualThreePhaseIPMSM plant(
      omega_mech_start = omega_mech_ref,
      i_d_start = i_d_ref,
      i_q_start = i_q_ref,
      phi_k_start = 0);
  equation
    der(int_d) = e_d;
    der(int_q) = e_q;
    plant.u_d = plant.Rs*i_d_ref - plant.omega_k*plant.psi_q + Kp*e_d + Ki*int_d;
    plant.u_q = plant.Rs*i_q_ref + plant.omega_k*plant.psi_d + Kp*e_q + Ki*int_q;
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 0;
    // speed hold boundary condition: load exactly balances torque + friction
    plant.m_load = plant.m_e - plant.nu*plant.omega_k;
  end RatedHold;

end Step3Harnesses;

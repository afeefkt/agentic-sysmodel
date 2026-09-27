within DualThreePhaseMachine;
package Harnesses
  "Verification harnesses for the Step-1 core machine (do NOT alter DualThreePhaseIPMSM.mo)"

  model SpeedLocked
    "REQ-06: rotor held at zero speed (load balances electromagnetic torque) -> pure dq RL dynamics"
    DualThreePhaseIPMSM plant(
      omega_mech_start = 0,
      i_d_start = 0,
      i_q_start = 0);
  equation
    plant.u_d = 1;
    plant.u_q = 1;
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 0;
    // balance total torque so omega_k stays at 0
    plant.m_load = plant.m_e;
  end SpeedLocked;

  model ZeroTorqueDecay
    "REQ-14: hold i_d=i_q=0 via back-EMF feed-forward -> m_e=0, rotor decays on viscous friction only"
    parameter Real i_d_ref = 0;
    parameter Real i_q_ref = 0;
    DualThreePhaseIPMSM plant(
      omega_mech_start = 100,
      i_d_start = 0,
      i_q_start = 0);
  equation
    plant.u_d = plant.Rs*i_d_ref - plant.omega_k*(plant.Lq + plant.Ll)*i_q_ref;
    plant.u_q = plant.Rs*i_q_ref + plant.omega_k*((plant.Ld + plant.Ll)*i_d_ref + plant.psi_pm);
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 0;
    plant.m_load = 0;
  end ZeroTorqueDecay;

  model ConstantTorque
    "REQ-13: hold dq currents at MTPA (m_e=10.6 N.m) with feed-forward + PI current regulator"
    parameter Real i_d_ref = -5.02;
    parameter Real i_q_ref = 10.24;
    parameter Real Kp = 1.0;
    parameter Real Ki = 200.0;
    Real e_d;
    Real e_q;
    Real int_d(start = 0);
    Real int_q(start = 0);
    DualThreePhaseIPMSM plant(
      omega_mech_start = 0,
      i_d_start = -5.02,
      i_q_start = 10.24);
  equation
    e_d = i_d_ref - plant.i_d;
    e_q = i_q_ref - plant.i_q;
    der(int_d) = e_d;
    der(int_q) = e_q;
    plant.u_d = plant.Rs*i_d_ref - plant.omega_k*plant.psi_q + Kp*e_d + Ki*int_d;
    plant.u_q = plant.Rs*i_q_ref + plant.omega_k*plant.psi_d + Kp*e_q + Ki*int_q;
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 0;
    plant.m_load = 0;
  end ConstantTorque;

  model ZeroSeq2N
    "REQ-09: isolated neutrals; u_0 excited, zero-sequence must stay blocked"
    DualThreePhaseIPMSM plant(
      neutral_config = NeutralConfig.TwoN,
      omega_mech_start = 0);
  equation
    plant.u_d = 0;
    plant.u_q = 0;
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 1;
    plant.m_load = 0;
  end ZeroSeq2N;

  model ZeroSeq1N
    "REQ-10: common neutral; u_0 step drives i_0 with tau_0 = L_l/R_s"
    DualThreePhaseIPMSM plant(
      neutral_config = NeutralConfig.OneN,
      omega_mech_start = 0);
  equation
    plant.u_d = 0;
    plant.u_q = 0;
    plant.u_x = 0;
    plant.u_y = 0;
    plant.u_0 = 1;
    plant.m_load = 0;
  end ZeroSeq1N;

end Harnesses;

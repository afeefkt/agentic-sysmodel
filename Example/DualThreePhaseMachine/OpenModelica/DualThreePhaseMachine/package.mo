package DualThreePhaseMachine
  "Dual three-phase interior permanent-magnet synchronous machine (ADT-IPMSM) plant model"

  import SI = Modelica.Units.SI;

  type NeutralConfig = enumeration(
      TwoN "Isolated neutrals: zero-sequence channel blocked (2N)",
      OneN "Common neutral: zero-sequence channel enabled (1N)")
    "Neutral configuration of the two three-phase winding sets";

  record MachineParameters
    "Machine parameters from Eldeeb et al., IEEE PEDS 2017 (Table I)"
    parameter SI.Resistance Rs = 0.8 "Stator phase resistance";
    parameter SI.Inductance Ld = 5.5e-3 "d-axis magnetising inductance";
    parameter SI.Inductance Lq = 16.5e-3 "q-axis magnetising inductance";
    parameter SI.Inductance Ll = 0.9e-3 "Leakage inductance";
    parameter SI.MagneticFlux psi_pm = 0.1746 "Permanent-magnet flux linkage";
    parameter Integer np = 3 "Pole-pair number";
    parameter SI.Inertia J = 0.01 "Rotor inertia";
    parameter SI.RotationalDampingConstant b = 1.0e-3 "Viscous friction coefficient";
    parameter SI.Current i_s_rated = 4.1 "Rated stator current (Table I)";
    parameter SI.Torque m_rated = 10.6 "Rated electromagnetic torque (Table I)";
    parameter SI.Power P_rated = 4400.0 "Rated power (Table I)";
    parameter NeutralConfig neutral_config = NeutralConfig.TwoN "Neutral configuration";
  end MachineParameters;

  annotation(version = "1.0.0",
    Documentation(info = "<html>
<p>Package for the dual three-phase interior permanent-magnet synchronous machine (ADT-IPMSM) plant model.</p>
<p>Source: Eldeeb et al., IEEE PEDS 2017 (Table I / Eq. 1-4).</p>
</html>"));
end DualThreePhaseMachine;

within DualThreePhaseMachine;

package TransformChecks
  "Verification harnesses for the Step-2 transforms (VSD + Park): orthogonality,
   round-trip, balanced-set subspace separation, 30-degree amplitude mapping,
   Park orthonormality and magnitude preservation."

  model VSDCheck
    "REQ-16..19: VSD orthogonality, round-trip, balanced-set subspace separation"

    final parameter Real pi = Modelica.Constants.pi;
    parameter Real A = 4.1 "balanced per-set current amplitude";
    parameter Real omega = 2*pi "electrical angle sweep rate (1 rev/s)";

    Real theta = omega*time "swept electrical angle";
    Real a1 = A*cos(theta);
    Real b1 = A*cos(theta - 2*pi/3);
    Real c1 = A*cos(theta + 2*pi/3);
    Real a2 = A*cos(theta - pi/6);
    Real b2 = A*cos(theta - pi/6 - 2*pi/3);
    Real c2 = A*cos(theta - pi/6 + 2*pi/3);

    VSDTransform.VSD vsd;
    VSDTransform.VSD_inv vsd_inv;

    Real alpha_beta_amp = sqrt(vsd.alpha^2 + vsd.beta^2) "peak alpha-beta magnitude";
    Real alpha_err = vsd.alpha/A - cos(theta) "alpha vs A*cos(theta) mapping";
    Real beta_err  = vsd.beta/A  - sin(theta) "beta vs A*sin(theta) mapping";
    Real roundtrip_phase_err = max({abs(vsd_inv.a1 - a1), abs(vsd_inv.b1 - b1),
      abs(vsd_inv.c1 - c1), abs(vsd_inv.a2 - a2), abs(vsd_inv.b2 - b2),
      abs(vsd_inv.c2 - c2)}) "max phase round-trip error";

  equation
    vsd.a1 = a1;
    vsd.b1 = b1;
    vsd.c1 = c1;
    vsd.a2 = a2;
    vsd.b2 = b2;
    vsd.c2 = c2;
    vsd_inv.alpha = vsd.alpha;
    vsd_inv.beta  = vsd.beta;
    vsd_inv.x     = vsd.x;
    vsd_inv.y     = vsd.y;
    vsd_inv.zp    = vsd.zp;
    vsd_inv.zm    = vsd.zm;

    annotation(Documentation(info = "<html>
<p>Drives both winding sets with a balanced, symmetric six-phase current set
(per-set amplitude A, second set lagging 30 deg) at a swept electrical angle.</p>
<p>Expected: alpha-beta carries the set (peak |alpha,beta| = A), while x, y, 0+, 0-
are all zero. Also checks the forward + inverse VSD round-trip on the phase quantities.</p>
</html>"));
  end VSDCheck;

  model ParkCheck
    "REQ-20: Park orthonormality, magnitude preservation, round-trip"

    final parameter Real pi = Modelica.Constants.pi;
    parameter Real A = 4.1;
    parameter Real omega = 2*pi;

    Real theta = omega*time;
    Real alpha = A*cos(theta);
    Real beta  = A*sin(theta);

    ParkTransform.Park park;
    ParkTransform.Park_inv park_inv;

    Real ab_amp = sqrt(alpha^2 + beta^2) "stationary magnitude |alpha,beta|";
    Real dq_amp = sqrt(park.d^2 + park.q^2) "rotating magnitude |d,q|";
    Real amp_err = dq_amp - ab_amp "magnitude preservation error";
    Real roundtrip_alpha_err = abs(park_inv.alpha - alpha);
    Real roundtrip_beta_err  = abs(park_inv.beta  - beta);

  equation
    park.alpha = alpha;
    park.beta  = beta;
    park.theta = theta;
    park_inv.d = park.d;
    park_inv.q = park.q;
    park_inv.theta = theta;

    annotation(Documentation(info = "<html>
<p>Drives the Park transform with a rotating stationary-frame vector
(alpha, beta) = A*(cos, sin) at a swept angle.</p>
<p>Expected: d = A (constant), q = 0, magnitude |d,q| = |alpha,beta|, and the
inverse Park recovers (alpha, beta) exactly.</p>
</html>"));
  end ParkCheck;

end TransformChecks;

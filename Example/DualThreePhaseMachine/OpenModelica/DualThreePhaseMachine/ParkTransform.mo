within DualThreePhaseMachine;

package ParkTransform
  "Park rotation transform blocks (Step 2)"

  block Park
    "Forward Park rotation: (alpha,beta) -> (d,q) at electrical angle theta.
     R = [[cos(theta), sin(theta)], [-sin(theta), cos(theta)]] (amplitude-invariant)."

    import MB = Modelica.Blocks.Interfaces;

    MB.RealInput alpha(unit = "A") "alpha (stationary) component";
    MB.RealInput beta(unit = "A") "beta (stationary) component";
    MB.RealInput theta(unit = "rad") "electrical rotor angle";

    MB.RealOutput d(unit = "A") "d-axis (rotating) component";
    MB.RealOutput q(unit = "A") "q-axis (rotating) component";

    MB.RealOutput park_roundtrip_err "max|R*R' - I_2|, should be ~0 (orthonormality)";

  equation
    d = cos(theta)*alpha + sin(theta)*beta;
    q = -sin(theta)*alpha + cos(theta)*beta;
    park_roundtrip_err = max(abs([
        cos(theta)^2 + sin(theta)^2 - 1,                 -cos(theta)*sin(theta) + sin(theta)*cos(theta);
        -sin(theta)*cos(theta) + cos(theta)*sin(theta),   sin(theta)^2 + cos(theta)^2 - 1]));

    annotation(
      Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
        Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "Park")}),
      Documentation(info = "<html>
<p>Forward Park rotation <code>[d;q] = R(theta)*[alpha;beta]</code> with
<code>R = [[cos, sin], [-sin, cos]]</code>.</p>
<p>R is orthonormal (<code>R*R' = I_2</code>) and preserves magnitude
<code>|dq| = |alpha,beta|</code>. Only the alpha-beta (energy-conversion)
subspace is rotated; the xy and 0+ 0- subspaces remain stationary.</p>
</html>"));
  end Park;

  block Park_inv
    "Inverse Park rotation: (d,q) -> (alpha,beta); R^T."

    import MB = Modelica.Blocks.Interfaces;

    MB.RealInput d(unit = "A") "d-axis (rotating) component";
    MB.RealInput q(unit = "A") "q-axis (rotating) component";
    MB.RealInput theta(unit = "rad") "electrical rotor angle";

    MB.RealOutput alpha(unit = "A") "alpha (stationary) component";
    MB.RealOutput beta(unit = "A") "beta (stationary) component";

  equation
    alpha = cos(theta)*d - sin(theta)*q;
    beta  = sin(theta)*d + cos(theta)*q;

    annotation(
      Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
        Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "Park inv")}),
      Documentation(info = "<html>
<p>Inverse Park rotation <code>[alpha;beta] = R(theta)'*[d;q]</code>.</p>
</html>"));
  end Park_inv;

  annotation(Documentation(info = "<html>
<p>Park (rotating-frame) coordinate transform between the stationary alpha-beta
frame and the synchronous d-q frame, angle theta = phi_k.</p>
<p><code>R = [[cos, sin], [-sin, cos]]</code>; orthonormal; magnitude-preserving.
Only the alpha-beta subspace is rotated.</p>
</html>"));
end ParkTransform;

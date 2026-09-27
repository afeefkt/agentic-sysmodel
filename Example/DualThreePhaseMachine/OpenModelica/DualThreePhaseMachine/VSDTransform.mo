within DualThreePhaseMachine;

package VSDTransform
  "Vector-space-decomposition (generalised Clarke) transform blocks (Step 2)"

  block VSD
    "Forward VSD (generalised Clarke) transform:
     6-phase (a1,b1,c1,a2,b2,c2) -> (alpha,beta,x,y,0+,0-).
     Generic: the same matrix applies to currents and voltages."

    import MB = Modelica.Blocks.Interfaces;

    // Amplitude-invariant VSD matrix T (rows: alpha,beta,x,y,0+,0-;
    // columns: a1,b1,c1,a2,b2,c2). Property: T*T' = (1/3)*I_6, T^-1 = 3*T'.
    final parameter Real T[6, 6] =
      (1/3) * [ 1,         -1/2,        -1/2,         sqrt(3)/2,  -sqrt(3)/2,  0;
                0,          sqrt(3)/2,  -sqrt(3)/2,    1/2,         1/2,      -1;
                1,         -1/2,        -1/2,        -sqrt(3)/2,   sqrt(3)/2,  0;
                0,         -sqrt(3)/2,   sqrt(3)/2,    1/2,         1/2,      -1;
                1,          1,           1,            0,           0,         0;
                0,          0,           0,            1,           1,         1]
      "Amplitude-invariant VSD matrix (rows alpha,beta,x,y,0+,0-; cols a1,b1,c1,a2,b2,c2)";

    final parameter Real orth_err = max(abs(T * transpose(T) - (1/3)*identity(6)))
      "max|T*T' - (1/3)*I_6|, should be ~0 (orthogonality of subspaces)";
    final parameter Real roundtrip_err = max(abs(T * (3*transpose(T)) - identity(6)))
      "max|T*(3*T') - I_6|, should be ~0 (forward+inverse round-trip)";

    MB.RealInput a1(unit = "A") "phase a1";
    MB.RealInput b1(unit = "A") "phase b1";
    MB.RealInput c1(unit = "A") "phase c1";
    MB.RealInput a2(unit = "A") "phase a2";
    MB.RealInput b2(unit = "A") "phase b2";
    MB.RealInput c2(unit = "A") "phase c2";

    MB.RealOutput alpha(unit = "A") "alpha subspace";
    MB.RealOutput beta(unit = "A") "beta subspace";
    MB.RealOutput x(unit = "A") "x subspace (harmonic)";
    MB.RealOutput y(unit = "A") "y subspace (harmonic)";
    MB.RealOutput zp(unit = "A") "zero-sequence 0+";
    MB.RealOutput zm(unit = "A") "zero-sequence 0-";

  equation
    alpha = T[1, 1]*a1 + T[1, 2]*b1 + T[1, 3]*c1 + T[1, 4]*a2 + T[1, 5]*b2 + T[1, 6]*c2;
    beta  = T[2, 1]*a1 + T[2, 2]*b1 + T[2, 3]*c1 + T[2, 4]*a2 + T[2, 5]*b2 + T[2, 6]*c2;
    x     = T[3, 1]*a1 + T[3, 2]*b1 + T[3, 3]*c1 + T[3, 4]*a2 + T[3, 5]*b2 + T[3, 6]*c2;
    y     = T[4, 1]*a1 + T[4, 2]*b1 + T[4, 3]*c1 + T[4, 4]*a2 + T[4, 5]*b2 + T[4, 6]*c2;
    zp    = T[5, 1]*a1 + T[5, 2]*b1 + T[5, 3]*c1 + T[5, 4]*a2 + T[5, 5]*b2 + T[5, 6]*c2;
    zm    = T[6, 1]*a1 + T[6, 2]*b1 + T[6, 3]*c1 + T[6, 4]*a2 + T[6, 5]*b2 + T[6, 6]*c2;

    annotation(
      Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
        Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "VSD")}),
      Documentation(info = "<html>
<p>Forward vector-space-decomposition (generalised Clarke) transform <code>y = T*u</code>.</p>
<p>Phase order <code>(a1,b1,c1,a2,b2,c2)</code>; output order <code>(alpha,beta,x,y,0+,0-)</code>.
Amplitude-invariant scaling 1/3. Properties: <code>T*T' = (1/3)*I_6</code> and
<code>T^-1 = 3*T'</code>.</p>
</html>"));
  end VSD;

  block VSD_inv
    "Inverse VSD transform: (alpha,beta,x,y,0+,0-) -> 6-phase (a1..c2); y = 3*T'*u"

    import MB = Modelica.Blocks.Interfaces;

    // Same reference matrix as VSD (inverse uses 3*T').
    final parameter Real T[6, 6] =
      (1/3) * [ 1,         -1/2,        -1/2,         sqrt(3)/2,  -sqrt(3)/2,  0;
                0,          sqrt(3)/2,  -sqrt(3)/2,    1/2,         1/2,      -1;
                1,         -1/2,        -1/2,        -sqrt(3)/2,   sqrt(3)/2,  0;
                0,         -sqrt(3)/2,   sqrt(3)/2,    1/2,         1/2,      -1;
                1,          1,           1,            0,           0,         0;
                0,          0,           0,            1,           1,         1]
      "Amplitude-invariant VSD matrix (rows alpha,beta,x,y,0+,0-; cols a1,b1,c1,a2,b2,c2)";

    MB.RealInput alpha(unit = "A") "alpha subspace";
    MB.RealInput beta(unit = "A") "beta subspace";
    MB.RealInput x(unit = "A") "x subspace (harmonic)";
    MB.RealInput y(unit = "A") "y subspace (harmonic)";
    MB.RealInput zp(unit = "A") "zero-sequence 0+";
    MB.RealInput zm(unit = "A") "zero-sequence 0-";

    MB.RealOutput a1(unit = "A") "phase a1";
    MB.RealOutput b1(unit = "A") "phase b1";
    MB.RealOutput c1(unit = "A") "phase c1";
    MB.RealOutput a2(unit = "A") "phase a2";
    MB.RealOutput b2(unit = "A") "phase b2";
    MB.RealOutput c2(unit = "A") "phase c2";

  equation
    a1 = 3*(T[1, 1]*alpha + T[2, 1]*beta + T[3, 1]*x + T[4, 1]*y + T[5, 1]*zp + T[6, 1]*zm);
    b1 = 3*(T[1, 2]*alpha + T[2, 2]*beta + T[3, 2]*x + T[4, 2]*y + T[5, 2]*zp + T[6, 2]*zm);
    c1 = 3*(T[1, 3]*alpha + T[2, 3]*beta + T[3, 3]*x + T[4, 3]*y + T[5, 3]*zp + T[6, 3]*zm);
    a2 = 3*(T[1, 4]*alpha + T[2, 4]*beta + T[3, 4]*x + T[4, 4]*y + T[5, 4]*zp + T[6, 4]*zm);
    b2 = 3*(T[1, 5]*alpha + T[2, 5]*beta + T[3, 5]*x + T[4, 5]*y + T[5, 5]*zp + T[6, 5]*zm);
    c2 = 3*(T[1, 6]*alpha + T[2, 6]*beta + T[3, 6]*x + T[4, 6]*y + T[5, 6]*zp + T[6, 6]*zm);

    annotation(
      Icon(graphics = {
        Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}),
        Text(extent = {{-90, 20}, {90, -20}}, lineColor = {0, 0, 255}, textString = "VSD inv")}),
      Documentation(info = "<html>
<p>Inverse VSD transform <code>y = (3*T')*u</code> (equivalently <code>T^-1*u</code>).</p>
<p>Recovers the six phase quantities from the alpha-beta / xy / 0+ 0- subspaces.</p>
</html>"));
  end VSD_inv;

  annotation(Documentation(info = "<html>
<p>Vector-space-decomposition (generalised Clarke) transform for an asymmetrical
six-phase machine (two three-phase sets displaced by pi/6 rad).</p>
<p>Reference matrix: Eldeeb et al., IEEE PEDS 2017, Eq. (1) / DER-8.
Amplitude-invariant scaling 1/3; <code>T*T' = (1/3)*I_6</code>; <code>T^-1 = 3*T'</code>.</p>
</html>"));
end VSDTransform;

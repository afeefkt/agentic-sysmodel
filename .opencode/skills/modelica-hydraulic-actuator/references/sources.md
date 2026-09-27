# Sources — modelica-hydraulic-actuator

| Fact area | Source | License | Confidence |
|---|---|---|---|
| `Modelica.Fluid` + `Modelica.Media` availability and suitability | local `knowledge/msl/Fluid.md` (MSL 4.1.0) | BSD-3-Clause | high |
| `PartialCompliant` base (flange_a/flange_b, s_rel, sign convention) | MSL `Modelica.Mechanics.Translational.Interfaces` | BSD-3-Clause | high |

Note: the lumped cylinder equations (chamber mass balance, orifice, laminar leak,
Coulomb+viscous friction, bulk modulus range) are standard hydraulics engineering
practice, not from a single cited source. β ≈ 1.0–1.5e9 Pa and Cd ≈ 0.6–0.7 are typical
engineering ranges — label them ASSUMED in `architecture.md`, or SOURCED if you take a
value from the fluid/valve datasheet. The vapor-pressure-of-oil claim ("a few kPa") is
approximate; source the exact value per fluid.

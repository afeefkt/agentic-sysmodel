# Sources — modelica-multibody

| Fact area | Source | License | Confidence |
|---|---|---|---|
| MultiBody package tree, components, examples | https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.html and local `knowledge/msl/MultiBody.md` | BSD-3-Clause | high |
| `BodyShape` parameter semantics (r, r_CM, m, I_11..I_33) | https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Parts.BodyShape.html | BSD-3-Clause | high |
| Loop handling (`RevolutePlanarLoopConstraint`, `Joints.Assemblies`) | `knowledge/msl/MultiBody.md` (MSL User's Guide) | BSD-3-Clause | high |
| Example models (DoublePendulum, PlanarFourbar, EngineV6_analytic) | MSL 4.1.0 examples, verified via `openmodelica_list_examples` | BSD-3-Clause | high |
| Historical Body rCM/I semantics | https://modelica.org/events/Conference2003/papers/h37_Otter_multibody.pdf | — | high (academic) |

Note: MultiBody is the most failure-prone domain in this repo; the loop rules above come
from the MSL User's Guide and are the single most important thing to get right.

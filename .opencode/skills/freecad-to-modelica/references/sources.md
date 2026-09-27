# Sources — freecad-to-modelica

| Fact area | Source | License | Confidence |
|---|---|---|---|
| FreeCAD mass-property semantics (mm units, `MatrixOfInertia` = unit-density mm⁵ about CoM, global-placement handling) | https://raw.githubusercontent.com/FreeCAD/FreeCAD-macros/master/Information/CenterOfMass.FCMacro | LGPL (macro) | high |
| `MatrixOfInertia` raw unit is length⁵ (mm⁵) | https://forum.freecad.org/viewtopic.php?style=1&p=874792 | forum | high |
| Inertia taken about centre of gravity | https://forum.freecad.org/viewtopic.php?t=105003 | forum | medium-high |
| STL/OBJ export (dimensionless, mm assumed) | https://github.com/FreeCAD/FreeCAD-documentation/blob/main/wiki/Export_to_STL_or_OBJ.md | FreeCAD docs | high |
| `BodyShape` parameter semantics (r, r_CM, m, I_11..I_33; frame parallel to frame_a at CoM) | https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Parts.BodyShape.html | BSD-3-Clause | high |
| `Visualizers.Advanced.Shape` (external file URI, metres, `extra` scaling) | https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape.html | BSD-3-Clause | high |
| FreeCAD MCP server tools | https://github.com/neka-nat/freecad-mcp (MIT, ~2.5k★) and local `../external/freecad-mcp/src/freecad_mcp/server.py` | MIT | high |
| Assembly workbench joint `Offset1`/`Offset2` LCS | https://github.com/FreeCAD/FreeCAD-documentation/blob/main/wiki/Assembly_Workbench.md | FreeCAD docs | medium |
| CAD→Modelica mass/inertia + mates mapping (historical) | https://modelica.org/events/workshop2000/proceedings/Bunus.pdf | — | high (academic) |
| MultiBody `Body` rCM/I semantics (historical) | https://modelica.org/events/Conference2003/papers/h37_Otter_multibody.pdf | — | high (academic) |

Unverified / flagged:
- The **sign convention of off-diagonal (product-of-inertia) terms** between
  FreeCAD/OCC and MSL has not been confirmed. For bodies that are not symmetric about
  the frame axes, validate with a tilted test body before trusting the products.
- Exact `TypeId` strings and `Object1`/`Object2` property names of FreeCAD
  `Assembly::Joint*` objects were not verified — inspect live with `get_object`
  before writing a joint-frame extraction script.
- No maintained, general-purpose FreeCAD→Modelica exporter exists; the handoff in this
  skill is the recommended manual workflow.

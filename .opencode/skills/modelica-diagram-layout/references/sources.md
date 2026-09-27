# Sources — modelica-diagram-layout

| Fact area | Source | License | Confidence |
|---|---|---|---|
| Placement/Line/Icon/Diagram annotations, coordinate systems, rotation/transform order | Modelica Language Spec 3.6 ch. 18 (local `knowledge/web/spec-annotations.md`); https://specification.modelica.org/maint/3.6/annotations.html | free distribution with notice | high |
| Default coordinate-system extent `{{-100,-100},{100,100}}`, `preserveAspectRatio` | Spec 3.6 ch. 18.6.1/18.6.5 | free distribution with notice | high |
| `Line` fields (pattern, smooth, arrow, thickness, color) | Spec 3.6 ch. 18.6.4/18.6.5.1 | free distribution with notice | high |
| Rotation is CCW about `{0,0}`; transform order extent→rotation→origin | Spec 3.6 ch. 18.6.2 | free distribution with notice | high |
| OMEdit diagram workflow / grid | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/omedit.html | CC BY 4.0 | medium |

Note: OMEdit's exact default grid spacing is tool-dependent and was not numerically
verified; this repo standardises on a 10-unit grid for its own models (see SKILL.md).

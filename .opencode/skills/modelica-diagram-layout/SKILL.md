---
name: modelica-diagram-layout
description: Use whenever you write or edit a Modelica model that contains components, so it shows up as a proper connected diagram in OMEdit — Placement/Line/Icon annotations, layout grid, rotation/flip, connector placement and icons for custom components. Required before openmodelica_diagram_check.
---

# Making models visible in the OMEdit diagram

A component **without a `Placement` annotation doesn't appear in the OMEdit diagram view**,
even if the model simulates. Every component instance (and every top-level connector) needs
one. `openmodelica_diagram_check` enforces this.

## Placement (component position)
```modelica
Modelica.Mechanics.MultiBody.Joints.Revolute rev(n = {0, 0, 1}, useAxisFlange = true)
  annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));
```
- `extent = {{x1, y1}, {x2, y2}}` in diagram coordinates. Default diagram area is
  `{{-100,-100},{100,100}}`. Put all extents on a **10-unit grid**.
- Standard component size: **20 × 20** (e.g. `{{-10,-10},{10,10}}` shifted).
- Rotate: `Placement(transformation(extent = {{-10,-10},{10,10}}, rotation = 90, origin = {40, 20}))`.
  **Transform order is extent → rotation → origin, and rotation is counter-clockwise about
  `{0,0}`** (not about `origin`). So keep the extent centred on the origin and put the
  position in `origin` — do not bake position into the extent and also set `origin`.
- Horizontal flip: swap x in extent (`{{10,-10},{-10,10}}`). Vertical flip: swap y.
- Larger canvas: add to the model annotation
  `annotation(Diagram(coordinateSystem(extent = {{-200,-100},{200,100}})))`.

## Line (connection route)
```modelica
connect(world.frame_b, rev.frame_a)
  annotation(Line(points = {{-40, 0}, {-20, 0}}, color = {95, 95, 95}, thickness = 0.5));
```
- `points` run from the first connector's position to the second, with orthogonal elbows
  (`{{0,40},{0,20},{-10,20},{-10,10}}`).
- Conventional colors: signals `{0,0,127}`, electrical `{0,0,255}`, rotational/translational
  `{0,0,0}`, MultiBody frames `{95,95,95}` with `thickness=0.5`, heat `{191,0,0}`, fluid `{0,127,255}`.
- Optional `Line` extras: `pattern=LinePattern.Solid|Dash|Dot`, `smooth=Smooth.None|Bezier`,
  `arrow={Arrow.None,...}` (arrowheads). Defaults are solid/none; add arrows only for signal
  direction where it helps.
- Lines are optional for OMEdit (it draws straight lines), but always add them for readability.

## Layout convention (use it every time)
- Left → right = cause → effect: **sources/commands (x ≈ -80…-60) → controllers (-40…-20) →
  actuators / plant (0…40) → sensors / loads (60…80)**.
- Feedback paths go **below** the forward path (y ≈ -40…-60); reference/setpoint blocks go
  **above** (y ≈ 40…60).
- MultiBody: `world` at the far left (x=-80). Mechanical chains run left→right. Parallel
  loop branches go in stacked rows.
- 20 units of space between neighbouring components. Don't let lines cross components.
- **Copy the layout of the closest MSL example**: `get_class_source(<example>)` shows its Placements and Lines.

## Custom components (only when no MSL component exists)
Give them connectors **with icon placement** and a minimal icon, so they look like library parts:
```modelica
model LumpedActuator "Double-acting hydraulic cylinder (lumped)"
  extends Modelica.Mechanics.Translational.Interfaces.PartialCompliant;  // flange_a, flange_b
  Modelica.Blocks.Interfaces.RealInput valveCmd "spool command [-1..1]"
    annotation(Placement(transformation(extent = {{-20,-20},{20,20}}, rotation = -90, origin = {0,120})));
  // ... parameters + equations ...
  annotation(Icon(coordinateSystem(extent = {{-100,-100},{100,100}}), graphics = {
    Rectangle(extent = {{-90,40},{40,-40}}, lineColor = {0,0,0}, fillColor = {215,215,215}, fillPattern = FillPattern.Solid),
    Rectangle(extent = {{40,10},{90,-10}}, lineColor = {0,0,0}, fillColor = {160,160,164}, fillPattern = FillPattern.Solid),
    Text(extent = {{-150,90},{150,50}}, textString = "%name", textColor = {0,0,255})}));
end LumpedActuator;
```
- Inherit MSL partials (`PartialCompliant`, `Electrical.Analog.Interfaces.OnePort`,
  `Rotational.Interfaces.PartialTwoFlanges`, `Blocks.Interfaces.SISO`) for correctly-placed connectors for free.
- `%name` shows the instance name under the icon.

Full annotation syntax (coordinate systems, primitives, `Line`/`Placement` fields):
`references/annotation-syntax.md`. Sources: `references/sources.md`.

## Checklist before handing back
1. Every component and top-level connector has a `Placement`.
2. Every `connect` has a `Line`.
3. No overlapping extents (look at the coordinates).
4. `openmodelica_diagram_check` → `ok: true`.

Source: Modelica Language Specification 3.6, ch. 18.9 (full text in `knowledge/web/spec-annotations.md`), and MSL example layouts.

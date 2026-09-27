# Annotation syntax reference (Placement, Line, Icon)

Condensed from Modelica Language Spec 3.6 ch. 18. Full text: `knowledge/web/spec-annotations.md`.

## Coordinate systems
```modelica
annotation(Icon(coordinateSystem(extent = {{-100,-100},{100,100}}, preserveAspectRatio = true), graphics = {...}));
annotation(Diagram(coordinateSystem(extent = {{-100,-100},{100,100}}), graphics = {...}));
```
- Default extent is `{{-100,-100},{100,100}}` for both Icon and Diagram; `preserveAspectRatio`
  is true by default (Icon scales uniformly).
- `graphics` holds the drawing primitives.

## Drawing primitives (inside `graphics`)
- `Rectangle(extent=..., origin=..., rotation=..., lineColor, fillColor, fillPattern, ...)`
- `Line(points={{x,y},...}, color, thickness, pattern=LinePattern.Solid|Dash|Dot, arrow={Arrow.None|Open|Filled|Half, ...}, smooth=Smooth.None|Bezier)`
- `Polygon(points=..., lineColor, fillColor, fillPattern)`
- `Ellipse(extent=..., ...)`
- `Text(extent=..., textString="%name", textColor, fontSize, horizontalAlignment, ...)`
- `Bitmap(extent=..., fileName="modelica://...", ...)`
- All use `extent`/`origin`/`rotation` for placement. Colors are 0–255 `{r,g,b}`.

## Placement (component instance)
```modelica
annotation(Placement(
  visible = true,
  transformation(origin = {x, y}, extent = {{x1,y1},{x2,y2}}, rotation = deg)));
```
- Transformation order: **extent → rotation → origin**.
- Rotation is **counter-clockwise about `{0,0}`**, applied before the origin translation.
- `iconVisible`/`iconTransformation` place the component's **public connectors** on the icon
  layer (so connectors appear in the icon view too).

## Line (connection)
```modelica
connect(a.x, b.x) annotation(Line(
  points = {{x1,y1},{x2,y2},...},
  color = {r,g,b},
  pattern = LinePattern.Solid,
  thickness = 0.25,
  smooth = Smooth.None,
  arrow = {Arrow.None, Arrow.None}));
```
- `points` list the polyline vertices (with optional orthogonal elbows).
- `arrow` is a pair — arrowhead at the first and last vertex respectively.
- Optional `Text(string="%first", index=-1, extent=...)` labels the line.

## Practical consequences
- To rotate a component 90°, set `rotation=90` and keep the extent centred on `{0,0}`,
  then use `origin` for position. Baking position into the extent AND setting origin
  double-translates the component.
- Flipping is done by swapping the extent endpoints (x for horizontal, y for vertical),
  not by a negative scale.

# STL export for Modelica animation

Animation is **optional** and only worth it after sizing passes. It is the last step.

## Export
```python
import Mesh
Mesh.export([doc.getObject("Strut")], "/path/to/CAD/Strut.stl")
# or: doc.getObject("Strut").Shape.exportStl("/path/to/CAD/Strut.stl")
```
STL has **no units**; FreeCAD writes the raw numbers as mm.

## What Modelica expects
`Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape` (used internally by
`BodyShape` with `shapeType`) expects the external shape file to be:
- in **metres** (default), and
- expressed in **frame_a** coordinates (the shape's origin = frame_a origin, axes aligned
  with frame_a).

The `shapeType` is a URI: `"modelica://<Pkg>/Resources/part.stl"` (for files shipped in
the package) or `"file:///abs/path.stl"`.

## Fixing the mm→m and origin mismatch
Two equivalent options:
1. **Scale and translate in FreeCAD before export** (recommended): apply `Draft.scale`
   ×1e-3 so the STL is in metres, and translate so the body's primary-joint point is at
   the origin with the body's frame_a axes aligned. Then `extra=0`.
2. **Let Modelica scale**: set `shapeType` and use the body's `length`/`width`/`height`
   with `extra=1` (MSL scales the shape by those dimensions). Simpler, but you must also
   handle the origin offset — usually via a `FixedTranslation`/frame.

Simplest reliable path: scale in FreeCAD, export, and verify in OMEdit that the shape
sits at the right place and orientation relative to the mechanism.

## Animation speed
- `World.enableAnimation=false` disables animation for batch/sizing runs (faster).
- When animation is on, ensure the STL scale is right or bodies will look wildly wrong
  (mm numbers rendered as metres = 1000× too big).

## Pitfalls
- STL origin is the part's local origin, which is rarely the joint point. Pre-translate.
- STL is a triangle mesh: fine for visuals, never use it for mass/inertia — always use
  `Shape.MatrixOfInertia` (see `references/mass-properties.md`).

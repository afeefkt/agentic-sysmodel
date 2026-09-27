# STL geometry for Modelica 3D animation

Animation is **optional**: it's for humans (OMEdit 3D view, videos), not for the physics.

## 1. Export from FreeCAD (cad-designer)
```python
import Mesh
Mesh.export([doc.getObject("Arm")], "D:/.../Example/<Project>/CAD/Arm.stl")
```
Leave it in mm and in the CAD frame. Binary is fine. Don't scale or move it in FreeCAD.

## 2. Import into the Modelica package (modelica-modeler)
```
openmodelica_cad_import_shape(
  stl_path    = "Example/<Project>/CAD/Arm.stl",
  package_dir = "Example/<Project>/OpenModelica/<Pkg>",
  body        = "Arm",
  pivot       = [15, 15, 5],                 # frame_a point in STL units (mm)
  axes_map    = {"x": "-y", "y": "x", "z": "z"})
```
This writes `<Pkg>/Resources/Shapes/Arm.stl`: **ASCII, metres, origin at frame_a, axes = model axes**. It returns the URI `modelica://<Pkg>/Resources/Shapes/Arm.stl`, the bounding box (check it: the arm length should appear along the expected model axis), and a declaration:
```modelica
Modelica.Mechanics.MultiBody.Visualizers.FixedShape armShape(
  shapeType = "modelica://<Pkg>/Resources/Shapes/Arm.stl",
  r_shape = {0, 0, 0}, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0},
  length = 1, width = 1, height = 1, color = {180, 180, 190});
connect(revolute.frame_b, armShape.frame_a);     // same frame as the BodyShape's frame_a
```
Set `animation = false` on the matching `BodyShape` so its default cylinder doesn't overlap.

## 3. View it
OMEdit → right-click the top-level model → **Simulate with Animation**, then press play.
If the part is 1000× too big, the scale is wrong. If it points the wrong way, fix `axes_map` (use the same map as `cad_body_parameters`).

## Pitfalls
- **OMEdit needs ASCII STL.** Binary STL (FreeCAD's default) won't render. The import tool always writes ASCII.
- The STL origin is the part's CAD origin (often a corner), rarely the joint. Always give `pivot`.
- STL is a triangle mesh: fine for visuals, never for mass or inertia. Those come from `Shape.MatrixOfInertia` via `mass_properties.json` and `openmodelica_cad_body_parameters`.
- `World.enableAnimation = false` for fast batch or sizing runs.

## How this compares with Simulink / Simscape Multibody
Simscape's *File Solid* block imports geometry and can compute inertia from it and a density. Modelica MultiBody separates the two: **physics = parameters** (m, r_CM, inertia) and **looks = shape file**. This pipeline is the equivalent of *Simscape Multibody Link*: FreeCAD computes the exact mass properties, and the tools map them plus the geometry into the model deterministically.

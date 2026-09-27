---
name: freecad-to-modelica
description: Use when creating geometry in FreeCAD for simulation, extracting mass/centre-of-mass/inertia and joint frames, exporting STL, or mapping FreeCAD data into Modelica BodyShape/joint parameters. Also use when moving CAD assemblies (FreeCAD Assembly workbench) into a Modelica.Mechanics.MultiBody skeleton.
---

# FreeCAD → Modelica data handoff

Goal: turn a FreeCAD part/assembly into the numbers `Modelica.Mechanics.MultiBody` needs — `m`, `r_CM`, `I_11..I_33` per body, and the joint positions/axes for the skeleton. Do all geometry in FreeCAD (mm); hand over **SI (m, kg, kg·m²)**.

## Units (the most common bug)
FreeCAD works in **mm** internally regardless of display units. Modelica works in **m, kg, kg·m²**.
- length: mm × 1e-3 → m
- volume: mm³ × 1e-9 → m³
- density: kg/m³ × 1e-9 → kg/mm³ (only needed to scale the raw inertia)
- inertia: kg·mm² × 1e-6 → kg·m²

## Extracting mass properties (use `freecad_execute_code`)
`Shape.MatrixOfInertia` is **not** kg·mm² — it is the raw **unit-density** tensor in **mm⁵**, taken about the **centre of mass**. Scale it with density and the unit factors:
```python
import FreeCAD as App
doc = App.getDocument("MyDoc")
rho = 2810.0            # kg/m^3 (e.g. Al 7075, state material)
out = {}
for name in ["Strut", "ActuatorCylinder", "ActuatorRod"]:
    s = doc.getObject(name).Shape
    V_m3 = s.Volume * 1e-9
    m = rho * V_m3
    com = s.CenterOfGravity            # mm, world coords (FreeCAD >= 0.20; CenterOfMass on 0.19)
    M = s.MatrixOfInertia              # mm^5, about CoM, unit density
    k = rho * 1e-9 * 1e-6              # (kg/mm^3) * (mm^2 -> m^2) = kg/m^3 * 1e-15
    I = [[M.A11*k, M.A12*k, M.A13*k],
         [M.A21*k, M.A22*k, M.A23*k],
         [M.A31*k, M.A32*k, M.A33*k]]
    out[name] = {"mass": m, "com": [com.x*1e-3, com.y*1e-3, com.z*1e-3], "inertia_com": I}
print(out)
```
**For assemblies**, apply the global placement before reading properties, exactly as the FreeCAD `CenterOfMass` macro does:
```python
import Part
o = Part.getShape(doc.getObject("Strut"))        # local shape
o.Placement = doc.getObject("Strut").getGlobalPlacement()  # world placement
s = o   # then read s.Volume / s.CenterOfGravity / s.MatrixOfInertia as above
```
**Validate once per session with a box:** for a box of sides a×b×c (in m), `I_xx = m(b²+c²)/12`. If your scaled inertia doesn't match, fix the scaling factor before continuing.

Full detail: `references/mass-properties.md` (semantics, conversion, tensor rotation, validation).

## mass_properties.json schema (SI, world frame at reference configuration)
```json
{
  "units": "SI", "reference_configuration": "gear down, locked",
  "world_axes": {"x": "forward", "y": "up", "z": "left"},
  "bodies": {
    "Strut": {"material": "Al7075", "density": 2810, "mass": 12.3,
              "com": [0.0, -0.45, 0.0],
              "inertia_com": [[...],[...],[...]], "stl": "CAD/Strut.stl"}
  },
  "joints": {
    "strutPivot":   {"type": "revolute",  "point": [0.0, 0.0, 0.0],   "axis": [0, 0, 1], "connects": ["world", "Strut"]},
    "actBase":      {"type": "revolute",  "point": [-0.30, 0.05, 0.0], "axis": [0, 0, 1], "connects": ["world", "ActuatorCylinder"]},
    "actSlide":     {"type": "prismatic", "axis_from": "actBase", "axis_to": "rodEnd", "connects": ["ActuatorCylinder", "ActuatorRod"]},
    "rodEnd":       {"type": "revolute",  "point": [-0.10, -0.20, 0.0], "axis": [0, 0, 1], "connects": ["ActuatorRod", "Strut"]}
  },
  "notes": ["simplified primitives", "pins not modeled"]
}
```

## Mapping to Modelica (frame_a at the body's primary joint, axes parallel to world)
- `BodyShape.r    = joint_next.point - joint_primary.point`  (frame_a → frame_b)
- `BodyShape.r_CM = body.com - joint_primary.point`          (frame_a → CoM)
- `BodyShape.m    = body.mass`
- Inertia: MSL takes the six unique terms `I_11, I_21, I_22, I_31, I_32, I_33` of the symmetric matrix `[[I_11 I_21 I_31],[I_21 I_22 I_32],[I_31 I_32 I_33]]`; map `I_11 = inertia_com[0][0]`, `I_21 = inertia_com[1][0]`, `I_22 = inertia_com[1][1]`, `I_31 = inertia_com[2][0]`, `I_32 = inertia_com[2][1]`, `I_33 = inertia_com[2][2]`.
- **Inertia frame:** MSL expects the tensor in a frame parallel to `frame_a` with origin at the CoM. If you rotate the body so frame_a axes are no longer world-aligned, rotate the tensor: `I_a = R · I_world · Rᵀ` where `R` maps world axes to frame_a axes. Do this only if you actually rotate the body; keeping frame_a world-parallel avoids it entirely.
- Fixed pivots: `Parts.Fixed(r = joint.point)`.
- Prismatic axis `n` = unit vector from `actBase` to `rodEnd` at the reference configuration.
- Joint angles are 0 in the reference configuration; retraction then moves `phi` away from 0.

## Getting joint frames from a FreeCAD Assembly
If you built an assembly with the Assembly workbench, each joint is an object with
`Offset1`/`Offset2` placements (the local coordinate systems on each part). For a
revolute/prismatic/cylindrical joint the **motion axis is the local Z** of the LCS.
Read the joint type from the object type and the axis/position from the offsets; see
`references/joint-frames.md` for the exact procedure.

## STL export (for animation — optional for sizing runs)
```python
import Mesh
Mesh.export([doc.getObject("Strut")], "/path/to/CAD/Strut.stl")
```
- STL is dimensionless; FreeCAD assumes the model is in **mm**. `BodyShape`/`Visualizers.Advanced.Shape` assumes external shape files are in **metres** and in **frame_a** coordinates.
- Fix the mm→m mismatch either by scaling the mesh ×1e-3 before export (`Draft.scale`) or by letting Modelica scale: `shapeType="modelica://<Pkg>/Resources/part.stl"` with `extra=1` (uses the body's `length/width/height`). Simplest: scale in FreeCAD and pre-translate so the STL origin sits at `frame_a`.
- Full procedure and pitfalls: `references/stl-animation.md`.

## Rules
- Save the document (`doc.saveAs(...)`) to `Example/<Project>/CAD/<Project>.FCStd`.
- Paths inside `execute_code` run on **Windows** FreeCAD. Use Windows paths: `D:/AI_Learnigns/OMSysModeling/agentic-sysmodel/Example/...`.
- `execute_code_headless` is disabled in this repo's `opencode.json` (no `freecadcmd` in WSL). Use `execute_code` in the GUI, or `execute_code_async` for long operations.
- State every material density: label it SOURCED (datasheet) or ASSUMED.

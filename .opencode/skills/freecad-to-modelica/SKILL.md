---
name: freecad-to-modelica
description: Use when creating geometry in FreeCAD for simulation, extracting mass/centre-of-mass/inertia and joint frames, exporting STL, or mapping FreeCAD data into Modelica BodyShape/joint parameters.
---

# FreeCAD → Modelica data handoff

## Units (the most common bug)
FreeCAD works in **mm**. Modelica works in **m, kg, kg·m²**.
- length: mm × 1e-3 → m
- volume: mm³ × 1e-9 → m³
- inertia: kg·mm² × 1e-6 → kg·m²

## Extracting mass properties (use `freecad_execute_code`)
```python
import FreeCAD as App
doc = App.getDocument("MyDoc")
rho = 2810.0            # kg/m^3 (e.g. Al 7075, state material)
out = {}
for name in ["Strut", "ActuatorCylinder", "ActuatorRod"]:
    s = doc.getObject(name).Shape
    V_m3 = s.Volume * 1e-9
    m = rho * V_m3
    com = s.CenterOfMass                      # mm, world coords
    M = s.MatrixOfInertia                     # about CoM, unit density, mm^5
    k = rho * 1e-9 * 1e-6                     # (kg/mm^3) * (mm^2 -> m^2)
    I = [[M.A11*k, M.A12*k, M.A13*k],
         [M.A21*k, M.A22*k, M.A23*k],
         [M.A31*k, M.A32*k, M.A33*k]]
    out[name] = {"mass": m, "com": [com.x*1e-3, com.y*1e-3, com.z*1e-3], "inertia_com": I}
print(out)
```
**Validate once per session with a box:** for a box of a×b×c, `I_xx = m(b²+c²)/12`. If it doesn't match, fix the scaling before continuing.

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
- `BodyShape.r    = joint_next.point - joint_primary.point`
- `BodyShape.r_CM = body.com - joint_primary.point`
- `BodyShape.m    = body.mass`, and `I_11 = inertia_com[0][0]`, `I_21 = inertia_com[1][0]`, and so on (MSL uses I_11, I_21, I_22, I_31, I_32, I_33)
- Fixed pivots: `Parts.Fixed(r = joint.point)`
- Prismatic axis `n` = the unit vector from `actBase` to `rodEnd` at the reference configuration
- Joint angles are 0 in the reference configuration. Retraction then moves phi away from 0.

## STL export
```python
import Mesh
Mesh.export([doc.getObject("Strut")], "/path/to/CAD/Strut.stl")
```
The STL coordinates are in mm, in world coordinates. For animation, scale by 1e-3 and offset by the frame_a position. Or leave animation off for sizing runs.

## Rules
- Save the document (`doc.saveAs(...)`) to `Example/<Project>/CAD/<Project>.FCStd`.
- Paths inside `execute_code` run on **Windows** FreeCAD. Use Windows paths: `D:/AI_Learnigns/OMSysModeling/agentic-sysmodel/Example/...`.
- `execute_code_headless` is disabled (no freecadcmd in WSL).

# Mass properties: exact semantics and conversion

This file pins down the FreeCAD → SI conversion so the handoff is deterministic.

## What `Shape` gives you (units = mm, regardless of FreeCAD display units)
- `Shape.Volume` → mm³.
- `Shape.CenterOfGravity` → mm, world coordinates (FreeCAD ≥ 0.20). On 0.19 the method
  was `CenterOfMass`; prefer `CenterOfGravity`, fall back if it is missing.
- `Shape.MatrixOfInertia` → the raw inertia tensor at **unit density**, about the
  **centre of mass**, in **mm⁵** (dimension = length⁵). It is *not* kg·mm². It is
  expressed in the shape's local coordinate system; for assemblies apply the global
  placement first (`o.Placement = obj.getGlobalPlacement()`).

## Conversion chain (verified by dimensional analysis + the official CenterOfMass macro)
- `mass [kg] = rho [kg/m³] × Volume [mm³] × 1e-9`
- `I [kg·m²] = MatrixOfInertia [mm⁵] × rho [kg/m³] × 1e-15`

Equivalently, the two-step form the macro uses (easier to reason about):
1. `I [kg·mm²] = MatrixOfInertia [mm⁵] × (rho × 1e-9)`  — apply density in kg/mm³.
2. `I [kg·m²] = I [kg·mm²] × 1e-6`                        — mm² → m².

So the single scale factor is `k = rho × 1e-9 × 1e-6 = rho × 1e-15`.

## Why this is the #1 bug
A common wrong path is to treat `MatrixOfInertia` as already kg·mm² and multiply only by
1e-6. That is off by the missing `rho × 1e-9` density factor, i.e. by orders of magnitude
for a metal part. Always run the box check below.

## Box validation (run once per session)
For a box of sides a, b, c (in **m**) and mass m:
```
I_xx = m·(b² + c²)/12
I_yy = m·(a² + c²)/12
I_zz = m·(a² + b²)/12
```
All products of inertia are zero for an axis-aligned box. If the scaled FreeCAD inertia
doesn't match, the scaling factor (or the placement) is wrong — fix it before proceeding.
Example sanity value: a 100 mm steel cube (rho ≈ 7850 kg/m³, m ≈ 7.85 kg) has
I_xx ≈ 0.0131 kg·m².

## Inertia tensor into Modelica
- MSL `BodyShape` stores the tensor in a frame **parallel to frame_a with origin at the
  CoM**. It takes the six unique terms of the symmetric matrix:
  `I_11, I_21, I_22, I_31, I_32, I_33` for `[[I_11 I_21 I_31],[I_21 I_22 I_32],[I_31 I_32 I_33]]`.
- If `frame_a` axes are world-parallel (the recommended convention), map directly:
  `I_11=M11·k`, `I_22=M22·k`, `I_33=M33·k`, `I_21=M21·k`, `I_31=M31·k`, `I_32=M32·k`.
- If you rotate the body so frame_a is not world-parallel, rotate the tensor first:
  `I_a = R · I_world · Rᵀ`, with `R` the rotation from world axes to frame_a axes.

## Product-of-inertia sign convention (unverified)
The sign of off-diagonal terms between FreeCAD/OCC and MSL has not been confirmed in this
repo. For non-symmetric bodies, validate against a tilted test body. For bodies symmetric
about their frame axes the products are ~0 and this is a non-issue.

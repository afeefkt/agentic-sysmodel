# Extracting joint frames from a FreeCAD Assembly

Use this when you model the assembly in the FreeCAD Assembly workbench and want the
joint positions/axes for the Modelica.Mechanics.MultiBody skeleton. (If you build the
mechanism from scratch as primitives with known placements, you can skip this and write
the joint frames directly.)

## How FreeCAD Assembly stores joints
- Joints live in a "Joints" container in the document tree.
- Each joint object has `Offset1` and `Offset2` placements, which define the local
  coordinate system (LCS) of the joint on each of the two connected parts.
- The joint's type is its object type (e.g. a revolute joint is a
  `Assembly::JointRevolute`; a fixed/grounded connection is a `GroundedJoint`).
- For revolute, prismatic (slider), and cylindrical joints, the **motion axis is the
  local Z axis** of the joint LCS. A revolute rotates about Z; a slider translates along Z.

## Procedure
1. List joints: iterate the "Joints" container (`doc.getObject("Joints").Group` or
   equivalent) and read each joint's `TypeId` and `Offset1`/`Offset2`.
2. For each revolute: record `point = Offset1.Base` (or the LCS origin in world) and
   `axis = Offset1.Rotation.multVec(App.Vector(0,0,1))`.
3. For a prismatic: record the axis direction (Z of the LCS) and the two endpoints that
   the slider travels between.
4. Convert all positions mm → m and write them into `mass_properties.json` `joints`.

## Caveats (unverified here — inspect live first)
- The exact `TypeId` strings and the `Object1`/`Object2` property names vary by FreeCAD
  version. Before writing an extraction script, call `freecad_get_object` on a joint and
  print its `TypeId` and property names.
- The axis being "local Z" is the standard Assembly-workbench convention, but confirm it
  against a known joint before trusting it for a real mechanism.
- If the LCS orientation is not what you expect, remember you only need the **axis unit
  vector** and a **point on the axis** for `Joints.Revolute(n=..., )` /
  `Joints.Prismatic(n=...)` — the other two frame directions are irrelevant to a revolute
  or prismatic joint.

## Fallback when the assembly has no joint objects
For mechanisms assembled with plain Part/Body placement (no Assembly workbench), derive
joint frames from the part placements directly: the hinge point is the centre of the
bearing, and the axis is the bearing axis — both read from the part's `Placement`.

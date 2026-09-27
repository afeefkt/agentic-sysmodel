---
name: modelica-multibody
description: Use when building or fixing 3D/planar mechanisms with Modelica.Mechanics.MultiBody (joints, bodies, kinematic loops, linkages, slider-cranks, landing-gear retraction, actuator attachment, gravity/aero loads, animation).
---

# Modelica MultiBody: working rules

## Component-first
- Start from an MSL example: `openmodelica_list_examples("Modelica.Mechanics.MultiBody.Examples")`. For slider-cranks and linkages, use `get_class_source("Modelica.Mechanics.MultiBody.Examples.Loops.Engine1a")`. For a single hinge + body, use `...Examples.Elementary.Pendulum`.
- Use only MSL parts and joints wired with `connect()`. Every instance needs a `Placement` (see `modelica-diagram-layout`). Frame lines are `color={95,95,95}, thickness=0.5`.
- Full catalog and User's Guide: `knowledge/msl/MultiBody.md`.

## Skeleton every mechanism needs
```modelica
model Mechanism
  import SI = Modelica.Units.SI;
  inner Modelica.Mechanics.MultiBody.World world(n = {0, -1, 0});  // gravity along -y
  // parts + joints ...
end Mechanism;
```
- Exactly **one** `inner World` per top-level model. Sub-models refer to it implicitly (`outer`), so don't declare a second one.
- MSL 4.x: units are `Modelica.Units.SI` (not `Modelica.SIunits`).

## Core components (check exact parameters with `openmodelica_describe_class`)
| Need | Class | Key parameters |
|---|---|---|
| Fixed point on ground | `Parts.Fixed` | `r` (position in world) |
| Rigid offset (no mass) | `Parts.FixedTranslation` | `r` (frame_a→frame_b) |
| Rigid body with 2 frames | `Parts.BodyShape` | `r`, `r_CM`, `m`, `I_11..I_33` (at CoM, frame_a axes) |
| Mass only at one frame | `Parts.Body` | `r_CM`, `m`, inertia |
| Hinge | `Joints.Revolute` | `n` axis, `useAxisFlange`, `phi`, `w` |
| Slider | `Joints.Prismatic` | `n` axis, `useAxisFlange`, `s`, `v` |
| Loop closure (planar) | `Joints.RevolutePlanarLoopConstraint` | `n` |
| Ready-made loop solvers | `Joints.Assemblies.JointRRR`, `JointRRP`, `JointSSP`, … | see describe_class |

All paths are relative to `Modelica.Mechanics.MultiBody.`.

## Kinematic loops (the #1 failure source)
A planar closed loop (a four-bar, or the gear strut + actuator slider-crank) over-constrains the 3D equations.
- **Fix:** in each planar loop, replace **exactly one** `Revolute` with `RevolutePlanarLoopConstraint`. It has no states and no axis flange, so it can't be the driven joint.
- Alternative: use an `Assemblies.JointRRP` / `JointRRR` sub-assembly, which solves the loop analytically.
- All revolute axes in a planar loop must be parallel (e.g. all `n={0,0,1}`).
- Choose **one** independent coordinate for a 1-DOF mechanism (e.g. the strut angle). Give only that one `fixed=true` start values. Other joints get start *guesses* (`phi(start=…)`, no fixed).

## Driving and loading
- Actuator as a force element: a `Prismatic` with `useAxisFlange=true` between the cylinder and rod bodies. Connect a translational force source or custom actuator component between `axis` and `support`.
- Torque on a hinge: `Revolute(useAxisFlange=true)` + `Modelica.Mechanics.Rotational.Sources.Torque`.
- Gravity comes automatically from body masses and `world.n`.
- A simple aero moment on the strut: `Rotational.Sources.Torque` on the strut hinge axis with `tau = f(phi, airspeed)`. Or use `Forces.WorldForce` at the wheel's CoP.
- For kinematics-only checks: drive the independent joint with `Rotational.Sources.Position` (with `exact=false`, needs a filter) or a prescribed angle, and read the dependent joint coordinates.

## Measuring
- Joint coordinates are directly accessible: `strutHinge.phi`, `actuatorSlider.s`, `actuatorSlider.f` (with axis flange).
- Expose metrics at top level: `SI.Angle gearAngle = strutHinge.phi;`, `SI.Length stroke = actuatorSlider.s - s0;`

## Geometry from CAD
- Take `r`, `r_CM`, `m` and `I_*` from `CAD/mass_properties.json` (SI, and see the `freecad-to-modelica` skill).
- Convention: frame_a of each body sits at its primary joint, with axes parallel to world **at the reference configuration**. Then CAD world-coordinate differences map straight into `r` and `r_CM`.
- STL for animation: `shapeType = "modelica://<Package>/Resources/part.stl"` (verify in OMEdit, and scale with `length/width/height` if needed). Animation is optional: `world.enableAnimation=false` speeds up batch runs.

## Gotchas
- A body with zero mass on a free chain gives a singular system. Every chain ending in a joint needs a mass or must close onto a constraint.
- Don't connect two joints directly without a part between them unless it's intended (it's allowed, but check the frame positions).
- Angles are in rad. The sign of `phi` follows the right-hand rule about `n`.
- If you get an "initialization failed" message on a loop, the start guesses are usually on the wrong assembly branch (elbow up vs down). Adjust the guesses.

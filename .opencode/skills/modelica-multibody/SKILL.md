---
name: modelica-multibody
description: Use when building or fixing 3D/planar mechanisms with Modelica.Mechanics.MultiBody (joints, bodies, kinematic loops, linkages, slider-cranks, landing-gear retraction, actuator attachment, gravity/aero loads, animation).
---

# Modelica MultiBody: working rules

## Component-first
- Start from an MSL example: `openmodelica_list_examples("Modelica.Mechanics.MultiBody.Examples")`.
  Slider-crank/linkage → `get_class_source("Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic")`
  (analytic `JointRRP`) or `.Loops.PlanarFourbar` (planar loop constraint). Single hinge +
  body → `...Examples.Elementary.DoublePendulum` / `.Pendulum`.
- Use only MSL parts and joints wired with `connect()`. Every instance needs a `Placement`
  (see `modelica-diagram-layout`). Frame lines: `color={95,95,95}, thickness=0.5`.
- Full component catalog: `references/components.md`. Full User's Guide: `knowledge/msl/MultiBody.md`.

## Skeleton every mechanism needs
```modelica
model Mechanism
  import SI = Modelica.Units.SI;
  inner Modelica.Mechanics.MultiBody.World world(n = {0, -1, 0});  // gravity along -y
  // parts + joints ...
end Mechanism;
```
- Exactly **one** `inner World` per top-level model; sub-models refer to it implicitly (`outer`).
- MSL 4.x: units are `Modelica.Units.SI` (not `Modelica.SIunits`).

## Core components (check exact parameters with `openmodelica_describe_class`)
| Need | Class | Key parameters |
|---|---|---|
| Fixed point on ground | `Parts.Fixed` | `r` (position in world) |
| Rigid offset (no mass) | `Parts.FixedTranslation` | `r` (frame_a→frame_b) |
| Rigid body with 2 frames | `Parts.BodyShape` | `r`, `r_CM`, `m`, `I_11..I_33` (at CoM, frame_a axes) |
| Visual body box/cylinder | `Parts.BodyBox`, `Parts.BodyCylinder` | dims + density |
| Mass only at one frame | `Parts.Body`, `Parts.PointMass` | `r_CM`, `m`, inertia |
| Hinge | `Joints.Revolute` | `n` axis, `useAxisFlange`, `phi`, `w` |
| Slider | `Joints.Prismatic` | `n` axis, `useAxisFlange`, `s`, `v` |
| Spherical / universal / cylindrical / free | `Joints.Spherical`, `.Universal`, `.Cylindrical`, `.FreeMotion` | see describe_class |
| Loop closure (planar) | `Joints.RevolutePlanarLoopConstraint` | `n` |
| Ready-made loop solvers | `Joints.Assemblies.JointRRR/JointRRP/JointSSR/JointSSP/JointUSR/JointUSP/JointUPS` | analytic loop closure |

All paths relative to `Modelica.Mechanics.MultiBody.`

## Kinematic loops (the #1 failure source)
A planar closed loop (four-bar, or gear strut + actuator slider-crank) over-constrains the
3D equations.
- **Fix:** in each planar loop, replace **exactly one** `Revolute` with
  `RevolutePlanarLoopConstraint`. It has no states and no axis flange, so it can't be the driven joint.
- Alternative: use an `Assemblies.JointRRP`/`JointRRR` sub-assembly, which solves the loop analytically.
- All revolute axes in a planar loop must be parallel (e.g. all `n={0,0,1}`).
- Choose **one** independent coordinate for a 1-DOF mechanism (e.g. the strut angle). Give
  only that one `fixed=true` start value; other joints get start *guesses* (`phi(start=…)`, no fixed).

## Driving and loading
- Actuator as a force element: a `Prismatic` with `useAxisFlange=true` between cylinder and
  rod bodies; connect a translational force source or custom actuator component between
  `axis` and `support`.
- Torque on a hinge: `Revolute(useAxisFlange=true)` + `Modelica.Mechanics.Rotational.Sources.Torque`.
- Gravity comes automatically from body masses and `world.n`.
- Aero moment on the strut: `Rotational.Sources.Torque` on the strut hinge axis with
  `tau = f(phi, airspeed)`, or `Forces.WorldForce` at the wheel's centre of pressure.
- Kinematics-only checks: drive the independent joint with `Rotational.Sources.Position`
  (`exact=false`, needs a filter) or a prescribed angle, and read the dependent joint coords.

## Measuring
- Joint coordinates are directly accessible: `strutHinge.phi`, `actuatorSlider.s`, `actuatorSlider.f` (with axis flange).
- Expose metrics at top level: `SI.Angle gearAngle = strutHinge.phi;`, `SI.Length stroke = actuatorSlider.s - s0;`

## Geometry from CAD
- Take `r`, `r_CM`, `m`, `I_*` from `CAD/mass_properties.json` (SI; see `freecad-to-modelica`).
- Convention: frame_a of each body sits at its primary joint, axes parallel to world **at the
  reference configuration**. Then CAD world-coordinate differences map straight into `r` and `r_CM`.
- STL animation: `shapeType = "modelica://<Package>/Resources/part.stl"` (verify in OMEdit;
  scale with `length/width/height` or scale the mesh — see `freecad-to-modelica`).
  Animation is optional: `world.enableAnimation=false` speeds up batch runs.

## Gotchas
- A zero-mass body on a free chain gives a singular system. Every chain ending in a joint
  needs a mass or must close onto a constraint.
- Don't connect two joints directly without a part between them unless intended (check frame positions).
- Angles are in rad. The sign of `phi` follows the right-hand rule about `n`.
- "initialization failed" on a loop → start guesses are usually on the wrong assembly
  branch (elbow up vs down). Adjust the guesses.

Full component catalog and loop patterns: `references/components.md`. Sources: `references/sources.md`.

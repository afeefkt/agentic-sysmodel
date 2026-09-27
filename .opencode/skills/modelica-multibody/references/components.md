# MultiBody component catalog (concise reference)

All paths relative to `Modelica.Mechanics.MultiBody.`. Verify exact parameter names with
`openmodelica_describe_class` before instantiating.

## Frames & bodies
| Class | Purpose | Key parameters |
|---|---|---|
| `World` | global frame + gravity + animation | `n` (gravity dir), `g`, `enableAnimation` |
| `Parts.Fixed` | fixed point on ground | `r` (world position) |
| `Parts.FixedTranslation` | rigid massless offset | `r` (frame_a→frame_b) |
| `Parts.FixedRotation` | rigid massless rotation | `n`, `angle` |
| `Parts.Body` | rigid body, one frame + CoM | `m`, `r_CM`, `I_11..I_33` |
| `Parts.BodyShape` | rigid body + visual shape | `m`, `r_CM`, `I_*`, `r`, `shapeType` |
| `Parts.BodyBox` | box with visual, auto mass | `r`, `length/width/height`, `density` |
| `Parts.BodyCylinder` | cylinder with visual, auto mass | `r`, `length/diameter`, `density` |
| `Parts.PointMass` | point mass at frame | `m` |

## Joints (1-DOF unless noted)
| Class | DOF | Key parameters |
|---|---|---|
| `Joints.Revolute` | 1 rot | `n`, `phi`, `w`, `useAxisFlange` |
| `Joints.Prismatic` | 1 trans | `n`, `s`, `v`, `useAxisFlange` |
| `Joints.Spherical` | 3 rot | — |
| `Joints.Universal` | 2 rot | `n_a`, `n_b` |
| `Joints.Cylindrical` | 1 rot + 1 trans | `n` |
| `Joints.FreeMotion` | 6 | — |
| `Joints.RevolutePlanarLoopConstraint` | 0 (constraint) | `n` — replaces one revolute in a planar loop |

## Analytic loop assemblies (`Joints.Assemblies.*`)
| Class | Joints solved |
|---|---|
| `JointRRR` | 3 revolute (revolute-revolute-revolute) |
| `JointRRP` | 2 revolute + 1 prismatic |
| `JointSSR` | 2 spherical + 1 revolute |
| `JointSSP` | 2 spherical + 1 prismatic |
| `JointUSR` | universal + spherical + revolute |
| `JointUSP` | universal + spherical + prismatic |
| `JointUPS` | universal + prismatic + spherical |

## Forces & sensors
| Class | Purpose |
|---|---|
| `Forces.WorldForce`, `Forces.WorldTorque` | force/torque resolved in world frame |
| `Forces.Force`, `Forces.Torque` | force/torque resolved in frame_a |
| `Forces.Spring`, `Forces.Damper` | spring/damper between two frames |
| `Forces.LineForceWithMass` | line force with mass (cable/rod) |
| `Sensors.AbsoluteSensor`, `Sensors.RelativeSensor` | position/velocity/angle |
| `Sensors.Distance`, `Sensors.CutForce` | distance / reaction force |

## Loop patterns (memorize these two)
1. **Planar loop** (e.g. slider-crank): make it planar by aligning all joint axes (all
   `n={0,0,1}`), then replace **one** revolute with `RevolutePlanarLoopConstraint`. Drive
   only the single independent coordinate; others are start guesses.
2. **Analytic loop**: if the loop matches an `Assemblies.Joint*` pattern, instantiate that
   assembly — it solves the loop analytically and is more robust than the planar constraint.

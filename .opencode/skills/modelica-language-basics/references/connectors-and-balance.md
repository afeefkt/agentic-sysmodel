# Connectors and balanced models (the fine print)

## Connector variable classes
- **potential** (`v`, `phi`, `p`, `T`): equal at a connection node.
- **flow** (`i`, `f`, `tau`, `m_flow`, `Q_flow`): summed to zero at a connection node.
- **stream** (fluid port enthalpy `h_outflow` etc.): use `inStream()`/`actualStream()`;
  bidirectional, not simply equal or summed. Only `Modelica.Fluid` ports normally need this.

## What `connect(a, b)` expands to
For non-stream connectors:
```
connect(A.x, B.y);
// ==>
A.x.potential = B.y.potential;   // equality of potentials
A.x.flow + B.y.flow = 0;         // sum of flows
```
Multiple connects to the same node chain these: all potentials equal, all flows sum to zero.

## Balance counting (how to spot an over/under-determined model)
- Every `model`/`block` needs `#equations == #unknowns`. Unknowns include all variables
  that are states, iteration variables, or declared but unsolved.
- Each unconnected **flow** variable is auto-set to 0 (a connector's flow set to zero when
  not connected). So an unconnected flange "hangs free" (zero force/torque) — that is
  usually the cause of a "too few equations / under-determined" error.
- `RealInput`/`RealOutput` (and any causal connector) contribute one equation or unknown
  each; an unconnected top-level `RealInput` is a missing equation.
- An over-determined system ("too many equations") almost always comes from defining a
  variable twice: a `connect` plus an explicit equation on the same variable, or a planar
  loop that needs a `RevolutePlanarLoopConstraint`.

## Causal vs acausal connectors (the rule of thumb)
- `RealInput`/`RealOutput`/`BooleanInput`/…: **causal**, signal flow. Use for sensors and controllers.
- `Pin`, `Flange_a/b`, `Frame_a/b`, `FluidPort`, `HeatPort`, `Plug`: **acausal**, physical. Use for plant.
- A `block` must have only causal connectors; a `model` can have both (but keep physics acausal).

## Base classes to extend for custom components
| Domain | Partial to extend | Provides |
|---|---|---|
| Electrical | `Electrical.Analog.Interfaces.OnePort` | `p`, `n` pins |
| Rotational | `Mechanics.Rotational.Interfaces.PartialTwoFlanges` | `flange_a`, `flange_b` |
| Translational | `Mechanics.Translational.Interfaces.PartialCompliant` | `flange_a`, `flange_b`, `s_rel` |
| MultiBody | `Mechanics.MultiBody.Interfaces.PartialTwoFrames` | `frame_a`, `frame_b` |
| Blocks | `Blocks.Interfaces.SISO` / `MISO` | causal `u`/`y` |

Extending these gives you correctly-typed, correctly-placed connectors for free (and the
`modelica-diagram-layout` skill relies on them for the icon).

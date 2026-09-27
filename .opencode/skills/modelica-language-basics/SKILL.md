---
name: modelica-language-basics
description: Use when writing any Modelica code or when reasoning about model structure — acausal vs signal-flow modeling, connectors (potential/flow), connect semantics, packages, inheritance/replaceable, parameters, initialization, events, units. Essential for engineers coming from Simulink.
---

# Modelica essentials (for model-based-design engineers)

## Think acausal, not block diagram
- Simulink wires **signals** (input → output). Modelica components are connected through **physical connectors**. Each connector carries a *potential* variable (voltage, position, angle, pressure, temperature) and a *flow* variable (current, force, torque, mass flow, heat flow).
- `connect(a.p, b.n)` produces **equal potentials** and **flows that sum to zero** at the node. The direction of power flow is not fixed in advance.
- Therefore: model plants with physical connectors (`Pin`, `Flange`, `Frame`, `FluidPort`, `HeatPort`). Use `RealInput`/`RealOutput` **only for real signals**: sensor outputs, commands, controller I/O.
- ❌ An anti-pattern we've seen: re-writing a machine or inverter as blocks with `RealInput u_d, u_q ...` wired by equations. That discards the physics connectors and the MSL components. ✅ Use the MSL machine and converter with pins and flanges instead.

## Structure
```modelica
package MyProject
  package Components  "custom reusable parts (only if MSL lacks them)"  end Components;
  package Controls    "controllers / logic (control-expert)"            end Controls;
  model System "top-level test model: MSL + custom components, connect() only"
    ...
  end System;
end MyProject;
```
- One class per file is optional. Files in a package directory start with `within MyProject;`.
- Class kinds: `model` (physics), `block` (signal-only, all I/O causal), `connector`, `record` (parameter sets), `function`, `package`, `type`.

## Parameters and modifiers
- `parameter SI.Length L = 0.5 "description";`: set at the top level so tuners can override them at run time (`simflags -override`).
- Modify sub-component parameters where you instantiate them: `Revolute rev(n = {0,0,1}, useAxisFlange = true);`
- Propagate a design parameter downward: `LumpedActuator act(D_bore = D_bore);`
- `final parameter` can't be overridden. Avoid it on anything the design-tuner should change.
- Parameter records (e.g. `Modelica.Electrical.Machines.Utilities.ParameterRecords.SM_PermanentMagnetData`) keep machine data in one place.

## Inheritance and replaceability
- `extends Base(...);` reuses connectors, equations and parameters. Extend the MSL partials for custom components.
- `replaceable model Load = ... constrainedby Partial...;` makes variants (nominal vs degraded) swappable without copying.

## Initialization
- `x(start = x0, fixed = true)` makes the start value mandatory. Without `fixed`, it's just a guess for the solver.
- `initial equation der(x) = 0;` gives a steady-state start.
- Fix only **independent states**. Too many `fixed=true` gives an over-determined initialization.
- Many MSL components have `initType` / `phi(fixed=true)` / `w(fixed=true)` options. Use those instead of extra equations.

## Events and discontinuities
- `if`, `abs`, `sign`, `min`/`max` and relations create events (solver restarts). Many of them slow the simulation down.
- Use `noEvent()` only where the expression is smooth enough, or regularize (`tanh`, smooth steps).
- `when` / `sample()` / `pre()` are for discrete logic. For sequencing, prefer Modelica.StateGraph or Blocks.Logical.

## Units
- Use `import SI = Modelica.Units.SI;` and typed declarations (`SI.Pressure p`). Unit checking catches mistakes.
- MSL 4.x: `Modelica.Units.SI`, not `Modelica.SIunits` (MSL 3.x).

## Balanced models
Each model must have exactly as many equations as unknowns. Connectors count toward this: flow variables of unconnected connectors are set to zero automatically. Top-level `RealInput`s must be connected or given a value.

Further reading (cite, do not copy): P. Fritzson, *Modelica tutorial* (user's local copy in `knowledge/`); M. Tiller, *Modelica by Example* https://mbe.modelica.university (CC BY-NC-ND).
Full language rules: `knowledge/web/spec-connectors.md`, `spec-equations.md`, `spec-classes.md`, `spec-inheritance.md` (Modelica Language Spec 3.6).

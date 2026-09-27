# Library-access workflow (how to discover MSL components reliably)

The four discovery tools and exactly how to chain them. This is the anti-hallucination
procedure: **never type a class name from memory — always confirm it with one of these
tools first.**

## 1. `openmodelica_search_library(query, limit=25, include_partial=False)`
- Searches **names and descriptions** of MSL classes. Put the need in plain words:
  `"permanent magnet synchronous machine"`, `"hydraulic cylinder"`, `"PID anti windup"`,
  `"prismatic joint"`, `"six phase machine"`.
- First call builds the search index (≈1 min); later calls are fast.
- `include_partial=true` also returns partial base classes (e.g. `PartialCompliant`,
  `PartialTwoFlanges`) you may want to extend for a custom component.
- If the query returns nothing useful, **rephrase** (synonyms, singular/plural) before
  concluding the component doesn't exist.

## 2. `openmodelica_describe_class(name, doc_chars=1500)`
Returns: `comment`, `restriction` (model/block/connector/record/package/type/function),
`parameters`, `components` (instances/connectors), `children` (nested classes),
`documentation` (excerpt), and **`inherited_parameters`** (parameters declared in base
classes, grouped by the base class that declares them).

Use it to:
- Confirm a class exists before instantiating it.
- Read the exact parameter **names and defaults** (e.g. `LimPID` has `controllerType`,
  `k`, `Ti`, `Td`, `yMax`, `yMin`, `Ni`, `Nd`, `initType`).
- Find inherited parameters that don't show in the class body (e.g. a machine's phase
  count `m`, or `Lssigma` inherited from `FundamentalWave.BasicMachines.Machine`).

## 3. `openmodelica_list_examples(package, limit=60)`
Lists example models under a package, e.g. `"Modelica.Electrical.Machines"` or
`"Modelica.Mechanics.MultiBody"`. Pick the example closest to your system.

## 4. `openmodelica_get_class_source(name, max_chars=12000)`
Returns the full Modelica source of a library class **including its Placement/Line
annotations**. Copy the component structure *and* the diagram layout. This is how the
`modelica-diagram-layout` skill sources its layout conventions.

## Recommended chain for a new subsystem
```
search_library("need") → describe_class(best hit) → list_examples(parent package)
→ get_class_source(closest example) → copy structure + layout
```

## When the search comes up empty
1. Re-run with `include_partial=true` (a partial may be what you extend).
2. Try the `knowledge/msl/<Domain>.md` catalog — it lists components by subsystem.
3. Only then write a custom component. Record the search (query + result) in
   `architecture.md` under "Assumptions" as the justification, per repo rule 4a.

## Two packages can share a class name
`SM_PermanentMagnet` exists in both `Modelica.Electrical.Machines.BasicMachines.SynchronousMachines`
(3-phase) and `Modelica.Magnetic.FundamentalWave.BasicMachines.SynchronousMachines`
(m-phase). Always use the fully-qualified name and check which package your example imports.

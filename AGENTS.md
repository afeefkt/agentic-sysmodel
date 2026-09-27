# agentic-sysmodel — project rules (read by every agent)

## What this repo is
A multi-agent workflow that turns a system need into a **verified** physical model:
requirements → architecture → CAD (FreeCAD) → Modelica model (OpenModelica) → simulation → requirement verification → parameter sizing.
Each system lives in `Example/<ProjectName>/`.

## Project folder convention
```
Example/<Project>/
  PLAN.md               # sysarch: build steps + status
  architecture.md       # sysarch: subsystems, interfaces, assumptions
  state.json            # sysarch: current step, iteration count, open issues
  Requirements/requirements.yaml    # req-engineer
  CAD/*.FCStd, CAD/*.stl, CAD/mass_properties.json   # cad-designer
  OpenModelica/<Package>/package.mo + *.mo           # modelica-modeler
  Results/parameters.json, tuning_log.md             # design-tuner
  Results/verification_report.md                     # sim-verifier
  Tests/cases.yaml                                   # sim-verifier (nominal + edge cases)
  OpenModelica/<Package>/Controls/*.mo               # control-expert
  Results/control_design.md                          # control-expert
  Results/plots/*.png, Results/data/*.csv|xlsx       # data-analyst, sim-verifier
```

## Hard rules
1. **SI units everywhere** (m, kg, s, N, Pa, rad). FreeCAD works in mm: convert at export and say so.
2. **Never invent results.** Every number in a report must come from a tool call (simulate/read_results/verify) in this session. If a tool fails, report the failure.
3. **Never invent Modelica classes.** Look up MSL components with `openmodelica_describe_class` before using them.
4. A model is only "done" when `openmodelica_check` returns ok, a smoke simulation runs, **and `openmodelica_diagram_check` returns ok**.
4a. **Component-first modeling** (the model must be a visible, connected diagram in OMEdit):
   - Search first: `openmodelica_search_library` → `openmodelica_list_examples` → `openmodelica_get_class_source` of the closest MSL example. Start from its structure and layout.
   - Instantiate MSL components and wire them **only with `connect()`** on physical connectors (flange, frame, pin/plug, fluid port, heat port). Plain equations only inside custom components or for exposed metric variables.
   - A custom component is allowed only when the search finds nothing suitable. Write down the search in `architecture.md`. Build it as a reusable model in `<Pkg>/Components/` (or a `block` in `Controls/`) with physical connectors (extend MSL partials) and an Icon.
   - **Every component instance has a `Placement` annotation, and every `connect` has a `Line`** (skill `modelica-diagram-layout`).
   - Never re-implement physics that MSL already provides (machines, converters, joints, masses, circuits) as RealInput/RealOutput equation blocks.
5. Paths passed to MCP tools are relative to this repo root (e.g. `Example/LandingGearMechanism/OpenModelica/LandingGear/package.mo`).
6. Every assumption goes in `architecture.md` under "Assumptions". Label it ASSUMED vs SOURCED (with source).
7. Keep outputs small: summarize tool results and do not paste whole result files.
8. Don't touch `../external/` (upstream repos). `knowledge/` is **read-only reference**. Read files there when a skill points to them (MSL catalogs and User's Guides in `knowledge/msl/`, OpenModelica User's Guide and Modelica Spec chapters in `knowledge/web/`).

## Skills
Load the relevant skill (`skill` tool) before starting work in its area. Each agent prompt lists its core skills.
- Language and structure: `modelica-language-basics`, `modelica-diagram-layout`, `msl-library-map`
- Domains: `modelica-multibody`, `modelica-hydraulic-actuator`, `modelica-electrical-drives`, `modelica-control`
- Running and fixing: `openmodelica-simulation`, `modelica-debugging`
- Process: `freecad-to-modelica`, `requirements-verification`, `skill-authoring`

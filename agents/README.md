# Agent team

| Agent | Role | Model (prototype) | Tools |
|---|---|---|---|
| `sysarch` (primary) | Architect and orchestrator: plans, delegates, keeps traceability | deepseek-v4-pro | Task, `openmodelica_describe_class` |
| `req-engineer` | Measurable requirements + verification cases | deepseek-flash | files only |
| `cad-designer` | FreeCAD geometry → mass properties + joint frames | deepseek-flash | `freecad_*` |
| `modelica-modeler` | Writes and fixes Modelica models | deepseek-v4-pro | `openmodelica_check/simulate/describe_class/...` |
| `design-tuner` | Parameter sizing against requirements | deepseek-v4-pro | `openmodelica_simulate/read_results/verify` |
| `sim-verifier` | Independent V&V, writes the report with plots and xlsx | deepseek-flash | `openmodelica_simulate/verify/measure/plot/...` |
| `control-expert` | Controllers, sequencing logic, linearization, margins, robustness | deepseek-v4-pro | `openmodelica_linearize/frequency_analysis/measure/...` |
| `data-analyst` | Measurements, case tables, PNG plots, CSV/Excel on request | deepseek-flash | `openmodelica_measure/compare_cases/plot/export_data` |

Measuring, plotting and exporting are **deterministic MCP tools** (`tools/om_mcp/analysis.py`), so the numbers are exact and repeatable. `data-analyst` is just a cheap front end that turns requests into tool calls.
DeepSeek can't see images, so plots are for humans. Agents reason with the numbers.

Prompts live in `agents/prompts/*.md`. Models, tools and permissions live in `../opencode.json` (the only file to edit when switching models).

## Flow
```
user need
   │
sysarch ──► req-engineer ──► Requirements/requirements.yaml
   │──► architecture.md, PLAN.md, state.json
   │──► cad-designer ──► CAD/mass_properties.json (+ .FCStd/.stl)
   │──► modelica-modeler ──► OpenModelica/<Pkg>/*.mo  (check + smoke sim)
   │──► control-expert ──► OpenModelica/<Pkg>/Controls/*.mo + control_design.md
   │──► data-analyst ──► tables, Results/plots/*.png, Results/data/*.xlsx (on demand)
   │──► sim-verifier ──► Results/verification_report.md
   │        FAIL? ── model bug ──► modelica-modeler
   │              └─ spec gap ──► design-tuner ──► parameters.json ──► sim-verifier
   ▼
report to user, next build step
```

## Using it
- Start `opencode` in `agentic-sysmodel/`. `sysarch` is the default agent. Tab switches primary agents.
- Call a subagent directly: `@modelica-modeler ...`.
- Phase-in: begin with sysarch + modelica-modeler + sim-verifier, then add CAD, then tuning.

## Switching models later
Edit the `"model"` lines in `opencode.json`, for example `"anthropic/claude-sonnet-5"` for the modeler. Keep verifier and modeler on **different** models if you can: that makes the verification more independent.

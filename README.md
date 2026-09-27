# agentic-sysmodel

**A multi-agent workflow that turns an engineering need into a verified physical system model**: requirements → architecture → CAD (FreeCAD) → acausal Modelica model (OpenModelica) → simulation → requirement-based verification → design sizing.

It runs in [opencode](https://opencode.ai) with DeepSeek models for prototyping, and every model choice lives in one config file. The first flagship example is the **sizing and verification of a nose-landing-gear retraction actuator**.

![selftests](https://github.com/OWNER/agentic-sysmodel/actions/workflows/selftests.yml/badge.svg)

---

## Why this exists
LLMs can write Modelica code that *compiles* and still violates the physics or the requirements. This project wraps the LLMs in an engineering process:

- **Requirements drive verification.** Every REQ maps to a model variable, a machine-checkable criterion and edge cases (cold fluid, degraded pump, …).
- **Independent verification.** The verifier agent can't edit models. It runs cases and issues PASS/FAIL with evidence from tool calls only.
- **Component-first, engineer-readable models.** Standard-library components are wired with `connect()` and laid out for the OMEdit diagram. A `diagram_check` gate rejects equation-only "code models".
- **Deterministic numbers.** Measurements, margins, plots and exports come from tested tools, not from the LLM.

## Architecture

```mermaid
flowchart LR
  U[Engineer] --> SA[sysarch<br/>orchestrator]
  SA --> RE[req-engineer]
  SA --> CAD[cad-designer]
  SA --> MM[modelica-modeler]
  SA --> CE[control-expert]
  SA --> DT[design-tuner]
  SA --> SV[sim-verifier]
  SA --> DA[data-analyst]
  CAD -- MCP --> FC[(FreeCAD<br/>freecad-mcp)]
  MM & CE & DT & SV & DA -- MCP --> OM[(OpenModelica<br/>om_mcp server)]
  OM --> OMC[omc + MSL 4.1]
```

| Agent | Role | Tools |
|---|---|---|
| `sysarch` (primary) | plans, delegates, keeps requirement→evidence traceability | library search |
| `req-engineer` | measurable requirements + verification cases | files |
| `cad-designer` | FreeCAD geometry → mass properties and joint frames (SI) | FreeCAD MCP |
| `modelica-modeler` | component-based Modelica models | check, simulate, library search, class source, diagram check |
| `control-expert` | controllers, sequencing logic, linearization and margins | linearize, frequency analysis, measure |
| `design-tuner` | parameter sizing against requirements | simulate with overrides, verify |
| `sim-verifier` | independent V&V report | simulate, verify, measure, plot, export |
| `data-analyst` | measurements, case tables, plots, CSV/Excel | measure, compare, plot, export |

### OpenModelica MCP server (`tools/om_mcp`, 17 tools)
| Group | Tools |
|---|---|
| Build and run | `check`, `simulate` (run-time parameter overrides, tagged cases), `describe_class` |
| Library-first | `search_library`, `list_examples`, `get_class_source`, `diagram_check` |
| Results | `read_results`, `list_variables`, `time_to_reach`, `verify` |
| Analysis | `measure` (rise/settling/overshoot/…), `compare_cases`, `plot`, `export_data` (CSV/XLSX) |
| Control | `linearize` (A,B,C,D), `frequency_analysis` (poles, GM/PM, bandwidth, Bode) |

Every analysis tool is checked against analytic results in `tools/om_mcp/selftest_*.py`.

### Skills (`.opencode/skills/`)
Modelica language basics for model-based-design engineers, diagram layout, an MSL library map, MultiBody, hydraulic actuators, electrical drives, control design, debugging, simulation settings, FreeCAD→Modelica handoff, requirements and verification, and skill authoring. They are backed by a generated knowledge base (`tools/knowledge/`) built from the MSL User's Guides, the OpenModelica User's Guide and the Modelica Language Specification.

## Quick start (Windows + WSL2)
Prerequisites: WSL2 Ubuntu with OpenModelica (`omc`), `uv`, opencode (Linux build), and FreeCAD on Windows with the freecad-mcp addon.
```bash
# 1. OpenModelica in WSL + Modelica Standard Library
sudo apt install omc   # after adding the OpenModelica apt repo
echo 'installPackage(Modelica); getErrorString();' > /tmp/i.mos && omc /tmp/i.mos

# 2. Clone next to the upstream FreeCAD MCP
git clone <this repo> agentic-sysmodel
git clone https://github.com/neka-nat/freecad-mcp external/freecad-mcp   # sibling folder ../external/

# 3. Self-tests (no LLM needed)
cd agentic-sysmodel/tools/om_mcp && uv run python selftest.py && uv run python selftest_control.py && uv run python selftest_library.py

# 4. Optional knowledge base for the skills
cd ../.. && python3 tools/knowledge/fetch_web_docs.py && uv run --directory tools/om_mcp python ../knowledge/build_msl_knowledge.py

# 5. Run (set DEEPSEEK_API_KEY or use /connect inside opencode)
opencode          # or start-agent.bat from Windows
```
Enable WSL mirrored networking (`networkingMode=mirrored` in `%UserProfile%\.wslconfig`) so the FreeCAD RPC server on Windows is reachable on `localhost:9875`.

## Repository layout
```
opencode.json            agents, models, MCP servers, per-agent tool permissions
AGENTS.md                project rules for every agent
agents/prompts/          one system prompt per agent
.opencode/skills/        domain skills
tools/om_mcp/            OpenModelica MCP server + self-tests
tools/knowledge/         knowledge-base builders (MSL docs, OM User's Guide, Modelica spec)
Example/<Project>/       Requirements/, CAD/, OpenModelica/, Results/, Tests/, PLAN.md, architecture.md
```

## Status
- [x] Agent team, OpenModelica MCP server, control and analysis tools, library-first gate, skills, knowledge base
- [ ] Flagship: NLG retraction actuator, all 5 build steps verified, with 3D animation
- [ ] Deterministic FreeCAD → Modelica exporter
- [ ] Agent benchmark (pass rate, cost, with/without skills, model comparison)
- [ ] Auto-generated verification dossier; Monte Carlo robustness

## What is mine vs. what I built on
**Built here:** the multi-agent process and prompts, the OpenModelica MCP server (analysis, control, library-discovery and diagram-quality tools), the skills and knowledge-base pipeline, the requirement-driven verification workflow and the examples.
**Built on:** [omagent](https://github.com/MasoudMiM/omagent) (BSD-3) for the omc session and verifiers, [freecad-mcp](https://github.com/neka-nat/freecad-mcp) (MIT), OpenModelica and the Modelica Standard Library. See [NOTICE.md](NOTICE.md).

> Simulation results are engineering estimates from models with documented assumptions (marked ASSUMED vs SOURCED). They are not certified data.

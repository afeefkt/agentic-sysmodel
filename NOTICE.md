# Notices and attributions

This project is an **integration layer**. It builds on the open-source work below. Upstream licenses apply to their code.

| Component | Used for | License | Source |
|---|---|---|---|
| **omagent** (Masoud Masoumi) | omc session wrapper, diagnostics parsing, result loading, verifiers, used by `tools/om_mcp` | BSD-3-Clause | https://github.com/MasoudMiM/omagent (pinned commit in `tools/om_mcp/pyproject.toml`) |
| **freecad-mcp** (neka-nat) | MCP server + FreeCAD addon used by the `cad-designer` agent | MIT | https://github.com/neka-nat/freecad-mcp |
| **OpenModelica** | Modelica compiler/simulator (`omc`), OMEdit | OSMC-PL / GPL / EPL (see openmodelica.org) | https://openmodelica.org |
| **Modelica Standard Library 4.1.0** | component library; User's Guides extracted into `knowledge/msl/` (generated, not committed) | BSD-3-Clause, © Modelica Association | https://github.com/modelica/ModelicaStandardLibrary |
| **OpenModelica User's Guide** | chapters fetched into `knowledge/web/omug-*` (generated, not committed); summarized in skills | CC BY 4.0, © Open Source Modelica Consortium | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/ |
| **Modelica Language Specification 3.6** | chapters fetched into `knowledge/web/spec-*` (generated, not committed) | free distribution with copyright notice, © Modelica Association | https://specification.modelica.org |
| Model Context Protocol Python SDK | MCP server framework | MIT | https://github.com/modelcontextprotocol/python-sdk |

Cited only, not copied: *Modelica by Example* (M. Tiller, CC BY-NC-ND), https://mbe.modelica.university, and P. Fritzson's Modelica tutorials.

Example parameter sources are cited inside each `Example/<Project>/` (e.g. the machine data from Eldeeb et al., IEEE PEDS 2017, and public L-39NG actuator figures). Values marked **ASSUMED** are not sourced.

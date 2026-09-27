# Sources — openmodelica-simulation

| Fact area | Source | License | Confidence |
|---|---|---|---|
| Solver list, defaults, initialization, tearing | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/solving.html | CC BY 4.0 | high |
| Simulation flags (`-tolerance`, `-stopTime`, `-numberOfIntervals`, `-abortSlowSimulation`, `-mei`, `-noEquidistantTimeGrid`, `-override`) | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/simulationflags.html | CC BY 4.0 | high |
| omc scripting API signatures (`simulate`, `checkModel`, `loadFile`, `readSimulationResult`, `linearize`, …) | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html | CC BY 4.0 | high |
| OMPython (`OMCSessionZMQ`, `ModelicaSystem`) | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/ompython.html | CC BY 4.0 | high |
| `.mat` (MAT v4) result format | https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/technical_details.html | CC BY 4.0 | medium |
| `linearize` semantics (top-level input/output, operating point) | https://build.openmodelica.org/Documentation/OpenModelica.Scripting.linearize.html | — | high |
| OpenModelica repo | https://github.com/OpenModelica/OpenModelica (OSMC license) | OSMC-License | high |
| Local curated copies | `knowledge/web/omug-{solving,simulation-flags,scripting-api,faq,omedit,ompython,plotting}.md` | CC BY 4.0 | high |

Notes:
- The OpenModelica User's Guide is CC BY 4.0, © 1998–2026 OSMC; safe to quote/adapt
  with attribution.
- `-override` limitation wording (structural/final/protected/evaluated) is corroborated by
  the flag doc (high) and the forum (medium).
- OMEdit's exact default grid spacing and Placement defaults were not numerically
  verified — see the `modelica-diagram-layout` skill for the grid convention this repo uses.

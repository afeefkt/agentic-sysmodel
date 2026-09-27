# Sources — modelica-control

| Fact area | Source | License | Confidence |
|---|---|---|---|
| Blocks catalog, LimPID parameters | local `knowledge/msl/Blocks.md` (MSL 4.1.0) | BSD-3-Clause | high |
| StateGraph catalog | local `knowledge/msl/StateGraph.md` | BSD-3-Clause | high |
| Clocked catalog | local `knowledge/msl/Clocked.md` | BSD-3-Clause | high |
| Linearize semantics (top-level input/output, operating point) | https://build.openmodelica.org/Documentation/OpenModelica.Scripting.linearize.html | — | high |
| Example templates (PID_Controller, SpeedControlledDCPM, StateGraph.Examples) | MSL 4.1.0 examples | BSD-3-Clause | high |

Note: the design rules of thumb (PM/GM targets, crossover placement, Ti ≈ 3–5/ω_c) are
standard classical-control practice, not from a single cited source; treat them as
engineering guidance, and always confirm with `frequency_analysis` on the actual loop.

# Sources — msl-library-map

Primary sources for MSL 4.1 facts, class names and parameters. All class names
were additionally cross-checked against the local curated catalogs in
`knowledge/msl/*.md` (generated from the installed MSL 4.1.0).

| Fact area | Source | License | Confidence |
|---|---|---|---|
| MSL 4.1.0 release, package structure, `Modelica.Units.SI` rename | https://github.com/modelica/ModelicaStandardLibrary/releases/tag/v4.1.0 and /tag/v4.0.0 | BSD-3-Clause | high |
| MSL repo | https://github.com/modelica/ModelicaStandardLibrary (≈616★, BSD-3-Clause) | BSD-3-Clause | high |
| Doc portal | https://doc.modelica.org/ | — | high |
| OpenModelica mirror of MSL docs | `https://build.openmodelica.org/Documentation/<Dotted.Name>.html` | — | high |
| Per-package component lists & example paths | local `knowledge/msl/{General,Rotational,Translational,MultiBody,ElectricalAnalog,Polyphase,Machines,FundamentalWave,PowerConverters,Blocks,StateGraph,Clocked,HeatTransfer,Fluid}.md` | BSD-3-Clause | high |
| FundamentalWave `SM_PermanentMagnet` params (Lmd/Lmq/Lrsigma*/Lssigma) | https://raw.githubusercontent.com/modelica/ModelicaStandardLibrary/v4.1.0/Modelica/Magnetic/FundamentalWave/BasicMachines/SynchronousMachines/SM_PermanentMagnet.mo | BSD-3-Clause | high |
| `Polyphase.Functions.symmetricOrientation` | https://build.openmodelica.org/Documentation/Modelica.Electrical.Polyphase.Functions.symmetricOrientation.html | BSD-3-Clause | high |

Notes:
- Star/fork counts are a live snapshot and will drift.
- `Modelica.Media` is a separate library from MSL; its internal class tree is not
  enumerated in `knowledge/`. Verify specific media paths with
  `openmodelica_describe_class`.
- Confidence "high" = verified against the installed library or the v4.1.0 source
  tree in this session; "medium" = from documentation description only.

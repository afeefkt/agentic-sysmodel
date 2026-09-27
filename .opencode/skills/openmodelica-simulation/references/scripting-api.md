# omc scripting API & OMPython (what sits under the MCP tools)

The `openmodelica_*` MCP tools are thin wrappers over the omc scripting API. Knowing the
underlying commands helps you understand tool errors and write correct requests.

## Core omc commands (signatures from the User's Guide)
- `loadFile(fileName, encoding="UTF-8", uses=true, notify=true, requireExactVersion=false, allowWithin=true) → Boolean`
- `checkModel(className) → String` — returns empty on success; errors otherwise.
- `getErrorString(warningsAsErrors=false) → String` — the last error message(s).
- `listVariables() → TypeName[:]` — all instantiated class names.
- `simulate(className, startTime, stopTime=1.0, numberOfIntervals=500, tolerance=1e-6, method="<default>", fileNamePrefix="", outputFormat="mat", variableFilter=".*", simflags="", …) → SimulationResult`
  — `SimulationResult` carries `resultFile`, `simulationOptions`, `messages`, and timing fields.
- `buildModel(className, …) → String[2]` — build without simulating.
- `setCommandLineOptions(options) → Boolean` — set global flags before a call.
- `readSimulationResult(fileName, variables, size=0) → Real[:,:]`
- `readSimulationResultVars(fileName, readParameters=true, openmodelicaStyle=false) → String[:]`
- `linearize(className, startTime, stopTime=1.0, numberOfIntervals=500, stepSize=0.002, tolerance=1e-6, method="dassl", simflags="") → String`
  — produces a model with symbolic linearization matrices A,B,C,D.

## Library discovery commands (used by the MCP `describe_class`/`search` tools)
- `getClassComment(name)`, `getClassRestriction(name)`, `getParameterNames(name)`,
  `getComponents(name)`, `getClassNames(name)`, `getInheritedClasses(name)`,
  `getDocumentationAnnotation(name)`, `list(name)` (full source string).

## OMPython
- Low-level: `from OMPython import OMCSessionZMQ; omc = OMCSessionZMQ(); omc.sendExpression("...")`.
- Higher-level: `ModelicaSystem` (`.build()`, `.simulate()`, `.getSolutions()`) in
  `OpenModelica/OMPython`.
- This repo does **not** call OMPython directly; the MCP server (built on `omagent`,
  BSD-3-Clause, https://github.com/MasoudMiM/omagent) holds one long-lived omc session
  with MSL preloaded.

## Why the MCP tools exist
The session keeps MSL loaded (loading MSL takes seconds), resolves relative paths to the
repo root, parses diagnostics into compact messages for the LLM, and provides the
measure/compare/plot/verify conveniences on top. Prefer them over raw omc in agent work.

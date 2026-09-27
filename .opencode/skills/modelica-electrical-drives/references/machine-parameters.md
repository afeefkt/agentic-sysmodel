# Machine parameter mapping (datasheet → MSL)

## PMSM (3-phase `Machines` vs m-phase `FundamentalWave`)
| Physical quantity | `Machines.BasicMachines.SynchronousMachines.SM_PermanentMagnet` | `FundamentalWave.BasicMachines.SynchronousMachines.SM_PermanentMagnet` |
|---|---|---|
| Phase count | fixed 3 | `m` (m ≥ 3; powers of two unsupported) |
| Stator resistance | `Rs` | `Rs` |
| Leakage inductance | `Lssigma` | `Lssigma` (inherited from base machine) |
| d-axis main inductance | `Lmd` | `Lmd` |
| q-axis main inductance | `Lmq` | `Lmq` |
| Rotor leakage (d/q) | — | `Lrsigmad`, `Lrsigmaq` |
| Rotor resistance (d/q) | — | `Rrd`, `Rrq` |
| PM flux | via `VsOpenCircuit` or data record | `VsOpenCircuit` |
| Effective stator turns | via data record | `effectiveStatorTurns` |
| Pole pairs | `p` | `p` |
| Inertia | `Jr` (in data record) | `Jr` |

- d/q inductances: `Ld = Lssigma + Lmd`, `Lq = Lssigma + Lmq`. For an IPMSM set `Lmd ≠ Lmq`.
- Look up exact parameter names with `openmodelica_describe_class` (it also returns
  `inherited_parameters` — e.g. `Lssigma` is declared in the base `Machine`, not the leaf).

## Data records (keep machine data in one place)
- `Modelica.Electrical.Machines.Utilities.ParameterRecords.SM_PermanentMagnetData`
- Induction: `...IM_SquirrelCageData`; DC: `...DC_PermanentMagnetData`.
- Instantiate the machine with `data = <record>(...)`, or modify individual machine
  parameters directly at the top level so the tuner can override them.

## Mapping from a datasheet
1. Line-line back-EMF at nominal speed → `VsOpenCircuit` (RMS phase voltage at nominal speed).
2. Phase resistance → `Rs` (use phase value, or convert line-line with star/delta).
3. d/q inductance (from datasheet Ld/Lq) → `Lmd = Ld − Lssigma`, `Lmq = Lq − Lssigma`;
   estimate `Lssigma` from the datasheet leakage or a small fraction of Ld.
4. Pole pairs `p` from rated electrical vs mechanical speed.

## Neutral / star configuration
- `Machines.Utilities.TerminalBox` (3-phase) / `MultiTerminalBox` (m-phase) wire the machine
  to the converter and let you choose star (`star`), delta, etc.
- For m-phase isolated-neutral use `Polyphase.Basic.MultiStar`; common neutral uses `Polyphase.Basic.Star`.

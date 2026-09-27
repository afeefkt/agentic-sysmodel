# MSL 4.1 release notes that change how you write models

The facts below are the ones that break or change models when moving to MSL 4.x.

## Units rename (breaking)
- MSL 3.x: `Modelica.SIunits.Force`, `Modelica.SIunits.Length`, etc.
- MSL 4.0+: `Modelica.Units.SI.Force`, `Modelica.Units.SI.Length`, … (also `Modelica.Units.NonSI`, `Modelica.Units.Conversions`).
- Always write `import SI = Modelica.Units.SI;` and declare `SI.Force`, `SI.Angle`, `SI.Torque`, `SI.Pressure`, `SI.Temperature`, `SI.HeatFlowRate`, `SI.Inductance`, `SI.Resistance`, …
- Any code or example you find that still says `Modelica.SIunits` is MSL 3.x — update it.

## Version & basis
- MSL **4.1.0** released 2025-05-23; backward compatible with 4.0.0; based on Modelica
  Specification **3.6**. 17 new components, 26 bug fixes over 4.0.0.

## Notable component facts (verified against installed 4.1.0)
- `Modelica.Electrical.Polyphase.Functions.symmetricOrientation(m)` returns the phase
  orientation angles; it is the authoritative source for phase ordering (used by the
  multi-phase machine skills).
- `Modelica.Magnetic.FundamentalWave.BasicMachines.SynchronousMachines.SM_PermanentMagnet`
  declares `Lmd` and `Lmq` ("stator main field inductance, d/q-axis"), plus
  `Lrsigmad`/`Lrsigmaq`, `Rrd`/`Rrq`, `VsOpenCircuit`, `effectiveStatorTurns`, and
  inherits `Lssigma` from the base machine.
- `Modelica.Electrical.Machines.Utilities` provides `ToDQ`, `FromDQ`, `DQCurrentController`,
  `VfController` — the dq control blocks are in the `Machines` package, not `FundamentalWave`.

## Where to get the authoritative reference
- Doc portal (pick library + version): https://doc.modelica.org/
- OpenModelica mirror (matches the installed MSL): `https://build.openmodelica.org/Documentation/Modelica.<...>.html`

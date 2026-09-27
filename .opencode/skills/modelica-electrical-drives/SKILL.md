---
name: modelica-electrical-drives
description: Use when modeling electric machines and drives in Modelica — PMSM/IPMSM, induction, DC machines, multi-phase (dual three-phase, six-phase) machines, inverters/PWM, dq transforms, field-oriented current control, speed control, electrical sensors and mechanical loads.
---

# Electric drives from MSL components (don't re-derive the machine equations)

MSL already contains validated machine, converter and dq-control components. Build the
drive **as a diagram** from them.

## Choose the machine library
| Case | Use |
|---|---|
| 3-phase PMSM / IPMSM | `Modelica.Electrical.Machines.BasicMachines.SynchronousMachines.SM_PermanentMagnet` + data record `Modelica.Electrical.Machines.Utilities.ParameterRecords.SM_PermanentMagnetData` |
| **m-phase** (5, 6, 9 …) incl. **dual three-phase** | `Modelica.Magnetic.FundamentalWave.BasicMachines.SynchronousMachines.SM_PermanentMagnet` with `m = 6` (parameter-compatible with the Machines version) |
| Saliency (IPMSM, Ld ≠ Lq) | set `Lmd` ≠ `Lmq` (main-field inductances), and `Lssigma` for leakage |
| Damper cage | `useDamperCage = false` for a plain PMSM |

**The MSL 6-phase convention (verified in omc):** `Modelica.Electrical.Polyphase.Functions.symmetricOrientation(6)`
= {0°, 120°, 240°, −30°, 90°, 210°} — two three-phase sets shifted by 30° (asymmetrical
dual three-phase). Phases 1–3 are set 1, phases 4–6 are set 2.
- Isolated neutrals (2N): `Polyphase.Basic.MultiStar` (one star per base system). Common
  neutral (1N): `Polyphase.Basic.Star`. Check connectors with `describe_class`.

## Typical drive diagram (left → right)
```
DC source (Analog.Sources.ConstantVoltage) ─► Polyphase2Level inverter (m) ─► current sensors (Polyphase.Sensors.CurrentSensor)
   ─► TerminalBox / MultiTerminalBox (star/delta) ─► SM_PermanentMagnet ─► Rotational.Components.Inertia ─► load (TorqueStep / QuadraticSpeedDependentTorque)
control: RotorDisplacementAngle or angle sensor ─► ToDQ (i_abc→i_dq) ─► DQCurrentController (i_d_ref, i_q_ref) ─► PWM/SVPWM ─► inverter gates
```
Relevant classes (all verified paths):
- Converter: `Modelica.Electrical.PowerConverters.DCAC.Polyphase2Level` (param `m`), modulation `...DCAC.Control.PWM` / `SVPWM` / `IntersectivePWM`
- Fast averaged alternative (much faster): drive the machine with `Modelica.Electrical.Polyphase.Sources.SignalVoltage` fed by the dq controller output. Use for control design and sizing sweeps; use the switching inverter only for ripple/harmonics.
- Transforms and control: `Modelica.Electrical.Machines.Utilities.ToDQ`, `FromDQ`, `DQCurrentController`, `VfController` (these live in `Machines.Utilities`, **not** `FundamentalWave`)
- Sensors: `Modelica.Electrical.Machines.Sensors.RotorDisplacementAngle`, `CurrentQuasiRMSSensor`, `VoltageQuasiRMSSensor`, `ElectricalPowerSensor`, `MechanicalPowerSensor`; `Modelica.Mechanics.Rotational.Sensors.SpeedSensor`
- Loads: `Modelica.Mechanics.Rotational.Sources.TorqueStep`, `QuadraticSpeedDependentTorque`, `Components.Inertia`

## Start from these examples (get_class_source, copy structure and layout)
- `Modelica.Electrical.Machines.Examples.SynchronousMachines.SMPM_CurrentSource` — current-fed PMSM (simplest control plant)
- `Modelica.Electrical.Machines.Examples.SynchronousMachines.SMPM_VoltageSource` — field-oriented control (FOC) template
- `Modelica.Electrical.Machines.Examples.InductionMachines.IMC_DOL` — induction, direct-on-line
- `Modelica.Magnetic.FundamentalWave.Examples.BasicMachines.SynchronousMachines.SMPM_Inverter`, `.ComparisonPolyphase` — m-phase versions
- `Modelica.Electrical.PowerConverters.Examples.DCAC.PolyphaseTwoLevel.ThreePhaseTwoLevel_PWM` — inverter + PWM
- `Modelica.Electrical.Machines.Examples.ControlledDCDrives.SpeedControlledDCPM` — cascaded speed/current template

## When a custom block is justified
The x-y (harmonic) subspace or a VSD (vector space decomposition) current controller for
dual three-phase **control** isn't in MSL. Write it as a `block` in `Controls/`
(control-expert) with RealInput/RealOutput vectors, and keep the **machine and inverter as
MSL components**. The VSD transform is a signal-side operation; the plant stays physical.

## Parameter mapping from papers or datasheets
Stator resistance R_s → `Rs`. Ld = Ll + Lmd → `Lmd`, `Lssigma = Ll`. Lq = Ll + Lmq → `Lmq`.
PM flux ψ_pm → via `VsOpenCircuit` (open-circuit voltage at nominal speed) or the data
record. Look up exact names with `describe_class` (including `inherited_parameters`).
Pole pairs → `p`. Inertia → `Jr`.

Deep detail: `references/machine-parameters.md` (full parameter table incl. FundamentalWave
names), `references/dq-control.md` (FOC structure, phase orientation). Sources: `references/sources.md`.
Details in knowledge: `knowledge/msl/Machines.md`, `FundamentalWave.md`, `PowerConverters.md`, `Polyphase.md`.

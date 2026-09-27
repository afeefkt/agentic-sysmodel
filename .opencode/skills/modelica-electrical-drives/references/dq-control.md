# Field-oriented control (FOC) and phase orientation

## The FOC loop (copy the structure from `Machines.Examples.SynchronousMachines.SMPM_VoltageSource`)
1. **Measure** the rotor angle (`Sensors.RotorDisplacementAngle`) and phase currents
   (`Polyphase.Sensors.CurrentSensor` or `Machines.Sensors.CurrentQuasiRMSSensor`).
2. **Transform** abc → dq with `Machines.Utilities.ToDQ` (needs the electrical angle).
3. **Regulate** `i_d` (→ 0 for max torque per amp) and `i_q` (→ torque command) with
   `Machines.Utilities.DQCurrentController`.
4. **Transform back** dq → abc with `FromDQ`, then drive the inverter via
   `PowerConverters.DCAC.Control.PWM`/`SVPWM` (or a `SignalVoltage` source for the
   averaged model).
5. **Speed loop** on top: speed error → `LimPID` → `i_q_ref`. This is the
   `SpeedControlledDCPM` template generalized to AC machines.

## Phase orientation for m-phase machines
- `Modelica.Electrical.Polyphase.Functions.symmetricOrientation(m)` returns the phase
  orientation angles used by MSL (e.g. `m=6` → {0,120,240,−30,90,210}°).
- A dual three-phase winding is two base three-phase sets shifted by 30°: phases 1–3 = set 1,
  phases 4–6 = set 2. Use `MultiStar` for isolated neutrals (one star per set).
- When you write a VSD (vector space decomposition) controller, decompose into d-q (torque)
  and x-y (harmonic) subspaces using this orientation — the x-y components must be
  suppressed (set to 0) in the current controller.

## Averaged vs switching model
- **Averaged** (`Polyphase.Sources.SignalVoltage` fed by the dq controller) simulates orders
  of magnitude faster and is the right choice for sizing sweeps and control design.
- **Switching** (`Polyphase2Level` + PWM) is only for ripple/harmonic/EMI studies and final
  verification of switching-frequency effects. It is slow (many events).

## Custom control blocks (only the parts MSL lacks)
- The x-y/VSD current controller for dual three-phase **control** is not in MSL — write it
  as a `block` in `Controls/` (control-expert). It is signal-side; the machine and inverter
  stay MSL components.

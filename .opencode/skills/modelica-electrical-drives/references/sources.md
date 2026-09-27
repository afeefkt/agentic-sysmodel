# Sources — modelica-electrical-drives

| Fact area | Source | License | Confidence |
|---|---|---|---|
| Machines package (SM_PermanentMagnet, ToDQ/FromDQ/DQCurrentController/VfController) | local `knowledge/msl/Machines.md` (MSL 4.1.0) | BSD-3-Clause | high |
| FundamentalWave package + SM_PermanentMagnet params (Lmd/Lmq/Lrsigma*/Lssigma) | `knowledge/msl/FundamentalWave.md`; https://raw.githubusercontent.com/modelica/ModelicaStandardLibrary/v4.1.0/Modelica/Magnetic/FundamentalWave/BasicMachines/SynchronousMachines/SM_PermanentMagnet.mo | BSD-3-Clause | high |
| PowerConverters package (Polyphase2Level, PWM/SVPWM) | local `knowledge/msl/PowerConverters.md` | BSD-3-Clause | high |
| Polyphase + `symmetricOrientation` | local `knowledge/msl/Polyphase.md`; https://build.openmodelica.org/Documentation/Modelica.Electrical.Polyphase.Functions.symmetricOrientation.html | BSD-3-Clause | high |
| Example models | MSL 4.1.0 examples (verified via `openmodelica_list_examples`) | BSD-3-Clause | high |

Note: the 6-phase `symmetricOrientation(6)` = {0,120,240,−30,90,210}° convention is
verified against the installed library in this session.

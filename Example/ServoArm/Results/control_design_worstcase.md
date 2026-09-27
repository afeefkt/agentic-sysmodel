# ServoArm — REQ-06 Worst-Case Stability Margins (control-expert, stage 5b)

Loop-cut linearization of `ServoArm.Controls.LoopCut` at the worst operating point (90°).

## Operating point & overrides
| Parameter | Value | Unit | Note |
|-----------|-------|------|------|
| payload_m | 0.30 | kg | heavy payload |
| R_a | 2.6 | Ω | hot/worn winding |
| Vsupply | 20.0 | V | degraded supply (output limit) |
| v_bias | 1.1917 | V | holding voltage, computed (see below) |
| N, k_t, L_a, J_r, kp, Ti | 50, 0.05, 1e-3, 5e-6, 60, 0.08 | — | unchanged |

**v_bias derivation** (hold 90° at equilibrium): `M_tip = 0.2416428·0.1357582 + 0.30·0.280 =
0.116805 kg·m`; `tau_g(90°) = 0.116805·9.81 = 1.14586 N·m`; `i_hold = 1.14586/(0.05·50) =
0.45834 A`; `v_bias = 2.6·0.45834 = 1.1917 V`.

## Trim note
Linearized at the initial state `phi = 1.5707963 rad, w = 0` (t_lin = 0). Confirmed at ~90°:
the gravity-stiffness entry `d(tau_g)/dphi` in A is `+7.8e-7` (≈0), the residual being purely
`cos(1.5707963) ≈ 2.7e-8` (phi is 2.7e-8 rad below exactly π/2). The two near-origin poles
(`0` and `+1.38e-8 rad/s`) are the double integrator — same Type-2 behaviour as nominal.

**Poles (worst case)**: `{0, +1.38e-8, -58.14, -2541.9}` rad/s
(nominal `{0, 0, -95.25, -1904.75}`). The back-EMF damping pole moved −95.25 → −58.14 rad/s
because R_a 2.0 → 2.6 Ω weakens velocity damping; the electrical pole moved −1904.75 → −2541.9
(R/L higher). Payload 0.20 → 0.30 kg raises reflected inertia J 0.0344 → 0.0423 kg·m².

## Margins (REQ-06)
| Quantity | Measured | Limit | Result |
|----------|----------|-------|--------|
| Gain crossover | 24.74 rad/s | — | — (nominal 25.75) |
| **Phase margin** (unwrapped) | **39.6°** | ≥ 45° | **FAIL** |
| **Gain margin** (upper phase crossover ω≈339.5 rad/s) | **38.5 dB** | ≥ 6 dB | **PASS** |

- Tool PM 399.59° → unwrapped **39.59°** (two integrators ⇒ −180° start, tool wraps +360°).
- Tool GM −182.7 dB is the degenerate ω→0 crossover (Type-2 artifact, as in §5 of the nominal
  report). The physical GM is at the **upper** phase crossover, computed from the returned
  A,B,C,D: ω_pc = √(Q − (R/L)/Ti) = √(147791 − 32500) = **339.5 rad/s**, |L| = 0.01183 →
  **GM = 38.5 dB**. (Method cross-checked against nominal: gives 37.13 dB / PM 48.2°,
  matching control_design.md §5.)

## Conclusion
**REQ-06 at the worst operating point: FAIL** — PM 39.6° < 45° (short by ~5.4°); GM 38.5 dB ≥
6 dB passes. Root cause: higher R_a weakens back-EMF velocity damping, adding phase lag near
crossover. Per instructions, no re-tuning here (tuning is a separate stage).

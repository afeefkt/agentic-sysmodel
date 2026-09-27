# Lumped hydraulic actuator — equation reference

## Notation
- `A_A` = π/4·D_bore² (piston side), `A_B` = π/4·(D_bore² − D_rod²) (rod side)
- `pA`, `pB` = chamber pressures; `x` = stroke; `v` = dx/dt; `β` = effective bulk modulus
- `ρ` = fluid density, `ν`/`μ` = kinematic/dynamic viscosity

## Level 3 chamber dynamics (compressible, the recommended form)
```
V_A = V_A0 + A_A*x
V_B = V_B0 + A_B*(stroke - x)
V_A/β * der(pA) = Q_in_A  - A_A*v - Q_leak
V_B/β * der(pB) = A_B*v   - Q_out_B + Q_leak
F_hyd = pA*A_A - pB*A_B - F_friction(v)
```
- `V_A0`, `V_B0` are the dead volumes (line + port volume). Non-zero dead volume keeps the
  model regular at x = 0 and x = stroke.
- Sign: `Q_leak` flows from A to B (positive = internal leakage A→B).

## Sub-equations
- **Turbulent orifice (regularized):** `Q = Cd*A0*sqrt(2/ρ) * Δp / (Δp² + dp_t²)^0.25`.
  `dp_t` ≈ 1e4–1e5 Pa avoids the sign/sqrt singularity at Δp=0 and prevents chattering.
- **Laminar leak / line:** `Q = Δp / R_lam`, `R_lam = 128·μ·L / (π·d⁴)`.
- **Pump + relief:** `Q = Q_max * clamp((p_set - p)/p_band, 0, 1)` — hard ceiling near `p_set`.
- **Friction:** `F_f = Fc·tanh(v/v_eps) + c_v·v` (smooth Coulomb + viscous).
- **Regularization helper:** for any `sign()` on a continuous variable, prefer
  `tanh(x/eps)` (eps small) or the `x/(x²+eps²)^0.5` form to keep the solver smooth.

## Sign convention check (do this every time)
MSL `PartialCompliant` flange force `f` is positive in **tension** (spring convention). A
hydraulic cylinder pushing = compression = negative `f`:
```
f = -(pA*A_A - pB*A_B - F_friction);
```
Smoke test: with `pA > pB`, the rod must extend (`s_rel` increases). If it retracts, the
sign is flipped.

## Metrics to expose at the top level
`p_A`, `p_B`, `p_max_obs` (max over both chambers), `p_min_obs` (min, for cavitation),
`x`, `v`, `Q_pump`, `F_hyd`. Make `D_bore`, `D_rod`, `A0_orifice`, `Q_max`, `p_set`, `nu`
top-level parameters for the tuner.

---
name: modelica-hydraulic-actuator
description: Use when modeling hydraulic actuators, pumps, relief valves, orifices, fluid compressibility, viscosity-vs-temperature, or cavitation checks in Modelica (e.g. landing-gear retraction cylinder sizing).
---

# Lumped hydraulic actuator modeling

## Component-first (this is a justified custom component)
MSL has no lumped hydraulic cylinder. `Modelica.Fluid` exists, but it's heavy for sizing (check with `openmodelica_search_library("hydraulic cylinder")` and write down the result). So:
- Write the actuator **once** as a reusable model in `<Pkg>/Components/`. It extends `Modelica.Mechanics.Translational.Interfaces.PartialCompliant` (so it has flange_a/flange_b) and has a `RealInput` command connector with a Placement and an Icon (template in `modelica-diagram-layout`).
- In the system model, *instantiate* it and `connect()` its flanges to the MultiBody `Prismatic` joint's `support`/`axis`, and its command to the controller. Keep everything else MSL (masses, springs, sources, sensors).

For sizing studies, write **small custom lumped components** with explicit equations. Don't use Modelica.Fluid. It's heavy, fragile to initialize, and hides the physics the requirements check.

## Build it in levels (simulate after each)
**L1: ideal force source.** `F = pA*A_A - pB*A_B` with prescribed pressures. This checks sign and attachment.
**L2: flow-driven, incompressible.** The pump flow `Q` sets rod velocity `v = Q/A_A`. Pressure follows from load: `pA = (F_load + pB*A_B)/A_A + Δp_orifice(Q)`.
**L3: compressible chambers (recommended for verification).**
```
V_A = V_A0 + A_A*x          V_B = V_B0 + A_B*(stroke - x)
V_A/β * der(pA) = Q_in_A  - A_A*v - Q_leak
V_B/β * der(pB) = A_B*v   - Q_out_B + Q_leak
F_hyd = pA*A_A - pB*A_B - F_friction(v)
```
- β (effective bulk modulus): around 1.0–1.5e9 Pa, lower with entrained air. State your assumption.
- `A_A = π/4·D_bore²`, `A_B = π/4·(D_bore² − D_rod²)`.

## Standard sub-equations
- **Orifice (turbulent)**: `Q = Cd*A0*sqrt(2*|Δp|/ρ)*sign(Δp)`, with Cd ≈ 0.6–0.7. **Regularize** near Δp=0 so the solver doesn't chatter:
  `Q = Cd*A0*sqrt(2/ρ) * Δp / (Δp^2 + dp_t^2)^0.25` with dp_t ≈ 1e4–1e5 Pa.
- **Laminar line or leak**: `Q = Δp / R_lam`, with `R_lam = 128*μ*L/(π*d^4)`. Here μ = ρ·ν, so this is where **viscosity and temperature** come in.
- **Pressure-compensated pump with relief**: `Q = Q_max * smoothClamp((p_set - p)/p_band, 0, 1)`. This gives a hard ceiling near `p_set` (e.g. 21e6 Pa).
- **Friction**: Coulomb + viscous with smooth sign: `F_f = Fc*tanh(v/v_eps) + c_v*v`.

## Temperature and viscosity cases
- Make ν (or μ) a **parameter** so the verifier can override it per case.
- MIL-PRF-5606-type fluids are orders of magnitude more viscous at −40 °C than at +40 °C. Take the numbers from the fluid spec and label them SOURCED, or label them ASSUMED.
- Viscosity mainly affects line and valve losses and leakage, so the cold case gives slower retraction and higher pump pressure.

## Cavitation check
- Track **absolute** pressure. If you model gauge pressure, add p_atm when checking.
- Expose `p_min_obs` (the minimum over both chambers) and verify `p_min_abs > p_vapor + margin` (vapor pressure of hydraulic oil is only a few kPa. Use a conservative margin and label it ASSUMED/SOURCED).

## Coupling to MultiBody
Implement the actuator as a component that extends `Modelica.Mechanics.Translational.Interfaces.PartialCompliant` (flange_a = cylinder side, flange_b = rod side, `s_rel` = length). MSL sign convention: positive `f` means **tension** (as in a Spring). So a pushing actuator uses:
```
f = -(pA*A_A - pB*A_B - F_friction);
```
Connect it between the `Prismatic` joint's `support` and `axis` flanges. **Always smoke-test the sign**: raising pA must extend the actuator.

## Exposed metrics (for requirements)
`p_A`, `p_B`, `p_max_obs`, `p_min_obs`, `x` (stroke), `v`, `Q_pump`, `F_hyd`. Declare the design parameters (`D_bore`, `D_rod`, `A0_orifice`, `Q_max`, `p_set`, `nu`) at the top level so they can be tuned with overrides.

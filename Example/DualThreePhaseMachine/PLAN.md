# PLAN — Dual Three-Phase IPMSM (ADT-IPMSM) Plant Model

Source: Eldeeb et al., "A Unified SVPWM Realization for Minimizing Circulating
Currents of Dual Three Phase Machines", IEEE PEDS 2017.
Scope: **B** — machine + VSD/Park transforms + 2-level VSI (controller out of scope).

## Build steps

| Step | Deliverable | REQs in scope | Status |
|------|-------------|---------------|--------|
| 0 | Requirements (`Requirements/requirements.yaml`) | — | done |
| 0 | Architecture (`architecture.md`), PLAN, state.json | — | done |
| 1 | Core machine `DualThreePhaseIPMSM.mo` | REQ-01..15, 26 | done (verified) |
| 2 | `VSDTransform.mo` + `ParkTransform.mo` | REQ-16..20 | done (verified) |
| 3 | `DualThreePhaseInverter.mo` + `PlantAssembly.mo` | REQ-21..25 | done (verified) |

## Per-step acceptance
- Step 1: `openmodelica_check` ok + smoke sim (dq/xy voltage steps; currents, torque, speed finite).
- Step 2: static checks — orthogonality, round-trip, subspace separation, 30° amplitude mapping.
- Step 3: representative switching-state voltages (Eq. 4), per-set sum = 0, bounds, full-plant smoke sim.

## Key decisions / open items
- OQ-1: Table I current/torque inconsistency → implement Eq. (3) faithfully; use MTPA
  current (−5.02, 10.24) A for the 10.6 N·m rated check; document 4.1 A discrepancy.
- ASSUMED parameters (u_dc=500 V, J=0.01, b=1e-3) exposed as tunable; flagged to user.

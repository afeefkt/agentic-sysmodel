# Architecture — Dual Three-Phase IPMSM (ADT-IPMSM) Plant Model

## 1. System need (restated)
A verified Modelica **plant model** of a 4.4 kW asymmetrical dual three-phase
interior permanent-magnet synchronous machine (ADT-IPMSM) drive, parameterised
from Eldeeb et al., *IEEE PEDS 2017* (Table I / Eq. 1–4). The plant is the
physical machine + coordinate transforms + 2-level VSI that an SVPWM controller
acts on. The controller itself (SVPWM modulator, PR current regulators) is OUT
of scope for this deliverable.

Scope decision (user-approved): **B** — machine + VSD/Park transforms + inverter.

## 2. Subsystems and physical interfaces

| Subsystem | Role | Interface |
|-----------|------|-----------|
| `DualThreePhaseIPMSM` | Core machine: dq energy-conversion dynamics, xy leakage subspace, 0+/0− zero-sequence, electromagnetic torque, rotor mechanics | voltage inputs `u_d,u_q,u_x,u_y,u_0p,u_0m`; current outputs `i_d,i_q,i_x,i_y,i_0p,i_0m`; `Modelica.Mechanics.Rotational` flange for load/speed |
| `VSDTransform` | Generalised Clarke (vector-space-decomposition) 6-phase ↔ αβ/xy/0+0−, 30° shift | 6 phase signals ↔ 6 subspace signals (forward + inverse) |
| `ParkTransform` | Rotating-frame αβ ↔ dq rotation (angle θ=φ_k) | αβ ↔ dq (forward + inverse) |
| `DualThreePhaseInverter` | 2-level VSI: switching states s∈{0,1}⁶ → phase voltages (Eq. 4); 2N/1N | gate inputs `s_a1..s_c2`; phase-voltage outputs `u_a1..u_c2`; DC-link `u_dc` |

**Signal chain (full plant):** inverter (phase voltages) → `VSDTransform` → `ParkTransform` (dq) + xy/0 branches → machine → inverse `ParkTransform`/`VSDTransform` → phase currents (back to inverter for current feedback).

## 3. Coordinate frames and transformations (from paper)
- **VSD (Eq. 1):** 6×6 amplitude-invariant generalised Clarke matrix `T`,
  phase order `(a1,b1,c1,a2,b2,c2)`, rows = (α, β, x, y, 0+, 0−), spatial shift
  π/6 rad between the two sets. Properties: `T·Tᵀ = (1/3)·I₆`, `T⁻¹ = 3·Tᵀ`.
  Exact reference matrix is recorded in `Requirements/requirements.yaml` DER-8.
- **Park (Eq. 2):** block-diagonal rotation on (αβ, xy) with `0+0−` unchanged;
  `R(θ) = [[cosθ, sinθ], [−sinθ, cosθ]]`, orthonormal (`R·Rᵀ = I₂`).
- **Machine dynamics (Eq. 3, rotating dq frame, neglecting saturation):**
  - dq: `u_d = R_s i_d + dψ_d/dt − ω_k ψ_q`; `u_q = R_s i_q + dψ_q/dt + ω_k ψ_d`
  - fluxes: `ψ_d = (L_l + L_d) i_d + ψ_pm`; `ψ_q = (L_l + L_q) i_q`
  - xy (leakage only): `u_x = R_s i_x + L_l di_x/dt`; `u_y = R_s i_y + L_l di_y/dt`
  - zero-seq: `u_0 = R_s i_0 + L_l di_0/dt` (2N blocks, 1N enables)
  - torque: `m_e = (3/2) n_p (ψ_d i_q − ψ_q i_d)`
  - mechanical: `Θ dω_k/dt = (3/2) n_p (ψ_d i_q − ψ_q i_d) − (m_load + ν ω_k)`,
    with `ω_k = n_p ω_mech`, `Θ = J/n_p`, `ν = b/n_p` (⇒ equivalent to
    `J dω_mech/dt = m_e − m_load − b ω_mech`, matching DER-6/REQ-13/14)
- **VSI (Eq. 4, 2N):** `u_ph,κ = (u_dc/3)(2 s_κ − s_j − s_k)` for the other two
  legs of the same 3-phase set; 64 switching states; per-set voltage sums to
  zero (2N).

## 4. Libraries
- **Custom** package `DualThreePhaseMachine` (no 6-phase machine exists in MSL).
- Reuse MSL: `Modelica.Mechanics.Rotational` (inertia/damper/flange),
  `Modelica.Blocks.Interfaces` (Real signals), `Modelica.SIunits` (types).
- Reference pattern: `Modelica.Electrical.Machines.BasicMachines.SynchronousMachines.SM_PermanentMagnet`
  (3-phase PMSM) — verified to exist via `openmodelica_describe_class`; used only
  as a naming/pattern reference, not instantiated.
- No CAD/geometry subsystem (electromagnetic lumped model; mass geometry N/A).

## 5. Modelica package layout (target)
```
Example/DualThreePhaseMachine/OpenModelica/DualThreePhaseMachine/
  package.mo                      # package + parameter record (Table I)
  DualThreePhaseIPMSM.mo          # core machine (Step 1)
  VSDTransform.mo                 # VSD forward/inverse (Step 2)
  ParkTransform.mo                # Park forward/inverse (Step 2)
  DualThreePhaseInverter.mo       # 2-level VSI (Step 3)
  PlantAssembly.mo                # full plant = inverter→transforms→machine (Step 3)
```

## 6. Assumptions
| ID | Value | Status |
|----|-------|--------|
| ASM-1 | DC-link `u_dc = 500 V` | ASSUMED (paper gives none) |
| ASM-2 | Rotor inertia `J = 0.01 kg·m²` → `Θ = 3.333e-3` | ASSUMED |
| ASM-3 | Viscous friction `b = 1e-3 N·m·s/rad` → `ν = 3.333e-4` | ASSUMED |
| ASM-4 | Neglect saturation (L_d,L_q,ψ_pm constant) | SOURCED (paper Eq.3) |
| ASM-5 | Reference current (−2.513, 5) A = peak dq pair at bench | SOURCED (paper) |
| ASM-6 | 2N (isolated) and 1N (common) neutral modelled | SOURCED (paper) |
| ASM-7 | R_s(120°C) = 1.393·R_s(20°C) = 1.114 Ω | ASSUMED (std α_Cu) |
| ASM-8 | VSD amplitude scaling 1/3, `T·Tᵀ=(1/3)I₆` | ASSUMED (std convention) |
| ASM-9 | Open-loop plant (voltage/current prescribed) | ASSUMED (scope) |

## 7. Incremental build sequence (each step simulable)
1. **Step 1 — core machine `DualThreePhaseIPMSM`.** dq + xy + 0+/0− dynamics,
   torque, mechanics, residual outputs. Gate: `openmodelica_check` ok + smoke sim
   (open-loop dq/xy voltage steps; observe currents/torque/speed). Verifies REQ-01..REQ-15, REQ-26.
2. **Step 2 — `VSDTransform` + `ParkTransform`.** Forward/inverse blocks.
   Gate: orthogonality/round-trip/subspace-separation/30° checks (static analysis).
   Verifies REQ-16..REQ-20.
3. **Step 3 — `DualThreePhaseInverter` + `PlantAssembly`.** Eq. (4) VSI + full
   plant wiring. Gate: representative switching-state voltages, per-set sum=0,
   bounds, full-plant smoke sim. Verifies REQ-21..REQ-25.

## 8. Known issues / open questions (from requirements review)
- **OQ-1 (physics discrepancy, decision made):** Table I is internally
  inconsistent — `i_s,rated = 4.1 A` yields only ≈3.2 N·m under the paper's own
  Eq. (3), not `m_rated = 10.6 N·m`. **Decision:** implement Eq. (3) *faithfully*
  (torque factor `(3/2)·n_p`, Table I parameters); verify the torque equation
  exactly (residual), verify the paper's own bench point `(−2.513, 5) A → 4.55 N·m`,
  and reach the nameplate 10.6 N·m via the MTPA current `(i_d, i_q)=(−5.02, 10.24) A`
  (DER-5). The 4.1 A inconsistency is documented, not "fixed" by changing physics.
- **OQ-2/3 (assumed u_dc, J, b)** — flagged to user; model exposes them as tunable parameters.
- **OQ-4/5 (current base, VSD scaling)** — conventions pinned in ASM-5/ASM-8; noted for the user.

## 9. Verification approach
- `sim-verifier` runs nominal + edge cases from `Tests/cases.yaml` (mirrors
  `Requirements/requirements.yaml` `cases:`), evaluates every REQ, writes
  `Results/verification_report.md`. Model defects → back to `modelica-modeler`;
  spec shortfalls (only the ASSUMED parameters) → `design-tuner`.

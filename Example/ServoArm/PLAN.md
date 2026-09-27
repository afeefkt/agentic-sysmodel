# ServoArm — Plan

## Build steps
| Step | Scope | REQs in scope | Owner | Status |
|------|-------|---------------|-------|--------|
| 1 | Requirements (requirements.yaml) | REQ-01..06 + 5 cases | req-engineer | done |
| 2 | Architecture + plan (this file) | — | sysarch | done |
| 3 | CAD: arm body (hole), mass_properties.json, Arm.stl | feeds arm.m / CoM / inertia | cad-designer | in-progress |
| 4 | Plant model (open-loop) + 5 V smoke test | (physical plausibility) | modelica-modeler → sim-verifier | pending |
| 5 | Control + closed-loop `System` + loop-cut model | REQ-01..06 | control-expert | pending |
| 6 | Verification (5 cases, plots, xlsx) | REQ-01..06 | sim-verifier | pending |
| 7 | Tuning if any REQ fails (ONLY gear.N) | REQ-01..05 | design-tuner | pending (conditional) |
| 8 | Comparison table (5 cases) | — | data-analyst | pending |
| 9 | Final summary + state.json | REQ-01..06 matrix | sysarch | pending |

## Current step
Stage 3 (CAD). User will manually verify stages 1–3 before authorising stages 4+.

## Deliverables
- Stage 1: `Requirements/requirements.yaml` ✅ (6 REQs, 5 cases, top-level param names).
- Stage 2: `architecture.md` + `PLAN.md` ✅ (MSL component map, search evidence, build sequence).
- Stage 3: `CAD/ServoArm.FCStd`, `CAD/mass_properties.json`, `CAD/Arm.stl` (in progress).

## Notes
- Nominal design point: payload.m=0.20 kg, Vsupply=24 V, motor.R=2.0 Ω, motor.L=1e-3 H,
  motor.k=0.05, motor.Jr=5e-6, gear.N=50, angle_ref=90°.
- Stop after stage 3 for manual review (user instruction).

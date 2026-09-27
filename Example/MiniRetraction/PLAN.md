# MiniRetraction — Plan

## Build steps
| Step | Scope | REQs in scope | Owner | Status |
|------|-------|---------------|-------|--------|
| 1 | Kinematics only (slider-crank loop, arm 0→90°, actuator length) | REQ-KIN-1..5 | modelica-modeler → sim-verifier | in-progress |
| 2 | Loads (gravity torque, actuator force per angle) | (feeds REQ-F-1) | — | pending |
| 3 | Actuator + dynamics (retraction time, force) | REQ-T-1, REQ-F-1 | — | pending |
| 4 | Control + edge cases (overshoot) | REQ-OS-1 | — | pending |

## Current step
Step 1 (kinematics). Stop and report after step 1 per user instruction.

## Deliverables per step
- Step 1: `OpenModelica/MiniRetraction/package.mo` (kinematics model) → `Results/verification_report.md` (REQ-KIN-1..5).

## Notes
- Actuator technology & control law are open (OQ-1, OQ-2); needed for steps 3–4 only.

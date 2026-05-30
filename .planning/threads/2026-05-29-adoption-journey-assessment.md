# Thread: Adoption Journey Assessment (v2.9)

**Captured:** 2026-05-29  
**Status:** closed  
**Closed:** 2026-05-30 — superseded by `.planning/threads/2026-05-30-milestone-next-step-assessment.md`
**Source:** Adoption Evidence Assessment pass + approved v2.9 plan

## Assessment Outcome

- **Done estimate:** ~87–90% (band 80–89%, upper edge) for embedded Phoenix AI-ops scope.
- **Confirmed next milestone:** v2.9 Adoption Journey & Reference Demo.
- **Confirmed queue:** v2.10 Hex consumer proof → v2.11 Orchestrator live wiring → v2.12 optional lane journeys in demo.

## Key Decisions

1. **Demo placement:** Phased hybrid (C) — extend merge-blocking `priv/host_app_proof` overlay + committed `examples/support_copilot/` gallery with shared `SupportJourney` fixture SSOT.
2. **Domain:** B2B support SaaS — Support Ops Lead persona; triage + approval, bounded handoff to billing, review-queue flywheel.
3. **CI posture:** Gallery lane is **advisory** (`mix scoria.test.support_copilot`), not in `VerificationLanes.closeout_order/0`.
4. **Overturns prior deferral:** Polished example app moves from "companion / later" to v2.9 scope now that Hex + CI hardening shipped.

## Graduation Candidates

- **D:** Adopter done-ness = host-app surprise reduction + journey depth, not feature count.
- **E:** Proof harness (overlay) + gallery (examples/) must share fixture SSOT or drift is guaranteed.
- **F:** Example gallery is companion/advisory CI, not merge-blocking closeout.

## Promoted From

- Candidate C from `.planning/threads/2026-05-27-milestone-assessment-learnings.md` — extended to journey depth.

## Routing Note

Seed graduation candidates D–F into Phase 74 `74-LEARNINGS.md` at phase start. Archive `2026-05-27-milestone-assessment-learnings.md` after promotion.

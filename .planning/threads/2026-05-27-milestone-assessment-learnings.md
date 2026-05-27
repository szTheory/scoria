# Thread: Milestone Assessment Learnings And Graduation Candidates

**Captured:** 2026-05-27  
**Status:** open (promote on first v2.6 phase start)  
**Source:** milestone-next-step assessment pass (implemented 2026-05-27)

## Assessment Outcome

- **Done estimate:** ~84% (band 80–89%) for embedded Phoenix AI-ops scope.
- **Confirmed next milestone:** v2.6 Warning Ratchet (`WARN-03`).
- **Confirmed queue:** v2.7 OSS Release + Docs Truth (Hex + README shipped-state + drift-test alignment).

## New Lessons

1. Scoria is feature-strong; remaining leverage is boring host-app and maintainer trust contracts, not net-new runtime features.
2. Canonical lane reliability is materially stronger than full-suite warning governance; baseline expiry must become executable policy in v2.6.
3. Support-truth drift can still appear with strong lane contracts (README still anchors v2.1 by test design until v2.7).

## Decisions Confirmed In This Assessment

- ~~Installer safety (`INST-03`, `INST-04`) as next milestone~~ — **shipped v2.5**.
- **Next milestone:** `WARN-03` full-suite warning ratchet (v2.6).
- **Queued:** v2.7 Hex publish + docs-truth.
- **Anti-overbuild:** no new runtime capability families until v2.6 + v2.7 close.

## Graduation Candidates For Next Phase `NN-LEARNINGS.md`

- **Candidate A:** "Installer trust beats feature breadth once core lanes are shipped."  
  **Status:** ready to promote — v2.5 verified plan/apply + drift semantics.
- **Candidate B:** "Baseline-led warning policy must be executable, not only documented."  
  **Status:** promote when v2.6 lands CI-enforced expiry checks.
- **Candidate C:** "Adopter-facing done-ness should be measured by host-app surprise reduction."  
  **Status:** ready to promote — v2.5 install contract reduced mutation surprise.

## Routing Note

Copy graduation candidates A and C into the first v2.6 phase `NN-LEARNINGS.md` when `/gsd-new-milestone` creates active phase directories. Hold Candidate B until executable baseline expiry ships.

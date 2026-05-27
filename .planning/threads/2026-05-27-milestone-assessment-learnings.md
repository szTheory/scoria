# Thread: Milestone Assessment Learnings And Graduation Candidates

**Captured:** 2026-05-27  
**Status:** open (promote on next phase start)  
**Source:** milestone-next-step assessment pass

## New Lessons

1. Scoria is now in a strong adopter-value band, but remaining leverage is concentrated in boring host-app safety contracts (installer plan/apply + drift handling), not in net-new runtime features.
2. Canonical lane reliability work is materially stronger than full-suite warning governance; warning baseline expiry should become executable policy in the next reliability pass.
3. Support-truth drift can still appear even with strong lane contracts (for example stale status wording in top-level docs), so docs-truth checks should keep focusing on shipped-state phrasing.

## Decisions Confirmed In This Assessment

- Next milestone priority: installer safety and upgrade confidence (`INST-03`, `INST-04`).
- Immediate follow-up priority: `WARN-03` full-suite warning ratchet after installer closeout.
- Explicit anti-overbuild rule: no new runtime capability families until installer and warning trust gaps are closed.

## Graduation Candidates For Next Phase `NN-LEARNINGS.md`

- **Candidate A:** "Installer trust beats feature breadth once core lanes are shipped."  
  Promote when phase execution proves plan/apply + drift semantics reduce support ambiguity.
- **Candidate B:** "Baseline-led warning policy must be executable, not only documented."  
  Promote when `WARN-03` phase lands with CI-enforced expiry checks.
- **Candidate C:** "Adopter-facing done-ness should be measured by host-app surprise reduction."  
  Promote after installer milestone verification demonstrates lower mutation risk on real host topologies.

## Routing Note

There is currently no active `.planning/phases/*` learnings target. Keep these entries in thread form and copy them into the first next-phase `NN-LEARNINGS.md` when `/gsd-new-milestone` creates active phase directories.

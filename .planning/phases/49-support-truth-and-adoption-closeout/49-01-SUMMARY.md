---
phase: 49-support-truth-and-adoption-closeout
plan: 01
subsystem: docs
tags: [docs, adoption, support-truth, verification]
requires:
  - phase: 48-host-app-install-contract-and-consumer-proof
    provides: canonical default-lane verifier and fresh-host proof boundary
provides:
  - README and adopter guides aligned to one default-lane proof order
  - Bounded handoffs repositioned as additive to the default lane
  - Semantic and knowledge guides demoted to explicit optional lanes
affects: [49-02, 49-03, adoption, support]
tech-stack:
  added: []
  patterns: [four-tier support hierarchy, one canonical verifier per lane]
key-files:
  created: []
  modified: [README.md, docs/adoption_lanes.md, docs/operator_verification.md, docs/bounded_handoffs.md, docs/semantic_fast_path.md]
key-decisions:
  - "Promoted `mix test.adoption` as the only canonical default-lane verifier across public docs."
  - "Kept bounded handoffs inside the base runtime story instead of inventing a separate verifier lane."
patterns-established:
  - "Public docs now present closeout proof, default adoption proof, optional lane verifiers, and broader repo-health context in that order."
  - "Compatibility aliases remain in code, but public docs promote one command per lane."
requirements-completed: [DOCS-01, DOCS-02]
duration: 20min
completed: 2026-05-26
---

# Phase 49: Support truth and adoption closeout Summary

**Adopter-facing docs now present one boring default-lane proof order and keep handoff, semantic, and knowledge surfaces explicitly secondary**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-26T12:20:00Z
- **Completed:** 2026-05-26T12:40:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Rewrote README verification guidance around `mix scoria.install -> mix ecto.migrate -> mix test.adoption -> inspect /scoria and /scoria/workflows/:run_id`.
- Updated the lane guide and operator guide to promote `mix test.knowledge` and keep `mix test` as broader repo-health context only.
- Clarified that bounded handoffs and semantic fast path are additive lanes, not first-adoption prerequisites or separate closeout proof chains.

## Task Commits

No new commits were created during this Codex run. The executed changes remain in the local working tree alongside pre-existing user changes.

## Files Created/Modified
- `README.md` - Default-lane verification order and optional-lane boundaries now match the phase contract.
- `docs/adoption_lanes.md` - Four-lane field guide now promotes one canonical verifier per lane.
- `docs/operator_verification.md` - Closeout/default/optional/context hierarchy now uses the bounded `release_preview -> test.adoption` chain.
- `docs/bounded_handoffs.md` - Handoffs are explicitly additive after `mix test.adoption`.
- `docs/semantic_fast_path.md` - Semantic troubleshooting now points to `mix test.knowledge` for the optional knowledge lane.

## Decisions Made

- Keep public docs recommendation-first and avoid documenting compatibility aliases unless necessary to prevent support ambiguity.
- Treat optional semantic and knowledge setup as explicit non-prerequisites for first adoption.

## Deviations from Plan

None - the docs were rewritten directly around the locked Phase 49 wording decisions.

## Issues Encountered

None. The work was bounded to copy alignment and link-preserving guide updates.

## User Setup Required

None - this plan only changes adopter-facing wording.

## Next Phase Readiness

Wave 2 guardrail tests can now lock the rewritten command hierarchy in source assertions without fighting contradictory docs language.

---
*Phase: 49-support-truth-and-adoption-closeout*
*Completed: 2026-05-26*

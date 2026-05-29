# Phase 74 Learnings — Journey Fixture Foundation

**Milestone:** v2.9  
**Phase:** 74

## Graduated lessons (from adoption assessment)

- **D:** Adopter done-ness = host-app surprise reduction + journey depth, not feature count.
- **E:** Proof harness (overlay) + gallery (examples/) must share fixture SSOT or drift is guaranteed.
- **F:** Example gallery is companion/advisory CI, not merge-blocking closeout.

## Decisions

- `Scoria.SupportJourney` ships in `lib/` with JSON fixtures under `priv/fixtures/support_journey/`.
- `AdoptionExample` remains the SSOT for v2.2–v2.8 default-lane doc fragments; `SupportJourney` owns gallery-specific journey truth.

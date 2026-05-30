# Thread: Milestone Next-Step Assessment (2026-05-30)

**Captured:** 2026-05-30  
**Status:** closed  
**Supersedes:** `.planning/threads/2026-05-29-adoption-journey-assessment.md`

## Assessment Outcome

- **Done estimate:** ~88–92% for embedded Phoenix AI-ops scope (upper 80–89% band).
- **Not CI-blocked:** Tarball adoption, registry attest, orchestrator live wiring shipped in v2.10–v2.11.
- **Soft gaps:** Gallery depth, docs persona split, connector named lane, registry semver leg.
- **Selected next milestone:** v2.12 Adoption Confidence & Reference Demo (reframed LANE-DEMO-01).
- **Queue:** v2.13 docs truth → v2.14 maintenance `0.1.1` → v2.15 connector adoption lane.

## Key Decisions

1. **Demo-first before docs split** — gallery journeys give concrete content to document.
2. **LiveView producer path > browser for CI** — Wallaby deferred; deterministic integration preferred.
3. **Gallery stays advisory** — not in `VerificationLanes.closeout_order/0`.
4. **Shared handlers** — `Scoria.SupportJourney.Handlers` prevents overlay/gallery drift.

## Graduation Candidates

- Adopter done-ness = host-app surprise reduction + journey depth, not feature count.
- Proof harness (overlay) + gallery (examples/) must share fixture SSOT.
- LiveView producer path is the orchestrator trust contract for shift-left CI.

## Implementation Notes (v2.12)

- Handler SSOT, optional lane gallery journeys, orchestrator producer smoke, gallery docs updated.
- v2.13/v2.14 partially executed in same pass: MAINTAINERS.md split, Hex metadata, `0.1.1` bump.

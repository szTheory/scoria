# Requirements — Milestone v2.9 Adoption Journey & Reference Demo

**Milestone:** v2.9  
**Status:** Active  
**Last updated:** 2026-05-29

## v2.9 Requirements

### Journey fixtures

- [x] **JOURN-01**: `Scoria.SupportJourney` exposes shared identities, handler contracts, seed ticket data, doc fragments, and operator UI expectations as the single source of truth for adoption journey proof.
- [x] **JOURN-02**: Source contract tests pin `SupportJourney` fragments against docs and prevent drift between overlay, gallery, and adopter guides.

### Host-proof overlay (merge-blocking)

- [x] **HOST-01**: Generated-host overlay proves install → migrate → default run → approval wait → `resume_run` → completed status using `SupportJourney` identities.
- [x] **HOST-02**: Generated-host overlay proves bounded handoff (`start_handoff_run/3`) with delegated evidence visible on `/scoria/workflows/:run_id`.

### Reference gallery (companion)

- [x] **GALL-01**: Committed `examples/support_copilot/` Phoenix app demonstrates support-copilot domain with rich seeds, host chat surface, and Scoria operator routes.
- [x] **GALL-02**: Gallery app tests exercise default-lane and handoff happy paths with deterministic LiveView assertions aligned to `SupportJourney`.

### Advisory CI + docs

- [x] **CI-GALL-01**: `mix scoria.test.support_copilot` runs gallery + journey contract tests; lane is documented as advisory and excluded from `closeout_order/0`.
- [x] **DOCS-GALL-01**: README and operator verification document how to spin up the gallery locally; drift guards link gallery ↔ fixtures ↔ docs.

## Future Requirements (deferred)

- **HEX-CONSUMER-01**: Hex dependency consumer proof (v2.10).
- **ORCH-LIVE-01**: Runtime→PubSub trace broadcast and HITL modal from real approvals (v2.11).
- **LANE-DEMO-01**: Semantic, knowledge, and connector journeys in gallery (v2.12).

## Out of Scope (this milestone)

- Hosted demo environments or managed onboarding services.
- Adding gallery tests to `mix test.adoption` closeout chain.
- Net-new runtime capability families.
- Wallaby/browser CI (LiveViewTest only for v2.9).

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| JOURN-01 | 74 | Complete |
| JOURN-02 | 74 | Complete |
| HOST-01 | 75 | Complete |
| HOST-02 | 75 | Complete |
| GALL-01 | 76 | Complete |
| GALL-02 | 76 | Complete |
| CI-GALL-01 | 77 | Complete |
| DOCS-GALL-01 | 77 | Complete |

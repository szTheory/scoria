# Roadmap — Milestone v2.9 Adoption Journey & Reference Demo

**Milestone:** v2.9  
**Phases:** 74–77.2 (continuing from v2.8 phase 73)  
**Last updated:** 2026-05-29 (77.2-02: CI contract test for gallery-after-knowledge ordering)

## Overview

Battle-test Scoria through a realistic support-copilot domain: shared journey fixtures, extended merge-blocking host-proof overlay, committed gallery app, and advisory CI lane — without weakening v2.4–v2.8 lane contracts.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 74 | Journey fixture foundation | `SupportJourney` SSOT + source contract tests | JOURN-01, JOURN-02 |
| 75 | Host-proof overlay expansion | Resume + handoff smokes in generated host | HOST-01, HOST-02 |
| 76 | Support copilot example app | Committed gallery with seeds + host UI | GALL-01, GALL-02 |
| 77 | Gallery CI + docs closeout | Advisory lane, README, operator docs | CI-GALL-01, DOCS-GALL-01 |
| 77.1 | Close gap: DOCS-GALL-01 drift guard expansion | Multi-surface drift guards | DOCS-GALL-01 |
| 77.2 | Address tech debt: v2.9 planning hygiene + CI contract (INSERTED) | Retroactive planning artifacts + CI contract test | CI-GALL-01 |

## Phase 74: Journey fixture foundation

**Goal:** Establish `Scoria.SupportJourney` as the single source of truth for adoption journey identities, seed data, handler contracts, and doc fragments.

**Success criteria:**
1. `lib/scoria/support_journey.ex` and `priv/fixtures/support_journey/` ship with the package.
2. `test/scoria/support_journey_source_test.exs` pins fragments against docs.
3. `AdoptionExample` delegates shared constants to `SupportJourney` where appropriate.

## Phase 75: Host-proof overlay expansion

**Goal:** Extend merge-blocking generated-host proof to cover approve→resume and bounded handoff journeys.

**Success criteria:**
1. Overlay runtime smoke proves `resume_run` completion using `SupportJourney` identities.
2. New `host_handoff_smoke_test.exs` proves delegated evidence on workflow page.
3. `mix test.adoption` remains green; `closeout_order/0` unchanged.

## Phase 76: Support copilot example app

**Goal:** Ship `examples/support_copilot/` as a human-clickable gallery with realistic support-domain seeds.

**Success criteria:**
1. Adopter can `cd examples/support_copilot && mix setup && mix phx.server`.
2. Gallery tests prove default-lane and handoff happy paths with LiveView assertions.
3. Gallery imports `SupportJourney` fixtures — no duplicated handler logic.

## Phase 77: Gallery CI + docs closeout

**Goal:** Wire advisory CI lane and document the gallery in README and operator verification.

**Success criteria:**
1. `mix scoria.test.support_copilot` runs gallery subprocess proof + contract tests.
2. CI runs gallery lane after closeout lanes (advisory, non-blocking).
3. README gallery section and operator verification updated with drift guards.

## Phase 77.1: Close gap: DOCS-GALL-01 drift guard expansion (INSERTED)

**Goal:** Close the v2.9 milestone audit partial on DOCS-GALL-01 by extending automated `SupportJourney` fragment pinning beyond `docs/support_copilot_gallery.md` to README and operator verification surfaces.

**Depends on:** Phase 77

**Success criteria:**
1. `SupportJourneySourceTest` (or equivalent contract tests) assert gallery-related `doc_fragments/0` against `README.md` and `docs/operator_verification.md`.
2. Drift between gallery fixtures, advisory lane command, and all three adopter docs fails CI — not only the gallery guide.
3. No widening of `VerificationLanes.closeout_order/0`; advisory gallery lane posture unchanged.

## Phase 77.2: Address tech debt: v2.9 planning hygiene + CI contract (INSERTED)

**Goal:** Close v2.9 milestone audit tech debt — retroactive planning artifacts for phases 74–77 and CI contract test for gallery lane ordering.

**Depends on:** Phase 77.1

**Success criteria:**
1. Retroactive VERIFICATION.md (or equivalent closeout ledgers) for phases 74–77 documenting shipped evidence.
2. `ci_policy_contract_test.exs` asserts gallery lane runs after knowledge WAE in CI topology.
3. No functional regressions; `closeout_order/0` and advisory lane posture unchanged.

## Prior milestones (archived)

- ✅ **v2.8 CI Hardening & Post-Ship Hygiene** — `.planning/milestones/v2.8-*`
- ✅ **v2.7 OSS Release + Docs Truth** — `.planning/milestones/v2.7-*`
- ✅ **v2.6 Warning Ratchet** — `.planning/milestones/v2.6-*`

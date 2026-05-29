# Roadmap — Milestone v2.9 Adoption Journey & Reference Demo

**Milestone:** v2.9  
**Phases:** 74–77 (continuing from v2.8 phase 73)  
**Last updated:** 2026-05-29

## Overview

Battle-test Scoria through a realistic support-copilot domain: shared journey fixtures, extended merge-blocking host-proof overlay, committed gallery app, and advisory CI lane — without weakening v2.4–v2.8 lane contracts.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 74 | Journey fixture foundation | `SupportJourney` SSOT + source contract tests | JOURN-01, JOURN-02 |
| 75 | Host-proof overlay expansion | Resume + handoff smokes in generated host | HOST-01, HOST-02 |
| 76 | Support copilot example app | Committed gallery with seeds + host UI | GALL-01, GALL-02 |
| 77 | Gallery CI + docs closeout | Advisory lane, README, operator docs | CI-GALL-01, DOCS-GALL-01 |

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

## Prior milestones (archived)

- ✅ **v2.8 CI Hardening & Post-Ship Hygiene** — `.planning/milestones/v2.8-*`
- ✅ **v2.7 OSS Release + Docs Truth** — `.planning/milestones/v2.7-*`
- ✅ **v2.6 Warning Ratchet** — `.planning/milestones/v2.6-*`

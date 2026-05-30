# Roadmap: Scoria

**Last updated:** 2026-05-30 (v2.12–v2.14 shipped; v2.15 planning)

## Milestones

- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)
- ✅ **v2.11 Orchestrator Live Wiring** — Phases 01, 01.1 (shipped 2026-05-30) — [archive](milestones/v2.11-ROADMAP.md)
- ✅ **v2.10 Hex Consumer Proof & Upgrade Smoke** — Phases 78–82 (shipped 2026-05-30)

## Phases (v2.12)

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 02 | Handler SSOT & tool exercise | Deduplicate journey handlers; wire lookup/refund tools | DEMO-01–03 | complete |
| 03 | Semantic & knowledge gallery lanes | Optional lane demos with LiveView tests | LANE-01, LANE-02 | complete |
| 04 | Connector lane, orchestrator smoke, docs | Connector journey + producer-path /scoria + gallery docs | LANE-03, ORCH-01, DOCS-01–02 | complete |

### Phase 02: Handler SSOT & tool exercise

**Goal:** Single handler module for overlay and gallery; exercise scenario tools.

**Requirements:** DEMO-01, DEMO-02, DEMO-03

**Success criteria:**
1. `Scoria.SupportJourney.Handlers` is the only handler implementation for journey smokes
2. Gallery "Lookup ticket" journey passes
3. Default + handoff journeys unchanged and green

### Phase 03: Semantic & knowledge gallery lanes

**Goal:** Demonstrate optional semantic and knowledge lanes in the reference demo.

**Requirements:** LANE-01, LANE-02

**Success criteria:**
1. Semantic FAQ button starts semantic-cache-enabled run in gallery
2. Knowledge lane seeds refund policy and completes journey test
3. Advisory lane `mix scoria.test.support_copilot` includes new tests

### Phase 04: Connector lane, orchestrator smoke, docs

**Goal:** Complete optional lane coverage and producer-path orchestrator confidence.

**Requirements:** LANE-03, ORCH-01, DOCS-01, DOCS-02

**Success criteria:**
1. Billing connector journey registers connector and lists in fleet
2. Orchestrator producer test shows approval from real runtime path
3. Gallery guide explains clone-repo and tarball vs path distinction
4. SupportJourney drift guards cover lane fragments

## Next milestone queue

- **v2.15:** Connector Adoption Lane (named proof task `mix test.connector`) — phases 05–07

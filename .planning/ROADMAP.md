# Roadmap: Scoria

**Last updated:** 2026-05-30 (v2.15 planning)

## Milestones

- 🚧 **v2.15 Connector Adoption Lane** — Phases 05–07 (planning)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)

## Phases (v2.15)

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 05 | Lane contract + Mix task | Named `mix test.connector` in VerificationLanes | CONN-LANE-01, CONN-LANE-02 | complete |
| 06 | Integration proof | SupportJourney connector register → fleet → drawer | CONN-LANE-03 | complete |
| 07 | Docs, drift guards, CI | Docs truth + PR WAE wiring | CONN-DOCS-01, CONN-DOCS-02, CONN-CI-01 | complete |

### Phase 05: Lane contract + Mix task

**Goal:** Add `:connector` to `VerificationLanes` and scaffold `Mix.Tasks.Scoria.Test.Connector`.

**Requirements:** CONN-LANE-01, CONN-LANE-02

**Success criteria:**
1. `VerificationLanes.command(:connector)` returns `mix test.connector`
2. `:connector` is not in `closeout_order/0`
3. `mix test.connector` runs bounded connector test file set green

### Phase 06: Integration proof + SupportJourney alignment

**Goal:** Prove register → fleet → operator drawer path with SupportJourney fixture identities.

**Requirements:** CONN-LANE-03

**Success criteria:**
1. `Scoria.Connectors.AdoptionLaneTest` uses `SupportJourney.connector_key/0` and `tenant_id/0`
2. Fleet list and drawer evidence assertions pass under lane task

### Phase 07: Docs, drift guards, CI wiring

**Goal:** Document connector lane; wire PR CI WAE after knowledge; update drift guards.

**Requirements:** CONN-DOCS-01, CONN-DOCS-02, CONN-CI-01

**Success criteria:**
1. `docs/adoption_lanes.md` and `docs/connector_adoption.md` name `mix test.connector`
2. `SupportJourney` + `adoption_surface_test` pin connector lane fragments
3. `ci-verify.yml` runs connector lane after knowledge, before gallery
4. `docs/MAINTAINERS.md` gate map includes connector lane row

## Previous milestone archive

See `.planning/MILESTONES.md` for v2.12–v2.14 closeout history.

# Requirements: Milestone v2.15 Connector Adoption Lane

**Milestone:** v2.15  
**Status:** Active (phases 05–07 implemented)  
**Last updated:** 2026-05-30

## v2.15 Requirements

### Lane Contract & Proof Task

- [x] **CONN-LANE-01**: `VerificationLanes` exposes `:connector` with command, prerequisites (`mix test.adoption`), and explicit exclusions — not in `closeout_order/0`
- [x] **CONN-LANE-02**: `Mix.Tasks.Scoria.Test.Connector` runs a bounded, documented test file set via `mix test.connector`

### Integration Proof

- [x] **CONN-LANE-03**: Lane proves register → fleet list → operator drawer evidence using `SupportJourney` fixture identities

### Docs Truth

- [x] **CONN-DOCS-01**: `adoption_lanes.md` and `connector_adoption.md` name `mix test.connector` with embedded-boundary framing
- [x] **CONN-DOCS-02**: `SupportJourney.adopter_doc_surfaces/0` and adoption drift guards pin connector lane command + boundary wording

### CI

- [x] **CONN-CI-01**: PR CI runs `mix test.connector --warnings-as-errors` after knowledge WAE and before advisory gallery; not in closeout order

## Future Requirements

- Connector lane expansion into host-proof overlay tarball consumer (defer — gallery covers domain story)

## Out of Scope

- Widening `VerificationLanes.closeout_order/0` for connector
- Hosted connector platform scope
- Wallaby/browser CI for connector proof
- Net-new connector capability families (v1.5 boundary already shipped)

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONN-LANE-01 | 05 | complete |
| CONN-LANE-02 | 05 | complete |
| CONN-LANE-03 | 06 | complete |
| CONN-DOCS-01 | 07 | complete |
| CONN-DOCS-02 | 07 | complete |
| CONN-CI-01 | 07 | complete |

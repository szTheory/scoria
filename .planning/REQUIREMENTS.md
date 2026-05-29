# Requirements: Scoria

**Defined:** 2026-05-28
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v2.7 Requirements

Requirements for milestone `v2.7 OSS Release + Docs Truth`. Docs truth merges before Hex publish.

### Docs Truth

- [x] **DOCS-03**: README and support docs use a capability-based shipped banner (not internal milestone codenames) reflecting v2.5+ installer safety and v2.6 CI trust; `adoption_surface_test` guards updated accordingly.
- [x] **DOCS-04**: Maintainer docs state semantic fast-path is a local troubleshooting lane (not PR CI) and explain planning milestones (`v2.x`) vs Hex semver (`0.1.0`) once each for adopters.

### Maintainer DX

- [x] **INST-DX-01**: `mix scoria.test.install_contract` runs deep installer contract proofs as a maintainer-only task; adoption lane file list excludes those tests; task documented in operator verification.

### Hex Publish

- [x] **HEX-01**: First Hex publish at semver `0.1.0` with git tag `v0.1.0`; release-please (or equivalent szTheory release automation) and publish workflow runs the same test topology as PR CI before `mix hex.publish`.
- [x] **HEX-02**: CHANGELOG for `0.1.0`, GitHub release at `v0.1.0`, Hex badge on README, and coordinated flip of README install snippet plus `package_surface_test` from pre-publish GitHub-only to Hex-primary with GitHub tag fallback.

## v2.8 Requirements

Shipped in milestone `v2.8 CI Hardening & Post-Ship Hygiene` (Phase 73):

- [x] **SEM-CI-01**: Semantic fast-path lane in PR CI after closeout lanes, without widening `VerificationLanes.closeout_order/0`.
- [x] **CI-KNOW-01**: `mix test.knowledge --warnings-as-errors` in CI.
- [x] **CI-INV-01**: `mix scoria.warning_inventory.check_baseline` in policy job — committed inventory JSON must keep `clusters` empty.

## Future Requirements

None queued for v2.8 closeout.

## Out of Scope

| Feature | Reason |
|---------|--------|
| SEM-CI-01 as v2.7 success criterion | v2.7 focused on Hex publish; landed in v2.8 |
| Knowledge WAE in default closeout order | Optional lane stays after full-suite WAE, not in closeout_order |
| New runtime capability families | v2.7 is adoption/maintainer trust, not breadth |
| Connector adoption guide expansion | Narrow `docs/connector_adoption.md` added post-v2.7; deep profiles deferred |
| Package-family Hex split | Too wide for first publish |
| Landing page / brand book visual implementation | Not release-blocking |
| Broad installer engine rewrite | v2.5 closed installer trust |
| Hex semver `2.7.0` to match GSD milestone | Breaks Elixir norms; use `0.1.0` for first publish |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOCS-03 | Phase 70 | Complete |
| DOCS-04 | Phase 70 | Complete |
| INST-DX-01 | Phase 70 | Complete |
| HEX-01 | Phase 71, Phase 72 | Complete |
| HEX-02 | Phase 71, Phase 72 | Complete |

**Coverage:**

- v2.7 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-29 after v2.8 CI hardening*

# Requirements: Scoria v2.2 OSS adopter onramp

**Defined:** 2026-05-25
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Scope Controls

### Packaging Ledger

| Surface | Classification | Reason |
|---------|----------------|--------|
| Hex metadata and docs configuration | `core` | Public package trust starts here |
| `mix scoria.install` contract | `core` | Primary host-app adoption seam |
| Consumer-app proof fixture or equivalent host-app harness | `core` | Closes the adopter reality gap |
| Lane-based docs and verification guides | `core` | Support truth depends on them |
| Advanced handoff examples | `defer` | Only needed if support evidence shows confusion |
| External semantic cache backends and ANN tuning | `defer` | Capability expansion, not adoption closure |

### Proof Posture

- **Merge-blocking:** package metadata and docs build locally; install and adoption lanes pass; consumer-app proof or equivalent host-app harness passes.
- **Advisory:** semantic fast path remains green on its dedicated lane; broader full-suite repo health remains informative but is not the milestone's core proof surface.

### Support Truth

- Missing Tailwind must produce explicit install-task messaging and keep the default lane installable.
- Missing optional knowledge setup must not block the default runtime lane.
- Semantic fast-path validation must route to `mix test.semantic_fast_path`.
- Docs, installer output, and verification guides must use the same lane vocabulary and order of adoption.

## v2.2 Requirements

### Packaging And Docs Truth

- [ ] **ADPT-03**: Maintainer can build Scoria's publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface.
- [ ] **ADPT-04**: Maintainer can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides.

### Host-App Install Contract

- [ ] **INST-01**: A Phoenix host app can run `mix scoria.install` once to mount the dashboard, copy core migrations, and inject baseline runtime defaults without duplicate or misleading mutations.
- [ ] **INST-02**: The default Phoenix lane installs cleanly when Tailwind or optional knowledge surfaces are absent, and the installer states the skipped or optional steps explicitly.

### Consumer-App Proof

- [ ] **PROOF-01**: A fresh Phoenix consumer app or equivalent host-app harness can prove dependency fetch, install, migration, and `/scoria` route visibility through the public adoption path.
- [ ] **PROOF-02**: That same consumer proof path can start one durable run through `Scoria.start_run/2`, read it back through the public runtime facade, and inspect operator evidence without enabling optional knowledge or semantic lanes.

### Support-Truth Alignment

- [ ] **DOCS-01**: README, operator verification, and installer output describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast-path, and optional knowledge surfaces.
- [ ] **DOCS-02**: Scoria names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing.

## Future Requirements

### Adoption Follow-up

- **ADPT-05**: Scoria ships stronger bounded-handoff examples only if actual adopter evidence proves the current public lane still creates confusion after the OSS onramp is boring.

### Semantic Follow-up

- **FAST-03**: Scoria supports external cache backends beyond the default Ecto-native semantic cache truth store.
- **FAST-04**: Scoria exposes advanced ANN tuning and analytics controls once exact-first proof and operator trust are established.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Package-family split into multiple Hex libraries | Too broad for the first adopter-closeout milestone |
| Hosted demo or managed onboarding surface | Would widen the product boundary before the embedded story is fully proven |
| Advanced bounded-handoff example expansion | Defer unless support evidence proves the current lane is still confusing |
| External semantic cache backends and ANN tuning | Adjacent capability work, not adoption closure |
| Folding optional knowledge or semantic verification into the default lane | Would weaken truthful prerequisite boundaries |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADPT-03 | Phase 47 | Pending |
| ADPT-04 | Phase 47 | Pending |
| INST-01 | Phase 48 | Pending |
| INST-02 | Phase 48 | Pending |
| PROOF-01 | Phase 48 | Pending |
| PROOF-02 | Phase 48 | Pending |
| DOCS-01 | Phase 49 | Pending |
| DOCS-02 | Phase 49 | Pending |

**Coverage:**
- v2.2 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after starting v2.2 OSS adopter onramp*

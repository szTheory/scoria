# Requirements: Scoria v3.5 Documentation & Release Readiness

**Defined:** 2026-07-09
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Positioning

- [x] **POS-01**: A Phoenix adopter can read the README first screen and understand that Scoria is an embedded Phoenix library for durable, inspectable AI/LLM work before encountering capability or verification-suite vocabulary.
- [x] **POS-02**: A Phoenix adopter can identify who Scoria is for, who it is not for, and how the n=1 reviewer/operator persona maps to the product surface.
- [x] **POS-03**: A Phoenix adopter can see what Scoria owns versus what the host app owns through a concrete scope-doctrine table.
- [x] **POS-04**: A Phoenix adopter can compare Scoria to hosted LLM-ops tools using honest tradeoffs: embedded governance, zero required egress, in-path gates, and ceded warehouse/cross-language strengths.

### Terminology

- [x] **TERM-01**: A Phoenix adopter can learn final canonical terms from a glossary that maps Scoria terms to industry equivalents.
- [x] **TERM-02**: Adopter-facing docs use the final terminology strategy: reviewer for the persona, trace for run-inspection surface sense, capabilities for adoption scope, verification suite for `mix test.*` proof commands, scoped context, semantic cache, and optional knowledge base.
- [x] **TERM-03**: Adopter-facing docs preserve correct RAG/citation use of evidence while removing leaked internal milestone code names and stale lane/count/version wording.
- [x] **TERM-04**: Public README and CHANGELOG include a pre-1.0 upgrade note for terminology changes that affect documented names, modules, or user-visible copy.

### Documentation

- [x] **DOCS-01**: A Phoenix adopter can navigate ExDoc through grouped modules and grouped extras instead of one flat sidebar.
- [x] **DOCS-02**: ExDoc source links, release docs links, logo/favicon metadata, and markdown/html formatter settings are version-aware and do not point `-dev` docs at missing tag URLs.
- [x] **DOCS-03**: Stable adopter guides are organized into a clear guide ladder covering getting started, golden path, user flows/JTBD, troubleshooting, hosted-LLM-ops comparison, and a cheatsheet.
- [ ] **DOCS-04**: Public moduledocs and guide links are warning-clean under the milestone's docs verification command.

### AI Accessibility

- [x] **AI-01**: An LLM or coding agent can use a curated root `llms.txt` and/or `AGENTS.md` to find Scoria's public facade, guide ladder, glossary, capabilities, and verification suites.
- [x] **AI-02**: The AI-accessibility surface distinguishes curated source docs from generated ExDoc artifacts and avoids stale or internal planning-only vocabulary.

### Release

- [ ] **REL-01**: The release train no longer fails on planning-ledger drift; the roadmap includes archived milestone breadcrumbs required by the policy contract, including v2.15 Connector Adoption Lane.
- [ ] **REL-02**: The release train no longer fails on current browser e2e regressions from PR #12, including hidden theme-toggle clicks, modal focus checks, and orientation walkthrough failures.
- [ ] **REL-03**: Version references in README, maintainer docs, release notes, and release automation reflect the live `0.1.2` baseline and the `0.1.3` release target without stale `0.1.1` guidance.
- [ ] **REL-04**: The `0.1.3` release PR reaches green `ci-gate`, publishes to Hex, and passes post-publish smoke for fresh install plus live-lineage upgrade.

## v2 Requirements

Deferred to future milestones. Tracked but not in the current roadmap.

### Future Capability Docs

- **TRACE-01**: OpenInference-compatible trace claims are updated after SEED-007 implements the trace substrate.
- **GOV-01**: Lethal-trifecta security boundary docs are written after SEED-010 implements the governance seam.
- **EVAL-DEPTH-01**: Trustworthy eval-depth guides are written after SEED-008 implements scorer/calibration/regression depth.
- **RAG-DEPTH-01**: Retrieval eval and faithfulness/reranker guides are written after SEED-009 implements the RAG depth seams.
- **PRIV-01**: Privacy, retention, purge, masking, and feedback docs are written after SEED-011 implements those controls.

### Repo Health

- **TEST-DET-01**: Broad SEED-004 test-code determinism work converts forced-serial test surfaces and removes non-essential sleeps after the release-readiness slice is complete.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Implementing SEED-007 trace substrate | This milestone may correct overclaims, but the OTel/OpenInference implementation belongs to the next feature milestone. |
| Implementing lethal-trifecta governance | This is the flagship feature milestone after trace substrate, not docs/release readiness. |
| Writing feature-specific guides for unbuilt seeds | Stable docs only; feature-specific docs must be written with their owning build milestone. |
| Broad SEED-004 async/test determinism refactor | Only release-blocking CI/e2e failures are in scope; broad test architecture cleanup remains a separate milestone. |
| Hosted demo or managed onboarding | Scoria remains an embedded library with local examples and docs, not a hosted service. |
| Modeling host business nouns such as Feature, Env, identity, or policy values | The scope doctrine says host declares and owns these nouns; Scoria records, gates, surfaces, and reconstructs. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| POS-01 | Phase 47 | Complete |
| POS-02 | Phase 47 | Complete |
| POS-03 | Phase 47 | Complete |
| POS-04 | Phase 47 | Complete |
| TERM-01 | Phase 46 | Complete |
| TERM-02 | Phase 46 | Complete |
| TERM-03 | Phase 46 | Complete |
| TERM-04 | Phase 46 | Complete |
| DOCS-01 | Phase 48 | Complete |
| DOCS-02 | Phase 48 | Complete |
| DOCS-03 | Phase 48 | Complete |
| DOCS-04 | Phase 49 | Pending |
| AI-01 | Phase 49 | Complete |
| AI-02 | Phase 49 | Complete |
| REL-01 | Phase 50 | Pending |
| REL-02 | Phase 50 | Pending |
| REL-03 | Phase 50 | Pending |
| REL-04 | Phase 50 | Pending |

**Coverage:**

- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-07-09*
*Last updated: 2026-07-09 after roadmap creation*

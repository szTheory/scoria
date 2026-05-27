# Requirements: Scoria

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1 Requirements

Requirements for milestone `v2.5 Installer Safety & Upgrade Confidence`.

### Installer Planning Contracts

- [x] **INST-03**: Maintainer can run `mix scoria.install --dry-run` and receive an ordered mutation plan without writing host files.
- [x] **INST-04**: Maintainer can run `mix scoria.install --check` to validate host compatibility and get non-zero exit semantics when drift or manual review is required.
- [x] **INST-05**: Maintainer can inspect per-surface mutation classification (`create`, `update`, `no-op`, `manual-review`) with file targets and rationale before apply.

### Drift-Aware Apply Safety

- [x] **INST-06**: Installer apply mode executes from the same planner artifact used by `--dry-run` and `--check`, so previewed mutations match applied mutations.
- [x] **INST-07**: Installer uses manifest-aware drift detection for managed router/config/migration surfaces and reports explicit remediation steps instead of blind overwrite.
- [x] **INST-08**: Installer output stays truthful and idempotent across preview/check/apply, including stable summaries for already-installed, skipped, and manual-review surfaces.

## v2 Requirements

Deferred to immediate follow-up milestone.

### Warning Ratchet Follow-up

- **WARN-03**: Full-suite warning baseline ratchet runs to closure with owner+expiry enforcement.

## Out of Scope

Explicitly excluded from this milestone.

| Feature | Reason |
|---------|--------|
| Broad installer engine rewrite beyond planner/check + drift-safe apply | Too wide for this leverage slice; risks delaying high-impact trust contracts |
| New runtime capability families | Priority is installer mutation confidence, not capability breadth |
| Folding optional semantic/knowledge lanes into default adoption path | Would weaken explicit lane-boundary contracts from v2.4 |
| `WARN-03` implementation work | Intentionally queued next so installer risk closes first |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INST-03 | Phase 59 | Complete |
| INST-04 | Phase 59 | Complete |
| INST-05 | Phase 59 | Complete |
| INST-06 | Phase 60 | Complete |
| INST-07 | Phase 60 | Complete |
| INST-08 | Phase 61 | Complete |

### Gap Closure (v2.5 audit)

| Item | Phase | Status |
|------|-------|--------|
| Nyquist validation + SUMMARY frontmatter parity (phases 59–61) | Phase 62 | Complete |
| Manifest check fingerprint integration hardening (INST-07 partial) | Phase 63 | Complete |
| Adoption lane discoverability sync (integration drift) | Phase 64 | Pending |
| Phase 63 Nyquist validation ledger | Phase 65 | Complete |

**Coverage:**

- v1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0
- Gap closure phases: 4 (audit tech debt + integration hardening + discoverability + Nyquist)

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after v2.5 post-audit gap closure planning*

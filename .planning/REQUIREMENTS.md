# Requirements: Scoria

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v1 Requirements

Requirements for milestone `v2.5 Installer Safety & Upgrade Confidence`.

### Installer Planning Contracts

- [ ] **INST-03**: Maintainer can run `mix scoria.install --dry-run` and receive an ordered mutation plan without writing host files.
- [ ] **INST-04**: Maintainer can run `mix scoria.install --check` to validate host compatibility and get non-zero exit semantics when drift or manual review is required.
- [ ] **INST-05**: Maintainer can inspect per-surface mutation classification (`create`, `update`, `no-op`, `manual-review`) with file targets and rationale before apply.

### Drift-Aware Apply Safety

- [ ] **INST-06**: Installer apply mode executes from the same planner artifact used by `--dry-run` and `--check`, so previewed mutations match applied mutations.
- [ ] **INST-07**: Installer uses manifest-aware drift detection for managed router/config/migration surfaces and reports explicit remediation steps instead of blind overwrite.
- [ ] **INST-08**: Installer output stays truthful and idempotent across preview/check/apply, including stable summaries for already-installed, skipped, and manual-review surfaces.

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
| INST-03 | Phase 59 | Pending |
| INST-04 | Phase 59 | Pending |
| INST-05 | Phase 59 | Pending |
| INST-06 | Phase 60 | Pending |
| INST-07 | Phase 60 | Pending |
| INST-08 | Phase 61 | Pending |

**Coverage:**
- v1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after milestone v2.5 initialization*

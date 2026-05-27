# Requirements: Scoria

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v2.6 Requirements

Requirements for milestone `v2.6 Warning Ratchet`.

### Baseline Policy

- [x] **WARN-03**: CI fails when any accepted-debt row in `.planning/WARNING-BASELINE.md` is past its expiry date.
- [x] **WARN-04**: Maintainer can run a documented inventory path that classifies full-suite compiler warnings by surface/area (directory, lane, or test group).

### Staged Warning Ratchet

- [x] **WARN-05**: `mix compile --warnings-as-errors` and canonical lane-contract tests remain green without regression.
- [x] **WARN-06**: High-signal test surfaces (`test/scoria/`, adoption lane tests, core workflow/replay LiveView tests targeted by inventory) pass under `--warnings-as-errors`.
- [x] **WARN-07**: CI runs `mix test --warnings-as-errors` and passes, or remaining debt is explicitly re-baselined in `.planning/WARNING-BASELINE.md` with owner and renewed expiry.

### CI Trust

- [ ] **CI-03**: CI preserves canonical closeout order (`release_preview` → `adoption` → `runtime_to_handoff`) while running baseline-expiry and staged WAE checks before the broad test gate.

## Future Requirements

Deferred beyond `v2.6`:

- **HEX-01**: First Hex publish with release process and version-tag alignment (v2.7).
- **DOCS-03**: README and support docs reflect v2.5+ shipped capability; `adoption_surface_test` shipped-state assertions updated (v2.7).
- **SEM-CI-01**: Optional semantic lane in CI without widening default closeout order.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Hex publish, README shipped-state rewrite | v2.7 OSS/docs-truth milestone |
| Semantic CI gate in default closeout | Optional wedge; not required for warning ratchet |
| Connector adoption guides expansion | Defer until OSS/docs truth lands |
| New runtime capability families | Repo is feature-strong; maintainer trust wedge first |
| All-at-once zero-warning flip without inventory | Risks noisy failures; staged ratchet required |
| Installer plan/apply changes | v2.5 closed installer trust; out of v2.6 scope |
| LiveView async teardown beyond inventory-targeted fixes | May remain baselined until 2026-06-30 if fixes are low-signal |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WARN-03 | Phase 66 | Complete |
| WARN-04 | Phase 66 | Complete |
| WARN-05 | Phase 67 | Complete |
| WARN-06 | Phase 67 | Complete |
| WARN-07 | Phase 68 | Complete |
| CI-03 | Phase 69 | Pending |

**Coverage:**

- v2.6 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after v2.6 roadmap creation*

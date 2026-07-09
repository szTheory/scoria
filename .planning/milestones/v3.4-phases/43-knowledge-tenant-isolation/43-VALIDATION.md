---
phase: 43
slug: knowledge-tenant-isolation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-05
updated: 2026-07-09T18:37:29Z
---

# Phase 43 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix; knowledge tests use `Scoria.KnowledgeCase`. |
| **Config file** | `config/test.exs`; test DB defaults to `localhost:55432`, database `scoria_test`. |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test.knowledge --warnings-as-errors` |
| **Estimated runtime** | ~20-60 seconds for the knowledge lane, depending on local DB state. |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` once the file exists, plus any existing test file touched by the task.
- **After every plan wave:** Run `MIX_ENV=test mix test.knowledge --warnings-as-errors`.
- **Before `/gsd:verify-work`:** Full knowledge suite must be green.
- **Max feedback latency:** 60 seconds expected for targeted test feedback; use the full knowledge suite at wave boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-W0-01 | 43-02 | 0 | KNOW-01 | T-43-01 | Knowledge migration adds tenant/scope columns and tenant indexes without changing the original create migration. | migration/schema integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | Yes | green |
| 43-W0-02 | 43-02, 43-03, 43-05 | 0 | KNOW-02 | T-43-02 | Retrieval runs, retrieval results, and citations persist tenant/actor audit evidence. | integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | Yes | green |
| 43-W0-03 | 43-01, 43-03, 43-04, 43-05 | 0 | KNOW-03 | T-43-03 | Nil or empty tenant raises before embedding/backend/list/citation paths can match all rows. | unit/integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | Yes | green |
| 43-W0-04 | 43-01, 43-04, 43-05 | 0 | KNOW-04 | T-43-04 | Tenant A retrieval returns zero tenant B chunks even when tenant B has the nearest vector. | integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | Yes | green |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [x] `test/scoria/knowledge/tenant_isolation_test.exs` - covers KNOW-01, KNOW-02, KNOW-03, and KNOW-04.
- [x] `test/scoria/knowledge_lane_contract_test.exs` - expected file list includes the tenant isolation test.
- [x] Existing knowledge tests pass explicit scope or assert fail-closed missing-scope behavior.
- [x] Migration/schema/index assertions exist in `tenant_isolation_test.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Knowledge lane production migration run path documentation is accurate. | KNOW-01 | Documentation wording is reviewed manually, while command/path presence is source-checked. | Confirm docs name `KnowledgeMigrationRepo`, `schema_migrations_knowledge`, and `priv/repo/knowledge_migrations/` as the optional knowledge migration lane. |

Documentation wording is now also covered by `test/scoria/scope_doctrine_contract_test.exs`. All tenant isolation, nil-tenant, actor-scope, result rejection, and citation-scope behaviors have automated verification.

---

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 4 requirements |
| Escalated | 0 |

Fresh closeout command: `MIX_ENV=test mix test.knowledge --warnings-as-errors` passed with 54 tests, 0 failures, 1045 excluded.

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing test references.
- [x] No watch-mode flags.
- [x] Feedback latency stays under 60 seconds for targeted checks.
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and pass.

**Approval:** complete

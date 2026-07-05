---
phase: 43
slug: knowledge-tenant-isolation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-05
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
| 43-W0-01 | TBD | 0 | KNOW-01 | T-43-01 | Knowledge migration adds tenant/scope columns and tenant indexes without changing the original create migration. | migration/schema integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | No - Wave 0 | pending |
| 43-W0-02 | TBD | 0 | KNOW-02 | T-43-02 | Retrieval runs, retrieval results, and citations persist tenant/actor audit evidence. | integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | No - Wave 0 | pending |
| 43-W0-03 | TBD | 0 | KNOW-03 | T-43-03 | Nil or empty tenant raises before embedding/backend/list/citation paths can match all rows. | unit/integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | No - Wave 0 | pending |
| 43-W0-04 | TBD | 0 | KNOW-04 | T-43-04 | Tenant A retrieval returns zero tenant B chunks even when tenant B has the nearest vector. | integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | No - Wave 0 | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `test/scoria/knowledge/tenant_isolation_test.exs` - covers KNOW-01, KNOW-02, KNOW-03, and KNOW-04.
- [ ] `test/scoria/knowledge_lane_contract_test.exs` - update expected file list after adding the tenant isolation test.
- [ ] Update existing knowledge tests that currently call tenant-owned APIs without scope, or split those calls into explicit raise tests.
- [ ] Add a migration/schema/index assertion helper if direct Ecto metadata checks become repetitive.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Knowledge lane production migration run path documentation is accurate. | KNOW-01 | Documentation wording is reviewed manually, while command/path presence is source-checked. | Confirm docs name `KnowledgeMigrationRepo`, `schema_migrations_knowledge`, and `priv/repo/knowledge_migrations/` as the optional knowledge migration lane. |

All tenant isolation, nil-tenant, actor-scope, result rejection, and citation-scope behaviors must have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays under 60 seconds for targeted checks.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and pass.

**Approval:** pending

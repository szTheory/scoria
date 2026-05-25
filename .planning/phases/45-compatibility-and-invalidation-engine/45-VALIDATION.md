---
phase: 45
slug: compatibility-and-invalidation-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria/runtime/semantic_fast_path_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~60-180 seconds depending on DB/compile alignment |

---

## Sampling Rate

- **After Wave 0:** Run `SCORIA_DB_PORT=5432 MIX_ENV=test mix clean && SCORIA_DB_PORT=5432 MIX_ENV=test mix compile`
- **After every task commit:** Run the task-specific `SCORIA_DB_PORT=5432 MIX_ENV=test mix test ...` command from the table below
- **After every plan wave:** Run `SCORIA_DB_PORT=5432 MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-00-01 | 00 | 0 | LOOK-01 | T-45-00-01 | Recompile the repo and prove semantic-cache tests run against the live `5432` database without compile/runtime repo-port mismatch | environment | `SCORIA_DB_PORT=5432 MIX_ENV=test mix clean && SCORIA_DB_PORT=5432 MIX_ENV=test mix compile && SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs --max-cases 1` | ✅ | ⬜ pending |
| 45-01-01 | 01 | 1 | LOOK-01 | T-45-01-01 | Semantic-cache rows persist vector-backed query storage plus explicit `policy_fingerprint`, `source_fingerprint`, and state reason truth | unit | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs` | ✅ | ⬜ pending |
| 45-01-02 | 01 | 1 | LOOK-01 | T-45-01-02 | Lookup only hits after exact-first filtering plus policy/source/scope/freshness compatibility; malformed callers bypass with `query_text_missing` | unit | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs` | ✅ | ⬜ pending |
| 45-01-03 | 01 | 1 | INVD-02 | T-45-01-04 | Lookup tests preserve explicit `active`, `stale`, `invalidated`, and `writeback_rejected` truth instead of collapsing stale/incompatible rows into `:miss` | unit | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs` | ✅ | ⬜ pending |
| 45-02-01 | 02 | 2 | LOOK-01 | T-45-02-04 | Runtime metadata records `eligibility_reason_code`, `lookup_status`, and `lookup_reason_code` with distinct bypass/miss/reject/hit semantics | integration | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |
| 45-02-02 | 02 | 2 | LOOK-02 | T-45-02-02 | Reject and miss outcomes fall through to the normal workflow path while writeback stores compatibility-rich entries for future lookups | integration | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |
| 45-03-01 | 03 | 3 | INVD-01 | T-45-03-01 | Transactional invalidation helpers mutate only the intended tenant/lane slice and append explicit invalidation events | unit | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache/invalidation_test.exs` | ✅ | ⬜ pending |
| 45-03-02 | 03 | 3 | INVD-01 | T-45-03-04 | Lookup-time stale marking and incompatible-candidate invalidation leave durable state truth before live fallback resumes | integration | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/invalidation_test.exs` | ✅ | ⬜ pending |
| 45-03-03 | 03 | 3 | INVD-02 | T-45-03-02 | Active, stale, invalidated, and writeback-rejected rows remain distinguishable with stable reason codes after fallback | unit + integration | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache/invalidation_test.exs test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Clean recompile completed with `SCORIA_DB_PORT=5432 MIX_ENV=test mix clean && SCORIA_DB_PORT=5432 MIX_ENV=test mix compile`
- [ ] `test/scoria/runtime/semantic_fast_path_test.exs` expanded to assert `lookup_status=reject`, `lookup_reason_code`, and persisted `stale` fallthrough
- [ ] Dedicated invalidation coverage added in `test/scoria/semantic_cache_test.exs` or a new invalidation-focused test file

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None currently identified | — | Existing phase scope should be coverable through ExUnit plus migration/state inspection | Reassess only if execution introduces external invalidation hooks or operator-triggered revoke flows that cannot be exercised in test |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

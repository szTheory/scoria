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
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~60-180 seconds depending on DB/compile alignment |

---

## Sampling Rate

- **After every task commit:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs`
- **After every plan wave:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | LOOK-01 | T-45-01 / — | Lookup requires compatibility-gated exact hit or semantic fallback only after prompt, policy, source, freshness, and scope filters pass | unit + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |
| 45-02-01 | 02 | 1 | INVD-01 | T-45-02 / — | Prompt, policy, and source changes transition affected rows to explicit invalidated or stale truth with append-only events | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs` | ✅ | ⬜ pending |
| 45-03-01 | 03 | 2 | LOOK-02 | T-45-03 / — | Miss, stale, or reject outcomes fall through to the normal runtime path without mutating workflow truth | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |
| 45-03-02 | 03 | 2 | INVD-02 | T-45-04 / — | Active, stale, and invalidated states remain distinguishable with explicit reason codes in persisted truth and runtime metadata | unit + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] DB-port alignment for test execution: either bootstrap/reuse the pgvector test database on `55432` or recompile the repo against `5432` before trusting automated commands
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

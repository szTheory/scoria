---
phase: 13
slug: public-runtime-api-and-session-lifecycle
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-14
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` with `Phoenix.LiveViewTest` |
| **Config file** | `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~30-60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs`
- **After every plan wave:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | `RUNT-01` | `T-13-01-*` | Public facade starts runs without exposing workflow-internal contract shape | unit + integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | `IDEN-03`, `RUNT-02` | `T-13-02-*` | Resume uses exact `run_id`, preserves same-session continuity, and does not infer resume from `session_id` | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` | ✅ | ✅ green |
| 13-03-01 | 03 | 3 | `RUNT-03` | `T-13-03-*` | Inspect APIs return curated stable DTOs instead of raw workflow schemas | unit | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs` | ✅ | ✅ green |
| 13-04-01 | 04 | 4 | `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-13-04-*` | End-to-end public runtime flow proves multi-run same-session continuity and operator-visible state alignment | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scoria/runtime_test.exs` — public facade coverage for `start_run/2`, `resume_run/2`, and parameter normalization
- [x] `test/scoria/runtime_integration_test.exs` — same-session multi-run continuity and exact `run_id` resume coverage
- [x] `test/scoria/runtime_view_test.exs` — stable public summary/detail projection assertions
- [x] Public-facade integration coverage that exercises operator-visible run state through the new runtime surface

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing verification files
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated via targeted runtime lanes plus full-suite hygiene on 2026-05-16; targeted runtime lanes are the primary proof, and `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` passed as secondary regression hygiene.

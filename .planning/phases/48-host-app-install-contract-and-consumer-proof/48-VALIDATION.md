---
phase: 48
slug: host-app-install-contract-and-consumer-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir `1.19.5` |
| **Config file** | none - repo uses `test/test_helper.exs` and env-specific Mix config |
| **Quick run command** | `SCORIA_DB_PORT=\"${SCORIA_DB_PORT:-5432}\" SCORIA_DB_PASSWORD=\"${SCORIA_DB_PASSWORD:-postgres}\" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/mix/tasks/test.adoption_test.exs --trace` |
| **Full suite command** | `SCORIA_DB_PORT=\"${SCORIA_DB_PORT:-5432}\" SCORIA_DB_PASSWORD=\"${SCORIA_DB_PASSWORD:-postgres}\" MIX_ENV=test mix do clean, test.adoption` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest focused smoke for the files just changed, defaulting DB env to the available local port on `5432`.
- **Fast interim smoke:** `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs --trace`
- **After every plan wave:** Run `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test.adoption`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | INST-01 | T-48-01-01 / T-48-01-02 | Installer only reports success when router, config, and migration mutations actually land or are truthfully skipped | unit/integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs --trace` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | INST-02 | T-48-01-03 | Missing Tailwind and optional lanes remain explicit non-blocking skips in installer output | unit/source | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/scoria/adoption_surface_test.exs --trace` | ✅ | ⬜ pending |
| 48-02-01 | 02 | 2 | PROOF-01 | T-48-02-01 | Generated host proves deps, install, migrate, and `/scoria` route visibility in a temp app without leaking repo state | integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/scoria/host_app_consumer_proof_test.exs --trace` | ✅ after Task 48-02-01 creates the file | ⬜ pending |
| 48-03-01 | 03 | 3 | PROOF-02 | T-48-03-01 | Generated host starts one durable run, reads it back, and renders operator evidence without optional lanes | integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/scoria/host_app_consumer_proof_test.exs test/scoria/runtime_integration_test.exs --trace` | ✅ after Task 48-03-01 extends the host proof | ⬜ pending |
| 48-04-01 | 04 | 4 | INST-02 / PROOF-01 / PROOF-02 | T-48-04-02 | Canonical adoption lane stays green while Tailwind, knowledge, and semantic surfaces remain explicit optional lanes | integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test.adoption` | ✅ after earlier plans land | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Harness Producer Requirements

- [x] `test/scoria/host_app_consumer_proof_test.exs` is produced directly by Task 48-02-01 and extended by Task 48-03-01; downstream verifies run the file after each task creates or extends it.
- [x] `test/support/scoria/host_app_proof/generator.ex` is produced directly by Task 48-02-01, so no separate Wave 0 producer plan is required.
- [x] Installer output assertions covering installed, skipped intentionally, and optional later lanes are owned by Plan 48-01.
- [x] DB-port handling is normalized in every automated verify command so compile-time/runtime mismatch does not masquerade as a Phase 48 failure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh-host dependency source choice stays support-truthful | PROOF-01 | The harness deliberately uses a local `path:` dependency in this phase while public package transport proof remains owned by Phase 47 | Confirm generated-host docs and plan text describe the local-path harness as a deterministic internal proof and do not mislabel it as Hex-publish proof |

---

## Validation Sign-Off

- [x] All tasks have directly runnable `<automated>` verify commands
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No `MISSING` verify placeholders remain
- [ ] No watch-mode flags
- [x] Feedback latency <= 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

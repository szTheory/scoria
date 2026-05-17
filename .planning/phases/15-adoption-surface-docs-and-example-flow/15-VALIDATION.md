---
phase: 15
slug: adoption-surface-docs-and-example-flow
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-15
completed: 2026-05-15
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` |
| **Config file** | `config/test.exs` |
| **Wave 1 quick run** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` |
| **Wave 2 quick run** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` |
| **Wave 3 / phase-final quick run** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local command from the owning plan.
- **After Wave 1:** Run the Wave 1 quick run.
- **After Wave 2:** Run the Wave 2 quick run.
- **After Wave 3 / phase closeout:** Run the Wave 3 / phase-final quick run.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | `ADOP-01` | `T-15-01-*` | README teaches the real runtime-first lane, exact `run_id` resume, and optional knowledge positioning | integration + content | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` | ✅ | ✅ green |
| 15-01-02 | 01 | 1 | `ADOP-04` | `T-15-01-*` | Public module docs establish `Scoria` as the happy path and document advanced modules deliberately | unit + content | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` | ✅ | ✅ green |
| 15-02-01 | 02 | 2 | `ADOP-02` | `T-15-02-*` | Canonical Phoenix example uses normalized identity, stored `run_id`, same-session continuity, and operator evidence | integration + content | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs` | ✅ | ✅ green |
| 15-03-01 | 03 | 3 | `ADOP-03` | `T-15-03-*` | Default verification story proves core success without requiring the knowledge lane | integration + content | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs` | ✅ | ✅ green |
| 15-03-02 | 03 | 3 | `ADOP-03` | `T-15-03-*` | Installer next-step output reinforces the same default-lane versus optional-knowledge split | unit + content | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs && rg -n "default Phoenix lane|mix ecto.migrate|mix test|/scoria|Optional knowledge lane|mix scoria.pgvector.bootstrap|mix scoria.test.knowledge" lib/mix/tasks/scoria.install.ex` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No dedicated Wave 0 scaffolding is required.
- Existing runtime and installer tests already cover the shipped behavior this phase is documenting.
- `test/scoria/adoption_surface_test.exs` provides repo-native docs and moduledoc assertions, including current Elixir 1.19 `Code.fetch_docs/1` compatibility.
- Later waves reuse that same test file instead of shell-only grep checks.

---

## Automated Operator Closure

The docs-described runtime lane is now closed by executable proof:

1. `test/scoria/runtime_integration_test.exs`
   Proves `Scoria.start_run/2`, `Scoria.get_run/1`, `Scoria.list_runs_for_session/1`, exact `run_id` resume, and `/scoria/workflows/:run_id` stay aligned on the same durable run.
2. `test/scoria/adoption_surface_test.exs`
   Proves `README.md`, `docs/phoenix_runtime_example.md`, and `docs/operator_verification.md` all still teach that shipped lane and optional-knowledge boundary.
3. `test/mix/tasks/scoria.install_test.exs` and `test/mix/tasks/scoria.install_route_smoke_test.exs`
   Prove the installer still wires the runtime/docs lane into a normal Phoenix app.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 requirements are explicit
- [x] No watch-mode flags
- [x] Feedback latency target is under 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** As of 2026-05-16, runtime/install test reruns are the primary behavioral proof for Phase 15, `test/scoria/adoption_surface_test.exs` is the semantic and moduledoc alignment proof, and the former operator walkthrough is now closed by automated verification.

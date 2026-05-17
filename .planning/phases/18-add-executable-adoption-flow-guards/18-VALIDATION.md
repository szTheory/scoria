---
phase: 18
slug: add-executable-adoption-flow-guards
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-16
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for executable adoption-flow guardrails.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` + `Phoenix.LiveViewTest` + semantic docs/source assertions + focused Mix task lane |
| **Config file** | `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~25 seconds for task-local smoke lanes; ~90 seconds for the focused/full phase lanes |

---

## Sampling Rate

- **After every task commit:** Run the task-local smoke lane below.
  - `18-01` smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/identity_doctest_test.exs test/scoria/adoption_surface_test.exs`
  - `18-02` smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/phoenix_example_source_test.exs && rg -n "Scoria.identity|Scoria.start_run|Scoria.get_run|Scoria.resume_run|list_runs_for_session|session_id|run_id|/scoria/workflows/:run_id" docs/phoenix_runtime_example.md`
  - `18-03` Task 1 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs && SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption && rg -n "mix test\\.adoption" .github/workflows/ci.yml`
  - `18-03` Task 2 smoke: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption && rg -n "mix scoria.install|mix ecto.migrate|mix test|mix test.adoption|Scoria.start_run|Scoria.get_run|/scoria/workflows/:run_id|Optional knowledge lane|mix scoria.test.knowledge" docs/operator_verification.md lib/mix/tasks/scoria.install.ex`
- **After Wave 1:** Run the combined docs/runtime guard proof from `18-01` and `18-02`.
- **After Wave 2:** Run the Phase 18 quick run command plus the operator/install/CI command grep checks.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 30 seconds for task-local smoke lanes; heavier plan-level and full-suite checks may take ~90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | `ADOP-01` | `T-18-01-01`, `T-18-01-03`, `T-18-01-06` | Pure `Scoria` and `Scoria.Identity` examples are executable without pretending to prove the full Phoenix flow | doctest | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/identity_doctest_test.exs` | planned | ✅ green |
| 18-01-02 | 01 | 1 | `ADOP-01` | `T-18-01-02`, `T-18-01-05` | README/public-surface guards assert semantic contract anchors and optional-knowledge separation without snapshotting prose | docs + doctest | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria_test.exs test/scoria/identity_doctest_test.exs && rg -n "Scoria.start_run|Scoria.resume_run|session_id|run_id|/scoria/workflows/:run_id|Optional knowledge lane" README.md` | planned | ✅ green |
| 18-02-01 | 02 | 1 | `ADOP-02` | `T-18-02-02`, `T-18-02-03` | The checked Phoenix example source and runtime integration seam encode the same controller-triggered public-runtime contract | integration | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs` | planned | ✅ green |
| 18-02-02 | 02 | 1 | `ADOP-02` | `T-18-02-01`, `T-18-02-04`, `T-18-02-05` | The guide stays docs-first but is traceable to checked helper truth and refuses fixture-app or whole-guide execution drift | integration + docs-source | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/phoenix_example_source_test.exs && rg -n "Scoria.identity|Scoria.start_run|Scoria.get_run|Scoria.resume_run|list_runs_for_session|session_id|run_id|/scoria/workflows/:run_id" docs/phoenix_runtime_example.md` | planned | ✅ green |
| 18-03-01 | 03 | 2 | `ADOP-03` | `T-18-03-02`, `T-18-03-03`, `T-18-03-05` | `mix test.adoption` runs the bounded adoption subset for fast feedback while all included files still run under default `mix test` | task + suite | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs && SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption && rg -n "mix test\\.adoption" .github/workflows/ci.yml` | planned | ✅ green |
| 18-03-02 | 03 | 2 | `ADOP-03` | `T-18-03-01`, `T-18-03-04`, `T-18-03-06` | Installer and operator docs teach the same layered proof using durable run state and Phoenix-native operator verification, not browser E2E | suite + docs | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption && rg -n "mix scoria.install|mix ecto.migrate|mix test|mix test.adoption|Scoria.start_run|Scoria.get_run|/scoria/workflows/:run_id|Optional knowledge lane|mix scoria.test.knowledge" docs/operator_verification.md lib/mix/tasks/scoria.install.ex && rg -n "mix test.adoption" .github/workflows/ci.yml` | planned | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave Coverage

| Wave | Plans | Coverage Goal | Automated Proof |
|------|-------|---------------|-----------------|
| 1 | `18-01`, `18-02` | Lock pure public-surface snippets plus checked Phoenix example sourcing before adding lane packaging | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/identity_doctest_test.exs test/scoria/adoption_surface_test.exs test/scoria/runtime_integration_test.exs test/scoria/phoenix_example_source_test.exs` |
| 2 | `18-03` | Package the existing installer/runtime/operator seams into the focused lane and align docs/CI to that command | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption && SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |

---

## Wave 0 Requirements

- [x] Existing ExUnit, Phoenix router, and LiveView test seams already cover installer mutation, route viability, runtime truth, and operator-page verification.
- [x] No fixture Phoenix app, browser E2E rig, README snapshots, or whole-guide execution harness is required.
- [x] The repo already provides the heavier-lane precedent via `mix test.knowledge`; Phase 18 only needs a lighter adoption subset runner.

---

## Automated Closure Notes

- `mix test` remains the authoritative default suite; `mix test.adoption` is a fast subset only.
- DB-backed verification commands should use `SCORIA_DB_PORT=55432 MIX_ENV=test` for local and CI consistency.
- `mix test.knowledge` remains the distinct optional heavier lane and must not become a prerequisite for adoption closure.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all existing infrastructure dependencies
- [x] No watch-mode flags
- [x] Feedback latency target is under 90 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated on 2026-05-17. Phase 18 closes adoption drift risk by keeping pure public snippets executable, deriving the Phoenix guide from checked runtime truth, and packaging the existing install/runtime/operator proof behind one named `mix test.adoption` lane while preserving default `mix test` coverage.
*** Add File: /Users/jon/projects/scoria/.planning/phases/18-add-executable-adoption-flow-guards/18-VERIFICATION.md
---
phase: 18
status: passed
verified_on: 2026-05-17
---

# Phase 18 Verification Report

## Goal Achievement
Phase 18 successfully converted the highest-risk Keystone adoption docs seams into executable guardrails. Public-surface snippets compile, the Phoenix example stays derived from checked source truth, and the named `mix test.adoption` lane keeps maintainer and operator proof aligned without replacing the default full-suite contract.

## Verification Evidence
- `test/scoria_test.exs`, `test/scoria/identity_doctest_test.exs`, and `test/scoria/adoption_surface_test.exs` prove the pure `Scoria` and `Scoria.Identity` public surface stays executable and semantically anchored.
- `test/support/scoria/adoption_example.ex`, `test/scoria/runtime_integration_test.exs`, and `test/scoria/phoenix_example_source_test.exs` keep the Phoenix guide tied to checked runtime truth.
- `lib/mix/tasks/test.adoption.ex`, `test/mix/tasks/test.adoption_test.exs`, `.github/workflows/ci.yml`, `docs/operator_verification.md`, and `lib/mix/tasks/scoria.install.ex` prove the bounded adoption lane and the maintainer/operator docs remain aligned.
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` passed on 2026-05-17 with `2 doctests, 12 tests, 0 failures` in the current closeout rerun.

## UAT Summary
- Pure public adoption surface executable and anchored: passed
- Phoenix runtime guide derived from checked example truth: passed
- Named adoption lane and docs alignment: passed

## Residual Risks
- None beyond ordinary rerun requirements for the local Postgres-backed verification environment.

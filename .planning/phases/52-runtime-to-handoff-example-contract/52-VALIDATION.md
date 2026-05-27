---
phase: 52
slug: runtime-to-handoff-example-contract
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.19.5 with Ecto SQL sandbox |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs` |
| **Estimated runtime** | ~20-60 seconds when the PostgreSQL test database is reachable |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green, or the summary must truthfully record an unavailable PostgreSQL test DB blocker.
- **Max feedback latency:** 60 seconds when dependencies and the local test DB are available.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | EXMP-01, EXMP-02 | T-52-01 / T-52-02 | Confirm existing public APIs and projected-context validator are sufficient before adding any new runtime API. | source inspection + docs tests | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` | Yes | pending |
| 52-02-01 | 02 | 2 | EXMP-01 | T-52-02 / T-52-03 | Example starts with `Scoria.start_run/2`, escalates through `Scoria.start_handoff_run/3`, and keeps host policy ownership explicit. | docs/source alignment | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` | Yes | pending |
| 52-02-02 | 02 | 2 | EXMP-02 | T-52-01 / T-52-04 | Example demonstrates bounded projected context and unsafe context rejection without hiding rejected inputs. | unit/integration | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/handoff_example_source_test.exs` | Yes | pending |
| 52-03-01 | 03 | 3 | EXMP-01, EXMP-02 | T-52-01 / T-52-03 | Documentation states host-app ownership, Scoria ownership, rejected context behavior, and operator readback boundary. | docs/source alignment | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` | Yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] Confirm whether the existing source-alignment tests already cover the final example artifact.
- [ ] Add or update an example-specific test if the final artifact is not covered by `test/scoria/handoff_example_source_test.exs` and `test/scoria/phoenix_example_source_test.exs`.
- [ ] Confirm PostgreSQL test DB reachability before claiming DB-backed runtime rejection tests as green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PostgreSQL test database availability | EXMP-02 | The runtime rejection tests depend on local DB service state outside the codebase. | Run the full suite command; if connection is refused, record the exact DB blocker and run the quick docs/source command. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s when dependencies and DB are available
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

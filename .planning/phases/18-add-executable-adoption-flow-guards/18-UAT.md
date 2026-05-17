---
status: complete
mode: shift-left
phase: 18-add-executable-adoption-flow-guards
source:
  - 18-01-SUMMARY.md
  - 18-02-SUMMARY.md
  - 18-03-SUMMARY.md
started: 2026-05-16T22:47:31Z
updated: 2026-05-16T22:53:06Z
human_steps_required: 0
automation_deferred: []
---

## Current Test

[testing complete]

## Automation Map

- Test 1 uses the public-surface doctests plus README anchor assertions to prove the pure `Scoria` and `Scoria.Identity` adoption snippets compile and keep the session-versus-run contract explicit.
- Test 2 uses the shared checked Phoenix example source, runtime integration suite, and Phoenix guide anchor assertions to keep the docs-first controller flow tied to executable truth.
- Test 3 uses the named `mix test.adoption` lane, CI wiring, installer guidance, and operator verification guide to prove the bounded adoption harness stays first-class without replacing the default full suite.

## Verification Run

- 2026-05-16T22:53:06Z: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` -> pass (`3 doctests, 15 tests, 0 failures`)
- 2026-05-16T22:53:06Z: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` -> pass (`3 doctests, 173 tests, 0 failures, 13 excluded`)

## Tests

### 1. Pure public adoption surface remains executable and semantically anchored
expected: Canonical `Scoria` and `Scoria.Identity` examples compile under doctest, and the README keeps the durable `session_id` versus exact `run_id` adoption guidance plus operator evidence path anchored in checked text.
result: pass
evidence:
  - "test/scoria_test.exs"
  - "test/scoria/identity_doctest_test.exs"
  - "test/scoria/adoption_surface_test.exs"
  - "README.md"

### 2. Phoenix runtime guide stays derived from checked example truth
expected: The controller-triggered Phoenix adoption example remains aligned with the shared checked helper source and runtime integration seam, including identity normalization, exact run persistence, same-session readback, and `/scoria/workflows/:run_id` operator evidence.
result: pass
evidence:
  - "test/support/scoria/adoption_example.ex"
  - "test/scoria/runtime_integration_test.exs"
  - "test/scoria/phoenix_example_source_test.exs"
  - "docs/phoenix_runtime_example.md"

### 3. Named adoption acceptance lane and maintainer/operator docs stay aligned
expected: `mix test.adoption` runs as the bounded adoption proof lane, remains wired in CI, and the installer plus operator docs teach the same maintainer/operator closeout flow while keeping the heavier knowledge lane optional.
result: pass
evidence:
  - "lib/mix/tasks/test.adoption.ex"
  - "test/mix/tasks/test.adoption_test.exs"
  - ".github/workflows/ci.yml"
  - "docs/operator_verification.md"
  - "lib/mix/tasks/scoria.install.ex"

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
none

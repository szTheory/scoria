---
phase: 48-host-app-install-contract-and-consumer-proof
verified: 2026-05-26T04:40:00Z
status: passed
score: 4/4 requirements verified
overrides_applied: 0
gaps: []
human_verification: []
---

# Phase 48: Host-app install contract and consumer proof Verification Report

**Phase Goal**: Prove that a fresh Phoenix app can adopt the default lane through the public install and runtime path.  
**Verified**: 2026-05-26T04:40:00Z  
**Status**: passed  
**Re-verification**: Yes

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `mix scoria.install` mounts the dashboard, injects baseline defaults, and keeps default-lane migration copy truthful without leaking optional semantic setup into the host proof. | ✓ VERIFIED | `test/mix/tasks/scoria.install_test.exs` proves installed/skipped/optional messaging and the filtered default-lane migration copy boundary. |
| 2 | The default lane remains installable when Tailwind is absent and optional semantic/knowledge surfaces stay named as later lanes rather than hidden prerequisites. | ✓ VERIFIED | `test/mix/tasks/scoria.install_test.exs`, `test/scoria/adoption_surface_test.exs`, and `docs/operator_verification.md` lock Tailwind optionality and lane separation. |
| 3 | A fresh generated Phoenix host can fetch deps, run `mix scoria.install`, create and migrate its database, and prove `/scoria` route visibility. | ✓ VERIFIED | `test/scoria/host_app_consumer_proof_test.exs` exercises the full generated-host install, migrate, and route smoke path. |
| 4 | That same generated host can start one durable run, read it back, and render operator evidence for the same `run_id` without enabling optional lanes. | ✓ VERIFIED | `test/scoria/host_app_consumer_proof_test.exs` and `test/scoria/runtime_integration_test.exs` prove the bounded host runtime smoke and the deeper repo-local runtime contract together. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Installer, docs, and adoption task guards | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/mix/tasks/test.adoption_test.exs test/scoria/adoption_surface_test.exs --trace` | 15 tests, 0 failures | ✓ PASS |
| Generated-host proof with repo-local runtime pairing | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/scoria/host_app_consumer_proof_test.exs test/scoria/runtime_integration_test.exs --trace` | 4 tests, 0 failures | ✓ PASS |
| Canonical default-lane verifier | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test.adoption` | 3 doctests, 42 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| INST-01 | 48-01, 48-02 | `mix scoria.install` mounts the dashboard, copies the default-lane migration set, and injects defaults without duplicate or misleading mutations. | ✓ SATISFIED | Installer contract tests cover first-run output, rerun idempotency, unsupported-router failure, and the bounded migration copy set. |
| INST-02 | 48-01, 48-04 | The default lane stays installable when Tailwind or optional surfaces are absent, and skipped or later lanes remain explicit. | ✓ SATISFIED | Installer tests and adoption-surface assertions prove Tailwind optionality and canonical lane naming. |
| PROOF-01 | 48-02, 48-04 | A fresh Phoenix host proves dependency fetch, install, migration, and route visibility through the public adoption path. | ✓ SATISFIED | Generated-host proof test runs the temp Phoenix harness end to end and `mix test.adoption` now includes it. |
| PROOF-02 | 48-03, 48-04 | The same host path proves one durable run, readback, and operator evidence without enabling optional lanes. | ✓ SATISFIED | Host runtime smoke and repo-local runtime integration verification both pass, and the canonical adoption lane now includes the generated-host proof. |

### Anti-Patterns Found

None remaining after execution. The two blocking regressions surfaced during the generated-host proof were fixed inside the phase:

1. Optional semantic-cache migrations leaked into the fresh-host install lane.
2. The generated host lacked minimal `:scoria` dependency config for runtime startup.

### Human Verification Required

None. The phase closes on deterministic local automation.

### Gaps Summary

*No blocking gaps found. Phase 48's generated-host proof, runtime proof, installer contract, and canonical adoption lane are all green.*

---
_Verified: 2026-05-26T04:40:00Z_  
_Verifier: Codex_

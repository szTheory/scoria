---
status: issues
phase: 68-full-suite-warning-closure
reviewed: 2026-05-27
depth: standard
files_reviewed: 16
critical: 0
warning: 2
info: 3
total: 5
---

# Phase 68 Code Review

## Scope

Reviewed source files from phase 68 SUMMARY artifacts (plans 68-00 through 68-03). Planning artifacts (`.planning/WARNING-*.md`, baseline JSON, `68-VERIFICATION.md`) excluded per workflow D-03.

**Focus areas:** tmp preflight/cleanup hygiene, JSON inventory encoding, high-signal path memoization, CI full-suite WAE flip, installer subprocess build isolation, LiveView async teardown, knowledge migration cache invalidation.

**Files reviewed (16):**

| Area | Files |
|------|-------|
| Warning inventory | `lib/scoria/warning_inventory.ex`, `lib/mix/tasks/scoria.warning_inventory.ex` |
| Ratchet tasks | `lib/mix/tasks/scoria.warning_ratchet.{check,test}.ex`, `lib/scoria/warning_ratchet.ex` |
| Test support | `lib/scoria/test_support/migrations.ex`, `test/support/scoria/host_install_fixtures.ex` |
| CI / docs | `.github/workflows/ci.yml`, `test/scoria/ci_policy_contract_test.exs`, `docs/operator_verification.md` |
| Contract tests | `test/scoria/warning_inventory/{tmp_preflight,json_encode}_test.exs`, `test/scoria/warning_ratchet_test.exs` |
| LiveView WAE | `test/scoria_web/live/{workflow_live,review_queue_live,prompt_live/release_workbench_live}_test.exs` |

**Verification run:** `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/warning_inventory/ test/scoria/warning_ratchet_test.exs` — 25 tests, 0 failures.

## Findings

### WR-01 [WARNING] `warning_ratchet.test` can leave `test/tmp/` pollution after run

**Files:** `lib/mix/tasks/scoria.warning_ratchet.test.ex`, `lib/scoria/warning_inventory.ex`

**Issue:** Phase 68-00 added shared tmp hygiene to `warning_ratchet.check` (preflight + `try/after` cleanup), but `Mix.Tasks.Scoria.WarningRatchet.Test` only calls `cleanup_transient_tmp!/0` **before** the run. High-signal paths include install-check tests that create entries under `test/tmp/install_check` (via `HostInstallFixtures.build!/2`).

**Why it matters:** A maintainer running the documented `mix scoria.warning_ratchet.test --warnings-as-errors` followed by `mix scoria.warning_inventory` can hit `ensure_clean_tmp!/0` failure unrelated to warning classification — the same class of workflow bug fixed for `warning_ratchet.check` in 68-00.

**Remediation:**

- Mirror `warning_ratchet.check` with `ensure_clean_tmp!/0` before capture and `cleanup_transient_tmp!/0` in an `after` block, **or**
- Document that inventory requires manual tmp cleanup after `warning_ratchet.test`, **or**
- Route install fixtures to a transient parent outside `test/tmp/` when invoked from ratchet scope.

---

### WR-02 [WARNING] Ratchet→inventory integration test is a no-op under ExUnit

**Files:** `test/scoria/warning_inventory/tmp_preflight_test.exs`, `lib/scoria/warning_inventory.ex`

**Issue:** The test `"ratchet check cleans test/tmp so inventory preflight passes afterward"` invokes `Mix.Tasks.Scoria.WarningRatchet.Check.run/1` from within the ExUnit suite. Phase 68-03 added `nested_ex_unit?/0` to skip nested `mix do compile + test` capture when `ExUnit.Server` is registered. The ratchet check therefore passes immediately with empty capture (~0.05s) and never exercises tmp pollution or cleanup.

**Why it matters:** The contract test intended to lock WR-01 remediation does not fail if nested capture is broken or if check stops cleaning tmp. False confidence in the maintainer chain.

**Remediation:**

- Run ratchet check in a subprocess (`System.cmd("mix", ...)`) so capture is not nested, **or**
- Add a dedicated unit test for `cleanup_transient_tmp!/0` after simulated fixture dirs without relying on full capture, **or**
- Temporarily unregister/stub `ExUnit.Server` in the integration test (heavier).

---

### IN-01 [INFO] `pgvector_available?/0` stub still always returns false

**File:** `lib/mix/tasks/scoria.warning_inventory.ex`

**Issue:** Preflight always emits "pgvector may be unavailable locally" regardless of environment. Unchanged since phase 67; still present in a file modified this phase.

**Why it matters:** Maintainers may ignore the note or misdiagnose incomplete knowledge cluster counts on machines where pgvector is running.

**Remediation:** Query `Repo` or `pg_available_extensions` (as in `migration_lane_compatibility_test.exs`) or remove the note until implemented.

---

### IN-02 [INFO] High-signal path `persistent_term` cache does not invalidate on glob changes

**File:** `lib/scoria/warning_ratchet.ex`

**Issue:** `path_set/1` caches expanded paths keyed by `File.cwd!()`. Adding or removing high-signal test files in a long-lived `iex -S mix` session without cwd change leaves a stale `MapSet` until VM restart.

**Why it matters:** Low impact for CI (fresh VM per job) and typical maintainer flows (restart between changes). Relevant for interactive debugging after adding ratchet paths.

**Remediation:** Optional cache bust on `Path.wildcard` mtime fingerprint, or document that path SSOT changes require VM restart.

---

### IN-03 [INFO] Duplicate JSON encode helpers in contract test

**File:** `test/scoria/warning_inventory/json_encode_test.exs`

**Issue:** Test defines private `encode_rows/1` and `encode_value/1` mirroring `Mix.Tasks.Scoria.WarningInventory` private helpers instead of asserting through the task's `--format json` path (as `tmp_preflight_test.exs` already does for stdout encode).

**Why it matters:** Encode logic can drift between task and test without failing until a maintainer runs JSON output manually.

**Remediation:** Consolidate on task-level JSON contract test or expose/test `json_encode_rows/1` through a shared module.

## Positive observations

- **WR-01/WR-02 from 67-REVIEW remediated** for `warning_ratchet.check` and `--format json` stdout encoding.
- **Installer subprocess isolation** (`MIX_BUILD_PATH=_build/install_subprocess`) prevents host-proof compile from clobbering `test/support` beams mid-suite — correct root-cause fix for 68-03 full WAE.
- **Nested capture guard** prevents recursive full-suite subprocess when ExUnit is already the WAE gate.
- **`ensure_knowledge_migrated!/0`** now re-migrates when compatibility tests drop knowledge tables — fixes intermittent ratchet failures.
- **CI policy contract** scopes full WAE assertions to the test job section, avoiding false matches against policy job lane WAE.
- **LiveView `render_async/1` sweep** follows established orchestrator pattern for async teardown warnings.

## Verdict

**status: issues** — no critical or security blockers; two maintainer-workflow warnings (ratchet.test tmp asymmetry, neutered integration test) should be addressed to preserve the hygiene guarantees established in 68-00.

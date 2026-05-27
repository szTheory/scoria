---
status: issues
phase: 67-high-signal-warning-ratchet
reviewed: 2026-05-27
depth: standard
files_reviewed: 22
critical: 0
warning: 2
info: 3
total: 5
---

# Phase 67 Code Review

## Scope

Reviewed source files from phase 67 SUMMARY artifacts and commits matching `67-` (plans 67-00 through 67-04).

**Focus areas:** `Scoria.WarningRatchet`, warning ratchet Mix tasks, `Scoria.TestSupport.Migrations` migrate-once gate, host-proof overlay architecture.

**Files reviewed (22):**

| Area | Files |
|------|-------|
| Warning ratchet SSOT | `lib/scoria/warning_ratchet.ex`, `test/scoria/warning_ratchet_test.exs` |
| Mix tasks | `lib/mix/tasks/scoria.warning_ratchet.{test,check}.ex`, `lib/mix/tasks/scoria.warning_inventory.ex` |
| Inventory | `lib/scoria/warning_inventory.ex`, `lib/scoria/warning_inventory/cluster.ex` |
| Migrations | `lib/scoria/test_support/migrations.ex`, `test/scoria/bootstrap/migration_lane_compatibility_test.exs` |
| Host proof | `test/scoria/host_app_proof_architecture_test.exs`, `test/support/scoria/host_app_proof/generator.ex`, `priv/host_app_proof/overlay/test/*.exs`, `test/mix/tasks/scoria.install_route_smoke_test.exs` |
| CI / lanes | `test/scoria/ci_policy_contract_test.exs`, `lib/scoria/verification_lanes.ex`, `test/scoria/verification_lanes_test.exs` |
| Test hygiene | `test/scoria/eval/review_queue_test.exs`, `test/scoria_web/live/review_queue_live_test.exs`, `test/scoria_web/live/prompt_live/release_workbench_live_test.exs`, `test/scoria/package_surface_test.exs` |

**Verification run:** `MIX_ENV=test mix scoria.warning_ratchet.check` — passed (~49s capture).

## Findings

### WR-01 [WARNING] `warning_ratchet.check` leaves `test/tmp/` pollution and skips preflight

**Files:** `lib/mix/tasks/scoria.warning_ratchet.check.ex`, `lib/mix/tasks/scoria.warning_inventory.ex`

**Issue:** `Mix.Tasks.Scoria.WarningInventory` enforces an empty `test/tmp/` preflight (D-27), but `Mix.Tasks.Scoria.WarningRatchet.Check` has no equivalent guard. `WarningInventory.capture_output/0` runs the **full** test suite (`mix do compile --force + test`), which creates installer fixture dirs under `test/tmp/` (e.g. `test/tmp/installer`).

**Why it matters:** A green `mix scoria.warning_ratchet.check` can immediately break `mix scoria.warning_inventory` with `test/tmp contains N entries`. Maintainers running the documented WARN-06 chain out of order hit a false failure unrelated to warning classification.

**Evidence:** After `mix scoria.warning_ratchet.check` on a clean `test/tmp/`, `test/tmp/installer` exists; subsequent inventory preflight fails.

**Remediation:**

- Share `preflight!/0` (or a lighter tmp guard) in `warning_ratchet.check` before capture, **or**
- Document that inventory must run first / tmp must be cleaned between commands, **or**
- Have capture/cleanup remove transient installer dirs in an `after` block when invoked from ratchet tasks.

---

### WR-02 [WARNING] `--format json` still encodes raw rows with tuple `dedupe_key`

**File:** `lib/mix/tasks/scoria.warning_inventory.ex`

**Issue:** Plan 67-00 added `json_encode_rows/1` for `--write` artifacts, but `render/3` for `"json"` still calls `Jason.encode!(Map.put(metadata, "rows", rows))` on classified rows whose `:dedupe_key` is a `{atom, string, string}` tuple.

**Why it matters:** Any inventory run with warnings present and `--format json` (without `--quiet`) raises at encode time. Plan 67-03 noted this as pre-existing; the partial fix leaves two JSON code paths with different behavior.

**Remediation:** Route `--format json` through `json_encode_rows/1` (same as `--write` latest.json path), or add a contract test that asserts JSON encode succeeds on a classified fixture row.

---

### IN-01 [INFO] `high_signal_path?/1` rebuilds wildcard path set on every call

**File:** `lib/scoria/warning_ratchet.ex`

**Issue:** `path_set/1` calls `high_signal_wae_paths/0` (two `Path.wildcard/1` scans + sort/uniq) for each membership check. The ratchet check filters offenders with one call per row.

**Why it matters:** Low impact today (few unclassified rows expected), but the SSOT hot path scales poorly if inventory noise grows.

**Remediation:** Memoize expanded paths per `File.cwd!()` in module attribute, `:persistent_term`, or compute once in `warning_ratchet.check` and pass a `MapSet` to a batch filter.

---

### IN-02 [INFO] `ensure_knowledge_migrated!/0` has a benign TOCTOU race

**File:** `lib/scoria/test_support/migrations.ex`

**Issue:** Two concurrent first callers can both observe `persistent_term` false and invoke `migrate_knowledge!/0` before either sets the flag.

**Why it matters:** Knowledge migrations are idempotent (proven in `migration_lane_compatibility_test.exs`) and `ignore_module_conflict` is scoped in `try/after`, so practical risk is low. Worth noting if async knowledge tests expand.

**Remediation:** Optional `:global` lock or `:persistent_term.put(..., true)` only after successful migration with compare-and-set pattern if stricter serialization is needed.

---

### IN-03 [INFO] `pgvector_available?/0` stub always returns false

**File:** `lib/mix/tasks/scoria.warning_inventory.ex`

**Issue:** Preflight always emits "pgvector may be unavailable locally" regardless of environment.

**Why it matters:** Maintainers may ignore the note or misdiagnose incomplete knowledge cluster counts. Stub predates phase 67 but remains in a file modified this phase.

**Remediation:** Query `Repo` or `pg_available_extensions` (as in migration compatibility test) or remove the note until implemented.

## Positive observations

- **WarningRatchet SSOT** is code-composed (not JSON-derived), sorted/unique, with existence and membership contract tests — aligns with WARN-06 intent.
- **`migrate_knowledge!/0`** correctly scopes `ignore_module_conflict` in `try/after`; global `config/test.exs` remains clean (D-11).
- **Host-proof architecture** guard plus `priv/host_app_proof/overlay/test/` relocation prevents overlay drift back into `test/support` (D-15).
- **CI policy contract** encodes D-17: policy job documents ratchet commands but does not run them until Phase 68.
- **Cluster registry** additions (`:test_unused_import`, `:install_fixture_undefined_ref`, tightened `:knowledge_migration_redefine`) match observed adoption-lane warning shapes.

## Verdict

**status: issues** — no critical or security blockers; two maintainer-workflow warnings (tmp pollution + JSON encode split) should be addressed before Phase 68 CI wiring of `warning_ratchet.test`.

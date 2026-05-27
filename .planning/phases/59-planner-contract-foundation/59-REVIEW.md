---
phase: 59
status: issues
updated: 2026-05-27T12:44:18Z
---

## Code Review: phase 59 planner contract foundation

**Scope reviewed**
- Commits: `9d32a7e`, `eaa1174`, `756bcc6`, `b5d7c27`, `6f4d982`, `cdc23bb` (messages containing `(59-01)` / `(59-02)`)
- Files in scope changed by those commits: `lib/mix/tasks/scoria.install.ex`, `lib/scoria/install/planner.ex`, `lib/scoria/install/report.ex`, `lib/scoria/install/surface/migrations.ex`, `lib/scoria/install/surface/router.ex`, `lib/scoria/install/surface/runtime_config.ex`, `lib/scoria/install/surface/tailwind.ex`, `test/mix/tasks/scoria.install_test.exs`, `test/mix/tasks/scoria.install_check_test.exs`, `test/scoria/install/planner_test.exs`
- Related scope files checked for phase impact but not changed by tagged commits: `test/scoria/verification_lanes_test.exs`, `test/mix/tasks/test.adoption_test.exs`
- Diff stats for changed scoped files: 10 files, 1158 insertions, 33 deletions
- Verification run: `mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs test/scoria/install/planner_test.exs test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs` (20 tests, 0 failures)

### Findings

### [MEDIUM] Contract mismatch: router planner can report manual review when install can still auto-fix import
**File**: `lib/scoria/install/surface/router.ex`

**Issue**: `classify_router/2` only emits `:update` when a root browser scope is found. If `/scoria` is already present but `import ScoriaWeb.Router` is missing, planner can return `:manual_review` even though `mix scoria.install` can still auto-insert the import without needing browser-scope patching.

**Why it matters**: `--check` may return `manual_review` and fail CI for a state that is actually auto-repairable by the installer, creating false-negative drift signals against the planner/install contract.

**Actionable fix**:
- Add an explicit branch for `mount_present? and not import_present?` to classify as `:update` when module import insertion is possible.
- Add a targeted test fixture where mount exists, import is missing, and no patchable browser scope is present.

### [MEDIUM] Dry-run robustness gap: unhandled read errors can crash planner flow
**Files**: `lib/mix/tasks/scoria.install.ex`, `lib/scoria/install/surface/router.ex`, `lib/scoria/install/surface/runtime_config.ex`, `lib/scoria/install/surface/tailwind.ex`

**Issue**: `--dry-run` calls `Planner.build/4` without rescue. Surface analyzers use `File.read!/1` after `File.exists?/1`, which still raises on directories or unreadable paths. `--check` has rescue and degrades to status `error`, but `--dry-run` can terminate with an exception instead of returning a report.

**Why it matters**: The dry-run planner contract is intended to be safe/read-only and deterministic. Unhandled filesystem edge cases break that contract and reduce operability in real host repos.

**Actionable fix**:
- In surface analyzers, gate reads with `File.regular?/1` (or handle `{:error, reason}` via non-bang reads) and classify as `:manual_review` with evidence.
- In the dry-run branch, mirror check-mode error handling so planner failures still render a structured report.
- Add a dry-run fixture test for a non-regular tailwind/runtime/router path.

### [LOW] Missing tests for CLI argument/format contract
**Files**: `test/mix/tasks/scoria.install_test.exs`, `test/mix/tasks/scoria.install_check_test.exs`

**Issue**: New CLI pathways are partially covered, but there are no direct tests for:
- `--format json` payload shape stability
- invalid/unsupported args handling
- `--dry-run` and `--check` mutual-exclusion error

**Why it matters**: These are externally visible contract behaviors and likely to regress during future task refactors.

**Actionable fix**:
- Add subprocess tests that assert exit and message behavior for invalid flags and mutually exclusive modes.
- Add a JSON-format snapshot-style assertion over required keys (`schema_version`, `mode`, `entries`, `summary`).

## Residual risk
- Main functional paths pass in the focused suite, but planner/report contract edge cases remain under-tested.
- `test.adoption` currently does not include `scoria.install_check` coverage, so default-lane verification will not detect regressions in check-mode semantics.

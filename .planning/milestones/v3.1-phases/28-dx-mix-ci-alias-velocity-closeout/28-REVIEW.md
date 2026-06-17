---
phase: 28-dx-mix-ci-alias-velocity-closeout
reviewed: 2026-06-17T14:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/scoria/warning_inventory.ex
  - test/scoria/warning_inventory/capture_parity_test.exs
  - test/mix/tasks/scoria.install_check_test.exs
  - .github/workflows/ci-verify.yml
  - test/scoria/ci_policy_contract_test.exs
  - docs/MAINTAINERS.md
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 28 (plan 28-03): Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This review covers the six files changed by gap-closure plan 28-03 (VELO-01). The core change
optimises `capture_output_standalone!/0` from `mix do compile --force + test` (full suite, ~19 min)
to `mix do compile --force + test --only __ratchet_compile_only__` (compile-only, ~2-3 min) and
adds a parity guard to prove WARN-06 still catches high-signal unclassified compile warnings.

**Core logic and security:** The argv change in `warning_inventory.ex` is structurally correct.
The `--force` step is preserved. The tag `__ratchet_compile_only__` has zero usages in the suite
(confirmed by grep). The parity test correctly mirrors the subprocess argv, uses `async: false`,
and calls `on_exit` for cleanup. Cluster classification of the injected `@_parity_unused_attr`
warning flows correctly to `:unclassified_compile` (none of the prior cluster rules match
"module attribute ... was set but never used"). `Path.wildcard("test/scoria/**/*_test.exs")`
matches zero-depth files, so `__ratchet_parity_tmp_test.exs` under `test/scoria/` is correctly
included in `high_signal_wae_paths/0` when the file exists. No security issues found.

**Two warnings and two info items** were identified, all in `docs/MAINTAINERS.md` and
`ci-verify.yml`. The two warnings are documentation inconsistencies that could mislead a
maintainer diagnosing a local ratchet failure. No correctness bugs were found in the changed
Elixir source files.

## Warnings

### WR-01: MAINTAINERS.md section heading still describes ratchet as "no Postgres" after Postgres was added

**File:** `docs/MAINTAINERS.md:37`
**Issue:** The section heading reads `**\`ratchet\` job (no Postgres):**` but the ratchet CI job
now has a full `services: postgres` block (added in this same PR, visible at ci-verify.yml lines
187-250). The `ci_policy_contract_test.exs` was correctly updated to assert
`Map.fetch!(blocks, "ratchet") =~ "services:"`, so the contract test reflects reality — but
MAINTAINERS.md still tells a maintainer the ratchet job has no database. A maintainer following
the docs to diagnose a ratchet CI failure will be confused when the real job boots Postgres.

**Fix:** Change line 37 from:

```
**`ratchet` job (no Postgres):**
```

to:

```
**`ratchet` job (Postgres on 55432):**
```

(Matching the style used for test, knowledge, connector, and full-suite headings on lines 30, 43,
47, and 52.)

---

### WR-02: MAINTAINERS.md gate map table omits SCORIA_DB_PORT from the ratchet local command

**File:** `docs/MAINTAINERS.md:25`
**Issue:** The gate map table at lines 22-28 shows the local command for the ratchet lane as:

```
MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs
```

This command lacks `SCORIA_DB_PORT=55432`. Because `tmp_preflight_test.exs` shells out to
`mix scoria.warning_ratchet.check` (a separate BEAM process that boots `Scoria.Application` with
Oban, which requires a live Postgres connection), the local command will fail with a DB connection
error if run against the local dev Postgres on port 55432. Every other DB-using lane in the table
correctly includes `SCORIA_DB_PORT=55432`.

Furthermore, the new parity guard step (`mix test ... capture_parity_test.exs`) also boots the
app via the subprocess's `mix test` invocation, so it too needs the correct DB port. The ratchet
lane's local equivalent should include `SCORIA_DB_PORT=55432` to match the sibling lanes.

**Fix:** Update line 25 to:

```
| `ratchet` | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` |
```

A separate maintainer note for the parity guard step (if desired) would be:

```
SCORIA_DB_PORT=55432 MIX_ENV=test mix test --include ratchet_parity test/scoria/warning_inventory/capture_parity_test.exs
```

---

## Info

### IN-01: Parity guard CI step omits --warnings-as-errors (minor consistency gap with sibling step)

**File:** `.github/workflows/ci-verify.yml:249`
**Issue:** The WARN-06 parity guard step runs:

```yaml
run: MIX_ENV=test mix test --include ratchet_parity test/scoria/warning_inventory/capture_parity_test.exs
```

The sibling ratchet hygiene step (line 244) uses `--warnings-as-errors`. The parity step does
not. `capture_parity_test.exs` itself is warning-clean (the injected warning lives in the
subprocess output, not in the test module), so omitting `--warnings-as-errors` on the parent
runner is not a correctness defect. However, the inconsistency means a future compile warning
accidentally introduced into `capture_parity_test.exs` would not be caught by this step.

**Fix:** Add `--warnings-as-errors` for consistency with the sibling step:

```yaml
run: MIX_ENV=test mix test --warnings-as-errors --include ratchet_parity test/scoria/warning_inventory/capture_parity_test.exs
```

---

### IN-02: `_status` from the subprocess is silently discarded in both parity tests

**File:** `test/scoria/warning_inventory/capture_parity_test.exs:60,93`
**Issue:** Both tests bind the subprocess exit code to `_status`:

```elixir
{output, _status} =
  System.cmd("mix", ["do", "compile", "--force", "+", "test", "--only", "__ratchet_compile_only__"], ...)
```

If the subprocess exits non-zero for an unexpected reason (e.g., a compile error introduced into
a test file, or a missing dep), the test proceeds and the assertion may fail with a confusing
"no offenders found" message rather than a clear "subprocess failed" message. This is not a
correctness bug (compile warnings exit 0 by design), but a diagnostic gap.

**Fix:** Assert or log the exit code after the subprocess call to produce a clearer failure
message on unexpected subprocess failure:

```elixir
{output, status} =
  System.cmd("mix", [...], env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

assert status in [0, 1],
       "Subprocess exited #{status} — unexpected; raw output:\n#{String.slice(output, 0, 1000)}"
```

(Exit code 1 is acceptable since the compile step may emit warnings in some environments; the
gate test does not use `--warnings-as-errors`. Exit code 2+ would indicate a hard compiler
failure worth surfacing explicitly.)

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

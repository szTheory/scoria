---
phase: 28-dx-mix-ci-alias-velocity-closeout
reviewed: 2026-06-17T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/mix/tasks/scoria.ci.ex
  - mix.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 28: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** standard
**Files Reviewed:** 2 (plus `lib/scoria/verification_lanes.ex` as SSOT reference)
**Status:** issues_found

## Summary

The two changed files implement `Mix.Tasks.Scoria.Ci` (the merge-gate mirror task) and wire it into `mix.exs` via a single-entry `ci: ["scoria.ci"]` alias.

The primary correctness concerns from the brief were all checked:

- **False-green footgun (elixir-lang/elixir#4318):** Not present. The alias is a single-element delegate (`["scoria.ci"]`), not a chained list. The task itself runs all steps before calling `aggregate_and_halt`, never short-circuiting.
- **`--skip-optional` exits non-zero:** Correct. `System.halt(1)` is unconditional in `run_skip_optional/0`, regardless of whether the remaining lanes pass.
- **Preflight hard-fails non-zero:** Correct. `System.halt(1)` is called directly in the `{:error, :preflight_failed}` branch before any lane runs.
- **Exit code propagation:** `System.cmd/3` returns `{output, status}` and the integer status is collected into the results list. `aggregate_and_halt/1` checks `status != 0` across all results. Correct.
- **Shell injection via VerificationLanes.command/1:** Acceptable risk per the threat model (T-28-01). Command strings are compile-time literals from the SSOT module, not user-supplied input. No untrusted data reaches `sh -c`.
- **SSOT derivation:** `gating_lane_ids/0` calls `VerificationLanes.closeout_order/0`, `VerificationLanes.exclusions/1`, and `VerificationLanes.command/1`. No command strings are duplicated or hardcoded. `:support_copilot_gallery` is excluded by checking the `"merge-blocking closeout"` string in its exclusions list, not by hardcoding the atom.

Two warnings were found: one is a correctness gap (local check is weaker than CI for the connector lane), and one is a latent runtime failure for a specific invocation environment. Two info items cover documentation gaps.

## Warnings

### WR-01: Connector lane runs without `--warnings-as-errors` locally but CI uses it

**File:** `lib/mix/tasks/scoria.ci.ex:197`
**Issue:** `run_lanes/1` calls `VerificationLanes.command(id)`, which for the `:connector` lane returns `"mix test.connector"`. The CI command (`VerificationLanes.ci_command(:connector)`) is `"mix test.connector --warnings-as-errors"`. The local merge gate therefore runs the connector lane with a weaker check than CI runs it. A local green on connector does not guarantee a CI green, which undermines the stated goal of "a green that never lies."

The same divergence exists for `:release_preview`: `command/1` returns `"mix scoria.release_preview"` while `ci_command/1` is `"MIX_ENV=dev mix scoria.release_preview"`. However for `release_preview` the MIX_ENV difference is likely benign if `mix ci` is invoked in a dev shell (MIX_ENV defaults to dev), whereas the connector `--warnings-as-errors` gap is a categorical omission.

**Fix:** Either use `VerificationLanes.ci_command(id)` instead of `command(id)` in `run_lanes/1` (making local parity exact), or document the connector `--warnings-as-errors` gap in the `@moduledoc` Local-vs-CI asymmetry section the same way the preamble asymmetry is documented. The cleaner fix is:
```elixir
defp run_lanes(lane_ids) do
  Enum.map(lane_ids, fn id ->
    cmd = VerificationLanes.ci_command(id)   # use CI command for exact parity
    Mix.shell().info("==> [lane: #{id}] #{cmd}")
    {_io, status} = System.cmd("sh", ["-c", cmd], into: IO.stream(), stderr_to_stdout: true)
    {Atom.to_string(id), status}
  end)
end
```
If `command/1` is intentional for local-environment-specific env vars (e.g. `SCORIA_DB_PORT=55432` in semantic_fast_path), then a mixed approach (prefer `command/1` but overlay `ci_command/1` flags) should be documented explicitly.

---

### WR-02: Test lanes inherit ambient MIX_ENV from the parent process; `mix ci` has no `preferred_env`

**File:** `lib/mix/tasks/scoria.ci.ex:199` / `mix.exs:29-51`
**Issue:** `run_lanes/1` invokes test lanes (`:adoption`, `:runtime_to_handoff`) via `System.cmd("sh", ["-c", "mix test.adoption"])`. These subprocesses inherit `MIX_ENV` from the parent shell. Neither `"scoria.ci"` nor `"ci"` appears in `preferred_envs` in `cli/0`. The `:adoption` and `:runtime_to_handoff` lane `command/1` strings have no `MIX_ENV=test` prefix.

If a contributor runs `mix ci` from a fresh shell where `MIX_ENV` is not set (defaults to `dev`), every test-lane subprocess will attempt `mix test` in `:dev` environment, which mix refuses with an error. The `:semantic_fast_path` lane is safe because its `command/1` inlines `MIX_ENV=test`, but `:adoption` and `:runtime_to_handoff` are not.

**Fix:** Add `"scoria.ci"` to `preferred_envs` in `mix.exs` `cli/0` to pin the task to `:test`. This ensures the subprocesses inherit the correct `MIX_ENV`:
```elixir
def cli do
  [
    preferred_envs: [
      "scoria.ci": :test,
      # ... existing entries
    ]
  ]
end
```
Alternatively (and more robustly), prefix the test lane commands in `VerificationLanes` with `MIX_ENV=test` the same way `:semantic_fast_path` already does, so each lane is self-contained regardless of the caller's environment. Note that `"ci"` (the alias) also needs a preferred_env entry if the alias is used directly, since Mix resolves preferred_envs for alias keys too.

---

## Info

### IN-01: `Mix.Tasks.Scoria.Ci` ships in the Hex package

**File:** `mix.exs:147`
**Issue:** The `package/0` `files` list includes `"lib"`, which means `lib/mix/tasks/scoria.ci.ex` will be included in the published Hex package. This is a maintainer-only development tool with no value to adopters. Other maintainer tasks (`:install`, `:release_preview`) appear to ship in the same way, so this is consistent with existing practice — but it does expose the maintainer's local CI workflow to adopters and grows their compiled artifact surface.
**Fix:** No immediate action required (consistent with project precedent). If the project wants a clean separation of maintainer tooling, consider moving dev-only tasks to a `dev/mix/tasks/` directory that is excluded from the package (analogous to how `dev/` hosts the dev harness), or add explicit `"lib/scoria"` and `"lib/scoria_web"` globs to `files` instead of the bare `"lib"` glob.

---

### IN-02: Hardcoded PARTIAL message and dynamic `skipped` string are in sync today but can drift

**File:** `lib/mix/tasks/scoria.ci.ex:122-139`
**Issue:** The runtime-generated skip notice and the hardcoded `RESULT: PARTIAL` stamp are two separate strings that happen to agree:
- Line 122: `@optional_lane_ids |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")` — produces `"knowledge, semantic_fast_path, connector"` today.
- Line 139: hardcoded `"RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)"`.

If `@optional_lane_ids` is updated in the future (lanes added or reordered), the `RESULT: PARTIAL` string will silently lie about which lanes were skipped. There is no test asserting that the two strings are consistent.

**Fix:** Derive the PARTIAL message from `skipped` rather than duplicating the lane names:
```elixir
defp run_skip_optional do
  skipped = @optional_lane_ids |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")
  # ...
  Mix.shell().info(
    "RESULT: PARTIAL (#{skipped} skipped — NOT a merge-gate pass)"
  )
  System.halt(1)
end
```
This eliminates the possibility of the two strings drifting apart.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

# Phase 28: DX `mix ci` alias + velocity closeout - Pattern Map

**Mapped:** 2026-06-17
**Files analyzed:** 6 (1 new task, 1 modified alias, 3 modified docs, 2 new planning artifacts) + 2 contract-guard tests to keep green
**Analogs found:** 6 / 6 (all have strong in-repo analogs)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/scoria.ci.ex` (NEW, `Mix.Tasks.Scoria.Ci`) | mix-task (orchestrator) | batch / sub-process fan-out + aggregate | `lib/mix/tasks/scoria.install.ex` (OptionParser + `System.halt`) + `lib/mix/tasks/scoria.release_preview.ex` (`System.cmd` step-runner) | role-match, composite |
| `mix.exs` `aliases/0` (MODIFY, ~line 108-115) | config | n/a | existing `aliases/0` entries (`assets.build`, `dev.setup`) | exact |
| preflight probe inside `scoria.ci.ex` | mix-task (infra check) | request-response (DB probe) | `lib/mix/tasks/scoria.pgvector.bootstrap.ex` `--check` mode (lines 19-23, 62-79) | exact |
| `docs/MAINTAINERS.md` (MODIFY) | docs | n/a | existing "Local parity" / "CI gate map" sections (line ~77) | exact |
| `docs/operator_verification.md`, `README.md` (MODIFY) | docs | n/a | existing maintainer-command mentions | exact |
| `.planning/phases/28-.../28-VELOCITY-PROOF.md` (NEW) | planning artifact | n/a | (none — new doc; structure from CONTEXT D-D) | template-only |
| `.planning/MILESTONES.md` (MODIFY, prepend headline) | planning ledger | n/a | existing `## v3.0 Control Room (Shipped: …)` block (lines 3-7) | exact |

**Read-model the new task drives off (NOT a file to modify — a contract to consume):**
`lib/scoria/verification_lanes.ex` — `closeout_order/0` (line 101), `command/1` (line 91), `ci_command/1` (line 93), `exclusions/1` (line 99), `closeout_chain/0` (lines 103-107), `boundary_sentence/1` (line 109).

---

## Pattern Assignments

### `lib/mix/tasks/scoria.ci.ex` (NEW — `Mix.Tasks.Scoria.Ci`)

This is a composite: borrow **task skeleton + OptionParser + `System.halt`** from `scoria.install.ex`, **`System.cmd` step execution** from `scoria.release_preview.ex`, **`Next step:` microcopy + `--check` preflight** from `scoria.pgvector.bootstrap.ex`, and **drive the step list off** `Scoria.VerificationLanes` (never a hardcoded list — D-A2).

**`<read_first>` for the planner's plan:**
- `lib/mix/tasks/scoria.install.ex` lines 1-57, 116-158 (moduledoc + OptionParser + `System.halt` exit-code pattern)
- `lib/mix/tasks/scoria.release_preview.ex` lines 23-57 (`System.cmd` + status capture + step echo)
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` lines 19-23, 35-79 (`--check` mode, `check_vector_support/0`, `Next step:` raise)
- `lib/scoria/verification_lanes.ex` lines 85-117 (the functions to drive off of)

**Task header / shortdoc / OptionParser pattern** — from `scoria.install.ex:1-56`:
```elixir
defmodule Mix.Tasks.Scoria.Ci do
  @moduledoc """
  ...exit-code table + local-vs-CI asymmetry note...
  """
  use Mix.Task

  @shortdoc "Reproduces the merge gate locally; exits non-zero on any failure"
  @switches [skip_optional: :boolean]   # D-B3: ONE opt-out flag

  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    ensure_valid_args!(argv, invalid)   # mirror install.ex ensure_valid_args!
    ...
  end
```
Note: `scoria.install.ex` uses the exact `{opts, argv, invalid} = OptionParser.parse(args, strict: @switches)` + `ensure_valid_args!` shape; `scoria.test.ci_trust.ex:24-28` and `scoria.ui.e2e.ex:58-62` show the lighter `if invalid != [], do: Mix.raise(...)` variant. Use `strict:` (not `switches:`) like `ci_trust` / `ui.e2e` — `pgvector.bootstrap.ex:13` uses the looser `switches:` form; prefer `strict:`.

**Step execution via `System.cmd` capturing status** — from `scoria.release_preview.ex:34-43`:
```elixir
{output, status} =
  System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
    cd: File.cwd!(),
    stderr_to_stdout: true
  )

if status != 0 do
  Mix.raise("hex preview failed:\n#{output}")
end
```
**Adaptation for D-A3 (run-all-then-aggregate, NOT fail-fast):** do NOT `Mix.raise`/return on first non-zero. Each lane `command` string from `VerificationLanes.command/1` is a `KEY=val … mix sub.task` form (see `verification_lanes.ex:48` — `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path`), so run via a shell to honor the inline env, e.g. `System.cmd("sh", ["-c", command], into: IO.stream(), stderr_to_stdout: true)` (the `into: IO.stream()` live-streaming form is shown in `scoria.ui.e2e.ex:96-101` and `scoria.ui.shots.ex:156`). Collect `{lane_id, status}` for every step, then aggregate.

**Run-all-aggregate + `System.halt`** — exit-code discipline from `scoria.install.ex:132-134, 155-157`:
```elixir
exit_code = result.exit_code
Mix.shell().info(Report.trailer_line(result))
System.halt(exit_code)
```
**Apply to `scoria.ci.ex`:** after the loop, print a per-step PASS/FAIL summary, then:
```elixir
if Enum.any?(results, fn {_lane, status} -> status != 0 end), do: System.halt(1), else: ...
```
Use `System.halt(1)` (D-A3 — so aggregation completes first), NOT `Mix.raise` for the final verdict. `--skip-optional` path (D-B3) must still `System.halt(1)` after stamping `RESULT: PARTIAL (...)`. `scoria.install.ex` is the only in-repo `System.halt` precedent — copy its "compute exit_code, print trailer, then halt" sequence.

**Preflight probe + `Next step:` microcopy** — from `scoria.pgvector.bootstrap.ex:19-23, 62-79, 109-129, 184-199`:
```elixir
# bootstrap.ex:19-23 — --check dispatch
case opts[:check] do
  true -> check_current_database!()
  _ -> provision_or_fail!(compose_file)
end

# bootstrap.ex:109-129 — the reusable probe (TCP reach + vector extension)
defp check_vector_support do
  config = Repo.config()
  ...
  case Ecto.Adapters.SQL.query(Repo, "select extname from pg_extension where extname = 'vector'", []) do
    {:ok, %{rows: [["vector"]]}}    -> {:ok, metadata}
    {:ok, %{rows: []}}              -> {:missing_extension, metadata}
    {:error, error}                -> {:connection_error, Exception.message(error)}
  end
end
```
**Reuse path (D-B2):** call `mix scoria.pgvector.bootstrap --check` as the preflight (it already runs `app.start` + this probe). Either shell out to it (`System.cmd("mix", ["scoria.pgvector.bootstrap", "--check"])`) or `Mix.Task.run("scoria.pgvector.bootstrap", ["--check"])` after `Mix.Task.reenable`. Note `bootstrap.ex` runs `Mix.Task.run("app.start")` (line 15) — the knowledge lane (`scoria.test.knowledge.ex:16-20`) shows the `Mix.Task.reenable("scoria.pgvector.bootstrap")` + `reenable("app.start")` ceremony required to invoke it programmatically.

**`Next step:` block idiom** — copy structure verbatim from `bootstrap.ex:41-58` and `184-199`:
```elixir
raise """
pgvector prerequisite failed: ...is reachable but does not have the vector extension enabled

Next step:
  mix scoria.pgvector.bootstrap
  export SCORIA_DB_PORT=#{@default_port}
  ...
"""
```
The CONTEXT D-B2 microcopy block (lines 68-77 of `28-CONTEXT.md`) is the exact target text. `@default_port 55432` (bootstrap.ex:9) is the canonical port constant to reference.

**Driving the step list off the SSOT (D-A2)** — consume `verification_lanes.ex:85-117`:
```elixir
# closeout_order/0 (line 101) => [:release_preview, :adoption, :runtime_to_handoff]
# Build the gating lane set: closeout_order ++ the merge-gating parallel lanes
#   (semantic_fast_path, knowledge, connector) — EXCLUDE :support_copilot_gallery (D-B4).
# For each lane id: VerificationLanes.command(id) gives the LOCAL command string
#   (encodes local-vs-CI divergence, e.g. SCORIA_DB_PORT=… for semantic_fast_path).
```
Do NOT inline the command strings — `command/1` (line 91) is the contract. Excluding `:support_copilot_gallery` is asserted by its `exclusions` containing `"merge-blocking closeout"` (`verification_lanes.ex:79`); filter on that exclusion rather than hardcoding the id if you want it self-documenting.

---

### `mix.exs` `aliases/0` (MODIFY)

**Analog:** the existing `aliases/0` list itself (`mix.exs:108-116`).

**`<read_first>`:** `mix.exs` lines 108-116.

**Current shape:**
```elixir
defp aliases do
  [
    "assets.build": ["scoria.assets.build"],
    "assets.deploy": ["scoria.assets.build"],
    # Dev harness convenience: ...
    "dev.setup": ["scoria.dev.db", "run priv/repo/dev_seed.exs"]
  ]
end
```
**Action (D-A1):** add one entry `ci: ["scoria.ci"]`. `ci` is a bare atom key (no quotes needed, unlike `"assets.build"`). The value is a **single-element** delegating list — deliberately NOT a chained command list (D-A1: Mix only surfaces the last chained sub-command's exit code → false-green footgun; the new task aggregates instead).

---

### `docs/MAINTAINERS.md` / `docs/operator_verification.md` / `README.md` (MODIFY)

**Analog:** existing "Local parity" line in `docs/MAINTAINERS.md:77` and the "CI gate map" section.

**`<read_first>`:** `docs/MAINTAINERS.md` around line 77 and the `## CI gate map` section.

**Constraint (from contract guards — see below):** `ci_policy_contract_test.exs` asserts many literal strings in `MAINTAINERS.md` / `operator_verification.md` / `README.md` (e.g. `"Local parity"`, `"mix scoria.warning_ratchet.test"`, `"For maintainers"`, `"CI topology"`, `## CI gate map`). When adding the `mix ci` asymmetry note (D-C3), **add — never replace/reorder** existing asserted strings. The note documents: `mix ci` runs `mix format --check-formatted` + `mix deps.unlock --check-unused` + `mix deps.get --check-locked` locally that CI's `policy` job does NOT (D-C2 strict-superset, D-C3 intentional asymmetry).

---

### `.planning/MILESTONES.md` (MODIFY — prepend v3.1 headline)

**Analog:** the existing `## v3.0 Control Room (Shipped: 2026-06-14)` block (`MILESTONES.md:3-7`).

**`<read_first>`:** `.planning/MILESTONES.md` lines 1-10.

**Pattern:** top-of-file is `# Milestones` then reverse-chronological `## vX.Y <Name> (Shipped: <date>)` blocks with `**Phases completed:**`, `**Timeline:**`, `**Delivered:**` lines. D-D1 wants a one-line headline: `v3.1: PR CI critical-path 77m→~12m, before <id> / after <id>`. Insert a new `## v3.1 CI/CD Velocity (Shipped: …)` block above v3.0, keeping the established sub-bullet shape.

---

### `.planning/phases/28-.../28-VELOCITY-PROOF.md` (NEW)

No in-repo analog (new artifact type). Structure dictated entirely by CONTEXT D-D1/D-D2/D-D3/D-D4 (lines 109-138). Must contain: pinned before/after run IDs + raw `gh run view --json …` JSON inline; critical-path computation (sum of stage maxima along `policy → build → max(parallel lanes) → verify-summary`, using `startedAt → completedAt`, slowest shard for matrix); run-level wall-clock headline; honesty caveats (warm-cache, same-workload). Baseline anchor: SEED-003 run IDs `27508317719` / `27505520774` (`SEED-003-ci-efficiency-overhaul.md`).

---

## Shared Patterns

### Sub-task invocation: `Mix.Task.run` vs `System.cmd`
**Sources:** `scoria.test.knowledge.ex:13-27` (programmatic `Mix.Task.reenable` + `Mix.Task.run`) vs `scoria.release_preview.ex:34-43` / `scoria.ui.e2e.ex:96-101` (`System.cmd`).
**Apply to:** `scoria.ci.ex` step loop. **Use `System.cmd` (subprocess), not `Mix.Task.run`** — D-A3 needs an independent per-step exit status and the lane `command` strings carry inline `KEY=val` env prefixes (`verification_lanes.ex:48`) that only a fresh shell honors. `Mix.Task.run` in the same BEAM can't cleanly isolate exit codes or env. Run-all-aggregate also requires each lane in its own OS process so one crash doesn't abort the run.

### `System.halt` for honest non-zero exit
**Source:** `scoria.install.ex:132-134, 155-157` (the only `System.halt` precedent in `lib/mix/tasks/`).
**Apply to:** `scoria.ci.ex` final verdict and `--skip-optional` PARTIAL path. Compute `exit_code`, print the trailer/summary line, THEN `System.halt`. D-A3: use `halt`, not `Mix.raise`, so aggregation/printing completes first.

### `Next step:` actionable microcopy on missing infra
**Source:** `scoria.pgvector.bootstrap.ex:41-58, 184-199` (`raise """ … Next step: … """` and `with_next_steps/1`).
**Apply to:** `scoria.ci.ex` preflight-failure message (D-B2) — no styling, plain CLI text, concrete commands. Reuse the literal port `55432`.

### OptionParser strict-switch + invalid-arg guard
**Source:** `scoria.test.ci_trust.ex:24-28` and `scoria.ui.e2e.ex:58-62`:
```elixir
{opts, _, invalid} = OptionParser.parse(args, strict: @switches)
if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")
```
**Apply to:** `scoria.ci.ex` `--skip-optional` parsing. (`scoria.install.ex:53-56` has the heavier `ensure_valid_args!`/`ensure_valid_mode_flags!` version if positional-arg rejection is wanted.)

### Compatibility wrapper module (optional)
**Source:** `scoria.test.adoption.ex:31-38`, `scoria.test.connector.ex:27-34`, `scoria.test.ci_trust.ex:46-53` — each defines a second `Mix.Tasks.Test.X` module delegating to the `Mix.Tasks.Scoria.Test.X` one.
**Apply to:** N/A for `scoria.ci.ex` — the alias `ci: ["scoria.ci"]` is the public surface; no `Mix.Tasks.Ci` wrapper needed (CONTEXT specifies `mix ci` via alias, not a `mix ci` task).

---

## Contract Guards (must stay green — DO NOT regress)

These two tests pin byte-order / closeout invariants. The new task must read from `Scoria.VerificationLanes`, never duplicate command strings, or these break.

### `test/scoria/verification_lanes_test.exs`
- Lines 9-17: `VerificationLanes.ids()` must equal the exact 7-element list (release_preview, adoption, runtime_to_handoff, semantic_fast_path, knowledge, connector, support_copilot_gallery). **`scoria.ci.ex` must not require adding/removing a lane.**
- Lines 30-44: `closeout_order/0` and `closeout_chain/0` pinned to `[:release_preview, :adoption, :runtime_to_handoff]` / the 3-line string. The task drives off these — do not change them.
- Lines 61-65: `:support_copilot_gallery` stays advisory / outside closeout order — confirms D-B4 exclusion is contract-backed.

### `test/scoria/ci_policy_contract_test.exs`
- This test pins literal strings in `MAINTAINERS.md`, `operator_verification.md`, `README.md`, `ci-verify.yml`, `ci.yml`. Editing those docs (D-C3 asymmetry note) must **add** lines, never remove/reorder asserted substrings (e.g. line 77 `"Local parity"`, lines 442-451 Hex-release section, lines 558-573 CI gate map, lines 576-583 README maintainer links).
- Lines 162-178, 274-313, 350-416: `verify-summary` fan-in aggregates **every** lane and fails on any non-success (`if: always()`, `join(needs.*.result`, `!= "success"`, `exit 1`). This is the gate `mix ci` mirrors (D-A3 run-all-aggregate) — the local task's aggregation semantics must match this CI fan-in, not fail-fast.
- D-C3 constraint: **do NOT edit `ci-verify.yml`'s `policy` job** this phase (would risk the ordering invariants at lines 141-153). Format/deps-lock stay local-only.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/phases/28-.../28-VELOCITY-PROOF.md` | planning artifact | n/a | New doc type; structure is defined inline by CONTEXT D-D, not by an existing file. Baseline JSON capture via `gh run view --json` (D-D2 example commands). |

The `mix ci` run-all-aggregate **across multiple subprocesses** is also novel — no single existing task loops over a step list capturing each exit status (release_preview/ui.e2e fail-fast on first non-zero). Synthesize from the `System.cmd` status-capture shape (release_preview.ex:34-43) + the `System.halt` exit discipline (install.ex:132-157), changing fail-fast → collect-then-aggregate per D-A3.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/` (27 task files), `lib/scoria/verification_lanes.ex`, `mix.exs`, `test/scoria/{ci_policy_contract,verification_lanes}_test.exs`, `docs/MAINTAINERS.md`, `.planning/MILESTONES.md`
**Files scanned:** 12
**Pattern extraction date:** 2026-06-17

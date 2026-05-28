# Phase 59: Planner Contract Foundation - Pattern Map

**Mapped:** 2026-05-27  
**Inputs read:** `59-CONTEXT.md`, `59-RESEARCH.md`  
**Primary code anchors:** `lib/mix/tasks/scoria.install.ex`, `test/mix/tasks/scoria.install_test.exs`, `lib/mix/tasks/scoria.pgvector.bootstrap.ex`, `lib/scoria/workflows/replay_disposition.ex`

## Scope Fence (Phase 59 Only)

This phase establishes planner/check contract truth for `mix scoria.install`:

- deterministic, ordered, no-write planner artifact
- `--dry-run` and `--check` behavior from the same planner result
- per-surface classification (`create`, `update`, `no-op`, `manual-review`)
- stable `--check` exit semantics and machine trailer output

Do **not** fold in Phase 60 work (apply rewrite/unification).

## Likely File Changes

| Planned file | Role | Data flow | Closest analog(s) | Confidence |
|---|---|---|---|---|
| `lib/mix/tasks/scoria.install.ex` | CLI orchestrator (existing) | args -> planner/check/apply branch -> renderer -> optional write path | same file (`run/1`, `do_run/3`, `print_summary/1`) | high |
| `lib/scoria/install/planner.ex` (new) | canonical planner artifact builder | discovered targets + probes -> ordered surface entries -> summary | `lib/scoria/workflows/replay_disposition.ex` (deterministic precedence + canonicalization) | high |
| `lib/scoria/install/surface/router.ex` (new) | router analyzer (pure) | router content -> anchor/ownership probe -> classification + rationale + evidence | `inject_dashboard_mount/1`, `browser_scope_index/1` in `scoria.install.ex` | high |
| `lib/scoria/install/surface/tailwind.ex` (new) | tailwind analyzer (pure) | tailwind config content -> anchor detection -> classification | `maybe_inject_tailwind/1` in `scoria.install.ex` | high |
| `lib/scoria/install/surface/migrations.ex` (new) | migration analyzer (pure) | source+destination migration inventory -> missing/drift detection -> classification | `copy_core_migrations/1` in `scoria.install.ex` | high |
| `lib/scoria/install/surface/runtime_config.ex` (new) | runtime config analyzer (pure) | runtime/config file content -> ownership/conflict checks -> classification | `inject_runtime_config/1` in `scoria.install.ex` | high |
| `lib/scoria/install/report.ex` (new) | human/json output formatter | planner artifact -> grouped text + JSON + `SCORIA_CHECK_RESULT` trailer | `print_summary/1` (`scoria.install.ex`), `with_next_steps/1` (`scoria.pgvector.bootstrap.ex`) | medium |
| `test/mix/tasks/scoria.install_test.exs` | contract + no-write + classification tests (existing expansion) | fixture host files -> task invocation -> output/assertions | same file (`capture_install_run/1`, idempotency tests) | high |
| `test/mix/tasks/scoria.install_check_test.exs` (new likely) | subprocess check exit semantics | fixture host -> `System.cmd/3` mix invocation -> assert `0/1/2` + trailer | no direct existing `System.halt/1` analog; use `System.cmd/3` pattern from other task tests | medium |
| `docs/operator_verification.md` (optional) | command contract docs | command behavior -> operator guidance | existing lane/docs style | medium |
| `docs/adoption_lanes.md` (optional) | lane boundary docs | installer check/dry-run mention -> adoption guidance | existing lane/docs style | medium |
| `test/scoria/adoption_surface_test.exs` (optional if docs touched) | docs drift guard | docs content -> invariant assertions | same file content-string matrix pattern | medium |

## High-Leverage Existing Patterns To Mirror

### 1) Deterministic target discovery order in installer entrypoint

Use explicit ordered path precedence rather than dynamic filesystem/map ordering.

```elixir
router_paths = Path.wildcard("lib/*_web/router.ex")
tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]
config_paths = ["config/runtime.exs", "config/config.exs"]

router_path = List.first(router_paths)
tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)
config_path = Enum.find(config_paths, &File.exists?/1)
```

Pattern implication for Phase 59:

- planner should preserve explicit path-precedence lists
- classification order should be static (`router`, `tailwind`, `migrations`, `runtime_config`)

### 2) Reuse router-shape probes, but split from mutation path

Current router inject path already has robust browser-scope detection that should become read-only analyzer logic.

```elixir
case browser_scope_index(lines) do
  {:ok, index, indent} ->
    injected_lines = List.insert_at(lines, index + 1, "#{indent}scoria_dashboard \"/scoria\"")
    {:ok, Enum.join(injected_lines, "\n")}

  :error ->
    :error
end
```

```elixir
cond do
  root_scope_line?(trimmed) -> {:cont, {:in_root_scope, 1}}
  in_root_scope? and browser_pipe_through_line?(trimmed) -> {:halt, {:ok, index, indentation <> "  "}}
  in_root_scope? -> {:cont, update_scope_depth(state, trimmed)}
  true -> {:cont, state}
end
```

Pattern implication for Phase 59:

- keep these probes pure in analyzer modules
- do not call `File.write!/2` from planner/check path

### 3) Precedence-driven classification chain (`cond` first-match wins)

Mirror deterministic precedence from replay disposition logic.

```elixir
cond do
  replay_mode?(run) == false -> {:execute_live, evidence(...)}
  authority_expanding?(seam) -> {:blocked, evidence(...)}
  pure_local?(seam) -> {:execute_live, evidence(...)}
  exact_source_match?(seam, source_evidence) -> {:historical_stub, evidence(...)}
  true -> {:execute_live, evidence(...)}
end
```

Pattern implication for Phase 59:

- implement explicit planner precedence chain:
  1) discover target
  2) validate anchors
  3) ownership confidence
  4) desired-state check
  5) classify safe create/update/no-op
  6) fallback `manual-review`
- never let optimistic branch bypass `manual-review` fallback on ambiguity

### 4) Stable identity + canonicalization for deterministic plan entry IDs

Replay module shows deterministic hash ID and canonical normalization.

```elixir
raw =
  [Map.get(run, :id), Map.get(seam, :tool_id), Map.get(seam, :args_fingerprint)]
  |> Enum.map(&to_string_or_empty/1)
  |> Enum.join(":")

"replay:" <> Base.encode16(:crypto.hash(:sha256, raw), case: :lower)
```

```elixir
defp canonical(value) when is_map(value), do: value |> normalize_map() |> Enum.sort()
```

Pattern implication for Phase 59:

- derive planner entry `id` from deterministic fields only (`surface`, `target_path`, stable probe key)
- avoid timestamps/random UUIDs in planner JSON

### 5) Human-first grouped output with explicit section order

Installer summary already uses grouped rendering and ordered line generation.

```elixir
Mix.shell().info("Installed:")
Enum.each(installed_lines(statuses), fn line -> Mix.shell().info("  - #{line}") end)

Mix.shell().info("Skipped intentionally:")
Enum.each(skipped_lines(statuses), fn line -> Mix.shell().info("  - #{line}") end)
```

Pattern implication for Phase 59:

- preserve calm grouped output order from context decisions:
  - outcome
  - would change
  - already aligned
  - intentionally skipped
  - manual review
  - next steps
- feed both human and JSON output from one planner artifact (no duplicate logic trees)

### 6) Actionable remediation copy pattern (`Next steps`)

Pgvector bootstrap already encodes operator-friendly remediation style.

```elixir
defp with_next_steps(message) do
  """
  #{message}

  Next steps:
    1. Start the bundled pgvector service:
       mix scoria.pgvector.bootstrap
  """
end
```

Pattern implication for Phase 59:

- every `manual-review` or unsafe `--check` result should include clear next-step guidance
- trailer line should be machine-stable and separate from prose

### 7) Mix task option parsing pattern

Use explicit `@switches` + parse path, but tighten invalid-option handling.

```elixir
@switches [check: :boolean, compose_file: :string]
{opts, _argv, _invalid} = OptionParser.parse(args, switches: @switches)
```

Pattern implication for Phase 59:

- add `--dry-run`, `--check`, `--format`
- explicitly reject conflicting combinations (`--dry-run` + `--check` together) and invalid values
- do not silently ignore unknown flags

### 8) Existing installer test harness pattern

Keep fast, isolated fixture-host tests and capture shell output deterministically.

```elixir
File.cd!(@tmp_dir, fn ->
  Mix.Task.reenable("scoria.install")
  Mix.Tasks.Scoria.Install.run([])

  collect_shell_messages([])
  |> Enum.reverse()
  |> Enum.map_join("\n", fn {level, message} -> "[#{level}] #{message}" end)
end)
```

Pattern implication for Phase 59:

- extend this harness for dry-run/check textual contract tests
- add subprocess tests for explicit exit semantics where `System.halt/1` is involved

## Pre-Edit Symbol Checklist

Inspect these symbols before editing:

- `Mix.Tasks.Scoria.Install.run/1`
- `Mix.Tasks.Scoria.Install.do_run/3`
- `Mix.Tasks.Scoria.Install.inject_router/1`
- `Mix.Tasks.Scoria.Install.maybe_inject_tailwind/1`
- `Mix.Tasks.Scoria.Install.copy_core_migrations/1`
- `Mix.Tasks.Scoria.Install.inject_runtime_config/1`
- `Mix.Tasks.Scoria.Install.inject_dashboard_mount/1`
- `Mix.Tasks.Scoria.Install.browser_scope_index/1`
- `Mix.Tasks.Scoria.Install.print_summary/1`
- `Mix.Tasks.Scoria.Install.status_line/4`
- `Mix.Tasks.Scoria.Pgvector.Bootstrap.run/1`
- `Mix.Tasks.Scoria.Pgvector.Bootstrap.with_next_steps/1`
- `Scoria.Workflows.ReplayDisposition.resolve/5`
- `Scoria.Workflows.ReplayDisposition.canonical/1`
- `ScoriaWeb.SemanticEvidenceNotebookComponent.normalize_for_json/1`
- `Mix.Tasks.Scoria.InstallTest.capture_install_run/1`

## Phase-59 Risks and Anti-Patterns To Avoid

1. **Hidden writes in planner/check mode**  
   Calling existing mutators (`inject_*`, `copy_core_migrations`) from `--dry-run` or `--check` will violate contract guarantees.

2. **Nondeterministic planner output**  
   Relying on map iteration order or unsorted wildcard inventories will create unstable JSON/human output and brittle CI.

3. **Overconfident auto-classification**  
   Ambiguous router/runtime-config topologies must fall back to `manual-review`, not guessed updates.

4. **Entangling human prose with machine contract**  
   JSON and trailer semantics should be stable even if wording in human summary changes.

5. **Exit semantics tested only in-process**  
   If `System.halt/1` is used, in-process test assertions are fragile; prefer subprocess assertions for `0/1/2`.

6. **Scope creep into apply rewrite (Phase 60)**  
   Keep apply path behavior minimally touched in this phase; focus on planner/check contract foundation.

7. **Silent CLI flag handling**  
   Accepting invalid/conflicting options without explicit failure creates operator confusion and inconsistent CI usage.

## Recommended Execution Order For This Phase

1. Add planner artifact schema + deterministic ordering rules.
2. Extract pure per-surface analyzers (router, tailwind, migrations, runtime config).
3. Wire `mix scoria.install` option parsing and mode routing (`apply` default, `--dry-run`, `--check`, optional `--format json`).
4. Add report formatter for grouped human output + stable JSON + `SCORIA_CHECK_RESULT`.
5. Expand installer tests for no-write + classification + deterministic ordering.
6. Add subprocess-level check exit semantics tests for `0/1/2` and trailer format.
7. Update docs only if command contract copy needs alignment.

## Planner Notes For Executors

- Keep planner artifact as the single source of truth used by both dry-run and check paths.
- Preserve existing installer idempotency/apply tests; Phase 59 should not break current default install contract.
- Prefer small pure modules for analyzers to make Phase 60 apply reuse straightforward without rewriting logic twice.

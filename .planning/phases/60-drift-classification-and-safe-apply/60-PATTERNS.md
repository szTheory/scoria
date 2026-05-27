# Phase 60 Pattern Map

## Overview: Patterns To Follow

Phase 60 should extend the existing installer architecture rather than introduce a second mutation system. The strongest repo pattern is: **surface analyzers produce deterministic planner entries -> report/check render that canonical shape -> CLI modes consume the same truth with mode-specific behavior**. Implementation should keep this spine and add safe-apply behavior by tightening contracts already present:

- Keep planner output as the single source of truth for `--dry-run`, `--check`, and apply.
- Preserve conservative classification semantics (`manual_review` on ambiguity, never silent takeover).
- Preserve deterministic ordering (`order`, stable IDs) and stable machine-facing output contracts.
- Introduce remediation and drift/ownership evidence as additive fields on existing entry maps.
- Enforce zero-write blocking when any entry requires manual review or plan freshness is invalid.

## File-Area Pattern Map

### `lib/mix/tasks/scoria.install.ex`

- **Role in system:** CLI entrypoint, mode parsing, plan/check rendering, current direct apply mutator.
- **Closest analog pattern already present:** `run_check_mode/4` already does planner-led mode execution and explicit exit code handoff.
- **Concrete excerpts:**
  - Mode split in `run/1`:
    - `opts[:dry_run] -> Planner.build(...) |> print_report(...)`
    - `opts[:check] -> run_check_mode(...)`
    - apply path still uses `do_run/3`.
  - Stable check semantics in `run_check_mode/4`:
    - `result = Report.check_result(plan)`
    - `Mix.shell().info(Report.trailer_line(result))`
    - `System.halt(exit_code)`
  - Existing ad-hoc mutators: `inject_router/1`, `maybe_inject_tailwind/1`, `copy_core_migrations/1`, `inject_runtime_config/1`.
- **Implications for Phase 60:** Replace `do_run/3` direct mutation orchestration with planner-entry execution dispatch; keep current mode parsing/report wiring intact. Reuse `run_check_mode/4` style for explicit apply exit behavior (`0/1/2`) and trailer compatibility.

### `lib/scoria/install/planner.ex`

- **Role in system:** canonical plan artifact builder and deterministic ordering/identity layer.
- **Closest analog pattern already present:** `annotate_entries/1` + `stable_id/2` already normalize surface outputs into stable executable entries.
- **Concrete excerpts:**
  - Entry fan-in: `{:router, Router.analyze(...)}`, `{:tailwind, Tailwind.analyze(...)}`, `{:migrations, Migrations.analyze(...)}`, `{:runtime_config, RuntimeConfig.analyze(...)}`
  - Deterministic metadata:
    - `Map.put(:id, stable_id(surface, target_path))`
    - `Map.put(:order, order)`
    - `Enum.sort_by(& &1.order)`
  - Summary contract: `summarize/1` reducing `%{create, update, no_op, manual_review}`.
- **Implications for Phase 60:** Add apply-operation, ownership-mode, drift evidence, remediation payload, and freshness fingerprint fields here so all modes consume the same enriched artifact. Avoid deriving apply behavior anywhere else.

### `lib/scoria/install/report.ex`

- **Role in system:** human/json rendering + check status and stable trailer contract for CI.
- **Closest analog pattern already present:** single plan input, dual renderer output (`render_human/2` and `render_json/2`) plus `check_result/1`.
- **Concrete excerpts:**
  - Human per-entry lines currently include:
    - `classification`, `target path`, `rationale`.
  - JSON path normalizes atoms via `normalize_json_value/1`.
  - Stable trailer: `trailer_line/1 -> "SCORIA_CHECK_RESULT status=... exit_code=..."`.
  - Status mapping in `do_check_result/1`: `manual_review` and `drift` => exit `1`, `compliant` => `0`, fallback => `2`.
- **Implications for Phase 60:** Remediation data should be rendered from one canonical payload in both renderers to avoid divergence; keep trailer string stable and additive-only for new automation hints.

### `lib/scoria/install/surface/router.ex`

- **Role in system:** router ownership/drift analyzer and patchability classifier.
- **Closest analog pattern already present:** conservative patchability gate (`browser_scope_available?/1`) with `manual_review` fallback.
- **Concrete excerpts:**
  - Core checks: `import_present?`, `mount_present?`, `browser_scope_found?`.
  - Classification branches:
    - both present => `:no_op`
    - patchable root browser scope => `:update`
    - no safe anchor => `:manual_review`
  - Scope parser analog in `browser_scope_index/1` and `browser_pipe_through_line?/1`.
- **Implications for Phase 60:** This is the clearest analog for marker-owned managed region safety: retain "safe anchor required" posture, add explicit ownership/drift reason codes, and block apply when ownership is ambiguous.

### `lib/scoria/install/surface/runtime_config.ex`

- **Role in system:** runtime config ownership classifier for managed Scoria defaults.
- **Closest analog pattern already present:** regex-owned managed block detection with explicit conflict path.
- **Concrete excerpts:**
  - Managed block detector: `@managed_runtime_block`.
  - Conflict detector: `@conflicting_scoria_config`.
  - Classification branches:
    - managed block present => `:no_op`
    - conflicting Scoria config => `:manual_review`
    - otherwise append-safe => `:update`.
- **Implications for Phase 60:** Keep this ownership-first gate model and add manifest-linked evidence fields so apply can distinguish "owned drift" vs "host-owned conflict" without guessing.

### `lib/scoria/install/surface/migrations.ex`

- **Role in system:** structural file-set ownership analyzer for required migrations.
- **Closest analog pattern already present:** required basename diffing against host migration directory.
- **Concrete excerpts:**
  - Canonical source filtering:
    - `Path.wildcard("*.exs")`
    - reject optional lane basenames (`@optional_lane_migration_basenames`).
  - Drift evidence: `missing_basenames`.
  - Classification branches:
    - no source migrations => `:manual_review`
    - none missing => `:no_op`
    - missing required files => `:create`.
- **Implications for Phase 60:** Preserve structural ownership (no marker model here). Extend evidence with required vs observed sets and reason codes to support explicit remediation and freshness checks.

### `lib/scoria/install/surface/tailwind.ex`

- **Role in system:** optional tailwind integration classifier for Scoria glob ownership.
- **Closest analog pattern already present:** optional-surface no-op behavior plus anchor-based update/manual-review split.
- **Concrete excerpts:**
  - Optional absence path: `is_nil(tailwind_path) -> classification: :no_op` with `optional?: true`.
  - Safe update anchor: `Regex.match?(~r/content:\s*\[/s, content) -> :update`.
  - Unsupported topology => `:manual_review`.
- **Implications for Phase 60:** Continue treating tailwind as optional but ownership-aware; add marker/drift evidence when managed region exists and avoid takeover when structure is nonstandard.

### `test/mix/tasks/scoria.install_test.exs`

- **Role in system:** end-to-end installer behavior contract (idempotency, no-write, deterministic output, mutation guardrails).
- **Closest analog pattern already present:** fixture-in-temp-dir integration tests with in-process shell capture and subprocess checks for exit behavior.
- **Concrete excerpts:**
  - Fixture setup conventions:
    - `@tmp_dir "test/tmp/installer"`
    - `setup` creates minimal Phoenix-like tree + local host `mix.exs`.
    - `on_exit(fn -> File.rm_rf!(@tmp_dir) end)`.
  - In-process command harness:
    - `Mix.shell(Mix.Shell.Process)`
    - `Mix.Task.reenable("scoria.install")`
    - `capture_install_run/2` + `collect_shell_messages/1`.
  - No-write snapshot strategy:
    - `before_snapshot = snapshot_host_files(...)`
    - run command
    - assert `after_snapshot.* == before_snapshot.*` across router/tailwind/runtime/migrations.
  - Existing determinism signal:
    - repeated `--dry-run` outputs are byte-equal.
- **Implications for Phase 60:** Add planner-vs-apply equivalence and blocked-apply-zero-write tests in this same fixture style; keep assertions on deterministic output and one-time injection semantics.

### `test/mix/tasks/scoria.install_check_test.exs`

- **Role in system:** subprocess-level contract tests for check exit codes and stable trailer parsing.
- **Closest analog pattern already present:** tri-state fixture matrix with `System.cmd/3` and isolated per-run fixture roots.
- **Concrete excerpts:**
  - Entry contract test:
    - `assert_check_result(:compliant, 0, "...status=compliant exit_code=0")`
    - `assert_check_result(:drift, 1, "...status=drift exit_code=1")`
    - `assert_check_result(:manual_review, 1, "...status=manual_review exit_code=1")`
    - `assert_check_result(:error, 2, "...status=error exit_code=2")`
  - Subprocess harness:
    - `System.cmd("mix", ["scoria.install", "--check"], cd: fixture_root, stderr_to_stdout: true, env: subprocess_mix_env())`.
  - Fixture builder pattern:
    - `build_fixture!/1` with per-kind router/runtime/tailwind states.
- **Implications for Phase 60:** Mirror this exact style for apply exit semantics (`0/1/2`) and blocked/manual-review cases, so shell-level behavior remains contract-tested independently from in-process unit-style assertions.

## Testing Pattern Guidance For Phase 60

Use the current installer test harness conventions exactly; extend rather than replace.

- **Fixture strategy (integration-first):**
  - Keep per-suite temp roots under `test/tmp/...` (`@tmp_dir` constants).
  - Build realistic host fixtures (router, runtime config, migrations, optional tailwind) in `setup`/builder helpers.
  - Always cleanup with `on_exit(File.rm_rf!...)`.
  - Continue copying repo `mix.lock` and writing local host `mix.exs` with `{:scoria, path: repo_root}` dependency for realistic command runs.

- **Subprocess style (exit-contract assertions):**
  - Use `System.cmd("mix", ["scoria.install", <mode>], cd: fixture_root, stderr_to_stdout: true, env: subprocess_mix_env...)`.
  - Keep `MIX_ENV=test`, `MIX_BUILD_PATH`, and `MIX_DEPS_PATH` pinned to repo paths.
  - Assert both exit code and machine-parsable trailer/status lines.

- **No-write snapshot checks (safety gate proof):**
  - Reuse the `snapshot_host_files/3` pattern (router/tailwind/runtime/migration basenames).
  - For all blocked conditions (`manual_review`, stale plan/freshness mismatch), assert byte-identical before/after snapshots.
  - Keep separate assertions for deterministic textual output to catch ordering drift.

- **Apply-specific additions for Phase 60:**
  - Add "planner/apply equivalence" tests that assert apply mutates only surfaces classified as actionable in planner entries.
  - Add deterministic operation-order tests (same fixture, repeated runs, same output/effects).
  - Add remediation contract checks in both human and json modes from the same blocking scenario.

## Implementation Checklist (Pattern-Driven)

- Route apply through planner artifact consumption (no direct ad-hoc write pipeline).
- Enrich planner entries with operation + ownership + drift + remediation + freshness metadata.
- Keep conservative analyzer behavior (`manual_review` on ambiguity, no implicit adoption).
- Preserve `SCORIA_CHECK_RESULT` trailer compatibility and existing `0/1/2` semantics.
- Prove safety via snapshot no-write tests and subprocess exit-contract tests.

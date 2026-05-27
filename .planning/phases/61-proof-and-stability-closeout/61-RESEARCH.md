# Phase 61 Research: Proof And Stability Closeout

## Objective

Plan Phase 61 to close `INST-08`: prove installer output truth and idempotency across `--dry-run`, `--check`, and apply on representative host shapes, without altering planner/apply semantics from phases 59–60. Regression-gate v2.4 lane contract, scoped warning policy, and CI closeout order.

## Requirement Mapping

- **INST-08**: Installer output stays truthful and idempotent across preview/check/apply, including stable summaries for already-installed, skipped, and manual-review surfaces.
- **Preserved from 59–60**: Planner atoms (`create | update | no_op | manual_review`), `SCORIA_CHECK_RESULT` trailer, tri-state exits (`0/1/2`), zero-write `--dry-run`/`--check`, planner-led apply.
- **Explicit non-goals**: `WARN-03` full-suite ratchet, fourth closeout lane, N× `phx.new` matrix, full CLI log goldens, planner engine rewrite.

## Current State (Post Phase 60)

### Implemented and reusable

- `Scoria.Install.Planner.build/4` — canonical entries with ownership/drift/remediation.
- `Scoria.Install.Report` — human/JSON render, `check_result/1`, stable `trailer_line/1`; summary uses planner atoms only (`create`, `update`, `no_op`, `manual_review`).
- `Scoria.Install.ApplyExecutor` — planner-led apply with freshness + manual_review gates.
- `test/mix/tasks/scoria.install_check_test.exs` — subprocess tri-state fixtures (`:compliant`, `:drift`, `:manual_review`, `:error`) with inline `build_fixture!/1`.
- `test/mix/tasks/scoria.install_test.exs` — dry-run no-write, check no-write, apply blocking, owned-host apply; inline fixture setup (parallel to check test).
- `Scoria.VerificationLanes` — frozen closeout order `[:release_preview, :adoption, :runtime_to_handoff]`.
- `mix test.adoption` — includes install tests in adoption file list.

### Gaps for INST-08

1. **Duplicate fixture builders** — `install_check_test.exs` and `install_test.exs` each construct subprocess hosts independently (D-01 violation risk).
2. **Missing fixture classes** — no shared `:root_list_form_browser`, `:non_root_browser_only`, `:optional_surface_absent` (D-02, D-04).
3. **No operator projection** — human summary counts planner atoms, not operator vocabulary (`would_change`, `already_present`, `skipped`, `manual_review`) (D-07, D-08).
4. **No `summary_operator` in JSON** — machine consumers cannot parse operator counts without reimplementing projection rules (D-09).
5. **No `Scoria.Install.Contract` SSOT** — trailer prefix, verify command, classification labels duplicated across tests/docs (D-25).
6. **No B-cycle integration proof** — dry-run → check → apply → check → apply idempotency chain missing (D-17–D-19).
7. **No dry_run/check body equivalence test** — same fixture should yield identical `entries` + `summary` (D-11).
8. **Minimal installer docs** — no operator modes subsection; `Mix.Tasks.Scoria.Install` lacks `@moduledoc` (D-26, D-27).

## Recommended Architecture

### 1. `Scoria.Install.Contract` (parallel to `VerificationLanes`)

Single module exposing:

- `trailer_prefix/0` → `"SCORIA_CHECK_RESULT"`
- `trailer_line/2` or delegate to `Report.trailer_line/1`
- `default_verify_command/0` → `"mix scoria.install --check"`
- `planner_classifications/0` and `operator_summary_keys/0`
- `operator_projection/2` — maps `{classification, drift.reason_code, mode}` → operator bucket
- Optional: `modes/0`, `exit_codes/0` for doc pins

Tests and `adoption_surface_test.exs` import Contract instead of hardcoding strings.

### 2. Operator projection in `Scoria.Install.Report`

Keep planner `plan.summary` unchanged. Add:

- `project_operator_summary/2` — derives `%{"would_change" => n, "already_present" => n, "skipped" => n, "manual_review" => n}` from entries + mode
- Update `render_human/2` — operator-ordered summary lines (D-08)
- Update `render_json/2` — add `summary_operator` key; normalize `schema_version` to `"1.0"` string (D-09)

Projection rules (locked):

| Planner state | Mode | Operator bucket |
|---------------|------|-----------------|
| `no_op` + `drift.reason_code: "optional_surface_absent"` | any | `skipped` |
| `no_op` + managed region current | check/apply post-converge | `already_present` |
| `create` / `update` | dry_run/check | `would_change` |
| `create` / `update` | apply (post-run re-check semantics via check mode tests) | per D-07 |
| `manual_review` | any | `manual_review` |

### 3. Shared fixture harness `Scoria.TestSupport.HostInstallFixtures`

Location: `test/support/scoria/host_install_fixtures.ex`

API sketch:

```elixir
build!(kind, opts \\ []) :: %{root: path, repo_root: path, ...}
kinds: :compliant | :drift | :manual_review | :error | :root_list_form_browser | :non_root_browser_only | :optional_surface_absent | :owned_apply_host
subprocess_mix_env/1
snapshot_host_files/1  # excludes manifest.json from byte compare
```

Refactor both install test modules to call `HostInstallFixtures.build!/1`. Preserve unique `test/tmp/installer/fixture-*` dirs per test.

### 4. Proof test layering (D-13–D-15)

| Layer | Location | Scope |
|-------|----------|-------|
| Adoption lane | existing install test files | mode equivalence smoke, B-cycle on owned host, operator summary substring pins |
| Deep lane | `@tag :install_deep` or same files | extended fixture matrix, tailwind-absent subprocess, migration copy-once |
| Maintainer optional | `mix test.install_contract` (if added) | NOT in `VerificationLanes.closeout_order/0` |

### 5. B-cycle idempotency proof (Molecule pattern)

On `:owned_apply_host` fixture with markers present:

1. `--dry-run` → exit 0, snapshot unchanged
2. `--check` → exit 1 (drift) or appropriate pre-apply state, snapshot unchanged
3. apply (default) → exit 0, expected surfaces mutate
4. `--check` → `SCORIA_CHECK_RESULT status=compliant exit_code=0`
5. apply again → snapshot unchanged, all entries `no_op`, operator counts show `already_present`

Use subprocess `System.cmd("mix", ...)` throughout for exit/`System.halt` truth.

## Test Strategy

### Contract / projection (Plan 01)

- Unit tests for `operator_projection/2` permutations
- JSON contains `"summary_operator"` with four operator keys
- Human output contains operator labels in order: would_change, already_present, skipped, manual_review
- `schema_version` is string `"1.0"` in JSON

### Fixture harness + equivalence (Plan 02)

- All six fixture classes build without error
- Tri-state trailers unchanged per class
- In-process: `Planner.build(..., :dry_run)` vs `:check` → same `entries` and `summary`
- Subprocess: `--dry-run` vs `--check` normalized bodies equal (strip trailer)
- `:optional_surface_absent` → operator `skipped`, no tailwind file created
- B-cycle test as primary integration proof

### Docs + guardrails (Plan 03)

- `docs/operator_verification.md` subsection with dry-run → check → remediate → apply flow
- `docs/adoption_lanes.md` 2–3 sentence cross-ref
- `adoption_surface_test.exs` pins subsection heading + `--check` mention
- `61-VERIFICATION.md` records v2.4 closeout chain (D-22); optional smoke for full `mix test`

## Risk Areas

- Projection drift if tests pin planner labels while operators read new vocabulary — pin both layers explicitly.
- Fixture refactor regressions — run adoption lane after refactor before adding new cases.
- Accidentally widening closeout order — `verification_lanes_test.exs` must stay green unchanged.
- Scope creep into WARN-03 — guardrail task uses scoped WAE only (D-22, D-24).

## Sequencing (Three Plans)

1. **61-01**: `Install.Contract` + Report projection + `@moduledoc` (foundation)
2. **61-02**: Shared fixtures + refactor + B-cycle + mode equivalence + deep cases (proof)
3. **61-03**: Minimal docs + adoption pins + `61-VERIFICATION.md` + guardrail pass (closeout)

## Validation Architecture

Four validation layers for Nyquist:

- **Contract validation**
  - `Install.Contract` exposes trailer prefix, verify command, operator keys
  - Projection rules match D-07 table for all fixture classes
  - JSON `schema_version` is `"1.0"` string; planner keys unchanged
- **Truth validation**
  - dry_run/check produce identical plan bodies for same host state
  - Operator summary counts match entry-level projection
  - Tri-state trailers exact per fixture class
- **Idempotency validation**
  - B-cycle: no writes on preview modes; second apply is no-op
  - Post-converge check returns `compliant exit_code=0`
- **Guardrail validation**
  - v2.4 closeout chain green (compile WAE, scoped tests, release_preview, ecto, adoption, runtime_to_handoff)
  - `VerificationLanes.closeout_order/0` unchanged
  - No fourth lane added

## RESEARCH COMPLETE

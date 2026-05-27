# Phase 61 — Pattern Map

**Phase:** 61 — Proof And Stability Closeout  
**Generated:** 2026-05-27

## Analog Modules

| Target (new/modified) | Closest analog | Role |
|----------------------|----------------|------|
| `lib/scoria/install/contract.ex` | `lib/scoria/verification_lanes.ex` | Code SSOT for commands, labels, closeout-adjacent constants |
| `test/support/scoria/host_install_fixtures.ex` | `test/support/scoria/host_app_proof/generator.ex` | Subprocess host construction (lighter — no phx.new) |
| Operator projection in `report.ex` | Existing `remediation_payload/1` + `check_result/1` | Single render pipeline, dual vocabulary |
| B-cycle test | `install_test.exs` `write_owned_managed_files!/1` + subprocess helpers | Idempotency proof pattern |

## Code Excerpts

### VerificationLanes SSOT pattern (mirror for Install.Contract)

```elixir
# lib/scoria/verification_lanes.ex
@closeout_order [:release_preview, :adoption, :runtime_to_handoff]

def closeout_order, do: @closeout_order
def command(id), do: fetch!(id).command
```

### Report summary today (planner atoms — preserve)

```elixir
# lib/scoria/install/report.ex
@summary_order [:create, :update, :no_op, :manual_review]

defp classification_label(:no_op), do: "no-op"
defp classification_label(:manual_review), do: "manual-review"
```

### Subprocess install test pattern

```elixir
# test/mix/tasks/scoria.install_test.exs
System.cmd("mix", ["scoria.install" | args],
  cd: ctx.fixture_root,
  stderr_to_stdout: true,
  env: subprocess_mix_env(ctx.repo_root)
)
```

### Check test fixture builder (refactor source)

```elixir
# test/mix/tasks/scoria.install_check_test.exs
defp build_fixture!(fixture_kind) do
  fixture_root = Path.join(@tmp_dir, "#{fixture_kind}-#{System.unique_integer([:positive])}")
  # ... writes router, runtime, tailwind, migrations
  fixture_root
end
```

### Phase 60 remediation parity test (template for INST-08)

```elixir
# test/mix/tasks/scoria.install_check_test.exs
assert human_output =~ "reason_code: missing_ownership_markers"
assert json_output =~ "\"reason_code\": \"missing_ownership_markers\""
assert output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"
```

## File Modification Map

| File | Action | Pattern to follow |
|------|--------|-------------------|
| `lib/scoria/install/contract.ex` | create | `VerificationLanes` module layout |
| `lib/scoria/install/report.ex` | extend | Add projection; keep `normalize_plan_for_json/1` additive |
| `lib/mix/tasks/scoria.install.ex` | extend | Ecto-style `@moduledoc` with mode table |
| `test/support/scoria/host_install_fixtures.ex` | create | Extract from `install_check_test.exs` |
| `test/mix/tasks/scoria.install_check_test.exs` | refactor | Delegate to fixtures module |
| `test/mix/tasks/scoria.install_test.exs` | refactor + extend | B-cycle + owned host via fixtures |
| `test/scoria/install/report_test.exs` | create | Unit tests for projection |
| `docs/operator_verification.md` | extend | Single subsection only |
| `docs/adoption_lanes.md` | extend | 2–3 sentence cross-ref |
| `test/scoria/adoption_surface_test.exs` | extend | Narrow substring pins |

## PATTERN MAPPING COMPLETE

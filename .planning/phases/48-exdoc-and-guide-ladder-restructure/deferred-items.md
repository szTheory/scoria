# Phase 48 Deferred Items

## 48-05 broad adoption-surface verification

During 48-05 closeout, the plan-level command
`MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs`
still failed in `test/scoria/adoption_surface_test.exs` for contracts outside the
48-05 file set.

Out-of-scope failures observed:

- README still links old `docs/scoria_vs_external_llm_ops.md` and is missing canonical `guides/golden-path.md`, `guides/reviewer-verification.md`, and `guides/scoria-vs-external-llm-ops.md` links. Later Phase 48 README rewiring owns this.
- `guides/golden-path.md` is missing some compatibility/contract fragments such as `guides/reviewer-verification.md`, `Default runtime capability`, and `Authorization remains delegated to the host; Scoria does not introduce a role model.` This predates 48-05 and belongs with Start Here/cross-link cleanup.
- `guides/jtbd-and-user-flows.md` is missing a `bounded handoff capability` fragment expected by `HexConsumerContract`.
- `guides/capabilities/bounded-handoffs.md` is missing an `identity -> start -> inspect -> resume` fragment.
- D-17 public moduledoc canonical guide links remain RED and are owned by later Phase 48 moduledoc plans.

48-05-specific checks passed for:

- `guides/reviewer-verification.md`
- `guides/troubleshooting.md`
- `guides/scoria-vs-external-llm-ops.md`
- `guides/maintainers.md`
- `test/scoria/terminology_contract_test.exs`

## 48-08 broad adoption-surface verification

During 48-08 closeout, the plan-level command
`MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria_test.exs test/scoria/identity_doctest_test.exs`
still failed outside the 48-08 file set.

Out-of-scope failures observed:

- Later-plan D-17 public moduledoc contracts still fail for modules outside the 48-08 file set, such as `ScoriaWeb.DashboardScope` / `Scoria.Connectors.Auth` guide-link coverage depending on map iteration order.
- The previously logged Start Here / capability guide fragment failures remain for `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, and `guides/capabilities/bounded-handoffs.md`.

48-08-specific checks passed for:

- `lib/scoria.ex`
- `lib/scoria/identity.ex`
- `lib/scoria/runtime.ex`
- `lib/scoria/runtime/run_summary.ex`
- `lib/scoria/runtime/run_detail.ex`
- `lib/scoria/prompt_policy.ex`
- `test/scoria_test.exs`
- `test/scoria/identity_doctest_test.exs`

## 48-11 broad adoption-surface verification

During 48-11 closeout, the plan-level command
`MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs`
still failed outside the 48-11 file set.

Out-of-scope failures observed:

- `guides/golden-path.md` is still missing existing contract fragments such as
  `guides/reviewer-verification.md`, `Start with the default runtime capability`,
  `Default runtime capability`, and `Authorization remains delegated to the host; Scoria does not introduce a role model.`
- `guides/jtbd-and-user-flows.md` is still missing a `bounded handoff capability`
  fragment expected by `HexConsumerContract`.
- `guides/capabilities/bounded-handoffs.md` is still missing an
  `identity -> start -> inspect -> resume` fragment.
- D-17 public moduledoc canonical guide links remain RED for modules outside the
  48-11 file set.

48-11-specific checks passed for:

- `docs/glossary.md`
- `docs/adoption_lanes.md`
- `docs/scoria_vs_external_llm_ops.md`
- `docs/phoenix_runtime_example.md`
- `test/scoria/terminology_contract_test.exs`

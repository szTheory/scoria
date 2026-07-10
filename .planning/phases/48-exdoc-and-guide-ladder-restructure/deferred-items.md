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

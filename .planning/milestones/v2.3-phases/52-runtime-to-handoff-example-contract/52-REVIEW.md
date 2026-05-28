---
phase: 52-runtime-to-handoff-example-contract
reviewed: 2026-05-27T07:04:07Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - docs/bounded_handoffs.md
  - docs/phoenix_runtime_example.md
  - test/scoria/adoption_surface_test.exs
  - test/scoria/runtime_test.exs
  - test/support/scoria/adoption_example.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 52: Code Review Report

**Reviewed:** 2026-05-27T07:04:07Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the Phase 52 docs and tests for the bounded handoff adoption contract, projected context safety claims, host/Scoria ownership boundary, and `run_id`/`session_id` semantics. The projected-context rejection examples and ownership boundary claims match the runtime implementation, but the new Phoenix runtime example codifies an extra default run before starting the bounded handoff run for the same draft-review turn.

## Warnings

### WR-01: Phoenix handoff example creates a stray run before the handoff run

**File:** `docs/phoenix_runtime_example.md:129`
**Issue:** The bounded handoff branch starts a default run, stores its `run_id`, then starts a separate `Scoria.start_handoff_run/3` run for the same draft review and redirects to the handoff run. That teaches adopters to create two durable runs for one bounded handoff turn, leaving `:last_scoria_run_id` pointing at a run with no delegated evidence while the actual delegated lineage lives under `:last_scoria_handoff_run_id`. This conflicts with the bounded handoff guide's "starts one durable run" and "same durable run" contract. The regression test at `test/scoria/runtime_test.exs:302` and fragment assertion at `test/support/scoria/adoption_example.ex:41` now lock in that confusing split-run behavior.

**Fix:** Decide whether bounded review is needed before creating a runtime run. For the handoff path, call `Scoria.start_handoff_run/3` directly and store only that returned `run_id`; for the non-handoff path, call `Scoria.start_run/2`.

```elixir
if needs_bounded_review?(draft_answer) do
  {:ok, started} =
    Scoria.start_handoff_run(identity, "critic",
      root_role_id: "planner",
      delegated_kind: "review",
      handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
      projected_context: %{
        "task" => "policy-and-accuracy review",
        "draft_answer" => draft_answer
      },
      handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
    )

  conn
  |> put_session(:last_scoria_run_id, started.run_id)
  |> redirect(to: ~p"/assistant/runs/#{started.run_id}")
else
  {:ok, started} = Scoria.start_run(identity, root_role_id: "executor")

  conn
  |> put_session(:last_scoria_run_id, started.run_id)
  |> redirect(to: ~p"/assistant/runs/#{started.run_id}")
end
```

Update `test/scoria/runtime_test.exs:302` to assert the handoff example creates one handoff run for the review branch, and remove the `started.run_id != handoff_run.run_id` doc-fragment requirement from `test/support/scoria/adoption_example.ex:41`.

---

_Reviewed: 2026-05-27T07:04:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

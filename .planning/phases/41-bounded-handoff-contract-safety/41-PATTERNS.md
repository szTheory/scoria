# Phase 41: Bounded Handoff Contract & Safety - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/runtime/params.ex` | service | transform | `lib/scoria/runtime/params.ex` | exact |
| `lib/scoria/runtime.ex` | facade | request-response | `lib/scoria/runtime.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | service | event-driven | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/workflows/handoff.ex` | model | CRUD | `lib/scoria/workflows/handoff.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | DTO projection | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `docs/bounded_handoffs.md` | docs | support-truth | `docs/bounded_handoffs.md` | exact |
| `test/scoria/runtime_test.exs` | test | request-response | `test/scoria/runtime_test.exs` | exact |
| `test/scoria/workflows/runtime_test.exs` | test | event-driven | `test/scoria/workflows/runtime_test.exs` | exact |
| `test/scoria/adoption_surface_test.exs` | test | support-truth | `test/scoria/adoption_surface_test.exs` | exact |
| `test/scoria/handoff_example_source_test.exs` | test | support-truth | `test/scoria/handoff_example_source_test.exs` | exact |
| `test/support/scoria/adoption_example.ex` | checked source | support-truth | `test/support/scoria/adoption_example.ex` | exact |

## Pattern Assignments

### `lib/scoria/runtime/params.ex` (service, transform)

**Analog:** existing `Scoria.Runtime.Params` normalization helpers

**Public contract assembly** (`lib/scoria/runtime/params.ex`)
```elixir
workflow_attrs = %{
  root_role_id: value(opts, runtime, :root_role_id) || "executor",
  actor_id: identity.actor_id,
  tenant_id: identity.tenant_id,
  session_id: identity.session_id,
  metadata: start_metadata(opts, runtime, identity, resolved_defaults)
}

handoff_attrs = %{
  "delegated_role_id" => delegated_role_id,
  "delegated_kind" => delegated_kind(opts, runtime),
  "capability_tags" => capability_tags(opts, runtime),
  "handoff_input" => normalize_metadata(value(opts, runtime, :handoff_input)),
  "projected_context" => projected_context(opts, runtime)
}
```

**Apply to Phase 41:** keep all public contract normalization here, but replace hidden defaults and implicit payload projection with explicit validation helpers returning clear contract errors.

---

### `lib/scoria/runtime.ex` (facade, request-response)

**Analog:** existing `start_handoff_run/3` public facade

**Same-run handoff creation** (`lib/scoria/runtime.ex`)
```elixir
with {:ok, %{workflow_attrs: workflow_attrs, handoff_attrs: handoff_attrs, dispatch_opts: dispatch_opts}} <-
       Params.start_handoff(identity, delegated_role_id, opts),
     {:ok, run} <- Workflows.create_run(workflow_attrs),
     {:ok, step} <-
       Workflows.create_step(run.id, %{
         sequence: 1,
         kind: "handoff",
         role_id: workflow_attrs.root_role_id,
         status: "queued"
       }),
     {:ok, _completed_step} <-
       Scoria.Workflows.Runtime.execute_step(step.id,
         handler: fn _step, _run -> {:handoff, handoff_attrs} end
       ) do
```

**Apply to Phase 41:** preserve this facade and same-run shape. Contract failures should be surfaced before this path persists run truth, and success-path readback must continue to flow through `Runtime.get_run_detail!/1`.

---

### `lib/scoria/workflows/runtime.ex` (service, event-driven)

**Analog:** existing `handle_handoff/3` handoff substrate

**Current handoff seam** (`lib/scoria/workflows/runtime.ex`)
```elixir
delegated_role_id = Map.fetch!(attrs, "delegated_role_id")
delegated_kind = Map.get(attrs, "delegated_kind", "handoff")
projected_context = Map.get(attrs, "projected_context", %{})

if unsafe_projected_context?(projected_context) do
  Workflows.fail_step(step.id, %{"reason" => "unsafe_projected_context"})
else
  {:ok, _handoff} =
    Workflows.create_handoff(step, %{
      delegated_role_id: delegated_role_id,
      capability_tags: List.wrap(Map.get(attrs, "capability_tags", [])),
      handoff_input: Map.get(attrs, "handoff_input", %{}),
      result_summary: %{},
      status: "pending"
    })
```

**Apply to Phase 41:** keep same-run child-step creation here, but treat validation helpers as reusable defense-in-depth instead of the primary public contract gate.

---

### `lib/scoria/workflows/handoff.ex` (model, CRUD)

**Analog:** existing workflow handoff schema and changeset

**Current durable row** (`lib/scoria/workflows/handoff.ex`)
```elixir
schema "ai_workflow_handoffs" do
  field :delegated_role_id, :string
  field :capability_tags, {:array, :string}, default: []
  field :status, :string, default: "pending"
  field :handoff_input, :map, default: %{}
  field :result_summary, :map, default: %{}
```

**Apply to Phase 41:** if durable truth needs more explicit contract fields such as delegated kind or root-role-facing truth, extend this schema rather than inventing a parallel persistence surface.

---

### `lib/scoria/runtime/run_detail.ex` (DTO projection, transform)

**Analog:** existing curated runtime detail DTO

**Current handoff item** (`lib/scoria/runtime/run_detail.ex`)
```elixir
defp handoff_item(%Handoff{} = handoff) do
  %{
    id: handoff.id,
    step_id: handoff.step_id,
    delegated_role_id: handoff.delegated_role_id,
    capability_tags: handoff.capability_tags || [],
    handoff_input: handoff.handoff_input || %{},
    status: handoff.status,
    inserted_at: handoff.inserted_at
  }
end
```

**Apply to Phase 41:** extend the curated DTO with the minimum contract truths callers need to inspect the bounded handoff lane without broadening into full operator UX polish.

---

### `docs/bounded_handoffs.md` and checked-source tests (support-truth)

**Analogs:** existing guide plus adoption/source assertions

**Current support-truth seam** (`docs/bounded_handoffs.md`)
```markdown
- the root role that is delegating
- the delegated role that should own the child step
- the exact projected context slice that is safe to pass down
- the child step kind that host handlers should execute
```

**Current adoption assertions**
```elixir
assert content =~ "Scoria.start_handoff_run"
assert content =~ "delegated_kind"
assert content =~ "projected_context"
```

**Apply to Phase 41:** keep docs and checked source fragments in lockstep with the explicit contract and unsafe-context rules. Do not let the guide continue teaching semantics the code no longer guarantees.


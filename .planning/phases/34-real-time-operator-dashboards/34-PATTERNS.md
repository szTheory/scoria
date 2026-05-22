# Phase 34: Real-time Operator Dashboards - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 8 proposed files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/eval.ex` | service | query/projection | `lib/scoria/runtime.ex` | role+flow |
| `lib/scoria/eval/campaign_worker.ex` | service | publish/update | `lib/scoria/eval/campaign_worker.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | liveview | projection/render | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/components/eval_campaign_detail_component.ex` | component | detail notebook | `lib/scoria_web/components/incident_evidence_component.ex` | role+flow |
| `lib/scoria_web/components/model_health_drawer_component.ex` | component | drawer/detail | `lib/scoria_web/components/runtime_detail_drawer_component.ex` | role+flow |
| `lib/scoria_web/components/eval_campaign_board_component.ex` | component | scan/list | `lib/scoria_web/components/connector_detail_drawer_component.ex` | partial |
| `test/scoria_web/live/orchestrator_live_test.exs` | test | liveview interaction | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria/eval/campaign_worker_test.exs` | test | projection updates | `test/scoria/eval/campaign_worker_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/eval.ex` (service, query/projection)

**Analog:** `lib/scoria/runtime.ex`

**Context API shape** (`lib/scoria/runtime.ex`):
```elixir
def list_compacted_memories_for_run(run_id) do
  Scoria.Runtime.CompactedMemory
  |> where([m], m.run_id == ^run_id)
  |> order_by([m], asc: m.start_sequence)
  |> Repo.all()
end
```

**Apply to Phase 34:** Add small query-facing functions such as `list_dashboard_campaigns/1`, `get_campaign_dashboard_detail/2`, and `list_model_health/1` in the context rather than embedding Ecto queries into the LiveView.

### `lib/scoria/eval/campaign_worker.ex` (service, publish/update)

**Analog:** `lib/scoria/eval/campaign_worker.ex`

**Stable worker lifecycle**:
```elixir
with {:ok, context} <- Eval.load_campaign_execution(args),
     :ok <- maybe_mark_running(context),
     {:ok, result} <- Eval.execute_campaign_target(context),
     {:ok, _campaign} <- Eval.complete_campaign_target(context, result) do
  :ok
end
```

**Apply to Phase 34:** Hook campaign progress broadcasts off the same durable lifecycle transitions that already update rollup truth, so PubSub reflects persisted state instead of speculative UI events.

### `lib/scoria_web/live/orchestrator_live.ex` (liveview, projection/render)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Refresh seam** (`load_operator_surface/1`):
```elixir
socket
|> assign(:approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}))
|> assign(:connector_fleet, Connectors.list_connector_fleet(%{tenant_id: tenant_id}))
|> assign(:runtimes, runtimes)
```

**Apply to Phase 34:** Extend this one refresh seam with eval summary counters, campaign board data, selected campaign detail, and model health instead of scattering refresh logic across many `handle_info` branches.

### `lib/scoria_web/components/eval_campaign_detail_component.ex` (component, detail notebook)

**Analog:** `lib/scoria_web/components/incident_evidence_component.ex`

**Operator detail layout**:
```elixir
<div class="grid gap-3 lg:grid-cols-5">
...
</div>

<div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
...
</div>
```

**Apply to Phase 34:** Use the same summary-first plus dense-detail composition for campaign detail: top-level counters/status, then target shard rows and lineage links.

### `lib/scoria_web/components/model_health_drawer_component.ex` (component, drawer/detail)

**Analog:** `lib/scoria_web/components/runtime_detail_drawer_component.ex`

**Compact drawer pattern**:
```elixir
<section id="runtime-detail-drawer" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm mt-6">
...
</section>
```

**Apply to Phase 34:** Model-health detail should stay lightweight and inline, showing provider, model, breaker state, fallback count, freshness, and linked campaigns without introducing modal complexity.

### `lib/scoria_web/components/eval_campaign_board_component.ex` (component, scan/list)

**Analog:** `lib/scoria_web/components/connector_detail_drawer_component.ex`

**Compact list card rhythm**:
```elixir
<article class="rounded-xl border border-stone-200 bg-stone-50 p-3">
...
</article>
```

**Apply to Phase 34:** Campaign rows should follow the existing compact operator-card rhythm, with one obvious primary action and dense metadata instead of a full data-grid-first treatment.

### `test/scoria_web/live/orchestrator_live_test.exs` (test, liveview interaction)

**Analog:** `test/scoria_web/live/orchestrator_live_test.exs`

**Interaction style**:
```elixir
{:ok, view, _html} = live(conn, "/scoria")
render_click(view, "open_runtime_drawer", %{"id" => id})
assert render(view) =~ "runtime detail"
```

**Apply to Phase 34:** Verify mount output, live PubSub refresh, campaign selection, inline detail rendering, and empty-state copy with the same direct render/click assertions.

### `test/scoria/eval/campaign_worker_test.exs` (test, projection updates)

**Analog:** `test/scoria/eval/campaign_worker_test.exs`

**Durable rollup assertions**:
```elixir
campaign = Repo.get!(EvalCampaign, campaign.id)
assert campaign.status == "completed_partial"
assert campaign.completed_targets == 1
assert campaign.failed_targets == 1
```

**Apply to Phase 34:** When adding PubSub broadcasts, keep the worker tests focused on the same durable transitions and assert that broadcasts are emitted only after the rollup row reflects the new state.

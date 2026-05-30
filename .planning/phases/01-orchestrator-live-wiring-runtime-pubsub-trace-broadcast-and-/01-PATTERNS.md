# Phase 01: Orchestrator Live Wiring — Pattern Map

**Mapped:** 2026-05-30  
**Phase:** 01 — Orchestrator Live Wiring (ORCH-LIVE-01)  
**Files analyzed:** 16  
**Analogs found:** 15 / 16

---

## File Classification

| New/Modified File | Role | Data Flow | Wave | Closest Analog | Match Quality |
|-------------------|------|-----------|------|----------------|---------------|
| `lib/scoria/observe/operator_broadcast.ex` | **NEW** context | event-driven (PubSub fan-out) | 01-01 | `lib/scoria/workflows.ex` (`broadcast/2`) | exact |
| `lib/scoria/observe/trace_projection.ex` | **NEW** utility | transform (span → UI map) | 01-01 | `lib/scoria/workflows/remote_approval_projection.ex` | exact |
| `lib/scoria/observe/telemetry.ex` | **MODIFY** handler | event-driven (telemetry → buffer + broadcast) | 01-01 | self (extend existing hook) | exact |
| `lib/scoria/observe/adapters/req_llm.ex` | **MODIFY** adapter | event-driven (upstream → span stop) | 01-01 | self + `jido.ex` | exact |
| `lib/scoria/observe/adapters/jido.ex` | **MODIFY** adapter | event-driven | 01-01 | `req_llm.ex` | exact |
| `lib/scoria/workflows.ex` | **MODIFY** context | CRUD + dual PubSub | 01-02 | self (`mark_waiting_for_approval/3`, `approve/3`) | exact |
| `lib/scoria/workflows/remote_approval_projection.ex` | **MODIFY** projection | transform (Approval → map) | 01-02 | self (`project_approval/1`) | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | **MODIFY** liveview | event-driven (PubSub consumer) | 01-02/03 | self (hollow handlers today) | exact |
| `lib/scoria_web/components/trace_tree_component.ex` | **MODIFY** component | UI (lazy span tree) | 01-02 | self (depth + assign_async slot) | exact |
| `test/scoria/observe/operator_broadcast_test.exs` | **NEW** unit test | test | 01-01 | `test/scoria/observe/telemetry_test.exs` | role-match |
| `test/scoria/observe/trace_projection_test.exs` | **NEW** unit test | test | 01-01 | `test/scoria/workflows/remote_approval_projection_test.exs` | role-match |
| `test/scoria/observe/telemetry_test.exs` | **EXTEND** unit test | test | 01-01 | self | exact |
| `test/scoria_web/live/orchestrator_live_integration_test.exs` | **NEW** integration test | test (real runtime path) | 01-03 | `test/scoria/runtime_integration_test.exs` | exact |
| `lib/mix/tasks/scoria.test.semantic_fast_path.ex` | **MODIFY** mix task | command-line (lane pin) | 01-03 | self | exact |
| `test/mix/tasks/test.semantic_fast_path_test.exs` | **MODIFY** contract test | test | 01-03 | self | exact |
| `docs/adoption_lanes.md` (fragment) | **MODIFY** docs | documentation | 01-03 | `test/support/scoria/adoption_example.ex` (`doc_fragments/0`) | role-match |

---

## Message Contract (tenant topic)

Topic: `"scoria:runs:{tenant_id}"` — OrchestratorLive already subscribes here.

| Message | Producer | Consumer action |
|---------|----------|-----------------|
| `{:trace_opened, header_map}` | `OperatorBroadcast.span_stopped/1` (first span) | Insert trace into `trace_records` + `stream_insert` |
| `{:trace_span, trace_id, span_view}` | `OperatorBroadcast.span_stopped/1` (each span) | Upsert span; recompute depths via `TraceProjection.with_depths/1` |
| `{:trace_delta, %{trace_id, span_id, chunk}}` | `OperatorBroadcast.span_delta/1` | Per-span token coalesce (best-effort) |
| `{:hitl_request, projection_map}` | `OperatorBroadcast.hitl_request/2` | Hybrid modal / inbox highlight |
| `{:approval_decided, approval_id, status}` | `OperatorBroadcast.approval_decided/3` | Clear `@active_approval` if id matches |
| `{:new_trace, trace_map}` | Test shim only | Map to opened + spans (migration) |

Dual broadcast preserved: run-scoped `scoria:workflow_runs:{run_id}` unchanged for `WorkflowLive.Show`.

---

## Pattern Assignments

### `lib/scoria/observe/operator_broadcast.ex` (NEW — context, PubSub fan-out)

**Analog:** `lib/scoria/workflows.ex` — run-scoped broadcast pattern

**Topic prefix pattern** (`workflows.ex` lines 22–26):

```22:26:lib/scoria/workflows.ex
  @topic_prefix "scoria:workflow_runs:"

  def subscribe_run(run_id) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, @topic_prefix <> run_id)
  end
```

**Broadcast primitive** (`workflows.ex` lines 752–754):

```752:754:lib/scoria/workflows.ex
  defp broadcast(run_id, message) do
    Phoenix.PubSub.broadcast(Scoria.PubSub, @topic_prefix <> run_id, message)
  end
```

**Target shape for OperatorBroadcast:**

```elixir
defmodule Scoria.Observe.OperatorBroadcast do
  @topic_prefix "scoria:runs:"

  def tenant_topic(tenant_id), do: @topic_prefix <> tenant_id

  def broadcast(tenant_id, message) when is_binary(tenant_id) do
    Phoenix.PubSub.broadcast(Scoria.PubSub, tenant_topic(tenant_id), message)
  end

  def span_stopped(redacted_metadata), do: ...
  def span_delta(metadata), do: ...
  def hitl_request(tenant_id, projection), do: broadcast(tenant_id, {:hitl_request, projection})
  def approval_decided(tenant_id, approval_id, status), do: ...
end
```

**Fail-closed tenant guard:** drop broadcast + debug log when `tenant_id` missing from span metadata (D-119). No global `scoria:runs:all` topic.

**Run-scoped consumer precedent** (`workflow_live/show.ex` lines 22–24, 59–62):

```22:24:lib/scoria_web/live/workflow_live/show.ex
    if connected?(socket) do
      Workflows.subscribe_run(run_id)
    end
```

```59:62:lib/scoria_web/live/workflow_live/show.ex
  def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}

  def handle_info({:approval_requested, run_id, _approval_id}, socket),
    do: {:noreply, load_run(socket, run_id)}
```

OrchestratorLive must **never** subscribe to per-run topics (D-115).

---

### `lib/scoria/observe/trace_projection.ex` (NEW — utility, UI-safe span maps)

**Analog:** `lib/scoria/workflows/remote_approval_projection.ex` — curated operator DTO projection

**Projection map pattern** (`remote_approval_projection.ex` lines 39–80):

```39:55:lib/scoria/workflows/remote_approval_projection.ex
  defp project_approval(%Approval{} = approval) do
    baseline_target = baseline_target(approval)

    %{
      id: approval.id,
      workflow_run_id: approval.workflow_run_id,
      step_id: approval.step_id,
      checkpoint_id: approval.checkpoint_id,
      status: approval.status,
      tool_name: approval.tool_name,
      actor_id: approval.actor_id,
      tenant_id: approval.tenant_id,
      session_id: approval.session_id,
      reason: approval.reason,
      trace_id: approval.trace_id,
      blocker_kind: approval.blocker_kind,
```

**Redaction boundary** (`redactor.ex` lines 8–14):

```8:14:lib/scoria/observe/redactor.ex
  def redact(data) do
    config = Application.get_env(:scoria, __MODULE__, [])

    case Keyword.get(config, :mfa) do
      {mod, fun, args} -> apply(mod, fun, [data | args])
      nil -> do_redact(data, build_deny_list(config))
    end
  end
```

**Depth algorithm to port** (`workflow_live/show.ex` lines 314–328) — adapt `parent_step_id` → `parent_id`:

```314:328:lib/scoria_web/live/workflow_live/show.ex
  defp decorate_steps(steps) do
    parent_map = Map.new(steps, &{&1.id, &1})

    Enum.map(steps, fn step ->
      Map.put(step, :depth, depth_for(step, parent_map, 0))
    end)
  end

  defp depth_for(%{parent_step_id: nil}, _parent_map, depth), do: depth

  defp depth_for(step, parent_map, depth) do
    case Map.get(parent_map, step.parent_step_id) do
      nil -> depth
      parent -> depth_for(parent, parent_map, depth + 1)
    end
  end
```

**Target API:**

```elixir
defmodule Scoria.Observe.TraceProjection do
  def span_view(redacted_metadata) :: map  # id, name, span_kind, status_code, parent_id, timing, attributes_preview
  def trace_header(redacted_metadata) :: map  # id, session_id, workflow_run_id, tenant_id
  def with_depths(spans) :: [map]  # adds :depth for TraceTreeComponent
end
```

**Span schema fields** (`repo/span.ex` lines 7–19):

```7:19:lib/scoria/repo/span.ex
  schema "ai_spans" do
    field(:name, :string)
    field(:span_kind, :string)
    field(:status_code, :string)
    field(:start_time, :utc_datetime_usec)
    field(:end_time, :utc_datetime_usec)
    field(:attributes, :map, default: %{})
    field(:parent_id, :binary_id)

    belongs_to(:trace, Scoria.Repo.Trace)
    has_many(:events, Scoria.Repo.SpanEvent)
```

---

### `lib/scoria/observe/telemetry.ex` (MODIFY — insert broadcast before buffer)

**Analog:** self — extend existing handler ordering

**Current hook** (lines 18–21):

```18:21:lib/scoria/observe/telemetry.ex
  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{buffer_name: buffer_name}) do
    redacted_metadata = Redactor.redact(metadata)
    Buffer.cast_span(redacted_metadata, buffer_name)
  end
```

**Target ordering (D-118):**

```elixir
redacted = Redactor.redact(metadata)
OperatorBroadcast.span_stopped(redacted)
Buffer.cast_span(redacted, buffer_name)
```

**Do not hook at Buffer flush** — 5s default latency unacceptable (`buffer.ex` line 6):

```5:6:lib/scoria/observe/buffer.ex
  @default_max_size 1000
  @default_flush_interval 5000
```

**Add delta event** to `@events` or separate attach for `[:scoria, :observe, :span, :delta]` → `OperatorBroadcast.span_delta/1` (D-128).

**Test setup precedent** (`telemetry_test.exs` lines 7–21):

```7:21:test/scoria/observe/telemetry_test.exs
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    {:ok, trace} = Repo.insert(%Trace{id: Ecto.UUID.generate()})
    
    # Start Buffer
    pid = start_supervised!({Buffer, [name: :test_telemetry_buffer, flush_interval: 10, max_size: 5]})
    
    # Attach telemetry
    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(:test_telemetry_buffer)
    
    %{trace: trace, buffer: pid}
  end
```

Extend tests to assert broadcast occurs **before** buffer flush (subscribe to tenant topic in test process).

---

### `lib/scoria/observe/adapters/req_llm.ex` + `jido.ex` (MODIFY — span metadata contract)

**Analog:** self — extend emitted span map with required metadata

**Current ReqLLM span** (lines 11–25) — missing `tenant_id`, `parent_id`, `workflow_run_id`:

```11:25:lib/scoria/observe/adapters/req_llm.ex
  def handle_event([:req_llm, :request, :stop], measurements, metadata, _config) do
    span = %{
      name: "req_llm_request",
      span_kind: "LLM",
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      attributes: %{
        "llm.model_name" => metadata[:model],
        "llm.token_count" => measurements[:total_tokens],
        "req.url" => metadata[:url]
      }
    }
    
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
```

**Target enrichment:**

```elixir
span = %{
  # ... existing fields ...
  tenant_id: metadata[:tenant_id],
  parent_id: metadata[:parent_id],
  workflow_run_id: metadata[:workflow_run_id],
  session_id: metadata[:session_id],
  attributes: Map.merge(base_attrs, %{
    "tenant_id" => metadata[:tenant_id],
    "workflow_run_id" => metadata[:workflow_run_id]
  })
}
```

Persist `tenant_id` in span/trace `attributes` for DB hydrate query (`attributes->>'tenant_id'`).

---

### `lib/scoria/workflows.ex` (MODIFY — HITL tenant fan-out + multi-operator guards)

**Analog:** self — extend success paths after existing run-scoped broadcast

**HITL fan-out insertion point** (`workflows.ex` lines 415–419):

```415:419:lib/scoria/workflows.ex
    |> case do
      {:ok, {run, approval, audit_outbox_event}} ->
        SRE.emit_audit_outbox_telemetry(audit_outbox_event)
        broadcast(run.id, {:approval_requested, run.id, approval.id})
        {:ok, approval}
```

**After line 418, add:**

```elixir
projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
OperatorBroadcast.hitl_request(approval.tenant_id, projection)
```

**Approve success path** (lines 630–687) — add `not_pending` guard before update; broadcast `approval_decided` on success:

```630:645:lib/scoria/workflows.ex
  def approve(approval_id, status, attrs) when status in ["approved", "rejected", "expired"] do
    attrs = Map.new(attrs)

    Repo.transaction(fn repo ->
      approval = repo.get!(Approval, approval_id)
      audit_context = approval_decision_context(repo, approval, attrs)

      update_attrs =
        attrs
        |> Map.drop([:actor_id, "actor_id", :tenant_id, "tenant_id", :session_id, "session_id"])
        |> Map.put(:status, status)

      updated_approval =
        approval
        |> Approval.changeset(update_attrs)
        |> repo.update!()
```

Add guard: `if approval.status != "pending", do: repo.rollback(:not_pending)` before changeset. On `{:ok, updated_approval}`, call `OperatorBroadcast.approval_decided/3`.

---

### `lib/scoria/workflows/remote_approval_projection.ex` (MODIFY — `arguments_preview`, `connector_label`)

**Analog:** self — extend `project_approval/1` map

**Current projection** (lines 39–80) — no `arguments_preview`:

```39:55:lib/scoria/workflows/remote_approval_projection.ex
  defp project_approval(%Approval{} = approval) do
    baseline_target = baseline_target(approval)

    %{
      id: approval.id,
      workflow_run_id: approval.workflow_run_id,
      ...
      blocker_kind: approval.blocker_kind,
```

**Target additions (D-121, D-123):**

```elixir
arguments_preview: preview_arguments(approval.arguments),
connector_label: approval.connector_label,
```

Use `Scoria.Observe.Redactor.redact/1` on arguments before capping for DOM. Inbox rows and modal share this map — never render raw `arguments`.

**Argument extraction precedent** (lines 113–117):

```113:117:lib/scoria/workflows/remote_approval_projection.ex
  defp argument_value(arguments, key) when is_map(arguments) do
    Map.get(arguments, key, Map.get(arguments, String.to_existing_atom(key), nil))
  rescue
    ArgumentError -> Map.get(arguments, key)
  end
```

---

### `lib/scoria_web/live/orchestrator_live.ex` (MODIFY — delta handlers, hydrate, hybrid modal)

**Analog:** self — extend hollow PubSub handlers; mirror token coalesce for per-span buffers

**Subscribe on connect** (lines 33–38):

```33:38:lib/scoria_web/live/orchestrator_live.ex
  def mount(params, session, socket) do
    tenant_id = session["tenant_id"] || "default"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
      Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
```

**Session contract (D-130):** host must set `session["tenant_id"]` and `session["actor_id"]` — matches `approval_decision_attrs/2` (lines 816–824).

**Hollow trace handler** (lines 74–81) — replace/extend with incremental deltas:

```74:81:lib/scoria_web/live/orchestrator_live.ex
  def handle_info({:new_trace, trace}, socket) do
    socket =
      socket
      |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace.id, trace))
      |> stream_insert(:traces, trace)

    {:noreply, socket}
  end
```

**Add handlers:**

```elixir
def handle_info({:trace_opened, header}, socket), do: ...  # idempotent: skip if trace in trace_records
def handle_info({:trace_span, trace_id, span_view}, socket), do: ...  # upsert span, TraceProjection.with_depths/1
def handle_info({:trace_delta, delta}, socket), do: ...  # per-span_id coalesce
def handle_info({:approval_decided, approval_id, _status}, socket), do: ...  # clear @active_approval if match
```

**HITL handler** (lines 109–114) — extend for hybrid UX (D-124):

```109:114:lib/scoria_web/live/orchestrator_live.ex
  def handle_info({:hitl_request, approval}, socket) do
    {:noreply,
     socket
     |> assign(:active_approval, approval)
     |> load_operator_surface()}
  end
```

Only set `@active_approval` (push modal) when nil OR approval matches `@runtime_query`; otherwise inbox-only highlight.

**Token coalesce to refactor** (lines 83–107) — replace global `@token_text` with per-`span_id` buffers, 75ms via `config :scoria, :live_token_coalesce_ms, 75`:

```83:107:lib/scoria_web/live/orchestrator_live.ex
  def handle_info({:token, token}, socket) do
    new_buffer = [token | socket.assigns.token_buffer]
    ...
  end

  def handle_info(:flush_tokens, socket) do
    new_chunk = socket.assigns.token_buffer |> Enum.reverse() |> Enum.join("")
    socket =
      socket
      |> assign(token_text: socket.assigns.token_text <> new_chunk)
```

Remove global `#token-stream` strip (line 212).

**Approval modal** (lines 370–387) — extend with reason, `arguments_preview`, connector badge, workflow link, dismiss ("Decide later"):

```370:387:lib/scoria_web/live/orchestrator_live.ex
      <%= if @active_approval do %>
        <div id="approval-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div class="bg-white p-6 rounded shadow-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Approval Required</h2>
            <p class="mb-2"><strong>Tool:</strong> <%= @active_approval.tool_name %></p>
            ...
```

**Workflow-owned HITL guard** (lines 802–803):

```802:803:lib/scoria_web/live/orchestrator_live.ex
  defp maybe_resume_approval(socket, _approval, status) when status != "approved",
    do: {:ok, socket}
```

**DB hydrate on connect (D-119):** after subscribe, query recent traces/spans for `tenant_id` (limit 25, configurable), seed `:traces` stream. Trace schema has no `tenant_id` column — filter via attributes:

```7:11:lib/scoria/repo/trace.ex
  schema "ai_traces" do
    field(:session_id, :string)
    field(:attributes, :map, default: %{})

    has_many(:spans, Scoria.Repo.Span)
```

**Pending approval hydrate** already on mount via `load_operator_surface/1` (lines 870–903):

```870:903:lib/scoria_web/live/orchestrator_live.ex
  defp load_operator_surface(socket) do
    tenant_id = socket.assigns.tenant_id
    ...
    socket
    |> assign(:approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}))
    |> assign(:connector_fleet, connector_fleet(tenant_id))
    |> assign(:runtimes, runtimes)
  end
```

Reconnect test (D-131): `render_disconnect` → trigger approval → `render_reconnect` → modal from pending list on mount.

**Trace tree render** (lines 289–291):

```289:291:lib/scoria_web/live/orchestrator_live.ex
        <div id="traces-list" phx-update="stream" class="space-y-4">
          <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
            <.live_component module={ScoriaWeb.TraceTreeComponent} id={"tree-#{id}"} spans={trace.spans} />
```

Pass per-span token preview assign to TraceTreeComponent.

---

### `lib/scoria_web/components/trace_tree_component.ex` (MODIFY — per-span token slot)

**Analog:** self — depth CSS grid + lazy metadata slot

**Depth rendering** (lines 27–38):

```27:38:lib/scoria_web/components/trace_tree_component.ex
      <%= for span <- @spans do %>
        <div 
          class="trace-row pl-[calc(var(--indent-level)*1.5rem)] flex flex-col py-1 border-b"
          style={"--indent-level: #{Map.get(span, :depth, 0)}"}
        >
          <div 
            class="trace-span-name font-mono text-sm cursor-pointer hover:bg-gray-100 p-1"
            phx-click="load_metadata" 
            phx-value-span_id={Map.get(span, :id, span.name)} 
            phx-target={@myself}
          >
            <%= span.name %>
```

**Add:** coalesced token preview on active LLM span row only; hide/freeze when span completes (D-127). Accept `token_previews: %{span_id => text}` assign from parent.

---

### `test/scoria_web/live/orchestrator_live_integration_test.exs` (NEW — ORCH-LIVE-01 proof)

**Analog:** `test/scoria/runtime_integration_test.exs` — real runtime, dedicated Endpoint, `eventually/1`

**Endpoint + session pattern** (lines 1–26, 67–71):

```1:26:test/scoria/runtime_integration_test.exs
defmodule Scoria.RuntimeIntegrationTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end
```

**Runtime → LiveView test** (lines 159–176):

```159:176:test/scoria/runtime_integration_test.exs
  test "operator-visible workflow page stays aligned with the public runtime contract" do
    {:ok, started} =
      Scoria.start_run(
        %{actor_id: "live-actor", tenant_id: "live-tenant", session_id: "live-session"},
        root_role_id: "executor",
        initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "actor_id" => "operator-integration",
        "tenant_id" => "tenant-integration"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, Scoria.RuntimeIntegrationTest.Endpoint)

    {:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))
```

**Critical difference for integration test:** mount `/scoria` (orchestrator), **session `tenant_id` must match runtime tenant**, use `eventually/1` on DOM — **no `send(view.pid, ...)`**.

**Contrast with unit tier** (`orchestrator_live_test.exs` lines 99–101, 301):

```99:101:test/scoria_web/live/orchestrator_live_test.exs
    # Send a dummy trace message simulating PubSub broadcast
    trace = %{id: "trace-123", spans: [%{id: "span-1", name: "llm_call", depth: 0}]}
    send(view.pid, {:new_trace, trace})
```

```301:301:test/scoria_web/live/orchestrator_live_test.exs
    send(view.pid, {:hitl_request, approval})
```

**Setup requirements:**

```elixir
use Scoria.IntegrationCase
# Start Telemetry + Buffer (mirror telemetry_test.exs)
# Start dedicated Endpoint with session keys
# Scoria.start_run with matching tenant_id
# eventually(fn -> render(view) =~ "span_name" end)
# eventually(fn -> render(view) =~ "Approval Required" end)
```

**Reconnect test (D-131):**

```elixir
html = render_disconnect(view)
# trigger real approval via Runtime
{:ok, view, html} = render_reconnect(view)
assert html =~ "Approval Required"
```

---

### `test/scoria/observe/operator_broadcast_test.exs` + `trace_projection_test.exs` (NEW — unit)

**Analog:** `test/scoria/observe/telemetry_test.exs` (PubSub subscribe in test process) + `test/scoria/workflows/remote_approval_projection_test.exs` (projection shape assertions)

**Eventually helper** (`eventually.ex` lines 17–35):

```17:35:test/support/scoria/eventually.ex
  def eventually(fun, opts \\ []) when is_function(fun, 0) do
    timeout_ms = Keyword.get(opts, :timeout_ms, env_timeout_ms())
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)
    message = Keyword.get(opts, :message)

    case poll(fun, timeout_ms, interval_ms, nil) do
      {:ok, result} ->
        result

      {:error, last} ->
        detail =
          case last do
            nil -> "last observed value: nil"
            other -> "last observed value: #{inspect(other)}"
          end

        base = message || "condition not met before timeout (#{timeout_ms}ms)"
        flunk("#{base}\n#{detail}")
    end
  end
```

**OperatorBroadcast tests:** assert drop when `tenant_id` nil; assert `{:trace_opened, _}` + `{:trace_span, _, _}` message shapes.

**TraceProjection tests:** redaction of deny-list keys; `with_depths/1` parent walk; `attributes_preview` cap.

---

### `lib/mix/tasks/scoria.test.semantic_fast_path.ex` + contract test (MODIFY — lane pin)

**Analog:** self — append to `@semantic_fast_path_test_files`

**Current list** (lines 7–16):

```7:16:lib/mix/tasks/scoria.test.semantic_fast_path.ex
  @semantic_fast_path_test_files [
    "test/scoria/runtime/semantic_fast_path_test.exs",
    "test/scoria/semantic_cache/lookup_test.exs",
    "test/scoria/semantic_cache/invalidation_test.exs",
    "test/scoria_web/live/orchestrator_live_test.exs",
    "test/scoria_web/components/runtime_detail_drawer_component_test.exs",
    "test/scoria_web/components/semantic_evidence_notebook_component_test.exs",
    "test/scoria_web/live/workflow_live_test.exs",
    "test/mix/tasks/test.semantic_fast_path_test.exs"
  ]
```

**Add:** `"test/scoria_web/live/orchestrator_live_integration_test.exs"`  
**Update:** `test/mix/tasks/test.semantic_fast_path_test.exs` `expected_files` to match.

**Do not widen** `VerificationLanes.closeout_order/0` (D-129).

---

### `docs/adoption_lanes.md` (MODIFY — session contract fragment)

**Analog:** `test/support/scoria/adoption_example.ex` — doc fragment pattern for host identity keys

**Existing identity doc pattern** (`adoption_example.ex` lines 29–31):

```29:31:test/support/scoria/adoption_example.ex
      "actor_id: conn.assigns.current_user.id",
      "tenant_id: conn.assigns.current_account.id",
      "session_id: get_session(conn, :assistant_session_id)",
```

**Add fragment (D-130):** before mounting `/scoria`, host apps must set `session["tenant_id"]` and `session["actor_id"]` so PubSub scoping and audit refs match runtime identity. `mix scoria.install` unchanged (auth-agnostic).

Suggested placement: under "Operator surfaces" in default runtime lane section of `docs/adoption_lanes.md`.

---

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| *(none)* | — | All 16 artifacts have close analogs in the codebase |

---

## Implementation Ordering (suggested waves)

| Wave | Files | Gate command |
|------|-------|--------------|
| **01-01** | `operator_broadcast.ex`, `trace_projection.ex`, `telemetry.ex`, adapters, observe unit tests | `mix test test/scoria/observe/operator_broadcast_test.exs test/scoria/observe/trace_projection_test.exs test/scoria/observe/telemetry_test.exs` |
| **01-02** | `workflows.ex`, `remote_approval_projection.ex`, `orchestrator_live.ex`, `trace_tree_component.ex` | `mix test test/scoria_web/live/orchestrator_live_test.exs` |
| **01-03** | integration test, semantic lane pin, adoption doc fragment | `mix test test/scoria_web/live/orchestrator_live_integration_test.exs` then `mix test.semantic_fast_path --warnings-as-errors` |

---

## Locked Principles (do not re-litigate)

1. **Redact → broadcast → buffer** — never broadcast before `Redactor.redact/1`
2. **Dual broadcast** — run-scoped for WorkflowLive; tenant-scoped for OrchestratorLive
3. **Idempotent merge** — upsert spans by `span.id`; ignore duplicate `trace_opened`
4. **Workflow-owned HITL** — UI never calls `Resume.resume_run/1` before successful `approve/3`
5. **Fail closed** — missing `tenant_id` → drop broadcast, debug log
6. **Integration proof** — new test without `send/2`; keep existing tests as UI unit tier

---

## PATTERN MAPPING COMPLETE

**Output:** `/Users/jon/projects/scoria/.planning/phases/01-orchestrator-live-wiring-runtime-pubsub-trace-broadcast-and-/01-PATTERNS.md`

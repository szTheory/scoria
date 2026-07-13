# Phase 53: Structured Child Spans + Write-Time Bound - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 14 (new + modified)
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/application.ex` | config (OTP supervision) | event-driven | itself — `maybe_reconciler/0` shape (same file, lines 29-31) | exact |
| `lib/scoria/observe.ex` (extend: `span/4`, `with_tool/3`, `with_prompt/3`, `with_guardrail/3`) | service (facade) | request-response / event-driven | itself — `emit_retriever_span/1`/`emit_prompt_span/1` (lines 68-178) | exact |
| `lib/scoria/observe/bounds.ex` (NEW) | middleware (choke point) | transform | `lib/scoria/observe/redactor.ex` (deny-list transform over a map) + `lib/scoria/observe/span_kind.ex` (`normalize/2` fallback+telemetry pattern) | role-match (composite) |
| `lib/scoria/observe/guardrail.ex` (NEW) | service (span builder/emitter) | event-driven | `lib/scoria/observe.ex` `emit_retriever_span/1` (span-map-build-then-emit shape) | exact |
| `lib/scoria/observe/adapters/mcp.ex` (NEW) | middleware (telemetry adapter) | event-driven | `lib/scoria/observe/adapters/req_llm.ex` (telemetry handler → span map → emit) | exact |
| `lib/scoria/observe/semconv.ex` (extend: `attribute_registry/0`, `vendor_key_prefixes/0`, guardrail keys/enums, `error_attributes/1`) | utility (key registry owner) | transform | itself — `retrieval_config_keys/0`/`host_declared_keys/0`/`merge_host_declared/2` (lines 39-94) | exact |
| `lib/scoria/observe/telemetry.ex` (extend: insert `Bounds.enforce/2`) | middleware (telemetry handler) | event-driven | itself — `handle_event/4` (lines 60-66) | exact |
| `lib/scoria/observe/reviewer_broadcast.ex` (unchanged, referenced) | service (PubSub fan-out) | pub-sub | n/a — read-only reference for `tenant_id` fail-closed contract | exact |
| `lib/scoria/observe/trace_projection.ex` (extend: `tree_order/1`, cycle-guarded `depth_for/3`) | utility (projection) | transform | itself — `with_depths/1`/`depth_for/3` (lines 47-63) | exact |
| `lib/scoria_web/components/trace_tree_component.ex` (extend: consume `--indent-level`, status-error overlay, guardrail badge) | component (LiveComponent) | request-response (SSR render) | `lib/scoria_web/components/workflow_tree_component.ex` (sibling component, already correct) | exact |
| `lib/scoria/runtime.ex` (extend: G1 guardrail emit after `create_run`) | controller (lifecycle orchestration) | request-response | `lib/scoria/runtime/release_gate.ex` (the gate being wrapped) | role-match |
| `lib/scoria/workflows/runtime.ex` (extend: step-level parent span, trace_id threading, G2/G3/G4) | controller (workflow step executor) | event-driven | `lib/scoria/mcp/executor.ex` (telemetry-emitting orchestration around a policy/budget gate) | role-match |
| `test/scoria/observe/bounds_test.exs` (NEW) | test | transform | `test/scoria/observe/redactor_test.exs` (deny-list unit test shape) + `test/scoria/observe/prompt_span_test.exs` (real-Postgres acceptance shape) | role-match (composite) |
| `test/scoria/observe/guardrail_test.exs`, `span_test.exs`, `adapters/mcp_test.exs` (NEW) | test | event-driven | `test/scoria/observe/prompt_span_test.exs` (real-Postgres, scoped-Buffer, `Telemetry.attach/1` pattern) | exact |
| `test/scoria_web/components/trace_tree_component_test.exs` (REWRITE) | test | request-response | itself (existing file — must be rewritten, currently locks in the flat-DOM bug) | exact |

## Pattern Assignments

### `lib/scoria/application.ex` (config, OTP supervision wiring)

**Analog:** itself, `maybe_reconciler/0` (lines 29-31)

**Existing shape to mirror** (lines 1-41, full file read):
```elixir
defmodule Scoria.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Scoria.Repo,
        Scoria.Vault,
        {Oban, Application.fetch_env!(:scoria, Oban)},
        {Phoenix.PubSub, name: Scoria.PubSub},
        ScoriaWeb.Presence,
        {Registry, keys: :unique, name: Scoria.MCP.SessionRegistry},
        {Task.Supervisor, name: Scoria.MCP.TaskSupervisor},
        {Task.Supervisor, name: Scoria.Workflow.TaskSupervisor},
        Scoria.SRE.Relay
      ] ++ maybe_reconciler() ++ dev_children()

    opts = [strategy: :one_for_one, name: Scoria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_reconciler do
    if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
  end

  defp dev_children do
    Application.get_env(:scoria, :dev_children, [])
  end
end
```
**Pattern to copy:** add a `maybe_observe_buffer/0` private helper folded into the `++` children list exactly like `maybe_reconciler/0`, but gated on `config :scoria, Scoria.Observe, enabled: false` (an explicit opt-out config key, NOT `Mix.env()`  — Buffer must boot in `:prod` too, unlike Reconciler). Call `Scoria.Observe.Telemetry.attach()` from inside the helper (or `start/2` directly) before returning the children list. Must tolerate `{:error, :already_exists}` from `:telemetry.attach_many/4` (match-and-ignore, don't crash boot) so tests that `:telemetry.detach/1` + re-attach onto a scoped buffer (see `prompt_span_test.exs` pattern below) remain unaffected.

---

### `lib/scoria/observe.ex` (extend: `span/4` + kind wrappers)

**Analog:** itself, `emit_retriever_span/1` / `emit_prompt_span/1` (lines 68-178)

**Span-map-build-then-emit shape to mirror** (lines 69-92, 172-178):
```elixir
def emit_retriever_span(opts) when is_map(opts) do
  # ... build attributes via Semconv merges ...
  span = %{
    name: "knowledge.retrieve",
    span_kind: SpanKind.normalize("retriever"),
    status_code: "OK",
    start_time: opts[:started_wall] || DateTime.utc_now(),
    end_time: DateTime.utc_now(),
    trace_id: opts[:trace_id],
    id: opts[:span_id],
    parent_id: opts[:parent_id],
    attributes: attributes
  }
  emit_span(span)
end

defp emit_span(span) do
  :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  :ok
rescue
  _ -> :ok
end
```
**Pattern to copy:** `span/4`'s emit-once-per-outcome-branch discipline follows this exact `try/rescue -> :ok` wrapping shape around `:telemetry.execute/3`; `emit_retriever_span/1`/`emit_prompt_span/1` refactor onto `span/4` with unchanged signatures (D-01c) — extract the shared attribute-building lines into one private builder both call. Own-id semantics: `id: opts[:span_id]` (fresh, own id — never a caller's existing id), `parent_id: opts[:parent_id]` (explicit only, D-02a). D-01e requires every span dict here also set `tenant_id` top-level (this module currently omits it — new code must add `tenant_id: opts[:tenant_id]` to the span map or spans stay invisible per D-00c).

---

### `lib/scoria/observe/bounds.ex` (NEW — closed key registry + write-time bound)

**Analog 1 (deny-list-over-map recursion shape):** `lib/scoria/observe/redactor.ex` (full file, 55 lines)
```elixir
defp do_redact(map, deny_list) when is_map(map) and not is_struct(map) do
  Map.new(map, fn {k, v} ->
    if MapSet.member?(deny_list, k) do
      {k, "[REDACTED]"}
    else
      {k, do_redact(v, deny_list)}
    end
  end)
end

defp do_redact(list, deny_list) when is_list(list) do
  Enum.map(list, &do_redact(&1, deny_list))
end

defp do_redact(other, _deny_list), do: other
```
**Pattern to copy:** the recursive `Map.new/2` + list-map + fall-through-clause shape for walking an arbitrary metadata map is the base traversal `Bounds.enforce/2` needs (depth-aware version, capped at `max_depth: 5`). `Bounds` is a sibling module in the same directory, NOT inside `Redactor` — D-06a is explicit this must not live in `redactor.ex` (adopter-removable via its `:mfa` config hook).

**Analog 2 (unrecognized-value fallback + telemetry pattern):** `lib/scoria/observe/span_kind.ex` `normalize/2` (lines 55-75)
```elixir
def normalize(value, default \\ "agent") do
  normalized = value |> to_string() |> String.downcase()

  if normalized in @kinds do
    normalized
  else
    Logger.warning("Unrecognized span_kind #{inspect(value)}, defaulting to #{default}")

    try do
      :telemetry.execute([:scoria, :observe, :span_kind, :fallback], %{}, %{
        value: value,
        default: default
      })
    rescue
      _ -> :ok
    end

    default
  end
end
```
**Pattern to copy:** this is the exact shape D-06f's `[:scoria, :observe, :bounds, :exceeded]` telemetry + `Logger.warning` should mirror — a closed-list membership check, log on the negative branch, defensively-wrapped telemetry emit, deterministic fallback value. Reuse for both the registry-miss path and the non-map fail-closed path (D-06h).

**Analog 3 (once-per-key ETS dedupe for the log-storm control, D-06f):** `lib/scoria/observe/reviewer_broadcast.ex` (lines 25, 93-106)
```elixir
@trace_seen_table :scoria_observe_reviewer_broadcast_trace_seen

defp first_span_for_trace?(trace_id) do
  ensure_trace_seen_table()
  :ets.insert_new(@trace_seen_table, {trace_id, true})
end

defp ensure_trace_seen_table do
  case :ets.whereis(@trace_seen_table) do
    :undefined -> :ets.new(@trace_seen_table, [:named_table, :set, :public, read_concurrency: true])
    _table -> :ok
  end
end
```
**Pattern to copy:** `:ets.insert_new/2` as the atomic "have I logged this key before" check, `:ets.whereis/1`-guarded lazy table creation. `Bounds`'s once-per-distinct-key-per-node dedupe should use this exact `insert_new` idiom against a `:scoria_observe_bounds_warned_keys` named table.

**Insertion point (verified):** `lib/scoria/observe/telemetry.ex` lines 60-66 — `Bounds.enforce/2` goes between `Redactor.redact/1` and both `ReviewerBroadcast.span_stopped/1` + `Buffer.cast_span/2`. A `:drop` result must short-circuit both.

---

### `lib/scoria/observe/guardrail.ex` (NEW — guardrail span builder/emitter)

**Analog:** `lib/scoria/observe.ex` `emit_retriever_span/1` (span-map-build pattern, lines 68-92) composed with `lib/scoria/observe/semconv.ex`'s key-registry-owner pattern (below) and `lib/scoria/runtime/release_gate.ex`'s existing atom vocabulary (lines 20-93 — `:unapproved_draft`, `:eval_not_passing`, `:eval_required` are the exact atoms `@guardrail_reason_codes` closes over).

**Existing ReleaseGate vocabulary to reuse verbatim** (lines 20, 29, 82):
```elixir
def check(%PromptTemplate{status: "draft"}), do: {:error, :unapproved_draft}
# ...
if Verdict.blocks_release?(verdict) do
  {:error, {:eval_not_passing, verdict}}
# ...
if Application.get_env(:scoria, :require_eval_verdict, false) do
  {:error, :eval_required}
```
**Pattern to copy:** `Guardrail.emit/1` builds a GUARDRAIL-kind span via the same map shape as `emit_retriever_span/1`, sourcing `scoria.guardrail.reason_code` from these exact atoms (do not invent new ones — D-05f explicitly says "we are not inventing the enum, we are refusing to widen it"). Per D-05e, `status_code` stays `"OK"` even on a `block` decision — never derive `status_code` from the guardrail decision. Per D-05d, a `:ok` (not-applicable) result from `ReleaseGate.check/1` emits NO span at all.

---

### `lib/scoria/observe/adapters/mcp.ex` (NEW — MCP 4-event tool lifecycle → child spans)

**Analog:** `lib/scoria/observe/adapters/req_llm.ex` (full file, 61 lines) — the closest existing "telemetry handler → project metadata → build span map → emit" adapter.

**Full pattern to copy** (lines 1-60):
```elixir
defmodule Scoria.Observe.Adapters.ReqLLM do
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  def attach do
    :telemetry.attach_many(
      "scoria-observe-reqllm",
      [[:req_llm, :request, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:req_llm, :request, :stop], _measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    base_attributes =
      %{"tenant_id" => tenant_id, "workflow_run_id" => workflow_run_id}
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    span_kind = SpanKind.normalize(metadata[:span_kind] || "llm")

    attributes =
      base_attributes
      |> Semconv.merge_req_llm_attributes(metadata)
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))
      |> Semconv.merge_host_declared(metadata)

    span = %{
      name: "req_llm_request",
      span_kind: span_kind,
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      parent_id: metadata[:parent_id],
      tenant_id: tenant_id,
      workflow_run_id: workflow_run_id,
      session_id: metadata[:session_id],
      attributes: attributes
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end
```
**Pattern to copy:** `attach/0` with `:telemetry.attach_many/4` against a unique handler id (`"scoria-observe-mcp"`), a `handle_event/4` clause per event name. `Adapters.MCP` needs THREE clauses (or a shared private builder) for `[:scoria, :tool, :started/:completed/:timeout/:failed]` (source events verified in `lib/scoria/mcp/executor.ex` lines 194, 51, 57, 63, 69) → duration+status span. D-04b: project ONLY `tool_ref`, `tool_name`, `status`, `duration_ms`, `args_fingerprint` — never merge `metadata.args` wholesale the way `executor.ex:37` does internally. `args_fingerprint`-never-`args` precedent: `lib/scoria/sre/audit_outbox_event.ex:32` has an `args_fingerprint` column and no `args` column; `executor.ex:228` already computes `Integer.to_string(:erlang.phash2({tool_module, args}))` as `"tool_hash"` under `reserve_budget/3` — same fingerprint idea, reuse `:erlang.phash2/1`.

**Source events to consume (verified, `lib/scoria/mcp/executor.ex`):**
```elixir
# line 194 (inside execute_tool/5):
:telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)
# line 51 (completed):
:telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
# line 57 (timeout):
:telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
# lines 63, 69 (failed / breaker_open, both emit :failed with a raw :reason):
:telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
```

---

### `lib/scoria/observe/semconv.ex` (extend: `attribute_registry/0`, guardrail keys/enums, `error_attributes/1`)

**Analog:** itself — `retrieval_config_keys/0` + `host_declared_keys/0` + `merge_host_declared/2` (lines 39-94)

**Exact keyword-list-of-keys + reduce-merge pattern to mirror:**
```elixir
@retrieval_config_keys [
  embedding_model: "scoria.retrieval.embedding_model",
  index_version: "scoria.retrieval.index_version",
  reranker: "scoria.retrieval.reranker"
]

@host_declared_keys ~w(feature route archetype intent)a

@spec merge_host_declared(map(), map()) :: map()
def merge_host_declared(attributes, metadata) do
  Enum.reduce(@host_declared_keys, attributes, fn key, acc ->
    case Map.get(metadata, key) do
      nil -> acc
      value -> Map.put(acc, Atom.to_string(key), value)
    end
  end)
end
```
**Pattern to copy:** `@guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)`, `@guardrail_decisions ~w(allow block escalate)`, `@guardrail_reason_codes ~w(unapproved_draft eval_not_passing eval_required approval_required budget_rejected breaker_open)` follow the exact `~w(...)a` compile-time-constant-list style already used for `@host_declared_keys` and `SpanKind.@kinds` — NOT `Ecto.Enum` (mirrors D-14's rejection reasoning in `span_kind.ex`'s moduledoc). `attribute_registry/0` returns a flat `%{key => class}` map, structurally similar to how `@retrieval_config_keys` is a flat keyword list — no nested/dynamic key generation.

---

### `lib/scoria/observe/telemetry.ex` (extend: insert `Bounds.enforce/2`)

**Analog:** itself, `handle_event/4` (lines 60-66)

**Exact insertion point (verified):**
```elixir
def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  redacted = Redactor.redact(metadata)
  # NEW: Bounds.enforce/2 goes HERE.
  ReviewerBroadcast.span_stopped(redacted)
  Buffer.cast_span(buffer_span(redacted), buffer_name)
end
```
**Pattern to copy:** the `case Bounds.enforce(redacted, :span) do {:ok, bounded} -> ...two calls...; :drop -> :ok end` branch replaces the two-call sequence above. `@span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a` (line 68) is the existing whitelist `buffer_span/1` (line 70-72) already applies via `Map.take/2` — Bounds only touches the `attributes` sub-map's key space, it does not change this top-level whitelist.

---

### `lib/scoria/observe/trace_projection.ex` (extend: `tree_order/1`, cycle-guarded `depth_for/3`)

**Analog:** itself, `with_depths/1` / `depth_for/3` (lines 47-63) — the function being extended IS the analog.

**Current unguarded recursion (verified, will infinite-loop on a cycle once `parent_id` is populated):**
```elixir
def with_depths(spans) when is_list(spans) do
  parent_map = Map.new(spans, &{&1.id, &1})
  Enum.map(spans, fn span -> Map.put(span, :depth, depth_for(span, parent_map, 0)) end)
end

defp depth_for(%{parent_id: nil}, _parent_map, depth), do: depth
defp depth_for(%{parent_id: parent_id}, _parent_map, depth) when is_nil(parent_id), do: depth

defp depth_for(span, parent_map, depth) do
  case Map.get(parent_map, span.parent_id) do
    nil -> depth
    parent -> depth_for(parent, parent_map, depth + 1)
  end
end
```
**Pattern to copy:** add a `visited` `MapSet` accumulator threaded through the recursion (return current `depth` if `span.id` already in `visited`, or once `depth` exceeds a hard cap e.g. 100) — same private-function-per-branch style already used here. Required test: `with_depths([%{id: "a", parent_id: "a"}])` terminates.

---

### `lib/scoria_web/components/trace_tree_component.ex` (extend: consume `--indent-level`, status-error overlay, guardrail badge)

**Analog:** `lib/scoria_web/components/workflow_tree_component.ex` (full file, 43 lines) — sibling component, already correctly consumes `--indent-level`.

**Current bug (verified, `trace_tree_component.ex:36`):**
```heex
style={"--indent-level: #{Map.get(span, :depth, 0)}"}
```
**Working fix already shipped one file over (`workflow_tree_component.ex:23`):**
```heex
style={"--indent-level: #{Map.get(step, :depth, 0)}; padding-left: calc(0.75rem + var(--indent-level) * 1.25rem)"}
```
**Pattern to copy:** inline the identical `padding-left: calc(0.75rem + var(--indent-level) * 1.25rem)` onto `trace_tree_component.ex`'s row div's `style` attribute (or add the equivalent rule to `.scoria-span` in `assets/css/04-components.css` — either satisfies D-07a). For the status-error overlay (D-07b), `.scoria-span--status-error` already exists in `assets/css/04-components.css:1100-1104`; apply the class conditionally when `String.upcase(status_code) == "ERROR"` plus a `.sr-only` "Errored" label — mirror how `workflow_tree_component.ex:26` conditionally applies `<.badge tone={tone(step.status)} label={status_label(step.status)} dot={false} .../>` for status-driven affordances. For the guardrail badge (D-07e), mirror `workflow_tree_component.ex:29-31`'s conditional badge-span pattern:
```heex
<span :if={step.kind == "handoff"} class="workflow-handoff-marker scoria-badge scoria-badge--trace scoria-badge--bare">
  handoff
</span>
```
and the `ReviewCopy.severity_label/1` enum→copy pattern for translating `scoria.guardrail.decision` into operator microcopy (never the raw `reason_code`).

---

### `lib/scoria/runtime.ex` (extend: G1 guardrail emit after `create_run`)

**Analog:** `lib/scoria/runtime/release_gate.ex` (the gate itself, full file, 95 lines) + `lib/scoria/observe.ex`'s emit-after-effect style.

**Current call site (verified, lines 34-38):**
```elixir
def start_run(identity, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start(identity, opts),
       :ok <- Scoria.Runtime.ReleaseGate.check(workflow_attrs) do
    case Scoria.Workflows.Runtime.prepare_semantic_fast_path(workflow_attrs) do
      {:hit, prepared_attrs, entry} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs), ...
      {:continue, prepared_attrs} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs), ...
```
**Pattern to copy:** `ReleaseGate.check/1`'s existing atom vocabulary (`:unapproved_draft`, `{:eval_not_passing, verdict}`, `:eval_required`, and the bare `:ok` no-op fall-throughs at `check(_), do: :ok`) is the exact reason-code source for `Guardrail.emit/1`. D-03d requires restructuring so the emit happens AFTER `create_run` succeeds (using `run.id` as `trace_id`, `parent_id: nil`) — on a blocked gate (no run created), emit with a freshly-minted `trace_id`, `parent_id: nil`.

---

### `lib/scoria/workflows/runtime.ex` (extend: step-level parent span, trace_id threading, G2/G3/G4)

**Analog:** `lib/scoria/mcp/executor.ex` — closest existing "orchestration wrapping a policy/budget gate with telemetry at every outcome branch" shape (verified lines 186-296 for `execute_step/2`'s multi-branch `case` on outcome).

**Existing multi-branch telemetry-per-outcome shape to mirror** (`execute_step/2`, verified):
```elixir
case replay_execution(run, step, handler, timeout, opts, breaker_context) do
  {:ok, {:completed, result, duration_ms}} ->
    reconcile_budget(reservation_context, budget_context, normalized_result, "completed")
    emit_runtime_telemetry(step, run, budget_context, "completed", duration_ms, normalized_result)
    Workflows.complete_step(step.id, ...)

  {:ok, {:waiting_for_approval, approval_attrs, duration_ms}} ->
    reconcile_budget(reservation_context, budget_context, %{}, "waiting_for_approval")
    emit_runtime_telemetry(step, run, budget_context, "waiting_for_approval", duration_ms, %{})
    Workflows.mark_waiting_for_approval(run.id, step.id, Map.new(approval_attrs))
  # ... etc per outcome
end
```
**Pattern to copy:** this is the G2 call site (`{:waiting_for_approval, ...}` branch, verified at line 186) where `Guardrail.emit/1` (decision: `"escalate"`) belongs, following the same "one telemetry/side-effect call per outcome branch" discipline already established by `emit_runtime_telemetry/5`. The step-level parent span (D-03c) wraps the whole `execute_step/2` body via `span/4`, threading `trace_id` (D-03b) into `handler`/telemetry metadata so `req_llm.ex`/`jido.ex` adapters pick it up instead of `metadata[:trace_id] || Ecto.UUID.generate()`'s random fallback.

---

## Shared Patterns

### Telemetry emit wrapped `try/rescue -> :ok`
**Source:** `lib/scoria/observe.ex` lines 172-177 (`emit_span/1`), `lib/scoria/observe/span_kind.ex` lines 63-71 (`normalize/2`'s telemetry emit)
**Apply to:** `span/4`'s per-branch emit, `Guardrail.emit/1`, `Bounds`'s exceeded-telemetry emit — every NEW telemetry-emitting call site in this phase.
```elixir
defp emit_span(span) do
  :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  :ok
rescue
  _ -> :ok
end
```

### `tenant_id`-fail-closed broadcast (read-only, do not modify)
**Source:** `lib/scoria/observe/reviewer_broadcast.ex` lines 33-52
**Apply to:** every new span producer (`Guardrail.emit/1`, `Adapters.MCP`, `span/4` callers) MUST populate `tenant_id` top-level in the span map they emit, or `ReviewerBroadcast.span_stopped/1` silently drops the broadcast (`:dropped` return, `Logger.debug`).
```elixir
def span_stopped(metadata) when is_map(metadata) do
  case Map.get(metadata, :tenant_id) do
    tenant_id when is_binary(tenant_id) and tenant_id != "" ->
      # ... broadcasts trace_opened + trace_span ...
    _ ->
      Logger.debug("ReviewerBroadcast.span_stopped/1 dropped: missing tenant_id")
      :dropped
  end
end
```

### Closed compile-time-constant enum lists (`~w(...)a`), never `Ecto.Enum`
**Source:** `lib/scoria/observe/span_kind.ex` line 24 (`@kinds`), `lib/scoria/observe/semconv.ex` line 67 (`@host_declared_keys`)
**Apply to:** `Semconv.@guardrail_names`, `@guardrail_decisions`, `@guardrail_reason_codes`, and `Bounds.@attribute_registry`'s key-class enum.

### Real-Postgres acceptance test scaffold (scoped Buffer + explicit `Telemetry.attach/1`)
**Source:** `test/scoria/observe/prompt_span_test.exs` lines 29-52
**Apply to:** `bounds_test.exs`, `guardrail_test.exs`, `span_test.exs`, `adapters/mcp_test.exs` — every new drift-guard/acceptance test in this phase (D-ATTR01-6 discipline: never hand-synthesize a telemetry event as production evidence).
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

  buffer_name = :"prompt_span_test_buffer_#{System.unique_integer([:positive])}"

  pid =
    start_supervised!(
      Supervisor.child_spec(
        {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
        id: buffer_name
      )
    )

  :telemetry.detach("scoria-observe-telemetry")
  Scoria.Observe.Telemetry.attach(buffer_name)

  on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

  %{buffer: buffer_name, buffer_pid: pid}
end

defp emit_and_flush(opts, buffer_name) do
  trace_id = opts[:trace_id] || Ecto.UUID.generate()
  span_id = opts[:span_id] || Ecto.UUID.generate()

  :ok = opts |> Map.merge(%{trace_id: trace_id, span_id: span_id}) |> Observe.emit_prompt_span()
  :ok = Buffer.flush_now(buffer_name)

  Repo.get_by!(Span, id: span_id)
end
```

### Never-text recursive assertion helper (for the SEC-01 regression test)
**Source:** `test/scoria/observe/prompt_span_test.exs` lines 150-171 (`assert_never_text/1`)
**Apply to:** `bounds_test.exs`'s registry-canary + leaf-assertion tests, generalizing this exact recursive-walk-and-regex-guard shape (per D-06b's INV-SEC01: "every `:structured` key's builder output is leaf-asserted").
```elixir
@never_text_key_regex ~r/text|content|body|message|prompt|raw/i

defp assert_never_text(value) when is_map(value) do
  for {k, v} <- value do
    refute k =~ @never_text_key_regex, "forbidden key #{inspect(k)} matched the never-text guard"
    assert_never_text(v)
  end
end

defp assert_never_text(value) when is_list(value), do: Enum.each(value, &assert_never_text/1)
defp assert_never_text(value) when is_binary(value), do: assert byte_size(value) > 0
defp assert_never_text(value) when is_integer(value), do: assert value >= 0
```

## No Analog Found

None — all 14 classified files/lanes have a strong existing analog in the codebase (exact or role-match). This phase is explicitly additive-onto-existing-seams (per RESEARCH.md's Runtime State Inventory: "no existing stored data, live service config... this phase changes"), which is why analog coverage is complete.

## Metadata

**Analog search scope:** `lib/scoria/observe/`, `lib/scoria/observe/adapters/`, `lib/scoria/runtime.ex`, `lib/scoria/runtime/release_gate.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria_web/components/`, `lib/scoria/application.ex`, `test/scoria/observe/`
**Files scanned:** application.ex, observe.ex, telemetry.ex, semconv.ex, redactor.ex, span_kind.ex, buffer.ex, reviewer_broadcast.ex, trace_projection.ex, mcp/executor.ex, adapters/req_llm.ex, runtime.ex, runtime/release_gate.ex, workflows/runtime.ex (partial), trace_tree_component.ex, workflow_tree_component.ex, prompt_span_test.exs
**Pattern extraction date:** 2026-07-12

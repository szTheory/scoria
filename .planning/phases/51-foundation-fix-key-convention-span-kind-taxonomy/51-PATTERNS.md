# Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 9 (2 new, 7 modified)
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|-----------------|---------------|
| `lib/scoria/observe/span_kind.ex` (NEW) | utility (taxonomy module) | transform | `lib/scoria/observe/circuit_breaker.ex` (plain module, no behaviour, pure functions + constants) | role-match |
| `lib/scoria/observe/semconv.ex` (NEW) | utility (key-constant/delegation module) | transform | `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` (delegate target) + `lib/scoria/observe/circuit_breaker.ex` (in-repo plain-module shape) | role-match |
| `lib/scoria/observe/buffer.ex` (MODIFY) | service (GenServer, batch flush) | batch / event-driven | itself (extend existing opts-driven `init/1` + `flush_spans/1`) | exact |
| `lib/scoria/observe/telemetry.ex` (MODIFY) | service (telemetry router/wrapper) | event-driven | itself (extend existing `emit_span_delta/1` wrapper convention) | exact |
| `lib/scoria/observe/adapters/req_llm.ex` (MODIFY) | middleware (telemetry adapter) | transform / event-driven | itself + `lib/scoria/observe/adapters/jido.ex` (sibling adapter, identical shape) | exact |
| `lib/scoria/observe/adapters/jido.ex` (MODIFY) | middleware (telemetry adapter) | transform / event-driven | `lib/scoria/observe/adapters/req_llm.ex` (sibling adapter, identical shape) | exact |
| `lib/scoria_web/components/workflow_tree_component.ex` (MODIFY) | component (Phoenix.Component) | request-response (render) | `lib/scoria_web/components/trace_tree_component.ex` (sibling span-rendering component) | role-match |
| `lib/scoria_web/components/trace_tree_component.ex` (MODIFY) | component (Phoenix.LiveComponent) | request-response (render) | `lib/scoria_web/components/workflow_tree_component.ex` (sibling span-rendering component) | role-match |
| `assets/css/04-components.css` (MODIFY, ~1066-1091) | config (CSS design tokens) | transform (rename selector) | itself (existing `.scoria-span--*` rail block) | exact |

## Pattern Assignments

### `lib/scoria/observe/span_kind.ex` (NEW — utility/transform)

**Analog:** `lib/scoria/observe/circuit_breaker.ex` (plain `defmodule`, no behaviour, module-attribute constants + pure functions, `require Logger`/`:telemetry.execute` convention borrowed from `buffer.ex`/`telemetry.ex`)

**Module shape pattern** (`lib/scoria/observe/circuit_breaker.ex:1-12`):
```elixir
defmodule Scoria.Observe.CircuitBreaker do
  @table :scoria_circuit_breakers

  def init_table do
    ...
  end
```
— i.e. a flat module with a `@constant`, public pure functions, no GenServer/behaviour. `SpanKind` should follow this exact shape: `@kinds`, `@openinference_map`, `kinds/0`, `kind?/1`, `normalize/2`, `to_openinference/1`.

**Telemetry-emit-on-fallback pattern** — borrow the `:telemetry.execute/3` call convention already used at the write seam in both adapters:
`lib/scoria/observe/adapters/req_llm.ex:39`:
```elixir
:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
```
Use the same 3-arg shape for the new fallback event (`[:scoria, :observe, :span_kind, :fallback]`, per RESEARCH.md Pattern 2 / Open Question 3 — event name is not user-locked, treat as a naming decision).

**Logger convention** — mirror `lib/scoria/observe/buffer.ex:3,38`:
```elixir
require Logger
...
Logger.warning("Scoria.Observe.Buffer is full (#{state.max_size}), dropping span.")
```
`SpanKind.normalize/2`'s fallback path should `Logger.warning` in this same terse, interpolated-string style (not a struct/keyword log) to match existing project convention in this exact subsystem.

**Current drifted whitelists to replace (source-of-truth for the exact 9→8 diff):**
- `lib/scoria_web/components/workflow_tree_component.ex:38-44`:
```elixir
defp span_kind(kind) when kind in ~w(llm tool prompt mcp retriever guardrail eval agent),
  do: kind

defp span_kind("approval"), do: "guardrail"
defp span_kind("handoff"), do: "agent"
defp span_kind("answer"), do: "llm"
defp span_kind(_), do: "agent"
```
- `lib/scoria_web/components/trace_tree_component.ex:86-95`:
```elixir
defp span_kind(span) do
  span
  |> Map.get(:span_kind, Map.get(span, "span_kind", "agent"))
  |> to_string()
  |> String.downcase()
  |> case do
    kind when kind in ~w(agent llm prompt tool mcp retriever guardrail eval error) -> kind
    _ -> "agent"
  end
end
```
Note the `trace_tree` list still contains the stale `error` kind (9 entries) — this is the literal proof of D-12's "remove `error` from the whitelist" fix and the anti-inline-guard test target (D-15 item 4).

---

### `lib/scoria/observe/semconv.ex` (NEW — utility/transform, delegates)

**Analog (delegation target, read-only reference):** `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` — `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1`. Do not copy these functions' internals; call them. Full key set already enumerated in RESEARCH.md "Code Examples" (lines 459-526 of that file) — reuse verbatim, do not re-derive.

**In-repo shape analog:** same flat-module-with-constants pattern as `circuit_breaker.ex` above — one `@openinference_span_kind_key "openinference.span.kind"` constant + accessor function, plus one `merge_req_llm_attributes/2` function per RESEARCH.md Pattern 3 (already a fully-formed code example — copy verbatim, it is not illustrative pseudocode):
```elixir
defmodule Scoria.Observe.Semconv do
  @openinference_span_kind_key "openinference.span.kind"

  def openinference_span_kind_key, do: @openinference_span_kind_key

  def merge_req_llm_attributes(attributes, metadata) do
    attributes
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.start(metadata))
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.terminal(metadata))
  end
end
```

---

### `lib/scoria/observe/buffer.ex` (MODIFY — service/batch)

**Analog:** itself — full current file is 81 lines (`lib/scoria/observe/buffer.ex:1-81`), extend the existing conventions rather than rewriting from scratch.

**Opts-driven init pattern to extend** (`lib/scoria/observe/buffer.ex:20-33`):
```elixir
def init(opts) do
  Process.flag(:trap_exit, true)

  state = %{
    spans: [],
    max_size: Keyword.get(opts, :max_size, @default_max_size),
    flush_interval: Keyword.get(opts, :flush_interval, @default_flush_interval),
    timer: nil
  }

  state = schedule_flush(state)
  {:ok, state}
end
```
Add `on_flush_error: Keyword.get(opts, :on_flush_error, :log)` to this same map the same way `max_size`/`flush_interval` are threaded (D-07).

**Current silent-rescue anti-pattern being replaced** (`lib/scoria/observe/buffer.ex:64-81`):
```elixir
defp flush_spans([]), do: :ok
defp flush_spans(spans) do
  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

  entries = Enum.map(spans, fn span ->
    span
    |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
    |> Map.put_new(:inserted_at, now)
    |> Map.put_new(:updated_at, now)
  end)

  try do
    Scoria.Repo.insert_all(Scoria.Repo.Span, entries)
  rescue
    e ->
      Logger.error("Failed to flush spans: #{inspect(e)}")
  end
end
```
Replace with the `Ecto.Multi` shape given verbatim in RESEARCH.md "Architecture Patterns → Pattern 1" (trace-upsert `insert_all` + span `insert_all` in one `Multi`, `try/rescue` around `Repo.transaction(multi)` in addition to `{:error, ...}` matching — see Pitfall 3 in RESEARCH.md for why both are needed). Existing `Ecto.Multi` project precedent (not read this pass, cited by RESEARCH.md as already-idiomatic): `lib/scoria/workflows/batch_enqueue.ex`, `lib/scoria/knowledge.ex`.

**Callback structure to preserve** — `handle_info(:flush, state)` (`lib/scoria/observe/buffer.ex:45-51`) and `terminate/2` (`lib/scoria/observe/buffer.ex:53-56`) already exist as separate code paths; D-09(i) requires only `handle_info(:flush, ...)` to ever honor `:raise` — `terminate/2`'s call to `flush_spans/1` must always take the `:log`-equivalent path regardless of `state.on_flush_error`. Add `handle_call(:flush_now, _from, state)` as a new clause beside the existing `handle_cast`/`handle_info` clauses (`lib/scoria/observe/buffer.ex:35-51`).

**Existing test scaffolding to extend** (per RESEARCH.md, `test/scoria/observe/buffer_test.exs`):
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  pid = start_supervised!({Buffer, [name: :test_buffer, flush_interval: 10, max_size: 5, on_flush_error: :raise]})
  %{buffer_pid: pid}
end
```
Note: existing setup pre-inserts a `%Trace{}` row manually before testing span flush — new tests must add a variant that omits this pre-insert to prove auto-upsert (RESEARCH.md line 551).

---

### `lib/scoria/observe/telemetry.ex` (MODIFY — service/event-driven)

**Analog:** itself — full current file is 59 lines (`lib/scoria/observe/telemetry.ex:1-59`).

**Existing wrapper convention to mirror exactly** (`lib/scoria/observe/telemetry.ex:20-29`):
```elixir
@doc """
Emits a span delta telemetry event for streaming token chunks.

Future ReqLLM streaming adapters should call this instead of raw
`:telemetry.execute/3`. Integration tests must use this for delta proof
(not raw `:telemetry.execute` on `[:scoria, :observe, :span, :delta]`).
"""
def emit_span_delta(metadata) when is_map(metadata) do
  :telemetry.execute([:scoria, :observe, :span, :delta], %{}, metadata)
end
```
Add `emit_flush_error/1` in this exact style (doc comment stating "tests must use this wrapper, not raw `:telemetry.execute`" + a guard clause), per D-06's contract: event `[:scoria, :observe, :buffer, :flush_error]`, measurements `%{dropped_count: n, system_time: ...}`, metadata `%{error: e, kind: :error, stacktrace: ..., buffer: name, max_size: ...}`.

**`@events` list to extend** (`lib/scoria/observe/telemetry.ex:6-9`) — the `flush_error` event is emitted from `Buffer` directly (not routed through `Telemetry.handle_event/4`'s attach list), so no change needed here unless the planner wants `Telemetry` to also *attach* to it for logging/broadcast — RESEARCH.md's architecture diagram treats `emit_flush_error/1` as a pure emit-wrapper, not a new `handle_event/4` clause.

---

### `lib/scoria/observe/adapters/req_llm.ex` (MODIFY — middleware/transform)

**Analog:** itself (full file, 41 lines) + sibling `jido.ex` for the shared span-map-building idiom.

**Full current file** (`lib/scoria/observe/adapters/req_llm.ex:1-41`) — the entire attribute-building + span-map block to be replaced:
```elixir
attributes =
  %{
    "llm.model_name" => metadata[:model],
    "llm.token_count" => measurements[:total_tokens],
    "req.url" => metadata[:url],
    "tenant_id" => tenant_id,
    "workflow_run_id" => workflow_run_id
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()

span = %{
  name: "req_llm_request",
  span_kind: "LLM",
  ...
}
```
Replace `attributes` construction with `Semconv.merge_req_llm_attributes(%{"tenant_id" => tenant_id, "workflow_run_id" => workflow_run_id} |> reject_nils(), metadata)` (drop `llm.model_name`/`llm.token_count`/`req.url` per D-01/COMPAT-01 — exact old→new key mapping table is in RESEARCH.md "Code Examples → CHANGELOG Old→New Key Mapping Table"). Replace `span_kind: "LLM"` literal with `span_kind: SpanKind.normalize(metadata[:operation] || "llm")` and add `attributes["openinference.span.kind"] => SpanKind.to_openinference(...)` via `Semconv.openinference_span_kind_key/0` (never hardcode the string).

**Known second bug to fix incidentally** (RESEARCH.md Pitfall 1): `metadata[:model]` at line 17 is a raw `%LLMDB.Model{}` struct in production, not a string — calling `ReqLLM.OpenTelemetry.Attributes.start/1` (which internally extracts `.id`) fixes this for free; do not re-introduce a raw `metadata[:model]` literal anywhere in the rewritten adapter.

---

### `lib/scoria/observe/adapters/jido.ex` (MODIFY — middleware/transform)

**Analog:** `lib/scoria/observe/adapters/req_llm.ex` (identical sibling shape — same `attach/0` + `handle_event/4` + attribute-map + span-map structure).

**Full current file** (`lib/scoria/observe/adapters/jido.ex:1-41`) — only the `span_kind` line changes per D-13:
```elixir
span = %{
  name: "jido_action",
  span_kind: "INTERNAL",   # <- replace this line
  ...
}
```
becomes:
```elixir
span_kind: SpanKind.normalize(metadata[:span_kind] || "tool"),
```
No `gen_ai.*`/`Semconv` merge needed here (Jido spans are not LLM-model spans) — only the `SpanKind.normalize/2` + `to_openinference/1` mirror wiring applies, matching req_llm.ex's `openinference.span.kind` mirror pattern.

---

### `lib/scoria_web/components/workflow_tree_component.ex` (MODIFY — component/render)

**Analog:** `lib/scoria_web/components/trace_tree_component.ex` (sibling component, same span-rail CSS-class convention: `"scoria-span--#{span_kind(...)}"`).

**Current inline whitelist to remove** (`lib/scoria_web/components/workflow_tree_component.ex:37-44`):
```elixir
# Map a step kind to a trace span-kind for the colored rail (brand book §8.8).
defp span_kind(kind) when kind in ~w(llm tool prompt mcp retriever guardrail eval agent),
  do: kind

defp span_kind("approval"), do: "guardrail"
defp span_kind("handoff"), do: "agent"
defp span_kind("answer"), do: "llm"
defp span_kind(_), do: "agent"
```
Per RESEARCH.md's explicit note (line 102 of CONTEXT.md code_context): this component's input (`step.kind`) is a **different data source** — workflow-step vocabulary (`approval`/`handoff`/`answer`), not a stored `ai_spans.span_kind` value. Keep the step-vocab→native-kind mapping clauses (`"approval"→"guardrail"`, `"handoff"→"agent"`, `"answer"→"llm"`), but route the final fallback/validation through `Scoria.Observe.SpanKind.normalize/2` instead of the inline `~w(...)` guard, e.g.:
```elixir
defp span_kind("approval"), do: "guardrail"
defp span_kind("handoff"), do: "agent"
defp span_kind("answer"), do: "llm"
defp span_kind(kind), do: Scoria.Observe.SpanKind.normalize(kind)
```

---

### `lib/scoria_web/components/trace_tree_component.ex` (MODIFY — component/render)

**Analog:** `lib/scoria_web/components/workflow_tree_component.ex` (sibling).

**Current inline whitelist to remove** (`lib/scoria_web/components/trace_tree_component.ex:86-95`):
```elixir
defp span_kind(span) do
  span
  |> Map.get(:span_kind, Map.get(span, "span_kind", "agent"))
  |> to_string()
  |> String.downcase()
  |> case do
    kind when kind in ~w(agent llm prompt tool mcp retriever guardrail eval error) -> kind
    _ -> "agent"
  end
end
```
This one reads the real `ai_spans.span_kind` value directly — replace the whole `case`/downcase chain with a direct delegate:
```elixir
defp span_kind(span) do
  span
  |> Map.get(:span_kind, Map.get(span, "span_kind"))
  |> Scoria.Observe.SpanKind.normalize()
end
```
This also fixes D-12 (drops the stale `error` kind entry) and D-15's anti-inline-guard target for this file.

---

### `assets/css/04-components.css` (MODIFY — config/CSS)

**Analog:** itself — existing rail block (`assets/css/04-components.css:1066-1091`):
```css
.scoria-span--agent .scoria-span__rail { background: var(--scoria-span-agent); }
.scoria-span--llm .scoria-span__rail { background: var(--scoria-span-llm); }
.scoria-span--prompt .scoria-span__rail { background: var(--scoria-span-prompt); }
.scoria-span--tool .scoria-span__rail { background: var(--scoria-span-tool); }
.scoria-span--mcp .scoria-span__rail { background: var(--scoria-span-mcp); }
.scoria-span--retriever .scoria-span__rail { background: var(--scoria-span-retriever); }
.scoria-span--guardrail .scoria-span__rail { background: var(--scoria-span-guardrail); }
.scoria-span--eval .scoria-span__rail { background: var(--scoria-span-eval); }
.scoria-span--error .scoria-span__rail { background: var(--scoria-span-error); }
.scoria-span--redacted .scoria-span__rail { background: var(--scoria-span-redacted); }
```
Per D-12: rename `.scoria-span--error` → `.scoria-span--status-error`, and change its semantics from a rail-color swap to a status **overlay** (left-border + icon, not color-only, per WCAG). The 8 kind rails (`agent`/`llm`/`prompt`/`tool`/`mcp`/`retriever`/`guardrail`/`eval`) stay unchanged and are exactly the D-15 item-3 CSS-coherence assertion target (`scoria-span--#{k}` must exist for every `k` in `SpanKind.kinds()`). `.scoria-span--redacted` stays as its own orthogonal class, unaffected.

---

## Shared Patterns

### Plain-module-with-constants (no GenServer/behaviour)
**Source:** `lib/scoria/observe/circuit_breaker.ex:1-12`
**Apply to:** `span_kind.ex`, `semconv.ex` (both NEW files)
```elixir
defmodule Scoria.Observe.CircuitBreaker do
  @table :scoria_circuit_breakers

  def init_table do
    ...
  end
```

### Telemetry-wrapper-not-raw-execute convention
**Source:** `lib/scoria/observe/telemetry.ex:20-29` (`emit_span_delta/1`)
**Apply to:** `Telemetry.emit_flush_error/1` (new), and by extension `SpanKind.normalize/2`'s fallback emit (same discipline, different module)
```elixir
def emit_span_delta(metadata) when is_map(metadata) do
  :telemetry.execute([:scoria, :observe, :span, :delta], %{}, metadata)
end
```

### Adapter attribute-map-then-span-map shape
**Source:** `lib/scoria/observe/adapters/req_llm.ex:11-40` and `lib/scoria/observe/adapters/jido.ex:11-40` (identical structure — build `attributes` map, reject nils, build `span` map, `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`)
**Apply to:** Both adapter modifications — preserve this exact two-step structure, only change what populates `attributes` and `span_kind`.

### Silent-rescue → structured Logger.error + telemetry event
**Source:** `lib/scoria/observe/buffer.ex:74-80` (current anti-pattern being fixed) + RESEARCH.md Pattern 1 (target code, given verbatim, copy from there)
**Apply to:** `Buffer.flush_spans/1` (or its `Ecto.Multi` replacement).

## No Analog Found

None — all 9 files have a role-match or exact analog in the existing codebase (this phase is "wiring existing correct machinery together," per RESEARCH.md's own framing, not greenfield design).

## Metadata

**Analog search scope:** `lib/scoria/observe/**`, `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex`, `assets/css/04-components.css`, `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` (reference only, not an in-repo analog)
**Files scanned:** 9 target files + 3 analog-only reads (`circuit_breaker.ex`, `span.ex` schema, CSS block)
**Pattern extraction date:** 2026-07-12

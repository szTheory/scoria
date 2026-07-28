# Phase 55: Content Trust & Taint Substrate - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 12 new + 6 modified
**Analogs found:** 12 / 12 (all have at least a role-match; 1 — `Trust.Tiered` protocol — has no in-repo protocol precedent, cites idiomatic-Elixir shape instead)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/trust.ex` | utility (leaf vocab) | transform (fail-closed read/normalize) | `lib/scoria/observe/semconv.ex` (`normalize_reason_code/1`, `guardrail_reason_codes/0`) | exact |
| `lib/scoria/trust/tiered.ex` | utility (protocol) | transform | none in-repo (first protocol) — idiomatic Elixir `defprotocol`/`defimpl` shape | no-analog |
| `lib/scoria/trust/scanner.ex` | service (behaviour + NoOp impl) | request-response | `lib/scoria/orchestrator.ex` (`req_llm_module` config-swap idiom) + any existing `@behaviour`/`@callback` module | role-match |
| `lib/scoria/trust/scan.ex` | service (orchestration) | event-driven (bounded Task, fail-closed) | `lib/scoria/mcp/executor.ex` (`BreakerRegistry.run/2` + Task/timeout branch, `reconcile_budget`/`emit_sre_telemetry` error isolation) | role-match |
| `lib/scoria/trust/verdict.ex` | model (struct) | transform | `lib/scoria/knowledge/chunk.ex` / any `@enforce_keys` struct | role-match |
| `lib/scoria/mcp/envelope.ex` | model (struct + accessors) | transform | `lib/scoria/knowledge/source.ex` (`@enforce_keys`-style schema struct) + `MCP.Executor` success branch it wraps | role-match |
| `lib/scoria/spotlight.ex` | service (host-called pure fn) | transform | `lib/scoria/orchestrator.ex` (host-called library entry point, no owned state) | role-match |
| `lib/scoria/spotlight/marked.ex` | model (struct) | transform | `lib/scoria/knowledge/chunk.ex` (plain struct/schema shape) | role-match |
| `lib/scoria/knowledge/chunk.ex` (modify: add `defimpl Trust.Tiered`) | model | CRUD | — (self) | exact |
| `lib/scoria/knowledge/source.ex` (modify: trust storage convention) | model | CRUD | — (self) | exact |
| `lib/scoria/knowledge.ex` (modify: `ingest_source/2`, `reembed_source/2`, `reindex_source/2`, `retrieve/2`, new `create_source/2` trust opt, new `set_source_trust/3`) | service | CRUD | — (self); `set_source_trust/3` bulk-update mirrors `Multi.delete_all` tenant-scoped `where` at `knowledge.ex:70-75` | exact |
| `lib/scoria/mcp/executor.ex` (modify: wrap success branch, `actual_units` head, replay-stub wrap) | controller/service | request-response | — (self) | exact |
| `lib/scoria/observe/semconv.ex` (modify: `attribute_registry/0` + `trust_attributes/1` + `spotlight_attributes/1`) | config/utility | transform | — (self); mirrors `@guardrail_keys`/`guardrail_attributes/1` pair | exact |
| `lib/scoria/application.ex` (modify: add `Scoria.Trust.TaskSupervisor`) | config | — | — (self); mirrors existing `{Task.Supervisor, name: Scoria.MCP.TaskSupervisor}` line | exact |

## Pattern Assignments

### `lib/scoria/trust.ex` (leaf vocab, transform)

**Analog:** `lib/scoria/observe/semconv.ex` (`normalize_reason_code/1`, lines 436-455) and `@guardrail_reason_codes` (lines 300-315)

**Fail-closed normalize pattern** (`semconv.ex:436-455`):
```elixir
@spec normalize_reason_code(term()) :: String.t()
def normalize_reason_code(value) do
  normalized = to_string(value)

  if normalized in @guardrail_reason_codes do
    normalized
  else
    Logger.warning("Unrecognized guardrail reason_code #{inspect(value)}, defaulting to \"unknown\"")

    try do
      :telemetry.execute([:scoria, :observe, :guardrail, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    "unknown"
  end
end
```

**Apply to `Scoria.Trust`:** D-03 wants TWO branches (silent-absent vs logged-junk), not one — do not literally copy the single-branch shape. Use:
```elixir
def tier(metadata) when is_map(metadata) do
  case Map.get(metadata, @tier_key) do
    nil -> default_tier()                 # SILENT — absent key, D-03
    "trusted" -> "trusted"
    "untrusted" -> "untrusted"
    junk -> fallback(junk)                 # LOGGED + telemetry, D-03
  end
end
```
The `try/rescue -> :ok` around `:telemetry.execute/3` and the `Logger.warning` call format are copied verbatim in shape; only the telemetry event name changes to `[:scoria, :trust, :fallback]`.

**Closed-enum module attribute pattern** (`semconv.ex:300-315`, `@guardrail_reason_codes`):
```elixir
@guardrail_reason_codes ~w(
  unapproved_draft
  eval_not_passing
  ...
)
```
Mirror for `@tiers ~w(trusted untrusted)`, and separately (in `Scoria.Trust.Scanner`/`.Verdict` normalization) the reason_code enum `~w(prompt_injection moderation_flag untrusted_source scanner_error scanner_timeout unknown)` (D-21).

---

### `lib/scoria/trust/tiered.ex` (protocol) + impls in `Chunk`/`Envelope`

**No in-repo analog** (`grep -rn "defprotocol\|defimpl" lib/` returns zero matches — this is the first protocol in the codebase, confirmed in RESEARCH.md). Use idiomatic Elixir protocol shape:
```elixir
defprotocol Scoria.Trust.Tiered do
  @spec tier(t) :: String.t()
  def tier(item)
end

# lib/scoria/knowledge/chunk.ex — impl block added to the OWNING module
defimpl Scoria.Trust.Tiered, for: Scoria.Knowledge.Chunk do
  def tier(%Scoria.Knowledge.Chunk{metadata: metadata}), do: Scoria.Trust.tier(metadata)
end

# lib/scoria/mcp/envelope.ex — same pattern
defimpl Scoria.Trust.Tiered, for: Scoria.MCP.Envelope do
  def tier(%Scoria.MCP.Envelope{tier: tier}), do: Scoria.Trust.normalize_tier(tier)
end
```
This is per D-23/RESEARCH.md's Pattern 3 — keeps `Scoria.Trust` a leaf; `impl` blocks live in `Chunk`/`Envelope`, never in `Trust` itself, avoiding a `Knowledge↔Trust`/`MCP↔Trust` compile cycle.

---

### `lib/scoria/trust/scanner.ex` (behaviour + `NoOp`)

**Analog for config-swap registration:** `lib/scoria/orchestrator.ex:21`
```elixir
{req_llm_module, options} = Keyword.pop(options, :req_llm_module, Application.get_env(:scoria, :req_llm_module, ReqLLM))
```
**Apply per D-17, with container-type care (RESEARCH.md flags this):**
- `Knowledge.retrieve/2` — `opts` is a **keyword list** (matches existing `Keyword.get(opts, :retriever)`/`Keyword.get(opts, :embedder, Embedder.Deterministic)` at `knowledge.ex:248-252`) → `Keyword.get(opts, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))`.
- `MCP.Executor` — `context` is a **map** throughout (`Map.get(context, ...)` used pervasively, e.g. `build_replay_seam/2` above) → `Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))`. Do NOT copy `Keyword.pop` literally into the executor.

**Behaviour shape:** no existing `@behaviour`/`@callback` pair was found via a full-codebase read pass in this session's read set; use standard Elixir behaviour idiom:
```elixir
defmodule Scoria.Trust.Scanner do
  @callback scan(content :: binary() | map(), context :: map()) ::
              {:ok, Scoria.Trust.Verdict.t()} | {:ok, :not_scanned} | {:error, term()}
end

defmodule Scoria.Trust.Scanner.NoOp do
  @behaviour Scoria.Trust.Scanner
  @impl true
  def scan(_content, _context), do: {:ok, :not_scanned}
end
```
Cf. `lib/scoria/mcp/tool.ex:26` — `@callback execute/2 :: {:ok, any()} | {:error, any()}` — confirms this is the codebase's existing behaviour-declaration style (2-arity callback returning a tagged tuple).

---

### `lib/scoria/trust/scan.ex` (orchestration — bounded Task, fail-closed, monotonic law)

**Analog:** `lib/scoria/mcp/executor.ex` success/error branches (lines ~40-55) — the `BreakerRegistry.run/2` + timeout/error isolation discipline:
```elixir
case BreakerRegistry.run(breaker_context, fn ->
       execute_tool(tool_module, args, access_context, timeout, metadata)
     end) do
  {:ok, {:completed, result, duration}} ->
    reconcile_budget(execution_context, access_context, result, "completed")
    emit_sre_telemetry(tool_module, access_context, "completed", duration, result)
    :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
    result

  {:error, {:timeout, duration}} ->
    reconcile_budget(execution_context, access_context, %{}, "timeout")
    ...
```
**Apply to `Scoria.Trust.Scan`:** wrap the host scanner call in a `Task.Supervisor.async_nolink/2` (or similar) on a **dedicated** `Scoria.Trust.TaskSupervisor` (see application.ex section below — do NOT reuse `Scoria.MCP.TaskSupervisor`, that creates a `Knowledge → MCP` dependency per RESEARCH.md Pitfall 3), `Task.yield/2` with a bounded timeout, and convert any `raise`/`throw`/`exit`/`{:error, _}`/timeout into `%Verdict{tier: "untrusted", reason_code: :scanner_error | :scanner_timeout}` (D-20). Then apply the monotonic law (D-19):
```elixir
# RESEARCH.md code example, Monotonic taint resolution (D-19)
defp most_restrictive(a, b) do
  order = %{"untrusted" => 0, "trusted" => 1}
  if Map.fetch!(order, a) <= Map.fetch!(order, b), do: a, else: b
end
```

**Error-isolation-wrapped telemetry pattern** (copy the `try/rescue -> :ok` shape used throughout `semconv.ex` and observe modules) applies to any telemetry emitted from `Scan`.

---

### `lib/scoria/trust/verdict.ex` (struct, `@enforce_keys [:tier]`)

**Analog:** any Ecto-schema-adjacent plain struct in the codebase with required fields — closest shape is `lib/scoria/knowledge/source.ex`'s `@type t :: %__MODULE__{}` declaration plus `validate_required/2` discipline (Ecto-side enforcement) translated to a plain-struct `@enforce_keys`:
```elixir
defmodule Scoria.Trust.Verdict do
  @enforce_keys [:tier]
  defstruct [:tier, :score, :reason_code, :scanner]

  @type t :: %__MODULE__{
          tier: String.t(),
          score: float() | nil,
          reason_code: atom() | nil,
          scanner: module() | nil
        }
end
```
**Reminder (RESEARCH.md anti-pattern):** `score` is host-only — never thread it into `step.result_envelope["scoria.taint"]` or any span attribute.

---

### `lib/scoria/mcp/envelope.ex` (struct + total accessors, `@enforce_keys [:value, :tier]`)

**Analog for struct shape:** `lib/scoria/knowledge/source.ex` (plain schema struct with `@enforce_keys`-equivalent `validate_required/2`). **Analog for the wrap choke point:** `lib/scoria/mcp/executor.ex` success branch (lines ~46-53):
```elixir
case BreakerRegistry.run(breaker_context, fn ->
       execute_tool(tool_module, args, access_context, timeout, metadata)
     end) do
  {:ok, {:completed, result, duration}} ->
    reconcile_budget(execution_context, access_context, result, "completed")
    emit_sre_telemetry(tool_module, access_context, "completed", duration, result)
    :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
    result
```
**CRITICAL nested-shape note (verified this session, not in CONTEXT.md):** `result` at `executor.ex:48` is itself `{:ok, value} | {:error, reason}` per `Tool.execute/2`'s `@callback` contract (`mcp/tool.ex:26`) — because `execute_tool/5`'s `Task.yield` wraps the tool's full return in `{:completed, result, duration}` without unwrapping. So the wrap edit must be:
```elixir
{:ok, {:completed, result, duration}} ->
  reconcile_budget(execution_context, access_context, result, "completed")
  emit_sre_telemetry(tool_module, access_context, "completed", duration, result)
  :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)

  case result do
    {:ok, value} ->
      wrapped = maybe_wrap_envelope(value, tier: ..., provenance: ...)
      {:ok, wrapped}
    {:error, _} = error ->
      error
  end
```
NOT `Envelope.wrap(result, ...)` directly — that double-nests (`%Envelope{value: {:ok, actual_value}}`).

**`actual_units/3` defense-in-depth head** — analog `executor.ex:278-289`:
```elixir
defp actual_units(_context, _result, outcome) when outcome in ["timeout", "execution_failed"], do: 0
defp actual_units(context, {:ok, result}, outcome), do: actual_units(context, result, outcome)
defp actual_units(context, result, _outcome) do
  cond do
    is_map(result) && Map.has_key?(result, :actual_units) -> Map.fetch!(result, :actual_units)
    ...
    true -> estimated_units(context)
  end
end
```
Add a new head `defp actual_units(context, %Envelope{value: v}, outcome), do: actual_units(context, v, outcome)` placed BEFORE the generic `is_map(result)` clause (order matters — a struct won't match `Map.has_key?/2` cleanly against `:actual_units` semantics the way a plain map does).

**Replay-stub parity (D-10)** — analog `executor.ex` replay_gate historical-stub block:
```elixir
{:historical_stub, evidence} ->
  record_replay_audit(context, tool_module, evidence, "tool.replay.stubbed")
  {:ok, %{status: :historical_stub, replay_disposition: :historical_stub,
          replay_reason_code: evidence.replay_reason_code,
          result: Map.get(source_evidence, :result) || Map.get(source_evidence, "result")}}
```
Wrap the `result:` field's value the same way, under the same flag check, so live and replay shapes match.

---

### `lib/scoria/spotlight.ex` + `lib/scoria/spotlight/marked.ex`

**Analog:** `lib/scoria/orchestrator.ex` — a stateless, host-called library entry point taking data in, returning data out, with no owned persistence:
```elixir
defmodule Scoria.Orchestrator do
  def generate_text(model, prompt, options \\ []) do
    execute(:generate_text, model, [model, prompt], options)
  end
end
```
Mirror the "public function takes data + opts, delegates to a private `execute`/`render` helper" shape for `Scoria.Spotlight.render(items, opts) :: Marked.t()`. `Marked` struct mirrors `lib/scoria/knowledge/chunk.ex`'s plain-field-list schema style (translated to a plain struct, no Ecto).

**Telemetry emission pattern** (bounds-safe, D-14) — copy the `try/rescue -> :ok` wrapped `:telemetry.execute/3` shape from `semconv.ex:436-455` / `Trust.fallback/1` above; never let a raising host handler break `render/2`.

---

### `lib/scoria/knowledge.ex` modifications (`ingest_source/2`, `reembed_source/2`, `reindex_source/2`, `retrieve/2`, `create_source/2`, `set_source_trust/3`)

**Analog for chunk-attrs derivation at ingest** — `knowledge.ex:78`:
```elixir
chunks
|> Enum.map(&(&1 |> Map.put(:source_id, source.id) |> Scope.put_source_attrs(scope)))
```
Add a `Map.update(:metadata, %{}, &Trust.put_tier(&1, Trust.tier(source.metadata)))`-style step alongside `Scope.put_source_attrs/2` — same `Enum.map` pipeline position.

**Analog for tenant-scoped bulk operation** (`set_source_trust/3`'s bulk chunk UPDATE) — `knowledge.ex:70-75` (a `Multi.delete_all` scoped by both `source_id` and `tenant_id`, not an UPDATE as CONTEXT.md's prose implies — RESEARCH.md verified this):
```elixir
Multi.delete_all(
  :delete_chunks,
  from(chunk in Chunk,
    where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id
  )
)
```
Mirror the `where: ... and chunk.tenant_id == ^scope.tenant_id` double-scoping for the `Repo.update_all`/`Multi.update_all` call `set_source_trust/3` needs. Additional `update_all` precedent cited by RESEARCH.md: `lib/scoria/prompt_registry.ex:114,121`, `lib/scoria/sre/relay.ex:108,143`, `lib/scoria/semantic_cache/invalidation.ex:115` (not read this session — use as a secondary reference if `Multi.update_all` syntax needed).

**Analog for `reembed_source/2` needing a new metadata-preserving read** — currently (`knowledge.ex` ~96-104) it only re-embeds vectors and does NOT touch `Chunk.metadata`:
```elixir
def reembed_source(%Source{} = source, opts \\ []) do
  scope = Scope.for_write!(scope_input(source, opts))
  embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
  backend = Keyword.get(opts, :backend, Pgvector)
  chunks = list_source_chunks(source.id, scope: scope)
  embeddings = embedder.embed_chunks(chunks, opts)
  backend.upsert_chunk_embeddings(chunks, embeddings)
end
```
Per D-04's red-team fix / RESEARCH.md Pitfall 4: this needs a genuinely new code path reading `source.metadata["scoria.trust.tier"]` via `Trust.tier/1` and re-stamping `Chunk.metadata` — do NOT reconstruct from `Trust.default_tier()`.

**Analog for `retrieve/2` scan insertion point** — `knowledge.ex:264-282` (result binding before persistence):
```elixir
with {:ok, result_rows} <- results,
     {:ok, run} <- create_retrieval_run(%{ ... metadata: config_map |> Semconv.retrieval_config_attributes() |> Semconv.merge_host_declared(host_metadata) }),
     {:ok, persisted_results} <- append_retrieval_results(run.id, result_rows) do
  emit_retriever_span(config_map, host_metadata, trace_id, span_id, opts[:parent_id], started_wall)
  {:ok, %{run: run, results: persisted_results, trace_id: trace_id, span_id: span_id}}
end
```
Insert `Scoria.Trust.Scan` batch-scan call after `result_rows` is bound (before `create_retrieval_run`), fold `reason_code`/`scanned_count` into the same `Semconv`-projected metadata map, and pass the resolved trust attributes into `emit_retriever_span/6`'s existing `attributes` map (same span, no new emitter — confirmed by RESEARCH.md `observe.ex` read).

---

### `lib/scoria/mcp/executor.ex` (scan-at-envelope insertion)

Insert `Scoria.Trust.Scan` call at the same choke point as the Envelope wrap (`executor.ex` ~L48-53), tagging the SAME tool span/telemetry event `emit_sre_telemetry`/`:telemetry.execute([:scoria, :tool, :completed], ...)` already emits — no second span.

---

### `lib/scoria/observe/semconv.ex` (add `trust_attributes/1`, `spotlight_attributes/1`, registry entries)

**Analog:** `@guardrail_keys` / `guardrail_attributes/1` pair, verbatim structural mirror:

**Key-list declaration** (`semconv.ex:242-247`):
```elixir
@guardrail_keys [
  name: "scoria.guardrail.name",
  decision: "scoria.guardrail.decision",
  reason_code: "scoria.guardrail.reason_code",
  subject_ref: "scoria.guardrail.subject_ref",
  policy_key: "scoria.guardrail.policy_key"
]
def guardrail_keys, do: @guardrail_keys
```
Apply for:
```elixir
@trust_keys [
  tier: "scoria.trust.tier",
  scanner: "scoria.trust.scanner",
  reason_code: "scoria.trust.reason_code",
  scanned_count: "scoria.trust.scanned_count"
]

@spotlight_keys [
  technique: "scoria.spotlight.technique",
  marked_spans: "scoria.spotlight.marked_spans",
  marked_bytes: "scoria.spotlight.marked_bytes",
  tier: "scoria.spotlight.tier"
]
```

**Fixed-key projector** (`semconv.ex:466-473`, `guardrail_attributes/1`):
```elixir
@spec guardrail_attributes(map()) :: map()
def guardrail_attributes(input) when is_map(input) do
  Enum.reduce(@guardrail_keys, %{}, fn {field, key}, acc ->
    case Map.get(input, field) do
      nil -> acc
      value -> Map.put(acc, key, value)
    end
  end)
end
```
Copy verbatim shape for `trust_attributes/1`/`spotlight_attributes/1` — never spreads the input map, `nil` omitted not defaulted (structural never-free-text guarantee).

**Registry entry** (`semconv.ex:319-341`, `@attribute_registry`):
```elixir
@attribute_registry Map.merge(
                      %{
                        ...
                        Keyword.fetch!(@guardrail_keys, :name) => :enum,
                        Keyword.fetch!(@guardrail_keys, :decision) => :enum,
                        Keyword.fetch!(@guardrail_keys, :reason_code) => :enum,
                        Keyword.fetch!(@guardrail_keys, :subject_ref) => :id,
                        Keyword.fetch!(@guardrail_keys, :policy_key) => :id
                      },
                      ...
                    )
```
Add `Keyword.fetch!(@trust_keys, :tier) => :enum`, `:scanner => :id`, `:reason_code => :enum`, `:scanned_count => :count` and the `@spotlight_keys` equivalents (`:technique => :enum`, `:marked_spans => :count`, `:marked_bytes => :count`, `:tier => :enum`) into the SAME `Map.merge` literal. **MANDATORY companion edit:** `test/scoria/observe/semconv_test.exs:274-306`'s sorted-list canary test must be updated in the SAME commit, or `Scoria.Observe.Bounds.enforce/2`'s registry-only admission silently DROPS the new keys (confirmed via `observe/bounds.ex` read in RESEARCH.md) — this is the deliberate RED-then-GREEN D-14/D-21 intend, not a bug to route around.

---

### `lib/scoria/application.ex` (add `Scoria.Trust.TaskSupervisor`)

**Analog** (`application.ex:16-19`):
```elixir
{Registry, keys: :unique, name: Scoria.MCP.SessionRegistry},
{Task.Supervisor, name: Scoria.MCP.TaskSupervisor},
{Task.Supervisor, name: Scoria.Workflow.TaskSupervisor},
```
Add a third: `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}` in the same children list, same line style. Do NOT reuse `Scoria.MCP.TaskSupervisor` for `Scoria.Trust.Scan` (creates an undocumented `Knowledge → MCP` dependency since `Scan` serves both `Knowledge.retrieve/2` and `MCP.Executor` call sites — RESEARCH.md Pitfall 3).

## Shared Patterns

### Fail-closed-with-telemetry normalization
**Source:** `lib/scoria/observe/semconv.ex:436-455` (`normalize_reason_code/1`)
**Apply to:** `Scoria.Trust.normalize_tier/1`, `Scoria.Trust.tier/1` (silent + logged branches per D-03), `Scoria.Trust.Scan` error/timeout conversion (D-20), reason_code normalization in the `scoria.trust.*` projector (D-21)
```elixir
Logger.warning("Unrecognized <thing> #{inspect(value)}, defaulting to \"<sentinel>\"")
try do
  :telemetry.execute([:scoria, :<domain>, :fallback], %{}, %{value: value})
rescue
  _ -> :ok
end
```

### Fixed-key attribute projector (never spreads input map)
**Source:** `lib/scoria/observe/semconv.ex:242-256` (`@guardrail_keys`) + `:466-473` (`guardrail_attributes/1`)
**Apply to:** `Semconv.trust_attributes/1`, `Semconv.spotlight_attributes/1` — copy the `Keyword` key-list + `Enum.reduce` projector shape exactly; this is what makes the never-free-text guarantee structural.

### Config-swap module registration (`Application.get_env` + per-call override)
**Source:** `lib/scoria/orchestrator.ex:21` (`req_llm_module`)
**Apply to:** `content_scanner` registration in both `Knowledge.retrieve/2` (keyword-list `opts`) and `MCP.Executor` (map `context`) — container type differs by call site, do not copy `Keyword.pop` into the map-based executor context.

### Registry-gated span attributes (mandatory two-file edit)
**Source:** `lib/scoria/observe/semconv.ex` `@attribute_registry` + `test/scoria/observe/semconv_test.exs:274-306`
**Apply to:** every new `scoria.trust.*`/`scoria.spotlight.*` key — both files MUST be edited in the same commit or `Bounds.enforce/2` silently drops the attribute before Postgres.

### Tenant-scoped bulk write
**Source:** `lib/scoria/knowledge.ex:70-75` (`Multi.delete_all` with `where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id`)
**Apply to:** `Knowledge.set_source_trust/3`'s bulk chunk-metadata UPDATE — same double-scoping (`source_id` AND `tenant_id`), never cross-tenant.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria/trust/tiered.ex` | protocol | transform | First `defprotocol`/`defimpl` in the codebase (confirmed via `grep -rn "defprotocol\|defimpl" lib/` → zero matches). Use the standard Elixir protocol shape cited above (RESEARCH.md Pattern 3) — no in-repo precedent to copy structurally, only the "leaf owns vocabulary, caller reaches in" shape from `Semconv`'s function-reference registration is analogous in spirit. |

## Metadata

**Analog search scope:** `lib/scoria/observe/semconv.ex`, `lib/scoria/orchestrator.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria/mcp/tool.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/chunk.ex`, `lib/scoria/knowledge/source.ex`, `lib/scoria/observe/guardrail.ex`, `lib/scoria/application.ex`
**Files scanned:** 9 read directly (targeted ranges), plus `grep -rn "defprotocol\|defimpl" lib/` (RESEARCH.md, zero matches confirmed)
**Pattern extraction date:** 2026-07-27

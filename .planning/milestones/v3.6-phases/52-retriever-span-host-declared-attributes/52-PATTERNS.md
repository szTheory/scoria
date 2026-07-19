# Phase 52: RETRIEVER Span + Host-Declared Attributes - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 7 (2 new, 5 modified)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/scoria/observe.ex` (new) — `emit_retriever_span/1` | service (span-emitter facade) | event-driven (telemetry emit) | `lib/scoria/observe/adapters/req_llm.ex` | role-match (adapter → facade, same event-driven shape) |
| `lib/scoria/observe.ex` (new) — `emit_prompt_span/1` | service (span-emitter facade) | event-driven (telemetry emit) | `lib/scoria/observe/adapters/req_llm.ex` | role-match (symmetric with `emit_retriever_span/1`) |
| `lib/scoria/observe/semconv.ex` (extend) | utility (key-string + projection owner) | transform | `lib/scoria/observe/semconv.ex` (existing `merge_req_llm_attributes/2`, `openinference_span_kind_key/0`) | exact (self, add siblings) |
| `lib/scoria/knowledge.ex` `retrieve/2` (~:215-257) | service (CRUD orchestrator) | CRUD + event-driven (emits span as side-effect) | itself (existing function) | exact (self, extend) |
| `lib/scoria/knowledge/embedder.ex` | behaviour/model | transform | itself (existing behaviour + `Deterministic` impl) | exact (self, extend) |
| `lib/scoria/observe/adapters/{req_llm,jido}.ex` | event handler / adapter | event-driven | each other (near-identical siblings today) | exact (both already match each other; add one pipe stage) |
| `test/scoria/knowledge/retrieval_test.exs` (~:47-72) | test | integration (real-Postgres) | itself (existing test) | exact (mandatory edit) |
| `test/scoria/observe/semconv_test.exs` | test | unit + drift-guard | itself (existing test, Phase-51 D-15 discipline) | exact (self, extend) |

## Pattern Assignments

### `lib/scoria/observe.ex` (new) — `emit_retriever_span/1` (service, event-driven)

**Analog:** `lib/scoria/observe/adapters/req_llm.ex:1-54`

**Imports pattern** (lines 1-3):
```elixir
defmodule Scoria.Observe.Adapters.ReqLLM do
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind
```
Mirror in the new facade module: `alias Scoria.Observe.Semconv` + `alias Scoria.Observe.SpanKind`.

**Base-attributes reject-nils pattern** (lines 18-24):
```elixir
base_attributes =
  %{
    "tenant_id" => tenant_id,
    "workflow_run_id" => workflow_run_id
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()
```
Delta: `emit_retriever_span/1` has no `tenant_id`/`workflow_run_id` base map to build (retrieval attaches those through `Scope`, not this seam) — instead the analogous reject-nils composition happens implicitly via `Semconv.retrieval_config_attributes/1`'s `"none"` sentinel (D-RETR02-4: never nil, so no reject-nils step needed here) and `Semconv.merge_host_declared/2`'s own skip-nil reduce (D-ATTR01-2).

**Core span-map + emit pattern** (lines 34-53, the load-bearing excerpt):
```elixir
attributes =
  base_attributes
  |> Semconv.merge_req_llm_attributes(metadata)
  |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))

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
```
Delta for `emit_retriever_span/1` (per D-R2/R3/R4/R5/R7, RESEARCH.md Code Examples):
```elixir
attributes =
  %{}
  |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference("retriever"))
  |> Map.merge(Semconv.retrieval_config_attributes(config_map))
  |> Semconv.merge_host_declared(host_metadata)

span = %{
  name: "knowledge.retrieve",
  span_kind: SpanKind.normalize("retriever"),
  status_code: "OK",
  start_time: started_wall,
  end_time: DateTime.utc_now(),
  trace_id: trace_id,
  id: span_id,
  parent_id: opts[:parent_id],
  attributes: attributes
}

:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
```
Key structural deltas vs. the analog: (a) `id: span_id` is set explicitly (own-id, D-R2) — the analog never sets `:id`, relying on `Buffer`'s `Map.put_new_lazy(:id, …)` (`buffer.ex:109`); (b) `status_code: "OK"` is new (D-R5) — the analog omits it (defaults apply downstream); (c) no `tenant_id`/`workflow_run_id`/`session_id` top-level fields — retrieval's tenant scoping rides `Scope`, not this seam; (d) wrap the whole `:telemetry.execute` call `try/rescue -> :ok` (D-R6) — the analog does not need this because it already runs inside a telemetry handler, but `emit_retriever_span/1` is called directly from `retrieve/2`'s business logic and must never let a handler crash propagate.

---

### `lib/scoria/observe.ex` (new) — `emit_prompt_span/1` (service, event-driven)

**Analog:** same as above (`req_llm.ex`), symmetric structure per RESEARCH.md Recommendation 1 (`observe.ex` facade, `name: "prompt.compose"`, `span_kind: SpanKind.normalize("prompt")`).

**Core pattern delta:**
```elixir
attributes =
  %{}
  |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference("prompt"))
  |> Semconv.merge_host_declared(host_metadata)
  |> maybe_put_prompt_context(opts[:context_pack])   # omit key entirely if absent/empty (D-ATTR02-7)
  |> maybe_put_input_tokens(opts[:input_tokens])      # "gen_ai.usage.input_tokens", omit if nil (D-ATTR02-5)

span = %{
  name: "prompt.compose",
  span_kind: SpanKind.normalize("prompt"),
  status_code: "OK",
  start_time: DateTime.utc_now(),
  end_time: DateTime.utc_now(),
  trace_id: opts[:trace_id],
  id: opts[:span_id] || Ecto.UUID.generate(),
  parent_id: opts[:parent_id],
  attributes: attributes
}

try do
  :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  :ok
rescue
  _ -> :ok
end
```
Never write raw chunk/memory text — `Semconv.prompt_context/1` must map each item to `%{"id" => id, "tokens" => tokens}` only (D-ATTR02-4).

---

### `lib/scoria/observe/semconv.ex` (extend) (utility, transform)

**Analog:** itself — `merge_req_llm_attributes/2` (lines 28-33) and `openinference_span_kind_key/0` (lines 18-20) are the sibling-function precedent to extend.

**Existing sibling pattern to mirror** (lines 16-33):
```elixir
@openinference_span_kind_key "openinference.span.kind"

@doc "Returns the canonical OpenInference span-kind attribute key."
@spec openinference_span_kind_key() :: String.t()
def openinference_span_kind_key, do: @openinference_span_kind_key

@doc """
Merges the req_llm-owned `gen_ai.*` attribute set ...
"""
@spec merge_req_llm_attributes(map(), map()) :: map()
def merge_req_llm_attributes(attributes, metadata) do
  attributes
  |> Map.merge(ReqLLM.OpenTelemetry.Attributes.start(metadata))
  |> Map.merge(ReqLLM.OpenTelemetry.Attributes.terminal(metadata))
end
```
Delta — add five/six new functions following this exact "module-attribute constant + `@doc` + `@spec` + thin function" shape (per RESEARCH.md Recommendation 4 — three sibling families, not one generic projection):
- `retrieval_config_keys/0` — returns the keyword list `[embedding_model: "scoria.retrieval.embedding_model", index_version: "scoria.retrieval.index_version", reranker: "scoria.retrieval.reranker"]` (D-RETR02-3).
- `retrieval_config_attributes/1` — takes the one canonical `%{embedding_model:, index_version:, reranker:}` map, applies `"none"` sentinel-never-nil (D-RETR02-4), and projects to the dotted-string keys.
- `host_declared_keys/0` — returns `~w(feature route archetype intent)a` (D-ATTR01-1).
- `merge_host_declared/2` — `Enum.reduce` over `host_declared_keys/0`, atom-keyed source map, `nil -> skip`, else `Map.put(acc, Atom.to_string(key), value)` verbatim (D-ATTR01-2).
- `prompt_context_key/0` — returns `"scoria.prompt.context"` (D-ATTR02-3).
- `prompt_context/1` — builds the nested `%{"chunks" => [...], "memories" => [...], "token_budget" => %{...}}` map, mapping each item to `%{"id" => id, "tokens" => tokens}` only (never raw text, D-ATTR02-4), capping each list at ≤100 with `"truncated" => true` (D-ATTR02-6).

**Moduledoc delta:** update the moduledoc block (lines 11-14) to state these are now implemented, not just "(Phase 52+) reserved."

**Anti-inline grep test precedent to mirror** (semconv_test.exs lines 81-89):
```elixir
test "single-origin guard: semconv.ex source contains no hand-declared gen_ai.* literal" do
  source =
    "lib/scoria/observe/semconv.ex"
    |> Path.expand(File.cwd!())
    |> File.read!()

  refute source =~ ~r/"gen_ai\./,
         "semconv.ex must delegate to ReqLLM.OpenTelemetry.Attributes, never hand-write a gen_ai.* string literal"
end
```
Mirror this shape for the new anti-inline grep guards, but inverted target: assert the reserved-key strings (`"scoria.retrieval."`, `"feature"`/`"route"`/`"archetype"`/`"intent"`, `"scoria.prompt.context"`) appear ONLY inside `semconv.ex`, by reading the *other* files (`knowledge.ex`, `observe.ex`, `adapters/req_llm.ex`, `adapters/jido.ex`) and `refute`-ing the literal (per RESEARCH.md's Code Example, lines 377-380).

---

### `lib/scoria/knowledge.ex` `retrieve/2` (~:215-257) (service, CRUD + event-driven)

**Analog:** itself — the function already exists; RESEARCH.md Recommendation 2 gives the exact concrete edit list against the verified current body (reproduced below at lines 215-257).

**Current body to extend** (verified lines 215-257):
```elixir
def retrieve(query_text, opts \\ []) do
  scope = Scope.from_opts!(opts)
  opts = Keyword.put(opts, :scope, scope)
  backend = Keyword.get(opts, :backend, Pgvector)
  retriever = Keyword.get(opts, :retriever)
  limit = Keyword.get(opts, :limit, 5)
  filters = Keyword.get(opts, :filters, %{})
  started_at = System.monotonic_time(:millisecond)

  results =
    case retriever do
      nil ->
        query_embedding =
          opts[:query_embedding] ||
            Embedder.Deterministic.embed_query(query_text, opts)

        backend.similar_chunks(query_embedding, limit: limit, filters: filters, scope: scope)

      Scrypath ->
        Scrypath.retrieve(query_text, opts)

      module ->
        module.retrieve(query_text, opts)
    end

  with {:ok, result_rows} <- results,
       {:ok, run} <-
         create_retrieval_run(%{
           query_text: query_text,
           backend: inspect(backend),
           retriever: retriever && inspect(retriever),
           top_k: limit,
           filters: filters,
           trace_id: opts[:trace_id],
           span_id: opts[:span_id],
           scope: scope,
           status: "completed",
           latency_ms: System.monotonic_time(:millisecond) - started_at
         }),
       {:ok, persisted_results} <- append_retrieval_results(run.id, result_rows) do
    {:ok, %{run: run, results: persisted_results}}
  end
end
```

**Deltas to apply (D-R2/R3/R4, D-RETR02-1/2, D-ATTR01-3, D-R6, D-R7 — exact ordering from RESEARCH.md Recommendation 2):**
1. Add `started_wall = DateTime.utc_now()` alongside `started_at` (D-R4) — keep `started_at`/monotonic delta as the sole `latency_ms` authority; never derive `start = end - latency`.
2. Mint `trace_id = opts[:trace_id] || Ecto.UUID.generate()` and `span_id = opts[:span_id] || Ecto.UUID.generate()` (D-R2) — **replaces** the current bare `opts[:trace_id]`/`opts[:span_id]` reads at lines 248-249.
3. Add `embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)` — new opt, currently absent; use it in place of the hardcoded `Embedder.Deterministic.embed_query(query_text, opts)` at line 229 AND for the `embedding_model` precedence lookup (guarded `function_exported?(embedder, :model_name, 0)`, D-RETR02-5).
4. Build one `config_map = %{embedding_model: ..., index_version: ..., reranker: ...}` per the D-RETR02-2 precedence rules; feed through `Semconv.retrieval_config_attributes/1` for both `create_retrieval_run`'s `metadata:` and the span `attributes` (single computation, D-RETR02-1).
5. `host_metadata = Map.new(opts)` before calling `Semconv.merge_host_declared/2` (D-ATTR01-3 — `opts` is a keyword list; the seam needs a map to avoid `BadMapError`).
6. Write `span_id` to both `create_retrieval_run`'s `span_id:` field (line 249, unchanged column) AND the emitted span's `:id`.
7. After the `with` succeeds, call `Scoria.Observe.emit_retriever_span(span_map)` wrapped `try/rescue -> :ok` (D-R6) — never before the `with` (RETR-01 success-path only).
8. Change the final return to additive: `{:ok, %{run: run, results: persisted_results, trace_id: trace_id, span_id: span_id}}` (non-breaking per verified caller patterns, including this phase's own updated test).

---

### `lib/scoria/knowledge/embedder.ex` (behaviour/model, transform)

**Analog:** itself — current full file (27 lines) shown below; add the optional callback + one function per D-RETR02-5.

**Current file (verified, full):**
```elixir
defmodule Scoria.Knowledge.Embedder do
  @callback embed_chunks([map()], keyword()) :: [[float()]]

  defmodule Deterministic do
    @behaviour Scoria.Knowledge.Embedder

    @impl true
    def embed_chunks(chunks, _opts) do
      Enum.map(chunks, &vectorize(&1.body))
    end

    def embed_query(text, _opts \\ []) do
      vectorize(text)
    end

    defp vectorize(text) do
      ...
    end
  end
end
```
Delta:
```elixir
defmodule Scoria.Knowledge.Embedder do
  @callback embed_chunks([map()], keyword()) :: [[float()]]
  @callback model_name() :: String.t()
  @optional_callbacks [model_name: 0]

  defmodule Deterministic do
    @behaviour Scoria.Knowledge.Embedder

    @impl true
    def embed_chunks(chunks, _opts) do
      Enum.map(chunks, &vectorize(&1.body))
    end

    @impl true
    def model_name, do: "scoria.deterministic.sha256.v1"

    def embed_query(text, _opts \\ []) do
      vectorize(text)
    end

    ...
  end
end
```
Caller in `knowledge.ex` must guard with `function_exported?(embedder, :model_name, 0)` before invoking — never call unconditionally (a host embedder lacking it must fall through to `opts[:embedding_model]` → `"none"`, not `UndefinedFunctionError`).

---

### `lib/scoria/observe/adapters/{req_llm,jido}.ex` (event handler/adapter, event-driven)

**Analog:** each other — `req_llm.ex` and `jido.ex` are already near-identical siblings (both build `base_attributes` reject-nils, both end with the same `span` map shape and `:telemetry.execute` call). Use either as the analog for the other.

**Shared attributes-pipe shape to extend** (`req_llm.ex` lines 34-37; `jido.ex` lines 23-33 is the same shape with an inline map instead of a piped `base_attributes`):
```elixir
attributes =
  base_attributes
  |> Semconv.merge_req_llm_attributes(metadata)
  |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))
```
Delta — insert `|> Semconv.merge_host_declared(metadata)` into this pipe (both files) so `feature`/`route`/`archetype`/`intent` ride every LLM and TOOL span when present in `metadata` (D-ATTR01-5). **Caveat (D-ATTR01-7, verified against `deps/req_llm/lib/req_llm/telemetry.ex:485-514`): on a real `[:req_llm, :request, :stop]` emission, `metadata` never contains these host keys** — req_llm builds a fixed base map with no host-key merge channel. This edit is therefore correct/harmless (skip-nil reduce, D-ATTR01-2) but only takes effect for `req_llm.ex` on hand-synthesized test events, not production traffic; the reliable production carrier for host keys on the prompt/LLM lane is the new `emit_prompt_span/1`, not this adapter pipe. `jido.ex`'s `metadata[:span_kind]`/`metadata[:tenant_id]` are host-supplied via the emitting call site already, so `merge_host_declared/2` there is expected to be reachable in production.

---

### `test/scoria/knowledge/retrieval_test.exs` (~:47-72) (test, integration/real-Postgres)

**Analog:** itself — current test body (verified lines 27-72, reproduced above in Read output) is the mandatory-edit target (D-R2b).

**Current assertions to migrate** (lines 60, 65):
```elixir
assert {:ok, %{run: %RetrievalRun{} = run, results: [result | _]}} =
         Knowledge.retrieve("challengeable answer",
           query_embedding: [0.1, 0.2, 0.3],
           filters: %{source_id: source.id},
           scope: @scope,
           trace_id: trace.id,
           span_id: span.id            # <- currently "caller's span" semantics
         )

assert run.query_text == "challengeable answer"
assert run.trace_id == trace.id
assert run.span_id == span.id          # <- currently asserts run.span_id == the PASSED span.id
```
Delta (mandatory, D-R2/D-R2b): change the `retrieve/2` call's `span_id: span.id` to `parent_id: span.id`; change the assertion to `run.span_id == <the minted own-id returned from retrieve/2>` (i.e. `run.span_id == returned_span_id` where `{:ok, %{span_id: returned_span_id}} = ...`); add a new assertion that the persisted RETRIEVER span's `parent_id == span.id` (join via `Repo.get_by!(Span, id: run.span_id)` after `Scoria.Observe.Buffer.flush_now()`, per RESEARCH.md's `flush_now/1` test-hook pattern). Add the RETR-01 join test and RETR-02 real-Postgres equality test (RESEARCH.md Code Example, "The RETR-02 consistency guard") as new tests in this file or a sibling integration test, following the exact `flush_now/1` → `Repo.get_by!` → `Keyword.values(Semconv.retrieval_config_keys())` → `Map.take` equality shape.

---

### `test/scoria/observe/semconv_test.exs` (test, unit + drift-guard)

**Analog:** itself — existing `describe` blocks (lines 6-44, 46-90) are the exact shape to replicate for the three new key families.

**Existing shape to mirror** (lines 6-10, simplest canary example):
```elixir
describe "openinference_span_kind_key/0" do
  test "returns exactly \"openinference.span.kind\"" do
    assert Semconv.openinference_span_kind_key() == "openinference.span.kind"
  end
end
```

**Existing anti-inline grep shape to mirror** (lines 81-89, reproduced above under semconv.ex section).

Delta — add three new `describe` blocks:
- `describe "retrieval_config_keys/0 + retrieval_config_attributes/1"` — canary exact-list assertion; sentinel `"none"`-never-nil assertion; anti-inline grep refuting `"scoria.retrieval."` outside `semconv.ex`.
- `describe "host_declared_keys/0 + merge_host_declared/2"` — canary; skip-nil / never-default assertion (`refute Map.has_key?` on empty metadata); pass-through byte-for-byte sentinel; anti-inline grep for `"feature"`/`"route"`/`"archetype"`/`"intent"` literals outside `semconv.ex`.
- `describe "prompt_context_key/0 + prompt_context/1"` — canary key string; never-text structural guard (regex `~r/text|content|body|message|prompt|raw/i` over built keys); ≤100-item cap + `"truncated" => true`; `Jason.encode!/1` ≤ 8KB size guard; empty/absent ⇒ omitted key.

## Shared Patterns

### Telemetry span-emit + Buffer persistence seam
**Source:** `lib/scoria/observe/adapters/req_llm.ex:52` (`:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`), backed by `lib/scoria/observe/buffer.ex:23` (`flush_now/1`), `:109` (`Map.put_new_lazy(:id, ...)`), `:123-129` (FK-safe `Ecto.Multi`, trace `on_conflict: :nothing` → span `insert_all` with no `on_conflict`).
**Apply to:** `emit_retriever_span/1`, `emit_prompt_span/1`. Never `Repo.insert` synchronously; always go through this event. Test assertions must call `Buffer.flush_now/1` before querying `ai_spans`.

### Span-kind normalize + OpenInference mirror
**Source:** `lib/scoria/observe/span_kind.ex:56` (`SpanKind.normalize/2`) and `:83` (`SpanKind.to_openinference/1`); already includes `"retriever"` → `"RETRIEVER"` (line 32) and `"prompt"` → `"PROMPT"` (line 29).
**Apply to:** `emit_retriever_span/1` (`SpanKind.normalize("retriever")`), `emit_prompt_span/1` (`SpanKind.normalize("prompt")`). Never hardcode the uppercase string; always derive via `to_openinference/1` under `Semconv.openinference_span_kind_key()`.

### Semconv single-key-string ownership + anti-inline grep
**Source:** `lib/scoria/observe/semconv.ex` moduledoc (lines 1-14) + `test/scoria/observe/semconv_test.exs:81-89`.
**Apply to:** every new key string (`scoria.retrieval.*`, bare `feature`/`route`/`archetype`/`intent`, `scoria.prompt.context`) — defined once in `semconv.ex`, referenced everywhere else via function call, never inlined. Enforce with a grep-based test per key family.

### Redaction (unchanged, reused as-is)
**Source:** `lib/scoria/observe/redactor.ex:32-46` (depth-recursive, key-based `do_redact`).
**Apply to:** all new attribute values (host-declared keys, retrieval config, prompt context) pass through this existing redactor unchanged — no new Phase-52 value-hygiene code (D-ATTR01-4). Note: a host-declared key named `token`/`secret`/`password`/`api_key` will legitimately redact — this is expected, not a bug (Pitfall 3 in RESEARCH.md).

## No Analog Found

None — every file in scope has either a direct existing analog (`req_llm.ex`/`jido.ex` adapter shape, `semconv.ex` sibling-function shape) or is itself the file being extended with a verified current body.

## Metadata

**Analog search scope:** `lib/scoria/observe/`, `lib/scoria/observe/adapters/`, `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/embedder.ex`, `test/scoria/knowledge/`, `test/scoria/observe/`.
**Files scanned:** 8 (all read in full or targeted range; no file exceeded 2,000 lines).
**Pattern extraction date:** 2026-07-12

# Stack Research: v3.6 Trace Foundation (SEED-007 — OTel-GenAI / OpenInference Interop)

**Domain:** Elixir/Phoenix embedded AI observability — trace/span attribute naming convention
**Researched:** 2026-07-11
**Confidence:** HIGH (source-code-verified against the vendored `deps/req_llm` checkout at the exact
locked version, cross-checked against the live OTel GenAI and OpenInference specification repos)

## Executive verdict

**No new runtime dependency is needed.** Scoria's peer `req_llm ~> 1.13` (locked at `1.13.0`) already
ships a dependency-free `gen_ai.*` attribute builder (`ReqLLM.OpenTelemetry.Attributes`) that produces
exactly the OTel-GenAI-conventional key names Scoria needs, sourced from telemetry metadata ReqLLM
*already* populates on every request — including `temperature`/`top_p`/`seed`/`max_tokens`, which
Scoria's adapter currently drops on the floor. Wiring SEED-007's naming convention is almost entirely
a matter of *reading data ReqLLM already computes*, not adding new machinery. `openinference.span.kind`
has no Elixir library at all (OpenInference publishes JS/Python/Rust packages only) — it is a bare
string literal Scoria writes itself, confirming the seed's "convention, not dependency" thesis for that
half too.

## Recommended Stack

### Core Technologies (already present — zero new deps)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `req_llm` | `~> 1.13` (locked `1.13.0`, current Hex latest `1.17.1`) | LLM peer; already declared in `mix.exs` | Ships `ReqLLM.OpenTelemetry.Attributes` (dependency-free `gen_ai.*` map builder) and `ReqLLM.Telemetry.RequestOptions` (normalizes caller opts into an OTel-attribute-shaped map) as of **`v1.12.0`** (2026-05-22), refined in `v1.13.0` (2026-05-28, "Otel sub-span allocation to parent spans"). The version Scoria already pins has this. Verified: `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex`, `deps/req_llm/lib/req_llm/telemetry/request_options.ex`, `deps/req_llm/CHANGELOG.md` lines 37–54. |
| OTel-GenAI semantic-convention key names (as strings) | spec repo `open-telemetry/semantic-conventions-genai`, schema `1.37.0` (the URL ReqLLM's own tracer/meter constructs pin) | Naming convention for `gen_ai.request.*` / `gen_ai.usage.*` / `gen_ai.response.*` keys inside Scoria's existing `attributes` jsonb map | No package to install — these are plain string map keys. **Every `gen_ai.*` attribute in the current spec is tagged `Development` (not Stable)** as of this research (confirmed directly on the live `gen-ai-attributes.md` registry page, 2026). That instability is *exactly why* the seed's "convention over columns" call is correct: a typed-column migration against a namespace OTel itself hasn't stabilized would be premature; a string key just gets bumped if/when OTel renames something. |
| OpenInference span-kind taxonomy (as a string) | spec: `Arize-ai/openinference` `spec/semantic_conventions.md` | Naming convention for `openinference.span.kind` values on Scoria spans | No Elixir client exists or is needed — OpenInference ships only JS/Python/Rust instrumentation packages. The **value enum** is the useful artifact, not a library: `LLM, CHAIN, TOOL, RETRIEVER, RERANKER, EMBEDDING, AGENT, GUARDRAIL, EVALUATOR, PROMPT` (10 values, verified against the canonical spec doc on GitHub). |

### Supporting Libraries — none required in Scoria's runtime

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `opentelemetry` / `opentelemetry_api` (Erlang/Elixir OTel SDK) | n/a | Actually **exporting** spans to a real OTel collector/backend (Datadog, Langfuse, Honeycomb, etc.) | **Host-side only, opt-in, never inside Scoria.** ReqLLM's own `ReqLLM.OpenTelemetry.attach/2` bridge needs this SDK present to call `:otel_tracer`/`:otel_span`, and it degrades gracefully (`{:error, :opentelemetry_unavailable}`) when absent — proving the SDK is designed as an *optional host add-on*, not a hard peer. Scoria's job (per P5/P6 doctrine) is to make its `attributes` jsonb map "OTel-shaped" so a host that *does* add this SDK can trivially forward it; Scoria itself must never require it to boot. |
| `opentelemetry_semantic_conventions` (Hex, `hexdocs.pm/opentelemetry_semantic_conventions`) | n/a | Compile-time Elixir constants (`@gen_ai_request_model "gen_ai.request.model"` etc.) for a *host* writing its own OTel exporter code | Not needed by Scoria — Scoria writes plain binary map keys directly into jsonb; there's no compile-time attribute macro use case inside the library itself. Mention this package in host-facing docs only, as an option for hosts who want compiler-checked attribute names in their own export glue. |

### What NOT to add

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Typed columns for `gen_ai.request.temperature`/`top_p`/`seed`/etc. | The whole `gen_ai.*` namespace is `Development`-status upstream (unstable, still being renamed/extended) — a pre-1.0 schema migration against a moving target invites the exact churn SEED-007 is designed to avoid | Conventional string keys inside the existing `attributes` jsonb column on `ai_spans`/`ai_traces` |
| `opentelemetry` / `opentelemetry_api` / any OTel exporter as a **runtime dependency of the `scoria` package itself** | Turns an embedded BEAM-native library into something that assumes/requires an OTel SDK/collector at boot — violates P5 (zero required egress) and P6 (not a metrics warehouse) | Keep OTel interop as a "hook at the edges": Scoria writes OTel-shaped keys into its own Ecto-owned jsonb; a host that wants live OTel export adds the SDK itself and reads Scoria's spans to forward them (or attaches ReqLLM's own bridge separately, which is designed for exactly this) |
| `gen_ai.system` | Renamed. Confirmed absent from the current `gen-ai-attributes.md` registry; fully superseded by `gen_ai.provider.name`. ReqLLM's `Attributes.start/1` already emits `"gen_ai.provider.name"`, never the old name. | `gen_ai.provider.name` |
| `gen_ai.usage.prompt_tokens` / `gen_ai.usage.completion_tokens` | Renamed (older instrumentation-era names). Confirmed absent from the current registry — not even listed as deprecated aliases, i.e. fully retired. | `gen_ai.usage.input_tokens` / `gen_ai.usage.output_tokens` — exactly what ReqLLM's `Attributes.terminal/1` already emits |
| Forcing every span kind (`tool`/`prompt`/`retrieval`/`guardrail`) into `ai_span_events` | The seed explicitly rejects this — peers (OTel-GenAI, OpenInference) model these as span *kinds*, not point-events. Doing otherwise is "a worse model than every peer." | Resurrect `ai_span_events` **minimally**, for true point-events only (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`); everything else is a proper child span keyed by `span_kind` |
| Collapsing `ai_retrieval_runs` into a generic span | It is richer than a span (grounding scores, typed results) and is explicitly the seed's system-of-record | Dual-write: emit a linked `RETRIEVER` span for visibility, keep `ai_retrieval_runs` for detail |

## Question 1 — Current OTel GenAI attribute names, verified against the live spec (2026)

Source of truth: `open-telemetry/semantic-conventions-genai` (the GenAI conventions moved out of the
main `open-telemetry/semantic-conventions` repo; the old `opentelemetry.io/docs/specs/semconv/gen-ai/`
pages are now redirect stubs — confirmed by fetching them directly and getting only a "this page has
moved" notice). Fetched the live registry (`gen-ai-attributes.md`) directly:

| Attribute | Current name | Stability (as fetched, 2026) | Historical note |
|---|---|---|---|
| Model requested | `gen_ai.request.model` | Development | unchanged |
| Sampling temp | `gen_ai.request.temperature` | Development | unchanged |
| Nucleus sampling | `gen_ai.request.top_p` | Development | unchanged (also `gen_ai.request.top_k` exists) |
| Max output tokens | `gen_ai.request.max_tokens` | Development | unchanged |
| Determinism seed | `gen_ai.request.seed` | Development | unchanged |
| Input tokens | `gen_ai.usage.input_tokens` | Development | **renamed from `gen_ai.usage.prompt_tokens`** — old name is gone from the registry entirely (not even listed as a deprecated alias) |
| Output tokens | `gen_ai.usage.output_tokens` | Development | **renamed from `gen_ai.usage.completion_tokens`** — same, fully retired |
| Provider/vendor | `gen_ai.provider.name` | Development | **renamed from `gen_ai.system`** — `gen_ai.system` no longer appears in the current registry |
| Operation type | `gen_ai.operation.name` | Development | unchanged (values: `"chat"`, `"embeddings"`, `"generate_content"`, etc.) |
| Response model actually used | `gen_ai.response.model` | Development | unchanged |
| Response id | `gen_ai.response.id` | Development | unchanged |
| Stop reason(s) | `gen_ai.response.finish_reasons` | Development | unchanged |

**Critical framing for the roadmap:** the OTel GenAI semantic conventions have **not been marked
Stable as of this research** — OTel's own transition-plan language says stabilization has no public
timeline. This is independent confirmation (from the standard itself, not just the seed's internal
argument) that adopting these as **typed columns** would be premature; adopting them as **conventional
string keys** costs nothing if/when a future OTel release renames something again (exactly what already
happened once, with `prompt_tokens`→`input_tokens` and `system`→`provider.name`).

Full current attribute surface (all `Development` status) also includes things Scoria doesn't need yet
but should keep in mind for later seeds: `gen_ai.input.messages` / `gen_ai.output.messages` (content
capture, off by default), `gen_ai.conversation.id`, `gen_ai.tool.*` (tool-call spans), `gen_ai.retrieval.*`
(`top_k`, `documents`, `query.text` — directly relevant to SEED-007 item 4, the RETRIEVER span),
`gen_ai.agent.name`, `gen_ai.prompt.name`/`.version` (directly relevant to SEED-007's "prompt version"
attribution goal).

Sources: [Gen AI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/)
(redirect notice, confirms relocation), live fetch of the GenAI repo's `gen-ai-attributes.md` (via
`raw.githubusercontent.com/open-telemetry/semantic-conventions-genai/main/docs/gen-ai/gen-ai-attributes.md`,
returned the full table with per-attribute `Development` badges quoted above),
[open-telemetry/semantic-conventions-genai](https://github.com/open-telemetry/semantic-conventions-genai),
[OpenTelemetry for Generative AI blog](https://opentelemetry.io/blog/2024/otel-generative-ai/). Confidence: HIGH
(primary spec source, directly fetched, cross-checked against ReqLLM's own vendored implementation which
independently arrived at the identical current names).

## Question 2 — OpenInference span-kind taxonomy, reconciled against OTel-GenAI

Source: `Arize-ai/openinference` `spec/semantic_conventions.md` (canonical; fetched directly from GitHub).

`openinference.span.kind` is a **required** attribute on every OpenInference span. Full current enum
(10 values):

```
LLM        — a call to a language model (chat/completion)
CHAIN      — a starting point / link between application steps (general orchestration span)
TOOL       — an external tool/function invocation
RETRIEVER  — a data retrieval operation (vector store, DB, search)
RERANKER   — a document-reranking operation
EMBEDDING  — a call to an embedding model/service
AGENT      — a reasoning block encompassing LLM + tool calls
GUARDRAIL  — jailbreak protection / content-filtering
EVALUATOR  — an output-evaluation function
PROMPT     — rendering of a prompt template
```

**Reconciliation with OTel-GenAI (why both conventions, not one):** OTel-GenAI has no equivalent
taxonomy attribute. OTel's own `SpanKind` enum (`INTERNAL`/`CLIENT`/`SERVER`/`PRODUCER`/`CONSUMER`) is a
low-level transport-role concept (confirmed in ReqLLM's own `OTelAdapter.start_span/3`, which hardcodes
`kind: :client` for every GenAI span regardless of what it represents) — it cannot distinguish an LLM
call from a retrieval call from a guardrail check. OpenInference's `openinference.span.kind` is exactly
the taxonomy layer OTel-GenAI is missing. **They are complementary, not competing:** use OTel-GenAI
`gen_ai.*` keys for the scalar request/response/usage facts on a span, and OpenInference's
`openinference.span.kind` string for what *kind* of span it is. This is precisely what SEED-007 already
proposes.

**Match against Scoria's existing UI vocabulary** (`lib/scoria_web/components/workflow_tree_component.ex:38`):
`llm tool prompt mcp retriever guardrail eval agent` — 6 of 8 map directly onto OpenInference values
(`LLM`, `TOOL`, `PROMPT`, `RETRIEVER`, `GUARDRAIL`→`GUARDRAIL`, `eval`→`EVALUATOR`, `agent`→`AGENT`).
`mcp` has no OpenInference equivalent — treat it as a Scoria-specific extension value layered on top of
the OpenInference enum (a remote-connector invocation is a `TOOL`-shaped operation with extra
connector-scope attributes; keeping `mcp` as Scoria's own `span_kind` value rather than forcing it into
`TOOL` preserves the distinction the dashboard already draws). `CHAIN`, `RERANKER`, `EMBEDDING` exist in
OpenInference but have no current Scoria UI slot — not required by this seed's scope, note as a gap for
future span-kind coverage if embeddings/reranking get their own adapters.

Sources: [OpenInference semantic_conventions.md](https://github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md)
(directly fetched, full span-kind enum + attribute table quoted above),
[Arize Phoenix OpenInference docs](https://arize.com/docs/phoenix/tracing/concepts-tracing/otel-openinference/semantic-conventions),
[OpenInference spec index](https://arize-ai.github.io/openinference/spec/). Confidence: HIGH (primary
spec source, directly fetched).

## Question 3 — Does Scoria need a new Elixir OTel dependency?

**No.** Verdict backed by reading the actual vendored source, not just docs:

1. **Attribute naming needs zero dependency.** `ReqLLM.OpenTelemetry.Attributes` (in
   `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex`) is explicitly documented as
   "Shared between the live bridge... and the dependency-free mapper" and its source contains **no**
   calls into `:otel_tracer`/`:otel_span`/any OTel SDK module — it is pure `Map`-building code that
   takes ReqLLM's own telemetry metadata and returns a plain `%{"gen_ai.request.model" => ..., ...}`
   map. Scoria's adapter can call `ReqLLM.OpenTelemetry.Attributes.start/1` and `.terminal/1` directly —
   `req_llm` is already a declared peer dependency, so this costs literally nothing new.

2. **Full OTel SDK (`opentelemetry`/`opentelemetry_api`) is exclusively for export.**
   `ReqLLM.OpenTelemetry.OTelAdapter.available?/0` (same file, `open_telemetry.ex`) checks for
   `:otel_tracer_provider`, `:otel_tracer`, `:otel_span` at runtime via `Code.ensure_loaded?/1` and
   `function_exported?/3`, and `ReqLLM.OpenTelemetry.attach/2` returns
   `{:error, :opentelemetry_unavailable}` when the SDK isn't present — i.e. ReqLLM itself treats the OTel
   SDK as **optional, host-attached, checked at runtime**, never a hard dependency. This is the exact
   shape SEED-007 wants Scoria to mirror: naming convention lives in the library, span export is a host
   decision.

3. **`opentelemetry_semantic_conventions` (Hex)** is a convenience package of compile-time attribute-name
   constants for people hand-writing OTel exporter code. Scoria doesn't hand-write exporter code — it
   writes into its own jsonb `attributes` map — so there's no compile-time-macro use case inside the
   library. It is worth a documentation *mention* for hosts building their own OTel forwarder, not an
   addition to `mix.exs`.

**Conclusion:** SEED-007 ships with `mix.exs` **unchanged**. No `{:opentelemetry, ...}`,
`{:opentelemetry_api, ...}`, or `{:opentelemetry_semantic_conventions, ...}` line is added.

## Question 4 — Exact ReqLLM v1.13 request-opts shape (where temp/top_p/seed/max_tokens live)

Caller-facing opts (what a Scoria consumer of `ReqLLM.generate_text/3` etc. passes, e.g. today's
hardcoded `req_llm_module.generate_text(model_spec, messages, max_tokens: 2048)` in `lib/scoria/ui_critique.ex:92`)
are **plain top-level keyword-list options**: `:temperature`, `:top_p`, `:top_k`, `:max_tokens`,
`:frequency_penalty`, `:presence_penalty`, `:stop` (or `:stop_sequences`), `:seed`, `:n`,
`:encoding_format`, `:service_tier`, plus an escape-hatch `:provider_options` keyword for
provider-specific extras.

**They are already normalized for Scoria, no re-parsing needed.** Every call into ReqLLM's generation
path builds a telemetry context via `ReqLLM.Telemetry.new_context/3`
(`deps/req_llm/lib/req_llm/telemetry.ex:138`), which unconditionally runs:

```elixir
request_options: ReqLLM.Telemetry.RequestOptions.extract(mode, opts),
```

`RequestOptions.extract/2` (`deps/req_llm/lib/req_llm/telemetry/request_options.ex`) turns the raw
keyword opts into a compact atom-keyed map — **this happens on every request regardless of whether any
OTel bridge is attached**, purely as part of ReqLLM's own telemetry context:

```elixir
%{
  temperature: opts[:temperature],
  top_p: opts[:top_p],
  top_k: opts[:top_k],
  max_tokens: opts[:max_tokens],
  frequency_penalty: opts[:frequency_penalty],
  presence_penalty: opts[:presence_penalty],
  stop_sequences: normalize_string_list(opts[:stop] || opts[:stop_sequences]),
  seed: opts[:seed],
  n: normalize_choice_count(opts[:n]),
  stream?: mode == :stream,
  encoding_formats: normalize_string_list(opts[:encoding_format]),
  conversation_id: telemetry_conversation_id(opts),
  service_tier: opts[:service_tier] || provider_opts[:service_tier]
}
# nil values dropped
```

This map is threaded onto **both** `[:req_llm, :request, :start]` **and** `[:req_llm, :request, :stop]`
telemetry metadata as `metadata[:request_options]` (confirmed: `telemetry.ex:159` sets it in the shared
context at construction, `telemetry.ex:494` re-threads `context.request_options` into the terminal/stop
metadata builder — same map, both events).

**Concretely, for the adapter fix (`lib/scoria/observe/adapters/req_llm.ex`):** the current adapter only
attaches to `[:req_llm, :request, :stop]` and reads `metadata[:model]`/`measurements[:total_tokens]`. It
already receives `metadata[:request_options]` on that same event today and simply isn't reading it. The
two implementation options, both zero-dependency:

- **Minimal:** read `metadata[:request_options][:temperature]` etc. directly and hand-map the ~6 keys
  Scoria cares about (`temperature`, `top_p`, `seed`, `max_tokens`) onto `"gen_ai.request.*"` string keys
  in the existing `attributes` map.
- **Recommended — reuse ReqLLM's own builder:** call
  `ReqLLM.OpenTelemetry.Attributes.start(metadata)` and `ReqLLM.OpenTelemetry.Attributes.terminal(metadata)`
  from inside the existing `:stop` handler and `Map.merge/2` the results into the span's `attributes` map.
  Both functions only read fields already present in `:stop` metadata (`:operation`, `:model`,
  `:request_options`, `:reasoning`, `:server`, `:finish_reason`, `:usage`, `:response_payload`) — there is
  no need to also attach a `:start` handler or manage cross-event state (ReqLLM's own live bridge needs an
  ETS table to correlate `:start`→`:stop`; Scoria's adapter doesn't, because it only emits on `:stop` and
  both attribute-builder functions are metadata-only, not event-order-dependent). This single call gets
  Scoria the full current `gen_ai.request.*` / `gen_ai.usage.*` / `gen_ai.response.*` set for free,
  automatically staying in sync with future ReqLLM/OTel renames instead of Scoria hand-maintaining its own
  parallel key list.

Sources: `deps/req_llm/lib/req_llm/telemetry.ex` (lines 138–175, 490–500 — vendored source, read directly
at the exact locked version `1.13.0`), `deps/req_llm/lib/req_llm/telemetry/request_options.ex` (full file,
read directly), `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` (full file, read directly),
`lib/scoria/ui_critique.ex:92` (the hardcoded `max_tokens: 2048` breadcrumb named in the seed, confirmed
still present and still the only place in Scoria's own code that sets a generation opt today). Confidence:
HIGH — first-party, exact-version source read, not documentation.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| Conventional string keys in the existing `attributes` jsonb map | Typed Ecto columns for `temperature`/`top_p`/`seed`/`max_tokens`/etc. | Only once the OTel-GenAI namespace is marked Stable (not the case as of this research) *and* Scoria is querying/filtering on these fields at a volume where jsonb GIN-index scans become the bottleneck — not true today at Scoria's scale |
| Reuse ReqLLM's `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` | Hand-roll a parallel `gen_ai.*` key-mapping module inside Scoria | Only if Scoria ever needs attribute names ReqLLM's builder doesn't cover (e.g. a provider Scoria talks to outside ReqLLM) — not the case today; ReqLLM is Scoria's only LLM peer |
| `openinference.span.kind` as a bare string, no library | Full OpenInference OTel Python/JS instrumentation SDKs | N/A — those SDKs don't exist for Elixir; not an option regardless |
| Keep `ai_retrieval_runs` as system-of-record, dual-write a linked `RETRIEVER` span | Collapse retrieval detail entirely into generic spans (the hosted-SaaS-lens memo's original suggestion) | Only if Scoria drops its typed grounding-score/citation model — explicitly rejected by the seed |

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `req_llm 1.13.0` (locked) | `gen_ai.*` semconv naming (schema `1.37.0`, verified in `OTelAdapter`'s `@otel_schema_url`) | Already compatible — no bump needed. Checked CHANGELOG.md `v1.13.0`→`v1.17.1` (current Hex latest) for any further OTel/gen_ai/telemetry/span changes: **none found** — the semconv-naming feature set is unchanged from `1.13.0` through the current `1.17.1`. A `mix deps.update req_llm` is safe/optional hygiene, not required for SEED-007. |
| Scoria `attributes` jsonb map (on `ai_traces`/`ai_spans`) | `gen_ai.*` string keys, `openinference.span.kind` string value | No schema migration — this is a value-shape convention only, confirmed compatible with the existing column type |
| `ai_retrieval_runs.trace_id`/`span_id` | Linked `RETRIEVER` span emission | Columns already exist per the seed's breadcrumb (`lib/scoria/knowledge/retrieval_run.ex`) — unverified by this research pass (out of scope for the STACK question set; confirm in the phase plan) |

## Sources

- [OpenTelemetry Gen AI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/) — confirms docs relocated to `semantic-conventions-genai` repo; MEDIUM (redirect stub, not itself authoritative content)
- `raw.githubusercontent.com/open-telemetry/semantic-conventions-genai/main/docs/gen-ai/gen-ai-attributes.md` — live-fetched full attribute registry with per-attribute stability badges (all `Development`); HIGH (primary spec source, directly fetched 2026-07-11)
- [open-telemetry/semantic-conventions-genai](https://github.com/open-telemetry/semantic-conventions-genai) — GenAI conventions repo (spans, metrics, events, MCP, provider-specific conventions); HIGH
- [OpenTelemetry for Generative AI (blog)](https://opentelemetry.io/blog/2024/otel-generative-ai/) — background/history; MEDIUM
- [Arize-ai/openinference spec/semantic_conventions.md](https://github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md) — live-fetched full span-kind enum + attribute table; HIGH (primary spec source, directly fetched 2026-07-11)
- [Arize Phoenix OpenInference docs](https://arize.com/docs/phoenix/tracing/concepts-tracing/otel-openinference/semantic-conventions) — corroborating; MEDIUM
- `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex`, `deps/req_llm/lib/req_llm/open_telemetry.ex`, `deps/req_llm/lib/req_llm/open_telemetry/sem_conv.ex`, `deps/req_llm/lib/req_llm/telemetry.ex`, `deps/req_llm/lib/req_llm/telemetry/request_options.ex`, `deps/req_llm/CHANGELOG.md` — vendored first-party source at the exact locked version `1.13.0`, read directly; HIGH
- `hex.pm/packages/req_llm/versions` — confirmed current Hex latest `1.17.1` (2026-07-06) vs. locked `1.13.0`; MEDIUM (web-fetched listing)
- `lib/scoria/observe/adapters/req_llm.ex`, `lib/scoria/ui_critique.ex`, `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md`, `.planning/PROJECT.md` — Scoria's own current source/spec; HIGH

---
*Stack research for: SEED-007 Trace Foundation — v3.6 milestone*
*Researched: 2026-07-11*

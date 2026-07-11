# Feature Research

**Domain:** AI trace/observability schema interoperability (OTel-GenAI / OpenInference) for an embedded Phoenix AI-governance library
**Researched:** 2026-07-11
**Confidence:** HIGH on taxonomy/attribute facts (cross-checked against OTel and OpenInference official docs + a real Elixir hex package); MEDIUM on forward-looking claims (context-pack composition — the finding itself is "no peer has standardized this yet," which is inherently more inferential)

## Scope Note

This research answers SEED-007 (v3.6 Trace Foundation): reconciling Scoria's existing 8-value span-kind UI vocabulary (`llm tool prompt mcp retriever guardrail eval agent`, `lib/scoria_web/components/workflow_tree_component.ex:38`) against OTel-GenAI/OpenInference peer conventions, validating the spans-vs-events emission split, and categorizing model-config/retrieval/context-pack/host-tag capture as table stakes, differentiators, or anti-features. Two corrections to the seed's own framing surfaced during research — see Span-Kind Mapping.

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Correct span-kind enum on every span, not a free-text/2-value string | Every peer (OpenInference's 10-value `openinference.span.kind`; OTel's `gen_ai.operation.name` = `chat`/`embeddings`/`execute_tool`/`invoke_agent`) treats span-kind as the primary trace-tree organizing attribute. Scoria's own dashboard UI already assumes an 8-value enum but the 2 live adapters emit only `"LLM"`/`"INTERNAL"`. | LOW | This is "finish the half-built thing," not new design — see PITFALLS-adjacent framing in SEED-007. |
| `gen_ai.request.*` model-config attributes on every LLM span (`temperature`, `top_p`, `max_tokens`, `seed` at minimum) | The literal OTel-official attribute names, and table stakes for Scoria's own replay/recovery claim — replay without model params is silently wrong. | LOW | Params already sit in ReqLLM request opts; only wiring is missing. A real Elixir hex package (`opentelemetry_semantic_conventions` v1.27.0, `opentelemetry-semantic-conventions.hexdocs.pm/gen-ai.html`) already defines these as constants — worth depending on directly or mirroring key-for-key. |
| `gen_ai.usage.input_tokens`/`output_tokens` + `gen_ai.response.model`/`id`/`finish_reasons` on LLM spans | Cost/latency attribution is the #1 reason teams adopt any trace tooling. | LOW | Currently only a non-conventional `"llm.token_count"` total is captured (`lib/scoria/observe/adapters/req_llm.ex:18`) — no input/output split. |
| `openinference.span.kind` portability attribute written alongside Scoria's own `span_kind` column | This is the literal "your traces aren't locked into Scoria" claim — any OTel/OpenInference-reading backend (Langfuse, Arize Phoenix, Datadog) must be able to render the trace with zero translation layer on the reader's side. | LOW | Must be an *exact-string match* to the OpenInference enum (uppercase `LLM`/`TOOL`/etc.), which differs from Scoria's own lowercase UI vocabulary — requires a small translation table at write time (see Span-Kind Mapping). |
| Tool/retrieval/guardrail/prompt-render emitted as real child **spans** with `parent_id` linkage, not point events | Every peer (OTel `execute_tool`; OpenInference `TOOL`/`RETRIEVER`/`PROMPT`/`GUARDRAIL`) models these as spans because they have duration and can independently fail/error. | MEDIUM | New emission call sites needed in both adapters plus guardrail/prompt-render code paths. Validated below in Spans vs Events. |
| Host-declared tag/metadata attributes for later segmentation | Langfuse's `tags`/`metadata`/`propagate_attributes()`, LangSmith, and every serious trace backend give hosts a supported way to stamp spans/traces with app-level dimensions; without it operators can't answer "which feature/route is expensive, slow, or wrong." | LOW | Scoria just needs to reserve + document the key names; the host writes the values. |
| `RETRIEVER` span linked via `trace_id`/`span_id` surfacing query/`top_k`/backend | RAG is now a default pattern; every RAG-aware trace tool treats retrieval as a first-class traced step, not an opaque sub-call inside the LLM span. | LOW | `ai_retrieval_runs` already has `trace_id`/`span_id` columns (`lib/scoria/knowledge/retrieval_run.ex:16-17`) — plumbing exists, unemitted. |
| Point-event vocabulary for content-bearing / instantaneous signals, separate from structural spans (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) | OTel's own GenAI spec puts full prompt/completion **content** on events (via the Logs API signal), not span attributes — specifically because it's opt-in and PII-sensitive, and because these moments have no meaningful duration. | LOW-MEDIUM | Resurrects `ai_span_events` (`lib/scoria/repo/span_event.ex`, currently dead — belongs_to a span, `name`/`time`/`attributes`). Functionally equivalent to OTel's Logs-signal approach but stays inside the same table family (matches scope doctrine P5: reconstructable in the host's own DB). |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `embedding_model` / `index_version` / `reranker` fields on the `RETRIEVER` span (not separate spans) | This is exactly the "attribute a quality delta to a retrieval config" claim the whole milestone exists for. `index_version` in particular has **no OpenInference/OTel equivalent** — peers don't version their knowledge base in-span. | LOW | Field-on-span, not a new span kind — matches the convention-over-columns discipline. |
| Context-pack / token-budget composition capture — which chunks + which memories + the token split that actually entered the assembled prompt, alongside `gen_ai.usage.input_tokens` | Multiple independent industry sources describe this as an unsolved, manually-instrumented gap: *"did retrieval miss the evidence, or did prompt assembly drop it?"* No current OTel or OpenInference attribute answers this. Being early here is the differentiator, and it is the single highest-leverage attribute for this milestone's actual stated goal. | LOW | Convention-key-only, riding the existing `PROMPT` span's attributes map — no new primitive. Keep scope narrow: chunk IDs + per-source token counts, not full chunk text (already covered by `ai_retrieval_runs`/`evidence_refs`). |
| Host-declared `archetype`/`intent` as reserved, *documented* keys (vs. Langfuse's fully generic open metadata bag) | Scoria ships an opinionated, pre-named taxonomy rather than an open bag — this becomes the stable join key SEED-012 (per-route analytics) and SEED-013 (scope bar) read with **zero new primitive**. A generic bag doesn't buy that cross-seed leverage. | LOW | Host declares; Scoria never infers (see Anti-Features). |
| `RETRIEVER` span dual-written alongside the richer `ai_retrieval_runs` system-of-record | Gives portability (any OTel/OpenInference backend sees a real `RETRIEVER` span) without losing typed grounding-score/result detail no generic attributes-map span could hold. | LOW-MEDIUM | Write to both; no migration, no collapse. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Auto-inferred `archetype`/`intent`/`feature` classifier | "Scoria could just detect what kind of request this is" | Violates Scoria's own scope doctrine (P1 business-truth / P2 opinion) — Scoria doesn't get to assert what a request *means*, only record what the host declares. An inferred label baked into governance evidence is a guess presented as fact. | Host declares via the reserved attribute keys; Scoria documents the convention and stays silent (no key) if the host doesn't set it. |
| Typed columns per `gen_ai`/`openinference` attribute (a schema rewrite) | Type safety, indexable queries | Rigid columns invite migration churn pre-1.0 and lock Scoria to today's exact attribute set — which upstream itself still marks **Experimental** and has already renamed once (`gen_ai.system` → `gen_ai.provider.name`). | Conventional key names on the existing jsonb `attributes` map (LOCKED discipline per SEED-007). |
| Forcing every span kind through `ai_span_events` instead of real child spans | "Just log events, simpler than a span tree" | Loses duration/error/parent-child structure every peer (OTel `execute_tool`; OpenInference `TOOL`/`RETRIEVER`/`PROMPT`/`GUARDRAIL`) treats as span-shaped — would be a strictly worse trace model than every reference implementation. | Structural steps are spans; only true instantaneous/content-bearing signals are events (see Spans vs Events verdict). |
| Collapsing `ai_retrieval_runs` into a generic span and dropping the table | "One trace model, less code" | Loses typed grounding scores and typed retrieval results a generic attributes-map span can't hold without becoming its own mini-schema; breaks the existing system-of-record other subsystems already read. | Dual-write: span for visibility/portability, table for detail — already the seed's decision, reconfirmed by this research. |
| A metrics/analytics warehouse inside Scoria (cost dashboards, alerting, time-series rollups, cross-trace aggregation) | "We already have the spans, may as well chart them" | Violates scope doctrine P6 — Scoria is BEAM-native/embedded, not a hosted analytics platform. Every peer that does this (Langfuse, Arize, Datadog) is a *separate hosted product*, not a library. | Emit OTel-shaped/OpenInference-tagged spans; let the host export to its own backend for warehousing — the literal "hook at the edges" framing in the seed. |
| Always-on, unredacted full prompt/completion text on every LLM/PROMPT span **attribute** | "More debugging detail is always better" | OTel's own spec deliberately keeps full content OFF span attributes and ON opt-in Logs-API events, specifically for PII/proprietary-data risk. Scoria already has a `Redactor` in the observe pipeline (`lib/scoria/observe/redactor.ex`) — content-bearing point-events must route through it, not bypass it. | `prompt_rendered` event carries content, gated through existing redaction; span attributes stay metadata-only (template id, token counts, status). |
| A literal `CHAIN` span kind mirroring OpenInference 1:1 | "Peer parity — match their full enum" | OpenInference needs `CHAIN` because it has no native workflow/run concept. Scoria already has `ai_traces` + a durable workflow-run model playing the same "glue/start" role — a `CHAIN` kind would be redundant with no distinct UI or attribution use. | Leave it out; document the non-gap explicitly so it isn't "discovered missing" in a later audit. |
| A separate `EMBEDDING` or `RERANKER` span kind in this milestone | "Closer 1:1 OpenInference parity" | Scope-creep against SEED-007's own "medium-large, not a rewrite" estimate. Neither embedding calls (today folded inside semantic cache / retrieval) nor reranking are yet operator-visible pain points needing independent latency/failure attribution. | Keep `embedding_model`/`reranker` as fields on the `RETRIEVER` span now (already the seed's plan); promote to standalone kinds only if a real attribution need for those specific steps appears later. |

## Span-Kind Mapping (Scoria ↔ Peers)

| Scoria `span_kind` | Peer equivalent | Clean match? | Notes |
|---|---|---|---|
| `llm` | OpenInference `LLM` / OTel `gen_ai.operation.name=chat` | Clean | Direct 1:1. |
| `tool` | OpenInference `TOOL` / OTel `execute_tool` | Clean | Direct 1:1. |
| `prompt` | OpenInference `PROMPT` ("a span that represents the rendering of a prompt template") | Clean — **not Scoria-specific** | **Correction to the seed:** SEED-007 frames `prompt` as one of two Scoria-specific kinds. OpenInference has had an explicit `PROMPT` kind in its spec all along — this maps cleanly, no divergence to document. |
| `mcp` | No direct OpenInference kind. OTel has a *separate* MCP semantic-conventions track (`mcp.method.name`, `mcp.session.id`, `mcp.protocol.version`) layered on top of what is otherwise a `TOOL`-shaped span. | Hybrid | **Correction to the seed:** `mcp` is not purely invented by Scoria either — OTel has real MCP semconv, just not as an `openinference.span.kind` value. Recommendation: keep `mcp` as Scoria's own `span_kind` (defensible — a remote connector call crosses a real trust/auth boundary distinct from a local tool call, which is the whole point of the Switchyard connector subsystem), but when writing the `openinference.span.kind` portability attribute, map `mcp` → `"TOOL"` and add `mcp.method.name`/`mcp.session.id`/`mcp.protocol.version` as attributes for full peer conformance. |
| `retriever` | OpenInference `RETRIEVER` | Clean | Direct 1:1. |
| `guardrail` | OpenInference `GUARDRAIL` | Clean | Direct 1:1. |
| `eval` | OpenInference `EVALUATOR` | Clean (name differs) | Same concept; keep `eval` as Scoria's internal short name, use `"EVALUATOR"` for the `openinference.span.kind` portability value. |
| `agent` | OpenInference `AGENT` / OTel `invoke_agent` | Clean | Direct 1:1. |
| *(none)* | OpenInference `EMBEDDING` | Missing — deferred | Not built this milestone. Embedding calls stay implicit inside the `RETRIEVER` span's `embedding_model` field. Candidate future 9th kind only if semantic-cache embed steps need independent tracing. |
| *(none)* | OpenInference `CHAIN` | Missing — **intentional non-gap** | Scoria's `ai_traces`/workflow-run model already plays this role. Do not add (see Anti-Features). |
| *(none)* | OpenInference `RERANKER` | Missing — deferred | Reranker stays a field on the `RETRIEVER` span per the seed's plan. Candidate future 9th kind only if reranking latency becomes its own attribution target. |

**Net result:** 7 of Scoria's 8 kinds (`llm`, `tool`, `prompt`, `retriever`, `guardrail`, `eval`, `agent`) map cleanly 1:1 onto peer conventions. 1 (`mcp`) is a legitimate hybrid — Scoria keeps it as a top-level UI/attribution kind but must translate to `TOOL` + `mcp.*` attributes for portability. Of the 10 OpenInference kinds, Scoria is missing 3: `EMBEDDING` and `RERANKER` are reasonable v3.6 scope deferrals (field-not-span for now), `CHAIN` is an intentional non-gap because Scoria's workflow/trace model already fills that role.

## Spans vs Events — Validated

**Verdict: the seed's decision is correct.** OTel's own GenAI spec draws the same line Scoria proposes, just via a different mechanism: structural steps with duration and failure modes go on **spans** (`chat`, `execute_tool`, `invoke_agent` are real OTel spans; OpenInference's `TOOL`/`RETRIEVER`/`PROMPT`/`GUARDRAIL` are span kinds, not events) — this validates emitting `tool`/`prompt`/`retrieval`/`guardrail` as child spans. Full prompt/completion **content**, by contrast, is deliberately kept off span attributes and instead emitted via OTel's Logs-API events signal, specifically because content is opt-in and PII/proprietary-data-sensitive and has no duration of its own — this validates resurrecting `ai_span_events` narrowly for content-bearing/instantaneous signals only (`prompt_rendered`, `guardrail_triggered`) rather than forcing the whole kind vocabulary through it.

One nuance worth flagging to the roadmap (not a peer-precedent question, an implementation risk): `prompt_rendered` and `guardrail_triggered` fire inline during their parent span's execution, so they have a natural `span_id` at insert time. `user_feedback_received` is the odd one out — feedback often arrives asynchronously, after the span/trace it references may be long closed. `Scoria.Repo.SpanEvent`'s `belongs_to :span` FK must still resolve at insert time even when feedback lands minutes or hours later. Small design note for planning, not a blocker.

## Context-Pack / Token-Budget Composition — Table Stakes vs Differentiator

**Categorized as Differentiator, not table stakes.** Neither the OTel GenAI attribute registry nor the OpenInference spec has a standardized context-pack/composition attribute as of this research. Every RAG-observability discussion found treats "which chunks/memories actually entered the assembled prompt, and what was the token split" as a real, common, and currently *manually instrumented* pain point — it is the direct answer to "did retrieval miss the evidence, or did prompt-assembly drop it?" Recommend building it (it's the highest-leverage single attribute for this milestone's stated goal of attributing a quality delta to what the model actually saw), but categorize it as a differentiator so the roadmap doesn't treat it as launch-blocking if time-constrained. Keep scope to convention keys on the existing `PROMPT` span (chunk IDs + per-source token counts) — not full chunk text, which `ai_retrieval_runs`/`evidence_refs` already own.

## Host-Declared Attribute Convention — Table Stakes vs Differentiator

**Split verdict.** The *capability* — letting a host stamp spans/traces with app-level dimensions for later segmentation — is unambiguous table stakes; Langfuse (`tags` + `metadata` + `propagate_attributes()`), LangSmith, and every serious trace backend supports it, and without it operators cannot answer "which feature/route is expensive, slow, or wrong." Scoria's specific choice to pre-name 4 reserved keys (`feature`/`route`/`archetype`/`intent`) rather than expose an open bag is the differentiator — it turns the convention into a stable, discoverable, cross-seed contract (SEED-012 per-route analytics, SEED-013 scope bar) instead of an ad hoc key namespace every host reinvents. The hard boundary either way: Scoria documents and reserves the keys; it must never populate them itself (see Anti-Features — auto-inferred classifier).

## Feature Dependencies

```
span_kind taxonomy fix (8-value enum + openinference.span.kind mapping)
    └──requires (blocks)──> structured span emission (tool/prompt/retrieval/guardrail as child spans)
                                └──requires──> ai_span_events resurrection (point-events need a stable parent span_id)

ai_retrieval_runs (already has trace_id/span_id)
    └──enables──> RETRIEVER span emission (linking only; no migration for the link)
                     └──requires (new fields)──> embedding_model / index_version / reranker migration on ai_retrieval_runs

structured PROMPT span existing
    └──requires (foundation for)──> context-pack / token-budget composition keys (rides the PROMPT span's attributes map)

host-declared feature/route/archetype/intent
    (no dependency on anything else in this milestone — pure documentation + reserved-key convention, can ship first/independently)

README accuracy fix ("OpenInference-compatible")
    └──depends on──> span_kind taxonomy fix actually landing (can't claim compatibility before span_kind values match the enum)
```

### Dependency Notes

- **Structured span emission requires the span-kind taxonomy fix first:** there's no stable "kind" to attach a child span to until the 8-value convention (plus the `openinference.span.kind` translation table) is in place.
- **`ai_span_events` resurrection is a hard prerequisite for the point-event vocabulary**, not optional plumbing — the dead schema (`lib/scoria/repo/span_event.ex`) has no migration currently applied/used; this must land before `prompt_rendered`/`guardrail_triggered`/`user_feedback_received` emission code exists.
- **`ai_retrieval_runs` needs no new migration for `trace_id`/`span_id` linkage** (already present) but does need one for the 3 new fields (`embedding_model`/`index_version`/`reranker`) — small, additive, no collapse of the table.
- **Context-pack capture rides the `PROMPT` span**, so it is sequenced after structured span emission, not parallel to it.
- **Host-declared attributes have zero technical dependency** on the rest of the milestone and are the safest first-landed piece — pure naming/documentation.

## MVP Definition

Framed as "must ship this milestone" vs. "safe to defer," since SEED-007 is a single scoped milestone, not a multi-release roadmap.

### Launch With (v3.6)

- [ ] `span_kind` taxonomy fix (8-value convention, both adapters stop emitting `"LLM"`/`"INTERNAL"` only) + `openinference.span.kind` portability attribute with the `mcp`→`TOOL` translation
- [ ] `gen_ai.request.*` (temperature/top_p/max_tokens/seed) + `gen_ai.usage.*`/`gen_ai.response.*` on LLM spans
- [ ] `tool`/`prompt`/`retrieval`/`guardrail` emitted as real child spans
- [ ] `ai_span_events` resurrected, scoped to exactly 3 point-events (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`)
- [ ] `RETRIEVER` span emission + `embedding_model`/`index_version`/`reranker` fields, `ai_retrieval_runs` kept as system-of-record
- [ ] Host-declared `feature`/`route`/`archetype`/`intent` reserved keys, documented
- [ ] README accuracy fix ("OpenInference-style" → "OpenInference-compatible")

### Add After Validation (v3.6 stretch / fast-follow)

- [ ] Context-pack / token-budget composition keys — differentiator-tier, not launch-blocking; first candidate to slip if the milestone runs long

### Future Consideration (v3.7+)

- [ ] `EMBEDDING` span kind — only if semantic-cache embed steps need independent tracing
- [ ] `RERANKER` span kind — only if reranking latency becomes its own attribution target
- [ ] Track upstream `gen_ai.system` → `gen_ai.provider.name` rename (OTel GenAI semconv is still Experimental-stability; expect further churn before it stabilizes)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `span_kind` taxonomy fix + `openinference.span.kind` | HIGH | LOW | P1 |
| `gen_ai.request.*`/`usage.*` model-config capture | HIGH | LOW | P1 |
| Structured tool/prompt/retrieval/guardrail child spans | HIGH | MEDIUM | P1 |
| `ai_span_events` resurrection (3 point-events) | MEDIUM | LOW-MEDIUM | P1 |
| `RETRIEVER` span + embedding_model/index_version/reranker | HIGH | LOW | P1 |
| Host-declared feature/route/archetype/intent | MEDIUM | LOW | P1 |
| README accuracy fix | LOW (trust-adjacent) | LOW | P1 |
| Context-pack / token-budget composition | HIGH (for eval attribution) | LOW | P2 |
| `EMBEDDING` span kind | LOW (no current pain signal) | MEDIUM | P3 |
| `RERANKER` span kind | LOW (no current pain signal) | LOW-MEDIUM | P3 |

**Priority key:**
- P1: Must have for this milestone (SEED-007 scope)
- P2: Should have, add if time allows within this milestone
- P3: Future milestone, only if a concrete operator need appears

## Competitor Feature Analysis

| Feature | OpenInference (Arize Phoenix) | Langfuse / LangSmith (OTel-native) | Scoria's Approach |
|---------|-------------------------------|-------------------------------------|--------------------|
| Span-kind taxonomy | 10-value enum (`LLM`/`CHAIN`/`RETRIEVER`/`EMBEDDING`/`TOOL`/`RERANKER`/`AGENT`/`GUARDRAIL`/`EVALUATOR`/`PROMPT`) as a span attribute | Uses OTel spans directly + own UI-level grouping | 8-value enum on a real `span_kind` column, mapped down to the OpenInference attribute value for portability |
| Content capture | Not explicitly separated from spans in OpenInference's own spec | OTel GenAI puts content on opt-in Logs-API events | Content-bearing point-events via resurrected `ai_span_events`, gated through existing `Redactor` |
| Host tagging for segmentation | Generic `metadata`/`tag.tags` | Explicit `tags` + `metadata` + `propagate_attributes()` | Reserved, pre-named `feature`/`route`/`archetype`/`intent` keys — narrower but more discoverable/joinable |
| Retrieval detail | `retrieval.documents` (id/content/score/metadata) on the `RETRIEVER` span itself | Similar generic document-list attributes | Kept in typed `ai_retrieval_runs` table (grounding scores, typed results); `RETRIEVER` span is a portability projection, not the source of record |
| Context-pack composition | Not standardized | Not standardized (ad hoc per-team instrumentation described in RAG-observability write-ups) | Convention-key addition on the `PROMPT` span — a genuine differentiator, no peer has this |
| Analytics/warehousing | Yes — Arize is itself a hosted analytics platform | Yes — both are hosted SaaS platforms | Explicitly NOT built — scope doctrine P6 keeps this a hook-at-the-edges export, not a Scoria feature |

## Sources

- [OpenInference Semantic Conventions (spec)](https://arize-ai.github.io/openinference/spec/semantic_conventions.html) — HIGH confidence, official spec, primary source for the full span-kind enumeration (including `PROMPT`) and per-kind descriptions
- [openinference/spec/semantic_conventions.md (GitHub source)](https://github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md) — HIGH confidence, official source doc, primary source for RETRIEVER/TOOL/EMBEDDING attribute names and session/user/metadata tagging conventions
- [OpenInference Specification index](https://arize-ai.github.io/openinference/spec/) — HIGH confidence, official spec
- [OpenTelemetry Gen AI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/) — HIGH confidence, official OTel docs, source for `gen_ai.request.*`/`usage.*`/`response.*`/`operation.name` attribute names (Experimental stability, moved to a dedicated genai-semconv repo)
- [OpenTelemetry GenAI Semantic Conventions Elixir hex package docs](https://opentelemetry-semantic-conventions.hexdocs.pm/gen-ai.html) — HIGH confidence, real published Hex package (`opentelemetry_semantic_conventions` v1.27.0), confirms exact attribute names/types/examples and that an Elixir-native dependency already exists for this convention
- [OpenTelemetry: Inside the LLM Call — GenAI Observability with OpenTelemetry](https://opentelemetry.io/blog/2026/genai-observability/) — HIGH confidence, official OTel blog, source for the events-vs-spans content-capture model (`invoke_agent`/`chat`/`execute_tool` span tree; content on opt-in Logs-API events)
- [OpenTelemetry semantic conventions for MCP](https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/) and [MCP attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/mcp/) — HIGH confidence, official OTel docs, source for `mcp.method.name`/`mcp.session.id`/`mcp.protocol.version` and the finding that MCP is a semconv layer on TOOL-shaped spans, not its own OpenInference kind
- [Langfuse: Metadata](https://langfuse.com/docs/observability/features/metadata) and [Langfuse: Tags](https://langfuse.com/docs/observability/features/tags) — HIGH confidence, official vendor docs, source for the host-tagging/segmentation table-stakes finding
- Corroborating secondary sources (MEDIUM confidence, used only to cross-check patterns already confirmed by official docs above, not as sole basis for any claim): techbytes.app OTel GenAI Agent SemConv Cheat Sheet, greptime.com OTel GenAI blog, oneuptime.com GenAI prompt/completion capture post, multiple RAG-observability write-ups (72technologies, dev.to, ragaboutit) on context-window/token-budget instrumentation gaps
- Local codebase: `lib/scoria_web/components/workflow_tree_component.ex`, `lib/scoria/knowledge/retrieval_run.ex`, `lib/scoria/repo/span.ex`, `lib/scoria/repo/span_event.ex`, `lib/scoria/observe/adapters/req_llm.ex`, `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md`

---
*Feature research for: OTel-GenAI / OpenInference trace interop (SEED-007, v3.6 Trace Foundation)*
*Researched: 2026-07-11*

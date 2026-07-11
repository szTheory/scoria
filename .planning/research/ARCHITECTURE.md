# Architecture Research: v3.6 Trace Foundation (SEED-007)

**Domain:** internal integration architecture — OTel-GenAI / OpenInference key convention over Scoria's existing embedded trace subsystem
**Researched:** 2026-07-11
**Confidence:** HIGH (grounded directly in the real source tree — `lib/scoria/observe/**`, `lib/scoria/repo/{span,span_event,trace}.ex`, `lib/scoria/knowledge.ex`, migrations, tests, and the `req_llm` dependency source at the locked version `1.13.0`)

This is not a greenfield "what does the ecosystem look like" survey — SEED-007 finishes a subsystem Scoria already half-built. Every claim below is traced to a real file/line so the roadmapper can plan phases against ground truth, not the seed's paraphrase of it.

## System Overview — Current State (as-built)

```
┌───────────────────────────────────────────────────────────────────────────┐
│  EMITTERS (2 adapters, telemetry-attached)                                │
│  lib/scoria/observe/adapters/req_llm.ex   — [:req_llm, :request, :stop]   │
│  lib/scoria/observe/adapters/jido.ex      — [:jido, :action, :stop]       │
│  span_kind hardcoded: "LLM" / "INTERNAL"  (not lowercase, not in UI's set)│
└──────────────────────────┬──────────────────────────────────────────────┘
                            │ :telemetry.execute([:scoria,:observe,:span,:stop], %{}, span_map)
                            ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Scoria.Observe.Telemetry (lib/scoria/observe/telemetry.ex)               │
│  attaches [:scoria,:observe,:span,:stop] + [...,:span,:delta]             │
│  → Redactor.redact/1 (key-exact-match deny-list scrub)                    │
│  → ReviewerBroadcast.span_stopped/1 (live PubSub, tenant-scoped)          │
│  → Buffer.cast_span(Map.take(redacted, @span_buffer_fields))              │
│     @span_buffer_fields = id trace_id parent_id name span_kind            │
│                           status_code start_time end_time attributes      │
└──────────────────────────┬──────────────────────────────────────────────┘
                            │ GenServer.cast
                            ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Scoria.Observe.Buffer (lib/scoria/observe/buffer.ex)                     │
│  in-memory list, flush every 5s OR at 1000 spans                          │
│  flush_spans/1 → Repo.insert_all(Scoria.Repo.Span, entries)  [SPANS ONLY] │
│  NO event buffering path exists. NO trace-row upsert exists.              │
└──────────────────────────┬──────────────────────────────────────────────┘
                            ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Postgres: ai_traces ← ai_spans ← ai_span_events (FK chain, all 3 tables  │
│  ALREADY EXIST — migration 20260510015813 created all three together)    │
│  ai_spans.trace_id  references ai_traces(id), null: false                 │
│  ai_span_events.span_id references ai_spans(id), null: false              │
└───────────────────────────────────────────────────────────────────────────┘

  Parallel, currently disconnected system-of-record:
  ai_retrieval_runs (lib/scoria/knowledge/retrieval_run.ex) — has trace_id/
  span_id columns, populated by callers, but Knowledge.retrieve/2
  (lib/scoria/knowledge.ex:215-257) never calls into Observe at all.

  ai_approvals (lib/scoria/observe/approval.ex) — same shape of problem:
  a rich system-of-record HITL/guardrail table with a `trace_id` column and
  no telemetry emission wired to it. Relevant precedent for item 3's
  guardrail_triggered event (see "Dual-Write Pattern" below).
```

### Correction to the seed's framing

`ai_span_events` is **not a dead schema at the DB/Ecto level** — it is a fully migrated table (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`) with a working `Scoria.Repo.SpanEvent` schema+changeset (`lib/scoria/repo/span_event.ex`), a `has_many(:events, ...)` already declared on `Scoria.Repo.Span` (`lib/scoria/repo/span.ex:16`), and a passing standalone unit test (`test/scoria/repo/span_event_test.exs`) that proves `Repo.insert(SpanEvent.changeset(...))` works. What's actually dead is the **ingestion path**: no `:telemetry` event channel, no `Telemetry.handle_event/4` clause, and no `Buffer` capacity ever produces an event row outside a test that hand-builds one. "Resurrection" is 100% application-layer wiring — zero migration work.

### Pre-existing gap this milestone inherits (flag for phase 0 / phase 1)

**No production code path inserts a row into `ai_traces`.** Grep-confirmed: the only places that construct `%Scoria.Repo.Trace{}` are `test/scoria/observe/buffer_test.exs` and `test/scoria/repo/span_event_test.exs` (both manually pre-insert a `Trace` before inserting a `Span`). `Buffer.flush_spans/1` (`lib/scoria/observe/buffer.ex:64-81`) calls `Repo.insert_all(Scoria.Repo.Span, entries)` directly against spans whose `trace_id` is either passed in from metadata or `Ecto.UUID.generate()`'d fresh by an adapter (`req_llm.ex:31`, `jido.ex:27`) — in both cases nothing ever creates the matching `ai_traces` row. Because `ai_spans.trace_id` is `null: false, references(:ai_traces)`, this insert should be rejected by Postgres FK enforcement in real (non-test) usage; the `rescue` in `flush_spans/1` (`buffer.ex:75-80`) swallows the error and only logs it. **This means span persistence may already be silently broken for any span whose trace_id isn't already backed by a Trace row created some other way.** This is upstream of SEED-007 proper, but every deliverable in this milestone (convention keys, RETRIEVER span, span_events) writes through this same path and will be equally silently dropped if unaddressed. Recommend treating "trace upsert on write" as a load-bearing prerequisite of Phase 1, not a separate ticket — see Build Order below.

## Component Responsibilities

| Component | File | Today | Change needed |
|-----------|------|-------|----------------|
| ReqLLM adapter | `lib/scoria/observe/adapters/req_llm.ex` | Reads `metadata[:model]`, `measurements[:total_tokens]`, `metadata[:url]`; hardcodes `span_kind: "LLM"` | **MODIFY**: merge `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` output (already ships in the locked `req_llm 1.13.0` dep) into `attributes`; set `span_kind` from `metadata[:operation]` not a literal; drop the non-standard `req.url`/`llm.*` keys once `gen_ai.*` covers them |
| Jido adapter | `lib/scoria/observe/adapters/jido.ex` | Hardcodes `span_kind: "INTERNAL"` — not in either UI allow-list, silently normalizes to `"agent"` | **MODIFY**: map `action_name`/action taxonomy to a real span kind (`tool` is the likely default; needs a planning decision, not fabricated here) |
| `Scoria.Observe.Telemetry` | `lib/scoria/observe/telemetry.ex` | 2 event clauses: `:stop` (spans) and `:delta` (streaming chunks) | **MODIFY**: add a 3rd clause for point-events (`[:scoria, :observe, :event, :emit]`) running the same `Redactor.redact/1` pass; add public `emit_event/1` mirroring the existing `emit_span_delta/1` doc-comment pattern (line 20-26) |
| `Scoria.Observe.Buffer` | `lib/scoria/observe/buffer.ex` | Single `spans` list, single `flush_spans/1` | **MODIFY**: add a second `events` list + `cast_event/2` + folded into the same flush cycle; add a trace-upsert step ordered *before* span insert in the same flush; span insert must be ordered before event insert (event FK depends on span existing) |
| `Scoria.Repo.SpanEvent` | `lib/scoria/repo/span_event.ex` | Complete schema, unused in production | **NO CHANGE** to schema/changeset — wire the ingestion path around it |
| `Scoria.Knowledge.retrieve/2` | `lib/scoria/knowledge.ex:215-257` | Accepts `opts[:trace_id]`/`opts[:span_id]`, writes them onto `ai_retrieval_runs`, never touches Observe | **MODIFY**: after (or wrapping) `create_retrieval_run/1`, `:telemetry.execute([:scoria, :observe, :span, :stop], ...)` with `span_kind: "retriever"` using the *same* trace_id/span_id/latency already computed for the row |
| `Scoria.Knowledge.RetrievalRun` | `lib/scoria/knowledge/retrieval_run.ex` | Has `trace_id`, `span_id`, `metadata` (jsonb, unused convention surface) | **MODIFY**: no migration needed — `embedding_model`/`index_version`/`reranker` fit as conventional keys inside the existing `metadata` map, mirroring the same convention-over-columns discipline the milestone locks for spans (see Redaction & Data Model sections) |
| `Scoria.Observe.Approval` | `lib/scoria/observe/approval.ex` | Rich HITL/guardrail system-of-record (`ai_approvals`), has `trace_id`, no span/event emission | **REFERENCE ONLY this milestone** (not in SEED-007's explicit scope) but is the natural future call site for `guardrail_triggered` — flag as the seam SEED-008 or a SEED-007 follow-up phase will use |
| `ScoriaWeb.WorkflowTreeComponent` | `lib/scoria_web/components/workflow_tree_component.ex:38` | Hardcodes an 8-kind allow-list `~w(llm tool prompt mcp retriever guardrail eval agent)` | **NO CHANGE required for this milestone**, but flagged: this list and TraceTreeComponent's list have already drifted (see next row) — both should eventually read one canonical source |
| `ScoriaWeb.TraceTreeComponent` | `lib/scoria_web/components/trace_tree_component.ex:86-93` | Hardcodes a **9**-kind allow-list `~w(agent llm prompt tool mcp retriever guardrail eval error)` (adds `error`, which OpenInference doesn't treat as a span kind) — unmatched kinds silently fall back to `"agent"` | **NO CHANGE required for this milestone** (adapters just need to emit values *inside* this existing allow-list); worth a one-line note in the phase plan that `"error"` is a status, not a kind, and the two lists disagree |

## Data Model — Convention, Not Columns

`ai_traces`, `ai_spans`, `ai_span_events` keep their current shape (`attributes: :map` jsonb on trace/span, `attributes: :map` jsonb on event). SEED-007 does **not** add typed columns to any of these three tables. All 5 "what to build" items are key-naming work inside the existing jsonb maps:

| Convention key | Where written | Confirmed source of the value |
|---|---|---|
| `gen_ai.provider.name`, `gen_ai.operation.name`, `gen_ai.request.model` | `req_llm.ex` adapter, on span start | `ReqLLM.OpenTelemetry.Attributes.start/1` — already computes this exact map from `[:req_llm, :request, :stop]` metadata (see below) |
| `gen_ai.request.temperature`, `.top_p`, `.top_k`, `.max_tokens`, `.seed`, `.frequency_penalty`, `.presence_penalty`, `.stop_sequences` | `req_llm.ex` adapter | `metadata[:request_options]` — built by `ReqLLM.Telemetry.RequestOptions.extract/2` in the dep, already 1:1 OTel-shaped (its own moduledoc says so) |
| `gen_ai.usage.input_tokens`, `.output_tokens`, `.cache_read.input_tokens`, `.cost` | `req_llm.ex` adapter | `ReqLLM.OpenTelemetry.Attributes.terminal/1`, from `metadata[:usage]` |
| `openinference.span.kind` | every adapter, mirrored from the top-level `span_kind` column | New — adapters must set both the DB column (for the UI's existing badge/rail rendering) and the attribute (for portability/export) |
| `feature`, `route`, `archetype`, `intent` (host-declared) | wherever the host calls into the runtime/prompt/LLM path — **Scoria never infers these**, it only reserves the key names and passes through whatever the host puts in `opts`/metadata | No current call site threads these; this is new plumbing through whatever request-context map already flows adapter-ward (`metadata[:tenant_id]`/`metadata[:workflow_run_id]` is the existing precedent for "caller-supplied identity fields make it into `attributes`") |
| context-pack / token-split composition (chunk IDs, memory IDs, token counts — **not raw text**) | wherever context assembly happens ahead of the LLM call (no dedicated module found; likely added inside the prompt-render step being built for item 3) | New |
| `embedding_model`, `index_version`, `reranker` | `Knowledge.retrieve/2`, written into **both** the RETRIEVER span's `attributes` and `ai_retrieval_runs.metadata` | New — recommend the map, not new columns, on `RetrievalRun` too, for consistency; see Component table above |

### `ReqLLM.OpenTelemetry.Attributes` — do not re-derive this by hand

This is the single most consequential finding for scoping items 1 and 2. The locked `req_llm` dependency (`~> 1.13`, `1.13.0` in `mix.lock`) already ships `ReqLLM.OpenTelemetry.Attributes.start/1` and `.terminal/1` (`deps/req_llm/lib/req_llm/open_telemetry/attributes.ex`), which builds the *exact* `gen_ai.*` binary-keyed attribute map (provider, operation, request params, usage, response id/model, finish reasons, embeddings dims) straight from the same `[:req_llm, :request, :stop]` metadata Scoria's adapter already receives. The adapter's job shrinks to: call both functions, merge their output into `attributes`, keep the existing `tenant_id`/`workflow_run_id` keys alongside them. This eliminates hand-naming ~15 keys and any risk of Scoria's convention drifting from the upstream library's — they'll be byte-identical to what ReqLLM's own OTel bridge (`ReqLLM.OpenTelemetry`) would emit if a host wired real OTel instead.

## Integration Points (answering the 5 numbered questions)

### 1. Where conventional keys get written / where `span_kind` gets set

Write path is exactly as the seed described, confirmed end-to-end: **adapter → `:telemetry.execute([:scoria,:observe,:span,:stop])` → `Telemetry.handle_event/4` → `Redactor.redact/1` → `Buffer.cast_span/2` (in-memory) → periodic `Repo.insert_all(Scoria.Repo.Span, entries)`**. `Telemetry.handle_event/4` is a *pass-through* for `span_kind` and all `attributes` keys — it does no naming, mapping, or classification of its own; it only redacts and routes. That means **all convention-key and `span_kind` work belongs at the adapter layer**, not in `telemetry.ex`. Concretely: `req_llm.ex:26-38` and `jido.ex:24-36` are the only two places `span_kind:` gets set today, and both are literals. Fix both to compute the value from real metadata (`operation`/`action_name`) instead of a hardcoded string, and mirror the same value into `attributes["openinference.span.kind"]` at the same call site. `Buffer` and `Telemetry` need **zero changes** for this item — they already forward whatever `attributes`/`span_kind` the adapter hands them straight to `ai_spans.attributes` jsonb.

### 2. RETRIEVER span dual-write seam, keeping `ai_retrieval_runs` as system-of-record

The single call site is `Scoria.Knowledge.retrieve/2` (`lib/scoria/knowledge.ex:215-257`). It already:
- accepts `opts[:trace_id]` / `opts[:span_id]` from the caller (confirmed by `test/scoria/knowledge/retrieval_test.exs:49-65` — the plumbing genuinely is "just unemitted," as the seed claims),
- computes `latency_ms` via `System.monotonic_time(:millisecond)` bracketing (`knowledge.ex:222` / `:252`),
- calls `create_retrieval_run/1` (`knowledge.ex:137-151`) which persists the rich row (query text, backend, retriever module, top_k, filters, status, latency) — this is genuinely richer than a generic span and should stay the system-of-record exactly as the seed argues (grounding scores and typed `RetrievalResult` rows hang off `RetrievalRun`, not off any span).

**Minimal wiring**: inside `retrieve/2`, once `{:ok, run}` comes back from `create_retrieval_run/1` (and again once `append_retrieval_results/2` succeeds, if end/status needs the result count), call `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span_map)` with `span_kind: "retriever"`, `trace_id: opts[:trace_id]`, using `run.id` as `parent_id`/correlation if useful, and attributes carrying `embedding_model`/`index_version`/`reranker` + `result_count` + `retriever` (mirroring, not duplicating, the columns already on `run`). This is a **generic-visibility span for the trace tree UI**; `ai_retrieval_runs` stays the place eval/grounding code actually queries for detail. No new table, no collapse — literally "the same event, two representations, one call site." Same pattern generalizes cleanly to `Scoria.Observe.Approval` (`ai_approvals`) for a future `guardrail`-kind span, though that's out of this milestone's explicit scope (SEED-007 lists only `guardrail_triggered` as a *point-event*, not a span — see item 3).

### 3. Resurrecting `ai_span_events` minimally

Schema/migration state: **already fully present** (see "Correction to the seed's framing" above) — this is pure application wiring, no `mix ecto.gen.migration` needed. What's missing:

- A telemetry event name for point-events, distinct from the span lifecycle events `Telemetry` already attaches (`[:scoria, :observe, :span, :stop]` / `:delta`). Recommend `[:scoria, :observe, :event, :emit]` — a single fire-and-forget event, no start/stop pairing needed since these are instantaneous by definition (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`).
- A new `Telemetry.handle_event/4` clause for it, running `Redactor.redact/1` on the event's `attributes` exactly like spans do, then routing to `Buffer`.
- A public `Scoria.Observe.Telemetry.emit_event/1` (mirrors the `emit_span_delta/1` docstring convention at `telemetry.ex:20-26`, which explicitly tells future integrations "must use this... not raw `:telemetry.execute`").
- `Buffer` needs a second list (`events`) and a `cast_event/2`, flushed in the **same** flush cycle as spans but **strictly after** the span insert completes — `ai_span_events.span_id` is `null: false` and FK-references `ai_spans`, so an event for a span still sitting unflushed in the buffer's `spans` list would itself hit the same class of FK failure already lurking in the trace-upsert gap. Recommend wrapping "insert missing traces → insert spans → insert events" as one ordered sequence (ideally one `Ecto.Multi`/transaction) in the flush callback, rather than three independent `insert_all` calls with silent per-call rescue.
- **New call sites**, not existing ones. Unlike the RETRIEVER span (which slots into an existing function), none of `prompt_rendered`, `guardrail_triggered`, `user_feedback_received` have a home today — there is no dedicated prompt-render module (`prompt_version`/`prompt_ref` are workflow-runtime fields set in `lib/scoria/workflows/runtime.ex`, not an instrumentation point) and no guardrail module (`lib/scoria/observe/approval.ex` is the closest existing concept, an HITL/tool-approval system-of-record, not a "guardrail" per se). Flag this to the roadmapper explicitly: item 3 requires *adding* instrumentation calls into runtime/workflow code paths that don't currently call into Observe at all, which is materially different effort than items 1/2 (which are "wire up what already flows").

### 4. Redaction interplay

`Scoria.Observe.Redactor.redact/1` (`lib/scoria/observe/redactor.ex`) does an **exact key match** against a deny-list (default `~w(password api_key token secret)` as both atoms and strings, extensible via `config :scoria, Scoria.Observe.Redactor, deny_list: [...]` or a full `{mod, fun, args}` override), recursing through maps/lists, replacing matched values with `"[REDACTED]"`. It is not a substring or pattern matcher on keys — `do_redact/2` uses `MapSet.member?(deny_list, k)` on the whole key, so `"gen_ai.usage.output_tokens"` or any other compound dotted key is safe by construction; it can never accidentally collide with the `token` deny-entry. This means:

- All new conventional keys (`gen_ai.request.*`, `gen_ai.usage.*`, `openinference.span.kind`, `feature`/`route`/`archetype`/`intent`, context-pack composition keys, `embedding_model`/`index_version`/`reranker`) pass through the existing redactor **unchanged, with zero redactor code changes required** — none of them are PII by shape (model names, numeric params, categorical labels, counts, opaque IDs).
- The real risk isn't the key names, it's **what gets put under them**. Two guardrails worth calling out to whoever plans item 3 specifically: (a) `intent`/`route`/`feature`/`archetype` are host-declared *categorical labels* by design (P2 doctrine — Scoria never infers, host declares) — nothing in the redactor stops a host from putting a raw customer identifier into `intent`'s string value, since the redactor is key-based, not value-pattern-based. That's an adoption-docs concern, not a code fix. (b) context-pack composition should capture chunk IDs / memory IDs / token counts (opaque, safe), **not** raw chunk text — if raw text is captured anywhere, it needs to route through `Redactor.scrub_text/1` (the free-text `key=value` regex scrubber already used for streaming chunks, see `telemetry.ex:54-58`'s `scrub_delta_chunk/1`), not just `redact/1`.
- `prompt_rendered` deserves the most scrutiny: if its `attributes` end up carrying the actual rendered prompt string (which may contain interpolated user content), `redact/1` alone won't scrub free text inside a string value — it only redacts values whose *key* is on the deny-list. Recommend the event capture prompt **composition metadata** (template/version id, token count, chunk/memory ids used) rather than the rendered text itself, consistent with the milestone's own P5/P6 doctrine ("reconstructable in the host's own DB," not a content warehouse) — this avoids the redaction question entirely rather than trying to solve free-text PII scrubbing inside a jsonb event payload.
- Recommend one new regression test as part of whichever phase lands the convention keys: assert `gen_ai.*` / `openinference.span.kind` / host-declared keys survive `Redactor.redact/1` unredacted (locks the "safe by construction" claim above against future deny-list changes).

### 5. New vs modified components, and suggested build order

**New:**
- `Telemetry` event-ingest clause + `emit_event/1` public API (point-events)
- `Buffer` event-list + `cast_event/2` + ordered flush (traces → spans → events)
- Trace-upsert-on-flush logic (closes the pre-existing FK gap; not itself an OTel/OpenInference deliverable, but blocking)
- RETRIEVER span emission call inside `Knowledge.retrieve/2`
- New instrumentation call sites for `prompt_rendered` / `guardrail_triggered` / `user_feedback_received` wherever those actually happen in runtime/workflow code (none exist yet — needs to be located/created as part of planning, not assumed)

**Modified:**
- `req_llm.ex` adapter — convention keys via `ReqLLM.OpenTelemetry.Attributes`, real `span_kind`
- `jido.ex` adapter — real `span_kind` instead of `"INTERNAL"`
- `Scoria.Knowledge.RetrievalRun` — no migration; `metadata` map gains conventional keys
- README.md:272 — "OpenInference-style" → "redaction + OTel-shaped spans" now, "OpenInference-compatible" once item 1 ships (can happen any time convention lands, independent of items 2-4)

**Unchanged (confirmed, not just assumed):**
- `ai_traces` / `ai_spans` / `ai_span_events` table shapes — zero migrations for this milestone
- `Scoria.Repo.SpanEvent` schema/changeset
- `ScoriaWeb.WorkflowTreeComponent` / `TraceTreeComponent` span-kind allow-lists (adapters just need to emit values already inside them)

**Suggested build order (dependency-driven, mappable to phases):**

1. **Foundation fix + key convention + span_kind (Phase 1).** Fix the trace-upsert gap in `Buffer` (or wherever the flush lands — this must exist before *anything* else in this milestone can be proven end-to-end against a real Postgres). In the same phase: wire `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1` into `req_llm.ex`, fix both adapters' `span_kind`, add `openinference.span.kind` mirroring. This is the highest-leverage phase — it's mostly "call an existing function" plus fixing the one correctness bug blocking everything downstream.
2. **Model config on LLM spans (folds into Phase 1 or immediately after).** Once `ReqLLM.OpenTelemetry.Attributes` is wired, model config (temp/top_p/seed/max_tokens) arrives for free via `.start/1`'s `request_options` merge — there may be little-to-no separate work here beyond confirming it. Worth explicitly verifying with a test rather than assuming.
3. **RETRIEVER span + config fields (Phase 2).** Depends on (1) because it reuses the same span-emission path/trace-upsert fix. Single call site (`Knowledge.retrieve/2`), well-bounded.
4. **Host-declared attribute convention (`feature`/`route`/`archetype`/`intent` + context-pack keys) (Phase 2 or 3, can run parallel to RETRIEVER work).** Independent of RETRIEVER; depends only on (1)'s span-write path being solid. Needs a decision on which existing metadata-threading point (tenant_id/workflow_run_id precedent) these ride alongside.
5. **Structured child spans + `ai_span_events` resurrection (Phase 3, last).** Depends on (1) for the ordering discipline (spans-before-events in flush) and requires *new* instrumentation call sites that don't exist yet (prompt-render, guardrail-trigger, feedback-capture) — this is genuinely the highest-effort, most open-ended item and should be scoped/discussed carefully rather than estimated as "just wire the dead schema."
6. **README accuracy fix — can ship any time**, but sequence the *second* edit ("OpenInference-compatible") after (1) actually lands so the claim is true when made, not before.

## Anti-Patterns to Avoid

### Anti-Pattern: re-deriving `gen_ai.*` attribute names by hand
**What people would do:** hand-write a mapping from ReqLLM's telemetry metadata to `gen_ai.*` keys inside `req_llm.ex`.
**Why it's wrong:** `ReqLLM.OpenTelemetry.Attributes` already does this, is already a dependency, and is guaranteed to match what ReqLLM's own real OTel bridge emits. A hand-rolled mapping would drift and duplicate ~100 lines of already-correct code.
**Instead:** call `ReqLLM.OpenTelemetry.Attributes.start/1` and `.terminal/1`, merge into `attributes`.

### Anti-Pattern: typed columns for `embedding_model`/`index_version`/`reranker`
**What people would do:** a migration adding 3 new columns to `ai_retrieval_runs`.
**Why it's wrong:** breaks the milestone's own locked discipline (convention over columns) for no benefit — `RetrievalRun.metadata` is already a jsonb map sitting unused for exactly this purpose.
**Instead:** conventional keys inside `metadata`, mirrored into the RETRIEVER span's `attributes`.

### Anti-Pattern: forcing the full span-kind vocabulary into `ai_span_events`
**What the seed itself already correctly warns against (§ "What to build" item 3):** don't force `tool`/`prompt`/`retrieval`/`guardrail` into events — those are span kinds (they have duration, children, status). Only true instantaneous point-events (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) belong in `ai_span_events`.

## Sources

- Direct source inspection: `lib/scoria/observe/telemetry.ex`, `buffer.ex`, `redactor.ex`, `trace_projection.ex`, `reviewer_broadcast.ex`, `adapters/req_llm.ex`, `adapters/jido.ex`; `lib/scoria/repo/{span,span_event,trace}.ex`; `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/retrieval_run.ex`; `lib/scoria/observe/approval.ex`; `lib/scoria_web/components/{workflow_tree_component,trace_tree_component}.ex`; `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `20260523000300_expand_ai_scores_and_create_online_score_candidates.exs`; test files `test/scoria/observe/buffer_test.exs`, `test/scoria/repo/span_event_test.exs`, `test/scoria/knowledge/retrieval_test.exs`. Confidence: HIGH (primary source, not inferred).
- `deps/req_llm/lib/req_llm/telemetry.ex`, `deps/req_llm/lib/req_llm/telemetry/request_options.ex`, `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` — locked at `req_llm 1.13.0` per `mix.lock`. Confidence: HIGH (primary source, live in the dependency tree this project already builds against).
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — milestone intent, scope doctrine (P5/P6), and disagreements-with-memo record.
- `.planning/PROJECT.md` — current milestone framing ("Convention-over-columns (LOCKED)", dual-write directive).
- [OpenTelemetry Gen AI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/) — confirms `gen_ai.request.temperature`, `gen_ai.request.model`, `gen_ai.usage.input_tokens` etc. are the real upstream convention (matches what `ReqLLM.OpenTelemetry.Attributes` already emits). Confidence: HIGH (official spec).
- [OpenInference semantic conventions](https://arize-ai.github.io/openinference/spec/semantic_conventions.html) — confirms `openinference.span.kind` is required on every span and enumerates the 10 canonical kinds (`LLM, EMBEDDING, RETRIEVER, RERANKER, TOOL, CHAIN, AGENT, GUARDRAIL, EVALUATOR, PROMPT`) — used to sanity-check Scoria's UI-side 8/9-kind lists (workflow_tree vs trace_tree) which have already drifted from each other and from this canonical set (notably `"error"` isn't an OpenInference span kind). Confidence: HIGH (official spec).

---
*Architecture research for: Scoria v3.6 Trace Foundation (SEED-007)*
*Researched: 2026-07-11*

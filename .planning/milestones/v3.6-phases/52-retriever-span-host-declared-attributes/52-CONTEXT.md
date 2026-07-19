# Phase 52: RETRIEVER Span + Host-Declared Attributes - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Make retrieval calls **visible in the trace tree** as a linked `RETRIEVER` span **without displacing `ai_retrieval_runs` as the system-of-record**, and let hosts **declare** `feature`/`route`/`archetype`/`intent` plus context-pack composition **without Scoria ever inferring them**.

In scope (locked by `.planning/REQUIREMENTS.md`):
- **RETR-01** — a `RETRIEVER` span dual-written at the single `Knowledge.retrieve/2` call site alongside `ai_retrieval_runs` (kept, not collapsed), reusing the trace_id/span_id/latency it already computes.
- **RETR-02** — `embedding_model`/`index_version`/`reranker` as convention keys (no migration), mirrored onto both the `RETRIEVER` span and `ai_retrieval_runs.metadata`, with a span↔table consistency guard.
- **ATTR-01** — reserved host-declared keys `feature`/`route`/`archetype`/`intent` threaded through the existing metadata precedent; Scoria reserves and passes through, **never infers**.
- **ATTR-02** — context-pack / token-budget composition captured on the prompt-composition span (which chunk IDs + which memory IDs + per-source token split) alongside `gen_ai.usage.input_tokens` — **IDs and counts only, never raw text**.

**This phase clarifies HOW to implement the above.** It reuses the Phase-51 span-emission + FK-safe trace-upsert pipeline. New capabilities — real duration-bearing child spans, `ai_span_events`/`emit_event/1`, the write-time PII/cardinality bound, and the "OpenInference-compatible" claim + conformance check — belong to Phases 53–54 and are out of scope here.

**Method:** four parallel research subagents (one per requirement, cross-aware for coherence) + one adversarial red-team pass verified against real code, synthesized into the locked decisions below. Red-team revisions are marked **(revised)**; the red-team found one **BLOCKER** (req_llm does not forward host metadata — see the open decision in `<decisions>`) and several REVISEs, all folded in. This mirrors the Phase 51 discuss method the user values.

**Cross-cutting meta-principle (inherited from Phase 51):** *one shared, Semconv-owned seam; single source of truth; structural guarantees proven by drift-guard tests; host declares, Scoria never infers.*

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting — the one shared threading seam + namespace rule
- **D-00 (spine):** All four requirements compose through **one Semconv-owned metadata→attributes seam**, reused by both adapters, the new RETRIEVER span builder, and the prompt-composition path. Every persisted key **MUST land inside the span `attributes` map** — `Telemetry.buffer_span/1` does `Map.take(redacted, @span_buffer_fields)` (`telemetry.ex:68-72`), so any top-level span field beyond `id/trace_id/parent_id/name/span_kind/status_code/start_time/end_time/attributes` is **silently dropped before insert** (this is exactly why the adapters double-write `tenant_id`/`workflow_run_id` into `attributes`). No new keys as top-level span fields.
- **D-00b — namespace rule (revised, resolves a synthesis contradiction):** Namespace by **who defines the key's meaning**, independent of who supplies the value:
  - Scoria-defined subsystem field → `scoria.<subsystem>.*` (e.g. `scoria.retrieval.*`, `scoria.prompt.context`).
  - Host free-form dimension Scoria assigns no meaning to → **bare** (`feature`/`route`/`archetype`/`intent`) — extends the existing bare `tenant_id`/`workflow_run_id` precedent.
  - Third-party tool field → tool prefix (existing `jido.*`).
  - Cross-vendor portability → spec namespace (existing `openinference.span.kind`, req_llm-owned `gen_ai.*`).
  This reconciles RETR-02's `scoria.retrieval.*` (Scoria owns the retrieval-config **schema**, even though `index_version`/`reranker` **values** are host-supplied) with ATTR-01's bare keys. **The "a `scoria.*` prefix on host-declared values is a doctrine lie" rationale from the ATTR-01 research is struck** — it conflated value-origin with schema-ownership. Bare `route`/`feature`/`intent` are collision-prone with host/OTel keys: **last-writer-wins, host owns the collision** (document it).
- **D-00c:** **Semconv owns every key string** (extend `lib/scoria/observe/semconv.ex`; its moduledoc already reserves the ATTR-01 keys). No adapter/builder ever inlines a key string. Enforced structurally by anti-inline grep guards (D-15 pattern from Phase 51).

### RETR-01 — RETRIEVER span emission mechanics
- **D-R1 — async emit, IDs pinned synchronously:** Emit the RETRIEVER span via the Phase-51 pipeline: `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)` → redaction + `ReviewerBroadcast` + FK-safe trace-upsert-then-insert in `Buffer`. **No synchronous `Repo.insert`** — that re-opens the exact FK footgun Phase 51 fixed (the trace-upsert-before-span logic lives only in `Buffer.flush_spans`, `buffer.ex:123-129`), skips redaction/broadcast, and taxes the product hot path. The "join never comes up empty" criterion is about **linkage correctness** (guaranteed because span_id is pinned on both sides synchronously), not zero-latency persistence — the trace tree is already eventually-consistent for LLM spans. The acceptance test calls `Buffer.flush_now/1` (`buffer.ex:23`) before asserting the join.
- **D-R2 — ID sourcing + own-id semantics (revised):** In `retrieve/2`, mint up-front: `trace_id = opts[:trace_id] || Ecto.UUID.generate()`, `span_id = opts[:span_id] || Ecto.UUID.generate()`. Write the **same** `span_id` to the run row's `span_id` column **and** the emitted span map's `:id` (`Buffer`'s `Map.put_new_lazy(:id, …)` preserves a pre-set id, `buffer.ex:109`; `:id` is in `@span_buffer_fields` → survives to the `ai_spans` PK). **⚠ Semantic change:** `opts[:span_id]` is redefined from "a reference to the caller's/parent span stored on the run" to "**this retrieval's OWN span id**". It MUST be fresh/unique — passing an existing `ai_spans.id` PK-collides (the span `insert_all` has **no `on_conflict`**, `buffer.ex:129`), and the span is silently dropped via the flush-error path. Always emit (retrieval is observable by default; a context-less retrieval legitimately roots its own trace — the Buffer upserts the trace idempotently). Return additively: `{:ok, %{run: run, results: persisted_results, trace_id: trace_id, span_id: span_id}}` (existing callers use partial map patterns — non-breaking, verified).
- **D-R2b — mandatory test migration (revised, was omitted by synthesis):** `test/scoria/knowledge/retrieval_test.exs` (~lines 50-73) inserts a `Span` and calls `retrieve(..., span_id: span.id)`, asserting `run.span_id == span.id`. Under D-R2/D-R3 that path must change to `parent_id: span.id`; the assertion becomes `run.span_id == <minted own-id>` and `retriever_span.parent_id == span.id`. This test change is **required**, not optional.
- **D-R3 — parent linkage:** `parent_id = opts[:parent_id]` (nil ⇒ trace root). Host declares, Scoria never infers the parent. Distinct axes: `opts[:parent_id]` = the caller's/originating span; `opts[:span_id]` = this retrieval's own span id (= the join key). Document both on `retrieve/2`.
- **D-R4 — wall-clock times:** Add one line `started_wall = DateTime.utc_now()` at the top of `retrieve/2`; emit `start_time: started_wall`, `end_time: DateTime.utc_now()`. Keep the existing monotonic delta as the authoritative `latency_ms`. **Do not** derive `start = end - latency` (double-samples/drifts).
- **D-R5 — kind + name:** `span_kind = SpanKind.normalize("retriever")`; mirror `SpanKind.to_openinference(span_kind)` under `Semconv.openinference_span_kind_key()` in `attributes` (never hardcode kind/key/casing — D-14/D-16). `name = "knowledge.retrieve"` (low-cardinality, operator-legible). **Never** put `query_text` in `name` or unredacted in `attributes`. `status_code: "OK"` (verified canonical: `trace_projection.ex:39` defaults `"OK"`, `online_scoring.ex` matches upcased `"ERROR"`; coheres with Phase 51 D-12 error-as-status).
- **D-R6 — failure isolation:** Emit **after** the `with` chain succeeds (after run + results persist), wrapped `try/rescue → :ok` (`:telemetry.execute` runs `Redactor`/`ReviewerBroadcast` **synchronously in the caller**, so an unguarded raise would propagate into `retrieve/2`). Span emission must **never** fail retrieval (FOUND-01 non-fatal-but-loud). **Success-path only for v3.6** — an ERROR-status RETRIEVER span is deferred.
- **D-R7 — emitter module:** Add `Scoria.Observe.emit_retriever_span/1` (builds the span map + emits). `knowledge.ex` calls it and stays free of span plumbing (consumer-not-provider). This is the single span-build path that RETR-02 config keys and ATTR-01 host keys compose through.

### RETR-02 — retrieval config fields + span↔table consistency guard
- **D-RETR02-1 — single origin, structural:** Compute **one** canonical `%{embedding_model:, index_version:, reranker:}` map once in `retrieve/2`; a single `Semconv.retrieval_config_attributes/1` projection feeds the **same** map to both the RETRIEVER span `attributes` and `create_retrieval_run`'s `metadata`. Never compute the value twice — that is the exact divergence class RETR-02 exists to prevent.
- **D-RETR02-2 — per-field precedence (revised for embedder-in-scope):**
  - `embedding_model` = `opts[:embedding_model]` > `(opts[:embedder] || Embedder.Deterministic).model_name()` *(only if exported — see D-RETR02-5)* > `"none"`. **⚠** `retrieve/2` today hardcodes `Embedder.Deterministic.embed_query` on the `nil`-retriever path (`knowledge.ex:229`) and takes **no `:embedder` opt** — planner must add `:embedder` resolution (defaulting to `Deterministic`) for this lookup. When the host passes `opts[:query_embedding]` (Scoria did not embed), fall through to host declaration → `"none"`; **never assert a model name Scoria didn't produce.**
  - `index_version` = `opts[:index_version]` > `Application.get_env(:scoria, :index_version)` > `"none"`. Host/config-declared — **do not infer** from the migration DDL (the HNSW index has no version concept; `knowledge_migrations/...:45`).
  - `reranker` = `opts[:reranker]` > `"none"`. Host-declared; no reranker exists in `lib/` today (grep empty).
- **D-RETR02-3 — keys (Semconv `@retrieval_config_keys`, keyword list):** `scoria.retrieval.embedding_model`, `scoria.retrieval.index_version`, `scoria.retrieval.reranker`. The **same dotted string keys** on both the span `attributes` and `run.metadata` top level (jsonb handles dotted keys) → the guard is a trivial `Map.take` equality with no second mapping to drift.
- **D-RETR02-4 — sentinel, never nil:** Absent values normalize to `"none"` (never `nil`, never omit). Exporters/serializers drop nil-valued keys → the two sinks would diverge and defeat the guard. All three keys always present on both sides.
- **D-RETR02-5 — embedder `model_name/0` (revised, optional + guarded):** Add `@callback model_name() :: String.t()` to `Scoria.Knowledge.Embedder` **as `@optional_callbacks [model_name: 0]`**; `Embedder.Deterministic` returns a stable literal (e.g. `"scoria.deterministic.sha256.v1"`). Guard the call with `function_exported?(embedder, :model_name, 0)` before invoking — a host embedder without it must **fall through** (→ `opts[:embedding_model]` → `"none"`), never `UndefinedFunctionError` inside `retrieve/2`. (Only `Deterministic` implements the behaviour in-app; the other `@behaviour` hit is an uncompiled hex-consumer fixture.)
- **D-RETR02-6 — no migration + merge order:** The three keys ride the existing `metadata :map` column (`retrieval_run.ex:20`, already cast). Host-declared ATTR-01 keys merge into the **same** `metadata` map; the `scoria.retrieval.*` namespace is disjoint from the bare ATTR-01 keys so there is no collision, but keep merge direction explicit (host keys + config keys, config confined to its own namespace).
- **D-RETR02-7 — the guard (the key deliverable):** Structural single-build (D-RETR02-1) **plus** a drift-guard test mirroring Phase 51 D-15: (1) **canary** — `assert Semconv.retrieval_config_keys() == [embedding_model: "scoria.retrieval.embedding_model", index_version: "scoria.retrieval.index_version", reranker: "scoria.retrieval.reranker"]`; (2) **real-Postgres equality** — after a `Knowledge.retrieve/2` + `Buffer.flush_now/1`, fetch the RETRIEVER span, `keys = Keyword.values(Semconv.retrieval_config_keys())`, `assert map_size(Map.take(run.metadata, keys)) == 3` and `assert Map.take(span.attributes, keys) == Map.take(run.metadata, keys)`; (3) **anti-inline grep** — refute any `"scoria.retrieval."` literal outside `semconv.ex`. Fails on any rename-one-side, compute-twice, nil, omit, or added-to-one-sink edit.

### ATTR-01 — reserved host-declared keys
- **D-ATTR01-1 — bare keys:** Attribute-key strings `"feature"`/`"route"`/`"archetype"`/`"intent"` (per D-00b). Canonical source `Semconv.host_declared_keys/0 :: [atom()]` (`~w(feature route archetype intent)a`); docs, the merge loop, and the guard test all read it. Never inline the strings.
- **D-ATTR01-2 — shared seam:** `Semconv.merge_host_declared(attributes, metadata) :: map()` — `Enum.reduce` over `host_declared_keys/0`, `nil → skip` (absent-if-omitted; never defaulted), else `Map.put(acc, Atom.to_string(key), value)` (verbatim). **This is the single seam for all four areas** — called by both adapters, the RETRIEVER span builder (D-R7), and the prompt-composition path (ATTR-02).
- **D-ATTR01-3 — container normalization (revised):** The seam reads an **atom-keyed map**. The adapter path passes a map (telemetry metadata); `retrieve/2` holds a **keyword list** `opts`. Normalize once at the retrieve call site — `metadata = Map.new(opts)` (or a `host_metadata_from_opts/1` helper) — before invoking the seam, so both call sites hand it a map (avoids `BadMapError` from `Map.get`/`map_size` on a keyword list).
- **D-ATTR01-4 — no Phase-52 value hygiene:** Pass values through the **existing key-based `Redactor.redact/1`** (which already runs on every span and recurses into nested maps/lists — verified `redactor.ex:32-44`) **unchanged**. No length bound, no truncation, no `archetype`-enum validation (validation ≠ storage; coupling to SEED-012's unstable enum now invites churn and drifts toward "Scoria judges the value"). The uniform write-time size/cardinality/PII bound is **SEC-01 (Phase 53)**, not bolted onto these four. This preserves the "flows through unmodified" criterion.
- **D-ATTR01-5 — carried on every span:** LLM, TOOL (jido), RETRIEVER, and the prompt-composition span all route metadata through `merge_host_declared` — so the whole trace is sliceable by feature/route/archetype/intent (the SEED-012 JTBD). *(Caveat: reliably reaching the LLM/tool spans depends on the open decision D-ATTR01-7.)*
- **D-ATTR01-6 — guards:** (a) sentinel byte-for-byte pass-through per span type; (b) empty-metadata ⇒ keys **absent** (`refute Map.has_key?`) — the never-default proof; (c) D-15-style anti-inline grep asserting **only `semconv.ex`** writes a reserved key string. **⚠ (b)/(c) must not treat synthetic hand-built telemetry events as production evidence** (see D-ATTR01-7).
- **D-ATTR01-7 — OPEN DECISION / BLOCKING PREREQUISITE (red-team, verified):** **req_llm's native `[:req_llm, :request, :stop]` metadata does NOT forward arbitrary host keys.** `ReqLLM.Telemetry.request_metadata/2` (`deps/req_llm/lib/req_llm/telemetry.ex:485-514`) builds a **fixed base map** (request_id/operation/model/usage/…); `tenant_id`/`trace_id`/`parent_id`/`span_kind`/`context_pack` are **always nil** on a real emission. The existing Phase-51 adapter only "works" because its test **hand-synthesizes** the event (`req_llm_test.exs:38-53`). Therefore host-declared keys (ATTR-01) and context-pack (ATTR-02) **cannot reach the LLM/prompt span via req_llm in production.** The RETRIEVER span is **unaffected** (host values arrive directly in `retrieve/2` opts; Scoria emits the span itself) — so **RETR-01 + RETR-02 + ATTR-01-on-the-RETRIEVER-span are fully implementable and are the reliable core of this phase.** For the LLM/prompt-composition span, the planner/researcher **MUST choose and specify an explicit host-owned injection mechanism** before implementing — recommended direction (see Claude's Discretion): a **Scoria-owned host-facing emit/annotation helper** at the host's prompt-assembly site (mirrors `emit_retriever_span/1`; coheres with "host declares"), **not** reliance on req_llm forwarding. Do **not** write plans as if req_llm forwards host metadata.

### ATTR-02 — context-pack / token-budget composition
- **D-ATTR02-1 — span target + boundary (revised):** Attach composition attributes to the **prompt-composition (LLM-request) span** in v3.6 — do **not** emit a new `prompt`/`PROMPT` child span in Phase 52 (that structural work is **Phase 53 / EVENT-01**). **⚠ This reinterprets Phase 52 Success Criterion #4's literal "PROMPT span" wording:** state explicitly in planning that the attributes ride the composition-carrying span now and **Phase 53 relocates the identical Semconv keys onto a real `PROMPT` child span with zero contract change.** Reaching that span in production is gated by **D-ATTR01-7**.
- **D-ATTR02-2 — host-declared source:** Scoria does **not** assemble the RAG prompt (the only `build_prompt/2` is compaction-internal, `summarize_worker.ex:96`) — so it cannot infer which chunks/memories entered the budget or their token split. The **host supplies** `context_pack`, threaded on the same metadata seam (per D-ATTR01-7's chosen mechanism). Chunk `id`s are the **same UUIDs** the RETRIEVER span records (`chunk_id`/`source_id`, `knowledge.ex:371-385`); memory `id`s are `ai_compacted_memories` binary_ids — so operators join retriever→prompt on the ID value.
- **D-ATTR02-3 — key + shape (Semconv-owned):** Single key `"scoria.prompt.context"` (add `Semconv.prompt_context_key/0`). Value is a **nested map**: `%{"chunks" => [%{"id" => uuid, "tokens" => int}, …], "memories" => [%{"id" => uuid, "tokens" => int}, …], "token_budget" => %{"total" => int, "chunks" => int, "memories" => int, "overhead" => int}}`. **Reject** OpenInference indexed-flat keys (`…chunks.0.id` — bloats the jsonb/GIN key space; nested supports `@>` containment + `jsonb_array_elements`). **Reject** the `gen_ai.prompt.*` namespace (OTel-GenAI reserves it for prompt **content** → would falsely signal we carry text). It coexists on the same span as `gen_ai.usage.input_tokens` — no relationship key needed.
- **D-ATTR02-4 — never-text, structural + guarded:** The builder maps each item to **only** `%{"id" => id, "tokens" => tokens}` — **no passthrough** of the host's raw item map (so an over-sharing host cannot smuggle a `text`/`content` field onto the span). Drift-guard test over the fully-built value: every key ∈ `{"chunks","memories","token_budget","id","tokens","total","overhead"}`; no key matches `~r/text|content|body|message|prompt|raw/i`; every leaf is a binary ≤64 bytes (an ID) or a non-negative integer; `Jason.encode!/1` ≤ 8 KB.
- **D-ATTR02-5 — token provenance:** Per-source `tokens` are **host-supplied**; `gen_ai.usage.input_tokens` (from req_llm, `attributes.ex:221` — verified key name) is the provider total. **Record both; enforce NO `sum == input_tokens` guard** (chat-template/role overhead guarantees drift → flaky). Tolerate `input_tokens` being **absent** (usage nil on embedding-only/failed calls — `attributes.ex:211 usage(nil) -> %{}`); do not assert its unconditional presence.
- **D-ATTR02-6 — cardinality cap:** Cap `chunks`/`memories` at ≤100 items each **now** with a `"truncated" => true` marker (local landmine prevention); the general write-time size bound remains SEC-01/Phase 53.
- **D-ATTR02-7 — empty/absent:** When no `context_pack` (or empty chunk+memory lists), **omit the key entirely** (no empty-but-present key). The SC#4 acceptance test **must** supply a populated pack (≥1 chunk **and** ≥1 memory with token counts) and assert the nested structure coexists with `gen_ai.usage.input_tokens` on the same persisted span (after `Buffer.flush_now/1`).

### Claude's Discretion (delegated to researcher/planner)
- **The D-ATTR01-7 injection mechanism** — the exact host-facing seam for host-declared keys + `context_pack` on the LLM/prompt span. **Recommended:** a Scoria-owned `Scoria.Observe.emit_*` helper the host calls at prompt-assembly (symmetric with `emit_retriever_span/1`, doctrine-honest), emitting `[:scoria, :observe, :span, :stop]` with the composition + host keys + host-supplied `gen_ai.usage.input_tokens`. Bound it against Phase 53 creep: if this equals emitting a prompt span, coordinate the span-taxonomy boundary with EVENT-01 (Phase 52 carries the composition attributes; Phase 53 formalizes the child-span structure + parent linkage + events). The researcher confirms the precise req_llm option/path the host uses to inject metadata and whether an annotation-on-existing-LLM-span variant is viable.
- **Whether to reuse a single generic `Semconv.merge_host_declared`-style projection** for all three new key families (host-declared, retrieval-config, prompt-context) vs. three sibling functions — an internal factoring choice; keep them all Semconv-owned and grep-guarded.
- **Trace-tree UI surfacing of the RETRIEVER span** (does the existing `TraceTreeComponent` render a `retriever` kind + the config attrs?) — a display concern the planner scopes; the CSS rail + SpanKind whitelist already include `retriever` (Phase 51 D-11/D-15).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements & roadmap (authoritative)
- `.planning/REQUIREMENTS.md` — v3.6 locked requirements; Phase 52 owns RETR-01/02, ATTR-01/02. Scope doctrine (convention-not-columns, host-declares-Scoria-never-infers, keep `ai_retrieval_runs` system-of-record, zero required egress) is held here. Line 74 puts auto-inferred archetype/intent classifiers explicitly out of scope.
- `.planning/ROADMAP.md` §"Phase 52" — goal + 4 success criteria (the acceptance bar). **Note the SC#4 "PROMPT span" wording caveat in D-ATTR02-1.** §"Phase 53" defines the boundary (child spans, `ai_span_events`, SEC-01 bound) that ATTR-02/ATTR-01 must NOT cross.
- `.planning/research/SUMMARY.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md`, `.planning/research/PITFALLS.md`, `.planning/research/STACK.md` — the milestone research base.
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — origin seed (§"What to build" items on retrieval-as-span + host-declared attrs).
- `.planning/seeds/SEED-012-*.md` — downstream consumer of `archetype`/`route`/`intent` ("Scoria stores + surfaces, never infers"); do NOT couple Phase 52 to its enum ladder.

### The foundation this phase reuses (READ FIRST)
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/51-CONTEXT.md` — the just-shipped span-emission + FK-safe trace-upsert pipeline, `SpanKind` (D-10..D-15), `Semconv` (D-16), the Buffer flush-error posture (D-05..D-09), and the drift-guard-test pattern (D-15) this phase mirrors.

### Convention sources (reference, NOT dependencies)
- `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` — `start/1`/`.terminal/1`/`.usage/1`; source of `gen_ai.usage.input_tokens` (`:221`) and the model-config keys. `req_llm 1.13` locked.
- `deps/req_llm/lib/req_llm/telemetry.ex:485-514` — `request_metadata/2`; **evidence for D-ATTR01-7** (fixed base map, no host-metadata merge).
- OpenInference span-kind enum + retrieval/document attribute conventions — plain-string reference for key naming; NOT a runtime dep (do not add `opentelemetry*`).

### Project DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, Ecto-native durable state (no opaque in-memory state), consumer-not-provider API (hide span plumbing behind `retrieve/2`), host owns identity/policy, "prepare telemetry hooks for Parapet", zero-config default.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scoria/observe/adapters/req_llm.ex` — the reference span-emitter (span map → `:telemetry.execute([:scoria,:observe,:span,:stop], …)`); the RETRIEVER emitter (D-R7) mirrors its `attributes` composition + `base_attributes` reject-nils pattern.
- `lib/scoria/observe/semconv.ex` — the single key-string owner (extend with `retrieval_config_keys/0`, `host_declared_keys/0` + `merge_host_declared/2`, `prompt_context_key/0`). Its moduledoc already reserves the ATTR-01 keys.
- `lib/scoria/observe/span_kind.ex` — `SpanKind.normalize/2` + `to_openinference/1`; `retriever`→`RETRIEVER` already defined (Phase 51 D-11). CSS rail `scoria-span--retriever` + both UI whitelists already include it.
- `lib/scoria/observe/buffer.ex` — `flush_now/1` test hook (D-08), FK-safe `Ecto.Multi` (trace upsert `on_conflict: :nothing` → span `insert_all` **without** `on_conflict`), `Map.put_new_lazy(:id, …)` id preservation.
- `lib/scoria/observe/redactor.ex` — depth-recursive, key-based redaction that already runs on every span (`redact/1`, `:32-44`); ATTR-01/ATTR-02 values pass through it unchanged.
- `ai_retrieval_runs.metadata :map` (`retrieval_run.ex:20`, cast `:44`) — carries RETR-02 config keys + ATTR-01 host keys with **no migration**.

### Established Patterns
- **Span persistence contract:** only `@span_buffer_fields` survive `Telemetry.buffer_span/1` (`telemetry.ex:68`) → **all new keys go in `attributes`** (D-00). Top-level `tenant_id`/`workflow_run_id` survive only because the adapters double-write them into `attributes`.
- **Drift-guard test discipline (Phase 51 D-15):** canary + exhaustiveness + anti-inline grep + real-Postgres assertion — reused for both the RETR-02 consistency guard (D-RETR02-7) and the ATTR-01 never-infer guard (D-ATTR01-6).
- **Host-declares override, Scoria-never-infers (Phase 51 D-13):** the Jido `span_kind` host-override precedent that ATTR-01 generalizes to `feature`/`route`/`archetype`/`intent`.

### Integration Points
- `lib/scoria/knowledge.ex:215` `retrieve/2` — mint trace_id/span_id (D-R2), capture wall-clock start (D-R4), build the one config map (D-RETR02-1), normalize `opts`→map (D-ATTR01-3), add `:embedder` resolution (D-RETR02-2), call `create_retrieval_run` with config+host metadata, then `emit_retriever_span/1` after the `with` (D-R6). Additive return (D-R2).
- **New:** `Scoria.Observe.emit_retriever_span/1` (D-R7) and the D-ATTR01-7 host-facing prompt/LLM-span emit seam (Claude's Discretion).
- `test/scoria/knowledge/retrieval_test.exs` (~:50-73) — **mandatory migration** of the `span_id`→`parent_id` linkage assertion (D-R2b).
- `lib/scoria/observe/adapters/{req_llm,jido}.ex` — add `merge_host_declared/2` into the `attributes` pipe (host-declared keys), subject to D-ATTR01-7 for real-event reachability.
- `lib/scoria/knowledge/embedder.ex` — add `@optional_callbacks [model_name: 0]` + `Deterministic.model_name/0` (D-RETR02-5).

</code_context>

<specifics>
## Specific Ideas

- Method: 4 parallel research subagents (RETR-01 / RETR-02 / ATTR-01 / ATTR-02, cross-aware) + 1 adversarial red-team pass, all verified against real code. Red-team caught: (1) a **BLOCKER** — req_llm does not forward host metadata (D-ATTR01-7), reshaping ATTR-01/ATTR-02 for the LLM span while leaving the RETRIEVER span intact; (2) the `opts[:span_id]` **PK-collision + semantic redefinition** and the omitted mandatory test migration (D-R2/D-R2b); (3) a `scoria.retrieval.*`-vs-bare-keys **namespace contradiction** resolved by the "prefix = vocabulary owner" rule (D-00b); (4) a keyword-list-vs-map **`BadMapError`** at the shared seam (D-ATTR01-3); (5) an unguarded `model_name/0` behaviour addition that would `UndefinedFunctionError` on host embedders (D-RETR02-5); (6) the SC#4 "PROMPT span" **boundary reinterpretation** (D-ATTR02-1).
- The whole phase coheres under one seam: `retrieve/2` and both adapters hand a normalized atom-keyed map to Semconv-owned projections (`retrieval_config_attributes/1`, `merge_host_declared/2`, prompt-context builder) that write into `attributes`; guard tests prove single-origin structurally. The reliable production core is **RETR-01 + RETR-02 + ATTR-01-on-the-RETRIEVER-span**; the LLM/prompt-span portion is gated on resolving D-ATTR01-7.

</specifics>

<deferred>
## Deferred Ideas

- **Real duration-bearing `tool`/`prompt`/`retrieval`/`guardrail` child spans with `parent_id` linkage** — Phase 53 / EVENT-01. Phase 52 carries composition attributes on the LLM/composition span; 53 relocates the same Semconv keys onto a real `PROMPT` child span (zero contract change).
- **`ai_span_events` / `emit_event/1`** — Phase 53 / EVENT-02/03.
- **Uniform write-time attribute size/cardinality/PII bound** — Phase 53 / SEC-01 (Phase 52 does only the local ≤100-item cap on context-pack lists, D-ATTR02-6, and no ATTR-01 value hygiene).
- **`EMBEDDING`/`RERANKER` first-class span kinds** — stay as attrs on the RETRIEVER span (KIND-EMB-01/RRK-01, v3.7+).
- **Auto-inferred `archetype`/`intent` classifiers** — explicitly out of scope (`REQUIREMENTS.md:74`); Scoria reserves + passes through only. SEED-012 consumes these host-declared values downstream.
- **ERROR-status RETRIEVER span** (failed retrieval) — success-path only for v3.6 (D-R6); errored retrieval already surfaces via `ai_retrieval_runs.status`.
- **"OpenInference-compatible" claim + falsifiable conformance check** — Phase 54.

### Reviewed Todos (not folded)
None — `todo.match-phase 52` returned zero matches.

</deferred>

---

*Phase: 52-retriever-span-host-declared-attributes*
*Context gathered: 2026-07-12 (research + red-team method)*

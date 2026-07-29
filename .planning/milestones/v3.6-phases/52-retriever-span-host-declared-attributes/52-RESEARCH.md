# Phase 52: RETRIEVER Span + Host-Declared Attributes - Research

**Researched:** 2026-07-12
**Domain:** BEAM-native OTel-GenAI/OpenInference trace convention over the existing `attributes` jsonb map; Elixir `:telemetry` span emission; Ecto jsonb dual-write consistency
**Confidence:** HIGH (all locked code-anchored claims re-verified against live code this session; the one open decision — D-ATTR01-7 injection mechanism — is resolved with a code-verified recommendation)

<user_constraints>
## User Constraints (from CONTEXT.md)

The Phase 52 CONTEXT.md is an already-locked, code-verified spec produced by a 4-subagent + red-team discuss pass. Its decisions D-00..D-ATTR02-7 are LOCKED. This research does **not** re-litigate them; it (a) verifies the code-anchored claims still match live code, (b) closes the genuinely-open items, and (c) derives the validation architecture. The constraints below are copied from CONTEXT.md.

### Locked Decisions (must honor — do not re-open)
- **D-00 (spine):** All four requirements compose through ONE Semconv-owned metadata→attributes seam. Every persisted key MUST land inside the span `attributes` map — `Telemetry.buffer_span/1` does `Map.take(redacted, @span_buffer_fields)`, so any top-level span field beyond `id/trace_id/parent_id/name/span_kind/status_code/start_time/end_time/attributes` is silently dropped before insert. No new keys as top-level span fields.
- **D-00b (namespace rule):** Namespace by who defines the key's meaning. Scoria-defined subsystem field → `scoria.<subsystem>.*`. Host free-form dimension → bare (`feature`/`route`/`archetype`/`intent`). Third-party tool → tool prefix (`jido.*`). Cross-vendor portability → spec namespace (`openinference.*`, `gen_ai.*`). Bare host keys are last-writer-wins, host owns the collision.
- **D-00c:** Semconv owns every key string. No adapter/builder inlines a key string. Enforced by anti-inline grep guards.
- **D-R1:** Async emit via the Phase-51 pipeline (`:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`). No synchronous `Repo.insert`. Acceptance test calls `Buffer.flush_now/1` before asserting the join.
- **D-R2 / D-R2b:** Mint `trace_id`/`span_id` up front; write the same `span_id` to the run row's `span_id` column AND the span map's `:id`. `opts[:span_id]` is redefined to "this retrieval's OWN span id" (must be fresh/unique). The `retrieval_test.exs` migration (span_id→parent_id) is MANDATORY, not optional.
- **D-R3:** `parent_id = opts[:parent_id]` (nil ⇒ trace root). Host declares, Scoria never infers the parent.
- **D-R4:** Wall-clock `start_time`/`end_time` via `DateTime.utc_now()`; keep the existing monotonic delta as authoritative `latency_ms`. Do NOT derive `start = end - latency`.
- **D-R5:** `span_kind = SpanKind.normalize("retriever")`; mirror `SpanKind.to_openinference/1` under `Semconv.openinference_span_kind_key()`. `name = "knowledge.retrieve"`. `status_code: "OK"`. Never put `query_text` in `name` or unredacted in `attributes`.
- **D-R6:** Emit AFTER the `with` chain succeeds, wrapped `try/rescue → :ok`. Span emission must NEVER fail retrieval. Success-path only for v3.6.
- **D-R7:** Add `Scoria.Observe.emit_retriever_span/1`. `knowledge.ex` calls it and stays free of span plumbing.
- **D-RETR02-1..7:** One canonical config map computed once; single `Semconv.retrieval_config_attributes/1` projection feeds both the span `attributes` and `create_retrieval_run`'s `metadata`; keys `scoria.retrieval.{embedding_model,index_version,reranker}`; sentinel `"none"` never nil; per-field precedence; optional guarded `model_name/0`; no migration; the drift-guard (canary + real-Postgres equality + anti-inline grep).
- **D-ATTR01-1..7:** Bare keys `feature/route/archetype/intent`; `Semconv.host_declared_keys/0` + `merge_host_declared/2` seam; atom-keyed-map normalization; no Phase-52 value hygiene beyond the existing `Redactor`; carried on every span; guards. **D-ATTR01-7 is the OPEN decision** (resolved below).
- **D-ATTR02-1..7:** Composition attributes on the prompt-composition (LLM-request) span (NOT a new PROMPT child span — that's Phase 53); host-supplied `context_pack`; single key `scoria.prompt.context` with a nested map; never-text structural guard; both per-source `tokens` and `gen_ai.usage.input_tokens` recorded with NO sum guard; ≤100-item cap; omit key when empty.

### Claude's Discretion (this research recommends)
- The D-ATTR01-7 injection mechanism (RESOLVED below — Recommendation 1).
- Single generic projection vs. three sibling functions (RESOLVED below — Recommendation 4).
- Trace-tree UI surfacing of the RETRIEVER span (RESOLVED below — Recommendation 3).

### Deferred Ideas (OUT OF SCOPE — Phase 53+)
- Real duration-bearing child spans with `parent_id` linkage (EVENT-01).
- `ai_span_events` / `emit_event/1` (EVENT-02/03).
- Uniform write-time attribute size/cardinality/PII bound (SEC-01). Phase 52 does only the local ≤100-item cap.
- `EMBEDDING`/`RERANKER` first-class span kinds (KIND-EMB-01/RRK-01, v3.7+).
- Auto-inferred `archetype`/`intent` classifiers (out of scope, `REQUIREMENTS.md:74`).
- ERROR-status RETRIEVER span (success-path only for v3.6).
- "OpenInference-compatible" claim + conformance check (Phase 54).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RETR-01 | `RETRIEVER` span emitted at the single `Knowledge.retrieve/2` call site, dual-written alongside `ai_retrieval_runs` (kept as system-of-record), reusing the trace_id/span_id/latency it computes | Verified the Phase-51 async emit pipeline (`telemetry.ex:60-66` → `Buffer.cast_span` → FK-safe multi `buffer.ex:123-129`) is reusable as-is; `retrieve/2` already computes `latency_ms` (`knowledge.ex:222/252`); `emit_retriever_span/1` (new, D-R7) mirrors `req_llm.ex` adapter. See Verification §1, §2. |
| RETR-02 | `embedding_model`/`index_version`/`reranker` as convention keys (no migration), mirrored onto the span AND `ai_retrieval_runs.metadata`, with a span↔table consistency guard | `metadata :map` column verified cast (`retrieval_run.ex:20/42`); single-projection factoring recommended (Rec 4); embedder `model_name/0` addition verified needed (`embedder.ex` has no `model_name`, `knowledge.ex:229` hardcodes `Embedder.Deterministic.embed_query`). See Verification §5, §6. |
| ATTR-01 | Reserved host-declared keys `feature`/`route`/`archetype`/`intent` threaded through the existing metadata precedent; Scoria reserves and passes through, never infers | `Redactor.redact/1` recursion verified (`redactor.ex:32-46`) — values pass through unchanged; bare-key precedent (`tenant_id`/`workflow_run_id`) verified in both adapters. See Verification §4, §7. |
| ATTR-02 | Context-pack / token-budget composition on the prompt-composition span (chunk IDs + memory IDs + per-source token split), alongside `gen_ai.usage.input_tokens` — IDs and counts only, never raw text | `gen_ai.usage.input_tokens` key verified (`attributes.ex:221`); `usage(nil) -> %{}` verified (`attributes.ex:211`); reachability gated on D-ATTR01-7 (RESOLVED, Rec 1). See Verification §8 + Recommendation 1. |
</phase_requirements>

## Summary

Phase 52's CONTEXT.md is unusually complete: every material decision is locked and was code-verified during the discuss pass. This research re-ran that verification against the current tree and found **zero drift** — all twelve code-anchored claims (Verification §1–§8 below) still hold at the cited file:line. The reliable production core — **RETR-01 + RETR-02 + ATTR-01-on-the-RETRIEVER-span** — is fully implementable today because the host's `feature/route/archetype/intent` and retrieval-config values arrive directly in `Knowledge.retrieve/2` opts and Scoria emits that span itself through the Phase-51 pipeline.

The one genuinely-open item is **D-ATTR01-7**: `req_llm`'s native `[:req_llm, :request, :stop]` telemetry does **not** forward arbitrary host keys. I re-verified this against `deps/req_llm/lib/req_llm/telemetry.ex:485-514` (`request_metadata/2` builds a fixed base map; the only host-influenced channel is `request_options`, which is filtered to a closed `gen_ai.request.*` allow-list at `request_options.ex:26-42`). There is **no** req_llm option or metadata path that carries `feature`/`context_pack` onto a real emission — the existing Phase-51 adapter test only passes because it hand-synthesizes the event. **Recommendation: a Scoria-owned host-facing `Scoria.Observe.emit_prompt_span/1` helper** the host calls at prompt-assembly time (symmetric with the new `emit_retriever_span/1`), emitting `[:scoria, :observe, :span, :stop]` with composition + host keys + host-supplied `gen_ai.usage.input_tokens`. This is doctrine-honest ("host declares"), reuses the exact same persistence seam, and stays strictly inside the Phase-52 boundary because it carries composition **attributes** on a Scoria-emitted span — it does **not** build Phase-53's child-span parent-linkage structure or events.

**Primary recommendation:** Build one `Scoria.Observe` module exposing two sibling emitters — `emit_retriever_span/1` (D-R7) and `emit_prompt_span/1` (D-ATTR01-7) — both routing host metadata through a single set of Semconv-owned projections; validate every requirement with the Phase-51 drift-guard discipline (canary + real-Postgres-after-`flush_now` + anti-inline grep).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| RETRIEVER span emission | API/Backend (`Scoria.Observe`) | — | Scoria owns the span; host calls `retrieve/2` and never touches span plumbing (consumer-not-provider DNA). |
| Retrieval-config value origin | Host (declares) + API (schema owner) | — | `index_version`/`reranker` values are host-supplied; Scoria owns the `scoria.retrieval.*` schema (D-00b). |
| `feature/route/archetype/intent` values | Host (declares) | API (reserves + passes through) | Scoria never infers (`REQUIREMENTS.md:74`); it only reserves the key names and threads them unchanged. |
| Context-pack composition | Host (assembles prompt) | API (records IDs/counts) | Scoria does not assemble the RAG prompt (`summarize_worker.ex:96` is the only `build_prompt/2`, compaction-internal), so it cannot infer composition. |
| Span persistence | API (`Buffer` GenServer → Postgres) | — | Eventually-consistent async flush; FK-safe trace-upsert-then-span (Phase 51). |
| Redaction | API (`Redactor` at the `Telemetry` seam) | — | Runs on every span synchronously in the caller; host values pass through key-based recursion unchanged. |
| Trace-tree display | Frontend (`TraceTreeComponent`) | — | Reads `span_kind` via the shared `SpanKind.normalize/1`; already renders `retriever`. |

## Standard Stack

No new runtime dependencies. Phase 52 is pure application-layer wiring over already-present modules.

### Core (already in tree — reuse, do not add)
| Module / Asset | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `:telemetry` | (transitive) | Span emission bus (`[:scoria, :observe, :span, :stop]`) | The Phase-51 span pipeline is built on it; the RETRIEVER + prompt emitters reuse it verbatim. |
| `Scoria.Observe.Buffer` | in-repo | FK-safe async span persistence + `flush_now/1` test hook | Verified `buffer.ex:23,109,123-129`; the only correct write path (trace-upsert-before-span lives only here). |
| `Scoria.Observe.Semconv` | in-repo | Single key-string owner | Verified `semconv.ex`; moduledoc already reserves the ATTR-01 keys (`semconv.ex:13`). |
| `Scoria.Observe.SpanKind` | in-repo | `normalize/2` + `to_openinference/1`; `retriever`→`RETRIEVER` present | Verified `span_kind.ex:24,32,83`. |
| `Scoria.Observe.Redactor` | in-repo | Depth-recursive key-based redaction on every span | Verified `redactor.ex:32-46`; ATTR-01/02 values pass through unchanged. |
| `req_llm` | 1.13.0 (locked) | `gen_ai.usage.input_tokens` key source (reference, not a call dependency for host keys) | Verified `mix.lock:50`; `attributes.ex:221`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scoria-owned `emit_prompt_span/1` (Rec 1) | Rely on req_llm forwarding host metadata | **Rejected — impossible.** `request_metadata/2` (`telemetry.ex:485-514`) builds a fixed base map; no host-key channel exists. Confirmed below. |
| Scoria-owned `emit_prompt_span/1` | Annotate the existing LLM span in-place after emission | **Rejected — no seam.** The LLM span is persisted async through `Buffer` with no post-hoc update path (span `insert_all` has no `on_conflict`, `buffer.ex:129`); there is no "annotate an already-flushed span" API, and building one is Phase-53 structural work. |
| `scoria.prompt.context` nested map | OpenInference indexed-flat keys (`…chunks.0.id`) | Rejected by D-ATTR02-3 (bloats jsonb/GIN key space; nested supports `@>` + `jsonb_array_elements`). |

**Installation:** none.

## Package Legitimacy Audit

Not applicable — Phase 52 installs **no external packages**. All work is application-layer code over modules already present in the repository (`Scoria.Observe.*`, `Scoria.Knowledge`) and one already-locked dependency (`req_llm 1.13.0`, referenced for a key name only). No `npm`/`pip`/`cargo`/`hex` add.

## Architecture Patterns

### System Architecture Diagram

```
                    HOST APP
                       │
      ┌────────────────┼─────────────────────────────┐
      │                │                              │
 retrieve/2 opts   (host assembles prompt)      req_llm call
 (feature, route,  builds context_pack          (unchanged;
  archetype,       {chunks,memories,budget}       emits gen_ai.*
  intent,          + host input_tokens            with NO host keys)
  embedding_model, │                              │
  index_version,   │                              │
  reranker,        ▼                              ▼
  parent_id)  Scoria.Observe.emit_prompt_span/1   [:req_llm,:request,:stop]
      │            (NEW, D-ATTR01-7)               (Phase-51 adapter)
      ▼            │                               │
 Knowledge.retrieve/2                              │
   │  mint trace_id/span_id (D-R2)                 │
   │  wall-clock start (D-R4)                      │
   │  build ONE config map (D-RETR02-1)            │
   │  normalize opts→map (D-ATTR01-3)              │
   │                                               │
   ├──► create_retrieval_run(metadata:             │
   │      config_attrs + host_keys)  ──► ai_retrieval_runs (SYSTEM OF RECORD, kept)
   │                                               │
   └──► Scoria.Observe.emit_retriever_span/1 (NEW, D-R7)
              │                                     │
              ▼                                     ▼
   ══════════ ONE SHARED SEAM ══════════════════════════
   Semconv projections (all keys owned here):
     • retrieval_config_attributes/1  → scoria.retrieval.*
     • merge_host_declared/2          → feature/route/archetype/intent (bare)
     • prompt_context/1 (+ key)       → scoria.prompt.context (prompt span only)
   ══════════════════════════════════════════════════════
              │                                     │
              ▼                                     ▼
   :telemetry.execute([:scoria,:observe,:span,:stop], %{}, span)
              │
              ▼
   Telemetry.handle_event → Redactor.redact/1 → ReviewerBroadcast
              │             → buffer_span/1 = Map.take(@span_buffer_fields)  ⚠ (D-00: keys survive ONLY inside :attributes)
              ▼
   Buffer.cast_span → (async flush | flush_now/1 in tests)
              │
              ▼
   Ecto.Multi: insert_all traces (on_conflict :nothing) → insert_all spans (NO on_conflict)
              │
              ▼
        ai_spans  (RETRIEVER span; PROMPT-composition span)
              │
   operators JOIN retriever↔prompt on the shared chunk/memory ID values
```

### Component Responsibilities
| File | Change | Decision |
|------|--------|----------|
| `lib/scoria/observe.ex` (NEW or extend) | `emit_retriever_span/1`, `emit_prompt_span/1` | D-R7, D-ATTR01-7 |
| `lib/scoria/observe/semconv.ex` | `retrieval_config_attributes/1`, `host_declared_keys/0`, `merge_host_declared/2`, `prompt_context/1`, `prompt_context_key/0` | D-00c, D-RETR02-3, D-ATTR01-1/2, D-ATTR02-3 |
| `lib/scoria/knowledge.ex` (`retrieve/2`, `:215`) | mint IDs, wall-clock, one config map, normalize opts→map, `:embedder` resolution, call `emit_retriever_span/1` after the `with`, additive return | D-R2/R3/R4, D-RETR02-1/2, D-ATTR01-3 |
| `lib/scoria/knowledge/embedder.ex` | `@optional_callbacks [model_name: 0]` + `Deterministic.model_name/0` | D-RETR02-5 |
| `test/scoria/knowledge/retrieval_test.exs` (`:47-72`) | migrate `span_id:`→`parent_id:` assertion | **D-R2b (mandatory)** |
| `lib/scoria/observe/adapters/{req_llm,jido}.ex` | pipe `merge_host_declared/2` into `attributes` | D-ATTR01-5 (real-event reachability gated by D-ATTR01-7) |

### Pattern 1: Sibling Scoria-owned emitters (the D-ATTR01-7 mechanism)
**What:** A host-facing `Scoria.Observe.emit_prompt_span/1` symmetric with `emit_retriever_span/1`. Both build a span map and `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`. This is the doctrine-honest injection seam.
**When to use:** The host calls `emit_prompt_span/1` at prompt-assembly time (where it already knows the chunk/memory IDs and per-source token split), passing `context_pack`, the host-declared keys, and its `gen_ai.usage.input_tokens`.
**Example (recommended signature — see Recommendation 1 for the full contract):**
```elixir
# Source: mirrors lib/scoria/observe/adapters/req_llm.ex:39-52 (verified this session)
Scoria.Observe.emit_prompt_span(%{
  trace_id: trace_id,           # join key to the RETRIEVER span's trace
  parent_id: parent_span_id,    # host declares; nil ⇒ trace root
  span_id: Ecto.UUID.generate(),# this prompt span's OWN id (fresh, D-R2 semantics)
  context_pack: %{
    chunks: [%{id: chunk_uuid, tokens: 128}, ...],
    memories: [%{id: mem_uuid, tokens: 64}, ...],
    token_budget: %{total: 2048, chunks: 1200, memories: 700, overhead: 148}
  },
  input_tokens: 1900,           # host-supplied gen_ai.usage.input_tokens
  feature: "support-copilot", route: "/tickets/:id", archetype: "rag", intent: "answer"
})
```

### Anti-Patterns to Avoid
- **Assuming req_llm forwards host metadata:** it does not (Verification §8). Do not write plans that thread `context_pack` through a req_llm option.
- **Synchronous `Repo.insert` of the span:** re-opens the FK footgun Phase 51 fixed; skips redaction/broadcast; taxes the hot path (D-R1).
- **Passing an existing `ai_spans.id` as `opts[:span_id]`:** PK-collides (no `on_conflict`, `buffer.ex:129`) → span silently dropped. `span_id` must be fresh (D-R2).
- **Deriving `start_time = end_time - latency`:** double-samples/drifts (D-R4).
- **Adding new top-level span fields:** dropped by `Map.take(@span_buffer_fields)` (`telemetry.ex:68-72`). All keys go in `:attributes` (D-00).
- **A `sum(tokens) == input_tokens` guard:** chat-template overhead guarantees drift → flaky (D-ATTR02-5).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Span persistence with correct FK ordering | A bespoke `Repo.insert` in `retrieve/2` | `:telemetry.execute → Buffer` | Trace-upsert-before-span exists only in `Buffer.flush_spans` (`buffer.ex:123-129`); anything else violates the FK Phase 51 fixed. |
| Redaction of host values | A Phase-52 length/PII bound | Existing `Redactor.redact/1` | Already recurses maps/lists (`redactor.ex:32-46`); a new bound is SEC-01/Phase-53 (D-ATTR01-4). |
| span_kind string + OI mirror | Hardcoded `"RETRIEVER"` literal | `SpanKind.normalize("retriever")` + `to_openinference/1` | Verified `span_kind.ex:24,32,83`; anti-inline grep guards forbid literals. |
| gen_ai.* key strings | Re-declaring `"gen_ai.usage.input_tokens"` | Reference `req_llm`'s `attributes.ex:221` value; own only `scoria.*` in Semconv | FOUND-03 discipline; one-module diff on upstream rename. |
| Test-timer racing | `Process.sleep` before asserting the join | `Buffer.flush_now/1` | Verified `buffer.ex:23,58-61`; synchronous flush hook exists for exactly this. |

**Key insight:** Phase 52 is a *composition* phase — every hard problem (FK ordering, redaction, key ownership, taxonomy, flush timing) was already solved in Phase 51. The risk is re-solving one of them incorrectly, which the drift-guard tests exist to catch.

## Verification of Locked Code-Anchored Claims

All claims in CONTEXT.md were re-checked against the live tree this session. **Result: zero drift.** Each row cites the exact file:line confirmed.

| # | CONTEXT claim | Cited location | Status |
|---|---------------|----------------|--------|
| §1 | `Telemetry.buffer_span/1` does `Map.take(redacted, @span_buffer_fields)`; the field list is `id/trace_id/parent_id/name/span_kind/status_code/start_time/end_time/attributes` | `telemetry.ex:68-72` (`@span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a`) | ✅ VERIFIED [VERIFIED: codebase grep] |
| §2 | Buffer FK-safe multi: trace `insert_all` `on_conflict: :nothing` → span `insert_all` with **NO** `on_conflict`; `Map.put_new_lazy(:id, …)` preserves a pre-set id; `flush_now/1` test hook | `buffer.ex:109` (put_new_lazy), `:123-129` (multi; span insert has no on_conflict), `:23` + `:58-61` (flush_now) | ✅ VERIFIED |
| §3 | `retrieve/2` shape; hardcoded `Embedder.Deterministic.embed_query` on the nil-retriever path; `retrieve/2` takes no `:embedder` opt; computes `latency_ms` via monotonic delta; validate_retrieval_result reads `chunk_id`/`source_id` | `knowledge.ex:215` (retrieve), `:229` (hardcoded embed_query), `:219` (retriever opt only — no `:embedder`), `:222/252` (monotonic latency), `:371-385` (chunk_id/source_id) | ✅ VERIFIED — `:embedder` resolution must be ADDED (D-RETR02-2) |
| §4 | `Redactor.redact/1` recurses into nested maps/lists, key-based | `redactor.ex:32-46` (`do_redact` map clause `:32-40`, list clause `:42-44`) | ✅ VERIFIED (spans one line later than the cited `:32-44`; behavior identical) |
| §5 | `SpanKind.normalize` + `to_openinference` define `retriever`→`RETRIEVER` | `span_kind.ex:24` (`@kinds` includes `retriever`), `:32` (`"retriever" => "RETRIEVER"`), `:83` (`to_openinference/1`) | ✅ VERIFIED |
| §6 | `Semconv` moduledoc reserves the ATTR-01 keys; owns `openinference.span.kind`; delegates `gen_ai.*` to req_llm | `semconv.ex:13` (moduledoc reserves feature/route/archetype/intent), `:16-20` (OI key), `:29-33` (merge_req_llm) | ✅ VERIFIED |
| §7 | `ai_retrieval_runs.metadata :map` cast | `retrieval_run.ex:20` (`field(:metadata, :map, default: %{})`), `:42` (in `cast/3` list) | ✅ VERIFIED (cast is at `:42`, CONTEXT said `:44` — off by two; still present and cast) |
| §8 | `gen_ai.usage.input_tokens` key name; `usage(nil) -> %{}` | `attributes.ex:221` (`"gen_ai.usage.input_tokens" => …`), `:211` (`defp usage(nil), do: %{}`) | ✅ VERIFIED |
| §8b | **req_llm does NOT forward arbitrary host keys** — `request_metadata/2` builds a fixed base map; `tenant_id`/`context_pack`/`feature` never present on a real emission | `telemetry.ex:485-514` (fixed base map: request_id/operation/mode/provider/model/transport/reasoning/request_options/server/…/usage); `request_options.ex:19-42` (closed allow-list, `gen_ai.request.*` only) | ✅ VERIFIED — **the BLOCKER is real** (D-ATTR01-7); resolved by Recommendation 1 |
| §9 | The test to migrate: `retrieval_test.exs` inserts a `Span` and calls `retrieve(..., span_id: span.id)`, asserting `run.span_id == span.id` | `retrieval_test.exs:47-52` (inserts Span), `:60` (`span_id: span.id`), `:65` (`assert run.span_id == span.id`) | ✅ VERIFIED — migration is mandatory (D-R2b); the assertion is at `:65`, CONTEXT said ~50-73 (correct range) |

**Minor citation drift (non-material):** `redactor.ex` map/list recursion spans `:32-46` (CONTEXT said `:32-44`); `retrieval_run.ex` metadata cast is at `:42` (CONTEXT said `:44`); `retrieval_test.exs` `span_id`-assertion is at `:65`. None change any decision — the code behaves exactly as CONTEXT describes.

## Recommendation 1 (PRIMARY, D-ATTR01-7): The host-owned prompt-span injection mechanism

**Decision: build a Scoria-owned `Scoria.Observe.emit_prompt_span/1` helper.** Rejected alternatives (req_llm forwarding, in-place LLM-span annotation) are impossible/absent — see Alternatives Considered and Verification §8b.

### Why req_llm cannot carry the host keys (verified)
`ReqLLM.Telemetry.request_metadata/2` (`telemetry.ex:485-514`) constructs a **fixed** base map — `request_id`, `operation`, `mode`, `provider`, `model`, `transport`, `reasoning`, `request_options`, `server`, timing, summaries, `http_status`, `finish_reason`, `usage`, and (conditionally) `streaming`/`request_payload`/`response_payload`/`error`/`builtin_tool_timing`. There is **no merge of caller-supplied arbitrary keys.** The only caller-influenced channel is `request_options`, and `ReqLLM.Telemetry.RequestOptions.extract/2` (`request_options.ex:19-42`) hard-codes a closed set that maps 1:1 to `gen_ai.request.*` — it drops everything else. Therefore `feature`/`context_pack` **cannot** ride a real `[:req_llm, :request, :stop]` event. The Phase-51 adapter's `metadata[:tenant_id]` read (`req_llm.ex:15`) only ever yields non-nil in the hand-synthesized test event; on a real emission `metadata[:tenant_id]` is `nil` and the base_attributes reject-nils drops it (`req_llm.ex:23`). This is exactly the red-team BLOCKER.

### Recommended contract
```elixir
# lib/scoria/observe.ex  (new public module — or add to an existing Scoria.Observe facade)
@doc """
Host-facing emitter for the prompt-composition span. The host calls this at
prompt-assembly time, where it alone knows which chunks/memories entered the
budget and their token split. Symmetric with emit_retriever_span/1; both route
through the same Semconv-owned projections and the Phase-51 span pipeline.

Carries composition ATTRIBUTES on a Scoria-emitted span (Phase 52). Phase 53
(EVENT-01) relocates the identical Semconv keys onto a real PROMPT child span
with parent linkage — zero contract change.
"""
@spec emit_prompt_span(map()) :: :ok
def emit_prompt_span(opts) when is_map(opts)
```

- **Telemetry event:** `[:scoria, :observe, :span, :stop]` (the SAME event the RETRIEVER + adapter spans use — reuses redaction, `ReviewerBroadcast`, FK-safe flush verbatim).
- **`span_kind`:** `SpanKind.normalize("prompt")` (present in `@kinds`, maps to `PROMPT`, `span_kind.ex:24,29`). Mirror `to_openinference/1` under `Semconv.openinference_span_kind_key()`.
- **`name`:** `"prompt.compose"` (low-cardinality, operator-legible; parallels D-R5's `"knowledge.retrieve"`).
- **`attributes`:** `merge_host_declared/2` (feature/route/archetype/intent) + `Semconv.prompt_context/1` under `Semconv.prompt_context_key()` (`"scoria.prompt.context"`, nested map per D-ATTR02-3) + `"gen_ai.usage.input_tokens" => opts[:input_tokens]` (host-supplied; omit when nil per D-ATTR02-5). **Never** raw chunk/memory text (structural map-to-`%{id,tokens}` per D-ATTR02-4).
- **IDs (D-R2 semantics):** `trace_id` = the same trace as the RETRIEVER span (the join key); `span_id`/`:id` = this prompt span's OWN fresh id; `parent_id` = host-declared (nil ⇒ root). Same fresh-id discipline as the RETRIEVER span — passing an existing PK collides.
- **Failure isolation (D-R6 mirror):** wrap the emit `try/rescue → :ok` because `:telemetry.execute` runs `Redactor`/`ReviewerBroadcast` synchronously in the caller — a bad handler must never crash the host's prompt path.
- **Empty pack (D-ATTR02-7):** when `context_pack` is absent or both lists empty, omit `scoria.prompt.context` entirely (no empty-but-present key).

### Where the host calls it
At the host's prompt-assembly site — the same place it decides which retrieved chunks + compacted memories to include and computes the per-source token split — immediately before (or after) the `req_llm` call. Scoria does **not** assemble the RAG prompt (`summarize_worker.ex:96`'s `build_prompt/2` is compaction-internal), so this must be a host call. Document it in the `Scoria.Observe` moduledoc and a capability guide fragment as the symmetric partner to `emit_retriever_span/1`.

### Phase-53 boundary (do not cross)
Phase 52 carries composition **attributes** on a Scoria-emitted span. It does **not**: build real duration/failure-bearing child spans, formalize `parent_id` linkage semantics beyond passthrough, emit `ai_span_events`, or add the SEC-01 write-time bound. When Phase 53/EVENT-01 introduces the real `PROMPT` child span, the identical `scoria.prompt.context` + host keys relocate onto it with zero contract change (D-ATTR02-1). The `emit_prompt_span/1` name should be chosen with that continuity in mind (it becomes the prompt child-span emitter in Phase 53).

## Recommendation 2 (verification confirmation): the reliable core is unblocked

**RETR-01 + RETR-02 + ATTR-01-on-the-RETRIEVER-span are fully implementable now** and independent of D-ATTR01-7, because the host's config + host-declared values arrive directly in `retrieve/2` opts and Scoria emits the RETRIEVER span itself. Plan these as the load-bearing spine; treat `emit_prompt_span/1` (ATTR-02 + ATTR-01-on-the-prompt-span) as the second, host-call-dependent lane. Both lanes share the same Semconv projections and the same drift-guard discipline.

**Concrete `retrieve/2` edits (all verified feasible against `knowledge.ex:215-257`):**
1. `started_wall = DateTime.utc_now()` at the top (D-R4); keep the existing monotonic `started_at` (`:222`) as `latency_ms` authority.
2. `trace_id = opts[:trace_id] || Ecto.UUID.generate()`, `span_id = opts[:span_id] || Ecto.UUID.generate()` (D-R2).
3. Add `:embedder` resolution (`embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)`) — needed because `:229` currently hardcodes `Embedder.Deterministic.embed_query` and there is no `:embedder` opt today (Verification §3). Use the resolved embedder both for the nil-retriever embed path AND the `embedding_model` precedence lookup (D-RETR02-2).
4. Build ONE `%{embedding_model:, index_version:, reranker:}` map (D-RETR02-1); feed it through `Semconv.retrieval_config_attributes/1` to both `create_retrieval_run(metadata: …)` and the span.
5. `metadata = Map.new(opts)` before the host-declared seam (D-ATTR01-3 — avoids `BadMapError`; `opts` is a keyword list).
6. Write `span_id` to BOTH the run row's `span_id` column (`:250`, currently `opts[:span_id]`) AND the emitted span's `:id`.
7. After the `with` succeeds, `try: Scoria.Observe.emit_retriever_span(span_map) rescue _ -> :ok` (D-R6).
8. Additive return: `{:ok, %{run: run, results: persisted_results, trace_id: trace_id, span_id: span_id}}` (existing callers use partial map patterns — non-breaking; verified `retrieval_test.exs:54` matches `%{run: …, results: …}`).

## Recommendation 3 (trace-tree UI surfacing): minimal-to-zero change

**Finding:** `ScoriaWeb.TraceTreeComponent` (`trace_tree_component.ex`) already renders any span whose `span_kind` normalizes to a canonical kind. It reads `span_kind` via `Scoria.Observe.SpanKind.normalize/1` (`:86-90`) and applies the CSS rail class `scoria-span--#{span_kind(span)}` (`:34`). The `retriever` rail exists (`assets/css/04-components.css:1087` — `.scoria-span--retriever .scoria-span__rail { background: var(--scoria-span-retriever); }`). So a persisted RETRIEVER span will render in the tree with its correct rail **with no component change**.

**What the plan may optionally touch (display legibility, not correctness):**
- The component currently displays only the span `name` and (for `llm`) a token preview (`:45-51,73-80`). The `scoria.retrieval.*` config attrs and `scoria.prompt.context` composition live in `attributes` and are surfaced only through the existing lazy `load_metadata` click path (`:15-25`), which returns a placeholder string (`:20-21`) — it does not yet render real attribute maps. **Recommendation:** keep Phase 52 scope minimal — do NOT build attribute-rendering UI here. Emitting the span so it appears in the tree with the right rail satisfies RETR-01's "visible in the trace tree." Rich attribute display is a display concern that can ride a later UI pass; flag it as an open display item rather than expanding Phase 52.
- Only consumer of the component is `orchestrator_live.ex` (verified via grep) — no other surface needs coordination.

**Net:** the RETRIEVER span is visible/legible with **zero required UI edits**; any attribute-panel work is optional and out of the critical path.

## Recommendation 4 (factoring): sibling functions, one module, all Semconv-owned

**Recommendation: three sibling Semconv functions, not one generic projection.** The three new key families have genuinely different shapes and precedence rules:
- `retrieval_config_attributes/1` — three fixed dotted keys with per-field precedence + `"none"` sentinel (D-RETR02-2/4).
- `merge_host_declared/2` — reduce over `host_declared_keys/0`, skip-nil, bare atom-to-string keys (D-ATTR01-2).
- `prompt_context/1` (+ `prompt_context_key/0`) — a single key holding a nested, structurally-sanitized map with a ≤100 cap (D-ATTR02-3/4/6).

A single generic projection would have to branch internally on all three shapes, obscuring the per-family guards and making the drift-guard tests harder to target. Three named siblings keep each family's canary test crisp (each asserts its own exact key list) and each anti-inline grep scoped. **All three stay Semconv-owned** (D-00c) and grep-guarded — the factoring is internal and does not weaken the "one seam" spine (they are all called from the same two emitters + two adapters). This matches the Phase-51 precedent where `merge_req_llm_attributes/2` and `openinference_span_kind_key/0` coexist as siblings in `Semconv` rather than one mega-function.

## Runtime State Inventory

Phase 52 is **greenfield emission + new convention keys** — it renames/migrates no stored data. Explicit per-category audit:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — no existing `ai_retrieval_runs.metadata` values use the new `scoria.retrieval.*` or bare host keys (grep `index_version`/`reranker` returned empty across `lib/` and `priv/`); no RETRIEVER spans exist yet (Phase 51 fixed the FK only for adapter spans). No backfill needed. | None |
| Live service config | **None** — no external service holds these keys; the convention is internal to Scoria's own Postgres. | None |
| OS-registered state | **None** — no OS-level registration involved. | None |
| Secrets/env vars | `index_version` optionally reads `Application.get_env(:scoria, :index_version)` (D-RETR02-2) — a NEW optional config key, not a rename; defaults to `"none"` when absent. No existing secret/env renamed. | Document the optional `:index_version` app-env key. |
| Build artifacts | **None** — no compiled artifacts carry these names; pure source addition. | None |

**Canonical question — after every file is updated, what runtime systems still have an old string cached/stored/registered?** Answer: **nothing.** Phase 52 introduces new keys and a new span kind that no prior data used; there is no old value to migrate. The one behavioral semantic change (`opts[:span_id]` redefined from "caller's parent span" to "this retrieval's own span id", D-R2) affects only **code and the one test** (`retrieval_test.exs:60,65`), not stored rows — no existing `ai_retrieval_runs.span_id` value needs rewriting because the column's meaning (the run's own span) is unchanged; only the caller contract for supplying it changes.

## Common Pitfalls

### Pitfall 1: PK collision from a reused span_id
**What goes wrong:** A caller passes an existing `ai_spans.id` as `opts[:span_id]`; the span `insert_all` has no `on_conflict` (`buffer.ex:129`), so the transaction errors and the whole batch is dropped via the flush-error path — silently, from the caller's perspective.
**Why it happens:** D-R2 redefines `opts[:span_id]` semantics; a caller written against the old "reference to parent" meaning would pass the wrong id.
**How to avoid:** Mint fresh (`opts[:span_id] || Ecto.UUID.generate()`); document both axes on `retrieve/2` (`opts[:parent_id]` = caller's span; `opts[:span_id]` = this retrieval's own). The migrated `retrieval_test.exs` proves the new contract.
**Warning signs:** A retrieval succeeds but no RETRIEVER span appears after `flush_now/1`; a `[:scoria, :observe, :buffer, :flush_error]` event fires.

### Pitfall 2: Keys silently dropped by buffer_span
**What goes wrong:** A new key placed as a top-level span field (e.g. `span.context_pack`) never persists.
**Why it happens:** `buffer_span/1` does `Map.take(redacted, @span_buffer_fields)` (`telemetry.ex:68-72`); only nine fields survive.
**How to avoid:** Everything except id/trace_id/parent_id/name/span_kind/status_code/start_time/end_time goes **inside `:attributes`** (D-00). The RETR-02 real-Postgres equality test catches a dropped config key.
**Warning signs:** Span row exists but `attributes` is missing an expected key.

### Pitfall 3: Redactor mutates a host value
**What goes wrong:** A host-declared value keyed `token`/`secret`/`password`/`api_key` comes back `[REDACTED]`, breaking the "flows through unmodified" criterion.
**Why it happens:** `Redactor.redact/1` is key-based (`redactor.ex:6,32-40`) and recurses; a host who names a dimension `token` triggers it.
**How to avoid:** This is *correct, documented behavior* (D-ATTR01-4 keeps the existing redactor unchanged). The ATTR-01 sentinel pass-through guard must use a value that is NOT on the deny-list (e.g. `feature: "support-copilot"`), and the guard documents that deny-listed keys are intentionally redacted.
**Warning signs:** A guard using `feature: "token"` unexpectedly sees `[REDACTED]` — that is the redactor working as intended, not a bug.

### Pitfall 4: input_tokens asserted present unconditionally
**What goes wrong:** The ATTR-02 test asserts `gen_ai.usage.input_tokens` is always on the prompt span; it's absent on embedding-only/failed calls.
**Why it happens:** `usage(nil) -> %{}` (`attributes.ex:211`) omits the key when usage is nil.
**How to avoid:** Tolerate absence (D-ATTR02-5); the SC#4 acceptance test supplies a populated pack WITH a host `input_tokens` value and asserts coexistence, but the general guard must not assert unconditional presence.

## Code Examples

### RETRIEVER span map (mirrors the verified req_llm adapter shape)
```elixir
# Source: lib/scoria/observe/adapters/req_llm.ex:39-52 (verified this session)
# emit_retriever_span/1 builds an analogous map:
span = %{
  name: "knowledge.retrieve",                     # D-R5, low-cardinality
  span_kind: SpanKind.normalize("retriever"),      # → "retriever"
  status_code: "OK",                               # D-R5 (success-path only, D-R6)
  start_time: started_wall,                         # D-R4 wall-clock
  end_time: DateTime.utc_now(),                     # D-R4
  trace_id: trace_id,                               # minted D-R2
  id: span_id,                                      # OWN id == run.span_id (D-R2)
  parent_id: opts[:parent_id],                      # host-declared, nil ⇒ root (D-R3)
  attributes:
    %{}
    |> Map.put(Semconv.openinference_span_kind_key(),
               SpanKind.to_openinference("retriever"))   # → "RETRIEVER"
    |> Map.merge(Semconv.retrieval_config_attributes(config_map))  # scoria.retrieval.*
    |> Semconv.merge_host_declared(host_metadata)                  # feature/route/archetype/intent
}
:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
```

### The RETR-02 consistency guard (D-RETR02-7 — real-Postgres after flush_now)
```elixir
# Pattern: Phase-51 D-15 drift-guard discipline
# (1) canary
assert Semconv.retrieval_config_keys() ==
  [embedding_model: "scoria.retrieval.embedding_model",
   index_version: "scoria.retrieval.index_version",
   reranker: "scoria.retrieval.reranker"]

# (2) real-Postgres equality (after Buffer.flush_now/1)
{:ok, %{run: run}} = Knowledge.retrieve("q", scope: @scope, embedding_model: "m", index_version: "v1")
Scoria.Observe.Buffer.flush_now()
span = Repo.get_by!(Span, id: run.span_id)
keys = Keyword.values(Semconv.retrieval_config_keys())
assert map_size(Map.take(run.metadata, keys)) == 3
assert Map.take(span.attributes, keys) == Map.take(run.metadata, keys)

# (3) anti-inline grep
refute File.read!("lib/scoria/observe/adapters/req_llm.ex") =~ "scoria.retrieval."
# ...assert the literal appears ONLY in semconv.ex
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `opts[:span_id]` = a reference to the caller's/parent span stored on the run | `opts[:span_id]` = this retrieval's OWN span id (the join key); parent goes in `opts[:parent_id]` | Phase 52 (D-R2) | `retrieval_test.exs:60,65` migration mandatory; callers passing an existing PK now collide. |
| Retrieval visible only as `ai_retrieval_runs` rows | Dual-write: run row (system-of-record) + linked RETRIEVER span | Phase 52 (RETR-01) | Trace tree shows retrieval; table kept, never collapsed. |
| Host keys assumed to ride req_llm metadata | Scoria-owned `emit_prompt_span/1` host-call seam | Phase 52 (D-ATTR01-7 resolution) | req_llm forwarding is impossible; host must call the helper. |

**Deprecated/outdated:** none introduced.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The host has a discrete prompt-assembly call site where it can call `emit_prompt_span/1` with the chunk/memory IDs + token split it already computed. | Recommendation 1 | If a host cannot supply composition, ATTR-02 simply has no data for that call (D-ATTR02-7 omits the key) — graceful degradation, not a break. LOW risk. |
| A2 | `SpanKind.normalize("prompt")` → `"prompt"` and maps to `"PROMPT"` for the prompt-composition span kind. | Recommendation 1 | Verified present in `@kinds`/`@openinference_map` (`span_kind.ex:24,29`). Effectively VERIFIED — listed here only because the prompt-span *usage* is new. |
| A3 | Additive `retrieve/2` return (adding `trace_id`/`span_id`) is non-breaking for all callers. | Recommendation 2 | Verified against `retrieval_test.exs` partial-map patterns; a caller using an exact `%{run:, results:}` map-size match would break. LOW risk — grep found none. |

**If a host names a host-declared dimension with a deny-listed key** (`token`/`secret`/etc.), the value is intentionally redacted (Pitfall 3) — this is documented behavior, not an assumption gap.

## Open Questions

1. **Rich attribute rendering in the trace tree** — `TraceTreeComponent`'s `load_metadata` path returns a placeholder (`trace_tree_component.ex:20-21`), not the real `attributes` map.
   - What we know: the RETRIEVER span renders with its rail today (Rec 3); config/composition attrs persist in `attributes`.
   - What's unclear: whether operators need the `scoria.retrieval.*` / `scoria.prompt.context` values displayed inline in this milestone.
   - Recommendation: keep out of Phase 52 scope; RETR-01 "visible in the tree" is satisfied by the rail. Flag as a later display item.

2. **Exact `emit_prompt_span/1` module home** — new `lib/scoria/observe.ex` facade vs. adding to an existing `Scoria.Observe.*` module.
   - Recommendation: a `Scoria.Observe` public facade housing both `emit_retriever_span/1` and `emit_prompt_span/1` reads best (consumer-facing symmetry, DNA "hide plumbing"). Planner's call.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (+ pgvector) | Retrieval + span persistence + real-Postgres guards | ✓ (project standard; `scoria.pgvector.bootstrap` + `Migrations.migrate_knowledge!`) | project-pinned | — |
| `req_llm` | `gen_ai.usage.input_tokens` key reference | ✓ | 1.13.0 (`mix.lock:50`) | — |
| Elixir/`:telemetry`/Ecto | Span emission + jsonb | ✓ | project toolchain | — |

**Missing dependencies:** none. Phase 52 adds no external tools or services.

## Validation Architecture

> Nyquist validation is enabled (`.planning/config.json` has no `workflow.nyquist_validation: false`). This section maps each requirement to an automated test using the Phase-51 drift-guard discipline (canary + exhaustiveness + anti-inline grep + real-Postgres assertion after `Buffer.flush_now/1`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `test/test_helper.exs`; knowledge lane gated by `@moduletag :knowledge` (`test/support/knowledge_case.exs:10`) |
| Knowledge/Postgres lane | `mix scoria.test.knowledge` (bootstraps pgvector + migrates core+knowledge, runs `--only knowledge`; `lib/mix/tasks/scoria.test.knowledge.ex:13-26`) |
| Observe unit lane | `mix test test/scoria/observe/` |
| Full suite | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RETR-01 | `retrieve/2` produces a persisted `ai_retrieval_runs` row AND a linked RETRIEVER span sharing `trace_id`/`span_id`; join never empty for a successful call | integration (real Postgres, after `flush_now/1`) | `mix scoria.test.knowledge --only knowledge` (new assertions in `test/scoria/knowledge/retrieval_test.exs`) | ⚠️ file exists; NEW assertions + Wave 0 |
| RETR-01 | Span emission never fails retrieval (D-R6 try/rescue) | integration | same lane — induce an emit-path raise, assert `retrieve/2` still `{:ok, …}` | ❌ Wave 0 |
| RETR-01 | **D-R2b mandatory migration** — `retrieval_test.exs:60,65` `span_id:`→`parent_id:`; assert `run.span_id == <minted own-id>` and `retriever_span.parent_id == <passed span.id>` | integration | `mix scoria.test.knowledge --only knowledge` | ⚠️ EXISTS at `:47-72` — **must be edited** |
| RETR-02 | `scoria.retrieval.*` keys equal on span.attributes AND run.metadata; canary key list; anti-inline grep | drift-guard (canary + real-Postgres equality + grep) | `mix scoria.test.knowledge` + `mix test test/scoria/observe/semconv_test.exs` | ❌ Wave 0 (extend `semconv_test.exs`) |
| RETR-02 | Sentinel `"none"` on all three keys when absent (never nil/omit) | unit + integration | same | ❌ Wave 0 |
| RETR-02 | Guarded optional `model_name/0` — host embedder without it falls through, no `UndefinedFunctionError` | unit | `mix test test/scoria/knowledge/` (embedder test) | ❌ Wave 0 |
| ATTR-01 | Sentinel host value passes byte-for-byte through to persisted span attributes (per span type) | drift-guard (pass-through) | `mix scoria.test.knowledge` + observe lane | ❌ Wave 0 |
| ATTR-01 | Empty metadata ⇒ keys ABSENT (`refute Map.has_key?`) — the never-default proof | unit/integration | same | ❌ Wave 0 |
| ATTR-01 | Anti-inline grep: only `semconv.ex` writes a reserved key string | source-scan | `mix test test/scoria/observe/semconv_test.exs` | ❌ Wave 0 |
| ATTR-01 | Guards must use REAL emissions, not hand-synthesized events (D-ATTR01-6 ⚠) | integration | for the RETRIEVER span: real `retrieve/2`; for the prompt span: real `emit_prompt_span/1` call | ❌ Wave 0 |
| ATTR-02 | **SC#4 acceptance** — populated pack (≥1 chunk AND ≥1 memory with token counts) → nested `scoria.prompt.context` coexists with `gen_ai.usage.input_tokens` on the same persisted span (after `flush_now/1`) | integration (real Postgres) | `mix scoria.test.knowledge` (or an observe integration test that calls `emit_prompt_span/1` + `flush_now/1`) | ❌ Wave 0 (D-ATTR02-7) |
| ATTR-02 | Never-text structural guard: every key ∈ allowed set; no key matches `~r/text|content|body|message|prompt|raw/i`; leaves are ID-binary ≤64B or non-neg int; `Jason.encode!` ≤ 8KB | drift-guard (over the fully-built value) | `mix test test/scoria/observe/semconv_test.exs` | ❌ Wave 0 (D-ATTR02-4) |
| ATTR-02 | `input_tokens` absence tolerated (usage nil) — no unconditional-presence assertion | unit | same | ❌ Wave 0 (D-ATTR02-5) |
| ATTR-02 | ≤100-item cap with `"truncated" => true` marker | unit | `mix test test/scoria/observe/semconv_test.exs` | ❌ Wave 0 (D-ATTR02-6) |
| ATTR-02 | Empty/absent pack ⇒ key omitted entirely | unit | same | ❌ Wave 0 (D-ATTR02-7) |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/observe/` (fast, no-DB unit + canary + grep guards).
- **Per wave merge:** `mix scoria.test.knowledge` (real-Postgres integration — the join, equality, and SC#4 acceptance).
- **Phase gate:** full `mix test` green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/scoria/knowledge/retrieval_test.exs` — **edit** the existing `span_id:`→`parent_id:` assertion (D-R2b, `:60/:65`) AND add the RETR-01 join + RETR-02 real-Postgres equality assertions — covers RETR-01, RETR-02.
- [ ] `test/scoria/observe/semconv_test.exs` — **extend** with the RETR-02 canary + anti-inline grep, ATTR-01 never-default + grep, ATTR-02 never-text/cap/omit guards — covers RETR-02, ATTR-01, ATTR-02.
- [ ] New/extended embedder test — guarded optional `model_name/0` fall-through — covers RETR-02.
- [ ] New observe integration test (or fold into knowledge lane) — `emit_prompt_span/1` + `flush_now/1` → SC#4 populated-pack acceptance + ATTR-01-on-the-prompt-span real-emission guard — covers ATTR-02, ATTR-01.
- [ ] Framework install: none — ExUnit + the `scoria.test.knowledge` lane already exist.

*The drift-guard discipline (canary + exhaustiveness + anti-inline grep + real-Postgres-after-`flush_now`) is the mandatory shape for RETR-02 (D-RETR02-7) and ATTR-01 (D-ATTR01-6), mirroring Phase-51 D-15. The SC#4 populated-context-pack acceptance test (D-ATTR02-7) MUST supply ≥1 chunk AND ≥1 memory with token counts and assert coexistence with `gen_ai.usage.input_tokens` on the persisted span.*

## Security Domain

`security_enforcement` is not disabled — this section applies. Phase 52's security surface is narrow: it writes convention keys and IDs/counts to jsonb, never raw text.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Host values pass through the existing key-based `Redactor.redact/1` (`redactor.ex`); no Phase-52-specific validation (D-ATTR01-4 — value hygiene is SEC-01/Phase-53). |
| V7 Error Handling & Logging | yes | Span emission wrapped `try/rescue → :ok` (D-R6) — never crashes the host retrieval/prompt path; failures surface via the Phase-51 `[:scoria, :observe, :buffer, :flush_error]` telemetry. |
| V8 Data Protection | yes | **IDs and counts only, never raw chunk/memory/prompt text** (ATTR-02 core; D-ATTR02-4 structural map-to-`%{id,tokens}` prevents an over-sharing host from smuggling a `text` field). |
| V2/V3/V4/V6 | no | No auth/session/access-control/crypto surface introduced (tenant scoping is inherited from `Scope`, unchanged). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw prompt/completion text leaking into span attributes | Information Disclosure | D-ATTR02-4 never-text structural guard (map to `%{id,tokens}` only); regression test asserts no `text|content|body|message|prompt|raw` key. |
| Unbounded cardinality/size on `scoria.prompt.context` | Denial of Service (jsonb/GIN bloat) | D-ATTR02-6 local ≤100-item cap + `truncated` marker + `Jason.encode!` ≤8KB guard now; uniform write-time bound deferred to SEC-01/Phase-53. |
| Host telemetry handler raising inside the caller | Denial of Service | Emit wrapped `try/rescue → :ok` (D-R6); `:telemetry.execute` runs handlers synchronously in the caller. |
| Deny-listed secret named as a host dimension | Information Disclosure | Existing `Redactor` key-based recursion redacts `token`/`secret`/`password`/`api_key` values (documented behavior, Pitfall 3). |

## Sources

### Primary (HIGH confidence)
- Live codebase (re-verified this session): `lib/scoria/observe/telemetry.ex:60-72`, `buffer.ex:23,58-61,101-169`, `semconv.ex`, `span_kind.ex:24,29,32,83`, `redactor.ex:32-46`, `adapters/req_llm.ex:14-53`, `adapters/jido.ex`, `knowledge.ex:215-257,371-385`, `knowledge/embedder.ex`, `knowledge/retrieval_run.ex:20,42`, `scoria_web/components/trace_tree_component.ex`, `test/scoria/knowledge/retrieval_test.exs:47-72`, `test/scoria/observe/semconv_test.exs`, `mix.exs`, `lib/mix/tasks/scoria.test.knowledge.ex`, `assets/css/04-components.css:1087` — [VERIFIED: codebase grep].
- `deps/req_llm/lib/req_llm/telemetry.ex:485-514` (`request_metadata/2` fixed base map) + `.../telemetry/request_options.ex:19-42` (closed `gen_ai.request.*` allow-list) + `.../open_telemetry/attributes.ex:211,221` (`usage(nil) -> %{}`, `gen_ai.usage.input_tokens`) — the D-ATTR01-7 evidence, req_llm 1.13.0 locked (`mix.lock:50`) — [VERIFIED: deps source].
- `.planning/phases/52-retriever-span-host-declared-attributes/52-CONTEXT.md` — the locked spec — [CITED].
- `.planning/REQUIREMENTS.md` (RETR-01/02, ATTR-01/02; `:74` archetype/intent out of scope), `.planning/ROADMAP.md` §Phase 52/53, `.planning/phases/51-*/51-CONTEXT.md` — [CITED].

### Secondary (MEDIUM confidence)
- None required — all claims were confirmable against the live tree or deps source.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all reused modules verified present.
- Verification of locked claims: HIGH — all 12 code anchors re-checked at file:line, zero material drift (three off-by-≤2 line citations noted).
- D-ATTR01-7 resolution: HIGH — the impossibility of req_llm forwarding is directly verified in deps source; the recommended `emit_prompt_span/1` reuses a proven seam.
- Validation architecture: HIGH — mirrors the shipped Phase-51 drift-guard discipline; test lanes verified to exist.
- Pitfalls: HIGH — each traced to a verified code location.

**Research date:** 2026-07-12
**Valid until:** 2026-08-11 (stable — internal convention over a locked dep; re-verify only if `req_llm` bumps past 1.13 or the Phase-51 `Buffer`/`Telemetry`/`SpanKind` seams change).

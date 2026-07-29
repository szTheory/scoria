# Pitfalls Research — v3.6 Trace Foundation (SEED-007)

**Domain:** Adding OTel-GenAI / OpenInference trace-span conventions to an existing, shipped, embedded Phoenix/Elixir AI-governance library (Hex `0.1.3` live, pre-1.0, real adopters)
**Milestone:** v3.6 Trace Foundation
**Researched:** 2026-07-11
**Confidence:** HIGH for pitfalls grounded in direct code inspection (cited file:line); MEDIUM for OTel-GenAI semconv stability claims (based on documented semconv versioning history, not a live fetch of the current spec page)

**Method note:** every pitfall below is grounded against the actual current implementation — `lib/scoria/observe/**`, `lib/scoria/repo/span.ex`, `lib/scoria/repo/span_event.ex`, `lib/scoria_web/components/{workflow_tree,trace_tree}_component.ex`, `lib/scoria/{adopter_doc_contract,ai_doc_contract}.ex`, `README.md`, `guides/reference/glossary.md`, `guides/scoria-vs-external-llm-ops.md` — not generic OTel advice. Two upstream facts assumed at MEDIUM confidence and flagged where used: (a) OTel GenAI semantic conventions are marked "Development"/experimental and have had breaking key renames across releases (e.g. `gen_ai.usage.prompt_tokens` → `gen_ai.usage.input_tokens`); (b) OpenInference (Arize) uses a parallel but not identical attribute vocabulary (`openinference.span.kind`, `llm.*`, `input.value`/`output.value`) rather than being a strict subset of OTel GenAI. Verify the exact current key names against the pinned spec version at build time — do not trust this document's key names as a spec fetch.

---

## Critical Pitfalls

### Pitfall 1: Convention-vs-Columns Churn (semconv becomes typed schema)

**What goes wrong:**
Under implementation pressure ("just add a column, it's cleaner to query"), someone adds typed Ecto/Postgres columns for `gen_ai_request_model`, `gen_ai_request_temperature`, `openinference_span_kind`, etc. on `ai_spans`, instead of writing conventionally-named keys into the existing `attributes` jsonb map. Once one column ships, the pattern compounds — every new semconv field becomes "just one more migration" — and pre-1.0 Scoria accumulates a migration per attribute, which is exactly the churn the seed was planted to prevent (SEED-007 "Scope Estimate": *"rigid columns invite migration churn pre-1.0; conventional key names are free portability"*).

**Why it happens:**
Typed columns feel more "correct" to engineers used to relational modeling, are easier to `WHERE` on without `->>'key'` operators, and every semconv version bump (see Pitfall 2) creates pressure to "just add the new column too" rather than touch the (harder to reason about) jsonb blob. The existing schema already primed this: `Scoria.Repo.Span` (`lib/scoria/repo/span.ex:7-14`) has exactly one untyped `attributes :map` field alongside typed `name`/`span_kind`/`status_code`/timestamps — the temptation is to keep promoting attributes into that typed-column pattern one field at a time.

**How to avoid:**
- Hard rule for this milestone: the only new typed columns allowed are ones already decided by the seed as **non-convention data** — i.e. `ai_retrieval_runs`'s `embedding_model`/`index_version`/`reranker` fields (explicitly scoped as typed columns on the *system-of-record* table, not on `ai_spans`). Every OTel-GenAI/OpenInference key (`gen_ai.request.*`, `gen_ai.usage.*`, `openinference.span.kind`, host-declared `feature`/`route`/`archetype`/`intent`, context-pack composition keys) goes into `attributes` as a string key, full stop.
- Add a **queryability seam** instead of columns: a GIN index on `ai_spans.attributes` (`CREATE INDEX ... USING gin (attributes)`) plus one or two helper query functions (`Scoria.Observe.SpanQuery.by_attribute/3` using `attributes @> %{...}` or `attributes ->> 'gen_ai.request.model'`) so "queryability" is solved without schema churn. This gives the "it's cleaner to query" objection a real answer that isn't a migration.
- Codify the internal mapping-seam module (see Pitfall 2) as the single place semconv key strings are defined — reviewers can grep one module, not the schema, to see what's conventional.
- Add a lightweight contract test that fails the build if a new migration adds a column to `ai_spans` whose name looks like a semconv key (heuristic: matches `gen_ai_*` / `openinference_*` pattern) — cheap, mechanical, catches the drift before merge rather than in review.

**Warning signs:**
- A PR diff includes a migration touching `ai_spans` or `ai_span_events` for anything other than the already-agreed `RETRIEVER`-span linkage.
- Code review comments like "can we just add a column for this, it'd be faster to query."
- `Scoria.Repo.Span.changeset/2`'s `cast/3` allowlist (`lib/scoria/repo/span.ex:22-35`) grows new field names beyond the existing 8.

**Prevention owner (build step):** the key-convention build step (SEED-007 item 1) — this is where the discipline must be established as the very first commit, before model-config capture or structured-span-emission steps exist to imitate a bad pattern.

---

### Pitfall 2: Baking In a Soon-Stale Experimental Semconv Key Set

**What goes wrong:**
OTel GenAI semantic conventions are explicitly marked experimental/development-stability upstream and have already undergone breaking renames in their short history (e.g., `gen_ai.usage.prompt_tokens`/`completion_tokens` → `gen_ai.usage.input_tokens`/`output_tokens`). If Scoria hardcodes today's key names directly at every call site (`req_llm.ex`, future `guardrail`/`retrieval` emitters, the UI components that read attributes), a future semconv rename means (a) grep-and-replace across N call sites, (b) a silent split where old rows use old keys and new rows use new keys with no way to query across both, and (c) the "portability" claim becomes a liability — an adopter's external OTel backend expects the *current* upstream key name, not whatever Scoria pinned a year ago.
Concretely, Scoria's *current* (pre-this-milestone) code already uses ad hoc non-conventional keys — `"llm.model_name"`, `"llm.token_count"`, `"req.url"` (`lib/scoria/observe/adapters/req_llm.ex:17-21`) — so this milestone is itself already doing a one-time rename of every existing key. Get the target vocabulary wrong or unpinned and it repeats.

**Why it happens:**
Engineers copy key names straight out of whatever OTel-GenAI/OpenInference doc page they're reading in the moment, with no version pin recorded anywhere in the codebase, so "what version of the convention are we implementing" becomes an oral-tradition fact instead of a checked-in one.

**How to avoid:**
- Pin a specific semconv version in a comment/moduledoc at the point of definition (e.g., `# Pinned to OTel GenAI semconv v1.x as of 2026-07 — do not silently follow upstream renames`) and record the pin + stability caveat in the trace-foundation doc-delta this milestone ships (per the seed's "Feature-specific OpenInference-compatible trace docs ship as a doc-delta inside this milestone").
- Centralize every semconv key string behind one internal mapping module — e.g. `Scoria.Observe.Semconv` exposing `Semconv.request_model/0 -> "gen_ai.request.model"`, `Semconv.usage_input_tokens/0`, etc. — so a future rename is a one-module diff, not a grep-and-replace across adapters, UI, and docs. This is the "internal mapping seam" the question calls for.
- ReqLLM (the actual upstream dependency this milestone threads model config from) already normalizes on `input_tokens`/`output_tokens` (`deps/req_llm/lib/req_llm/response.ex:269`, `generation.ex:64`) — i.e., the *already-current* OTel-GenAI naming, not the deprecated `prompt_tokens`/`completion_tokens`. Confirm this alignment explicitly in the mapping module rather than assuming it; don't re-derive the old names from a stale blog post or example.
- Do not claim "OTel-GenAI compliant" in docs (see Pitfall 6) — claim "OTel-GenAI-*inspired* naming, pinned to version X, not a guaranteed-stable export contract" so an upstream rename is a documented future migration, not a broken promise.
- Consider building the mapping module *on top of* the official `opentelemetry_semantic_conventions` Hex package (published attribute-name constants, currently versioned e.g. `v1.27.0` on HexDocs, covering `gen_ai.*`) rather than hand-transcribing key strings from a doc page — it exists specifically to solve this problem, ships versioned, and confirms the current stable-attribute set is opt-in gated upstream (`OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental` — OTel itself defaults new instrumentations to the *old* attribute format until an app opts into the latest experimental set, which is direct upstream confirmation this vocabulary is still actively transitioning). Even if not taken as a runtime dependency, its source is a better version-pinned reference than ad hoc doc scraping.

**Warning signs:**
- Any semconv key string literal appears in more than one file (`req_llm.ex` AND a UI component AND a test) instead of coming from one shared module/constant.
- No comment anywhere states which semconv version/date the key names were pinned against.
- A future PR needs to touch 5+ files to rename one attribute key.

**Prevention owner (build step):** the key-convention build step (SEED-007 item 1) creates the mapping module; every subsequent build step (model-config capture, structured span/event emission, retrieval span) must import keys from it rather than inlining strings.

---

### Pitfall 3: Breaking the 2 Existing Adapters / UI Span-Kind Rendering

**What goes wrong:**
Both live span-kind consumers hardcode their own **independent, slightly different** whitelist and silently default anything unrecognized to `"agent"`:
- `ScoriaWeb.WorkflowTreeComponent.span_kind/1` (`lib/scoria_web/components/workflow_tree_component.ex:38-44`): whitelist is `llm tool prompt mcp retriever guardrail eval agent` (8 kinds), plus ad hoc remaps (`"approval" -> "guardrail"`, `"handoff" -> "agent"`, `"answer" -> "llm"`).
- `ScoriaWeb.TraceTreeComponent.span_kind/1` (`lib/scoria_web/components/trace_tree_component.ex:86-95`): whitelist is `agent llm prompt tool mcp retriever guardrail eval error` (9 kinds — includes `"error"`, which the other list doesn't) and case-normalizes via `String.downcase/1` before matching.

Both emitters today only ever send `"LLM"` (`req_llm.ex:28`) or `"INTERNAL"` (`jido.ex:28`) — `"INTERNAL"` isn't in *either* whitelist, so every non-LLM span already silently renders as generic `"agent"` styling today. If this milestone starts emitting the real taxonomy (`RETRIEVER`, `TOOL`, `PROMPT`, `GUARDRAIL`, `EVAL`) but a new kind is spelled differently than either hardcoded list expects (case, singular/plural, or a kind not yet added to both lists), spans silently fall back to the generic "agent" rail color instead of erroring — a **silent UI regression**, not a crash, so it can ship unnoticed. Existing tests hardcode the old values too (`trace_tree_component_test.exs:55` asserts `span_kind: "LLM"`), so span-kind changes can pass CI while still being wrong for the new taxonomy if the test fixtures aren't updated in lockstep.

**Why it happens:**
The two whitelists evolved independently (different components, different authors/phases) and there is no single source-of-truth list — extending the taxonomy means remembering to touch both files (and their remap tables) at once, with no compiler or test forcing that.

**How to avoid:**
- Before emitting any new `span_kind` value, **first** extract a single shared whitelist/constant (e.g. `ScoriaWeb.UI.span_kinds/0` or a `Scoria.Observe.SpanKind` module) and make both `workflow_tree_component.ex` and `trace_tree_component.ex` delegate to it instead of hardcoding their own lists. This is cheap now (2 call sites) and expensive to retrofit later.
- Emit span_kind values as UPPERCASE OTel/OpenInference-style constants at write time (`"LLM"`, `"RETRIEVER"`, `"TOOL"`, `"GUARDRAIL"`, `"PROMPT"`, `"EVAL"`) and keep the existing downcase-then-match UI logic — but make the canonical list explicit and shared so the mapping from write-side constant to UI-side lowercase key is one function, not two independently maintained lists.
- Add a **drift guard test**: assert (via source scan or shared-constant equality, not string duplication) that every `span_kind` value the adapters can emit exists in the shared whitelist consumed by both UI components — fails loudly (test failure) instead of failing silently (generic gray "agent" rail).
- Update `trace_tree_component_test.exs` and any other hardcoded-`"LLM"`/`"INTERNAL"` fixtures as part of the *same* PR that changes what adapters emit, not a follow-up.
- Keep `"INTERNAL"` (or an equivalent generic/uncategorized bucket) as an explicit, intentional catch-all kind rather than relying on the implicit "anything unmatched becomes agent" default — an explicit bucket is auditable; a silent fallback is not.

**Warning signs:**
- A code review touches `req_llm.ex` or `jido.ex`'s `span_kind:` value but doesn't touch both `workflow_tree_component.ex` and `trace_tree_component.ex` in the same diff.
- `mix test` stays green after a span_kind rename (it will, today — nothing currently asserts the two whitelists match), which is itself the warning sign: absence of a failing test here is the risk.
- Dashboard screenshots after the change show unexpectedly many spans rendered in the generic "agent" gray rail color.

**Prevention owner (build step):** the key-convention build step (SEED-007 item 1, "populate span_kind correctly") — extract the shared whitelist *before* changing what gets emitted; the structured span/event emission step (item 3) is the next-highest-risk point since it introduces the most new kind values at once.

---

### Pitfall 4: PII / Cardinality in Attributes

**What goes wrong:**
Two distinct risks compound once host-declared and context-pack attributes land in the same `attributes` map as model config:
1. **PII leakage.** `Scoria.Observe.Redactor` (`lib/scoria/observe/redactor.ex:6,27-30`) is a **flat key-name deny-list** (`password`, `api_key`, `token`, `secret` + host-configured additions) applied recursively over map *keys*. It has no concept of semconv keys or of PII *inside a value* — e.g. a `gen_ai.prompt.0.content` or `gen_ai.completion.0.content` value containing a user's email, name, or free-text PII sails straight through, because the key itself (`"gen_ai.prompt.0.content"`) isn't on the deny-list, only the *value* is sensitive. `scrub_text/1` only regex-matches `key=value` patterns inside free text (built for streaming chunks, `telemetry.ex:54-56`), not prose PII embedded in a rendered prompt/response body.
2. **Cardinality bloat.** Host-declared `feature`/`route`/`archetype`/`intent` plus context-pack composition (chunk ids, memory ids, token splits) are exactly the kind of high-cardinality, high-volume fields that blow up jsonb row size and make per-span storage/index cost balloon at scale — especially once every LLM/prompt/retrieval span on every request carries a growing attributes map with no size cap. `Scoria.Observe.Buffer.flush_spans/1` (`buffer.ex:64-80`) does a raw `Repo.insert_all(Scoria.Repo.Span, entries)` with no attribute-size validation or truncation today.

**Why it happens:**
The redaction system was built for a narrower threat model (secrets/credentials by key name) before this milestone's plan to route full prompt/completion content and host-declared free-text identifiers through the same pipeline. Nobody re-derived the threat model when the attribute surface grew.

**How to avoid:**
- **Do not put raw rendered prompt/completion text into `attributes` by default.** If Scoria captures prompt content at all (the seed's context-pack item wants "which chunks/memories/token split", not full text), keep it to IDs and counts (`retrieved_doc_ids`, `context_chunk_ids`, `token_split: {system: N, context: N, user: N}`) rather than raw text — this is both a PII mitigation and a cardinality mitigation simultaneously, and matches P5 (host's own Postgres, not a text warehouse).
- If any free-text value must be captured (e.g., for guardrail-triggered events), route it through `Redactor.scrub_text/1`-style content scanning, not just key-name matching — or make it explicit that redaction is **key-based only** and document that hosts must not put PII-bearing values into attribute *values*, only into pre-approved key slots (the P5/host-declares-attributes doctrine already implies the host, not Scoria, owns what goes into `intent`/`route` values — make the redaction contract for those values equally explicit: host is responsible for not putting raw PII into declared attribute values).
- Cap `attributes` map depth/size at write time (e.g., reject or truncate individual string values over N chars, cap total key count) inside `Buffer`/`Telemetry` before insert, with a `Logger.warning` when truncation happens — cheap guard against unbounded growth from a misbehaving host declaration.
- Add a GIN index (Pitfall 1) sized and tested against a *realistic* attribute cardinality (e.g., an integration test that inserts spans with the full expected key set including context-pack composition keys) rather than only against today's 3-key stub — cardinality problems are invisible until tested at realistic shape.
- Extend the existing `test/scoria/observe/*` redaction tests to assert host-declared attribute keys (`feature`, `route`, `archetype`, `intent`) and context-pack keys pass through the *same* redaction path spans already go through — don't let events (Pitfall 5) or the new attribute keys bypass `Telemetry.handle_event/4`'s `Redactor.redact/1` call.

**Warning signs:**
- Any adapter or new emitter builds an `attributes` map value from a raw ReqLLM prompt/message/completion string rather than an ID/summary.
- No test asserts that host-declared `intent`/`route`/`archetype` values pass through `Redactor.redact/1` before persistence.
- No upper bound exists on `attributes` map size/string length anywhere in `Buffer`/`Telemetry`.

**Prevention owner (build step):** the host-declared-attribute-convention build step (SEED-007 "Host-declared attribute convention" item, from the AI-Architecture-Patterns cross-ref) and the context-pack composition item — both must define the redaction/cardinality contract *before* any host-facing documentation tells adopters what's safe to put in `intent`/`route`/`feature` values.

---

### Pitfall 5: Dead-Schema Resurrection Footguns (`ai_span_events`)

**What goes wrong:**
`ai_span_events` is not a *new* table — it already exists in the shipped migration (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, present in every already-installed adopter DB since `0.1.0`) and has a live Ecto schema (`Scoria.Repo.SpanEvent`, `lib/scoria/repo/span_event.ex`) — it has simply never been written to. So the migration-on-a-live-adopter-DB risk is **lower than the seed's framing implies** (no `ALTER TABLE`/backfill needed, just new INSERTs into an already-empty table) — but two real risks remain:
1. **The redaction/ingest pipeline only understands spans today.** `Scoria.Observe.Telemetry.handle_event/4` (`telemetry.ex:40-46`) and `Scoria.Observe.Buffer` (`buffer.ex:14-16,36-43,64-80`) are span-shaped end to end — one telemetry event name family (`[:scoria, :observe, :span, :stop|:delta]`), one buffer list, one `insert_all(Scoria.Repo.Span, ...)`. Writing to `ai_span_events` means adding a parallel event-shaped path (new telemetry event name, new buffer list or batching, new `insert_all(Scoria.Repo.SpanEvent, ...)`) — and if that new path is built as a quick bolt-on that calls `Repo.insert_all` directly without routing through `Redactor.redact/1` first (easy mistake: the redaction call is currently embedded in `Telemetry.handle_event/4`, not in `Buffer`, so a new event-ingest path that skips `Telemetry` and calls `Buffer`/`Repo` directly would skip redaction entirely), events ship unredacted while spans stay redacted — a silent, inconsistent privacy regression.
2. **Over-stuffing the whole vocabulary into `span_events`.** The seed is explicit that this is a worse model than every peer (OTel-GenAI/OpenInference model `tool`/`prompt`/`retrieval`/`guardrail` as span *kinds*, not events) — the temptation to treat "resurrect ai_span_events" as license to route everything through it (because it already has a stable table + minimal existing usage, so it's the path of least resistance) must be actively resisted. Only true point-in-time events belong there: `prompt_rendered`, `guardrail_triggered`, `user_feedback_received` — anything with meaningful duration or child structure is a span.

**How to avoid:**
- Confirm via `mix ecto.migrations` / a fresh-install smoke that no new migration is needed for the table itself (already true per the shipped migration file) — but *do* add a migration for the GIN index on `ai_span_events.attributes` if events start getting queried, since that's new.
- Build the event-ingest path as an explicit parallel branch of `Telemetry.handle_event/4` (a new `[:scoria, :observe, :event, :emit]` telemetry event, redacted via the *same* `Redactor.redact/1` call already used for spans) rather than a shortcut that calls `Buffer`/`Repo.insert_all(SpanEvent, ...)` directly — reuse the exact call site pattern spans already use so redaction can't be structurally skipped.
- Write a name-allowlist for events at the point of emission (`prompt_rendered | guardrail_triggered | user_feedback_received`) and reject/log anything else — a compile-time or runtime guard, not just a convention in a comment — so a future contributor reaching for "let's also add a `tool_invoked` event" is stopped by the code, not just documentation.
- Add an integration test proving `ai_span_events` inserts go through redaction (mirroring whatever test today proves `ai_spans` redaction, e.g. `test/scoria/observe/telemetry_test.exs`).

**Warning signs:**
- A PR adds a call to `Scoria.Repo.insert_all(Scoria.Repo.SpanEvent, ...)` or `Repo.insert(%SpanEvent{...})` anywhere outside the new dedicated event-ingest path.
- The set of event `name` values in code grows past the three named in the seed without an explicit new decision recorded.
- No test exercises redaction specifically for `ai_span_events` (only for `ai_spans`).

**Prevention owner (build step):** the structured span/event emission build step (SEED-007 item 3) — this is the step that resurrects the schema; its acceptance criteria should explicitly include "events pass through the same redaction call site as spans" and "only the 3 named event types are accepted."

---

### Pitfall 6: Portability False-Promise (claiming compatibility without matching it)

**What goes wrong:**
The README's original overclaim ("OpenInference-style trace capture") described in the seed **has already been partially walked back before this milestone starts** — current `README.md:313` reads "reviewer-visible trace capture and redaction inside your Phoenix app" (no OpenInference claim at all), and the project already ships explicit anti-overclaim language: `guides/reference/glossary.md:36` states *"Scoria does not claim an OpenInference-compatible export or trace substrate until that future work ships"*, and `guides/scoria-vs-external-llm-ops.md:77` states *"OpenInference export is not a current Scoria claim... belongs to the future trace-foundation seed."* This is good — but it creates a **specific, code-enforced trap for this milestone**: two drift-guard contract modules currently **ban** the exact phrase this milestone will eventually want to make true.
- `lib/scoria/adopter_doc_contract.ex:83-94` — `@comparison_deferred_not_current_claims` requires the phrase *"OpenInference export is not a current Scoria claim"* to appear, and `@comparison_forbidden_current_claims` explicitly **forbids** `"OpenInference export"` and `"OpenInference-compatible export"` from appearing anywhere in adopter docs.
- `lib/scoria/ai_doc_contract.ex:79-91` — `@forbidden_ai_doc_fragments` bans the literal string `"OpenInference export"` from `llms.txt`/`AGENTS.md`.

If this milestone ships real convention-adoption + updates the README to say "OpenInference-compatible" (per the seed's own item 5: *"flip to 'OpenInference-compatible' once (1) ships"*) **without updating these two contract files first**, the docs-contract test suite fails the build — or worse, if someone weakens/removes the guard under deadline pressure instead of correctly re-scoping it, the project loses the exact mechanism that caught the *original* overclaim, reopening the honesty gap this milestone is supposed to close.
The deeper risk beyond the contract-test mechanics: "OpenInference-compatible" is a testable claim, not a vibe. OpenInference and OTel-GenAI are *not identical* vocabularies (OpenInference uses `openinference.span.kind` + `llm.*`/`input.value`/`output.value`; OTel-GenAI uses `gen_ai.*`). Claiming "compatible" without picking *which* spec, at *which* version, and proving key-for-key conformance with an executable check is the same overclaim in new words.

**How to avoid:**
- Treat the doc-contract files as **part of the build surface for this milestone**, not an afterthought fixed at the end: when the key-convention build step lands, update `@comparison_deferred_not_current_claims`/`@comparison_forbidden_current_claims` (`adopter_doc_contract.ex`) and `@forbidden_ai_doc_fragments` (`ai_doc_contract.ex`) in the *same PR* — flip "OpenInference export is not a current Scoria claim" to a new, equally-specific, equally-tested honest claim string (e.g. "OpenInference-compatible span-kind and gen_ai.* attribute naming, verified by `mix scoria.trace_conformance`" — a claim that names a check, not just an adjective).
- Make the claim **testable**, not just re-worded: write an executable conformance check (a Mix task or ExUnit test) that asserts every span emitted by the two adapters uses only allow-listed OTel-GenAI/OpenInference key names and that `span_kind` values match the shared whitelist from Pitfall 3 — then the README/docs claim can cite that check by name, so "compatible" is falsifiable, not aspirational.
- Keep the claim scoped to what's actually true: attribute *naming* convention + `span_kind` taxonomy alignment is realistic; a full *export* pipeline (actually shipping spans to a Langfuse/Datadog/OTel collector in wire format) is explicitly out of scope per P5/P6 (host does the exporting) — so the honest claim is "portable naming, host-owned export," never "Scoria exports to X."
- Do not claim compatibility with a moving target without a version pin (ties to Pitfall 2) — "OpenInference-compatible" should name a spec version/date, exactly like the internal mapping module does.

**Warning signs:**
- `mix test` fails on `adopter_doc_contract_test.exs` / `ai_doc_contract_test.exs` after a docs PR that updates README claim language — this is actually a *good* warning sign (the guard working) but only if someone doesn't just delete the failing assertion to unblock CI.
- The new/flipped claim string contains no reference to a checkable artifact (test name, conformance task, version pin) — i.e., it reads like marketing copy instead of a testable statement.
- "OpenInference" and "OTel-GenAI" get used interchangeably in the same doc paragraph as if they were one spec.

**Prevention owner (build step):** the docs-accuracy build step (SEED-007 item 5) owns the *language* flip, but the *conformance check it can honestly point to* must be built alongside the key-convention step (item 1) — sequence the docs step to land only after (or in the same PR as) whichever build step gives it something true to cite. Do not let item 5 ship as a standalone doc-only change disconnected from a check.

---

### Pitfall 7: Replay Correctness (silently-broken replay from missing/partial model config)

**What goes wrong:**
Model config (temperature/top_p/seed/max_tokens) is captured **nowhere today** — confirmed: the current `req_llm.ex` adapter's `attributes` map (`req_llm.ex:16-22`) has exactly `llm.model_name`, `llm.token_count`, `req.url`, `tenant_id`, `workflow_run_id` — no temp/top_p/seed/max_tokens at all (the seed notes the only hardcoded value anywhere is `max_tokens: 2048` in `ui_critique.ex`, unrelated to the runtime adapter). Since Scoria's whole positioning is durable/replayable runs, replay today is **silently** non-deterministic for any temperature/top_p-sensitive call — nothing errors, nothing warns, the replayed output just quietly diverges from the original and nobody is told why. The specific new risk this milestone introduces: shipping **partial** capture (e.g., temperature but not seed, or model config on `LLM` spans but not on child `TOOL`/`PROMPT` spans that also have provider-call parameters) looks like "the feature is done" in a demo (temperature shows up in the trace UI!) while leaving replay just as broken as before for the un-captured fields — worse, it's now a *false confidence* problem: reviewers looking at the trace see "temperature: 0.7" and assume replay is faithful when seed/top_p are still silently missing.

**Why it happens:**
Model config params live in ReqLLM request options at call time, not in the response/telemetry metadata the adapter currently reads (`req_llm.ex:11-22` only touches `metadata`/`measurements` from the `[:req_llm, :request, :stop]` telemetry event) — threading them through means capturing *request* opts, not just response data, which is a different (and easy to half-do) code path than what exists today.

**How to avoid:**
- Treat "model config capture" as one atomic unit covering **all four params** (temp/top_p/seed/max_tokens) plus any provider-specific params ReqLLM exposes that affect determinism (e.g. `frequency_penalty`, `presence_penalty` if used) — ship all-or-nothing rather than incrementally, specifically to avoid the false-confidence half-done state.
- Explicitly test the **absence** case: when a param wasn't supplied by the caller (e.g. no `seed` set — many providers don't support one), the span attribute should be *omittable/nullable* with a clear "not captured/not supported" distinction from "captured as null," not silently absent in a way indistinguishable from a bug. This matters for replay tooling deciding whether it can trust the trace.
- If replay functionality (`v1.9 Crucible`'s replay-from-checkpoint feature) reads span attributes to reconstruct a call, add/update an integration test that replay-with-captured-model-config actually reproduces bit-identical (or documented-tolerance) provider call params — don't just test that the attribute exists in the trace, test that the *consumer* (replay) can use it.
- Document in the trace-foundation doc-delta exactly which params are captured and which provider/params combinations still can't be replayed deterministically (e.g., providers with no seed support) — an honest "replay fidelity" statement, not a blanket "replay works now" claim (ties to Pitfall 6's testable-claims discipline).

**Warning signs:**
- A PR adds `temperature`/`top_p` to the attributes map but not `seed`/`max_tokens` (or vice versa), and ships as "model config capture done."
- No test exercises the replay path consuming the newly-captured model-config attributes end-to-end.
- Trace UI displays a model-config field with no visual distinction between "provider doesn't support this param" and "we didn't capture it."

**Prevention owner (build step):** the model-config-capture build step (SEED-007 item 2) — own the all-four-params-together decision explicitly in that step's acceptance criteria, and cross-check against the replay feature's actual read path before declaring done.

---

### Pitfall 8: Dual-Write Divergence (RETRIEVER span vs `ai_retrieval_runs`)

**What goes wrong:**
The seed deliberately keeps `ai_retrieval_runs` as system-of-record (richer than a generic span: grounding scores, typed results) while *also* emitting a linked `RETRIEVER` span for trace-tree visibility — a dual-write by design. `Scoria.Knowledge.RetrievalRun`'s schema already has `trace_id`/`span_id` fields (`retrieval_run.ex:16-17,38-39`) — the FK-shaped linkage exists, but nothing populates or enforces it today (the seed: "plumbing exists, just unemitted"). Once both writes are live, they can silently drift out of sync:
- The `RETRIEVER` span gets written but the `trace_id`/`span_id` on the `ai_retrieval_runs` row is never set (or set inconsistently) — orphaning the span with no way to join back to the richer table, defeating the whole "dual-write for detail" design.
- The two writes happen at different times/in different transactions (span goes through the async `Buffer` batch-flush path; `ai_retrieval_runs` presumably writes synchronously inside the knowledge retrieval call) — a crash or partial failure between the two leaves one written and the other not, and there's no reconciliation job to detect/fix the gap.
- Summary fields that exist on *both* (e.g., `embedding_model`/`index_version`/`reranker` are being added to the span's config fields per the seed, while `ai_retrieval_runs` presumably already has or gains its own copies) can diverge in value if one write path gets updated and the other doesn't during a future change — e.g., someone bumps the index_version constant in the knowledge module but forgets the span-emission call site also needs it.

**Why it happens:**
`Buffer`'s span-insert path is async/batched (`buffer.ex:36-43,64-80` — cast → buffered list → flush on timer or `max_size`), while the retrieval-run write is very likely synchronous inside the knowledge call (`ai_retrieval_runs` is described as the system-of-record consulted for grounding checks that presumably gate the response). Two different write paths with two different consistency models, written by two different call sites, is exactly the shape that drifts.

**How to avoid:**
- Generate `trace_id`/`span_id` for the `RETRIEVER` span **at the point the retrieval call starts** (not after) and pass the same IDs into both the span-emission call and the `ai_retrieval_runs` insert/update — one ID-generation site, two consumers, not two independent ID generators that happen to agree today.
- Prefer writing `ai_retrieval_runs` (the source of truth) synchronously as today, and treat the `RETRIEVER` span as a *derived, best-effort* visibility artifact — if the async span-buffer flush fails (already logged-and-dropped on buffer-full per `buffer.ex:37-39`, or on insert exception per `flush_spans/1:75-80`), that's an acceptable, non-fatal loss of trace-tree visibility, **as long as it's asymmetric in the safe direction** (never let a dropped/failed span write roll back or block the `ai_retrieval_runs` write, and never let it silently corrupt the FK — if the span never gets written, `ai_retrieval_runs.span_id` should stay null/known-absent, not point at a phantom span).
- Add a maintainer-facing consistency check (a Mix task or a periodic dev-mode assertion, not necessarily a hard runtime constraint) that samples `ai_retrieval_runs` rows with non-null `trace_id`/`span_id` and confirms a matching `ai_spans` row exists with `span_kind = "RETRIEVER"` — cheap drift detector, catches the "orphaned FK" failure mode in dev/CI before an adopter notices missing spans in their trace tree.
- Keep config fields (`embedding_model`/`index_version`/`reranker`) sourced from **one function/module** that both the span-attribute builder and the `ai_retrieval_runs` changeset call, rather than two independent literals — the same "one source, two consumers" discipline as the ID generation, applied to values instead of identity.

**Warning signs:**
- `ai_retrieval_runs.trace_id`/`span_id` stay null in practice after this ships (grep production/dev data — if they're always null, the dual-write link was never wired, just the columns).
- A `RETRIEVER` span exists in `ai_spans` with no corresponding `ai_retrieval_runs` row reachable via its `trace_id`/`span_id` (orphan spans).
- `embedding_model`/`index_version` values differ between what a `RETRIEVER` span shows and what the corresponding `ai_retrieval_runs` row shows for the same retrieval call.

**Prevention owner (build step):** the retrieval-linked-span build step (SEED-007 item 4) — this step's acceptance criteria must include an explicit consistency test (span ⇄ retrieval-run join test), not just "a RETRIEVER span gets emitted."

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems in this specific migration.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Inline semconv key strings at each call site instead of a shared mapping module (Pitfall 2) | Faster first PR, no new module to design | Every future semconv rename becomes a multi-file grep-and-replace; risk of key-name typos diverging between adapters | Never for this milestone — the mapping module is cheap to build first |
| Route new attributes through `attributes` without an upper size/length cap (Pitfall 4) | Simpler `Buffer`/`Telemetry` code, no truncation logic to write | Unbounded jsonb growth once context-pack composition keys land; slow queries/bloated storage at scale | Only as an explicit, time-boxed MVP step with a tracked follow-up task — never as the permanent shape |
| Emit `RETRIEVER` span as fire-and-forget with no consistency check against `ai_retrieval_runs` (Pitfall 8) | One less test to write this milestone | Orphaned/drifted dual-write goes undetected until an adopter files a confusing bug report about "missing" retrieval spans | Acceptable only if a dev-mode consistency-check task ships in the *same* milestone, even if not CI-blocking |
| Leave `trace_tree_component.ex` and `workflow_tree_component.ex` with independent span-kind whitelists rather than extracting a shared one (Pitfall 3) | Zero refactor risk to two already-working, tested components | Every future taxonomy change (SEED-009/012/013 all read `span_kind`) must remember to touch both files; guaranteed eventual drift | Never — the extraction is small and this milestone is the natural moment (it's the one changing what gets emitted) |
| Ship the docs "OpenInference-compatible" claim flip without a corresponding conformance check (Pitfall 6) | Docs PR ships faster, satisfies the seed's literal wording | Recreates the exact overclaim problem this milestone exists to fix, just with different words | Never |

## Integration Gotchas

Mistakes specific to integrating with the ReqLLM peer dependency and OTel/OpenInference conventions.

| Integration | Common Mistake | Correct Approach |
|--------------|-----------------|--------------------|
| ReqLLM telemetry (`[:req_llm, :request, :stop]`) | Assuming `metadata`/`measurements` already contain request-time params (temp/top_p/seed) because that's all today's adapter reads | Thread request *opts* (not just response metadata) into the span — confirm exactly which ReqLLM telemetry fields expose call-time params vs. response-time usage (`deps/req_llm/lib/req_llm/telemetry.ex`) before assuming coverage |
| OTel GenAI semconv | Treating "GenAI semconv" and "OpenInference" as one vocabulary and mixing key styles (`gen_ai.request.model` next to `llm.model_name` in the same span) | Pick and document which spec each key family maps to (`gen_ai.*` = OTel-GenAI, `openinference.span.kind` = OpenInference's own top-level kind attribute) inside the mapping module (Pitfall 2) — don't invent a third hybrid dialect |
| Existing non-conventional keys (`llm.model_name`, `llm.token_count`, `req.url`) | Deleting the old keys outright the moment new conventional keys ship, breaking any host/adopter already querying `attributes["llm.model_name"]` directly against their own Postgres (a real risk per P5 — hosts are expected to query this) | Emit *both* old and new keys for one deprecation window (or at minimum: document the rename in CHANGELOG with the exact old→new key mapping) so P5's "reconstructable in host's own DB" promise doesn't silently break existing host queries |
| `ai_span_events` ingestion | Wiring event-insert directly from a new call site into `Repo`/`Buffer`, bypassing `Telemetry.handle_event/4`'s redaction call (Pitfall 5) | New event path must route through the same `Redactor.redact/1` call site pattern spans already use |

## Performance Traps

Patterns that work fine in dev/CI-scale tests but fail as attribute volume grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| No GIN index on `ai_spans.attributes`/`ai_span_events.attributes` while adding queryable convention keys | Trace/dashboard queries filtering by `attributes ->> 'gen_ai.request.model'` or host-declared `feature`/`route` do sequential scans | Add a GIN index migration as part of the key-convention build step, not deferred | Once trace volume exceeds a few thousand rows per tenant — small pre-1.0 adopters may not notice, but the seed explicitly targets this as the substrate for 008/010/012/013, all of which will query by these attributes |
| Unbounded `attributes` map growth from context-pack composition keys (chunk ids, memory ids, per-request) | `ai_spans` row/jsonb size grows with every prompt span; `Buffer.flush_spans/1`'s batch insert gets slower | Cap attribute value sizes/counts at write time (Pitfall 4); consider storing chunk/memory ID *lists* capped at N with a "+K more" summary rather than the full set | At moderate-to-high request volume with RAG-heavy workloads (many chunks per prompt) |
| `Buffer`'s in-memory list (`max_size: 1000` default, `buffer.ex:5,37-39`) now also needs to hold heavier attribute maps per span | Buffer fills faster (in span *count*, but each span now carries more bytes), more frequent `"Buffer is full, dropping span"` warnings, meaning silently dropped spans under load | Re-validate the default `max_size`/`flush_interval` against realistic post-milestone attribute payload sizes, not the pre-milestone (3-key) baseline | Under bursty high-traffic workflows once model-config + host-declared + context-pack attributes are all landing on every span |

## Security Mistakes

Domain-specific issues beyond general web security — see Pitfall 4 for the full PII analysis.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating key-name-based redaction (`Redactor`'s deny-list) as sufficient for full-text prompt/completion content | PII embedded in prompt/response *values* (not keys) leaks to `/scoria` dashboard viewers and any host-side export | Keep raw text out of `attributes` by default (IDs/counts only); document the redaction model's actual scope (key-based) so hosts don't assume value-level scrubbing exists |
| Host-declared `intent`/`route`/`feature`/`archetype` values treated as inherently safe because "the host declared them" | A host could (accidentally) put a customer's raw ticket text into `intent` (the seed's own example is `"intent": "billing_duplicate_charge"` — a category, but nothing stops a host from putting something worse there) | Document the P5-adjacent expectation explicitly: Scoria never infers these values (correct, per doctrine), but Scoria *should* still redact them through the same key-deny-list path as everything else — "host declares" is not "host is exempt from redaction" |
| Events (`ai_span_events`) shipping without redaction because the event-ingest path is newly built and bypasses the span redaction call site | A `prompt_rendered` event (literally the rendered prompt) or `guardrail_triggered` event (may include the triggering content) leaks unredacted content through a schema that's easy to overlook because it's "new" | Route events through the identical `Redactor.redact/1` call as spans (Pitfall 5); add a dedicated redaction test for events |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|--------------|-------------------|
| Trace UI silently renders unrecognized `span_kind` values as generic "agent" gray (Pitfall 3) | Reviewer can't tell a genuinely-agent span from a taxonomy-mismatch bug — loses trust in the trace tree as "evidence" | Make unmatched kinds visually distinct (e.g., a dashed/warning-tone rail) rather than indistinguishable from real `agent` spans, or fail loudly in dev/test builds |
| Model-config fields shown in the trace UI with no distinction between "not captured" and "provider doesn't support this param" (Pitfall 7) | Reviewer assumes replay fidelity that doesn't exist | Explicit UI states: captured value / "not supported by provider" / "not captured (pre-upgrade trace)" — three states, not a blank field for all three |
| `RETRIEVER` span shown in trace tree with no link to the richer `ai_retrieval_runs` detail (Pitfall 8, if the linkage silently fails) | Reviewer clicks a retrieval span expecting grounding scores/typed results and finds nothing, undermining the "richer system-of-record" design intent | Trace UI's retrieval-span detail view should explicitly fall back to "linked retrieval detail unavailable" rather than a blank/broken panel when the FK join comes up empty, so the gap is visible not silent |

## "Looks Done But Isn't" Checklist

- [ ] **Key convention adopted:** Often missing — the shared internal mapping module (Pitfall 2) actually being *used* everywhere vs. some call sites still inlining string literals. Verify: grep for raw `"gen_ai.` / `"openinference.` string literals outside the mapping module.
- [ ] **`span_kind` taxonomy populated:** Often missing — both `workflow_tree_component.ex` and `trace_tree_component.ex` whitelists updated together (Pitfall 3), and old test fixtures (`trace_tree_component_test.exs:55`) updated too. Verify: search test suite for hardcoded `"LLM"`/`"INTERNAL"` literals that should now be exercising the fuller taxonomy.
- [ ] **Model config capture:** Often missing seed/top_p even when temperature/max_tokens are captured (Pitfall 7) — a half-done capture that looks complete in a demo. Verify: check all four params are present together on a real LLM span, not just the two easiest to thread.
- [ ] **`ai_span_events` redaction:** Often missing — event path built as a shortcut around `Telemetry.handle_event/4`'s redaction call (Pitfall 5). Verify: an integration test asserting a deny-listed key in an event's attributes gets `[REDACTED]`, mirroring the existing span redaction test.
- [ ] **RETRIEVER span ⇄ `ai_retrieval_runs` linkage:** Often missing in practice even when both writes individually "work" (Pitfall 8) — `trace_id`/`span_id` columns populated but never actually joined/tested. Verify: an integration test that starts a retrieval, then joins `ai_spans` to `ai_retrieval_runs` by the shared IDs and asserts both rows exist and agree on `embedding_model`/`index_version`.
- [ ] **Docs claim + drift guard updated together:** Often missing — README/glossary language updated but `adopter_doc_contract.ex`/`ai_doc_contract.ex` banned-phrase lists left stale (Pitfall 6), either failing CI or (worse) getting weakened under pressure. Verify: `mix test` green on both contract test files with the *new* claim string asserted present and the *old* "not a current claim" string removed/updated intentionally, not accidentally.
- [ ] **Backward read-compat for already-persisted attribute keys:** Often missing — old rows with `llm.model_name` etc. become unreadable by any new-key-only UI/query code (see Integration Gotchas). Verify: seed a test DB with a pre-migration-shaped `ai_spans` row and confirm the trace UI still renders something sensible for it, not a blank/crash.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|-------------------|
| Typed columns added to `ai_spans` for semconv fields (Pitfall 1) | MEDIUM | Add a migration dropping the column, backfill the value into `attributes` via a data migration, update any code that read the column directly; cheaper the earlier it's caught (pre-1.0, but still real adopter data once installed) |
| Semconv key rename needed after initial ship (Pitfall 2) | LOW if the mapping module exists (one-module diff) / HIGH if keys are inlined everywhere | With the mapping module: update the constant, ship a doc-delta CHANGELOG note, optionally dual-emit old+new for a window. Without it: full grep-and-replace + retroactive dual-emit patch across every call site |
| Span-kind whitelist drift causes spans to silently render as "agent" (Pitfall 3) | LOW | Extract the shared whitelist retroactively, backfill/re-render is not needed (rendering is computed at read time from stored `span_kind`, not baked in) — just ship the fix and old spans immediately render correctly |
| Unredacted PII shipped via `ai_span_events` before the gap was caught (Pitfall 5) | HIGH | This is a real data-exposure incident for any adopter running with events enabled — requires: emergency patch to route events through redaction, a data audit/purge task for already-persisted unredacted event rows (host-owned data, so this needs an adopter-facing advisory + a Mix task to redact-in-place), and a postmortem-driven test addition |
| README/docs claim flipped without a conformance check backing it (Pitfall 6) | LOW-MEDIUM | Revert or soften the claim string, ship the missing conformance check, re-flip once it exists — cheap if caught before a Hex release, more visible (public credibility cost) if caught after |
| `ai_retrieval_runs` ⇄ `RETRIEVER` span drift discovered in production | MEDIUM | Write a one-off backfill script joining on request/time-window heuristics where the FK is missing (best-effort, not guaranteed 1:1), then ship the consistency-check task (Pitfall 8) going forward so it can't silently recur |

## Pitfall-to-Phase Mapping

How the eventual roadmap phases (mapped to SEED-007's 5 build items until REQUIREMENTS.md finalizes exact phase numbers) should own prevention.

| Pitfall | Prevention Owner (build step) | Verification |
|---------|-------------------------------|----------------|
| 1. Convention-vs-columns churn | Key-convention step (item 1) | No new typed columns on `ai_spans`/`ai_span_events` beyond agreed exceptions; GIN index + query-helper module shipped instead; contract/lint guard against semconv-shaped column names |
| 2. Experimental/unstable semconv | Key-convention step (item 1), consumed by every later step | Internal mapping module exists, is the sole source of semconv key strings, and cites a pinned spec version/date in its moduledoc |
| 3. Breaking the 2 adapters/UI | Key-convention step (item 1) extracts the shared whitelist before emission changes; structured span/event step (item 3) is highest-risk consumer | Shared `span_kind` whitelist used by both `workflow_tree_component.ex` and `trace_tree_component.ex`; drift-guard test asserts adapter-emittable kinds ⊆ shared whitelist; updated test fixtures |
| 4. PII/cardinality in attributes | Host-declared-attribute-convention item + context-pack item | No raw prompt/completion text in `attributes` by default; redaction test covers host-declared + context-pack keys; size/count caps enforced in `Buffer`/`Telemetry` |
| 5. Dead-schema resurrection footguns | Structured span/event emission step (item 3) | Events route through the same `Redactor.redact/1` call site as spans; name allowlist enforced (3 event types only); redaction integration test for events exists |
| 6. Portability false-promise | Docs-accuracy step (item 5), gated on key-convention step (item 1) producing a conformance check | `adopter_doc_contract.ex`/`ai_doc_contract.ex` updated in the same PR as any claim-language change; new claim string names a checkable artifact (test/task), not just an adjective |
| 7. Replay correctness | Model-config-capture step (item 2) | All four params (temp/top_p/seed/max_tokens) captured together, not incrementally; replay-path integration test consumes the captured config end-to-end; explicit "not captured/not supported" distinction documented |
| 8. Dual-write divergence | Retrieval-linked-span step (item 4) | Single ID-generation site feeds both `RETRIEVER` span and `ai_retrieval_runs` row; consistency-check task/test joins the two and asserts agreement; config fields (`embedding_model`/`index_version`/`reranker`) sourced from one shared function |

## Sources

- Direct code inspection (HIGH confidence, cited file:line throughout): `lib/scoria/repo/span.ex`, `lib/scoria/repo/span_event.ex`, `lib/scoria/observe/telemetry.ex`, `lib/scoria/observe/buffer.ex`, `lib/scoria/observe/redactor.ex`, `lib/scoria/observe/adapters/req_llm.ex`, `lib/scoria/observe/adapters/jido.ex`, `lib/scoria/knowledge/retrieval_run.ex`, `lib/scoria_web/components/workflow_tree_component.ex`, `lib/scoria_web/components/trace_tree_component.ex`, `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/ai_doc_contract.ex`, `README.md`, `guides/reference/glossary.md`, `guides/scoria-vs-external-llm-ops.md`, `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `deps/req_llm/lib/req_llm/response.ex`, `deps/req_llm/lib/req_llm/generation.ex`.
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — the seed itself, including "Disagreements with the memo" (dual-write-not-collapse decision) and the AI-Architecture-Patterns / Operator-UI North-Star cross-refs.
- `.planning/PROJECT.md` — scope doctrine P1-P6 (`## Constraints`), milestone history, and the v3.5-era terminology/README-accuracy work that already partially preempted the README overclaim this seed originally flagged.
- OTel GenAI semantic conventions stability/renaming history — confirmed via web search 2026-07-11: [Gen AI attribute registry](https://opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai/), [Semantic conventions for generative client AI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/), [opentelemetry_semantic_conventions v1.27.0 (HexDocs)](https://hexdocs.pm/opentelemetry_semantic_conventions/gen-ai.html). Current stable naming is `gen_ai.usage.input_tokens`/`output_tokens`; upstream confirms the vocabulary is still transitioning (`OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental` opt-in, v1.36 cited as a transition baseline where existing instrumentations default to the older attribute format) — MEDIUM-HIGH confidence on the transition/instability claim, exact historical `prompt_tokens`→`input_tokens` rename date not independently re-verified against changelog. OpenInference (Arize Phoenix) attribute vocabulary (`openinference.span.kind`, `llm.*`, `input.value`/`output.value`) — MEDIUM confidence, general domain knowledge, not re-fetched this session.

---
*Pitfalls research for: v3.6 Trace Foundation (SEED-007) — OTel-GenAI/OpenInference trace interop in an existing shipped embedded Elixir/Phoenix AI-governance library*
*Researched: 2026-07-11*

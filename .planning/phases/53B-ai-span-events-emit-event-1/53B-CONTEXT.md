# Phase 53b: `ai_span_events` + `emit_event/1` - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Resurrect the dead `ai_span_events` table via a **public, allow-listed `emit_event/1`** that routes point-events through the **identical `Redactor.redact/1` call site** spans use, give `Buffer` an **event list with an ordered flush (traces → spans → events)** structured so **an orphan event can never take down a batch of good spans**, and emit **`prompt_rendered` / `guardrail_triggered` from real call sites** during normal operation.

In scope (locked by `.planning/REQUIREMENTS.md`):
- **EVENT-02** — `emit_event/1` + `[:scoria, :observe, :event, :emit]` telemetry clause through the identical redaction path; `Buffer` event list + ordered flush; a 3-name **reserved point-event vocabulary** (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) that cannot silently grow — including via a raw `:telemetry.execute` on the public bus.
- **EVENT-03** — `prompt_rendered` and `guardrail_triggered` emitted from **real instrumentation call sites**. `user_feedback_received` is **reserved in the vocabulary but NOT emitted in v3.6** (its capture is SEED-011 flywheel work).

**This is the EVENT-02 + EVENT-03 half of the Phase 53 split.** Phase 53 (shipped) built the guardrail and prompt **spans** these events attach to, wired the pipeline into `Scoria.Application` (D-00a), and built + unit-tested `Bounds.enforce(_, :event)` — leaving it **activated here**. No requirement is split across the two phases.

**Out of scope:** operator UI for events (a fired `guardrail_triggered` lands in Postgres and no operator can see it in v3.6 — a deliberate, roadmapped gap, per Phase 53 D-08); `user_feedback_received` emission (SEED-011); any new span kinds or guardrail producers.

**Method (mirrors 51/52/53):** four parallel cross-aware research subagents (orphan isolation / Buffer flush / allow-list+redact / real call sites), each applying the full lens set (Elixir-Ecto-Phoenix idiom for a *library*, ecosystem lessons right/wrong/footguns, consumer-first API DX, SRE/security/architecture hats, project DNA in `prompts/`), then one adversarial red-team pass, every claim verified against real code. The red-team resolved four cross-area risks and caught one coherence break (D-05). **The orchestrator independently fact-checked and CORRECTED one hallucinated citation** — see D-00.

**Cross-cutting meta-principle (inherited):** *one public verb (`emit_event/1`), one closed vocabulary owned by `Semconv`, one shared redaction call site, one write-time `Bounds` choke point — structural guarantees proven by drift-guard tests; a deny-listed key cannot leak, and the vocabulary cannot widen without a red test failing.*

</domain>

<decisions>
## Implementation Decisions

### D-00 — Method integrity + one corrected citation (verified against real code)

- **D-00a — the FK-drop precedent that the research cited DOES NOT EXIST — cite the real one.** Research A and the red-team both cited a Phase 52 migration `20260712210000_drop_retrieval_run_trace_span_fk.exs` as the "house pattern" for dropping this FK. **It does not exist** — the migration list ends at `20260704235536` and nothing from 2026-07-12 is present. The FK-drop decision (D-01) is still correct, but the **real** in-repo precedents are: (1) `ai_spans.parent_id` is genuinely **FK-free by construction** (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:19` — `add :parent_id, :binary_id` with **no `references(...)`**, indexed at `:31`) — the exact "deliberately FK-free for out-of-order arrival" precedent; and (2) the Ecto `execute("ALTER TABLE … DROP CONSTRAINT IF EXISTS …")` pattern is already used in-repo at `priv/repo/migrations/20260519000000_converge_eval_persistence.exs:117,144` (dropping `ai_eval_runs_dataset_id_fkey` / `ai_scores_dataset_item_id_fkey` for the *same* async-arrival reason). **Planner/executor: cite these, not the phantom migration.**
- **D-00b — the differentiator, restated (and freshly re-validated).** `ai_span_events` is a Postgres table Scoria owns — **durable and unsampled** — unlike an OTel span event, which the SDK is licensed by spec to drop (`OTEL_SPAN_EVENT_COUNT_LIMIT = 128` + sampling). Research surfaced that **OTel is now deprecating the Span Events API entirely (2026), routing toward the Logs API** — direct external validation of this table's reason to exist, and of Phase 54's flag: *if Scoria ever adds an OTLP exporter, `guardrail_triggered` must NOT be exported as an OTel span event — export it as a log record or a separate signal.*

### D-01 — Orphan-event isolation: DROP the FK **and** flush events in a SEPARATE transaction (SC#4)

The tension is real and verified: `ai_span_events.span_id` is a **hard immediate FK** (`…015813:41` — `references(:ai_spans, on_delete: :delete_all, null: false)`), and `Buffer` flushes via `Ecto.Multi` + `insert_all` (`buffer.ex:123-129`), which **bypasses changesets** and **raises a raw `Postgrex.Error` 23503 on an FK violation, rolling back the whole ≤1000-row batch**. Events arrive out-of-order relative to spans (a span may not have flushed, or was dropped by Bounds / buffer-full).

- **D-01a — LOCK: do BOTH, because each defends a different failure class.**
  - **Drop the DB-level FK on `ai_span_events.span_id`** (new core-lane migration; `execute("ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey")`, following the D-00a pattern). Keep the column **`NOT NULL`** and its index. This removes the dominant raise class and makes an orphan **insertable** rather than fatal.
  - **Flush events in a transaction SEPARATE from spans** (D-02). This earns the SC's word *"never"* for spans: **any** event-insert failure — present or future — is structurally incapable of touching already-committed spans. Spans commit first; events are attempted second, independently.
- **D-01b — orphan fate: PERSIST DANGLING, durably. Never drop, never retry.** "Loses nothing" has **two** objects: the 50 spans **and** the event. Drop+log contradicts the durable-audit guarantee (D-00b); bounded-retry cannot converge when the span was *permanently* dropped and is an unbounded-memory DoS — the exact thing SC#4 guards. Persist-dangling is OPA's decision-log model: the decision record is durable, the span is a correlation handle, and the read side tolerates the miss with a `LEFT JOIN`. `span_id` stays **NOT NULL** (dangling, never null).
- **D-01c — the Ecto `belongs_to`/`has_many` associations STAY.** Dropping the DB constraint breaks no reader — verified: the only references to the association are `span.ex:17 has_many(:events, …)` (an Ecto association, not a DB FK) and the `SpanEvent.changeset` unit test; **there is no join on `ai_span_events` anywhere in `lib/`.** `SpanEvent.changeset`'s `validate_required([:span_id, :name, :time])` also stays (span_id is always present at real call sites) — but note it is **irrelevant to the flush path**, which uses `insert_all` and bypasses changesets. The real non-null guarantee is the **DB `NOT NULL`** columns + the handler seam (D-05).
- **D-01d — migration is Hex-lib-safe with no fixture refresh.** A new post-0.1.0 migration auto-surfaces via `Install.Surface.Migrations` structural-set drift (`mix scoria.install --check` remediation); Phase 53's Deferred note already established this posture. This is a **core-lane** migration (not dev-only).

### D-02 — Buffer event list + ordered flush (EVENT-02)

- **D-02a — a SEPARATE `events: []` list in Buffer state, with its OWN cap and its OWN failure counter.** Add `events`, `max_event_size` (default 1000), and `event_consecutive_failures` alongside the existing span fields. Events accumulate reversed (`[ev | events]`) like spans and restore via `Enum.reverse` at flush. **Rejected:** a tagged unified list (couples the caps, kills O(1) `length`) and a second GenServer (breaks the single-`flush_now` proof, doubles timers/supervision). Independent caps stop cross-signal head-of-line starvation. Buffer-full for events = drop newest + `Logger.warning`, parity with spans (`buffer.ex:49-51`).
- **D-02b — `do_flush` becomes two ordered phases.** Phase 1: the **existing** traces→spans `Ecto.Multi` (`buffer.ex:114-129`) — **unchanged**. Phase 2: a **separate** `Repo.insert_all(Scoria.Repo.SpanEvent, event_entries)` in its **own `try/rescue`**, run **regardless of Phase 1's outcome**. This preserves the required traces → spans → events ordering AND the D-01 isolation. **No single combined Multi** (that reintroduces the SC#4 violation). **No per-row savepoints** (hot-path cost, no SC — see D-05 for why they are unnecessary). Events get `Map.put_new_lazy(:id, …)` + `inserted_at`/`updated_at` like spans.
- **D-02c — `Buffer.cast_event/2`**, mirroring `cast_span/2`. Area C's telemetry handler calls it after redact + `Bounds.enforce(_, :event)`, having projected the metadata to the fixed key set `~w(span_id name time attributes)a`.
- **D-02d — `flush_now/1` stays byte-for-byte.** It already routes through `do_flush`, so the one synchronous test hook now proves **both** the ordered-flush test and the SC#4 orphan test. **Do not split it.**
- **D-02e — event flush-error surfacing reuses `surface_flush_error/*` parameterized by `signal: :span | :event`**, backed by the independent `event_consecutive_failures` counter (independent storm dedupe), emitting the same `[:scoria, :observe, :buffer, :flush_error]` with a `signal` dimension. Never crashes the GenServer (every arm returns a count); never loses good spans (they committed in Phase 1). `:raise` reraises on the **timer path only**; `terminate/2` never reraises (Phase 53 D-09i continuity).

### D-03 — `emit_event/1` + allow-list + raw-bus defense + identical redact (SC#1 + SC#2)

- **D-03a — `Scoria.Observe.emit_event/1`** (observe-domain audit fact; **NOT** top-level `Scoria`), beside `emit_retriever_span/1` / `emit_prompt_span/1` and mirroring `Guardrail.emit/1`'s `is_map` shape. Takes a **single map** `%{name: atom, span_id: binary, attributes: map, time: DateTime.t()}`. Returns `:ok | {:error, :unknown_event}`. **Never raises** (`try/rescue → :ok`, Phase 53 loud-but-non-fatal continuity).
  - **`:name` is an ATOM from the closed vocabulary** — drift-proof (`"prompt_rendered "` whitespace/case variants are non-members), pattern-matchable, cheap. **Never `String.to_atom` on inbound data** — membership check only (no atom-table exhaustion). The atom→string conversion for the DB `name` column happens **exactly once**, at the fixed-key projection into the buffer row.
  - `span_id` is **required** (the FK anchor). See D-05 for the nil-`span_id` guard.
- **D-03b — enforcement is defense-in-depth; the HANDLER is the boundary of record.** `emit_event/1` checks the name up front for a synchronous `{:error, :unknown_event}` + a clean bus (good caller DX). But SC#2's raw-`:telemetry.execute([:scoria, :observe, :event, :emit], …)` bypass is caught **only** in the new `handle_event([:scoria, :observe, :event, :emit], …)` clause — the choke point **every** path funnels through — which **re-checks** `Semconv.event_name?/1`. **Red-team CONFIRMED keeping both** (not redundant-and-dangerous, because there is exactly one source of truth): the anti-divergence guarantee is **neither point may inline its own name list — both call `Semconv.event_name?/1`**, and the SC#2 canary asserts **both** the direct-call path and the raw-bus path reject an unknown name.
- **D-03c — vocabulary lives in `Semconv`, closed and grep-guarded.** `@event_names ~w(prompt_rendered guardrail_triggered user_feedback_received)a` + `event_names/0` + `event_name?/1`, mirroring `@guardrail_names` (`semconv.ex:246-250`) and the D-15 anti-inline grep-guard discipline. **`user_feedback_received` is in the list but has NO emitter (D-04d).**
- **D-03d — the "identical `Redactor.redact/1` call site" is LITERAL.** Collapse the span + delta + event redaction into **ONE shared `defp redact(m), do: Redactor.redact(m)`** — literally a single `Redactor.redact(` token in the source, which all three handler clauses funnel through. This fulfills the Phase 53 code_context note ("53b collapses the two redact sites to one"). Order for events matches spans: `redact → Bounds.enforce(_, :event) → Buffer.cast_event`. `Redactor.redact/1` already recurses into nested `:attributes`, so a deny-listed key inside an event's attributes comes back `[REDACTED]`. Proven by an integration test (real `Telemetry.attach/1` + scoped Buffer + `flush_now` + real Postgres) **and** a source-scan drift guard asserting exactly one `Redactor.redact(` call site.
- **D-03e — rejection behavior: fail-closed + observable.** One shared `reject_event(name, source)` (used by both enforcement points): `[:scoria, :observe, :event, :rejected]` telemetry + a **once-per-name-per-node** `Logger.warning` via ETS `insert_new` (reuse the `reviewer_broadcast.ex` dedupe). Microcopy names the fix: *"edit `Semconv @event_names`"*. Never persisted.
- **D-03f — add `[:scoria, :observe, :event, :emit]` to `Telemetry.attach/1`'s `@events`** (`telemetry.ex:7-10`) — verified absent today; without it the handler never fires.

### D-04 — Real call-site emission (EVENT-03)

- **D-04a — `guardrail_triggered` emits INSIDE `Guardrail.emit/1`'s `do_emit`, after `emit_span(span)`** (`guardrail.ex:171`), where the minted `span.id` (`:163`) and the computed `decision` (`:137`) already coexist. All **five** call sites get it for free and none change (`runtime.ex:131,154`; `workflows/runtime.ex:417,434,452`); the whole `emit/1` is already `try/rescue → :ok`. **Condition: `decision not in [nil, "allow"]`** — the span already records an `allow` durably (no audit gap), so the *event* is reserved for the actual intervention ("it fired", per Phase 53 D-05c). ≤1 event per blocked/escalated step. **Rejected:** emitting at the 5 call sites (`emit/1` doesn't return the id; 5× duplication; a new gate silently forgets).
- **D-04b — `prompt_rendered` emits INLINE at `judge_runner.ex`'s `build_judge_prompt_span/3` — NO new public wrapper.** Red-team **KILLED** the proposed `Observe.with_prompt_render/3`: there is exactly one `lib/` producer (the judge; `Compaction.SummarizeWorker` has no `lib/` enqueuer, so it is not the production proof). Pre-mint a `span_id`, thread it via the **existing `opts[:span_id]` own-id opt** into `with_prompt/3`, and call `emit_event` **after** the wrapper returns. This keeps `span/4` / `with_prompt` transparent (Phase 53 D-01a) and adds **zero public surface**. Emit-after-success semantics: a raised render produces an ERROR span **and no event** (correct: "the span tried; the event is a fact that happened").
  - **Condition: unconditional on *successful* render.** One event per judge prompt = one per dataset item (bounded by the dataset, not per-token). Volume control is the *inline-at-one-site* choice, **never sampling** — audit events are not sampled.
- **D-04c — event `attributes`: closed, ids/enums/counts only, never text.**
  - `guardrail_triggered`: **reuse the existing, already-tested `Semconv.guardrail_attributes/1`** to project `scoria.guardrail.{decision, reason_code, name}` (the three low-cardinality enums that keep an orphan event legible). **OMIT `subject_ref` / `policy_key`** (correlate via `span_id`; don't duplicate the span). **Red-team REVISED:** do **NOT** mint a new `guardrail_event_attributes/1` — that is speculative `Semconv` surface with no SC behind it.
  - `prompt_rendered`: **one NEW registry key only — `scoria.prompt.template_ref` (class `:id`)** — the judge passes `"eval-spec-v#{version}"`; it makes an orphan event legible. **Red-team KILLED `scoria.prompt.tokens`** (class `:count`) — the judge does not populate it in v3.6, and a registry key with no v3.6 producer is exactly what 51/52/53 red-teams cut. Add `scoria.prompt.template_ref` to `Semconv.attribute_registry/0` (`semconv.ex:330`); build the payload inline (no new projector module).
  - The judge's free-form `explanation:` (`judge_runner.ex:167,202`) — the single most likely free-text leak in the codebase — is **doubly blocked**: **temporally** (the event fires at *render* time, pre-inference; the explanation does not exist yet) and **structurally** (fixed-key projection + `Bounds(:event)` + the closed registry). It can never reach the event.
- **D-04d — `user_feedback_received` stays reserved with ZERO `lib/` emitter.** Make "reserved, deliberately not emitted" **structural**: a grep-guard test (mirroring the D-15 anti-inline canary) that goes **RED** if anyone wires an emitter, plus a moduledoc note pointing at FB-01 / SEED-011. So a future dev does not mistake the absence for a bug.

### D-05 — 🔒 THE HANDLER SEAM MUST FAIL CLOSED (the single most important thing — red-team's caught coherence break)

Research A justified accepting **batch atomicity** (no per-event savepoints) on the premise that `name` / `time` / `span_id` are "always non-null upstream." But Research C's handler defaulted **neither** `time` nor guarded a nil `span_id` — and only `emit_event/1` (which the SC#2 raw bus **bypasses**) defaulted `time`. **The paths were incoherent.** Concretely, after the FK drop the remaining `insert_all` raise classes are:

1. **NULL `name`** — unreachable (the allow-list gates it before cast).
2. **NULL `time`** — **reachable via the raw bus** (only `emit_event/1` defaults it).
3. **NULL `span_id`** — **reachable** (`emit_event/1` passes `Map.get(event, :span_id)` = maybe nil; the raw bus can omit it).
4. **invalid-UTF-8 jsonb** from a `Bounds` `binary_part` truncation — pre-existing parity with spans, contained by the separate event txn.

- **D-05a — LOCK: the `[:scoria, :observe, :event, :emit]` HANDLER (not just `emit_event/1`) must default `time` (`DateTime.utc_now()`) and DROP nil-`span_id` events (fail-closed, via `reject_event`).** Because the SC#2 raw-bus path bypasses `emit_event/1`, those two `NOT NULL` columns are the **only** remaining raise classes that could roll back a batch of *sibling* events. Close them at the boundary of record and **batch atomicity is provably safe with zero per-event machinery** — which is why D-02b takes no savepoints.
- **D-05b — the SC#4 test asserts the ORPHAN ROW EXISTS.** Drive 50 real `span/4` emissions + 1 real `emit_event/1` orphan (its span never flushed); assert (1) 50 spans persisted, (2) **the orphan row exists with its dangling `span_id`**, (3) no span for that id. Asserting object (2) is what *forces* the FK drop — a span-count-only test would pass under a kept FK while silently losing the event. **Add a second test:** a raw-bus event with a nil `span_id` / missing `time` is **dropped at the handler** and never reaches `insert_all`, while 50 good events land — proving D-05a closes the batch-atomicity hole.

### D-06 — Activate `Bounds.enforce(_, :event)` (SEC-01's event clause)

- **D-06a — the `:event` arm already exists and is unit-tested** (`bounds.ex:137-138`, Phase 53 D-06i). This phase **activates** it: the event handler calls `Bounds.enforce(redacted, :event)` **after** the shared `redact/1` and **before** `Buffer.cast_event/2`, with the same `{:ok, bounded} | :drop` contract the span path uses (`telemetry.ex:67-74`). A `:drop` routes through `reject_event`/observability, never persists. No new Bounds code — just the wiring + a test that an oversized/denied event key is bounded exactly as a span key is.

### D-07 — What Phase 53b does NOT do (guard the boundary)

- **No operator UI for events.** A fired `guardrail_triggered` lands in Postgres and no operator can see it in v3.6 (Phase 53 D-08). Deliberate, roadmapped follow-on — state it in the CHANGELOG, do not silently omit.
- **No `user_feedback_received` emission** (SEED-011 / FB-01) — reserved-only (D-04d).
- **No new guardrail producers, no new span kinds, no `with_prompt_render/3`** (D-04b), **no `guardrail_event_attributes/1`** (D-04c), **no `scoria.prompt.tokens`** (D-04c), **no per-event savepoints / second GenServer / config disable-switch** (D-02, D-05) — each cut for lack of a success criterion.
- **No changes to the span pipeline's behavior** beyond the single-call-site redact collapse (D-03d) and adding the event clause to `@events` (D-03f).

### Claude's Discretion (delegated to researcher/planner)

- **Plan sequencing within the ~5-plan budget** (51/52/53 shipped 5/6/8; 53b is the smaller EVENT-02/03 half). Red-team's honest estimate + hard-prerequisite ordering: **(1)** core-lane FK-drop migration + `Semconv` vocabulary (`@event_names`/`event_name?`) + the `scoria.prompt.template_ref` registry key — **gates SC#4**; **(2)** Buffer event list + two-phase flush + `cast_event/2`; **(3)** `emit_event/1` + the `:event` telemetry handler (redact collapse, allow-list re-check, `Bounds(:event)`, fail-closed `time`/`span_id` seam) — **HARD PREREQUISITE, gates all downstream, depends on 1+2**; **(4)** guardrail + judge call sites (D-04); **(5)** SC canaries + integration tests. Plans 1 & 2 can run in parallel; 3 waits on both; 4 on 3; 5 on all.
- **The exact internal factoring** of the two-phase `do_flush` (D-02b) and the shared `redact/1`/`reject_event/2` helpers — keep them Semconv-owned and grep-guarded.
- **Whether the up-front `emit_event/1` name check and the handler check share one private guard or each call `Semconv.event_name?/1` directly** (D-03b) — either satisfies the anti-divergence lock, provided neither inlines a name list.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements & roadmap (authoritative)
- `.planning/REQUIREMENTS.md` — v3.6 locked requirements. **Phase 53b owns EVENT-02 + EVENT-03 only.** See also FB-01 (the SEED-011 flywheel that owns `user_feedback_received` *emission* — reserved here, not built). Scope doctrine (convention-not-columns, host-declares-Scoria-never-infers, zero required egress) is held here.
- `.planning/ROADMAP.md` §"Phase 53b" — goal + the 4 success criteria (the acceptance bar). §"Phase 54" is the downstream consumer of the conformance surface.

### The foundation this phase reuses (READ FIRST)
- `.planning/phases/53-structured-child-spans-write-time-bound/53-CONTEXT.md` — **the parent split.** The guardrail/prompt **spans** these events attach to (D-05, D-01), the `Bounds` choke point + its **`:event` clause built-and-unit-tested-here-activated-there** assignment (D-06i), the application wiring that makes the pipeline live (D-00a), the loud-but-non-fatal Buffer posture (D-05..D-09), the fixed-key-projector / closed-enum discipline (D-05f/g), and the D-15 anti-inline grep-guard pattern. The code_context note that "53b collapses the two `Redactor.redact` call sites to one" is fulfilled by D-03d.
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/51-CONTEXT.md` — the Buffer FK-safe trace-upsert + flush-error posture (D-05..D-09) that D-02's Phase 1 leaves unchanged, and the drift-guard-test pattern D-04d/D-03d mirror.
- `.planning/phases/52-retriever-span-host-declared-attributes/52-CONTEXT.md` — the `Semconv` seam and the real-Buffer + `Telemetry.attach/1` integration-test discipline (never hand-synthesize a telemetry event as production evidence) the SC#1/SC#4 tests reuse.
- `.planning/seeds/SEED-011-*.md` — owns `user_feedback_received` **emission**; reserved-not-built here (D-04d).

### Real-code anchors this phase edits (verify line numbers at plan time — do not trust blindly)
- `lib/scoria/observe/buffer.ex` — event list + two-phase flush (D-02); the FK-raise reality at `:123-129`.
- `lib/scoria/observe/telemetry.ex` — the new `:event` handler, the single-call-site `redact/1` collapse, the fail-closed `time`/`span_id` seam (D-03, D-05); `@events` at `:7-10` (D-03f); the two redact sites at `:53`/`:65`.
- `lib/scoria/observe.ex` — `emit_event/1` lives here (D-03a); `with_prompt/3` own-id opt for D-04b.
- `lib/scoria/observe/semconv.ex` — `@event_names`/`event_name?/1` (D-03c), the `scoria.prompt.template_ref` registry key (D-04c); mirror `@guardrail_names` at `:246-250`, `attribute_registry/0` at `:330`, `guardrail_attributes/1` at `:430`.
- `lib/scoria/observe/guardrail.ex` — `guardrail_triggered` inside `do_emit` (D-04a); span id `:163`, decision `:137`, emit `:171`.
- `lib/scoria/observe/redactor.ex` — the single redaction primitive (recurses into `:attributes`).
- `lib/scoria/observe/bounds.ex` — the `:event` arm to activate (D-06); `enforce/2` at `:137`.
- `lib/scoria/repo/span_event.ex` (+ `lib/scoria/repo/span.ex:17`) — the schema; `belongs_to`/`has_many` STAY (D-01c).
- `lib/scoria/eval/judge_runner.ex` — `prompt_rendered` inline at `build_judge_prompt_span/3` (D-04b); the `explanation:` leak at `:167`/`:202`.
- `lib/scoria/runtime.ex` (`:131`,`:154`) + `lib/scoria/workflows/runtime.ex` (`:417`,`:434`,`:452`) — the five `Guardrail.emit` call sites (unchanged by D-04a).
- **Migration precedents (D-00a — cite THESE, not the phantom one):** `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:19` (FK-free `parent_id`) and `…20260519000000_converge_eval_persistence.exs:117,144` (real `DROP CONSTRAINT IF EXISTS` pattern). The 53b FK-drop is a **new core-lane migration**.

### Project DNA (reference)
- `prompts/sztheory-elixir-dna.md`, `prompts/phoenix-ai-lib-deep-research.md`, `prompts/ai-architectural-patterns-deep-research.md` — operator-first DX, consumer-not-provider API (hide the plumbing behind `emit_event/1`), Ecto-native durable state, host owns identity, zero-config default.
- `brandbook/` — **canonical** (supersedes any older brand refs in `prompts/`). Low relevance this phase (no operator UI for events in v3.6).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scoria/observe/buffer.ex` — `cast_span/2`, `flush_now/1`, the FK-safe traces→spans `Ecto.Multi`, `Map.put_new_lazy(:id, …)`, and `surface_flush_error/*` storm control — all extended (not rewritten) for the event list + `signal: :event` dimension (D-02).
- `lib/scoria/observe/semconv.ex` — the single vocabulary owner. `@guardrail_names`/`guardrail_names/0` (`:246-250`) is the exact shape for `@event_names`/`event_name?/1`; `guardrail_attributes/1` (`:430`) is reused verbatim for `guardrail_triggered` (D-04c); `attribute_registry/0` (`:330`) gains one key.
- `lib/scoria/observe/guardrail.ex` — `do_emit` already holds both the span id and the decision at emit time — the free, DRY hook for `guardrail_triggered` (D-04a).
- `lib/scoria/observe/bounds.ex` — the `:event` arm is **already built and unit-tested**; this phase only wires it (D-06).
- `lib/scoria/observe/reviewer_broadcast.ex` — the ETS once-per-key dedupe reused by `reject_event`'s once-per-name log (D-03e).
- `Redactor.redact/1` — recurses into nested `:attributes`; one shared call site serves span + delta + event (D-03d).

### Established Patterns
- **`insert_all` bypasses changesets** (`buffer.ex:129`) → the flush path's only non-null guarantee is the DB `NOT NULL` columns + the handler seam (D-05), **not** `SpanEvent.changeset`. This is load-bearing for SC#4.
- **Closed-vocabulary + fixed-key-projector discipline (Phase 53 D-05f/g):** the projector never spreads host input; a caller who passes `reason:`/`explanation:` gets it silently ignored. `emit_event/1`'s event row is built by fixed-key `Map.take(~w(span_id name time attributes)a)` (D-02c/D-03a).
- **Loud-but-non-fatal (Phase 51 D-05..D-09):** `emit_event/1`, the `:event` handler, and the event flush all wrap `try/rescue`; observability never breaks host business logic and never crashes the Buffer.
- **Real-Postgres integration proof (Phase 52 D-ATTR01-6):** never hand-synthesize a telemetry event — reuse the scoped-Buffer + real `Telemetry.attach/1` + `flush_now` setup (`prompt_span_test.exs`) for the SC#1 and SC#4 tests.

### Integration Points
- **New migration:** core-lane `DROP CONSTRAINT` on `ai_span_events.span_id` (D-01a).
- **`telemetry.ex`:** add `[:scoria, :observe, :event, :emit]` to `@events` (`:7-10`); new `handle_event` clause; collapse redaction to one `defp redact/1`; fail-closed `time`/`span_id` seam (D-03, D-05, D-06).
- **`buffer.ex`:** `events` list + `max_event_size` + `event_consecutive_failures` in state; two-phase `do_flush`; `cast_event/2`; `signal`-parameterized `surface_flush_error` (D-02).
- **`observe.ex`:** `emit_event/1` (D-03a).
- **`semconv.ex`:** `@event_names` + `event_names/0` + `event_name?/1`; `scoria.prompt.template_ref` in the registry (D-03c, D-04c).
- **`guardrail.ex`:** `guardrail_triggered` in `do_emit` (D-04a). **`judge_runner.ex`:** `prompt_rendered` inline at `build_judge_prompt_span/3` (D-04b).

</code_context>

<specifics>
## Specific Ideas

- **The phase coheres under one line:** *one public verb (`emit_event/1`), one closed vocabulary owned by `Semconv`, one shared `Redactor.redact/1` call site, one `Bounds(:event)` choke point, and a two-phase Buffer flush where an orphan event can never sink a batch of good spans — because the FK is gone and the handler fails closed on the only two columns that could raise.*
- **The differentiator worth stating out loud (D-00b):** `ai_span_events` is durable and unsampled, unlike an OTel span event the SDK may silently drop — and OTel is now **deprecating the Span Events API entirely (2026)**. Scoria accidentally already has OPA's decision-log architecture: the decision record is durable, the span is the correlation handle. 🚩 Flag to Phase 54: if Scoria ever adds an OTLP exporter, `guardrail_triggered` must NOT be exported as an OTel span event — export it as a log record or a separate signal.
- **The sharpest lesson from the pass:** the research's own cited FK-drop precedent was a hallucination (D-00a) — the decision survived fact-check, but the *citation* was corrected. Downstream agents must cite `ai_spans.parent_id` (FK-free by construction) and `converge_eval_persistence.exs:117` (real `DROP CONSTRAINT`), never the phantom `20260712210000_*` migration.

</specifics>

<deferred>
## Deferred Ideas

- **Operator UI for events** — a fired `guardrail_triggered` is invisible to the operator in v3.6. Roadmapped follow-on, deliberately (Phase 53 D-08).
- **`user_feedback_received` emission** — capture thumbs/accept/edit/regenerate + async-arrival FK resolution. SEED-011 / FB-01; reserved in the vocabulary here, not built.
- **`scoria.prompt.tokens`** — a token-count key on `prompt_rendered`; no v3.6 producer (the judge omits it). Add when a real producer exists.
- **`guardrail_event_attributes/1`** — a dedicated event projector; unnecessary while `guardrail_attributes/1` suffices. Revisit only if event and span payloads must diverge.
- **`Compaction.SummarizeWorker` `prompt_rendered`** — instrument for symmetry if desired, but it has no `lib/` enqueuer, so it is not SC#3's production proof (the judge is).
- **Per-event insert isolation (savepoints)** — cut; the FK drop + fail-closed handler (D-05) make the only remaining raise classes unreachable. Revisit only if a new non-null event column with a reachable-null path is ever added.
- **OTLP export of events** — Phase 54+ concern; must not use OTel span events (D-00b).

### Reviewed Todos (not folded)
None — `todo.match-phase 53b` scope produced no matches (no `.planning/` todos target this lane).

</deferred>

---

*Phase: 53B-ai-span-events-emit-event-1*
*Context gathered: 2026-07-18 (4 parallel cross-aware research subagents + adversarial red-team, every claim verified against real code; one hallucinated migration citation caught and corrected)*

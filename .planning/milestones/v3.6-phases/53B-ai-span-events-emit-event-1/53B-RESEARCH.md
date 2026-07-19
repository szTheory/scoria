# Phase 53B: `ai_span_events` + `emit_event/1` - Research

**Researched:** 2026-07-18
**Domain:** Elixir/Ecto telemetry pipeline hardening (event vocabulary, write-time isolation, redaction reuse)
**Confidence:** HIGH

## Summary

This phase does not need new design work — `53B-CONTEXT.md` already carries a locked, red-teamed spec. This RESEARCH.md exists to do the thing the CONTEXT explicitly demanded: **re-verify every real-code anchor against the current tree, confirm the reuse assets are shaped as claimed, and produce the Nyquist Validation Architecture the planner consumes.**

**Verification verdict: no plan-blocking landmines found.** I independently re-read all eleven anchor files (`buffer.ex`, `telemetry.ex`, `observe.ex`, `semconv.ex`, `guardrail.ex`, `bounds.ex`, `redactor.ex`, `span_event.ex`, `span.ex`, `judge_runner.ex`, `runtime.ex`, `workflows/runtime.ex`, `reviewer_broadcast.ex`) plus both cited migrations and the phantom-migration list. Every structural claim in CONTEXT.md (the FK reality, the `:event` Bounds arm, the five `Guardrail.emit` call sites, the `ai_spans.parent_id` FK-free precedent, the absence of the `20260712210000_*` migration) checked out exactly. Two citations have small line-number drift (both immaterial to the plan — documented below under "Citation Drift"). One genuinely useful clarification surfaced that CONTEXT.md did not spell out: the single-`Redactor.redact(` drift-guard test **must be scoped to `lib/scoria/observe/telemetry.ex` only** — the repo has 5 total `Redactor.redact(` call sites across `lib/`, and a repo-wide grep would never pass.

**Primary recommendation:** Plan exactly per D-00 through D-07 and the delegated sequencing in "Claude's Discretion." Use this document for: (1) corrected/confirmed line-number citations, (2) the Validation Architecture (test seams, file paths, concrete assertions) for the 4 success criteria, (3) exact current-state code excerpts for the two call sites EVENT-03 touches, so the planner can write byte-accurate task diffs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `emit_event/1` public API | API / Backend (library facade) | — | `Scoria.Observe` is the host-facing emission facade; this is a library-internal API surface, not a web-tier concern |
| Event vocabulary (`@event_names`) | API / Backend | — | `Semconv` is the single closed-vocabulary owner; no UI or DB dependency |
| Telemetry handler + redact/Bounds/Buffer wiring | API / Backend | — | Synchronous in-process telemetry dispatch inside the host BEAM node; not a network boundary |
| `ai_span_events` persistence | Database / Storage | — | Ecto schema + migration; Postgres is system-of-record, durable and unsampled by design (D-00b) |
| FK-drop migration | Database / Storage | — | Schema-level change; core-lane (ships with the Hex package), not dev-only |
| Guardrail/judge real call sites | API / Backend | — | `Guardrail.do_emit` and `JudgeRunner.build_judge_prompt_span/3` are both server-side business logic, not LiveView/browser |
| Operator visibility of events | *(none — explicitly out of scope, D-07)* | — | No LiveView/dashboard component reads `ai_span_events` in this phase; deliberate, roadmapped gap |

No browser/client or CDN/static tier involvement in this phase — it is entirely a backend/database seam. This map confirms the phase boundary in CONTEXT.md's D-07 (no operator UI) is coherent with the codebase: `grep -rn "ai_span_events\|SpanEvent" lib/scoria_web/` returns nothing, confirming zero read-side wiring exists to accidentally violate.

## Real-Code Anchor Verification (verified 2026-07-18 against current `main`)

All citations below were independently re-derived by reading the live files, not copied from CONTEXT.md. **Verdict: ACCURATE**, two minor drifts noted.

### `lib/scoria/observe/buffer.ex`
- FK-raise `Ecto.Multi` (traces→spans): lines **123-129** — confirmed exact match to CONTEXT's `:123-129`.
  ```elixir
  multi =
    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:traces, Scoria.Repo.Trace, trace_entries,
      on_conflict: :nothing,
      conflict_target: [:id]
    )
    |> Ecto.Multi.insert_all(:spans, Scoria.Repo.Span, span_entries)
  ```
- `Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)` — line 109. Confirmed.
- `surface_flush_error/4` — line 174 (private, called from both the `{:error, ...}` branch at :138 and the `rescue` branch at :161). Confirmed present and shaped exactly as CONTEXT describes (returns new consecutive-failure count; always emits telemetry; logs only on the first of a run).
- Buffer-full drop+warn — lines 49-51 (`handle_cast`). Confirmed.
- `flush_now/1` — lines 23-25, routes through `handle_call(:flush_now, ...)` → `do_flush(state, from_timer?: false)` at line 59. Confirmed byte-for-byte the "test hook" CONTEXT describes.
- `terminate/2` — lines 71-77, never honors `:raise` (comment explicitly states this, matching Phase-53 D-09i continuity CONTEXT cites).
- **No `events` field, `max_event_size`, or `event_consecutive_failures` exist yet** in `Buffer` state (line 33-41) — confirmed greenfield addition, exactly as D-02a describes.

### `lib/scoria/observe/telemetry.ex`
- `@events` list — lines **7-10**, currently exactly 2 entries (`[:scoria, :observe, :span, :stop]`, `[:scoria, :observe, :span, :delta]`). Confirmed CONTEXT's `:7-10` citation and confirmed `[:scoria, :observe, :event, :emit]` is **absent** — D-03f's addition is real and necessary.
- Two `Redactor.redact` call sites: line **65** (`redacted = Redactor.redact(metadata)`, the span/other-type clause) confirmed exact match. The delta-arm call is at line **55** (`|> Redactor.redact()`), not `:53` as CONTEXT cites — **2-line drift, immaterial** (`:53` is the `redacted =` assignment header one line above the pipe).
- Span `handle_event` clause + redact→Bounds→Buffer.cast_span order — lines 62-75, with the `case Bounds.enforce(redacted, :span) do {:ok, bounded} -> ... :drop -> :ok end` shape at lines **67-74**. Confirmed exact.
- **No `handle_event` clause matches `[:scoria, :observe, :event, :emit]`** today — confirmed, this whole clause is new (D-03/D-05/D-06 wiring target).

### `lib/scoria/observe.ex`
- `with_prompt/3` at lines 153-154, thin wrapper over `span/4`.
- The own-id `opts[:span_id]` semantics live inside `build_span_map/7`'s private helper at line 372: `id: opts[:span_id] || Ecto.UUID.generate(),`. Confirmed — this is the exact seam D-04b's "thread it via the existing `opts[:span_id]` own-id opt" plan step will use.
- **`emit_event/1` does not exist yet** — confirmed greenfield addition (D-03a).

### `lib/scoria/observe/semconv.ex`
- `@guardrail_names` — lines **246-250**, exact match to CONTEXT's citation, confirmed shape (`~w(release_gate approval_gate budget_gate breaker_gate)`, closed 4-value list + accessor).
- `attribute_registry/0` — line **330** (`def attribute_registry, do: @attribute_registry`), exact match.
- `guardrail_attributes/1` — line **430** (`def guardrail_attributes(input) when is_map(input) do`), exact match.
- **`@event_names` / `event_names/0` / `event_name?/1` do not exist yet** — confirmed greenfield addition (D-03c). The mirror target (`@guardrail_names`/`guardrail_names/0`) is real, present, and exactly the shape to copy.
- The registry (`@attribute_registry`, lines 283-307) does **not** yet contain `scoria.prompt.template_ref` — confirmed, needs adding per D-04c.

### `lib/scoria/observe/guardrail.ex`
- `do_emit/1` private function starts at line 131.
- Span id: line **163** (`id: Map.get(input, :span_id) || Ecto.UUID.generate(),`) — exact match.
- Decision: line **137** (`decision: Map.get(input, :decision),`) — exact match.
- `emit_span(span)` call: line **171** — exact match.
- Confirmed `do_emit` already computes `gate_name` (`:132`) and `guardrail_fields.decision` (`:137`) in the same scope before `emit_span/1` runs at `:171` — the "free, DRY hook" D-04a describes for inserting `emit_event(%{name: :guardrail_triggered, ...})` right after line 171 (inside `do_emit`, still under `emit/1`'s outer `try/rescue -> :ok` at lines 125-129) is real and available.

### `lib/scoria/observe/bounds.ex`
- `enforce/2` spec + guard clause accepting `:span | :event` — lines **137-138** (`@spec enforce(term(), :span | :event) :: {:ok, map()} | :drop` / `def enforce(metadata, kind) when kind in [:span, :event] do`). Exact match. **Confirmed already built and unit-tested**: `test/scoria/observe/bounds_test.exs:265-269` — `describe "Test 13: the :event arm is built and unit-tested (activated in Phase 53b, D-06i)"` exercises `Bounds.enforce(metadata, :event)` directly and asserts `{:ok, bounded}` with identical registry admission to `:span`. Nothing to build here — this phase only needs to add the call site in the new event `handle_event` clause.
- `do_enforce/2`'s fail-closed `:not_a_map`/`:attributes_not_a_map` branches (lines 144-160) apply identically regardless of `kind` — relevant to D-05 (the handler's fail-closed nil-`span_id`/nil-`time` guard is a *separate*, earlier check the handler itself must do; `Bounds` does not know about `span_id`/`time` at all, it only touches `:attributes`).

### `lib/scoria/observe/redactor.ex`
- `redact/1` (lines 8-15) dispatches to `do_redact/2` (lines 32-46), which recurses generically into any map/list value — **confirmed it is not attribute-specific**; it recurses into whatever nested structure it's handed, so an event map's `:attributes` sub-map is redacted exactly like a span's, with zero new code needed. Confirmed.
- **Landmine-adjacent finding (not a landmine, but load-bearing for planning the drift-guard test):** `grep -rn "Redactor\.redact(" lib/` returns **5** total call sites in the whole `lib/` tree:
  1. `lib/scoria_web/live/orchestrator_live.ex:269`
  2. `lib/scoria/sre.ex:367`
  3. `lib/scoria/observe/telemetry.ex:55`
  4. `lib/scoria/observe/telemetry.ex:65`
  5. `lib/scoria/workflows/remote_approval_projection.ex:154`

  D-03d's "source-scan drift guard asserting exactly one `Redactor.redact(` call site" **must scope its `File.read!` to `lib/scoria/observe/telemetry.ex` alone**, not a repo-wide grep — the other three call sites (LiveView trace rendering, SRE telemetry, remote-approval projection) are legitimate independent redaction consumers unrelated to this phase and would make a repo-wide assertion permanently false. This is the one concrete correction/addition to CONTEXT.md's D-03d test design that the planner needs and CONTEXT did not spell out.

### `lib/scoria/repo/span_event.ex` + `lib/scoria/repo/span.ex`
- `SpanEvent` schema: `belongs_to(:span, Scoria.Repo.Span)` (line 12), `validate_required([:span_id, :name, :time])` in `changeset/2` (line 20). Confirmed exact match to D-01c's claims.
- `Span` schema: `has_many(:events, Scoria.Repo.SpanEvent)` at **line 17** — exact match to CONTEXT's `span.ex:17` citation.
- Confirmed via `grep -rn "ai_span_events\|Repo.SpanEvent\|has_many(:events" lib/` that the only `lib/` references to this association are the schema declaration and the changeset — **no join query exists anywhere in `lib/`**, confirming D-01c's "dropping the DB constraint breaks no reader" claim.

### `lib/scoria/eval/judge_runner.ex`
- `build_judge_prompt_span/3` (private, lines 197-206) — **current shape does NOT pass `:span_id`** to `Observe.with_prompt/3`'s opts map (only `trace_id`/`parent_id`). This confirms the D-04b plan step is a real, needed edit (pre-mint a `span_id`, add it to the opts map, thread it to the post-render `emit_event` call) — not already partially done.
- The free-form `explanation:` literal — actual lines are **168** and **227** (CONTEXT cites `:167`/`:202` — see "Citation Drift" below). Both occurrences confirmed: line 168 is the live-judge success path (`explanation: Map.get(verdict, "explanation", "Judge verdict unavailable")`), line 227 is the `not_scored` fallback path (`explanation: "Live judge could not score the sealed dataset item: #{reason}"`). Both are genuinely free-text and both are irrelevant to `prompt_rendered` because the event fires **before** these lines execute (at `build_judge_prompt_span/3`, during render — the judge hasn't run yet), confirming D-04c's "doubly blocked, temporally and structurally" claim holds regardless of the exact line numbers.

### `lib/scoria/runtime.ex` + `lib/scoria/workflows/runtime.ex`
- `runtime.ex`: `Guardrail.emit(%{...})` call sites at lines **131** (`emit_g1_allow/4`, decision `"allow"`) and **154** (`emit_g1_block/3`, decision `"block"`) — exact match to CONTEXT's `:131`,`:154`.
- `workflows/runtime.ex`: `Guardrail.emit(%{...})` call sites at lines **417** (`emit_g2_approval_escalate/3`, decision `"escalate"`), **434** (`emit_g3_budget_block/3`, decision `"block"`), **452** (`emit_g4_breaker_block/4`, decision `"block"`) — exact match to CONTEXT's `:417`,`:434`,`:452`.
- All 5 call sites confirmed unchanged by D-04a (the event fires inside `Guardrail.do_emit`, downstream of all 5 callers — zero caller-side edits needed). Confirmed each caller passes `decision:` as one of `"allow"`/`"block"`/`"escalate"` (never `nil`), matching D-04a's `decision not in [nil, "allow"]` gating condition — 4 of the 5 real call sites (`emit_g1_block`, `emit_g2_approval_escalate`, `emit_g3_budget_block`, `emit_g4_breaker_block`) will produce a `guardrail_triggered` event; only `emit_g1_allow`'s `"allow"` decision will not.

### Migrations (D-00a)
- Confirmed the migration directory's most recent file is `20260704235536_add_eval_runs_verdict_index.exs` — **no `20260712210000_*` file exists**, confirming the phantom-migration correction in D-00a is accurate.
- `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`:
  - Line **19**: `add :parent_id, :binary_id` on `ai_spans` — **no `references(...)`** — confirmed FK-free by construction, exactly the D-00a precedent.
  - Line **31**: `create index(:ai_spans, [:parent_id])` — confirmed indexed, matching CONTEXT.
  - Line **41**: `add :span_id, references(:ai_spans, type: :binary_id, on_delete: :delete_all), null: false` on `ai_span_events` — confirmed the exact hard immediate FK D-01 is built to drop.
- `priv/repo/migrations/20260519000000_converge_eval_persistence.exs`:
  - Line **117**: `execute("ALTER TABLE ai_eval_runs DROP CONSTRAINT IF EXISTS ai_eval_runs_dataset_id_fkey")` — confirmed exact match.
  - Line **144**: `execute("ALTER TABLE ai_scores DROP CONSTRAINT IF EXISTS ai_scores_dataset_item_id_fkey")` — confirmed exact match.
  - **This is the real, in-repo precedent for the new migration's `ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey` statement** — cite this file, not the phantom one.

### Citation Drift (both immaterial — informational only)

| Cited (CONTEXT.md) | Actual | Delta | Impact |
|---|---|---|---|
| `telemetry.ex:53` (delta-arm redact call) | `telemetry.ex:55` | 2 lines | None — same function, same pipe chain, 2-line offset from the `redacted =` header |
| `judge_runner.ex:167,:202` (explanation: literal) | `judge_runner.ex:168,:227` | 1 / 25 lines | None — both are still free-text `explanation:` literals in the two code paths CONTEXT describes; the temporal/structural argument for why `prompt_rendered` can never see them is unaffected |

Neither drift changes any locked decision, blocks any plan, or invalidates any claim. Recorded here purely so the planner cites the exact current line when writing task diffs.

## Reusable Assets — Confirmed Present and Shaped as Claimed

- **`lib/scoria/observe/reviewer_broadcast.ex`** — ETS once-per-key dedupe pattern confirmed at lines 93-106 (`first_span_for_trace?/1` using `:ets.insert_new(@trace_seen_table, {trace_id, true})`, lazily-created named public ETS table via `ensure_trace_seen_table/0`). This exact idiom is what `reject_event`'s once-per-name-per-node `Logger.warning` (D-03e) should mirror. **Note:** `Scoria.Observe.Bounds` itself already has an even closer precedent at `bounds.ex:385-395` (`first_warning_for_key?/1`, identical `:ets.insert_new` shape against its own `@warned_table`) — either is a valid template; `Bounds`'s version is literally in the same subsystem this phase extends.
- **`Redactor.redact/1`** confirmed to recurse generically (not attribute-specific) — no new code needed for "redaction recurses into nested `:attributes`" to hold for events.
- **D-15 anti-inline grep-guard pattern** — confirmed a concrete, working example exists at `test/scoria/observe/semconv_test.exs:128-142` (`"anti-inline grep: no lib consumer file inlines the \"scoria.retrieval.\" literal"`): a hardcoded list of consumer file paths, each read via `File.read!/1` (guarded by `File.exists?/1`), asserted via `refute source =~ "<literal>"`. This is the exact template for both D-03d's scoped single-call-site guard and D-04d's zero-emitter guard for `user_feedback_received`.
- **Real-Postgres integration test pattern (D-ATTR01-6 lineage)** — confirmed at `test/scoria/observe/prompt_span_test.exs:29-52`: `Ecto.Adapters.SQL.Sandbox.checkout/1` + `{:shared, self()}` mode, a uniquely-named `start_supervised!` `Buffer` child, `:telemetry.detach("scoria-observe-telemetry")` followed by `Scoria.Observe.Telemetry.attach(buffer_name)` to re-point the shared production handler at the scoped test buffer, and `on_exit(fn -> :telemetry.detach(...) end)`. `emit_and_flush/2` (lines 68-80) calls the real public emitter, then `Buffer.flush_now(buffer_name)` (no `Process.sleep` race), then reads back from `Repo`. **This is the exact, ready-to-copy scaffold for the SC#1 and SC#4 integration tests** — the planner should model new event tests on this file, not `telemetry_test.exs` (which still uses raw `:telemetry.execute` + `Process.sleep(50)` — an older, racier pattern present in the codebase but superseded by the `flush_now` idiom for anything written from Phase 52 onward).
- **Closed-vocabulary / fixed-key-projector discipline** confirmed live in two places: `Semconv.guardrail_attributes/1` (`semconv.ex:430-437`, `Enum.reduce` over a fixed keyword list, `nil` values omitted, never spread) and `Semconv.merge_host_declared/2` (`semconv.ex:117-124`, same shape). `emit_event/1`'s event-row projection (`Map.take(~w(span_id name time attributes)a)`, D-02c/D-03a) is the same idiom applied to top-level event fields rather than an attributes sub-map — consistent with the rest of the codebase.

## Standard Stack

No new dependencies. This phase is pure application code inside the existing `Scoria` OTP app: `Ecto.Multi`/`Repo.insert_all` (already a dependency), `:telemetry` (already a dependency, `~> 1.x`, used pervasively), ExUnit + `Ecto.Adapters.SQL.Sandbox` for tests (already the project's test stack). `[VERIFIED: mix.exs deps already present, no new deps added]`.

**Installation:** none required.

## Package Legitimacy Audit

Not applicable — this phase adds zero new external packages. `mix.exs` is not touched by this plan.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  Producers (real call sites)                                        │
│                                                                       │
│  Guardrail.do_emit/1 (guardrail.ex:131)                              │
│    ├─ emits SPAN  → [:scoria,:observe,:span,:stop]  (existing)       │
│    └─ emits EVENT → [:scoria,:observe,:event,:emit] (NEW, D-04a)     │
│         only when decision not in [nil, "allow"]                    │
│                                                                       │
│  JudgeRunner.build_judge_prompt_span/3 (judge_runner.ex:197)         │
│    ├─ Observe.with_prompt/3 → SPAN (existing, span_id now pre-minted)│
│    └─ on successful return → Observe.emit_event/1 (NEW, D-04b)      │
│         name: :prompt_rendered, attributes: {template_ref}          │
└───────────────────────────┬───────────────────────────────────────┘
                            │ :telemetry.execute
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Scoria.Observe.emit_event/1 (NEW, observe.ex, D-03a)                │
│    - Semconv.event_name?/1 up-front check → {:error,:unknown_event} │
│    - try/rescue -> :ok (never raises)                                │
└───────────────────────────┬───────────────────────────────────────┘
                            │ :telemetry.execute([:scoria,:observe,:event,:emit])
                            │  (ALSO reachable directly via raw :telemetry.execute —
                            │   the SC#2 bypass path)
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Scoria.Observe.Telemetry.handle_event/4 (NEW clause, D-03/D-05/D-06)│
│                                                                       │
│  1. Semconv.event_name?/1 RE-CHECK (boundary of record, D-03b)      │
│       unknown -> reject_event/2 -> telemetry :rejected + log, STOP  │
│  2. defp redact/1 (collapsed single call site, D-03d)                │
│  3. fail-closed seam (D-05a, NEW logic, not in Bounds):              │
│       - default `time` to DateTime.utc_now() if missing              │
│       - DROP if `span_id` is nil (-> reject_event, never reaches     │
│         insert_all)                                                   │
│  4. Bounds.enforce(redacted, :event)  (ALREADY BUILT, bounds.ex:137) │
│       :drop -> reject_event/2, STOP                                  │
│       {:ok, bounded} -> continue                                     │
│  5. Buffer.cast_event/2 (NEW, mirrors cast_span/2, D-02c)            │
└───────────────────────────┬───────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Scoria.Observe.Buffer (extended, D-02)                              │
│    state: existing `spans` list  +  NEW `events` list                │
│                                                                       │
│  do_flush/2 — TWO ORDERED PHASES (D-02b):                            │
│    Phase 1 (UNCHANGED): Ecto.Multi traces→spans insert_all            │
│              (buffer.ex:123-129) — own try/rescue, own outcome        │
│    Phase 2 (NEW): Repo.insert_all(SpanEvent, event_entries)            │
│              — SEPARATE transaction, own try/rescue,                  │
│              runs REGARDLESS of Phase 1's outcome                     │
│                                                                        │
│  FK on ai_span_events.span_id is DROPPED (new migration, D-01a) —      │
│  an event whose span never flushed (or was dropped) is INSERTABLE,    │
│  not fatal — persists dangling, never retried, never discarded        │
│  (D-01b: SC#4's "never loses a batch of good spans" guarantee)        │
└───────────────────────────┬───────────────────────────────────────┘
                            ▼
                     Postgres: ai_span_events
              (durable, unsampled, span_id NOT NULL but
               may be dangling; no operator UI reads this table
               in v3.6, D-07)
```

### Recommended Project Structure

No new files/modules — every change is an addition inside existing files:

```
lib/scoria/
├── observe.ex                 # + emit_event/1 (D-03a)
├── observe/
│   ├── buffer.ex               # + events list, cast_event/2, two-phase do_flush (D-02)
│   ├── telemetry.ex            # + :event handle_event clause, redact/1 collapse, @events entry (D-03/D-05/D-06)
│   ├── semconv.ex               # + @event_names/event_names/0/event_name?/1, scoria.prompt.template_ref (D-03c/D-04c)
│   ├── guardrail.ex             # do_emit gains one emit_event call after emit_span (D-04a)
│   ├── bounds.ex                # UNCHANGED — :event arm already built
│   └── redactor.ex              # UNCHANGED
├── eval/
│   └── judge_runner.ex          # build_judge_prompt_span/3 pre-mints span_id, emits after success (D-04b)
├── runtime.ex                   # UNCHANGED (Guardrail.emit callers get the event for free)
└── workflows/
    └── runtime.ex                # UNCHANGED (same)

priv/repo/migrations/
└── <new>_drop_ai_span_events_span_id_fk.exs   # core-lane, D-01a

test/scoria/observe/
├── buffer_test.exs               # + two-phase flush + orphan-persistence assertions (SC#4)
├── telemetry_test.exs            # + :event handler tests (allow-list, fail-closed seam)
├── semconv_test.exs              # + event vocabulary + anti-inline grep tests
├── guardrail_test.exs (if exists) # + guardrail_triggered emission assertion
└── event_emit_test.exs (NEW, suggested)  # emit_event/1 + raw-bus SC#2 canary + SC#1 redact integration

test/scoria/eval/
└── judge_runner_test.exs         # + prompt_rendered emission assertion, no-explanation-leak assertion
```

### Pattern 1: Two-Phase, Independently-Isolated Buffer Flush
**What:** `do_flush/2` runs the existing spans `Ecto.Multi` first (unchanged), then unconditionally attempts a separate `Repo.insert_all` for events in its own `try/rescue`, regardless of Phase 1's outcome.
**When to use:** Any time two persistence concerns share a flush cadence but must not share failure blast radius.
**Example (illustrative, matches D-02b):**
```elixir
# Source: 53B-CONTEXT.md D-02b, applying the existing buffer.ex:85-96 do_flush/2 shape
defp do_flush(state, timer_opts) do
  from_timer? = Keyword.get(timer_opts, :from_timer?, false)

  new_span_failures =
    flush_spans(state.spans, %{name: state.name, max_size: state.max_size,
      on_flush_error: state.on_flush_error, consecutive_failures: state.consecutive_failures,
      from_timer?: from_timer?})

  new_event_failures =
    flush_events(state.events, %{name: state.name, max_size: state.max_event_size,
      on_flush_error: state.on_flush_error, consecutive_failures: state.event_consecutive_failures,
      from_timer?: from_timer?})

  %{state | spans: [], events: [],
    consecutive_failures: new_span_failures,
    event_consecutive_failures: new_event_failures}
end
```

### Pattern 2: Allow-List Re-Checked at Both Ends (Defense in Depth, Single Source of Truth)
**What:** `emit_event/1` checks `Semconv.event_name?/1` for good caller DX; the telemetry handler re-checks the SAME function as the boundary of record, because a raw `:telemetry.execute` bypasses `emit_event/1` entirely.
**When to use:** Any time a public API function and a `:telemetry` event bus both need the same admission rule, and the bus is reachable independently of the function.
**Example:**
```elixir
# Source: 53B-CONTEXT.md D-03b, confirmed against semconv.ex's @guardrail_names/guardrail_names/0 shape
def emit_event(%{name: name} = event) when is_map(event) do
  if Semconv.event_name?(name) do
    :telemetry.execute([:scoria, :observe, :event, :emit], %{}, event)
    :ok
  else
    {:error, :unknown_event}
  end
rescue
  _ -> :ok
end
```

### Anti-Patterns to Avoid
- **Widening the batch-atomicity fix with per-event savepoints or a second GenServer:** cut explicitly in D-02/D-05 — the FK drop + fail-closed handler make every remaining raise class unreachable, so this machinery has no success criterion behind it. Do not add it.
- **`String.to_atom` on inbound event names:** never — membership-check only against the closed `@event_names` list; the atom→string conversion for the DB column happens exactly once, at the fixed-key projection (D-03a).
- **A repo-wide `Redactor.redact(` grep for the D-03d drift guard:** will immediately false-RED — 5 legitimate call sites exist outside `telemetry.ex`. Scope the assertion to `lib/scoria/observe/telemetry.ex` only (see Anchor Verification above).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Attribute size/key bounding for events | A new `Bounds`-style module for events | `Bounds.enforce(metadata, :event)` (already built, `bounds.ex:137-138`) | Unit-tested since Phase 53; this phase only activates it |
| Guardrail-event attribute projection | A new `guardrail_event_attributes/1` | `Semconv.guardrail_attributes/1` (`semconv.ex:430`) reused verbatim | Red-team explicitly killed the dedicated projector — no SC behind it |
| Once-per-key warning dedupe | A new dedupe mechanism for `reject_event` | The existing ETS `:ets.insert_new` idiom (`reviewer_broadcast.ex:93-106` or `bounds.ex:385-395`) | Same idiom already proven correct in this exact subsystem |

**Key insight:** every piece of machinery this phase needs to build a NEW thing for (event list, two-phase flush, event vocabulary, fail-closed handler seam) already has a structurally-identical sibling elsewhere in `Scoria.Observe` (span list, span Multi, guardrail vocabulary, `Bounds`'s own fail-closed `enforce/2`). The plan should mirror, never invent.

## Runtime State Inventory

Not applicable — this is not a rename/refactor/migration phase. `ai_span_events` already exists as a table since `0.1.0` (per REQUIREMENTS.md's research basis note); this phase only unblocks its write path and adds one column-level FK drop, not a rename or data migration of existing rows. Confirmed via migration history: no existing production data in `ai_span_events` needs remediation (it has never had a working write path — REQUIREMENTS.md explicitly frames the whole EVENT-02/03 pair as "wire the dead table," not "migrate existing rows").

## Common Pitfalls

### Pitfall 1: Scoping the Redactor drift-guard test too broadly
**What goes wrong:** A repo-wide `grep -r "Redactor.redact(" lib/` assertion for "exactly one call site" fails immediately on landing.
**Why it happens:** `Redactor.redact/1` is a shared utility with 3 other legitimate, phase-unrelated consumers (`orchestrator_live.ex`, `sre.ex`, `remote_approval_projection.ex`).
**How to avoid:** Scope the `File.read!/1` + count-occurrences assertion to `lib/scoria/observe/telemetry.ex` specifically (mirrors the existing `semconv_test.exs` anti-inline pattern's file-list scoping).
**Warning signs:** Test written against `Path.wildcard("lib/**/*.ex")` instead of a literal path.

### Pitfall 2: Forgetting the raw-bus bypass when reasoning about "the handler is the boundary of record"
**What goes wrong:** A developer adds validation only to `emit_event/1` and assumes it's sufficient, missing that `:telemetry.execute([:scoria, :observe, :event, :emit], ...)` is public API surface reachable by any adapter or host code directly, with zero coupling to `emit_event/1`.
**Why it happens:** `:telemetry.execute/3` is a bare BEAM function call, not gated by any Elixir module boundary — anyone who knows the event name tuple can call it.
**How to avoid:** D-05a's fail-closed handler-level checks (default `time`, drop nil `span_id`) and the handler-level `Semconv.event_name?/1` re-check are BOTH mandatory, not redundant. SC#2's test must exercise both paths independently.
**Warning signs:** A test that only calls `Observe.emit_event/1` and never raw `:telemetry.execute/3` directly for the SC#2 canary.

### Pitfall 3: Treating `SpanEvent.changeset/2`'s `validate_required` as a real guarantee on the flush path
**What goes wrong:** Assuming `validate_required([:span_id, :name, :time])` protects the `insert_all` flush path from nulls.
**Why it happens:** It's easy to see a changeset with `validate_required` and assume it's load-bearing everywhere the schema is touched.
**How to avoid:** `insert_all` bypasses changesets entirely (`buffer.ex:129`, same as the existing span path) — the changeset only guards direct `Repo.insert/2` calls (none exist on this path). The ONLY real guarantees on the flush path are the DB `NOT NULL` columns plus the D-05a handler-level fail-closed seam.
**Warning signs:** A plan task that treats `SpanEvent.changeset/2` edits as satisfying D-05's requirement.

## Code Examples

### Guardrail event emission (D-04a) — the free DRY hook
```elixir
# Source: verified against lib/scoria/observe/guardrail.ex:131-172 (current, unmodified)
defp do_emit(input) do
  gate_name = Map.get(input, :name)
  # ... existing span-building code, unchanged through line 171 (emit_span(span)) ...
  emit_span(span)

  # NEW (D-04a): after the span emits, and only for a real intervention.
  decision = Map.get(input, :decision)
  if decision not in [nil, "allow"] do
    Scoria.Observe.emit_event(%{
      name: :guardrail_triggered,
      span_id: Map.get(input, :span_id) || span.id,
      time: end_time,
      attributes: Semconv.guardrail_attributes(%{
        name: gate_name,
        decision: decision,
        reason_code: Map.get(guardrail_fields, :reason_code)
      })
    })
  end
end
```
Note: `span.id` (the freshly-minted or caller-supplied id at line 163) must be captured before/alongside `emit_span/1` so the event's `span_id` can reference it — both already coexist in the same function scope, confirming D-04a's "free hook" framing.

### Judge prompt-render event emission (D-04b) — pre-mint + emit-after-success
```elixir
# Source: verified against lib/scoria/eval/judge_runner.ex:197-206 (current, unmodified)
defp build_judge_prompt_span(dataset_item, subject_output, attrs, eval_spec) do
  span_id = fetch(attrs, :span_id) || Ecto.UUID.generate()

  result =
    Observe.with_prompt(
      "eval.judge_prompt",
      %{
        trace_id: fetch(attrs, :trace_id) || Ecto.UUID.generate(),
        parent_id: fetch(attrs, :parent_id),
        span_id: span_id                      # NEW: own-id opt (D-04b)
      },
      fn -> build_judge_prompt(dataset_item, subject_output) end
    )

  # NEW (D-04b): only reached on successful return -- span/4 reraises on
  # error, so a raised render never executes past this point.
  Observe.emit_event(%{
    name: :prompt_rendered,
    span_id: span_id,
    time: DateTime.utc_now(),
    attributes: %{Semconv.prompt_template_ref_key() => "eval-spec-v#{eval_spec.version}"}
  })

  result
end
```
(`Semconv.prompt_template_ref_key/0` is illustrative naming — the exact accessor name is Claude's Discretion per D-04c, which only locks the registry key STRING `scoria.prompt.template_ref`.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OTel Span Events API | OTel Logs API | 2026, per CONTEXT D-00b research finding | If Scoria ever ships an OTLP exporter (Phase 54+ concern), `guardrail_triggered` must export as a log record, never a span event — flagged forward, no action this phase |

**Deprecated/outdated:** N/A within this phase's own code — no existing Scoria code is being deprecated by this change; it is a pure addition.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | OTel is "now deprecating the Span Events API entirely (2026)" (D-00b, carried from CONTEXT.md, not independently re-verified via web search in this research pass) | Summary / State of the Art | Low — this is a forward-looking flag for Phase 54's OTLP-exporter design, not a locked decision this phase's tests depend on. If the OTel claim is imprecise, only the moduledoc's framing (not any test or migration) would need a wording fix later. |

No other claims in this document are assumed — every other factual statement was independently re-verified against the live codebase in this research session (file reads, greps, and direct line citation) rather than carried over from CONTEXT.md without checking.

## Open Questions

1. **Should the suggested new test file `test/scoria/observe/event_emit_test.exs` be a new file or folded into `telemetry_test.exs`?**
   - What we know: `telemetry_test.exs` already exists and covers the span/delta handler clauses; adding the event clause there keeps one file per "handler," but the file would grow past ~130 lines with the SC#1/SC#2/SC#4 event-specific canaries.
   - What's unclear: no CONTEXT.md decision addresses file organization for the test suite (this is implementation-plan-level, not spec-level).
   - Recommendation: Claude's Discretion at plan time — either is structurally fine; a new file keeps a name-collision-prone `describe` block count down and cleanly separates "span pipeline" tests from "event pipeline" tests for future readers.

2. **Exact accessor name for the new `scoria.prompt.template_ref` Semconv key.**
   - What we know: D-04c locks the registry key STRING (`"scoria.prompt.template_ref"`) and its class (`:id`), mirroring `prompt_context_key/0`'s existing naming convention (`semconv.ex:126-131`).
   - What's unclear: whether the accessor should be named `prompt_template_ref_key/0` (mirrors `prompt_context_key/0`) or something else.
   - Recommendation: use `prompt_template_ref_key/0` — it is the literal naming convention already established by the sibling `prompt_context_key/0` in the same module.

## Environment Availability

Not applicable — no external tools, services, or runtimes beyond what's already running in every other phase of this milestone (Postgres via `Ecto.Adapters.SQL.Sandbox`, the BEAM's own `:telemetry` application). No new environment dependency is introduced.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir; no version pin needed) |
| Config file | `test/test_helper.exs` (existing, unchanged) |
| Quick run command | `mix test test/scoria/observe/ test/scoria/eval/judge_runner_test.exs` |
| Full suite command | `mix test --warnings-as-errors` |

No dedicated `mix test.observe` alias exists yet in `mix.exs` (`aliases()` at line 111 defines `test.adoption`, `test.knowledge`, `test.connector`, etc. but no observe-scoped alias) — the quick-run command above is a plain directory-scoped `mix test` invocation, not a custom alias. Adding one is optional/discretionary, not required by this phase's success criteria.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVENT-02 (SC#1: identical redact) | An event's `attributes` sub-map is redacted through the same call site spans use; a deny-listed key inside event attributes comes back `[REDACTED]` | integration (real Postgres, real `Telemetry.attach/1`, `flush_now`) | `mix test test/scoria/observe/event_emit_test.exs -x` | ❌ Wave 0 — new file, model on `prompt_span_test.exs` |
| EVENT-02 (SC#1: single call site) | Exactly one `Redactor.redact(` token exists in `lib/scoria/observe/telemetry.ex` | unit (source-scan drift guard) | `mix test test/scoria/observe/telemetry_test.exs -x` (add describe block to existing file) | ✅ existing file, ❌ new test |
| EVENT-02 (SC#2: allow-list, direct path) | `emit_event(%{name: :unknown_thing, ...})` returns `{:error, :unknown_event}` and never reaches Buffer | unit | `mix test test/scoria/observe/event_emit_test.exs -x` | ❌ Wave 0 |
| EVENT-02 (SC#2: allow-list, raw-bus path) | `:telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{name: :unknown_thing, ...})` is rejected at the handler, never persisted | integration (real Postgres, real handler attach) | `mix test test/scoria/observe/event_emit_test.exs -x` | ❌ Wave 0 |
| EVENT-03 (SC#3: guardrail_triggered real emission) | A real `Guardrail.emit/1` call with `decision: "block"` (or `"escalate"`) produces a persisted `ai_span_events` row after flush | integration (real Postgres, real `Guardrail.emit/1`, `flush_now`) | `mix test test/scoria/observe/guardrail_event_test.exs -x` (new, or add to existing guardrail test file if one exists) | ❌ Wave 0 |
| EVENT-03 (SC#3: prompt_rendered real emission) | A real `JudgeRunner.build_judge_prompt_span/3` (or its caller) call produces a persisted `ai_span_events` row for `prompt_rendered` — NOT hand-synthesized | integration (real Postgres, real judge call path, `flush_now`) | `mix test test/scoria/eval/judge_runner_test.exs -x` | ✅ existing file (need to check contents; if absent, create) — ❌ new test |
| EVENT-03 (`user_feedback_received` no-emitter grep-guard) | No `lib/` file calls `emit_event` with `name: :user_feedback_received` | unit (source-scan) | `mix test test/scoria/observe/semconv_test.exs -x` (add describe block) | ✅ existing file, ❌ new test |
| SEC-01 (D-06: Bounds `:event` activation) | An oversized/denied event attribute key is bounded exactly as a span key is, end-to-end through the real handler | integration | `mix test test/scoria/observe/event_emit_test.exs -x` | ❌ Wave 0 (Bounds unit coverage for `:event` already exists at `bounds_test.exs:265-269` — this is the END-TO-END wiring proof, a different test) |
| D-01/D-05 (SC#4: orphan isolation) | 50 real spans + 1 real orphan event (span never flushed) → 50 spans persist, the orphan event row exists with its dangling `span_id`, no span exists for that id | integration (real Postgres, real Buffer, `flush_now`) | `mix test test/scoria/observe/buffer_test.exs -x` | ✅ existing file, ❌ new test |
| D-05 (fail-closed handler: nil span_id / missing time) | A raw-bus event with nil `span_id` or missing `time` is dropped at the handler and never reaches `insert_all`, while 50 good events land in the same batch | integration | `mix test test/scoria/observe/buffer_test.exs -x` (or `telemetry_test.exs`) | ✅ existing file, ❌ new test |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/observe/ test/scoria/eval/judge_runner_test.exs`
- **Per wave merge:** `mix test --warnings-as-errors`
- **Phase gate:** Full suite green before `/gsd-verify-work`, matching the project's existing CI gate convention (`mix compile --warnings-as-errors` then a scoped `mix test --no-start --warnings-as-errors` policy-contract run, per `.github/workflows/ci-verify.yml:51-56`).

### Wave 0 Gaps
- [ ] `test/scoria/observe/event_emit_test.exs` — new file, covers EVENT-02 SC#1 (redact integration + single-call-site drift guard), SC#2 (both allow-list bypass paths), and the SEC-01 Bounds `:event` end-to-end wiring proof. **Model directly on `test/scoria/observe/prompt_span_test.exs`'s scoped-Buffer + `Telemetry.attach/1` + `flush_now` setup** — do not hand-synthesize telemetry metadata.
- [ ] A guardrail-event integration test (either a new file or an addition to whatever the existing guardrail span test file is named — confirm exact path at plan time, was not directly located in this research pass under an obvious name) — covers EVENT-03's `guardrail_triggered` real-call-site proof.
- [ ] Additions to `test/scoria/eval/judge_runner_test.exs` (confirm this file exists and its current shape at plan time — not read in this research pass) — covers EVENT-03's `prompt_rendered` real-call-site proof, sourced from the judge, not hand-synthesized.
- [ ] Additions to `test/scoria/observe/buffer_test.exs` — covers SC#4 (50 spans + 1 orphan event persistence proof) and D-05's fail-closed nil-`span_id`/missing-`time` raw-bus test.
- [ ] Additions to `test/scoria/observe/semconv_test.exs` — covers the `user_feedback_received` zero-emitter grep-guard (D-04d) and the new `@event_names`/`event_name?/1` unit tests, following the exact anti-inline-grep template already at lines 128-142.
- [ ] Additions to `test/scoria/observe/telemetry_test.exs` — covers the scoped single-`Redactor.redact(` drift guard for `telemetry.ex` specifically.
- [ ] New migration file under `priv/repo/migrations/` — `ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey`, core-lane (not dev-only), following the `converge_eval_persistence.exs:117,144` precedent exactly.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | Not touched — this phase has no auth surface |
| V3 Session Management | no | Not touched |
| V4 Access Control | no | No new dashboard/LiveView read surface added (D-07 explicitly excludes operator UI) |
| V5 Input Validation | yes | `Semconv.event_name?/1` closed-vocabulary allow-list (defense-in-depth at both `emit_event/1` and the telemetry handler); `Bounds.enforce(_, :event)` closed-registry attribute admission (already built) |
| V6 Cryptography | no | Not touched |
| V7 Error Handling / Logging | yes | `try/rescue -> :ok` at every emit boundary (never surfaces to caller); `reject_event/2` fail-closed observability with once-per-name-per-node dedupe |
| V13 Malicious Input Handling | yes | Fail-closed handling of malformed raw-bus telemetry payloads (nil `span_id`, missing `time`, non-map metadata) — the handler drops rather than crashes or silently corrupts a batch |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Free-text leak via a judge's `explanation:` field reaching a durable event | Information Disclosure | Structural: the event fires at prompt-*render* time (before the judge produces `explanation:`) and the fixed-key attribute projection never reads `explanation:` regardless — both temporal and structural blocks, per D-04c |
| Raw-bus telemetry bypass of the public API's validation | Tampering / Elevation of Privilege (of the vocabulary) | The telemetry handler re-checks `Semconv.event_name?/1` independently — it is the boundary of record, not `emit_event/1` (D-03b) |
| Unbounded-memory DoS via an infinite orphan-event retry loop | Denial of Service | D-01b explicitly rejects bounded retry for this reason — persist-dangling, never retry, is chosen precisely to avoid this failure mode |
| A dropped/denied event attribute key silently corrupting an otherwise-good batch | Tampering (data integrity) | The FK drop + D-05a's fail-closed `time`/`span_id` defaulting-or-dropping at the handler boundary close every remaining raw `insert_all` raise class before the batch transaction begins |

## Sources

### Primary (HIGH confidence — direct codebase verification, this session)
- `lib/scoria/observe/buffer.ex`, `telemetry.ex`, `observe.ex`, `semconv.ex`, `guardrail.ex`, `bounds.ex`, `redactor.ex`, `reviewer_broadcast.ex` — read in full, 2026-07-18
- `lib/scoria/repo/span.ex`, `span_event.ex` — read in full, 2026-07-18
- `lib/scoria/eval/judge_runner.ex`, `lib/scoria/runtime.ex`, `lib/scoria/workflows/runtime.ex` — read in full, 2026-07-18
- `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `20260519000000_converge_eval_persistence.exs` — read in full, 2026-07-18
- `test/scoria/observe/prompt_span_test.exs`, `telemetry_test.exs`, `semconv_test.exs`, `bounds_test.exs` (grep + targeted read) — 2026-07-18
- `priv/repo/migrations/` directory listing (confirmed absence of `20260712210000_*`) — 2026-07-18
- `.planning/phases/53B-ai-span-events-emit-event-1/53B-CONTEXT.md` — the locked spec this research verifies against
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — project requirement/decision history

### Secondary (MEDIUM confidence)
- `.github/workflows/ci-verify.yml` (grep only) — confirms the project's `--warnings-as-errors` CI convention referenced in Validation Architecture

### Tertiary (LOW confidence)
- D-00b's OTel Span Events API deprecation claim (2026) — carried from CONTEXT.md, not independently re-verified via web search in this research pass (see Assumptions Log A1)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, pure application-code addition to an already-verified stack
- Architecture: HIGH — every pattern mirrors an existing, working sibling in the same module; all anchors independently re-verified line-by-line
- Pitfalls: HIGH — the Redactor drift-guard scoping pitfall was discovered by direct `grep` in this session, not inherited from CONTEXT.md
- Package legitimacy: N/A — no new packages

**Research date:** 2026-07-18
**Valid until:** Stable — 30 days (no fast-moving external dependency; the only external claim, D-00b's OTel note, is a forward-looking flag for a future phase, not load-bearing here)

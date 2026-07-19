---
phase: 53B-ai-span-events-emit-event-1
reviewed: 2026-07-18T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - lib/scoria/observe.ex
  - lib/scoria/observe/telemetry.ex
  - lib/scoria/observe/buffer.ex
  - lib/scoria/observe/semconv.ex
  - lib/scoria/observe/guardrail.ex
  - lib/scoria/eval/judge_runner.ex
  - priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs
  - CHANGELOG.md
  - test/scoria/observe/event_emit_test.exs
  - test/scoria/observe/telemetry_test.exs
  - test/scoria/observe/observe_test.exs
  - test/scoria/observe/buffer_test.exs
  - test/scoria/observe/semconv_test.exs
  - test/scoria/observe/guardrail_test.exs
  - test/scoria/eval/judge_runner_test.exs
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 53B: Code Review Report

**Reviewed:** 2026-07-18
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the AI span-event emission slice: the `emit_event/1` public API and its
raw-bus handler boundary, the two-phase Buffer flush (spans vs events in separate
transactions), the closed event-name allow-list, the fail-closed seam for the
`ai_span_events` NOT NULL columns, `Bounds.enforce(_, :event)`, and the FK-drop
migration.

The core architecture holds up well and I verified the five security-relevant
behaviors the phase calls out:

- **Single shared redaction call site** — confirmed exactly one `defp redact/1`
  in `telemetry.ex`, routed to by the span, delta, and event clauses.
- **Closed allow-list re-checked at the handler** — the event handler
  independently calls `Semconv.event_name?/1`; the raw-bus bypass is closed.
- **Orphan-event isolation** — `do_flush/2` runs `flush_spans` (Phase 1,
  `Ecto.Multi` txn) then `flush_events` (Phase 2, separate `insert_all` in its
  own `try/rescue`). Phase 1 commits before Phase 2 runs; an event failure
  cannot roll back committed spans. Correct.
- **`Bounds.enforce(_, :event)`** — wired identically to `:span`. Correct.

The one substantive defect is that the fail-closed seam guarding the NOT NULL
`time`/`span_id` columns only handles the `nil` case, not the equally-reachable
type-invalid case — and because all buffered events share one `insert_all`, a
single malformed event drops the entire co-flushed batch of good sibling events.
That directly undermines the D-05 "malformed raw-bus event cannot roll back a
batch of good siblings" guarantee, which the tests only prove for `nil`.

## Critical Issues

### CR-01: Fail-closed seam only guards `nil` — a type-invalid `time`/`span_id` poisons the entire event flush batch

**File:** `lib/scoria/observe/telemetry.ex:146-161`, `lib/scoria/observe/buffer.ex:217-232`

**Issue:**
The handler's fail-closed seam is `default_time/1` (replaces `nil`/absent time
with `DateTime.utc_now()`) + `reject_if_nil_span_id/2` (drops a `nil` span_id).
Both guard **only `nil`**. The comment at `telemetry.ex:84-91` claims these close
"the only two raise classes reachable via the raw bus," but a *non-nil,
type-invalid* value clears both seams:

- `default_time/1` — `case Map.get(metadata, :time) do nil -> ...; _time -> metadata end`.
  A `time` of `"2026-01-01"` (string) or `1737158400` (integer, e.g. from
  `System.system_time()`) passes through unchanged.
- `reject_if_nil_span_id/2` — only rejects `nil`. A `span_id` of `""` or
  `"not-a-uuid"` passes.

`Bounds.enforce/2` only touches the `attributes` sub-map, so the bad top-level
value survives to `buffer_event/2` and into `Buffer.cast_event/2`. At flush,
`flush_events/2` calls `Scoria.Repo.insert_all(Scoria.Repo.SpanEvent, ...)`,
which dumps each value against the schema types. `ai_span_events.time` is
`:utc_datetime_usec` and `span_id` is `:binary_id` (both `NOT NULL`, verified in
`20260510015813_create_ai_observability_tables.exs:41-43`). A non-`DateTime`
time or non-UUID span_id makes Ecto raise `Ecto.ChangeError` — and since **all
buffered events share one `insert_all` call**, that single malformed event aborts
the whole batch. The `rescue` in `flush_events/2` keeps the buffer alive and
spans are unaffected (separate txn), but **every otherwise-valid sibling event in
that flush is lost**.

This is reachable two ways, neither exotic:
1. Raw bus (`:telemetry.execute([:scoria, :observe, :event, :emit], ...)`) — the
   attack surface SC#2 exists to close.
2. The public `emit_event/1` itself, which performs **no type validation** on
   `time`/`span_id` (`observe.ex:450-459`). A buggy internal caller passing
   `time: DateTime.to_iso8601(...)` or an integer timestamp silently takes out
   the batch.

`event_emit_test.exs:240-296` proves the `nil`-span_id and missing-`time` cases
but never a type-invalid value, so the batch-isolation guarantee is asserted
narrower than it actually holds.

**Fix:** Coerce/validate at the seam so a malformed single event fails closed to
a per-event drop instead of poisoning the batch. For example, extend the seam to
validate types before Bounds:

```elixir
defp default_time(metadata) do
  case Map.get(metadata, :time) do
    %DateTime{} = t -> Map.put(metadata, :time, t)
    nil            -> Map.put(metadata, :time, DateTime.utc_now())
    _invalid       -> Map.put(metadata, :time, DateTime.utc_now())  # or {:reject, :bad_time}
  end
end

defp reject_if_nil_span_id(metadata, _name) do
  case Map.get(metadata, :span_id) do
    span_id when is_binary(span_id) ->
      case Ecto.UUID.cast(span_id) do
        {:ok, _} -> {:ok, metadata}
        :error   -> {:reject, :bad_span_id}
      end
    _ -> {:reject, :nil_span_id}
  end
end
```

Alternatively (defense in depth), have `flush_events/2` fall back to per-row
inserts on a batch `ChangeError` so one bad row cannot drop good siblings. Add a
regression test in `event_emit_test.exs` covering a type-invalid `time` and a
non-UUID `span_id` alongside a batch of good events.

## Warnings

### WR-01: ETS lazy-create race in the reject path can raise and detach the whole telemetry handler

**File:** `lib/scoria/observe/telemetry.ex:190-198`

**Issue:**
`ensure_rejected_warned_table/0` checks `:ets.whereis/1` and, if `:undefined`,
calls `:ets.new(@rejected_warned_table, [:named_table, ...])`. Under concurrent
first-time rejections (e.g. multiple processes emitting unknown-name events
before the table exists), two processes can both observe `:undefined` and both
call `:ets.new` with `:named_table`; the loser raises `ArgumentError` (table
already exists). The event `handle_event/4` clause is **not** wrapped in
`try/rescue`, so the raise propagates into `:telemetry.execute`, which detaches a
failing handler — silently disabling `scoria-observe-telemetry` for the node, so
all subsequent span AND event persistence stops. The window is narrow (first
rejection only) and mirrors the existing `Bounds`/`ReviewerBroadcast` idiom, but
this instance is newly introduced and sits on the reject path that fires for
every unknown-name raw-bus event.

**Fix:** Create the table eagerly in `attach/1` (or `Buffer.init/1`), or guard
the lazy create:

```elixir
defp ensure_rejected_warned_table do
  :ets.new(@rejected_warned_table, [:named_table, :set, :public, read_concurrency: true])
rescue
  ArgumentError -> :ok
end
```

### WR-02: `emit_event/1` never validates its own payload, so malformed values surface only downstream

**File:** `lib/scoria/observe.ex:449-459`

**Issue:**
`emit_event/1` is documented as a safe, never-raising DX signal, and it checks
only `Semconv.event_name?/1`. It performs no validation that `span_id` is a
well-formed id or that `time` is a `DateTime`. The result is that a caller
mistake (wrong-typed `time`/`span_id`) returns `:ok` synchronously and then
fails asynchronously in the flush batch (see CR-01), with no signal to the
caller. This is the public-API half of CR-01; even after CR-01's handler seam is
fixed, callers get silent per-event drops with no synchronous feedback.

**Fix:** Either validate `span_id`/`time` shape in `emit_event/1` and return a
distinct error tuple (e.g. `{:error, :invalid_event}`) for a member name with a
malformed payload, or document explicitly that shape validation is the handler's
responsibility and that malformed non-nil values are dropped. Prefer the former
for a "clean bus + synchronous DX signal" contract the moduledoc already claims.

### WR-03: `run_existing/2` dead fallback — `fetch!` defeats the `||` dataset lookup

**File:** `lib/scoria/eval/judge_runner.ex:53`

**Issue:**
`dataset = fetch!(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)`.
`fetch!/2` (`:284-289`) raises `ArgumentError` when the key is absent or `nil`,
so it never returns a falsy value — the `|| Eval.get_dataset!(eval_run.dataset_id)`
branch is unreachable dead code. `run_existing/2` therefore always *requires*
`:dataset` in `attrs` and can never fall back to loading it by
`eval_run.dataset_id`, contradicting the apparent intent of the fallback. (This
line is pre-existing, outside this phase's diff, but is a genuine logic defect in
a reviewed file.)

**Fix:** Use the optional `fetch/2` when a fallback is intended:

```elixir
dataset = fetch(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)
```

## Info

### IN-01: Non-`DateTime` `time` also weakens the D-05 test coverage claim

**File:** `test/scoria/observe/event_emit_test.exs:240-296`

**Issue:** The D-05 batch-isolation test only exercises `nil` span_id and
missing `time`. Adding a type-invalid `time` and a non-UUID `span_id` to the same
"50 good siblings" batch would have caught CR-01. Recommend extending this test
once CR-01 is fixed so the guarantee is proven at its real boundary, not just the
`nil` subset.

### IN-02: `emit_event/1` has a redundant guard

**File:** `lib/scoria/observe.ex:450`

**Issue:** `def emit_event(%{name: name} = event) when is_map(event)` — the
`%{name: name}` head already requires a map, so `when is_map(event)` is
redundant. Harmless; noted for cleanliness only.

---

_Reviewed: 2026-07-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

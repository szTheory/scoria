---
phase: 53B-ai-span-events-emit-event-1
fixed_at: 2026-07-18T20:31:06Z
review_path: .planning/phases/53B-ai-span-events-emit-event-1/53B-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 53B: Code Review Fix Report

**Fixed at:** 2026-07-18T20:31:06Z
**Source review:** .planning/phases/53B-ai-span-events-emit-event-1/53B-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (CR-01, WR-01, WR-02, WR-03)
- Fixed: 4
- Skipped: 0

**Test result:** `mix test test/scoria/observe/` (MIX_ENV=test, Postgres on port 55432):
`210 tests, 0 failures` (208 pre-existing + 2 new: a WR-01 concurrent-race
regression test in `telemetry_test.exs` and a WR-02 shape-validation
regression test in `observe_test.exs`; the CR-01 regression extended the
existing D-05 batch-isolation test in place rather than adding a new test).
`mix test test/scoria/eval/judge_runner_test.exs`: `4 tests, 0 failures`
(3 pre-existing + 1 new WR-03 regression test). Full combined run
(`test/scoria/observe/ test/scoria/eval/`): `290 tests, 0 failures`. Verified
non-flaky by rerunning the WR-01 race test and the WR-03 test 3x each.

## Fixed Issues

### CR-01: Fail-closed seam only guards `nil` — a type-invalid `time`/`span_id` poisons the entire event flush batch

**Files modified:** `lib/scoria/observe/telemetry.ex`, `test/scoria/observe/event_emit_test.exs`
**Commit:** `7bcf17f2`
**Applied fix:** `default_time/1` now matches on `%DateTime{}` explicitly —
anything that is not a real `DateTime` struct (string, integer, etc.) is
coerced to `DateTime.utc_now()`, closing the "type-invalid but non-nil"
gap the reviewer identified. `reject_if_nil_span_id/2` now additionally
runs `Ecto.UUID.cast/1` on any binary `span_id` and rejects (drops, per-event,
reason `:invalid_span_id`) anything that isn't UUID-castable or isn't a
binary at all, alongside the existing `nil` rejection (reason
`:nil_span_id`, unchanged for backward compatibility with existing
assertions). Both changes happen strictly before `Bounds.enforce/2` and
`Buffer.cast_event/2`, so a malformed value now fails closed per-event
instead of reaching `Repo.insert_all` and raising across the whole
co-flushed batch. Extended the existing D-05 batch-isolation test in
`event_emit_test.exs` with a type-invalid `time` (string) and a
non-UUID-castable `span_id` alongside the pre-existing nil-span_id /
missing-time cases and the 50-good-sibling batch (total persisted count
updated from 51 to 52 to reflect the new defaulted-time survivor).

### WR-01: ETS lazy-create race in the reject path can raise and detach the whole telemetry handler

**Files modified:** `lib/scoria/observe/telemetry.ex`, `test/scoria/observe/telemetry_test.exs`
**Commit:** `0eeebb02`
**Applied fix:** Wrapped `ensure_rejected_warned_table/0` in a
`rescue ArgumentError -> :ok` clause, matching the reviewer's suggested
fix exactly. This closes the window where two concurrent first-time
rejections both observe `:ets.whereis/1 == :undefined` and race to
`:ets.new/2` — the loser's `ArgumentError` is now swallowed instead of
propagating into `:telemetry.execute/3` and detaching
`scoria-observe-telemetry` for the whole node. Added a regression test
that deletes the rejected-warned ETS table (forcing every caller to
observe `:undefined`), fires 50 concurrent first-time rejections via
`Task.async`/`Task.await_many`, then proves the handler survived by
persisting a follow-up well-formed event through it.

### WR-02: `emit_event/1` never validates its own payload, so malformed values surface only downstream

**Files modified:** `lib/scoria/observe.ex`, `test/scoria/observe/observe_test.exs`
**Commit:** `677ed488`
**Applied fix:** Chose the reviewer's preferred option ("validate shape
and return a distinct error tuple") over the documentation-only
alternative, since it matches the moduledoc's existing "clean bus +
synchronous DX signal" claim. Added `valid_event_shape?/1` (private),
which requires `:span_id` to be a UUID-castable binary
(`Ecto.UUID.cast/1`) and `:time` to be a real `%DateTime{}`. `emit_event/1`
now checks event-name membership first (unchanged), then shape, returning
`{:error, :invalid_event}` for a member name with a malformed `span_id`/
`time` and firing no telemetry at all — giving the caller synchronous
feedback instead of a silent async drop at the CR-01 handler seam. All
production call sites (`guardrail.ex`, `judge_runner.ex`) already pass a
real `DateTime` and UUID `span_id`, so this is additive and did not
require any call-site changes. Added 3 regression assertions (invalid
time, invalid span_id, nil span_id) to the existing "emit_event/1
synchronous return contract" describe block in `observe_test.exs`.

### WR-03: `run_existing/2` dead fallback — `fetch!` defeats the `||` dataset lookup

**Files modified:** `lib/scoria/eval/judge_runner.ex`, `test/scoria/eval/judge_runner_test.exs`
**Commit:** `99dd5d44`
**Applied fix:** Changed `fetch!(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)`
to `fetch(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)`,
exactly as the reviewer suggested — `fetch/2` (the optional variant)
actually returns `nil` on a missing key, so the `||` fallback now fires
for real. Verified all 3 existing production call sites
(`lib/scoria/eval.ex:539`, `lib/scoria/eval/online_scoring.ex:323`,
`lib/scoria/eval/runner.ex:72`) already pass `:dataset` explicitly, so
this change is purely additive (activates previously-dead code) and does
not alter any existing caller's behavior. Added a regression test that
calls `run_existing/2` with `:dataset` omitted from `attrs` and confirms
it succeeds by loading the dataset via `eval_run.dataset_id`.

## Skipped Issues

None — all 4 in-scope findings (CR-01, WR-01, WR-02, WR-03) were fixed.

Note: IN-01 and IN-02 (Info-tier) were out of scope for this run
(`fix_scope: critical_warning`) and were not touched. IN-01 is
substantially addressed as a side effect of the CR-01 test extension
(the D-05 test now covers the type-invalid case IN-01 called out), but
IN-02 (`emit_event/1`'s redundant `is_map(event)` guard) remains
unaddressed and available for a future `--fix` pass with
`fix_scope: all`.

---

_Fixed: 2026-07-18T20:31:06Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

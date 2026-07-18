---
phase: 53B-ai-span-events-emit-event-1
verified: 2026-07-18T20:10:48Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The fail-closed seam at the [:scoria, :observe, :event, :emit] handler closes the only two NOT NULL raise classes reachable via the raw bus (time, span_id), so a malformed event can never poison the batch of good sibling events (D-05a, Plan 03 must_have)."
    status: failed
    reason: "default_time/1 and reject_if_nil_span_id/2 guard ONLY the nil/absent case. A non-nil, type-invalid value (e.g. time: \"2026-01-01\" or time: 1737158400, or span_id: \"not-a-uuid\") passes both seams unchanged, survives Bounds.enforce/2 (which only touches :attributes), and reaches Buffer.cast_event/2 -> flush_events/2's single Repo.insert_all(SpanEvent, event_entries) call. Ecto dumps all entries against the schema types (time: :utc_datetime_usec, span_id: :binary_id, both NOT NULL per ai_span_events schema) before issuing SQL; a single bad value raises Ecto.ChangeError before the query executes, and flush_events/2's rescue catches it -- but ALL events buffered in that flush (potentially dozens of good siblings) are lost, not just the malformed one. This is reachable via (a) the raw telemetry bus -- the exact SC#2 attack surface this phase closes for the *name* dimension but not for time/span_id -- and (b) emit_event/1 itself, which performs zero type validation on its payload (WR-02, observe.ex:450-459), so a buggy internal Scoria caller can silently take out a batch with no synchronous signal."
    artifacts:
      - path: "lib/scoria/observe/telemetry.ex"
        issue: "default_time/1 (lines ~146-151) and reject_if_nil_span_id/2 (lines ~156-161) only pattern-match on nil; no type/shape validation for time (%DateTime{}) or span_id (well-formed UUID string)."
      - path: "lib/scoria/observe/buffer.ex"
        issue: "flush_events/2 (lines ~217-254) uses one Repo.insert_all for the whole events list with no per-row isolation/fallback -- one Ecto.ChangeError from a bad entry drops the entire buffered batch."
      - path: "test/scoria/observe/event_emit_test.exs"
        issue: "The D-05 fail-closed test (lines 240-296) only exercises nil span_id and missing/nil time -- never a type-invalid non-nil value -- so the batch-isolation guarantee is asserted narrower than the Plan 03 must_have literally claims (\"the only two ... raise classes ... are closed\")."
    missing:
      - "Type-validate time (must be %DateTime{}) and span_id (must Ecto.UUID.cast/1 successfully) at the handler seam, rejecting (not defaulting) a type-invalid value the same way a nil is rejected today -- per the code review's CR-01 proposed fix."
      - "Optionally, defense in depth: have flush_events/2 fall back to per-row inserts on a batch Ecto.ChangeError so one bad row cannot drop good siblings even if a new raise class is later introduced."
      - "A regression test in event_emit_test.exs covering a type-invalid time and a non-UUID span_id inside a batch of 50 good sibling events (mirrors the existing nil/missing-time test structure)."
---

# Phase 53B: `ai_span_events` + `emit_event/1` Verification Report

**Phase Goal:** The three reserved point-events can be emitted through a redaction-safe, allow-listed event path that cannot lose a batch of good spans, and two of them fire from real call sites during normal operation.
**Verified:** 2026-07-18T20:10:48Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria — literal contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC#1 — `emit_event/1` for an allow-listed name produces a persisted `ai_span_events` row whose attributes passed through the identical `Redactor.redact/1` call site spans use; a deny-listed key comes back `[REDACTED]` | ✓ VERIFIED | `lib/scoria/observe/telemetry.ex:141` — one `defp redact(metadata), do: Redactor.redact(metadata)` shared by span (`:69`), delta (`:57-61`), and event (`:99`) clauses. `test/scoria/observe/event_emit_test.exs` "SC#1" test (lines 84-116) drives the real `emit_event/1` → handler → `flush_now` → Repo readback and asserts `event.attributes["session_id"] == "[REDACTED]"` while `template_ref` survives. Independently re-ran: `mix test test/scoria/observe/event_emit_test.exs` → 6 tests, 0 failures. |
| 2 | SC#2 — an unknown event name is rejected/never persisted, including via a raw `:telemetry.execute` on the public bus; vocabulary cannot silently grow | ✓ VERIFIED | Direct path: `emit_event/1` returns `{:error, :unknown_event}` and executes no telemetry for a non-member (`lib/scoria/observe.ex:450-459`). Raw-bus path: the `:event` handler (`telemetry.ex:92-115`) independently re-checks `Semconv.event_name?(name)` and calls `reject_event/2` (never reaches `Buffer.cast_event`/insert_all) for an unknown name, emitting `[:scoria, :observe, :event, :rejected]` unconditionally. Both proven in `event_emit_test.exs` "SC#2" describe block (lines 119-166) — direct path asserts zero persisted rows; raw-bus path hand-synthesizes `:telemetry.execute` (the one legitimate bypass-attack-surface exception) and asserts zero rows + the `:rejected` telemetry firing. `Semconv.@event_names` (`semconv.ex:277`) is a closed, hardcoded 3-atom list; `event_name?/1` is membership-only, never `String.to_atom` on inbound data. |
| 3 | SC#3 — `prompt_rendered` and `guardrail_triggered` are emitted from real call sites during normal operation; `user_feedback_received` stays reserved-only | ✓ VERIFIED | `guardrail.ex:187-201` `maybe_emit_guardrail_triggered/3` calls `Observe.emit_event(%{name: :guardrail_triggered, ...})` inside `do_emit/1`, gated `decision not in [nil, "allow"]` — inherited for free by all 5 existing `Guardrail.emit/1` callers with zero caller-file edits (confirmed `runtime.ex`/`workflows/runtime.ex` untouched by this phase's commits). `judge_runner.ex:198-226` `build_judge_prompt_span/4` emits `prompt_rendered` immediately after `with_prompt/3` returns successfully (emit-after-success — a raised render never reaches the emit line). Real-call-site proofs: `test/scoria/observe/guardrail_test.exs` "Task 3 (SC#3)" (lines 357-396) drive real `Guardrail.emit/1` with block/escalate → persisted event; allow → no event. `test/scoria/eval/judge_runner_test.exs:128-159` drives a real judge render → persisted `prompt_rendered` with `template_ref` set and an explicit `refute encoded =~ @distinctive_explanation` no-leak assertion. `user_feedback_received` has zero `lib/` emitters, locked by a grep-guard test (`semconv_test.exs:484-499`). |
| 4 | SC#4 — an event whose span has not flushed (or was dropped) can never take down a batch of good spans; proven by 50 valid spans + 1 orphan event losing nothing | ✓ VERIFIED | Structural guarantee: `Buffer.do_flush/2` (`buffer.ex:102-134`) runs `flush_spans/2` (Phase 1, the unchanged traces→spans `Ecto.Multi`, its own `try/rescue`) then `flush_events/2` (Phase 2, a SEPARATE `Repo.insert_all` in its own `try/rescue`) unconditionally after Phase 1 — Phase 1's spans are already committed in their own transaction before Phase 2 ever runs, so nothing in Phase 2 (however it fails) can roll back a span. The DB-level FK on `ai_span_events.span_id` was also dropped (`priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs`), so a dangling `span_id` is insertable rather than a Postgrex 23503 raise. `event_emit_test.exs` "SC#4" test (lines 200-237) drives 50 real `with_tool` spans + 1 real orphan `emit_event/1` whose `span_id` was never emitted, asserts exactly 50 `ai_spans` rows, the orphan `ai_span_events` row EXISTS with its dangling `span_id`, and no span exists for that id. Independently re-ran and confirmed green. **Note:** this SC is literally about spans surviving an event-side failure, which the two-phase separate-transaction design guarantees unconditionally regardless of CR-01 below — CR-01 concerns a *sibling-events* batch-loss scenario, a distinct (and real) gap from this SC's literal wording. |

**Score (ROADMAP SCs only):** 4/4 verified.

### Additional Plan-Level Must-Have (merged from PLAN frontmatter, Step 2c)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 5 | Plan 03 D-05a — "the fail-closed seam ... the only two NOT NULL raise classes reachable via the raw bus are closed at the handler" | ✗ **FAILED** | Independently confirmed in the code (not just trusting 53B-REVIEW.md's CR-01 claim): `default_time/1` (`telemetry.ex:146-151`) and `reject_if_nil_span_id/2` (`telemetry.ex:156-161`) both branch on `nil` only. A non-nil, type-invalid `time` (string/integer) or `span_id` (non-UUID string) passes both seams unchanged. `Bounds.enforce/2` only touches `:attributes`, not top-level `time`/`span_id`. `Scoria.Repo.SpanEvent`'s schema (`lib/scoria/repo/span_event.ex`) types `time: :utc_datetime_usec` and `span_id: :binary_id`, both `NOT NULL`. `Buffer.flush_events/2` (`buffer.ex:217-254`) does ONE `Repo.insert_all(Scoria.Repo.SpanEvent, event_entries)` for the whole batch — Ecto dumps every entry against schema types before issuing SQL, so one type-invalid entry raises `Ecto.ChangeError` and the `rescue` there loses **every event in that flush**, not just the offending one. Reachable via the raw bus (the exact bypass SC#2 closes for `name` but not for `time`/`span_id`) and via `emit_event/1` itself, which does no payload-shape validation (WR-02). `event_emit_test.exs`'s D-05 test (lines 240-296) only covers nil-span_id/missing-time, never a type-invalid value, so it does not exercise this gap. |

**Combined score:** 4/5 must-haves verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs` | Core-lane FK-drop, span_id stays NOT NULL + indexed | ✓ VERIFIED | `up` drops `ai_span_events_span_id_fkey`; `down` re-adds it; column untouched. |
| `lib/scoria/observe/semconv.ex` `@event_names`/`event_names/0`/`event_name?/1` | Closed 3-atom vocabulary | ✓ VERIFIED | `:277-299`; membership-only, atoms not strings. |
| `lib/scoria/observe/semconv.ex` `prompt_template_ref_key/0` | `"scoria.prompt.template_ref"`, class `:id` | ✓ VERIFIED | `:133-143`, registered in `@attribute_registry` (`:323`). |
| `lib/scoria/observe/buffer.ex` events list + two-phase flush | Independent cap/counter, ordered flush_spans→flush_events | ✓ VERIFIED | `:44-46`, `:65-72`, `:102-134`, `:215-254`. |
| `lib/scoria/observe.ex` `emit_event/1` | Public, allow-list-gated, never-raises | ✓ VERIFIED | `:449-466`, wrapped `rescue _ -> :ok`, catch-all clause for malformed input. |
| `lib/scoria/observe/telemetry.ex` `:event` handler | Boundary of record: re-check, redact, fail-closed seam, Bounds, cast | ⚠️ VERIFIED WITH GAP | Wired exactly as designed (`:92-115`), but the fail-closed seam is incomplete per the FAILED must-have above (CR-01). |
| `lib/scoria/observe/guardrail.ex` guardrail_triggered emission | Real call site, gated to actual intervention | ✓ VERIFIED | `:173-201`. |
| `lib/scoria/eval/judge_runner.ex` prompt_rendered emission | Real call site, emit-after-success | ✓ VERIFIED | `:198-226`. |
| `test/scoria/observe/event_emit_test.exs` | SC canary suite | ✓ VERIFIED (green) | Re-ran independently: 6 tests, 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `Scoria.Observe.emit_event/1` | `[:scoria, :observe, :event, :emit]` handler | `:telemetry.execute/3` | ✓ WIRED | `observe.ex:452`; handler subscribed via `@events` (`telemetry.ex:10-14`). |
| `:event` handler | `Buffer.cast_event/2` | `buffer_event/1` fixed-key projection | ✓ WIRED | `telemetry.ex:108`, `:123-136`. |
| `Buffer.do_flush/2` | Postgres `ai_span_events` | `flush_events/2` → `Repo.insert_all` | ✓ WIRED (but see FAILED must-have — single insert_all is an all-or-nothing batch boundary) | `buffer.ex:217-254`. |
| `Guardrail.do_emit` | `Observe.emit_event/1` | `maybe_emit_guardrail_triggered/3` | ✓ WIRED | `guardrail.ex:175`, `:187-201`. |
| `judge_runner.build_judge_prompt_span/4` | `Observe.emit_event/1` | inline post-`with_prompt/3` call | ✓ WIRED | `judge_runner.ex:218-223`. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|--------------|--------|----------|
| EVENT-02 | 53B-01, 53B-02, 53B-03 | `ai_span_events` wired via `emit_event/1` + telemetry clause through the identical redact call site; ordered Buffer flush; allow-listed vocabulary | ⚠️ SATISFIED WITH A FLAGGED DEFECT | Structurally complete and tested (SC#1/SC#2/SC#4 all pass), but the underlying fail-closed seam this requirement's own design (D-05a) claims is complete is not — see FAILED must-have above. REQUIREMENTS.md and ROADMAP.md both still show EVENT-02 as `[ ]`/Pending, which is expected (verification precedes the checkbox flip), not itself a gap. |
| EVENT-03 | 53B-04 | `prompt_rendered`/`guardrail_triggered` emitted from real call sites | ✓ SATISFIED | Confirmed above; REQUIREMENTS.md already shows `[x]` Complete. |

No orphaned requirements found for this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/scoria/observe/telemetry.ex` | 146-161 | Fail-closed seam guards `nil` only, not type-invalid non-nil values | 🛑 Blocker (CR-01, independently confirmed) | A single malformed event (reachable via raw bus or a buggy internal caller) can drop an entire batch of good sibling events at flush time. |
| `lib/scoria/observe/telemetry.ex` | 190-198 | `ensure_rejected_warned_table/0` lazy `:ets.new` under `:named_table` has a TOCTOU race on first concurrent rejection — the loser raises `ArgumentError`, uncaught in `handle_event/4`, which `:telemetry.execute` will treat as a failing handler and detach `"scoria-observe-telemetry"` node-wide | ⚠️ Warning (WR-01 from code review, confirmed present in current code) | Narrow window (first unknown-name rejection only), but blast radius is total — silently disables all span AND event persistence for the node if hit. Not part of this phase's stated success criteria; flagged for follow-up. |
| `lib/scoria/observe.ex` | 449-459 | `emit_event/1` performs no shape validation on `time`/`span_id` | ℹ️ Info (WR-02, the public-API half of CR-01) | Malformed internal caller input returns `:ok` synchronously and fails silently downstream at flush. |
| `lib/scoria/eval/judge_runner.ex` | 53 | `fetch!(attrs, :dataset) || Eval.get_dataset!(...)` — `fetch!/2` raises so the `||` fallback is dead code | ℹ️ Info (WR-03, pre-existing, outside this phase's diff) | Not caused by this phase; noted for completeness only. |

No `TBD`/`FIXME`/`XXX` debt markers found in the phase's modified files.

### Behavioral Spot-Checks / Test Evidence

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full canary suite | `mix test test/scoria/observe/event_emit_test.exs` (re-run independently) | 6 tests, 0 failures | ✓ PASS |
| Compile cleanliness | `mix compile --warnings-as-errors` (per orchestrator-provided evidence) | clean | ✓ PASS |
| Observe domain suite | `mix test test/scoria/observe/` (per orchestrator-provided evidence) | 208 tests, 0 failures | ✓ PASS |
| Full suite | `mix test` (per orchestrator-provided evidence, not re-run here per instructions) | 1312 tests, 1 pre-existing unrelated flake (`WarningInventory.CaptureParityTest`, SEED-004, confirmed green in isolation, zero lib/ diff from this phase) | ✓ PASS (not a 53B regression) |

### Human Verification Required

None. All findings above are resolvable by direct code inspection and existing/newly-run automated tests; nothing here requires subjective human judgment (visual, UX, or external-service behavior).

### Gaps Summary

The four literal ROADMAP success criteria for Phase 53B are all genuinely achieved and independently re-verified against the real codebase and a re-run of the canary suite — redaction is proven identical to the span path, the closed vocabulary rejects both the direct and raw-bus unknown-name paths, `prompt_rendered`/`guardrail_triggered` fire from real production call sites with `user_feedback_received` structurally locked out, and the two-phase separate-transaction flush design (plus the FK drop) guarantees an event-side failure can never roll back already-committed spans.

However, an independent re-read of `lib/scoria/observe/telemetry.ex` and `lib/scoria/observe/buffer.ex` confirms the code review's CR-01 finding is real and unfixed: the fail-closed seam that Plan 03's own must_have literally claims closes "the only two NOT NULL raise classes reachable via the raw bus" only guards the `nil` case. A non-nil, type-invalid `time` or `span_id` clears both seams, survives `Bounds.enforce/2` (which never touches those top-level fields), and reaches a single shared `Repo.insert_all` for the whole events batch — so one malformed event (via the raw bus, or via any internal Scoria caller of `emit_event/1`, which does zero payload validation) can silently drop every other good event queued in that same flush. This is a distinct failure mode from SC#4 (which is about spans, and is fully protected by the two-phase transaction separation regardless of this defect) — but it directly undermines the D-05 "cannot roll back a batch of good siblings" guarantee this phase's own Plan 03/05 explicitly set out to prove, and the existing test only proves the guarantee for the narrower nil/missing subset.

**Recommended fix** (per the code review's CR-01 remediation, not yet applied): extend `default_time/1` to reject (not silently pass through) a non-`DateTime` value, and extend `reject_if_nil_span_id/2` to `Ecto.UUID.cast/1`-validate a non-nil `span_id`, treating a cast failure the same as `nil` (reject before Bounds). Add a regression test in `event_emit_test.exs` covering a type-invalid `time` and a non-UUID `span_id` alongside a batch of 50 good sibling events, mirroring the existing D-05 test structure.

This looks like an unintentional gap (a genuine correctness bug, not a documented alternative design), so no override is suggested. Closing CR-01 is a small, well-scoped fix; recommend a fast follow-up plan before this phase's ROADMAP checkbox is flipped to complete.

---

_Verified: 2026-07-18T20:10:48Z_
_Verifier: Claude (gsd-verifier)_

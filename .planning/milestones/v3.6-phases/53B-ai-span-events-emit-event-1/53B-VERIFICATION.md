---
phase: 53B-ai-span-events-emit-event-1
verified: 2026-07-18T21:05:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Plan 03 D-05a — the fail-closed seam at the [:scoria, :observe, :event, :emit] handler now closes BOTH the nil raise class AND the type-invalid (non-nil) raise class for `time` and `span_id`, so a malformed event can never poison a batch of good sibling events."
  gaps_remaining: []
  regressions: []
---

# Phase 53B: `ai_span_events` + `emit_event/1` Verification Report (Re-Verification)

**Phase Goal:** The three reserved point-events can be emitted through a redaction-safe, allow-listed event path that cannot lose a batch of good spans, and two of them fire from real call sites during normal operation.
**Verified:** 2026-07-18T21:05:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commit `7bcf17f2`, CR-01 fix)

## What Changed Since Last Verification

The prior run (2026-07-18T20:10:48Z, `status: gaps_found`, 4/5) found one real gap: `default_time/1` and `reject_if_nil_span_id/2` in `lib/scoria/observe/telemetry.ex` guarded only the `nil` case, leaving a non-nil, type-invalid `time` (e.g. a string/integer) or `span_id` (e.g. a non-UUID string) able to clear the fail-closed seam, survive `Bounds.enforce/2` (which never touches those top-level fields), and reach `Buffer.flush_events/2`'s single shared `Repo.insert_all` — where Ecto's schema-type dump would raise `Ecto.ChangeError` and the batch's `rescue` would drop every event in that flush, not just the malformed one.

A fix pass (53B-REVIEW-FIX.md, commit `7bcf17f2`) closed this (CR-01) plus three lower-severity findings (WR-01 ETS race, WR-02 `emit_event/1` payload validation, WR-03 dead fallback in `judge_runner.ex`). This re-verification independently re-reads the fixed code (not the fix report's narrative) and re-confirms all four ROADMAP success criteria plus the Plan 03 must-have.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria — literal contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC#1 — `emit_event/1` for an allow-listed name produces a persisted `ai_span_events` row whose attributes passed through the identical `Redactor.redact/1` call site spans use; a deny-listed key comes back `[REDACTED]` | ✓ VERIFIED | `lib/scoria/observe/telemetry.ex:144` — one `defp redact(metadata), do: Redactor.redact(metadata)` shared by span (`:69`), delta (`:59`), and event (`:102`) clauses. Confirmed by direct grep: `grep -c "Redactor.redact(" telemetry.ex` → `1`. `test/scoria/observe/event_emit_test.exs` "SC#1" test (lines 84-116) drives real `emit_event/1` → handler → `flush_now` → Repo readback, asserting `event.attributes["session_id"] == "[REDACTED]"` while `template_ref` survives. Independently re-ran: `mix test test/scoria/observe/event_emit_test.exs` → 6 tests, 0 failures. |
| 2 | SC#2 — an unknown event name is rejected/never persisted, including via a raw `:telemetry.execute` on the public bus; vocabulary cannot silently grow | ✓ VERIFIED | Direct path: `emit_event/1` returns `{:error, :unknown_event}` for a non-member and executes no telemetry (`lib/scoria/observe.ex:459-473`). Raw-bus path: the `:event` handler (`telemetry.ex:95-118`) independently re-checks `Semconv.event_name?(name)` and calls `reject_event(name, :unknown_name)` (never reaches `Buffer.cast_event`/insert_all) for an unknown name. Proven in `event_emit_test.exs` "SC#2" describe block — direct path asserts zero persisted rows; raw-bus path hand-synthesizes `:telemetry.execute` and asserts zero rows + the `:rejected` telemetry firing with `reason: :unknown_name`. Re-ran green. |
| 3 | SC#3 — `prompt_rendered` and `guardrail_triggered` are emitted from real call sites during normal operation; `user_feedback_received` stays reserved-only | ✓ VERIFIED | Unchanged since prior verification (not touched by the fix pass). `guardrail.ex:187-201` `maybe_emit_guardrail_triggered/3` calls `Observe.emit_event/1` inside `do_emit/1`. `judge_runner.ex:198-226` `build_judge_prompt_span/4` emits `prompt_rendered` after a successful `with_prompt/3`. `user_feedback_received` has zero `lib/` emitters (grep-guard test in `semconv_test.exs`). |
| 4 | SC#4 — an event whose span has not flushed (or was dropped) can never take down a batch of good spans; proven by 50 valid spans + 1 orphan event losing nothing | ✓ VERIFIED | `Buffer.do_flush/2` (`buffer.ex:102-134`) runs `flush_spans/2` then `flush_events/2` — a SEPARATE `Repo.insert_all` in its own `try/rescue` — unconditionally after Phase 1's spans are already committed. The FK on `ai_span_events.span_id` was dropped in an earlier plan. `event_emit_test.exs` "SC#4" test (lines 200-237) drives 50 real `with_tool` spans + 1 real orphan `emit_event/1`, asserts exactly 50 `ai_spans` rows and the orphan event row exists with its dangling `span_id`. Re-ran green. |

**Score (ROADMAP SCs only):** 4/4 verified.

### Additional Plan-Level Must-Have (merged from PLAN frontmatter, Step 2c) — RE-VERIFIED

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 5 | Plan 03 D-05a — "the fail-closed seam ... the only two NOT NULL raise classes reachable via the raw bus are closed at the handler" | ✓ **VERIFIED (gap closed)** | Independently re-read `lib/scoria/observe/telemetry.ex` directly (not the fix report's claim). `default_time/1` (`:152-157`) now pattern-matches explicitly on `%DateTime{} = time`; ANY other value (`nil`, a string, an integer) falls to the `_invalid` clause and is coerced to `DateTime.utc_now()` — a type-invalid `time` can no longer reach `insert_all` unchanged. `reject_if_nil_span_id/2` (`:166-180`) now branches three ways: `nil` → `{:reject, :nil_span_id}`; a binary → `Ecto.UUID.cast/1`, rejecting with `{:reject, :invalid_span_id}` on cast failure; any non-binary → `{:reject, :invalid_span_id}`. Both checks run strictly before `Bounds.enforce/2` and `Buffer.cast_event/2` (confirmed by reading the handler's pipe chain at `:100-118`), so a type-invalid `span_id` is now dropped per-event instead of reaching the shared `Repo.insert_all(SpanEvent, event_entries)` in `buffer.ex:217-254` and raising `Ecto.ChangeError` across the whole batch. This closes the exact raise classes the prior gap identified. Regression coverage: `event_emit_test.exs`'s D-05 test (lines 240-328) now includes, alongside the pre-existing nil-span_id/missing-time cases and 50 good siblings, a type-invalid `time: "2026-01-01"` (asserted to persist with a real `%DateTime{}`, coerced) and a non-UUID `span_id: "not-a-uuid"` (asserted absent from the final count) — total persisted count asserted at exactly 52, proving the batch was never rolled back. Independently re-ran `mix test test/scoria/observe/event_emit_test.exs` → 6 tests, 0 failures (fresh run, not reused from the fix report). |

**Combined score:** 5/5 must-haves verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/observe/telemetry.ex` `default_time/1` | Coerces any non-`%DateTime{}` (nil, string, int) to `DateTime.utc_now()` | ✓ VERIFIED | `:152-157`, explicit `%DateTime{} = time ->` match with a catch-all `_invalid ->` default clause. |
| `lib/scoria/observe/telemetry.ex` `reject_if_nil_span_id/2` | Rejects nil AND non-UUID-castable span_id with distinct reasons | ✓ VERIFIED | `:166-180`, `nil` → `:nil_span_id`; non-castable/non-binary → `:invalid_span_id`. |
| `lib/scoria/observe.ex` `emit_event/1` shape validation (WR-02, defense in depth) | Public API rejects malformed `span_id`/`time` synchronously | ✓ VERIFIED | `:458-501`, `valid_event_shape?/1` + `valid_span_id?/1` + `valid_time?/1`; returns `{:error, :invalid_event}` before touching the bus. |
| `test/scoria/observe/event_emit_test.exs` | D-05 regression covers type-invalid time + non-UUID span_id in a 50-sibling batch | ✓ VERIFIED | Lines 281-326; exact count assertion (52) proves no batch loss. |
| All four ROADMAP SC artifacts (redaction, allow-list, real call sites, two-phase flush) | Unchanged, previously verified | ✓ VERIFIED (regression check) | No diff to `guardrail.ex`/`judge_runner.ex`/`semconv.ex`/`buffer.ex`'s two-phase structure in the fix commit; `git show 7bcf17f2 --stat` scope confirmed limited to `telemetry.ex` + test files (CR-01 hunk) plus the separately-committed WR-01/02/03 hunks in `observe.ex`/`judge_runner.ex`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `:event` handler fail-closed seam | `Buffer.cast_event/2` | `default_time/1` → `reject_if_nil_span_id/2` → `Bounds.enforce/2` → `buffer_event/1` | ✓ WIRED, now closed | `telemetry.ex:100-118` — confirmed the seam order runs strictly before `Bounds.enforce(_, :event)`, so a type-invalid entry never reaches `Buffer.flush_events/2`'s shared `insert_all`. |
| `Buffer.do_flush/2` | Postgres `ai_span_events` | `flush_events/2` → `Repo.insert_all` | ✓ WIRED, now safe | `buffer.ex:217-254` — this call site itself is unchanged (still one batched `insert_all`, no per-row savepoints), but it is now safe because the handler-level type seam prevents a malformed row from ever reaching it (per the comment at `buffer.ex:210-214`, which explicitly cites "Plan 03's fail-closed handler seam make[s] the remaining raise classes unreachable"). |
| `Scoria.Observe.emit_event/1` | `valid_event_shape?/1` | direct call inline in `cond` | ✓ WIRED (defense in depth, WR-02) | `observe.ex:459-473` — a malformed internal caller now gets a synchronous `{:error, :invalid_event}` instead of a silent async drop; this is additive to (not a replacement for) the handler-level seam, since the handler must still independently re-check for the raw-bus bypass. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|--------------|--------|----------|
| EVENT-02 | 53B-01, 53B-02, 53B-03 | `ai_span_events` wired via `emit_event/1` + telemetry clause through the identical redact call site; ordered Buffer flush; allow-listed vocabulary; fail-closed batch atomicity | ✓ SATISFIED | All four ROADMAP SCs verified plus the previously-flagged Plan 03 D-05a must-have is now closed. REQUIREMENTS.md still shows EVENT-02 as `[ ]` Pending — expected, since the checkbox flip follows verification, not the reverse. |
| EVENT-03 | 53B-04 | `prompt_rendered`/`guardrail_triggered` emitted from real call sites | ✓ SATISFIED | Confirmed above (unchanged); REQUIREMENTS.md already shows `[x]` Complete. |

No orphaned requirements found for this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | The CR-01 blocker from the prior verification is resolved; no new blockers introduced by the fix. | — | — |
| `lib/scoria/eval/judge_runner.ex` | ~53 | WR-03 dead-fallback fix applied (`fetch!` → `fetch`) | ℹ️ Info (resolved) | Previously-dead `||` fallback is now live; regression test added. Not a remaining concern. |

No `TBD`/`FIXME`/`XXX` debt markers found in the phase's modified files (`telemetry.ex`, `observe.ex`, `buffer.ex`, `judge_runner.ex`, test files).

### Behavioral Spot-Checks / Test Evidence

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| CR-01 regression (type-invalid time + non-UUID span_id inside a 50-sibling batch) | `mix test test/scoria/observe/event_emit_test.exs` (independently re-run in this session, not reused from the fix report) | 6 tests, 0 failures | ✓ PASS |
| Single-redact-site drift guard | `grep -c "Redactor.redact(" lib/scoria/observe/telemetry.ex` (re-run in this session) | `1` | ✓ PASS |
| Compile cleanliness | `mix compile --warnings-as-errors` (re-run in this session) | clean, no output | ✓ PASS |
| Observe domain suite | `mix test test/scoria/observe/` (per orchestrator-provided evidence, not re-run here per task instructions) | 210 tests, 0 failures | ✓ PASS |
| Eval domain suite | `mix test test/scoria/eval/` (per orchestrator-provided evidence) | 80 tests, 0 failures | ✓ PASS |
| Full suite | `mix test` (per orchestrator-provided evidence, not re-run here per instructions) | 1 pre-existing unrelated flake (`CaptureParityTest`, confirmed green in isolation) | ✓ PASS (not a 53B regression) |

### Human Verification Required

None. All findings are resolvable by direct code inspection and automated tests; nothing here requires subjective human judgment.

### Gaps Summary

No gaps remain. The single gap from the prior verification (Plan 03's D-05a must-have — "the only two NOT NULL raise classes reachable via the raw bus are closed at the handler") is now genuinely closed, confirmed by independently reading the fixed source (not trusting 53B-REVIEW-FIX.md's narrative):

- `default_time/1` now defaults BOTH the nil/missing case AND any type-invalid non-`%DateTime{}` value.
- `reject_if_nil_span_id/2` now rejects BOTH the nil case AND any non-UUID-castable or non-binary `span_id`, via the same `Ecto.UUID.cast/1` well-formedness check the `:binary_id` column type implies.
- Both seams run strictly before `Bounds.enforce/2` and `Buffer.cast_event/2`, so no type-invalid value from either field can reach `Buffer.flush_events/2`'s single shared `Repo.insert_all` and raise `Ecto.ChangeError` across the whole co-flushed batch.
- A fresh regression test in `event_emit_test.exs`'s D-05 describe block exercises both new cases inside the same 50-good-sibling batch structure the original test used, with an exact-count assertion (52) proving no batch loss.
- Independently re-ran the canary suite in this session (not reusing the fix report's claimed results) — 6 tests, 0 failures.

All four ROADMAP success criteria remain independently verified (SC#1 redaction identity, SC#2 allow-list including the raw-bus bypass, SC#3 real call sites with `user_feedback_received` locked out, SC#4 two-phase transaction isolation), and the previously-flagged Plan 03 must-have now also holds. Phase goal achieved.

---

_Verified: 2026-07-18T21:05:00Z_
_Verifier: Claude (gsd-verifier)_

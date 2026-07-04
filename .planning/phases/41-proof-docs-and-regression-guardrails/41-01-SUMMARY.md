---
phase: 41-proof-docs-and-regression-guardrails
plan: 01
subsystem: ui
tags: [liveview, phoenix, a11y, regression-testing, tdd]

# Dependency graph
requires:
  - phase: 39-component-groups-and-operator-flows
    provides: review_queue_live.ex and release_workbench_live.ex as built (bugs surfaced but not fixed)
  - phase: 40-accessibility-motion-and-responsive-proof
    provides: a11y_structural_guard_test.exs source-scan guard suite
provides:
  - "CR-01(39-review): review_queue_live.ex dismiss_candidate no longer crashes the LiveView when no candidate is selected"
  - "WR-04: release_workbench_live.ex mount/2 assigns a safe :origin_context default so render/1 never depends on handle_params/3 having run first"
  - "D-18: .scoria-table__viewport carries an aria-label; a11y_structural_guard_test.exs now asserts it"
  - "A1 spike finding: a bare %Phoenix.LiveView.Rendered{} match does not force evaluation of the lazily-evaluated `dynamic` closure — Phoenix.HTML.Safe.to_iodata/1 must be called to genuinely reproduce a KeyError from an unassigned @-binding in a direct-callback regression test"
affects: [41-05-gap-register, proof-docs]

tech-stack:
  added: []
  patterns:
    - "Direct-callback LiveView regression test (mount/2 + render/1 + Phoenix.HTML.Safe.to_iodata/1 forced evaluation) to isolate callback-order bugs from a full live/2 navigation test that would false-pass both before and after the fix"

key-files:
  created: []
  modified:
    - lib/scoria_web/live/review_queue_live.ex
    - lib/scoria_web/live/prompt_live/release_workbench_live.ex
    - lib/scoria_web/ui.ex
    - test/scoria_web/live/review_queue_live_test.exs
    - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
    - test/scoria_web/a11y_structural_guard_test.exs

key-decisions:
  - "CR-01 fix: exhaustive `else` clause on the dismiss_candidate `with`, returning {:noreply, socket} with notice \"Could not dismiss this candidate. Refresh and try again.\" — copied verbatim from 41-PATTERNS.md/39-REVIEW.md's own suggested fix"
  - "WR-04 fix: used the direct-callback technique (not the A1 source-scan fallback) — mount/2 + render/1 against a bare %Phoenix.LiveView.Socket{} worked fine for assign/3 compatibility against phoenix_live_view 1.1.30, but required an added Phoenix.HTML.Safe.to_iodata/1 call to force real evaluation, since %Phoenix.LiveView.Rendered{}'s `dynamic` field is a lazy closure and a bare struct match false-passed on unfixed source"
  - "D-18 aria-label copy: \"Scrollable table content\" (Claude's discretion per D-11/D-18)"

patterns-established:
  - "When writing a direct-callback LiveView regression test that must prove an @-binding KeyError, force the Rendered struct to iodata/string (Phoenix.HTML.Safe.to_iodata/1) rather than asserting on the struct shape alone — the struct always succeeds because dynamic content is a deferred closure"

requirements-completed: [PROOF-01, PROOF-03]

coverage:
  - id: D1
    description: "CR-01(39-review): dismiss_candidate with no selected candidate no longer crashes the LiveView; returns a graceful notice instead"
    requirement: "PROOF-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/review_queue_live_test.exs#dismiss_candidate with no selected candidate does not crash the LiveView"
        status: pass
    human_judgment: false
  - id: D2
    description: "WR-04: release_workbench_live.ex mount/2 assigns a default :origin_context so render/1 never KeyErrors regardless of callback order"
    requirement: "PROOF-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/prompt_live/release_workbench_live_test.exs#WR-04: mount/2 assigns a safe :origin_context default render/1 does not depend on handle_params/3 having run first"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-18: .scoria-table__viewport gains an aria-label; a11y_structural_guard_test.exs asserts it alongside the existing tabindex check"
    requirement: "PROOF-03"
    verification:
      - kind: unit
        ref: "test/scoria_web/a11y_structural_guard_test.exs#the table scroll viewport stays keyboard-reachable (tabindex=\"0\", D-11 calmer-surface contract)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-04
status: complete
---

# Phase 41 Plan 01: D-16b Bounded Crash Fix Lane Summary

**Fixed the two CRASH-class LiveView bugs from Phases 39/40 (CR-01 dismiss_candidate, WR-04 origin_context KeyError) plus the D-18 table-scroll aria-label, each locked by a red-to-green regression test.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-04T16:51:59Z (baseline: prior commit 65b74a5b)
- **Completed:** 2026-07-04T16:58:11Z
- **Tasks:** 3 completed
- **Files modified:** 6

## Accomplishments
- CR-01(39-review): `review_queue_live.ex`'s `dismiss_candidate` handler no longer crashes the LiveView process when a client sends the event with no candidate selected — it now shows a graceful notice.
- WR-04: `release_workbench_live.ex`'s `mount/2` now defensively assigns `:origin_context`, so `render/1` never KeyErrors regardless of callback ordering; `handle_params/3` is unchanged and still overrides the default.
- D-18: `.scoria-table__viewport` now carries an `aria-label`, and the existing a11y structural guard asserts it.
- Discovered and worked around an A1 pitfall in the WR-04 regression test technique: a bare `%Phoenix.LiveView.Rendered{}` match does not force evaluation of the lazily-evaluated `dynamic` field, so it silently false-passed on the unfixed source. Fixed by adding `Phoenix.HTML.Safe.to_iodata/1` to force real evaluation, matching what `Phoenix.LiveViewTest.render/1` does under the hood.

## Task Commits

Each task was committed atomically (RED/GREEN pairs for the two `tdd="true"` tasks):

1. **Task 1: Fix CR-01(39-review) dismiss_candidate crash + regression test**
   - `c54d1e81` (test, RED — confirmed crash on today's source: `ArgumentError invalid return from handle_event/3 callback`)
   - `d90dc972` (fix, GREEN — exhaustive `else` clause added)
2. **Task 2: Fix WR-04 release_workbench mount/2 :origin_context KeyError + regression test**
   - `0375ec1a` (test, RED — confirmed `KeyError :origin_context not found`, raised from `render/1` line 178 via `Phoenix.HTML.Safe.to_iodata/1`)
   - `f35b1362` (fix, GREEN — `mount/2` assigns `:origin_context` default)
3. **Task 3: D-18 — add `.scoria-table__viewport` aria-label + tighten the a11y guard**
   - `38a891ed` (fix + guard tightening in one commit — confirmed RED on unfixed source before applying the fix, then GREEN after; task is not `tdd="true"` so a single commit was used)

**Plan metadata:** captured in this SUMMARY commit.

## Files Created/Modified
- `lib/scoria_web/live/review_queue_live.ex` — exhaustive `else` on the `dismiss_candidate` `with`, returning `{:noreply, socket}` with a graceful notice.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` — `mount/2` defensively assigns `:origin_context` to `nil` before `handle_params/3` overrides it.
- `lib/scoria_web/ui.ex` — `.scoria-table__viewport` gains `aria-label="Scrollable table content"`.
- `test/scoria_web/live/review_queue_live_test.exs` — new regression test "dismiss_candidate with no selected candidate does not crash the LiveView".
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` — new regression test "WR-04: mount/2 assigns a safe :origin_context default" using the direct-callback technique (not the A1 source-scan fallback).
- `test/scoria_web/a11y_structural_guard_test.exs` — tightened the existing tabindex test to also assert the aria-label.

## Decisions Made
- **CR-01 fix:** used the exact `else` clause shape from `41-PATTERNS.md` (already matched `39-REVIEW.md`'s own suggested fix). Notice literal chosen: `"Could not dismiss this candidate. Refresh and try again."`
- **WR-04 technique:** used the **direct-callback** approach (`mount/2` + `render/1` against a bare `%Phoenix.LiveView.Socket{}`), not the A1 source-scan fallback. The bare-socket spike against pinned `phoenix_live_view` 1.1.30 worked for `assign/3` compatibility, but the naive `%Phoenix.LiveView.Rendered{}` struct-match assertion the plan sketched was itself a false-pass (see Deviations below) — fixed by forcing evaluation via `Phoenix.HTML.Safe.to_iodata/1`.
- **D-18 aria-label copy:** `"Scrollable table content"` — exact wording was left to implementer discretion per D-11/D-18.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] WR-04 regression test as literally specified in RESEARCH/PATTERNS was a false-pass**
- **Found during:** Task 2, RED phase
- **Issue:** The plan's suggested regression test (`assert %Phoenix.LiveView.Rendered{} = ReleaseWorkbenchLive.render(socket.assigns)`) passed on *both* the pre-fix and post-fix source. `%Phoenix.LiveView.Rendered{}`'s `dynamic` field is a lazily-evaluated closure; matching on the struct shape never forces it, so the `@origin_context` KeyError (which only fires when the closure is actually invoked) never surfaced. A spike (`mix run` against a minimal `Phoenix.Component` module) confirmed: rendering to a `%Rendered{}` succeeds even with a genuinely missing assign key, but calling `Phoenix.HTML.Safe.to_iodata/1` on that struct — exactly what `Phoenix.LiveViewTest.render/1` does under the hood — raises the KeyError.
- **Fix:** Added `assert is_binary(Phoenix.HTML.Safe.to_iodata(rendered) |> IO.iodata_to_binary())` after the `%Phoenix.LiveView.Rendered{}` match, forcing real evaluation. Re-verified RED (KeyError raised from `render/1:178`) then GREEN after the `mount/2` fix.
- **Files modified:** `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` (same file already in scope — no scope expansion)
- **Verification:** `mix test test/scoria_web/live/prompt_live/release_workbench_live_test.exs` — RED confirmed KeyError before the fix, GREEN (8 tests, 0 failures) after.
- **Committed in:** `0375ec1a` (RED commit) and `f35b1362` (GREEN commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in the plan's own suggested test technique, not in application code)
**Impact on plan:** Necessary for the regression test to actually lock the fix rather than silently permitting a regression. No scope creep — same file, same task, no architectural change.

## Issues Encountered
None beyond the deviation documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CR-01(39-review), WR-04, and D-18 are now eligible for gap-register Section A (fixed-in-v3.3) — Plan 05 can cite these commits and the chosen WR-04 technique (direct-callback) directly.
- WR-01, WR-02, and all IN-* items remain untouched and deferred per D-16b scope fence — no files outside the plan's `files_modified` were touched.
- All 21 tests across the three target files pass (`mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/a11y_structural_guard_test.exs`).

---
*Phase: 41-proof-docs-and-regression-guardrails*
*Completed: 2026-07-04*

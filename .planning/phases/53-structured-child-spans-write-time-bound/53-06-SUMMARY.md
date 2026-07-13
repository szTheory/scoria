---
phase: 53-structured-child-spans-write-time-bound
plan: 06
subsystem: ui
tags: [liveview, phoenix-component, css, trace-tree, accessibility, wcag, elixir]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    plan: "01"
    provides: "parent_id write-time population that this plan's cycle guard defends against"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "02"
    provides: "Semconv.guardrail_keys/0, guardrail_names/0, guardrail_decisions/0 — the closed vocabulary the guardrail badge reads through"
provides:
  - "TraceProjection.tree_order/1 — cycle-safe pre-order DFS over the parent/child span graph, applied on both the hydrate and live-append paths"
  - "TraceProjection.with_depths/1 / depth_for/3 — now cycle-guarded (visited set + hard depth cap 100), disarming the DoS that populated parent_id values arm"
  - "TraceTreeComponent renders visual nesting (padding-left calc() consuming --indent-level), the ERROR overlay + WCAG 1.4.1 sr-only label, and a guardrail decision badge"
  - "ReviewCopy.guardrail_label/2 — closed (gate, decision) enum pair to operator copy, never the raw reason_code"
affects: [53-07-guardrail-spans]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared .scoria-span CSS rule for padding-left: calc(0.75rem + var(--indent-level, 0) * 1.25rem) — one depth-rendering path for both trace-tree and workflow-tree rows, no per-component duplication of the calc()"
    - "Dual guard for unbounded recursion: MapSet visited-set (catches cycles) + hard numeric cap (bounds the worst case even if the visited-set logic regresses) — same shape reusable anywhere a host-declared graph edge feeds recursion"
    - "Two-pass emit-every-node graph walk: pass 1 walks from true roots (nil or missing parent), pass 2 force-emits any node still unvisited (pure cycles with no reachable root) — guarantees no input is silently dropped by a malformed graph"

key-files:
  created: []
  modified:
    - lib/scoria/observe/trace_projection.ex
    - lib/scoria_web/components/trace_tree_component.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/review_copy.ex
    - assets/css/04-components.css
    - test/scoria/observe/trace_projection_test.exs
    - test/scoria_web/components/trace_tree_component_test.exs

key-decisions:
  - "padding-left consumes --indent-level via a shared CSS class rule on .scoria-span (assets/css/04-components.css), not an inline style duplicate per component — matches the plan's must_haves wording ('consumed by a padding-left calc() rule') and the D-07a prohibition against a second rendering path. workflow_tree_component.ex's existing inline duplicate was left as-is (out of this plan's file scope) since the two are numerically idempotent, not contradictory."
  - "tree_order/1 uses a two-pass walk: pass 1 emits from true roots in relative input order (DFS, subtree immediately follows); pass 2 force-emits any span left unvisited after pass 1 — this is what makes a pure cycle with no reachable root (e.g. a bare self-parent, the exact Test 1 shape) still get emitted exactly once instead of silently vanishing."
  - "Guardrail attribute reads go through TraceTreeComponent's own attributes_preview accessor (dual atom/string key lookup, matching the existing span_id/1 and span_kind/1 convention), keyed by Semconv.guardrail_keys/0's dotted strings — the component never inlines a scoria.guardrail.* literal."
  - "ReviewCopy.guardrail_label/2 takes (name, decision) as two explicit arguments rather than a raw attributes map — keeps the closed-enum case shape identical to severity_label/1's pattern and keeps Semconv the sole place that resolves attribute keys to values."

requirements-completed: [EVENT-01]

coverage:
  - id: D1
    description: "depth_for/3 terminates on a self-parent or 2-cycle (visited-set + hard cap 100), verified under a bounded Task.await so a regression fails as a timeout rather than hanging the suite (T-53-07)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/trace_projection_test.exs#with_depths/1 cycle guard (T-53-07)"
        status: pass
    human_judgment: false
  - id: D2
    description: "tree_order/1 pre-order DFS orders spans by tree position (not start_time), and emits every input span exactly once including orphans and pure-cycle spans"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/trace_projection_test.exs#tree_order/1"
        status: pass
    human_judgment: false
  - id: D3
    description: "tree_order/1 is applied on both the hydrate path (build_hydrated_trace/2) and the live-append path (upsert_trace_span/3)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/live/orchestrator_live_test.exs (full file, 12 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "--indent-level flows from TraceProjection depth into a padding-left calc() CSS rule — the trace tree renders visible nesting (D-07a, SC#1)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs#nesting is rendered"
        status: pass
    human_judgment: false
  - id: D5
    description: "A span with status_code ERROR renders the scoria-span--status-error overlay plus a visually-hidden Errored label; an OK span renders neither (D-07b, WCAG 1.4.1)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs#ERROR overlay (D-07b, WCAG 1.4.1)"
        status: pass
    human_judgment: false
  - id: D6
    description: "A guardrail span renders a badge with operator-worded microcopy naming the gate and decision, never the raw reason_code enum value (D-07e, T-53-01)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs#guardrail badge (D-07e, T-53-01)"
        status: pass
    human_judgment: false
  - id: D7
    description: "A blocked guardrail span (status_code OK per D-05e) renders the guardrail badge but never the error overlay (T-53-17)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs#guardrail badge (D-07e, T-53-01)#a blocked guardrail span (status_code OK) renders the badge but NOT the error overlay (D-05e)"
        status: pass
    human_judgment: false
  - id: D8
    description: "The bug-locking test ('renders trace span data using a flat DOM structure') is removed; the rewritten component test file passes in full"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs (full file, 9 tests)"
        status: pass
    human_judgment: false

# Metrics
duration: 16min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 06: Trace Tree Nesting + Cycle-Guarded Depth + Guardrail Badge Summary

**The trace tree now renders parent-child indentation via a shared `padding-left: calc()` CSS rule consuming an already-computed `--indent-level`, `depth_for/3` is cycle-guarded (visited-set + hard depth cap) against the DoS this same phase arms via write-time `parent_id`, and guardrail/error spans get accessible, closed-vocabulary operator affordances.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-07-13T17:46:45Z
- **Completed:** 2026-07-13T18:02:34Z
- **Tasks:** 3 (Task 1 TDD RED/GREEN, Tasks 2-3 direct)
- **Files modified:** 7

## Accomplishments
- `TraceProjection.depth_for/3` threads a `visited` `MapSet` accumulator plus a hard cap (`@max_depth 100`) through its recursion — a self-parent or an N-cycle in host-declared `parent_id` (D-02a) now terminates instead of infinite-looping the operator's LiveView process (T-53-07). A pathologically deep but legitimate chain clamps at depth 100 rather than growing unbounded. Orphan spans (parent not in the fetched set) are unaffected and still root at depth 0 (D-07f).
- `TraceProjection.tree_order/1` — a new cycle-safe pre-order DFS. Roots come first in relative input order, each root's subtree follows immediately, siblings preserve input order (tree position, not `start_time`, per D-07c). A two-pass walk guarantees every input span is emitted exactly once, including a span whose entire connected component is a cycle with no reachable root.
- `OrchestratorLive` pipes `tree_order/1` after `with_depths/1` on both `build_hydrated_trace/2` (hydrate path) and `upsert_trace_span/3` (live-append path) — the same tree ordering applies whether a trace is loaded fresh or a span streams in live.
- `assets/css/04-components.css`: `.scoria-span` gains `padding-left: calc(0.75rem + var(--indent-level, 0) * 1.25rem)` — the one CSS rule that was missing. `--indent-level` was already being set by `trace_tree_component.ex` and thrown away; it is now consumed, closing the exact defect SC#1 called out (the component test that certified the flat-DOM bug as correct behavior is deleted in Task 3). No new design tokens (`--scoria-span-guardrail` already existed in both themes).
- `TraceTreeComponent` applies `scoria-span--status-error` (the already-shipped, WCAG-designed overlay from Phase 51 D-12) when `status_code` is `"ERROR"`, paired with a `.sr-only` "Errored" text label per WCAG 1.4.1 — the CSS comment at `04-components.css:1094-1098` explicitly demanded this pairing and it had never been wired.
- `TraceTreeComponent` renders a guardrail badge (existing `<.badge>`/`scoria-badge` chrome) for `span_kind == "guardrail"`, reading `name`/`decision` from `attributes_preview` via `Semconv.guardrail_keys/0` — the component never inlines a `scoria.guardrail.*` key string. Badge tone: `block -> :fail`, `escalate -> :warn`, `allow -> :pass`.
- `ReviewCopy.guardrail_label/2` — closed `(gate, decision)` pair to operator sentence, mirroring `severity_label/1`'s shape. `block` reads "Blocked...", never "Failed" (a block is a successful evaluation that reached a business decision, D-05e); `allow` reads "Checked — allowed", deliberately not "Passed" (guardrails gate, evals judge). The raw `reason_code` is never read or rendered by the component or ReviewCopy (T-53-01).
- Rewrote `test/scoria_web/components/trace_tree_component_test.exs`: deleted "renders trace span data using a flat DOM structure" (which locked in the bug this plan fixes via its sibling-count assertion), added coverage for nesting/indent, the ERROR overlay, the guardrail badge, and the blocked-guardrail-is-not-errored invariant (D-05e/T-53-17). Token-preview, casing-normalization, and tokenized-source assertions carried forward unchanged.

## Task Commits

Each task was committed atomically:

1. **Task 1: Cycle-guard depth_for/3 and add tree_order/1 (pre-order DFS)** - TDD RED `6caaa807` (test), GREEN `fbf66e77` (feat)
2. **Task 2: Consume --indent-level, apply the ERROR overlay, add the guardrail badge** - `1c34ed9f` (feat)
3. **Task 3: Rewrite the component test — it currently asserts the bug** - `e2546b25` (test)

**Plan metadata:** committed as part of this SUMMARY commit.

## Files Created/Modified
- `lib/scoria/observe/trace_projection.ex` - `with_depths/1`/`depth_for/3` cycle-guarded (visited set + hard cap 100); new `tree_order/1` pre-order DFS, both `@spec`'d and `@doc`'d
- `lib/scoria_web/live/orchestrator_live.ex` - pipes `TraceProjection.tree_order/1` after `with_depths/1` on both `build_hydrated_trace/2` and `upsert_trace_span/3`
- `lib/scoria_web/components/trace_tree_component.ex` - consumes `--indent-level` via CSS (no template change needed for that half); applies the ERROR overlay + `.sr-only` label; renders the guardrail badge via `<.badge>` + `ReviewCopy.guardrail_label/2`; new private helpers `errored?/1`, `status_code/1`, `guardrail?/1`, `guardrail_name/1`, `guardrail_decision/1`, `guardrail_attribute/2`, `attributes_preview/1`, `guardrail_tone/1`
- `lib/scoria_web/review_copy.ex` - new `guardrail_label/2` (closed gate/decision enum pair to operator copy) and `humanize_guardrail/2` fallback helper
- `assets/css/04-components.css` - `.scoria-span` gains `padding-left: calc(0.75rem + var(--indent-level, 0) * 1.25rem)`
- `test/scoria/observe/trace_projection_test.exs` - 7 new tests: cycle guard (self-parent, 2-cycle, depth cap), orphan root, and `tree_order/1` (pre-order/tree-position, cycle+orphan tolerance)
- `test/scoria_web/components/trace_tree_component_test.exs` - rewritten: deletes the flat-DOM-locking test, adds nesting/depth/ERROR-overlay/guardrail-badge/blocked-not-errored coverage, carries forward token-preview/casing/tokenized-source tests

## Decisions Made
- `padding-left` is a shared CSS class rule on `.scoria-span` (not an inline style duplicate in the component), matching both the must_haves wording ("consumed by a padding-left calc() rule") and the D-07a prohibition against a second depth-rendering path. `workflow_tree_component.ex`'s pre-existing inline `padding-left` duplicate is out of this plan's file scope and numerically idempotent with the new CSS rule (same formula), so it was left untouched rather than refactored.
- `tree_order/1`'s two-pass design (roots first, then force-emit anything still unvisited) is what makes a pure self-parent or N-cycle with no reachable root still get emitted exactly once — the plan's Test 7 requirement ("emits orphan roots" + "tolerates cycles") needed this, since a bare self-parent span is neither `nil`-parented nor "orphan" by the strict definition (its parent_id resolves to itself, which IS present in the input set).
- Guardrail attribute access in the component reads `attributes_preview` (not a hypothetical raw `attributes` field, which `TraceProjection.span_view/1` never exposes to the UI layer) — this is the same redacted/capped preview the rest of the component already reads from, consistent with the "never expose raw attribute maps" moduledoc invariant in `trace_projection.ex`.
- `ReviewCopy.guardrail_label/2` takes `(name, decision)` as two arguments rather than a raw span/attributes map, keeping its case-clause shape structurally identical to `severity_label/1` and keeping all Semconv-key resolution inside the component (Semconv remains the sole key-string owner per the plan's action item).

## Deviations from Plan

None — plan executed as written. One clarifying interpretation is noted above under Decisions Made: the plan's Task 3 behavior prose described the child row's rendered `style` attribute as containing "BOTH `--indent-level: 1` AND a `padding-left` calc()," which read as potentially requiring an inline duplicate of the calc() in the component's own `style` attribute (as `workflow_tree_component.ex:23` does). The plan's frontmatter `must_haves.truths` and Task 2's machine-checkable `acceptance_criteria` (`grep -q 'indent-level' assets/css/04-components.css` — a CSS *rule*, not an inline duplicate) point unambiguously at the shared-CSS-rule design, and the D-07a prohibition explicitly forbids "a new depth-computation path" duplication. The rewritten test in Task 3 verifies both facts independently (the child row's `--indent-level: 1` in its `style` attribute, and the `padding-left: calc(...)` rule's presence in the CSS source) rather than requiring them in the same attribute string — this is the reading that satisfies every machine-checkable acceptance criterion in the plan and the D-07a "MUST NOT leave --indent-level ... consumed by nothing" prohibition without introducing a second rendering path.

## Issues Encountered
- Full-suite `mix test --warnings-as-errors` shows 15 pre-existing failures, all in `Mix.Tasks.Scoria.InstallTest`, `Mix.Tasks.Scoria.InstallCheckTest`, `Scoria.WarningInventory.TmpPreflightTest`, `Scoria.WarningInventory.CaptureParityTest`, and `Scoria.SupportCopilotGalleryTest` — none of which touch any file this plan modified. Every failure's assertion output is a raw Mix dependency-resolution error ("the dependency is not available, run 'mix deps.get'" / "lock mismatch") from a `System.cmd("mix", ...)` subprocess these tests spawn against a fixture host directory; the subprocess does not inherit this worktree's `MIX_DEPS_PATH` shim (this worktree has no local `deps/`/`_build`, so tests run against the main checkout's `deps/` via `MIX_DEPS_PATH`, per the same one-time setup noted in 53-02-SUMMARY.md) and is additionally exposed to concurrent `mix deps.get`/compile contention from sibling parallel-wave worktree agents sharing that same `deps/` directory. Confirmed environment-only: all scoped verification commands from the plan pass cleanly — `mix test test/scoria/observe/trace_projection_test.exs --warnings-as-errors` (10/10), `mix test test/scoria_web/components/trace_tree_component_test.exs --warnings-as-errors` (9/9), `mix test test/scoria_web/live/orchestrator_live_test.exs --warnings-as-errors` (12/12), and `mix test test/scoria_web/ --warnings-as-errors` (453/453, 0 failures).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- SC#1's rendering half is satisfied: the trace tree visibly nests parent/child spans, and the write-time `parent_id` population from plans 53-01/53-03/53-05 is now safe to render against (cycle-guarded).
- `Semconv.guardrail_keys/0`/`guardrail_names/0`/`guardrail_decisions/0` consumers now have a working reference implementation in `TraceTreeComponent` + `ReviewCopy.guardrail_label/2` for plan 53-07 (guardrail spans) to build on or extend.
- No blockers.

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*

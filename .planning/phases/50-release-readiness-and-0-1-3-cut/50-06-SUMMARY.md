---
phase: 50-release-readiness-and-0-1-3-cut
plan: 06
subsystem: testing
tags: [exdoc, guides, docs-source-contract, elixir, exunit]

# Dependency graph
requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: guides/ canonical guide ladder (golden-path.md, capabilities/*.md, reviewer-verification.md), docs/*.md compatibility stubs
provides:
  - All 7 Bucket-A docs-source cases green (phoenix, handoff, semantic-cache, and all 4 SupportJourney adopter-doc surfaces)
  - AdoptionExample.doc_fragments/0 restructured into phoenix_doc_surfaces/0 (per-guide fragment groups), mirroring SupportJourney.adopter_doc_surfaces/0
  - SupportJourney.adopter_doc_surfaces/0 fully repointed to guides/ SSOT with content-drift fragments re-aligned per user decision
affects: [50-07, 50-08, 50-09, 50-10, 50-11, REL-04 CI verify-lane closeout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "docs-source contract tests must File.read! the canonical guides/ path, not the docs/*.md compatibility stub, per D-16"
    - "When source content that used to live in one file is split across multiple guides/ files, restructure the fixture into a path -> fragments map (mirroring SupportJourney.adopter_doc_surfaces/0) and iterate with `for {path, fragments} <- ... do test ... end`, instead of forcing a single File.read!/1 to satisfy the whole fragment set"
    - "When two logical fragment concerns consolidate into the same physical guides/ file, merge them into one map entry (Enum.uniq/1 of the concatenated fragment lists) rather than keeping duplicate map keys — Elixir map literals silently collapse duplicate keys to the last value, which would silently drop test coverage"

key-files:
  created: []
  modified:
    - test/scoria/phoenix_example_source_test.exs
    - test/support/scoria/adoption_example.ex
    - lib/scoria/support_journey.ex

key-decisions:
  - "USER DECISION (this plan's checkpoint): re-align fixtures to the canonical guides/ (guides/ is source of truth, left untouched); update fixture wording/paths to current canonical text; drop fragments whose concept was genuinely removed by Phase 46/48; every retained fragment re-confirmed present at its canonical path via CONFIRM-FRAGMENT-PRESENT."
  - "Restructured AdoptionExample.doc_fragments/0 into phoenix_doc_surfaces/0, a path -> fragments map (golden-path.md, capabilities/default-runtime.md, capabilities/bounded-handoffs.md, cheatsheet.cheatmd), because Phase 48 split the single-file phoenix_runtime_example.md content across those four guides and no single File.read!/1 could satisfy the whole set."
  - "Updated 3 reworded fragments to current wording: 'next_run.session_id == session_id' -> 'next_run.session_id == started.session_id'; 'next_run.run_id != run_id' -> 'next_run.run_id != started.run_id'; 'last_scoria_handoff_run_id' -> 'last_scoria_run_id'; and the session_id/run_id rule sentence updated to golden-path.md's current backtick/period phrasing."
  - "Dropped 2 phoenix fragments for genuinely-removed concepts: the `needs_bounded_review?/1` decision-point helper (not present anywhere in guides/), and 'started.run_id != handoff_run.run_id' (contradicts the current same-run bounded-handoff design, which explicitly keeps the delegated child step under the same durable run)."
  - "Repointed all 4 SupportJourney.adopter_doc_surfaces/0 entries: docs/support_copilot_gallery.md -> guides/capabilities/support-copilot-gallery.md; docs/connector_adoption.md -> guides/capabilities/connectors-and-mcp.md; README.md unchanged; docs/operator_verification.md content merged into the gallery guide key (Phase 48 folded that SupportJourney/VerificationSuites cross-reference paragraph into support-copilot-gallery.md itself, not reviewer-verification.md)."
  - "Merged operator_doc_fragments()/doc_fragments() under one map key (guides/capabilities/support-copilot-gallery.md) rather than two separate keys, because Elixir map literals silently collapse duplicate string keys to the last value — keeping them as separate entries pointing at the same file would have silently dropped one fragment set's test coverage."
  - "Fixed case-sensitivity: 'clone the repository' -> 'Clone the repository' (sentence-initial capital in the current guide)."
  - "Updated 'VerificationLanes.closeout_order/0' -> 'Scoria.VerificationSuites.closeout_order/0' (Phase 46/48 module rename)."
  - "Dropped 'not a hosted connector platform' from connector_doc_fragments/0 — genuinely removed by the Embedded-boundary rewrite; no equivalent phrase exists in connectors-and-mcp.md (closest unrelated wording lives in getting-started.md: 'not a hosted SaaS agent platform')."
  - "Dropped the self-referential 'support_copilot_gallery.md' filename fragment from operator_doc_fragments/0 — asserting the gallery guide mentions its own filename no longer makes sense now that the content is self-contained rather than a cross-file reference."

patterns-established:
  - "CONFIRM-FRAGMENT-PRESENT gate applied to every retained fragment (grep -F against the target guides/ file) before finalizing a path/wording change."
  - "Path -> fragments map fixtures (SupportJourney.adopter_doc_surfaces/0 style) generalize cleanly to content that is split across, or consolidated across, multiple canonical files — prefer this shape over a single File.read!/1 whenever the SSOT does not fit one file."

requirements-completed: []  # REL-04 stays pending per plan instruction — full gap-closure train + publish still required before REL-04 closes.

coverage:
  - id: D1
    description: "phoenix_example_source_test.exs restructured to phoenix_doc_surfaces/0 (4 canonical guide files); all fragments confirmed present, 3 fragments reworded to current wording, 2 fragments dropped for genuinely-removed concepts"
    verification:
      - kind: unit
        ref: "test/scoria/phoenix_example_source_test.exs (4 generated test cases, one per guides/ path)"
        status: pass
    human_judgment: false
  - id: D2
    description: "handoff_example_source_test.exs and semantic_fast_path_example_source_test.exs repointed to guides/ SSOT (completed in prior partial session, unchanged this session)"
    verification:
      - kind: unit
        ref: "test/scoria/handoff_example_source_test.exs, test/scoria/semantic_fast_path_example_source_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "SupportJourney.adopter_doc_surfaces/0 fully repointed (support-copilot-gallery.md, connectors-and-mcp.md, README.md), with content-drift fragments realigned per the user's decision"
    verification:
      - kind: unit
        ref: "test/scoria/support_journey_source_test.exs (3 doc-surface test cases + 3 fixture/seed cases)"
        status: pass
    human_judgment: false
---

# Phase 50 Plan 06: Docs-source path repoint (Bucket A) — complete, 7/7 cases closed

**All 7 Bucket-A docs-source cases now pass: repointed phoenix/handoff/semantic-cache example-source tests and all 4 SupportJourney adopter-doc surfaces to the canonical guides/ SSOT, applying the user's decision to update fixture wording/paths to current canonical text and drop fragments whose concept Phase 46/48 genuinely removed, while leaving guides/ itself untouched.**

## Performance

- **Duration (this continuation):** ~35 min
- **Tasks:** 2 of 2 completed in full
- **Files modified:** 3 (this session) + 2 (prior partial session) = 5 total across the plan

## Accomplishments

- `test/scoria/phoenix_example_source_test.exs` restructured to iterate `AdoptionExample.phoenix_doc_surfaces/0`, a path -> fragments map covering `guides/golden-path.md`, `guides/capabilities/default-runtime.md`, `guides/capabilities/bounded-handoffs.md`, and `guides/cheatsheet.cheatmd` — the four files Phase 48 split the old single-file phoenix runtime example across.
- `test/support/scoria/adoption_example.ex`'s `doc_fragments/0` replaced by `phoenix_doc_surfaces/0` plus four per-guide fragment-list helpers (`golden_path_doc_fragments/0`, `default_runtime_doc_fragments/0`, `bounded_handoffs_doc_fragments/0`, `cheatsheet_doc_fragments/0`).
- `lib/scoria/support_journey.ex`'s `adopter_doc_surfaces/0` repointed all 4 entries to canonical `guides/` paths, with `docs/operator_verification.md`'s fragment set merged into the gallery guide key (since that's where Phase 48 actually moved the content).
- All 12 tests across the plan's 4 target files pass; `mix test test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria/semantic_fast_path_example_source_test.exs test/scoria/support_journey_source_test.exs` exits 0.
- Confirmed no collateral impact: `test/scoria/adoption_surface_test.exs` (a different fixture module, `HexConsumerContract`, explicitly out of scope per the plan) still passes unchanged (29 tests, 0 failures).

## Task Commits

1. **Task 1: repoint phoenix_example_source_test to per-guide fragment groups** - `b8867e67` (fix)
   - `test/scoria/phoenix_example_source_test.exs`, `test/support/scoria/adoption_example.ex`
2. **Task 2: repoint SupportJourney adopter doc surfaces to canonical guides/** - `ee7f53f5` (fix)
   - `lib/scoria/support_journey.ex`

Prior partial-session commits (already landed before this continuation):
- `e9fe82f5` (fix): repointed `handoff_example_source_test.exs` and `semantic_fast_path_example_source_test.exs`
- `ea90bbdf` (docs): partial SUMMARY + STATE recording the checkpoint blocker

## Files Created/Modified

- `test/scoria/phoenix_example_source_test.exs` - rewritten to iterate `AdoptionExample.phoenix_doc_surfaces/0` (4 generated test cases, one per canonical guide file), replacing the single `@phoenix_example "docs/phoenix_runtime_example.md"` constant.
- `test/support/scoria/adoption_example.ex` - `doc_fragments/0` replaced by `phoenix_doc_surfaces/0` (path -> fragments map) plus 4 new per-guide fragment-list functions; 3 fragments reworded, 2 fragments dropped (see Decisions).
- `lib/scoria/support_journey.ex` - `adopter_doc_surfaces/0` repointed to 3 canonical `guides/` paths (was 4 stale `docs/*.md` paths); `operator_doc_fragments/0` merged into the gallery guide's fragment set; `doc_fragments/0`, `connector_doc_fragments/0`, `readme_doc_fragments/0` updated per Decisions.

## Decisions Made

See `key-decisions` in frontmatter for the full list. Summary: the user resolved the prior session's Rule-4 blocker by choosing "re-align fixtures to canonical guides" (guides/ untouched, fixtures updated). Every fragment change in this session follows directly from that decision, with the CONFIRM-FRAGMENT-PRESENT gate re-applied to every retained fragment before finalizing.

One additional non-content decision made during execution (not covered by the user's explicit examples but a direct, low-risk consequence of them): merging `operator_doc_fragments/0` into the `support-copilot-gallery.md` map key instead of keeping `docs/operator_verification.md` -> `guides/reviewer-verification.md` as its own key. Grep-confirmed 0/6 of the operator fragments live in `reviewer-verification.md` (that guide now covers only general install/dashboard/optional-capability proof), while 5/6 (post-rename) live in `support-copilot-gallery.md`. Keeping them as two map keys pointing at different files would have failed the gate for `reviewer-verification.md`; keeping them as two keys pointing at the *same* file would have hit Elixir's silent duplicate-map-key collapse (last write wins), dropping test coverage for one of the two fragment sets. Merging into one key with `Enum.uniq/1` is the only structurally correct option that preserves every fragment's coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - blocking structural issue] Merged operator_doc_fragments/0 into the gallery guide map key instead of keeping it separate**
- **Found during:** Task 2
- **Issue:** The plan's `<read_first>` assumed `docs/operator_verification.md` -> `guides/reviewer-verification.md` (per the `package_surface_test.exs` redirect map), but Phase 48 actually moved this fragment set's content into `guides/capabilities/support-copilot-gallery.md`. Keeping `adopter_doc_surfaces/0` as a 4-entry map with two keys resolving to the same physical file would have caused Elixir's map-literal duplicate-key collapse to silently drop one fragment set.
- **Fix:** Merged `doc_fragments() ++ operator_doc_fragments()` (deduplicated) under the single `guides/capabilities/support-copilot-gallery.md` key; reduced `adopter_doc_surfaces/0` from 4 entries to 3.
- **Files modified:** `lib/scoria/support_journey.ex`
- **Commit:** `ee7f53f5`

None of the fragment content itself was weakened by this — every fragment that was previously checked is still checked, just against the file that actually contains it now, consolidated as a map-structural necessity rather than a content decision.

## Auth Gates

None encountered.

## Current Test Status

```
mix test test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria/semantic_fast_path_example_source_test.exs test/scoria/support_journey_source_test.exs
```
12 tests, 0 failures. (All 7 originally-failing Bucket-A cases now pass, plus 5 pre-existing fixture/seed tests in the same files.)

Also verified no collateral regression: `mix test test/scoria/adoption_surface_test.exs` (HexConsumerContract, explicitly out of scope) — 29 tests, 0 failures, unchanged.

## Issues Encountered

None beyond the structural map-key-collision issue documented above, which was resolved inline as a Rule 3 blocking-issue fix (not a new content decision — the user's decision already established which fragments to keep/drop/reword; only the map key shape needed to change to correctly express "these two fragment groups now live in the same file").

## Next Phase Readiness

- Bucket A (docs-source alignment) is fully closed: all 7 originally-failing cases pass.
- 50-07 through 50-11 do not depend on this plan's prior blocker; they were already able to proceed independently and remain unaffected by this closeout.
- REL-04 remains pending per plan instruction — this plan closes Bucket A only; the full gap-closure train (50-07..11) and publish steps still gate REL-04 completion. Per explicit instruction, `requirements mark-complete REL-04` was NOT run in this session.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED

- FOUND: test/scoria/phoenix_example_source_test.exs
- FOUND: test/support/scoria/adoption_example.ex
- FOUND: lib/scoria/support_journey.ex
- FOUND: b8867e67 (commit)
- FOUND: ee7f53f5 (commit)
- FOUND: e9fe82f5 (commit, prior session)
- FOUND: ea90bbdf (commit, prior session)

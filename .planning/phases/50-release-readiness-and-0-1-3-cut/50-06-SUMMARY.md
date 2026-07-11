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
  - Two of three example-source tests (handoff, semantic fast path) repointed to the canonical guides/ SSOT
  - A precise, fragment-level diagnosis of five remaining Bucket-A failures that require a human decision before they can be closed (see Blockers)
affects: [50-07, 50-08, 50-09, 50-10, 50-11, REL-04 CI verify-lane closeout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "docs-source contract tests must File.read! the canonical guides/ path, not the docs/*.md compatibility stub, per D-16"

key-files:
  created: []
  modified:
    - test/scoria/handoff_example_source_test.exs
    - test/scoria/semantic_fast_path_example_source_test.exs

key-decisions:
  - "Repointed handoff_example_source_test.exs and semantic_fast_path_example_source_test.exs to guides/capabilities/{bounded-handoffs,semantic-cache}.md after grep-confirming every asserted fragment is present byte-for-byte at the new path"
  - "Did NOT repoint phoenix_example_source_test.exs or any of the four lib/scoria/support_journey.ex adopter_doc_surfaces/0 entries — CONFIRM-FRAGMENT-PRESENT gate failed for all five; forcing a path change would either require restoring removed/renamed content into guides/ or weakening the fragment assertions, both explicitly prohibited by this plan. Filed as a Rule 4 architectural blocker instead (see Blockers)."

patterns-established:
  - "CONFIRM-FRAGMENT-PRESENT gate: grep -F every asserted fragment against the candidate guides/ path (and, where ambiguous, the full guides/ tree) before touching a path constant. If any fragment is absent, leave the constant untouched and report rather than editing the fragment list or the docs/ stub."

requirements-completed: []  # REL-04 stays pending until the full gap-closure train + publish complete, per plan instruction — this plan only partially closes Bucket A.

coverage:
  - id: D1
    description: "handoff_example_source_test.exs repointed to guides/capabilities/bounded-handoffs.md; all fragments in AdoptionExample.handoff_doc_fragments/0 confirmed present"
    verification:
      - kind: unit
        ref: "test/scoria/handoff_example_source_test.exs#bounded handoff guide stays aligned with the checked adoption fragments"
        status: pass
    human_judgment: false
  - id: D2
    description: "semantic_fast_path_example_source_test.exs repointed to guides/capabilities/semantic-cache.md; all seven inline fragments confirmed present"
    verification:
      - kind: unit
        ref: "test/scoria/semantic_fast_path_example_source_test.exs#semantic cache guide stays aligned with the shipped public profile"
        status: pass
    human_judgment: false
  - id: D3
    description: "phoenix_example_source_test.exs and lib/scoria/support_journey.ex adopter_doc_surfaces/0 (4 entries) remain blocked pending a human decision on reworded/renamed content (see Blockers)"
    verification: []
    human_judgment: true
    rationale: "Fixing these requires choosing between restoring removed guide content, updating fixture terminology, or restructuring the single-file-read assumption in the test itself — an architectural/content decision the plan explicitly reserves for a human (Rule 4), not something CONFIRM-FRAGMENT-PRESENT permits an executor to force."

duration: 45min
completed: 2026-07-11
status: blocked
---

# Phase 50 Plan 06: Docs-source path repoint (Bucket A) — partial, 2/7 cases closed, 5 blocked

**Repointed 2 of 3 example-source tests to canonical guides/ SSOT paths (handoff, semantic cache); phoenix and all four SupportJourney adopter-doc surfaces are blocked on genuine content drift that the plan's CONFIRM-FRAGMENT-PRESENT gate explicitly forbids force-fixing.**

## Performance

- **Duration:** ~45 min (mostly fragment-by-fragment verification against guides/)
- **Tasks:** 1 of 2 completed in full; both tasks partially executed (see below)
- **Files modified:** 2

## Accomplishments
- `test/scoria/handoff_example_source_test.exs` now reads `guides/capabilities/bounded-handoffs.md`; all 29 fragments in `AdoptionExample.handoff_doc_fragments/0` grep-confirmed present, test passes.
- `test/scoria/semantic_fast_path_example_source_test.exs` now reads `guides/capabilities/semantic-cache.md`; all 7 inline fragments grep-confirmed present, test passes.
- Produced a fragment-by-fragment diagnosis (below) for the 5 remaining failures, narrowing each to the exact missing string(s) and the exact commit where Phase 48 dropped or renamed the content, so a follow-up decision can be made quickly without re-doing this investigation.

## Task Commits

1. **Task 1 (partial — 2 of 3 files): repoint handoff/semantic docs-source tests** - `e9fe82f5` (fix)
   - `phoenix_example_source_test.exs` deliberately NOT touched — see Blockers.
2. **Task 2: repoint SupportJourney adopter doc surfaces** - NOT executed. `lib/scoria/support_journey.ex` is unchanged. All four `adopter_doc_surfaces/0` entries fail the CONFIRM-FRAGMENT-PRESENT gate against their D-16 canonical target — see Blockers.

**Plan metadata:** (this commit, docs-only)

## Files Created/Modified
- `test/scoria/handoff_example_source_test.exs` - `@handoff_guide` repointed to `guides/capabilities/bounded-handoffs.md`
- `test/scoria/semantic_fast_path_example_source_test.exs` - `@semantic_guide` repointed to `guides/capabilities/semantic-cache.md`

## Decisions Made
- Applied the plan's CONFIRM-FRAGMENT-PRESENT gate literally: only repoint a path when every asserted fragment is grep-confirmed present byte-for-byte at the destination. Two of three Task 1 files passed cleanly; both were repointed and verified green.
- For every fragment set that failed the gate, did NOT edit the fragment list, did NOT restore content into the `docs/` stub, and did NOT edit `guides/` content to manufacture a match — all three would violate the plan's explicit scope-reduction prohibition and threat-model mitigation (T-50-06-01). Instead left the affected path constants/map keys unchanged and documented the exact gap below for a human decision.

## Deviations from Plan

None beyond the STOP-and-report behavior the plan itself mandates for this exact scenario (see Blockers). No unauthorized fixes were applied.

## Blockers — Rule 4 (Architectural/Content Decision Required)

All five blockers below hit the plan's own explicit STOP condition: *"If a fragment is genuinely absent from every guides/ file (i.e. Phase 48 changed the wording, not just the location), STOP and report — do NOT edit the fragment list to match, and do NOT restore content into the docs/ stub."* Every fragment listed below was verified absent via `grep -F` against the **entire `guides/` tree** (`guides/*.md`, `guides/capabilities/*.md`, `guides/reference/*.md`, `guides/cheatsheet.cheatmd`), not just the single candidate file, so this is not a wrong-file-guess problem — the content is genuinely gone or renamed.

### 1. `test/scoria/phoenix_example_source_test.exs` (`AdoptionExample.doc_fragments/0`, 29 fragments + `operator_route_pattern/0`)

No single `guides/` file contains the full fragment set — the content that used to live in one file (`docs/phoenix_runtime_example.md`) is now split across `guides/golden-path.md`, `guides/capabilities/default-runtime.md`, and `guides/capabilities/bounded-handoffs.md` / `guides/cheatsheet.cheatmd`. Even the union of every `guides/` file is missing 6 fragments, confirmed genuinely absent repo-wide:

- `"next_run.session_id == session_id"` / `"next_run.run_id != run_id"` — `guides/golden-path.md:135-136` now reads `next_run.session_id == started.session_id` / `next_run.run_id != started.run_id` (reworded to use the `started.` prefix).
- `"defp needs_bounded_review?(draft_answer) do"` — this decision-point helper function does not appear anywhere in `guides/`; it was apparently dropped when the runtime-to-handoff walkthrough was split into separate capability guides.
- `"last_scoria_handoff_run_id"` — `guides/capabilities/default-runtime.md:96` stores `put_session(:last_scoria_run_id, started.run_id)` (renamed key, drops `_handoff`).
- `"started.run_id != handoff_run.run_id"` — not present in any guide.
- `"session_id groups related host turns; run_id names one exact Scoria execution."` — closest match is `guides/golden-path.md:66`: `` `session_id` groups related host turns. `run_id` names one exact Scoria execution. `` (backticks + period instead of semicolon — a genuine copy-edit, not a location change).

Because `File.read!/1` can only read one file, even choosing the best-matching single candidate cannot satisfy the full fragment set as long as fragments live in different files. **Decision needed:** either (a) restore the 6 missing/reworded fragments into one canonical guide, (b) update `AdoptionExample.doc_fragments/0` to match current wording/location and possibly split it into per-guide fragment groups (mirroring how `handoff_doc_fragments/0` is already split out), or (c) some other resolution the plan author did not anticipate. `docs/phoenix_runtime_example.md` (the constant's current value) was left unchanged.

### 2-5. `lib/scoria/support_journey.ex` `adopter_doc_surfaces/0` (all four entries)

None of the four entries pass the gate. `lib/scoria/support_journey.ex` was left entirely unchanged (no map keys repointed):

| Current key | D-16 candidate target | Fragment function | Missing fragment(s) |
|---|---|---|---|
| `docs/support_copilot_gallery.md` | `guides/capabilities/support-copilot-gallery.md` | `doc_fragments/0` | `"clone the repository"` — present only as `Clone the repository` (sentence-initial capital, line 7 and the `## Clone the repository` heading, line 9). Case-sensitive `=~` fails. |
| `docs/connector_adoption.md` | `guides/capabilities/connectors-and-mcp.md` | `connector_doc_fragments/0` | `"not a hosted connector platform"` — present verbatim in the pre-Phase-48 file (`git show 70c668b7~1:docs/connector_adoption.md`) but dropped when Phase 48 rewrote the "Embedded boundary" section; no equivalent phrase in `connectors-and-mcp.md` (closest is unrelated wording in `guides/getting-started.md`: "not a hosted SaaS agent platform"). |
| `README.md` (unchanged key candidate) | n/a — README.md is still canonical | `readme_doc_fragments/0` | `"docs/support_copilot_gallery.md"` — README now links the renamed `guides/capabilities/support-copilot-gallery.md` path (lines 65, 303); the old literal filename string no longer appears anywhere in README. |
| `docs/operator_verification.md` | `guides/reviewer-verification.md` | `operator_doc_fragments/0` | `"examples/support_copilot"`, `"Scoria.SupportJourney"`, `"VerificationLanes.closeout_order/0"`, `"support_copilot_gallery.md"`, `"Scoria.get_run_detail/1"` — 5 of 6 fragments missing from `reviewer-verification.md`. `guides/capabilities/support-copilot-gallery.md` and `README.md` are closer (4/6, missing only `VerificationLanes.closeout_order/0` and `support_copilot_gallery.md`), but still fail the gate. The pre-Phase-48 `docs/operator_verification.md` (`git show c9958ab1~1`) had all 6 fragments; confirmed the module was renamed `VerificationLanes` -> `Scoria.VerificationSuites` (see `guides/capabilities/support-copilot-gallery.md:53`) and the gallery doc filename was renamed to the hyphenated `support-copilot-gallery.md` slug — both deliberate Phase 46/48 terminology changes, not accidental drops. |

**Decision needed per row:** for the gallery/README items, whether to reword the guide sentence (case-only, no semantic loss) or update the fixture fragment. For connector and operator_verification, whether to restore the specific phrase/identifiers into the canonical guide (re-adding "not a hosted connector platform," etc.) or update `connector_doc_fragments/0` / `operator_doc_fragments/0` to reflect current terminology (`Scoria.VerificationSuites.closeout_order/0`, hyphenated gallery slug). This plan's threat-model mitigation (T-50-06-01) explicitly reserves that choice for a human, since the wrong call either quietly restores stale terminology contradicting Phase 46/48's deliberate rename, or silently narrows what the drift guard checks.

## Current Test Status

```
mix test test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria/semantic_fast_path_example_source_test.exs test/scoria/support_journey_source_test.exs
```
10 tests, 5 failures (was 7 failures across these + connector/operator sub-cases before this plan; handoff and semantic now green).

## Issues Encountered

The plan's own "likely mapping" guesses in the `<read_first>` block undersold the scope of Phase 48's content drift — it flagged the phoenix mapping as needing confirmation but the actual gap (6 fragments, spread across 3+ files) is larger than a simple path miss. The SupportJourney gap was not flagged at all in the plan's read_first notes but affects all 4 of 4 entries.

## Next Phase Readiness

- 50-07 through 50-11 do not depend on this plan's blocked items (different files per `50-CI-GAP-INVENTORY.md` buckets); they can proceed independently.
- REL-04 remains pending, as instructed — this plan alone cannot close Bucket A.
- Recommend a follow-up plan (or amendment to this one) that makes the two decisions above explicit — likely as a `checkpoint:decision` — before re-attempting `phoenix_example_source_test.exs` and the `SupportJourney` adopter-doc surfaces.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11 (partial — see Blockers)*

## Self-Check: PASSED

- FOUND: test/scoria/handoff_example_source_test.exs
- FOUND: test/scoria/semantic_fast_path_example_source_test.exs
- FOUND: e9fe82f5 (commit)

---
phase: 54-docs-accuracy-conformance-check
plan: 01
subsystem: docs
tags: [otel-genai, openinference, req_llm, doc-contract, glossary, llms.txt]

# Dependency graph
requires:
  - phase: 51-52
    provides: gen_ai.*/server.*/openinference.span.kind convention keys emitted via req_llm ~> 1.13 and Semconv
provides:
  - Honest, version-pinned "OpenInference-compatible convention keys" adopter claim, allowed by Scoria's own doc-contract guards
  - New canonical guides/capabilities/trace-observability.md
  - Additive @comparison_safe_current_claims and @required_llms_paths entries
  - Glossary softener removal (D-12)
affects: [54-02 conformance test, docs-accuracy-conformance-check phase closeout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One canonical D-10 sentence reused byte-identical across README, AGENTS, glossary, comparison guide, and the new trace guide"
    - "Additive-only doc-contract list edits (append, never mutate existing forbidden/deferred entries) to keep D-11 safety invariant"

key-files:
  created:
    - guides/capabilities/trace-observability.md
  modified:
    - lib/scoria/adopter_doc_contract.ex
    - lib/scoria/ai_doc_contract.ex
    - guides/scoria-vs-external-llm-ops.md
    - guides/reference/glossary.md
    - llms.txt
    - README.md
    - AGENTS.md

key-decisions:
  - "D-10 canonical sentence landed byte-identical on 5 surfaces: README.md, AGENTS.md, glossary.md L36, the comparison guide's currently-owns section, and the new trace-observability guide's opening line."
  - "@comparison_safe_current_claims and @required_llms_paths were extended additively only; no export-bearing forbidden/deferred entry was touched (D-11 KEEP)."
  - "Glossary L31 dropped only the '-style' softener (OpenInference-compatible observability); L36's full softener sentence was replaced with the D-10 sentence plus a link to the new guide."

patterns-established:
  - "New capability guides register in both @required_llms_paths (ai_doc_contract.ex) and llms.txt's Capability Guides list in the same commit to avoid a RED doc-contract window."

requirements-completed: [DOCS-01]

coverage:
  - id: D1
    description: "Comparison guide's currently-owns section carries the OpenInference-compatible convention keys claim, matched by an additive @comparison_safe_current_claims entry"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/scoria/adoption_surface_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "New guides/capabilities/trace-observability.md exists, opens with the D-10 sentence, and is registered in @required_llms_paths + llms.txt"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/scoria/ai_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Glossary softeners removed (L31 -style dropped, L36 replaced with D-10 sentence + guide link); README/AGENTS carry the byte-identical D-10 sentence"
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/scoria/adoption_surface_test.exs, test/scoria/ai_doc_contract_test.exs, test/scoria/terminology_contract_test.exs"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-07-19
status: complete
---

# Phase 54 Plan 01: OpenInference-Compatible Claim Flip Summary

**Flipped the adopter-facing observability claim from the softened "OpenInference-style" to an honest, version-pinned "OpenInference-compatible convention keys" claim across 5 doc surfaces, additively extending the doc-contract's allowed/required lists in the same change.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-07-19T00:20:00Z (approx)
- **Completed:** 2026-07-19T00:44:43Z
- **Tasks:** 3
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments
- Appended `"OpenInference-compatible convention keys"` to `@comparison_safe_current_claims` and landed the D-10 canonical sentence in the comparison guide's "What Scoria currently owns" section, keeping all `export`-bearing forbidden/deferred entries byte-stable.
- Created `guides/capabilities/trace-observability.md` (opens with the D-10 sentence; documents recorded keys, the OTel-GenAI schema 1.37.0 pin, and the "not an exporter" framing), and registered its path in both `@required_llms_paths` and `llms.txt`'s Capability Guides list in the same task.
- Removed the glossary's two softeners (L31 `-style` -> `-compatible`; L36 full sentence replaced with the D-10 sentence + a link to the new guide) and added the byte-identical D-10 sentence to README.md (new `## Trace Observability` section) and AGENTS.md (`## Docs Language` section).

## Task Commits

Each task was committed atomically:

1. **Task 1: Additive safe-claim edit + comparison-guide sentence** - `02da9364` (feat)
2. **Task 2: New trace-observability guide + docs-source registration** - `0ecac9fc` (feat)
3. **Task 3: Land canonical sentence on README/AGENTS + glossary softener removal** - `43ce17ee` (feat)

**Plan metadata:** committed with this SUMMARY.md (docs commit) — see final commit below.

## Files Created/Modified
- `guides/capabilities/trace-observability.md` - New canonical trace-observability guide (D-10 sentence + recorded-keys/schema-pin/not-an-exporter framing)
- `lib/scoria/adopter_doc_contract.ex` - Additive `@comparison_safe_current_claims` entry
- `lib/scoria/ai_doc_contract.ex` - Additive `@required_llms_paths` entry
- `guides/scoria-vs-external-llm-ops.md` - D-10 sentence landed in "What Scoria currently owns"
- `guides/reference/glossary.md` - L31 `-style` -> `-compatible`; L36 softener replaced with D-10 sentence + guide link
- `llms.txt` - New Capability Guides bullet for the trace-observability guide
- `README.md` - New `## Trace Observability` section with the D-10 sentence
- `AGENTS.md` - D-10 sentence added under `## Docs Language`

## Decisions Made
- Reused the D-10 sentence verbatim (byte-identical, verified via direct Python string-containment check) across all 5 target surfaces rather than paraphrasing per-surface, per the plan's "one voice" instruction.
- Placed the README addition as a new `## Trace Observability` section between Semantic Cache and Verification (natural capability-ladder slot); placed the AGENTS.md addition under the existing `## Docs Language` section (pure addition, no existing OpenInference mention there).
- Cross-linked the new trace guide from the glossary's Trace entry and referenced the comparison guide and glossary from the new guide itself, matching the support-copilot-gallery.md structural analog's cross-link style.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' acceptance criteria were met verbatim; no `export`-bearing forbidden/deferred entry was touched (confirmed via `git diff` against the pre-plan base commit, showing only the two additive one-line appends in the contract modules).

## Issues Encountered

Fresh worktree had no `deps/`/`_build` (each worktree checkout is independent); ran `mix deps.get` once before the first test run. This is expected worktree-isolation behavior, not a plan deviation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix test test/scoria/adoption_surface_test.exs test/scoria/ai_doc_contract_test.exs test/scoria/terminology_contract_test.exs` is green (49 tests, 0 failures) with the new claim string present and all D-11 KEEP invariants intact.
- `mix format --check-formatted` clean for both edited `.ex` files.
- Plan 02 (conformance test) can now build on the D-10 sentence and the new `guides/capabilities/trace-observability.md` guide as its canonical target surface.

---
*Phase: 54-docs-accuracy-conformance-check*
*Completed: 2026-07-19*

## Self-Check: PASSED

All created/modified files verified present on disk; all 4 task/summary commit hashes (`02da9364`, `0ecac9fc`, `43ce17ee`, `3c0da73f`) verified present in git log.

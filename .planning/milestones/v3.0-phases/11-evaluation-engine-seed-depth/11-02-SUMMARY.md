---
phase: 11-evaluation-engine-seed-depth
plan: "02"
subsystem: testing
tags: [req_llm, vision, claude, content_part, json_validation, exunit]

# Dependency graph
requires: []
provides:
  - "Scoria.UICritique module: vision critique via ReqLLM ContentPart.image with 9-dimension rubric"
  - "parse_findings_json/2: strict 9-key {score 1..5, findings:[string]} contract enforcement"
  - "critique_screen/3: injectable req_llm_module for testability (mirrors JudgeRunner pattern)"
  - "10-test unit suite with no API dependency (async: true, ExUnit pure logic)"
affects:
  - 11-03-PLAN (Mix task that calls critique_screen/3)
  - 11-05-PLAN (baseline audit that drives the gap register)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ReqLLM injectable module pattern: req_llm_module opt defaults to Generation, overrideable in tests"
    - "ContentPart.image(binary, media_type) for vision calls — dogfoods Scoria's own LLM layer"
    - "Jason.decode! + pattern-match validation (no external validation dep) for strict contract"
    - "Markdown code-fence stripping before JSON decode for LLM response hygiene"
    - "async: true ExUnit tests for pure Elixir logic with no DB or app start"

key-files:
  created:
    - lib/scoria/ui_critique.ex
    - test/scoria/ui_critique_test.exs
  modified: []

key-decisions:
  - "UICritique raises Mix.Error (not {:error, ...}) on key-absent or API failure — matches Mix task consumer pattern"
  - "parse_findings_json/2 is public and pure — enables direct unit testing without File.read! or PNG fixture"
  - "ReqLLMStub uses real %ReqLLM.Response{} and %ReqLLM.Message{} structs with [ContentPart] list to match Response.text/1 implementation"
  - "Default model: anthropic:claude-sonnet-4-5 (capable vision model; Claude's discretion per RESEARCH D-03)"

patterns-established:
  - "Pattern: inject req_llm_module keyword opt (default: Generation) for test stubbing — mirrors JudgeRunner lines 66-69"
  - "Pattern: strip_code_fences/1 private helper decouples fence-stripping from decode — testable via parse_findings_json surface"

requirements-completed: [EVAL-02]

# Metrics
duration: 25min
completed: 2026-06-04
---

# Phase 11, Plan 02: UICritique Module Summary

**ReqLLM vision critique module with strict 9-key JSON contract enforcement and pure-logic unit test suite (EVAL-02)**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-04T00:00:00Z
- **Completed:** 2026-06-04
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `Scoria.UICritique` module using ReqLLM `ContentPart.image/2` for vision critique (dogfoods the existing LLM layer per D-03)
- Implemented strict `parse_findings_json/2` enforcing the 9-key `{score: 1–5, findings:[string]}` contract with fence-stripping and named-error raises
- Built 10-test ExUnit suite (`async: true`) covering positive, fence-strip, negative (missing key, out-of-range score, non-integer score), boundary values, and `critique_screen/3` happy path via `ReqLLMStub` — zero API calls

## Task Commits

1. **Task 1: UICritique module** - `3aab316` (feat)
2. **Task 2: UICritique unit tests** - `6862a7f` (test)

**Plan metadata:** see final commit below

## Files Created/Modified

- `/Users/jon/projects/scoria/lib/scoria/ui_critique.ex` — Vision critique service: `system_instruction/0`, `critique_screen/3` (injectable req_llm_module), `parse_findings_json/2` (pure, strict 9-key contract)
- `/Users/jon/projects/scoria/test/scoria/ui_critique_test.exs` — 10 unit tests: JSON shape (all 9 keys), fence-strip, assert_raise (missing key, score 6, score 0, score 3.5), boundary scores, empty findings, critique_screen happy path via ReqLLMStub

## Decisions Made

- Used `Mix.raise/1` (not `{:error, ...}`) in `critique_screen/3` error paths — the module is called from a Mix task consumer and this matches the existing project pattern (`scoria.post_publish_smoke.ex`)
- Made `parse_findings_json/2` a public function so it can be unit-tested directly without a PNG file or API call
- Chose `anthropic:claude-sonnet-4-5` as the default vision model (capable Claude vision model; Claude's discretion per RESEARCH D-03)
- `ReqLLMStub.generate_text/3` returns a proper `%ReqLLM.Response{}` with `%ReqLLM.Message{content: [%ContentPart{type: :text, text: json}]}` — required because `Response.text/1` calls `Enum.filter` on the content list (discovered during test run, fixed inline)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ReqLLMStub used string for message content instead of ContentPart list**
- **Found during:** Task 2 (UICritique unit tests)
- **Issue:** Initial `ReqLLMStub` set `message: %ReqLLM.Message{content: json_string}` — but `Response.text/1` calls `Enum.filter` on the content field (must be a list of `ContentPart` structs), causing `Protocol.UndefinedError` for BitString on `Enumerable`
- **Fix:** Changed stub to wrap JSON in `%ReqLLM.Message.ContentPart{type: :text, text: json}` and set `content: [text_part]` — matches actual `Response.text/1` implementation
- **Files modified:** `test/scoria/ui_critique_test.exs`
- **Verification:** `mix test test/scoria/ui_critique_test.exs` → 10 tests, 0 failures
- **Committed in:** `6862a7f` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — Bug)
**Impact on plan:** Fix was necessary for the test to correctly exercise the critique_screen happy path through the real Response.text/1 boundary. No scope creep.

## Threat Surface Scan

No new security-relevant surface beyond what the plan's `<threat_model>` already covers:
- `ANTHROPIC_API_KEY` never logged — handled (T-11-02 mitigated)
- `parse_findings_json/2` strictly validates LLM output — raises on any deviation (T-11-03 mitigated)
- Zero new Hex deps (T-11-SC: no install tasks, no slopcheck needed)

## Issues Encountered

- `ReqLLM.Response.text/1` requires `message.content` to be a list of `ContentPart` structs (Enumerable), not a raw string. Discovered from test failure, fixed immediately (see Deviations).

## User Setup Required

None — no external service configuration required for this plan. The `ANTHROPIC_API_KEY` path is exercised only in the live critique pass (Plan 05), not in these unit tests.

## Next Phase Readiness

- `Scoria.UICritique` is ready for Plan 03's Mix task to call `critique_screen/3`
- `parse_findings_json/2` contract is locked and unit-tested — Plan 03 can trust the return shape
- 10-test suite passes in `mix test test/scoria/ui_critique_test.exs` with 0 failures
- `mix compile --warnings-as-errors` is clean

---
*Phase: 11-evaluation-engine-seed-depth*
*Completed: 2026-06-04*

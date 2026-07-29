---
phase: 54-docs-accuracy-conformance-check
plan: 02
subsystem: testing
tags: [telemetry, opentelemetry, openinference, exunit, conformance, req_llm, jido, mcp]

# Dependency graph
requires:
  - phase: 51-53
    provides: Semconv/SpanKind/Bounds SSOT modules and the three span-emitting adapters (ReqLLM, MCP, Jido)
provides:
  - Falsifiable ExUnit conformance check proving all three span-emitting adapters only ever persist SSOT-allow-listed convention keys and a whitelisted span_kind
  - Registration of the check in the test.adoption lane for maintainer visibility
affects: [54-01 (DOCS-01 claim flip), future adapter changes to req_llm/mcp/jido]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Record-of-truth in-test replay: capture at the emit-layer telemetry event, then replay Redactor.redact/1 |> Bounds.enforce/2 in-test (no DB/Sandbox) to derive exactly what Buffer.cast_span/2 would persist."
    - "Execute-the-SSOT + exhaustiveness + guard-must-bite drift-guard idiom (mirrors span_kind_test.exs/semconv_test.exs)."

key-files:
  created:
    - test/scoria/observe/conformance_test.exs
  modified:
    - lib/mix/tasks/test.adoption.ex

key-decisions:
  - "Captured spans via a distinct telemetry handler id (scoria-observe-telemetry-test-conformance), never reusing a production handler id."
  - "Derived the post-Bounds record of truth by calling Redactor.redact/1 then Bounds.enforce/2 directly (the exact production functions, in production order) rather than reconstructing the admission rule from Semconv.attribute_registry/0 by hand."
  - "Scoped D-06 exhaustiveness to the 3 adapter-reachable span_kind values (llm/mcp/tool) rather than all 8 SpanKind.kinds() values, since the other 5 are emitted by Workflows.Runtime/Knowledge/JudgeRunner, not these adapters."
  - "Registered the new file as the 14th @adoption_test_files entry only — did not touch VerificationLanes.closeout_order/0 or the lane/CI contract tests."

requirements-completed: [DOCS-02]

coverage:
  - id: D1
    description: "Scoria.Observe.ConformanceTest drives ReqLLM/MCP/Jido live, derives the post-Bounds record of truth via in-test Redactor.redact/1 |> Bounds.enforce/2 replay, and asserts every surviving key is SSOT-admitted, span_kind is whitelisted, and the openinference.span.kind mirror matches SpanKind.to_openinference/1."
    requirement: "DOCS-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/conformance_test.exs (9 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-06 exhaustiveness scoped to the 3 adapter-reachable span_kind values (llm/mcp/tool) with a non-empty corpus per adapter, plus a host-override probe proving the override path is honored end-to-end."
    requirement: "DOCS-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/conformance_test.exs#D-06: exhaustiveness + non-empty corpus, scoped to adapter-reachable kinds"
        status: pass
    human_judgment: false
  - id: D3
    description: "Negative self-test proves the guard bites: a bogus attribute key is dropped by Bounds.enforce/2 and a bogus span_kind is SpanKind.kind?/1-false."
    requirement: "DOCS-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/conformance_test.exs#negative self-test: the guard must bite"
        status: pass
    human_judgment: false
  - id: D4
    description: "Jido's dropped-key classification: the pre-Bounds minus post-Bounds attribute key difference is asserted a subset of the documented drop-list (jido.action_name, jido.status), so a new silently-dropped key becomes a loud failure."
    requirement: "DOCS-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/conformance_test.exs#D-07 dropped-key classification: jido's silently-dropped keys are the documented set"
        status: pass
    human_judgment: false
  - id: D5
    description: "test/scoria/observe/conformance_test.exs registered as the 14th @adoption_test_files entry; mix test.adoption includes and passes it without touching closeout_order/0 or lane/CI contract tests."
    requirement: "DOCS-02"
    verification:
      - kind: unit
        ref: "mix test.adoption (82 tests + 3 doctests, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/scoria/verification_lanes_test.exs and test/scoria/ci_policy_contract_test.exs (65 tests, 0 failures — unchanged, byte-stable)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-18
status: complete
---

# Phase 54 Plan 02: Live ReqLLM/MCP/Jido Conformance Check Summary

**A falsifiable `Scoria.Observe.ConformanceTest` that replays the exact production `Redactor.redact/1 |> Bounds.enforce/2` pipeline in-test to prove all three span-emitting adapters (ReqLLM, MCP, Jido) only ever persist SSOT-allow-listed convention keys and a whitelisted `span_kind`, registered in `mix test.adoption`.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2 completed
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Added `test/scoria/observe/conformance_test.exs` (`Scoria.Observe.ConformanceTest`, `@moduletag :conformance`, `async: true`) that drives all three span-emitting adapters live via real telemetry events, captures the emit-layer span under a distinct handler id, and derives the post-`Bounds` "record of truth" by calling the exact two production functions (`Redactor.redact/1`, `Bounds.enforce/2`) in production order — no DB, no Sandbox, no golden fixture, no hand-copied allow-list.
- Proved DOCS-02's structural claim: every surviving attribute key is SSOT-admitted (via direct `Bounds.enforce/2` call), `span_kind` is drawn from `SpanKind.kinds()`, and `attributes["openinference.span.kind"]` mirrors `SpanKind.to_openinference/1` — for ReqLLM (`"llm"`), MCP (`"mcp"`, both `:completed` and `:timeout` terminal events), and Jido (`"tool"`).
- Scoped D-06 exhaustiveness correctly to the 3 adapter-reachable `span_kind` values (per RESEARCH.md's corrected scoping), with a non-empty corpus per adapter and a host-override probe (ReqLLM with `metadata[:span_kind] => "agent"`) proving the override mechanism is honored end-to-end.
- Added a negative self-test proving the guard actually bites: a deliberately bogus attribute key (`"totally.not.allowed"`) is dropped by `Bounds.enforce/2`, and a bogus `span_kind` (`"not_a_kind"`) is `SpanKind.kind?/1`-false — using the identical calls the positive assertions exercise.
- Added the D-07 dropped-key classification: computes the pre-Bounds minus post-Bounds attribute key difference for the jido corpus and asserts it is a subset of the documented drop-list (`jido.action_name`, `jido.status`), so any future silently-dropped key becomes a loud test failure instead of passing vacuously.
- Registered `test/scoria/observe/conformance_test.exs` as the 14th `@adoption_test_files` entry in `Mix.Tasks.Scoria.Test.Adoption` — a one-line append that gives the check adoption-lane visibility without touching `VerificationLanes.closeout_order/0` or the byte-stable lane/CI contract tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Conformance test — capture, in-test replay, positive assertions** - `99651f5a` (test)
2. **Task 2: Negative self-test + dropped-key bite + adoption registration** - `720bab13` (test)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP update, owned by orchestrator post-wave in worktree mode)

## Files Created/Modified
- `test/scoria/observe/conformance_test.exs` - New conformance test: live adapter capture, in-test `Redactor.redact/1 |> Bounds.enforce/2` replay, positive/negative/dropped-key assertions
- `lib/mix/tasks/test.adoption.ex` - Appended the 14th `@adoption_test_files` entry

## Decisions Made
- Used a distinct telemetry handler id (`"scoria-observe-telemetry-test-conformance"`) for capture, never reusing a production handler id (`"scoria-observe-reqllm"`/`"-mcp"`/`"-jido"`/`"-telemetry"`), per D-04's explicit instruction and to avoid `{:error, :already_exists}` collisions with boot-attached handlers.
- Derived the record of truth by calling `Redactor.redact/1` then `Bounds.enforce/2` directly (the same two production functions, in `telemetry.ex:69-71`'s exact order) instead of hand-reconstructing the admission rule from `Semconv.attribute_registry/0`/`vendor_key_prefixes/0` — per D-05's corrected resolution (`Bounds` exposes no public `admit?/1`, but `enforce/2` itself is the public SSOT function).
- Scoped D-06 exhaustiveness to the 3 adapter-reachable `span_kind` values (`llm`/`mcp`/`tool`) rather than attempting to exercise all 8 `SpanKind.kinds()` values — the other 5 (`agent`/`prompt`/`retriever`/`guardrail`/`eval`) are emitted by `Workflows.Runtime`/`Knowledge`/`JudgeRunner`, out of scope for an adapter-level conformance check (per RESEARCH.md item 4 / A2).
- Included one host-override probe (ReqLLM with `metadata[:span_kind] => "agent"`) to prove the override mechanism is honored end-to-end through `Bounds`/`SpanKind`, without attempting to enumerate all 7 non-default kinds (per RESEARCH.md Open Question 1's recommendation).
- Registered the file only in `@adoption_test_files` — did not wire it into `VerificationLanes.closeout_order/0` or any CI policy/lane contract (D-01/D-02), and did not modify the jido adapter or `Semconv.attribute_registry/0` (D-07's "compliant-by-enforcement" resolution — jido's raw `jido.action_name`/`jido.status` keys are proven dropped by `Bounds`, not registered).

## Deviations from Plan

None - plan executed exactly as written. Both tasks' acceptance criteria were met without needing Rule 1/2/3 auto-fixes; no architectural decisions (Rule 4) were required.

## Issues Encountered

None. The local dev environment's `deps/` and `_build/` were populated by symlinking `deps/` from the primary repo checkout (a local execution-environment convenience for this worktree — no repository files were affected) and setting `SCORIA_DB_PORT=55432` to reach the already-running dev Postgres container; the symlink was removed before finalizing this plan and is not part of any commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- DOCS-02 is fully satisfied: the "OpenInference-compatible" claim (DOCS-01, Plan 01) now has an executable, falsifiable backing that fails RED on real drift in any of the three adapters' emitted keys or `span_kind`.
- `mix test.adoption` is green (82 tests + 3 doctests) with the new conformance test included; `VerificationLanes.closeout_order/0` and the byte-stable lane/CI contract tests (`verification_lanes_test.exs`, `ci_policy_contract_test.exs`, 65 tests) are unchanged and green.
- No blockers for Phase 54's remaining work or Phase 54.1.

---
*Phase: 54-docs-accuracy-conformance-check*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: test/scoria/observe/conformance_test.exs
- FOUND: lib/mix/tasks/test.adoption.ex
- FOUND: .planning/phases/54-docs-accuracy-conformance-check/54-02-SUMMARY.md
- FOUND commit: 99651f5a (Task 1)
- FOUND commit: 720bab13 (Task 2)
- FOUND commit: 9ef34138 (SUMMARY)

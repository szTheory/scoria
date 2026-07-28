---
phase: 56-tool-declared-trifecta-classification-per-run-rails
plan: 02
subsystem: mcp-classification
tags: [elixir, mcp, telemetry, jsonb-persistence, semconv, trace-attributes]

# Dependency graph
requires:
  - phase: 56-tool-declared-trifecta-classification-per-run-rails
    provides: "Scoria.MCP.Classification struct/enum, MCP.Executor's resolve_classification/2 choke point (plan 56-01)"
provides:
  - "config :scoria, :require_tool_classification opt-in strict-refusal flag (default false)"
  - "{:error, %{status: :unclassified_tool, ...}} refusal envelope from MCP.Executor.execute/4"
  - "Scoria.MCP.Executor.persist_classification_to_step/3 -- durable step.result_envelope[\"scoria.classification\"]"
  - "Scoria.Observe.Semconv.classification_keys/0 and classification_attributes/1 (scoria.classification.* fixed-key projector)"
  - "attribute_registry/0 entries for the five scoria.classification.* keys"
affects: [56-03-remaining-fail-open-sites, phase-57-confluence-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Opt-in strict-refusal flag mirroring Scoria.Runtime.ReleaseGate.handle_missing_verdict/1's require_eval_verdict shape -- default-off, telemetry fires only on the ungated branch"
    - "jsonb fragment(\"? || ?\") merge choke point reused verbatim for a second independent top-level key (scoria.classification alongside scoria.taint)"
    - "Fixed-key Enum.reduce projector (no map spread) mirroring trust_attributes/1 and guardrail_attributes/1 -- SEC-01 discipline"

key-files:
  created: []
  modified:
    - lib/scoria/mcp/executor.ex
    - lib/scoria/observe/semconv.ex
    - test/scoria/mcp/classification_test.exs
    - test/scoria/mcp/executor_test.exs
    - test/scoria/mcp/executor_telemetry_test.exs
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "require_tool_classification gates on source == :unclassified_default specifically, never on \"was there a declaration\" -- a host-tightened resolution is a real classification and is never refused."
  - "persist_classification_to_step/3 is called from resolve_classification/2's non-refusal branch, at RESOLUTION time (before replay_gate/3), not from finalize_tool_result/5 -- so blocked and stubbed replay calls still get their classification persisted, unlike taint which only applies to completed {:ok, value} results."
  - "classification_attributes_for_telemetry/1 reads context[:tool_classification] (already resolved earlier in the same call) and merges into the EXISTING [:scoria, :tool, :completed] metadata -- no new span, :telemetry.execute( count in executor.ex stays at 7 before and after this plan."
  - "The SEC-01 registry canary in semconv_test.exs was deliberately edited (5 new sorted keys inserted between scoria.attributes.truncated_keys and scoria.guardrail.decision) -- the canary going RED was the guard working, not a regression to work around."

patterns-established: []

requirements-completed: [CLASS-02]

coverage:
  - id: D1
    description: "config :scoria, :require_tool_classification defaults to false; absent or false is byte-identical to pre-plan behavior (undeclared tool still runs, telemetry fires)"
    requirement: "CLASS-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#require_tool_classification strict refusal (D-03 opt-in flag, plan 56-02) flag absent (default false): an undeclared tool still runs and emits exactly one unclassified event"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#require_tool_classification strict refusal (D-03 opt-in flag, plan 56-02) flag explicitly false: identical to absent"
        status: pass
    human_judgment: false
  - id: D2
    description: "With the flag true, an undeclared tool is refused with {:error, %{status: :unclassified_tool, ...}}, the tool's execute/2 is never invoked, and zero [:scoria, :class, :unclassified] events fire; a declaring or host-tightened resolution is never refused"
    requirement: "CLASS-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#require_tool_classification strict refusal (D-03 opt-in flag, plan 56-02) flag true + an undeclared tool: refused with zero side effects and zero unclassified events"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#require_tool_classification strict refusal (D-03 opt-in flag, plan 56-02) flag true + a declaring tool: unaffected -- runs, no refusal, no unclassified event"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#require_tool_classification strict refusal (D-03 opt-in flag, plan 56-02) flag true + a host-tightened resolution: the flag refuses only genuinely unclassified calls, not this one"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every resolved classification (declared, host-tightened, or unclassified-default) is persisted to step.result_envelope[\"scoria.classification\"] as a jsonb merge with a string source, including for blocked/stubbed replay calls; a nil or unmatched step_id is a no-op, not an error"
    requirement: "CLASS-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#classification persisted to step.result_envelope (D-03/D-06, plan 56-02) persists action_class/source/legs/tool_ref for an undeclared tool (source: unclassified_default)"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#classification persisted to step.result_envelope (D-03/D-06, plan 56-02) persists source: tool_declared and the declared action_class for a declaring tool"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#classification persisted to step.result_envelope (D-03/D-06, plan 56-02) jsonb MERGE: a pre-existing scoria.taint key survives the classification write, persisted even for a replay-blocked call"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#classification persisted to step.result_envelope (D-03/D-06, plan 56-02) execute/4 with no :step_id in context returns the tool's normal result and raises nothing"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#classification persisted to step.result_envelope (D-03/D-06, plan 56-02) a :step_id that matches no row returns normally -- not an error"
        status: pass
    human_judgment: false
  - id: D4
    description: "Semconv.classification_attributes/1 is a fixed-key projector over exactly five scoria.classification.* keys, never spreads its input map, drops only nil (an explicit false leg is emitted), and the five keys are registered in attribute_registry/0 with legal classes plus the deliberate SEC-01 canary edit"
    requirement: "CLASS-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#classification_attributes/1 fixed-key projection (phase 56, CLASS-02) projects onto exactly the five scoria.classification.* keys, all registry keys, no extras"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#classification_attributes/1 fixed-key projection (phase 56, CLASS-02) an unlisted extra field (e.g. score or reason) is ignored -- exactly five keys emitted"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#classification_attributes/1 fixed-key projection (phase 56, CLASS-02) an explicit false-valued leg IS emitted -- only nil is dropped, never a truthiness check"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#attribute_registry/0 registry canary (SEC-01 Test 1) returns exactly the pinned sorted key list -- adding a key requires a deliberate edit here (D-06b)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The five scoria.classification.* attributes merge into the EXISTING [:scoria, :tool, :completed] telemetry event's metadata alongside scoria.trust.*, with no new span or second :telemetry.execute/3 call"
    requirement: "CLASS-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_telemetry_test.exs#completed MCP execution's [:scoria, :tool, :completed] metadata carries the five scoria.classification.* keys (phase 56, CLASS-02)"
        status: pass
      - kind: other
        ref: "grep -c ':telemetry.execute(' lib/scoria/mcp/executor.ex == 7 (unchanged before/after Task 3)"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-07-28
status: complete
---

# Phase 56 Plan 02: require_tool_classification, jsonb Persistence, and the scoria.classification.* Registry Summary

**The opt-in `require_tool_classification` strict-refusal path, `step.result_envelope["scoria.classification"]` jsonb persistence, and the closed `scoria.classification.*` trace-attribute projector complete CLASS-02's enforcement, replayability, and observability legs.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-07-28 (session start)
- **Completed:** 2026-07-28T16:47:58Z
- **Tasks:** 3 completed
- **Files modified:** 6 (0 created, 6 modified)

## Accomplishments

- `config :scoria, :require_tool_classification` (default `false`, no config-file entry) gates a genuine refusal path in `MCP.Executor.resolve_classification/2`: when truthy AND the resolved classification's `source` is `:unclassified_default`, `execute/4` returns `{:error, %{status: :unclassified_tool, reason_code: "tool_classification_required", tool_ref:, trace_id:, policy_key:}}` before `replay_gate/3` runs -- zero side effects (no budget reservation, no audit insert, no tool `Task`) -- and emits no `[:scoria, :class, :unclassified]` event, mirroring `Scoria.Runtime.ReleaseGate.handle_missing_verdict/1`'s `require_eval_verdict` shape exactly. A host-tightened resolution is never refused; the flag targets only genuinely unclassified calls.
- `persist_classification_to_step/3`, a near-identical sibling of `persist_taint_to_step/3`, durably writes every resolved classification (declared, host-tightened, or unclassified-default) onto `step.result_envelope["scoria.classification"]` via the same `fragment("? || ?", ...)` jsonb merge choke point, with `source` round-tripped through `to_string/1`. Called at RESOLUTION time (before `replay_gate/3`), so blocked and stubbed replay calls get their classification persisted too -- not just completed `{:ok, value}` results, satisfying D-06's Phase-57 cascade-mitigation obligation.
- `Scoria.Observe.Semconv.classification_keys/0` and `classification_attributes/1` project a `%Classification{}`-shaped map onto exactly the five `scoria.classification.*` keys (`action_class`, `source` as `:enum`; the three trifecta legs as `:flag`), registered in `attribute_registry/0`, with the SEC-01 canary in `semconv_test.exs` deliberately edited in the same commit. The projector never spreads its input map (only `nil` is dropped, `false` is emitted), so a free-text or score-shaped field is structurally impossible to leak.
- The five attributes merge into the EXISTING `[:scoria, :tool, :completed]` telemetry event's metadata alongside `scoria.trust.*` -- no new span, no second `:telemetry.execute/3` call (`grep -c ':telemetry.execute('` stays at 7 in `executor.ex` before and after this plan, confirmed by direct count).

## Task Commits

Each task was committed atomically:

1. **Task 1: `require_tool_classification` strict refusal path** - `156c354b` (feat)
2. **Task 2: Persist the resolved classification to `step.result_envelope`** - `6e64263d` (feat)
3. **Task 3: `scoria.classification.*` fixed-key projector, registry entries, and the deliberate canary edit** - `09ea904a` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified

- `lib/scoria/mcp/executor.ex` - `refuse_unclassified_tool?/1`, `unclassified_tool_envelope/2`, `persist_classification_to_step/3`, `classification_attributes_for_telemetry/1`, and the `[:scoria, :tool, :completed]` metadata merge
- `lib/scoria/observe/semconv.ex` - `@classification_keys`, `classification_keys/0`, `classification_attributes/1`, five new `attribute_registry/0` entries
- `test/scoria/mcp/classification_test.exs` - `RefusalProbeTool`, `HostTightenableTool` fixtures + full `require_tool_classification` behavior coverage
- `test/scoria/mcp/executor_test.exs` - `ClassifiedTool` fixture + full `scoria.classification` jsonb persistence coverage
- `test/scoria/mcp/executor_telemetry_test.exs` - assertion that `[:scoria, :tool, :completed]` metadata carries the five classification keys
- `test/scoria/observe/semconv_test.exs` - `classification_keys/0` + `classification_attributes/1` direct projector tests, canary list edit

## Decisions Made

- `require_tool_classification` gates on `source == :unclassified_default` specifically (D-03), never on "was there a tool declaration" -- a host-only declaration (`source: :host_tightened`) is a real classification and must never be refused. Verified with a dedicated test.
- `persist_classification_to_step/3` is invoked from `resolve_classification/2`'s non-refusal branch at RESOLUTION time, not from `finalize_tool_result/5` -- unlike taint (only meaningful for a completed `{:ok, value}` result), Phase 57 needs the classification of blocked and stubbed calls too. Never called on the strict-refusal branch: a refused call never runs and has no step evidence to attach.
- `classification_attributes_for_telemetry/1` sources its input from `context[:tool_classification]` (the struct `resolve_classification/2` already put there earlier in the same call), converts `source` with `to_string/1`, and merges into the SAME `[:scoria, :tool, :completed]` metadata map that already carries `trust_attrs` -- no second span (Phase 55 D-21 discipline unchanged).
- The SEC-01 registry canary in `semconv_test.exs` was deliberately edited to insert the five new sorted keys between `"scoria.attributes.truncated_keys"` and `"scoria.guardrail.decision"` -- the canary going RED here is the guard working as designed, not a regression to work around.
- Task 1 and Task 2's code both live inside `resolve_classification/2` and were interleaved during authoring; to keep the plan's per-task atomic-commit contract, the `persist_classification_to_step/3` call and definition were temporarily removed before committing Task 1, then re-added and committed separately as Task 2 (mirrors the split-commit technique already used in Phase 38-02).

## Deviations from Plan

None - plan executed exactly as written. All three tasks' `<action>` instructions were followed literally; no Rule 1/2/3 auto-fixes were needed, and no Rule 4 architectural questions arose.

## Issues Encountered

None specific to this plan's files. The full-suite run (`mix test --warnings-as-errors --seed 0`) showed exactly 1 failure out of 1467 tests: `Scoria.WarningInventory.CaptureParityTest` at `test/scoria/warning_inventory/capture_parity_test.exs:79` ("optimized compile-only capture catches high-signal unclassified warning (injected)") -- this is the pre-existing, previously-documented SEED-004-class async-ordering flake recorded in `STATE.md`'s Deferred Items table (`2026-07-18-flaky-capture-parity-test.md`) and confirmed unrelated to this plan's files (it was already present and out of scope in plan 56-01's own full-suite run). Per the environment notes, this was not chased.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `require_tool_classification` flag, `{:error, %{status: :unclassified_tool}}` envelope shape, `step.result_envelope["scoria.classification"]` jsonb key, and `scoria.classification.*` attribute keys are now the stable, published contract plan 56-03 (the remaining four fail-open sites: `policy_sensitive_invocation?/1`, `budget_required?/1`, `Connectors.Invocation.build_seam/2`, `Workflows.Runtime`'s default replay seam) and Phase 57 (the confluence gate) build on directly.
- D-06's cross-phase obligation is discharged: `source` is enforced (`@enforce_keys`), persisted as a string on every resolved call including blocked/stubbed replay calls, and projected onto a closed trace-attribute registry -- Phase 57 can give `:unclassified_default` an operator-selectable disposition separate from `:tool_declared` without any Phase-56 branching.
- No blockers. `mix compile --warnings-as-errors` exits 0; `mix test test/scoria/mcp/classification_test.exs test/scoria/mcp/executor_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/observe/semconv_test.exs --warnings-as-errors` exits 0 (119 tests, 0 failures); the full suite (`--seed 0`) is green except the documented pre-existing flake above.

---
*Phase: 56-tool-declared-trifecta-classification-per-run-rails*
*Completed: 2026-07-28*

## Self-Check: PASSED

All 6 modified files verified present on disk; all three task commit hashes (`156c354b`, `6e64263d`, `09ea904a`) verified present in `git log --oneline --all`.

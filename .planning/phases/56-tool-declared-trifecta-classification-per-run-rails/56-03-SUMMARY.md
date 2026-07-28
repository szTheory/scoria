---
phase: 56-tool-declared-trifecta-classification-per-run-rails
plan: 03
subsystem: mcp-classification
tags: [elixir, mcp, telemetry, replay-disposition, budget-engine, connectors, workflows-runtime]

# Dependency graph
requires:
  - phase: 56-tool-declared-trifecta-classification-per-run-rails
    provides: "Scoria.MCP.Classification struct/enum, MCP.Executor's resolve_classification/2 choke point (plan 56-01), require_tool_classification + jsonb persistence + scoria.classification.* registry (plan 56-02)"
provides:
  - "Scoria.MCP.Classification.declared_sensitive?/1 -- declared-only sensitivity predicate shared by sites 2 and 3"
  - "Scoria.MCP.Executor.policy_sensitive_invocation?/1 (site 2) and budget_required?/1 (site 3) both widened declared-only"
  - "Scoria.Connectors.Invocation.invoke/4 resolves the classification before its own replay decision (site 4), carrying it on build_seam/2's seam and forwarding it to Executor.execute/4"
  - "Scoria.Workflows.Runtime.default_replay_seam/2 -- the named, telemetried, classification-carrying replacement for the anonymous %{local_classification: :pure} default (site 5)"
affects: [phase-57-confluence-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared declared-only sensitivity predicate consumed by two independent gates (site 2 audit, site 3 budget) rather than duplicated inline logic"
    - "Idempotent classification resolution reused across two entry points (Connectors.Invocation and MCP.Executor) via the same struct-shape match guard"
    - "Named default-seam helper mirroring Scoria.Runtime.ReleaseGate.handle_missing_verdict/1's defaulted-path-emits-telemetry shape"

key-files:
  created: []
  modified:
    - lib/scoria/mcp/classification.ex
    - lib/scoria/mcp/executor.ex
    - lib/scoria/connectors/invocation.ex
    - lib/scoria/workflows/runtime.ex
    - test/scoria/mcp/classification_test.exs
    - test/scoria/mcp/executor_test.exs
    - test/scoria/connectors/invocation_test.exs
    - test/scoria/workflows/replay_disposition_test.exs

key-decisions:
  - "D-A2 (locked, plan 56-01 naming, implemented here): consumption at sites 2/3 is read-side and declared-only -- declared_sensitive?/1 never writes into :policy_sensitive, :sensitive_tool, :approval_sensitive, :local_classification, :action_class, or :risk_level, and returns false for :unclassified_default so legacy traffic (no tool declares classification/0) is byte-identical."
  - "declared_sensitive?/1 is derived from action_classes/0 (Enum.drop(action_classes(), 2), i.e. exec-and-above) rather than a second literal [\"exec\", \"admin\"] list, so it tracks the enum if it ever grows."
  - "Site 4's resolution and site 5's default both route through Classification.tool_declaration/1 + Classification.resolve/2 directly (not a shared wrapper with the executor's refusal logic) -- D-03 scopes require_tool_classification's refusal to MCP.Executor resolution only; sites 4 and 5 deliberately never consult or extend it."
  - "Site 5's default_replay_seam/2 keeps local_classification: :pure byte-identical and ADDS tool_classification alongside it -- the value ReplayDisposition.pure_local?/1 short-circuits on is unchanged, only what rides alongside it changed."

patterns-established: []

requirements-completed: [CLASS-03]

coverage:
  - id: D1
    description: "declared_sensitive?/1 is a strict, declared-only boolean predicate: false for nil and :unclassified_default (D-04's fallback is never an operand), true for a tool_declared/host_tightened struct with can_exfiltrate: true or action_class in [exec, admin]"
    requirement: "CLASS-03"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/classification_test.exs#declared_sensitive?/1 (D-A2, plan 56-03)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sites 2 (policy_sensitive_invocation?/1) and 3 (budget_required?/1) each gain declared_sensitive?/1 as one additional OR operand; an undeclared tool with a bare context writes zero audit rows and reserves zero budget (byte-identical to pre-phase), while a can_exfiltrate: true or action_class: admin declaring tool now writes one tool.invocation row and reserves budget on its own declaration"
    requirement: "CLASS-03"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#declared_sensitive?/1 widens sites 2 and 3 declared-only (D-A2, plan 56-03)"
        status: pass
      - kind: other
        ref: "git diff lib/scoria/mcp/executor.ex -- both predicates' pre-existing operands unchanged, one OR term added each"
        status: pass
    human_judgment: false
  - id: D3
    description: "Connectors.Invocation.invoke/4 resolves the classification immediately after normalize_map(context) and before build_seam/2 (and therefore before replay_resolution/5); build_seam/2 carries :tool_classification as one new entry with the four pre-existing seam defaults (action_class, risk_level, approval_sensitive, local_classification) byte-unchanged; exactly one [:scoria, :class, :unclassified] event fires per call (site: :connector_invocation), reused (not re-resolved) by Executor.execute/4"
    requirement: "CLASS-03"
    verification:
      - kind: unit
        ref: "test/scoria/connectors/invocation_test.exs#Site 4 (D-05, plan 56-03): classification resolved before Invocation's own replay decision"
        status: pass
      - kind: other
        ref: "git diff lib/scoria/connectors/invocation.ex -- build_seam/2 gains exactly one pipeline step, four pre-existing lines unchanged"
        status: pass
    human_judgment: false
  - id: D4
    description: "Workflows.Runtime.replay_execution/8's anonymous %{local_classification: :pure} default is replaced by a named default_replay_seam(run, step) helper that keeps :pure byte-identical, adds tool_classification: Classification.unclassified_default(), and emits one [:scoria, :class, :unclassified] event (site: :workflow_runtime_step) only when the caller supplied no :replay_seam; the resulting disposition is still {:execute_live, %{replay_reason_code: \"local_safe_to_rerun\"}}; require_tool_classification is not consulted or extended here"
    requirement: "CLASS-03"
    verification:
      - kind: unit
        ref: "test/scoria/workflows/replay_disposition_test.exs#site-5 named default seam shape (plan 56-03, Workflows.Runtime.default_replay_seam/2)"
        status: pass
      - kind: other
        ref: "grep -n \"local_classification: :pure\" lib/scoria/workflows/runtime.ex (unchanged value) + grep -n \"require_tool_classification\" lib/scoria/workflows/runtime.ex (no match, not extended)"
        status: pass
    human_judgment: false
  - id: D5
    description: "All five D-05 fail-open sites now consume the resolved classification; full-suite regression proof that legacy (undeclared-tool) traffic and every pre-existing replay disposition are unchanged"
    requirement: "CLASS-03"
    verification:
      - kind: unit
        ref: "mix test --warnings-as-errors --seed 0 (1480 tests, 1 pre-existing SEED-004-class flake, 0 regressions)"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-07-28
status: complete
---

# Phase 56 Plan 03: All Five D-05 Fail-Open Sites Consume the Resolved Classification Summary

**`Classification.declared_sensitive?/1` closes sites 2/3 declared-only, `Connectors.Invocation` resolves before its own replay decision (site 4), and `Workflows.Runtime` replaces its anonymous `:pure` replay bypass with a named, telemetried, classification-carrying default (site 5) -- completing CLASS-03 and all of Phase 56.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-28 (session start)
- **Completed:** 2026-07-28T17:17:00Z
- **Tasks:** 3 completed
- **Files modified:** 8 (0 created, 8 modified)

## Accomplishments

- `Scoria.MCP.Classification.declared_sensitive?/1`: a strict, declared-only boolean predicate. `false` for `nil` and for any `:unclassified_default` classification (D-04's fallback is never an operand, verified with an explicit test); `true` for a `:tool_declared`/`:host_tightened` struct with `can_exfiltrate: true` or `action_class` in `Enum.drop(action_classes(), 2)` (`["exec", "admin"]`), derived from the enum rather than a second literal list.
- Site 2 (`policy_sensitive_invocation?/1`) and site 3 (`budget_required?/1`) in `MCP.Executor` each gain `declared_sensitive?/1` as one additional OR operand -- the SAME shared predicate, so the two sites cannot drift apart. Both predicates' pre-existing operands and legacy return semantics are byte-unchanged; an undeclared tool with a bare context still writes zero `tool.invocation` audit rows and reserves zero budget, while a tool declaring `can_exfiltrate: true` or `action_class: "admin"` now writes one audit row and reserves budget on its own declaration, even with no host-passed `:policy_sensitive`/`:sensitive_tool`.
- `Scoria.Connectors.Invocation.invoke/4` (site 4) resolves the tool's classification immediately after `normalize_map(context)`, BEFORE `build_seam/2` and therefore before `replay_resolution/5` -- a connector-routed tool's replay decision is now made with the classification already present. `build_seam/2` carries `:tool_classification` as one new parallel entry; the four pre-existing seam defaults (`action_class`, `risk_level`, `approval_sensitive`, `local_classification`) are byte-unchanged. Exactly one `[:scoria, :class, :unclassified]` event fires per call (`site: :connector_invocation`); `Executor.execute/4`'s existing idempotence guard (already matching on the `%Classification{}` struct shape, not mere key presence) reuses the injected value with no second resolution or emission -- verified directly, no `executor.ex` change was needed for this guarantee.
- `Scoria.Workflows.Runtime.replay_execution/8`'s anonymous inline default (`Keyword.get(opts, :replay_seam, %{local_classification: :pure})`, site 5, "the worst" per D-05) is replaced by `Keyword.get(opts, :replay_seam) || default_replay_seam(run, step)` -- a single named, documented helper. `local_classification: :pure` is carried EXACTLY as before (load-bearing: `ReplayDisposition.pure_local?/1` clause 3 still short-circuits to `:execute_live` before clause 7 ever runs); the helper ADDS `tool_classification: Classification.unclassified_default()` alongside it and emits one `[:scoria, :class, :unclassified]` event (`site: :workflow_runtime_step`) only when the caller supplied no `:replay_seam`. `require_tool_classification` is deliberately not consulted or extended here (documented inline) -- there is no tool module at this site to classify.
- All five D-05 fail-open sites now consume the resolved classification. CLASS-03 is complete; CLASS-01, CLASS-02, and CLASS-03 are all closed for Phase 56.

## Task Commits

Each task was committed atomically:

1. **Task 1: Site inventory re-verification + sites 2 and 3 consume the classification declared-only** - `c5ab5249` (feat)
2. **Task 2: Site 4 -- `Connectors.Invocation` resolves before its own replay decision** - `317b9f5b` (feat)
3. **Task 3: Site 5 -- replace `Workflows.Runtime`'s anonymous `:pure` bypass with a named, telemetried, classification-carrying default** - `e6b4a945` (feat)
4. **Fix: reword comments so the `declared_sensitive?` acceptance-criteria grep count stays exactly 2** - `b1ff3019` (fix, part of Task 1's scope)

**Plan metadata:** (this commit, following)

## Files Created/Modified

- `lib/scoria/mcp/classification.ex` - `declared_sensitive?/1`: declared-only sensitivity predicate
- `lib/scoria/mcp/executor.ex` - `policy_sensitive_invocation?/1` (site 2) and `budget_required?/1` (site 3) each gain one OR operand
- `lib/scoria/connectors/invocation.ex` - `invoke/4` resolves classification before `build_seam/2`; `build_seam/2` +1 entry; new `resolve_tool_classification/2` + `maybe_emit_unclassified/3` helpers
- `lib/scoria/workflows/runtime.ex` - `replay_execution/8`'s site-5 default extracted to named `default_replay_seam/2` + `emit_workflow_runtime_step_unclassified/2`
- `test/scoria/mcp/classification_test.exs` - `declared_sensitive?/1` matrix; budget-policy fixture added to 3 pre-existing `DeclaringTool` end-to-end tests that now legitimately require one
- `test/scoria/mcp/executor_test.exs` - `ExfiltratingTool`/`AdminActionTool` fixtures + four end-to-end declared-sensitive? rows
- `test/scoria/connectors/invocation_test.exs` - `ClassifiedReplayTool` fixture + site-4 single-emission and context-forwarding tests
- `test/scoria/workflows/replay_disposition_test.exs` - site-5 named-default-seam shape test

## Decisions Made

- **D-A2** (locked in `56-CONTEXT.md`, implemented as written): consumption at sites 2/3 is read-side and declared-only -- `declared_sensitive?/1` never writes into any of the six prohibited context keys, and `:unclassified_default` is never an operand, so legacy (no-declaration) traffic is byte-identical.
- `declared_sensitive?/1`'s "exec and above" threshold is derived from `Enum.drop(action_classes(), 2)` rather than a second literal `["exec", "admin"]` list, so it tracks the enum if it ever grows (documented in the function's `@doc`).
- Site 4 and site 5 both route through `Classification.tool_declaration/1` + `Classification.resolve/2` directly rather than reusing the executor's private `resolve_classification/2` wholesale -- D-03 scopes the `require_tool_classification` strict-refusal path to `MCP.Executor` resolution only, and both new call sites deliberately never consult or extend it (site 4 has a tool module but the prohibition explicitly names it out of scope for this phase; site 5 has no tool module at all).
- Site 5's `default_replay_seam/2` keeps `local_classification: :pure` byte-identical and ADDS `tool_classification` alongside it -- the value `ReplayDisposition.pure_local?/1` short-circuits on is unchanged; only what rides alongside it changed. This mirrors `Scoria.Runtime.ReleaseGate.handle_missing_verdict/1`'s "defaulted/ungated path emits telemetry, gated path is silent" precedent.
- Task 2's `<files>` list named `lib/scoria/mcp/executor.ex` for verifying the idempotence guard still holds; on inspection the guard already matches on `%Classification{}` struct shape (not key presence), so no executor.ex change was needed for Task 2 -- confirmed by a dedicated single-emission test in `invocation_test.exs` instead.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a real cross-cutting regression: `DeclaringTool` legitimately trips the new `budget_required?/1` operand in three pre-existing `classification_test.exs` cases**
- **Found during:** Task 1, running `mix test test/scoria/mcp/classification_test.exs test/scoria/mcp/executor_test.exs --warnings-as-errors`
- **Issue:** `classification_test.exs`'s pre-existing `DeclaringTool` fixture declares `can_exfiltrate: true, action_class: "exec"` -- exactly the shape `declared_sensitive?/1` is designed to catch. Three pre-existing end-to-end tests routing `DeclaringTool` through `Executor.execute/4` now legitimately require budget reservation, but the file had no budget policy fixture and one test passed no `tenant_id` at all, so `BudgetEngine.reserve_step/1` either raised (`ArgumentError`, comparing a nil tenant_id) or returned `{:error, budget_policy_not_found}`, aborting the whole call before it reached the assertions under test.
- **Fix:** Added a `create_budget_policy!/2` test helper (mirroring the one already in `executor_test.exs`) and called it in the three affected tests, plus added an explicit `tenant_id: "tenant-1"` to the one test that previously passed none. This is the fail-open seam genuinely closing for a declaring tool -- the correct fix is a real budget policy fixture, not weakening `declared_sensitive?/1`.
- **Files modified:** `test/scoria/mcp/classification_test.exs`
- **Verification:** `mix test test/scoria/mcp/classification_test.exs test/scoria/mcp/executor_test.exs --warnings-as-errors` -- 74 tests, 0 failures.
- **Committed in:** `c5ab5249` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed a grep-count acceptance-criteria collision from explanatory comments**
- **Found during:** Task 1, running the plan's own acceptance-criteria greps after implementation
- **Issue:** The plan's acceptance criteria expect `grep -n "declared_sensitive?" lib/scoria/mcp/executor.ex` to match exactly twice (the two real call sites). My explanatory comments above each call site also named the function verbatim, bringing the literal grep count to 4 -- the same class of collision plan 56-01 hit with its leaf-discipline moduledoc prose grep.
- **Fix:** Reworded both comments to describe "the shared predicate" without repeating the function name verbatim; the grep now returns exactly 2.
- **Files modified:** `lib/scoria/mcp/executor.ex`
- **Verification:** `grep -c "declared_sensitive?" lib/scoria/mcp/executor.ex` returns `2`; `mix test test/scoria/mcp/ test/scoria/workflows/ test/scoria/connectors/ --warnings-as-errors` -- 185 tests, 0 failures.
- **Committed in:** `b1ff3019` (separate fix commit, part of Task 1's scope)

**3. [Rule 1 - Bug] Test names too long for `list_to_atom`**
- **Found during:** Task 2 and Task 3, compiling the new test files
- **Issue:** Elixir's compiler generates an atom name for each test that includes its full describe-block name plus test name; two of my initially-written test names (site 4's undeclared-tool test, and site 5's describe/test pairing) exceeded the 255-character or atom-table limit, producing a `SystemLimitError` / compile error.
- **Fix:** Shortened the test names while keeping the same assertions and intent.
- **Files modified:** `test/scoria/connectors/invocation_test.exs`, `test/scoria/workflows/replay_disposition_test.exs`
- **Verification:** Both files compile and their tests pass.
- **Committed in:** `317b9f5b` (Task 2), `e6b4a945` (Task 3)

---

**Total deviations:** 3 auto-fixed (1 real cross-cutting test regression, 1 grep-count/comment-wording collision, 1 test-name-length compile fix)
**Impact on plan:** All three were necessary for a green `--warnings-as-errors` build and a green pre-existing test suite; none represent scope creep beyond what this plan's own changes directly caused.

## Issues Encountered

- The full-suite run (`mix test --warnings-as-errors --seed 0`) showed exactly 1 failure out of 1480 tests (3 doctests): `Scoria.WarningInventory.CaptureParityTest` at `test/scoria/warning_inventory/capture_parity_test.exs:53` ("optimized compile-only capture catches high-signal unclassified warning (injected)") -- this is the pre-existing, previously-documented `2026-07-18-flaky-capture-parity-test.md` SEED-004-class async-ordering flake recorded in `STATE.md`'s Deferred Items table, and was already present and out of scope in plans 56-01's and 56-02's own full-suite runs. Per the environment notes, this was not chased.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ROADMAP Phase 56 Success Criterion 4 is satisfied end-to-end: resolution now covers ALL five fail-open seams -- the replay seam (site 1, plan 56-01), `policy_sensitive_invocation?/1` (site 2), `budget_required?/1` (site 3), `Connectors.Invocation.build_seam/2` (site 4), and `Workflows.Runtime`'s `%{local_classification: :pure}` default (site 5). None is scoped out; site 5's treatment (a step-granularity default that is now inspectable but structurally unchanged) is documented in code as this plan required.
- CLASS-01, CLASS-02, and CLASS-03 are all closed. Phase 56 (tool-declared trifecta classification) is complete and ready to feed Phase 57's confluence escalation gate, which was the stated dependency in `ROADMAP.md:72`.
- No Ecto migration and no schema change exists anywhere in this phase (`git status --porcelain priv/repo/migrations/` returns 0 lines) -- the Phase 56.1 scope fence (per-run rails, deferred separately) holds.
- No blockers. `mix compile --warnings-as-errors` exits 0; the plan's pinned quick run (`test/scoria/mcp/classification_test.exs test/scoria/mcp/executor_test.exs test/scoria/workflows/replay_disposition_test.exs test/scoria/connectors/invocation_test.exs --warnings-as-errors`) exits 0 (91 tests); the full suite (`--seed 0`) is green except the documented pre-existing flake above.

---
*Phase: 56-tool-declared-trifecta-classification-per-run-rails*
*Completed: 2026-07-28*

## Self-Check: PASSED

All 8 modified files verified present on disk; all four commit hashes (`c5ab5249`, `317b9f5b`, `e6b4a945`, `b1ff3019`) verified present in `git log --oneline --all`.

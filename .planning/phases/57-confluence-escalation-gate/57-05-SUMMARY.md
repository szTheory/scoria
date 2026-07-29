---
phase: 57-confluence-escalation-gate
plan: 05
subsystem: agent-security
tags: [elixir, ecto, confluence-gate, telemetry, mcp, workflows, postgres]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "confluence_gate/3 insertion point, the exit({:shutdown, ...}) signal, the D-47 migration (consumed_at/consumed_by_step_id/confluence_scope), and the D-25/D-50 locked checkpoint decisions"
  - phase: 57-confluence-escalation-gate
    plan: 02
    provides: "Confluence.classify/1's total combination ladder, grade/1, decide/2, resolve_config/1 -- all called live by this plan's evaluate_confluence/5"
  - phase: 57-confluence-escalation-gate
    plan: 03
    provides: "the mint-site taint repair and %Trust.Verdict{}.scanner_tier evidence field this plan reconciles into Semconv's closed registry"
provides:
  - "Approval-consume CAS (D-26): confluence_gate/3's FIRST action, single-statement Repo.update_all mirroring Rails.admit_tool_call/2, with a nil-fingerprint fail-closed guard, a rejected-match deny path, and a run_tool-scoped non-consuming match bounded to the structurally-declared grade (D-44/D-50)"
  - "Attribution + containment resolution (D-18/D-21/D-22): unattributed and uncontained calls default to allow with skipped telemetry and never create an approval row; containment proven via a process-dictionary marker resolved through self()/$callers"
  - "canonical_context/1's :workflow_run_id -> :run_id alias, and the fixed in-repo reference fixture (runtime_span_test.exs) that now forwards run_id/step_id"
  - "resolve_classification/2's idempotence clause gated on classification source (D-35 bypass fix)"
  - "One always-on [:scoria, :gate, :confluence, :observed] telemetry event per evaluation on all three dispositions (D-36), decision carried as a metadata tag, projected through Semconv.confluence_attributes/1"
  - "scanner_tier reconciled into Semconv's closed attribute_registry/0 (fixes the SEC-01 hole plan 57-03 flagged and deferred)"
affects: [57-06, 57-07, 57-08, 57-09, 57-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-arm approval-consume CAS: a consuming single-statement Repo.update_all for 'call' scope (mirrors Rails.admit_tool_call/2 exactly), and a separate non-consuming Repo.exists? for 'run_tool' scope, structurally guarded to the 'declared' grade via a pattern-match head rather than a stored column"
    - "Containment proof via Process.get(:\"$callers\", []) non-emptiness (Task.async/Task.Supervisor.async_nolink/Task.async_stream all propagate it transitively and automatically) plus an explicit Scoria-owned process-dictionary marker cached once proven, checked on self() and on every named $callers pid's own dictionary"
    - "decide/2 + resolve_config/1 called live per evaluation (not hand-rolled), so the enforcement:observe kill switch and per-call/app-env config tightening apply to the escalation decision automatically without duplicating Confluence's own logic in the executor"

key-files:
  created: []
  modified:
    - lib/scoria/mcp/executor.ex
    - lib/scoria/observe/semconv.ex
    - test/scoria/mcp/executor_confluence_test.exs
    - test/scoria/workflows/runtime_span_test.exs
    - test/scoria/observe/semconv_test.exs
    - test/scoria/connectors/invocation_test.exs

key-decisions:
  - "The 'run_tool' scope match is guarded by an explicit `\"declared\"` pattern-match head (with a `_other_grade -> false` catch-all) rather than a stored grade column on ai_approvals -- there is no such column, and every run_tool approval that can currently exist was necessarily created for a declared-grade escalation (the only grade this plan's confluence_input/2 can construct), so the guard is structural, not assumed. The 'different grade' bound from the plan's acceptance criteria is consequently unreachable via Executor.execute/4's public API in this plan's scope (grade is always \"declared\" or nil through the current declared-only leg sourcing) and is instead asserted via a source-scan test."
  - "decide/2 + resolve_config/1 are called live in evaluate_confluence/5 rather than reimplementing a narrower escalate/allow check -- this correctly wires D-31's enforcement:observe kill switch and D-33's tighten-only-over-may-loosen config precedence into the live decision with no duplicated logic, while remaining behaviorally identical to the pre-existing narrow check under shipped defaults (only the declared grade ever resolves \"escalate\")."
  - "Run.halted?/1 is checked BEFORE the containment check in resolve_escalation/6 (not after, as an initial draft had it) -- a halt denial never calls exit/1, so it carries none of the risk containment guards against, and an existing plan-01 test (a bare, non-Task-wrapped call) proved that ordering matters: checking containment first would have routed a halted-but-uncontained call through the allow branch, silently defeating D-24's halt-beats-everything invariant."
  - "scanner_tier is reconciled into Semconv.trust_keys/0 and attribute_registry/0 (registry canary 49 -> 50 keys) rather than left as plan 57-03's hand-injected key, per the wave_context's explicit authorization to edit semconv.ex/semconv_test.exs for this purpose."

requirements-completed: [GATE-02, GATE-04]

coverage:
  - id: D1
    description: "The gate's first action is a single-statement approval-consume CAS; a matching approved+unconsumed call-scope approval passes through and is consumed exactly once; a nil args fingerprint fails closed; a rejected match denies without re-escalating; a run_tool-scoped grant matches same-tool/same-run calls without being consumed and does not match a different tool or run"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"approval consume (D-26)\""
        status: pass
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"run-scoped grant (confluence_scope: \\\"run_tool\\\", D-44/D-50)\""
        status: pass
    human_judgment: false
  - id: D2
    description: "A tool call with no run/step attribution resolves to unattributed/allow with skipped telemetry and no approval row; a raw spawn resolves as uncontained/allow with skipped telemetry; Task.async and Task.async_stream nesting are treated as contained; canonical_context/1 aliases :workflow_run_id to :run_id"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"attribution and containment (D-21, D-22)\""
        status: pass
    human_judgment: false
  - id: D3
    description: "resolve_classification/2's idempotence clause is gated on classification source -- a pre-resolved unclassified-default classification no longer bypasses require_tool_classification, while a declared-source classification still short-circuits"
    requirement: "GATE-02"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"resolve_classification/2 idempotence clause gated on source (D-35)\""
        status: pass
    human_judgment: false
  - id: D4
    description: "Exactly one confluence gate telemetry event fires per evaluation on all three dispositions (allow/escalate/block), decision as a metadata tag, empty measurements, grade/combination/action_class/leg sources in metadata; a raising handler cannot break the tool call"
    requirement: "GATE-04"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_confluence_test.exs#describe \"one always-on gate telemetry event (D-36)\""
        status: pass
    human_judgment: false

duration: 46min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 05: Approval-Consume CAS, Attribution/Containment, and Always-On Gate Telemetry Summary

**Wired the confluence gate's three cross-cutting concerns into `MCP.Executor`: an atomic approval-consume CAS that stops the resume loop, attribution+containment resolution that decides whether a call can safely be paused at all, and one always-on telemetry event per evaluation carrying the decision as a tag on all three dispositions.**

## Performance

- **Duration:** 46 min (git-timestamp span from base commit `a401b56a` to final commit `8f714a2c`; includes worktree setup, `mix deps.get`, extensive design work reconciling the containment-check backward-compatibility constraint, and full-suite verification)
- **Started:** 2026-07-28T23:02:25-04:00 (base commit)
- **Completed:** 2026-07-28T23:48:11-04:00
- **Tasks:** 3 (all `auto`/`tdd="true"` except Task 3, which is `auto`)
- **Files modified:** 6 (0 created, 6 modified)

## Accomplishments

- `confluence_gate/3`'s FIRST action is now the D-26 approval-consume CAS: `consume_call_scope/3` is a single-statement `Repo.update_all` mirroring `Rails.admit_tool_call/2`'s exact shape (query guard clauses in `where`, one update, a two-element tuple match). A `nil` args fingerprint never matches (fails closed); a matching `"rejected"` approval denies with reason code `"confluence_rejected"` and never re-escalates; a matching `"call"`-scoped `"approved"` approval passes through and is consumed exactly once (`consumed_at`/`consumed_by_step_id` set), so a resumed run never re-escalates the identical call.
- A `"run_tool"`-scoped grant (D-44/D-50, the developer-selected bounded per-run/per-tool/per-grade scope recorded verbatim in `57-01-SUMMARY.md`) matches on run id + tool name via a **structural, pattern-matched `"declared"` grade guard** (`run_tool_scope_granted?/3`'s match head, with an explicit `_other_grade -> false` fallback) and is deliberately never consumed, so it stays usable for the rest of the granting run.
- Attribution resolution (D-18/D-22): a call with no run/step attribution resolves the `unattributed` config key (shipped default `:allow`) rather than deny-by-default — Scoria's own reference handler didn't forward the keys the gate depends on until this plan fixed it.
- Containment resolution (D-21): a process-dictionary marker (`@confluence_containment_key`) checked via `self()` first, then every pid named in `Process.get(:"$callers", [])`. Since `Task.async`/`Task.Supervisor.async(_nolink)`/`Task.async_stream` all propagate `$callers` transitively and automatically, this covers arbitrary nesting depth of both idioms with zero additional Scoria-side wiring; a raw `spawn/1` propagates neither the process dictionary nor `$callers` and is the honest, telemetried residual — never papered over, never silently escalated. **Design note:** `Run.halted?/1` is checked *before* containment in `resolve_escalation/6` — a halt denial never calls `exit/1`, so it carries none of the risk containment exists to guard against, and an existing plan-01 test (a bare, non-Task-wrapped call to a halted run) proved this ordering is load-bearing.
- `canonical_context/1` now aliases `:workflow_run_id` to `:run_id` (D-22), and the in-repo reference fixture in `test/scoria/workflows/runtime_span_test.exs`'s `Handlers.full_tree/2` now forwards both `run_id` and `step_id` alongside the pre-existing `workflow_run_id`, so the canonical copy-paste an adopter has is attributable to the gate.
- `resolve_classification/2`'s idempotence clause is now gated on the classification's `source` (D-35): only a genuinely resolved (`:tool_declared`/`:host_tightened`) pre-existing classification short-circuits re-resolution; a pre-resolved `source: :unclassified_default` classification — injected by both `Connectors.Invocation.invoke/4`'s `resolve_tool_classification/2` and `Workflows.Runtime`'s `default_replay_seam/2` — no longer bypasses `refuse_unclassified_tool?/1`, closing a silent `require_tool_classification` bypass on both of those seams.
- Exactly one `[:scoria, :gate, :confluence, :observed]` telemetry event fires per confluence evaluation on all three dispositions (allow/escalate/block, D-36), `decision` carried as a metadata tag rather than separate per-decision events. The span-bound half is projected through `Semconv.confluence_attributes/1` (no unregistered field can ride along); `run_id`/`step_id`/`trace_id` ride as correlation identifiers only. Every emit — this event and the `[:scoria, :gate, :confluence, :skipped]` unattributed/uncontained event — is wrapped so a raising host handler cannot break the tool call.
- **Reconciliation (wave context):** `scanner_tier` — hand-injected by plan 57-03 as a stopgap because `semconv.ex` was outside that plan's file scope — is now registered in `Semconv.trust_keys/0` and `attribute_registry/0` (a fifth entry, `:enum` class) and routed through `trust_attributes/1`'s closed projector instead of a bare `Map.put`. The sorted registry canary in `semconv_test.exs` moved from 49 to 50 keys.

## Task Commits

1. **Reconciliation: register `scanner_tier` in Semconv's closed trust-key registry** - `b277b24e` (fix)
2. **Tasks 1-3: approval-consume CAS, attribution/containment resolution, and always-on gate telemetry** - `ad35b922` (feat) — landed as one commit; see "Deviations" for why.
3. **Deviation fix: update `invocation_test.exs` for the D-35 idempotence-clause fix** - `8f714a2c` (fix)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/mcp/executor.ex` — `confluence_gate/3` rewritten: `consume_confluence_approval/3` + `consume_call_scope/3` + `resolve_non_consuming_match/2` (D-26 CAS), `run_tool_scope_granted?/3` (D-44/D-50), `evaluate_confluence/5` + `confluence_decision/2` + `attach_confluence_idempotency_key/3` (live `decide/2`/`resolve_config/1` wiring), `resolve_escalation/6` + `apply_unattributed_disposition/3` (D-18/D-22/D-24 ordering), `confluence_contained?/0` + `confluence_ancestor_marked?/1` (D-21), `emit_confluence_skipped/3` + `emit_confluence_observed/5` (D-36), `resolve_classification/2`'s source-gated idempotence clause (D-35), `canonical_context/1`'s `maybe_alias_run_id/1` (D-22), `scan_tool_output/2`'s `scanner_tier` now routed through `Semconv.trust_attributes/1`
- `lib/scoria/observe/semconv.ex` — `:scanner_tier` added to `@trust_keys`/`attribute_registry/0`
- `test/scoria/mcp/executor_confluence_test.exs` — new `ThreeLegTool`-adjacent fixtures (`OtherThreeLegTool`, `ExfilOnlyTool`, `UndeclaredTool`), `insert_confluence_approval!/2`, `create_budget_policy!/2`, `attach_confluence_telemetry/1` helpers; new `describe` blocks: "approval consume (D-26)", "run-scoped grant", "attribution and containment (D-21, D-22)", "resolve_classification/2 idempotence clause gated on source (D-35)", "one always-on gate telemetry event (D-36)" (22 new tests)
- `test/scoria/workflows/runtime_span_test.exs` — `Handlers.full_tree/2` now forwards `run_id`/`step_id` alongside `workflow_run_id`
- `test/scoria/observe/semconv_test.exs` — registry canary + `trust_attributes/1` projection test updated for the fifth `scoria.trust.scanner_tier` key
- `test/scoria/connectors/invocation_test.exs` — the "undeclared tool" classification test updated for the D-35 fix's intended second telemetry emission (see Deviations)

## Decisions Made

- **`run_tool_scope_granted?/3`'s grade guard is structural (a pattern-match head), not a stored column.** See `key-decisions` in the frontmatter. `ai_approvals` has no grade column; the guard is provably correct because every `run_tool`-scoped approval that can exist today was necessarily granted for a declared-grade escalation.
- **`decide/2`/`resolve_config/1` are called live, not hand-rolled.** `evaluate_confluence/5` calls `Confluence.resolve_config(context)` and `Confluence.decide(evidence.grade, config)` for every evaluation. This correctly threads the `enforcement: :observe` kill switch and D-33's config precedence into the executor with zero duplicated logic, while remaining behaviorally identical to a narrower hand-rolled "declared grade only" check under shipped defaults.
- **Containment ordering: halt-check before containment-check.** See `key-decisions`. This was discovered via a genuine test regression during implementation (documented in Issues Encountered) and is now load-bearing, not incidental.
- **Containment mechanism finalized as self()-marker-or-$callers-non-emptiness**, after extensive design exploration (documented in Issues Encountered) ruled out several designs that would have broken backward compatibility with a direct, non-Task-wrapped `Executor.execute/4` call — which the plan's own pre-existing halted-run test exercises and which real host code may legitimately do.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `run_tool_scope_granted?/3` crashed on a `nil` run_id for an unattributed call**
- **Found during:** Task 2, running the new "unattributed" test against the freshly-integrated `evaluate_confluence/5`
- **Issue:** `evaluate_confluence/5` calls `run_tool_scope_granted?(run_id, tool_module, evidence.grade)` before attribution is checked (attribution is resolved later, inside `resolve_escalation/6`). For an unattributed call, `run_id` is `nil`, and the query's `where: a.workflow_run_id == ^run_id` raised `Ecto.Query.CompileError`-adjacent `ArgumentError: comparing a.workflow_run_id with nil is forbidden`.
- **Fix:** Added a `defp run_tool_scope_granted?(nil, _tool_module, _grade), do: false` guard clause ahead of the query-issuing clauses.
- **Files modified:** `lib/scoria/mcp/executor.ex`
- **Verification:** The "unattributed" test passes; full suite green.
- **Committed in:** `ad35b922` (part of the combined Tasks 1-3 commit)

**2. [Rule 1 - Bug, necessary consequence] `test/scoria/connectors/invocation_test.exs`'s "exactly one unclassified event" assertion was itself the bug D-35 fixes**
- **Found during:** full-suite verification after Tasks 1-3
- **Issue:** `test/scoria/connectors/invocation_test.exs` asserted that an undeclared tool routed through `Connectors.Invocation` produces exactly ONE `[:scoria, :class, :unclassified]` event. This assertion encoded the pre-fix behavior: before D-35's gate-on-source fix, `MCP.Executor.resolve_classification/2` silently bypassed re-resolution (and hence its own unclassified-event emission) whenever `Connectors.Invocation`'s `resolve_tool_classification/2` had already injected a pre-resolved `source: :unclassified_default` classification onto the context — exactly the D-35 bypass this plan's task 2 was required to close.
- **Fix:** Updated the test to expect one event at `site: :connector_invocation` AND one at `site: :mcp_executor` (never a third), documenting why this is the fix taking effect, not a regression.
- **Files modified:** `test/scoria/connectors/invocation_test.exs`
- **Verification:** `test/scoria/connectors/invocation_test.exs` (68 tests incl. this file) green.
- **Committed in:** `8f714a2c` (separate commit, since it's outside this plan's declared `files_modified` scope but a direct necessary consequence of the required D-35 fix)

---

**Total deviations:** 2 auto-fixed (2 bugs, both Rule 1)
**Impact on plan:** Both necessary for correctness. No scope creep — the second fix is scoped entirely to updating a stale assertion that the plan's own required D-35 fix makes obsolete.

## Issues Encountered

**Containment design required significant iteration and one architectural reconciliation with an existing test.** D-21's prose ("a process-dictionary marker resolved through self() or any pid in $callers") does not, by itself, distinguish a genuine raw-spawn call from an ordinary direct/synchronous call to `Executor.execute/4` — both present identical process-dictionary evidence (`$callers` absent, no marker) since neither is spawned via `Task`. Empirically verified via a throwaway script (`mix run`) before finalizing the design: `Task.Supervisor.async_nolink`/`Task.async` set `$callers` non-empty and transitively cumulative across nesting; bare `spawn/1` sets nothing at all, and — critically — neither does a plain top-level function call. An initial implementation that treated "empty `$callers`, no marker" as *uncontained* broke plan-01's pre-existing "a halted run is denied" test, which calls `Executor.execute/4` directly with no Task wrapper. Root-caused to an ordering bug, not a containment-design bug: `Run.halted?/1`'s denial never calls `exit/1`, so it carries none of the risk containment guards against, and checking containment *before* the halt check incorrectly routed a halted-but-uncontained call through the "allow, don't pause" branch. Reordering the `cond` (halt check before containment check) fixed it without weakening the raw-spawn residual for genuinely escalating calls. This ordering, and the accompanying analysis, is documented at length in `resolve_escalation/6`'s moduledoc-style comment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **The gate is now safe to run more than once.** The consume CAS, attribution/containment resolution, and always-on telemetry are all in place; `confluence_scope` (schema-only since plan 01) now has both a consumer (this plan's CAS) and the run_tool bypass 57-09 will add a UI action for.
- **`decide/2`/`resolve_config/1` are live-wired**, so a later plan adding `strict: true` support or additional grade sourcing (scanner-observed legs) does not need to touch the executor's decision logic again — it flows through automatically once `confluence_input/2` can construct non-`declared` witnesses.
- **The "different grade" run_tool-scope bound is currently untestable via the public API** (documented above) because `confluence_input/2`'s `leg_witness/1` only constructs `source: :declared` witnesses through this plan's wiring. A later plan wiring scanner-sourced legs into `confluence_input/2` should add a genuine integration test for this bound once it becomes reachable; the structural guard (`run_tool_scope_granted?/3`'s pattern-match head) is already correct and in place.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` is empty. Full suite: 1660 tests + 3 doctests, 0 failures (the one pre-existing `Scoria.WarningInventory.CaptureParityTest` flake documented in the phase's own test-environment briefing is unrelated to this plan and untouched by it).

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 6 claimed source/test files found on disk plus this SUMMARY.md; all 3 commits (`b277b24e`, `ad35b922`, `8f714a2c`) found in `git log --oneline --all`. `examples/support_copilot/deps` clean, `git status --short` empty.

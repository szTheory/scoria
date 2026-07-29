---
phase: 57-confluence-escalation-gate
plan: 07
subsystem: agent-security
tags: [elixir, ecto, postgres, jsonb, confluence-gate, audit-outbox, lethal-trifecta, mcp, replay]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "the D-47 migration's ai_audit_outbox_events event_type index, and the D-25/D-50 locked checkpoint decisions this plan reads but does not re-decide"
  - phase: 57-confluence-escalation-gate
    plan: 05
    provides: "confluence_gate/3's approval-consume CAS, attribution/containment resolution, and the always-on [:scoria, :gate, :confluence, :observed] telemetry this plan's audit writes sit alongside unchanged"
  - phase: 57-confluence-escalation-gate
    plan: 06
    provides: "the per-run confluence_legs accumulator and evaluate_confluence/5's fold-then-classify shape this plan's evidence objects are built from"
provides:
  - "Scoria.Confluence.audit_metadata/1 -- a pure, dependency-free closed projector over %Confluence.Evidence{} (combination, grade, decision, reason_code, the three leg sources, action_class, confluence_idempotency_key, tool_ref), mirroring Semconv.confluence_attributes/1's reduce-over-a-fixed-key-list shape"
  - "MCP.Executor.record_confluence_audit/5 (private): writes exactly one ai_audit_outbox_events row (event_type tool.confluence.escalated, policy_class confluence_gate, actor_ref system:scoria.confluence) on every confluence ESCALATE and every confluence BLOCK (rejected-approval, unattributed-strict, declared:block-tightened, halted-run); an ALLOW writes none"
  - "Explicit D-42 dedupe key composition (event type + run id + step id + args fingerprint) that survives two genuine escalations in one run without collapsing into one row"
  - "Approval.blocker_audit_outbox_event_id is now populated on every confluence escalation, threaded from the audit row's id written FIRST, before mark_waiting_for_approval/3 -- a single left join from approval to its own audit evidence (D-40/D-41)"
  - "Confluence's moduledoc documents what 'replayable' means for this gate: reconstructable evidence, never a reusable grant (D-43/D-44)"
  - "Three literal-set pinning tests proving Phase 57 adds nothing to Scoria.Workflows.ReplayDisposition's disposition/reason-code/replay-scope value spaces"
affects: [58]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Small closed projector as an audit envelope's metadata: value (Confluence.audit_metadata/1), never assembled inline at the call site -- SRE.build_audit_metadata/1 is a DROP-LIST, not an allowlist, so passing a pre-closed map as the envelope's own metadata: key is what keeps the persisted jsonb's key set exactly equal to the projector's output key set (proven by an integration test comparing MapSet.new/1 of both key lists)"
    - "Write-the-audit-row-first-then-thread-its-id pattern: record_confluence_audit/5 runs BEFORE Workflows.mark_waiting_for_approval/3 on the escalate path, and its returned event's id is merged into that call's attrs as blocker_audit_outbox_event_id -- requires zero workflows.ex changes because mark_waiting_for_approval/3 already merges caller attrs straight through"
    - "Source-level literal-set pinning test (mirroring the codebase's existing exact-match enum test convention, e.g. replay_disposition_test.exs's action_class ownership test): a Regex.scan/2 over the raw .ex source extracts the full set of a target module's literal atoms/strings and asserts it against a hardcoded expected list, used here because Scoria.Workflows.ReplayDisposition exposes none of its enums as public introspectable functions"

key-files:
  created:
    - test/scoria/confluence_audit_test.exs
  modified:
    - lib/scoria/confluence.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/confluence_test.exs

key-decisions:
  - "Task 1 implemented the audit write with a TEMPORARY private confluence_audit_metadata/1 inlined in executor.ex (identical shape to the eventual projector), then Task 2 promoted it verbatim to Scoria.Confluence.audit_metadata/1 and repointed the call site -- this kept Task 1's file scope honest (lib/scoria/confluence.ex was not in Task 1's declared files) while avoiding any behavioral churn between the two commits."
  - "Audit rows are written on ALL FOUR block sites the code can reach (rejected-approval, unattributed-under-a-strict-config, declared:block-tightened-via-host-config, and a halted-run denial), not just the two explicitly named in the plan's must_haves prose (unattributed, rejected-approval). The objective's own broader claim (\"a deny is a decision, and denies currently have no durable record anywhere\") and threat T-57-33's mitigation text (\"Audit rows are written on block as well as on escalate\") both state the general rule; scoping to only 2 of 4 reachable block sites would have left 2 genuinely undurable denies. Verified via a new orphan-row test for the halted-run path's telemetry-adjacent code, plus the two explicitly-required tests."
  - "The rejected-approval-consume block site (in confluence_gate/3) precedes evaluate_confluence/5 and therefore has no real %Confluence.Evidence{} yet -- a minimal synthetic evidence is built with combination hardcoded to \"exfiltration_path\", which is always correct there because resolve_escalation/6 only ever creates an approval for that exact combination, so a rejected match can only exist against a row that was genuinely an exfiltration_path escalation."
  - "evidence.decision (always nil coming out of Confluence.classify/1, since classify/1 never sets it -- confluence_decision/2 computes it in a separate local variable) is explicitly overridden with %{evidence | decision: \"block\"|\"escalate\"} at each audit call site before projection, so the closed metadata's \"decision\" key reflects the actual disposition rather than riding through as nil."
  - "The D-41 no-dedupe-key-in-attrs requirement is pinned via a source-level scan isolating the literal attrs = %{...} map (not the surrounding prose comments, which legitimately discuss dedupe_key) -- a naive whole-function substring search initially false-failed against this plan's own explanatory comment."
  - "The three ReplayDisposition enum-pinning tests (Task 3) use a Regex-based literal-set extraction against the raw .ex source rather than calling exported enum functions, because Scoria.Workflows.ReplayDisposition -- unlike Scoria.Confluence's own combinations/0, reason_codes/0, grades/0 -- exposes no such introspectable functions; each regex was validated standalone against the real source before being committed into the test file."

requirements-completed: [GATE-03]

coverage:
  - id: D1
    description: "An escalation writes exactly one audit outbox row with event type tool.confluence.escalated, policy class confluence_gate and actor reference system:scoria.confluence"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#an escalation writes exactly one audit outbox row with the confluence event type, policy class and actor reference"
        status: pass
    human_judgment: false
  - id: D2
    description: "A confluence block (rejected-approval deny and unattributed-strict-config deny) writes an audit row carrying the deny reason code"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#a block via a rejected-approval deny writes an audit row carrying the deny reason code"
        status: pass
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#an unattributed deny under a strict configuration writes an audit row carrying the deny reason code"
        status: pass
    human_judgment: false
  - id: D3
    description: "An allow writes zero confluence audit outbox rows"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#an allow writes zero confluence audit outbox rows"
        status: pass
    human_judgment: false
  - id: D4
    description: "Scoria.Confluence.audit_metadata/1 is a small closed projector (combination/grade/decision/reason_code/three leg sources/action_class/confluence_idempotency_key/tool_ref) that never spreads the evidence input -- extra fields and free-text content on the input cannot leak into the output, and a persisted row's metadata key set equals the projector's own output key set"
    requirement: "GATE-03"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#audit_metadata/1 -- a small closed projector, output not a spread (D-39, plan 57-07)"
        status: pass
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#a persisted audit row's metadata key set equals Confluence.audit_metadata/1's output key set for equivalent evidence (D-39 integration)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The dedupe key is set explicitly from event type + run id + step id + args fingerprint; two genuine escalations in one run write two distinct rows with two distinct dedupe keys, and the escalation attrs handed to mark_waiting_for_approval/3 carry no dedupe key"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#two genuine escalations in one run write two distinct rows with two distinct dedupe keys, and both approvals carry a blocker_audit_outbox_event_id"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_audit_test.exs#the escalation attrs map passed to mark_waiting_for_approval/3 carries no dedupe key (D-41)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The escalation audit row is written FIRST and its id is threaded into mark_waiting_for_approval/3's attrs as the approval's blocker_audit_outbox_event_id; the audit row survives as an orphan if the pause transition subsequently fails"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#the created approval's blocker_audit_outbox_event_id equals the audit row's id, and its blocker_kind is confluence"
        status: pass
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#when the audit write succeeds but the pause transition subsequently fails, the audit row remains an orphan"
        status: pass
    human_judgment: false
  - id: D7
    description: "Phase 57 adds nothing to Scoria.Workflows.ReplayDisposition -- the disposition, replay-reason-code and replay-scope value spaces are pinned to their pre-phase literal sets"
    requirement: "GATE-03"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_audit_test.exs#ReplayDisposition's disposition enum -- the set of atoms resolve/5 can return -- equals its pre-phase value"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_audit_test.exs#ReplayDisposition's replay_reason_code enum -- the set of literal reason code strings resolve/5 can emit -- equals its pre-phase value"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_audit_test.exs#the replay_scope value space (Workflows.mark_waiting_for_approval/3's default) equals its pre-phase value"
        status: pass
    human_judgment: false
  - id: D8
    description: "A replayed historical stub never fires the confluence gate and is never auto-approved (no telemetry, no audit row, no approval row, tool body never runs); a replayed live-override re-execution fires the gate exactly like a live call; the connector invocation seam needs no separate hook and inherits the gate automatically"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#a replayed call resolving to a historical stub never fires the confluence gate -- no telemetry event, no audit row, no approval row"
        status: pass
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#a replayed call resolving to live execution through the override path fires the confluence gate"
        status: pass
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#a tool routed through the connector invocation path is gated identically -- the connector seam needs no separate hook"
        status: pass
    human_judgment: false
  - id: D9
    description: "An approved escalation is not a reusable replay grant -- a replay of an approved run reaching the identical tool call under a different run id re-evaluates the gate afresh rather than passing through on the original approval"
    requirement: "GATE-03"
    verification:
      - kind: integration
        ref: "test/scoria/confluence_audit_test.exs#an approved escalation is not a reusable replay grant -- a replay of an approved run re-evaluates rather than passing through"
        status: pass
    human_judgment: false

duration: 26min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 07: Confluence Audit Outbox, Closed Metadata Projector, and Replay-Contract Pin Summary

**Every confluence escalation and every confluence block now writes exactly one durable, back-linked `ai_audit_outbox_events` row through a small closed metadata projector; an allow writes none; and three source-pinned tests prove Phase 57 adds nothing to `ReplayDisposition`'s enums while integration tests prove an approved escalation is never a reusable replay grant.**

## Performance

- **Duration:** ~26 min (timestamp span from base commit `1eae8c2f` to final commit `2105968b`; includes reading five upstream SUMMARY.md files, the SRE audit-outbox drop-list mechanics, and full regression runs after each task)
- **Started:** 2026-07-29T00:24:22-04:00 (base commit)
- **Completed:** 2026-07-29T00:50:08-04:00
- **Tasks:** 3 (all `auto`; Tasks 1-2 `tdd="true"`)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `MCP.Executor` writes exactly one `ai_audit_outbox_events` row (`event_type: "tool.confluence.escalated"`, `policy_class: "confluence_gate"`, `actor_ref: "system:scoria.confluence"`) at every reachable confluence ESCALATE and BLOCK site -- the escalate arm in `resolve_escalation/6`, the rejected-approval-consume deny in `confluence_gate/3`, the unattributed-strict-config deny and the declared:block-tightened-config deny in `evaluate_confluence/5`/`apply_unattributed_disposition/3`, and a halted-run denial -- while every ALLOW arm writes none (D-37, D-38).
- The dedupe key is set EXPLICITLY from `event type + run id + step id + args fingerprint` (D-42), never the automatic builder, which would have collapsed two genuine escalations in one run into a single row against the tenant-and-dedupe-key unique index.
- The escalate path writes its audit row FIRST, then threads the returned id into `Workflows.mark_waiting_for_approval/3`'s attrs as `blocker_audit_outbox_event_id` -- zero `workflows.ex` changes needed, since that function already merges caller attrs straight through (D-40/D-41). No `dedupe_key` rides in those attrs, so a second escalation in the same run cannot fail the entire pause transition on the approval-requested audit row's own unique-index insert.
- `Scoria.Confluence.audit_metadata/1` is a pure, dependency-free reduce over a fixed 10-key list (combination, grade, decision, reason_code, the three leg sources, action_class, confluence_idempotency_key, tool_ref), mirroring `Semconv.confluence_attributes/1`'s shape -- an OUTPUT, never a spread, proven resistant to both extra-field and long-free-text-field leakage via unit tests, and proven byte-equal (key-set-for-key-set) to a persisted row's actual `metadata` jsonb via an integration test.
- Three source-level literal-set pinning tests prove Phase 57 contributes nothing to `Scoria.Workflows.ReplayDisposition`'s disposition (`execute_live`/`historical_stub`/`blocked`), replay-reason-code (7 strings), or replay-scope (`"replay_live"`) value spaces -- structurally defusing the fail-open fall-through hazard 56 D-02 documented, rather than merely mitigating it.
- End-to-end integration tests through `Executor.execute/4` prove: a replayed historical stub never fires the gate (no telemetry, no audit row, no approval row, tool body never runs); a replayed live-override re-execution fires the gate exactly like a live call; the connector invocation seam (`Connectors.Invocation.invoke/4`) needs no separate hook and inherits the gate automatically on its `:execute_live` branch; and an approved escalation is NOT a reusable replay grant -- a replay of an approved run reaching the identical tool call under a different run id re-evaluates the gate afresh and mints its own distinct, pending approval.
- `Scoria.Confluence`'s moduledoc gains a section stating plainly what "replayable" means for this gate: reconstructable evidence (the audit row, the accumulator, and the approval together), never a reusable grant.

## Task Commits

1. **Task 1: Write the confluence audit row on escalate and on block, never on allow** - `ea00bd45` (feat)
2. **Task 2: A small closed metadata projector -- output, never a spread** - `0ab05b22` (feat)
3. **Task 3: Pin the replay contract -- nothing added to ReplayDisposition, no reusable grant** - `2105968b` (test)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/mcp/executor.ex` -- `record_confluence_audit/5`, `confluence_audit_dedupe_key/3`, `confluence_rejected_evidence/4`, and the `@confluence_audit_event_type`/`@confluence_audit_policy_class`/`@confluence_audit_actor_ref` module attributes; new audit-write call sites in `confluence_gate/3`'s `:rejected` clause, `evaluate_confluence/5`'s `"block"` arm, `resolve_escalation/6`'s halted-run and escalate arms, and `apply_unattributed_disposition/3`'s `_other` arm
- `lib/scoria/confluence.ex` -- `audit_metadata/1` (public), `@audit_metadata_keys`, `audit_metadata_value/1`; a new moduledoc section on what "replayable" means for this gate
- `test/scoria/confluence_audit_test.exs` -- new file: 16 tests covering escalate/block/allow audit-row behavior, the D-40/D-41/D-42 orderings, the D-39 metadata-key-set integration proof, and the D-43/D-44 replay-contract pin (enum literal-set tests plus historical-stub/live-override/connector-seam/replay-reuse integration tests)
- `test/scoria/confluence_test.exs` -- new `describe "audit_metadata/1 -- a small closed projector, output not a spread (D-39, plan 57-07)"` block (6 tests); `function_exported?(Confluence, :audit_metadata, 1)` added to the module-hygiene surface check

## Decisions Made

See `key-decisions` in the frontmatter for the full rationale on each of: the temporary-then-promoted metadata builder split across Tasks 1-2; writing audit rows on all four reachable block sites rather than only the two named in prose; the synthetic evidence for the pre-evaluation rejected-approval deny; overriding `evidence.decision` at each call site since `Confluence.classify/1` never sets it; the source-level (not whole-function) D-41 dedupe-key scan; and the regex-based ReplayDisposition enum pin.

## Deviations from Plan

### Auto-fixed Issues

None -- no Rule 1/2/3 auto-fixes were required. The four decisions above (writing audit rows on the two additional block sites, overriding `evidence.decision`, the synthetic rejected-approval evidence, and the regex-based enum pin) were all resolved during each task's own TDD RED/GREEN cycle before any commit, as executor-discretion implementation choices within the plan's explicit instructions -- not post-hoc fixes against already-shipped behavior.

---

**Total deviations:** 0
**Impact on plan:** None -- all three task commits landed with the plan's own required tests green, plus the broader `test/scoria/mcp/`, `test/scoria/connectors/`, and `test/scoria/workflows/` regression lanes (339 tests, 0 failures).

## Issues Encountered

- **First attempt at the D-41 source-level scan false-failed.** A whole-function substring search for `"dedupe_key"` across `resolve_escalation/6`'s entire body matched this plan's OWN explanatory comment ("Deliberately NO `dedupe_key` in `attrs`..."), not the `attrs` map literal itself. Fixed by isolating just the `attrs = %{...}` map literal text before asserting its absence.
- **`mix run -e` for validating the ReplayDisposition regex extractions hung/produced noisy Oban/DB-relation-missing output** because it boots the full `Scoria.Application` supervision tree against the dev database, which has no migrations applied in this worktree. Switched to plain `elixir -e` (no app boot, pure `File.read!`/`Regex` work) to validate each extraction pattern against the real source before committing it into the test file.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- **Reviewer-facing confluence evidence (`.planning/WINDOWS.md` entry 5) has a genuinely usable read path as of this plan, and it is the DIRECT one-hop join, not the whole-run accumulator.** For a given `%Approval{}` row created by a confluence escalation, a follow-up plan (the one that eventually wires `lib/scoria_web/approval_copy.ex` / `lib/scoria/workflows/remote_approval_projection.ex` -- explicitly out of this plan's file scope) should:
  1. Read `approval.blocker_audit_outbox_event_id` -- populated on every confluence escalation as of this plan (D-40/D-41), NEVER on a block (blocks never create an approval row at all).
  2. Fetch the row DEFENSIVELY: `Repo.get(Scoria.SRE.AuditOutboxEvent, approval.blocker_audit_outbox_event_id)` (never `get!/2` -- the column carries no foreign key and can legitimately be `nil` or dangling, D-40).
  3. Read `event.metadata["combination"]`, `event.metadata["grade"]`, `event.metadata["private_data_source"]`, `event.metadata["untrusted_content_source"]`, `event.metadata["exfil_source"]` -- these are EXACTLY the five keys `WINDOWS.md` entry 5 names as what `reject_blank_rows/1` currently filters out for lack of a data source, and they are the closed-projector output verified byte-equal to what is actually persisted.
  This read path is a better fit than 57-06's `confluence_legs` accumulator for THIS specific need: `confluence_legs` is a whole-run, monotone-accumulating snapshot (2 of 3 legs, no `combination`/`decision`, and its state can drift further after the escalation that created a given approval, if the run continues), whereas the audit row is a per-decision, frozen-at-escalation-time snapshot scoped to the EXACT approval being reviewed -- `combination`/`grade`/`decision`/all three leg sources/`action_class` are ALL present in one row, keyed 1:1 by `blocker_audit_outbox_event_id`. No new column or migration is required; both fields already exist. `confluence_legs` remains the correct read path for a DIFFERENT future need -- reconstructing run-scoped provenance independent of any single approval -- but is not the natural fit for the approvals-drawer's per-escalation evidence rows.
- **The gate's audit trail is now complete for every disposition that matters operationally.** Combined with 57-05's always-on telemetry and 57-06's per-run accumulator, every confluence decision (allow/escalate/block) is now either durably recorded (escalate/block) or intentionally left un-recorded because it is proportional-to-tool-calls noise (allow) -- matching the plan's own volume argument.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` shows only this SUMMARY.md as untracked. Full targeted suite (`test/scoria/mcp/`, `test/scoria/connectors/`, `test/scoria/workflows/`, `test/scoria/confluence_test.exs`, `test/scoria/confluence_audit_test.exs`): 339 tests, 0 failures. `mix compile --warnings-as-errors` exits 0.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 claimed files found on disk (`lib/scoria/mcp/executor.ex`, `lib/scoria/confluence.ex`, `test/scoria/confluence_audit_test.exs`, `test/scoria/confluence_test.exs`, this SUMMARY.md); all 4 commits (`ea00bd45`, `0ab05b22`, `2105968b`, `69f06264`) found in `git log --oneline --all`. `examples/support_copilot/deps` clean, `git status --short` empty prior to this edit.

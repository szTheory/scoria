---
phase: 57-confluence-escalation-gate
verified: 2026-07-29T06:45:00Z
status: gaps_found
score: 4/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A reviewer looking at a confluence approval sees the named combination, the three legs with their sources, and the evidence grade (57-09-PLAN.md must_have, tagged D-48/GATE-02)."
    status: failed
    reason: >
      ScoriaWeb.ApprovalCopy.confluence_rows/1 is correct and fully tested, but its data source
      is never populated on a real escalation. Scoria.Workflows.RemoteApprovalProjection.project_approval/1
      (the function that builds the map ApprovalsLive assigns to @active_approval) does not set
      :combination, :grade, :private_data_source, :untrusted_content_source, or :exfil_source
      anywhere. Scoria.MCP.Executor.escalate/3 only writes tool_name, blocker_kind: "confluence",
      and a free-text reason: "confluence gate: #{evidence.combination}" onto the ai_approvals row
      -- it does not persist %Scoria.Confluence.Evidence{} or its fields. On today's actual
      executor-produced confluence approval, ApprovalCopy.request_rows/1's Combination/<Leg>
      evidence/Evidence grade rows are silently dropped by reject_blank_rows/1, so the reviewer
      sees only "Target" and the free-text policy reason (which does contain the combination name,
      e.g. "confluence gate: exfiltration_path", but no leg-source attribution and no evidence
      grade). This is independently confirmed against the codebase, not just SUMMARY narration --
      it is also honestly self-reported in 57-09-SUMMARY.md's "Known Gaps" section and tracked as
      WINDOWS.md entry 5 (open, unmet-truth).
    artifacts:
      - path: "lib/scoria/workflows/remote_approval_projection.ex"
        issue: "project_approval/1 (lines 81-125) has no clause reading blocker_audit_outbox_event_id -> Repo.get(AuditOutboxEvent, id) -> event.metadata[...], and no clause reading Run.confluence_legs, so the confluence evidence fields never reach the map the LiveView renders from."
      - path: "lib/scoria/mcp/executor.ex"
        issue: "escalate/3 (~line 1087) sets only tool_name/blocker_kind/reason on the ai_approvals insert; it does not persist evidence.combination/grade/leg sources onto the row or a place the drawer reads."
      - path: "lib/scoria_web/approval_copy.ex"
        issue: "confluence_rows/1 (correct, tested) has no live caller that ever supplies non-nil combination/grade/leg-source keys outside test fixtures."
    missing:
      - "Wire approval.blocker_audit_outbox_event_id -> Repo.get(AuditOutboxEvent, id) -> event.metadata[\"combination\"|\"grade\"|\"private_data_source\"|\"untrusted_content_source\"|\"exfil_source\"] into RemoteApprovalProjection.project_approval/1, mirroring the existing decider_ref/1 audit-metadata-read pattern already used elsewhere in approvals_live/index.ex for decision-actor attribution. Both 57-07-SUMMARY.md and 57-10-SUMMARY.md already name this exact fix path."
      - "An integration test that drives a real Executor.execute/4 confluence escalation through to the drawer's rendered request_rows/1 output and asserts the Combination/leg/grade rows are present and non-blank (the current test suite only proves ApprovalCopy against synthetic maps and never against a live escalation's projected approval)."
deferred: []
---

# Phase 57: Confluence Escalation Gate Verification Report

**Phase Goal:** Escalate to human approval when private-data + untrusted-content + exfil co-occur on one tainted path.
**Verified:** 2026-07-29
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GATE-01: A confluence evaluator classifies a tainted path by which of the three legs are present, total over all 8 leg vectors. | ✓ VERIFIED | `lib/scoria/confluence.ex` `classify/1` is a total `cond` over p/u/e (lines 517-565); the unreachable terminal clause returns `:unevaluable` with `reason_code: :confluence_resolver_fallthrough` rather than silently falling open. `test/scoria/confluence_test.exs` "totality over all eight leg vectors" describe block (11 tests) plus a dedicated property test ("is total over the leg vector regardless of dict insertion order or extra keys" and "none of the eight leg vectors ever falls to the terminal :unevaluable sentinel"). Ran in isolation: 0 failures. |
| 2 | GATE-02 (amended): the confluence gate decides and refuses at `Scoria.MCP.Executor`, before the tool's execution task starts, and the STEP (not the run) transitions to `waiting_for_approval` via `mark_waiting_for_approval/3`, resumable via `resume_run/1`; step-scoped pause is an accepted, tested limitation. | ✓ VERIFIED | `execute/4`'s dispatch chain: `resolve_classification -> replay_gate -> confluence_gate -> {:continue, _} -> execute_live` (executor.ex lines 44-65) — the gate runs strictly before `execute_live/4`. `test/scoria/confluence_concurrency_test.exs` "a sibling completing after an escalation reopens dispatch (D-25 accepted limitation)" directly pins the step-scoped (not run-scoped) semantics the amended wording describes. Ran: 0 failures. |
| 3 | GATE-03: every confluence escalation and every confluence block writes exactly one audit outbox row (event type `tool.confluence.escalated`, policy class `confluence_gate`, actor `system:scoria.confluence`); allow writes none; the escalation row is back-linked via `blocker_audit_outbox_event_id`; Phase 57 adds nothing to `ReplayDisposition`. | ✓ VERIFIED | `lib/scoria/mcp/executor.ex` `record_confluence_audit/5` (called from both the escalate and the two block/reject paths, never from allow). `test/scoria/confluence_audit_test.exs` (18 tests) directly asserts: exactly one row per escalate, back-link equality, zero rows on allow, two distinct dedupe keys for two escalations in one run, a block via rejected-approval writes a row, an unattributed deny writes a row, `ReplayDisposition`'s disposition/reason-code/replay-scope enums are byte-identical to pre-phase (regex-scanned from source), a replayed historical stub fires no telemetry/audit/approval, and an approved escalation does not pass through a differently-scoped replay run. Ran: 0 failures. |
| 4 | GATE-04 (amended): `declared` grade enforces (escalates) from the shipped default; the three ungated grades (`unclassified`, `scanner_infra`, `default_tier`) are telemetry-only under shipped defaults; strict mode is an explicit opt-in that extends enforcement to the ungated grades. | ✓ VERIFIED | `Confluence.decide/2` (lines 302-317): `declared` always consults `config[:declared]` (shipped `:escalate`); the three weak grades consult their own configured value (shipped `:allow`) unless `strict: true`. `test/scoria/confluence_test.exs` "decide/2" describe block covers exactly this matrix (declared->escalate, three weak->allow, strict forces escalate on weak grades, declared still escalates under strict, `enforcement: :observe` is a kill switch). The Phase 55 mint-site defect that would have made a scanner's clean verdict impossible to reach (and made `declared: :escalate` a 100%-pause-rate trap on first scanner install) is independently repaired and regression-tested in `test/scoria/mcp/executor_test.exs`. Ran: 0 failures. |
| 5 | (57-09 plan-level must-have, tagged GATE-02) A reviewer looking at a confluence approval sees the named combination, the three legs with their sources, and the evidence grade. | ✗ FAILED | See Gaps below. The rendering code is correct and tested against synthetic data, but the live data path that would populate it is never wired — confirmed directly against `remote_approval_projection.ex` and `executor.ex`, not just SUMMARY narration. |

**Score:** 4/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/confluence.ex` | Total 8-clause classifier, grading ladder, disposition resolver, config surface | ✓ VERIFIED | All present; 92-test `confluence_test.exs` green. |
| `lib/scoria/confluence/evidence.ex` | Closed `%Evidence{}` struct with `@derive Jason.Encoder` | ✓ VERIFIED | Present, closed field set, no free-text fields. |
| `priv/repo/migrations/20260728140000_add_confluence_columns.exs` | Consolidated migration: `confluence_legs` NOT NULL default `{}`, `consumed_at`/`consumed_by_step_id`/`confluence_scope`, audit event_type index | ✓ VERIFIED | All four present with `add_if_not_exists`; migration comment explicitly documents the `jsonb || NULL = NULL` load-bearing rationale for the default. |
| `lib/scoria/mcp/executor.ex` | Gate wiring, approval-consume CAS, leg accumulator, audit write, telemetry | ✓ VERIFIED | Confirmed wired end-to-end via code read + 117 passing tests across 4 confluence-specific test files. |
| `lib/scoria_web/approval_copy.ex` | Confluence evidence rows, combination label/tone mapping | ⚠️ HOLLOW (Level 4) | Code is correct and unit-tested, but its live data source is empty — see Gaps. |
| `lib/scoria/workflows/remote_approval_projection.ex` | Projects the approval a reviewer sees | ✗ Incomplete | Never sets `combination`/`grade`/leg-source keys — this is the missing link. |
| `.planning/REQUIREMENTS.md` | GATE-02/GATE-04 amended wording matches shipped behavior | ✓ VERIFIED | Amended text cross-checked against code (gate ordering, step-scoped pause, grade/decision matrix) — accurate, not overstated. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `approval_copy.ex#confluence_rows/1` (rendered via `index.ex` `@active_approval`) | `combination`, `grade`, `private_data_source`, `untrusted_content_source`, `exfil_source` | `RemoteApprovalProjection.project_approval/1` -> `Approval` schema (no such columns exist; would need to read `blocker_audit_outbox_event_id` -> `AuditOutboxEvent.metadata`) | No — fields are never set | ✗ DISCONNECTED |
| All other Phase 57 escalation-path writes (run status, step status, `ai_approvals` row, `confluence_legs` accumulator, audit outbox row) | n/a | `Executor`/`Workflows`/`Repo` direct writes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks / Test Runs

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Confluence-specific test files (totality, grading, gate wiring, audit, concurrency) | `mix test test/scoria/confluence_test.exs test/scoria/confluence_audit_test.exs test/scoria/confluence_concurrency_test.exs test/scoria/mcp/executor_confluence_test.exs` | `117 tests, 0 failures` | ✓ PASS |
| Full suite with warnings-as-errors against migrated DB | `mix test --warnings-as-errors` | `3 doctests, 1736 tests, 1 failure (75 excluded)` | ✓ PASS — the 1 failure is `Scoria.WarningInventory.CaptureParityTest`, independently reproduced at the pre-phase-57 baseline commit `5a9d0f8f` per the task briefing and `WINDOWS.md` entry 1; not attributable to this phase. |
| Gate ordering (`confluence_gate` runs before `execute_live`) | source read, `lib/scoria/mcp/executor.ex` lines 44-65 | Confirmed | ✓ PASS |
| D-50 bounded run-tool-grade scope | source read, `run_tool_scope_granted?/3` (lines 472-486) | Bound to `run_id` + `tool_name` + `"declared"` grade only; no other grade ever matches | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| GATE-01 | 57-01, 57-02, 57-03, 57-10 | Confluence evaluator classifies tainted path by leg presence | ✓ SATISFIED | Code + 92 confluence_test.exs tests. **REQUIREMENTS.md checkbox/traceability row (line 36, line 97) currently shows unchecked/"Pending"** — this is a documentation bookkeeping gap, not a functional one; the developer's suspicion in the task brief is confirmed correct. |
| GATE-02 | 57-01, 57-05, 57-06, 57-08, 57-09, 57-10 | Gate decides/refuses at Executor, step-scoped pause, resumable | ✓ SATISFIED (mechanism); ✗ evidence-visibility sub-truth failed (see Gaps) | Amended wording matches shipped code exactly. REQUIREMENTS.md shows GATE-02 Complete — accurate for the mechanism, but the reviewer-evidence must-have from its own owning plan (57-09) is not met end-to-end. |
| GATE-03 | 57-07, 57-10 | Audit outbox + replay contract | ✓ SATISFIED | Code + 18 confluence_audit_test.exs tests. **REQUIREMENTS.md checkbox/traceability row (line 39, line 99) currently shows unchecked/"Pending"** — same bookkeeping gap as GATE-01; functionally complete. |
| GATE-04 | 57-02, 57-04, 57-05, 57-10 | Graded, fail-closed-but-inspectable enforcement | ✓ SATISFIED | Code + decide/2 test matrix; REQUIREMENTS.md shows Complete — accurate. |

No orphaned requirements — all four GATE IDs mapped to Phase 57 in REQUIREMENTS.md are claimed by at least one plan's frontmatter.

### Anti-Patterns Found

None. Scanned every file modified across all 10 plans (`lib/scoria/confluence.ex`, `confluence/evidence.ex`, `mcp/executor.ex`, `workflows/runtime.ex`, `workflows/run.ex`, `observe/approval.ex`, `trust/verdict.ex`, `trust/scan.ex`, `runtime/params.ex`, `observe/semconv.ex`, `workflows.ex`, `workflows/resume.ex`, `scoria_web/approval_copy.ex`, `scoria_web/live/approvals_live/index.ex`, `workflows/remote_approval_projection.ex`, `adopter_doc_contract.ex`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`/"not yet implemented" — zero matches.

### Human Verification Required

None. All open questions were resolvable against the codebase and test suite.

### Gaps Summary

**Four of four GATE requirements (GATE-01 through GATE-04) are genuinely, substantively implemented** — this is not a SUMMARY-claims-vs-code mismatch. `Scoria.Confluence.classify/1` is a real total function over all eight leg vectors (GATE-01); the gate demonstrably runs at the correct point in `Executor.execute/4` before any tool body executes, with the step-scoped-not-run-scoped pause semantics honestly amended in REQUIREMENTS.md/ROADMAP.md and pinned by a dedicated concurrency test (GATE-02); every escalation and block writes exactly one audit row with a working back-link and the replay contract is negatively pinned to prevent a future auto-approve bypass (GATE-03); and the grading/disposition ladder matches the amended fail-closed-but-inspectable wording exactly, including the Phase-55 mint-site repair that makes the whole grading model non-vacuous (GATE-04). 117 confluence-specific tests and the full 1736-test suite (minus the one independently-confirmed pre-existing flake) all pass.

**One real, material gap exists**: the confluence evidence rows plan 57-09 built for the human reviewer (`ApprovalCopy.confluence_rows/1` — combination, leg witness sources, evidence grade) have no live data source. `RemoteApprovalProjection.project_approval/1` never reads `blocker_audit_outbox_event_id` back to the audit row's metadata (or `Run.confluence_legs`), so on today's actual escalated approval those rows render blank — the human sees only the target and a free-text "confluence gate: exfiltration_path" reason, with no leg-attribution or grade to judge how strong the evidence is. This directly implicates 57-09's own must-have truth and its own prohibition ("MUST NOT manufacture consent"). The gap is honestly self-reported by the executing agent in 57-09-SUMMARY.md's Known Gaps and tracked as `WINDOWS.md` entry 5 (open, unmet-truth) with the exact fix path already identified (`blocker_audit_outbox_event_id -> Repo.get(AuditOutboxEvent, id) -> event.metadata[...]`, mirroring the existing `decider_ref/1` pattern already in `approvals_live/index.ex`). Because the developer's own tooling (`WINDOWS.md`, `open_count: 5`) already blocks `/gsd-ship` on this, this verification's `gaps_found` status is consistent with, not a new blocker on top of, the project's existing gate.

**Assessment of materiality (per the task's specific ask):** this does undercut the "a human must be able to adjudicate an escalation" spirit of GATE-02, though not its literal amended text (which is purely about pause mechanics, not UI evidence). It is meaningfully mitigated today because the shipped default only ever escalates on the `declared` grade (the strongest, most-vetted evidence class — full-trifecta tool self-declaration) and the free-text reason does name the combination; but the gap becomes materially worse for any adopter who opts into `strict: true`, where weak-grade (`unclassified`/`scanner_infra`/`default_tier`) escalations become common and are, without the leg/grade rows, visually indistinguishable from a high-confidence `declared` escalation. This is a real functional gap requiring a follow-up plan, not merely a documented accepted limitation on the order of D-25 (step-scoped pause) or D-50 (bounded approval scope) — those two were explicit, developer-confirmed one-way-door decisions; this one is an acknowledged incomplete wiring with no such decision behind it.

**Secondary, non-blocking finding:** `.planning/REQUIREMENTS.md`'s GATE-01 and GATE-03 checkboxes/traceability-table rows are still unchecked/"Pending" despite both being functionally complete and covered by tests. 57-10-SUMMARY.md explicitly left this for the orchestrator's `state_updates` pass (it was out of that plan's `roadmap_exception` scope, which was limited to the GATE-02/GATE-04 wording amendment). This is a documentation-only mismatch, not a code gap — recommend the orchestrator tick both checkboxes and traceability rows to "Complete" as part of closing this phase, once the evidence-rows gap above is resolved or explicitly waived.

---

_Verified: 2026-07-29_
_Verifier: Claude (gsd-verifier)_

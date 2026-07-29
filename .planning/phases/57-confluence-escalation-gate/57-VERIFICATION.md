---
phase: 57-confluence-escalation-gate
verified: 2026-07-29T16:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "A reviewer looking at a confluence approval sees the named combination, the three legs with their sources, and the evidence grade (57-09-PLAN.md must_have, tagged D-48/GATE-02)."
  gaps_remaining: []
  regressions: []
deferred: []
---

# Phase 57: Confluence Escalation Gate Verification Report

**Phase Goal:** When a single tainted execution path touches private data, untrusted content, and an exfil-capable action at once, Scoria pauses for human approval before the exfil action executes — audited, replayable, and fail-closed-but-inspectable by default so no adopter is bricked.

**Verified:** 2026-07-29
**Status:** passed
**Re-verification:** Yes — after gap closure (plans 57-11, 57-12)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GATE-01: A confluence evaluator classifies a tainted path by which of the three legs are present, total over all 8 leg vectors. | ✓ VERIFIED (regression-checked) | `lib/scoria/confluence.ex` `classify/1` unchanged since prior verification; `test/scoria/confluence_test.exs` re-run in this session's focused lane, 0 failures. |
| 2 | GATE-02 (amended): the confluence gate decides and refuses at `Scoria.MCP.Executor`, before the tool's execution task starts, and the STEP (not the run) transitions to `waiting_for_approval` via `mark_waiting_for_approval/3`, resumable via `resume_run/1`; step-scoped pause is an accepted, tested limitation. | ✓ VERIFIED (regression-checked) | `executor.ex`'s dispatch chain unchanged; `test/scoria/confluence_concurrency_test.exs` re-run, 0 failures. |
| 3 | GATE-03: every confluence escalation and every confluence block writes exactly one audit outbox row, back-linked via `blocker_audit_outbox_event_id`; allow writes none. | ✓ VERIFIED (regression-checked) | `record_confluence_audit/5` unchanged; `test/scoria/confluence_audit_test.exs` re-run, 0 failures. |
| 4 | GATE-04 (amended): `declared` grade enforces from the shipped default; the three ungated grades are telemetry-only unless `strict: true`. | ✓ VERIFIED (regression-checked) | `Confluence.decide/2` unchanged; `test/scoria/confluence_test.exs` "decide/2" describe block re-run, 0 failures. |
| 5 | (57-09/57-11 must-have, tagged GATE-02/GATE-03) A reviewer looking at a confluence approval sees the named combination, the three legs with their sources, and the evidence grade — proven end-to-end against a real `Executor.execute/4` escalation, not a hand-built map. | ✓ VERIFIED — **gap closed** | `RemoteApprovalProjection.project_approval/2` (lib/scoria/workflows/remote_approval_projection.ex:196-246) now resolves `:combination`, `:grade`, `:private_data_source`, `:untrusted_content_source`, `:exfil_source` from the approval's own `blocker_audit_outbox_event_id` back-link, scoped by `event_type == "tool.confluence.escalated"` AND `workflow_run_id` match (lines 154-181), through a batch loader (`confluence_audit_events_by_id/1`, lines 122-142) that costs one query per rendered page and zero for a page with no confluence approvals. Leg-source strings convert through a closed 4-pair map (lines 35-40) with an `:unknown` fallback — `String.to_atom/1`/`String.to_existing_atom/1` are never called on persisted JSON. Traced the write side independently: `Scoria.MCP.Executor.record_confluence_audit/5` (executor.ex:542-559) merges `Confluence.audit_metadata/1`'s output (string keys `combination`, `grade`, `private_data_source`, `untrusted_content_source`, `exfil_source` — confirmed at `confluence.ex:632-644`) into the same envelope whose `workflow_run_id` is persisted onto `AuditOutboxEvent` (`sre.ex:288`), so the read-side scope check matches the write side exactly. `test/scoria/confluence_reviewer_evidence_test.exs` drives a real `Executor.execute/4` escalation and asserts the rendered `Combination`/leg/grade rows are non-blank via both `get_approval_lineage!/1` and `list_pending_approvals/1`; `test/scoria/workflows/remote_approval_projection_test.exs` "confluence evidence projection" describe block (6 tests: real audit row, nil back-link, dangling back-link, foreign-run back-link, unrecognized leg source, non-confluence approval) plus "confluence evidence batch query (D-51 no N+1)" (2 telemetry-based query-count tests); `test/scoria_web/live/approvals_live_test.exs` renders a real escalation in the actual `ApprovalsLive.Index` LiveView and asserts the combination string, witness label and grade label appear in the rendered HTML, and are absent for a non-confluence approval. Independently re-ran all three files in this verification session: **57 tests, 0 failures.** |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/confluence.ex` | Total 8-clause classifier, grading ladder, disposition resolver | ✓ VERIFIED | Unchanged from prior verification; still green. |
| `lib/scoria/mcp/executor.ex` | Gate wiring, approval-consume CAS, audit write | ✓ VERIFIED | Unchanged from prior verification; still green. |
| `lib/scoria_web/approval_copy.ex` | Confluence evidence rows, combination label/tone mapping | ✓ VERIFIED (now wired) | Code was already correct/tested; now has a live, non-empty data source (see below). |
| `lib/scoria/workflows/remote_approval_projection.ex` | Projects the approval a reviewer sees, including confluence evidence | ✓ VERIFIED | `project_approval/2` (was `/1`) adds `:combination`, `:grade`, and the three leg-source keys via `confluence_evidence_fields/2`, sourced from the escalation's own audit row, never defaulted/inferred (lines 144-194, 196-246). All three call sites (`list_pending_approvals/1`, `list_decided_approvals/1`, `get_approval_lineage!/1`) pass through the shared batch loader. |
| `test/scoria/confluence_reviewer_evidence_test.exs` | End-to-end proof, real escalation → rendered rows | ✓ VERIFIED | New file; 2 tests; re-run in this session, 0 failures. |
| `.planning/REQUIREMENTS.md` | All four GATE requirements read Complete | ✓ VERIFIED | Confirmed directly: lines 36/37/39/40 all `- [x]`; traceability rows 97-100 all `Complete`. |
| `.planning/WINDOWS.md` | Entry 5 (reviewer-evidence unmet-truth) closed by proof, not waived | ✓ VERIFIED | Confirmed directly: entry 5's `status` is `fixed` (not `waived`) with `resolved_at: 2026-07-29T15:08:51.394Z`; frontmatter `open_count: 4`, `fixed_count: 1`, `total_count: 5`; entries 1-4 unchanged and still `open`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `approval_copy.ex#confluence_rows/1` (rendered via `index.ex` `@active_approval`) | `combination`, `grade`, `private_data_source`, `untrusted_content_source`, `exfil_source` | `RemoteApprovalProjection.project_approval/2` → batch-loaded `AuditOutboxEvent` (via `blocker_audit_outbox_event_id`, scoped to `event_type` + `workflow_run_id`) → `event.metadata` | Yes — confirmed via a real `Executor.execute/4` escalation rendering non-blank rows through all three reviewer entry points (lineage, pending list, LiveView drawer) | ✓ FLOWING (previously ✗ DISCONNECTED) |
| All other Phase 57 escalation-path writes (run status, step status, `ai_approvals` row, `confluence_legs` accumulator, audit outbox row) | n/a | `Executor`/`Workflows`/`Repo` direct writes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks / Test Runs

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gap-closure test files, run independently by this verifier | `mix test test/scoria/confluence_reviewer_evidence_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/approvals_live_test.exs` | `57 tests, 0 failures` | ✓ PASS |
| Full confluence-specific lane (orchestrator-confirmed, this session) | `mix test` over 7 confluence-related files | `174 tests, 0 failures` | ✓ PASS |
| Full suite with warnings-as-errors (orchestrator-confirmed, this session) | `mix test --warnings-as-errors` | `3 doctests, 1748 tests, 1 failure` | ✓ PASS — sole failure is `Scoria.WarningInventory.CaptureParityTest`, documented pre-existing baseline flake (WINDOWS.md entry 1), reproduced at pre-phase baseline `5a9d0f8f`. Not a regression, not in scope. |
| REQUIREMENTS.md GATE rows | `grep -n "GATE-0" .planning/REQUIREMENTS.md` | All 4 checkboxes `[x]`, all 4 traceability rows `Complete` | ✓ PASS |
| WINDOWS.md entry 5 | `sed -n .planning/WINDOWS.md` | `status: fixed`, `resolved_at` populated, `open_count: 4`/`fixed_count: 1`/`total_count: 5` | ✓ PASS |
| Anti-pattern scan on all files touched by plans 57-11/57-12 | `grep -nE "TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER"` | No matches | ✓ PASS |
| Working tree clean, no stray `.dag` artifacts | `git status --short` | Clean | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| GATE-01 | 57-01, 57-02, 57-03, 57-10, 57-12 (bookkeeping) | Confluence evaluator classifies tainted path by leg presence | ✓ SATISFIED | Code + 92 `confluence_test.exs` tests; REQUIREMENTS.md now correctly reads `Complete` in both checkbox and traceability table (previously the sole non-code bookkeeping gap; now closed by 57-12). |
| GATE-02 | 57-01, 57-05, 57-06, 57-08, 57-09, 57-10, 57-11 | Gate decides/refuses at Executor, step-scoped pause, resumable, AND reviewer sees the evidence | ✓ SATISFIED (mechanism + evidence-visibility) | Amended wording matches shipped code; the reviewer-evidence sub-truth that was the prior verification's sole gap is now proven end-to-end by plan 57-11. |
| GATE-03 | 57-07, 57-10, 57-11, 57-12 (bookkeeping) | Audit outbox + replay contract | ✓ SATISFIED | Code + 18 `confluence_audit_test.exs` tests; the read side (reviewer projection) now also sources from this same audit row. REQUIREMENTS.md reads `Complete`. |
| GATE-04 | 57-02, 57-04, 57-05, 57-10 | Graded, fail-closed-but-inspectable enforcement | ✓ SATISFIED | Code + `decide/2` test matrix; unchanged, still `Complete`. |

No orphaned requirements. All four GATE IDs are now `Complete` in both the checkbox list and the traceability table.

### Anti-Patterns Found

None in any file touched by plans 57-11 or 57-12 (`lib/scoria/workflows/remote_approval_projection.ex`, `test/scoria/confluence_reviewer_evidence_test.exs`, `test/scoria/workflows/remote_approval_projection_test.exs`, `test/scoria_web/live/approvals_live_test.exs`, `.planning/REQUIREMENTS.md`, `.planning/WINDOWS.md`).

**Carried-forward, non-blocking finding from `57-REVIEW.md` (code review gate, 2026-07-29):** One critical finding (**CR-01**: `halt_run/3`'s D-52 confluence-approval cleanup, `resolve_pending_confluence_approvals/1`, is not wrapped in its own `try/rescue` the way its sibling post-commit calls are, so a concurrent decide-vs-rail-trip race raises an uncaught/miscaught `Ecto.StaleEntryError` that can misreport a successful halt as `{:error, :already_halted}` or crash the caller) was deliberately deferred rather than fixed in this run, and is tracked at `.planning/todos/pending/2026-07-29-halt-run-confluence-cleanup-stale-entry-race.md` with the orchestrator's note that this was a user-approved scope decision to keep the gap-closure lane limited to the reviewer-evidence gap. Assessed against the phase goal: this bug lives in a secondary cleanup path (bulk-expiring *other* pending confluence approvals on a *sibling* run halt), not in the core escalate-and-pause mechanism the phase goal describes, and no test exercises the race today — it does not undermine any of the five observable truths above. It is a real, correctly-triaged piece of technical debt, appropriately classified as a **WARNING**, not a phase-blocking gap. Two lower-severity warnings from the same review (WR-01: client-side-only authorization gate on `approve_run_scoped`; WR-02: untested telemetry-tagging assumption for partial-leg `declared`-grade combinations) are noted in the same todo file for a future pass and are similarly non-blocking to this phase's goal.

### Human Verification Required

None. All open questions were resolvable against the codebase and the independently re-run test suite.

### Gaps Summary

**The phase goal is now fully achieved and the prior verification's sole gap is closed by proof, not assertion.** All five observable truths verify against the codebase:

- GATE-01 through GATE-04 (the classification, gate-ordering/pause-mechanics, audit/replay contract, and grading/enforcement matrix) were already verified in the prior pass and are confirmed unregressed here via an independent re-run of the confluence-specific test lane (174 tests, 0 failures) and the full suite (1748 tests, 1 pre-existing unrelated failure).
- The single carried-over gap — the reviewer-facing evidence rows (combination, three leg sources, evidence grade) having no live data source — is now closed. `RemoteApprovalProjection.project_approval/2` reads the escalation's own frozen audit-outbox metadata through its `blocker_audit_outbox_event_id` back-link, scoped by event type and workflow-run-id so a dangling or foreign-run pointer never renders fabricated evidence; leg-source strings convert through a closed atom map with no `String.to_atom/1` on persisted JSON; the read is batched once per rendered page so the existing pending-query cap (D-51) is not undone by an N+1; and all three reviewer entry points (lineage read, pending list, decided list) carry the same evidence. This was proven — independently re-verified in this session, not merely trusted from SUMMARY.md — by driving a real `Scoria.MCP.Executor.execute/4` escalation through to non-blank rendered rows at the row-list level (`ApprovalCopy.request_rows/1`) and at the actual rendered LiveView drawer HTML level, plus six defensive-case tests (nil/dangling/foreign-run back-link, unrecognized leg source, non-confluence approval) and two telemetry-based query-count tests proving the no-N+1 property. 57 tests, 0 failures, re-run directly by this verifier.
- The bookkeeping-only issue from the prior verification (GATE-01/GATE-03 checkboxes reading Pending despite functional completeness) is also closed: both now read `Complete` in `.planning/REQUIREMENTS.md`, confirmed directly, not from SUMMARY narration.
- `.planning/WINDOWS.md` entry 5 is closed as `fixed` (not waived), with the three remaining open entries (1-4) confirmed unrelated pre-existing Phase 56.1 items, untouched by this phase.
- One deliberately-deferred, correctly-triaged piece of technical debt remains (CR-01, a race-condition edge case in a secondary halt-time cleanup path), tracked in a todo file with user-approved scope justification — it does not touch the core escalate/pause/audit/grade mechanism this phase's goal describes and is reported here as a non-blocking WARNING for visibility, not as a gap.

Phase 57's goal — pausing for human approval before an exfil-capable action executes when private data, untrusted content, and exfil co-occur on one tainted path, audited, replayable, fail-closed-but-inspectable, and now genuinely reviewable by a human — is achieved and verified against the codebase.

---

_Verified: 2026-07-29_
_Verifier: Claude (gsd-verifier)_

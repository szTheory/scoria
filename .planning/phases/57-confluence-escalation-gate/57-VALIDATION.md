---
phase: 57
slug: confluence-escalation-gate
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-28
validated: 2026-07-29
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded by `/gsd-plan-phase` from `57-RESEARCH.md` § Validation Architecture. Task IDs are filled in by `/gsd-validate-phase` once plans exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `mix.exs` (scoped `test.*` aliases, ~lines 25–52) |
| **Quick run command** | `mix test test/scoria/confluence_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~2 s quick (pure classifier, no DB) / full suite minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowly-scoped test file for the module just touched (e.g. `mix test test/scoria/confluence_test.exs`, `mix test test/scoria/mcp/executor_test.exs`)
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green, **plus** the concurrent-step / multi-sibling-step integration test exercising D-25 / D-26 / D-28 interactions (highest-risk untested interaction class per RESEARCH.md Pitfalls 4–5)
- **Max feedback latency:** ~30 seconds for the quick lane

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| T1 | 57-01 | 1 | GATE-01 | — | `Confluence.classify/1` is total over all 8 leg combinations and returns the correct closed enum value | unit (property-style, no DB) | `mix test test/scoria/confluence_test.exs` | ✅ | ✅ green |
| T1 | 57-03 | 2 | GATE-01 | T-57-mint | `scan_tool_output/2` no longer clamps a clean scanner verdict to `"untrusted"` (D-01a mint-site bug) | unit/integration | `mix test test/scoria/mcp/executor_test.exs` | ✅ `:667` (`CleanScanner`) | ✅ green |
| T1 | 57-05 | 4 | GATE-02 | T-57-bypass | Escalation pauses BEFORE `execute_live/4` — no budget reserved, no `mcp.access.granted` row written | integration (DB, `Scoria.IntegrationCase`) | `mix test test/scoria/mcp/executor_confluence_test.exs` | ✅ | ✅ green |
| T1 | 57-06 | 5 | GATE-02 | — | `Runtime.execute_handler/6` new exit clause maps to `{:ok, {:waiting_for_approval, attrs, elapsed_ms}}` | integration | `mix test test/scoria/workflows/runtime_test.exs` | ✅ `:286` | ✅ green |
| T1 | 57-08 | 7 | GATE-02 | T-57-replay | Resume after approval re-reaches the identical tool call and does NOT re-escalate (consume CAS) | integration | `mix test test/scoria/workflows_test.exs --only confluence` | ✅ `:367` (D-26 describe) | ✅ green |
| T1 | 57-07 | 6 | GATE-03 | T-57-audit | Audit row written on `escalate` AND `block`, never on `allow`; `blocker_audit_outbox_event_id` links correctly | integration | `mix test test/scoria/confluence_audit_test.exs` | ✅ | ✅ green |
| T2 | 57-01 | 1 | GATE-04 | — | `declared: :escalate` enforces by default; the three weak grades emit telemetry only, never block | unit | `mix test test/scoria/confluence_test.exs` | ✅ | ✅ green |
| T2 | 57-04 | 1 | GATE-04 | T-57-leak | `Semconv.confluence_attributes/1` is a no-passthrough fixed-key projector; registry canary includes the new keys | unit | `mix test test/scoria/observe/semconv_test.exs` | ✅ `:294` | ✅ green |
| T3 | 57-10 | 8 | D-53 | — | Guide no longer denies the confluence claim; positive assertion fails if the edit is missing | unit (doc-content) | `mix test test/scoria/adoption_surface_test.exs` | ✅ `:272` | ✅ green |
| T1 | 57-10 | 8 | GATE-02 | T-57-race | Concurrent / multi-sibling-step interaction class (D-25 / D-26 / D-28) — the highest-risk untested interaction per RESEARCH.md Pitfalls 4–5 | integration (8 tests) | `mix test test/scoria/confluence_concurrency_test.exs` | ✅ | ✅ green |
| T1–T3 | 57-11 | 9 | GATE-02, GATE-03 | T-57-51, T-57-56 | A reviewer sees the named combination, the three legs with their sources, and the evidence grade — proven against a **real** `Executor.execute/4` escalation, not a fixture | integration (E2E) | `mix test test/scoria/confluence_reviewer_evidence_test.exs` | ✅ | ✅ green |
| T2 | 57-11 | 9 | GATE-03 | T-57-52, T-57-54, T-57-55 | Evidence is read from the escalation's own audit row scoped by `event_type` **and** `workflow_run_id`; nil/dangling/foreign back-link fabricates nothing; leg sources resolve via a closed map (no `String.to_atom` on persisted JSON); one audit query per page, zero when no confluence rows | integration + query-count telemetry | `mix test test/scoria/workflows/remote_approval_projection_test.exs` | ✅ | ✅ green |
| T3 | 57-11 | 9 | GATE-02 | T-57-51 | The rendered approvals-drawer HTML for a real escalation shows the combination, leg witness labels and grade; a non-confluence approval shows none of them | integration (LiveView) | `mix test test/scoria_web/live/approvals_live_test.exs` | ✅ | ✅ green |
| T1–T2 | 57-12 | 10 | GATE-01, GATE-03 | T-57-57, T-57-58 | Requirement statuses and the broken-window ledger match what the code and tests actually deliver | doc-state (verified by inspection + the three tests above) | `grep -c '^| GATE-0[1-4] | Phase 57 | Complete |' .planning/REQUIREMENTS.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scoria/confluence_test.exs` — pure classifier property-style coverage over all 8 leg combinations + grading matrix (GATE-01, GATE-04)
- [x] Confluence-specific audit coverage — landed as a dedicated `test/scoria/confluence_audit_test.exs` (GATE-03)
- [x] Framework install: **none needed** — ExUnit is already fully configured, no new test dependency

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human approval UX copy reads correctly in the approval surface | GATE-02 | Copy/legibility judgement is not assertable beyond string presence | Trigger a confluence escalation in the dev harness and read the rendered approval prompt |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags (ExUnit is one-shot by default; no `--listen`/watch alias used)
- [x] Feedback latency < 30s (quick lane: `mix test test/scoria/confluence_test.exs` — pure classifier, no DB)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-29

---

## Validation Audit 2026-07-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 (none required) |
| Escalated | 0 |

**Method.** Audited in State A against the executed phase. Every row of the plan-time
seeded map was cross-referenced to a test file that exists on disk and runs green — no
row was accepted on SUMMARY narration. The one row that looked like a candidate gap
(`scan_tool_output/2`'s D-01a mint-site fix, seeded as "needs new cases") is in fact
covered: `test/scoria/mcp/executor_test.exs:667` drives the executor with a `CleanScanner`
fixture and asserts `metadata["scoria.trust.tier"] == "trusted"`, with the paired
malicious-scanner case at `:684` proving the two outcomes differ. No auditor agent was
needed.

Four rows were **added** to the map, covering work planned after this file was seeded:
the 57-10 concurrency suite and the three 57-11 gap-closure suites (reviewer evidence
end-to-end, projection defensive cases + query-count property, and the rendered LiveView
drawer), plus the 57-12 doc-state row.

**Evidence runs (this audit, 2026-07-29):**

| Lane | Result |
|------|--------|
| `confluence_reviewer_evidence` + `remote_approval_projection` + `approvals_live` + `confluence` + `confluence_audit` + `confluence_concurrency` + `executor_confluence` | 174 tests, 0 failures |
| `test/scoria/trust/` | 36 tests, 0 failures |
| `executor_test` + `runtime_test` + `workflows_test` + `semconv_test` + `adoption_surface_test` | 200 tests, 0 failures |
| Full suite `mix test --warnings-as-errors` | 3 doctests, 1748 tests, 1 failure — `Scoria.WarningInventory.CaptureParityTest` only (documented pre-existing baseline flake, WINDOWS.md entry 1, reproduced at pre-phase commit `5a9d0f8f`; **not** a phase 57 regression) |

**Carried debt (not a validation gap).** Code-review finding CR-01 — an unguarded
`Ecto.StaleEntryError` race in `halt_run/3`'s D-52 confluence cleanup — has no covering
test and is tracked at
`.planning/todos/pending/2026-07-29-halt-run-confluence-cleanup-stale-entry-race.md`.
It sits in a halt-time cleanup path, not in the escalate/pause/audit/grade mechanism this
phase's requirements describe, so it does not block Nyquist compliance for GATE-01..04.

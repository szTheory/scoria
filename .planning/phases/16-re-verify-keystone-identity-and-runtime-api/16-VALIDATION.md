---
phase: 16
slug: re-verify-keystone-identity-and-runtime-api
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-16
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` with `Phoenix.LiveViewTest` plus planning-doc grep verification |
| **Config file** | `config/test.exs` |
| **Quick run command** | `rg -n 'verified_by_phase: 16-re-verify-keystone-identity-and-runtime-api|IDEN-01|IDEN-02|IDEN-03|RUNT-01|RUNT-02|RUNT-03|Phase 12 \\| Verified|Phase 13 \\| Verified|Activate .*Keystone.*✓ Good' .planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md .planning/REQUIREMENTS.md .planning/PROJECT.md` |
| **Full suite command** | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `rg -n 'verified_by_phase: 16-re-verify-keystone-identity-and-runtime-api|IDEN-01|IDEN-02|IDEN-03|RUNT-01|RUNT-02|RUNT-03|Phase 12 \\| Verified|Phase 13 \\| Verified|Activate .*Keystone.*✓ Good' .planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md .planning/REQUIREMENTS.md .planning/PROJECT.md`
- **After every plan wave:** Run `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | `IDEN-01`, `IDEN-02` | `T-16-01`, `T-16-02`, `T-16-03` | Phase 12 backfill copies only rerun identity proof into canonical verification artifacts and closes validation rows to terminal truth | integration + docs | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/identity_test.exs test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs test/scoria/runtime_integration_test.exs` | ✅ | ✅ green |
| 16-01-02 | 01 | 1 | `IDEN-02` | `T-16-02`, `T-16-03` | Bounded operator walkthrough records exact identity-lineage observations instead of vague manual closure prose | manual + docs | `rg -n "Operator evidence reads coherently|Observation|actor_id|tenant_id|session_id" .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md .planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md` | ✅ | ✅ green |
| 16-01-03 | 01 | 1 | `IDEN-02` | `T-16-02`, `T-16-03` | Phase 12 final closeout stamps the recorded manual observation into both canonical artifacts and removes all placeholder text | docs | `rg -n "Approval:|approved|Observed|2026-05-16" .planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md && ! rg -n "awaiting operator note|placeholder observation|TBD" .planning/phases/12-canonical-runtime-identity/12-VERIFICATION.md .planning/phases/12-canonical-runtime-identity/12-VALIDATION.md` | ✅ | ✅ green |
| 16-02-01 | 02 | 1 | `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-16-04`, `T-16-05`, `T-16-06` | Phase 13 backfill maps each public runtime requirement to exact targeted proof and reserves the full-suite hygiene pass for wave closeout | integration + docs | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` | ✅ | ✅ green |
| 16-02-02 | 02 | 1 | `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-16-04`, `T-16-05`, `T-16-06` | Phase 13 validation wording matches the supported env and records the full-suite run as secondary regression hygiene, not primary proof | docs + full-suite closeout | `rg -n "SCORIA_DB_PORT=55432 MIX_ENV=test mix test|validated via targeted lanes plus full" .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md && ! rg -n "^\\| 13-..-.. .* ⬜ pending" .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VALIDATION.md && SCORIA_DB_PORT=55432 MIX_ENV=test mix test` | ✅ | ✅ green |
| 16-03-01 | 03 | 2 | `IDEN-01`, `IDEN-02`, `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-16-07`, `T-16-08`, `T-16-09` | Live roadmap, requirements, project, and state surfaces advance only after canonical Phase 12/13 verification exists and historical audits stay unchanged | docs | `rg -n "\\[x\\] 12-01|\\[x\\] 13-04|3/3 \\| Completed|4/4 \\| Completed" .planning/ROADMAP.md && rg -n "\\| IDEN-01 \\| Phase 12 \\| Verified \\||\\| RUNT-03 \\| Phase 13 \\| Verified \\|" .planning/REQUIREMENTS.md && rg -n "Current Focus|Current Position|Last activity" .planning/STATE.md && rg -n 'Activate .*Keystone.*✓ Good|Scope Keystone around identity plus runtime API.*✓ Good' .planning/PROJECT.md` | ✅ | ✅ green |
| 16-03-02 | 03 | 2 | `IDEN-01`, `IDEN-02`, `IDEN-03`, `RUNT-01`, `RUNT-02`, `RUNT-03` | `T-16-07`, `T-16-08`, `T-16-09` | Final milestone-state pass removes remaining false-current wording while keeping historical audits and out-of-scope phases untouched | docs | `! rg -n "0/3 \\| Pending|0/4 \\| Pending|Phase 16 \\| Pending|orphaned|missing verification chain for Keystone identity and runtime APIs|— Pending" .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/STATE.md && rg -n "Phase 12|Phase 13|verified|Completed|✓ Good" .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/STATE.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing repo test files already cover all identity and public-runtime proof seams used by this phase.
- [x] Existing planning artifacts already provide the canonical verification and reconciliation analogs (`07-VERIFICATION.md`, `11-02-SUMMARY.md`).
- [x] No new test framework or fixture installation is required for Phase 16.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator evidence reads coherently after the identity backfill | `IDEN-02` | Existing suites prove persistence and telemetry, but not the operator-facing evidence drilldown end-to-end | Follow the bounded acceptance script written into `.planning/phases/12-canonical-runtime-identity/12-VALIDATION.md`, then paste the observed outcome verbatim into both Phase 12 artifacts |

---

## Validation Audit 2026-05-16

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Audit Evidence

- Targeted Phase 12 backfill lane rerun passed: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/identity_test.exs test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/workflows/runtime_telemetry_test.exs test/scoria/mcp/executor_telemetry_test.exs test/scoria/sre/telemetry_test.exs test/scoria/runtime_integration_test.exs` (`42 tests, 0 failures`).
- Targeted Phase 13 public runtime lane rerun passed: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` (`17 tests, 0 failures`).
- Cross-reference grep passed for `IDEN-*`, `RUNT-*`, `verified_by_phase`, Keystone decision truth, and live-state markers across the canonical Phase 12/13 verification artifacts plus `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, and `.planning/STATE.md`.
- Result: no missing or partial Nyquist coverage found in Phase 16; the only drift was this file's stale `status: draft` metadata.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or an explicit manual checkpoint dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all existing infrastructure dependencies
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Wave 1 and Wave 2 completed on 2026-05-16. Phase 12 and Phase 13 now have canonical verification artifacts, the manual `IDEN-02` operator walkthrough recorded a coherent identity lineage for run `470ddbcc-33e5-4b38-9059-919d44040e0b`, and the live milestone-state docs are reconciled to that backfilled truth.

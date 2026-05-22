---
phase: 38
slug: replay-safe-execution-tool-modes
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scoria/workflows/replay_disposition_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/workflows/replay_disposition_test.exs`
- **After every plan wave:** Run `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | RPLY-02 | T-38-01 | Replay intent remains `live | replay`; seam-level replay truth is persisted separately from run intent | integration | `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/workflows/integration_test.exs` | ❌ W0 | ⬜ pending |
| 38-02-01 | 02 | 1 | RPLY-02 | T-38-02 | Connector and MCP seams default to `historical_stub` or `blocked` for risky replay paths and never silently fall through to live execution | integration | `mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs` | ❌ W0 | ⬜ pending |
| 38-03-01 | 03 | 2 | RPLY-02 | T-38-03 | Replay-live overrides require replay-scoped approval, durable evidence, and retry-safe idempotency | integration | `mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/connectors/invocation_test.exs` — add replay-specific cases for `historical_stub`, `blocked`, and allowlisted `execute_live`
- [ ] `test/scoria/workflows/integration_test.exs` — add missing-evidence and replay-approval integration coverage
- [ ] `test/scoria/workflows/replay_branch_test.exs` — extend replay branch assertions to cover seam-level replay evidence expectations

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator-visible replay badges and evidence phrasing remain calm and unambiguous | RPLY-02 | Final wording and evidence readability depend on composed LiveView output rather than a pure function result | Inspect the workflow run and trace-facing operator surfaces for one safe replay, one historical stub, one blocked seam, and one replay-live override path; confirm each displays disposition and source evidence explicitly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

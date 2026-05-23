---
phase: 38
slug: replay-safe-execution-tool-modes
status: draft
nyquist_compliant: true
wave_0_complete: true
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
| 38-01-01 | 01 | 1 | RPLY-02 | T-38-01 | Replay intent remains `live | replay`; seam-level replay truth is persisted separately from run intent, with fail-closed local classification and exact-match stub rules | integration | `mix test test/scoria/workflows/replay_disposition_test.exs` | ✅ task-owned | ⬜ pending |
| 38-02-01 | 02 | 2 | RPLY-02 | T-38-02 | Connector and MCP seams default to `historical_stub` or `blocked` for risky replay paths, block authority-expanding seams, and never silently fall through to live execution | integration | `mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs` | ✅ existing | ⬜ pending |
| 38-03-01 | 03 | 3 | RPLY-02 | T-38-03 | Replay-live overrides require replay-scoped approval, immutable branch allowlists, durable evidence, and retry-safe idempotency | integration | `mix test test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None. Each plan now owns an automated verification lane directly: plan 38-01 creates its resolver test file as part of Task 1, and plans 38-02/38-03 extend existing test files without a pre-execution scaffold step.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator-visible replay badges and evidence phrasing remain calm and unambiguous | RPLY-02 | Final wording and evidence readability depend on composed LiveView output rather than a pure function result | Inspect the workflow run and trace-facing operator surfaces for one safe replay, one historical stub, one blocked seam, and one replay-live override path; confirm each displays disposition and source evidence explicitly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

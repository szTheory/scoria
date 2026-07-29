---
phase: 57
slug: confluence-escalation-gate
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
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
| TBD | TBD | 0 | GATE-01 | — | `Confluence.classify/1` is total over all 8 leg combinations and returns the correct closed enum value | unit (property-style, no DB) | `mix test test/scoria/confluence_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | GATE-01 | T-57-mint | `scan_tool_output/2` no longer clamps a clean scanner verdict to `"untrusted"` (D-01 mint-site bug) | unit/integration | `mix test test/scoria/mcp/executor_test.exs` | ✅ (needs new cases) | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | T-57-bypass | Escalation pauses BEFORE `execute_live/4` — no budget reserved, no `mcp.access.granted` row written | integration (DB, `Scoria.IntegrationCase`) | `mix test test/scoria/mcp/executor_test.exs --only confluence` | ❌ new `describe` | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | — | `Runtime.execute_handler/6` new exit clause maps to `{:ok, {:waiting_for_approval, attrs, elapsed_ms}}` | integration | `mix test test/scoria/workflows/runtime_test.exs` | ✅ (needs new cases) | ⬜ pending |
| TBD | TBD | TBD | GATE-02 | T-57-replay | Resume after approval re-reaches the identical tool call and does NOT re-escalate (consume CAS) | integration | `mix test test/scoria/workflows_test.exs --only confluence` | ✅ (needs new cases) | ⬜ pending |
| TBD | TBD | TBD | GATE-03 | T-57-audit | Audit row written on `escalate` AND `block`, never on `allow`; `blocker_audit_outbox_event_id` links correctly | integration | `mix test test/scoria/sre_test.exs` (or new `confluence_audit_test.exs`) | ❌ W0 likely | ⬜ pending |
| TBD | TBD | 0 | GATE-04 | — | `declared: :escalate` enforces by default; the three weak grades emit telemetry only, never block | unit | `mix test test/scoria/confluence_test.exs --only grading` | ❌ W0 (same new file) | ⬜ pending |
| TBD | TBD | TBD | GATE-04 | T-57-leak | `Semconv.confluence_attributes/1` is a no-passthrough fixed-key projector; registry canary includes the new keys | unit | `mix test test/scoria/observe/semconv_test.exs` | ✅ (canary list update) | ⬜ pending |
| TBD | TBD | TBD | D-53 | — | Guide no longer denies the confluence claim; positive assertion fails if the edit is missing | unit (doc-content) | `mix test test/scoria/adoption_surface_test.exs` | ✅ (needs positive assertion) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/confluence_test.exs` — pure classifier property-style coverage over all 8 leg combinations + grading matrix (GATE-01, GATE-04)
- [ ] Confluence-specific audit coverage — new file or `describe` block appended to `sre_test.exs` / `workflows_test.exs` (GATE-03)
- [ ] Framework install: **none needed** — ExUnit is already fully configured, no new test dependency

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human approval UX copy reads correctly in the approval surface | GATE-02 | Copy/legibility judgement is not assertable beyond string presence | Trigger a confluence escalation in the dev harness and read the rendered approval prompt |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (quick lane)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 53B
slug: ai-span-events-emit-event-1
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 53B — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` (`Ecto.Adapters.SQL.Sandbox`) |
| **Quick run command** | `mix test <file>` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~depends on Postgres-backed integration tests (real DB) |

Integration proofs (SC#1, SC#4) use the ready-to-copy scoped-Buffer + real `Telemetry.attach/1` + `flush_now` + real-Postgres scaffold at `test/scoria/observe/prompt_span_test.exs`. Never hand-synthesize a telemetry event as production evidence.

---

## Sampling Rate

- **After every task commit:** Run `mix test <touched test file>`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** integration tests dominate; keep unit/drift-guard tests fast

---

## Per-Task Verification Map

*Populated once PLAN.md files exist (planner emits `<verify>` per task; `/gsd-validate-phase` reconciles). Success-criteria → validation-seam map below is the acceptance bar the per-task rows must collectively satisfy.*

| SC | Requirement | Validation seam | Test type | File / template |
|----|-------------|-----------------|-----------|-----------------|
| SC#1 identical redact | EVENT-02 | Deny-listed key inside an event's `:attributes` returns `[REDACTED]` through the same `Redactor.redact/1` as spans | integration (real Postgres) + source-scan drift guard | copy `prompt_span_test.exs`; drift guard scoped to `lib/scoria/observe/telemetry.ex` ONLY (5 `Redactor.redact(` sites in `lib/`) |
| SC#2 closed vocabulary | EVENT-02 | Unknown name rejected/logged, never persisted — via BOTH direct `emit_event/1` AND raw `:telemetry.execute([:scoria,:observe,:event,:emit],…)` | integration + unit | both paths call `Semconv.event_name?/1`; canary asserts both reject |
| SC#3 real call sites | EVENT-03 | `prompt_rendered` (judge `build_judge_prompt_span/3`) and `guardrail_triggered` (`Guardrail.do_emit`) fire in normal operation; `user_feedback_received` has NO `lib/` emitter | integration (not hand-synthesized) + anti-inline grep-guard | grep-guard template at `test/scoria/observe/semconv_test.exs:128-142` |
| SC#4 orphan isolation | EVENT-02 | Flush 50 valid spans + 1 orphan event (span never flushed) → 50 spans + orphan row persists, nothing lost; nil-`span_id`/missing-`time` raw-bus event dropped at handler, 50 good events land | integration (real Postgres), two tests | copy `prompt_span_test.exs` scaffold |

---

## Wave 0 Requirements

- [ ] New test file(s) for the `:event` path — new `event_emit_test.exs` vs. folding into `telemetry_test.exs` is Claude's Discretion (no CONTEXT decision).
- [ ] Reuse existing `Ecto.Adapters.SQL.Sandbox` + scoped-Buffer fixtures (`prompt_span_test.exs`) — no new framework install.

*Existing ExUnit + Postgres sandbox infrastructure covers all phase requirements; no framework bootstrap needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification (SC#1–SC#4 are all test-provable). No operator UI ships this phase (deliberate — Phase 53 D-08).*

---

## Validation Sign-Off

- [ ] All tasks have `<verify>` automated commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

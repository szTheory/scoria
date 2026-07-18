---
phase: 53B
slug: ai-span-events-emit-event-1
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-18
validated: 2026-07-18
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

*Reconciled by `/gsd-validate-phase` on 2026-07-18 against the shipped PLAN/SUMMARY set and the tests on disk. Every row is COVERED by an automated test that was independently re-run green in this audit (102 tests, 0 failures across the seven files below). Success-criteria → validation-seam map is the acceptance bar; the per-plan rows collectively satisfy it.*

### Acceptance bar (ROADMAP success criteria)

| SC | Requirement | Validation seam | Test type | Test location | Status |
|----|-------------|-----------------|-----------|---------------|--------|
| SC#1 identical redact | EVENT-02 | Deny-listed key (`session_id`, via Redactor `deny_list` config seam) inside an event's `:attributes` returns `[REDACTED]` through the same `Redactor.redact/1` as spans; allow-listed `template_ref` survives | integration (real Postgres) + source-scan drift guard | `event_emit_test.exs:84` "SC#1"; drift guard `telemetry_test.exs:128` (asserts exactly 1 `Redactor.redact(` token in `telemetry.ex`) | ✅ COVERED |
| SC#2 closed vocabulary | EVENT-02 | Unknown name rejected/never persisted via BOTH direct `emit_event/1` (`{:error, :unknown_event}`) AND raw `:telemetry.execute([:scoria,:observe,:event,:emit],…)` (handler re-check fires `…:rejected`) | integration + unit | `event_emit_test.exs:119` (both paths); `observe_test.exs:246` (direct contract); `telemetry_test.exs:171` (raw-bus); `semconv_test.exs:446` (vocabulary) | ✅ COVERED |
| SC#3 real call sites | EVENT-03 | `prompt_rendered` (judge `build_judge_prompt_span/4`) and `guardrail_triggered` (`Guardrail.do_emit`) fire in normal operation; `user_feedback_received` has NO `lib/` emitter | integration (not hand-synthesized) + anti-inline grep-guard | `guardrail_test.exs:359` (block/escalate emit, allow does not); `judge_runner_test.exs:128` (real render, no free-text leak); reserved-only grep guard `semconv_test.exs:484` | ✅ COVERED |
| SC#4 orphan isolation | EVENT-02 | 50 valid spans + 1 orphan event (span never flushed) → 50 spans + orphan row persists, nothing lost | integration (real Postgres) | `event_emit_test.exs:200` "SC#4"; two-phase flush unit proof `buffer_test.exs:198` | ✅ COVERED |

### Corollary contracts (Plan-level must-haves)

| ID | Requirement | Validation seam | Test type | Test location | Status |
|----|-------------|-----------------|-----------|---------------|--------|
| D-05 fail-closed batch atomicity | EVENT-02 | nil-`span_id` dropped at handler; missing-`time` defaulted+persists; type-invalid `time`/`span_id` (CR-01) coerced/dropped — 50 good siblings + defaulted survivors land, batch never rolls back (exact count 52) | integration (real Postgres) | `event_emit_test.exs:240` "D-05"; `telemetry_test.exs:200` (nil span_id → `:nil_span_id`) | ✅ COVERED |
| SEC-01 Bounds:event wiring | EVENT-03 | Oversized registered value truncated + unregistered key dropped in persisted event row, identical to a span attribute | integration (real Postgres) | `event_emit_test.exs:168` "SEC-01" | ✅ COVERED |
| Buffer error isolation | EVENT-02 | Event flush error reuses signal-parameterized `surface_flush_error/6`; GenServer survives; `:raise` reraises on timer path only, never from `terminate/2` | unit | `buffer_test.exs:86,128,149` | ✅ COVERED |
| FK-drop (orphan insertable) | EVENT-02 | `ai_span_events.span_id` FK dropped; column stays NOT NULL + indexed; migration round-trips | migration round-trip (manual) + behavioral effect automated | manual `mix ecto.migrate`/`rollback` round-trip (Plan 01 D1); effect proven automatically by SC#4 orphan-persist test | ✅ COVERED |

---

## Wave 0 Requirements

- [x] New test file(s) for the `:event` path — new `test/scoria/observe/event_emit_test.exs` created (Plan 05, 6 SC-canary tests).
- [x] Reuse existing `Ecto.Adapters.SQL.Sandbox` + scoped-Buffer fixtures (`prompt_span_test.exs`) — no new framework install; scaffold reused verbatim.

*Existing ExUnit + Postgres sandbox infrastructure covered all phase requirements; no framework bootstrap was needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification (SC#1–SC#4 are all test-provable). No operator UI ships this phase (deliberate — Phase 53 D-08).*

---

## Validation Sign-Off

- [x] All tasks have `<verify>` automated commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-18 (all requirements automated; 0 manual-only)

---

## Validation Audit 2026-07-18

Input state **A** (existing pre-execution draft VALIDATION.md, created before the PLANs). Reconciled the placeholder SC→seam map against the shipped PLAN/SUMMARY set and the tests on disk; ran all seven phase-relevant test files (`event_emit_test.exs`, `telemetry_test.exs`, `observe_test.exs`, `buffer_test.exs`, `semconv_test.exs`, `guardrail_test.exs`, `judge_runner_test.exs`) → **102 tests, 0 failures**.

| Metric | Count |
|--------|-------|
| Requirements/SCs audited | 7 (SC#1–SC#4, D-05, SEC-01, Buffer isolation) |
| COVERED | 7 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 0 |
| Resolved (auditor-generated) | 0 (none needed) |
| Escalated to manual-only | 0 |

No `gsd-nyquist-auditor` spawn was required — every requirement already had a green automated test. The one manual step (Plan 01's FK-drop migration round-trip) has its behavioral effect covered automatically by the SC#4 orphan-persist test, so it is not carried as a manual-only gap. Phase is **Nyquist-compliant**.

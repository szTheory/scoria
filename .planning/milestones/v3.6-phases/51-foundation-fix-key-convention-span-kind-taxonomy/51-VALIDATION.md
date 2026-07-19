---
phase: 51
slug: foundation-fix-key-convention-span-kind-taxonomy
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-12
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/scoria/observe/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/observe/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green (real-Postgres persistence test included)
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

> Filled by the planner from PLAN.md `<verify>`/`<acceptance_criteria>` blocks. Rows below are the validation seams the RESEARCH.md Validation Architecture identifies as load-bearing for the 5 ROADMAP success criteria.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-03-T2 | 51-03 | 1 | FOUND-01 | — | Span persists to `ai_spans` with matching `ai_traces` row via real adapter path against real Postgres; no silent rescue | unit/integration | `mix test test/scoria/observe/buffer_test.exs` | ❌ W0 | ⬜ pending |
| 51-03-T1 | 51-03 | 1 | FOUND-01 | — | `[:scoria,:observe,:buffer,:flush_error]` telemetry event fires with `dropped_count > 0` on induced constraint failure; `:on_flush_error: :raise` also provable | unit | `mix test test/scoria/observe/buffer_test.exs` | ❌ W0 | ⬜ pending |
| 51-01-T3 | 51-01 | 1 | FOUND-02 | — | `SpanKind.kinds()` canary == `~w(agent llm prompt tool mcp retriever guardrail eval)`; exhaustive `to_openinference/1`; anti-inline grep guard | unit | `mix test test/scoria/observe/span_kind_test.exs` | ❌ W0 | ⬜ pending |
| 51-02-T1 | 51-02 | 1 | FOUND-03 | — | Every `gen_ai.*`/`openinference.*` key string sourced from `Scoria.Observe.Semconv` (no inline literals at call sites) | unit | `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 | ⬜ pending |
| 51-04-T1 | 51-04 | 2 | SPAN-01 | — | Persisted LLM span carries `gen_ai.request.model/.temperature/.top_p/.max_tokens/.seed` + `gen_ai.usage.*` together (never a partial subset) | integration | `mix test test/scoria/observe/adapters/req_llm_test.exs` | ❌ W0 | ⬜ pending |
| 51-04-T1 / 51-05-T1 | 51-04, 51-05 | 2 | SPAN-02 | — | Adapter sets native lowercase `span_kind` + mirrored `openinference.span.kind`; `mcp`→`TOOL`; Jido default `tool` | integration | `mix test test/scoria/observe/adapters/` | ❌ W0 | ⬜ pending |
| 51-04-T3 | 51-04 | 2 | COMPAT-01 | — | CHANGELOG `0.1.4` breaking-change entry with literal old→new mapping table + upgrade-guide sentence; legacy keys absent from adapter output | doc/source | `grep` assertions + `mix test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/observe/span_kind_test.exs` — drift-guard suite for FOUND-02 (D-15)
- [ ] `test/scoria/observe/semconv_test.exs` — key-source single-origin assertions for FOUND-03
- [ ] `test/scoria/observe/buffer_test.exs` — extend with `:flush_error` telemetry + `:on_flush_error: :raise` + `:flush_now` sync hook (may already exist; augment)
- [ ] `test/scoria/observe/adapters/req_llm_test.exs` — replace unrealistic `model: "gpt-4"` fixture with a real `%LLMDB.Model{}` struct (RESEARCH pitfall)
- [ ] Real-Postgres persistence fixture (sandbox) exercising the adapter → Buffer → `insert_all` path for Success Criterion #1

*Existing ExUnit + Ecto SQL sandbox infrastructure covers the framework; only the above test files/fixtures are new.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CSS status-overlay renders (`.scoria-span--status-error` left-border + alert icon + aria "errored", WCAG dark/light/system, not color-only) | SPAN-02 / D-12 | Visual/accessibility rendering not fully assertable in ExUnit | Load trace tree with an errored LLM span; confirm real-kind rail + status overlay, aria label present, contrast in dark & light |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (the new/extended test files are owned by each plan's Task 1)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter
- [x] No full-E2E frameworks (ExUnit + Ecto SQL sandbox only)

**Approval:** ready

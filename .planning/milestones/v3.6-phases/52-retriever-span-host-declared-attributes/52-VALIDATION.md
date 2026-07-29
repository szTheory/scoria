---
phase: 52
slug: retriever-span-host-declared-attributes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-12
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `52-RESEARCH.md` § Validation Architecture. The mandatory shape for
> RETR-02 (D-RETR02-7) and ATTR-01 (D-ATTR01-6) is the Phase-51 drift-guard discipline:
> **canary + exhaustiveness + anti-inline grep + real-Postgres assertion after `Buffer.flush_now/1`.**

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs`; knowledge lane gated by `@moduletag :knowledge` (`test/support/knowledge_case.exs:10`) |
| **Quick run command** | `mix test test/scoria/observe/` (fast: no-DB unit + canary + anti-inline grep guards) |
| **Full suite command** | `mix scoria.test.knowledge` (real Postgres/pgvector — the join, span↔table equality, SC#4 acceptance) then `mix test` |
| **Estimated runtime** | observe lane ~a few seconds; knowledge lane ~30–60s (pgvector bootstrap + migrate) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/observe/`
- **After every plan wave:** Run `mix scoria.test.knowledge`
- **Before `/gsd-verify-work`:** Full `mix test` must be green
- **Max feedback latency:** ~60 seconds (knowledge lane)

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| RETR-01 | `retrieve/2` produces a persisted `ai_retrieval_runs` row AND a linked RETRIEVER span sharing `trace_id`/`span_id`; join never empty for a successful call | integration (real Postgres, after `flush_now/1`) | `mix scoria.test.knowledge --only knowledge` | ⚠️ file exists; NEW assertions + W0 | ⬜ pending |
| RETR-01 | Span emission never fails retrieval (D-R6 `try/rescue → :ok`) | integration | same lane — induce an emit-path raise, assert `retrieve/2` still `{:ok, …}` | ❌ W0 | ⬜ pending |
| RETR-01 | **D-R2b mandatory migration** — `retrieval_test.exs:60,65` `span_id:`→`parent_id:`; assert `run.span_id == <minted own-id>` and `retriever_span.parent_id == <passed span.id>` | integration | `mix scoria.test.knowledge --only knowledge` | ⚠️ EXISTS `:47-72` — must be EDITED | ⬜ pending |
| RETR-02 | `scoria.retrieval.*` keys equal on `span.attributes` AND `run.metadata`; canary key list; anti-inline grep | drift-guard (canary + real-Postgres equality + grep) | `mix scoria.test.knowledge` + `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 (extend `semconv_test.exs`) | ⬜ pending |
| RETR-02 | Sentinel `"none"` on all three keys when absent (never nil / never omit) | unit + integration | same | ❌ W0 | ⬜ pending |
| RETR-02 | Guarded optional `model_name/0` — host embedder without it falls through, no `UndefinedFunctionError` | unit | `mix test test/scoria/knowledge/` (embedder test) | ❌ W0 | ⬜ pending |
| ATTR-01 | Sentinel host value passes byte-for-byte through to persisted span attributes (per span type) | drift-guard (pass-through) | `mix scoria.test.knowledge` + observe lane | ❌ W0 | ⬜ pending |
| ATTR-01 | Empty metadata ⇒ keys ABSENT (`refute Map.has_key?`) — the never-default proof | unit/integration | same | ❌ W0 | ⬜ pending |
| ATTR-01 | Anti-inline grep: only `semconv.ex` writes a reserved key string | source-scan | `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 | ⬜ pending |
| ATTR-01 | Guards use REAL emissions, not hand-synthesized events (D-ATTR01-6 ⚠) | integration | RETRIEVER span: real `retrieve/2`; prompt span: real `emit_prompt_span/1` | ❌ W0 | ⬜ pending |
| ATTR-02 | **SC#4 acceptance** — populated pack (≥1 chunk AND ≥1 memory w/ token counts) → nested `scoria.prompt.context` coexists with `gen_ai.usage.input_tokens` on same persisted span (after `flush_now/1`) | integration (real Postgres) | `mix scoria.test.knowledge` (or observe integration test calling `emit_prompt_span/1` + `flush_now/1`) | ❌ W0 (D-ATTR02-7) | ⬜ pending |
| ATTR-02 | Never-text structural guard: every key ∈ allowed set; no key matches `~r/text\|content\|body\|message\|prompt\|raw/i`; leaves are ID-binary ≤64B or non-neg int; `Jason.encode!` ≤ 8KB | drift-guard (over fully-built value) | `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 (D-ATTR02-4) | ⬜ pending |
| ATTR-02 | `input_tokens` absence tolerated (usage nil) — no unconditional-presence assertion | unit | same | ❌ W0 (D-ATTR02-5) | ⬜ pending |
| ATTR-02 | ≤100-item cap with `"truncated" => true` marker | unit | `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 (D-ATTR02-6) | ⬜ pending |
| ATTR-02 | Empty/absent pack ⇒ key omitted entirely | unit | same | ❌ W0 (D-ATTR02-7) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/knowledge/retrieval_test.exs` — **EDIT** the existing `span_id:`→`parent_id:` assertion (D-R2b, `:60/:65`) AND add the RETR-01 join + RETR-02 real-Postgres equality assertions — covers RETR-01, RETR-02.
- [ ] `test/scoria/observe/semconv_test.exs` — **EXTEND** with the RETR-02 canary + anti-inline grep, ATTR-01 never-default + grep, ATTR-02 never-text / cap / omit guards — covers RETR-02, ATTR-01, ATTR-02.
- [ ] New/extended embedder test — guarded optional `model_name/0` fall-through — covers RETR-02.
- [ ] New observe integration test (or fold into knowledge lane) — `emit_prompt_span/1` + `flush_now/1` → SC#4 populated-pack acceptance + ATTR-01-on-the-prompt-span real-emission guard — covers ATTR-02, ATTR-01.
- [ ] Framework install: none — ExUnit + the `mix scoria.test.knowledge` lane already exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| RETRIEVER span visible in the trace tree with its rail | RETR-01 | Rendering is UI; correctness is covered by the persisted-span integration test. Research confirms **zero required UI edits** (`trace_tree_component.ex:34,86-90`; CSS `04-components.css:1087`) | Open `orchestrator_live.ex` trace view after a real `retrieve/2`; confirm a `RETRIEVER`-rail node appears. Rich attribute display is out of Phase-52 scope. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 53
slug: structured-child-spans-write-time-bound
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-12
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `53-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 — the project's only test framework) |
| **Config file** | `test/test_helper.exs` + `mix.exs` `test_load_filters`/`test_ignore_filters` |
| **Quick run command** | `mix test test/scoria/observe/ --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~30s quick / ~3-5 min full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/observe/ --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds (quick run)

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. This map is keyed by behavior; the planner
> MUST attach each row's automated command to the task that delivers the behavior.

| Behavior | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|----------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| `Scoria.Observe.Buffer` boots under `Scoria.Application`; `Telemetry.attach/1` fires on boot | EVENT-01 | — | N/A | integration | `mix test test/scoria/application_test.exs` | ❌ W0 | ⬜ pending |
| `span/4` records real duration, marks `status_code: "ERROR"` on raise, reraises host exception unchanged (single emit, no double-emit) | EVENT-01 | — | `exception.type` only — never `exception.message`/stacktrace | unit | `mix test test/scoria/observe/span_test.exs` | ❌ W0 | ⬜ pending |
| tool/prompt/retrieval/guardrail spans persist with `parent_id` linkage through the real Buffer (`flush_now/1`) | EVENT-01 | — | every producer sets `tenant_id` | integration (real Postgres) | `mix test test/scoria/observe/guardrail_test.exs test/scoria/observe/adapters/mcp_test.exs` | ❌ W0 | ⬜ pending |
| MCP 4-event tool lifecycle produces child spans | EVENT-01 | — | `args_fingerprint` (hashed), never raw args | integration | `mix test test/scoria/observe/adapters/mcp_test.exs` | ❌ W0 | ⬜ pending |
| Trace tree renders visual nesting (CSS `--indent-level` actually consumed) | EVENT-01 | — | N/A | unit (LiveComponent render) | `mix test test/scoria_web/components/trace_tree_component_test.exs` | ✅ exists — **must be rewritten** (currently asserts the flat-DOM bug) | ⬜ pending |
| `TraceProjection.depth_for/3` terminates on a parent cycle | EVENT-01 | DoS (cycle) | N/A | unit | `mix test test/scoria/observe/trace_projection_test.exs` | ✅ exists — add cycle case | ⬜ pending |
| Closed `Semconv` key registry canary — exact key list + exhaustiveness; RED when an unbounded free-text key is added | SEC-01 | T-INFO-01 | drop-not-truncate on unregistered keys | unit | `mix test test/scoria/observe/bounds_test.exs` | ❌ W0 | ⬜ pending |
| Exact dot-segment key matching (not substring): `args_fingerprint` survives, `gen_ai.input.messages` dropped | SEC-01 | T-INFO-01 | allowlist, positive validation | unit | `mix test test/scoria/observe/bounds_test.exs` | ❌ W0 | ⬜ pending |
| `req_llm` exact-key denylist canary (`gen_ai.system_instructions`, `gen_ai.tool.definitions` dropped) — version-pinned | SEC-01 | T-SUPPLY-01 | catches upstream capture-surface drift on version bump | unit | `mix test test/scoria/observe/bounds_test.exs` | ❌ W0 | ⬜ pending |
| Non-map `Redactor.redact/1` output fails closed in `Bounds` | SEC-01 | T-INFO-01 | fail-closed | unit | `mix test test/scoria/observe/bounds_test.exs` | ❌ W0 | ⬜ pending |
| `Bounds.enforce/2` runs BEFORE `ReviewerBroadcast`, not just before `Buffer` | SEC-01 | T-DOS-01 (browser DoS via 2 MB attr map) | bound before broadcast | unit | `mix test test/scoria/observe/bounds_test.exs` | ❌ W0 | ⬜ pending |
| `Guardrail.emit/1` never persists a free-text `reason` key | EVENT-01, SEC-01 | T-INFO-01 | reason_code only, no free text | unit + real-Postgres regression | `mix test test/scoria/observe/guardrail_test.exs` | ❌ W0 | ⬜ pending |
| Dashboard hydration survives Bounds ON (pre-seeded bare keys) | SEC-01 | — | no regression in operator UI | integration (Postgres + `OrchestratorLive`) | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ exists — add Bounds-on case | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/observe/span_test.exs` — `span/4` duration / failure / reraise semantics (EVENT-01)
- [ ] `test/scoria/observe/guardrail_test.exs` — guardrail span shape + never-free-text guarantee (EVENT-01, SEC-01)
- [ ] `test/scoria/observe/adapters/mcp_test.exs` — 4-event MCP tool lifecycle → child spans (EVENT-01)
- [ ] `test/scoria/observe/bounds_test.exs` — full SEC-01 registry / denylist / fail-closed surface (SEC-01)
- [ ] `test/scoria/application_test.exs` — Buffer supervision + `Telemetry.attach/1` on boot (EVENT-01, D-00a)
- [ ] `test/scoria_web/components/trace_tree_component_test.exs` — **targeted rewrite**: existing file asserts the flat-DOM bug this phase fixes. Not a coverage gap, a correctness gap in existing coverage.
- [ ] Framework install: **none** — ExUnit + `Ecto.Adapters.SQL.Sandbox` already fully wired.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual nesting reads correctly at depth > 3 in a real browser | EVENT-01 | CSS `calc()` indent is asserted in DOM by the component test, but visual legibility at depth is a judgment call | Boot `mix phx.server` (DevEndpoint), open the trace tree for a seeded nested trace, confirm indentation is visible and does not overflow the container |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-12 (gsd-plan-checker: VERIFICATION PASSED — all 8 plans carry `<automated>` verify commands scoped to targeted `mix test` runs; every Wave 0 gap is owned by a named task)

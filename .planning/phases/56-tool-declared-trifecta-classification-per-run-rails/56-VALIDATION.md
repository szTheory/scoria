---
phase: 56
slug: tool-declared-trifecta-classification-per-run-rails
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-27
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (ships with Elixir/OTP — no separate version to pin) |
| **Config file** | none dedicated — `test/test_helper.exs` + `mix.exs`'s `elixirc_paths(:test)` govern the test tree |
| **Quick run command** | `mix test test/scoria/mcp/classification_test.exs test/scoria/mcp/executor_test.exs test/scoria/workflows/replay_disposition_test.exs test/scoria/connectors/invocation_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~45 seconds quick run · ~6 minutes full suite |

**`--warnings-as-errors` is load-bearing, not hygiene.** D-01's `@optional_callbacks [classification: 0]` exists precisely because a *required* callback would emit an "undefined behaviour function" warning on every existing tool module, which this repo escalates to a hard build failure (`AGENTS.md`). Any verification command that drops the flag cannot detect the regression D-01 is designed to prevent.

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

Note: `test/scoria/mcp/executor_test.exs` declares `use ExUnit.Case, async: false` and is DB-backed (Postgres via `SCORIA_DB_PORT`); the quick run is not a pure-unit fast path.

---

## Per-Task Verification Map

Task IDs are assigned by the planner. This map is seeded at requirement granularity; `/gsd-validate-phase` refines it to per-task rows once PLAN.md files exist.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0 | CLASS-01 | — | Test stubs exist before implementation (Wave 0 scaffold) | unit | `mix test test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | CLASS-01 | T-56-01 | Tool declares trifecta legs + `action_class` once via `classification/0`; a module *without* the callback still compiles clean under `--warnings-as-errors` (`@optional_callbacks`) | unit | `mix test test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | CLASS-01 | T-56-01 | Existing `@behaviour Scoria.MCP.Tool` fixtures (`DummyTool`, `ActualUnitsTool`, `BlockingTool` — 4 required callbacks only) still compile and execute unchanged | regression | `mix test test/scoria/mcp/executor_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | CLASS-01 | T-56-04 | `normalize_action_class/1` fail-closes junk/unknown input to `"admin"` before any ordinal lookup; `action_classes/0` preserves `~w(read write exec admin)` order (index 0 = `"read"` is pinned by `Enum.drop(@effectful_classes, 1)` at `replay_disposition.ex:92`) | unit | `mix test test/scoria/mcp/classification_test.exs test/scoria/workflows/replay_disposition_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 2 | CLASS-02 | T-56-01 | Undeclared tool resolves to the maximal fail-closed default (all three legs `true`, `action_class: "admin"`, `source: :unclassified_default`) and **still runs**, emitting `[:scoria, :class, :unclassified]` | unit + telemetry | `mix test test/scoria/mcp/executor_telemetry_test.exs test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ W0 (assertions) / ✅ (host file) | ⬜ pending |
| TBD | TBD | 2 | CLASS-02 | T-56-01 | With `config :scoria, :require_tool_classification, true`, resolution refuses with `{:error, %{status: :unclassified_tool, ...}}`; default-off path is unchanged | unit | `mix test test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 2 | CLASS-02 | T-56-04 | Resolved values are written **only** to new namespaced keys — no write to `:policy_sensitive`, `:sensitive_tool`, `:approval_sensitive`, `:local_classification`, `:action_class`, or `:risk_level` (D-03 hard prohibition) | unit (structural) | `mix test test/scoria/workflows/replay_disposition_test.exs test/scoria/mcp/executor_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 2 | CLASS-02 | — | `%{"scoria.classification" => ...}` persists into `step.result_envelope` through the existing jsonb `fragment("? \|\| ?")` choke point | integration | `mix test test/scoria/mcp/executor_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | T-56-02 | Tighten-only join: legs `or`, `action_class` max. Directional pair both ways — `join("read","admin") == "admin"` **and** `join("admin","read") == "admin"` (polarity is inverted vs Phase 55 D-19's `Trust.Scan.most_restrictive/2` min-join at `scan.ex:40,128-130`) | unit (directional) | `mix test test/scoria/workflows/replay_disposition_test.exs --warnings-as-errors` | ✅ (extend) | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | T-56-02 | Host disagreement table: host absent → declaration wins silently; host tighter → `source: :host_tightened`; host looser/junk → clamp + `Logger.warning` + `[:scoria, :class, :precedence_conflict]`. `:unclassified_default` is never a join operand | unit | `mix test test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | T-56-04 | **Non-bricking regression (site 5, "the worst"):** a replay call using `runtime.ex:474`'s default `%{local_classification: :pure}` seam that resolves `:execute_live` today STILL resolves `:execute_live` after classification wiring lands | unit (regression) | `mix test test/scoria/workflows/replay_disposition_test.exs --warnings-as-errors` | ✅ (extend) | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | T-56-04 | Sites 1–3 reflect resolved classification: `build_replay_seam/2` (`executor.ex:181-196`), `policy_sensitive_invocation?/1` (`executor.ex:552-554`), `budget_required?/1` (`executor.ex:442-447`) | integration | `mix test test/scoria/mcp/executor_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | T-56-04 | Site 4: `Connectors.Invocation.build_seam/2` reflects resolved classification **before** its own `replay_resolution/5` call at `invocation.ex:26` | integration | `mix test test/scoria/connectors/invocation_test.exs --warnings-as-errors` | ✅ (extend) | ⬜ pending |
| TBD | TBD | 3 | CLASS-03 | — | Semconv registry canary updated for the new `scoria.classification.*` attribute keys | unit (structural) | `mix test test/scoria/observe/semconv_test.exs --warnings-as-errors` | ✅ (**must be edited**, not merely re-run) | ⬜ pending |
| TBD | TBD | 3 | CLASS-01/02/03 | — | Phase-wide: full suite green under `--warnings-as-errors` | full suite | `mix test --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Threat refs** resolve against the `<threat_model>` block each PLAN.md carries (ASVS L1, block-on `high`). Seeded IDs map to the research Security Domain rows: `T-56-01` silent under-classification (Elevation of Privilege) · `T-56-02` request-derived context loosening a declared classification (Tampering / EoP) · `T-56-03` cascading over-classification degrading Phase 57's signal (DoS of the signal) · `T-56-04` seam-key clobbering flipping the replay-safety invariant (Tampering).

---

## Wave 0 Requirements

- [ ] `test/scoria/mcp/classification_test.exs` — **new file.** Stubs for CLASS-01 (struct shape, `@enforce_keys [:source]`, closed-enum order, `use Scoria.MCP.Tool, reads_private_data: true, ...` macro, `Code.ensure_loaded?/1` + `function_exported?/3` detection, `:persistent_term` memoization) and CLASS-02 (unclassified maximal default, telemetry event, `require_tool_classification` refusal path)
- [ ] `test/scoria/workflows/replay_disposition_test.exs` — **additions to an existing file.** D-04 directional join pair (both argument orders) + the site-5 `%{local_classification: :pure}` non-bricking regression test
- [ ] `test/scoria/observe/semconv_test.exs` — **required edit to an existing structural guard**, not a coverage gap. The `attribute_registry/0` canary list must gain the `scoria.classification.*` keys the moment they are registered, or the guard fails
- [ ] No framework or config install needed — ExUnit + existing `mix.exs` aliases cover this domain. There is no `mix test.classification` alias today (unlike `test.knowledge` / `test.connector`) and no existing contract requires one; the planner may add one for convenience

---

## Manual-Only Verifications

*None.* All phase behaviors have automated verification — this phase is 100% in-repo library code with no UI surface, no external service, and no environment probe (`## Environment Availability` in RESEARCH.md: "Not applicable").

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 56-tool-declared-trifecta-classification-per-run-rails
verified: 2026-07-28T17:35:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: No — initial verification
---

# Phase 56: Tool-Declared Trifecta Classification Verification Report

**Phase Goal:** Every tool call enforced at `MCP.Executor` carries an explicit, tool-declared trifecta classification instead of a silent host-passed default.
**Verified:** 2026-07-28T17:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A tool declares its trifecta legs + `action_class` once, on the tool itself | ✓ VERIFIED | `lib/scoria/mcp/tool.ex:36-38` adds `@callback classification() :: Scoria.MCP.Classification.t()` with `@optional_callbacks [classification: 0]`; `defmacro __using__/1` (`tool.ex:51-70`) generates it from `use Scoria.MCP.Tool, reads_private_data: ..., action_class: ...` opts via `Classification.declared/1`. `mix compile --warnings-as-errors` exits 0, proving existing 4-callback-only tool modules (`DummyTool`, `ActualUnitsTool`, etc.) still compile clean. |
| 2 | An unclassified tool fails closed to an inspectable default (not silent `approval_sensitive: false`) and emits telemetry | ✓ VERIFIED | `Classification.unclassified_default/0` (`classification.ex:117-126`) returns all three legs `true`, `action_class: "admin"`, `source: :unclassified_default`. `Executor.resolve_classification/2` (`executor.ex:63-80`) emits exactly one `[:scoria, :class, :unclassified]` event with a `site` discriminator per call when `tool_declaration/1` returns `:none`. The opt-in `config :scoria, :require_tool_classification` (default `false`, `executor.ex:88-92`) additionally hard-refuses with `{:error, %{status: :unclassified_tool, ...}}` when enabled — real enforcement path exists, not telemetry-only. |
| 3 | At `MCP.Executor` enforcement, every tool call's per-call taint is resolved from the tool's own declaration, never a host-passed default | ✓ VERIFIED | `execute/4` (`executor.ex:27-43`) routes every call through `resolve_classification/2` before `replay_gate/3`; resolution reads `Classification.tool_declaration(tool_module)` (the tool's own declaration) and joins tighten-only against any host context via `Classification.resolve/2` (`classification.ex:301-340`) — the join can only tighten (`or` on legs, ordinal `max` on `action_class`), never loosen or substitute a host value alone. `:unclassified_default` is never a join operand (explicit clause, `classification.ex:302`). |
| 4 | Resolution covers ALL FIVE fail-open seams (replay seam, `policy_sensitive_invocation?/1`, `budget_required?/1`, `Connectors.Invocation.build_seam/2`, `Workflows.Runtime`'s `%{local_classification: :pure}` default) | ✓ VERIFIED (all 5 sites individually confirmed in source — see per-site table below) | See "Criterion 4: Per-Site Verification" below. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Criterion 4: Per-Site Verification (individually checked, not aggregated)

| Site | Location | Consumes classification? | Prohibited keys touched? | Evidence |
|---|---|---|---|---|
| 1 — Replay seam (`build_replay_seam/2`) | `lib/scoria/mcp/executor.ex:273-289` | Yes — `tool_classification: Map.get(context, :tool_classification)` added as a new entry (line 275) | No — `local_classification`, `action_class`, `risk_level`, `approval_sensitive` lines unchanged (byte-identical hardcoded fallbacks `:write`/`"write"`/`"high"`/`false`) | Negative grep for `Map.put(seam/context, :prohibited-key...)` returns nothing across `executor.ex`, `invocation.ex`, `runtime.ex` |
| 2 — Live path `policy_sensitive_invocation?/1` | `lib/scoria/mcp/executor.ex:730-733` | Yes — `Classification.declared_sensitive?(Map.get(context, :tool_classification))` added as 3rd OR operand | No — first two `Map.get(context, :policy_sensitive)` / `:sensitive_tool` operands unchanged | `declared_sensitive?` grep count in `executor.ex` = 2 (both real call sites); `Executor.execute/4` test suite passes (36 tests) |
| 3 — `budget_required?/1` | `lib/scoria/mcp/executor.ex:611-617` | Yes — same shared `Classification.declared_sensitive?/1` predicate as 5th OR operand | No — 4 pre-existing `Map.get/2` operands unchanged | Same shared predicate as site 2 (single origin, cannot drift) |
| 4 — `Connectors.Invocation.build_seam/2` | `lib/scoria/connectors/invocation.ex:70-94` | Yes — `invoke/4` resolves classification at line 30 (immediately after `normalize_map(context)`, BEFORE `build_seam/2` at line 32 and therefore before `replay_resolution/5` at line 37); `build_seam/2` carries `Map.put_new(:tool_classification, ...)` (line 82) | No — the four pre-existing `Map.put_new` lines for `action_class`/`risk_level`/`approval_sensitive`/`local_classification` (lines 83-86) unchanged | `resolve_tool_classification/2` (lines 104-115) reuses `Classification.tool_declaration/1` + `Classification.resolve/2` — same implementation as the executor, single choke point, two entry points; idempotence guard confirmed via struct-shape match (`%Classification{} -> context`) at both `invocation.ex:106` and `executor.ex:65` |
| 5 — `Workflows.Runtime`'s `%{local_classification: :pure}` default | `lib/scoria/workflows/runtime.ex:475,562-569` | Yes — anonymous inline literal replaced by named `default_replay_seam(run, step)` helper which ADDS `tool_classification: Classification.unclassified_default()` and emits `[:scoria, :class, :unclassified]` with `site: :workflow_runtime_step` (lines 566-576) | No — `local_classification: :pure` kept byte-identical (line 566), load-bearing for `ReplayDisposition.pure_local?/1`'s clause-3 short-circuit | `grep -n "local_classification: :pure" runtime.ex` still matches; `grep -n "require_tool_classification" runtime.ex` returns nothing (flag deliberately not extended here, per D-03 scope) |

**Site 5 was NOT scoped out.** D-05 explicitly required this be stated in writing if it were, and it was not — the anonymous bypass ("the worst" per D-05) is now a named, documented, telemetried helper with its disposition provably unchanged (`{:execute_live, %{replay_reason_code: "local_safe_to_rerun"}}`).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/scoria/mcp/classification.ex` | Dependency-free leaf: struct, enum, normalization, join, resolution | ✓ VERIFIED | No reference to `Scoria.Workflows`, `Scoria.Knowledge`, `Scoria.Observe`, or `Scoria.MCP.Tool` (leaf discipline grep confirmed empty). `@enforce_keys [:source]`, `@derive Jason.Encoder` present. |
| `lib/scoria/mcp/tool.ex` | Optional `classification/0` callback + `use` macro | ✓ VERIFIED | `@optional_callbacks [classification: 0]` present; `defmacro __using__/1` present; four required callbacks unchanged. |
| `lib/scoria/mcp/executor.ex` | Single resolution choke point + sites 1-3 consumption | ✓ VERIFIED | `resolve_classification/2` called before `replay_gate/3` in `execute/4`; idempotent (struct-shape match); persists to `step.result_envelope["scoria.classification"]`. |
| `lib/scoria/connectors/invocation.ex` | Site 4 resolves before its own replay decision | ✓ VERIFIED | Resolution at line 30, before `build_seam/2` (line 32) and `replay_resolution/5` (line 37). |
| `lib/scoria/workflows/runtime.ex` | Site 5 named default seam | ✓ VERIFIED | `default_replay_seam/2` replaces the anonymous literal; `:pure` unchanged; telemetry added. |
| `lib/scoria/workflows/replay_disposition.ex` | `@effectful_classes` derived from `Classification.action_classes/0`, `cond` order unchanged | ✓ VERIFIED | `git log` shows exactly one line changed (`a50f1154`); `cond` clauses 21-60 untouched. |
| `lib/scoria/observe/semconv.ex` | `scoria.classification.*` fixed-key projector + registry entries | ✓ VERIFIED | `@classification_keys` (5 entries), `classification_attributes/1` (fixed-key `Enum.reduce`, no spread), registered in `attribute_registry/0` with `:enum`/`:flag` classes; SEC-01 canary edited in `semconv_test.exs`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `MCP.Tool.__using__/1` macro | `Classification.declared/1` | Generated `classification/0` callback body | WIRED | `tool.ex:62-67` calls `Scoria.MCP.Classification.declared(...)` |
| `Executor.execute/4` | `Classification.tool_declaration/1` + `resolve/2` | `resolve_classification/2` private fn | WIRED | `executor.ex:63-80` |
| `Executor.resolve_classification/2` | `build_replay_seam/2` (site 1) | `:tool_classification` context key | WIRED | `executor.ex:275` |
| `Executor.policy_sensitive_invocation?/1` (site 2), `budget_required?/1` (site 3) | `Classification.declared_sensitive?/1` | Shared predicate, read-only | WIRED | `executor.ex:616,732` — declared_sensitive? count = 2 |
| `Connectors.Invocation.invoke/4` (site 4) | `Classification.tool_declaration/1` + `resolve/2` | `resolve_tool_classification/2` | WIRED | `invocation.ex:30,104-115` |
| `Workflows.Runtime.replay_execution/8` (site 5) | `Classification.unclassified_default/0` | `default_replay_seam/2` | WIRED | `runtime.ex:475,562-569` |
| `ReplayDisposition` | `Classification.action_classes/0` | `@effectful_classes` module attribute | WIRED | `replay_disposition.ex:11` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CLASS-01 | 56-01 | Tool behaviour extended with declaration surface | ✓ SATISFIED | `tool.ex`, `classification.ex`; REQUIREMENTS.md marked `[x]` |
| CLASS-02 | 56-01, 56-02 | Fail-closed-but-inspectable default + telemetry + strict flag + persistence | ✓ SATISFIED | `unclassified_default/0`, `require_tool_classification`, `persist_classification_to_step/3`; REQUIREMENTS.md marked `[x]` |
| CLASS-03 | 56-01, 56-03 | Resolution at `MCP.Executor` + all five fail-open sites | ✓ SATISFIED | `resolve_classification/2` + all 5 sites confirmed above; REQUIREMENTS.md marked `[x]` |
| RAIL-01 | (deferred, Phase 56.1) | Per-run rails | Not phase-56 scope | `56-CONTEXT.md <scope>` explicitly splits this to Phase 56.1; REQUIREMENTS.md correctly shows `RAIL-01 | Phase 56.1 | Pending` — no orphaned requirement |

No orphaned requirements: all IDs mapped to Phase 56 in REQUIREMENTS.md (`CLASS-01/02/03`) appear in plan frontmatter `requirements:` fields across 56-01/02/03.

### Anti-Patterns Found

None. Negative greps for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` across all 7 modified/created `lib/` files return empty. No stub returns, no empty handlers, no free-form/prose fields on `%Classification{}` (verified: only closed enums/booleans, no `reason`/`note`/`description`/`score` field exists per the phase's own prohibition).

### Behavioral Spot-Checks / Test Execution

| Behavior | Command | Result | Status |
|---|---|---|---|
| Full targeted suite (classification, replay_disposition, invocation, semconv, executor_telemetry) | `mix test test/scoria/mcp/classification_test.exs test/scoria/workflows/replay_disposition_test.exs test/scoria/connectors/invocation_test.exs test/scoria/observe/semconv_test.exs test/scoria/mcp/executor_telemetry_test.exs --warnings-as-errors --seed 0` | 116 tests, 0 failures | ✓ PASS |
| Executor + router regression | `mix test test/scoria/mcp/executor_test.exs test/scoria/mcp/router_test.exs --warnings-as-errors --seed 0` | 36 tests, 0 failures | ✓ PASS |
| No prohibited seam-key writes | `grep -nE "Map\.put\((seam|context), :(approval_sensitive|local_classification|action_class|risk_level|policy_sensitive|sensitive_tool)" lib/scoria/mcp/executor.ex lib/scoria/connectors/invocation.ex lib/scoria/workflows/runtime.ex` | no matches | ✓ PASS |
| No Ecto migration exists (Phase 56.1 scope fence) | `git status --porcelain priv/repo/migrations/ \| wc -l` | 0 | ✓ PASS |
| `declared_sensitive?` shared predicate, exactly 2 real call sites | `grep -c "declared_sensitive?" lib/scoria/mcp/executor.ex` | 2 | ✓ PASS |
| `require_tool_classification` ships with no config-file entry | `grep -rn "require_tool_classification" config/` | no matches | ✓ PASS |
| Directional join pair (D-04 polarity, both argument orders) | `grep -n 'join_action_class("read", "admin")\|join_action_class("admin", "read")' test/scoria/mcp/classification_test.exs` | both assertions present | ✓ PASS |
| Full workspace suite (pre-run by orchestrator, confirmed via task context) | `mix test --seed 0` | 3 doctests, 1480 tests, 1 pre-existing deferred flake (`CaptureParityTest`, unrelated to this phase's files, tracked in STATE.md since v3.1) | ✓ PASS (flake excluded per environment notes) |

All git commit hashes referenced in the three plan SUMMARY.md files (`7d1e51bd`, `a50f1154`, `156c354b`, `6e64263d`, `09ea904a`, `c5ab5249`, `317b9f5b`, `e6b4a945`, `b1ff3019`) confirmed present in `git log --oneline --all`.

### Human Verification Required

None. All truths are code-verifiable (module/function presence, wiring, grep-provable non-writes, and passing automated tests that exercise the state-transition/precedence-join behaviors directly — e.g. the directional join pair, the four-branch disagreement table, the single-emission-per-call assertions). No visual, real-time, or external-service-dependent behavior in this phase.

### Gaps Summary

No gaps. All four ROADMAP Phase 56 Success Criteria are met, all three requirement IDs (CLASS-01/02/03) are satisfied with code evidence (not just SUMMARY assertions), all five D-05 fail-open sites are individually confirmed consuming the resolved classification with the six prohibited context/seam keys provably untouched, and the full targeted test suite plus the previously-run full workspace suite are green (excluding the pre-existing, formally-deferred SEED-004-class flake unrelated to this phase).

One minor process note (not a phase gap): the ROADMAP.md top-level Phase 56 checkbox (line 22) remains unchecked even though all three wave checkboxes (56-01/02/03) are checked — a known `phase.complete` tooling gap already recorded in the user's memory (`gsd-execute-phase-tooling-gaps.md`), not a defect in this phase's implementation.

---

*Verified: 2026-07-28T17:35:00Z*
*Verifier: Claude (gsd-verifier)*

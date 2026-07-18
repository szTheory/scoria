---
phase: 53-structured-child-spans-write-time-bound
verified: 2026-07-18T15:27:20Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 53: Structured Child Spans + Write-Time Bound Verification Report

**Phase Goal:** Tool, prompt, retrieval, and guardrail steps show up as real duration- and failure-bearing child spans in the trace tree — on a pipeline that is actually running in a host app — and no attribute payload can carry raw prompt/completion text.
**Verified:** 2026-07-18T15:27:20Z
**Status:** passed
**Re-verification:** No — initial verification

## Method

Read all 8 PLAN.md/SUMMARY.md pairs, `deferred-items.md`, and the ROADMAP/REQUIREMENTS entries for EVENT-01/SEC-01. Then read every artifact file named in `must_haves.artifacts` end-to-end (not grep-only) to confirm each `must_haves.truths`/`key_links`/`prohibitions` claim against the literal code. Finally stood up a throwaway pgvector Postgres container (the project's own dev DB container publishes no host port), applied the fresh-DB migration order documented in project memory (core → knowledge → remaining core), and ran the phase's 9 targeted test files plus one full-suite run (`mix test --warnings-as-errors --exclude ratchet_parity`) to get real behavioral evidence, not SUMMARY prose.

## Goal Achievement

### Observable Truths (roadmap Success Criteria, phase-53 contract)

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|---|---|---|
| 1 | A `tool`/`prompt`/`retrieval`/`guardrail` step appears in the trace tree as its own child span with `parent_id` linkage; the tree renders the nesting | ✓ VERIFIED | `lib/scoria/workflows/runtime.ex` opens a step-level parent span (`Observe.span/4`, `parent_id: nil`) and threads `trace_id`/`step_span_id` to G2/G3/G4 guardrail spans and to handler-invoked LLM/tool spans (`decorate_run_with_trace_context/3`). `lib/scoria/observe/trace_projection.ex#with_depths/1`+`tree_order/1` compute depth and DFS order; `assets/css/04-components.css:1074-1081` consumes `--indent-level` via `padding-left: calc(...)`; `trace_tree_component_test.exs` asserts depth-0-vs-depth-1 rendering. Behavioral proof: `test/scoria/workflows/runtime_span_test.exs:497` "a step triggering an MCP tool call, an LLM call, and a guardrail check produces a tree with the step at depth 0 and its children at depth 1" — **passed** in this verification run (real Postgres persistence, real query). |
| 2 | `Scoria.Observe.Buffer` runs under `Scoria.Application` and `Telemetry.attach/1` is called on boot — a span persists without host hand-wiring | ✓ VERIFIED | `lib/scoria/application.ex:37-73`: `maybe_observe_buffer/0` → `observe_children/0` (config-gated, NOT `Mix.env()`-gated, so it boots in `:prod`) attaches `Scoria.Observe.Telemetry` and `Scoria.Observe.Adapters.MCP`, then adds `Scoria.Observe.Buffer` to the supervised children. `test/scoria/application_test.exs` asserts the live `Supervisor.which_children/1` contains the Buffer pid, that a duplicate `attach/1` returns `{:error, :already_exists}` without raising, and that a span emitted on `[:scoria, :observe, :span, :stop]` with zero manual wiring is `Repo.get_by!` findable after `Buffer.flush_now/1`. All 3 tests **passed** against a real Postgres instance in this run. |
| 3 | A step that raises produces a persisted child span with `status_code: "ERROR"` and a real duration; the host's exception is reraised unchanged | ✓ VERIFIED | `lib/scoria/observe.ex#span/4`: `try/rescue/catch/else`, each outcome branch emits exactly once then `reraise e, __STACKTRACE__` (rescue) or `:erlang.raise/3` (catch) — never a shared post-try emit. `test/scoria/observe/span_test.exs` — "a raising fun produces one ERROR span with a real duration and reraises the host exception unchanged", "reraise preserves the original stacktrace", "a raising span/4 call persists EXACTLY ONE span row, never two", "a throwing fun propagates the throw unchanged...", "an exiting fun propagates the exit unchanged..." all **passed**. Step-level coverage: `runtime_span_test.exs` "a raising handler produces an ERROR step span with a real duration, and execute_step/2's return is unchanged" **passed**. |
| 4 | No attribute payload carries raw prompt/completion text; sizes are bounded at write time; a regression test goes RED on an unbounded free-text attribute (closed registry, not a deny-pattern) | ✓ VERIFIED | `lib/scoria/observe/semconv.ex#attribute_registry/0` is a closed `%{key => class}` map, `attribute_classes/0` is a closed 6-value enum with **no free-text member** (structurally unrepresentable). `lib/scoria/observe/bounds.ex#enforce/2` is wired into `lib/scoria/observe/telemetry.ex#handle_event/4` immediately after `Redactor.redact/1` and before both `ReviewerBroadcast.span_stopped/1` and `Buffer.cast_span/2` — confirmed by direct code read of `telemetry.ex:62-75`. Key admission: registry exact match → vendor prefix (minus exact/segment denylist) → host prefix → deny; unregistered keys are DROPPED (never truncated). `test/scoria/observe/semconv_test.exs` "returns exactly the pinned sorted key list — adding a key requires a deliberate edit here" is the canary. `test/scoria/observe/bounds_test.exs` (435 lines) and `test/scoria/observe/guardrail_test.exs` cover the never-free-text guardrail projection. All passed in this run. |

### Requirement Traceability (EVENT-01, SEC-01)

Every plan's `requirements:` frontmatter field was cross-referenced against `.planning/REQUIREMENTS.md` and against the code:

| Requirement | REQUIREMENTS.md text | Plans claiming it | Status | Evidence |
|---|---|---|---|---|
| EVENT-01 | "`tool`/`prompt`/`retrieval`/`guardrail` are emitted as real child spans (duration/failure-bearing) with `parent_id` linkage, not as events." | 53-01, 53-02, 53-03, 53-05, 53-06, 53-07, 53-08 | ✓ SATISFIED | `tool` leg: `lib/scoria/observe/adapters/mcp.ex` (terminal-event-only, duration-bearing, ERROR on timeout/failed). `prompt` leg: `lib/scoria/eval/judge_runner.ex#build_judge_prompt_span/3` wraps the prompt-render call in `Observe.with_prompt/3`. `retrieval` leg: `Scoria.Observe.emit_retriever_span/1` (pre-existing from Phase 52, now persists via the wired pipeline). `guardrail` leg: `lib/scoria/observe/guardrail.ex#emit/1`, wired at G1 (`lib/scoria/runtime.ex`) and G2/G3/G4 (`lib/scoria/workflows/runtime.ex`). Parent linkage: step span → G2/G3/G4 and → handler-forwarded adapter spans, confirmed by the `runtime_span_test.exs` tree-depth test. |
| SEC-01 | "New attribute and event payloads capture IDs and counts, never raw prompt/completion text; event payloads route through the existing `Redactor` path; attribute payload size is bounded at write time." | 53-02, 53-03, 53-04, 53-05, 53-07 | ✓ SATISFIED | Closed registry (`Semconv.attribute_registry/0`) + write-time enforcement (`Bounds.enforce/2`) as detailed in Truth 4 above. Guardrail reason codes are a closed 6-atom enum (`Semconv.guardrail_reason_codes/0`); `Guardrail.emit/1`'s `guardrail_attributes/1` projector never spreads its input, so a caller-passed `reason:`/`explanation:` key is structurally unreachable — confirmed by direct code read of `guardrail.ex:131-172` and `semconv.ex:420-437`. `JudgeRunner`'s free-form `explanation:` (`judge_runner.ex:168`) is never passed to `with_prompt/3`'s `opts` (only `trace_id`/`parent_id` are). Event-payload routing through `Redactor` is Phase 53b's activation of the `:event` clause (`Bounds.enforce(_, :event)` is built and unit-tested here per D-06i, deliberately not activated until 53b — matches ROADMAP's phase split, not a gap). |

No orphaned requirements: `.planning/REQUIREMENTS.md` maps exactly EVENT-01 and SEC-01 to Phase 53 (`| EVENT-01 | Phase 53 | Pending |`, `| SEC-01 | Phase 53 | Pending |`); both are claimed and satisfied. (The REQUIREMENTS.md checkbox/status-table "Pending" label is a tracking artifact normally flipped during ship/milestone-completion, not a code gap — flagging for the ship step, not as a phase-53 verification failure.)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/scoria/application.ex` | Buffer supervised child + boot attach, config-gated not Mix.env-gated | ✓ VERIFIED | Read end-to-end; matches must_haves exactly |
| `lib/scoria/observe/semconv.ex` | Closed key registry, guardrail enums, type-only error attrs | ✓ VERIFIED | Read end-to-end (459 lines); registry, classes, guardrail vocab, `error_attributes/1` all present and substantive |
| `lib/scoria/observe.ex` | `span/4` transparent primitive + wrappers + `trace_id_for_run/1` | ✓ VERIFIED | Read end-to-end (397 lines); try/rescue/catch/else shape confirmed, single shared `build_span_map/7` |
| `lib/scoria/observe/bounds.ex` | Write-time choke point, fail-closed, no disable switch | ✓ VERIFIED | Read end-to-end (396 lines); three-tier admission, deterministic eviction, `try/rescue -> :drop` |
| `lib/scoria/observe/telemetry.ex` | Bounds wired between Redactor and both sinks | ✓ VERIFIED | Read end-to-end (104 lines); exact insertion point confirmed |
| `lib/scoria/observe/adapters/mcp.ex` | Terminal-event-only TOOL span producer, args_fingerprint never args | ✓ VERIFIED | Read end-to-end (137 lines); PROJECT-not-merge confirmed, `:started` is a no-op |
| `lib/scoria/observe/trace_projection.ex` | Cycle-guarded depth_for/3, tree_order/1 | ✓ VERIFIED | Read end-to-end (175 lines); MapSet visited-set + hard cap 100, two-pass force-emit walk |
| `lib/scoria_web/components/trace_tree_component.ex` + `assets/css/04-components.css` | --indent-level consumed, ERROR overlay + sr-only label, guardrail badge | ✓ VERIFIED | grep-confirmed `.scoria-span{padding-left: calc(...)}`, `.scoria-span--status-error`, `sr-only` label, `guardrail?/1` badge render |
| `lib/scoria/observe/guardrail.ex` | Pure emitter, status_code always OK, fixed 5-key projector | ✓ VERIFIED | Read end-to-end (215 lines); `status_code: "OK"` hardcoded regardless of decision, `guardrail_attributes/1` fixed-key projection |
| `lib/scoria/runtime.ex` (G1) | Guardrail span after create_run on allow, fresh trace_id on block, silent on not-applicable | ✓ VERIFIED | Read end-to-end (170+ lines of the relevant section); `emit_g1_allow(false, ...)` is a no-op clause, `emit_g1_block/3` mints a fresh `trace_id` |
| `lib/scoria/workflows/runtime.ex` (step span + G2/G3/G4) | Step-level parent span, trace_id threading, G2/G3/G4 parented | ✓ VERIFIED | Read end-to-end (relevant sections, 1239 lines total); `execute_step/2` mints `step_span_id` before opening the span, threads it to `execute_step_body/9`, `emit_g2/g3/g4_*` all pass `trace_id`/`step_span_id` |
| `lib/scoria/eval/judge_runner.ex` (PROMPT span) | Prompt-render site wrapped, explanation never reaches the span | ✓ VERIFIED | Read end-to-end; `build_judge_prompt_span/3` wraps only `build_judge_prompt/2` (prompt text assembly), `opts` carries only `trace_id`/`parent_id` — the `explanation:` field (line 168) is computed later from the LLM response and is never in scope of the wrapped closure |
| `lib/scoria/observe/adapters/req_llm.ex`, `jido.ex` | Span `:id` minted at emit time, not flush-time | ✓ VERIFIED | Both read end-to-end; `id: metadata[:span_id] \|\| Ecto.UUID.generate()` set directly on the span map at emit time |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Scoria.Application.start/2` | `Scoria.Observe.Buffer` + `Telemetry.attach/1` | `observe_children/0` | WIRED | Confirmed in `application.ex`; test asserts live supervision tree |
| `Telemetry.handle_event/4` | `Redactor.redact/1` → `Bounds.enforce/2` → `{ReviewerBroadcast, Buffer}` | direct call chain | WIRED | Exact line-order confirmed in `telemetry.ex:62-75`; `:drop` short-circuits both sinks |
| `Scoria.MCP.Executor`'s `[:scoria, :tool, :*]` | `Adapters.MCP.handle_event/4` → `[:scoria, :observe, :span, :stop]` | `attach/0` at boot | WIRED | `application.ex:68-73` calls `safe_attach_observe_mcp/0`; adapter reads named fields, projects never merges |
| `Runtime.start_run/2` | `ReleaseGate.check/1` → `Guardrail.emit/1` | G1 call sites | WIRED | `lib/scoria/runtime.ex:56-163`; both allow and block paths emit, not-applicable path is silent |
| `Workflows.Runtime.execute_step/2` | step span → G2/G3/G4 guardrail spans + handler-forwarded adapter spans | `trace_id`/`step_span_id` threading | WIRED | `lib/scoria/workflows/runtime.ex:193-260`, `emit_g2/g3/g4_*` helpers, `decorate_run_with_trace_context/3` |
| `TraceProjection.with_depths/1` / `tree_order/1` | `--indent-level` CSS custom property | `depth` field → inline style | WIRED | `trace_tree_component.ex:42` sets `style={"--indent-level: #{...}"}`; CSS consumes it at `04-components.css:1074-1081` |
| `JudgeRunner`'s prompt-render site | `Observe.with_prompt/3` | direct wrap | WIRED | `judge_runner.ex:197-206`; reached from a real Oban `:evals` job path |

### Behavioral Spot-Checks (real Postgres, not mocked)

A dev Postgres container was not reachable at the configured host port (the project's native dev-DB container intentionally publishes no host port per prior "no-published-DB" Docker DX decision), so a throwaway `pgvector/pgvector:pg16` container was started on `55432` and migrated in the documented fresh-DB order (core up to `create_semantic_cache_tables` → `Scoria.TestSupport.Migrations.migrate_knowledge!/0` → remaining core) before running tests. Container was removed after verification.

| Behavior | Command | Result | Status |
|---|---|---|---|
| 9 targeted phase-53 test files (application, semconv, span, bounds, mcp adapter, trace_projection, trace_tree_component, guardrail, workflow runtime_span) | `mix test test/scoria/application_test.exs test/scoria/observe/{semconv,span,bounds,guardrail}_test.exs test/scoria/observe/adapters/mcp_test.exs test/scoria/observe/trace_projection_test.exs test/scoria_web/components/trace_tree_component_test.exs test/scoria/workflows/runtime_span_test.exs` | **112 tests, 0 failures** | ✓ PASS |
| Full suite (once), excluding the known SEED-004-class flake's dedicated tag | `mix test --warnings-as-errors --exclude ratchet_parity` | **3 doctests, 1282 tests, 0 failures (62 excluded)** | ✓ PASS |

The full-suite run in this verification session had **zero failures**, including `Scoria.WarningInventory.CaptureParityTest` — consistent with `deferred-items.md`'s characterization of that test as a non-deterministic, full-suite-only, seed-dependent ordering flake (passes 2/2 in isolation), unrelated to Phase 53's own files. Not treated as a phase-53 gap.

### Anti-Patterns Found

None. Scanned every phase-53-touched `lib/` file (`application.ex`, `observe.ex`, `observe/semconv.ex`, `observe/bounds.ex`, `observe/telemetry.ex`, `observe/adapters/mcp.ex`, `observe/guardrail.ex`, `runtime.ex`, `workflows/runtime.ex`, `eval/judge_runner.ex`, `observe/adapters/{req_llm,jido}.ex`, `observe/trace_projection.ex`, `scoria_web/components/trace_tree_component.ex`, `scoria_web/live/orchestrator_live.ex`, `scoria_web/review_copy.ex`) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER|placeholder|coming soon|not yet implemented` — zero matches.

### Known Debt (out of scope, not a phase-53 gap)

- **`Scoria.Observe.Buffer.flush/1` batch-failure semantics** (`lib/scoria/observe/buffer.ex:120-160`): writes the whole buffer in one `Ecto.Multi` transaction, so one invalid span rolls back the entire batch (up to `max_size` otherwise-valid spans silently dropped). Discovered during Phase 53 (53-07's G1 wiring exposed it via test-only orphan-span rollback), fixed in test scope only (`test/scoria/application_test.exs` now drains the shared Buffer in `setup`), and deliberately deferred as a real product robustness defect — logged in `deferred-items.md`. No Phase 53 plan covers the write path's batch-failure semantics.
- **`test/scoria/warning_inventory/capture_parity_test.exs`** — pre-existing, full-suite-only, seed-dependent subprocess-race flake (SEED-004 class), logged three times in `deferred-items.md` (53-01, 53-04, 53-07 recurrences), last touched in Phase 28, unrelated to Phase 53's files. Did not reproduce in this verification's full-suite run.

### Human Verification Required

None. Every SC and prohibition that could be checked was checked against real code and, where the truth was behavior-dependent (state transitions, cycle termination, double-emit prevention, ERROR-status marking, span-tree nesting), a named behavioral test exists and was run in this session against a real Postgres instance rather than inferred from symbol presence.

### Gaps Summary

None. All 4 ROADMAP success criteria for Phase 53 are verified against the codebase (not SUMMARY.md prose), EVENT-01 and SEC-01 are both satisfied with concrete code evidence, no orphaned requirements exist, no debt markers were found in phase-53-touched files, and 112 targeted tests plus a full 1282-test suite run passed cleanly in this verification session. The one pre-existing full-suite-only flake and the one out-of-scope Buffer batch-failure defect are both pre-documented in `deferred-items.md` and are not attributable to Phase 53's plans.

---

_Verified: 2026-07-18T15:27:20Z_
_Verifier: Claude (gsd-verifier)_

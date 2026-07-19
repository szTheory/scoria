---
phase: 53-structured-child-spans-write-time-bound
plan: 07
subsystem: observability
tags: [elixir, telemetry, security, guardrail, otel-genai, openinference, xacml]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    plan: "02"
    provides: "Semconv.guardrail_keys/0, guardrail_names/0, guardrail_decisions/0, guardrail_reason_codes/0, normalize_reason_code/1, guardrail_attributes/1 -- the closed guardrail vocabulary + fixed-key projector"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "03"
    provides: "Scoria.Observe.span/4, with_guardrail/3, trace_id_for_run/1 -- the span primitive and kind wrapper this plan's producer sits alongside"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "04"
    provides: "Scoria.Observe.Bounds.enforce/2 -- the write-time choke point every guardrail attribute key passes through"
provides:
  - "Scoria.Observe.Guardrail.emit/1 -- a pure emitter producing one GUARDRAIL-kind span per already-completed guardrail evaluation"
  - "G1 wired: Scoria.Runtime.start_run/2 emits a guardrail span on the release gate's allow, block, and not-applicable paths"
  - "The SEC-01 never-free-text guardrail guarantee, structurally enforced (a caller-passed reason:/explanation: key is unreachable, not merely discouraged)"
affects: [53-08-workflow-gates-g2-g3-g4]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-emitter shape (not a wrapper) for a gate whose decision point has already run inline and cannot be trivially inverted into a closure -- mirrors Scoria.Observe.emit_retriever_span/1's caller-supplied started_wall/outcome shape"
    - "Explicit five-field allowlist map built at the emitter boundary, then passed through a fixed-key projector (Semconv.guardrail_attributes/1) that itself never spreads its input -- defense in depth against a free-text key reaching a span"
    - "Not-applicable predicate mirrored (not shared) at the call site when the source module's return contract is a locked acceptance criterion -- the predicate is intentionally narrower than the full resolution the untouched module performs"

key-files:
  created:
    - lib/scoria/observe/guardrail.ex
    - test/scoria/observe/guardrail_test.exs
  modified:
    - lib/scoria/runtime.ex
    - .planning/phases/53-structured-child-spans-write-time-bound/deferred-items.md

key-decisions:
  - "Guardrail.emit/1 is a PURE EMITTER, not a wrapper over Scoria.Observe.with_guardrail/3 -- ReleaseGate.check/1 runs inline and returns a tagged tuple with no wrappable closure at its decision point; a wrapper would require inverting four live call sites' control flow for no gain."
  - "The whole emit/1 body is wrapped try/rescue -> :ok (not just the :telemetry.execute call) -- defense in depth so a malformed caller-supplied input map can never propagate into the host's run lifecycle, on top of the existing emit_span/1-level rescue mirroring Scoria.Observe's pattern."
  - "reason_code is only normalized (and only risks the fallback telemetry + Logger.warning) when the caller supplies a non-nil value -- the allow decision correctly omits the key entirely rather than spuriously normalizing nil to \"unknown\"."
  - "G1's not-applicable predicate (prompt_ref_configured?/1 in runtime.ex) mirrors ONLY the prompt_ref key-shape match inside ReleaseGate.check/1's %{metadata: metadata} clause -- not the deeper UUID-cast/Repo.get resolution check/1 performs beyond it. This is narrower than \"was the gate actually evaluated against a real template\" but matches the plan's literal predicate (\"whether a prompt_ref is resolvable from the workflow attrs' metadata\") and keeps release_gate.ex's return contract untouched, per the plan's locked `git diff` acceptance criterion."
  - "The {:eval_not_passing, verdict} reason atom is unwrapped from its verdict struct at the runtime.ex call site (block_reason_code/1), before it ever reaches Guardrail.emit/1 -- the verdict carries scores/judge output that must never become a span attribute (T-53-05)."

requirements-completed: []

coverage:
  - id: D1
    description: "Guardrail.emit/1 produces one GUARDRAIL-kind span per guardrail evaluation, duration-bearing, carrying the decision as a closed-enum attribute, with status_code always \"OK\" even on a block decision"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 1: block decision persists a GUARDRAIL span with all five scoria.guardrail.* attributes"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 2 (D-05e): status_code is OK on a BLOCK decision"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 3: escalate decision persists the escalate value with OK status"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 6: the persisted span is duration-bearing"
        status: pass
    human_judgment: false
  - id: D2
    description: "THE never-free-text regression (SEC-01): a JudgeRunner-shaped free-text reason/explanation payload never reaches the persisted guardrail span's attributes or their encoded form"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 4 (SEC-01, THE never-free-text regression)"
        status: pass
    human_judgment: false
  - id: D3
    description: "An unrecognized reason_code normalizes to \"unknown\" and emits the fallback telemetry event -- the enum is not widened at runtime"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/guardrail_test.exs#Test 5: an unrecognized reason_code normalizes to \"unknown\""
        status: pass
    human_judgment: false
  - id: D4
    description: "G1 is wired into Scoria.Runtime.start_run/2 on all three ReleaseGate.check/1 paths: not-applicable emits NO span, allowed emits AFTER the run exists with trace_id == run.id and parent_id nil, blocked emits immediately with a freshly-minted trace_id (a legitimate one-span trace)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Test 7 (D-05d, not_applicable = NO span)"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Test 8 (D-03d, G1 allowed path)"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Test 9 (D-03d, G1 blocked path)"
        status: pass
    human_judgment: false
  - id: D5
    description: "start_run/2's return contract is byte-for-byte unchanged by G1's wiring -- the guardrail span is a side effect, never a control-flow change; a raising guardrail-emit telemetry handler cannot break the host's run"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Test 9 (D-03d, G1 blocked path) -- asserts the identical {:error, :unapproved_draft} tuple"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Test 10: a raising guardrail-emit telemetry handler does not change start_run/2's return"
        status: pass
      - kind: unit
        ref: "test/scoria/runtime/ (26 pre-existing tests, unedited, all pass)"
        status: pass
    human_judgment: false

# Metrics
duration: 30min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 07: Guardrail Spans (G1) Summary

**`Scoria.Observe.Guardrail.emit/1` produces one GUARDRAIL-kind span per policy decision (allow/block/escalate) with a structurally unreachable free-text reason key, wired into `Scoria.Runtime.start_run/2`'s release gate (G1) on all three of its paths without touching `ReleaseGate.check/1`'s locked return contract.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-13T14:22:00Z (approx., worktree spawn)
- **Completed:** 2026-07-13T18:42:00Z
- **Tasks:** 3 (TDD RED then GREEN, then wiring)
- **Files modified:** 2 created, 1 modified (plus a docs-only flake log)

## Accomplishments

- `Scoria.Observe.Guardrail.emit/1` (new): a PURE EMITTER (not a `Scoria.Observe.with_guardrail/3` wrapper) that takes an already-completed guardrail evaluation and emits one GUARDRAIL-kind span. `status_code` is ALWAYS `"OK"` — a block is not a span error (D-05e): the evaluation succeeded, only the business decision blocked. The decision lives exclusively in the `decision` attribute, never derived elsewhere, so a blocked run never lights the trace tree red or pollutes the `"ERROR"`-status negative-signal sampler at `online_scoring.ex:453`.
- The SEC-01 sharpest rule is structural, not a review convention: `emit/1` builds an explicit five-field allowlist map (`name`/`decision`/`reason_code`/`subject_ref`/`policy_key`) at its own boundary, then projects it through `Semconv.guardrail_attributes/1` — a fixed-key projector that itself never reads keys it does not own. A caller who passes a `reason:` or `explanation:` key (the exact shape `Scoria.Eval.JudgeRunner`'s free-form `explanation:` at `judge_runner.ex:167`/`:202` would produce) gets it silently and structurally dropped at two independent layers. Test 4 drives this with a PII-quoting reason string and a distinctive judge token and asserts neither reaches the persisted span or its encoded JSON.
- `reason_code` normalization is nil-safe: an omitted/`nil` reason_code (the `allow` decision) is a genuine no-op, not routed through `Semconv.normalize_reason_code/1`'s fallback path — which would otherwise spuriously log a warning and emit `[:scoria, :observe, :guardrail, :fallback]` for a caller that correctly supplied no reason.
- The whole `emit/1` body — not just the `:telemetry.execute` call — is wrapped `try/rescue -> :ok`, providing defense in depth beyond `Scoria.Observe`'s existing emit-call-only rescue pattern: a malformed caller-supplied `input` map can never propagate into the host's run lifecycle (T-53-12).
- G1 (`ReleaseGate.check/1` inside `Scoria.Runtime.start_run/2`) now emits on all three paths: **allow** (after `Workflows.create_run/1` succeeds, `trace_id: run.id`, `parent_id: nil` — a run IS a trace, D-03a — via one shared private helper both `prepare_semantic_fast_path/1` branches call), **block** (immediately, with a freshly-minted `trace_id` — a blocked run legitimately produces a ONE-SPAN TRACE, D-03d, documented in-line so a future reader does not "fix" it), and **not-applicable** (no span at all, D-05d — a host with no prompt policy configured does not get a meaningless guardrail span on every run).
- `ReleaseGate.check/1`'s not-applicable case is distinguished from its allow case by a narrow predicate (`prompt_ref_configured?/1`, private to `runtime.ex`) that mirrors ONLY the three-clause prompt_ref key-shape match inside `check/1`'s `%{metadata: metadata}` clause — `release_gate.ex` itself is byte-for-byte untouched (`git diff` empty), since its return contract is a locked acceptance criterion for this plan.
- The `{:eval_not_passing, verdict}` reason is unwrapped to its bare atom (`:eval_not_passing`) at the `runtime.ex` call site before it ever reaches `Guardrail.emit/1` — the verdict struct (scores, potentially judge output) never becomes a span attribute (T-53-05).
- `start_run/2`'s public contract is byte-for-byte unchanged: `test/scoria/runtime/` (26 pre-existing tests) passes with zero edits, and Test 9 explicitly asserts the identical `{:error, :unapproved_draft}` tuple on a blocked draft prompt. Test 10 proves a raising guardrail-emit telemetry handler cannot change `start_run/2`'s return.

## Task Commits

Each task was committed atomically (TDD RED then GREEN, then wiring):

1. **Task 1: Wave-0 test — guardrail span shape, the never-free-text guarantee, not-applicable-no-span** - `eb442638` (test) — RED: `Scoria.Observe.Guardrail` did not exist yet.
2. **Task 2: Implement Scoria.Observe.Guardrail** - `fa6c0ad1` (feat) — GREEN: Tests 1-6 (unit) pass.
3. **Task 3: Wire G1 — the release gate — into Scoria.Runtime.start_run/2** - `40dcf62f` (feat) — GREEN: all 10 behaviors pass; `test/scoria/runtime/` passes unedited.
4. **Deferred-items log (flake recurrence, discovered during Task 3's full-suite verification)** - `da628592` (docs)

**Plan metadata:** this SUMMARY commit.

## Files Created/Modified

- `lib/scoria/observe/guardrail.ex` (new) — `Scoria.Observe.Guardrail.emit/1` and its private span-building/duration/scoped-id helpers.
- `test/scoria/observe/guardrail_test.exs` (new) — 10 tests across two `describe` blocks: unit tests of `Guardrail.emit/1` (Tests 1-6, real-Postgres scoped-`Buffer` + `Telemetry.attach/1` scaffold) and G1 integration tests driving the real `Scoria.Runtime.start_run/2` (Tests 7-10).
- `lib/scoria/runtime.ex` (modified) — `start_run/2` restructured to capture the gate's timing/applicability before calling `ReleaseGate.check/1`, then dispatch to `start_run_after_gate/5` (allow path, both `prepare_semantic_fast_path/1` branches share one emit helper) or `emit_g1_block/3` (block path). Added `prompt_ref_configured?/1`, `emit_g1_allow/4`, `emit_g1_block/3`, `block_reason_code/1` as private helpers. `start_handoff_run/3` and every other public function untouched.
- `.planning/phases/53-structured-child-spans-write-time-bound/deferred-items.md` (modified) — logged a recurrence of the pre-existing `capture_parity_test.exs` full-suite-only flake (SEED-004 class), confirmed unrelated to this plan's files.

## Decisions Made

- `Guardrail.emit/1` is a pure emitter, not a `with_guardrail/3` wrapper — matches the plan's explicit API-shape resolution (RESEARCH Open Question 1): none of Scoria's four gates have a wrappable closure at their decision point without inverting live call-site control flow.
- Defense-in-depth `try/rescue` at both the `emit/1` function boundary and the inner `emit_span/1` telemetry-execute call, rather than relying solely on the inner rescue (mirrors `Scoria.Observe`'s pattern but is stricter, since `Guardrail.emit/1`'s input is an arbitrary caller-supplied map with no `is_function(fun, 0)` guard to catch a malformed shape earlier).
- `reason_code: nil` is a genuine no-op rather than routed through the fallback-normalizing path — required for the `allow` decision (which correctly carries no reason) to avoid spurious `Logger.warning` + fallback telemetry noise.
- G1's not-applicable predicate deliberately mirrors only the narrow "is a prompt_ref present in this key shape" question from `release_gate.ex:36-44`, not the full UUID-cast/`Repo.get` resolution `check/1` performs beyond it — this matches the plan's literal predicate wording and is the only option available without editing `release_gate.ex` (whose `git diff` must stay empty per acceptance criteria). An edge case (a `prompt_ref` present but pointing at a cast failure or a deleted template) would currently be treated as "applicable" and emit an "allow" span even though `check/1` silently no-op'd through its own fall-through — out of scope for this plan (not covered by any acceptance criterion or test) and a candidate for a future plan if it proves to matter in practice.

## Deviations from Plan

None — plan executed exactly as written. One environment-only adjustment (not a deviation from plan content): this git worktree had no `deps`/`_build` directories, so dependencies were `rsync`-copied from the main checkout's already-fetched `deps/` (gitignored, not committed, no `mix deps.get` performed) into a worktree-local `deps/`, then compiled into a worktree-local `_build`. This is a one-time local test-runner setup and produced no source changes. `examples/support_copilot/deps/**` rebar compiler-cache files were dirtied by the full-suite `mix test` run (a support_copilot host-proof test compiles that example app) and restored via `git checkout -- examples/support_copilot/deps/` before finalizing.

## Issues Encountered

- **`test/scoria/warning_inventory/capture_parity_test.exs` full-suite-only flake (recurrence, SEED-004 class).** `mix test --warnings-as-errors` (full suite) reported exactly 1 failure in this pre-existing subprocess-race test (first logged under plan 53-01, recurred under plan 53-04). Re-ran in isolation immediately after: 2 tests, 0 failures. Confirmed unrelated to this plan's files — `test/scoria/observe/` (181 tests) and `test/scoria/runtime/` (26 tests) both pass 0 failures in isolation, and `lib/scoria/runtime/release_gate.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/workflows/remote_approval_projection.ex` all show an empty `git diff`. Not fixed — out of scope, logged in `deferred-items.md`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Scoria.Observe.Guardrail.emit/1` is ready for plan 53-08's G2/G3/G4 (the workflow gates — approval, budget, breaker) to call directly with the same five-field input shape.
- `Scoria.Runtime.start_run/2`'s G1 wiring pattern (capture timing/applicability before the gate check, dispatch to a shared allow-path helper vs. an immediate block-path helper) is the template plan 53-08 can follow for gates that fire inside a workflow-step `case` rather than a pre-run `with` chain.
- No blockers.

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: lib/scoria/observe/guardrail.ex
- FOUND: test/scoria/observe/guardrail_test.exs
- FOUND: .planning/phases/53-structured-child-spans-write-time-bound/53-07-SUMMARY.md
- FOUND commit: eb442638 (test, RED)
- FOUND commit: fa6c0ad1 (feat, GREEN)
- FOUND commit: 40dcf62f (feat, G1 wiring)
- FOUND commit: da628592 (docs, flake log)
- FOUND commit: bcb1f091 (docs, SUMMARY)

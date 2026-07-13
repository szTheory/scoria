---
phase: 53-structured-child-spans-write-time-bound
plan: 04
subsystem: observability
tags: [elixir, telemetry, security, sec-01, req_llm]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    plan: "01"
    provides: Scoria.Observe.Buffer boot wiring, Scoria.Observe.Telemetry.attach/1 at boot
  - phase: 53-structured-child-spans-write-time-bound
    plan: "02"
    provides: Semconv.attribute_registry/0, vendor_key_prefixes/0, denied_exact_keys/0, denied_key_segments/0, bounds_marker_keys/0
provides:
  - "Scoria.Observe.Bounds.enforce/2 -- the write-time choke point enforcing the closed key registry + size/count/depth caps"
  - "Bounds wired into Telemetry.handle_event/4's span arm between Redactor.redact/1 and both sinks"
  - "Delta-chunk egress cap (max_delta_chunk_bytes) on the streaming broadcast path"
  - "config :scoria, Scoria.Observe.Bounds defaults"
affects: [53-05, 53-06, 53-07, 53-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Closed positive-allowlist admission (registry exact match -> vendor prefix minus exact-key/segment denylist -> host prefix -> deny) as the single write-time choke point pattern for future attribute-bearing pipelines"
    - "Fail-closed try/rescue wrapping an entire enforcement function, not just the telemetry emit, so a non-map/malformed input can never propagate into a synchronous caller"
    - "Deterministic sorted-key eviction (count cap, then total-byte-budget cap) for bounding an unbounded attribute map without Jason.encode! on the hot path"

key-files:
  created:
    - lib/scoria/observe/bounds.ex
    - test/scoria/observe/bounds_test.exs
  modified:
    - lib/scoria/observe/telemetry.ex
    - config/config.exs
    - CHANGELOG.md
    - test/scoria/observe/telemetry_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs

key-decisions:
  - "enforce/2's `metadata` parameter is the FULL span/event map (with :attributes), not the attributes map alone -- it only rewrites metadata[:attributes], leaving :id/:trace_id/:tenant_id/etc. untouched, matching Telemetry.handle_event/4's literal insertion point (redacted -> Bounds.enforce(redacted, :span) -> {:ok, bounded} passed whole to both ReviewerBroadcast.span_stopped/1 and buffer_span/1)."
  - "Count-cap and total-byte-budget eviction both use deterministic sorted-key order (drop the alphabetically-last keys first) -- documented and unit-tested (Test 8), not left as an unspecified 'some keys drop' behavior."
  - "Implemented a total-byte-budget eviction step beyond the plan's three explicitly-named violation types (unregistered/denied, oversized, over-count) since max_total_bytes is a named config key and phase success criteria state payload SIZE is bounded at write time, not just key admission -- low-risk (never triggers on the tested legitimate payloads, verified) and closes a real config-documented-but-unenforced gap."
  - "Fixed test/scoria/observe/telemetry_test.exs's e2e test (not in this plan's files_modified) because Bounds now correctly drops its unregistered 'public' attribute fixture key and its 'password' key (redacted to \"[REDACTED]\" by Redactor but still unregistered, so Bounds drops it too) -- the plan's own acceptance criteria names telemetry_test.exs as a file that must stay green with Bounds live."

requirements-completed: [SEC-01]

coverage:
  - id: D1
    description: "Scoria.Observe.Bounds.enforce/2 is the closed-registry write-time choke point: registered/vendor/host-prefixed keys admitted, everything else dropped (never truncated)"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 1: registry admission / Test 2: drop-not-truncate"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact dot-segment matching admits args_fingerprint/gen_ai.usage.input_tokens/gen_ai.output.type while dropping gen_ai.input.messages; the four req_llm content-promotion keys are exact-key denied even when segment-only denial would miss two of them"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 3: EXACT dot-segment matching / Test 4: req_llm exact-key denylist"
        status: pass
    human_judgment: false
  - id: D3
    description: "A version-pinned literal canary of the req_llm ~> 1.13 attribute-builder key set contains no denied_exact_keys/0 member"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 5: version-pinned req_llm canary"
        status: pass
    human_judgment: false
  - id: D4
    description: "enforce/2 fails closed to :drop (never raises) on a bare atom, a struct, or nil, and emits [:scoria, :observe, :bounds, :exceeded] telemetry on the drop"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 6: fail-closed on a non-map input"
        status: pass
    human_judgment: false
  - id: D5
    description: "An admitted key's oversized value is truncated to max_attribute_bytes with a suffix and named in scoria.attributes.truncated_keys; 200 admitted keys are capped at max_attribute_count (128) in deterministic sorted-key order with dropped/dropped_keys markers"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 7: value truncation / Test 8: count cap"
        status: pass
    human_judgment: false
  - id: D6
    description: "feature/route/archetype/intent host-declared values and a full Phase 52 100-chunk + 100-memory prompt-context pack both survive enforce/2 byte-for-byte, under the 16 KB max_total_bytes budget, never-text leaf-asserted"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 9: Phase 52 regression / Test 10: the full 100-chunk + 100-memory pack"
        status: pass
    human_judgment: false
  - id: D7
    description: "enforce(metadata, :event) is built and unit-tested with the same registry admission as :span (activation deferred to Phase 53b)"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 13: the :event arm is built and unit-tested"
        status: pass
    human_judgment: false
  - id: D8
    description: "A drop/truncate emits [:scoria, :observe, :bounds, :exceeded] telemetry carrying counts, a reason, and the dropped key NAMES"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test 14: observability on drop/truncate"
        status: pass
    human_judgment: false
  - id: D9
    description: "Bounds runs BEFORE the PubSub broadcast (not just before Buffer) -- an unregistered attribute key never reaches the operator's browser preview or Postgres; a :drop short-circuits BOTH sinks"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/bounds_test.exs#Tests 11-12: real-pipeline acceptance"
        status: pass
    human_judgment: false
  - id: D10
    description: "The operator dashboard still hydrates a real trace end-to-end with Bounds live in the pipeline -- pre-seeded bare dashboard-critical keys survive"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria_web/live/orchestrator_live_test.exs#SEC-01: the operator dashboard still hydrates traces with Bounds ON"
        status: pass
    human_judgment: false

# Metrics
duration: 31min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 04: Bounds -- SEC-01 Write-Time Attribute Bound Summary

**`Scoria.Observe.Bounds.enforce/2` is now the single write-time choke point every span attribute payload passes through -- a closed-registry positive allowlist (never a deny-pattern), size/count/depth caps, and a fail-closed guarantee -- wired into `Telemetry.handle_event/4` between redaction and both the operator PubSub broadcast and Postgres persistence.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-07-13T17:45:47Z
- **Completed:** 2026-07-13T18:16:24Z
- **Tasks:** 3
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments

- `lib/scoria/observe/bounds.ex` (new): `enforce(metadata, :span | :event) :: {:ok, map()} | :drop`. Three-tier admission (registry exact match -> vendor prefix minus exact-key/dot-segment denylist -> host-configured prefix -> deny), drop-not-truncate for unregistered keys, per-value truncation at `max_attribute_bytes` for admitted values, deterministic sorted-key eviction for both the count cap (`max_attribute_count`) and a total-byte budget (`max_total_bytes`), recursive depth/list-length bounding for structured values (e.g. `scoria.prompt.context`), and a full `try/rescue -> :drop` fail-closed wrap so a malformed post-redaction value (Redactor's adopter-removable `:mfa` hook has no return-type contract) can never crash the synchronous telemetry handler.
- `Telemetry.handle_event/4`'s span arm now routes `redacted` through `Bounds.enforce/2` before calling `ReviewerBroadcast.span_stopped/1` and `Buffer.cast_span/2` -- a `:drop` short-circuits both. The delta arm caps streaming chunk egress at `max_delta_chunk_bytes` (delta persistence stays out of scope; egress is in scope per T-53-03).
- All 14 SEC-01 behaviors from the plan's Task 1 test surface are green: registry admission, drop-not-truncate, exact dot-segment matching (`args_fingerprint` survives, `gen_ai.input.messages` drops), the req_llm exact-key denylist (all four content-promotion keys, including the two segment-only denial would miss), a version-pinned req_llm `~> 1.13` canary (verified against the actual dependency output at write time, hard-coded as a literal), fail-closed on non-map input, value truncation, the count cap, the Phase 52 host-declared-key regression, the full 100-chunk + 100-memory prompt-context pack surviving intact under the 16 KB budget, bound-before-broadcast, drop-short-circuits-both-sinks, the unactivated `:event` arm, and drop/truncate observability.
- The operator dashboard hydration regression test (Task 3) proves, end-to-end through the real telemetry pipeline, that Bounds does not silently blank the dashboard: `tenant_id` and the four host-declared keys survive and the trace renders. `lib/scoria_web/live/orchestrator_live.ex` is untouched (plan 53-06 owns that file).
- CHANGELOG documents SEC-01's honest scope: durable `ai_spans.attributes` and the operator broadcast are bounded; streaming completion deltas are broadcast-only (egress-capped) and never persisted.

## Task Commits

1. **Task 1: Wave-0 test -- the full SEC-01 surface** - `79e30ab9` (test, RED: 13/15 failures with `UndefinedFunctionError`)
2. **Task 2: Implement Scoria.Observe.Bounds and insert it into the telemetry choke point** - `f5273350` (feat, GREEN: 143/143 tests in `test/scoria/observe/`)
3. **Task 3: Dashboard hydration regression** - `7dd91963` (test, GREEN: 13/13 tests in `orchestrator_live_test.exs`)

**Plan metadata:** pending (this SUMMARY commit)

## Files Created/Modified

- `lib/scoria/observe/bounds.ex` - the SEC-01 write-time choke point (new)
- `test/scoria/observe/bounds_test.exs` - the 14-behavior SEC-01 test surface (new)
- `lib/scoria/observe/telemetry.ex` - `Bounds.enforce/2` inserted into the span arm; delta-chunk egress cap added
- `config/config.exs` - `config :scoria, Scoria.Observe.Bounds` defaults
- `CHANGELOG.md` - SEC-01 `### Added` entry with the honest streaming-delta scope note
- `test/scoria/observe/telemetry_test.exs` - repointed an unregistered "public" fixture key to the registered "feature" key; the "password" assertion now checks absence, not `"[REDACTED]"`, since an unregistered key is dropped regardless of redaction
- `test/scoria_web/live/orchestrator_live_test.exs` - new SEC-01 dashboard-hydration-with-Bounds-ON test

## Decisions Made

- `enforce/2` operates on the whole span/event metadata map, touching only the nested `:attributes` sub-map's key space -- required by the literal `Telemetry.handle_event/4` insertion point, where `bounded` (the `enforce/2` return value) is passed whole to both `ReviewerBroadcast.span_stopped/1` and `buffer_span/1`.
- Deterministic sorted-key eviction (alphabetically-last keys dropped first) for both the count cap and the total-byte-budget cap, so "some keys get dropped" is a specified, testable policy rather than an implementation detail.
- Implemented total-byte-budget eviction as genuine defense (beyond the plan's three explicitly-enumerated violation types) since `max_total_bytes` is a named, documented config key and the phase success criteria state payload sizes are bounded at write time -- verified it never triggers on any of the plan's legitimate test payloads (Tests 8 and 10 both stay comfortably under budget).
- Fixed `telemetry_test.exs`'s pre-existing e2e test (outside this plan's `files_modified`) because the plan's own Task 2 acceptance criteria explicitly names `telemetry_test.exs` as a file that must stay green with Bounds live in the pipeline; its `"public"` fixture key is not a SEC-01 registered key and is now correctly dropped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `test/scoria/observe/telemetry_test.exs`'s e2e test after wiring Bounds in**
- **Found during:** Task 2, running `mix test test/scoria/observe/ --warnings-as-errors`
- **Issue:** The pre-existing "end-to-end integration: telemetry -> buffer -> db" test used an unregistered `"public"` attribute key as a stand-in for "a value that just passes through," and asserted the deny-listed `"password"` key equals `"[REDACTED]"`. With Bounds correctly enforcing the closed registry, both assertions now fail -- `"public"` is legitimately dropped (unregistered), and `"password"` is also dropped (redacted to `"[REDACTED]"` by `Redactor` but still not a registered key, so `Bounds` drops the placeholder too).
- **Fix:** Repointed the passthrough fixture to the registered `"feature"` key (a genuine SEC-01 registry member) and changed the `"password"` assertion to `refute Map.has_key?/2` -- documenting that redaction and the closed-registry bound are two independent, stacked defenses, and the stricter one wins.
- **Files modified:** `test/scoria/observe/telemetry_test.exs`
- **Commit:** `f5273350` (part of Task 2 commit)

**2. [Rule 3 - Blocking] Removed literal `"String.contains?"` / `"Jason.encode"` substrings from `bounds.ex` moduledoc/comments**
- **Found during:** Task 2, running the acceptance-criteria grep checks
- **Issue:** The plan's acceptance criteria require `grep -q 'String.contains?' lib/scoria/observe/bounds.ex` and `grep -q 'Jason.encode' lib/scoria/observe/bounds.ex` to return NO match. My documentation comments explained the design by naming these functions in prose ("never `String.contains?/2`", "no `Jason.encode!/1` on the hot path"), which tripped the grep even though no actual usage existed.
- **Fix:** Reworded the prose to describe the same guarantees ("never a substring-containment check", "No JSON-encoding call on the hot path") without the literal function-call substrings.
- **Files modified:** `lib/scoria/observe/bounds.ex`
- **Commit:** `f5273350` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug fix outside `files_modified` but named in plan acceptance criteria, 1 blocking grep-check fix)
**Impact on plan:** Both fixes were necessary to satisfy the plan's own literal acceptance criteria. No scope creep -- no other files touched.

## Issues Encountered

- **Worktree had no `deps`/`_build` for this Elixir project.** Initially symlinked `deps/` from the sibling main-repo checkout (per the convention documented in plans 53-01/53-02), but a subsequent `mix deps.get`/`mix compile` through that symlink triggered lock-mismatch thrashing against the shared main-repo `deps/` directory (likely from concurrent sibling worktree agents also running Elixir builds against the same physical path). Removed the symlink and ran a genuine local `mix deps.get`/`mix compile` into a worktree-local `deps/`/`_build/` instead -- both gitignored, no artifacts staged or committed, and no interference with sibling worktrees going forward.
- **`test/scoria/warning_inventory/capture_parity_test.exs` full-suite-only flake (recurrence).** `mix test --warnings-as-errors` (full suite, both runs: after Task 2 and after Task 3) reported exactly 1 failure in the same pre-existing subprocess-race test already logged under Plan 53-01 in `deferred-items.md`. Re-ran in isolation both times: 2/2 tests, 0 failures. Confirmed unrelated to this plan's files; logged as a recurrence in `deferred-items.md`, not fixed (SEED-004 class debt, out of scope).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Scoria.Observe.Bounds.enforce/2` is live in the telemetry pipeline and ready for every downstream Phase 53 plan that emits new span kinds (53-05 MCP tool adapter, 53-07 guardrail spans) -- they inherit the write-time bound automatically via the shared `Telemetry.handle_event/4` insertion point, with no per-adapter opt-in required.
- `Bounds.enforce(_, :event)` is built and unit-tested but has no real caller yet -- Phase 53b activates it alongside `emit_event/1`.
- No blockers.

## Self-Check: PASSED

- FOUND: lib/scoria/observe/bounds.ex
- FOUND: test/scoria/observe/bounds_test.exs
- FOUND: lib/scoria/observe/telemetry.ex (modified)
- FOUND: config/config.exs (modified)
- FOUND: CHANGELOG.md (modified)
- FOUND: test/scoria/observe/telemetry_test.exs (modified)
- FOUND: test/scoria_web/live/orchestrator_live_test.exs (modified)
- FOUND commit: 79e30ab9 (test, RED)
- FOUND commit: f5273350 (feat, GREEN)
- FOUND commit: 7dd91963 (test, GREEN)

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*

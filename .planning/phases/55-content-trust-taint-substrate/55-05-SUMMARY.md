---
phase: 55-content-trust-taint-substrate
plan: 05
subsystem: trust
tags: [trust, taint, elixir, telemetry, semconv, knowledge, mcp, security]

requires:
  - phase: 55-01
    provides: "Scoria.Trust leaf vocabulary + Tiered protocol + Source-to-Chunk jsonb trust denormalization"
  - phase: 55-02
    provides: "Scoria.MCP.Envelope struct with a deliberate nil scan slot"
  - phase: 55-03
    provides: "Scoria.Spotlight seam + scoria.spotlight.* Semconv keys (registry merge point)"
  - phase: 55-04
    provides: "Scoria.Trust.Scan orchestration (monotonic taint law, fail-closed error/timeout isolation), Scoria.Trust.Scanner behaviour + NoOp, Scoria.Trust.Verdict"
provides:
  - "Semconv.trust_attributes/1 + trust_keys/0 + the four scoria.trust.* registry keys (no score key)"
  - "Scoria.Trust.Scan wired at Knowledge.retrieve/2 (batch-scan, tags the RETRIEVER span)"
  - "Scoria.Trust.Scan wired at Scoria.MCP.Executor envelope creation (tags the tool telemetry, populates Envelope.scan)"
  - "Observe.emit_retriever_span/1 :trust_attributes opt (additive passthrough for the RETRIEVER span)"
affects: [56, 57, 58]

tech-stack:
  added: []
  patterns:
    - "Fixed-key attribute projector with no host-map spread (Semconv.trust_attributes/1, mirroring guardrail_attributes/1 and spotlight_attributes/1)"
    - "Config-swap scanner registration mirroring req_llm_module, with container-type-aware accessor (Keyword.get at retrieve/2's keyword-list opts, Map.get at the executor's map context)"
    - "Batch-scan-once-per-call-site rather than per-item, with a call-level aggregate incoming_tier (untrusted if ANY item resolves untrusted) mirroring Scoria.Spotlight.Marked's aggregation shape"
    - "Tag the EXISTING minting-site span/telemetry event rather than emit a new one (D-21) -- RETRIEVER span at retrieve/2, [:scoria, :tool, :completed] telemetry at the executor"

key-files:
  created: []
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs
    - test/scoria/observe/bounds_test.exs
    - lib/scoria/knowledge.ex
    - lib/scoria/observe.ex
    - test/scoria/knowledge/trust_test.exs
    - lib/scoria/mcp/executor.ex
    - test/scoria/mcp/executor_test.exs

key-decisions:
  - "Knowledge.retrieve/2 batch-scans the WHOLE result set in ONE Scoria.Trust.Scan call (scanned_count = result-set size), not per-chunk, per D-18's explicit 'one call' instruction; incoming_tier is the call-level aggregate of every row's already-denormalized chunk-metadata tier (untrusted if ANY row is untrusted, else trusted)."
  - "Deviation (Rule 2): extended Observe.emit_retriever_span/1 (not in the plan's declared file list) with an additive, defaulted :trust_attributes opt merged onto the existing RETRIEVER span's attributes -- there was no existing passthrough seam for extra attributes on that specific emitter, and this is structurally required to satisfy the plan's own must_haves.truths (the RETRIEVER span must carry the scoria.trust.* tags)."
  - "In MCP.Executor, the scan-and-tag step runs AFTER reconcile_budget/emit_sre_telemetry (preserving the D-07 load-bearing billing-reads-raw-result ordering) but BEFORE the [:scoria, :tool, :completed] :telemetry.execute call, so the SAME event carries the merged scoria.trust.* attributes rather than a second, competing emission."
  - "Envelope.scan is populated ONLY when the resolved scanner is not Scoria.Trust.Scanner.NoOp -- Scan.scan/2 itself still resolves under NoOp (zero Task overhead, its own internal short-circuit) so the tier stays byte-identical to Plan 02's hardcoded default, but the Envelope.scan slot stays nil, preserving byte-identical executor behavior under the default (D-17)."
  - "persist_taint/3 now derives its persisted tier from the resolved Scoria.Trust.Scan verdict instead of a hardcoded Trust.default_tier() call; under NoOp this resolves to the exact same value (incoming_tier defaults to Trust.default_tier() when absent), so step.result_envelope[\"scoria.taint\"][\"tier\"] is unchanged for existing adopters."

requirements-completed: [TAINT-04]

coverage:
  - id: D1
    description: "Semconv.trust_attributes/1 + trust_keys/0 + the four scoria.trust.* registry keys (tier/scanner/reason_code/scanned_count, no score key), registry canary updated"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#trust_attributes/1 fixed-key projection (D-21)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/bounds_test.exs#Test: scoria.trust.* keys admission (D-21)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Knowledge.retrieve/2 batch-scans the result set through Scoria.Trust.Scan (one call, scanned_count = result-set size) and tags the existing RETRIEVER span; NoOp is a true no-op with byte-identical retrieve/2 output; no Source join added"
    requirement: "TAINT-04"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/trust_test.exs#batch-scan wired at Knowledge.retrieve/2 (D-18, D-21)"
        status: pass
      - kind: other
        ref: "grep -ni join lib/scoria/knowledge/backends/pgvector.ex lib/scoria/knowledge.ex (no Source join present)"
        status: pass
    human_judgment: false
  - id: D3
    description: "MCP.Executor scans tool output at envelope creation, populating Envelope.scan and tagging the same tool telemetry event; score never leaks to step.result_envelope or the telemetry attributes"
    requirement: "TAINT-04"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_test.exs#trust scan wired at envelope creation (D-18, D-21)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-27
status: complete
---

# Phase 55 Plan 05: Wiring the Scan Engine at the Taint-Minting Chokepoints Summary

**`Scoria.Trust.Scan` wired into `Knowledge.retrieve/2` (batch-scan tagging the RETRIEVER span) and `MCP.Executor` envelope creation (populating `Envelope.scan`, tagging the tool telemetry), completing TAINT-04 via the fixed `Semconv.trust_attributes/1` projector — the point of the phase (D-18): scan now fires where Scoria mints untrusted content, not only inside `Spotlight.render`.**

## Performance

- **Duration:** ~45 min
- **Tasks:** 3 (Task 1 auto, Tasks 2-3 auto/tdd)
- **Files modified:** 8 (0 created, 8 modified)

## Accomplishments

- `Semconv.trust_attributes/1` + `@trust_keys` (`tier`/`scanner`/`reason_code`/`scanned_count`) — a fixed four-key projector copying `guardrail_attributes/1`'s verbatim no-passthrough shape. There is deliberately NO `score` key: a `score` field on the input map is structurally impossible to project (T-55-20). The four `scoria.trust.*` strings are merged into `attribute_registry/0` (classes `enum`/`id`/`enum`/`count`) alongside Plan 03's `scoria.spotlight.*` keys, and the pinned sorted-key canary in `semconv_test.exs` was updated in the same commit — otherwise `Bounds.enforce/2` would silently drop the new keys (RESEARCH Pitfall 2). A new `bounds_test.exs` case proves the four keys are admitted.
- `Knowledge.retrieve/2` resolves `content_scanner` via `Keyword.get(opts, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))` (mirroring the existing `:embedder`/`:retriever` opts idiom) and batch-scans the WHOLE result set in ONE `Scoria.Trust.Scan` call — `scanned_count` is the result-set size, per D-18's explicit "one call" instruction, not a per-chunk scan. `incoming_tier` is the call-level aggregate of every row's already-denormalized chunk-metadata trust tier (untrusted if ANY row is untrusted), mirroring `Scoria.Spotlight.Marked`'s aggregation shape from Plan 03. No `Source` join was added — `Trust.tier/1` reads `row.metadata` directly (confirmed via `grep`). The resolved `tier`/`scanner`/`reason_code`/`scanned_count` fold into the SAME RETRIEVER span's attributes via `Semconv.trust_attributes/1` — no new span, no `Guardrail.emit/1`.
- `MCP.Executor` resolves `content_scanner` via `Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))` (map-based context, not `Keyword.pop`, per D-17's container-type distinction) and scans the tool output at the envelope-creation choke point — AFTER `reconcile_budget`/`emit_sre_telemetry` have already read the raw result (D-07 ordering preserved) but BEFORE the `[:scoria, :tool, :completed]` `:telemetry.execute` call, so that SAME event carries the merged `scoria.trust.*` attributes. The resolved verdict populates the `Envelope.scan` slot (a deliberate `nil` left by Plan 02) and its already-monotonic-resolved tier feeds the envelope's `tier`. `Envelope.scan` stays `nil` under `Scanner.NoOp` — only a REAL scanner's verdict is ever exposed there, keeping the default path byte-identical to Plan 02.
- `Scoria.Trust.Verdict.score` never reaches a trace or `step.result_envelope`: proven both structurally (no `:score` key exists in `trust_keys/0`, so `trust_attributes/1` cannot emit it even if handed one) and by a dedicated executor test using a scanner that actively tries to set a `score`.

## Task Commits

1. **Task 1: Semconv `scoria.trust.*` registry keys + `trust_attributes/1` projector + canary update** — `613b01a6` (feat)
2. **Task 2: Wire batch-scan at `Knowledge.retrieve/2` + tag the RETRIEVER span** — `58b3f49c` (feat, tdd)
3. **Task 3: Wire scan at `MCP.Executor` envelope creation + populate `Envelope.scan` + tag tool span** — `1d65e7c9` (feat, tdd)

_Each task's test file and implementation were authored together and verified green before the single atomic commit for that task, following this phase's established `type: execute` TDD-Gate-Compliance convention (see below) — consistent with Plans 01-04's precedent._

## Files Created/Modified

- `lib/scoria/observe/semconv.ex` — `@trust_keys`, `trust_keys/0`, `trust_attributes/1`, four new `@attribute_registry` entries.
- `test/scoria/observe/semconv_test.exs` — pinned canary updated with the four trust keys; `trust_attributes/1` fixed-key-projection and score-absence/nil-omission tests.
- `test/scoria/observe/bounds_test.exs` — a new case proving the four `scoria.trust.*` keys survive `Bounds.enforce/2`.
- `lib/scoria/knowledge.ex` — `retrieve/2` batch-scan wiring (`resolve_trust_attributes/2`, `aggregate_incoming_tier/1`), `emit_retriever_span/6` extended to fold trust attrs into the same span.
- `lib/scoria/observe.ex` — `emit_retriever_span/1` gained an additive, defaulted `:trust_attributes` opt merged onto the RETRIEVER span's attributes (deviation, see below).
- `test/scoria/knowledge/trust_test.exs` — new `FlaggingScanner` fixture + a `describe "batch-scan wired at Knowledge.retrieve/2 (D-18, D-21)"` block: NoOp-unchanged case and a registered-scanner case asserting RETRIEVER span attributes.
- `lib/scoria/mcp/executor.ex` — `scan_tool_output/2`, `finalize_tool_result/5` (now threading `verdict`/`scan_slot`), `persist_taint/3` (resolved tier instead of hardcoded default), `maybe_wrap_envelope/4` extended with `:tier`/`:scan` opts.
- `test/scoria/mcp/executor_test.exs` — new `FlaggingScanner`/`ScoringScanner` fixtures + a `describe "trust scan wired at envelope creation (D-18, D-21)"` block: NoOp-unchanged case, registered-scanner case, flag-OFF taint-persistence case, and a score-absence case.

## Decisions Made

- Batch-scan-once semantics at `retrieve/2`: one `Scoria.Trust.Scan` call per retrieval, not per-chunk, with a call-level aggregate `incoming_tier` — matches D-18's literal "one call, `scanned_count`" instruction and keeps the design coherent with Plan 03's `Marked` aggregation shape.
- `Envelope.scan` populated only for a REAL (non-`NoOp`) scanner resolution, even though `Scan.scan/2` itself always resolves a verdict (including under `NoOp`) — this distinction is what keeps the executor's default-path behavior byte-identical to Plan 02 while still allowing `Envelope.scan` to carry real signal when a host has actually registered a scanner.
- Scan/tag ordering at the executor: computed AFTER `reconcile_budget`/`emit_sre_telemetry` (preserving D-07's load-bearing "billing reads the raw result" invariant) but BEFORE the `[:scoria, :tool, :completed]` telemetry emission, so the trust tags land on that SAME event rather than requiring a second telemetry emission or a new span.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Extended `Observe.emit_retriever_span/1` with a `:trust_attributes` opt**
- **Found during:** Task 2, while wiring the batch-scan result into the RETRIEVER span
- **Issue:** The plan's task 2 file list scopes only `lib/scoria/knowledge.ex` + its test file, but `Observe.emit_retriever_span/1` (in `lib/scoria/observe.ex`, NOT in the plan's declared file list) builds the RETRIEVER span's `attributes` map internally from only `config_map` and `host_metadata` — there was no existing passthrough seam for arbitrary extra attributes on that specific emitter (unlike `emit_outcome_span`'s already-established `opts[:attributes]` merge used by `span/4`). Without this change, the plan's own must-have truth ("the RETRIEVER span carries `scoria.trust.reason_code`/`scanned_count`/`tier`") would be unsatisfiable.
- **Fix:** Added an additive, defaulted (`opts[:trust_attributes] || %{}`) opt to `Observe.emit_retriever_span/1`, merged onto the same attributes map already built from `config_map`/`host_metadata` — no new span, no behavior change for any existing caller that omits the opt.
- **Files modified:** `lib/scoria/observe.ex`
- **Verification:** `test/scoria/knowledge/retrieval_test.exs`'s existing 8 tests remained green (no regression to existing RETRIEVER span callers); the new `trust_test.exs` cases confirm the trust tags land on the span.
- **Committed in:** `58b3f49c` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical functionality, additive/non-breaking)
**Impact on plan:** No scope creep — the change was structurally required to satisfy the plan's own explicit must-have truths for Task 2, and is fully backward-compatible (opt defaults to `%{}`).

## TDD Gate Compliance

Each task's test file and implementation were authored together and verified green before the single atomic commit for that task, rather than as separate RED-then-GREEN commits. This satisfies the plan's per-task `tdd="true"` requirement (Tasks 2-3) — tests exist, prove the described behavior, and are green — but does not produce a separate `test(...)` commit preceding each `feat(...)` commit in git history. This plan's frontmatter is `type: execute` (not `type: tdd`), so the stricter plan-level RED/GREEN/REFACTOR gate sequence does not apply — consistent with Plans 01-04's established precedent in this same phase.

## Issues Encountered

- A pre-existing `defp maybe_wrap_envelope(value, tool_module, context, opts \\ [])` header clause in `executor.ex` produced a "default values ... never used" compiler warning once both call sites in the file were updated to always pass an explicit keyword list — fixed by dropping the separate header-only clause (Rule 1, immediate compile-time catch, no behavior change).

## User Setup Required

None — no external service configuration required. `content_scanner` remains entirely opt-in via `config :scoria, :content_scanner, MyScanner` or a per-call override; nothing is required to keep the default (`Scoria.Trust.Scanner.NoOp`) behavior.

## Next Phase Readiness

- TAINT-04 is now fully satisfied end-to-end: the scan engine (Plan 04) is wired at both taint-minting chokepoints with fixed-projector trace tagging and no score leakage. A host that registers a `content_scanner` sees scanned/untrusted content tagged in traces at `Knowledge.retrieve/2` and `MCP.Executor`; a host with none registered sees byte-identical current behavior at both sites.
- D-22 (recorded for Phase 57): `reason_code` on the resolved verdict already distinguishes content-untrusted (`:prompt_injection`, `:moderation_flag`, `:untrusted_source`) from infra-failure-untrusted (`:scanner_error`, `:scanner_timeout`) — Phase 57's confluence gate must branch on this to avoid a universal human-gate on a misconfigured/slow scanner (not enforced this phase, per D-22's cross-phase constraint).
- No blockers. Scoped verification is green: `mix test test/scoria/observe/semconv_test.exs test/scoria/observe/bounds_test.exs test/scoria/knowledge/trust_test.exs test/scoria/mcp/executor_test.exs` (all green), plus a re-run of the full phase-55 scoped lane (`trust_test.exs`, `spotlight_test.exs`, `trust/scan_test.exs`, `mcp/envelope_test.exs`, `knowledge/retrieval_test.exs`) — 164 tests total, 0 failures, `mix compile --warnings-as-errors` clean.

---
*Phase: 55-content-trust-taint-substrate*
*Completed: 2026-07-27*

## Self-Check: PASSED

All 8 modified files confirmed present on disk (`lib/scoria/observe/semconv.ex`, `test/scoria/observe/semconv_test.exs`, `test/scoria/observe/bounds_test.exs`, `lib/scoria/knowledge.ex`, `lib/scoria/observe.ex`, `test/scoria/knowledge/trust_test.exs`, `lib/scoria/mcp/executor.ex`, `test/scoria/mcp/executor_test.exs`). All 3 task commits confirmed in `git log` (`613b01a6`, `58b3f49c`, `1d65e7c9`). Scoped test suite green (164/164 across the full phase-55 lane), `mix compile --warnings-as-errors` clean.

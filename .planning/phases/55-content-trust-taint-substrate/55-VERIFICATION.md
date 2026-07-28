---
phase: 55-content-trust-taint-substrate
verified: 2026-07-28T02:20:16Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: No — initial verification
---

# Phase 55: Content Trust & Taint Substrate Verification Report

**Phase Goal:** Untrusted content moving through Scoria — retrieved knowledge chunks and tool outputs — carries a trust tier, is visibly separated from instructions at prompt assembly, and is scannable via a BYO hook, supplying the missing untrusted-content leg the confluence gate (Phase 57) will read.
**Verified:** 2026-07-28T02:20:16Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A retrieved knowledge chunk carries a trust-tier/taint tag in `Knowledge.Chunk` metadata, defaulting to untrusted for externally-sourced/retrieved content | ✓ VERIFIED | `lib/scoria/trust.ex` (closed binary enum, fail-closed `tier/1`, `default_tier/0 = "untrusted"`); `lib/scoria/trust/tiered.ex` + `defimpl Scoria.Trust.Tiered, for: Scoria.Knowledge.Chunk` in `lib/scoria/knowledge/chunk.ex`; `Knowledge.ingest_source/2` denormalizes `Source.metadata["scoria.trust.tier"]` onto every chunk (`lib/scoria/knowledge.ex:90-119`); host-override API (`create_source`/`ingest_source` `trust:` opt, `set_source_trust/3` tenant-scoped bulk update) and `reembed_source/2`/`reindex_source/2` idempotency all present and tested (`test/scoria/trust_test.exs`, `test/scoria/knowledge/trust_test.exs`) |
| 2 | A tool's output arrives wrapped in an envelope carrying a trust tier, so downstream code treats it as potentially-untrusted rather than implicitly-trusted context | ✓ VERIFIED | `lib/scoria/mcp/envelope.ex` — `Scoria.MCP.Envelope` struct (`@enforce_keys [:value, :tier]`), total accessors (`wrap/2` idempotent, `envelope?/1`, `tier/1`, `value/1`, `scan/1`, `unwrap/1`), `Trust.Tiered` impl; wired at the `MCP.Executor` success choke point (`lib/scoria/mcp/executor.ex:56-75`, AFTER `reconcile_budget`/`emit_sre_telemetry` read the raw result — confirmed by inline comment and a dedicated ordering test); soft-launch flag defaults off (byte-identical `{:ok, value}`); taint always persisted to `step.result_envelope["scoria.taint"]`; replay-stub parity wired (`executor.ex:121-128`) |
| 3 | When a prompt is assembled in the orchestrator, untrusted content is spotlighted/datamarked with a model-agnostic delimiter that distinguishes it from instructions | ✓ VERIFIED | `lib/scoria/spotlight.ex` — host-called `render/2`, content-shape-aware technique selection (`:datamark` for prose, `:delimit` for structured/ambiguous), nonce mechanics (`:crypto.strong_rand_bytes(16) \|> Base.encode32(padding: false)`), bounded 8-retry collision handling with `:delimit` fallback, instruction returned as data on `Marked.instruction`. An adversarial test (`test/scoria/spotlight_test.exs:124-148`, "a forged closing token embedded in the body cannot terminate the real marked region") independently confirms an attacker-planted fake closing token cannot escape the real, nonce-derived marked region — genuinely proves the anti-escape property, not just presence |
| 4 | A host can register a `scan/2` hook (e.g. Rebuff/LlamaGuard-shaped) and see scanned/untrusted content tagged in traces; with none registered, the default no-op leaves current behavior unchanged | ✓ VERIFIED | `lib/scoria/trust/scanner.ex` (`Scoria.Trust.Scanner` behaviour + `NoOp` default), `lib/scoria/trust/verdict.ex` (`Verdict` struct + closed `reason_code` enum), `lib/scoria/trust/scan.ex` (monotonic taint law `most_restrictive/2`, fail-closed error/timeout isolation on a dedicated `Scoria.Trust.TaskSupervisor`); wired at both taint-minting chokepoints — `Knowledge.retrieve/2` (batch-scan, tags the RETRIEVER span) and `MCP.Executor` envelope creation (populates `Envelope.scan`, tags tool telemetry) — via `Semconv.trust_attributes/1` (no `score` key, verified structurally and by a dedicated executor test with an actively-leaking `ScoringScanner`) |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/trust.ex` | Leaf trust vocabulary, fail-closed reader | ✓ VERIFIED | `tiers/0`, `default_tier/0`, `tier_key/0`, `normalize_tier/1`, `tier/1`, `trusted?/1`, `put_tier/2`, `scan/2` delegator. Confirmed dependency-free leaf: `grep -n "alias Scoria.Knowledge\|alias Scoria.MCP\|alias Scoria.Observe"` returns nothing |
| `lib/scoria/trust/tiered.ex` | `Tiered` protocol | ✓ VERIFIED | `defprotocol Scoria.Trust.Tiered` with `tier/1`; impls in `Chunk` and `Envelope` (owning modules, no compile cycle) |
| `lib/scoria/knowledge/chunk.ex`, `source.ex`, `knowledge.ex` | Trust storage + host-override API | ✓ VERIFIED | `defimpl` in `chunk.ex`; `Source.metadata` convention documented in `source.ex`; `create_source`/`ingest_source` `trust:` opt, `set_source_trust/3` (tenant-scoped bulk update), `reembed_source/2`/`reindex_source/2` idempotency, `retrieve/2` batch-scan wiring all in `knowledge.ex` |
| `lib/scoria/mcp/envelope.ex` | Envelope struct + accessors | ✓ VERIFIED | `@enforce_keys [:value, :tier]`, exactly `value, tier, provenance, scan, enveloped_at`; total accessors confirmed by direct read |
| `lib/scoria/mcp/executor.ex` | Envelope wrap + scan wiring | ✓ VERIFIED | `finalize_tool_result/5`, `scan_tool_output/2`, `persist_taint/3`, `maybe_wrap_envelope/4`, `actual_units/3` `%Envelope{}` defense-in-depth head — all present, ordering documented inline as load-bearing |
| `lib/scoria/spotlight.ex`, `spotlight/marked.ex` | Spotlighting seam | ✓ VERIFIED | `render/2`, `Marked` struct with exactly `marked, instruction, technique, tier, marked?, spans`; nonce/nonce-collision mechanics present |
| `lib/scoria/trust/scanner.ex`, `verdict.ex`, `scan.ex` | Scan engine | ✓ VERIFIED | `Scanner` behaviour + `NoOp`, `Verdict` struct + reason_code normalizer, `Scan` orchestration with monotonic law + fail-closed isolation on `Scoria.Trust.TaskSupervisor` (confirmed distinct from `Scoria.MCP.TaskSupervisor` via grep and `application.ex`) |
| `lib/scoria/observe/semconv.ex` | `scoria.trust.*`/`scoria.spotlight.*` registry + projectors | ✓ VERIFIED | `@trust_keys`, `@spotlight_keys`, `trust_attributes/1`, `spotlight_attributes/1`; all 8 keys present in `@attribute_registry`; NO `scoria.trust.score` key exists anywhere |
| `lib/scoria/observe.ex` | RETRIEVER span trust-attribute passthrough | ✓ VERIFIED (additive deviation) | `emit_retriever_span/1` gained a defaulted `:trust_attributes` opt (not in plan 55-05's declared file list) — required to satisfy the plan's own must-have; backward-compatible, no existing caller broken |
| `lib/scoria/application.ex` | Dedicated `Scoria.Trust.TaskSupervisor` | ✓ VERIFIED | `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}` present alongside `MCP.TaskSupervisor`/`Workflow.TaskSupervisor` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `Knowledge.ingest_source/2` | `Chunk.metadata` | `Trust.tier/1` + `Trust.put_tier/2` denormalization | WIRED | Confirmed in code; no `Source` join added on the retrieval hot path (`retrieve/2` reads `row.metadata` directly, `aggregate_incoming_tier/1`) |
| `MCP.Executor` success branch | `Scoria.MCP.Envelope` | `finalize_tool_result/5` → `maybe_wrap_envelope/4` | WIRED | Only the `{:ok, value}` leg's inner value is wrapped; `{:error, _}` passes through untouched (tested) |
| `MCP.Executor` | `step.result_envelope["scoria.taint"]` | `persist_taint/3` → `persist_taint_to_step/3` (jsonb merge fragment) | WIRED | Always computed regardless of `wrap_tool_output` flag (tested for both flag states) |
| `Scoria.Trust.Scan` | RETRIEVER span | `Knowledge.retrieve/2`'s `resolve_trust_attributes/2` → `Semconv.trust_attributes/1` → `Observe.emit_retriever_span/1`'s `:trust_attributes` opt | WIRED | Same span, no `Guardrail.emit/1`, no new span |
| `Scoria.Trust.Scan` | tool telemetry / `Envelope.scan` | `MCP.Executor`'s `scan_tool_output/2` → `finalize_tool_result/5` | WIRED | `Envelope.scan` populated only for a real (non-NoOp) scanner; `[:scoria, :tool, :completed]` telemetry carries `scoria.trust.*` |
| `Scoria.Trust.scan/2` | `Scoria.Trust.Scan.scan/2` | thin runtime delegator | WIRED | Confirmed: `grep -n "Scoria.MCP" lib/scoria/trust/scan.ex` returns nothing (no compile-time coupling) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase-55 scoped test lane green | `mix test test/scoria/trust_test.exs test/scoria/knowledge/trust_test.exs test/scoria/mcp/envelope_test.exs test/scoria/mcp/executor_test.exs test/scoria/spotlight_test.exs test/scoria/trust/ test/scoria/observe/semconv_test.exs test/scoria/observe/bounds_test.exs` | 154 tests, 0 failures | ✓ PASS |
| Compile warnings-as-errors | `mix compile --warnings-as-errors` | clean (no output) | ✓ PASS |
| Full suite (isolated, uncontaminated run) | `mix test` | 3 doctests, 1415 tests, 1 failure (75 excluded) | ✓ PASS (see note below) |
| Adversarial forged-closing-token escape test | `mix test test/scoria/spotlight_test.exs` | real nonce-derived boundary cannot be forged; forged token stays inside the marked region | ✓ PASS |
| Monotonic taint law exhaustive enumeration | `mix test test/scoria/trust/scan_test.exs` | all 4 tier combinations correct, including adversarial laundering-attempt scanner | ✓ PASS |
| `score` never reaches a trace or jsonb | `mix test test/scoria/observe/semconv_test.exs test/scoria/mcp/executor_test.exs` | structural (no `:score` key in `trust_keys/0`) + a `ScoringScanner` fixture actively trying to leak `score: 0.987` | ✓ PASS |

**Note on the one full-suite failure:** `Scoria.WarningInventory.CaptureParityTest` ("optimized compile-only capture catches high-signal unclassified warning (injected)", `test/scoria/warning_inventory/capture_parity_test.exs:53`) is a documented pre-existing flake tracked at `.planning/todos/pending/2026-07-18-flaky-capture-parity-test.md` (created 2026-07-18, ten days before this phase's work began on 2026-07-27). Independently confirmed during this verification:
- `git diff --stat 75389559..HEAD -- lib/ test/` shows phase 55 touches zero files under `lib/scoria/warning_inventory/` or `test/scoria/warning_inventory/`.
- The failure is order/concurrency-sensitive by the todo's own description ("fails intermittently... depending on seed/ordering... passes cleanly in isolation").
- Re-ran the full suite from a clean, single (non-concurrent) `mix test` invocation after killing all other concurrent test processes against the same DB — result: 1415 tests, 1 failure, same test, same failure mode. This matches the orchestrator's reported baseline exactly and is not attributable to this phase.

(An earlier attempt to run a second full suite concurrently against the same `scoria_test` Postgres instance — for cross-checking purposes — produced 4-5 spurious failures in unrelated tests, e.g. `Mix.Tasks.Scoria.InstallCheckTest`, due to shared-DB/subprocess contention from running multiple full suites in parallel. This is a self-inflicted artifact of verification methodology, not a code regression; it is not counted as evidence and does not appear in the isolated re-run.)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|--------------|------------|-------------|--------|----------|
| TAINT-01 | 55-01 | Retrieved knowledge chunks carry a trust-tier/taint tag on `Knowledge.Chunk` metadata, defaulting to untrusted | ✓ SATISFIED | `Scoria.Trust` + `Tiered` + `Knowledge` wiring; REQUIREMENTS.md checkbox and traceability table correctly marked "Complete" |
| TAINT-02 | 55-02 | Tool outputs wrapped in an envelope carrying a trust tier | ✓ SATISFIED (code) / ⚠️ REQUIREMENTS.md stale | `Scoria.MCP.Envelope` fully implemented and tested. **REQUIREMENTS.md still shows this unchecked (`- [ ]`) and "Pending" in the traceability table** — commit `ea7f71fd` ("docs(55-02): complete tool-output envelope plan") added the SUMMARY.md but did not run the `requirements.mark-complete` step that plans 55-01 and 55-05 used. This is a documentation/traceability bookkeeping gap, not a functional gap — recommend updating REQUIREMENTS.md before shipping |
| TAINT-03 | 55-03 | Prompt-assembly spotlighting/datamarking with a model-agnostic delimiter | ✓ SATISFIED (code) / ⚠️ REQUIREMENTS.md stale | `Scoria.Spotlight` fully implemented and tested (including the adversarial forged-token test). **REQUIREMENTS.md still shows this unchecked (`- [ ]`) and "Pending"** — commit `e1e0dd3a` ("docs(55-03): complete spotlighting seam plan") likewise did not mark the requirement complete. Same recommendation as TAINT-02 |
| TAINT-04 | 55-04, 55-05 | `scan/2` BYO hook (default no-op) + trace tagging, no detector shipped in-lib | ✓ SATISFIED | `Scoria.Trust.Scanner`/`.NoOp`, `Verdict`, `Scan` (monotonic law + fail-closed isolation), wired at both minting chokepoints; REQUIREMENTS.md correctly marked "Complete" (commit `bbffb8d6`) |

No orphaned requirements: REQUIREMENTS.md maps exactly TAINT-01..04 to Phase 55, and all four appear in the phase's plan frontmatter `requirements:` fields.

### Anti-Patterns Found

Scanned all files created/modified across all 5 plans (`lib/scoria/trust.ex`, `trust/tiered.ex`, `trust/scanner.ex`, `trust/verdict.ex`, `trust/scan.ex`, `mcp/envelope.ex`, `mcp/executor.ex`, `spotlight.ex`, `spotlight/marked.ex`, `knowledge.ex`, `knowledge/chunk.ex`, `knowledge/source.ex`, `observe/semconv.ex`, `observe.ex`, `application.ex`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`/"not yet implemented"/"coming soon" — **none found**.

No stub patterns (`return null`/hardcoded-empty-with-no-populating-path) found in any of the reviewed modules — every accessor, wiring point, and fail-closed branch has a real implementation backed by a passing test.

One transparently-documented deviation (not an anti-pattern): `lib/scoria/observe.ex`'s `emit_retriever_span/1` gained an additive `:trust_attributes` opt outside plan 55-05's declared file list, disclosed in the 55-05 SUMMARY.md as a Rule 2 fix. Assessed as acceptable — backward-compatible (defaults to `%{}`), structurally required to satisfy the plan's own must-have (tagging the RETRIEVER span), and does not touch `SpanKind` or introduce a new span.

### Human Verification Required

None. Every must-have truth in this phase is deterministically testable in-repo (trust vocabulary, envelope wrapping, spotlighting mechanics, scan orchestration) — the only inherently non-automatable item (a real BYO scanner like Rebuff/LlamaGuard) is explicitly out-of-lib per scope doctrine and documented as such in `55-VALIDATION.md`'s "Manual-Only Verifications" section; it does not block this phase's goal, which is the seam itself, not a shipped detector.

### Gaps Summary

No functional gaps. All four ROADMAP success criteria are independently verified against the actual codebase (not SUMMARY.md claims): reading every implementation file directly, confirming the D-01 through D-23 decisions from `55-CONTEXT.md` were honored in code, and running both the phase-scoped test lane (154/154 green) and a clean, uncontaminated full suite (1415 tests, 1 pre-existing unrelated failure).

One non-blocking documentation gap: `.planning/REQUIREMENTS.md` has stale checkboxes/traceability-table entries for TAINT-02 and TAINT-03 (both show "Pending" despite being fully implemented and tested). This should be corrected before the milestone ships so downstream tooling (progress tracking, phase-dependency checks) reflects reality. This is a paperwork fix, not a code fix — no gap in the actual substrate exists.

---

_Verified: 2026-07-28T02:20:16Z_
_Verifier: Claude (gsd-verifier)_

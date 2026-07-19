---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
verified: 2026-07-12T17:10:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy Verification Report

**Phase Goal:** Every span Scoria emits actually persists to Postgres, carries the current OTel-GenAI model-config attributes, and reports a correct, canonically-sourced `span_kind` — closing the pre-existing silent FK gap that has been swallowing every span insert.
**Verified:** 2026-07-12T17:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A span emitted through the real adapter path persists as a row in `ai_spans` with a matching `ai_traces` row present (no FK violation, no silent rescue), verifiable against real Postgres without hand-inserting the trace | ✓ VERIFIED | `lib/scoria/observe/buffer.ex:103-169` runs one `Ecto.Multi` per flush: `insert_all(:traces, ..., on_conflict: :nothing, conflict_target: [:id])` then `insert_all(:spans, ...)` in one `Repo.transaction/1`. `test/scoria/observe/buffer_test.exs:59-82` ("auto-upserts the parent trace row before inserting the span (no hand-inserted trace)") starts a Buffer with NO pre-inserted `%Trace{}`, casts a span with a fresh `trace_id`, calls the synchronous `:flush_now` hook, then asserts both `Repo.get(Trace, trace_id)` and the span row exist. Ran the test directly against real Postgres (sandbox-backed): observed live SQL — `INSERT INTO "ai_traces" (...) ON CONFLICT ("id") DO NOTHING` followed by `INSERT INTO "ai_spans" (...)` in the same transaction. The old bare `rescue e -> Logger.error("Failed to flush spans: #{inspect(e)}")` string is gone (`grep -c 'Failed to flush spans' lib/scoria/observe/buffer.ex` == 0). |
| 2 | A persisted LLM span carries `gen_ai.request.model`, `.temperature`, `.top_p`, `.max_tokens`, `.seed`, and `gen_ai.usage.*` together (never a partial subset), sourced via `ReqLLM.OpenTelemetry.Attributes` | ✓ VERIFIED | `lib/scoria/observe/semconv.ex:29-33` `merge_req_llm_attributes/2` delegates wholesale to `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` — zero hand-declared `gen_ai.*` string literals in the module (`grep -c '"gen_ai\.' lib/scoria/observe/semconv.ex` == 0). `lib/scoria/observe/adapters/req_llm.ex:36` calls `Semconv.merge_req_llm_attributes/2`. `test/scoria/observe/adapters/req_llm_test.exs` (SPAN-01 describe block) and `test/scoria/observe/semconv_test.exs` assert all five model-config keys plus a `gen_ai.usage.*` key are present together, using a realistic `%LLMDB.Model{}` fixture (not a bare string — the incidental struct-in-jsonb bug (Pitfall 1) is also fixed). Ran both test files: pass. |
| 3 | Every span's `span_kind` is drawn from one shared whitelist module consumed by both `WorkflowTreeComponent` and `TraceTreeComponent` (no independently-hardcoded lists), carries a mirrored `openinference.span.kind` attribute, with `mcp` translating to `"TOOL"` | ✓ VERIFIED | `lib/scoria/observe/span_kind.ex` is the single shared module (`kinds/0`, `kind?/1`, `normalize/2`, `to_openinference/1`; `to_openinference("mcp") == "TOOL"`). `lib/scoria_web/components/trace_tree_component.ex:86-89` delegates wholly to `SpanKind.normalize/1`. `lib/scoria_web/components/workflow_tree_component.ex:38-41` keeps its distinct step-vocab clauses but routes its fallback through `SpanKind.normalize/1` — no inline `~w(...)` whitelist remains in either file (confirmed via grep). Both adapters (`req_llm.ex:32,37` and `jido.ex:21,33`) set `span_kind` via `SpanKind.normalize/2` and mirror `openinference.span.kind` via `SpanKind.to_openinference/1` + `Semconv.openinference_span_kind_key/0`. The D-15 drift-guard suite (`test/scoria/observe/span_kind_test.exs`) enforces canary, exhaustiveness, CSS coherence, and anti-inline-guard assertions — all pass. |
| 4 | Every `gen_ai.*`/`openinference.*` key string traces back to one version-pinned mapping module (`Scoria.Observe.Semconv`), not inline string literals at multiple call sites | ✓ VERIFIED | `lib/scoria/observe/semconv.ex` owns `openinference_span_kind_key/0` (`"openinference.span.kind"`) and is the sole call site for `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1`. Neither adapter file contains a `gen_ai.*`/`openinference.*` string literal (`grep -Ec '"(gen_ai\.|openinference\.span\.kind)"' lib/scoria/observe/adapters/req_llm.ex` == 0; same check on `jido.ex` == 0). Both adapters call `Semconv.openinference_span_kind_key()` rather than hardcoding the string. |
| 5 | Adopters querying legacy keys (`llm.model_name`, `llm.token_count`, `req.url`) get an explicit, CHANGELOG-documented behavior, not a silent break | ✓ VERIFIED | `lib/scoria/observe/adapters/req_llm.ex` no longer emits `llm.model_name`/`llm.token_count`/`req.url` (grep confirms 0 occurrences) — clean replacement per D-01. `CHANGELOG.md` (`## [Unreleased]` → `### ⚠ BREAKING CHANGES (0.1.4 cut)`, lines 151-179) documents the full old→new key mapping table (all three legacy keys + replacements, including the `req.url` lossiness callout), one upgrade-guide sentence, and the FOUND-01 `flush_error`/`:on_flush_error` announcement. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/observe/span_kind.ex` | Shared 8-value taxonomy module | ✓ VERIFIED | Plain module, no `Ecto.Enum`, all 4 public functions present and correct |
| `lib/scoria/observe/semconv.ex` | Version-pinned key mapping module | ✓ VERIFIED | Delegates to `ReqLLM.OpenTelemetry.Attributes`; owns `openinference.span.kind` |
| `lib/scoria/observe/buffer.ex` | FK-safe flush + loud failure surfacing | ✓ VERIFIED | `Ecto.Multi` trace-upsert-then-span-insert; `:on_flush_error`, `:flush_now`, terminate-gate, storm counter all present |
| `lib/scoria/observe/telemetry.ex` | `emit_flush_error/1` wrapper | ✓ VERIFIED | Mirrors `emit_span_delta/1` convention; not attached; carries counts/identity only |
| `lib/scoria/observe/adapters/req_llm.ex` | gen_ai.* + span_kind wiring, legacy keys dropped | ✓ VERIFIED | Semconv/SpanKind wired; legacy keys absent; struct-in-jsonb bug fixed |
| `lib/scoria/observe/adapters/jido.ex` | span_kind via SpanKind, openinference mirror | ✓ VERIFIED | `INTERNAL` literal replaced; host-override + flat default `"tool"` |
| `lib/scoria_web/components/trace_tree_component.ex` | Delegates to SpanKind | ✓ VERIFIED | `span_kind/1` wholly delegates to `SpanKind.normalize/1` |
| `lib/scoria_web/components/workflow_tree_component.ex` | Delegates to SpanKind (fallback) | ✓ VERIFIED | Step-vocab clauses kept; fallback delegates |
| `assets/css/04-components.css` | 8 kind rails + status-error overlay | ✓ VERIFIED | All 8 `.scoria-span--<kind>` rails present; `.scoria-span--status-error` present; stale `.scoria-span--error ` rail form absent |
| `CHANGELOG.md` | 0.1.4 breaking-change entry | ✓ VERIFIED | Mapping table + upgrade sentence + flush_error announcement present, no dual-emit language |
| Test files (6) | Behavior + drift-guard + adapter tests | ✓ VERIFIED | All ran directly; 80/80 tests pass in `test/scoria/observe/`; component tests pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `trace_tree_component.ex` | `Scoria.Observe.SpanKind` | `SpanKind.normalize/1` | ✓ WIRED | Confirmed by grep + passing render test |
| `workflow_tree_component.ex` | `Scoria.Observe.SpanKind` | `SpanKind.normalize/1` (fallback clause) | ✓ WIRED | Confirmed by grep + passing render test |
| `Buffer.flush_spans/2` | `Scoria.Observe.Telemetry.emit_flush_error/1` | direct call, wrapped in `safe_emit_flush_error/1` | ✓ WIRED | Confirmed by grep + live telemetry-event test (`assert_receive`) |
| `Ecto.Multi` trace-upsert | `insert_all(:spans, ...)` | one `Repo.transaction/1` | ✓ WIRED | Confirmed by grep + real SQL observed during test run (`ON CONFLICT ("id") DO NOTHING` then span insert in same txn) |
| `req_llm.ex` | `Scoria.Observe.Semconv.merge_req_llm_attributes/2` | direct call | ✓ WIRED | Confirmed by grep + passing SPAN-01 completeness test |
| `req_llm.ex` / `jido.ex` | `Scoria.Observe.Semconv.openinference_span_kind_key/0` + `SpanKind.to_openinference/1` | mirror attribute write | ✓ WIRED | Confirmed by grep (no inline literal) + passing SPAN-02 mirror tests |

### Behavioral Spot-Checks (real test execution, not SUMMARY claims)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Real-Postgres auto-upsert (no hand-inserted trace) | `mix test test/scoria/observe/buffer_test.exs` | Live SQL observed: trace `INSERT ... ON CONFLICT DO NOTHING` then span `INSERT` in one transaction; test passed | ✓ PASS |
| Loud, non-fatal flush-error surfacing | same run | Real `not_null_violation` induced; `Logger.error` + `[:scoria,:observe,:buffer,:flush_error]` event fired; `Process.alive?(pid)` true | ✓ PASS |
| Full targeted suite (`span_kind`, `semconv`, `buffer`, `req_llm`, `jido`, both UI components) | `mix test <7 files>` | 45 tests, 0 failures | ✓ PASS |
| `test/scoria/observe/` full regression | `mix test test/scoria/observe/` | 80 tests, 0 failures | ✓ PASS |
| Full workspace suite | `mix test` (run once) | 3 doctests, 1163 tests, 1 failure | ✓ PASS (see note) |
| The one full-suite failure is the pre-existing, documented flake, not a phase-51 regression | `mix test test/scoria/warning_inventory/capture_parity_test.exs` (standalone) | 2 tests, 0 failures | ✓ PASS — confirms `test/scoria/warning_inventory/capture_parity_test.exs:53` is the sole full-suite failure and it passes standalone, matching `deferred-items.md`'s documented environment-only flake, unrelated to any phase-51 file |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| FOUND-01 | 51-03 | Trace auto-upsert closes FK gap; silent rescue replaced | ✓ SATISFIED | `buffer.ex` Ecto.Multi + loud surfacing; live-Postgres test passes |
| FOUND-02 | 51-01 | Shared span_kind whitelist module + drift guard | ✓ SATISFIED | `span_kind.ex` + D-15 suite green |
| FOUND-03 | 51-02 | Version-pinned semconv mapping module | ✓ SATISFIED | `semconv.ex` delegates to ReqLLM.OpenTelemetry.Attributes |
| SPAN-01 | 51-04 | All 4 model-config params + usage together | ✓ SATISFIED | `req_llm_test.exs` SPAN-01 completeness test passes |
| SPAN-02 | 51-01, 51-04, 51-05 | Correct span_kind + openinference mirror, mcp→TOOL | ✓ SATISFIED | Both adapters + both UI components wired; tests pass |
| COMPAT-01 | 51-04 | Legacy keys documented (clean replacement) | ✓ SATISFIED | CHANGELOG mapping table present; legacy keys absent from adapter |

No orphaned requirements — all 6 IDs declared across plan frontmatter map 1:1 to REQUIREMENTS.md entries, all marked `[x]` Complete, and all traced to concrete evidence above.

### Anti-Patterns Found

None. Scanned all 6 key `lib/` files modified/created in this phase (`span_kind.ex`, `semconv.ex`, `buffer.ex`, `telemetry.ex`, `adapters/req_llm.ex`, `adapters/jido.ex`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` — zero matches.

### Human Verification Required

None. All 5 roadmap success criteria resolved to programmatically-verifiable evidence (source inspection + live test execution against real Postgres), with no runtime/visual/UX behavior requiring human judgment for this phase's scope.

### Gaps Summary

None. All 5 ROADMAP success criteria and all 6 requirement IDs (FOUND-01/02/03, SPAN-01/02, COMPAT-01) are verified against actual code and live test execution — not SUMMARY.md claims. Every plan's must_haves (truths, artifacts, key_links) checked out. The single full-suite test failure (`capture_parity_test.exs`) is a pre-existing, environment-only flake (confirmed to pass standalone), documented in the phase's own `deferred-items.md`, and explicitly excluded from phase-51 scope per the task instructions — it is not a phase-51 regression and does not block this verification.

---

*Verified: 2026-07-12T17:10:00Z*
*Verifier: Claude (gsd-verifier)*

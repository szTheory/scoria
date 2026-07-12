---
phase: 52-retriever-span-host-declared-attributes
verified: 2026-07-12T21:38:44Z
status: passed
score: 4/4 requirements verified (RETR-01, RETR-02, ATTR-01, ATTR-02); 4/4 ROADMAP success criteria verified
behavior_unverified: 0
overrides_applied: 0
re_verification: null
---

# Phase 52: RETRIEVER Span + Host-Declared Attributes Verification Report

**Phase Goal:** Retrieval calls are visible in the trace tree as a linked `RETRIEVER` span without displacing `ai_retrieval_runs` as the system-of-record, and hosts can declare feature/route/archetype/intent plus context-pack composition without Scoria ever inferring them.
**Verified:** 2026-07-12T21:38:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 (SC#1/RETR-01) | `Knowledge.retrieve/2` produces both a persisted `ai_retrieval_runs` row and a linked `RETRIEVER` span sharing `trace_id`/`span_id`; join never empty for a successful call | ✓ VERIFIED | `lib/scoria/knowledge.ex:245-305` mints `trace_id`/`span_id`, writes `span_id` to `run.span_id` and to `emit_retriever_span/1`'s `:id` (`lib/scoria/observe.ex:86`). Real-Postgres test `test/scoria/knowledge/retrieval_test.exs:105-131` ("RETR-01: retrieve/2 produces a linked RETRIEVER span sharing trace_id/span_id with the run") asserts the join after `Buffer.flush_now/1`. Independently re-ran: `mix scoria.test.knowledge --only knowledge` → 58 tests, 0 failures. |
| 2 (SC#2/RETR-02) | `embedding_model`/`index_version`/`reranker` appear as convention keys on both the span attributes and `run.metadata`, from one shared value origin, with a consistency guard | ✓ VERIFIED | One `config_map` computed once in `retrieve/2` (`knowledge.ex:258-262`), projected via `Semconv.retrieval_config_attributes/1` into both `create_retrieval_run`'s `metadata:` (`knowledge.ex:295-298`) and `emit_retriever_span/1`'s attributes (`observe.ex:76`). Real-Postgres equality test `retrieval_test.exs:133-164` asserts `Map.take(span.attributes, keys) == Map.take(run.metadata, keys)` for all 3 keys plus the `"none"` sentinel behavior. Canary + anti-inline grep guards in `test/scoria/observe/semconv_test.exs:92-142`. |
| 3 (SC#3/ATTR-01) | A host-supplied `feature`/`route`/`archetype`/`intent` value flows through to persisted span attributes unmodified; Scoria never infers | ✓ VERIFIED | `Semconv.host_declared_keys/0` + `merge_host_declared/2` (`lib/scoria/observe/semconv.ex:67-94`) is the single skip-nil seam; called by `retrieve/2` (via `emit_retriever_span/1`), both adapters (`req_llm.ex:43`, `jido.ex:37`), and `emit_prompt_span/1`. Real-Postgres byte-for-byte pass-through + never-default proof at `retrieval_test.exs:166-197` and prompt-span proof at `test/scoria/observe/prompt_span_test.exs` (ATTR-01 describe block). Adapter-level pass-through proven at `test/scoria/observe/adapters/jido_test.exs` (production-shaped) and `req_llm_test.exs` (hand-synthesized, with the D-ATTR01-7 reachability caveat documented inline). |
| 4 (SC#4/ATTR-02) | A `PROMPT`-carrying span's attributes carry which chunk IDs, which memory IDs, and per-source token split, alongside `gen_ai.usage.input_tokens` — IDs and counts only, never raw text | ✓ VERIFIED (with documented, disclosed scope reinterpretation) | `Scoria.Observe.emit_prompt_span/1` (`observe.ex:137-158`) attaches `Semconv.prompt_context/1`'s nested id/tokens-only map plus `Semconv.merge_usage_input_tokens/2`. Real-Postgres coexistence + never-text end-to-end + omit-when-absent proofs at `test/scoria/observe/prompt_span_test.exs` (5 tests, all pass in isolation and in the full suite). D-ATTR02-1 explicitly and correctly documents that Phase 52 attaches these attributes to a Scoria-emitted composition span (`name: "prompt.compose"`, `span_kind: "prompt"`) rather than a duration/parent-linked child `PROMPT` span — that structural relocation is explicitly deferred to Phase 53/EVENT-01 with "zero contract change." This is a disclosed, roadmap-documented reinterpretation (not a silent gap) and the underlying attribute contract (SC#4's literal ask: "chunk IDs, memory IDs, token split, alongside `gen_ai.usage.input_tokens`, IDs/counts only") is met. |

**Score:** 4/4 truths verified, 0 present-but-behavior-unverified, 0 failed.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scoria/observe/semconv.ex` | Single-origin key-string owner: `retrieval_config_keys/0`, `retrieval_config_attributes/1`, `host_declared_keys/0`, `merge_host_declared/2`, `prompt_context_key/0`, `prompt_context/1`, `merge_usage_input_tokens/2` | ✓ VERIFIED | All 7 functions present with `@spec`/`@doc`, module-attribute-backed constants. Read and confirmed against source. |
| `lib/scoria/observe.ex` | `emit_retriever_span/1`, `emit_prompt_span/1` host-facing facade | ✓ VERIFIED | Both present, both route every attribute through Semconv/SpanKind, both wrap `:telemetry.execute` in `try/rescue -> :ok` (D-R6). |
| `lib/scoria/knowledge/embedder.ex` | Optional `model_name/0` callback + `Deterministic.model_name/0` | ✓ VERIFIED | `@callback model_name() :: String.t()` with `@optional_callbacks [model_name: 0]`; `Deterministic.model_name/0` returns the stable literal `"scoria.deterministic.sha256.v1"`. |
| `lib/scoria/knowledge.ex` | `retrieve/2` wired to mint IDs, build one config map, emit RETRIEVER span, additive return | ✓ VERIFIED | Confirmed at `knowledge.ex:245-339` — matches the plan's 8-step edit list exactly (mint IDs, wall-clock start, embedder resolution, single config_map, host_metadata normalization, span_id written to run + span, post-with-chain emit, additive return). |
| `lib/scoria/observe/adapters/req_llm.ex`, `.../jido.ex` | `merge_host_declared/2` pipe stage added | ✓ VERIFIED | Both adapters pipe `metadata` through `Semconv.merge_host_declared/2` as the final attribute stage. |
| `priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs` | FK-drop migration (deviation, see below) | ✓ VERIFIED, assessed sound | See "FK-Drop Migration Assessment" below. |
| `test/scoria/observe/semconv_test.exs`, `observe_test.exs`, `test/scoria/knowledge/retrieval_test.exs`, `test/scoria/observe/prompt_span_test.exs`, `test/scoria/observe/adapters/{jido,req_llm}_test.exs`, `test/scoria/knowledge_embedder_test.exs` | Drift-guard + integration tests | ✓ VERIFIED | All present, all independently re-run green (see Behavioral Spot-Checks). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `Knowledge.retrieve/2` | `Scoria.Observe.emit_retriever_span/1` | private `emit_retriever_span/6` helper, called after the `with`-chain succeeds, `try/rescue -> :ok` | ✓ WIRED | `knowledge.ex:301,328-339`. |
| `retrieve/2`'s `config_map` | both `create_retrieval_run`'s `metadata:` and the emitted span's `attributes` | `Semconv.retrieval_config_attributes/1` — single computation, dual projection | ✓ WIRED | `knowledge.ex:258-262,295-298` → `observe.ex:76`. Confirmed structurally single-origin (not computed twice). |
| `run.span_id` | emitted span's `:id` | explicit `id: opts[:span_id]` (not `Buffer`'s `put_new_lazy`) | ✓ WIRED | `observe.ex:86`; this is the join key proven by the RETR-01 real-Postgres test. |
| `host_metadata` (opts→map) | RETRIEVER span attributes, prompt span attributes, both adapter spans | `Semconv.merge_host_declared/2` (single seam) | ✓ WIRED | `observe.ex:77,141`; `req_llm.ex:43`; `jido.ex:37`. |
| `emit_prompt_span/1`'s `context_pack` | persisted `scoria.prompt.context` attribute | `Semconv.prompt_context/1` via `maybe_put_prompt_context/2` (omit-when-empty) | ✓ WIRED | `observe.ex:142,160-170`. |
| Adapters/knowledge/observe → Semconv | key strings | anti-inline grep guards | ✓ WIRED | `semconv_test.exs` grep-guards scan `lib/scoria/knowledge.ex`, `lib/scoria/observe.ex`, both adapters for `scoria.retrieval.`, `feature`/`route`/`archetype`/`intent`, and `scoria.prompt.context` literals — all refuted (0 inline occurrences outside `semconv.ex`). |

### Behavioral Spot-Checks (independently re-run by this verifier)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Observe-lane unit + drift-guard tests | `mix test test/scoria/observe/semconv_test.exs test/scoria/observe/observe_test.exs test/scoria/observe/adapters/ test/scoria/observe/prompt_span_test.exs` | 52 tests, 0 failures | ✓ PASS |
| Knowledge-lane real-Postgres integration tests | `mix scoria.test.knowledge --only knowledge` | 58 tests, 0 failures | ✓ PASS |
| Embedder unit tests (relocated file) | `test/scoria/knowledge_embedder_test.exs` present, content confirms `NoModelName` guard + `Code.ensure_loaded?` fix | file read directly, matches claims | ✓ PASS |
| Full suite (independently re-run twice by this verifier, not trusted from SUMMARY) | `mix test` | 3 doctests, 1202 tests, 1 failure (both runs) | ✓ MATCHES CLAIM |
| Single failure identity | `grep "1)" full test log` | `Scoria.WarningInventory.CaptureParityTest` — subprocess-based compile-warning capture, `test/scoria/warning_inventory/capture_parity_test.exs:53`, last modified 2026-06-17 (pre-Phase-52) | ✓ CONFIRMED unrelated to Phase 52 |
| Deferred item #3/#4 (`test/tmp` races) reproduction check | grepped full independent test log for `InstallCheckTest`/`TmpPreflightTest` failures | none found in this verifier's run (only the CaptureParityTest failure occurred) | ✓ Consistent with "intermittent, unrelated" characterization |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|--------------|--------|----------|
| RETR-01 | 52-01, 52-03, 52-04 | RETRIEVER span dual-written alongside `ai_retrieval_runs` | ✓ SATISFIED | See Truth #1. |
| RETR-02 | 52-01, 52-02, 52-04 | Retrieval config convention keys with span↔table consistency guard | ✓ SATISFIED | See Truth #2. |
| ATTR-01 | 52-01, 52-03, 52-04, 52-05, 52-06 | Reserved host-declared keys, reserve-and-pass-through-never-infer | ✓ SATISFIED | See Truth #3. |
| ATTR-02 | 52-01, 52-03, 52-06 | Context-pack/token-budget composition, IDs/counts only | ✓ SATISFIED | See Truth #4. |

No orphaned requirements — `REQUIREMENTS.md` maps exactly RETR-01/02, ATTR-01/02 to Phase 52, and all four are claimed by plan frontmatter and independently verified above.

### Anti-Patterns Found

None. Grep for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` and "not yet implemented"/"coming soon"-style phrases across all 14 files touched by this phase's 6 plans (semconv.ex, observe.ex, knowledge.ex, embedder.ex, both adapters, the FK-drop migration, and all associated test files) returned zero matches.

### FK-Drop Migration Assessment (the deviation flagged for scrutiny)

**What changed:** Plan 52-04 added `priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs`, which drops the `ai_retrieval_runs_trace_id_fkey`/`ai_retrieval_runs_span_id_fkey` hard foreign-key constraints (originally `references(:ai_traces/:ai_spans, on_delete: :nilify_all)`, added in `20260511000300_create_knowledge_tables.exs:54-55`). The columns and their indexes are kept.

**Why it was needed:** D-R2 (locked in `52-CONTEXT.md`) mandates minting a fresh `trace_id`/`span_id` on *every* `retrieve/2` call (not just when the host supplies one), written synchronously into `ai_retrieval_runs` inside the `with`-chain. The linked RETRIEVER span, however, is persisted *asynchronously* via the Phase-51 telemetry→`Buffer`→Postgres pipeline — D-R1 explicitly forbids a synchronous span insert (it would re-open the exact FK footgun Phase 51 fixed, bypass `Redactor`, and skip `ReviewerBroadcast`). With a hard, immediate-check FK and IDs now always non-nil, every context-less retrieval — the overwhelmingly common case — would raise `Ecto.ConstraintError` at run-insert time, because the referenced trace/span rows do not exist yet. This was independently confirmed: `resolve_embedding_model`/ID-minting logic in `knowledge.ex` always assigns `trace_id`/`span_id`, and the async `Buffer.flush_now/1`-based persistence path is real (confirmed by reading `lib/scoria/observe/buffer.ex` and the passing RETR-01 test).

**Assessment: sound, not a silent weakening.**
1. **Not a regression of a previously-enforced guarantee.** Before Phase 52, `trace_id`/`span_id` were `nil`-able opt-in fields — the FK was rarely exercised because the columns were usually `nil` (nil FK values are vacuously valid in Postgres). Phase 52's own change (mandatory ID minting) is what turns the previously-dormant FK into an unconditional footgun; dropping it restores the pre-existing *effective* behavior (no enforced synchronous reference) rather than removing a guarantee real callers depended on.
2. **The two real alternatives were both worse.** (a) Synchronously pre-inserting a full span row would bypass `Redactor` — an actual security regression per this phase's own threat model (T-52-04c mitigation depends on Redactor running). (b) Synchronously upserting a bare-bones stub span row would collide with the async `Buffer`'s own unconditional `insert_all` (no `on_conflict`, by Phase-51 design) and silently drop the real, attribute-bearing span for the whole flush batch — a worse outcome than a missing FK, since it would destroy legitimate span data.
3. **Linkage correctness is proven at the application level, not just asserted.** The RETR-01 join test (`retrieval_test.exs:105-131`) independently verified by this verifier calls `Buffer.flush_now/1` before asserting `span.trace_id == run.trace_id` and the join is non-empty — this is real evidence, not a documentation claim.
4. **No downstream code depends on the dropped FK.** Grepped `lib/scoria_web/` for any join/query assuming a DB-enforced `ai_retrieval_runs.trace_id/span_id` relationship — none found. Dashboard/UI code does not currently rely on an `INNER JOIN` or cascade behavior that the FK provided.
5. **Residual risk (acceptable, disclosed):** if the host application never starts `Scoria.Observe.Buffer`/attaches `Scoria.Observe.Telemetry` (confirmed: `lib/scoria/application.ex`'s supervision tree does **not** start the Observe pipeline by default — this is inherited Phase-51 "host wires it" architecture, not new to Phase 52), a `retrieve/2` call's `trace_id`/`span_id` will permanently reference non-existent rows with no FK to catch it. This is consistent with the project's "consumer-not-provider" DNA (the host owns telemetry wiring) and is not a Phase-52-introduced gap — Phase 51's LLM/TOOL spans have the identical dependency and were not flagged as a gap at that phase's verification. Not a blocker for this phase's goal, but worth carrying into Phase 53/docs as a known operational precondition.

**Verdict on this deviation: SOUND.** The fix is surgical (a single constraint-drop migration, columns/indexes retained), necessary (without it RETR-01's core "join never comes up empty" criterion is unreachable for the majority use case), and does not weaken any guarantee actually relied upon elsewhere in the codebase.

### Human Verification Required

None required to pass this phase. One optional manual-only item was scoped in `52-VALIDATION.md` (RETRIEVER span visible in the trace-tree UI rail) but is explicitly out of the phase's required acceptance bar — research confirmed zero required UI edits (existing `SpanKind`/CSS whitelist already includes `retriever` from Phase 51), and persisted-span correctness is already covered by the automated RETR-01 integration test. Not gating.

### Gaps Summary

No gaps found. All four ROADMAP success criteria and all four requirement IDs (RETR-01, RETR-02, ATTR-01, ATTR-02) are independently verified against real code and real-Postgres test evidence (not SUMMARY claims) by this verifier:
- Read and manually confirmed the implementation of `lib/scoria/observe/semconv.ex`, `lib/scoria/observe.ex`, `lib/scoria/knowledge.ex` (the `retrieve/2` wiring), both adapters, and the embedder callback.
- Independently re-ran (not copied from SUMMARY) `mix test test/scoria/observe/...` (52/52 pass), `mix scoria.test.knowledge --only knowledge` (58/58 pass), and the full `mix test` suite twice (3 doctests, 1202 tests, 1 failure both times) — confirming the claimed test status byte-for-byte.
- Independently traced the single full-suite failure to `Scoria.WarningInventory.CaptureParityTest`, confirmed via `git log` that the failing test file predates Phase 52 by nearly a month (2026-06-17) and is untouched by any Phase-52 commit — the "pre-existing Phase-28 flake" attribution holds up under independent scrutiny, not just trust in the SUMMARY.
- The FK-drop migration (the flagged deviation) was read in full, cross-referenced against the original schema migration, and assessed as a sound, necessary, surgical fix — not a silent referential-integrity regression — per the detailed assessment above.
- The two post-merge test fixes (function_exported?/3 load-order flake fix via `Code.ensure_loaded?/1`, and relocating `embedder_test.exs` out of the knowledge-lane glob to `test/scoria/knowledge_embedder_test.exs`) were verified by reading the actual file and its content, and by confirming `knowledge_lane_contract_test.exs`'s `@expected_files` no longer references the old path (the file was moved, not merely re-listed) — neither fix weakens coverage; the embedder tests remain present, fast, and DB-free as intended.

---

*Verified: 2026-07-12T21:38:44Z*
*Verifier: Claude (gsd-verifier)*

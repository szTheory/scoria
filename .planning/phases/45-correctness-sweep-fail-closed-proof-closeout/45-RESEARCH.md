# Phase 45: Correctness sweep + fail-closed proof & closeout - Research

**Researched:** 2026-07-07
**Domain:** Elixir/Ecto pgvector retrieval scoring, eval scorer latency, fail-closed verdicting, deterministic ExUnit proof, and narrow doctrine documentation
**Confidence:** HIGH - scope and implementation surfaces were verified from phase context, planning docs, source code, local dependency docs, Hex package metadata, and local environment probes.

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this section: `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-CONTEXT.md` [VERIFIED: 45-CONTEXT.md].

### Locked Decisions

#### Phase Boundary

This phase closes the v3.4 P0 trust/security milestone by fixing four fake/misleading measurements discovered after Phases 42/43 and cross-linking the already-decided scope doctrine. It is a correctness/proof sweep, not a feature expansion.

In scope:
- Correctness fixes for retrieval score, citation presence, chunker overlap no-op, and eval latency gate.
- Focused regression tests proving fail-closed behavior and real measurement persistence.
- Narrow documentation/proof updates that confirm the scope doctrine is recorded and cross-linked.
- Closeout rationale for the fix milestone.

Out of scope:
- Hex 0.1.3 publish/release cut.
- Full docs overhaul or user-facing marketing updates.
- Semantic/faithfulness RAG eval beyond citation-presence label awareness.
- A real sliding-window/overlap chunker.
- Reranking, hybrid retrieval, or retrieval quality tuning.
- UI scope bars, tenant switching UI, or end-user auth policy.
- Live LLM calls in CI.

#### Hard Constraints

1. **Fix + prove only; no release.**
   - Do not publish Hex 0.1.3.
   - Do not change package version unless implementation tooling requires it, and that should be treated as suspicious.

2. **No live LLM calls in CI/tests.**
   - Proof must be deterministic and key-free.
   - Existing injected judge seams/stubs should be used for latency and verdict tests.

3. **No fake-green/fake measurements.**
   - Unknown/missing measurement must not silently become `passed`, `0.0`, or harmless default evidence.
   - Missing latency under a configured latency policy must fail closed as inconclusive.

4. **Scope doctrine remains the boundary.**
   - Scoria owns the verb; host owns the noun.
   - Scoria fixes recording/gating/filtering/scoring/proof mechanisms.
   - Host owns identity, business truth, policy values, and end-user semantics.

#### D-01 Pgvector Retrieval Score

Decision:
- Keep ordering on pgvector cosine-distance.
- Persist `score = 1 - cosine_distance`.
- Treat `RetrievalResult.score` as raw cosine similarity, not a probability.
- Do not clamp, round, normalize, or make anti-correlated vectors look prettier.
- Filter nil embeddings before ranking; do not return nil embedding rows with fabricated `0.0`.
- Invalid query vectors/dimension mismatches should fail loudly before retrieval rows are persisted.
- Prefer a DB-projected score in the retrieval query over reimplementing vector math in Elixir.

Rejected alternatives:
- Keep fake component-sum score for "relative" ranking.
- Use Euclidean distance or dot product.
- Normalize scores to 0..1 for display.

Proof expected:
- Backend fixture proving stored/persisted score matches the same cosine metric used for ordering.
- E2E `Knowledge.retrieve/2` persistence check.
- Tests for exact match, orthogonal vector, nil embedding exclusion, invalid query/dimension behavior.

#### D-02 Citation Presence Label Awareness

Decision:
- Add a no-schema label path to `Knowledge.Grounding.score_citation_presence`.
- Canonical label: `expected_answerable: true | false`.
- Accept string keys too.
- Compatibility alias `answerable` is acceptable if cheap.
- Missing label keeps legacy behavior so old callers do not get accidental passes.

Required matrix:
- answerable + citations => pass.
- answerable + empty citations => fail.
- unanswerable + empty citations => pass.
- unanswerable + citations => fail.
- missing label + empty citations => legacy fail.

Details should include:
- Citation count.
- Expected answerability when present.

Rejected alternatives:
- Parse natural-language refusal text.
- Add semantic abstention scoring.
- Introduce `not_scored` for correct abstention.
- Build a full label schema.

#### D-03 Chunker Overlap No-op Removal

Decision:
- Remove the dead `overlap = Keyword.get(opts, :overlap, 24)` parameter.
- Replace `max(chunk.end_offset - overlap, chunk.end_offset)` with `chunk.end_offset`.
- Document `Chunker.Default` as section/paragraph based and non-overlapping.
- Preserve deterministic offsets and digests.
- Existing callers that pass `overlap:` should not receive new overlapping behavior.

Rejected alternatives:
- Implement real overlapping chunks in this phase.
- Warn/raise on `overlap:` unless implementation risk is demonstrably low.
- Keep the option in docs for future use.

Deferred:
- Real overlapping chunker stays in SEED-009.

#### D-04 Real Latency Gate

Decision:
- Record real per-item scorer wall-clock latency in `ai_scores.metadata["latency_ms"]`.
- Use monotonic time with unit conversion.
- Keep `max_latency_ms` as a score-level threshold in `Scoria.Eval.Verdict.compute/2`, not whole-run duration.
- If `max_latency_ms` is configured and a scored item lacks parseable latency metadata, verdict should be `:inconclusive`.
- A measured `0` is allowed only if it comes from the real measurement seam.
- Also set `EvalRun.duration_ms` from a real whole-run timer, but do not use whole-run duration for the score latency gate.

Rejected alternatives:
- Keep hardcoded `0`.
- Use `DateTime.utc_now()` deltas.
- Sleep in tests to prove latency.
- Treat missing latency as `0`.
- Make latency gate depend on total eval run duration.

Proof expected:
- Runner/judge/online scoring tests with injected timing or deterministic seams.
- Verdict tests for over-threshold and missing-latency behavior.
- Persistence assertions showing metadata latency is present and non-fabricated.

#### D-05 Scope Doctrine Cross-links

Decision:
- Confirm `.planning/PROJECT.md ## Constraints` contains the P1-P6 doctrine.
- Confirm `.planning/PROJECT.md ## Key Decisions` includes the 2026-07-03 audit/doctrine decision and v3.4 fix-and-prove decision.
- Add short cross-links from eval/knowledge/dashboard/Phase 45 closeout rationale to the doctrine SSOT.

Cross-link themes:
- Eval: Scoria owns scoring/gating mechanisms, not policy/business truth.
- Knowledge: Scoria owns retrieval query/filtering/storage mechanics, not tenant identity truth.
- Dashboard: Scoria delegates authz to host but records trusted host-auth scope.
- Phase 45: closing the milestone means real measurements and no fake evidence.

Rejected alternatives:
- Full "owns vs delegates" table in docs.
- UI scope indicator or tenant switcher.
- Rewrite adoption docs broadly.

Proof expected:
- Source/doc contract test or equivalent checklist proving doctrine exists and closeout rationale links back.

### the agent's Discretion

- Private helper names for latency timing and label normalization.
- Exact Ecto query projection shape for pgvector score, as long as it uses the same DB cosine-distance metric as ordering.
- Test placement across existing knowledge/eval suites.
- Whether the citation label helper accepts atom-only booleans or also string booleans; prefer strict booleans unless compatibility pressure is visible.
- Which narrow docs receive cross-links, with likely targets: `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, and the Phase 45 closeout artifact.

### Deferred Ideas (OUT OF SCOPE)

- Hex 0.1.3 publish/release cut.
- Full docs overhaul.
- Semantic/faithfulness RAG evaluation.
- Real overlapping chunker.
- Reranking or hybrid retrieval.
- UI scope bars or tenant switching UI.
- Live LLM calls in CI.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | `Knowledge.Backends.Pgvector.score_chunk/2` persists a real cosine similarity matching `cosine_distance`; fake component-sum score is removed. [VERIFIED: REQUIREMENTS.md] | `similar_chunks/2` currently orders by `cosine_distance` but maps results through private `score_chunk/2`, which returns `0.0` for nil embeddings and otherwise computes `1.0 / (1.0 + abs(sum_delta))`; the planner should replace this with DB-projected `1 - cosine_distance` and proof tests. [VERIFIED: codebase grep] |
| FIX-02 | `Knowledge.Grounding.score_citation_presence` is label-aware so correct abstention on unanswerable queries is not penalized. [VERIFIED: REQUIREMENTS.md] | `score_citation_presence/1` currently only checks whether the `citations` list is empty and has no answerability label path; existing `GroundingScore.details` can carry citation count and label evidence. [VERIFIED: codebase grep] |
| FIX-03 | `Chunker.Default` dead `overlap` parameter is removed and documented as non-overlapping. [VERIFIED: REQUIREMENTS.md] | `Chunker.Default.chunk/2` currently reads `:overlap` and computes `max(chunk.end_offset - overlap, chunk.end_offset)`, which always equals `chunk.end_offset`; source search found no production caller relying on `overlap:`. [VERIFIED: codebase grep] |
| FIX-04 | `max_latency_ms` gate uses real recorded latency instead of hardcoded zero. [VERIFIED: REQUIREMENTS.md] | `Eval.Runner`, `Eval.JudgeRunner`, and `Eval.OnlineScoring` currently persist `metadata["latency_ms"]` as `0` and some `EvalRun.duration_ms` values as `0`; `Eval.Verdict` currently treats missing/invalid latency as zero. [VERIFIED: codebase grep] |
| DOC-01 | P1-P6 doctrine is confirmed in `.planning/PROJECT.md` constraints/key decisions and cross-linked from fix rationale. [VERIFIED: REQUIREMENTS.md] | `.planning/PROJECT.md` contains the P1-P6 scope doctrine under `## Constraints` and the 2026-07-03/v3.4 decisions under `## Key Decisions`; docs do not yet carry the narrow Phase 45 cross-links. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 45 is a narrow correctness and proof phase: it should remove fabricated retrieval and latency evidence, make citation presence respect an explicit answerability label, delete a dead chunker option, and close the v3.4 milestone with doctrine cross-links. [VERIFIED: 45-CONTEXT.md] The implementation should not add new external packages, change public release state, call live LLMs in CI, or expand product scope. [VERIFIED: 45-CONTEXT.md]

The highest-risk technical boundary is keeping measurement semantics aligned with the mechanism that produced the ranking or verdict. [VERIFIED: codebase grep] For FIX-01, ranking already uses the pgvector cosine operator, but persisted scores are currently recomputed with unrelated Elixir component-sum math; for FIX-04, verdict gating already has a latency policy hook, but the runners currently record hardcoded zero and the verdict parser defaults missing latency to zero. [VERIFIED: codebase grep]

**Primary recommendation:** Implement a repair-first plan that changes only existing retrieval, grounding, chunker, eval timing, verdict, and narrow docs surfaces, then prove each requirement with deterministic ExUnit tests and source/doc contract checks. [VERIFIED: 45-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Pgvector retrieval score persistence (FIX-01) | API / Backend | Database / Storage | Backend owns retrieval orchestration and persistence, while PostgreSQL/pgvector owns cosine-distance calculation used for ordering and score projection. [VERIFIED: codebase grep; VERIFIED: deps/pgvector] |
| Citation answerability label scoring (FIX-02) | API / Backend | Database / Storage | `Scoria.Knowledge.Grounding` owns scorer semantics and `GroundingScore.details` persists proof metadata. [VERIFIED: codebase grep] |
| Default chunker non-overlap cleanup (FIX-03) | API / Backend | Database / Storage | `Chunker.Default` owns chunk offset generation; persisted chunks and citations consume those offsets. [VERIFIED: codebase grep] |
| Real scorer latency and verdict gate (FIX-04) | API / Backend | Database / Storage | Eval runners produce score metadata, `Eval.Verdict` gates on score-level latency, and `EvalRun`/`Eval.Score` persist duration and metadata. [VERIFIED: codebase grep] |
| Scope doctrine confirmation and cross-links (DOC-01) | Docs / Planning | API / Backend and Dashboard Docs | `.planning/PROJECT.md` is the doctrine SSOT; eval, knowledge, and dashboard rationale links explain why mechanism belongs in Scoria and policy/noun ownership stays with the host. [VERIFIED: PROJECT.md; VERIFIED: 45-CONTEXT.md] |

## Project Constraint Discovery

No root `CLAUDE.md`, `.claude/CLAUDE.md`, or root `AGENTS.md` exists in this project checkout, and no project `SKILL.md` files were found under `.claude/skills` or `.agents/skills`. [VERIFIED: file search] Two `AGENTS.md` files exist only inside vendored example dependency paths and should not steer Phase 45 planning. [VERIFIED: file search]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime and test language for Phase 45 changes. [VERIFIED: `elixir --version`] | Existing project runtime and source language. [VERIFIED: mix.exs] |
| Erlang/OTP | 28 | BEAM runtime for Elixir and monotonic-time source. [VERIFIED: `elixir --version`; VERIFIED: `erl`] | Required by the locked local Elixir runtime. [VERIFIED: environment probe] |
| Ecto SQL | locked 3.13.5; recent 3.14.0 released 2026-05-19 | Query composition and SQL adapter layer. [VERIFIED: `mix deps`; VERIFIED: Hex metadata] | Existing DB stack for repository queries and persistence. [VERIFIED: mix.exs] |
| Postgrex | locked 0.22.1; recent 0.22.2 released 2026-05-12 | PostgreSQL driver. [VERIFIED: `mix deps`; VERIFIED: Hex metadata] | Existing Postgres driver used by Ecto. [VERIFIED: mix.exs] |
| pgvector Elixir | locked 0.3.1; recent 0.4.0 released 2026-06-04 | Ecto vector type and cosine-distance query macro. [VERIFIED: `mix deps`; VERIFIED: Hex metadata] | Existing package provides `Pgvector.new/1`, `Pgvector.to_list/1`, and `Pgvector.Ecto.Query.cosine_distance/2`; Phase 45 should use the DB operator rather than custom vector math. [VERIFIED: deps/pgvector] |
| ExUnit / Mix | 1.19.5 | Deterministic unit/integration tests and task execution. [VERIFIED: `mix --version`] | Existing project test framework; no new test runner required. [VERIFIED: test files] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExDoc | locked 0.40.3; released 2026-05-21 | Documentation generation and doc checks. [VERIFIED: `mix deps`; VERIFIED: Hex metadata] | Use only if planner adds docs-generation verification; not required for code proof. [VERIFIED: mix.exs] |
| Docker Desktop | 29.5.2 | Local service container runtime. [VERIFIED: `docker --version`; VERIFIED: `docker info`] | Available fallback for local Postgres/pgvector services if the current `localhost:55432` service is unavailable. [VERIFIED: environment probe] |
| PostgreSQL CLI | 14.17 | Local database readiness checks. [VERIFIED: `psql --version`; VERIFIED: `pg_isready`] | Use for pgvector lane availability checks before knowledge tests. [VERIFIED: environment probe] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| DB-projected `1 - cosine_distance` | Elixir-side cosine helper over `Pgvector.to_list/1` | Elixir helper would duplicate math and can drift from the DB operator used for ranking; context explicitly prefers DB projection. [VERIFIED: 45-CONTEXT.md; VERIFIED: deps/pgvector] |
| Strict boolean answerability labels | String boolean coercion such as `"true"` / `"false"` | Compatibility may improve, but context prefers no schema expansion and strict labels reduce accidental passes. [VERIFIED: 45-CONTEXT.md] |
| Injected deterministic timer seam | `Process.sleep/1` tests | Sleeps make tests slow and flaky; context explicitly rejects sleep-based latency proof. [VERIFIED: 45-CONTEXT.md] |

**Installation:**

```bash
# No new package installation is recommended for Phase 45.
mix deps.get
```

**Version verification:** Existing stack versions were verified with `mix deps`, `mix hex.info pgvector`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, `mix hex.info ex_doc`, `elixir --version`, and `mix --version`. [VERIFIED: environment probe]

## Package Legitimacy Audit

No external packages should be installed for Phase 45; the plan should use existing locked dependencies only. [VERIFIED: 45-CONTEXT.md; VERIFIED: mix.exs] Because no new package install is recommended, the package legitimacy gate has no packages to approve, remove, or flag. [VERIFIED: package audit]

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package audit]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: package audit]

## Architecture Patterns

### System Architecture Diagram

```text
Knowledge retrieve request
  -> Scope.from_opts! / Scope.visible_to
  -> Pgvector query filters nil embeddings and host-visible chunks
  -> PostgreSQL pgvector cosine_distance ranks rows
  -> Query projects score = 1 - cosine_distance
  -> RetrievalResult rows persist rank + raw cosine similarity

Grounding score request
  -> Normalize citation payload and expected_answerable label
  -> Apply answerable/unanswerable matrix
  -> Persist GroundingScore score/status/details

Eval run
  -> Runner/Judge/Online scorer executes through deterministic or injected seam
  -> Monotonic timer records per-score latency_ms
  -> Eval.Score persists metadata latency
  -> Eval.Verdict computes thresholds over scored items
  -> Missing parseable latency under max_latency_ms => inconclusive
  -> EvalRun stores real duration_ms and aggregate metadata

Docs/proof closeout
  -> Confirm PROJECT.md doctrine
  -> Add narrow links from eval/knowledge/dashboard/closeout rationale
  -> Contract test verifies doctrine SSOT and links
```

### Recommended Project Structure

```text
lib/scoria/
+-- knowledge/
|   +-- backends/pgvector.ex       # FIX-01 DB-projected retrieval score
|   +-- grounding.ex               # FIX-02 label-aware citation presence
|   +-- chunker.ex                 # FIX-03 non-overlap docs and offset cleanup
+-- eval/
    +-- runner.ex                  # FIX-04 offline scorer latency + run duration
    +-- judge_runner.ex            # FIX-04 injected-judge latency + run duration
    +-- online_scoring.ex          # FIX-04 online scorer latency + run duration
    +-- verdict.ex                 # FIX-04 fail-closed latency gate

test/scoria/
+-- knowledge/                     # pgvector, retrieval, grounding proof
+-- eval/                          # verdict and runner latency proof
+-- scope_doctrine_contract_test.exs # DOC-01 source/doc contract if added
```

### Pattern 1: DB-Projected Cosine Similarity

**What:** Rank with `cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding))` and persist `score = 1 - same_distance` from the query projection. [VERIFIED: 45-CONTEXT.md; VERIFIED: deps/pgvector]

**When to use:** Use for FIX-01 inside `Scoria.Knowledge.Backends.Pgvector.similar_chunks/2`, after `Scope.visible_to(scope)` and before result mapping. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: deps/pgvector/lib/pgvector/ecto/query.ex and current pgvector backend.
query_vector = Pgvector.new(query_embedding)

Chunk
|> Scope.visible_to(scope)
|> where([chunk], not is_nil(chunk.embedding))
|> maybe_filter_source(source_id)
|> order_by([chunk], asc: cosine_distance(chunk.embedding, ^query_vector))
|> select([chunk], {chunk, fragment("1.0 - (? <=> ?)", chunk.embedding, ^query_vector)})
|> limit(^limit)
```

Planning note: the exact Ecto projection can return either `{chunk, score}` or `{chunk, distance}` and compute `1 - distance` afterward; the important invariant is that the distance value comes from the same DB operator used for ordering. [VERIFIED: 45-CONTEXT.md]

### Pattern 2: Explicit Answerability Matrix

**What:** Normalize label input from atom or string keys and apply the five-row matrix from the context. [VERIFIED: 45-CONTEXT.md]

**When to use:** Use for `Knowledge.Grounding.score_citation_presence/1`; do not parse natural-language refusal text. [VERIFIED: 45-CONTEXT.md]

**Example:**

```elixir
# Source: 45-CONTEXT.md decision matrix.
case {expected_answerable(attrs), citation_count(attrs)} do
  {true, count} when count > 0 -> pass(count, true)
  {true, 0} -> fail(0, true)
  {false, 0} -> pass(0, false)
  {false, count} when count > 0 -> fail(count, false)
  {:missing, 0} -> legacy_fail(0)
  {:missing, count} when count > 0 -> legacy_pass(count)
end
```

### Pattern 3: Monotonic Timing With Injectable Tests

**What:** Measure scorer execution with monotonic time and convert elapsed native units to milliseconds before writing score metadata. [VERIFIED: local Elixir docs; VERIFIED: 45-CONTEXT.md]

**When to use:** Wrap each actual scorer call in `Eval.Runner`, `Eval.JudgeRunner`, and online deterministic/judge scoring paths. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Elixir System docs fetched locally with Code.fetch_docs(System).
start_time = System.monotonic_time()
result = run_scorer.()
elapsed_ms =
  System.monotonic_time()
  |> Kernel.-(start_time)
  |> System.convert_time_unit(:native, :millisecond)
```

Planning note: production code can use a small private helper or injectable timer function; tests should inject deterministic elapsed values instead of sleeping. [VERIFIED: 45-CONTEXT.md]

### Pattern 4: Fail-Closed Latency Gate

**What:** Treat missing or unparseable `metadata["latency_ms"]` as `:inconclusive` only when `max_latency_ms` is configured; over-threshold scored items fail. [VERIFIED: 45-CONTEXT.md]

**When to use:** Use inside `Scoria.Eval.Verdict.compute/2`, preserving Phase 42 behavior for empty/all-unscored/coverage-inconclusive cases. [VERIFIED: STATE.md; VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Phase 42 fail-closed verdict pattern plus Phase 45 D-04.
with {:ok, scored_items} <- require_scored_items(items),
     :ok <- require_latency_metadata_if_policy_configured(scored_items, policy),
     :ok <- enforce_latency_threshold(scored_items, policy) do
  passed_or_failed_from_score_thresholds(scored_items, policy)
else
  {:inconclusive, reason} -> %{status: :inconclusive, reason: reason}
  {:failed, reason} -> %{status: :failed, reason: reason}
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cosine similarity for pgvector retrieval | Elixir-side vector math or component-sum similarity | PostgreSQL pgvector `<=>` cosine-distance operator through `Pgvector.Ecto.Query.cosine_distance/2` and DB projection | Ordering already uses the DB operator, so persisted score must come from the same metric to avoid drift. [VERIFIED: codebase grep; VERIFIED: deps/pgvector] |
| Correct abstention semantics | Natural-language refusal parser or semantic answerability judge | Explicit `expected_answerable` boolean label matrix | Context requires deterministic, no-schema, no-live-LLM scoring. [VERIFIED: 45-CONTEXT.md] |
| Overlapping chunking | Sliding-window chunker or future `overlap:` option behavior | Current section/paragraph chunker with explicit non-overlap docs | Real overlap is deferred to SEED-009; this phase removes a fake option. [VERIFIED: 45-CONTEXT.md] |
| Latency measurement | `DateTime.utc_now()` deltas, sleeps, or hardcoded zero | `System.monotonic_time` plus `System.convert_time_unit` and injectable tests | Context rejects DateTime deltas, sleeps, and fake zero defaults. [VERIFIED: 45-CONTEXT.md; VERIFIED: local Elixir docs] |
| Scope doctrine docs | Broad ownership matrix, UI tenant switcher, or authz redesign | Narrow cross-links to `.planning/PROJECT.md` doctrine SSOT | DOC-01 is confirm-and-cross-link only. [VERIFIED: 45-CONTEXT.md; VERIFIED: PROJECT.md] |

**Key insight:** Phase 45 is about eliminating fake evidence at existing seams; custom new abstractions are only justified if they preserve deterministic proof and reduce repeated timing or label parsing code. [VERIFIED: 45-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Persisted score diverges from ranking metric

**What goes wrong:** Retrieval results rank by pgvector cosine distance but persist a different score, so downstream evidence is misleading. [VERIFIED: codebase grep]
**Why it happens:** Current `score_chunk/2` uses component sums and not vector cosine distance. [VERIFIED: codebase grep]
**How to avoid:** Project DB distance or score in the same query that orders results, then persist that projected value. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** `Enum.sum`, `Pgvector.to_list`, or `1.0 / (1.0 + ...)` remains in the pgvector backend scoring path. [VERIFIED: codebase grep]

### Pitfall 2: Nil embeddings become fake zero-score results

**What goes wrong:** A chunk with no embedding can be returned and persisted with fabricated `0.0` evidence. [VERIFIED: codebase grep]
**Why it happens:** Current private `score_chunk(nil, _)` returns `0.0`. [VERIFIED: codebase grep]
**How to avoid:** Filter `not is_nil(chunk.embedding)` before ordering and mapping results. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** `score_chunk(nil, _)` or similar default score remains after the fix. [VERIFIED: codebase grep]

### Pitfall 3: Cosine similarity gets normalized as if it were a probability

**What goes wrong:** Orthogonal or anti-correlated vectors are clamped or rounded into prettier values that no longer reflect raw cosine similarity. [VERIFIED: 45-CONTEXT.md]
**Why it happens:** UI-style display assumptions leak into backend evidence semantics. [VERIFIED: 45-CONTEXT.md]
**How to avoid:** Persist raw `1 - cosine_distance` without clamping, rounding, or probability wording. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** Code uses `max`, `min`, `Float.round`, or probability labels in retrieval score persistence. [VERIFIED: 45-CONTEXT.md]

### Pitfall 4: Missing latency silently passes as zero

**What goes wrong:** `max_latency_ms` passes because missing or invalid metadata is converted to `0`. [VERIFIED: codebase grep]
**Why it happens:** `Eval.Verdict.latency_ms/1` currently defaults missing/unparseable latency to zero. [VERIFIED: codebase grep]
**How to avoid:** Add an explicit configured-policy branch that marks missing/unparseable latency as `:inconclusive`. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** Tests can delete `metadata["latency_ms"]` under a configured `max_latency_ms` and still get `:passed`. [VERIFIED: codebase grep]

### Pitfall 5: Latency tests use sleeps or live providers

**What goes wrong:** Tests become slow, flaky, or require external API keys. [VERIFIED: 45-CONTEXT.md]
**Why it happens:** Wall-clock proof is tested through elapsed real time rather than an injected timing seam. [VERIFIED: 45-CONTEXT.md]
**How to avoid:** Inject a deterministic timer or clock sequence around scorer calls and assert persisted metadata. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** `Process.sleep`, live LLM configuration, or provider API keys appear in Phase 45 tests. [VERIFIED: 45-CONTEXT.md]

### Pitfall 6: Chunker cleanup accidentally creates overlap behavior

**What goes wrong:** Removing the no-op turns into a semantic chunking change or compatibility warning/raise. [VERIFIED: 45-CONTEXT.md]
**Why it happens:** The dead `overlap` option looks like unfinished functionality and invites feature work. [VERIFIED: codebase grep]
**How to avoid:** Only remove the read and no-op expression, document non-overlap, and preserve existing offsets/digests. [VERIFIED: 45-CONTEXT.md]
**Warning signs:** New tests assert overlapping spans or callers observe a new warning/exception for `overlap:`. [VERIFIED: 45-CONTEXT.md]

### Pitfall 7: Doctrine work expands into host policy

**What goes wrong:** DOC-01 becomes an authz redesign, UI scope feature, or full docs rewrite. [VERIFIED: 45-CONTEXT.md]
**Why it happens:** The doctrine is broad, but this phase only needs confirm-and-cross-link proof. [VERIFIED: 45-CONTEXT.md]
**How to avoid:** Keep links short and point to `.planning/PROJECT.md` as SSOT. [VERIFIED: PROJECT.md; VERIFIED: 45-CONTEXT.md]
**Warning signs:** Tasks mention UI tenant switching, end-user RBAC, or a full owns-vs-delegates table. [VERIFIED: 45-CONTEXT.md]

## Code Examples

Verified patterns from local sources:

### Pgvector Cosine Query Macro

```elixir
# Source: deps/pgvector/lib/pgvector/ecto/query.ex
defmacro cosine_distance(left, right) do
  quote do
    fragment("(? <=> ?)", unquote(left), unquote(right))
  end
end
```

Use this macro or the equivalent `<=>` fragment for both ordering and score projection. [VERIFIED: deps/pgvector]

### Existing Retrieval Persistence Flow

```elixir
# Source: lib/scoria/knowledge.ex
with {:ok, backend_results} <- backend.similar_chunks(query_embedding, retrieval_opts),
     {:ok, retrieval_run} <- create_retrieval_run(...),
     {:ok, results} <- append_retrieval_results(retrieval_run, backend_results) do
  {:ok, %{run: retrieval_run, results: results}}
end
```

FIX-01 should prove the backend-projected score is the value persisted through this existing flow. [VERIFIED: codebase grep]

### Existing Grounding Score Sink

```elixir
# Source: lib/scoria/knowledge.ex and lib/scoria/knowledge/grounding_score.ex
%{
  score_type: "citation_presence",
  score: citation_score.score,
  status: citation_score.status,
  details: citation_score.details
}
```

FIX-02 can include `citation_count` and `expected_answerable` in existing details without schema changes. [VERIFIED: codebase grep; VERIFIED: 45-CONTEXT.md]

### Existing Eval Verdict Entry Point

```elixir
# Source: lib/scoria/eval/verdict.ex
def compute(%Scoria.EvalRun{} = run, policy \\ %{}) do
  scores = run.ai_scores || []
  scored_items = Enum.filter(scores, &item_scored?/1)
  ...
end
```

FIX-04 should preserve Phase 42 all-unscored/empty fail-closed behavior while adding a missing-latency inconclusive branch when `max_latency_ms` is configured. [VERIFIED: STATE.md; VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed / Source | Impact |
|--------------|------------------|------------------------|--------|
| Retrieval persisted component-sum fake score. | Persist raw `1 - cosine_distance` from the DB metric used for ranking. | Required by Phase 45 D-01. [VERIFIED: 45-CONTEXT.md] | Retrieval evidence and ordering share one metric. [VERIFIED: 45-CONTEXT.md] |
| Empty citations always fail. | Empty citations pass only when `expected_answerable` is explicitly false. | Required by Phase 45 D-02. [VERIFIED: 45-CONTEXT.md] | Correct abstention on unanswerable cases is no longer mislabeled failure. [VERIFIED: REQUIREMENTS.md] |
| `overlap:` option exists but has no effect. | Default chunker is documented as non-overlapping and no longer reads a fake option. | Required by Phase 45 D-03. [VERIFIED: 45-CONTEXT.md] | Planner should not create overlap functionality in this phase. [VERIFIED: 45-CONTEXT.md] |
| Eval latency evidence is hardcoded `0`. | Score metadata stores measured per-item latency; missing latency under a configured gate is inconclusive. | Required by Phase 45 D-04. [VERIFIED: 45-CONTEXT.md] | Latency gates can fail closed instead of fake passing. [VERIFIED: 45-CONTEXT.md] |
| Scope doctrine exists in `.planning/PROJECT.md` but fix rationale lacks links. | Narrow eval/knowledge/dashboard/closeout links point back to doctrine SSOT. | Required by Phase 45 DOC-01. [VERIFIED: PROJECT.md; VERIFIED: 45-CONTEXT.md] | Milestone closeout explains why Scoria owns mechanisms and hosts own nouns/policy. [VERIFIED: 45-CONTEXT.md] |

**Deprecated/outdated:**
- `Knowledge.Backends.Pgvector.score_chunk/2` component-sum scoring is outdated and must be removed from the active path. [VERIFIED: codebase grep; VERIFIED: REQUIREMENTS.md]
- Hardcoded eval `latency_ms: 0` and `duration_ms: 0` are outdated for real scorer proof. [VERIFIED: codebase grep; VERIFIED: REQUIREMENTS.md]
- `Chunker.Default`'s `overlap` read is outdated because the expression is a no-op and overlap behavior is deferred. [VERIFIED: codebase grep; VERIFIED: 45-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | No `[ASSUMED]` claims are required for this research; findings are from project planning docs, source code, local dependency source, Hex metadata, and environment probes. [VERIFIED: research process] | All | Low; planner should still verify with tests before implementation merge. [VERIFIED: research process] |

## Open Questions (RESOLVED)

1. **Exact Ecto projection shape — RESOLVED**
   - What we know: `Pgvector.Ecto.Query.cosine_distance/2` expands to the PostgreSQL `<=>` operator, and the context requires DB-projected score. [VERIFIED: deps/pgvector; VERIFIED: 45-CONTEXT.md]
   - Resolution: Plan `45-01` requires the active retrieval query to select a DB-derived score equal to `1.0 - cosine_distance(chunk.embedding, ^query_vector)`, matching the same metric used for ordering. [VERIFIED: 45-01-PLAN.md]
   - Implementation constraint: Do not project distance for separate Elixir-side subtraction; keep the persisted score as DB-projected raw cosine similarity and prove it with persisted-score tests. [VERIFIED: 45-CONTEXT.md; VERIFIED: 45-01-PLAN.md]

2. **Timer helper placement — RESOLVED**
   - What we know: Three eval modules currently need measured latency and run duration changes. [VERIFIED: codebase grep]
   - Resolution: Plan `45-03` creates the shared internal helper `Scoria.Eval.Timing` in `lib/scoria/eval/timing.ex` with `mark/0`, `elapsed_ms/1`, and `measure/1`. [VERIFIED: 45-03-PLAN.md]
   - Implementation constraint: `Scoria.Eval.Runner`, `Scoria.Eval.JudgeRunner`, and `Scoria.Eval.OnlineScoring` should consume `Scoria.Eval.Timing` for measured score latency and whole-run duration instead of duplicating private timing helpers. [VERIFIED: 45-03-PLAN.md; VERIFIED: 45-04-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | All implementation and tests | yes | 1.19.5 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Test and task runner | yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| Erlang/OTP | Monotonic timing runtime | yes | 28 | None needed. [VERIFIED: `elixir --version`; VERIFIED: `erl`] |
| PostgreSQL CLI | Knowledge lane DB readiness | yes | 14.17 | Docker service if local process changes. [VERIFIED: `psql --version`] |
| Pgvector-enabled Postgres | Knowledge pgvector tests | yes | `localhost:55432` accepting connections and `mix scoria.pgvector.bootstrap --check` passed | Docker Desktop is available. [VERIFIED: `pg_isready`; VERIFIED: Mix task] |
| Docker | Optional service fallback | yes | 29.5.2 | Existing local Postgres service. [VERIFIED: `docker --version`; VERIFIED: `docker info`] |
| Context7 CLI | External docs lookup | no | - | Local dependency docs and Elixir runtime docs were used. [VERIFIED: `command -v ctx7`] |

**Missing dependencies with no fallback:** none. [VERIFIED: environment probe]

**Missing dependencies with fallback:**
- Context7 CLI is unavailable; local `deps/pgvector` source, local Elixir docs, Hex metadata, and project code were sufficient for this phase. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix 1.19.5. [VERIFIED: `mix --version`; VERIFIED: test files] |
| Config file | `test/test_helper.exs`; knowledge lane uses `Scoria.KnowledgeCase` and pgvector bootstrap helpers. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` [VERIFIED: test files] |
| Knowledge run command | `mix test.knowledge --warnings-as-errors` after pgvector readiness check. [VERIFIED: test/scoria/knowledge_lane_contract_test.exs; VERIFIED: Mix task] |
| Full suite command | `mix test --warnings-as-errors` plus `mix test.knowledge --warnings-as-errors` for pgvector coverage. [VERIFIED: test files; VERIFIED: knowledge lane contract] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FIX-01 | DB-ranked retrieval persists raw cosine similarity and excludes nil embeddings. [VERIFIED: 45-CONTEXT.md] | integration | `SCORIA_TEST_INCLUDE_KNOWLEDGE=true mix test test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/retrieval_test.exs --warnings-as-errors` | Existing files yes; new cases needed. [VERIFIED: test files] |
| FIX-02 | Citation presence respects `expected_answerable` matrix and persists details. [VERIFIED: 45-CONTEXT.md] | unit/integration | `mix test test/scoria/knowledge/grounding_test.exs --warnings-as-errors` | Existing file yes; new cases needed. [VERIFIED: test files] |
| FIX-03 | Default chunker ignores/removes fake overlap and remains deterministic/non-overlapping. [VERIFIED: 45-CONTEXT.md] | unit/source contract | `mix test test/scoria/knowledge_test.exs --warnings-as-errors` | Existing file yes; new cases needed. [VERIFIED: test files] |
| FIX-04 | Runner/judge/online scorers persist real latency; verdict fails closed on missing latency under policy. [VERIFIED: 45-CONTEXT.md] | unit/integration | `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/online_scoring_test.exs --warnings-as-errors` | Existing files yes; new cases needed. [VERIFIED: test files] |
| DOC-01 | PROJECT doctrine exists and docs/source rationale link back to doctrine SSOT. [VERIFIED: 45-CONTEXT.md] | source/doc contract | `mix test test/scoria/scope_doctrine_contract_test.exs --warnings-as-errors` | File likely needs Wave 0 creation. [VERIFIED: test file search] |

### Sampling Rate

- **Per task commit:** Run the smallest changed-file command from the table above. [VERIFIED: validation plan]
- **Per wave merge:** Run `mix test --warnings-as-errors` and `mix test.knowledge --warnings-as-errors`. [VERIFIED: validation plan]
- **Phase gate:** Pgvector readiness check, full non-knowledge suite, full knowledge lane, and source scans for fake-score/fake-latency leftovers. [VERIFIED: validation plan]

### Wave 0 Gaps

- [ ] Extend `test/scoria/knowledge/pgvector_test.exs` for exact/orthogonal/nil/dimension behavior. [VERIFIED: test files]
- [ ] Extend `test/scoria/knowledge/retrieval_test.exs` for persisted score matching backend cosine score. [VERIFIED: test files]
- [ ] Extend `test/scoria/knowledge/grounding_test.exs` for answerability matrix and details. [VERIFIED: test files]
- [ ] Extend `test/scoria/knowledge_test.exs` for non-overlap offset/digest stability. [VERIFIED: test files]
- [ ] Extend `test/scoria/eval/verdict_test.exs` for over-threshold and missing/invalid latency. [VERIFIED: test files]
- [ ] Extend `test/scoria/eval/offline_runner_test.exs`, `judge_runner_test.exs`, and `online_scoring_test.exs` for measured latency and duration persistence through deterministic seams. [VERIFIED: test files]
- [ ] Add `test/scoria/scope_doctrine_contract_test.exs` or equivalent doc/source contract for DOC-01. [VERIFIED: test file search]
- [ ] Add source-scan verification that active code no longer contains component-sum scoring, `score_chunk(nil, _)` fake zero, hardcoded scorer latency `0`, or the chunker no-op expression. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 45 does not implement authentication; Phase 44 documents host-owned auth seam. [VERIFIED: STATE.md; VERIFIED: 45-CONTEXT.md] |
| V3 Session Management | no | Phase 45 does not manage sessions. [VERIFIED: 45-CONTEXT.md] |
| V4 Access Control | yes | Preserve `Scope.visible_to(scope)` before retrieval ranking/filtering and keep tenant isolation from Phase 43. [VERIFIED: STATE.md; VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate answerability labels strictly, fail loudly on invalid query vectors/dimensions, and parse latency metadata explicitly. [VERIFIED: 45-CONTEXT.md] |
| V6 Cryptography | no | No new cryptography is introduced. [VERIFIED: 45-CONTEXT.md] |
| V7 Error Handling and Logging | yes | Missing latency under configured policy should return inconclusive rather than fake pass; invalid vector retrieval should fail before persisted rows. [VERIFIED: 45-CONTEXT.md] |

### Known Threat Patterns for Scoria Phase 45

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant retrieval leakage through score/ranking changes | Information Disclosure | Keep `Scope.visible_to(scope)` before source filters, ranking, and limit; preserve Phase 43 tenant isolation tests. [VERIFIED: STATE.md; VERIFIED: codebase grep] |
| Fabricated retrieval score evidence | Tampering / Repudiation | Project score from the same DB cosine-distance metric used for ordering and test persisted values. [VERIFIED: 45-CONTEXT.md; VERIFIED: deps/pgvector] |
| Fabricated latency evidence | Tampering / Repudiation | Measure scorer latency with monotonic time and make missing latency inconclusive under configured latency policy. [VERIFIED: 45-CONTEXT.md; VERIFIED: local Elixir docs] |
| Accidental abstention pass without label | Tampering | Keep missing-label legacy behavior so empty citations still fail unless `expected_answerable: false` is explicit. [VERIFIED: 45-CONTEXT.md] |
| Scope creep into host policy | Elevation of Privilege / Authorization Boundary Confusion | Link docs to P1-P6 doctrine and do not implement host authz/policy values in Scoria. [VERIFIED: PROJECT.md; VERIFIED: 45-CONTEXT.md] |

## Phase 42 and Phase 43 Dependency Preservation

Phase 42 completed the fail-closed eval spine: empty/all-unscored/strict coverage violations are inconclusive, and only persisted `"passed"` non-blocking release verdicts count as green. [VERIFIED: STATE.md] Phase 45 must extend that spine for latency without regressing the Phase 42 verdict semantics. [VERIFIED: 45-CONTEXT.md]

Phase 43 completed knowledge tenant-isolation foundations, including scoped pgvector visibility before source filters and ranking. [VERIFIED: STATE.md] Phase 45 must change score projection without weakening `Scope.visible_to(scope)` ordering, source filters inside scope, or tenant isolation tests. [VERIFIED: codebase grep; VERIFIED: 45-CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/45-correctness-sweep-fail-closed-proof-closeout/45-CONTEXT.md` - locked decisions, out-of-scope boundaries, proof expectations. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - FIX-01, FIX-02, FIX-03, FIX-04, DOC-01 requirement text. [VERIFIED: file read]
- `.planning/STATE.md` - Phase 42/43/44 completion state and v3.4 release gate decisions. [VERIFIED: file read]
- `.planning/PROJECT.md` - P1-P6 scope doctrine and key decisions. [VERIFIED: file read]
- `lib/scoria/knowledge/backends/pgvector.ex`, `lib/scoria/knowledge/grounding.ex`, `lib/scoria/knowledge/chunker.ex`, `lib/scoria/knowledge.ex` - knowledge implementation surfaces. [VERIFIED: codebase grep]
- `lib/scoria/eval/runner.ex`, `lib/scoria/eval/judge_runner.ex`, `lib/scoria/eval/online_scoring.ex`, `lib/scoria/eval/verdict.ex`, `lib/scoria/eval.ex` - eval latency/verdict implementation surfaces. [VERIFIED: codebase grep]
- `test/scoria/**` - existing ExUnit proof surfaces and Wave 0 gaps. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- `deps/pgvector/README.md` and `deps/pgvector/lib/pgvector/ecto/query.ex` - local dependency docs/source for Ecto vector query support and cosine-distance macro. [VERIFIED: local dependency source]
- Local Elixir docs fetched with `Code.fetch_docs(System)` - monotonic-time and unit-conversion behavior. [VERIFIED: local runtime docs]
- `mix hex.info pgvector`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, `mix hex.info ex_doc` - package metadata, locked versions, recent release dates, downloads, and source links. [VERIFIED: Hex metadata]

### Tertiary (LOW confidence)

- GSD research cache entries for local findings were stored with provider `local`; the classification seam reported LOW for that provider even though the underlying evidence is local source/planning docs. [VERIFIED: gsd-tools output]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified from local runtime, `mix deps`, and Hex metadata; no new package install is recommended. [VERIFIED: environment probe]
- Architecture: HIGH - all target modules and persistence sinks were verified in source code and constrained by locked phase decisions. [VERIFIED: codebase grep; VERIFIED: 45-CONTEXT.md]
- Pitfalls: HIGH - pitfalls map directly to current code behavior or explicit rejected alternatives. [VERIFIED: codebase grep; VERIFIED: 45-CONTEXT.md]

**Research date:** 2026-07-07
**Valid until:** 2026-08-06 for codebase-specific planning; re-check dependency versions if planning is delayed or if Phase 45 becomes a dependency-upgrade phase. [VERIFIED: research process]

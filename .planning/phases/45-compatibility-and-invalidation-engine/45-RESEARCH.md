# Phase 45: Compatibility and invalidation engine - Research

**Researched:** 2026-05-25
**Domain:** Semantic-cache compatibility, invalidation, and conservative semantic lookup in Elixir/Phoenix/Postgres [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Similarity posture
- **D-01:** Phase 45 should keep exact-text lookup as the safest first hit path, then add a semantic fallback only after tenant, lane, scope, status, freshness, prompt, policy, and source filters have already reduced the candidate set.
- **D-02:** Semantic lookup should remain exact-first `pgvector` search inside Postgres/Ecto rather than ANN-first retrieval. Recall and explainability are more important than hit rate in `v2.1`.
- **D-03:** Similarity is the last compatibility gate, not the first. A candidate must already be partition-compatible and compatibility-compatible before similarity is considered.
- **D-04:** The default posture for this milestone is false negatives over false positives. Missing a reusable answer is acceptable; serving a wrong cached answer is not.
- **D-05:** Session continuity is not a semantic reuse boundary. Reuse remains tenant-rooted and may narrow to actor scope, but never widens from actor-scoped history into tenant-shared reuse.

### Compatibility contract
- **D-06:** Lookup outcomes must become stage-separated and support-friendly: eligibility bypass, lookup miss, lookup reject, or hit. Scoria should stop collapsing true compatibility failures into plain misses.
- **D-07:** `eligibility_reason_code` remains reserved for pre-lookup bypasses such as `lane_not_registered`, `tenant_scope_missing`, `approval_required`, `write_side_step_present`, `personalized_tool`, and `query_text_missing`.
- **D-08:** `lookup_reason_code` should only describe post-candidate compatibility rejection, with stable codes such as `prompt_version_mismatch`, `policy_mismatch`, `source_fingerprint_mismatch`, `scope_mismatch`, `entry_stale`, and `entry_invalidated`.
- **D-09:** `lookup_status=miss` means no reusable compatible candidate existed. It should not be overloaded to hide stale or incompatible candidates.
- **D-10:** Scoria may derive an internal compatibility fingerprint for efficient matching and fan-out, but that fingerprint is an implementation detail, not the primary external explanation surface.

### Invalidation and freshness
- **D-11:** Phase 45 should use a hybrid model: hard invalidation for provable incompatibility plus a conservative soft freshness window for age-based decay.
- **D-12:** Persisted entry lifecycle states for this phase should be `active`, `stale`, `invalidated`, and existing `writeback_rejected`. `stale` and `invalidated` are both non-reusable and fall through to the normal runtime path.
- **D-13:** Hard invalidation must be explicit and reason-coded when prompt version changes, policy compatibility changes, source fingerprint changes, or an operator explicitly revokes an entry.
- **D-14:** Freshness expiry should transition entries to `stale` with a stable reason such as `freshness_window_elapsed`, not silently disappear into a generic miss.
- **D-15:** `invalidated` is reserved for provable incompatibility, not mere age. Age-based decay and semantic incompatibility are distinct truths and must stay distinct in persisted state.

### Compatibility inputs
- **D-16:** `source_fingerprint` must be derived from durable source-version and source-digest truth, not ad hoc text snapshots or lossy heuristics.
- **D-17:** Policy compatibility should be stronger than `policy_key` alone. Phase 45 should persist and compare a stable policy fingerprint or equivalent compatibility snapshot so silent policy-semantic drift does not leave old answers reusable.
- **D-18:** Prompt compatibility should fence on explicit prompt identity and version, reusing the normalized runtime metadata surfaces already present in Scoria.
- **D-19:** Similarity thresholds should default conservatively and stay shift-left inside Scoria/GSD. Threshold tuning, rerankers, and lane-specific controls are deferred unless they materially change product behavior or blast radius.

### Product posture and defaults
- **D-20:** Low-impact cache mechanics should be shifted left into Scoria and future GSD flows. Later discuss/planning steps should not re-ask about ANN, stale-while-revalidate, per-lane tuning UI, or background refresh unless the choice changes product shape, security, durable truth, tenant blast radius, or major operator UX.
- **D-21:** Phase 45 should preserve the embedded-library shape: one boring Ecto/Postgres truth path, explicit reason codes, explicit fallback, and no hosted cache tier or invisible middleware semantics.

### Claude's Discretion
- Exact schema field names for policy compatibility snapshot/fingerprint as long as the stronger-than-`policy_key` contract remains intact.
- Exact freshness window defaults per lane, provided they remain conservative and fail closed.
- Exact internal query/ranking implementation for the semantic fallback, provided it stays exact-first, filter-first, and explainable.
- Exact internal representation of stage-separated outcomes in Elixir structs/tuples, provided persisted/operator-facing reason codes remain stable.

### Deferred Ideas (OUT OF SCOPE)
- ANN indexes, HNSW/IVFFlat tuning, and broad scaling controls.
- Per-lane threshold tuning UI or public advanced similarity controls.
- Stale-while-revalidate serving, background refresh workers, and asynchronous refresh orchestration.
- Persisted miss/reject ledgers for every lookup and richer analytics-heavy cache dashboards.
- External cache backends, hosted cache services, or cross-runtime cache federation.
- Bulk epoch/generation invalidation machinery unless later phases prove that simple explicit invalidation is operationally insufficient.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOOK-01 | Scoria reuses a cached answer only when semantic similarity, prompt compatibility, policy compatibility, and source compatibility all pass. [VERIFIED: .planning/REQUIREMENTS.md] | Filter-first lookup pipeline, exact-first pgvector fallback, policy snapshot/fingerprint, source fingerprint derived from durable source facts, explicit prompt/version fence. [VERIFIED: codebase grep] [CITED: https://github.com/pgvector/pgvector] |
| LOOK-02 | Cache miss, stale, or rejected outcomes fall through to the normal execution path without changing workflow truth. [VERIFIED: .planning/REQUIREMENTS.md] | Stage-separated outcomes in runtime metadata, persisted `stale` and `invalidated` states, no hidden hit-on-reject behavior. [VERIFIED: codebase grep] |
| INVD-01 | Cache entries invalidate when prompt version, source fingerprint, or policy compatibility changes. [VERIFIED: .planning/REQUIREMENTS.md] | Transactional bulk state transition plus append-only events using `Ecto.Multi.update_all/4` and reason-coded invalidation. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| INVD-02 | Developers and operators can distinguish active, stale, and invalidated cache entries with explicit reasons. [VERIFIED: .planning/REQUIREMENTS.md] | Entry status expansion, stable reason taxonomy, and no collapsing of stale/incompatible rows into plain misses. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 45 should stay inside the existing Scoria semantic-cache seam and add three things, not a new subsystem: a filter-first semantic lookup path, explicit lifecycle state transitions, and explicit invalidation fan-out. `Scoria.SemanticCache.lookup/1` is currently exact-text plus equality filters on active/non-expired rows, and `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1` currently exposes only `bypass`, `miss`, or `hit`, so this phase is extending an existing contract rather than inventing a second cache plane. [VERIFIED: codebase grep]

The safest implementation is: keep exact `query_text` as the first lookup, run compatibility filters before any vector ranking, then use pgvector exact nearest-neighbor ordering only inside the already-filtered partition. pgvector’s official guidance says exact indexes work well when conditions match a low percentage of rows, and warns that approximate HNSW/IVFFlat filtering happens after index scan and can return fewer matching rows unless tuned. [CITED: https://github.com/pgvector/pgvector] That matches the user’s locked exact-first, false-negative-biased posture. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]

The planner should treat invalidation as durable state mutation, not lookup-time inference. `Scoria.SemanticCache.Entry` currently supports `active`, `writeback_rejected`, `invalidated`, and `expired`, but the phase requirement needs `stale` to be a first-class persisted truth with explicit reasons, and current tests do not yet cover stale/reject/invalidate fan-out semantics. [VERIFIED: codebase grep]

**Primary recommendation:** Use `Scoria.SemanticCache` as the single context, add a `Lookup`/`Compatibility` split plus transactional invalidation helpers, and implement `exact_text_hit -> compatible semantic fallback -> reason-coded fallthrough` with `active/stale/invalidated/writeback_rejected` as persisted states. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Eligibility bypass and scope narrowing | API / Backend | Database / Storage | `Scoria.SemanticCache.Eligibility` already derives tenant/actor scope and bypass reasons before DB lookup. [VERIFIED: codebase grep] |
| Compatibility lookup and outcome shaping | API / Backend | Database / Storage | `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1` owns lookup orchestration, while `Scoria.SemanticCache.lookup/1` owns persisted candidate retrieval. [VERIFIED: codebase grep] |
| Semantic similarity ranking | Database / Storage | API / Backend | pgvector ordering happens in SQL/Ecto queries, and the existing knowledge backend already uses `Pgvector.Ecto.Query` distance functions in Repo queries. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/pgvector/readme.html] |
| Invalidation and stale state transitions | API / Backend | Database / Storage | The state change should be orchestrated in Scoria code and executed transactionally as row updates plus appended events. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Operator-visible truth for later phases | Database / Storage | API / Backend | Phase 45 must persist stable status and reason codes so Phase 46 can project them without inventing a second model. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | locked `3.13.5`; latest `3.14.0` published 2026-05-19 [VERIFIED: mix hex.info ecto_sql] | Transactional state transitions and migrations. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | `Ecto.Multi` supports grouped repo operations, `run`, and `update_all`, which fits entry+event invalidation fan-out exactly. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `pgvector` | locked/latest `0.3.1` published 2025-06-23 [VERIFIED: mix hex.info pgvector] | Exact-first semantic ranking in Postgres through Ecto. [CITED: https://hexdocs.pm/pgvector/readme.html] | The current repo already depends on it and uses `Pgvector.Ecto.Query` for cosine-distance ordering. [VERIFIED: codebase grep] |
| `postgrex` + Postgres `vector` extension | locked `0.22.1`; latest `0.22.2` published 2026-05-12 [VERIFIED: mix hex.info postgrex] | Database transport plus vector extension support. [CITED: https://hexdocs.pm/pgvector/readme.html] | The repo defines `Scoria.PostgrexTypes` with `Pgvector.extensions()` and the local `scoria_test` database on `5432` currently has the `vector` extension enabled. [VERIFIED: codebase grep] [VERIFIED: psql query] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix` | locked/latest `1.8.7` published 2026-05-06 [VERIFIED: mix hex.info phoenix] | Runtime metadata projection and later operator surface reuse. [VERIFIED: codebase grep] | Use existing runtime/workflow DTO seams; Phase 45 should not add UI-specific cache logic. [VERIFIED: .planning/ROADMAP.md] |
| Internal `Scoria.PromptPolicy` | current repo module [VERIFIED: codebase grep] | Canonical normalized prompt/policy metadata. [VERIFIED: codebase grep] | Use as the source for compatibility snapshot inputs before computing any derived policy fingerprint/snapshot. [VERIFIED: codebase grep] |
| Internal `Scoria.Knowledge.Source` | current repo module [VERIFIED: codebase grep] | Durable source `version` and `digest` truth. [VERIFIED: codebase grep] | Use when building `source_fingerprint`; do not hash raw prompt text or transient payloads. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Exact-first pgvector lookup | HNSW / IVFFlat approximate indexes | pgvector docs warn filtered approximate scans can miss matches unless tuned; that conflicts with the phase’s false-negative-over-false-positive posture. [CITED: https://github.com/pgvector/pgvector] |
| Durable row state + events | TTL-only lookup rejection | TTL-only handling hides why reuse failed and cannot satisfy explicit `stale` vs `invalidated` truth. [VERIFIED: .planning/REQUIREMENTS.md] |
| `Ecto.Multi` row update + event append | Ad hoc sequential Repo calls | `Ecto.Multi` gives atomic grouped operations and explicit failure handling for state transition fan-out. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

**Installation:** Phase 45 needs no new Hex dependency; it should reuse the existing `pgvector`, `ecto_sql`, and `postgrex` stack already present in `mix.exs`. [VERIFIED: codebase grep]

```bash
mix deps.get
mix ecto.migrate
```

**Version verification:** [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info pgvector] [VERIFIED: mix hex.info postgrex]

```bash
mix hex.info ecto_sql
mix hex.info pgvector
mix hex.info postgrex
```

## Architecture Patterns

### System Architecture Diagram

The phase should follow this flow. [VERIFIED: codebase grep] [CITED: https://github.com/pgvector/pgvector]

```text
Runtime.start_run/input
  -> Runtime.Params normalizes runtime metadata
  -> Workflows.Runtime.prepare_semantic_fast_path/1
    -> SemanticCache.Eligibility.evaluate/1
      -> bypass => normal execution path
      -> eligible => SemanticCache.Lookup.lookup/1
        -> exact query_text + compatibility filters
          -> active compatible row => hit
          -> none => semantic fallback on filtered candidate set
            -> compatible nearest row => hit
            -> stale/invalidated/incompatible row => reject with reason
            -> no candidate => miss
  -> normal execution path on bypass/miss/reject/stale
  -> writeback on successful safe completion
  -> SemanticCache.Invalidation transition(s) on prompt/policy/source change
    -> update affected rows
    -> append entry events
```

### Recommended Project Structure

```text
lib/scoria/
├── semantic_cache.ex                    # public context API and common helpers
├── semantic_cache/eligibility.ex        # pre-lookup bypass and scope rules
├── semantic_cache/entry.ex              # entry schema
├── semantic_cache/entry_event.ex        # append-only lifecycle events
├── semantic_cache/lookup.ex             # exact-hit + semantic-fallback candidate selection
├── semantic_cache/compatibility.ex      # prompt/policy/source/freshness checks
└── semantic_cache/invalidation.ex       # stale/invalidate fan-out helpers
```

This split matches the repo’s current explicit-module pattern and keeps Phase 45 additions adjacent to existing `Scoria.SemanticCache` rather than spreading logic across runtime and knowledge contexts. [VERIFIED: codebase grep]

### Pattern 1: Stage-Separated Lookup Outcome
**What:** Represent semantic lookup as `bypass | miss | reject | hit`, with `lookup_reason_code` only for post-candidate rejections and `eligibility_reason_code` only for pre-lookup bypasses. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]

**When to use:** Always in `prepare_semantic_fast_path/1` and any helper it delegates to. [VERIFIED: codebase grep]

**Example:**
```elixir
case Eligibility.evaluate(facts) do
  {:bypass, code} -> {:continue, put_state(attrs, "bypass", Atom.to_string(code))}
  {:eligible, lookup_attrs} ->
    case Lookup.lookup(lookup_attrs) do
      {:hit, entry} -> {:hit, put_state(attrs, "hit", nil), entry}
      {:reject, reason, candidate} -> {:continue, put_reject_state(attrs, reason, candidate)}
      :miss -> {:continue, put_state(attrs, "miss", nil)}
    end
end
```
Source pattern: current runtime fast-path seam and explicit tuple-based outcomes. [VERIFIED: codebase grep]

### Pattern 2: Transactional State Transition Plus Event Append
**What:** Update rows and append entry events in one transaction for `stale`, `invalidated`, and `reused` transitions. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**When to use:** Any bulk invalidation or stale-marking path, and any lookup path that upgrades state before falling through. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```elixir
Ecto.Multi.new()
|> Ecto.Multi.update_all(:entries, invalidation_query, set: [status: "invalidated", invalidated_at: now])
|> Ecto.Multi.run(:events, fn repo, %{entries: {count, _}} ->
  insert_invalidation_events(repo, count, reason_code, metadata)
end)
|> Repo.transact()
```
Source pattern: `Ecto.Multi.update_all/4` and `run/3` transaction semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Anti-Patterns to Avoid
- **ANN-first retrieval:** Approximate filtered scans can miss expected matches and are explicitly deferred by user decision. [CITED: https://github.com/pgvector/pgvector] [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
- **TTL-only invalidation:** Phase 45 needs explicit `stale` vs `invalidated` truth, not silent exclusion by `expires_at`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]
- **Compatibility after similarity:** The user locked similarity as the last gate, and the repo already has strong partition/policy/prompt metadata available before ranking. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] [VERIFIED: codebase grep]
- **Splitting truth across contexts:** `Scoria.SemanticCache` already owns entry/event persistence and should remain the single context for this phase. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Vector distance and ranking | Custom Elixir similarity math in memory | `Pgvector.Ecto.Query` distance functions in SQL | The repo already uses pgvector query helpers, and the official docs provide the supported distance operators. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/pgvector/readme.html] |
| Transactional fan-out for invalidation | Sequential `Repo.update`/`Repo.insert` calls with manual rollback logic | `Ecto.Multi` with `update_all` and `run` | The docs define atomic grouped operations and failure propagation explicitly. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Hidden in-memory cache state | ETS/process cache invalidation truth | Existing `ai_semantic_cache_entries` + `ai_semantic_cache_entry_events` tables | The milestone is explicitly Ecto/Postgres truth, not middleware-local behavior. [VERIFIED: .planning/PROJECT.md] [VERIFIED: codebase grep] |
| Prompt/policy/source provenance guesses | Free-text metadata comparisons at lookup time | Stable persisted snapshot fields and derived fingerprints from normalized metadata | Current code already normalizes prompt policy and persists durable source version/digest facts. [VERIFIED: codebase grep] |

**Key insight:** The tricky part of this phase is not vector math; it is preserving inspectable compatibility truth under change, so planner tasks should bias toward schema/state/event work before tuning similarity. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md]

## Common Pitfalls

### Pitfall 1: Collapsing reject/stale into `miss`
**What goes wrong:** Support surfaces cannot explain whether Scoria found a row and refused it or found nothing at all. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
**Why it happens:** The current runtime seam only persists `bypass`, `miss`, or `hit` states. [VERIFIED: codebase grep]
**How to avoid:** Introduce a distinct lookup reject outcome with stable `lookup_reason_code` values and preserve `stale`/`invalidated` as entry states. [VERIFIED: .planning/REQUIREMENTS.md]
**Warning signs:** Tests only assert `:miss` or `{:hit, entry}` and never assert reject reasons or persisted `stale` rows. [VERIFIED: codebase grep]

### Pitfall 2: Relying on `policy_key` alone
**What goes wrong:** Policy semantics can drift while the same key keeps matching, making an old answer look reusable. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
**Why it happens:** `Scoria.PromptPolicy` currently normalizes richer fields than `policy_key`, but `Scoria.SemanticCache` currently filters only by `policy_key`. [VERIFIED: codebase grep]
**How to avoid:** Persist either a compatibility snapshot, a derived fingerprint, or both, and compare that stronger signal at lookup time. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
**Warning signs:** Invalidation code only matches `policy_key` and tests do not cover semantic policy drift. [VERIFIED: codebase grep]

### Pitfall 3: Using approximate ANN under heavy filters
**What goes wrong:** Filtered queries return fewer matches than expected, which looks like conservative behavior but is actually retrieval-quality loss. [CITED: https://github.com/pgvector/pgvector]
**Why it happens:** pgvector applies filters after approximate index scan for HNSW/IVFFlat unless additional tuning is used. [CITED: https://github.com/pgvector/pgvector]
**How to avoid:** Keep this phase exact-first and filter-first. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
**Warning signs:** Planner tasks start talking about HNSW/IVFFlat, probes, or iterative scans in Phase 45. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]

### Pitfall 4: Assuming the current test lane is environment-clean
**What goes wrong:** Targeted tests fail before phase logic runs because the compiled repo expects a different DB port than the current runtime config. [VERIFIED: mix test]
**Why it happens:** This checkout is compiled with `Scoria.Repo` port `55432`, while current runtime defaults point at `5432`; `5432` is live and has `vector`, but `55432` is not responding right now. [VERIFIED: mix test] [VERIFIED: pg_isready] [VERIFIED: psql query]
**How to avoid:** Either bootstrap/reuse the `55432` pgvector service or recompile the repo against `5432` before using semantic-cache verification commands. [VERIFIED: codebase grep]
**Warning signs:** Mix raises `different value set for key Scoria.Repo during runtime compared to compile time`. [VERIFIED: mix test]

## Code Examples

Verified patterns from official sources:

### pgvector nearest-neighbor ordering in Ecto
```elixir
import Ecto.Query
import Pgvector.Ecto.Query

Repo.all(
  from i in Item,
    order_by: cosine_distance(i.embedding, ^Pgvector.new(query_embedding)),
    limit: 5
)
```
Source: `pgvector-elixir` Ecto example. [CITED: https://hexdocs.pm/pgvector/readme.html]

### `Ecto.Multi` update-and-append transaction
```elixir
Ecto.Multi.new()
|> Ecto.Multi.run(:post, fn repo, _changes ->
  case repo.get(Post, 1) do
    nil -> {:error, :not_found}
    post -> {:ok, post}
  end
end)
|> Ecto.Multi.update_all(:update_all, fn %{post: post} ->
  from(c in Comment, where: c.post_id == ^post.id, update: [set: [title: "New title"]])
end, [])
|> MyApp.Repo.transact()
```
Source: `Ecto.Multi.update_all/4` documentation. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Exact `query_text` equality only | Exact `query_text` first, then semantic fallback on already-filtered candidate sets | Phase 45 design target on 2026-05-25. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] | Preserves explainability while adding conservative reuse. [VERIFIED: .planning/ROADMAP.md] |
| Approximate filtered ANN without extra tuning | Exact-first default; ANN remains deferred | pgvector documents filtered ANN caveats and iterative scan tuning in current README. [CITED: https://github.com/pgvector/pgvector] | Keeps false positives and silent recall loss out of the first shipped invalidation engine. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] |
| `expired`/implicit exclusion semantics | Explicit `stale` vs `invalidated` persisted truth | Required by `INVD-02` and user decisions for Phase 45. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] | Lets Phase 46 surface why a row fell through without reverse-engineering timestamps. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**
- `status == "expired"` as the user-facing freshness truth is outdated for this milestone because the requirement and context now require explicit `stale` state. [VERIFIED: codebase grep] [VERIFIED: .planning/REQUIREMENTS.md]
- `policy_key`-only compatibility is outdated for this milestone because the context explicitly requires a stronger policy compatibility snapshot/fingerprint. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Freshness windows can stay lane-defaulted and conservative without a new public API in Phase 45. [ASSUMED] | Architecture Patterns / Open Questions | Medium; planner may need a config surface earlier than expected. |
| A2 | Phase 45 uses `policy_fingerprint` as the canonical persisted policy-compatibility fence, derived from normalized `PromptPolicy` fields `policy_key`, `tools_allowed`, `grounding_required`, `approval_required`, and `metadata`. [RESOLVED] | Open Questions (RESOLVED) | Low; representation is now locked for planning/execution. |
| A3 | `source_fingerprint` is built from retrieval-run evidence by joining ordered retrieval results to `ai_knowledge_sources`, serializing `#{source_id}:#{version}:#{digest}`, sorting by retrieval `rank` then `source_id`, and hashing the ordered token list. [RESOLVED] | Open Questions (RESOLVED) | Low; aggregation is now locked for planning/execution. |

## Open Questions (RESOLVED)

1. **What is the canonical persisted representation for policy compatibility?**
   - Resolution: Phase 45 should treat `policy_fingerprint` as the canonical persisted compatibility fence and compute it from normalized `Scoria.PromptPolicy` fields `policy_key`, `tools_allowed`, `grounding_required`, `approval_required`, and `metadata`. [RESOLVED]
   - Rationale: this satisfies D-17's stronger-than-`policy_key` requirement without widening the row contract into a second human-facing snapshot surface before Phase 46 needs it. The normalized prompt-policy metadata already remains available elsewhere in runtime truth, so Phase 45 only needs the stable compatibility digest on the cache entry. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] [VERIFIED: codebase grep]

2. **How should `source_fingerprint` aggregate multi-source answers?**
   - Resolution: the authoritative source-fingerprint builder for Phase 45 should use retrieval-run evidence, join ordered retrieval results to `ai_knowledge_sources`, serialize each cited source as `#{source_id}:#{version}:#{digest}`, sort by retrieval rank then `source_id`, and hash the ordered token list into one stable fingerprint. [RESOLVED]
   - Rationale: this anchors compatibility to durable source-version and digest truth per D-16, preserves deterministic ordering for multi-source answers, and avoids lossy text snapshots or prompt-derived heuristics. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] [VERIFIED: codebase grep]

3. **Should stale marking happen eagerly or only on lookup?**
   - Resolution: Phase 45 should perform lookup-time stale transitions immediately when an expired candidate is encountered, marking the row `stale` with `freshness_window_elapsed` before falling through to live execution. Background sweep machinery remains deferred. [RESOLVED]
   - Rationale: this satisfies D-11 through D-15 with explicit persisted truth now, keeps the implementation inside the existing lookup/runtime seam, and avoids adding asynchronous refresh or sweep infrastructure that the phase explicitly defers. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | ExUnit, compilation, migrations | ✓ | Elixir `1.19.5`, Mix `1.19.5` [VERIFIED: elixir --version] [VERIFIED: mix --version] | — |
| PostgreSQL server | Repo-backed lookup/invalidation tests | ✓ | `14.17` client; `localhost:5432` accepting connections. [VERIFIED: psql --version] [VERIFIED: pg_isready] | Use bundled pgvector bootstrap flow if local DB state changes. [VERIFIED: codebase grep] |
| pgvector `vector` extension | Semantic lookup storage/querying | ✓ | enabled in `scoria_test` on `5432`. [VERIFIED: psql query] | `mix scoria.pgvector.bootstrap` can provision/enable it. [VERIFIED: codebase grep] |
| Docker | Optional pgvector bootstrap on `55432` | ✓ | `29.4.1` [VERIFIED: docker --version] | Not needed if staying on live `5432` database. [VERIFIED: pg_isready] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: command probes]

**Missing dependencies with fallback:**
- The dedicated `55432` pgvector service is not currently running, but the repo includes `mix scoria.pgvector.bootstrap` and the `5432` database is live with `vector` enabled. [VERIFIED: pg_isready] [VERIFIED: psql query] [VERIFIED: codebase grep]
- The current compiled test artifact expects `SCORIA_DB_PORT=55432`; the locked revision strategy is to recompile against `5432` before trusting any Phase 45 automated verification. [VERIFIED: mix test]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs] [VERIFIED: elixir --version] |
| Config file | `test/test_helper.exs` and `config/test.exs`. [VERIFIED: codebase grep] |
| Quick run command | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test test/scoria/semantic_cache_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria/runtime/semantic_fast_path_test.exs` after `mix clean && mix compile` on the same port. [VERIFIED: mix test] [VERIFIED: codebase grep] |
| Full suite command | `SCORIA_DB_PORT=5432 MIX_ENV=test mix test` after `mix clean && mix compile` on the same port. [VERIFIED: mix test] [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOOK-01 | Compatibility-gated hit only after prompt/policy/source/similarity checks | unit + integration | `mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` [VERIFIED: codebase grep] | ✅ existing files; coverage must expand. [VERIFIED: codebase grep] |
| LOOK-02 | miss/stale/reject fallthrough preserves normal path | integration | `mix test test/scoria/runtime/semantic_fast_path_test.exs` [VERIFIED: codebase grep] | ✅ existing file; stale/reject assertions missing. [VERIFIED: codebase grep] |
| INVD-01 | prompt/source/policy change invalidates affected rows | unit | `mix test test/scoria/semantic_cache_test.exs` or new invalidation-focused file. [VERIFIED: codebase grep] | ❌ dedicated invalidation test file not present. [VERIFIED: codebase grep] |
| INVD-02 | active/stale/invalidated reasons remain distinct | unit + integration | `mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` [VERIFIED: codebase grep] | ❌ current assertions do not cover `stale`. [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** targeted semantic-cache tests above. [VERIFIED: codebase grep]
- **Per wave merge:** full `mix test` with compile-env-aligned DB port. [VERIFIED: mix test]
- **Phase gate:** targeted semantic-cache lane plus green full suite before Phase 46. [VERIFIED: .planning/ROADMAP.md]

### Wave 0 Gaps
- [ ] `test/scoria/semantic_cache/invalidation_test.exs` or equivalent coverage in `test/scoria/semantic_cache_test.exs` for prompt/policy/source invalidation fan-out. [VERIFIED: codebase grep]
- [ ] `test/scoria/runtime/semantic_fast_path_test.exs` coverage for `lookup_status=reject`, `lookup_reason_code`, and persisted `stale` fallthrough. [VERIFIED: codebase grep]
- [ ] DB-port alignment step for test execution: `SCORIA_DB_PORT=5432 MIX_ENV=test mix clean && SCORIA_DB_PORT=5432 MIX_ENV=test mix compile` before relying on automated commands. [VERIFIED: mix test]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app identity is already provided; Phase 45 does not introduce a new auth mechanism. [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | no | User decision D-05 explicitly says session continuity is not a semantic reuse boundary. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] |
| V4 Access Control | yes | Mandatory `tenant_id` partitioning plus actor-scope narrowing through eligibility and lookup filters. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Existing normalization and changesets in runtime params, prompt policy, and semantic cache schemas. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | If fingerprints are derived, use standard digest primitives and canonical serialized inputs; never custom reversible encodings. [ASSUMED] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant reuse | Information Disclosure | Always filter reads/writes by `tenant_id`, then narrow by actor scope when required. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| Reuse after prompt/policy/source drift | Tampering | Persist compatibility snapshot fields and explicitly invalidate on prompt/source/policy change. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] |
| Silent false-positive semantic hit | Integrity | Filter-first lookup, conservative thresholding, and explicit fallthrough on incompatibility. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] |
| Hidden state transition without evidence | Repudiation | Append lifecycle events alongside row-state changes with stable reason codes. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

## Sources

### Primary (HIGH confidence)
- `mix hex.info ecto_sql` - latest version `3.14.0`, publish date `2026-05-19`, locked version `3.13.5`. [VERIFIED: mix hex.info ecto_sql]
- `mix hex.info pgvector` - latest/locked version `0.3.1`, publish date `2025-06-23`. [VERIFIED: mix hex.info pgvector]
- `mix hex.info postgrex` - latest version `0.22.2`, locked version `0.22.1`, publish date `2026-05-12`. [VERIFIED: mix hex.info postgrex]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transaction, `run`, `update_all`, and `to_list` behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- `https://hexdocs.pm/pgvector/readme.html` - Ecto integration, vector extension setup, and query helpers. [CITED: https://hexdocs.pm/pgvector/readme.html]
- `https://github.com/pgvector/pgvector` - exact vs approximate search, HNSW/IVFFlat filtering caveats, iterative scans. [CITED: https://github.com/pgvector/pgvector]
- Repo files: `lib/scoria/semantic_cache.ex`, `lib/scoria/semantic_cache/entry.ex`, `lib/scoria/semantic_cache/eligibility.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/prompt_policy.ex`, `lib/scoria/knowledge/source.ex`, `lib/scoria/knowledge/backends/pgvector.ex`, `test/scoria/semantic_cache_test.exs`, `test/scoria/runtime/semantic_fast_path_test.exs`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- `.planning/research/STACK.md` and `.planning/research/PITFALLS.md` - prior milestone-local synthesis aligned to current repo shape. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were checked live with Hex and the repo already uses the recommended libraries. [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info pgvector] [VERIFIED: mix hex.info postgrex]
- Architecture: HIGH - recommendations align with current runtime/cache seams and locked context decisions. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md]
- Pitfalls: HIGH - they are directly grounded in current code limitations, requirement wording, and pgvector official guidance. [VERIFIED: codebase grep] [CITED: https://github.com/pgvector/pgvector]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24 for repo-local architecture; re-check Hex package versions and pgvector docs if planning happens after that date. [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info pgvector] [VERIFIED: mix hex.info postgrex]

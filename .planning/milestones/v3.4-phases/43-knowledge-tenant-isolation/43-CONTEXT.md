# Phase 43: Knowledge tenant isolation - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Scoria's optional knowledge lane tenant-isolated end to end. Every source,
chunk, retrieval run, retrieval result, and citation must carry enough scope truth
to prove which tenant and actor produced it. Every read path that can expose raw
chunk body or citation quote must fail closed when tenant scope is missing, and
must never fall back to match-all behavior.

This phase delivers KNOW-01..04 only:

1. A new knowledge migration adds tenant/actor/scope columns and tenant indexes.
2. Retrieval audit tables carry tenant/actor evidence.
3. `similar_chunks`, `Scrypath.retrieve`, `list_source_chunks`, and
   `Knowledge.retrieve`/`ingest_source` enforce mandatory tenant scope.
4. Cross-tenant isolation tests prove tenant A never retrieves tenant B chunks.

**Method note:** The user selected all decision areas and requested one coherent
research-backed recommendation set. Four parallel research passes covered API
scope shape, migration/backfill, enforcement, and proof/DX; this context
synthesizes those recommendations with the local code and prompt research corpus.

**In scope:** fix + prove knowledge isolation in the existing optional
knowledge lane. **Out of scope:** Hex `0.1.3` release, dashboard auth seam
(Phase 44), correctness sweep items such as real cosine scoring and
label-aware citation presence (Phase 45), deeper RAG eval breadth (SEED-009),
PII masking/retention (SEED-011), and in-lib RBAC.

</domain>

<decisions>
## Implementation Decisions

Hard constraints carried forward:

- **No live LLM calls in CI/tests.** Phase 43 proof must be deterministic,
  local, and key-free, matching Phase 42.
- **Fix + prove only.** This is a P0 security/correctness fix for shipped
  `0.1.2`; it does not publish `0.1.3`.
- **Host owns identity and authorization.** Scoria owns the knowledge storage
  and retrieval verb; the host supplies trustworthy tenant/actor nouns.

### D-01 - Scope contract: explicit `scope:` with a small Knowledge scope helper

- Add `Scoria.Knowledge.Scope` (or equivalently named local helper) as the
  single normalization and validation point for knowledge scope.
- Canonical public shape:

  ```elixir
  scope =
    Scoria.Knowledge.Scope.new!(
      tenant_id: tenant.id,
      actor_id: current_user.id,
      scope_kind: :tenant_shared
    )

  {:ok, source} = Scoria.Knowledge.ingest_source(attrs, scope: scope)

  {:ok, %{run: run, results: results}} =
    Scoria.Knowledge.retrieve("refund policy",
      scope: scope,
      filters: %{source_id: source.id}
    )
  ```

- Accept `tenant_id:`, `actor_id:`, and `scope_kind:` as keyword shorthand for
  backward-compatible ergonomics, but immediately normalize into the same scope
  struct/map. If `scope:` and top-level scope keys disagree, raise.
- Store `scope_kind` as strings matching `SemanticCache`:
  `"tenant_shared"` and `"actor_scoped"`. Accept atoms and known strings at the
  API boundary.
- `tenant_id` is always required and must be non-empty. Nil tenant is a
  programmer error/security error, not a miss/bypass.
- For writes with `scope_kind: :actor_scoped`, require non-empty `actor_id`.
  For reads, visibility is:
  - tenant-shared rows for the same tenant
  - actor-scoped rows only for the same tenant and actor
  - missing actor never widens visibility to actor-scoped rows
- Do **not** accept `Plug.Conn` as a Knowledge API input. Host Phoenix code can
  derive the scope from assigns/session, but core Scoria receives explicit data.
- Do **not** use process dictionary/current-tenant state, Repo global options,
  `?tenant=` params, or a `"default"` tenant fallback.

**Why:** This is idiomatic for a Phoenix/Ecto library because it keeps core APIs
plain-data and testable while preserving the current `attrs_or_query, opts`
shape. It matches Ash/Phoenix-style explicit scopes better than hidden state,
and keeps Plug concerns out of the knowledge subsystem.

### D-02 - Migration and rollout: additive knowledge migration with quarantined legacy rows

- Add a new file under `priv/repo/knowledge_migrations/`. Do **not** mutate
  `20260511000300_create_knowledge_tables.exs`, and do **not** add this to the
  main `priv/repo/migrations/20260511000300_create_knowledge_tables.exs` no-op
  compatibility shell.
- Preserve the separate `KnowledgeMigrationRepo` /
  `schema_migrations_knowledge` path. The production/adopter run path must be
  documented where optional knowledge lane setup is documented.
- Add columns:
  - `ai_knowledge_sources`: `tenant_id` (string, initially nullable for
    upgrade), `actor_id` (string nullable), `scope_kind` (string nullable or
    default `"tenant_shared"` only for new writes)
  - `ai_knowledge_chunks`: same scope fields, copied from source at ingest
  - `ai_retrieval_runs`: `tenant_id`, `actor_id`
  - `ai_retrieval_results`: `tenant_id`, `actor_id`
  - `ai_knowledge_citations`: `tenant_id`, `actor_id`, and `scope_kind`
    if citation UI/proof needs the exact display label without a join
- Add indexes at minimum:
  - `ai_knowledge_sources(tenant_id)`
  - `ai_knowledge_sources(tenant_id, entity_id, version)` as a partial unique
    index where `tenant_id IS NOT NULL` if the existing global uniqueness would
    block same logical source IDs across tenants
  - `ai_knowledge_chunks(tenant_id)` and `ai_knowledge_chunks(tenant_id, source_id)`
  - keep the existing HNSW embedding index, but do not treat it as the tenant
    proof
  - `ai_retrieval_runs(tenant_id, status, inserted_at DESC)`
  - `ai_retrieval_results(tenant_id, retrieval_run_id, rank)`
  - `ai_knowledge_citations(tenant_id, source_id)` and
    `ai_knowledge_citations(tenant_id, chunk_id)`
- New writes require tenant scope immediately in changesets/API paths, even if
  the migration keeps columns nullable for existing adopter rows.
- Existing rows with null tenant are **quarantined**: retrieval must not return
  them, list functions must not return them, and citation validation must not
  trust them.
- Do **not** backfill unknown rows to `"default"`, `"system"`, or any synthetic
  tenant. If a host has historical knowledge data, the host must provide an
  explicit backfill mapping from legacy sources to tenant IDs.
- A later hardening slice may add not-null/check constraints after backfill
  tooling proves no null tenant rows remain. That is optional if Phase 43 can
  prove new writes fail closed and legacy rows are unreachable.

**Why:** This is the least surprising Hex-adopter path: additive, reversible,
and honest about legacy ambiguity. Recreating tables or forcing reingest would
be poor library DX; nullable-forever without quarantine would preserve the leak
class.

### D-03 - Enforcement: public boundary plus backend/result/citation leaves

- Normalize scope at the start of every public knowledge entry point that reads
  or writes tenant-owned knowledge:
  - `create_source/1`
  - `ingest_source/2`
  - `reembed_source/2`
  - `reindex_source/2`
  - `list_source_chunks/2`
  - `retrieve/2`
  - `create_retrieval_run/1`
  - `append_retrieval_results/2`
  - `create_citation/1`
- `Knowledge.retrieve/2` must compute and validate scope **before** embedding
  or calling any retriever/backend. Missing tenant raises before calling
  `Pgvector.similar_chunks/2`, `Scrypath.retrieve/2`, or a custom retriever.
- `Pgvector.similar_chunks/2` must require tenant scope itself. It should apply
  `where(chunk.tenant_id == ^tenant_id)` before ordering by cosine distance.
  `filters[:source_id]` remains an additional narrowing filter only after the
  tenant filter. Remove the current `maybe_filter_source(nil) -> query`
  match-all behavior for any tenant-sensitive path.
- `Scrypath.retrieve/2` and `Scrypath.normalize_results` must require scope and
  resolve hits through tenant-qualified queries. Replace `Repo.get!(Chunk, id)`
  with a tenant-qualified chunk lookup. Durable locator matching must include
  tenant, source, and digest.
- `list_source_chunks/2` must require scope and query by `source_id` **and**
  tenant visibility. `list_source_chunks(source_id)` without scope should raise
  or be retired to internal/test-only usage with an explicit unsafe name.
- `append_retrieval_results/2` must verify every result chunk/source belongs to
  the retrieval run tenant before inserting. If a custom backend returns a
  cross-tenant chunk, reject the result set and persist no mixed-tenant rows.
- `create_citation/1` must verify `source_id`, `chunk_id`, and `chunk_digest`
  under tenant scope before inserting. Citation quotes are as sensitive as raw
  chunk bodies; do not treat citation creation as audit-only.
- Use Ecto composable `where` filters. Do not rely on `Repo.prepare_query/3` as
  the primary mechanism for this phase; it is too hidden for a library-owned
  optional lane and does not cover all insert/update/cross-backend paths.
- Do not use Postgres RLS as the primary Phase 43 fix. RLS can be a later
  defence-in-depth option, but this phase needs explicit Elixir API behavior
  and deterministic tests in the existing knowledge lane.

**Why:** Retrieval is a trust boundary. The prompt research and AI eval work
both identify wrong-tenant data as a context failure and a security failure.
Security should not depend on optional filters supplied by callers or by vector
backend metadata.

### D-04 - Audit evidence: duplicate curated scope truth onto retrieval and citation rows

- Persist enough duplicated evidence that an operator can answer "retrieved
  under which tenant/actor?" without replaying joins:
  - `retrieval_run.tenant_id`, `retrieval_run.actor_id`
  - `retrieval_result.tenant_id`, `retrieval_result.actor_id`
  - `citation.tenant_id`, `citation.actor_id`, and scope label when useful
- Do not expose `backend_payload`, HNSW, SQL, embedding vectors, or namespace
  mechanics as primary proof. Those are backend internals, not operator-facing
  evidence.
- `metadata` may keep backend/debug details, but first-class scope columns are
  the proof consumed by tests, docs, and UI.
- Keep event language user/JTBD-focused:
  - "Tenant"
  - "Tenant-shared"
  - "Actor-scoped"
  - "Retrieved under"
  - "Citation scope"
- Host authorization remains delegated. These columns prove what scope Scoria
  used; they do not create an in-lib RBAC model.

**Why:** Scoria's product promise is operator-visible evidence. Joins alone are
fragile for audit, and metadata-only scope is too easy to miss in tests and UI.
Duplicated curated scope fields match the trace/eval pattern of storing
reconstructable evidence with each event.

### D-05 - Proof, docs, and operator DX: focused knowledge-lane tests and existing evidence UI

- Add `test/scoria/knowledge/tenant_isolation_test.exs` under
  `Scoria.KnowledgeCase`; update `test/scoria/knowledge_lane_contract_test.exs`
  expected file list.
- Required tests:
  - new source creation/ingest requires non-empty tenant
  - chunks inherit tenant/scope/actor evidence from sources on ingest/reingest
  - missing/nil/empty tenant raises before backend calls
  - `Pgvector.similar_chunks/2` excludes tenant B even when tenant B would rank
    higher by vector distance
  - `Scrypath.retrieve/2` rejects tenant-mismatched locators/results
  - tenant-shared rows are visible tenant-wide; actor-scoped rows require the
    same actor; missing actor does not widen access
  - backend-poison/custom-retriever result from another tenant is rejected and
    no mixed-tenant `retrieval_results` rows are persisted
  - citations carry tenant/scope evidence and reject tenant-mismatched anchors
  - migration/schema/index presence is proven for the new columns and key indexes
- Update optional knowledge docs:
  - `README.md`: one sentence that retrieval/citations are tenant-scoped and
    fail closed on missing tenant
  - `docs/adoption_lanes.md`: host app supplies tenant/actor identity; metadata
    filters are not a security proof
  - `docs/operator_verification.md`: `mix test.knowledge` now proves
    missing-tenant raise, cross-tenant exclusion, actor narrowing, and citation
    scope evidence
  - maintainer docs only if command/topology text changes. Do not change the
    lane topology just for this phase.
- UI/DX:
  - No new design-system primitive.
  - No new Knowledge Home/dashboard route.
  - If UI code is touched, extend existing citation/retrieval evidence surfaces
    with simple `Tenant` / `Scope` / `Actor` rows using existing components.
  - Keep backend internals out of primary UI. Raw evidence can remain available
    only if sanitized and not presented as the main proof.

**Why:** The n=1 operator needs quick proof that the retrieval was scoped, not
a tour through backend architecture. The existing optional knowledge lane is
the right verification surface; first adoption must stay free of pgvector setup.

### Research Tradeoffs Considered

- **Per-tenant prefixes or partitions:** Stronger physical isolation, but
  multiplies migrations and placement state. Does not match Scoria's optional
  knowledge lane or embedded Phoenix library posture. Defer to host-specific
  regulated/large-tenant deployments.
- **Postgres RLS:** Valuable later defence-in-depth, but requires connection
  tenant plumbing and policy deployment assumptions. Too much for this P0 fix.
- **Backend-native namespaces only:** Useful adapter detail for Pinecone-like
  backends, but Scoria owns Ecto audit rows and pgvector-first behavior. Not
  sufficient system proof.
- **Metadata-only scope:** Lowest migration pressure, but fails the evidence
  and testability bar. Avoid except as temporary legacy backfill metadata.
- **Implicit global tenant:** Less call-site noise, but surprising in async
  Elixir/Oban tests and not appropriate when Scoria is fixing a data leak.

### Claude's Discretion

- Exact module/function names for the scope helper (`Scope.normalize!/1`,
  `Scope.from!/1`, `Scope.new!/1`) as long as there is one canonical helper.
- Exact migration timestamp/name and whether constraints harden in the same
  migration or a follow-up, provided new writes fail closed and legacy null rows
  are unreachable.
- Exact UI placement if existing citation evidence components are already
  structured differently; do not create a new route or primitive for this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and Roadmap

- `.planning/ROADMAP.md` - Phase 43 goal and four success criteria.
- `.planning/REQUIREMENTS.md` - KNOW-01..04 locked requirement text.
- `.planning/PROJECT.md` - v3.4 trust/security boundary, n=1 operator lens,
  fix+prove scope, and release hold.
- `.planning/phases/42-eval-fails-closed/42-CONTEXT.md` - carry-forward
  fail-closed posture and no-live-LLM proof constraint.

### Prompt Research Corpus

- `prompts/ai-eval-best-practices-deep-research.md` - RAG/security guidance:
  retrieval quality is separate from generation; tenant/user/session IDs are
  trace identity; wrong-tenant retrieval is a security failure.
- `prompts/ai-architectural-patterns-deep-research.md` - RAG as evidence
  supply; permissions before retrieval; trace/audit as reconstructable proof.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops posture,
  RAG/knowledge nouns, tenant/cost/audit fields, and LiveView operator UX.
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` -
  global scope/orientation principle: operators should always know for whom
  they are looking.
- `prompts/scoria-brand-book-deep-research.md` - UI tone: operator-grade,
  evidence-based, dark/light consistency, no backend-guts-as-product language.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable,
  Ecto-native durable state, operator-first DX.

### Existing Knowledge Code

- `lib/scoria/knowledge.ex` - public knowledge context; current unscoped
  `create_source`, `ingest_source`, `list_source_chunks`, `retrieve`,
  retrieval-run/result/citation write paths.
- `lib/scoria/knowledge/source.ex` - source schema currently lacks scope fields.
- `lib/scoria/knowledge/chunk.ex` - chunk schema currently lacks scope fields.
- `lib/scoria/knowledge/retrieval_run.ex` - retrieval run schema currently
  lacks tenant/actor audit fields.
- `lib/scoria/knowledge/retrieval_result.ex` - result schema currently lacks
  tenant/actor audit fields.
- `lib/scoria/knowledge/citation.ex` - citation schema currently lacks
  tenant/actor/scope evidence.
- `lib/scoria/knowledge/backends/pgvector.ex` - current leak point:
  optional `source_id` filter and match-all when absent.
- `lib/scoria/knowledge/retrievers/scrypath.ex` - current leak point:
  `Repo.get!(Chunk, id)` and digest/source lookup without tenant qualification.
- `lib/scoria/knowledge/citation_formatter.ex` - citation anchor construction
  and any validation path that must become tenant-aware if touched.

### Migration and Lane Infrastructure

- `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`
  - real optional knowledge DDL; add the new migration next to this file.
- `priv/repo/migrations/20260511000300_create_knowledge_tables.exs` - main
  repo no-op compatibility shell; do not use for Phase 43 scope DDL.
- `lib/scoria/test_support/migrations.ex` - `KnowledgeMigrationRepo` and
  `schema_migrations_knowledge` migration source.
- `lib/mix/tasks/scoria.test.knowledge.ex` - optional knowledge lane runner.
- `test/scoria/knowledge_lane_contract_test.exs` - update expected knowledge
  test file list when adding tenant isolation tests.
- `test/scoria/knowledge_test.exs`, `test/scoria/knowledge/retrieval_test.exs`,
  `test/scoria/knowledge/pgvector_test.exs`,
  `test/scoria/knowledge/scrypath_test.exs` - existing knowledge tests to
  update for explicit scope.

### Existing Scope Precedents

- `lib/scoria/semantic_cache.ex` - public semantic cache wrapper and
  normalized identity keys.
- `lib/scoria/semantic_cache/lookup.ex` - fail-closed lower query layer using
  `Map.fetch!` for tenant/lane and actor-vs-tenant-shared filtering.
- `priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs` -
  tenant/actor/scope schema precedent.
- `docs/semantic_fast_path.md` - tenant-partitioned semantic fast path and
  operator-visible hit/miss/reject evidence.

### Adopter and Operator Docs

- `README.md` - optional knowledge lane paragraph.
- `docs/adoption_lanes.md` - optional knowledge lane setup and sequencing.
- `docs/operator_verification.md` - optional knowledge verification narrative.
- `docs/MAINTAINERS.md` - CI topology; update only if lane command/topology
  text changes.
- `docs/design_system.md` - evidence component conventions if UI is touched.

### External Primary References Consulted

- Ecto official multi-tenancy with foreign keys guide - explicit tenant keys,
  fail-closed query scoping, and migration/data-validity guidance.
- Ash official multitenancy guide - attribute-based tenant strategy and
  explicit tenant/scope options.
- Pinecone docs - namespace vs metadata-filter tradeoffs; tenant filters are
  query/storage design, not incidental metadata.
- Qdrant docs - payload-based multitenancy and tenant payload indexing.
- pgvector docs - filtered ANN behavior and index/partition considerations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Scoria.SemanticCache.Lookup.base_query/1` - the closest local fail-closed
  precedent: `Map.fetch!` for scope values plus tenant-shared/actor-scoped
  visibility.
- `Scoria.SemanticCache` schemas and migrations - existing `tenant_id`,
  `actor_id`, `scope_kind`, `scope_reason` vocabulary.
- `Scoria.KnowledgeCase` and `mix test.knowledge` - focused optional lane for
  pgvector-backed proof.
- Existing `CitationEvidenceComponent` / evidence components - reuse for
  curated scope display if UI proof is added.

### Established Patterns

- Scoria keeps optional knowledge migrations separate from core app migrations
  via `KnowledgeMigrationRepo` and `schema_migrations_knowledge`.
- Verification lanes are command-SSOTed and contract-tested. Add tests to the
  knowledge lane without changing first-adoption proof.
- The product avoids hidden magic in security-sensitive paths: host identity is
  supplied explicitly, and Scoria records durable evidence rather than trusting
  transient request params.

### Integration Points

- `Knowledge.ingest_source/2` must propagate scope from source to chunks.
- `Knowledge.retrieve/2` must pass scope into default Pgvector, Scrypath, and
  custom retriever paths.
- `Pgvector.similar_chunks/2` must be tenant-filtered before vector ranking.
- `Scrypath.normalize_results/2` or equivalent must resolve hits with tenant.
- `append_retrieval_results/2` and `create_citation/1` must validate result
  rows against the run/source/chunk tenant before inserting.
- `docs/adoption_lanes.md`, `docs/operator_verification.md`, and `README.md`
  need small updates so adopters know the optional knowledge lane is now
  fail-closed on missing tenant.

</code_context>

<specifics>
## Specific Ideas

- User requested a one-shot, researched recommendation set covering all gray
  areas rather than interactive Q&A.
- User explicitly asked to consider Elixir/Phoenix/Ecto/Plug idioms, lessons
  from successful libraries/platforms in other ecosystems, DX, SRE/security,
  UI/UX only where applicable, and Scoria's prompt corpus.
- The coherent recommendation is: **explicit scope data in; tenant-qualified
  retrieval/citation data out; fail closed everywhere; show curated
  Tenant/Scope/Actor evidence, not backend internals.**
- Keep UI effort limited. This is primarily a backend/security/data-model
  phase. Any UI touch should only make existing evidence clearer.

</specifics>

<deferred>
## Deferred Ideas

- **Postgres RLS for knowledge tables** - useful later defence-in-depth, but
  too much connection/session-policy surface for this P0 fix.
- **Per-tenant prefixes, partitions, or dedicated vector collections** - good
  for regulated or very large deployments, but not Scoria's default embedded
  optional knowledge lane.
- **Backend-native namespaces as the primary proof** - adapter detail for
  future non-pgvector backends, not sufficient for Scoria's Ecto audit rows.
- **Dedicated Knowledge Home / global scope bar UI** - valuable for future
  operator IA work, but new route/shell work belongs outside this fix.
- **Hard not-null constraints after legacy backfill** - desirable hardening if
  adopters can map existing rows; planner may include if cheap, otherwise
  document as follow-up after quarantine.

### Reviewed Todos (not folded)

- `ci-policy-job-cache-key-mislabel.md` - unrelated CI copy/cache-key cleanup;
  not knowledge tenant isolation.
- `docker-dx-fleet-hardening.md` - fleet/local Docker DX hardening; not
  knowledge tenant isolation.
- `2026-06-20-add-approval-decision-history.md` - stale UI approval history
  follow-up; not knowledge tenant isolation.

</deferred>

---

*Phase: 43-Knowledge tenant isolation*
*Context gathered: 2026-07-04*

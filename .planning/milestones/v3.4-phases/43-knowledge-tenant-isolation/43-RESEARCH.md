# Phase 43: Knowledge tenant isolation - Research

**Researched:** 2026-07-05  
**Domain:** Elixir/Phoenix/Ecto knowledge retrieval tenant isolation  
**Confidence:** HIGH for codebase topology and required behavior; MEDIUM for external docs currency

<user_constraints>
## User Constraints (from CONTEXT.md)

All constraints in this section are copied from `.planning/phases/43-knowledge-tenant-isolation/43-CONTEXT.md`; provenance for this section: [VERIFIED: CONTEXT.md]

### Locked Decisions

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

### the agent's Discretion

### Claude's Discretion

- Exact module/function names for the scope helper (`Scope.normalize!/1`,
  `Scope.from!/1`, `Scope.new!/1`) as long as there is one canonical helper.
- Exact migration timestamp/name and whether constraints harden in the same
  migration or a follow-up, provided new writes fail closed and legacy null rows
  are unreachable.
- Exact UI placement if existing citation evidence components are already
  structured differently; do not create a new route or primitive for this phase.

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KNOW-01 | Add tenant scope columns and tenant indexes to sources/chunks through the knowledge migration path. [VERIFIED: REQUIREMENTS.md] | Use additive migration under `priv/repo/knowledge_migrations/`; preserve `KnowledgeMigrationRepo` and `schema_migrations_knowledge`; add indexes listed in D-02. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep] |
| KNOW-02 | Carry tenant/actor on retrieval runs, retrieval results, and citations for audit. [VERIFIED: REQUIREMENTS.md] | Schemas currently lack those fields; duplicate scope fields onto run/result/citation rows and changesets. [VERIFIED: codebase grep] |
| KNOW-03 | Enforce mandatory fail-closed tenant filter in Pgvector, Scrypath, source chunk listing, and public Knowledge ingest/retrieve paths. [VERIFIED: REQUIREMENTS.md] | Current Pgvector has `maybe_filter_source(nil) -> query` and Scrypath uses global chunk lookups; replace with scope-normalized, tenant-qualified queries and pre-backend nil-tenant raises. [VERIFIED: codebase grep] |
| KNOW-04 | Prove cross-tenant isolation with a test where tenant A cannot retrieve tenant B chunks. [VERIFIED: REQUIREMENTS.md] | Add `test/scoria/knowledge/tenant_isolation_test.exs`, update the lane contract file list, and run `mix test.knowledge --warnings-as-errors`. [VERIFIED: CONTEXT.md] [VERIFIED: local command] |
</phase_requirements>

## Summary

Phase 43 is a data-boundary and audit-evidence change, not a new retrieval product. The required plan should make `Scoria.Knowledge.Scope` the single public normalization point, then require that normalized scope at every knowledge read/write boundary before embeddings, vector ranking, Scrypath normalization, citation validation, or result insertion can occur. [VERIFIED: CONTEXT.md] The current code has no tenant fields on knowledge sources, chunks, retrieval runs, retrieval results, or citations, so the data model must be expanded before fail-closed enforcement can be complete. [VERIFIED: codebase grep]

The main leak points are concrete: `Pgvector.similar_chunks/2` only applies optional `source_id` narrowing and leaves the query global when that filter is nil; `Scrypath.resolve_chunk/1` uses either `Repo.get!(Chunk, id)` or a source/digest lookup without tenant qualification; `list_source_chunks/1` filters only by `source_id`. [VERIFIED: codebase grep] OWASP multi-tenant guidance aligns with the local D-03 decision: validate resource ownership at the data access layer, use tenant-plus-resource lookups, log tenant context, and avoid queries without tenant filters. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html]

**Primary recommendation:** Implement explicit scope normalization first, then additive schema/changset changes, then tenant-qualified data access leaves, then deterministic cross-tenant and nil-tenant tests in the existing `mix test.knowledge` lane. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Knowledge scope normalization | API / Backend | Database / Storage | `Knowledge.retrieve/2`, `ingest_source/2`, and related context functions own the public contract before DB access begins. [VERIFIED: codebase grep] |
| Tenant persistence columns/indexes | Database / Storage | API / Backend | Scope evidence must live on source/chunk/run/result/citation rows, while schemas and changesets expose those columns. [VERIFIED: CONTEXT.md] |
| Vector retrieval filtering | API / Backend | Database / Storage | Ecto query composition should add tenant predicates before `cosine_distance` ordering. [CITED: https://ecto.hexdocs.pm/dynamic-queries.html] [CITED: https://github.com/pgvector/pgvector-elixir] |
| Scrypath hit normalization | API / Backend | Database / Storage | External hits must be resolved against Scoria-owned, tenant-qualified chunks before becoming retrieval results. [VERIFIED: codebase grep] |
| Audit evidence | Database / Storage | Frontend Server / UI | Retrieval and citation rows need first-class tenant/actor fields; existing UI surfaces can show curated rows if touched. [VERIFIED: CONTEXT.md] |
| Host identity and authorization | Host Application | API / Backend | Host supplies trustworthy tenant/actor nouns; Scoria records and enforces them but does not model in-lib RBAC. [VERIFIED: PROJECT.md] |

## Project Constraints (from CLAUDE.md / AGENTS.md)

- No root `CLAUDE.md`, `.claude/CLAUDE.md`, root `AGENTS.md`, `.claude/skills/`, `.agents/skills/`, or `.codex/skills/` project skill files were found in this workspace scan; only nested example dependency `AGENTS.md` files exist and are not project-root directives. [VERIFIED: find]
- Scoria remains embedded and Phoenix-first, not a hosted connector platform. [VERIFIED: PROJECT.md]
- Default-lane proof must not require pgvector, retrieval, grounding, or semantic fast-path setup. [VERIFIED: PROJECT.md]
- Scope doctrine: Scoria owns verbs such as record, gate, surface, and reconstruct; the host owns identity, business truth, policy values, and end-user authorization. [VERIFIED: PROJECT.md]
- v3.4 is fix-and-prove only; no Hex `0.1.3` publish belongs in this phase. [VERIFIED: PROJECT.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local; project requires `~> 1.19` | Runtime, build, ExUnit, Mix tasks | Existing project baseline and local runtime. [VERIFIED: local command] [VERIFIED: mix.exs] |
| Ecto | locked 3.13.6; latest observed 3.14.0 | Schemas, changesets, query DSL | Existing lock; use composable `where` predicates for tenant filters. [VERIFIED: mix deps] [VERIFIED: mix hex.info] |
| Ecto SQL | locked 3.13.5; latest observed 3.14.0 | Migrations, `Ecto.Migrator`, SQL sandbox | Existing migration stack; supports indexes, partial indexes, and migration options used by this phase. [VERIFIED: mix deps] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] |
| Postgrex | locked 0.22.1 | Postgres adapter | Existing Repo adapter path. [VERIFIED: mix deps] |
| pgvector-elixir | locked 0.3.1; latest observed 0.4.0 | Ecto vector fields and distance query helpers | Existing knowledge backend imports `Pgvector.Ecto.Query` and uses `Pgvector.Ecto.Vector`. [VERIFIED: mix deps] [VERIFIED: codebase grep] |
| ExUnit / SQL Sandbox | Elixir 1.19.5 built-in plus Ecto SQL sandbox | Deterministic local tests | `KnowledgeCase` uses sandbox checkout/shared mode and pgvector bootstrap. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Docker | 29.5.2 local | Starts bundled pgvector Postgres if needed | Fallback when local pgvector DB is unavailable. [VERIFIED: local command] |
| PostgreSQL / psql | psql 14.17 local; CI uses `pgvector/pgvector:pg16` | Knowledge lane DB | Local `localhost:55432` is accepting and pgvector preflight is green; CI has a dedicated pgvector service. [VERIFIED: local command] [VERIFIED: CI workflow] |
| `mix test.knowledge` | project Mix task | Focused optional knowledge verification lane | Use as the phase quick/full knowledge proof after adding tenant tests. [VERIFIED: codebase grep] [VERIFIED: local command] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit Ecto tenant filters | Postgres RLS | RLS is useful later, but D-03 rejects it as primary because this phase needs explicit API raises and deterministic tests across backend and custom retriever paths. [VERIFIED: CONTEXT.md] |
| First-class columns | Metadata-only scope | Metadata lowers migration pressure but fails audit/testability and is explicitly out of scope as primary proof. [VERIFIED: CONTEXT.md] |
| Shared table + tenant columns | Per-tenant collections/partitions | Stronger physical isolation but more migration/placement complexity than the embedded optional lane needs. [VERIFIED: CONTEXT.md] |
| Host/global current tenant | Process dictionary, `Plug.Conn`, Repo global options | D-01 rejects hidden state and Plug coupling; core APIs should receive plain explicit scope data. [VERIFIED: CONTEXT.md] |

**Installation:**

```bash
# No new dependencies should be installed for Phase 43.
mix deps.get --check-locked
```

**Version verification:** Existing versions were verified with `mix deps` and `mix hex.info ecto`, `mix hex.info ecto_sql`, and `mix hex.info pgvector`; no package upgrade is recommended for this phase. [VERIFIED: local command]

## Package Legitimacy Audit

No external package installation is recommended for this phase, so the Package Legitimacy Gate is not required. [VERIFIED: mix.exs] [VERIFIED: CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No new package install. [VERIFIED: mix.exs] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: mix.exs]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Host app identity
  -> Scoria.Knowledge.Scope.new!/1
      -> Knowledge public API boundary
          -> normalize/validate tenant before side effects
          -> branch:
              ingest/create source
                -> source changeset with tenant/actor/scope
                -> chunk insert copies source scope
                -> pgvector embedding update stays same tenant row set
              retrieve/list chunks
                -> tenant visibility query
                -> optional source_id filter after tenant
                -> vector/Scrypath/custom backend result
                -> validate every chunk/source against run tenant
                -> persist run/result audit rows with tenant/actor
              citation
                -> tenant-qualified chunk/source/digest validation
                -> persist citation tenant/actor/scope evidence
          -> output:
              tenant-isolated chunks/results/citations or raised missing-scope error
```

### Recommended Project Structure

```text
lib/scoria/knowledge/
├── scope.ex                    # canonical tenant/actor/scope normalization
├── source.ex                   # source schema + tenant fields
├── chunk.ex                    # chunk schema + tenant fields
├── retrieval_run.ex            # run audit scope fields
├── retrieval_result.ex         # result audit scope fields
├── citation.ex                 # citation audit scope fields
├── backends/pgvector.ex        # tenant-filtered vector query leaf
└── retrievers/scrypath.ex      # tenant-qualified hit normalization

priv/repo/knowledge_migrations/
└── <new timestamp>_add_knowledge_tenant_scope.exs

test/scoria/knowledge/
└── tenant_isolation_test.exs
```

### Pattern 1: Scope Normalization At Public Boundaries

**What:** Add one helper such as `Scoria.Knowledge.Scope.new!/1` and call it at the top of public knowledge functions before DB reads, writes, embedding generation, or backend calls. [VERIFIED: CONTEXT.md]

**When to use:** Every knowledge API path that can create tenant-owned rows or expose raw chunk/citation data. [VERIFIED: CONTEXT.md]

**Example:**

```elixir
# Source: Phase 43 CONTEXT.md + SemanticCache precedent
scope = Scoria.Knowledge.Scope.new!(opts)

query =
  Chunk
  |> where([chunk], chunk.tenant_id == ^scope.tenant_id)
  |> Scoria.Knowledge.Scope.visible_to(scope)
```

The SemanticCache precedent uses `Map.fetch!(attrs, :tenant_id)` inside lower query construction, which intentionally raises when the required tenant key is absent. [VERIFIED: codebase grep]

### Pattern 2: Tenant Predicate Before Optional Filters

**What:** Compose tenant visibility first, then apply optional filters such as `source_id`, then order by vector distance. [CITED: https://ecto.hexdocs.pm/dynamic-queries.html] [CITED: https://github.com/pgvector/pgvector-elixir]

**When to use:** `Pgvector.similar_chunks/2`, `list_source_chunks/2`, Scrypath durable locator resolution, and citation validation. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Ecto dynamic query docs + pgvector-elixir README
Chunk
|> where([chunk], chunk.tenant_id == ^scope.tenant_id)
|> where([chunk], chunk.scope_kind == "tenant_shared" or
  (chunk.scope_kind == "actor_scoped" and chunk.actor_id == ^scope.actor_id))
|> maybe_filter_source(filters[:source_id])
|> order_by([chunk], asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding)))
|> limit(^limit)
```

### Pattern 3: Validate Backend Results Before Insert

**What:** Treat retriever output as untrusted until Scoria has reloaded each chunk/source with tenant-qualified constraints. [VERIFIED: CONTEXT.md]

**When to use:** `append_retrieval_results/2`, custom retriever modules, and `Scrypath.normalize_results`. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Phase 43 CONTEXT.md
def append_retrieval_results(%RetrievalRun{} = run, results) do
  Multi.new()
  |> Multi.run(:validated_results, fn repo, _changes ->
    validate_results_belong_to_scope(repo, run, results)
  end)
  |> Multi.insert_all(:results, RetrievalResult, fn %{validated_results: rows} -> rows end)
  |> Repo.transaction()
end
```

### Pattern 4: Additive Migration With Legacy Quarantine

**What:** Add nullable tenant columns for upgrade compatibility, require tenant in new write paths immediately, and ensure null-tenant legacy rows are not returned by reads. [VERIFIED: CONTEXT.md]

**When to use:** The new `priv/repo/knowledge_migrations/*` migration and schema changesets. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Ecto.Migration docs + Phase 43 CONTEXT.md
alter table(:ai_knowledge_chunks) do
  add :tenant_id, :string
  add :actor_id, :string
  add :scope_kind, :string
end

create index(:ai_knowledge_chunks, [:tenant_id])
create index(:ai_knowledge_chunks, [:tenant_id, :source_id])
```

Ecto supports partial indexes through `where:` and supports expression index columns as strings; use those for scoped uniqueness only if the current global `[:entity_id, :version]` uniqueness blocks same logical source IDs across tenants. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] [VERIFIED: CONTEXT.md]

### Anti-Patterns To Avoid

- **Nil tenant as match-all:** The current `maybe_filter_source(nil) -> query` shape is the leak class; nil tenant must raise before backend calls. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]
- **Post-filtering results in Elixir only:** Tenant filtering belongs in the SQL lookup as well as result validation; OWASP recommends access checks at the data access layer. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html]
- **Metadata-only tenant proof:** First-class tenant/actor columns are required for audit and tests. [VERIFIED: CONTEXT.md]
- **`Plug.Conn` or process dictionary scope:** Core Scoria APIs should receive explicit data, not hidden request state. [VERIFIED: CONTEXT.md]
- **Changing CI topology for this phase:** The knowledge lane already exists and is CI-wired; update tests and docs, not lane shape. [VERIFIED: CI workflow] [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tenant context transport | Process dictionary/current tenant magic | Explicit `Scoria.Knowledge.Scope` helper | Keeps security state plain-data and testable. [VERIFIED: CONTEXT.md] |
| Query construction | Ad hoc SQL string concatenation | Ecto `where` composition | Existing project style and official Ecto pattern support composable filters. [VERIFIED: codebase grep] [CITED: https://ecto.hexdocs.pm/dynamic-queries.html] |
| Vector search | Custom vector distance/ranking engine | Existing pgvector backend + `cosine_distance` query helper | The current backend already uses pgvector; Phase 45 owns score correctness, not this phase. [VERIFIED: codebase grep] [VERIFIED: REQUIREMENTS.md] |
| Migration runner | New migration task | Existing `KnowledgeMigrationRepo` / `schema_migrations_knowledge` path | The optional knowledge migration path already exists and is contract-tested. [VERIFIED: codebase grep] |
| Tenant isolation proof | Backend metadata or HNSW internals | First-class DB columns plus tests | Operator-facing proof should be rows and curated fields, not index internals. [VERIFIED: CONTEXT.md] |
| In-lib authorization | RBAC/permissions system | Host-supplied tenant/actor + Scoria enforcement of storage/retrieval scope | Project doctrine delegates identity/authz to the host. [VERIFIED: PROJECT.md] |

**Key insight:** Retrieval is both a data-access boundary and an LLM context boundary; wrong-tenant chunks and citation quotes are sensitive data leaks even when the vector ranking is technically correct. [VERIFIED: REQUIREMENTS.md] [CITED: https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Local test DB at `localhost:55432` had no knowledge tables before `mix test.knowledge`; after baseline lane, sandboxed tests created rows only transiently. [VERIFIED: local command] Existing adopters may have rows from shipped `0.1.2` without tenant columns. [VERIFIED: REQUIREMENTS.md] | Add nullable columns, require tenant on new writes, and quarantine null-tenant legacy rows from all reads; do not synthesize `"default"` tenants. [VERIFIED: CONTEXT.md] |
| Live service config | Knowledge lane config is local/CI database setup and CI workflow service config; no external SaaS knowledge service config was found in repo search. [VERIFIED: rg] | Do not add a new service; document the production/adopter run path through knowledge migrations. [VERIFIED: CONTEXT.md] |
| OS-registered state | No OS-level registrations for knowledge migration/routing were found in repo-local scan; only Mix tasks and CI workflows drive the lane. [VERIFIED: find] [VERIFIED: rg] | None for OS state; use existing Mix/CI commands. [VERIFIED: codebase grep] |
| Secrets/env vars | Knowledge-specific env var found: `SCORIA_TEST_INCLUDE_KNOWLEDGE` for test lane gating; DB env vars are `SCORIA_DB_*`. [VERIFIED: rg] | No secret rename required; keep tenant values as API data, not environment defaults. [VERIFIED: CONTEXT.md] |
| Build artifacts | `tmp/scoria-hex-consumer`, `tmp/scoria-release-preview`, and `doc/scoria.epub` artifacts exist; package inclusion already covers `priv/repo/knowledge_migrations`. [VERIFIED: find] [VERIFIED: mix.exs] | No migration needed for artifacts; release-preview/package tests may need rerun if docs/package surface is touched. [VERIFIED: codebase grep] |

**Nothing found in category:** No project-root live external knowledge service, OS registration, or secret-key rename was found; this phase is a code/schema/test/docs migration with adopter legacy-row quarantine as the primary runtime concern. [VERIFIED: rg] [VERIFIED: local command]

## Common Pitfalls

### Pitfall 1: Adding Columns Without Changing Read Leaves
**What goes wrong:** Source/chunk rows get `tenant_id`, but `Pgvector.similar_chunks/2`, `Scrypath`, or `list_source_chunks/1` still expose global rows. [VERIFIED: codebase grep]  
**Why it happens:** Schema migration work and retrieval query work are planned separately. [VERIFIED: CONTEXT.md]  
**How to avoid:** Plan schema, scope helper, query leaves, and tests as one vertical slice. [VERIFIED: CONTEXT.md]  
**Warning signs:** A function still accepts only `source_id` or `query_embedding` with no scope. [VERIFIED: codebase grep]

### Pitfall 2: Raising At Public API But Not Backend Leaves
**What goes wrong:** `Knowledge.retrieve/2` raises on nil tenant, but direct calls to `Pgvector.similar_chunks/2` or `Scrypath.normalize_results` can still bypass. [VERIFIED: CONTEXT.md]  
**Why it happens:** Tests cover facade calls only. [VERIFIED: CONTEXT.md]  
**How to avoid:** Add direct backend/retriever tests for nil/mismatched tenant. [VERIFIED: CONTEXT.md]  
**Warning signs:** Backends accept `opts` with no `scope` and do not call scope normalization. [VERIFIED: codebase grep]

### Pitfall 3: Actor-Scoped Rows Widen When Actor Is Missing
**What goes wrong:** A tenant-wide read returns actor-scoped rows for all actors. [VERIFIED: CONTEXT.md]  
**Why it happens:** Tenant filter is applied but `scope_kind` visibility is not. [VERIFIED: CONTEXT.md]  
**How to avoid:** Mirror `SemanticCache.Lookup.maybe_scope_filter/2`: missing actor returns tenant-shared rows only. [VERIFIED: codebase grep]  
**Warning signs:** Query only checks `tenant_id` and ignores `scope_kind`/`actor_id`. [VERIFIED: codebase grep]

### Pitfall 4: Custom Retriever Poisoned Results Persist
**What goes wrong:** A custom backend returns a cross-tenant chunk ID and Scoria persists it because foreign keys exist. [VERIFIED: CONTEXT.md]  
**Why it happens:** `append_retrieval_results/2` currently inserts result rows directly from attrs. [VERIFIED: codebase grep]  
**How to avoid:** Reload and validate each chunk/source under the retrieval run tenant before inserting, inside one transaction. [VERIFIED: CONTEXT.md]  
**Warning signs:** Result rows are inserted before tenant validation. [VERIFIED: codebase grep]

### Pitfall 5: Citations Treated As Audit-Only
**What goes wrong:** Citation `quote` leaks raw chunk text across tenants. [VERIFIED: REQUIREMENTS.md]  
**Why it happens:** `CitationFormatter.validate_anchor/2` currently checks only chunk ID, digest, and offsets. [VERIFIED: codebase grep]  
**How to avoid:** Tenant-qualify citation anchor validation and `create_citation/1` with source/chunk/digest. [VERIFIED: CONTEXT.md]  
**Warning signs:** `Repo.get(Chunk, chunk_id)` appears in citation validation without tenant. [VERIFIED: codebase grep]

### Pitfall 6: Unique Index Blocks Cross-Tenant Logical Sources
**What goes wrong:** A global `[:entity_id, :version]` unique index prevents two tenants from using the same logical source/version. [VERIFIED: codebase grep]  
**Why it happens:** The original knowledge migration was global. [VERIFIED: codebase grep]  
**How to avoid:** Add tenant-scoped partial unique index and plan any old index drop/compat strategy carefully. [VERIFIED: CONTEXT.md] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html]

## Code Examples

Verified patterns from official and local sources:

### Local Fail-Closed Scope Pattern

```elixir
# Source: lib/scoria/semantic_cache/lookup.ex
defp base_query(attrs) do
  tenant_id = Map.fetch!(attrs, :tenant_id)
  lane_key = Map.fetch!(attrs, :lane_key)
  actor_id = Map.get(attrs, :actor_id)

  Entry
  |> where([entry], entry.tenant_id == ^tenant_id and entry.lane_key == ^lane_key)
  |> where([entry], entry.status in ^@rankable_statuses)
  |> maybe_scope_filter(actor_id)
end
```

This is the local pattern Phase 43 should mirror for lower knowledge query leaves. [VERIFIED: codebase grep]

### Current Pgvector Leak Shape To Replace

```elixir
# Source: lib/scoria/knowledge/backends/pgvector.ex
Chunk
|> maybe_filter_source(source_id)
|> order_by([chunk], asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding)))
|> limit(^limit)
|> Repo.all()

defp maybe_filter_source(query, nil), do: query
```

This must become tenant-required and tenant-filtered before optional source filters. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]

### Current Scrypath Lookup To Replace

```elixir
# Source: lib/scoria/knowledge/retrievers/scrypath.ex
result[:chunk_id] && result[:source_id] ->
  {:ok, Repo.get!(Chunk, result[:chunk_id])}
```

Replace direct global `Repo.get!` with tenant-qualified chunk/source/digest lookup. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md]

### Ecto Migration Index Pattern

```elixir
# Source: Ecto.Migration official docs
create index(:ai_knowledge_chunks, [:tenant_id])
create index(:ai_knowledge_chunks, [:tenant_id, :source_id])
create index(:ai_knowledge_sources, [:tenant_id, :entity_id, :version],
  unique: true,
  where: "tenant_id IS NOT NULL"
)
```

Ecto documents `:where` for partial indexes and string expression columns for database expressions. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Optional tenant metadata or caller-supplied filter | Mandatory tenant context at the data-access layer | Current OWASP multi-tenant guidance | Prevents IDOR-style cross-tenant access and forbids queries without tenant filters. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html] |
| Vector search as a backend-only ranking concern | Vector search as tenant-scoped data access plus ranking | Phase 43 requirement | Tenant filter must apply before ranking and result persistence. [VERIFIED: REQUIREMENTS.md] |
| Citation validation as digest/offset validation | Citation validation as tenant-qualified source/chunk/digest validation | Phase 43 requirement | Citation quotes are protected like raw chunks. [VERIFIED: CONTEXT.md] |
| Metadata-only audit | First-class tenant/actor columns on runs/results/citations | Phase 43 requirement | Operators can audit retrieval scope without reconstructing joins. [VERIFIED: CONTEXT.md] |

**Deprecated/outdated:**

- Querying tenant-owned rows without tenant filters is explicitly rejected by Phase 43 and OWASP multi-tenant guidance. [VERIFIED: CONTEXT.md] [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html]
- Treating RLS, vector namespaces, HNSW internals, or metadata as primary proof is out of scope for this P0 fix. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No `[ASSUMED]` claims are used as planning inputs; all recommendations are from CONTEXT.md, local code/commands, or official docs. | All | None. [VERIFIED: codebase grep] [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html] |

## Open Questions (RESOLVED)

1. **Should not-null/check constraints land in this phase or a follow-up?**  
   What we know: D-02 allows nullable columns for upgrade safety and requires new writes to fail closed. [VERIFIED: CONTEXT.md]  
   RESOLVED: Phase 43 keeps tenant columns nullable in the additive migration for adopter upgrade safety, enforces non-empty tenant scope immediately in `Scoria.Knowledge.Scope`, changesets, and public API paths, and quarantines null-tenant legacy rows from reads. Hard not-null/check constraints are deferred to a post-backfill hardening slice after hosts can provide explicit tenant mappings for historical rows. [VERIFIED: CONTEXT.md] [VERIFIED: PLAN.md]

2. **Should `create_source/1` remain public without options?**  
   What we know: D-03 lists `create_source/1` as a public boundary that must normalize scope. [VERIFIED: CONTEXT.md]  
   RESOLVED: Add opts-aware `create_source/2` so callers can pass `scope:` or tenant/actor/scope shorthand through the same normalization path as other Knowledge write APIs. Keep public `create_source/1` only as fail-closed compatibility that raises without tenant scope rather than silently creating unscoped rows; update tests and call sites to use explicit scoped writes. [VERIFIED: CONTEXT.md] [VERIFIED: PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | ✓ | 1.19.5 / OTP 28 | — [VERIFIED: local command] |
| Mix | Mix tasks/tests | ✓ | 1.19.5 | — [VERIFIED: local command] |
| Docker | pgvector bootstrap fallback | ✓ | 29.5.2 | Existing local DB on `localhost:55432`. [VERIFIED: local command] |
| PostgreSQL server | Knowledge lane | ✓ | `localhost:55432` accepting | `mix scoria.pgvector.bootstrap` can provision. [VERIFIED: local command] [VERIFIED: codebase grep] |
| psql | Manual DB inspection | ✓ | 14.17 | Ecto queries through Mix tasks. [VERIFIED: local command] |
| pgvector extension | Vector tests | ✓ | extension present in `scoria_test` | Docker pgvector service. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none found for planning. [VERIFIED: local command]

**Missing dependencies with fallback:** none found; Docker remains the fallback if local pgvector DB disappears. [VERIFIED: local command] [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix; knowledge tests use `Scoria.KnowledgeCase`. [VERIFIED: codebase grep] |
| Config file | `config/test.exs`; test DB defaults to `localhost:55432`, database `scoria_test`. [VERIFIED: codebase grep] |
| Quick run command | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` once the file exists. [VERIFIED: CONTEXT.md] |
| Full suite command | `MIX_ENV=test mix test.knowledge --warnings-as-errors`; baseline currently passes 13 tests. [VERIFIED: local command] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| KNOW-01 | Migration adds source/chunk tenant columns and required indexes in knowledge migration path | migration/schema integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | ❌ Wave 0 |
| KNOW-02 | Retrieval runs/results/citations persist tenant/actor audit fields | integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | ❌ Wave 0 |
| KNOW-03 | Nil/empty tenant raises across facade, Pgvector, Scrypath, list chunks, ingest | unit/integration | `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` | ❌ Wave 0 |
| KNOW-04 | Tenant A query returns zero tenant B chunks even if B ranks closer | integration | `MIX_ENV=test mix test.knowledge --warnings-as-errors` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` plus the specific changed existing test file. [VERIFIED: CONTEXT.md]
- **Per wave merge:** `MIX_ENV=test mix test.knowledge --warnings-as-errors`. [VERIFIED: local command]
- **Phase gate:** `MIX_ENV=test mix test.knowledge --warnings-as-errors` and any docs/package contract tests touched by docs updates. [VERIFIED: local command] [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `test/scoria/knowledge/tenant_isolation_test.exs` — covers KNOW-01..04. [VERIFIED: CONTEXT.md]
- [ ] `test/scoria/knowledge_lane_contract_test.exs` — update expected file list after adding tenant isolation test. [VERIFIED: codebase grep]
- [ ] Existing knowledge tests currently call APIs without scope and must be updated or intentionally split into raise tests. [VERIFIED: rg]
- [ ] Migration/schema/index assertion helper may be needed for index presence. [VERIFIED: CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Host owns identity; Phase 43 only consumes tenant/actor values. [VERIFIED: PROJECT.md] |
| V3 Session Management | no | No session token behavior is changed. [VERIFIED: CONTEXT.md] |
| V4 Access Control | yes | Tenant-qualified data access, fail-closed nil tenant, cross-tenant tests. [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x12-V4-Access-Control.md] [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Scope helper validates non-empty tenant and allowed scope kinds before writes/reads. [VERIFIED: CONTEXT.md] |
| V6 Cryptography | no | No cryptographic primitive or key management change in this phase. [VERIFIED: CONTEXT.md] |
| V7 Error Handling and Logging | yes | Audit rows persist tenant/actor evidence; failed access decisions should be test-visible and not leak raw data. [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x15-V7-Error-Logging.md] [VERIFIED: CONTEXT.md] |

### Known Threat Patterns For Elixir/Ecto Knowledge Retrieval

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant chunk retrieval through missing tenant filter | Information Disclosure / Elevation of Privilege | Required tenant scope, SQL tenant predicates, and cross-tenant tests. [VERIFIED: REQUIREMENTS.md] |
| IDOR via `chunk_id` or `source_id` lookup | Information Disclosure | Composite tenant-plus-resource lookup at data-access layer. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html] |
| Custom retriever returns another tenant's chunk | Tampering / Information Disclosure | Validate result set against run tenant before insert; reject and persist no mixed rows. [VERIFIED: CONTEXT.md] |
| Citation quote leak | Information Disclosure | Tenant-qualified citation anchor validation and first-class citation scope fields. [VERIFIED: CONTEXT.md] |
| Legacy null-tenant rows returned after migration | Information Disclosure | Quarantine null tenant rows in every read path. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/43-knowledge-tenant-isolation/43-CONTEXT.md` - locked decisions, discretion, deferred ideas, implementation boundaries. [VERIFIED: CONTEXT.md]
- `.planning/REQUIREMENTS.md` - KNOW-01..04 requirement text. [VERIFIED: REQUIREMENTS.md]
- `.planning/PROJECT.md` - v3.4 release hold, scope doctrine, embedded Phoenix constraints. [VERIFIED: PROJECT.md]
- `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/backends/pgvector.ex`, `lib/scoria/knowledge/retrievers/scrypath.ex`, schemas, migrations, and tests - current code topology and leak points. [VERIFIED: codebase grep]
- Local commands: `mix deps`, `mix hex.info`, `MIX_ENV=test mix scoria.pgvector.bootstrap --check`, `MIX_ENV=test mix test.knowledge --warnings-as-errors`. [VERIFIED: local command]

### Secondary (MEDIUM confidence)

- Ecto Migration docs - index options, partial indexes, concurrent index caveats. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html]
- Ecto dynamic query docs - composable `where` / `dynamic` query construction. [CITED: https://ecto.hexdocs.pm/dynamic-queries.html]
- pgvector-elixir README - `Pgvector.Ecto.Vector`, `Pgvector.new/1`, `cosine_distance`, HNSW vector operator classes. [CITED: https://github.com/pgvector/pgvector-elixir]
- OWASP Multi Tenant Security Cheat Sheet - tenant-plus-resource lookups and data-layer ownership checks. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html]
- OWASP Authorization and ASVS docs - fail-safe access control and logging test expectations. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html] [CITED: https://github.com/OWASP/ASVS/blob/master/4.0/en/0x12-V4-Access-Control.md]

### Tertiary (LOW confidence)

- None used as planning inputs. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified against `mix.exs`, `mix.lock`/`mix deps`, and Hex metadata commands; no new dependencies recommended. [VERIFIED: local command]
- Architecture: HIGH - locked by CONTEXT.md and confirmed in local code paths. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]
- Pitfalls: HIGH for current leak points, MEDIUM for external security framing. [VERIFIED: codebase grep] [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Multi_Tenant_Security_Cheat_Sheet.html]

**Research date:** 2026-07-05  
**Valid until:** 2026-08-04 for codebase topology; re-check Hex/doc versions before dependency upgrades. [VERIFIED: local command]

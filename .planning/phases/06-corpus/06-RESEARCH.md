# Phase 6: Advanced RAG, Citations & Knowledge Grounding - Research

**Researched:** 2026-05-11
**Domain:** Phoenix-native knowledge retrieval, citation persistence, and grounding evaluation for Scoria
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Use `Postgres + Ecto + pgvector` as the default retrieval backend.
- Keep backend choice behind a narrow adapter boundary.
- Keep Scrypath optional as a retrieval-source adapter, not the corpus owner.
- Scoria owns durable `Source`, `Chunk`, `Citation`, retrieval-span, and grounding-score nouns.
- Use conservative heading/paragraph-aware chunking with overlap and stable IDs derived from source digest plus offsets.
- Treat ingest, re-embed, and re-index as separate lifecycle steps.
- Retrieval-backed answers use strict inline citations by default.
- Citations must be machine-readable and anchored to durable source/chunk identity.
- Evidence must be inspectable in the answer, the trace, and the dashboard.
- Deterministic evals gate first; judge-based semantic review is second-layer only.
- Judge prompts/models/rubrics must be versioned.
- Operator UX stays trace-first and uses LiveView async loading for heavy evidence payloads.
- Install UX stays boring and additive to `mix scoria.install`.
- Favor ordinary Elixir modules/functions over DSLs.
- Prefer `Scoria.Knowledge` as the public context name.

### Phase Discretion

- Exact field names for corpus and scoring tables.
- Exact UI composition for evidence drilldown.
- Exact install-task wording and flags.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RAG-01 | Provide vector index and chunking abstractions behind a narrow adapter boundary. | `Recommended Project Structure`, `Architecture Patterns`, and `Common Pitfalls` define behaviors and anti-abstraction guidance. |
| RAG-02 | Ship Postgres/Ecto/pgvector as the default retrieval backend. | `Summary` and `Standard Stack` keep pgvector as the boring default while preserving adapter seams. |
| RAG-03 | Persist first-class `Source`, `Chunk`, `Citation`, retrieval-run/result, and grounding-score nouns. | `Recommended Project Structure` and `Architecture Patterns` map the data model and context ownership. |
| RAG-04 | Capture retrieval-backed answers with strict machine-readable citations and trace-visible provenance. | `Architecture Patterns`, `Recommended Data Contracts`, and `Common Pitfalls` define the citation shape. |
| RAG-05 | Add deterministic grounding/citation evals first, with versioned LLM-as-judge scoring second. | `Validation Architecture` and `Recommended Data Contracts` define the evaluation ladder. |
| RAG-06 | Expose retrieval evidence and grounding signals in the existing trace-first dashboard surface. | `Architecture Patterns` and `Operator UX Guidance` keep evidence inside the current LiveView mental model. |
| RAG-07 | Keep Scrypath optional as a retrieval-source adapter, not the corpus owner. | `Summary`, `Alternatives Considered`, and `Common Pitfalls` keep Scrypath behind a normalization boundary. |
| RAG-08 | Preserve simple install and ordinary module/function APIs. | `Recommended Project Structure` and `Operator UX Guidance` keep the surface additive and explicit. |
</phase_requirements>

## Summary

Phase 6 should add a small `Scoria.Knowledge` subsystem that mirrors the repo's existing style: Ecto-backed durable nouns, explicit context functions, thin adapter behaviors, and LiveView projection from persisted rows. The phase should not introduce a broad ingestion platform, a generic search framework, or a graph-first UI.

The cleanest slice sequence is:

1. Add durable corpus and provenance tables plus a `Scoria.Knowledge` context.
2. Add chunking, embedding, and pgvector retrieval behind narrow behaviors with pgvector as the default backend.
3. Persist retrieval runs/results and citation anchors so trace spans and answers share the same provenance contract.
4. Add deterministic citation/grounding evaluators and versioned judge-based review on top of the existing `Scoria.Eval` patterns.
5. Project retrieval evidence into the existing dashboard surface with async evidence loading instead of a second standalone RAG app.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Corpus truth (`Source`, `Chunk`, `Citation`, retrieval rows, grounding scores) | Database / Storage | API / Backend | Existing Scoria phases already use Ecto as durable truth. |
| Chunking, embedding, retrieval orchestration | API / Backend | Database / Storage | These are deterministic pipeline steps with persisted outputs. |
| Trace provenance and citation rendering | API / Backend | Frontend Server | The backend should own citation validity; LiveView should render it. |
| Evidence drilldown and score inspection | Frontend Server (LiveView) | Browser / Client | Current UX patterns use LiveView streams and `assign_async/3`. |
| Judge-based semantic review | API / Backend | Database / Storage | Rubrics and prompts need versioned persistence, not UI-owned state. |

## Standard Stack

### Core

| Library / Layer | Purpose | Why It Fits |
|-----------------|---------|-------------|
| Ecto + PostgreSQL | Durable corpus, retrieval, and scoring records | Matches every shipped Scoria phase. |
| `pgvector` extension + Ecto vector field wrapper | Default embedding storage and nearest-neighbor retrieval | Satisfies the locked backend decision while staying local and boring. |
| Phoenix LiveView | Evidence projection and operator drilldown | Matches the trace-first dashboard model already in the repo. |
| Existing `Scoria.Eval` patterns | Deterministic and versioned evaluation flows | Reuses immutable versioning and promotion conventions already shipped. |

### Supporting

| Layer | Purpose | When to Use |
|-------|---------|-------------|
| Scrypath adapter | Optional retrieval-source normalization | Only when the host app already uses Scrypath and wants Scoria provenance. |
| Existing trace/span schemas | Retrieval-span attachment and provenance lookup | Use instead of creating a second observability model. |
| `mix scoria.install` | Mount additive dashboard affordances | Extend, do not replace. |

## Environment Constraint

- The current local PostgreSQL 14.17 environment does not expose the `vector` extension yet.
- Phase 6 planning therefore needs an explicit Wave 0 bootstrap step that detects or provisions pgvector availability before vector-backed retrieval tests become blocking.
- Retrieval/index APIs should fail with actionable guidance when pgvector is unavailable rather than surfacing opaque database errors.

## Recommended Project Structure

```text
lib/
├── scoria/
│   ├── knowledge.ex
│   └── knowledge/
│       ├── source.ex
│       ├── chunk.ex
│       ├── citation.ex
│       ├── retrieval_run.ex
│       ├── retrieval_result.ex
│       ├── grounding_score.ex
│       ├── chunker.ex
│       ├── embedder.ex
│       ├── citation_formatter.ex
│       ├── grounding.ex
│       ├── backends/
│       │   └── pgvector.ex
│       └── retrievers/
│           └── scrypath.ex
├── scoria_web/
│   ├── components/
│   │   └── citation_evidence_component.ex
│   └── live/
│       └── orchestrator_live.ex
priv/repo/migrations/
└── *_create_knowledge_tables.exs
```

## Recommended Data Contracts

### Durable corpus nouns

- `Source`: stable `entity_id`, digest, kind, URI-ish locator, version, and source metadata.
- `Chunk`: belongs to `Source`, stores canonical text, embedding, offsets, heading path, digest, and freshness metadata.
- `Citation`: belongs to answer/retrieval context, references `Source` and `Chunk`, and stores exact anchor offsets plus rendered label metadata.
- `RetrievalRun`: records the query text, adapter/backend, top-k, filters, trace linkage, latency, and status.
- `RetrievalResult`: stores ranked chunk hits, scores, and normalized provenance for one retrieval run.
- `GroundingScore`: stores deterministic and judge-based score outputs with scorer kind, rubric version, and evidence references.

### Citation shape

Use one internal map shape everywhere:

```elixir
%{
  source_id: source_id,
  chunk_id: chunk_id,
  chunk_digest: chunk_digest,
  start_offset: 120,
  end_offset: 188,
  label: "[1]",
  locator: %{title: title, uri: uri}
}
```

The rendered inline citation string can change later. The durable machine-readable anchor should not.

## Architecture Patterns

### Data flow

```text
source payload
  -> chunker
  -> chunk rows
  -> embedder/backend index write
  -> retrieval query
  -> retrieval_run + retrieval_results
  -> answer citation anchors
  -> deterministic grounding checks
  -> optional judge review
  -> LiveView evidence projection
```

### Context boundary

Keep `Scoria.Knowledge` as the only public context for phase-6 work. It should expose ordinary functions such as:

- `create_source/1`
- `ingest_source/2`
- `reembed_source/2`
- `reindex_source/2`
- `retrieve/2`
- `build_citations/2`
- `score_grounding/2`
- `list_retrieval_results/1`

Adapters such as `Chunker`, `Embedder`, `Backends.Pgvector`, and `Retrievers.Scrypath` should stay internal-facing and replaceable without infecting the public API.

## Operator UX Guidance

- Keep evidence inside the current trace-first dashboard rather than a second RAG application.
- Render retrieval as evidence on or next to a selected trace span.
- Load heavy chunk bodies lazily with `assign_async/3` or stream updates.
- Show unsupported-claim flags and score summaries without forcing operators to leave the trace surface.
- Keep installation additive: extend existing router/install behavior only if a new panel or route is truly needed.

## Common Pitfalls

- Do not treat embeddings, re-indexing, and chunk persistence as one transactional illusion. The context explicitly rejects that.
- Do not let Scrypath become the source of truth for corpus rows.
- Do not store citations as rendered text only.
- Do not make judge-based scores the sole gate for correctness.
- Do not dump full retrieved bodies into long-lived LiveView socket assigns.
- Do not create a DSL for declaring corpora, retrievers, or citation formats.

## Validation Architecture

### Deterministic gate first

Add deterministic checks that can run in CI and on local test suites:

- Citation presence.
- Citation validity against existing `Chunk` / `Source` rows.
- Citation span membership (`start_offset` and `end_offset` inside the cited chunk).
- Unsupported-claim checks against retrieved evidence.
- Retrieval hit/rank metrics when labeled fixtures exist.

### Judge review second

Use versioned rubric storage for semantic groundedness review:

- Persist rubric version and prompt metadata alongside scores.
- Store per-score evidence references and reasoning payloads.
- Allow judge review to fail softly without replacing deterministic gate outcomes.

### Test strategy

- Unit-test chunking, citation validation, and deterministic scorers.
- Context tests should prove `Ecto.Multi` boundaries for ingest/reindex/retrieve persistence.
- LiveView tests should assert async evidence loading and rendered provenance state.

## Alternatives Considered

| Option | Why Not Default |
|--------|------------------|
| External vector DB first | Violates the locked boring-local default. |
| Scrypath as corpus owner | Conflicts with the explicit optional-adapter decision. |
| Graph-first evidence UI | Conflicts with the trace-first dashboard mental model. |
| Citation text-only rendering | Cannot support challengeable provenance. |

## Resolved Execution Choices

- Store embeddings directly on `Chunk` rows for Phase 6. If row size becomes a later pain point, split to a sibling table in a future phase rather than paying the indirection cost now.
- Land the first evidence UX inside `OrchestratorLive` with an additive `CitationEvidenceComponent`, not a new standalone LiveView.
- Start unsupported-claim detection with exact substring and sentence-level citation coverage heuristics. Defer broader semantic claim matching to later judge-assisted iterations.

## RESEARCH COMPLETE

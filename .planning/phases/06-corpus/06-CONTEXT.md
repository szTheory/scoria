# Phase 6: Advanced RAG, Citations & Knowledge Grounding - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide batteries-included RAG primitives that integrate with Scoria's trace tree and Eval Workbench. Phase 6 owns retrieval, citations, grounding signals, and the developer/operator experience around them. It does not become a generic ingestion platform or a broad framework for search/connectors.

</domain>

<decisions>
## Implementation Decisions

### Retrieval backend
- **D-01:** Ship `Postgres + Ecto + pgvector` as the default retrieval backend.
- **D-02:** Keep retrieval backend choice behind a narrow adapter boundary so Scoria can stay pluggable without becoming abstract-first.
- **D-03:** Keep Scrypath as an optional retrieval-source adapter, not the corpus owner or required dependency.

### Corpus and chunk lifecycle
- **D-04:** Scoria should own durable `Source`, `Chunk`, `Citation`, retrieval span, and grounding-score nouns.
- **D-05:** Use a conservative chunking default: heading/paragraph-aware chunking with overlap and stable IDs derived from source digest plus offsets.
- **D-06:** Ingest, re-embed, and re-index are separate lifecycle steps; do not pretend indexing is transactional truth.

### Citation contract
- **D-07:** Retrieval-backed answers should use strict inline citations as the blessed default contract.
- **D-08:** Citations must be machine-readable and anchored to durable source/chunk identity, not rendered text only.
- **D-09:** The answer should be inspectable if challenged: citations in the answer, evidence in the trace, and provenance visible in the dashboard.

### Grounding and evals
- **D-10:** Deterministic evals come first in CI and gating: citation presence, citation validity, chunk membership, unsupported-claim checks, and retrieval hit/rank metrics when labels exist.
- **D-11:** LLM-as-judge groundedness scoring is a second layer for semantic review, not the only gate.
- **D-12:** Judge prompts/models/rubrics must be versioned so eval output is reproducible.

### Operator UX
- **D-13:** The dashboard should expose retrieval query, returned chunks, scores/freshness, citation hover or side-by-side evidence, unsupported-claim flags, scorer output, and replay/promote actions.
- **D-14:** Use LiveView streaming and async loading for large evidence lists; do not load all retrieved bodies into socket state.
- **D-15:** Keep the existing trace-first mental model. Retrieval is evidence inside the trace, not a separate graph-first product surface.

### Install and API shape
- **D-16:** Keep install UX boring and local to the existing `mix scoria.install` / dashboard path.
- **D-17:** Favor ordinary Elixir module/function APIs over a DSL or configuration maze.
- **D-18:** Bless `Scoria.Knowledge` or `Scoria.Retrieval` as the public context name; treat `Corpus` as the milestone theme, not the primary API noun.

### the agent's Discretion
- Exact schema field names for `Source`, `Chunk`, `Citation`, and scoring records.
- Exact UI layout and visual treatment for evidence inspection.
- Exact install flag naming and generator text, so long as the UX remains simple.

</decisions>

<specifics>
## Specific Ideas

- The user wants the phase to feel like a coherent whole, not a menu of loosely related features.
- The user explicitly wants strong developer ergonomics, least surprise, and user-friendly operator experience where applicable.
- The user asked to incorporate the long-form prompt research in `prompts/` wherever relevant, especially the RAG, eval, and brand/vision material.
- The user wants low-impact choices pushed left into defaults unless they are materially important to the product vision.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone intent
- `.planning/ROADMAP.md` - phase boundary and milestone placement for Phase 6
- `.planning/MILESTONES.md` - v1.2 Corpus goals, especially the RAG and grounding scope
- `.planning/milestones/v1.1-MILESTONE-PROPOSALS.md` - decision history and tradeoff framing for the Corpus milestone
- `.planning/STATE.md` - current project state and locked preferences

### Prior phase context and patterns
- `.planning/phases/05-caldera/05-CONTEXT.md` - durable workflow, trace-first, and adapter-boundary decisions that Phase 6 must align with
- `.planning/PATTERNS.md` - existing code patterns, especially Ecto context style and LiveView boundaries
- `.planning/RESEARCH.md` - prior research synthesis for the project
- `.planning/MEMORY.md` - durable project memory, including Scrypath and RAG synergies
- `.planning/memory/scrypath-rag-synergy.md` - explicit RAG/Scrypath integration seed

### RAG, eval, and product vision
- `prompts/phoenix-ai-lib-deep-research.md` - RAG nouns, eval loop, grounding, citations, and observability guidance
- `prompts/scoria-brand-book-deep-research.md` - brand voice, trust builders, motion/style guidance, and evidence-first product framing
- `prompts/scoria-gsd-kickoff.md` - original Scoria product thesis and scope
- `prompts/sztheory-elixir-dna.md` - ecosystem and architecture constraints
- `prompts/scoria-brand-book-deep-research.md` - specific product/UX language for the trace-and-evidence experience

### Current code surface
- `lib/scoria/eval.ex` - immutable dataset/eval patterns and transactional updates
- `lib/scoria/workflows.ex` - `Ecto.Multi`, durable state transitions, and trace-first persistence style
- `lib/scoria_web/router.ex` - embedded router macro pattern
- `lib/scoria_web/live/orchestrator_live.ex` - LiveView streaming, async loading, and dashboard projection style
- `lib/mix/tasks/scoria.install.ex` - install UX baseline and generator style

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Eval` already models versioned, immutable records and promotion flows; that pattern fits versioned corpora, chunks, and citation/eval records.
- `Scoria.Workflows` already uses `Ecto.Multi` and durable transaction boundaries; that pattern should carry into ingest, re-embed, and score writes.
- `ScoriaWeb.OrchestratorLive` already uses LiveView streaming and async loading; that is the right shape for evidence-heavy retrieval inspection.
- `Mix.Tasks.Scoria.Install` already provides the project’s install baseline; phase 6 should extend rather than replace it.

### Established Patterns
- Ecto is the durable source of truth, with PubSub and LiveView used only as projections.
- The product favors explicit nouns and transactional writes over magic background orchestration.
- The dashboard is trace-first, not graph-first.

### Integration Points
- Retrieval evidence should appear inside the existing dashboard surface and trace tree model.
- Retrieval and grounding data should participate in the same promotion/eval loop used elsewhere in Scoria.
- The install path should continue to mount into host Phoenix apps without forcing a second embedded app surface.

</code_context>

<deferred>
## Deferred Ideas

- External vector databases as a first-party dependency.
- A broad document ingestion/connectors platform.
- Agentic query planning or automatic citation synthesis as a default behavior.
- A second standalone embedded UI surface for RAG.
- Semantic chunking as the first and only chunking strategy.

</deferred>

---

*Phase: 06-corpus*
*Context gathered: 2026-05-11*

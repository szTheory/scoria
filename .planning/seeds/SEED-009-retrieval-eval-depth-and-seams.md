---
id: SEED-009
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as RAG / knowledge / retrieval quality — sequence after SEED-006
scope: medium
priority: medium
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-009: Retrieval Eval Depth & Seams

## Why This Matters

[[SEED-006]] closes the P0 knowledge security hole + the worst RAG-scoring bugs. This seed builds the
*depth*: Scoria's RAG scoring is currently lexical/structural only (`Knowledge.Grounding`: recall@k,
MRR, citation anchor-integrity — the anchor/digest tamper-check is genuinely strong — but faithfulness
is a token-subset heuristic, and there's no precision@k/NDCG/reranking/abstention/answer-relevance). A
retriever can pass while being semantically wrong.

## When to Surface

**Trigger:** RAG/knowledge quality milestone, **after [[SEED-006]]** (which adds tenant scoping + fixes
`score_chunk`/`citation_presence`/chunker bugs this seed builds on).

## Scope Estimate

**Medium.** Within `lib/scoria/knowledge/**`. Split by ownership: model-free scorers = BUILD (Scoria's
job); model-requiring scorers = DELEGATE hook (host's model).

## What to build

1. **Model-free retrieval metrics (BUILD).** Add `precision@k` + `ndcg`/graded-relevance to sit beside
   the existing recall@k + MRR — the missing half of the *standard* deterministic set, no model, cheap,
   symmetric with what's there. NDCG needs graded labels (extend `expected_chunk_ids` → `{chunk_id, gain}`).
   *Peer: Arize Phoenix ships Precision@K/NDCG@K/MRR/Recall@K/Hit-Rate as the canonical set.*
2. **Abstention / unanswerable scoring (BUILD).** A deterministic `abstention` scorer (refusal vs
   hallucination vs gold-leak) for "no answer in corpus" cases — Scoria-owned. Requires a **small labeled
   answerable/unanswerable fixture** (ship a tiny one for the harness; do NOT ship a full benchmark corpus
   — that's host data/domain). *Peer: arXiv "Unanswerability Evaluation for RAG" (2412.12300).*
3. **Faithfulness / answer-relevance as host-supplied scorers (DELEGATE+DOC).** Do NOT ship an NLI/LLM
   model in-lib (violates P5/P6 — Scoria ships no provider/keys). Formalize a `faithfulness`/
   `answer_relevance` `scorer_kind` **contract over the existing `judge_result` hook** (`maybe_append_judge_score`)
   — host supplies the NLI/LLM verdict, Scoria records/versions it. Relabel the current lexical
   `unsupported_claims` as an explicit *prefilter*, not faithfulness. *Peers: Ragas faithfulness = claim
   decomposition → NLI entailment; TruLens groundedness; Phoenix hallucination judge — all run a model.*
4. **Reranker hook (DELEGATE+DOC / DEFER model).** Retrieval is single-stage cosine only. Add a `reranker`
   hook applied after `similar_chunks` (identity default); defer shipping a cross-encoder (a second model =
   host territory). *Peer: LlamaIndex two-stage bi-encoder recall → cross-encoder rerank.*
5. **Query-time staleness filter (FIX/BUILD).** `Source` is versioned (`is_current`) but retrieval never
   filters it → superseded versions stay retrievable. Add a default-on `is_current` filter (opt-out for
   point-in-time eval reproducibility); chunks table needs a join to source.
6. **Real sliding-window overlap chunker (DEFER/BUILD).** [[SEED-006]] removes the `Chunker.Default` overlap
   no-op and documents Default as section-based/non-overlapping; real fixed-size-with-overlap belongs in a
   *separate* windowing chunker (offsets feed `chunk_digest`/`citation_validity`, so blast radius is real —
   keep it out of the P0 sweep).

## Disagreements with the memo (recorded)
- Faithfulness: DISAGREE with "ship an LLM-judge/NLI faithfulness scorer in-library" — ship the seam, not
  the model.
- Reranking: DISAGREE with "core cross-encoder reranking" — provide the hook, defer the model.
- Gold set: agree Scoria ships a *tiny* answerable/unanswerable fixture for its own harness; disagree with
  shipping a full benchmark corpus (host's data/domain).

## Scope doctrine reference
P2 + P5/P6: Scoria owns the *scoring/recording mechanism* (model-free metrics + scorer_kind contracts);
the *models* (NLI, cross-encoder, embeddings) are the host's — Scoria provides hooks, not models.

## Breadcrumbs
- `lib/scoria/knowledge/grounding.ex` (add precision/NDCG/abstention; relabel unsupported_claims),
  `lib/scoria/knowledge.ex` (`score_grounding/2`, `maybe_append_judge_score` seam),
  `lib/scoria/knowledge/backends/pgvector.ex` (reranker hook point; staleness filter),
  `lib/scoria/knowledge/chunker.ex` (windowing chunker), `lib/scoria/knowledge/grounding_score.ex`,
  `priv/repo/knowledge_migrations/...create_knowledge_tables.exs` (graded-label / is_current join support).
- Source memo §10. Full audit: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`. Related: [[SEED-006]] (P0 knowledge fixes), [[SEED-007]] (RETRIEVER span).

## Notes
Planted during v3.3 from a 6-agent adjudicated audit. Peer precedent: Ragas, Arize Phoenix RAG evals,
TruLens RAG triad, LlamaIndex two-stage retrieval.

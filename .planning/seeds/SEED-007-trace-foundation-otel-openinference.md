---
id: SEED-007
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as observability / eval / interoperability — sequence after SEED-006
scope: medium-large
priority: high
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-007: Trace Foundation — OTel-GenAI / OpenInference Interop

## Why This Matters

Tracing is the **foundational gap**: scorers, eval attribution, and regression detection all read
spans, but Scoria's trace store is a thin generic 3-table shape (`ai_traces` = session_id+attributes
map; `ai_spans` = name/span_kind/status/times/attributes; `ai_span_events` = **dead schema, never
written**). Only 2 adapters emit spans, model config (temp/top_p/seed) is uncaptured, and no
structured event vocabulary exists. So an eval can only see a flat `attributes` blob — it cannot
attribute a quality delta to a prompt version, a retrieval config, or a temperature change. Also:
the README claims "OpenInference-style trace capture" but only the redaction half is real — an
overclaim in a pre-1.0 lib whose whole pitch is clear boundaries.

**The reframe that de-risks this:** Scoria's own UI already hardcodes the span-kind vocabulary
`llm tool prompt mcp retriever guardrail eval agent`
(`lib/scoria_web/components/workflow_tree_component.ex:38`) — almost exactly the OpenInference/
OTel-GenAI taxonomy. The schema intent is **already half-designed**; the emitters just don't
populate it. This is "finish the thing you already designed," not a rewrite.

## When to Surface

**Trigger:** next observability/eval/interop milestone, **after [[SEED-006]]** (P0 fixes first).
Foundational — sequence before the eval-depth seed ([[SEED-008]]).

## Scope Estimate

**Medium-Large.** Mostly `lib/scoria/observe/**` + the two adapters + resurrecting one dead schema.
The key discipline: **adopt semconv as a NAMING CONVENTION over the existing `attributes` map, NOT
as typed columns** — rigid columns invite migration churn pre-1.0; conventional key names are free
portability.

## What to build

1. **OTel-GenAI/OpenInference key convention (BUILD).** Name the existing `attributes` map keys
   conventionally (`gen_ai.request.model`, `gen_ai.request.temperature/top_p/max_tokens`,
   `gen_ai.usage.*`, `openinference.span.kind`) and **populate `span_kind` correctly** — the two
   adapters currently emit only `"LLM"`/`"INTERNAL"` while the UI expects 8 kinds. Portability is the
   embedded win: the host can export to Phoenix/Langfuse/any OTel backend — "your traces aren't locked
   into Scoria." Directly answers the memo's "eval vendors change; keep data portable" warning.
   *Peers: OpenInference = conventional attr names on OTel spans; Langfuse/LangSmith emit/ingest OTel natively.*
2. **Capture model config on LLM spans (BUILD).** temp/top_p/seed/max_tokens — currently NOT captured
   anywhere (only a hardcoded `max_tokens: 2048` in `ui_critique.ex`). Scoria positions on
   replay/recovery; replay without model params is silently broken. Params already sit in ReqLLM request
   opts; the adapter just doesn't thread them into the span.
3. **Structured span/event emission (BUILD).** Emit `tool`/`prompt`/`retrieval`/`guardrail` as proper
   child **spans** keyed by `span_kind` (peers model these as span *kinds*, not events). Resurrect the
   dead `ai_span_events` table **minimally** — for the true point-events only (`prompt_rendered`,
   `guardrail_triggered`, `user_feedback_received`). Do NOT force the whole vocabulary into span_events
   (that would be a worse model than every peer).
4. **Retrieval as a linked span + config fields (BUILD partial + KEEP table).** Emit a linked
   `RETRIEVER` span (the `ai_retrieval_runs` table already has `trace_id`/`span_id` columns — plumbing
   exists, just unemitted) and add `embedding_model`/`index_version`/`reranker` fields. **KEEP
   `ai_retrieval_runs` as system-of-record** — it's richer than a generic span (grounding scores, typed
   results); dual-write span-for-visibility + table-for-detail. Do not collapse it.
5. **README accuracy fix (DOCS — can ship immediately).** Soften "OpenInference-style trace capture"
   to "redaction + OTel-shaped spans" now; flip to "OpenInference-compatible" once (1) ships.

## Disagreements with the memo (recorded)
- The memo (hosted-SaaS lens) wants everything normalized into spans; for Scoria's embedded Knowledge
  subsystem the separate `ai_retrieval_runs` table is *richer and better* — don't collapse it.
- "Adopt OTel-GenAI" is over-engineering **only if** read as typed columns. As a naming convention over
  the existing map it's free portability. Adjudicate as convention-adoption, not schema-replacement.

## Scope doctrine reference
P5 (reconstructable/inspectable in the host's own DB, zero required egress) + P6 (BEAM-native; don't
build a metrics warehouse) — OTel interop is a *hook at the edges*, letting the host export to its own
Datadog/Langfuse for warehousing, NOT Scoria becoming an analytics platform.

## Breadcrumbs
- `lib/scoria/observe/adapters/req_llm.ex` (only LLM-span source; add model config + `gen_ai.*` keys),
  `lib/scoria/observe/telemetry.ex` (span/event ingestion + redaction; event hook point),
  `lib/scoria/observe/buffer.ex` (batch insert — spans only today),
  `lib/scoria/repo/span_event.ex` (dead schema to resurrect minimally),
  `lib/scoria/knowledge/retrieval_run.ex` (has trace_id/span_id; needs RETRIEVER-span emission + fields),
  `lib/scoria_web/components/workflow_tree_component.ex:38` (the de-facto span-kind vocabulary contract),
  `README.md:272` (the "OpenInference-style" overclaim).
- Source memo §7. Full audit: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`. Related: [[SEED-006]], [[SEED-008]], [[SEED-005]] (README claim fix).

## Notes
Planted during v3.3 from a 6-agent adjudicated audit. Peer precedent: OTel-GenAI spans/events semconv,
OpenInference (Arize Phoenix), Langfuse + LangSmith (both OTel-native). This is the layer [[SEED-008]]
(eval depth) and [[SEED-009]] (retrieval depth) will read.

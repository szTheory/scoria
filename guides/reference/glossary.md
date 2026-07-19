# Glossary

This glossary is the adopter-facing vocabulary source of truth for Scoria's public docs, examples, and dashboard copy.

## Core terms

### Run

A durable Scoria execution record for one unit of AI work.

- Industry equivalent: workflow run, agent run, or trace root.
- Use when you mean the exact execution handle stored by Scoria, such as `run_id`.
- Do not use when you mean a long-lived chat session or host-owned business object.
- Related APIs/docs: `Scoria.start_run/2`, `Scoria.resume_run/2`, `Scoria.get_run/1`.

### Reviewer

The human inspecting tenant-scoped runs, approvals, traces, eval results, and incidents in Scoria's dashboard.

- Industry equivalent: operator, approver, reviewer, or support engineer.
- Use when naming the person using Scoria's inspection and decision surfaces.
- Do not use as a tenant authority source; the host app owns authentication and authorization.
- Related APIs/docs: `ScoriaWeb.ReviewerSurface`, dashboard scope resolver docs.

`operator` remains a legacy/persona alias for `reviewer` in 0.1.x compatibility text and historical docs. Use `operator` only for an explicit SRE/on-call job sense or legacy mapping.

### Trace

The reviewer-visible execution story of a run: spans, model calls, retrievals, tool calls, approvals, eval scores, replay branches, semantic cache checks, and workflow inspection.

- Industry equivalent: trace or span tree in OpenTelemetry/OpenInference-compatible observability.
- Use when describing run inspection surfaces and execution flow.
- Do not use to rename stored proof fields such as `evidence_refs`.
- Related APIs/docs: workflow detail page, trace components, `Scoria.get_run_detail/1`.

Scoria records OpenTelemetry-GenAI / OpenInference-compatible convention keys (`gen_ai.*`,
`server.*`, `openinference.span.kind`) in your host Postgres, pinned to OpenTelemetry GenAI
semantic-conventions schema 1.37.0 (via `req_llm ~> 1.13`; these GenAI conventions are still
experimental upstream). Scoria is not an OpenTelemetry exporter — sending these traces onward
to Langfuse, Datadog, or Arize Phoenix is host-owned and opt-in. See [Trace
Observability](guides/capabilities/trace-observability.md).

### Evidence

Support or proof material attached to a run, incident, eval score, retrieval, citation, or grounding decision.

- Industry equivalent: audit evidence, citation evidence, grounding evidence, or support proof.
- Use for RAG/citation evidence, grounding evidence, `evidence_refs`, policy proof, breaker evidence, budget evidence, and audit evidence.
- Do not use as the top-level name for a reviewer-facing run inspection surface; use `trace`.
- Related APIs/docs: eval score evidence, knowledge citations, incident support proof.

RAG/citation evidence and `evidence_refs` are unchanged evidence vocabulary. Do not introduce a trace-reference storage field or rename stored evidence fields during this terminology migration.

### Capability

An adoption surface that can be added after the default runtime is working.

- Industry equivalent: feature area or integration capability.
- Use when discussing optional Scoria surfaces such as bounded handoff, semantic cache, optional knowledge base, and remote connectors.
- Do not use `lane` for adopter-facing capability grouping.
- Related APIs/docs: adoption guides, connector guide, knowledge guide.

### Verification suite

A proof command contract that verifies an adoption or maintainer surface.

- Industry equivalent: test suite, conformance suite, or release gate.
- Use for commands such as `$ mix test.adoption`, `$ mix test.runtime_to_handoff`, and `$ mix scoria.release_preview`.
- Do not call these proof commands verification lanes in new adopter-facing docs.
- Related APIs/docs: `Scoria.VerificationSuites`, reviewer verification guide.

### Scoped context

The deliberately bounded subset of host context passed into a same-run handoff.

- Industry equivalent: scoped prompt context or constrained delegation context.
- Use for public handoff inputs that the host intentionally curates.
- Do not use to imply full transcript, socket state, provider session, or secret transfer.
- Related APIs/docs: `scoped_context:`, `projected_context:` compatibility alias, `Scoria.start_handoff_run/3`.

### Semantic cache

An opt-in, tenant-partitioned reuse path for explicitly safe read-only work.

- Industry equivalent: semantic response cache or embedding-backed cache.
- Use when describing cache profiles and cache hits/misses.
- Do not describe it as a generic fast path for arbitrary writes or unsafe work.
- Related APIs/docs: `Scoria.SemanticCache.Profile`, `Scoria.SemanticLane` compatibility alias, `semantic_cache: [profile: MyApp.CacheProfile]`.

### Knowledge base

An optional retrieval and grounding surface backed by host-selected knowledge content.

- Industry equivalent: RAG knowledge base, retrieval corpus, or vector store-backed corpus.
- Use when the adopter intentionally enables retrieval, citations, and grounding.
- Do not imply knowledge base setup is required for the default runtime.
- Related APIs/docs: optional knowledge verification suite and retrieval/grounding docs.

### Grounding

The act of tying model output or a decision back to cited support material.

- Industry equivalent: citation grounding, retrieval grounding, or source attribution.
- Use for RAG and citation proof.
- Do not rename grounding evidence to trace evidence.
- Related APIs/docs: knowledge base docs, citation evidence, eval support proof.

### Bounded handoff

A same-run delegation to another role with host-curated input and scoped context.

- Industry equivalent: constrained handoff, delegated subtask, or workflow branch.
- Use when one role delegates a narrow slice of work inside the same durable run.
- Do not use when starting a separate host workflow or copying broad runtime state.
- Related APIs/docs: `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`.

## Legacy and industry equivalents

| Legacy or adjacent term | Final Scoria term | Compatibility note |
|-------------------------|-------------------|--------------------|
| operator | reviewer | Legacy/persona alias in 0.1.x; use reviewer in new public copy. |
| projected context | scoped context | `projected_context:` remains accepted as a compatibility alias. |
| semantic fast path | semantic cache | Existing guide filename may remain during migration; new concept language is semantic cache. |
| optional knowledge | optional knowledge base | Use knowledge base when naming the optional retrieval/grounding capability. |
| adoption/capability lane | capability | Use capability for adopter-facing optional surfaces. |
| proof/verification lane | verification suite | Use verification suite for proof commands. |
| surface-sense evidence | trace | Use trace for reviewer-facing run inspection surfaces. |
| RAG/citation evidence | unchanged evidence | Evidence remains correct for citations, grounding, and `evidence_refs`. |

## Compatibility aliases

The following old names and options remain accepted during the 0.1.x compatibility window:

- `ScoriaWeb.OperatorSurface` delegates to `ScoriaWeb.ReviewerSurface`.
- `Scoria.Observe.OperatorBroadcast` delegates to `Scoria.Observe.ReviewerBroadcast`.
- `Scoria.VerificationLanes` delegates to `Scoria.VerificationSuites`.
- `Scoria.SemanticLane` remains accepted as a semantic cache profile compatibility surface.
- `lane:` remains accepted where new docs prefer `profile:`.
- `lane_key` remains the stored semantic cache key field and is not renamed.
- `projected_context:` remains accepted where new docs prefer `scoped_context:`.

Compatibility aliases are naming bridges only. They do not create a database migration, rename `evidence_refs`, rename `lane_key`, or change tenant authority. Host apps still own identity, policy values, authorization, and business truth.

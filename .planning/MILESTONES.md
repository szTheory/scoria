# Milestones

## v2.3 Runtime-to-handoff adoption example

**Shipped:** 2026-05-27

**Phases completed:** 3 phases, 9 plans, 20 tasks

**Key accomplishments:**

- Runtime-to-handoff example contract using the existing Scoria public facade, with projected-context safety boundaries and a passing docs/source baseline.
- Phoenix runtime guide and DB-backed tests now prove the public-facade path from a default Scoria run into a bounded handoff with curated delegated readback.
- Bounded handoff docs now pin host-owned projected-context selection, Scoria-owned validation/readback, and unsafe context rejection before durable delegated run creation.
- Delegated evidence now presents the approved default-lane empty-state contract while retaining curated pending-state and populated delegated lineage behavior.
- Adopter-facing docs now consistently describe default runtime as first adoption and bounded handoff as explicit same-run escalation, with unchanged public API boundaries.
- Phase 53 now has executable drift guards that fail when docs regress default-first lane wording, expose internals, or drop key public facade/readback fragments.
- Added an executable runtime-to-handoff verification lane with enforceable bounded-file and no-optional-prereq contracts.
- Aligned README, support guides, and drift tests on one canonical runtime-to-handoff command contract with explicit lane-boundary truth.
- Finalized closeout truth by aligning CI and operator command order, then capturing executed evidence for all Phase 54 requirements.

**Known deferred items at close:** 3 (Nyquist validation ledgers remain partial; see `.planning/milestones/v2.3-MILESTONE-AUDIT.md`)

---

## v2.1 Tenant-scoped semantic fast path

**Shipped:** 2026-05-25
**Phases:** 3 | **Plans:** 12 | **Tasks:** 28
**Theme:** Inspectable semantic caching for safe read-only lanes

### Delivered

Scoria now ships a tenant-scoped semantic fast path as durable, operator-visible truth: explicitly safe read-only lanes can reuse answers only when prompt, policy, source, freshness, and scope compatibility all pass, while misses, rejects, stale entries, and invalidations remain visible and fall back through the normal workflow path.

### Key Accomplishments

- Added durable semantic cache entry and event truth with explicit hit, miss, bypass, and writeback rejection outcomes.
- Established an explicit semantic-lane contract and conservative eligibility engine for safe read-only runtime work.
- Implemented exact-first plus compatibility-filtered semantic lookup with durable `active`, `stale`, `invalidated`, and `writeback_rejected` lifecycle states.
- Projected semantic provenance, compatibility, and fallback evidence into runtime detail, the runtime drawer, and the workflow notebook.
- Shipped `mix test.semantic_fast_path` as the canonical bounded proof lane and aligned operator docs/source assertions to the same semantic vocabulary.

**Known deferred items at close:** 0

---

## v2.0 Relay

**Shipped:** 2026-05-25
**Phases:** 4 | **Plans:** 11 | **Tasks:** 22
**Theme:** Bounded public handoff proof and clean closeout

### Delivered

Scoria now ships the bounded public handoff lane as explicit, milestone-quality truth: `Scoria.start_handoff_run/3` stays same-run rooted, projected context is narrow and reject-by-default for unsafe state, delegated lineage is inspectable in runtime and workflow surfaces, and the adoption lane plus full suite close on a green verification baseline.

### Key Accomplishments

- Locked the explicit bounded handoff contract with durable delegated kind, handoff input truth, and same-run lineage.
- Hardened recursive projected-context rejection so unsafe nested runtime/session state fails explicitly instead of slipping through.
- Added curated delegated evidence projection and workflow UI surfaces for inspectable lineage, status, and projected context.
- Re-aligned README, bounded handoff docs, checked source fragments, and operator wording around one runtime-first adoption story.
- Preserved `mix test.adoption` as the canonical bounded-handoff proof lane and recorded the Relay closeout ledger against it.
- Restored a fresh full-suite `mix test` pass before ship by fixing offline eval contract drift and sparse approval metadata crashes.

**Known deferred items at close:** 0

---

## v1.9 Crucible

**Shipped:** 2026-05-24
**Phases:** 4 | **Plans:** 18
**Theme:** Replayable debugging and online quality feedback

### Delivered

Scoria now ships a closed operator remediation loop: durable replay branches, replay-safe execution, replay comparison and dataset promotion from workflow evidence, plus asynchronous online scoring that routes reviewable candidates into an embedded operator queue.

### Key Accomplishments

- Added durable replay-branch lineage rooted in checkpoint truth without mutating source run history.
- Enforced replay-safe seam behavior with explicit blocked, historical-stub, and replay-live provenance across workflow, connector, and MCP boundaries.
- Shipped replay comparison UX and frozen workflow-source draft promotion through the existing LiveView operator surface.
- Added async sampled-trace online scoring with deterministic-first and optional judge-backed additive evidence.
- Built a dedicated operator review queue with workflow/runtime deep links, dismissal, draft promotion, and sealed-baseline approval flow.
- Restored the canonical proof chain for all four v1.9 phases and reconciled milestone-state planning surfaces to shipped truth.

**Known deferred items at close:** 3 (project-level full-suite failures outside the owned lanes, connector/compaction warnings, and LiveView async teardown noise)

---

## v1.8 Vanguard

**Shipped:** 2026-05-22
**Phases:** 7 | **Plans:** 19
**Theme:** Multi-model orchestration and distributed evaluations

### Delivered

Scoria now ships resilient multi-model routing with ETS-backed breaker truth, distributed evaluation campaign fan-out through Oban, and a real-time operator dashboard that makes fallback and campaign progress visible without leaving Phoenix.

### Key Accomplishments

- Established isolated `system`, `inference`, and `evals` queues plus batch enqueue primitives for high-volume background work.
- Added circuit breakers, bounded retries, and fallback-chain orchestration across summarization and judge flows.
- Built durable eval campaign, target, and run lineage with coordinator fan-out and worker rollups.
- Shipped tenant-scoped LiveView model-health and campaign dashboards with eval-run drill-in.
- Restored the full canonical v1.8 verification chain and closed the orphaned requirement gaps.
- Reconciled roadmap, state, project, milestone, and strategic-arc surfaces to shipped truth.

**Known deferred items at close:** 1 (Nyquist frontmatter normalization for Phases 30-32 if they re-enter audit scope)

---

## v1.7 Outrider

**Shipped:** 2026-05-20
**Phases:** 3 | **Plans:** 7
**Theme:** Advanced ecosystem integrations and future-bet runtime surfaces

### Delivered

Scoria now supports out-of-process multi-runtime integration capabilities (using MCP over HTTP/SSE) and an asynchronous memory compaction engine via Oban. This allows Scoria to orchestrate external runtimes, efficiently manage long-running session history without context bloat, and track agent presence visually via Phoenix LiveView.

### Key Accomplishments

- Established an HTTP/SSE boundary implementing the MCP Server specification.
- Built an asynchronous Oban-backed memory compaction worker tracking `compacted_memories`.
- Wired external agent health liveliness natively via Phoenix Presence.
- Shipped an updated LiveView Operator UX capable of memory time-travel and displaying agent connection statuses.

**Known deferred items at close:** 0

---

## v1.6 Flightpath

**Shipped:** 2026-05-19
**Phases:** 4 | **Plans:** 12
**Theme:** Release gates, prompt lifecycle, and evaluation operations

### Objectives

Provide a unified prompt lifecycle and evaluation operations suite. Operators should be able to turn traces into datasets, developers should be able to run offline VCR-backed ExUnit evals, and organizations should be able to enforce release gates before a prompt goes live.

### Scope

- **Ecto-backed Prompt Registry:** Immutable versioning and lifecycle for prompts.
- **Trace-to-Dataset Curation:** Elevate real traces into baseline datasets via the dashboard.
- **CI/CD Regression & Evals:** Integration with `mix test`, ExUnit, and VCR cassettes.
- **Release Gates:** Tie EvalRun evidence to Scoria's workflow primitives for operator approvals.

---

## v1.5 Switchyard

**Shipped:** 2026-05-18
**Phases:** 4 | **Plans:** 9
**Theme:** Tool and MCP connector productization

### Delivered

Scoria now productizes remote MCP connector adoption as an embedded Phoenix capability with stateless-first defaults, policy-backed tool scopes, workflow-owned approvals, and operator-grade audit visibility.

### Key Accomplishments

- Established the Scoria-owned remote connector boundary with durable connector records, boring discovery defaults, and auth/grant storage.
- Enforced dual-plane policy, stable local tool identity, and stateless-first invocation defaults.
- Extended Scoria's workflow-owned approval and evidence model into remote connector scenarios with operator-grade visibility.
- Shipped a curated connector profile layer with boring adoption paths.

**Known deferred items at close:** 0

---

## v1.4 Keystone

**Shipped:** 2026-05-17
**Phases:** 7 | **Plans:** 22
**Theme:** Embedded app defaults, identity, and public runtime surface

### Delivered

Scoria now ships a Phoenix-facing runtime surface with canonical actor, tenant, and session identity, a public `Scoria` lifecycle API, predictable defaults and install ergonomics, adoption docs aligned to real runtime behavior, and executable guardrails that keep the public integration story from drifting.

### Key Accomplishments

- Added one canonical runtime identity contract and propagated it across workflows, approvals, telemetry, and audit evidence.
- Promoted `Scoria` into the public runtime facade for start, resume, inspect, and session-aware run access.
- Added documented provider/model/prompt-policy defaults with identity-aware composition and boring install defaults.
- Rewrote the README, moduledocs, Phoenix example, and operator verification flow around the shipped public boundary.
- Backfilled the missing canonical verification chain for Phases 12 through 15 and reconciled live milestone-state artifacts.
- Added executable adoption guardrails, including the named `mix test.adoption` lane, to keep docs aligned with checked runtime truth.

**Known deferred items at close:** 3 (see STATE.md Deferred Items)

## v1.0 MVP

**Shipped:** 2026-05-10
**Phases:** 4 | **Plans:** 13

### Delivered

A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications.

### Key Accomplishments

- Implemented Core Observability using Ecto and Telemetry
- Built MCP Gateway & Tool Governance with isolated OTP execution
- Created LiveView Operator UX with token coalescing and HITL approval modals
- Developed Evaluation Flywheel for promoting production traces to testing datasets

---

## v1.1 Caldera

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 4
**Theme:** Durable Agent Workflows & Handoffs

### Objectives

Build a lightweight, OTP-native agent loop capable of managing complex state machines, subagent handoffs, and durable pauses for long-running workflows or operator approval.

### Delivered

Scoria now ships a durable workflow layer with Ecto-backed checkpointing, root-owned delegated handoffs, supervised recovery semantics, and a trace-first workflow visualizer inside the dashboard surface.

### Scope

- **Durable Checkpoints:** Persist the `RunState` into Ecto natively so workflows can survive BEAM restarts, timeout limits, and operator approval delays.
- **Handoffs & Subagents:** First-class support for an agent to cleanly delegate to another `MyAI.Agent` with specialized tools.
- **Jido Integration (Optional):** Provide an adapter to map `Jido` v2 pure-functional decisions/directives into Scoria's observable trace and checkpoint engine.
- **LiveView Workflow Visualizer:** A visual representation of the agent graph/state machine in the admin dashboard.

### Key Accomplishments

- Added durable workflow tables and transactional lifecycle APIs.
- Added supervised runtime execution, exact resume, and retry-failed-step support.
- Added a workflow LiveView under the existing dashboard router surface.
- Added an optional Jido adapter boundary with full end-to-end lifecycle coverage.

---

## v1.2 Corpus

**Shipped:** 2026-05-11
**Phases:** 1 | **Plans:** 6
**Theme:** Advanced RAG, Citations & Knowledge Grounding

### Objectives

Provide batteries-included RAG primitives that natively integrate with the Scoria trace tree and Eval Workbench.

### Delivered

Scoria now ships a durable knowledge layer with pgvector-backed retrieval, provenance-preserving citations, deterministic grounding checks, and trace-first evidence projection inside the dashboard surface.

### Scope

- **Vector Index & Chunking Abstractions:** Clean behaviors for embedding models and chunking strategies.
- **pgvector Integration:** An out-of-the-box Ecto/pgvector adapter to store and query embeddings natively.
- **First-Class Citations:** Ensure the trace explicitly captures "Retrieval" spans, linking the model's generated output back to specific `Chunks` via `Citation` metadata.
- **Groundedness & Hallucination Scorers:** Deterministic and LLM-as-Judge scorers to verify outputs are factually grounded.
- **Scrypath Synergy (Optional):** First-class integration with `Scrypath` as a native retrieval engine. Scoria wraps Scrypath queries in `RETRIEVER` spans so they remain observable and evaluable without forcing external vector databases.

### Key Accomplishments

- Added explicit pgvector bootstrap and a shared knowledge test scaffold.
- Built durable corpus, retrieval, citation, and grounding schemas behind `Scoria.Knowledge`.
- Kept Scrypath optional behind a retrieval normalization boundary.
- Projected evidence and grounding signals into the existing operator surface with async loading.
- Added versioned deterministic-first evaluation for citations and grounding.

**Known deferred items at close:** 1 (see STATE.md Deferred Items)

---

## v1.3 Seismograph

**Shipped:** 2026-05-12
**Phases:** 5 | **Plans:** 20
**Theme:** SRE, Circuit Breakers & Ecosystem Synergy

### Objectives

Harden Scoria into a production-grade control plane with proactive governance, circuit breakers, and deep `szTheory` ecosystem integration.

### Scope

- **Circuit Breakers & Budgets:** Introduce configurable token and cost budgets per tenant/user that trip guardrails when exceeded.
- **Parapet SLO Integration:** Define SLOs for latency, cost, and eval pass rates for the upcoming `Parapet` SRE layer.
- **Threadline Audit Export:** Clean integration to export sensitive `ToolApproval` and MCP access events into immutable audit logs.
- **Automated Regression Alerts:** Automatically trigger incident workflows via `Chimeway`/`Mailglass` when a CI gate dips below the baseline.

### Delivered

Scoria now ships a durable SRE layer with explicit budget reservations and reconciliation, external-effect circuit breakers, runtime and incident telemetry, workflow-owned audit lineage, durable incident and delivery routing, and trace-first operator evidence inside the existing dashboard surface.

### Key Accomplishments

- Closed the breaker-open reservation gap at both workflow and MCP execution seams.
- Restored audited approval handling and durable delivery production on the real incident path.
- Wired live execution and incident lifecycle telemetry while keeping the knowledge lane explicit behind `mix test.knowledge`.
- Backfilled Phase 7 verification and aligned milestone-state artifacts so the repo has a normal validation -> verification -> shipped evidence chain.

**Known deferred items at close:** 1 (see STATE.md Deferred Items)

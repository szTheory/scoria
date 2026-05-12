# Phase 5 Context

## Phase Boundary

Phase 5 is `Durable Agent Workflows & Handoffs`.

This phase is about making Scoria a durable, operator-readable workflow layer for AI runs: persisted checkpoints, subagent handoffs, resumable failures/pauses, and a LiveView-facing visualizer. It is not a Jido rewrite and not a generic workflow engine.

## Locked Decisions

### Checkpointing model

Use a **hybrid semantic checkpoint model**.

Persist durable state at stable transitions:
- `run_started`
- after a model turn resolves to a stable next action
- before `waiting_*` / approval pauses
- after a side-effecting tool or subagent step completes
- at terminal states

Do not checkpoint:
- streaming tokens
- LiveView socket state
- PubSub frames
- raw GenServer memory

Why:
- `every-step` checkpointing is too expensive and too easy to overfit into Temporal-scale runtime complexity.
- `manual-only` checkpoints are too footgun-prone.
- `HITL-only` durability is not enough for real crash recovery.

### Handoff contract

Use a **root-owned run with bounded delegated steps**.

Scoria should own the durable lifecycle, approvals, cancellation, budgets, and traceability. Delegation should be modeled as bounded child steps, not literal ownership transfer.

Recommended structure:
- stable `role_id` for developer-facing roles like `researcher`, `critic`, `executor`
- capability filters for selection, not as the primary orchestration contract
- typed step envelopes for results/errors/approvals
- explicit `handoff_input` and `step_result` schemas
- projected context slices, not transcript dumping

Do not move by default:
- full transcript history
- secrets
- provider session internals
- LiveView UI state
- PIDs / ETS refs / monitors

### Recovery UX

The primary operator recovery flow is:
- exact resume
- retry failed step

Secondary later:
- fork from checkpoint

Do not ship in-place state editing for current runs in phase 5.

Why:
- exact resume plus retry keeps the trust model simple
- in-place mutation is high-risk and hard to audit
- forking is valuable, but it is a debug/eval workflow, not the default recovery path

### Visualizer shape

Use a **trace-first tree** as the primary view.

Add:
- inline lifecycle badges like `running`, `paused`, `waiting_for_approval`, `retrying`, `completed`
- compact handoff markers
- a right-side detail panel for checkpoint metadata and failure reasons
- a per-run timeline as the secondary drilldown

Do not make the primary UI graph-first.

Why:
- Scoria already has a flat trace tree pattern that is LiveView-friendly
- graph-first UIs are harder to keep calm, streamable, and legible
- timeline is important, but it should be a drilldown, not the default mental model

### Jido scope

Keep Jido as an **optional adapter**, not the center of the public API.

Scoria should define its own durable workflow nouns and checkpoint model, then map Jido into that model where useful.

Do not make Scoria Jido-first.

Why:
- preserves framework-agnostic reach
- avoids semantic lock-in
- keeps the product centered on AI ops/control plane, not another workflow DSL
- still gives Jido users a clean bridge into Scoria observability and durability

## Recommended Domain Model

Use these stable nouns downstream:
- `run`
- `step`
- `checkpoint`
- `handoff`
- `approval`
- `event`
- `artifact`
- `role`
- `capability`

Use these runtime statuses:
- `running`
- `waiting_for_approval`
- `paused`
- `retrying`
- `failed`
- `completed`
- `cancelled`

## Implementation Constraints

- Ecto is the source of truth for durable state.
- PubSub is for visibility, never for workflow truth.
- LiveView stays a projection layer over persisted state.
- OTP tasks/supervision are execution mechanisms, not the workflow contract.
- `Ecto.Multi` should wrap atomic checkpoint/state/event writes.
- `optimistic_lock` should guard mutable operator-facing records.

## What the next phase should research/plans against

- exact schema shape for runs, checkpoints, events, and handoff records
- task and step orchestration boundaries
- resume/retry semantics for crashed steps
- adapter mapping for Jido directives into Scoria steps
- the minimal install and router integration story for phase 5

## Deferred Ideas

These are intentionally not phase-5 defaults:
- full workflow graph authoring as the primary UX
- in-place editing of live run state
- telemetry-only Jido integration with no durability layer
- generic capability-driven orchestration without stable role IDs

## Canonical refs

- `.planning/ROADMAP.md`
- `.planning/MILESTONES.md`
- `.planning/milestones/v1.1-MILESTONE-PROPOSALS.md`
- `.planning/STATE.md`
- `.planning/RESEARCH.md`
- `.planning/PATTERNS.md`
- `.planning/MEMORY.md`
- `prompts/scoria-gsd-kickoff.md`
- `prompts/phoenix-ai-lib-deep-research.md`
- `prompts/sztheory-elixir-dna.md`
- `prompts/scoria-brand-book-deep-research.md`
- `.planning/memory/parapet-synergy.md`
- `.planning/memory/scrypath-rag-synergy.md`

## Sources Used

- `LangGraph` durable execution, persistence, and subgraphs
- `OpenAI Agents SDK` handoffs, sessions, human-in-the-loop, tracing
- `Temporal` durable execution and event history patterns
- `Strands` checkpointing and observability guidance
- `Jido` agents, directives, and `AgentServer`
- `Phoenix LiveView`, `Phoenix.PubSub`, `Ecto.Multi`, `Task`, `Supervisor`
- Scoria phase 3 research on LiveView operator UX
- Scoria phase 4 research on eval traces and dataset promotion


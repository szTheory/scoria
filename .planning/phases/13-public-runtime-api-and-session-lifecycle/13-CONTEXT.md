# Phase 13: Public Runtime API and Session Lifecycle - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose a documented app-facing runtime surface for starting, resuming, and inspecting Scoria runs on top of the durable workflow substrate.

This phase productizes the existing workflow engine into a Phoenix-friendly public runtime boundary. It does not broaden into provider/policy default composition, install ergonomics, or full docs/example closeout beyond the runtime/session contracts needed for host-app integration.

</domain>

<decisions>
## Implementation Decisions

### Public API surface
- **D-01:** `Scoria` should become the default happy-path public runtime surface for host apps, not `Scoria.Workflows`.
- **D-02:** The public boundary should be layered: `Scoria` exposes the small common path, while `Scoria.Runtime` may expose the fuller public runtime layer for advanced callers.
- **D-03:** `Scoria.Workflows` remains available as substrate/advanced integration, but it must not be documented as the primary app-facing API.
- **D-04:** Host apps should integrate around runtime nouns such as `identity`, `run`, `session`, `status`, and `approval`, not workflow-engine nouns such as `checkpoint`, `handoff`, `reconciler`, or raw step plumbing.

### Start and resume contracts
- **D-05:** The core public lifecycle contract should use explicit paired verbs rather than a polymorphic dispatcher: `start_run/2` and `resume_run/2` at the public layer.
- **D-06:** `resume_run/2` must use `run_id` as exact durable execution truth. `session_id` is not sufficient to determine which paused or prior run to resume.
- **D-07:** Start inputs should separate concerns clearly: canonical identity through `Scoria.Identity`, runtime/config options separately, and initial run payload or entrypoint input under explicit runtime keys rather than mixing everything into one loose attrs map.
- **D-08:** Session-based convenience helpers may exist later, but they must remain helpers layered on top of the explicit start/resume contract rather than replacing it.

### Inspection contract and host-app references
- **D-09:** Public inspection must not expose raw Ecto workflow structs as the primary host-app contract.
- **D-10:** The public runtime should return a stable small run summary by default and may expose an explicit curated detailed view for advanced inspection, but neither shape should be a disguised `%Scoria.Workflows.Run{}` dump.
- **D-11:** The minimum public run summary should include `run_id`, `session_id`, `status`, `actor_id`, `tenant_id`, `current_step_id`, `latest_checkpoint_id`, approval-wait state or equivalent, and lifecycle timestamps needed for polling, resume, and operator linking.
- **D-12:** Host apps should persist `session_id` for continuity and store the returned `run_id` whenever they need exact resume, polling, or deep-linking to operator evidence.

### Session lifecycle semantics
- **D-13:** `session_id` is a host-owned continuity identifier. It may represent a browser session, chat thread, workspace conversation, or other app-defined continuity boundary.
- **D-14:** `run_id` is the Scoria-owned durable execution identifier for exactly one run lifecycle.
- **D-15:** Multiple runs may share the same `session_id`. Every new start creates a new `run_id`, even when it reuses an existing `session_id`.
- **D-16:** Approvals, retries, checkpoints, events, telemetry refs, and operator evidence attach to `run_id` first and project `session_id` as grouping context.
- **D-17:** Scoria must not auto-infer whether to start or resume from prior persisted session state. The host app chooses continuity explicitly, and resume remains an explicit run-level act.

### DX posture and decision policy
- **D-18:** Keystone should prefer boring, principle-of-least-surprise runtime APIs over agent-platform magic. The public surface should read like a normal Phoenix library, not a managed runtime SDK.
- **D-19:** Low-impact runtime defaults and naming choices should be shifted left inside GSD and Scoria’s planning/implementation flows. User interruption should be reserved for materially consequential product-shape decisions.
- **D-20:** Edge helpers may extract identity/session context from Plug, LiveView, or host-app assigns, but those helpers must normalize immediately into canonical runtime nouns instead of making framework state the durable contract.

### the agent's Discretion
- Exact naming between `Scoria.start_run/2` and `Scoria.start/2`, provided the public API stays explicit and the docs teach one obvious start/resume pair.
- Exact layering between `Scoria` and `Scoria.Runtime`, provided `Scoria` remains the canonical happy path and `Scoria.Workflows` does not become the primary product surface again.
- Exact summary/detail public view module names and shapes, provided they stay curated and schema-independent.
- Exact helper APIs for listing or looking up runs by `session_id`, provided `run_id` remains the only exact resume handle.

</decisions>

<specifics>
## Specific Ideas

- The public runtime story should feel like `Req` or `Oban`: one obvious high-level entrypoint, deeper layers available when needed, and no requirement for callers to understand internal executors or persistence seams.
- Good Phoenix DX here means:
  - a host app can normalize identity once
  - start a run explicitly
  - store `run_id` for exact continuation
  - store `session_id` for continuity and grouping
  - inspect a stable run summary without coupling to workflow schemas
- Docs/examples should show three distinct cases:
  - same `session_id`, new `run_id` for a new turn or new attempt
  - same `run_id` for approval resume or durable continuation
  - listing/filtering by `session_id` without pretending it is execution truth
- Avoid blessing current fallback smells like treating `session_id` as an actor proxy or teaching host apps to call workflow contexts directly for normal runtime work.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 13 goal, plan breakdown, and Keystone sequencing.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and milestone thesis.
- `.planning/REQUIREMENTS.md` - `IDEN-03`, `RUNT-01`, `RUNT-02`, and `RUNT-03`.
- `.planning/STATE.md` - current milestone posture and accumulated constraints.
- `.planning/MILESTONE-ARC.md` - why runtime API clarity is an adoption prerequisite.

### Prior phase context
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - canonical identity envelope, immutable root identity, and edge-adapter rules locked in Phase 12.
- `.planning/phases/12-canonical-runtime-identity/12-RESEARCH.md` - local analysis of identity propagation and the boundary between durable root truth and transient execution context.
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md` - workflow-owned approval truth and resume-after-approval posture.
- `.planning/phases/05-caldera/05-CONTEXT.md` - durable workflow nouns, resume semantics, and operator-visible workflow lifecycle.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops framing.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons from Phoenix-native AI libs, agent runtimes, eval/tracing tools, and control-plane design.
- `prompts/scoria-brand-book-deep-research.md` - operator-grade, calm, evidence-first product tone and least-surprise expectations for public surface area.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first DX, embedded dashboards, and Ecto-native state principles.
- `.planning/seeds/SEED-001-agentcore-lessons.md` - durable identity/session lessons and anti-platform-drift guardrails.

### Current code surface
- `lib/scoria.ex` - current placeholder top-level public module that should become the happy-path runtime surface.
- `lib/scoria/identity.ex` - canonical runtime identity envelope and edge-normalization helpers.
- `lib/scoria/workflows.ex` - durable workflow truth, current run creation, approvals, checkpoints, and resume seam.
- `lib/scoria/workflows/resume.ex` - current thin recovery entrypoints that point toward a cleaner public runtime layer.
- `lib/scoria/workflows/runtime.ex` - execution seam for runtime steps and approval-paused transitions.
- `lib/scoria/workflows/run.ex` - durable run schema and current fields relevant to public run views.
- `lib/scoria_web/live/workflow_live/show.ex` - current operator-facing run evidence page and route shape.
- `lib/scoria_web/live/orchestrator_live.ex` - current fallback identity/session behavior that should inform helper design but not become the durable public contract.
- `README.md` - current public-facing mismatch that still understates Keystone and lacks the runtime story this phase should enable.
- `test/scoria/workflows/integration_test.exs` - current approval pause/resume and operator-view integration behavior that the public runtime contract must preserve.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Identity` already provides the canonical app-facing noun and should stay the input normalization seam for the public runtime surface.
- `Scoria.Workflows.create_run/1` already centralizes durable root run creation, initial checkpoint/event writes, and canonical identity stamping.
- `Scoria.Workflows.resume_run/1` plus `Scoria.Workflows.Resume.resume_run/2` already separate exact durable resume logic from dispatch, which makes them the right substrate for a cleaner public runtime API.
- `ScoriaWeb.WorkflowLive.Show` already gives the operator evidence destination that public run summaries can point toward.

### Established Patterns
- Ecto rows are durable truth, while LiveView, telemetry, and projections are operator-facing views on that truth.
- Scoria favors explicit durable seams and auditable transitions over hidden runtime magic.
- The current codebase already treats `run.id` as execution truth and `session_id` as identity context rather than as the exact resume key.

### Integration Points
- The top-level `Scoria` module should become the Phoenix-app integration entrypoint for common run lifecycle operations.
- A new `Scoria.Runtime` layer can wrap workflow substrate calls while preserving flexibility for future policy/default composition in Phase 14.
- Public run summaries/detailed views should be built from workflow truth but stay decoupled from raw Ecto schemas.
- Future docs and example flows in Phase 15 should reuse the same run/session semantics locked here instead of redefining them.

</code_context>

<deferred>
## Deferred Ideas

- A richer public thread/session/run hierarchy with additional first-class nouns beyond `session_id` and `run_id`.
- Session-first or auto-resolving runtime APIs that decide start vs resume implicitly from persisted state.
- Treating `session_id` as the one true execution handle.
- Exposing raw workflow schemas, checkpoints, or step internals as the default host-app contract.
- Broader policy/default composition and install ergonomics work that belongs to Phase 14.
- Full public docs/example closeout work that belongs to Phase 15.

</deferred>

---

*Phase: 13-public-runtime-api-and-session-lifecycle*
*Context gathered: 2026-05-14*

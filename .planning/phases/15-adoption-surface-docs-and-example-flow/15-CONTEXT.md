# Phase 15: Adoption Surface, Docs, and Example Flow - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Align the public-facing docs, example integration flow, and verification story with the shipped Keystone runtime surface so a normal Phoenix team can adopt Scoria without guessing at identity, run lifecycle, install expectations, or operator workflow boundaries.

This phase clarifies how Scoria is taught and proven in public materials. It does not invent new runtime semantics, add new product capabilities, or redefine the optional knowledge lane as part of the default success path.

</domain>

<decisions>
## Implementation Decisions

### README and docs posture
- **D-01:** The README and public docs should lead with the app-facing runtime story, not a feature inventory or operator-console-first pitch.
- **D-02:** The top-line product framing should present Scoria as the Phoenix-native runtime and operator surface for identity-aware AI runs inside an existing app.
- **D-03:** The public docs opening should follow this sequence: what Scoria is, why Phoenix teams use it, install, start a run, store `session_id` and `run_id` correctly, resume after approval, open `/scoria`, then expand into capabilities by layer.
- **D-04:** Capability-bucket overviews for tracing, workflows, approvals, telemetry, knowledge, and UI should remain below the primary quickstart rather than leading the page.
- **D-05:** Operator-console visuals and `/scoria` storytelling should support the runtime narrative, not replace it. Public docs must not imply that mounting the dashboard alone is the integration story.

### Canonical Phoenix example flow
- **D-06:** The canonical end-to-end example should be a controller-triggered Phoenix flow with one approval pause and explicit resume, not a pure LiveView-first or background-job-first example.
- **D-07:** The example should show `Scoria.identity/1` normalizing `actor_id`, `tenant_id`, and `session_id` from Phoenix edge state such as `conn.assigns` and session storage.
- **D-08:** The example should show `Scoria.start_run/2` returning a durable `run_id`, the host app storing that `run_id`, and the app using `Scoria.get_run/1` for status inspection.
- **D-09:** The example should teach that later turns in the same host-app conversation reuse `session_id` but create a fresh `run_id` via `start_run/2`.
- **D-10:** The example should show explicit resume through `Scoria.resume_run/2` after an approval pause. Public docs must not imply that `session_id` is sufficient for exact resume.
- **D-11:** The example should show `/scoria/workflows/:run_id` as operator evidence linked from host-app flows, not as Scoria’s source of business truth.
- **D-12:** A shorter secondary LiveView/chat example may exist later, but it should be positioned as an advanced or additional UX example, not the primary adoption narrative.

### Verification story and closeout
- **D-13:** The default verification story should be two-step: install preflight first, then a real core-lane runtime proof backed by the operator UI.
- **D-14:** Install preflight should include `mix scoria.install`, `mix ecto.migrate`, and `mix test` as the boring baseline proof that router/config/migrations/tests are wired correctly.
- **D-15:** The actual default proof of success should require one real `Scoria.start_run/2` invocation, a successful readback via `Scoria.get_run/1` or equivalent session listing, and visibility of that run at `/scoria/workflows/:run_id`.
- **D-16:** The default verification story must explicitly state that core success does not require pgvector, knowledge tables, retrieval, grounding, or `mix scoria.test.knowledge`.
- **D-17:** The knowledge lane should remain a clearly labeled optional expansion path, introduced only after the core runtime and operator lane are proven.
- **D-18:** Repo-level closeout and maintainer confidence should still lean on the existing test-first verification lane, but public first-run docs should not make tests alone the primary user-facing proof.

### Public module teaching depth
- **D-19:** Public docs should use a `Scoria`-first teaching posture with advanced modules introduced later in a deliberate sequence.
- **D-20:** The happy path should center `Scoria.start_run/2`, `resume_run/2`, `get_run/1`, `get_run_detail/1`, and `list_runs_for_session/1` as the primary app-facing runtime surface.
- **D-21:** `Scoria.Identity` should be introduced early as the canonical identity noun and edge-normalization boundary, not left implicit as “just pass a map”.
- **D-22:** Public docs must explicitly teach that `session_id` is host-owned continuity while `run_id` is Scoria’s exact durable execution handle.
- **D-23:** `Scoria.Runtime` should be documented as the fuller public lifecycle layer for advanced callers, but not given equal weight with `Scoria` in the README opening.
- **D-24:** `Scoria.PromptPolicy` should be introduced after the reader understands defaults and governance, not in the very first quickstart code sample.
- **D-25:** `Scoria.Workflows` should be documented as substrate/advanced integration, not as the normal host-app entrypoint.

### Decision policy and shift-left preference
- **D-26:** Low-impact docs choices should be shifted left within GSD and future planning flows wherever possible. Section names, badge order, screenshot placement, wording polish, and similar presentation details should not require user interruption by default.
- **D-27:** User interruption should be reserved for materially consequential public-surface choices such as top-line category framing, the first code sample, core run/session semantics, and whether a lane is default or optional.

### the agent's Discretion
- Exact README section titles and ordering within the recommended runtime-first structure, provided the public story still starts with the runtime quickstart and keeps capability expansion secondary.
- Exact controller example domain, route names, and UX copy, provided the example preserves the locked `identity` / `run_id` / `session_id` / approval-resume semantics.
- Exact shape of the default proof walkthrough, provided it proves one real core-lane run plus operator evidence without requiring the knowledge lane.
- Exact placement of `Scoria.Runtime` and `Scoria.PromptPolicy` in deeper docs, provided `Scoria` remains the obvious happy path and advanced modules remain discoverable.

</decisions>

<specifics>
## Specific Ideas

- The ideal README feel is closer to `Req`, `Oban`, and Phoenix LiveDashboard than to a feature-grid AI platform homepage: one obvious way in, deeper layers later.
- The canonical example should feel like normal Phoenix code:
  - normalize identity from the edge
  - call `Scoria.start_run/2`
  - keep `run_id` for exact continuation
  - keep `session_id` for continuity/history
  - inspect the run in both the host app and `/scoria`
- The example should include one approval pause so the docs naturally teach why `resume_run/2` exists and why resume is keyed by `run_id`.
- The docs should repeat the same semantic distinctions consistently:
  - `session_id` groups related turns
  - `run_id` identifies one exact run
  - Phoenix `conn` / LiveView state are edge adapters, not durable Scoria contracts
- Scoria should learn from strong outside examples without copying their posture wholesale:
  - OpenAI Agents SDK gets the small public runtime vocabulary right.
  - LangGraph gets durable pause/resume and exact execution truth right.
  - Langfuse, Braintrust, and Arize Phoenix get the trace -> dataset/eval feedback loop right.
  - FastMCP gets “protocol complexity hidden behind normal application code” right.
- Scoria should explicitly avoid the common footguns those ecosystems expose:
  - dashboard-first docs that hide the actual integration boundary
  - over-teaching advanced modules on first contact
  - blurring continuity identifiers with exact execution handles
  - making optional subsystems feel required for first value

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 15 goal, plan breakdown, and Keystone sequencing.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and public adoption thesis.
- `.planning/REQUIREMENTS.md` - `ADOP-01`, `ADOP-02`, `ADOP-03`, and `ADOP-04`.
- `.planning/STATE.md` - current milestone posture and the explicit TODO to align README/docs/examples with the shipped runtime.
- `.planning/MILESTONE-ARC.md` - the strategic rule that adoption prerequisites outrank adjacent capability expansion.

### Prior Keystone decisions
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - canonical identity envelope, immutable root identity, and edge-adapter posture.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - `Scoria` as the happy-path API, explicit `start_run/2` and `resume_run/2`, and the `session_id` vs `run_id` contract.
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - default install lane, optional knowledge lane, and the requirement that low-impact decisions shift left.

### Current public code surface
- `README.md` - current stale public-facing posture that Phase 15 must replace.
- `lib/scoria.ex` - top-level public facade and the exact API the README should teach first.
- `lib/scoria/runtime.ex` - fuller public lifecycle and inspection layer behind the facade.
- `lib/scoria/identity.ex` - canonical identity normalization and Phoenix-edge adapter boundary.
- `lib/scoria/prompt_policy.ex` - canonical prompt-policy noun for later public docs depth.
- `lib/scoria/runtime/params.ex` - start/resume normalization and resolved runtime metadata shape.

### Install and verification lane
- `lib/mix/tasks/scoria.install.ex` - install task and current printed verification flow.
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` - optional knowledge-lane bootstrap that must remain non-default.
- `lib/mix/tasks/scoria.test.knowledge.ex` - optional knowledge-lane verification command.
- `test/mix/tasks/scoria.install_test.exs` - installer mutation and idempotence expectations.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - default route wiring proof for `/scoria`.
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - core-vs-knowledge migration lane contract.
- `test/scoria/runtime_integration_test.exs` - the strongest local reference for the canonical end-to-end runtime + operator example story.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops framing and operator-first DX.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable design rules, operator-first DX, Ecto-native state, and zero-config onboarding.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem analysis and package-shape guidance for Phoenix-native AI libraries.
- `prompts/scoria-brand-book-deep-research.md` - public voice and positioning constraints for Scoria’s docs and adoption story.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria` already exposes the small public facade that Phase 15 should document directly.
- `Scoria.Runtime` already exposes the fuller lifecycle and inspection API, so docs do not need to invent a new public layering model.
- `Scoria.Identity` already provides the explicit identity normalization seam that public examples should teach.
- `test/scoria/runtime_integration_test.exs` already contains a near-canonical controller/runtime/operator proof pattern, including same-session new runs and exact `run_id` resume semantics.
- `mix scoria.install` plus the installer smoke tests already encode the intended default lane and can anchor the verification narrative.

### Established Patterns
- Scoria consistently prefers one obvious top-level noun over loose attrs and implicit conventions.
- Durable truth lives in Ecto-backed runtime rows; Phoenix edge state is an adapter, not the durable contract.
- The repo already distinguishes a default core lane from the optional knowledge lane and expects the latter to stay explicit.
- Operator-facing UI is presented as evidence and inspection over durable truth, not as a replacement for host-app runtime ownership.

### Integration Points
- README and guides should align exactly with `lib/scoria.ex` rather than teaching `Scoria.Workflows` directly.
- The canonical example should likely be derived from or validated against `test/scoria/runtime_integration_test.exs`.
- Verification docs should align with `mix scoria.install` output, `/scoria` routes, and runtime integration coverage rather than creating a new success definition.
- Public module docs should cross-link `Scoria`, `Scoria.Identity`, `Scoria.Runtime`, and `Scoria.PromptPolicy` in a deliberate layered sequence.

</code_context>

<deferred>
## Deferred Ideas

- LiveView-first or chat-first examples as the primary adoption story.
- Background-job-first examples as the default documentation lane.
- Expanding the default proof of success to include the knowledge lane.
- Reframing Scoria as a hosted-style AI ops platform instead of an embedded Phoenix library.
- Larger docs IA and presentation preferences that do not materially affect runtime semantics or default-lane expectations.

</deferred>

---

*Phase: 15-adoption-surface-docs-and-example-flow*
*Context gathered: 2026-05-15*

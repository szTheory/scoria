# Phase 15: Adoption Surface, Docs, and Example Flow - Research

**Researched:** 2026-05-15 [VERIFIED: repo]  
**Domain:** README/docs/example-flow alignment for the shipped Keystone runtime and installer surfaces [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: repo]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- LiveView-first or chat-first examples as the primary adoption story.
- Background-job-first examples as the default documentation lane.
- Expanding the default proof of success to include the knowledge lane.
- Reframing Scoria as a hosted-style AI ops platform instead of an embedded Phoenix library.
- Larger docs IA and presentation preferences that do not materially affect runtime semantics or default-lane expectations.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOP-01 | `README.md` and install guidance reflect the actual shipped milestone state and public runtime entrypoints. | Rewrite README around the already-shipped `Scoria` facade and installer output instead of the stale v1.2/v1.3 posture [VERIFIED: README.md; lib/scoria.ex; lib/mix/tasks/scoria.install.ex] |
| ADOP-02 | Scoria exposes at least one end-to-end documented Phoenix integration flow showing how request/session context maps into Scoria identity and runtime APIs. | Base the canonical example on the runtime integration test’s controller-like approval/resume flow and identity normalization rules [VERIFIED: test/scoria/runtime_integration_test.exs; lib/scoria/identity.ex; lib/scoria/runtime.ex] |
| ADOP-03 | Default verification guidance tells a Phoenix team how to prove the core lane is working without unexpectedly requiring the knowledge lane. | Use the install task’s baseline next steps and the migration-lane compatibility split as the default proof, with knowledge commands moved to an optional section [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
| ADOP-04 | The top-level public module surface is no longer placeholder-only and instead reflects the library's intended entrypoints. | Teach `Scoria.identity/1`, `start_run/2`, `resume_run/2`, `get_run/1`, `get_run_detail/1`, and `list_runs_for_session/1` first, with deeper modules later [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex] |
</phase_requirements>

## Summary

Phase 15 is a public-surface alignment phase, not a runtime invention phase. The repo already ships the Keystone nouns and behaviors the docs need to teach: canonical identity normalization, explicit `start_run/2` and `resume_run/2`, stable run inspection DTOs, installer-wired `/scoria` routes, and a split between the default core lane and the optional knowledge lane. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/identity.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; lib/mix/tasks/scoria.install.ex; test/scoria/runtime_integration_test.exs]

The biggest gap is narrative drift. `README.md` still advertises a pre-Keystone state and leads with a feature inventory instead of the runtime-first Phoenix integration story. The roadmap and requirements say the goal is to make Scoria the obvious embedded Phoenix runtime and operator surface for identity-aware AI runs, and the current public module surface already supports that story. [VERIFIED: README.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/PROJECT.md]

The strongest implementation anchor is `test/scoria/runtime_integration_test.exs`. That file already proves the exact semantics Phase 15 should document publicly: normalize identity once, start a run, wait for approval, approve out-of-band, resume by exact `run_id`, create a fresh run under the same `session_id`, and inspect the operator evidence at `/scoria/workflows/:run_id`. [VERIFIED: test/scoria/runtime_integration_test.exs]

**Primary recommendation:** break the phase into exactly these three execution slices:
1. `15-01: README and Public Module Alignment` [VERIFIED: .planning/ROADMAP.md]
2. `15-02: End-to-End Phoenix Integration Example` [VERIFIED: .planning/ROADMAP.md]
3. `15-03: Operator-Facing Verification Story and Closeout` [VERIFIED: .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| README/runtime-first narrative | Developer documentation | API / Backend | Docs must reflect the actual public boundary exposed by `Scoria`, not internal workflow modules [VERIFIED: README.md; lib/scoria.ex] |
| Identity extraction from Phoenix edge state | Browser / Client | API / Backend | Host-app state originates at the Phoenix edge, but `Scoria.identity/1` and `Scoria.Identity` own normalization into durable runtime nouns [VERIFIED: lib/scoria.ex; lib/scoria/identity.ex] |
| Run lifecycle operations | API / Backend | — | `start_run/2`, `resume_run/2`, `get_run/1`, and session listing all live in the public runtime layer [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex] |
| Operator evidence linkout | Frontend Server (SSR) | API / Backend | `/scoria` is a mounted LiveView evidence surface built on durable workflow truth, not the host-app source of truth [VERIFIED: lib/scoria_web/router.ex; test/scoria/runtime_integration_test.exs] |
| Install and verification guidance | Developer tooling | Frontend Server (SSR) | The install lane is expressed through Mix tasks and route smoke tests, then proven visually at `/scoria` [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_route_smoke_test.exs] |
| Optional knowledge-lane expansion | Developer tooling | Database / Storage | pgvector bootstrap and knowledge verification are explicit secondary steps after core runtime proof [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` [VERIFIED: mix.exs] | Host language for the public runtime, Mix tasks, and docs examples | The shipped package and badges already position Scoria as an Elixir/Phoenix library [VERIFIED: mix.exs; README.md] |
| Phoenix | `~> 1.7` [VERIFIED: mix.exs] | Canonical host-app integration target and `/scoria` mount surface | Phase 15 is specifically about normal Phoenix adoption and operator-visible routes [VERIFIED: .planning/PROJECT.md; lib/scoria_web/router.ex] |
| Phoenix LiveView | `~> 1.0` [VERIFIED: mix.exs] | Mounted operator evidence routes at `/scoria` and `/scoria/workflows/:id` | The public verification story relies on those routes as evidence, not as the app’s source of truth [VERIFIED: lib/scoria_web/router.ex; test/mix/tasks/scoria.install_route_smoke_test.exs] |
| Ecto / Ecto SQL | `~> 3.10` [VERIFIED: mix.exs] | Durable run truth behind summaries, details, approvals, checkpoints, and events | The public docs must teach `run_id` as durable truth because the runtime and operator views read from Ecto-backed workflow rows [VERIFIED: lib/scoria/runtime.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Scoria` facade | repo-local [VERIFIED: lib/scoria.ex] | Happy-path public API | Teach first in README and quickstart [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| `Scoria.Runtime` | repo-local [VERIFIED: lib/scoria/runtime.ex] | Fuller lifecycle and inspection layer | Introduce after the top-level facade, for advanced callers or module docs [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| `Scoria.Identity` | repo-local [VERIFIED: lib/scoria/identity.ex] | Canonical identity envelope and edge adapters | Introduce early in docs, immediately before `start_run/2` [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| `Scoria.PromptPolicy` | repo-local [VERIFIED: lib/scoria/prompt_policy.ex] | Deeper governance/defaults noun | Introduce after the reader understands the runtime happy path [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Scoria`-first README | `Scoria.Workflows`-first README | Would re-expose substrate nouns as the normal entrypoint and contradict Phase 13/15 decisions [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| Controller approval/resume example | LiveView-first or background-job-first example | Those are explicitly deferred as the primary adoption narrative [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| Core verification first, knowledge later | Making pgvector or `mix scoria.test.knowledge` part of first-run success | Violates the default-lane contract encoded in Phase 14 and migration compatibility tests [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

## Recommended Plan Breakdown

### `15-01: README and Public Module Alignment`
**Goal:** Replace the stale README posture with a runtime-first, `Scoria`-first adoption narrative. [VERIFIED: README.md; .planning/ROADMAP.md]  
**Likely files to touch:** `README.md`, `lib/scoria.ex` module docs, `lib/scoria/runtime.ex` module docs, `lib/scoria/identity.ex` module docs, possibly `lib/scoria/prompt_policy.ex` module docs for sequencing cleanup [VERIFIED: README.md; lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/identity.ex; lib/scoria/prompt_policy.ex]  
**Proof points:** README no longer references v1.2/v1.3 as future state, README opening teaches `Scoria.identity/1` and `Scoria.start_run/2`, and module docs line up with the same teaching order [VERIFIED: README.md; lib/scoria.ex]  
**Risk to guard:** accidentally over-teaching `Scoria.Runtime` or `Scoria.Workflows` in the first contact surface [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

### `15-02: End-to-End Phoenix Integration Example`
**Goal:** Add one canonical Phoenix controller approval-resume walkthrough derived from the runtime integration test. [VERIFIED: .planning/ROADMAP.md; test/scoria/runtime_integration_test.exs]  
**Likely files to touch:** `README.md`, a dedicated runtime example guide referenced from it, plus doctext in `lib/scoria.ex` and `lib/scoria/identity.ex` if examples are colocated there [RESOLVED: aligns with planned `15-01` README quickstart plus `15-02` dedicated guide]  
**Proof points:** the example shows `conn.assigns` plus session storage feeding `Scoria.identity/1`, stores `run_id`, reuses `session_id`, resumes explicitly by `run_id`, and links the operator to `/scoria/workflows/:run_id` [VERIFIED: test/scoria/runtime_integration_test.exs; lib/scoria/identity.ex; lib/scoria_web/router.ex]  
**Risk to guard:** implying `session_id` alone can resume a paused run, or implying `/scoria` is the host app’s source of truth [VERIFIED: lib/scoria/runtime.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]

### `15-03: Operator-Facing Verification Story and Closeout`
**Goal:** Teach the default proof path and optional knowledge path without blurring them. [VERIFIED: .planning/ROADMAP.md; lib/mix/tasks/scoria.install.ex]  
**Likely files to touch:** `README.md`, installer output copy in `lib/mix/tasks/scoria.install.ex` if wording needs alignment, and a dedicated verification guide [RESOLVED: aligns with planned `15-03` verification guide plus README summary]  
**Proof points:** the docs define baseline preflight as `mix scoria.install`, `mix ecto.migrate`, and `mix test`, then require one real started run plus `Scoria.get_run/1` or session listing plus `/scoria/workflows/:run_id` evidence, with knowledge commands clearly labeled optional [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs]  
**Risk to guard:** drifting public docs away from installer output or spreading the compile-time/runtime DB port mismatch as product behavior rather than a local environment detail [VERIFIED: lib/mix/tasks/scoria.install.ex; repo test run]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix request/session state
  -> host app extracts actor_id / tenant_id / session_id
  -> Scoria.identity/1 normalizes edge data
  -> Scoria.start_run(identity, runtime_opts)
  -> durable run created with runtime metadata + run_id
  -> host app stores run_id for exact continuation
  -> workflow may enter waiting_for_approval
  -> operator reviews evidence at /scoria/workflows/:run_id
  -> host app or operator approves out-of-band
  -> host app calls Scoria.resume_run(run_id, opts)
  -> same run_id completes
  -> later conversation turn reuses session_id
  -> host app calls Scoria.start_run(identity, opts) again
  -> new run_id created under same session_id
```

The diagram above is already proven by the runtime integration test and the public runtime facade. [VERIFIED: test/scoria/runtime_integration_test.exs; lib/scoria.ex; lib/scoria/runtime.ex]

### Recommended Project Structure

```text
README.md                         # Runtime-first entrypoint and verification story
lib/scoria.ex                     # Top-level public API docs
lib/scoria/identity.ex            # Identity explanation and edge-normalization examples
lib/scoria/runtime.ex             # Advanced lifecycle/inspection docs
lib/mix/tasks/scoria.install.ex   # Baseline install/verification copy
test/scoria/runtime_integration_test.exs
test/mix/tasks/scoria.install_test.exs
test/mix/tasks/scoria.install_route_smoke_test.exs
test/scoria/bootstrap/migration_lane_compatibility_test.exs
```

### Pattern 1: Runtime-first README opening
**What:** Teach `Scoria` as the first noun, not workflow substrate or dashboard inventory. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]  
**When to use:** README hero, installation section, and first code sample. [VERIFIED: README.md]  
**Example order:** what Scoria is -> why Phoenix teams use it -> install -> normalize identity -> start a run -> store `run_id` and `session_id` -> resume after approval -> inspect `/scoria` -> deeper capability map. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

### Pattern 2: Identity before lifecycle
**What:** Show `Scoria.identity/1` immediately before `Scoria.start_run/2` so edge-state adaptation is explicit. [VERIFIED: lib/scoria.ex; lib/scoria/identity.ex]  
**When to use:** Quickstart and example docs. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

### Pattern 3: `session_id` for continuity, `run_id` for exact resume
**What:** Repeat this distinction in every public example and verification guide. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]  
**When to use:** Example controller flow, run polling guidance, operator deep links, and session history docs. [VERIFIED: lib/scoria/runtime.ex; test/scoria/runtime_integration_test.exs]

### Pattern 4: Core verification first, knowledge expansion second
**What:** Present pgvector bootstrap and knowledge tests only after core runtime proof succeeds. [VERIFIED: lib/mix/tasks/scoria.install.ex; .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md]  
**When to use:** README verification section and any future install guide. [VERIFIED: test/scoria/bootstrap/migration_lane_compatibility_test.exs]

### Anti-Patterns to Avoid
- **Dashboard-first adoption story:** mounting `/scoria` is evidence plumbing, not the primary host-app integration boundary [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md; lib/scoria_web/router.ex]
- **Substrate-first examples:** teaching `Scoria.Workflows` directly would contradict the shipped public runtime facade [VERIFIED: lib/scoria.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]
- **Knowledge-lane creep:** making pgvector feel required for first-run success would contradict the installer copy and migration lane tests [VERIFIED: lib/mix/tasks/scoria.install.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical example semantics | A brand-new imaginary flow | `test/scoria/runtime_integration_test.exs` as the docs source of truth | It already proves approval pause/resume, session grouping, and operator route alignment [VERIFIED: test/scoria/runtime_integration_test.exs] |
| Public runtime API explanation | Separate prose that drifts from code | `Scoria` facade and `Scoria.Runtime` docs | The public surface is already concrete and small [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex] |
| Verification lane split | New ad hoc wording about optional subsystems | Existing install task output plus migration compatibility test | The repo already encodes the core-vs-knowledge contract [VERIFIED: lib/mix/tasks/scoria.install.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
| Operator proof story | Screenshots without route-backed evidence | `/scoria` and `/scoria/workflows/:run_id` deep links | Those routes are installed and smoke-tested today [VERIFIED: lib/scoria_web/router.ex; test/mix/tasks/scoria.install_route_smoke_test.exs] |

**Key insight:** Phase 15 should document the runtime that already exists instead of inventing a second conceptual model for users. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; test/scoria/runtime_integration_test.exs]

## Runtime State Inventory

> This phase is a docs/example/verification alignment phase, not a rename/refactor/migration phase, so runtime-state migration work is not expected. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None specific to Phase 15 scope; docs should describe existing `run_id` and `session_id` semantics rather than migrate stored rows [VERIFIED: lib/scoria/runtime.ex; test/scoria/runtime_integration_test.exs] | None |
| Live service config | None required for planning beyond existing runtime defaults and installer-generated config [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/scoria/runtime/params.ex] | None |
| OS-registered state | None researched because the phase does not register OS services or binaries [VERIFIED: repo] | None |
| Secrets/env vars | Optional knowledge lane references `SCORIA_DB_HOST`, `SCORIA_DB_PORT`, `SCORIA_DB_USERNAME`, and `SCORIA_DB_PASSWORD`; core docs should not make them baseline requirements [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] | Docs only |
| Build artifacts | None specific to the docs phase [VERIFIED: repo] | None |

## Common Pitfalls

### Pitfall 1: README advertises the wrong product state
**What goes wrong:** Users land on a stale v1.2/v1.3 narrative and never see the shipped runtime facade. [VERIFIED: README.md]  
**Why it happens:** The code moved ahead of the public narrative. [VERIFIED: README.md; lib/scoria.ex; .planning/STATE.md]  
**How to avoid:** Make Phase 15 explicitly reconcile docs with shipped code, not roadmap bookkeeping alone. [VERIFIED: .planning/STATE.md]  
**Warning signs:** README still says v1.3 is next or leads with knowledge/dashboard inventory before runtime quickstart. [VERIFIED: README.md]

### Pitfall 2: Example blurs `session_id` and `run_id`
**What goes wrong:** Host apps persist only `session_id` and cannot resume the exact paused run. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]  
**Why it happens:** Session continuity is easy to over-generalize into execution identity. [VERIFIED: test/scoria/runtime_integration_test.exs]  
**How to avoid:** Always show `run_id` persistence on start and explicit `resume_run/2` on approval continuation. [VERIFIED: lib/scoria.ex; test/scoria/runtime_integration_test.exs]  
**Warning signs:** Sample code uses “resume by session” language or omits `run_id` storage. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

### Pitfall 3: Operator UI becomes the primary story
**What goes wrong:** Scoria reads like a dashboard package instead of an embedded Phoenix runtime plus evidence surface. [VERIFIED: .planning/PROJECT.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]  
**Why it happens:** `/scoria` is visually compelling and easier to describe than runtime semantics. [VERIFIED: lib/scoria_web/router.ex]  
**How to avoid:** Put `/scoria` after `start_run/2` and `resume_run/2` in the teaching order. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]  
**Warning signs:** README says “mount the dashboard” before showing a host-app runtime call. [VERIFIED: README.md]

### Pitfall 4: Default verification lane accidentally requires knowledge
**What goes wrong:** First-run docs send users into pgvector/bootstrap work before they have proven the core runtime. [VERIFIED: lib/mix/tasks/scoria.install.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs]  
**Why it happens:** Knowledge features are prominent in older README copy. [VERIFIED: README.md]  
**How to avoid:** Keep knowledge commands in an explicit optional section after core runtime evidence. [VERIFIED: lib/mix/tasks/scoria.install.ex]  
**Warning signs:** `mix scoria.pgvector.bootstrap` appears in quickstart or preflight steps. [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex]

### Pitfall 5: Planner treats Phase 12/13 as still unshipped
**What goes wrong:** Phase 15 plans waste effort rebuilding public runtime semantics instead of documenting them. [VERIFIED: .planning/ROADMAP.md; .planning/STATE.md; lib/scoria.ex]  
**Why it happens:** Roadmap progress is stale relative to code and tests. [VERIFIED: .planning/ROADMAP.md; .planning/STATE.md]  
**How to avoid:** Plan only docs/example/verification work, and treat runtime semantics as fixed inputs. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]  
**Warning signs:** plan tasks mention “design start/resume API” or “introduce identity nouns” in Phase 15. [VERIFIED: .planning/ROADMAP.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]

## Code Examples

Verified patterns from shipped code and tests:

### Phoenix edge normalization and run start
```elixir
# Source: lib/scoria.ex; lib/scoria/identity.ex; test/scoria/runtime_integration_test.exs
identity =
  Scoria.identity(%{
    assigns: %{
      current_actor: %{id: conn.assigns.current_user.id},
      current_tenant: %{id: conn.assigns.current_tenant.id}
    },
    session: %{
      session_id: get_session(conn, :chat_session_id)
    }
  })

{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {MyApp.ScoriaHandlers, :wait_for_approval}}
  )

put_session(conn, :last_scoria_run_id, started.run_id)
```

### Approval resume by exact `run_id`
```elixir
# Source: lib/scoria.ex; test/scoria/runtime_integration_test.exs
run_id = get_session(conn, :last_scoria_run_id)

{:ok, resumed} =
  Scoria.resume_run(run_id,
    handlers: %{"approval" => {MyApp.ScoriaHandlers, :succeed}}
  )

{:ok, summary} = Scoria.get_run(resumed.run_id)
```

### Same session, new run
```elixir
# Source: test/scoria/runtime_integration_test.exs
{:ok, first_run} = Scoria.start_run(identity, root_role_id: "executor")
{:ok, second_run} = Scoria.start_run(identity, root_role_id: "executor")

first_run.session_id == second_run.session_id
first_run.run_id != second_run.run_id

Scoria.list_runs_for_session(identity.session_id)
```

### Operator evidence route
```elixir
# Source: lib/scoria_web/router.ex; test/mix/tasks/scoria.install_route_smoke_test.exs
scope "/" do
  pipe_through(:browser)
  scoria_dashboard("/scoria")
end

# Evidence deep link:
"/scoria/workflows/#{run_id}"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Placeholder `Scoria` module plus stale README posture [VERIFIED: README.md] | Public `Scoria` facade already exposes start/resume/inspect/session-list operations [VERIFIED: lib/scoria.ex] | Landed before 2026-05-15 and reflected in current repo state [VERIFIED: repo] | Phase 15 should document this surface instead of designing a new one [VERIFIED: .planning/STATE.md] |
| Dashboard/feature inventory as early public framing [VERIFIED: README.md] | Runtime-first docs posture required by Phase 15 decisions [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] | Locked on 2026-05-15 in phase context [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] | README and guides need narrative reordering, not subsystem changes [VERIFIED: README.md] |

**Deprecated/outdated:**
- The current README status text saying “v1.2 ships the knowledge layer, and v1.3 is next” is outdated relative to the active Keystone milestone and shipped runtime code [VERIFIED: README.md; .planning/PROJECT.md; .planning/STATE.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dedicated docs/example file beyond `README.md` may be introduced during `15-02` or `15-03` if README-only changes become too dense. | Recommended Plan Breakdown | Low; planner can still keep the work inside README/module docs if preferred. |
| A2 | Installer output wording in `lib/mix/tasks/scoria.install.ex` may need small copy edits to align exactly with the final public verification story. | Recommended Plan Breakdown | Low; if copy is already sufficient, the plan can stay docs-only. |

## Open Questions (RESOLVED)

1. **Should the canonical Phase 15 example live entirely in `README.md`, or should README link to a dedicated guide after the short quickstart?** [RESOLVED]
   - Resolution: use a split structure. `15-01` keeps `README.md` runtime-first and concise, while `15-02` creates a dedicated Phoenix runtime example guide linked from the README. [RESOLVED: matches the planned artifact split]
   - Why this is the right fit: it preserves the locked D-01 through D-05 runtime-first opening, keeps the README short enough to stay approachable, and gives the approval/resume example enough room to teach `session_id` versus `run_id` without collapsing into architecture sprawl. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md; test/scoria/runtime_integration_test.exs]
   - Repo consequence: Phase 15 should assume a small new docs surface is acceptable for deeper walkthroughs, with README acting as the adoption front door rather than the sole long-form guide. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | README command verification, Mix tasks, ExUnit docs proof | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Mix | Install and verification commands | ✓ [VERIFIED: local command] | bundled with current Elixir/OTP 28 toolchain [VERIFIED: local command] | — |
| PostgreSQL on `localhost:55432` | Current test-backed verification lane in this workspace | ✓ [VERIFIED: local command; repo test run] | accepting connections [VERIFIED: local command] | Docs should stay port-agnostic for users; this is local workspace evidence only [VERIFIED: repo test run] |
| Node.js | Tailwind config mutation path touched by `mix scoria.install` | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | — |
| npm | Ancillary JS toolchain presence | ✓ [VERIFIED: local command] | `11.1.0` [VERIFIED: local command] | — |
| Docker | Optional pgvector bootstrap lane | ✓ [VERIFIED: local command] | `29.4.1` [VERIFIED: local command] | Knowledge lane can remain optional if Docker is absent elsewhere [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |

**Missing dependencies with no fallback:**
- None found for the Phase 15 docs/example work in this workspace. [VERIFIED: repo]

**Missing dependencies with fallback:**
- None found in this workspace; the only optional dependency is Docker for the knowledge lane, and that lane is explicitly non-default. [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Mix / Elixir [VERIFIED: mix.exs; repo test run] |
| Config file | none visible at repo root [VERIFIED: repo] |
| Quick run command | `SCORIA_DB_PORT=55432 mix test test/scoria/runtime_integration_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs` [VERIFIED: repo test run] |
| Full suite command | `SCORIA_DB_PORT=55432 mix test` [ASSUMED] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOP-01 | README/install story matches shipped runtime and installer surface | docs review + smoke | `SCORIA_DB_PORT=55432 mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` [VERIFIED: repo test run] | ✅ [VERIFIED: repo] |
| ADOP-02 | Canonical Phoenix integration flow teaches identity/start/resume/operator evidence | integration | `SCORIA_DB_PORT=55432 mix test test/scoria/runtime_integration_test.exs` [VERIFIED: repo test run] | ✅ [VERIFIED: repo] |
| ADOP-03 | Default verification story preserves core-vs-knowledge split | integration | `SCORIA_DB_PORT=55432 mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs` [VERIFIED: repo test run] | ✅ [VERIFIED: repo] |
| ADOP-04 | Top-level public module surface is the primary documented API | docs review + integration | `SCORIA_DB_PORT=55432 mix test test/scoria/runtime_integration_test.exs` [VERIFIED: repo test run] | ✅ [VERIFIED: repo] |

### Sampling Rate
- **Per task commit:** targeted Phase 15 proof lane above [VERIFIED: repo test run]
- **Per wave merge:** same targeted proof lane plus any added docs/doctest checks if introduced [ASSUMED]
- **Phase gate:** targeted proof lane green and docs reviewed against locked semantics before `/gsd-verify-work` [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]

### Wave 0 Gaps
- [ ] Add a docs-proof assertion if the implementation introduces generated snippets or new Mix output wording that needs regression protection. [ASSUMED]
- [ ] Decide whether module-doc doctests are worth adding for `Scoria` or `Scoria.Identity`; current proof is integration-test based, not doctest based. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Host-app auth stays outside this docs phase; docs may mention `conn.assigns` only as edge input [VERIFIED: lib/scoria/identity.ex; .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md] |
| V3 Session Management | yes [VERIFIED: phase scope] | Teach `session_id` as host-owned continuity, distinct from `run_id` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; test/scoria/runtime_integration_test.exs] |
| V4 Access Control | yes [VERIFIED: phase scope] | Keep `/scoria` framed as operator evidence and avoid implying it replaces host-app business rules [VERIFIED: .planning/PROJECT.md; lib/scoria_web/router.ex] |
| V5 Input Validation | yes [VERIFIED: phase scope] | Reuse `Scoria.identity/1` and public runtime DTOs instead of ad hoc docs examples [VERIFIED: lib/scoria.ex; lib/scoria/identity.ex; lib/scoria/runtime/run_summary.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new cryptographic surface is introduced by Phase 15 docs work [VERIFIED: phase scope] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Resuming the wrong run because docs blur identifiers | Tampering | Explicitly document `resume_run/2` by `run_id` only [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; test/scoria/runtime_integration_test.exs] |
| Over-sharing operator routes as public app truth | Information Disclosure | Frame `/scoria` as operator evidence behind host-app routing/auth, not as the business API [VERIFIED: .planning/PROJECT.md; lib/scoria_web/router.ex] |
| Accidental optional-lane escalation | Denial of Service | Keep pgvector/bootstrap work out of the default quickstart and baseline proof [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/scoria.pgvector.bootstrap.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - locked docs posture, example semantics, and verification decisions [VERIFIED: repo]
- `.planning/ROADMAP.md` - exact plan names and Phase 15 scope [VERIFIED: repo]
- `.planning/REQUIREMENTS.md` - `ADOP-01` through `ADOP-04` [VERIFIED: repo]
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary [VERIFIED: repo]
- `.planning/STATE.md` - current TODO to align README/docs/examples with shipped runtime [VERIFIED: repo]
- `README.md` - current stale public posture that Phase 15 must replace [VERIFIED: repo]
- `lib/scoria.ex` - top-level public runtime facade [VERIFIED: repo]
- `lib/scoria/runtime.ex` - public lifecycle and inspection contract [VERIFIED: repo]
- `lib/scoria/identity.ex` - canonical identity normalization boundary [VERIFIED: repo]
- `lib/scoria/prompt_policy.ex` - later-layer governance noun [VERIFIED: repo]
- `lib/scoria/runtime/params.ex` - durable runtime metadata stamping at start boundary [VERIFIED: repo]
- `lib/mix/tasks/scoria.install.ex` - baseline install and next-step wording [VERIFIED: repo]
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` - optional knowledge-lane bootstrap [VERIFIED: repo]
- `lib/mix/tasks/scoria.test.knowledge.ex` - optional knowledge verification lane [VERIFIED: repo]
- `lib/scoria_web/router.ex` - `/scoria` and `/scoria/workflows/:id` route shape [VERIFIED: repo]
- `test/scoria/runtime_integration_test.exs` - canonical runtime + approval + operator evidence proof [VERIFIED: repo]
- `test/mix/tasks/scoria.install_test.exs` - installer idempotence and config injection [VERIFIED: repo]
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - installed route resolution proof [VERIFIED: repo]
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - core-vs-knowledge split [VERIFIED: repo]
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops framing [VERIFIED: repo]
- `prompts/sztheory-elixir-dna.md` - operator-first DX and zero-config onboarding rules [VERIFIED: repo]
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem rationale for a small public runtime vocabulary [VERIFIED: repo]
- `prompts/scoria-brand-book-deep-research.md` - public voice guidance for evidence-first positioning [VERIFIED: repo]
- Local command/test evidence:
  - `SCORIA_DB_PORT=55432 mix test ...` targeted Phase 15 proof lane passed with `8 tests, 0 failures` [VERIFIED: repo test run]
  - `pg_isready -h localhost -p 55432` returned accepting connections [VERIFIED: local command]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: repo]

### Tertiary (LOW confidence)
- None beyond the explicitly listed `[ASSUMED]` planning suggestions in this document. [VERIFIED: repo]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses repo-local public modules, Mix tasks, and existing Phoenix/Ecto dependencies already visible in code. [VERIFIED: mix.exs; lib/scoria.ex; lib/mix/tasks/scoria.install.ex]
- Architecture: HIGH - the canonical runtime semantics are proven by the integration test and locked by Phase 13/15 context. [VERIFIED: test/scoria/runtime_integration_test.exs; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md]
- Pitfalls: HIGH - each major regression risk is visible in the current README drift, installer split, and shipped test semantics. [VERIFIED: README.md; lib/mix/tasks/scoria.install.ex; test/scoria/runtime_integration_test.exs]

**Research date:** 2026-05-15 [VERIFIED: repo]  
**Valid until:** 2026-06-14 for repo-local planning unless the public runtime or installer surface changes materially first [ASSUMED]

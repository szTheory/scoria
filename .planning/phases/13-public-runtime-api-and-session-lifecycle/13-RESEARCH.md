# Phase 13: Public Runtime API and Session Lifecycle - Research

**Researched:** 2026-05-14 [VERIFIED: repo]
**Domain:** Phoenix-facing public runtime facade over durable workflow truth [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo + cited docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Claude's Discretion
- Exact naming between `Scoria.start_run/2` and `Scoria.start/2`, provided the public API stays explicit and the docs teach one obvious start/resume pair.
- Exact layering between `Scoria` and `Scoria.Runtime`, provided `Scoria` remains the canonical happy path and `Scoria.Workflows` does not become the primary product surface again.
- Exact summary/detail public view module names and shapes, provided they stay curated and schema-independent.
- Exact helper APIs for listing or looking up runs by `session_id`, provided `run_id` remains the only exact resume handle.

### Deferred Ideas (OUT OF SCOPE)
- A richer public thread/session/run hierarchy with additional first-class nouns beyond `session_id` and `run_id`.
- Session-first or auto-resolving runtime APIs that decide start vs resume implicitly from persisted state.
- Treating `session_id` as the one true execution handle.
- Exposing raw workflow schemas, checkpoints, or step internals as the default host-app contract.
- Broader policy/default composition and install ergonomics work that belongs to Phase 14.
- Full public docs/example closeout work that belongs to Phase 15.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IDEN-03 | Session identity supports resumable app-facing flows so a Phoenix app can continue a prior run without reconstructing hidden state manually. | Explicit `start_run/2` and `resume_run/2`, host-owned `session_id`, run-owned `run_id`, and session lookup helpers that never replace exact run resume [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| RUNT-01 | Developers can start a run through a documented public `Scoria` API instead of assembling lower-level workflow modules directly. | Use `Scoria` as the happy-path facade over `Scoria.Workflows.create_run/1` and optional `Scoria.Runtime` for advanced entrypoints [VERIFIED: lib/scoria.ex; lib/scoria/workflows.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| RUNT-02 | Developers can resume an interrupted or approval-paused run through the same public runtime surface. | Route public resume through `run_id` into existing durable resume seams, then dispatch execution through the runtime reconciler [VERIFIED: lib/scoria/workflows.ex; lib/scoria/workflows/resume.ex] |
| RUNT-03 | Developers can inspect the current state of a run, including status and durable identifiers needed by the host app. | Add curated summary/detail view structs built from workflow truth instead of exposing `%Scoria.Workflows.Run{}` directly [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/workflows.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 13 is a productization phase, not a workflow-engine rewrite. The durable substrate already creates runs atomically, persists checkpoints and events, pauses for approvals with immutable root identity, and resumes approved runs from durable state; the missing piece is a Phoenix-grade public facade that teaches host apps one obvious way to start, resume, and inspect runs. [VERIFIED: lib/scoria/workflows.ex; lib/scoria/workflows/resume.ex; test/scoria/workflows_test.exs; test/scoria/workflows/runtime_test.exs; test/scoria/workflows/integration_test.exs]

The best plan is to keep `Scoria.Workflows` as internal truth and advanced substrate, add a thin public runtime layer, and return curated run view structs from that layer. Phoenix’s own guidance treats a context module as an API boundary, and Ecto’s docs still support using transactional composition for multi-row invariants, which matches the current repository shape. [CITED: https://hexdocs.pm/phoenix/1.8.5/cross_context_boundaries.html] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

The critical semantic rule is already locked and already consistent with the codebase: `session_id` is grouping and continuity context, while `run_id` is exact execution truth. Planning should therefore center on public contracts that make start versus resume explicit, avoid session-driven inference, and keep host apps from binding to raw workflow schemas. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; lib/scoria/workflows.ex; lib/scoria/workflows/run.ex]

**Primary recommendation:** Build `Scoria.start_run/2`, `Scoria.resume_run/2`, and `Scoria.get_run/2` as the canonical public surface, backed by a repo-local `Scoria.Runtime` facade and curated `RunSummary`/`RunDetail` view structs over existing `Scoria.Workflows` truth. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; lib/scoria.ex; lib/scoria/workflows.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Identity normalization from Plug/LiveView/session input | API / Backend | Frontend Server (SSR) | `Scoria.Identity` already normalizes edge-shaped input into canonical runtime nouns, so framework-specific state should terminate at the library boundary rather than become durable contract shape [VERIFIED: lib/scoria/identity.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Start run public API | API / Backend | — | Run creation writes durable run, checkpoint, and event rows atomically and belongs with workflow truth, not UI state [VERIFIED: lib/scoria/workflows.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Resume paused or failed run | API / Backend | — | Resume mutates durable run and step state, and the exact resume handle is `run_id` [VERIFIED: lib/scoria/workflows.ex; lib/scoria/workflows/resume.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Inspect run summary/detail | API / Backend | Frontend Server (SSR) | The library should shape stable public run DTOs; LiveView and controllers can consume those DTOs for rendering or polling [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria_web/live/workflow_live/show.ex] |
| Session continuity storage | Browser / Client | API / Backend | The host app owns `session_id` continuity and may store it in browser session, chat thread state, or similar app-owned context [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Operator evidence deep-linking | Frontend Server (SSR) | API / Backend | The operator page is already a LiveView route over durable run data, so public run summaries should expose enough identifiers for linking without exposing internals [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.7` published 2026-05-06 [VERIFIED: hex.pm] | Public API should feel like a normal Phoenix library/context boundary [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html] | Phoenix docs treat a context module as an API boundary, which matches the locked `Scoria` facade decision [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html] |
| `ecto` | `3.13.6` published 2026-05-05 [VERIFIED: hex.pm] | Durable run, checkpoint, event, and approval truth [VERIFIED: mix.lock; lib/scoria/workflows.ex] | Existing run lifecycle invariants are already enforced through Ecto transactions and schema changesets [VERIFIED: lib/scoria/workflows.ex; lib/scoria/workflows/run.ex] |
| `ecto_sql` | `3.13.5` published 2026-03-03 [VERIFIED: hex.pm] | Database-backed transaction and migration layer [VERIFIED: mix.lock; priv/repo/migrations] | Phase 13 should reuse the current Ecto-backed substrate rather than introduce another persistence abstraction [VERIFIED: .planning/STATE.md; lib/scoria/workflows.ex] |
| `phoenix_live_view` | `1.1.30` in repo lock; newest Hex release is `1.2.0-rc.2` on 2026-05-05 [VERIFIED: mix.lock; hex.pm] | Existing operator workflow page and integration tests [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; test/scoria/workflows/integration_test.exs] | The public runtime API should feed LiveView projections, not replace them [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| `repo-local Scoria.Identity` | `repo-local` [VERIFIED: lib/scoria/identity.ex] | Canonical app-facing identity envelope and edge normalization | Phase 12 already established identity as the app-facing noun, so Phase 13 should accept this struct at the public runtime boundary [VERIFIED: lib/scoria.ex; lib/scoria/identity.ex; .planning/phases/12-canonical-runtime-identity/12-RESEARCH.md] |
| `repo-local Scoria.Runtime` | `new repo-local facade` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] | Advanced public runtime layer behind `Scoria` happy path | Locked decisions explicitly allow a layered `Scoria` plus `Scoria.Runtime` public boundary [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix.PubSub` | `2.2.0` [VERIFIED: mix.lock; hex.pm docs] | Push operator-run updates after durable writes [VERIFIED: lib/scoria/workflows.ex; lib/scoria_web/live/workflow_live/show.ex] | Keep for projection refresh after public API mutations; do not use it as workflow truth [VERIFIED: lib/scoria/workflows.ex; .planning/phases/05-caldera/05-CONTEXT.md] |
| `ExUnit` + `Phoenix.LiveViewTest` | bundled with current stack [VERIFIED: repo] | Public runtime API and operator-view verification | Use for requirement mapping and async-aware LiveView assertions; LiveView docs recommend `render_async/1` for async tasks [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| `repo-local Scoria.Workflows` | existing substrate [VERIFIED: lib/scoria/workflows.ex] | Internal durable lifecycle engine | Use behind the public facade; do not teach it as the primary host-app surface [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Scoria` facade [VERIFIED: context] | Expose `Scoria.Workflows` directly [VERIFIED: repo] | Faster to ship but violates locked product boundary and leaks workflow nouns into app code [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Explicit `start_run/2` + `resume_run/2` [VERIFIED: context] | Session-first `run/2` dispatcher [VERIFIED: context] | A polymorphic entrypoint would hide execution truth and encourage unsafe session inference [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Curated run DTOs [VERIFIED: context] | Return `%Scoria.Workflows.Run{}` directly [VERIFIED: repo] | Direct schema exposure couples callers to persistence shape and blocks safe contract evolution [VERIFIED: lib/scoria/workflows/run.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |

**Installation:** No new Hex dependency is required for Phase 13; implement on the existing project stack and run `mix deps.get` only as normal dependency hygiene [VERIFIED: mix.exs; mix.lock].

**Version verification:** Use `curl -s https://hex.pm/api/packages/<package>` for current Hex package version and publish date verification in this repo’s Elixir stack [VERIFIED: shell session].

## Architecture Patterns

### System Architecture Diagram

Recommended public runtime flow over existing substrate [VERIFIED: repo + context]:

```text
Host app request / LiveView event / job
        |
        v
Scoria.identity/1 or edge helper
        |
        v
Scoria.start_run/2 or Scoria.resume_run/2
        |
        v
Scoria.Runtime facade
        |
        +--> validate public args and normalize runtime nouns
        |
        +--> Scoria.Workflows.create_run/1 or Scoria.Workflows.Resume.resume_run/2
        |
        +--> durable writes: runs / steps / checkpoints / events / approvals
        |
        +--> curated RunSummary / RunDetail projection
        |
        +--> optional operator link data (run_id, session_id, status)
        |
        v
Host app stores run_id + session_id and renders/polls/link-outs
```

### Recommended Project Structure
```text
lib/
├── scoria.ex                     # happy-path public facade
├── scoria/runtime.ex             # advanced public runtime layer
├── scoria/runtime/
│   ├── run_summary.ex            # stable public summary DTO
│   ├── run_detail.ex             # stable public detail DTO
│   └── params.ex                 # public start/resume/inspect normalization
├── scoria/identity.ex            # canonical identity envelope
└── scoria/workflows/             # durable substrate remains internal truth
test/
├── scoria/runtime_test.exs       # public API unit tests
├── scoria/runtime_integration_test.exs
└── scoria_web/live/...           # operator projection tests
```

### Pattern 1: Thin Public Facade Over Workflow Truth
**What:** `Scoria` should expose only the common app-facing verbs and delegate to a public runtime layer, which in turn composes the existing workflow substrate [VERIFIED: lib/scoria.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**When to use:** For `start_run/2`, `resume_run/2`, and `get_run/2` style operations that host apps call directly [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**Example:**
```elixir
# Source pattern: Phoenix context as API boundary
# https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html
defmodule Scoria do
  def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)
  def start_run(identity, opts \\ []), do: Scoria.Runtime.start_run(identity, opts)
  def resume_run(run_id, opts \\ []), do: Scoria.Runtime.resume_run(run_id, opts)
  def get_run(run_id, opts \\ []), do: Scoria.Runtime.get_run(run_id, opts)
end
```

### Pattern 2: Keep Multi-Row Lifecycle Invariants in One Transaction
**What:** Public start/resume methods should keep durable truth changes inside the substrate’s transaction seams instead of splitting them across facade and workflow layers [VERIFIED: lib/scoria/workflows.ex].  
**When to use:** Any mutation that changes run status, step status, checkpoints, events, or approval state together [VERIFIED: lib/scoria/workflows.ex].  
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:run, run_changeset)
|> Ecto.Multi.run(:checkpoint, fn repo, changes -> {:ok, insert_checkpoint(repo, changes)} end)
|> Ecto.Multi.run(:event, fn repo, changes -> {:ok, insert_event(repo, changes)} end)
|> Repo.transact()
```

### Pattern 3: Public DTOs, Not Raw Schemas
**What:** Build `RunSummary` and `RunDetail` from workflow records and preload trees, but return only curated fields needed by host apps [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/workflows.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**When to use:** All app-facing inspect/list APIs and operator-link helpers [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**Example:**
```elixir
# Source shape: lib/scoria/workflows/run.ex + 13-CONTEXT.md
%RunSummary{
  run_id: run.id,
  session_id: run.session_id,
  status: run.status,
  actor_id: run.actor_id,
  tenant_id: run.tenant_id,
  current_step_id: run.current_step_id,
  latest_checkpoint_id: run.latest_checkpoint_id,
  inserted_at: run.inserted_at,
  started_at: run.started_at,
  completed_at: run.completed_at
}
```

### Anti-Patterns to Avoid
- **Session-driven dispatch:** Do not let `session_id` choose between new run and resume; locked semantics require explicit host choice and exact `run_id` resume [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].
- **Raw schema leakage:** Do not return `%Scoria.Workflows.Run{}` or preload trees as the public contract [VERIFIED: lib/scoria/workflows/run.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].
- **UI-derived durable identity:** Do not preserve `OrchestratorLive` fallback behavior where `session_id` can stand in for actor identity in edge assigns [VERIFIED: lib/scoria_web/live/orchestrator_live.ex].
- **Facade-side truth writes:** Do not spread transactional lifecycle changes across `Scoria`, LiveView, and `Scoria.Workflows`; keep truth changes in one workflow-owned seam [VERIFIED: lib/scoria/workflows.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-row lifecycle transactions | ad hoc `Repo.insert`/`Repo.update` chains in facade code | `Ecto.Multi` / `Repo.transact` [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Existing code already depends on atomic run/checkpoint/event invariants and Ecto documents this pattern directly [VERIFIED: lib/scoria/workflows.ex] |
| Identity normalization | bespoke per-controller/per-LiveView attr parsing | `Scoria.Identity.normalize/1` and helpers [VERIFIED: lib/scoria/identity.ex] | Phase 12 already paid the cost of canonical identity; duplicating normalization would reintroduce drift [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-RESEARCH.md; lib/scoria/identity.ex] |
| Run projection contract | exposing Ecto schema structs directly | `RunSummary` / `RunDetail` DTOs [VERIFIED: context + repo] | Public contracts must stay stable as persistence fields evolve [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; lib/scoria/workflows/run.ex] |
| Resume inference | session-to-run heuristics or latest-run guessing | explicit `resume_run(run_id, opts)` [VERIFIED: context] | Exact resume semantics are already durable-run based and must stay that way [VERIFIED: lib/scoria/workflows.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |

**Key insight:** The hard part of this phase is not execution mechanics; it is contract shaping. The repo already has durable mechanics, so custom glue should be minimized and public nouns should be stabilized instead. [VERIFIED: lib/scoria/workflows.ex; lib/scoria/workflows/resume.ex; test/scoria/workflows/integration_test.exs]

## Common Pitfalls

### Pitfall 1: Treating `session_id` as exact execution truth
**What goes wrong:** A host app resumes the wrong run or cannot disambiguate multiple runs in the same session [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**Why it happens:** `session_id` is continuity context and many runs may share it, while every start creates a fresh `run_id` [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**How to avoid:** Public API docs and types should always return `run_id`, and `resume_run/2` should accept only `run_id` as the exact durable handle [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**Warning signs:** Proposed helpers named `resume_session`, code that selects `latest run by session_id`, or controller state that stores only `session_id` [VERIFIED: context].

### Pitfall 2: Leaking workflow schema internals into host-app code
**What goes wrong:** App code starts depending on workflow preload shape, internal fields, or Ecto semantics [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/workflows.ex].  
**Why it happens:** The current substrate functions naturally return raw schemas, and `get_run_tree!/1` is convenient for internal UI use [VERIFIED: lib/scoria/workflows.ex].  
**How to avoid:** Add a public projection layer that intentionally shapes small stable structs for app-facing inspection [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].  
**Warning signs:** Public docs or examples containing `%Scoria.Workflows.Run{}`, `Repo.preload`, or checkpoint/event traversal in application code [VERIFIED: repo + context].

### Pitfall 3: Re-encoding identity at each edge
**What goes wrong:** Approval/audit/operator evidence diverges from app-facing run identity [VERIFIED: test/scoria/workflows_test.exs; test/scoria/workflows/integration_test.exs].  
**Why it happens:** UI/session code often has tempting fallbacks, such as the dashboard using `session["session_id"]` as actor fallback [VERIFIED: lib/scoria_web/live/orchestrator_live.ex].  
**How to avoid:** Accept `Scoria.Identity` or normalize immediately at the public boundary, then pass canonical identity inward exactly once [VERIFIED: lib/scoria.ex; lib/scoria/identity.ex].  
**Warning signs:** New public functions accepting loose attrs maps with `actor_id`, `tenant_id`, `session_id`, `session`, `mount`, and `assigns` all mixed together [VERIFIED: context].

### Pitfall 4: Testing only substrate seams and not the public facade
**What goes wrong:** The internal workflow engine keeps working, but the public API drifts, returns unstable shapes, or hides missing identifiers [VERIFIED: test/scoria/workflows_test.exs; test/scoria/workflows/integration_test.exs].  
**Why it happens:** Current tests are strong at workflow behavior and thin on facade contracts because `Scoria` is still placeholder-only [VERIFIED: lib/scoria.ex; test/scoria_test.exs].  
**How to avoid:** Add dedicated `Scoria`/`Scoria.Runtime` tests for start, resume, inspect, and same-session multi-run continuity [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md].  
**Warning signs:** New code that updates `Scoria` without any new tests outside `test/scoria/workflows*_test.exs` [VERIFIED: repo].

## Code Examples

Verified patterns from official sources and the current repo:

### Identity Normalization at the Public Boundary
```elixir
# Source: /Users/jon/projects/scoria/lib/scoria.ex
# Source: /Users/jon/projects/scoria/lib/scoria/identity.ex
identity = Scoria.identity(%{
  actor_id: "user-123",
  tenant_id: "tenant-456",
  session_id: "chat-789"
})
```

### Atomic Run Creation Pattern
```elixir
# Source: /Users/jon/projects/scoria/lib/scoria/workflows.ex
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:run, run_changeset)
  |> Ecto.Multi.run(:checkpoint, fn repo, changes -> {:ok, insert_checkpoint(repo, changes)} end)
  |> Ecto.Multi.run(:event, fn repo, changes -> {:ok, insert_event(repo, changes)} end)
  |> Ecto.Multi.update(:run_with_checkpoint, fn changes ->
    Run.changeset(changes.run, %{latest_checkpoint_id: changes.checkpoint.id})
  end)
```

### LiveView Async Test Pattern
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
{:ok, view, _html} = live(conn, "/my_live_view")
html = render_async(view)
assert html =~ "data loaded!"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat lower-level context modules as the de facto app API | Phoenix continues to document contexts as the API boundary for application functionality [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html] | Verified against Phoenix 1.8.5 docs on 2026-05-14 [VERIFIED: web session] | Supports shaping `Scoria` as the app-facing boundary without turning `Scoria.Workflows` into the product surface [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html] |
| Ad hoc transaction chains for complex lifecycle writes | Ecto 3.13.6 still documents `Ecto.Multi` and `Repo.transact` for composed transaction flows [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | Verified against Ecto 3.13.6 docs on 2026-05-14 [VERIFIED: web session] | Reinforces keeping lifecycle invariants in workflow-owned transaction seams [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Placeholder `Scoria` module with only identity helper | Keystone requires `Scoria` to become the happy-path runtime facade [VERIFIED: lib/scoria.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] | Local repo state as of 2026-05-14 [VERIFIED: repo] | Phase 13 should spend work on contract curation rather than new runtime mechanics [VERIFIED: repo + context] |

**Deprecated/outdated:**
- `README.md` still says "`v1.3` is next," which is stale relative to project state and milestone docs [VERIFIED: README.md; .planning/STATE.md; .planning/PROJECT.md].
- `Scoria` as a placeholder-only module is outdated for Keystone planning because Phase 13 explicitly turns it into the public runtime boundary [VERIFIED: lib/scoria.ex; .planning/ROADMAP.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].

## Assumptions Log

All material claims in this research were verified against the repo, Hex package metadata, or official docs in this session. No user-confirmation assumptions remain. [VERIFIED: research session]

## Open Questions (RESOLVED)

1. **Public inspect naming**
   - Decision: keep the top-level `Scoria.get_run/2` summary-only and place the richer inspect variant under `Scoria.Runtime.get_run_detail/2`.
   - Rationale: this preserves a small happy-path facade while still allowing an explicit curated detailed view, which matches the locked Phase 13 decisions around a default summary plus advanced detail [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md].

2. **Same-session lookup scope**
   - Decision: ship a read-only session-grouping helper in Phase 13, but keep it explicitly non-resume-authoritative and return curated summaries only.
   - Rationale: the phase context allows session-based helper APIs as long as `run_id` remains the only exact resume handle, and the roadmap's inspection/continuity plans benefit from a concrete host-app grouping helper rather than leaving that contract implicit [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md; .planning/ROADMAP.md].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and test public runtime modules | ✓ [VERIFIED: shell session] | `1.19.5` [VERIFIED: shell session] | — |
| Mix | Test execution and dependency tasks | ✓ [VERIFIED: shell session] | `1.19.5` [VERIFIED: shell session] | — |
| PostgreSQL | Ecto-backed workflow and integration tests | ✓ [VERIFIED: shell session; config/test.exs] | `localhost:5432 accepting connections` [VERIFIED: shell session] | — |

**Missing dependencies with no fallback:** None found in this session [VERIFIED: shell session].

**Missing dependencies with fallback:** None found in this session [VERIFIED: shell session].

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` with `Phoenix.LiveViewTest` [VERIFIED: test/scoria/workflows/integration_test.exs] |
| Config file | `config/test.exs` [VERIFIED: config/test.exs] |
| Quick run command | `MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/integration_test.exs` [VERIFIED: planning contract] |
| Full suite command | `MIX_ENV=test mix test` [VERIFIED: repo conventions] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IDEN-03 | Same `session_id` can start multiple runs, and exact continuation uses `run_id` rather than implicit session state [VERIFIED: context] | integration | `MIX_ENV=test mix test test/scoria/runtime_integration_test.exs -x` | ❌ Wave 0 [VERIFIED: repo] |
| RUNT-01 | `Scoria.start_run/2` starts a run without calling `Scoria.Workflows` directly from app code [VERIFIED: requirements + context] | unit + integration | `MIX_ENV=test mix test test/scoria/runtime_test.exs -x` | ❌ Wave 0 [VERIFIED: repo] |
| RUNT-02 | `Scoria.resume_run/2` resumes approval-paused or interrupted runs through the same public surface [VERIFIED: requirements + context] | integration | `MIX_ENV=test mix test test/scoria/runtime_integration_test.exs -x` | ❌ Wave 0 [VERIFIED: repo] |
| RUNT-03 | `Scoria.get_run/2` returns stable summary/detail fields with durable identifiers [VERIFIED: requirements + context] | unit | `MIX_ENV=test mix test test/scoria/runtime_view_test.exs -x` | ❌ Wave 0 [VERIFIED: repo] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/runtime_view_test.exs`
- **Per wave merge:** `MIX_ENV=test mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/runtime_test.exs` — public facade unit coverage for `start_run/2`, `resume_run/2`, and parameter normalization [VERIFIED: repo].
- [ ] `test/scoria/runtime_integration_test.exs` — same-session multi-run continuity and exact `run_id` resume [VERIFIED: requirements + context].
- [ ] `test/scoria/runtime_view_test.exs` — stable public summary/detail projection shape assertions [VERIFIED: context].
- [ ] Update `test/scoria/workflows/integration_test.exs` or add a public-facade integration equivalent so the operator LiveView can be exercised through the new public surface too [VERIFIED: test/scoria/workflows/integration_test.exs].

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: project scope] | Host app remains responsible for authenticating callers before invoking Scoria runtime APIs [VERIFIED: .planning/PROJECT.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| V3 Session Management | yes [VERIFIED: requirements + context] | Treat `session_id` as host-owned continuity state only; never as exact resume authority [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: phase scope] | Resume and inspect entrypoints should require explicit `run_id` and expect host-app authorization before disclosure or mutation [VERIFIED: context + repo] |
| V5 Input Validation | yes [VERIFIED: phase scope] | Normalize inputs through `Scoria.Identity` and public parameter modules; keep workflow writes behind Ecto changesets [VERIFIED: lib/scoria/identity.ex; lib/scoria/workflows/run.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new cryptographic primitive is required in this phase [VERIFIED: repo + requirements] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure direct object reference on `run_id` inspect/resume | Elevation of Privilege | Keep `run_id` explicit, but require host-app authz before calling public runtime inspect/resume functions; do not add unauthenticated convenience lookups [VERIFIED: context + project scope] |
| Session confusion between new-turn start and exact resume | Tampering | Separate `start_run/2` from `resume_run/2` and document `session_id` as grouping only [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md] |
| Raw schema leakage exposing internal evidence or mutable fields | Information Disclosure | Return curated run DTOs instead of `%Scoria.Workflows.Run{}` or preload trees [VERIFIED: context + repo] |
| Duplicate or unsafe lifecycle mutation outside workflow seams | Tampering | Keep public facade thin and route state changes through existing workflow-owned transactions [VERIFIED: lib/scoria/workflows.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/scoria/.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - locked decisions, scope, and allowed discretion [VERIFIED: repo]
- `/Users/jon/projects/scoria/lib/scoria.ex` - current placeholder public facade [VERIFIED: repo]
- `/Users/jon/projects/scoria/lib/scoria/identity.ex` - canonical identity envelope and normalization helpers [VERIFIED: repo]
- `/Users/jon/projects/scoria/lib/scoria/workflows.ex` - run creation, approval wait, resume, retry, and audit linkage seams [VERIFIED: repo]
- `/Users/jon/projects/scoria/lib/scoria/workflows/run.ex` - durable run schema fields available for public DTOs [VERIFIED: repo]
- `/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex` - operator-facing run evidence surface [VERIFIED: repo]
- `/Users/jon/projects/scoria/test/scoria/workflows_test.exs` - atomic lifecycle and immutable approval identity tests [VERIFIED: repo]
- `/Users/jon/projects/scoria/test/scoria/workflows/runtime_test.exs` - runtime pause/resume and retry behavior [VERIFIED: repo]
- `/Users/jon/projects/scoria/test/scoria/workflows/integration_test.exs` - end-to-end approval resume and operator page behavior [VERIFIED: repo]
- `https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html` - Phoenix API boundary guidance [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Context.html]
- `https://hexdocs.pm/phoenix/1.8.5/cross_context_boundaries.html` - Phoenix cross-context boundary guidance [CITED: https://hexdocs.pm/phoenix/1.8.5/cross_context_boundaries.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transactional composition guidance [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - async testing guidance via `render_async/1` [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` - topic subscribe/broadcast behavior [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html]
- `https://hex.pm/api/packages/phoenix` - current Phoenix version and publish date [VERIFIED: hex.pm]
- `https://hex.pm/api/packages/ecto` - current Ecto version and publish date [VERIFIED: hex.pm]
- `https://hex.pm/api/packages/ecto_sql` - current Ecto SQL version and publish date [VERIFIED: hex.pm]
- `https://hex.pm/api/packages/phoenix_live_view` - current LiveView release metadata [VERIFIED: hex.pm]

### Secondary (MEDIUM confidence)
- None needed; primary sources covered the important claims [VERIFIED: research session].

### Tertiary (LOW confidence)
- None [VERIFIED: research session].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions were verified against Hex and the recommended implementation stays on the existing repo stack [VERIFIED: mix.lock; hex.pm].
- Architecture: HIGH - the facade-over-substrate recommendation is directly supported by locked context decisions and existing workflow seams [VERIFIED: context + repo].
- Pitfalls: HIGH - all listed pitfalls are visible in locked semantics, existing code, or existing tests [VERIFIED: context + repo].

**Research date:** 2026-05-14 [VERIFIED: repo]
**Valid until:** 2026-06-13 for repo-local findings; 2026-05-21 for current package-release metadata [VERIFIED: research session]

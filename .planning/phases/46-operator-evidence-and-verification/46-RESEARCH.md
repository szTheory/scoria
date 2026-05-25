# Phase 46: Operator evidence and verification - Research

**Researched:** 2026-05-25
**Domain:** Semantic-cache operator evidence, Phoenix LiveView projection, and checked verification lanes in Scoria. [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Operator surface ownership
- **D-01:** The workflow run page is the canonical deep-inspection surface for semantic-cache evidence. The runtime presence surface stays summary-first and links into workflow evidence rather than duplicating the full notebook.
- **D-02:** The runtime surface should answer only the first-line operator questions: what happened, was the answer reused or did Scoria fall back, why, and where should the operator click next.
- **D-03:** The runtime surface should show a compact semantic summary with explicit `lookup_status`, fallback outcome, `lane_key`, `scope_kind`, `scope_reason`, one decisive reason chip, and deep links to the workflow evidence view and origin run when relevant.
- **D-04:** The workflow run page should expose the full semantic-evidence notebook because it already owns the trace tree, step detail, replay context, promotion flows, and other durable run-level evidence.

### Evidence contract and vocabulary
- **D-05:** Phase 46 must not invent a second semantic taxonomy. Operator-visible evidence should reuse the Phase 44 and Phase 45 nouns directly: `bypass`, `miss`, `reject`, `hit`; `active`, `stale`, `invalidated`, `writeback_rejected`; `eligibility_reason_code`; `lookup_reason_code`.
- **D-06:** Fallback is evidence, not absence. The UI and DTOs should explicitly show that Scoria evaluated the fast path and intentionally continued through the normal runtime path when reuse did not qualify.
- **D-07:** The operator story should remain reason-coded and stage-separated. `bypass`, `miss`, `reject`, and `stale` must stay distinct in UI copy, DTOs, and verification.
- **D-08:** Phase 46 should lead with operator-proof fields, not internals. Show verdict, fallback, scope, reason, and provenance first; embeddings and similarity internals are secondary debug detail.

### Evidence density and progressive disclosure
- **D-09:** Semantic evidence should use progressive disclosure in four layers:
  1. verdict, reason, age, lane, tenant/actor scope, fallback outcome
  2. compatibility checklist: prompt, policy, source, freshness, similarity
  3. provenance links: source run, cache entry, writeback event, invalidation event
  4. raw metadata / JSON escape hatch
- **D-10:** The workflow evidence notebook should present a dense but one-screen-understandable summary strip before any raw payloads or long metadata blocks.
- **D-11:** The runtime surface should stay concise enough for incident triage and should not absorb the full compatibility matrix, lifecycle timeline, or raw JSON view.
- **D-12:** Actor identity should only be surfaced prominently when scope is narrowed to `actor_scoped` or when it materially explains why reuse was fenced. Tenant-shared outcomes should not over-emphasize actor data.

### Provenance and lifecycle visibility
- **D-13:** Every reusable semantic entry should surface version-rooted provenance: source run/trace linkage, prompt identity/version, policy fingerprint snapshot, source fingerprint, lane, scope, created/reused times, and invalidation or stale reason when applicable.
- **D-14:** Workflow evidence should show entry lifecycle truth as first-class operator evidence: current status, `expires_at`, `invalidated_at`, `hit_count`, `last_hit_at`, and append-only semantic entry events.
- **D-15:** Rejected or stale candidates should remain inspectable as candidates that were found and refused, not flattened into a generic miss.

### Verification lane and support truth
- **D-16:** `PROOF-01` should ship as a dedicated checked verification lane, preferred task name `mix test.semantic_fast_path`, instead of being folded into `mix test.adoption` or left implicit in the full suite.
- **D-17:** The semantic verification lane should prove tenant partitioning, explicit fallback and bypass semantics, invalidation visibility, and the operator-surface projection of semantic outcomes.
- **D-18:** `mix test.adoption` should remain the public-runtime/adoption proof lane. `mix test` remains the release-confidence umbrella. The semantic lane becomes the canonical troubleshooting and support-truth answer for `v2.1`.
- **D-19:** Milestone docs should ship one boring golden path for semantic fast-path verification and troubleshooting so the support story, operator UI vocabulary, and test lane all say the same thing.

### Shift-left defaults
- **D-20:** Future GSD planning for semantic-cache work should treat these as locked defaults unless a later phase changes product shape, security or policy boundary, durable truth, tenant blast radius, or materially different operator UX:
  - workflow page is canonical deep-inspection surface
  - runtime surface is summary-first with strong deep links
  - semantic evidence uses the Phase 44/45 noun set without a second taxonomy
  - semantic proof ships as a dedicated named verification lane
- **D-21:** Later discuss/planning steps should not re-ask about duplicating full semantic detail across runtime and workflow surfaces, leading with analytics or hit-rate dashboards, or collapsing semantic proof into broader test lanes unless milestone scope changes.

### the agent's Discretion
- Exact component/module names for the semantic evidence panel, summary cards, and supporting function components.
- Exact DTO field names or grouping as long as they preserve the single semantic-evidence contract.
- Exact chip/badge copy and visual treatment as long as verdict, fallback, scope, reason, and provenance remain primary.
- Exact verification task module naming (`Mix.Tasks.Test.SemanticFastPath` vs a namespaced twin) so long as one canonical user-facing command exists.
- Exact split between LiveView async loading and eager assigns, provided summary truth renders immediately and heavier evidence loads without blocking the page.

### Deferred Ideas (OUT OF SCOPE)
- A second full semantic trace explorer inside the runtime surface.
- Symmetric deep semantic notebooks on both runtime and workflow pages.
- Analytics-first cache dashboards, hit-rate-first operator stories, or dense metric walls before the evidence notebook is proven boring.
- Annotation queues, review inboxes, or broader semantic evidence triage workflows beyond what is needed to satisfy `EVID-01` and `PROOF-01`.
- Hosted-style observability control-plane features, external cache evidence services, or non-Ecto primary truth paths.
- Broad proof-lane consolidation into `mix test.adoption` or `mix test` unless a later milestone intentionally redefines those contracts.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVID-01 | Operators can inspect cache hit, miss, stale, and rejection outcomes with provenance and partitioning context in Scoria runtime or workflow surfaces. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse existing runtime metadata and semantic-cache durable truth, then project one curated semantic-evidence DTO into the runtime drawer summary and workflow notebook. [VERIFIED: codebase grep] |
| PROOF-01 | Scoria ships a checked verification lane that proves semantic fast-path partitioning, fallback semantics, and invalidation behavior. [VERIFIED: .planning/REQUIREMENTS.md] | Add a named Mix task and explicit test inventory that covers cache semantics, operator projection, and docs/task discoverability. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Project.html] |
</phase_requirements>

## Summary

Phase 46 should not invent new semantic logic. The cache truth already exists in three places: `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1` records stage-separated runtime metadata, `Scoria.SemanticCache.Entry` persists lifecycle/provenance fields, and `Scoria.SemanticCache.EntryEvent` persists append-only event lineage. The phase is therefore a projection problem plus a proof-lane problem, not a new cache-engine phase. [VERIFIED: codebase grep]

The safest implementation is to extend Scoria’s existing curated DTO pattern instead of letting LiveViews reconstruct semantic meaning from raw rows. `Scoria.Runtime.get_run_detail!/1` already returns a `RunDetail` struct for workflow inspection, and the runtime drawer is already intentionally summary-first and links to `/workflows/:id`. That matches the locked product posture exactly: runtime presence stays concise, workflow detail stays canonical. [VERIFIED: codebase grep]

The proof lane should mirror the existing `mix test.adoption` pattern: one named Mix task, one discoverability test, one bounded file list, and matching docs. The repo already proves this approach works for support-truth lanes, and `mix.exs` already uses `preferred_envs` to pin those tasks to `:test`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Project.html]

**Primary recommendation:** Project one curated semantic-evidence contract from runtime metadata plus semantic-cache entry/event truth, render it summary-first in the runtime drawer and notebook-style in the workflow page, and ship it behind a dedicated `mix test.semantic_fast_path` lane with explicit UI/runtime/cache/docs coverage. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Semantic outcome derivation | API / Backend | Database / Storage | `prepare_semantic_fast_path/1` already computes `lookup_status`, reason codes, lane, scope, and fallback facts before any UI renders them. [VERIFIED: codebase grep] |
| Durable provenance and lifecycle truth | Database / Storage | API / Backend | Entry rows and entry events already persist status, stale/invalidation timestamps, hit counts, and lineage refs that operator surfaces can reuse. [VERIFIED: codebase grep] |
| Curated workflow inspection DTO | API / Backend | Browser / Client | `Runtime.get_run_detail!/1` and `RunDetail.from_run_tree/2` already define the repo’s stable inspection pattern for LiveViews. [VERIFIED: codebase grep] |
| Workflow deep evidence UI | Browser / Client | API / Backend | `WorkflowLive.Show` and `WorkflowDetailPanelComponent` already own the selected-step right rail and deep run inspection surface. [VERIFIED: codebase grep] |
| Runtime summary evidence UI | Browser / Client | API / Backend | `RuntimeDetailDrawerComponent` is already compact, summary-first, and links to the canonical workflow page. [VERIFIED: codebase grep] |
| Verification lane orchestration | API / Backend | Browser / Client | Named Mix tasks and ExUnit file lists live in backend code, while LiveView/component tests prove the operator surfaces. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | locked/latest `1.8.7`, released 2026-05-06. [VERIFIED: mix hex.info phoenix] | Function components, LiveView integration, and Scoria dashboard rendering. [CITED: https://hexdocs.pm/phoenix/components.html] | Phoenix function components are the standard building block for shared markup in Phoenix apps. [CITED: https://hexdocs.pm/phoenix/components.html] |
| `phoenix_live_view` | locked stable `1.1.30`, released 2026-05-05; newer `1.2.0-rc.*` exists but is prerelease. [VERIFIED: mix hex.info phoenix_live_view] | Workflow page rendering and LiveView tests for operator evidence. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] | The repo already uses LiveView pages and component tests for operator surfaces, so Phase 46 should extend that same seam. [VERIFIED: codebase grep] |
| `ecto_sql` | locked `3.13.5`; latest `3.14.0` released 2026-05-19. [VERIFIED: mix hex.info ecto_sql] | Fetching semantic entry/event truth for curated DTO projection. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | The phase reuses persisted row/event truth rather than transient UI-only state. [VERIFIED: codebase grep] |
| Elixir `ExUnit` / `mix test` | Elixir/Mix `1.19.5` on this machine. [VERIFIED: elixir --version] [VERIFIED: mix --version] | Bounded proof lane, file-list execution, and LiveView/component coverage. [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ExUnit filtering and file-targeted runs are the standard way to keep a named lane explicit and inspectable. [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | locked/latest `2.22.1`, released 2026-04-30. [VERIFIED: mix hex.info oban] | Existing workflow/background substrate; not a new dependency for this phase. [VERIFIED: mix hex.info oban] | Reuse only as already present; Phase 46 should not create async proof orchestration. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |
| Internal `Scoria.Runtime.RunDetail` | current repo struct. [VERIFIED: codebase grep] | Canonical workflow evidence DTO seam. [VERIFIED: codebase grep] | Extend when deep semantic evidence needs durable, typed projection for the workflow page. [VERIFIED: codebase grep] |
| Internal `Scoria.SemanticCache.Entry` + `EntryEvent` | current repo schemas. [VERIFIED: codebase grep] | Provenance, lifecycle, and candidate-event truth. [VERIFIED: codebase grep] | Use for notebook details, event timelines, and raw provenance escape hatches. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] [VERIFIED: codebase grep] |
| Internal `Mix.Tasks.Scoria.Test.Adoption` pattern | current repo task. [VERIFIED: codebase grep] | Named verification lane template. [VERIFIED: codebase grep] | Copy the bounded task-file-list and wrapper pattern for `mix test.semantic_fast_path`. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Curated semantic-evidence DTOs | Raw LiveView queries and per-component map spelunking | That would bypass the repo’s existing inspection contract and make workflow/runtime surfaces drift independently. [VERIFIED: codebase grep] |
| One canonical deep surface on workflow page | Full semantic notebooks on both runtime and workflow surfaces | The user explicitly deferred duplication and locked summary-first runtime UX. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |
| Dedicated `mix test.semantic_fast_path` lane | Folding Phase 46 into `mix test.adoption` or `mix test` | The user explicitly locked a dedicated semantic proof lane and retained adoption/full suite as separate contracts. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |

**Installation:** No new Hex dependencies are needed for Phase 46; the existing Phoenix/LiveView/Ecto/ExUnit stack is already present in `mix.exs`. [VERIFIED: codebase grep]

```bash
mix deps.get
```

**Version verification:** [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info oban]

```bash
mix hex.info phoenix
mix hex.info phoenix_live_view
mix hex.info ecto_sql
mix hex.info oban
```

## Architecture Patterns

### System Architecture Diagram

```text
Runtime.start_run/2 or existing run
  -> Workflows.Runtime.prepare_semantic_fast_path/1
     -> runtime metadata carries lookup_status / reason / lane / scope / origin refs
  -> SemanticCache.Entry + EntryEvent remain durable lifecycle truth
  -> Runtime.get_run_detail!/1
     -> curated semantic evidence DTO
        -> runtime drawer summary projection
        -> workflow page semantic notebook
  -> Mix task lane
     -> cache lookup/invalidation tests
     -> runtime metadata tests
     -> workflow LiveView + component tests
     -> docs/task discoverability tests
```
This matches the current code seams: semantic outcome shaping happens before UI rendering, durable truth stays in Ecto-backed rows/events, and both operator surfaces already sit behind curated runtime/workflow APIs. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/
├── scoria/runtime/run_detail.ex                    # extend deep workflow evidence DTO
├── scoria/runtime.ex                               # keep curated detail fetch boundary
├── scoria/semantic_cache.ex                        # existing public semantic cache context
├── scoria/semantic_cache/entry.ex                  # durable semantic entry truth
├── scoria/semantic_cache/entry_event.ex            # append-only semantic lifecycle evidence
├── scoria_web/components/runtime_detail_drawer_component.ex
├── scoria_web/components/workflow_detail_panel_component.ex
├── mix/tasks/scoria.test.semantic_fast_path.ex     # canonical file-list lane
└── mix/tasks/test.semantic_fast_path.ex            # compatibility wrapper

test/
├── scoria/runtime/semantic_fast_path_test.exs
├── scoria/semantic_cache/lookup_test.exs
├── scoria/semantic_cache/invalidation_test.exs
├── scoria_web/live/workflow_live_test.exs
├── scoria_web/components/runtime_detail_drawer_component_test.exs
└── mix/tasks/test.semantic_fast_path_test.exs
```
The component/module names are discretionary, but these are the existing seams the phase should extend rather than bypass. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

### Pattern 1: Curated Semantic-Evidence DTO
**What:** Build one curated semantic-evidence contract from runtime metadata plus entry/event truth, then feed both surfaces from that single projection. [VERIFIED: codebase grep]

**When to use:** Always for workflow detail and any runtime summary field beyond the already-persisted metadata strip. [VERIFIED: codebase grep]

**Example:**
```elixir
defmodule Scoria.Runtime.RunDetail do
  defstruct [..., :semantic_evidence]

  def from_run_tree(run, opts \\ []) do
    %__MODULE__{
      ...,
      semantic_evidence: Keyword.get(opts, :semantic_evidence, %{})
    }
  end
end
```
This follows the repo’s existing curated DTO pattern instead of pushing semantic joins into LiveViews. [VERIFIED: codebase grep]

### Pattern 2: Runtime Summary Plus Deep Link
**What:** Keep the runtime drawer limited to verdict, fallback, scope, reason, lane, and deep links to the workflow page and origin run. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

**When to use:** In `RuntimeDetailDrawerComponent` only. [VERIFIED: codebase grep]

**Example:**
```elixir
attr :drawer, :map, default: nil

def render(assigns) do
  ~H"""
  <section :if={@drawer}>
    <p><%= @drawer.semantic.lookup_status %></p>
    <p><%= @drawer.semantic.reason_code %></p>
    <.link navigate={@drawer.semantic.workflow_href}>View workflow evidence</.link>
  </section>
  """
end
```
Phoenix function components with explicit attrs are the standard rendering seam for this type of shared UI. [CITED: https://hexdocs.pm/phoenix/components.html]

### Pattern 3: Named Verification Lane Wrapper
**What:** Model the semantic proof lane after the existing adoption lane: one task module with a fixed file list plus a compatibility wrapper task. [VERIFIED: codebase grep]

**When to use:** For `mix scoria.test.semantic_fast_path` and `mix test.semantic_fast_path`. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

**Example:**
```elixir
defmodule Mix.Tasks.Scoria.Test.SemanticFastPath do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ semantic_fast_path_test_files())
  end
end
```
Mix tasks are the standard way to expose public project commands, and `preferred_envs` is the right place to pin them to `:test`. [CITED: https://hexdocs.pm/mix/Mix.Project.html] [CITED: https://hexdocs.pm/mix/Mix.Task.html]

### Anti-Patterns to Avoid
- **Recomputing semantic truth in LiveViews:** Outcome classification already exists in runtime metadata and semantic-cache rows/events. [VERIFIED: codebase grep]
- **Second semantic taxonomy:** The user locked the Phase 44/45 noun set as the only operator vocabulary. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
- **Runtime-surface bloat:** The runtime drawer is intentionally compact and should not become a second trace explorer. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
- **Implicit proof through broad suites:** Phase 46 requires one named troubleshooting answer, not accidental coverage. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Semantic outcome vocabulary | New prose-only labels disconnected from runtime codes | Existing `lookup_status`, `eligibility_reason_code`, `lookup_reason_code`, and entry statuses | The locked contract explicitly forbids a second taxonomy. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |
| Workflow evidence fetching | Ad hoc queries in LiveViews | Existing `Runtime.get_run_detail!/1` curated DTO boundary | The repo already uses DTO projection to keep operator truth stable and testable. [VERIFIED: codebase grep] |
| Verification lane plumbing | Shell scripts or README-only commands | Named Mix tasks plus ExUnit file lists | This is already the repo’s proven support-truth pattern. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Project.html] |
| UI behavior proof | Manual browser-only verification | `Phoenix.LiveViewTest` and component tests | LiveView’s testing API is the standard way to exercise both disconnected and connected mounts and interaction paths. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

**Key insight:** The hard part of this phase is not rendering chips; it is preserving one operator-proof semantic story across DTOs, UI copy, docs, and the named test lane. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Duplicating or renaming semantic outcomes in the UI
**What goes wrong:** Operators see “fallback”, “stale”, “miss”, or “rejected” used inconsistently between runtime, workflow, and tests. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
**Why it happens:** UI copy gets authored as a parallel taxonomy instead of a projection of runtime codes. [VERIFIED: codebase grep]
**How to avoid:** Drive labels and chips from the existing status/reason fields and reserve prose for explanation sentences only. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
**Warning signs:** Planner tasks mention “friendly aliases” for hit/miss/reject/stale without mapping them back to exact codes. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

### Pitfall 2: Letting the workflow page rebuild cache truth from raw rows
**What goes wrong:** Workflow and runtime surfaces drift because each assembles semantic facts differently. [VERIFIED: codebase grep]
**Why it happens:** LiveViews read raw schemas directly instead of using curated DTO projection. [VERIFIED: codebase grep]
**How to avoid:** Extend `RunDetail` or an adjacent curated contract and keep LiveViews render-only. [VERIFIED: codebase grep]
**Warning signs:** New Ecto queries appear inside `WorkflowLive.Show` or component modules for semantic classification logic. [VERIFIED: codebase grep]

### Pitfall 3: Turning the runtime drawer into a second notebook
**What goes wrong:** Incident triage gets slower because the summary surface starts mirroring deep workflow detail. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
**Why it happens:** The runtime surface absorbs compatibility matrices, event timelines, or raw JSON blocks. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
**How to avoid:** Keep the drawer to verdict, fallback, scope, reason, lane, and links. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
**Warning signs:** Component plans mention “full trace”, “timeline”, or “raw metadata” in the runtime drawer. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

### Pitfall 4: Shipping a named proof lane without matching docs and discoverability tests
**What goes wrong:** `mix test.semantic_fast_path` exists but support docs, wrappers, or lane tests drift. [VERIFIED: codebase grep]
**Why it happens:** The command is added without the same bounded-lane discipline used by `mix test.adoption`. [VERIFIED: codebase grep]
**How to avoid:** Add both task modules, a test asserting the file list, `preferred_envs`, and docs/source mentions. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Project.html]
**Warning signs:** There is no `test/mix/tasks/test.semantic_fast_path_test.exs` analogue or docs still point users to `mix test` only. [VERIFIED: codebase grep]

### Pitfall 5: Planning against the wrong database path
**What goes wrong:** Verification commands fail before assertions run because the repo is compiled for one DB port and executed against another. [VERIFIED: mix test]
**Why it happens:** This checkout is currently compiled for `SCORIA_DB_PORT=55432`, while `config/test.exs` defaults to `5432`; the working pgvector-capable service is on `55432`, and running the target lane against `5432` currently raises a compile-env mismatch. [VERIFIED: codebase grep] [VERIFIED: mix test] [VERIFIED: pg_isready] [VERIFIED: psql vector extension query]
**How to avoid:** Preserve a Wave 0 environment-alignment task in the plan before treating the new semantic lane as canonical. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-00-PLAN.md] [VERIFIED: mix test]
**Warning signs:** Mix reports `different value set for key Scoria.Repo during runtime compared to compile time`. [VERIFIED: mix test]

## Code Examples

Verified patterns from official sources:

### Phoenix function component with declared attrs
```elixir
use Phoenix.Component

attr :message, :string, required: true

def banner(assigns) do
  ~H"""
  <p><%= @message %></p>
  """
end
```
Source: Phoenix components guide and `Phoenix.Component` conventions. [CITED: https://hexdocs.pm/phoenix/components.html]

### LiveView integration test seam
```elixir
{:ok, view, _html} = live(conn, "/some/path")

view
|> element("button[phx-click='select']")
|> render_click()
```
Source: `Phoenix.LiveViewTest` interaction helpers. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Named task environment pinning
```elixir
def cli do
  [
    preferred_envs: [:"test.semantic_fast_path": :test]
  ]
end
```
Source: `Mix.Project.cli/0` preferred env configuration. [CITED: https://hexdocs.pm/mix/Mix.Project.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad suite or adoption-lane proof only | Dedicated semantic proof lane with explicit test inventory | Locked in Phase 46 context on 2026-05-25. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] | Gives operators and maintainers one exact troubleshooting command. [VERIFIED: .planning/REQUIREMENTS.md] |
| Runtime metadata only, no operator projection | Curated operator projection from runtime metadata plus durable entry/event truth | Phase 46 boundary on 2026-05-25. [VERIFIED: .planning/ROADMAP.md] | Enables inspectable hit/miss/reject/stale provenance without changing cache semantics. [VERIFIED: .planning/REQUIREMENTS.md] |
| Ad hoc deep evidence features in earlier milestones | Workflow page as canonical notebook, runtime surface as summary-first | Established by current workflow/runtime surfaces and locked again in Phase 46. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] | Keeps operator UX legible and avoids duplicated inspection surfaces. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |

**Deprecated/outdated:**
- Treating fallback as “nothing happened” is outdated for this milestone; fallback itself must render as operator evidence. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
- Treating `mix test` or `mix test.adoption` as the semantic fast-path proof answer is outdated for `v2.1`. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

## Assumptions Log

All claims in this research were verified or cited in this session; no user confirmation is required before planning.

## Open Questions

1. **Should Phase 46 preserve the currently working `55432` pgvector verification path or force a Wave 0 recompile to `5432` first?**
   - What we know: `55432` is reachable, has `vector` extension `0.8.2`, and the targeted semantic/UI lane passed there; `5432` is reachable but the repo currently fails with a compile-env mismatch when that port is used. [VERIFIED: pg_isready] [VERIFIED: psql vector extension query] [VERIFIED: mix test]
   - What's unclear: whether the planner should treat port realignment as in-scope here or inherit the Phase 45 fallback posture for immediate execution. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-00-PLAN.md]
   - Recommendation: keep a Wave 0 environment-alignment task in the plan and choose explicitly between “recompile to `5432`” and “ship Phase 46 on the already-green `55432` lane.” [VERIFIED: mix test]

2. **Should semantic deep evidence live directly on `RunDetail` or in an adjacent nested struct?**
   - What we know: `RunDetail` is already the canonical curated workflow inspection DTO and the repo has used this pattern for replay and delegated evidence. [VERIFIED: codebase grep]
   - What's unclear: whether adding semantic evidence directly to the existing struct is the least disruptive API shape or whether a nested struct would keep future additions cleaner. [VERIFIED: codebase grep]
   - Recommendation: plan against one curated contract either way, but decide the struct shape early so both surfaces and tests share the same field names. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, ExUnit, LiveView tests | ✓ | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Named verification lane | ✓ | `1.19.5` [VERIFIED: mix --version] | — |
| PostgreSQL on `55432` | Current green semantic-cache test path | ✓ | `14.17` client; pgvector `0.8.2` on `scoria_test`. [VERIFIED: psql --version] [VERIFIED: pg_isready] [VERIFIED: psql vector extension query] | Current working path. [VERIFIED: mix test] |
| PostgreSQL on `5432` | Default `config/test.exs` path and prior phase alignment target | ✓ with caveat | reachable, but current lane fails compile-env validation before semantic assertions. [VERIFIED: pg_isready] [VERIFIED: mix test] | Recompile against `5432` or keep `55432` lane. [VERIFIED: mix test] |

**Missing dependencies with no fallback:**
- None for planning. [VERIFIED: elixir --version] [VERIFIED: mix --version]

**Missing dependencies with fallback:**
- `5432` is not currently a trusted execution path for this checkout; the fallback is the already-green `55432` pgvector service until the repo is recompiled or config is realigned. [VERIFIED: mix test]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: elixir --version] |
| Config file | [test/test_helper.exs](/Users/jon/projects/scoria/test/test_helper.exs:1) and [config/test.exs](/Users/jon/projects/scoria/config/test.exs:1). [VERIFIED: codebase grep] |
| Quick run command | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/mix/tasks/test.adoption_test.exs --trace` is currently green. [VERIFIED: mix test] |
| Full suite command | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test` until the port strategy is realigned. [VERIFIED: mix test] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVID-01 | Runtime summary shows semantic verdict/fallback/scope/reason with deep links | component + LiveView | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/workflow_live_test.exs` | ✅ existing files; assertions must expand. [VERIFIED: codebase grep] |
| EVID-01 | Workflow page renders deep semantic notebook with provenance and lifecycle details | LiveView | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/live/workflow_live_test.exs` | ✅ existing file; semantic notebook coverage missing. [VERIFIED: codebase grep] |
| PROOF-01 | Partitioning, bypass/fallback, reject/stale, and invalidation semantics stay correct | unit + integration | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs` | ✅ existing files. [VERIFIED: mix test] |
| PROOF-01 | Named semantic proof lane is discoverable and pinned to `:test` | unit | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs` | ❌ Wave 0 gap. [VERIFIED: codebase grep] |
| PROOF-01 | Milestone docs align to the new lane and support story | docs/source test | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` or new docs-source assertion file | ⚠ existing docs test seam; semantic-lane assertions missing. [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** run the smallest affected semantic/UI subset on the currently aligned DB port. [VERIFIED: mix test]
- **Per wave merge:** run the bounded semantic fast-path lane once the new Mix task exists. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
- **Phase gate:** semantic lane green, then broader `mix test` as release-confidence context. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]

### Wave 0 Gaps
- [ ] `lib/mix/tasks/scoria.test.semantic_fast_path.ex`
- [ ] `lib/mix/tasks/test.semantic_fast_path.ex`
- [ ] `test/mix/tasks/test.semantic_fast_path_test.exs`
- [ ] `test/scoria_web/live/workflow_live_test.exs` semantic notebook assertions for hit/miss/reject/stale provenance
- [ ] `test/scoria_web/components/runtime_detail_drawer_component_test.exs` semantic summary assertions
- [ ] Docs assertion updates for `mix test.semantic_fast_path` in the milestone/operator verification story

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 46 projects existing run/cache truth; it does not introduce auth flows. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Session handling is not the semantic evidence boundary for this milestone. [VERIFIED: .planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md] |
| V4 Access Control | yes | Preserve tenant/actor scope fields exactly as persisted and never widen actor-scoped evidence in the UI. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |
| V5 Input Validation | yes | Keep LiveViews render-only and rely on curated DTO fields rather than accepting arbitrary UI payloads for semantic classification. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No new cryptographic control is introduced in this phase. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant semantic evidence leakage | Information Disclosure | Use persisted `tenant_id`, `scope_kind`, and `actor_id` truth from the cache entry/runtime metadata; do not infer broader visibility in the UI. [VERIFIED: codebase grep] |
| Actor-scoped result shown as tenant-shared | Elevation of Privilege | Keep actor identity prominent only when `scope_kind == actor_scoped` and derive visibility from durable scope fields. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |
| Provenance spoofing through UI-only composition | Tampering | Build evidence from `RunDetail` plus persisted semantic entry/event rows rather than ad hoc client state. [VERIFIED: codebase grep] |
| Hidden fallback after semantic rejection | Repudiation | Render fallback as an explicit operator outcome with stable reason codes and verification coverage. [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Codebase inspection of `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_detail.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/semantic_cache.ex`, `lib/scoria/semantic_cache/entry.ex`, `lib/scoria/semantic_cache/entry_event.ex`, `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/components/runtime_detail_drawer_component.ex`, `lib/scoria_web/components/workflow_detail_panel_component.ex`, `lib/mix/tasks/test.adoption.ex`, and related tests. [VERIFIED: codebase grep]
- `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql`, `mix hex.info oban`. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info oban]
- `elixir --version`, `mix --version`, `pg_isready`, targeted `psql` extension checks, and targeted `mix test` runs. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: pg_isready] [VERIFIED: psql vector extension query] [VERIFIED: mix test]
- Official docs:
  - https://hexdocs.pm/phoenix/components.html
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
  - https://hexdocs.pm/mix/Mix.Project.html
  - https://hexdocs.pm/mix/Mix.Task.html
  - https://hexdocs.pm/mix/main/Mix.Tasks.Test.html

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified against Hex and matched the repo’s actual dependencies. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql]
- Architecture: HIGH - the recommendations align directly with existing runtime/workflow/component/task seams and locked user decisions. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/46-operator-evidence-and-verification/46-CONTEXT.md]
- Pitfalls: HIGH - they are derived from current code structure, current environment behavior, and the milestone’s locked UX/proof constraints. [VERIFIED: codebase grep] [VERIFIED: mix test]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24

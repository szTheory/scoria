# Phase 53: Operator evidence and lane guidance - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/components/delegated_evidence_component.ex` | component | request-response | `lib/scoria_web/components/delegated_evidence_component.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | component | request-response | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `README.md` | documentation | transform | `README.md` | exact |
| `docs/adoption_lanes.md` | documentation | transform | `docs/adoption_lanes.md` | exact |
| `docs/operator_verification.md` | documentation | transform | `docs/operator_verification.md` | exact |
| `docs/phoenix_runtime_example.md` | documentation | request-response | `docs/phoenix_runtime_example.md` | exact |
| `docs/bounded_handoffs.md` | documentation | request-response | `docs/bounded_handoffs.md` | exact |
| `test/scoria/adoption_surface_test.exs` | test | file-I/O | `test/scoria/adoption_surface_test.exs` | exact |
| `test/support/scoria/adoption_example.ex` | utility | transform | `test/support/scoria/adoption_example.ex` | exact |
| `test/scoria/phoenix_example_source_test.exs` | test | file-I/O | `test/scoria/phoenix_example_source_test.exs` | exact |
| `test/scoria/handoff_example_source_test.exs` | test | file-I/O | `test/scoria/handoff_example_source_test.exs` | exact |
| `test/scoria_web/live/workflow_live_test.exs` | test | request-response | `test/scoria_web/live/workflow_live_test.exs` | exact |
| `test/scoria/runtime_test.exs` | test | CRUD | `test/scoria/runtime_test.exs` | exact |

## Pattern Assignments

### `lib/scoria_web/components/delegated_evidence_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/components/delegated_evidence_component.ex`

**Imports and component contract pattern** (lines 1-6):

```elixir
defmodule ScoriaWeb.DelegatedEvidenceComponent do
  use Phoenix.Component

  attr :delegated_handoffs, :list, required: true

  def render(assigns) do
```

**Stable section anchor and curated-readback copy pattern** (lines 8-19):

```elixir
<section id="delegated-evidence" class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
  <div class="flex flex-col gap-3 border-b border-stone-200 pb-4 md:flex-row md:items-start md:justify-between">
    <div>
      <p class="text-xs uppercase tracking-[0.22em] text-stone-500">Delegated Evidence</p>
      <h2 class="mt-1 text-lg font-semibold text-stone-900">Delegated handoff inspection</h2>
      <p class="mt-1 max-w-3xl text-sm text-stone-600">
        Review bounded delegated lineage from the curated runtime detail instead of reconstructing it from raw workflow rows.
      </p>
    </div>
    <a href="#delegated-evidence" class="inline-flex items-center gap-2 text-sm font-medium text-blue-700 underline">
      Inspect Delegated Evidence
```

**Empty state pattern** (lines 22-29):

```elixir
<div :if={@delegated_handoffs == []} class="mt-4 rounded-2xl border border-dashed border-stone-300 bg-stone-50 p-5">
  <p class="text-xs font-semibold uppercase tracking-[0.18em] text-stone-500">No Delegated Handoffs Recorded</p>
  <p class="mt-2 text-sm text-stone-600">
    This run has no bounded delegated handoff yet. Start with the normal runtime flow, or inspect the workflow tree after
    <span class="font-mono text-stone-900">Scoria.start_handoff_run/3</span>
    records a handoff and child step under the same run.
  </p>
</div>
```

**Lineage/status/context evidence pattern** (lines 51-83):

```elixir
<dl class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-4">
  <div class="rounded-xl border border-stone-200 bg-white p-3">
    <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Lineage</dt>
    <dd class="mt-2 text-sm text-stone-700">
      parent step <span class="font-mono text-stone-900"><%= delegated.parent_step_id %></span>
      <br />
      child step <span class="font-mono text-stone-900"><%= delegated.child_step_id || "pending" %></span>
    </dd>
  </div>

  <div class="rounded-xl border border-stone-200 bg-white p-3">
    <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Execution</dt>
    <dd class="mt-2 text-sm text-stone-700">
      child status <span class="font-medium text-stone-900"><%= delegated_status_label(delegated.child_status) %></span>
      <%= if delegated.child_status == "child_step_pending" do %>
        <p class="mt-2 text-xs text-stone-500">The handoff is recorded, but delegated execution has not produced a child-step readback yet.</p>
      <% end %>
    </dd>
  </div>

  <div class="rounded-xl border border-stone-200 bg-white p-3 md:col-span-2">
    <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Projected Context Preview</dt>
```

**Full context and helper pattern** (lines 85-151):

```elixir
<details class="rounded-xl border border-stone-200 bg-white p-3">
  <summary class="cursor-pointer text-sm font-medium text-stone-900">View full context</summary>
  <div class="mt-3 grid gap-3 lg:grid-cols-2">
    <div>
      <p class="text-xs uppercase tracking-[0.16em] text-stone-500">handoff input</p>
      <div class="mt-2 space-y-2">
        <div :for={{key, value} <- sorted_pairs(delegated.handoff_input)} class="flex items-start justify-between gap-4 text-sm">
```

```elixir
defp preview_context(delegated) do
  delegated.projected_context
  |> sorted_pairs()
  |> Enum.take(3)
end

defp delegated_status_label("child_step_pending"), do: "child step pending"
defp delegated_status_label(value) when is_binary(value), do: value
defp delegated_status_label(_value), do: "unknown"

defp badge_class("completed"), do: "bg-emerald-100 text-emerald-700"
defp badge_class("running"), do: "bg-sky-100 text-sky-700"
defp badge_class("waiting_for_approval"), do: "bg-amber-100 text-amber-800"
defp badge_class("failed"), do: "bg-rose-100 text-rose-800"
defp badge_class("child_step_pending"), do: "bg-stone-200 text-stone-700"
```

Planner notes:

- Keep the single `#delegated-evidence` anchor; Phase 53 should tighten copy and visibility, not add a second operator surface.
- Preserve explicit empty, pending, and populated states.
- Keep evidence dimensions together: same-run lineage, projected context, handoff input, and delegated status/outcome.

---

### `lib/scoria_web/live/workflow_live/show.ex` (component, request-response)

**Analog:** `lib/scoria_web/live/workflow_live/show.ex`

**Imports pattern** (lines 1-14):

```elixir
defmodule ScoriaWeb.WorkflowLive.Show do
  use Phoenix.LiveView

  alias Scoria.Eval
  alias Scoria.Runtime
  alias Scoria.SRE
  alias Scoria.Workflows
  alias ScoriaWeb.{
    DelegatedEvidenceComponent,
    MemoryNotebookComponent,
    RemoteInvocationEvidenceComponent,
    WorkflowDetailPanelComponent
  }
  alias ScoriaWeb.WorkflowTreeComponent
```

**Mount and subscription pattern** (lines 18-35):

```elixir
@impl true
def mount(%{"id" => run_id} = params, _session, socket) do
  review_candidate_id = Map.get(params, "review_candidate_id")

  if connected?(socket) do
    Workflows.subscribe_run(run_id)
  end

  socket =
    socket
    |> load_run(run_id)
    |> assign(:review_candidate, load_review_candidate(run_id, review_candidate_id))
```

**Component integration pattern** (lines 189-209):

```elixir
<div class="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]">
  <section class="rounded-2xl border border-stone-200 bg-white shadow-sm">
    <div class="border-b border-stone-200 px-4 py-3">
      <h2 class="text-lg font-semibold">Trace-First Workflow Tree</h2>
    </div>
    <WorkflowTreeComponent.workflow_tree steps={@steps} selected_step_id={@selected_step_id} />
  </section>

  <WorkflowDetailPanelComponent.workflow_detail_panel
    step={@selected_step}
    checkpoint={@selected_checkpoint}
    comparison={@selected_comparison}
    semantic_evidence={@run_detail.semantic_evidence}
    selected_source_variant={@selected_source_variant}
    selected_comparison_entry={@selected_comparison_entry}
    promotion_context={@promotion_context}
  />
</div>

<DelegatedEvidenceComponent.render delegated_handoffs={@delegated_handoffs} />
```

**Curated DTO assignment pattern** (lines 258-280):

```elixir
defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  detail = Runtime.get_run_detail!(run_id)
  steps = decorate_steps(detail.steps)
  selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)
  selected_source_variant = default_source_variant(run, socket.assigns[:selected_source_variant])

  socket
  |> assign(:page_title, "Workflow Run")
  |> assign(:run, run)
  |> assign(:run_detail, detail)
  |> assign(:steps, steps)
  |> assign(:events, run.events)
  |> assign(:comparison_by_step, detail.comparison_by_step)
  |> assign(:replay_provenance_strip, detail.replay_provenance_strip)
  |> assign(:delegated_handoffs, detail.delegated_handoffs)
```

Planner notes:

- Use `Runtime.get_run_detail!/1` as the operator evidence source.
- Do not introduce raw `Workflows` table reconstruction for delegated evidence.
- If layout moves, keep `DelegatedEvidenceComponent` on `/scoria/workflows/:run_id`.

---

### `lib/scoria/runtime/run_detail.ex` (model, transform)

**Analog:** `lib/scoria/runtime/run_detail.ex`

**Imports and DTO field pattern** (lines 1-20):

```elixir
defmodule Scoria.Runtime.RunDetail do
  @moduledoc """
  Curated public detail DTO for advanced run inspection.
  """

  alias Scoria.Observe.Approval
  alias Scoria.Runtime.RunSummary
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  @enforce_keys [
    :summary,
    :steps,
    :checkpoints,
    :events,
    :approvals,
    :handoffs,
    :delegated_handoffs,
```

**DTO construction pattern** (lines 49-65):

```elixir
def from_run_tree(%Run{} = run, opts \\ []) do
  steps = Enum.map(run.steps, &step_item/1)
  handoffs = Enum.map(run.handoffs, &handoff_item/1)

  %__MODULE__{
    summary: RunSummary.from_run(run),
    steps: steps,
    checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
    events: Enum.map(run.events, &event_item/1),
    approvals: Enum.map(run.approvals, &approval_item/1),
    handoffs: handoffs,
    delegated_handoffs: delegated_handoff_items(steps, handoffs),
```

**Delegated projection pattern** (lines 161-201):

```elixir
defp delegated_handoff_items(steps, handoffs) do
  steps_by_parent =
    Enum.group_by(steps, & &1.parent_step_id)

  steps_by_id = Map.new(steps, &{&1.id, &1})

  handoffs
  |> Enum.map(fn handoff ->
    parent_step = Map.get(steps_by_id, handoff.step_id)

    child_step =
      steps_by_parent
      |> Map.get(handoff.step_id, [])
      |> Enum.filter(&delegated_child_step?(&1, handoff))
      |> Enum.sort_by(&{&1.sequence || 0, Map.get(&1, :inserted_at) || ~U[1970-01-01 00:00:00Z]})
      |> List.first()

    %{
      id: handoff.id,
      handoff_id: handoff.id,
      parent_step_id: handoff.step_id,
      parent_step_sequence: parent_step && parent_step.sequence,
      parent_step_kind: parent_step && parent_step.kind,
      parent_role_id: parent_step && parent_step.role_id,
      delegated_role_id: handoff.delegated_role_id,
      delegated_kind: handoff.delegated_kind,
      handoff_input: handoff.handoff_input,
      capability_tags: handoff.capability_tags,
      child_step_id: child_step && child_step.id,
      child_step_sequence: child_step && child_step.sequence,
      child_step_kind: child_step && child_step.kind,
      child_role_id: child_step && child_step.role_id,
      child_status: child_step_status(child_step),
      status: child_step_status(child_step),
      projected_context: child_projected_context(child_step),
      sequence: delegated_sequence(parent_step, child_step),
      inserted_at: handoff.inserted_at
    }
  end)
  |> Enum.sort_by(&{&1.sequence || 0, Map.get(&1, :inserted_at) || ~U[1970-01-01 00:00:00Z]})
end
```

**Pending state pattern** (lines 203-211):

```elixir
defp delegated_child_step?(step, handoff) do
  step.role_id == handoff.delegated_role_id and step.kind == handoff.delegated_kind
end

defp child_step_status(nil), do: "child_step_pending"
defp child_step_status(child_step), do: child_step.status

defp child_projected_context(nil), do: %{}
defp child_projected_context(child_step), do: child_step.projected_context || %{}
```

Planner notes:

- Only change this if the UI needs a missing curated field; prefer existing keys first.
- Preserve `"child_step_pending"` as the explicit pending child-readback state.

---

### `README.md` (documentation, transform)

**Analog:** `README.md`

**Lane hierarchy pattern** (lines 8-18):

```markdown
Scoria is the Phoenix-native runtime and operator surface for identity-aware AI runs. It gives a host app one public place to normalize actor, tenant, and session identity, start durable runs, resume an exact paused run by `run_id`, and inspect operator evidence at `/scoria` without turning the dashboard into the app's source of business truth.

Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`. The current public shape is intentionally narrow:

- a default runtime lane for durable Phoenix-hosted runs
- a bounded handoff lane for narrow same-run delegation
- a semantic fast path for explicitly safe read-only work
- an optional knowledge lane for pgvector-backed retrieval and grounding

If you are adopting Scoria for the first time, start with the default runtime lane and treat the others as layered additions.
```

**Choose Your Lane pattern** (lines 25-40):

```markdown
## Choose Your Lane

Use the narrowest lane that solves your current app problem:

- **Default runtime lane**: start here for identity-aware durable runs, approvals, and operator evidence.
- **Bounded handoff lane**: add this when one role needs to delegate a narrow slice of work to another role under the same durable run.
- **Semantic fast-path lane**: add this when you want tenant-partitioned answer reuse for explicitly safe read-only work.
- **Optional knowledge lane**: add this only when you are intentionally validating retrieval, citations, and grounding.

Docs:

- [Lane selection guide](docs/adoption_lanes.md)
- [Phoenix runtime example](docs/phoenix_runtime_example.md)
- [Bounded handoffs](docs/bounded_handoffs.md)
- [Semantic fast path](docs/semantic_fast_path.md)
- [Operator verification](docs/operator_verification.md)
```

**Bounded handoff readback pattern** (lines 122-140):

```markdown
## Bounded Handoffs

When the runtime-first lane is already in place and one role needs to delegate a narrow slice of work to another role, branch to the public handoff lane:

```elixir
{:ok, started} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer"},
    projected_context: %{"task" => "policy review", "draft_answer" => draft_answer},
    handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
  )

{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

That records delegated lineage under one durable run and publishes one curated delegated evidence projection through `Scoria.get_run_detail/1`. The same run also exposes a `Delegated Evidence` section at `/scoria/workflows/:run_id`.
```

**Verification wording pattern** (lines 163-184):

```markdown
## Verification

Default Phoenix lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Then inspect `/scoria` and `/scoria/workflows/:run_id` for operator evidence from one real run in your app. Read it back through `Scoria.get_run/1` or `Scoria.list_runs_for_session/1`.

`mix test.adoption` is the canonical bounded verifier for the default lane.

The knowledge lane does not define first adoption. You do not need pgvector, knowledge tables, retrieval, grounding, semantic fast-path setup, or `mix test.knowledge` to prove the core runtime, identity, approval, and operator-evidence path.
```

Planner notes:

- Phase 53 should update version/lane wording if needed, but must keep default runtime first.
- Do not add a placeholder runtime-to-handoff proof command; Phase 54 owns it.

---

### `docs/adoption_lanes.md` (documentation, transform)

**Analog:** `docs/adoption_lanes.md`

**Default lane pattern** (lines 9-43):

```markdown
### 1. Default runtime lane

Use this first.

Choose it when you need:

- canonical actor, tenant, and session identity
- durable runs with exact `run_id` resume
- approval pauses and operator evidence
- one public facade for `identity -> start -> inspect -> resume`

Proof lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

If you are not sure where to start, start here.

This default lane is the first-adoption proof. You do not need pgvector, retrieval, grounding, semantic-fast-path setup, or knowledge verification before this lane is valid.
```

**Bounded handoff escalation pattern** (lines 45-67):

```markdown
### 2. Bounded handoff lane

Add this only after the default runtime lane is already working.

Choose it when:

- one role needs to delegate a narrow slice of work to another role
- the delegated role should stay under the same durable run
- projected context must stay least-privilege and inspectable

Core API:

- `Scoria.start_handoff_run/3`

Key rule:

- projected context stays narrow and host-controlled
- broad runtime-state keys such as `transcript`, `messages`, `provider_session`, `session`, and `secrets` are rejected explicitly

Use this for review, critique, classification, or bounded specialist work. Do not use it to build a broad autonomous multi-agent platform by default.

Validate the base runtime lane with `mix test.adoption` before you intentionally expand into `Scoria.start_handoff_run/3`.
```

**Adoption order pattern** (lines 119-138):

```markdown
## A Good Default Order

Adopt Scoria in this order:

1. `identity -> start -> inspect -> resume`
2. bounded handoffs if one role truly needs delegation
3. semantic fast path if safe read-only reuse is worth it
4. optional knowledge lane if retrieval and grounding are part of your product

## What You Do Not Need To Adopt First

You do not need:

- pgvector
- broad multi-agent orchestration
- a hosted control plane
- external semantic cache backends
- advanced ANN tuning

Start narrow. Expand only when the current lane already feels boring.
```

Planner notes:

- Use direct modal phrasing: "Use this first", "Add this only after", "You do not need".
- For Phase 53, add operator-visible delegated lineage and projected-context trigger wording here if docs need stronger DOCS-01 coverage.

---

### `docs/operator_verification.md` (documentation, transform)

**Analog:** `docs/operator_verification.md`

**Core success pattern** (lines 1-15):

```markdown
# Operator Verification

This guide is the default Phoenix verification lane for Scoria's public runtime surface. The goal is simple: prove the core install, runtime, and operator-evidence path before you touch the optional knowledge lane.

## What core success means

You have proven the default lane when all of these are true:

- `mix scoria.install` has wired the dashboard, copied core migrations, and set baseline runtime defaults
- `mix ecto.migrate` and `mix test.adoption` pass for the host app
- one real run starts through `Scoria.start_run/2`
- that same run can be read back through `Scoria.get_run/1` or found via `list_runs_for_session/1`
- `/scoria/workflows/:run_id` shows operator evidence for that exact run

You do not need pgvector, knowledge tables, retrieval, grounding, semantic-fast-path setup, or `mix test.knowledge` to prove the core lane.
```

**Default verifier pattern** (lines 17-35):

```markdown
## Step 1: Install preflight

Run the installer and the boring baseline commands first:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

What this proves:

- the dashboard routes mount at `/scoria`
- the Scoria-owned core tables are available through copied host-app migrations
- baseline runtime defaults are present
- the app passes the bounded default-lane adoption verifier

Use `mix test.adoption` as the canonical default-lane verifier when you want one bounded proof that covers installer truth, the fresh-host install/migrate/route/runtime smoke, and the repo-local adoption guards without waiting for the whole suite.
```

**Operator evidence pattern** (lines 100-110):

```markdown
## Step 4: Open operator evidence

Open the operator pages for the installed dashboard:

```text
/scoria
/scoria/workflows/:run_id
```

The second page should show the same durable run you started from the host app. This is operator evidence for the run, not the system of record for your domain model.
```

**Closeout proof boundary pattern** (lines 146-166):

```markdown
Keep it distinct from the other named lanes:

- `mix test.adoption` proves the canonical default runtime adoption boundary
- `mix test.semantic_fast_path` proves the bounded semantic troubleshooting lane
- `mix test.knowledge` proves the optional knowledge lane

## Maintainer closeout

For repository closeout, the canonical proof chain is exactly:

```bash
mix scoria.release_preview
mix test.adoption
```

Use `mix test.semantic_fast_path` only for the canonical `v2.1` semantic fast-path troubleshooting lane.
Use `mix test.knowledge` only when you are intentionally validating the optional knowledge lane.
```

Planner notes:

- Add bounded handoff decision guidance here only as optional escalation after the default lane.
- Do not publish the Phase 54 runtime-to-handoff proof command in this file.

---

### `docs/phoenix_runtime_example.md` (documentation, request-response)

**Analog:** `docs/phoenix_runtime_example.md`

**Opening contract pattern** (lines 1-15):

```markdown
# Phoenix Runtime Example

This is the canonical Phoenix-hosted Scoria flow for the Keystone public runtime surface. It is derived from the existing runtime integration behavior in `test/scoria/runtime_integration_test.exs`, not from a separate sample app or a speculative architecture.

Keep the canonical adoption order boring: `identity -> start -> inspect -> resume`.

## What this guide shows

- normalize request and session context with `Scoria.identity/1`
- start a run through `Scoria.start_run/2`
- persist `run_id` as the exact durable handle for one run
- reuse `session_id` for continuity across turns
- inspect progress with `Scoria.get_run/1` and `Scoria.list_runs_for_session/1`
- link `/scoria/workflows/:run_id` as operator evidence for that same run
- resume a paused approval flow through `Scoria.resume_run/2`
```

**Handoff branch pattern** (lines 113-164):

```elixir
If the core runtime path is already working and a draft needs a bounded review, branch from the same identity and `run_id` model instead of starting a second onboarding path.

The host app owns this escalation decision. Scoria only receives the explicit handoff contract you pass to `Scoria.start_handoff_run/3`.

def create(conn, %{"draft_answer" => draft_answer}) do
  identity =
    Scoria.identity(%{
      actor_id: conn.assigns.current_user.id,
      tenant_id: conn.assigns.current_account.id,
      session_id: get_session(conn, :assistant_session_id),
      metadata: %{"channel" => "web"}
    })

  {:ok, started} = Scoria.start_run(identity, root_role_id: "executor")

  if needs_bounded_review?(draft_answer) do
    {:ok, handoff_run} =
      Scoria.start_handoff_run(identity, "critic",
        root_role_id: "planner",
        delegated_kind: "review",
        handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
        projected_context: %{
          "task" => "policy-and-accuracy review",
          "draft_answer" => draft_answer
        },
        handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
      )

    {:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)
    delegated = detail.delegated_handoffs

    started.run_id != handoff_run.run_id
```

Planner notes:

- Keep `session_id` versus `run_id` explicit.
- Keep examples on the top-level `Scoria` facade.
- Ensure fragments added here are also pinned in `Scoria.TestSupport.AdoptionExample.doc_fragments/0`.

---

### `docs/bounded_handoffs.md` (documentation, request-response)

**Analog:** `docs/bounded_handoffs.md`

**Default-first lane boundary pattern** (lines 1-5):

```markdown
# Bounded Handoffs

This guide documents the narrow public delegation lane for Scoria. Use it when your Phoenix app needs one role to hand a bounded slice of work to another role without turning Scoria into a general-purpose agent platform.

Start with the normal runtime lane first: `identity -> start -> inspect -> resume`. Validate that base lane with `mix test.adoption`, then add bounded handoffs only when you intentionally need same-run delegation.
```

**Ownership boundary pattern** (lines 17-31):

```markdown
## Host and Scoria ownership boundary

The host app owns identity, escalation policy, prompt or draft selection, and projected-context selection.
Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.
Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.

Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`: the root role that is delegating
- the delegated role argument: the role that should own the child step
- `delegated_kind`: the child step kind that host handlers should execute
- `handoff_input`: the exact host-supplied work brief Scoria should persist
- `projected_context`: the exact projected context slice that is safe to pass down

The host app passes these fields explicitly. Scoria does not fill in hidden handoff defaults for you.
```

**Safety and validation pattern** (lines 67-96):

```markdown
## Safety rule: projected context must stay narrow

Projected context is for the bounded slice only. Do not pass broad runtime state through the public handoff lane.

Broad runtime-state keys are rejected explicitly, including:

- `transcript`
- `messages`
- `history`
- `provider_session`
- `session`
- `headers`
- `secrets`
- `socket_state`

Narrow host-controlled slices such as `%{"task" => "review"}` and `projected_context: %{}` remain valid.

Rejected projected context returns a runtime error before Scoria creates the delegated run:

```elixir
assert {:error, :unsafe_projected_context} =
         Scoria.start_handoff_run(identity, "critic",
           root_role_id: "planner",
           delegated_kind: "review",
           handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
           projected_context: %{"request_headers" => %{"authorization" => "secret"}}
         )
```
```

**Curated readback pattern** (lines 98-115):

```markdown
## Inspecting delegated lineage

After `Scoria.start_handoff_run/3`:

```elixir
{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

`detail.delegated_handoffs` exposes the delegated role, delegated kind, handoff input, bounded projected context, and the parent/child same-run lineage needed to inspect the bounded lane without reading raw workflow tables.

Open:

```text
/scoria/workflows/:run_id
```
```

Planner notes:

- Strongest DOCS-01 wording likely belongs here and in `docs/adoption_lanes.md`.
- Preserve the raw-internals prohibition; tests already refute raw workflow names.

---

### `test/scoria/adoption_surface_test.exs` (test, file-I/O)

**Analog:** `test/scoria/adoption_surface_test.exs`

**Imports and file constants pattern** (lines 1-12):

```elixir
defmodule Scoria.AdoptionSurfaceTest do
  use ExUnit.Case, async: true

  @readme "README.md"
  @lane_guide "docs/adoption_lanes.md"
  @phoenix_example "docs/phoenix_runtime_example.md"
  @handoff_guide "docs/bounded_handoffs.md"
  @gap_ledger "docs/bounded_handoffs.md"
  @semantic_guide "docs/semantic_fast_path.md"
  @operator_guide "docs/operator_verification.md"
```

**README docs invariant pattern** (lines 14-48):

```elixir
test "README documents the shipped lane model and canonical lane hierarchy" do
  content = File.read!(@readme)

  assert content =~ "Who This Is For"
  assert content =~ "Choose Your Lane"
  assert content =~ "Lane selection guide"
  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.start_run"
  assert content =~ "Scoria.start_handoff_run"
  assert content =~ "Scoria.get_run_detail"
  assert content =~ "delegated_handoffs"
  assert content =~ "mix test.adoption"
  assert content =~ "Optional knowledge lane"
  refute content =~ "mix scoria.test.knowledge"
end
```

**Lane guide invariant pattern** (lines 50-66):

```elixir
test "lane selection guide documents the adoption order and optional boundaries" do
  content = File.read!(@lane_guide)

  assert content =~ "Default runtime lane"
  assert content =~ "Bounded handoff lane"
  assert content =~ "Semantic fast-path lane"
  assert content =~ "Optional knowledge lane"
  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.start_handoff_run/3"
  assert content =~ "mix test.adoption"
  assert content =~ "This lane is explicitly optional."
  assert content =~ "Start narrow. Expand only when the current lane already feels boring."
end
```

**Bounded handoff public-contract invariant pattern** (lines 68-111):

```elixir
test "bounded handoff guide documents the narrow public delegation lane" do
  content = File.read!(@handoff_guide)

  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.start_handoff_run"
  assert content =~ "Scoria.get_run_detail"
  assert content =~ "delegated_handoffs"
  assert content =~ "projected_context"
  assert content =~ "queued child step"
  assert content =~ "same durable run"
  assert content =~ "Delegated Evidence"
  assert content =~ "Host and Scoria ownership boundary"
  assert content =~ "{:error, :unsafe_projected_context}"
  assert content =~ "/scoria/workflows/:run_id"
  refute content =~ "implicit payload projection"
  refute content =~ "Scoria.Workflows.create_run"
  refute content =~ "Repo.all"
  refute content =~ "workflow_steps"
  refute content =~ "workflow_handoffs"
end
```

**Operator verification proof-boundary pattern** (lines 168-223):

```elixir
test "operator verification guide documents the four-tier support hierarchy" do
  content = File.read!(@operator_guide)

  assert content =~ "mix scoria.release_preview"
  assert content =~ "mix test.adoption"
  assert content =~ "mix test.semantic_fast_path"
  assert content =~ "mix test.knowledge"
  assert content =~ "canonical default-lane verifier"
  assert content =~ "/scoria/workflows/:run_id"
  assert content =~ "mix scoria.release_preview\nmix test.adoption"
  refute content =~ "MIX_ENV=test mix scoria.release_preview"
  refute content =~ "mix scoria.test.knowledge"
  refute content =~ "pgvector, retrieval, or semantic caching before Scoria is usable"
end
```

Planner notes:

- Add Phase 53 docs invariants here for default-first, evidence-triggered handoff escalation, no first-adoption handoff requirement, v2.2 lane hierarchy, and public facade over raw internals.
- Keep assertions string-based and lightweight; do not add snapshots or rendered Markdown tooling.

---

### `test/support/scoria/adoption_example.ex` (utility, transform)

**Analog:** `test/support/scoria/adoption_example.ex`

**Shared constants and route helper pattern** (lines 1-21):

```elixir
defmodule Scoria.TestSupport.AdoptionExample do
  @moduledoc false

  @shared_session_id "shared-session"
  @waiting_status "waiting_for_approval"
  @completed_status "completed"

  def runtime_identity do
    %{
      actor_id: "public-actor",
      tenant_id: "public-tenant",
      session_id: @shared_session_id
    }
  end

  def operator_route(run_id), do: "/scoria/workflows/#{run_id}"
  def operator_route_pattern, do: "/scoria/workflows/:run_id"
```

**Phoenix source fragment pattern** (lines 23-48):

```elixir
def doc_fragments do
  [
    "actor_id: conn.assigns.current_user.id",
    "tenant_id: conn.assigns.current_account.id",
    "session_id: get_session(conn, :assistant_session_id)",
    "metadata: %{\"channel\" => \"web\"}",
    "{:ok, summary} = Scoria.get_run(run_id)",
    "same_session_runs = Scoria.list_runs_for_session(session_id)",
    "Scoria.resume_run(run_id,",
    "Scoria.start_run",
    "defp needs_bounded_review?(draft_answer) do",
    "Scoria.get_run_detail(handoff_run.run_id)",
    "started.run_id != handoff_run.run_id",
    "session_id groups related host turns; run_id names one exact Scoria execution.",
    "identity -> start -> inspect -> resume",
    "list_runs_for_session"
  ]
end
```

**Handoff source fragment pattern** (lines 50-79):

```elixir
def handoff_doc_fragments do
  [
    "Scoria.start_handoff_run(identity, \"critic\"",
    "Scoria.get_run_detail(started.run_id)",
    "delegated = detail.delegated_handoffs",
    "Host and Scoria ownership boundary",
    "The host app owns identity, escalation policy, prompt or draft selection, and projected-context selection.",
    "Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.",
    "Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.",
    "root_role_id: \"planner\"",
    "delegated_kind: \"review\"",
    "handoff_input: %{\"brief\" => \"Review the draft answer for policy and accuracy\"}",
    "projected_context: %{}",
    "{:error, :unsafe_projected_context}",
    "same durable run",
    "Delegated Evidence",
    "Broad runtime-state keys are rejected explicitly",
    "/scoria/workflows/:run_id"
  ]
end
```

Planner notes:

- Pin any new example fragments that must stay synchronized between source docs and support truth.
- Keep this as literal fragment lists; do not make it a rendered-doc parser.

---

### `test/scoria/phoenix_example_source_test.exs` (test, file-I/O)

**Analog:** `test/scoria/phoenix_example_source_test.exs`

**Shared fragment assertion pattern** (lines 1-15):

```elixir
defmodule Scoria.PhoenixExampleSourceTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.AdoptionExample

  @phoenix_example "docs/phoenix_runtime_example.md"

  test "Phoenix guide stays aligned with the checked adoption example source" do
    content = File.read!(@phoenix_example)

    for fragment <- AdoptionExample.doc_fragments() do
      assert content =~ fragment
    end
  end
end
```

Planner notes:

- Add or adjust `AdoptionExample.doc_fragments/0` rather than duplicating fragment lists in this test.

---

### `test/scoria/handoff_example_source_test.exs` (test, file-I/O)

**Analog:** `test/scoria/handoff_example_source_test.exs`

**Shared fragment assertion pattern** (lines 1-15):

```elixir
defmodule Scoria.HandoffExampleSourceTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.AdoptionExample

  @handoff_guide "docs/bounded_handoffs.md"

  test "bounded handoff guide stays aligned with the checked adoption fragments" do
    content = File.read!(@handoff_guide)

    for fragment <- AdoptionExample.handoff_doc_fragments() do
      assert content =~ fragment
    end
  end
end
```

Planner notes:

- This is the right pin for bounded handoff source fragments such as `Scoria.get_run_detail/1`, `delegated_handoffs`, ownership boundary, and projected context safety.

---

### `test/scoria_web/live/workflow_live_test.exs` (test, request-response)

**Analog:** `test/scoria_web/live/workflow_live_test.exs`

**LiveView test endpoint pattern** (lines 1-40):

```elixir
defmodule ScoriaWeb.WorkflowLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.WorkflowLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_workflow_key",
    signing_salt: "workflow_salt"
  )

  plug(ScoriaWeb.WorkflowLiveTest.Router)
end

defmodule ScoriaWeb.WorkflowLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
```

**DB sandbox setup pattern** (lines 42-58):

```elixir
setup_all do
  Application.put_env(:scoria, ScoriaWeb.WorkflowLiveTest.Endpoint,
    secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
    pubsub_server: Scoria.PubSub,
    live_view: [signing_salt: "87654321"],
    debug_errors: true
  )

  :ok
end

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  start_supervised!(ScoriaWeb.WorkflowLiveTest.Endpoint)
  :ok
end
```

**Delegated populated evidence test pattern** (lines 130-186):

```elixir
test "workflow page renders delegated evidence from the curated runtime DTO and keeps step selection on the right rail" do
  {:ok, run} = Workflows.create_run(%{root_role_id: "planner"})

  {:ok, parent_step} =
    Workflows.create_step(run.id, %{
      sequence: 1,
      kind: "handoff",
      role_id: "planner",
      status: "completed"
    })

  {:ok, _handoff} =
    Workflows.create_handoff(parent_step, %{
      delegated_role_id: "critic",
      delegated_kind: "review",
      capability_tags: ["policy"],
      handoff_input: %{"brief" => "Review the draft answer"},
      status: "pending"
    })

  {:ok, child_step} =
    Workflows.create_step(run.id, %{
      parent_step_id: parent_step.id,
      sequence: 2,
      kind: "review",
      role_id: "critic",
      status: "running",
      projected_context: %{"draft_answer" => "hello", "task" => "policy review", "tone" => "calm"}
    })

  {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

  assert html =~ "Delegated Evidence"
  assert html =~ "Inspect Delegated Evidence"
  assert html =~ "planner"
  assert html =~ "critic"
  assert html =~ "View full context"
  assert html =~ "handoff input"
  assert html =~ "projected context"
  assert html =~ "policy"
  assert html =~ "draft_answer"

  selected_html =
    view
    |> element("button[phx-click='select_step'][phx-value-id='#{child_step.id}']")
    |> render_click()
```

**Empty and pending state test pattern** (lines 188-224):

```elixir
test "workflow page renders delegated empty and pending states without altering the rest of the page" do
  {:ok, empty_run} = Workflows.create_run(%{root_role_id: "executor"})

  {:ok, pending_run} = Workflows.create_run(%{root_role_id: "planner"})

  {:ok, parent_step} =
    Workflows.create_step(pending_run.id, %{
      sequence: 1,
      kind: "handoff",
      role_id: "planner",
      status: "completed"
    })

  {:ok, _handoff} =
    Workflows.create_handoff(parent_step, %{
      delegated_role_id: "critic",
      delegated_kind: "review",
      handoff_input: %{"brief" => "Review the draft answer"},
      status: "pending"
    })

  {:ok, _empty_view, empty_html} = live(conn, "/scoria/workflows/#{empty_run.id}")
  {:ok, _pending_view, pending_html} = live(conn, "/scoria/workflows/#{pending_run.id}")

  assert empty_html =~ "No Delegated Handoffs Recorded"
  assert empty_html =~ "Scoria.start_handoff_run/3"
  assert empty_html =~ "Timeline"

  assert pending_html =~ "child step pending"
  assert pending_html =~ "The handoff is recorded, but delegated execution has not produced a child-step readback yet."
  assert pending_html =~ "Trace-First Workflow Tree"
end
```

Planner notes:

- Add assertions for the three Phase 53 evidence dimensions in this file: same-run lineage, projected-context summary, delegated outcome/status.
- Keep the current LiveViewTest approach; no browser or snapshot tooling needed.

---

### `test/scoria/runtime_test.exs` (test, CRUD)

**Analog:** `test/scoria/runtime_test.exs`

This file is not listed as a primary Phase 53 edit target, but it is the closest backend DTO drift analog if `RunDetail` changes.

**Setup pattern** (lines 1-13):

```elixir
defmodule Scoria.RuntimeTest do
  use ExUnit.Case, async: false

  alias Scoria.Runtime
  alias Scoria.Runtime.{RunDetail, RunSummary}
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end
```

**Delegated DTO populated projection pattern** (lines 25-69):

```elixir
test "start_handoff_run creates bounded delegated lineage with a queued child step" do
  assert {:ok, summary} =
           Runtime.start_handoff_run(
             %{
               actor_id: "actor-handoff",
               tenant_id: "tenant-handoff",
               session_id: "session-handoff"
             },
             "critic",
             root_role_id: "planner",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             projected_context: %{"task" => "review", "draft_answer" => "hello"}
           )

  detail = Runtime.get_run_detail!(summary.run_id)

  assert [
           %{
             delegated_role_id: "critic",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             child_status: "queued",
             status: "queued",
             projected_context: %{"task" => "review", "draft_answer" => "hello"}
           }
         ] = detail.delegated_handoffs
end
```

**Empty and pending DTO projection pattern** (lines 71-167):

```elixir
test "get_run_detail returns an empty delegated collection for non-handoff runs" do
  {:ok, summary} =
    Runtime.start_run(
      %{actor_id: "actor-empty-delegated", tenant_id: "tenant-empty-delegated", session_id: "session-empty-delegated"},
      root_role_id: "executor"
    )

  detail = Runtime.get_run_detail!(summary.run_id)

  assert detail.delegated_handoffs == []
  assert detail.handoffs == []
end

test "delegated projection keeps sequence order and reports pending child lineage explicitly" do
  detail = Runtime.get_run_detail!(run.id)

  assert [
           %{
             child_step_id: nil,
             child_status: "child_step_pending",
             status: "child_step_pending",
             capability_tags: ["policy"],
             projected_context: %{},
             sequence: 1
           },
           %{
             child_status: "completed",
             status: "completed",
             capability_tags: ["copy"],
             projected_context: %{"task" => "draft", "tone" => "calm"},
             sequence: 2
           }
         ] = detail.delegated_handoffs
end
```

Planner notes:

- Use this only if DTO shape or behavior changes; UI-only copy changes should stay in LiveView tests.

## Shared Patterns

### Public Facade Boundary

**Source:** `lib/scoria.ex` lines 33-79
**Apply to:** Documentation and tests that mention adopter APIs

```elixir
alias Scoria.Runtime

def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)
def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)
def start_handoff_run(identity, delegated_role_id, opts \\ []),
  do: Runtime.start_handoff_run(identity, delegated_role_id, opts)
def resume_run(run_id, opts \\ []), do: Runtime.resume_run(run_id, opts)
def get_run(run_id), do: Runtime.get_run(run_id)
def get_run_detail(run_id), do: Runtime.get_run_detail(run_id)
def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
```

Phase 53 docs should stay on the `Scoria` facade and curated readback. Do not direct adopters to `Scoria.Workflows`, `Repo.all`, `workflow_steps`, or `workflow_handoffs`.

### Curated Evidence Flow

**Source:** `lib/scoria_web/live/workflow_live/show.ex` lines 258-274 and `lib/scoria/runtime/run_detail.ex` lines 49-65
**Apply to:** Operator evidence UI and DTO tests

```elixir
detail = Runtime.get_run_detail!(run_id)

socket
|> assign(:run_detail, detail)
|> assign(:delegated_handoffs, detail.delegated_handoffs)
```

```elixir
%__MODULE__{
  summary: RunSummary.from_run(run),
  steps: steps,
  handoffs: handoffs,
  delegated_handoffs: delegated_handoff_items(steps, handoffs)
}
```

### LiveView Evidence Testing

**Source:** `test/scoria_web/live/workflow_live_test.exs` lines 130-224
**Apply to:** Delegated evidence operator assertions

```elixir
{:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

assert html =~ "Delegated Evidence"
assert html =~ "Inspect Delegated Evidence"
assert html =~ "handoff input"
assert html =~ "projected context"
assert html =~ "child step pending"
```

### Docs Drift Testing

**Source:** `test/scoria/adoption_surface_test.exs` lines 14-223
**Apply to:** README and docs lane wording

```elixir
content = File.read!(@lane_guide)

assert content =~ "Default runtime lane"
assert content =~ "Bounded handoff lane"
assert content =~ "mix test.adoption"
refute content =~ "mix scoria.test.knowledge"
```

```elixir
content = File.read!(@handoff_guide)

assert content =~ "Scoria.get_run_detail"
assert content =~ "delegated_handoffs"
assert content =~ "Delegated Evidence"
refute content =~ "Scoria.Workflows.create_run"
refute content =~ "workflow_steps"
refute content =~ "workflow_handoffs"
```

### Source Fragment Synchronization

**Source:** `test/support/scoria/adoption_example.ex` lines 23-79 and source tests lines 8-13
**Apply to:** `docs/phoenix_runtime_example.md`, `docs/bounded_handoffs.md`

```elixir
for fragment <- AdoptionExample.doc_fragments() do
  assert content =~ fragment
end
```

```elixir
for fragment <- AdoptionExample.handoff_doc_fragments() do
  assert content =~ fragment
end
```

## No Analog Found

All Phase 53 files have exact analogs because this is a tightening phase over existing UI, docs, DTO, and tests.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|

## Metadata

**Analog search scope:** `lib/scoria/runtime`, `lib/scoria_web/components`, `lib/scoria_web/live`, `test/scoria`, `test/scoria_web/live`, `test/support/scoria`, `README.md`, `docs/*.md`, `.planning/phases/52-runtime-to-handoff-example-contract/52-PATTERNS.md`
**Files scanned:** 21
**Pattern extraction date:** 2026-05-27
**Project instructions:** No project-root `AGENTS.md`, `CLAUDE.md`, `.claude/skills`, or `.agents/skills` were found.
**Planner warning:** Phase 54 owns canonical runtime-to-handoff proof commands, prerequisite-denial proof, support-surface command naming, and closeout proof lane mechanics. Phase 53 must not publish those as already available.

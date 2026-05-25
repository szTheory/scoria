# Phase 46: operator-evidence-and-verification - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/runtime.ex` | service | request-response | `lib/scoria/runtime.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `lib/scoria_web/components/runtime_detail_drawer_component.ex` | component | request-response | `lib/scoria_web/components/runtime_detail_drawer_component.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | route | request-response | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | component | request-response | `lib/scoria_web/components/workflow_detail_panel_component.ex` | exact |
| `lib/scoria_web/components/semantic_evidence_notebook_component.ex` | component | request-response | `lib/scoria_web/components/replay_evidence_notebook_component.ex` | role-match |
| `lib/mix/tasks/scoria.test.semantic_fast_path.ex` | utility | batch | `lib/mix/tasks/test.adoption.ex` | role-match |
| `lib/mix/tasks/test.semantic_fast_path.ex` | utility | batch | `lib/mix/tasks/test.adoption.ex` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/scoria/runtime/semantic_fast_path_test.exs` | test | request-response | `test/scoria/runtime/semantic_fast_path_test.exs` | exact |
| `test/scoria/semantic_cache/lookup_test.exs` | test | CRUD | `test/scoria/semantic_cache/lookup_test.exs` | exact |
| `test/scoria/semantic_cache/invalidation_test.exs` | test | event-driven | `test/scoria/semantic_cache/invalidation_test.exs` | exact |
| `test/scoria_web/live/workflow_live_test.exs` | test | request-response | `test/scoria_web/live/workflow_live_test.exs` | exact |
| `test/scoria_web/components/runtime_detail_drawer_component_test.exs` | test | request-response | `test/scoria_web/components/runtime_detail_drawer_component_test.exs` | exact |
| `test/mix/tasks/test.semantic_fast_path_test.exs` | test | batch | `test/mix/tasks/test.adoption_test.exs` | role-match |
| `docs/operator_verification.md` | utility | transform | `docs/operator_verification.md` | exact |
| `test/scoria/adoption_surface_test.exs` | test | transform | `test/scoria/adoption_surface_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/runtime.ex` (service, request-response)

**Analog:** `lib/scoria/runtime.ex`

**Imports and alias shape** (`lib/scoria/runtime.ex:14-20`)
```elixir
import Ecto.Query, warn: false

alias Ecto.NoResultsError
alias Scoria.Repo
alias Scoria.Runtime.{Instance, Params, ReplayComparison, RunDetail, RunSummary}
alias Scoria.Workflows
alias Scoria.Workflows.{Reconciler, Resume, Run}
```

**Curated fetch boundary** (`lib/scoria/runtime.ex:96-116`)
```elixir
def get_run_detail(run_id) do
  {:ok, get_run_detail!(run_id)}
rescue
  NoResultsError -> {:error, :not_found}
end

def get_run_detail!(run_id) do
  run = Workflows.get_run_tree!(run_id)
  source_run = load_source_run(run)

  RunDetail.from_run_tree(run,
    comparison_by_step: ReplayComparison.build(run, source_run),
    replay_provenance_strip: ReplayComparison.provenance_strip(run)
  )
end
```

**Phase 46 copy target:** keep semantic evidence assembly here or in helpers called from here so LiveViews stay render-only.

---

### `lib/scoria/runtime/run_detail.ex` (model, transform)

**Analog:** `lib/scoria/runtime/run_detail.ex`

**DTO struct contract** (`lib/scoria/runtime/run_detail.ex:10-31`)
```elixir
@enforce_keys [
  :summary,
  :steps,
  :checkpoints,
  :events,
  :approvals,
  :handoffs,
  :delegated_handoffs,
  :comparison_by_step,
  :replay_provenance_strip
]
defstruct [
  :summary,
  :steps,
  :checkpoints,
  :events,
  :approvals,
  :handoffs,
  :delegated_handoffs,
  :comparison_by_step,
  :replay_provenance_strip
]
```

**Projection entrypoint** (`lib/scoria/runtime/run_detail.ex:46-60`)
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
    comparison_by_step: Keyword.get(opts, :comparison_by_step, %{}),
    replay_provenance_strip: Keyword.get(opts, :replay_provenance_strip, %{})
  }
end
```

**Typed item mapping pattern** (`lib/scoria/runtime/run_detail.ex:63-77`)
```elixir
defp step_item(%Step{} = step) do
  %{
    id: step.id,
    sequence: step.sequence,
    kind: step.kind,
    role_id: step.role_id,
    status: step.status,
    parent_step_id: step.parent_step_id,
    idempotency_key: step.idempotency_key,
    projected_context: step.projected_context || %{},
    result_envelope: step.result_envelope || %{},
    error_envelope: step.error_envelope || %{},
    started_at: step.started_at,
    completed_at: step.completed_at
  }
end
```

**Phase 46 copy target:** add `:semantic_evidence` as another typed top-level field instead of pushing entry/event joins into LiveView modules.

---

### `lib/scoria_web/components/runtime_detail_drawer_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/components/runtime_detail_drawer_component.ex`

**Minimal attr + guard pattern** (`lib/scoria_web/components/runtime_detail_drawer_component.ex:1-8`)
```elixir
defmodule ScoriaWeb.RuntimeDetailDrawerComponent do
  use Phoenix.Component

  attr(:drawer, :map, default: nil)

  def render(assigns) do
    ~H"""
    <%= if @drawer do %>
```

**Summary-card rendering pattern** (`lib/scoria_web/components/runtime_detail_drawer_component.ex:23-33`)
```heex
<div class="mt-4 grid gap-3 md:grid-cols-2">
  <div class="rounded-xl bg-stone-50 p-3">
    <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Host session</p>
    <p class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.host_session_id %></p>
  </div>

  <div class="rounded-xl bg-stone-50 p-3">
    <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Transport</p>
    <p class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.transport_kind %></p>
  </div>
</div>
```

**Deep-link pattern** (`lib/scoria_web/components/runtime_detail_drawer_component.ex:42-49`)
```heex
<%= if @drawer.current_run_id do %>
  <div class="mt-4">
    <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Active workflow</p>
    <div class="mt-2">
      <.link navigate={"/workflows/#{@drawer.current_run_id}"} class="text-sm font-medium text-blue-700 underline">
        View run <%= @drawer.current_run_id %>
      </.link>
    </div>
  </div>
<% end %>
```

**Phase 46 copy target:** keep the runtime semantic block compact, summary-first, and link out to workflow evidence instead of embedding notebook detail here.

---

### `lib/scoria_web/live/workflow_live/show.ex` (route, request-response)

**Analog:** `lib/scoria_web/live/workflow_live/show.ex`

**Mount + async load pattern** (`lib/scoria_web/live/workflow_live/show.ex:19-34`)
```elixir
def mount(%{"id" => run_id} = params, _session, socket) do
  review_candidate_id = Map.get(params, "review_candidate_id")

  if connected?(socket) do
    Workflows.subscribe_run(run_id)
  end

  socket =
    socket
    |> load_run(run_id)
    |> assign(:review_candidate, load_review_candidate(run_id, review_candidate_id))
    |> assign_async(:compacted_memories, fn ->
      {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
    end)

  {:ok, socket}
end
```

**Canonical workflow surface composition** (`lib/scoria_web/live/workflow_live/show.ex:189-205`)
```heex
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
    selected_source_variant={@selected_source_variant}
    selected_comparison_entry={@selected_comparison_entry}
    promotion_context={@promotion_context}
  />
</div>
```

**Curated DTO assignment pattern** (`lib/scoria_web/live/workflow_live/show.ex:257-279`)
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
```

**Phase 46 copy target:** project semantic notebook assigns from `detail`, not fresh Ecto lookups inside the LiveView.

---

### `lib/scoria_web/components/workflow_detail_panel_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/components/workflow_detail_panel_component.ex`

**Panel shell pattern** (`lib/scoria_web/components/workflow_detail_panel_component.ex:6-15`)
```elixir
attr :step, :map, default: nil
attr :checkpoint, :map, default: nil
attr :comparison, :map, default: nil
attr :selected_source_variant, :string, default: "original"
attr :selected_comparison_entry, :map, default: nil
attr :promotion_context, :map, default: nil

def workflow_detail_panel(assigns) do
  ~H"""
  <aside id="workflow-detail-panel" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
```

**Progressive-disclosure composition** (`lib/scoria_web/components/workflow_detail_panel_component.ex:17-55`)
```heex
<%= if @step do %>
  <div class="flex items-start justify-between gap-4">
    <div>
      <p class="text-xs uppercase tracking-[0.22em] text-stone-500">Step detail</p>
      <h2 class="mt-1 text-lg font-semibold">Replay evidence</h2>
      <p class="mt-1 text-sm text-stone-600">
        Role <span class="font-medium text-stone-900"><%= @step.role_id %></span>
        · kind <span class="font-medium text-stone-900"><%= @step.kind %></span>
      </p>
    </div>
  </div>

  <p class="mt-3 text-sm text-stone-600">
    <%= promotion_helper_copy(@selected_source_variant, @promotion_context) %>
  </p>

  <ReplayEvidenceNotebookComponent.render
    step={@step}
    checkpoint={@checkpoint}
    comparison={@comparison}
    selected_source_variant={@selected_source_variant}
    selected_comparison_entry={@selected_comparison_entry}
  />
<% else %>
```

**Phase 46 copy target:** semantic notebook should slot in as another curated notebook surface under this panel rather than replacing the panel shell.

---

### `lib/scoria_web/components/semantic_evidence_notebook_component.ex` (component, request-response)

**Analog:** `lib/scoria_web/components/replay_evidence_notebook_component.ex`

**Notebook header + toggle pattern** (`lib/scoria_web/components/replay_evidence_notebook_component.ex:10-40`)
```heex
<section class="mt-4 rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
  <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
    <div>
      <p class="text-xs uppercase tracking-[0.24em] text-stone-500">replay evidence notebook</p>
      <h3 class="text-lg font-semibold text-stone-900">Original-versus-replay comparison</h3>
      <p class="mt-1 text-sm text-stone-600">
        Grouped operator evidence stays structured by provenance, overrides, outcome, safety, and promotion readiness.
      </p>
    </div>
```

**Grouped-card notebook layout** (`lib/scoria_web/components/replay_evidence_notebook_component.ex:42-65`)
```heex
<div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
  <div class="space-y-4">
    <.group_card title="Provenance" group={read_group(@selected_comparison_entry, :provenance)} />
    <.group_card title="Overrides" group={read_group(@selected_comparison_entry, :overrides)} />
    <.group_card
      title="Checkpoint / Output"
      group={read_group(@selected_comparison_entry, :checkpoint_output)}
    />
  </div>
```

**Raw JSON escape hatch** (`lib/scoria_web/components/replay_evidence_notebook_component.ex:62-65`)
```heex
<details class="mt-4 rounded-lg border border-stone-200 bg-white p-4">
  <summary class="cursor-pointer text-sm font-semibold text-stone-900">Advanced raw evidence</summary>
  <pre class="mt-3 overflow-x-auto whitespace-pre-wrap rounded-md bg-stone-50 p-3 text-xs text-stone-700"><%= Jason.encode_to_iodata!(normalize_for_json(@selected_comparison_entry), pretty: true) %></pre>
</details>
```

**Reusable card helpers** (`lib/scoria_web/components/replay_evidence_notebook_component.ex:79-100`)
```elixir
attr :title, :string, required: true
attr :group, :map, default: %{}

defp group_card(assigns) do
  ~H"""
  <div class="rounded-lg border border-stone-200 bg-white p-4">
    <div class="flex items-start justify-between gap-3">
      <div>
        <h4 class="text-sm font-semibold text-stone-900"><%= @title %></h4>
        <p class="mt-1 text-xs text-stone-500">Structured evidence projected from durable runtime DTOs.</p>
      </div>
      <span class={badge_class(card_status(@group), :status)}><%= card_status(@group) %></span>
    </div>
```

**Secondary analog:** `lib/scoria_web/components/memory_notebook_component.ex:7-24` for notebook title + runtime deep-link styling.

---

### `lib/mix/tasks/scoria.test.semantic_fast_path.ex` and `lib/mix/tasks/test.semantic_fast_path.ex` (utility, batch)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Bounded file-list lane pattern** (`lib/mix/tasks/test.adoption.ex:1-25`)
```elixir
defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @shortdoc "Runs the adoption-focused default verification lane"
  @adoption_test_files [
    "test/scoria_test.exs",
    "test/scoria/identity_doctest_test.exs",
    "test/scoria/adoption_surface_test.exs",
    ...
  ]

  def adoption_test_files, do: @adoption_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @adoption_test_files)
  end
end
```

**Compatibility wrapper pattern** (`lib/mix/tasks/test.adoption.ex:28-34`)
```elixir
defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria adoption verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

**Secondary analog:** `lib/mix/tasks/scoria.test.knowledge.ex:7-19` if the semantic lane needs setup before running `test`.

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**CLI preferred-env pattern** (`mix.exs:15-24`)
```elixir
def cli do
  [
    preferred_envs: [
      "scoria.test.adoption": :test,
      "test.adoption": :test,
      "scoria.test.knowledge": :test,
      "test.knowledge": :test
    ]
  ]
end
```

**Phase 46 copy target:** add both semantic lane task names here so `mix test.semantic_fast_path` is pinned to `:test` the same way as existing named lanes.

---

### `test/scoria/runtime/semantic_fast_path_test.exs` (test, request-response)

**Analog:** `test/scoria/runtime/semantic_fast_path_test.exs`

**Sandbox + runtime handler setup** (`test/scoria/runtime/semantic_fast_path_test.exs:41-58`)
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  start_supervised!(Scoria.Workflows.Reconciler)
  Application.put_env(:scoria, :workflow_runtime_handlers, %{"answer" => {Handlers, :answer}})
```

**End-to-end fallback/hit assertions** (`test/scoria/runtime/semantic_fast_path_test.exs:124-138`)
```elixir
assert {:ok, summary} =
         Runtime.start_run(
           %{tenant_id: "tenant-hit", actor_id: "actor-hit", session_id: "session-hit"},
           semantic_cache: [lane: AccountFaqLane],
           input: "what is scoria?"
         )

run = Workflows.get_run_tree!(summary.run_id)
[step] = run.steps

assert run.status == "completed"
assert step.result_envelope["semantic_cache"]["status"] == "hit"
assert step.result_envelope["semantic_cache"]["entry_id"] == tenant_entry.id
```

**Reason-coded bypass/reject assertions** (`test/scoria/runtime/semantic_fast_path_test.exs:157-162`, `285-291`)
```elixir
assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "bypass"
assert run.metadata["runtime"]["semantic_cache"]["eligibility_reason_code"] == "approval_required"

assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "reject"
assert run.metadata["runtime"]["semantic_cache"]["lookup_reason_code"] == "prompt_version_mismatch"
assert run.metadata["runtime"]["semantic_cache"]["candidate_status"] == "invalidated"
```

**Phase 46 copy target:** extend this file for operator-facing DTO/UI projection assertions before adding any brand-new semantic runtime test file.

---

### `test/scoria/semantic_cache/lookup_test.exs` (test, CRUD)

**Analog:** `test/scoria/semantic_cache/lookup_test.exs`

**Exact/higher-priority hit pattern** (`test/scoria/semantic_cache/lookup_test.exs:14-45`)
```elixir
test "exact query-text hit wins before semantic fallback" do
  ...
  assert {:hit, %Entry{id: entry_id}} =
           SemanticCache.lookup(%{
             tenant_id: "tenant-a",
             lane_key: "account_faq",
             actor_id: "actor-a",
             query_text: "what is scoria?",
             query_embedding: semantic_embedding,
             prompt_version: "1",
             policy_fingerprint: policy_fingerprint("default"),
             source_fingerprint: "source-v1"
           })
```

**Reason-coded reject pattern** (`test/scoria/semantic_cache/lookup_test.exs:72-92`)
```elixir
assert {:reject, "policy_mismatch", %Entry{id: rejected_entry_id}} =
         SemanticCache.lookup(%{
           tenant_id: "tenant-a",
           lane_key: "account_faq",
           actor_id: "actor-a",
           query_text: "policy question",
           query_embedding: [0.4, 0.4, 0.4],
           prompt_version: "1",
           policy_fingerprint: policy_fingerprint("different"),
           source_fingerprint: "source-v1"
         })
```

**Factory-helper pattern** (`test/scoria/semantic_cache/lookup_test.exs:140-160`)
```elixir
defp base_entry_attrs(overrides) do
  Map.merge(
    %{
      tenant_id: "tenant-a",
      actor_id: "actor-a",
      lane_key: "account_faq",
      lane_module: "MyApp.Lanes.AccountFaq",
      scope_kind: "actor_scoped",
      scope_reason: "actor_scope_required",
      ...
    },
    overrides
  )
end
```

---

### `test/scoria/semantic_cache/invalidation_test.exs` (test, event-driven)

**Analog:** `test/scoria/semantic_cache/invalidation_test.exs`

**State transition + event append pattern** (`test/scoria/semantic_cache/invalidation_test.exs:17-36`)
```elixir
assert {:ok, _} =
         SemanticCache.invalidate_by_prompt(%{
           tenant_id: "tenant-a",
           lane_key: "account_faq",
           prompt_ref: "faq",
           prompt_version: "2"
         })

target = Repo.get!(Entry, target.id)
event = SemanticCache.list_events(target.id) |> List.last()

assert target.status == "invalidated"
assert target.state_reason_code == "prompt_version_mismatch"
assert event.event_kind == "invalidated"
```

**Distinct stale vs invalidated truth** (`test/scoria/semantic_cache/invalidation_test.exs:78-98`)
```elixir
assert {:ok, %Entry{} = stale_entry} =
         SemanticCache.mark_stale(stale_entry, "freshness_window_elapsed", %{"phase" => "45"})

assert {:ok, %Entry{} = revoked_entry} =
         SemanticCache.revoke_entry(revoked_entry, %{"phase" => "45"})

assert stale_entry.status == "stale"
assert stale_entry.state_reason_code == "freshness_window_elapsed"
assert is_nil(stale_entry.invalidated_at)
```

---

### `test/scoria_web/live/workflow_live_test.exs` (test, request-response)

**Analog:** `test/scoria_web/live/workflow_live_test.exs`

**LiveView harness pattern** (`test/scoria_web/live/workflow_live_test.exs:28-57`)
```elixir
defmodule ScoriaWeb.WorkflowLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.WorkflowLiveTest.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(ScoriaWeb.WorkflowLiveTest.Endpoint)
    :ok
  end
end
```

**Mounted-page assertion pattern** (`test/scoria_web/live/workflow_live_test.exs:77-88`)
```elixir
conn =
  build_conn()
  |> Plug.Test.init_test_session(%{})
  |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

{:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

assert html =~ "Workflow Run"
assert html =~ run.id
```

**Interactive right-rail assertion pattern** (`test/scoria_web/live/workflow_live_test.exs:176-185`)
```elixir
selected_html =
  view
  |> element("button[phx-click='select_step'][phx-value-id='#{child_step.id}']")
  |> render_click()

assert selected_html =~ "Role"
assert selected_html =~ "critic"
assert selected_html =~ "review"
```

**Phase 46 copy target:** assert semantic notebook summary strip, provenance links, stale/reject candidate visibility, and workflow-to-runtime reciprocity here.

---

### `test/scoria_web/components/runtime_detail_drawer_component_test.exs` (test, request-response)

**Analog:** `test/scoria_web/components/runtime_detail_drawer_component_test.exs`

**Component rendering seam** (`test/scoria_web/components/runtime_detail_drawer_component_test.exs:9-31`)
```elixir
assigns = %{
  drawer: %{
    id: "rt-1234",
    status: "offline",
    host_session_id: "sess-999",
    transport_kind: "websocket",
    terminal_offline_reason: "Connection lost",
    current_run_id: nil
  }
}

html = rendered_to_string(~H"""
<RuntimeDetailDrawerComponent.render drawer={@drawer} />
""")
```

**Link assertion pattern** (`test/scoria_web/components/runtime_detail_drawer_component_test.exs:33-54`)
```elixir
assert html =~ "run-abc-123"
assert html =~ "href=\"/workflows/run-abc-123\""
refute html =~ "Terminal offline reason"
```

---

### `test/mix/tasks/test.semantic_fast_path_test.exs` (test, batch)

**Analog:** `test/mix/tasks/test.adoption_test.exs`

**Discoverability/file-list test pattern** (`test/mix/tasks/test.adoption_test.exs:4-28`)
```elixir
test "the adoption lane is discoverable and targets the bounded default-suite subset" do
  Mix.Task.load_all()

  expected_files = [
    "test/scoria_test.exs",
    ...
  ]

  assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :run, 1)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
  assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
  assert Mix.Task.get("scoria.test.adoption")
  assert Mix.Task.get("test.adoption")
end
```

**Phase 46 copy target:** mirror this exactly for `semantic_fast_path_test_files/0`, wrapper discoverability, and expected bounded file list.

---

### `docs/operator_verification.md` (utility, transform)

**Analog:** `docs/operator_verification.md`

**Canonical proof-lane narrative** (`docs/operator_verification.md:17-35`)
```markdown
## Step 1: Install preflight

Run the installer and the boring baseline commands first:

```bash
mix scoria.install
mix ecto.migrate
mix test
```

Use `mix test.adoption` as the canonical ADPT-02 proof lane when you want the same runtime-first bounded handoff subset CI runs without waiting for the whole suite.
```

**Closeout lane list pattern** (`docs/operator_verification.md:110-122`)
```markdown
## Maintainer closeout

```bash
mix test.adoption
mix test
mix scoria.test.knowledge
```
```

**Phase 46 copy target:** add `mix test.semantic_fast_path` into this guide as the semantic troubleshooting lane without replacing `mix test.adoption` as the default public-runtime lane.

---

### `test/scoria/adoption_surface_test.exs` (test, transform)

**Analog:** `test/scoria/adoption_surface_test.exs`

**Docs assertion seam** (`test/scoria/adoption_surface_test.exs:83-98`)
```elixir
test "operator verification guide documents the core automated lane without knowledge requirements" do
  content = File.read!(@operator_guide)

  assert content =~ "mix scoria.install"
  assert content =~ "mix ecto.migrate"
  assert content =~ "mix test"
  assert content =~ "mix test.adoption"
  assert content =~ "canonical ADPT-02 proof lane"
  assert content =~ "broader repo-health context"
  assert content =~ "mix scoria.test.knowledge"
end
```

**File constant pattern** (`test/scoria/adoption_surface_test.exs:4-10`)
```elixir
@readme "README.md"
@phoenix_example "docs/phoenix_runtime_example.md"
@handoff_guide "docs/bounded_handoffs.md"
@gap_ledger ".planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md"
@operator_guide "docs/operator_verification.md"
```

**Phase 46 copy target:** extend this file or add a sibling docs-source assertion file using the same `File.read!` plus string-guard pattern.

## Shared Patterns

### Semantic outcome truth
**Source:** `lib/scoria/workflows/runtime.ex`
**Apply to:** `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_detail.ex`, workflow/runtime UI projections, semantic UI tests

**Stage-separated status projection** (`lib/scoria/workflows/runtime.ex:52-85`, `106-135`)
```elixir
case Eligibility.evaluate(facts) do
  {:bypass, reason_code} ->
    {:continue, put_semantic_cache_state(workflow_attrs, %{
       "eligibility_status" => "bypass",
       "eligibility_reason_code" => Atom.to_string(reason_code),
       "lookup_status" => "bypass",
       "query_text" => query_text
     })}

  {eligibility_status, attrs} when eligibility_status in [:eligible, :eligible_actor_scoped] ->
    ...
    case SemanticCache.lookup(lookup_attrs) do
      {:hit, entry} ->
        {:hit, put_semantic_cache_state(workflow_attrs, %{...}), entry}
      {:reject, reason_code, entry} ->
        {:continue, put_semantic_cache_state(workflow_attrs, %{
           "lookup_status" => "reject",
           "lookup_reason_code" => reason_code,
           "candidate_entry_id" => entry.id,
           "candidate_status" => updated_entry.status,
           ...
         })}
      :miss ->
        {:continue, put_semantic_cache_state(workflow_attrs, %{
           "lookup_status" => "miss",
           ...
         })}
    end
end
```

### Durable provenance and lifecycle evidence
**Source:** `lib/scoria/semantic_cache.ex`, `lib/scoria/semantic_cache/entry.ex`, `lib/scoria/semantic_cache/entry_event.ex`
**Apply to:** semantic DTO projection, workflow notebook, lifecycle tests

**Entry schema fields to surface** (`lib/scoria/semantic_cache/entry.ex:11-43`)
```elixir
schema "ai_semantic_cache_entries" do
  field :tenant_id, :string
  field :actor_id, :string
  field :scope_kind, :string
  field :scope_reason, :string
  field :lane_key, :string
  field :lane_module, :string
  field :policy_key, :string
  field :prompt_ref, :string
  field :prompt_version, :string
  field :provider, :string
  field :model, :string
  ...
  field :status, :string, default: "active"
  field :state_reason_code, :string
  field :last_hit_at, :utc_datetime_usec
  field :hit_count, :integer, default: 0
  field :expires_at, :utc_datetime_usec
  field :invalidated_at, :utc_datetime_usec
```

**Append-only event list pattern** (`lib/scoria/semantic_cache.ex:170-175`)
```elixir
def list_events(entry_id) do
  EntryEvent
  |> where([event], event.entry_id == ^entry_id)
  |> order_by([event], asc: event.inserted_at, asc: event.id)
  |> Repo.all()
end
```

**Event record shape** (`lib/scoria/semantic_cache/entry_event.ex:8-24`)
```elixir
schema "ai_semantic_cache_entry_events" do
  field :event_kind, :string
  field :reason_code, :string
  field :metadata, :map, default: %{}
  belongs_to :entry, Scoria.SemanticCache.Entry
  belongs_to :workflow_run, Scoria.Workflows.Run
  belongs_to :span, Scoria.Repo.Span
end
```

### Notebook-style progressive disclosure
**Source:** `lib/scoria_web/components/replay_evidence_notebook_component.ex`
**Apply to:** semantic workflow notebook

**Summary -> grouped cards -> raw JSON** (`lib/scoria_web/components/replay_evidence_notebook_component.ex:42-75`)
```heex
<div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
  ...
</div>

<details class="mt-4 rounded-lg border border-stone-200 bg-white p-4">
  <summary class="cursor-pointer text-sm font-semibold text-stone-900">Advanced raw evidence</summary>
  <pre class="mt-3 overflow-x-auto whitespace-pre-wrap rounded-md bg-stone-50 p-3 text-xs text-stone-700"><%= Jason.encode_to_iodata!(normalize_for_json(@selected_comparison_entry), pretty: true) %></pre>
</details>
```

### Named verification lane mechanics
**Source:** `lib/mix/tasks/test.adoption.ex`, `mix.exs`, `test/mix/tasks/test.adoption_test.exs`
**Apply to:** new semantic Mix tasks and their discoverability test

**Task + wrapper + preferred env + discoverability** (`lib/mix/tasks/test.adoption.ex:1-34`, `mix.exs:15-24`, `test/mix/tasks/test.adoption_test.exs:20-28`)
```elixir
assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
assert Mix.Task.get("scoria.test.adoption")
assert Mix.Task.get("test.adoption")
```

### Docs-as-checked-proof pattern
**Source:** `docs/operator_verification.md`, `test/scoria/adoption_surface_test.exs`
**Apply to:** semantic verification docs updates

**String-guard docs test** (`test/scoria/adoption_surface_test.exs:83-98`)
```elixir
content = File.read!(@operator_guide)
assert content =~ "mix test.adoption"
assert content =~ "canonical ADPT-02 proof lane"
assert content =~ "mix scoria.test.knowledge"
```

## No Analog Found

None. Every scoped file has an existing repository analog or a strong role-match seam.

## Metadata

**Analog search scope:** `lib/`, `test/`, `docs/`, `mix.exs`
**Files scanned:** 22
**Pattern extraction date:** 2026-05-25

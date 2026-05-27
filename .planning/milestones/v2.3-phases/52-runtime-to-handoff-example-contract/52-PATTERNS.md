# Phase 52: Runtime-to-handoff example contract - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `docs/phoenix_runtime_example.md` | documentation | request-response | `docs/phoenix_runtime_example.md` | exact |
| `docs/bounded_handoffs.md` | documentation | request-response | `docs/bounded_handoffs.md` | exact |
| `test/support/scoria/adoption_example.ex` | utility | transform | `test/support/scoria/adoption_example.ex` | exact |
| `test/scoria/adoption_surface_test.exs` | test | file-I/O | `test/scoria/adoption_surface_test.exs` | exact |
| `test/scoria/handoff_example_source_test.exs` | test | file-I/O | `test/scoria/handoff_example_source_test.exs` | exact |
| `test/scoria/phoenix_example_source_test.exs` | test | file-I/O | `test/scoria/phoenix_example_source_test.exs` | exact |
| `test/scoria/runtime_test.exs` | test | CRUD | `test/scoria/runtime_test.exs` | exact |
| `test/scoria/runtime_integration_test.exs` | test | request-response | `test/scoria/runtime_integration_test.exs` | role-match |
| `lib/scoria.ex` | service | request-response | `lib/scoria.ex` | exact |
| `lib/scoria/runtime.ex` | service | CRUD | `lib/scoria/runtime.ex` | exact |
| `lib/scoria/runtime/params.ex` | utility | transform | `lib/scoria/runtime/params.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model | transform | `lib/scoria/runtime/run_detail.ex` | exact |

## Pattern Assignments

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

**Controller example pattern** (lines 30-65):

```elixir
defmodule MyAppWeb.AssistantController do
  use MyAppWeb, :controller

  def create(conn, %{"prompt" => prompt}) do
    identity =
      Scoria.identity(%{
        actor_id: conn.assigns.current_user.id,
        tenant_id: conn.assigns.current_account.id,
        session_id: get_session(conn, :assistant_session_id),
        metadata: %{"channel" => "web"}
      })

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "executor",
        initial_step: %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        },
        runtime: [
          metadata: %{
            "payload" => %{"prompt" => prompt}
          }
        ],
        handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
      )

    conn
    |> put_session(:last_scoria_run_id, started.run_id)
    |> redirect(to: ~p"/assistant/runs/#{started.run_id}")
  end
end
```

**Handoff branch pattern** (lines 113-131):

```elixir
{:ok, handoff_run} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer"},
    projected_context: %{"task" => "policy review", "draft_answer" => prompt},
    handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
  )

{:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)
delegated = detail.delegated_handoffs
```

### `docs/bounded_handoffs.md` (documentation, request-response)

**Analog:** `docs/bounded_handoffs.md`

**Core contract pattern** (lines 15-25):

```markdown
## Core contract

Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`: the root role that is delegating
- the delegated role argument: the role that should own the child step
- `delegated_kind`: the child step kind that host handlers should execute
- `handoff_input`: the exact host-supplied work brief Scoria should persist
- `projected_context`: the exact projected context slice that is safe to pass down

The host app passes these fields explicitly. Scoria does not fill in hidden handoff defaults for you.
```

**Safety wording pattern** (lines 61-76):

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
```

**Readback pattern** (lines 78-95):

```elixir
{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

### `test/support/scoria/adoption_example.ex` (utility, transform)

**Analog:** `test/support/scoria/adoption_example.ex`

**Fragment source pattern** (lines 1-23):

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

  def shared_session_id, do: @shared_session_id
  def waiting_status, do: @waiting_status
  def completed_status, do: @completed_status

  def operator_route(run_id), do: "/scoria/workflows/#{run_id}"
  def operator_route_pattern, do: "/scoria/workflows/:run_id"
```

**Doc-fragment pattern** (lines 23-43):

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
    "next_run.session_id == session_id",
    "next_run.run_id != run_id",
    operator_route_pattern(),
    "session_id",
    "run_id",
    "Scoria.start_run",
    "identity -> start -> inspect -> resume",
    "Scoria.resume_run",
    "Scoria.get_run",
    "list_runs_for_session"
  ]
end
```

**Handoff-fragment pattern** (lines 45-68):

```elixir
def handoff_doc_fragments do
  [
    "Scoria.start_handoff_run(identity, \"critic\"",
    "Scoria.get_run_detail(started.run_id)",
    "delegated = detail.delegated_handoffs",
    "root_role_id: \"planner\"",
    "delegated_kind: \"review\"",
    "handoff_input: %{\"brief\" => \"Review the draft answer for policy and accuracy\"}",
    "projected_context: %{",
    "projected_context: %{}",
    "same durable run",
    "Delegated Evidence",
    "No remaining adopter-facing gap",
    "deferred follow-up",
    "Broad runtime-state keys are rejected explicitly",
    "`transcript`",
    "`provider_session`",
    "`session`",
    "`secrets`",
    "`socket_state`",
    "handlers: %{\"review\" => {MyApp.RuntimeHandlers, :review}}",
    "/scoria/workflows/:run_id"
  ]
end
```

### `test/scoria/adoption_surface_test.exs` (test, file-I/O)

**Analog:** `test/scoria/adoption_surface_test.exs`

**Imports and fixture path pattern** (lines 1-12):

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
  @scoria_doctest "test/scoria_test.exs"
  @identity_doctest "test/scoria/identity_doctest_test.exs"
```

**Docs assertion pattern** (lines 68-95):

```elixir
test "bounded handoff guide documents the narrow public delegation lane" do
  content = File.read!(@handoff_guide)

  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.start_handoff_run"
  assert content =~ "Scoria.get_run_detail"
  assert content =~ "delegated_handoffs"
  assert content =~ "root_role_id"
  assert content =~ "delegated_kind"
  assert content =~ "handoff_input"
  assert content =~ "projected_context"
  assert content =~ "projected_context: %{}"
  assert content =~ "queued child step"
  assert content =~ "same durable run"
  assert content =~ "Delegated Evidence"
  assert content =~ "No remaining adopter-facing gap"
  assert content =~ "deferred follow-up"
  assert content =~ "mix test.adoption"
  assert content =~ "separate verifier lane"
  assert content =~ "Broad runtime-state keys are rejected explicitly"
  assert content =~ "transcript"
  assert content =~ "provider_session"
  assert content =~ "session"
  assert content =~ "secrets"
  assert content =~ "socket_state"
  assert content =~ "/scoria/workflows/:run_id"
  refute content =~ "implicit payload projection"
end
```

**Phoenix example assertion pattern** (lines 124-139):

```elixir
test "Phoenix runtime example documents identity, readback, and approval resume" do
  content = File.read!(@phoenix_example)

  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.identity"
  assert content =~ "Scoria.start_run"
  assert content =~ "Scoria.get_run"
  assert content =~ "Scoria.get_run_detail"
  assert content =~ "delegated_handoffs"
  assert content =~ "Scoria.resume_run"
  assert content =~ "list_runs_for_session"
  assert content =~ "session_id"
  assert content =~ "run_id"
  assert content =~ "/scoria/workflows/:run_id"
  assert content =~ "approval"
end
```

### `test/scoria/handoff_example_source_test.exs` (test, file-I/O)

**Analog:** `test/scoria/handoff_example_source_test.exs`

**Source-alignment pattern** (lines 1-15):

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

### `test/scoria/phoenix_example_source_test.exs` (test, file-I/O)

**Analog:** `test/scoria/phoenix_example_source_test.exs`

**Source-alignment pattern** (lines 1-15):

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

### `test/scoria/runtime_test.exs` (test, CRUD)

**Analog:** `test/scoria/runtime_test.exs`

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

**Public API exposure pattern** (lines 15-23):

```elixir
test "Scoria and Scoria.Runtime expose explicit lifecycle verbs" do
  assert Code.ensure_loaded?(Scoria)
  assert function_exported?(Scoria, :start_run, 2)
  assert function_exported?(Scoria, :start_handoff_run, 3)
  assert function_exported?(Scoria, :resume_run, 2)
  assert function_exported?(Scoria.Runtime, :start_run, 2)
  assert function_exported?(Scoria.Runtime, :start_handoff_run, 3)
  assert function_exported?(Scoria.Runtime, :resume_run, 2)
end
```

**Handoff lineage assertion pattern** (lines 25-69):

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
  handoff = Enum.find(detail.handoffs, &(&1.delegated_role_id == "critic"))
  child_step = Enum.find(detail.steps, &(&1.parent_step_id != nil and &1.role_id == "critic"))

  assert detail.summary.status == "running"
  assert handoff.delegated_kind == "review"
  assert handoff.handoff_input == %{"brief" => "review draft"}
  assert child_step.kind == "review"
  assert child_step.projected_context["task"] == "review"
end
```

**Unsafe projected-context rejection pattern** (lines 215-231):

```elixir
test "start_handoff_run rejects unsafe projected context before any durable write" do
  assert {:error, :unsafe_projected_context} =
           Runtime.start_handoff_run(
             %{
               actor_id: "actor-unsafe",
               tenant_id: "tenant-unsafe",
               session_id: "session-unsafe"
             },
             "critic",
             root_role_id: "planner",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             projected_context: %{"safe" => %{"provider_session" => %{"token" => "secret"}}}
           )

  assert Runtime.list_runs_for_session("session-unsafe") == []
end
```

**Accepted projected-context pattern** (lines 273-300):

```elixir
test "start_handoff_run accepts explicit empty or narrow projected context slices" do
  assert {:ok, empty_summary} =
           Runtime.start_handoff_run(
             %{actor_id: "actor-empty", tenant_id: "tenant-empty", session_id: "session-empty"},
             "critic",
             root_role_id: "planner",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             projected_context: %{}
           )

  assert {:ok, narrow_summary} =
           Runtime.start_handoff_run(
             %{
               actor_id: "actor-narrow",
               tenant_id: "tenant-narrow",
               session_id: "session-narrow"
             },
             "critic",
             root_role_id: "planner",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             projected_context: %{"task" => "review"}
           )

  assert Runtime.get_run_detail!(empty_summary.run_id).summary.status == "running"
  assert Runtime.get_run_detail!(narrow_summary.run_id).summary.status == "running"
end
```

### `test/scoria/runtime_integration_test.exs` (test, request-response)

**Analog:** `test/scoria/runtime_integration_test.exs`

**Phoenix test harness pattern** (lines 1-38):

```elixir
defmodule Scoria.RuntimeIntegrationTest.Router do
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

defmodule Scoria.RuntimeIntegrationTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_runtime_integration_key",
    signing_salt: "runtime_integration_salt"
  )

  plug(Scoria.RuntimeIntegrationTest.Router)
end

defmodule Scoria.RuntimeIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Runtime
  alias Scoria.TestSupport.AdoptionExample
  alias Scoria.Workflows

  @endpoint Scoria.RuntimeIntegrationTest.Endpoint
```

**Facade-driven runtime proof pattern** (lines 120-162):

```elixir
test "public runtime proves same-session new runs and exact run_id resume" do
  identity = AdoptionExample.runtime_identity()

  {:ok, started} =
    Scoria.start_run(identity,
      root_role_id: "executor",
      initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
      handlers: %{"approval" => {Handlers, :wait_for_approval}}
    )

  wait_for(fn ->
    case Runtime.get_run(started.run_id) do
      {:ok, summary} -> summary.status == "waiting_for_approval"
      _ -> false
    end
  end)

  assert {:ok, resumed} =
           Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

  assert resumed.run_id == started.run_id

  {:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

  assert next_run.session_id == started.session_id
  assert next_run.run_id != started.run_id
end
```

### `lib/scoria.ex` (service, request-response)

**Analog:** `lib/scoria.ex`

**Facade import/alias pattern** (lines 1-34):

```elixir
defmodule Scoria do
  @moduledoc """
  Public facade for Phoenix-hosted Scoria runtime integration.

  Start here when wiring Scoria into an application. The happy path is:

  1. Normalize request or session context with `identity/1`
  2. Start a durable run with `start_run/2`
  3. Persist the returned `run_id`
  4. Inspect or resume that exact run through the same module
  """

  alias Scoria.Runtime
```

**Delegating public API pattern** (lines 35-79):

```elixir
@doc """
Normalizes caller-supplied edge identity into the canonical runtime envelope.
"""
def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)

@doc """
Starts a run through the canonical public runtime facade.
"""
def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)

@doc """
Starts a bounded delegated run with one explicit handoff and projected context.
"""
def start_handoff_run(identity, delegated_role_id, opts \\ []),
  do: Runtime.start_handoff_run(identity, delegated_role_id, opts)

@doc """
Returns the curated detailed public view for a run.
"""
def get_run_detail(run_id), do: Runtime.get_run_detail(run_id)

@doc """
Lists runs that share the same host-owned `session_id`.
"""
def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
```

### `lib/scoria/runtime.ex` (service, CRUD)

**Analog:** `lib/scoria/runtime.ex`

**Imports and aliases pattern** (lines 14-22):

```elixir
import Ecto.Query, warn: false

alias Ecto.NoResultsError
alias Scoria.Repo
alias Scoria.Runtime.{Instance, Params, ReplayComparison, RunDetail, RunSummary}
alias Scoria.SemanticCache
alias Scoria.SemanticCache.Entry
alias Scoria.Workflows
alias Scoria.Workflows.{Reconciler, Resume, Run}
```

**Start run pattern** (lines 24-45):

```elixir
@doc """
Starts a new run from canonical identity plus explicit runtime options.
"""
def start_run(identity, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start(identity, opts),
       :ok <- Scoria.Runtime.ReleaseGate.check(workflow_attrs) do
    case Scoria.Workflows.Runtime.prepare_semantic_fast_path(workflow_attrs) do
      {:hit, prepared_attrs, entry} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs),
             {:ok, _completed_run} <- Scoria.Workflows.Runtime.complete_semantic_fast_path_hit(run, entry) do
          {:ok, get_run!(run.id)}
        end

      {:continue, prepared_attrs} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs),
             {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
          {:ok, get_run!(run.id)}
        end
    end
  end
end
```

**Start handoff pattern** (lines 47-68):

```elixir
@doc """
Starts a bounded delegated run with one explicit handoff and queued child step.
"""
def start_handoff_run(identity, delegated_role_id, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, handoff_attrs: handoff_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start_handoff(identity, delegated_role_id, opts),
       {:ok, run} <- Workflows.create_run(workflow_attrs),
       {:ok, step} <-
         Workflows.create_step(run.id, %{
           sequence: 1,
           kind: "handoff",
           role_id: workflow_attrs.root_role_id,
           status: "queued"
         }),
       {:ok, _completed_step} <-
         Scoria.Workflows.Runtime.execute_step(step.id,
           handler: fn _step, _run -> {:handoff, handoff_attrs} end
         ),
       {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
    {:ok, get_run!(run.id)}
  end
end
```

**Error/readback pattern** (lines 80-119):

```elixir
def get_run(run_id) do
  {:ok, get_run!(run_id)}
rescue
  NoResultsError -> {:error, :not_found}
end

def get_run_detail(run_id) do
  {:ok, get_run_detail!(run_id)}
rescue
  NoResultsError -> {:error, :not_found}
end

def get_run_detail!(run_id) do
  run = Workflows.get_run_tree!(run_id)
  source_run = load_source_run(run)

  RunDetail.from_run_tree(run,
    semantic_evidence: build_semantic_evidence(run),
    comparison_by_step: ReplayComparison.build(run, source_run),
    replay_provenance_strip: ReplayComparison.provenance_strip(run)
  )
end
```

### `lib/scoria/runtime/params.ex` (utility, transform)

**Analog:** `lib/scoria/runtime/params.ex`

**Parameter normalization pattern** (lines 1-16):

```elixir
defmodule Scoria.Runtime.Params do
  @moduledoc """
  Normalizes public runtime inputs into explicit start and resume contracts.
  """

  alias Scoria.{Identity, Runtime.Defaults, SemanticLane}

  @dispatch_keys ~w(dispatch handlers timeout budget_context breaker_context)a
  def start(identity, opts \\ []) do
    opts = normalize_map(opts)
    runtime = nested_map(opts, :runtime)
    dispatch = dispatch_opts(opts)
    identity = Identity.normalize(identity)
```

**Handoff validation pattern** (lines 35-77):

```elixir
def start_handoff(identity, delegated_role_id, opts)
    when is_binary(delegated_role_id) and delegated_role_id != "" do
  opts = normalize_map(opts)
  runtime = nested_map(opts, :runtime)
  dispatch = dispatch_opts(opts)
  identity = Identity.normalize(identity)

  with {:ok, resolved_defaults} <- Defaults.resolve(identity, opts),
       {:ok, semantic_cache} <- semantic_cache_config(opts, runtime),
       {:ok, root_role_id} <-
         required_string(opts, runtime, :root_role_id, :invalid_root_role_id),
       {:ok, delegated_kind} <-
         required_string(opts, runtime, :delegated_kind, :invalid_delegated_kind),
       {:ok, handoff_input} <-
         required_map(opts, runtime, :handoff_input, :invalid_handoff_input),
       {:ok, projected_context} <-
         required_map(opts, runtime, :projected_context, :invalid_projected_context),
       :ok <- validate_projected_context(projected_context) do
    handoff_attrs = %{
      "delegated_role_id" => delegated_role_id,
      "delegated_kind" => delegated_kind,
      "capability_tags" => capability_tags(opts, runtime),
      "handoff_input" => handoff_input,
      "projected_context" => projected_context
    }

    {:ok,
     %{workflow_attrs: workflow_attrs, handoff_attrs: handoff_attrs, dispatch_opts: dispatch}}
  end
end

def start_handoff(_identity, _delegated_role_id, _opts),
  do: {:error, :invalid_delegated_role_id}
```

**Projected-context rejection pattern** (lines 88-95, 249-312):

```elixir
def validate_projected_context(projected_context) when is_map(projected_context) do
  case find_unsafe_projected_context_path(projected_context, []) do
    nil -> :ok
    _path -> {:error, :unsafe_projected_context}
  end
end

def validate_projected_context(_projected_context), do: {:error, :invalid_projected_context}

defp unsafe_projected_context_key?(key) do
  key in [
    "transcript",
    "transcripts",
    "messages",
    "message_history",
    "history",
    "chat_history",
    "conversation_history",
    "provider_session",
    "provider_state",
    "runtime_state",
    "session",
    "session_state",
    "socket",
    "socket_state",
    "assigns",
    "private",
    "cookies",
    "headers",
    "secrets"
  ] or
    String.ends_with?(key, "_transcript") or
    String.ends_with?(key, "_history") or
    String.ends_with?(key, "_messages") or
    String.ends_with?(key, "_cookies") or
    String.ends_with?(key, "_headers") or
    String.ends_with?(key, "_secrets") or
    String.starts_with?(key, "provider_session_") or
    String.ends_with?(key, "_provider_session") or
    String.starts_with?(key, "socket_") or
    String.ends_with?(key, "_socket")
end
```

### `lib/scoria/runtime/run_detail.ex` (model, transform)

**Analog:** `lib/scoria/runtime/run_detail.ex`

**DTO shape pattern** (lines 1-33):

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
    :semantic_evidence,
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
    :semantic_evidence,
    :comparison_by_step,
    :replay_provenance_strip
  ]
```

**Run-tree transform pattern** (lines 49-65):

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
    semantic_evidence: Keyword.get(opts, :semantic_evidence, %{}),
    comparison_by_step: Keyword.get(opts, :comparison_by_step, %{}),
    replay_provenance_strip: Keyword.get(opts, :replay_provenance_strip, %{})
  }
end
```

**Delegated readback pattern** (lines 161-201):

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

## Shared Patterns

### Public Facade First

**Source:** `lib/scoria.ex` lines 35-79  
**Apply to:** `docs/phoenix_runtime_example.md`, `docs/bounded_handoffs.md`, all example/source tests

```elixir
def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)
def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)
def start_handoff_run(identity, delegated_role_id, opts \\ []),
  do: Runtime.start_handoff_run(identity, delegated_role_id, opts)
def get_run_detail(run_id), do: Runtime.get_run_detail(run_id)
def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
```

### ExUnit DB Runtime Setup

**Source:** `test/scoria/runtime_test.exs` lines 1-13  
**Apply to:** DB-backed runtime behavior tests

```elixir
use ExUnit.Case, async: false

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  start_supervised!(Scoria.Workflows.Reconciler)
  :ok
end
```

### Source-Alignment Tests

**Source:** `test/scoria/handoff_example_source_test.exs` lines 8-14 and `test/scoria/phoenix_example_source_test.exs` lines 8-14  
**Apply to:** docs backed by `test/support/scoria/adoption_example.ex`

```elixir
content = File.read!(@handoff_guide)

for fragment <- AdoptionExample.handoff_doc_fragments() do
  assert content =~ fragment
end
```

### Projected Context Validation

**Source:** `lib/scoria/runtime/params.ex` lines 88-95 and 280-312  
**Apply to:** runtime params, docs, runtime tests

```elixir
def validate_projected_context(projected_context) when is_map(projected_context) do
  case find_unsafe_projected_context_path(projected_context, []) do
    nil -> :ok
    _path -> {:error, :unsafe_projected_context}
  end
end
```

### Curated Delegated Readback

**Source:** `lib/scoria/runtime/run_detail.ex` lines 49-65 and 161-201  
**Apply to:** `Scoria.get_run_detail/1` examples, runtime tests, docs

```elixir
%__MODULE__{
  summary: RunSummary.from_run(run),
  steps: steps,
  handoffs: handoffs,
  delegated_handoffs: delegated_handoff_items(steps, handoffs),
  semantic_evidence: Keyword.get(opts, :semantic_evidence, %{}),
  comparison_by_step: Keyword.get(opts, :comparison_by_step, %{}),
  replay_provenance_strip: Keyword.get(opts, :replay_provenance_strip, %{})
}
```

## No Analog Found

None. All expected Phase 52 files/areas have exact or strong role-match analogs already in the repository.

## Metadata

**Analog search scope:** `docs/`, `test/support/scoria/`, `test/scoria/`, `lib/scoria.ex`, `lib/scoria/runtime.ex`, `lib/scoria/runtime/params.ex`, `lib/scoria/runtime/run_detail.ex`  
**Files scanned:** 120+ repo files via `rg --files`, with focused grep for `start_handoff_run`, `projected_context`, `delegated_handoffs`, and adoption example source tests  
**Pattern extraction date:** 2026-05-27

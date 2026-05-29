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
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Runtime
  alias Scoria.TestSupport.AdoptionExample
  alias Scoria.Workflows

  @endpoint Scoria.RuntimeIntegrationTest.Endpoint

  defmodule Handlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod"},
         reason: "Need approval",
         actor_id: "operator-runtime",
         tenant_id: "tenant-runtime",
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
  end

  setup_all do
    Application.put_env(:scoria, Scoria.RuntimeIntegrationTest.Endpoint,
      secret_key_base: "qS22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW9N",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "87654321"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :succeed}})
    start_supervised!(Scoria.RuntimeIntegrationTest.Endpoint)
    :ok
  end

  test "public runtime stamps the resolved provider model and policy snapshot into durable run metadata" do
    previous = Application.get_env(:scoria, Scoria.Runtime)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:scoria, Scoria.Runtime)
      else
        Application.put_env(:scoria, Scoria.Runtime, previous)
      end
    end)

    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5-mini",
        prompt_policy: [
          policy_key: "app-default",
          prompt_ref: "prompt://integration",
          prompt_version: "v1"
        ]
      ]
    )

    assert {:ok, started} =
             Scoria.start_run(
               %{
                 actor_id: "policy-actor",
                 tenant_id: "policy-tenant",
                 session_id: "policy-session"
               },
               runtime: [model: "gpt-5.1"]
             )

    run = Workflows.get_run!(started.run_id)

    assert run.metadata["runtime"]["provider"] == "openai"
    assert run.metadata["runtime"]["model"] == "gpt-5.1"
    assert run.metadata["runtime"]["policy_key"] == "app-default"
    assert run.metadata["runtime"]["prompt_ref"] == "prompt://integration"
    assert run.metadata["runtime"]["prompt_version"] == "v1"
  end

  test "public runtime proves same-session new runs and exact run_id resume" do
    identity = AdoptionExample.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "executor",
        initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    eventually(fn ->
      case Runtime.get_run(started.run_id) do
        {:ok, summary} -> summary.status == "waiting_for_approval"
        _ -> false
      end
    end)

    run = Workflows.get_run_tree!(started.run_id)
    [approval | _] = Enum.reverse(run.approvals)
    {:ok, _approval} = Workflows.approve(approval.id, "approved", %{actor_id: "decision-maker"})

    assert {:ok, resumed} =
             Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

    assert resumed.run_id == started.run_id

    eventually(fn ->
      case Runtime.get_run(started.run_id) do
        {:ok, summary} -> summary.status == "completed"
        _ -> false
      end
    end)

    {:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

    assert next_run.session_id == started.session_id
    assert next_run.run_id != started.run_id

    grouped = Scoria.list_runs_for_session(AdoptionExample.shared_session_id())

    assert Enum.map(grouped, & &1.run_id) |> Enum.sort() ==
             Enum.sort([started.run_id, next_run.run_id])
  end

  test "operator-visible workflow page stays aligned with the public runtime contract" do
    {:ok, started} =
      Scoria.start_run(
        %{actor_id: "live-actor", tenant_id: "live-tenant", session_id: "live-session"},
        root_role_id: "executor",
        initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "actor_id" => "operator-integration",
        "tenant_id" => "tenant-integration"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, Scoria.RuntimeIntegrationTest.Endpoint)

    {:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))

    eventually(fn ->
      case Runtime.get_run(started.run_id) do
        {:ok, summary} -> summary.status == AdoptionExample.waiting_status()
        _ -> false
      end
    end)

    assert render(view) =~ started.run_id
    assert render(view) =~ AdoptionExample.waiting_status()

    run = Workflows.get_run_tree!(started.run_id)
    [approval | _] = Enum.reverse(run.approvals)
    {:ok, _approval} = Workflows.approve(approval.id, "approved")

    {:ok, _summary} =
      Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

    eventually(fn ->
      case Runtime.get_run(started.run_id) do
        {:ok, summary} -> summary.status == AdoptionExample.completed_status()
        _ -> false
      end
    end)

    eventually(fn -> render(view) =~ AdoptionExample.completed_status() end)
    assert render(view) =~ "step_completed"
  end
end

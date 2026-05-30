defmodule ScoriaWeb.OrchestratorLiveIntegrationTest.Router do
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

defmodule ScoriaWeb.OrchestratorLiveIntegrationTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_orch_integration_key",
    signing_salt: "orch_integration_salt"
  )

  plug(ScoriaWeb.OrchestratorLiveIntegrationTest.Router)
end

defmodule ScoriaWeb.OrchestratorLiveIntegrationTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Observe.{Buffer, OperatorBroadcast}
  alias Scoria.Observe.Adapters.ReqLLM
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Runtime

  alias Phoenix.LiveViewTest.{ClientProxy, View}

  @endpoint ScoriaWeb.OrchestratorLiveIntegrationTest.Endpoint

  defmodule Handlers do
    alias Scoria.Observe.Adapters.ReqLLM
    alias Scoria.Repo
    alias Scoria.Repo.Trace

    @span_name "req_llm_request"

    def span_name, do: @span_name

    def emit_llm_span(_step, run) do
      trace_id = Ecto.UUID.generate()

      Repo.insert!(%Trace{
        id: trace_id,
        session_id: run.session_id,
        attributes: %{"tenant_id" => run.tenant_id}
      })

      ReqLLM.handle_event(
        [:req_llm, :request, :stop],
        %{total_tokens: 42},
        %{
          model: "gpt-4",
          url: "https://api.openai.com",
          trace_id: trace_id,
          tenant_id: run.tenant_id,
          workflow_run_id: run.id,
          session_id: run.session_id
        },
        nil
      )

      {:ok, %{"span" => @span_name}}
    end

    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod", "api_key" => "super-secret-key"},
         reason: "Need approval",
         actor_id: "operator-int",
         tenant_id: run.tenant_id,
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
  end

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.OrchestratorLiveIntegrationTest.Endpoint,
      secret_key_base: "qS22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW9N",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "99887766"],
      debug_errors: true
    )

    :ok
  end

  setup do
    OperatorBroadcast.reset_trace_seen!()

    buffer_name = :"orch_int_buffer_#{System.unique_integer([:positive])}"

    buffer_pid =
      start_supervised!({Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]})

    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)
    :telemetry.detach("scoria-observe-reqllm")
    ReqLLM.attach()

    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {Handlers, :succeed},
      "llm" => {Handlers, :emit_llm_span}
    })

    start_supervised!(ScoriaWeb.OrchestratorLiveIntegrationTest.Endpoint)

    on_exit(fn ->
      OperatorBroadcast.reset_trace_seen!()
      :telemetry.detach("scoria-observe-telemetry")
      :telemetry.detach("scoria-observe-reqllm")
    end)

    {:ok, buffer_name: buffer_name, buffer_pid: buffer_pid}
  end

  test "live trace appears in orchestrator without send/2" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "orch-int-tenant-" <> unique
    session_id = "orch-int-session-" <> unique

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "tenant_id" => tenant_id,
        "actor_id" => "operator-int"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    assert {:ok, _started} =
             Runtime.start_run(
               %{
                 tenant_id: tenant_id,
                 actor_id: "operator-int",
                 session_id: session_id
               },
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "llm",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"llm" => {Handlers, :emit_llm_span}}
             )

    eventually(fn ->
      assert render(view) =~ Handlers.span_name()
    end)
  end

  test "reconnect hydrates traces from DB after missed PubSub", %{
    buffer_name: buffer_name
  } do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "orch-reconnect-tenant-" <> unique
    session_id = "orch-reconnect-session-" <> unique

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "tenant_id" => tenant_id,
        "actor_id" => "operator-int"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    render_disconnect(view)

    assert {:ok, _started} =
             Runtime.start_run(
               %{
                 tenant_id: tenant_id,
                 actor_id: "operator-int",
                 session_id: session_id
               },
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "llm",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"llm" => {Handlers, :emit_llm_span}}
             )

    force_buffer_flush(buffer_name)

    {:ok, view, _html} = render_reconnect(conn, view, "/scoria")

    eventually(fn ->
      assert render(view) =~ Handlers.span_name()
    end)
  end

  test "real approval surfaces blocking modal without send/2" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "orch-hitl-tenant-" <> unique
    session_id = "orch-hitl-session-" <> unique

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "tenant_id" => tenant_id,
        "actor_id" => "operator-int"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    assert {:ok, started} =
             Runtime.start_run(
               %{
                 tenant_id: tenant_id,
                 actor_id: "operator-int",
                 session_id: session_id
               },
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "approval",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"approval" => {Handlers, :wait_for_approval}}
             )

    eventually(fn ->
      match?({:ok, %{status: "waiting_for_approval"}}, Runtime.get_run(started.run_id))
    end)

    eventually(fn ->
      render(view) =~ "Approval Required"
    end)

    html = render(view)
    assert html =~ "publish"
    refute html =~ "super-secret-key"
  end

  test "reconnect shows modal from DB pending approval" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "orch-hitl-reconnect-" <> unique
    session_id = "orch-hitl-reconnect-session-" <> unique

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "tenant_id" => tenant_id,
        "actor_id" => "operator-int"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    render_disconnect(view)

    assert {:ok, _started} =
             Runtime.start_run(
               %{
                 tenant_id: tenant_id,
                 actor_id: "operator-int",
                 session_id: session_id
               },
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "approval",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"approval" => {Handlers, :wait_for_approval}}
             )

    {:ok, _view, html} = render_reconnect(conn, view, "/scoria")

    assert html =~ "Approval Required"
    assert html =~ "publish"
    refute html =~ "super-secret-key"
  end

  defp render_disconnect(%View{} = view) do
    {_, _, proxy_pid} = view.proxy

    if Process.alive?(proxy_pid) do
      ClientProxy.stop(proxy_pid, :shutdown)
    end

    :ok
  end

  defp render_reconnect(conn, _view, path) do
    live(conn, path)
  end

  defp force_buffer_flush(buffer_name) do
    send(buffer_name, :flush)
    Process.sleep(50)
  end
end

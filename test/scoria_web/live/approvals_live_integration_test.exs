defmodule ScoriaWeb.ApprovalsLiveIntegrationTest.Router do
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

defmodule ScoriaWeb.ApprovalsLiveIntegrationTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_approvals_integration_key",
    signing_salt: "approvals_integration_salt"
  )

  plug(ScoriaWeb.ApprovalsLiveIntegrationTest.Router)
end

defmodule ScoriaWeb.ApprovalsLiveIntegrationTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Observe.{Approval, OperatorBroadcast}
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.Workflows
  alias Scoria.Workflows.RemoteApprovalProjection

  alias Phoenix.LiveViewTest.{ClientProxy, View}

  @endpoint ScoriaWeb.ApprovalsLiveIntegrationTest.Endpoint

  defmodule Handlers do
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

    def wait_for_other_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "other_tool",
         arguments: %{"env" => "staging"},
         reason: "Needs approval",
         actor_id: "operator-int",
         tenant_id: run.tenant_id,
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
  end

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ApprovalsLiveIntegrationTest.Endpoint,
      secret_key_base: "qS22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW9N",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "99887766"],
      debug_errors: true
    )

    :ok
  end

  setup do
    OperatorBroadcast.reset_trace_seen!()

    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {Handlers, :succeed}
    })

    start_supervised!(ScoriaWeb.ApprovalsLiveIntegrationTest.Endpoint)

    on_exit(fn -> OperatorBroadcast.reset_trace_seen!() end)

    :ok
  end

  defp approvals_conn(tenant_id) do
    build_conn()
    |> Plug.Test.init_test_session(%{"tenant_id" => tenant_id, "actor_id" => "operator-int"})
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  test "focused approval surfaces blocking modal without send/2" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-hitl-tenant-" <> unique
    session_id = "approvals-hitl-session-" <> unique

    {:ok, view, _html} =
      live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

    assert {:ok, started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
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

    eventually(fn -> render(view) =~ "Approval required" end)

    html = render(view)
    assert html =~ "publish"
    refute html =~ "super-secret-key"
  end

  test "approve decision clears modal via producer path" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-approve-tenant-" <> unique
    session_id = "approvals-approve-session-" <> unique

    {:ok, view, _html} =
      live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

    assert {:ok, started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
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
      html = render(view)
      html =~ "Approval required" and html =~ "publish" and not (html =~ "super-secret-key")
    end)

    [%{id: approval_id}] = Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id})

    render_click(view, "approve", %{})

    eventually(fn ->
      html = render(view)

      not (html =~ "Approval required") and Repo.get!(Approval, approval_id).status == "approved" and
        not (html =~ "super-secret-key")
    end)

    eventually(fn ->
      match?({:ok, %{status: "completed"}}, Runtime.get_run(started.run_id))
    end)
  end

  test "dismiss closes modal without approving via producer path" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-dismiss-tenant-" <> unique
    session_id = "approvals-dismiss-session-" <> unique

    {:ok, view, _html} =
      live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

    assert {:ok, _started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
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
      html = render(view)
      html =~ "Approval required" and html =~ "publish"
    end)

    [%{id: approval_id}] = Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id})

    render_click(view, "dismiss_approval", %{})

    eventually(fn ->
      html = render(view)

      not (html =~ "Approval required") and html =~ "publish" and
        Repo.get!(Approval, approval_id).status == "pending"
    end)
  end

  test "stale approval decision surfaces friendly flash via producer path" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-stale-tenant-" <> unique
    session_id = "approvals-stale-session-" <> unique

    {:ok, view, _html} =
      live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

    assert {:ok, _started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "approval",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"approval" => {Handlers, :wait_for_approval}}
             )

    eventually(fn -> render(view) =~ "Approval required" end)

    [%{id: approval_id}] = Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id})
    projection = RemoteApprovalProjection.get_approval_lineage!(approval_id)

    assert {:ok, _} = Workflows.approve(approval_id, "approved", %{actor_id: "other-operator"})

    eventually(fn -> not (render(view) =~ "Approval required") end)

    OperatorBroadcast.hitl_request(tenant_id, projection)

    eventually(fn -> render(view) =~ "Approval required" end)

    render_click(view, "approve", %{})

    assert render(view) =~ "already decided by another operator"
  end

  test "non-focused approval highlights inbox without replacing modal via producer path" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-highlight-tenant-" <> unique
    session_a = "approvals-highlight-session-a-" <> unique
    session_b = "approvals-highlight-session-b-" <> unique

    {:ok, view, _html} = live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_a}")

    assert {:ok, _started_a} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_a},
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
      html = render(view)
      html =~ "Approval required" and html =~ "publish"
    end)

    assert {:ok, _started_b} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_b},
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "approval",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"approval" => {Handlers, :wait_for_other_approval}}
             )

    eventually(fn ->
      html = render(view)

      html =~ "Approval required" and html =~ "publish" and html =~ "other_tool" and
        html =~ ~s(data-highlight="true")
    end)
  end

  test "reject decision clears modal and keeps run paused" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-reject-tenant-" <> unique
    session_id = "approvals-reject-session-" <> unique

    {:ok, view, _html} =
      live(approvals_conn(tenant_id), "/scoria/approvals?runtime=#{session_id}")

    assert {:ok, started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
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
      html = render(view)
      html =~ "Approval required" and html =~ "publish" and not (html =~ "super-secret-key")
    end)

    [%{id: approval_id}] = Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id})

    view
    |> element("button[phx-click='open_decision_modal'][phx-value-decision='reject']")
    |> render_click()

    assert render(view) =~ "Denying records your decision"

    render_click(view, "reject", %{})

    eventually(fn ->
      html = render(view)

      not (html =~ "Approval required") and Repo.get!(Approval, approval_id).status == "rejected" and
        match?({:ok, %{status: "waiting_for_approval"}}, Runtime.get_run(started.run_id)) and
        not (html =~ "super-secret-key")
    end)
  end

  test "focused reconnect shows modal from DB pending approval" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-reconnect-tenant-" <> unique
    session_id = "approvals-reconnect-session-" <> unique

    conn = approvals_conn(tenant_id)
    focused_path = "/scoria/approvals?runtime=#{session_id}"
    {:ok, view, _html} = live(conn, focused_path)

    render_disconnect(view)

    assert {:ok, _started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
               root_role_id: "executor",
               initial_step: %{
                 sequence: 1,
                 kind: "approval",
                 role_id: "executor",
                 status: "queued"
               },
               handlers: %{"approval" => {Handlers, :wait_for_approval}}
             )

    {:ok, _view, html} = render_reconnect(conn, view, focused_path)

    assert html =~ "Approval required"
    assert html =~ "publish"
    refute html =~ "super-secret-key"
  end

  test "plain inbox highlights producer approval without auto-opening drawer" do
    unique = Integer.to_string(System.unique_integer([:positive]))
    tenant_id = "approvals-plain-tenant-" <> unique
    session_id = "approvals-plain-session-" <> unique

    {:ok, view, _html} = live(approvals_conn(tenant_id), "/scoria/approvals")

    assert {:ok, started} =
             Runtime.start_run(
               %{tenant_id: tenant_id, actor_id: "operator-int", session_id: session_id},
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
      html = render(view)

      html =~ "publish" and html =~ ~s(data-highlight="true") and
        not (html =~ "Approval required") and not (html =~ "super-secret-key")
    end)
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
end

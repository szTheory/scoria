defmodule ScoriaWeb.ApprovalsLiveTest.Router do
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

defmodule ScoriaWeb.ApprovalsLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_approvals_key",
    signing_salt: "scoria_approvals_salt"
  )

  plug(ScoriaWeb.ApprovalsLiveTest.Router)
end

defmodule ScoriaWeb.ApprovalsLiveTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime
  alias Scoria.Workflows.RemoteApprovalProjection

  @endpoint ScoriaWeb.ApprovalsLiveTest.Endpoint

  defmodule ApprovalHandlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "test_tool",
         arguments: %{"env" => "prod"},
         reason: "Requires approval",
         actor_id: "operator-live",
         tenant_id: "tenant-live",
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "approved"}}
  end

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ApprovalsLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {ApprovalHandlers, :succeed}
    })

    start_supervised!(ScoriaWeb.ApprovalsLiveTest.Endpoint)
    :ok
  end

  defp session_conn(session \\ %{"tenant_id" => "tenant-live"}) do
    build_conn()
    |> Plug.Test.init_test_session(session)
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.ApprovalsLiveTest.Endpoint)
  end

  defp pending_approval(opts \\ []) do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: Keyword.get(opts, :tenant_id, "tenant-live")
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, approval} =
      Runtime.execute_step(step.id, handler: {ApprovalHandlers, :wait_for_approval})

    %{run: run, step: step, approval: approval}
  end

  test "renders empty inbox when no approvals are pending" do
    {:ok, _view, html} = live(session_conn(), "/scoria/approvals")

    assert html =~ "Approvals"
    assert html =~ "Approval inbox"
    assert html =~ "No pending approvals."
    refute html =~ "Approval Required"
  end

  test "HITL approval request renders modal and handles approve" do
    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals"
      )

    %{run: run, step: step, approval: approval} = pending_approval()

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    html = render(view)
    assert html =~ "Approval Required"
    assert html =~ "test_tool"
    assert html =~ "Requires approval"
    assert html =~ "Approve decision"
    assert html =~ "Reject decision"
    assert html =~ "Decide later"
    assert html =~ "durably"
    assert html =~ "arguments_preview" or html =~ "prod"

    render_click(view, "approve", %{})

    eventually(fn -> not (render(view) =~ "Approval Required") end)

    updated_approval = Repo.get!(Scoria.Observe.Approval, approval.id)
    assert updated_approval.status == "approved"
    assert Workflows.get_run!(run.id).status == "completed"
    assert Workflows.get_step!(step.id).status == "completed"

    approved_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.approved",
        trace_id: "trace-#{run.id}"
      )

    assert approved_event.actor_ref == "operator-live"
    assert approved_event.redacted_refs["approval_id"] == approval.id
  end

  test "HITL approval request handles reject" do
    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals"
      )

    %{run: run, step: step, approval: approval} = pending_approval()

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    render_click(view, "reject", %{})

    eventually(fn -> Repo.get!(Scoria.Observe.Approval, approval.id).status == "rejected" end)
    assert Workflows.get_run!(run.id).status == "waiting_for_approval"
    assert Workflows.get_step!(step.id).status == "waiting_for_approval"

    rejected_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.rejected",
        trace_id: "trace-#{run.id}"
      )

    assert rejected_event.actor_ref == "operator-live"
    assert rejected_event.redacted_refs["approval_id"] == approval.id
  end

  test "HITL modal dismiss closes without approving" do
    {:ok, view, _html} = live(session_conn(), "/scoria/approvals")

    projection = %{
      id: Ecto.UUID.generate(),
      tool_name: "dismiss_tool",
      reason: "Review later",
      arguments_preview: %{"env" => "staging"},
      workflow_run_id: Ecto.UUID.generate(),
      status: "pending"
    }

    send(view.pid, {:hitl_request, projection})
    assert render(view) =~ "Approval Required"

    render_click(view, "dismiss_approval", %{})

    refute render(view) =~ "Approval Required"
  end

  test "approval_decided clears active modal" do
    {:ok, view, _html} = live(session_conn(), "/scoria/approvals")
    approval_id = Ecto.UUID.generate()

    send(view.pid, {:hitl_request, %{id: approval_id, tool_name: "sync_tool", status: "pending"}})
    assert render(view) =~ "Approval Required"

    send(view.pid, {:approval_decided, approval_id, "approved"})

    refute render(view) =~ "Approval Required"
  end

  test "select_approval opens the modal for a chosen inbox row" do
    %{approval: approval} = pending_approval()

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals")

    # The inbox auto-seeds the first pending approval; dismiss then reselect it.
    render_click(view, "dismiss_approval", %{})
    refute render(view) =~ "Approval Required"

    render_click(view, "select_approval", %{"id" => approval.id})
    assert render(view) =~ "Approval Required"
    assert render(view) =~ "test_tool"
  end

  test "stale approval decision surfaces friendly flash" do
    {:ok, view, _html} =
      live(
        session_conn(%{"actor_id" => "operator-live", "tenant_id" => "tenant-live"}),
        "/scoria/approvals"
      )

    %{approval: approval} = pending_approval()

    projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
    send(view.pid, {:hitl_request, projection})

    assert {:ok, _} = Workflows.approve(approval.id, "approved", %{actor_id: "other-operator"})
    send(view.pid, {:approval_decided, approval.id, "approved"})
    send(view.pid, {:hitl_request, projection})
    render_click(view, "approve", %{})

    assert render(view) =~ "already decided by another operator"
  end

  test "focused runtime highlights non-matching inbox approval without replacing modal" do
    session_a = "session-focus-a"

    {:ok, run_a} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: "tenant-live",
        session_id: session_a
      })

    {:ok, step_a} =
      Workflows.create_step(run_a.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval_a} =
      Workflows.mark_waiting_for_approval(run_a.id, step_a.id, %{
        tool_name: "run_a_tool",
        arguments: %{"env" => "prod"},
        reason: "Needs approval"
      })

    {:ok, run_b} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: "tenant-live",
        session_id: "session-focus-b"
      })

    {:ok, step_b} =
      Workflows.create_step(run_b.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval_b} =
      Workflows.mark_waiting_for_approval(run_b.id, step_b.id, %{
        tool_name: "run_b_tool",
        arguments: %{"env" => "staging"},
        reason: "Needs approval"
      })

    projection_a = RemoteApprovalProjection.get_approval_lineage!(approval_a.id)
    projection_b = RemoteApprovalProjection.get_approval_lineage!(approval_b.id)

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{session_a}")

    drain_pubsub_messages()

    send(view.pid, {:hitl_request, projection_a})
    assert render(view) =~ "Approval Required"
    assert render(view) =~ "run_a_tool"

    send(view.pid, {:hitl_request, projection_b})

    html = render(view)
    assert html =~ "run_a_tool"
    assert html =~ "Approval Required"
    assert html =~ "run_b_tool"
    assert html =~ "ring-2 ring-amber-400"
  end

  test "matching focus opens modal for same workflow run" do
    run_id = Ecto.UUID.generate()

    {:ok, view, _html} = live(session_conn(), "/scoria/approvals?runtime=#{run_id}")

    send(
      view.pid,
      {:hitl_request,
       %{
         id: Ecto.UUID.generate(),
         tool_name: "focused_tool",
         workflow_run_id: run_id,
         status: "pending"
       }}
    )

    assert render(view) =~ "focused_tool"
    assert render(view) =~ "Approval Required"
  end

  defp drain_pubsub_messages do
    receive do
      _ -> drain_pubsub_messages()
    after
      0 -> :ok
    end
  end
end

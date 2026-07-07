defmodule ScoriaWeb.DashboardAuthApprovalsTest.Router do
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

defmodule ScoriaWeb.DashboardAuthApprovalsTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dashboard_auth_approvals_key",
    signing_salt: "dashboard_auth_approvals_salt"
  )

  plug(ScoriaWeb.DashboardAuthApprovalsTest.Router)
end

defmodule ScoriaWeb.DashboardAuthApprovalsTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows

  @endpoint ScoriaWeb.DashboardAuthApprovalsTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DashboardAuthApprovalsTest.Endpoint,
      secret_key_base:
        "dA22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1AuthExtraKey0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "441234567"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DashboardAuthApprovalsTest.Endpoint)
    :ok
  end

  test "tenant query hints do not switch pending, decided, or deep-linked approvals" do
    fixtures = seed_cross_tenant_approvals!()

    {:ok, _view, html} =
      live(
        scoped_conn(fixtures.tenant_a, "host-actor-a"),
        "/scoria/approvals?tenant=#{fixtures.tenant_b}&approval=#{fixtures.b_pending.approval.id}"
      )

    assert html =~ fixtures.a_pending.tool_name
    refute html =~ fixtures.b_pending.tool_name
    refute html =~ "#{fixtures.b_pending.tool_name} approval"
    refute html =~ fixtures.b_pending.reason

    {:ok, _view, decided_html} =
      live(
        scoped_conn(fixtures.tenant_a, "host-actor-a"),
        "/scoria/approvals?tenant=#{fixtures.tenant_b}&scope=decided"
      )

    assert decided_html =~ fixtures.a_decided.tool_name
    refute decided_html =~ fixtures.b_decided.tool_name
  end

  test "decision actions persist tenant and actor from assigned dashboard scope" do
    unique = unique_suffix()
    tenant_a = "dashboard-auth-approval-a-#{unique}"
    tenant_b = "dashboard-auth-approval-b-#{unique}"
    actor_a = "host-actor-a-#{unique}"

    a_pending =
      seed_approval!(tenant_a,
        unique: unique,
        tool_name: "tenant-a-decision-tool-#{unique}",
        reason: "tenant A decision request #{unique}"
      )

    _b_pending =
      seed_approval!(tenant_b,
        unique: unique,
        tool_name: "tenant-b-decision-tool-#{unique}",
        reason: "tenant B decision request #{unique}"
      )

    {:ok, view, html} =
      live(
        scoped_conn(tenant_a, actor_a),
        "/scoria/approvals?tenant=#{tenant_b}&approval=#{a_pending.approval.id}"
      )

    assert html =~ "#{a_pending.tool_name} approval"

    render_click(view, "reject", %{})

    decision_event =
      eventually(fn ->
        Repo.get_by(AuditOutboxEvent,
          workflow_run_id: a_pending.run.id,
          event_type: "approval.rejected",
          trace_id: a_pending.trace_id
        )
      end)

    assert decision_event.tenant_id == tenant_a
    refute decision_event.tenant_id == tenant_b
    refute decision_event.tenant_id == "default"
    assert get_in(decision_event.metadata, ["metadata", "decision_actor_id"]) == actor_a
    assert decision_event.redacted_refs["approval_id"] == a_pending.approval.id
    assert Repo.get!(Approval, a_pending.approval.id).status == "rejected"
  end

  test "missing dashboard scope does not render pending or decided approval rows" do
    fixtures = seed_cross_tenant_approvals!()

    assert {:halt, halted_socket} =
             ScoriaWeb.DashboardScope.on_mount(
               :default,
               %{"tenant" => fixtures.tenant_a, "scope" => "decided"},
               %{},
               scope_socket()
             )

    assert halted_socket.assigns.flash["error"] ==
             "This Scoria dashboard is not available for this session."

    refute Map.has_key?(halted_socket.assigns, :approval_inbox)
    refute Map.has_key?(halted_socket.assigns, :active_approval)
    refute Map.has_key?(halted_socket.assigns, :decision_receipts)
  end

  defp scoped_conn(tenant_id, actor_id) do
    session =
      %{}
      |> maybe_put("tenant_id", tenant_id)
      |> maybe_put("actor_id", actor_id)

    build_conn()
    |> Plug.Test.init_test_session(session)
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp scope_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, flash: %{}},
      view: ScoriaWeb.ApprovalsLive.Index
    }
  end

  defp seed_cross_tenant_approvals! do
    unique = unique_suffix()
    tenant_a = "dashboard-auth-tenant-a-#{unique}"
    tenant_b = "dashboard-auth-tenant-b-#{unique}"

    %{
      tenant_a: tenant_a,
      tenant_b: tenant_b,
      a_pending:
        seed_approval!(tenant_a,
          unique: unique,
          tool_name: "tenant-a-pending-tool-#{unique}",
          reason: "tenant A pending request #{unique}"
        ),
      a_decided:
        seed_approval!(tenant_a,
          unique: unique,
          status: "approved",
          tool_name: "tenant-a-decided-tool-#{unique}",
          reason: "tenant A decided request #{unique}",
          decision_actor: "tenant-a-decider-#{unique}"
        ),
      b_pending:
        seed_approval!(tenant_b,
          unique: unique,
          tool_name: "tenant-b-pending-tool-#{unique}",
          reason: "tenant B pending request #{unique}"
        ),
      b_decided:
        seed_approval!(tenant_b,
          unique: unique,
          status: "approved",
          tool_name: "tenant-b-decided-tool-#{unique}",
          reason: "tenant B decided request #{unique}",
          decision_actor: "tenant-b-decider-#{unique}"
        )
    }
  end

  defp seed_approval!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    tool_name = Keyword.fetch!(opts, :tool_name)
    reason = Keyword.fetch!(opts, :reason)
    trace_id = "trace-#{tenant_id}-#{unique}"

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: tenant_id,
        session_id: "session-#{tenant_id}-#{unique}"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "executor",
        status: "running"
      })

    {:ok, approval} =
      Workflows.mark_waiting_for_approval(run.id, step.id, %{
        tool_name: tool_name,
        arguments: %{"tenant" => tenant_id, "unique" => unique},
        reason: reason,
        trace_id: trace_id
      })

    approval =
      case Keyword.get(opts, :status, "pending") do
        "pending" ->
          approval

        status when status in ["approved", "rejected", "expired"] ->
          {:ok, decided} =
            Workflows.approve(approval.id, status, %{
              actor_id: Keyword.get(opts, :decision_actor, "decision-actor-#{unique}")
            })

          decided
      end

    %{
      run: run,
      step: step,
      approval: approval,
      tool_name: tool_name,
      reason: reason,
      trace_id: trace_id
    }
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end

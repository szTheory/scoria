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

  alias Scoria.Connectors.{Connector, Grant, LocalTool}
  alias Scoria.Repo
  alias Scoria.Workflows

  @endpoint ScoriaWeb.WorkflowLiveTest.Endpoint

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

  test "LiveView mounts from persisted workflow records and subscribes for projection updates" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "running"
      })

    {:ok, _checkpoint} =
      Workflows.append_checkpoint(run.id, step.id, %{
        transition: "tool_started",
        status: "running",
        snapshot: %{"tool" => "fetch"}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Workflow Run"
    assert html =~ run.id
    assert html =~ "running"
    assert html =~ "tool"
  end

  test "run page renders lifecycle badges and responds to run and step updates without owning truth" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "running"
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")

    assert render(view) =~ "running"

    {:ok, _step} = Workflows.complete_step(step.id, %{"ok" => true})

    assert render(view) =~ "completed"
    assert render(view) =~ "step_completed"
  end

  test "run page renders the remote invocation evidence notebook from durable approval truth" do
    connector =
      Repo.insert!(
        Connector.changeset(%Connector{}, %{
          tenant_id: "tenant-live",
          key: "github",
          label: "GitHub",
          endpoint_url: "https://github.example/mcp",
          transport_kind: "streamable_http",
          auth_mode: "oauth_pkce",
          status: "ready",
          health_state: "healthy",
          last_refresh_status: "ok"
        })
      )

    Repo.insert!(
      Grant.changeset(%Grant{}, %{
        connector_id: connector.id,
        tenant_id: connector.tenant_id,
        subject_ref: "acct-1",
        grant_kind: "oauth",
        status: "active",
        granted_scopes: ["repo:write"],
        last_refresh_status: "ok",
        last_authenticated_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })
    )

    local_tool =
      Repo.insert!(
        LocalTool.changeset(%LocalTool{}, %{
          connector_id: connector.id,
          tenant_id: connector.tenant_id,
          display_name: "Issue Update",
          lifecycle_state: "active",
          remote_tool_name: "issues.update",
          schema_fingerprint: "sha256:issue-update",
          required_scopes: ["repo:write"],
          risk_level: "high",
          action_class: "write",
          binding_metadata: %{},
          metadata: %{}
        })
      )

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "root-actor",
        tenant_id: "tenant-live",
        session_id: "root-session"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "running"
      })

    {:ok, _approval} =
      Workflows.request_remote_approval(run.id, step.id, %{
        tool_name: "issues.update",
        arguments: %{"title" => "Rotate"},
        reason: "remote_write_approval_required",
        trace_id: "trace-workflow-live",
        blocker_kind: "remote_write",
        connector_id: connector.id,
        local_tool_id: local_tool.id,
        grant_status: "active",
        grant_subject_ref: "acct-1",
        policy_outcome: "waiting_for_approval",
        requested_scopes: ["repo:write"],
        replay_allowed: true
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "remote evidence notebook"
    assert html =~ "Identity -&gt; policy -&gt; approval -&gt; connector"
    assert html =~ "GitHub"
    assert html =~ "issues.update"
    assert html =~ "Replay blocked step"
  end

  test "can open the dataset promotion modal from a selected step" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"some" => "context"}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")

    # Send the event to open the modal
    render_click(view |> element("button[phx-click='open_promote_modal'][phx-value-step-id='#{step.id}']"))
    
    assert render(view) =~ "Promote to Dataset"
    assert render(view) =~ "Input Context (JSON)"
    assert render(view) =~ "&quot;some&quot;: &quot;context&quot;"
  end
end

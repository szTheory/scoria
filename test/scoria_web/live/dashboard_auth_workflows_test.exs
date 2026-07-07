defmodule ScoriaWeb.DashboardAuthWorkflowsTest.Router do
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

defmodule ScoriaWeb.DashboardAuthWorkflowsTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dashboard_auth_workflows_key",
    signing_salt: "dashboard_auth_workflows_salt"
  )

  plug(ScoriaWeb.DashboardAuthWorkflowsTest.Router)
end

defmodule ScoriaWeb.DashboardAuthWorkflowsTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.SRE.Incident
  alias Scoria.Workflows

  @endpoint ScoriaWeb.DashboardAuthWorkflowsTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DashboardAuthWorkflowsTest.Endpoint,
      secret_key_base:
        "dW22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1AuthWorkflowKey0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "449876543"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DashboardAuthWorkflowsTest.Endpoint)
    :ok
  end

  test "workflow index uses assigned tenant scope despite tenant query hints" do
    unique = unique_suffix()
    tenant_a = "dashboard-workflow-a-#{unique}"
    tenant_b = "dashboard-workflow-b-#{unique}"

    {:ok, run_a} =
      Workflows.create_run(%{
        root_role_id: "tenant-a-role-#{unique}",
        tenant_id: tenant_a,
        session_id: "tenant-a-workflow-marker-#{unique}"
      })

    {:ok, run_b} =
      Workflows.create_run(%{
        root_role_id: "tenant-b-role-#{unique}",
        tenant_id: tenant_b,
        session_id: "tenant-b-workflow-marker-#{unique}"
      })

    {:ok, _view, html} =
      live(scoped_conn(tenant_a), "/scoria/workflows?tenant=#{tenant_b}")

    assert html =~ "tenant-a-workflow-marker-#{unique}"
    assert html =~ run_a.id
    refute html =~ "tenant-b-workflow-marker-#{unique}"
    refute html =~ run_b.id
  end

  test "workflow detail refuses a foreign run before linked evidence is hydrated" do
    unique = unique_suffix()
    tenant_a = "dashboard-workflow-detail-a-#{unique}"
    tenant_b = "dashboard-workflow-detail-b-#{unique}"

    %{run: foreign_run, step: foreign_step} =
      seed_workflow_run!(tenant_b,
        unique: unique,
        session_id: "tenant-b-detail-session-#{unique}",
        role_id: "tenant-b-detail-step-role-#{unique}"
      )

    incident =
      seed_incident!(tenant_b, foreign_run.id,
        unique: unique,
        summary: "tenant B linked incident #{unique}"
      )

    candidate =
      seed_review_candidate!(tenant_b, foreign_run.id, foreign_step.id,
        unique: unique,
        rationale: "tenant B review candidate #{unique}"
      )

    {:ok, _view, html} =
      live(
        scoped_conn(tenant_a),
        "/scoria/workflows/#{foreign_run.id}?tenant=#{tenant_b}&review_candidate_id=#{candidate.id}"
      )

    assert html =~ "Workflow run not found"
    assert html =~ "not available for the current tenant"
    refute html =~ foreign_run.id
    refute html =~ "tenant-b-detail-session-#{unique}"
    refute html =~ "tenant-b-detail-step-role-#{unique}"
    refute html =~ "tenant B linked incident #{unique}"
    refute html =~ "/scoria/incidents/#{incident.id}"
    refute html =~ "tenant B review candidate #{unique}"
    refute html =~ "Review candidate evidence"
  end

  defp scoped_conn(tenant_id) do
    build_conn()
    |> Plug.Test.init_test_session(%{"tenant_id" => tenant_id, "actor_id" => "workflow-operator"})
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp seed_workflow_run!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    session_id = Keyword.fetch!(opts, :session_id)
    role_id = Keyword.fetch!(opts, :role_id)

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        tenant_id: tenant_id,
        session_id: session_id,
        status: "running"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: role_id,
        status: "running",
        projected_context: %{"tenant_marker" => "tenant-b-context-#{unique}"}
      })

    %{run: run, step: step}
  end

  defp seed_incident!(tenant_id, run_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    summary = Keyword.fetch!(opts, :summary)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    %Incident{}
    |> Incident.changeset(%{
      tenant_id: tenant_id,
      incident_key: "dashboard-workflow-incident-#{unique}",
      severity: "warning",
      status: "open",
      summary: summary,
      routing_class: "review",
      dedupe_key: Ecto.UUID.generate(),
      first_seen_at: now,
      last_seen_at: now,
      workflow_run_id: run_id,
      trace_id: "trace-workflow-incident-#{unique}"
    })
    |> Repo.insert!()
  end

  defp seed_review_candidate!(tenant_id, run_id, step_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    rationale = Keyword.fetch!(opts, :rationale)

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "trace-session-workflow-#{unique}",
        attributes: %{"tenant_id" => tenant_id}
      })
      |> Repo.insert()

    %OnlineScoreCandidate{}
    |> OnlineScoreCandidate.changeset(%{
      tenant_id: tenant_id,
      trace_id: trace.id,
      workflow_run_id: run_id,
      workflow_step_id: step_id,
      dedupe_key: "#{tenant_id}:#{trace.id}:workflow-detail",
      status: "needs_review",
      review_status: "pending",
      score_status: "failed",
      score_explanation: rationale,
      scorer_kind: "deterministic_rule",
      scorer_version: "workflow-auth@2026.07.07",
      sampling_metadata: %{"sample_reason" => "policy_trigger"}
    })
    |> Repo.insert!()
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end

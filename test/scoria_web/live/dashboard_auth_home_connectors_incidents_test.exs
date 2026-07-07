defmodule ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Router do
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

defmodule ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dashboard_auth_home_connectors_incidents_key",
    signing_salt: "dashboard_auth_home_connectors_incidents_salt"
  )

  plug(ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Router)
end

defmodule ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Connectors.Connector
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.{Span, Trace}
  alias Scoria.Runtime.Instance
  alias Scoria.SRE.Incident
  alias Scoria.Workflows.{Run, Step}

  @endpoint ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Endpoint,
      secret_key_base:
        "dH22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1AuthHomeConnectorsIncidentsKey",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "442020246"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Code.ensure_loaded!(Scoria.Connectors)
    start_supervised!(ScoriaWeb.DashboardAuthHomeConnectorsIncidentsTest.Endpoint)
    :ok
  end

  test "home ignores tenant query hints for trace hydration, PubSub, and review candidate deep links" do
    unique = unique_suffix()
    tenant_a = "dashboard-home-a-#{unique}"
    tenant_b = "dashboard-home-b-#{unique}"

    span_a =
      seed_trace_span!(tenant_a,
        unique: unique,
        name: "tenant A hydrated trace marker #{unique}"
      )

    span_b =
      seed_trace_span!(tenant_b,
        unique: unique,
        name: "tenant B hydrated trace marker #{unique}"
      )

    foreign_candidate =
      seed_review_candidate!(tenant_b,
        unique: unique,
        rationale: "tenant B home review candidate marker #{unique}"
      )

    {:ok, view, _html} =
      live(
        scoped_conn(tenant_a),
        "/scoria?tenant=#{tenant_b}&runtime=foreign-runtime&review_candidate_id=#{foreign_candidate.id}"
      )

    html = render_async(view)

    assert html =~ span_a.name
    refute html =~ span_b.name
    refute html =~ "tenant B home review candidate marker #{unique}"
    refute html =~ "Review candidate context"

    Phoenix.PubSub.broadcast(
      Scoria.PubSub,
      "scoria:runs:#{tenant_b}",
      {:trace_span, "tenant-b-pubsub-trace-#{unique}",
       %{id: "tenant-b-pubsub-span-#{unique}", name: "tenant B pubsub trace marker #{unique}"}}
    )

    Process.sleep(75)
    refute render(view) =~ "tenant B pubsub trace marker #{unique}"

    Phoenix.PubSub.broadcast(
      Scoria.PubSub,
      "scoria:runs:#{tenant_a}",
      {:trace_span, "tenant-a-pubsub-trace-#{unique}",
       %{id: "tenant-a-pubsub-span-#{unique}", name: "tenant A pubsub trace marker #{unique}"}}
    )

    eventually(fn -> render(view) =~ "tenant A pubsub trace marker #{unique}" end)
  end

  test "connectors use assigned tenant scope for fleet reads and runtime presence reloads" do
    unique = unique_suffix()
    tenant_a = "dashboard-connectors-a-#{unique}"
    tenant_b = "dashboard-connectors-b-#{unique}"

    connector_a =
      seed_connector!(tenant_a,
        unique: unique,
        label: "tenant A connector marker #{unique}"
      )

    connector_b =
      seed_connector!(tenant_b,
        unique: unique,
        label: "tenant B connector marker #{unique}"
      )

    {:ok, view, html} = live(scoped_conn(tenant_a), "/scoria/connectors?tenant=#{tenant_b}")

    assert html =~ connector_a.label
    refute html =~ connector_b.label

    runtime_b =
      seed_runtime_instance!(tenant_b,
        unique: unique,
        host_session_id: "tenant-b-runtime-session-#{unique}"
      )

    Phoenix.PubSub.broadcast(Scoria.PubSub, "mcp:runtimes:#{tenant_b}", %Phoenix.Socket.Broadcast{
      event: "presence_diff",
      payload: %{},
      topic: "mcp:runtimes:#{tenant_b}"
    })

    Process.sleep(75)
    refute render(view) =~ runtime_b.host_session_id

    runtime_a =
      seed_runtime_instance!(tenant_a,
        unique: unique,
        host_session_id: "tenant-a-runtime-session-#{unique}"
      )

    Phoenix.PubSub.broadcast(Scoria.PubSub, "mcp:runtimes:#{tenant_a}", %Phoenix.Socket.Broadcast{
      event: "presence_diff",
      payload: %{},
      topic: "mcp:runtimes:#{tenant_a}"
    })

    eventually(fn -> render(view) =~ runtime_a.host_session_id end)
  end

  test "incidents index and legacy run-origin hints stay inside assigned tenant scope" do
    unique = unique_suffix()
    tenant_a = "dashboard-incidents-a-#{unique}"
    tenant_b = "dashboard-incidents-b-#{unique}"
    foreign_run_id = Ecto.UUID.generate()

    incident_a =
      seed_incident!(tenant_a,
        unique: unique,
        summary: "tenant A incident marker #{unique}"
      )

    incident_b =
      seed_incident!(tenant_b,
        unique: unique,
        workflow_run_id: foreign_run_id,
        summary: "tenant B incident marker #{unique}"
      )

    {:ok, _view, html} = live(scoped_conn(tenant_a), "/scoria/incidents?tenant=#{tenant_b}")

    assert html =~ incident_a.summary
    refute html =~ incident_b.summary

    {:ok, _view, run_origin_html} =
      live(scoped_conn(tenant_a), "/scoria/incidents?tenant=#{tenant_b}&from=run:#{foreign_run_id}")

    assert run_origin_html =~ "No incident is linked to"
    refute run_origin_html =~ incident_b.summary
    refute run_origin_html =~ "/scoria/incidents/#{incident_b.id}"

    {:ok, _view, detail_html} =
      live(scoped_conn(tenant_a), "/scoria/incidents/#{incident_b.id}?tenant=#{tenant_b}")

    assert detail_html =~ "Incident not found"
    refute detail_html =~ incident_b.summary
  end

  test "missing dashboard scope halts before page-specific data assigns are populated" do
    tenant_from_query = "dashboard-missing-scope-#{unique_suffix()}"

    for {view, forbidden_keys} <- [
          {ScoriaWeb.OrchestratorLive, [:status_home, :trace_records, :tenant_id]},
          {ScoriaWeb.ConnectorsLive.Index, [:runtimes, :connector_fleet, :tenant_id]},
          {ScoriaWeb.IncidentsLive.Index, [:streams, :has_incidents, :tenant_id]},
          {ScoriaWeb.IncidentsLive.Show, [:incident, :incidents, :tenant_id]}
        ] do
      assert {:halt, halted_socket} =
               ScoriaWeb.DashboardScope.on_mount(
                 :default,
                 %{"tenant" => tenant_from_query},
                 %{},
                 scope_socket(view)
               )

      assert halted_socket.assigns.flash["error"] ==
               "This Scoria dashboard is not available for this session."

      for key <- forbidden_keys do
        refute Map.has_key?(halted_socket.assigns, key)
      end
    end
  end

  defp scoped_conn(tenant_id) do
    build_conn()
    |> Plug.Test.init_test_session(%{
      "tenant_id" => tenant_id,
      "actor_id" => "home-connectors-incidents-operator"
    })
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp seed_trace_span!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    name = Keyword.fetch!(opts, :name)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "trace-session-#{tenant_id}-#{unique}",
        attributes: %{"tenant_id" => tenant_id}
      })
      |> Repo.insert()

    Repo.insert!(
      Span.changeset(%Span{}, %{
        trace_id: trace.id,
        name: name,
        span_kind: "LLM",
        status_code: "OK",
        start_time: now,
        end_time: now,
        attributes: %{
          "tenant_id" => tenant_id,
          "session_id" => trace.session_id
        }
      })
    )
  end

  defp seed_review_candidate!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    rationale = Keyword.fetch!(opts, :rationale)

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "home-review-session-#{unique}",
        attributes: %{"tenant_id" => tenant_id}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: tenant_id,
        session_id: trace.session_id,
        status: "running",
        execution_mode: "live"
      })
      |> Repo.insert()

    {:ok, step} =
      %Step{}
      |> Step.changeset(%{
        run_id: run.id,
        sequence: 1,
        kind: "llm_call",
        role_id: "assistant",
        status: "completed"
      })
      |> Repo.insert()

    Repo.insert!(
      OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, %{
        tenant_id: tenant_id,
        trace_id: trace.id,
        workflow_run_id: run.id,
        workflow_step_id: step.id,
        dedupe_key: "#{tenant_id}:#{trace.id}:#{unique}:home",
        status: "needs_review",
        review_status: "pending",
        score_status: "failed",
        score_explanation: rationale,
        scorer_kind: "deterministic_rule",
        scorer_version: "dashboard-auth-home@2026.07.07",
        sampling_metadata: %{"sample_reason" => "policy_trigger"}
      })
    )
  end

  defp seed_connector!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    label = Keyword.fetch!(opts, :label)

    Repo.insert!(
      Connector.changeset(%Connector{}, %{
        tenant_id: tenant_id,
        key: "#{tenant_id}-connector-#{unique}",
        label: label,
        endpoint_url: "https://example.com/#{unique}/mcp",
        transport_kind: "sse",
        auth_mode: "none",
        status: "ready",
        health_state: "healthy",
        last_refresh_status: "ok"
      })
    )
  end

  defp seed_runtime_instance!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    host_session_id = Keyword.fetch!(opts, :host_session_id)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert!(%Instance{
      tenant_id: tenant_id,
      host_session_id: host_session_id,
      current_run_id: nil,
      first_seen_at: now,
      last_seen_at: now,
      transport_kind: "sse",
      terminal_offline_reason: "Runtime marker #{unique}"
    })
  end

  defp seed_incident!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    summary = Keyword.fetch!(opts, :summary)
    workflow_run_id = Keyword.get(opts, :workflow_run_id, Ecto.UUID.generate())
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert!(
      Incident.changeset(%Incident{}, %{
        tenant_id: tenant_id,
        incident_key: "dashboard-incident-#{tenant_id}-#{unique}",
        severity: "warning",
        status: "open",
        summary: summary,
        routing_class: "review",
        dedupe_key: Ecto.UUID.generate(),
        first_seen_at: now,
        last_seen_at: now,
        workflow_run_id: workflow_run_id,
        trace_id: "trace-dashboard-incident-#{unique}"
      })
    )
  end

  defp scope_socket(view) do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}, flash: %{}},
      view: view
    }
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end

defmodule ScoriaWeb.IncidentsLiveTest.Router do
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

defmodule ScoriaWeb.IncidentsLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_incidents_key",
    signing_salt: "scoria_incidents_salt"
  )

  plug(ScoriaWeb.IncidentsLiveTest.Router)
end

defmodule ScoriaWeb.IncidentsLiveTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.SRE.Incident

  @endpoint ScoriaWeb.IncidentsLiveTest.Endpoint
  @tenant "tenant-incidents"

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.IncidentsLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "446655443"]
    )

    :ok
  end

  setup do
    start_supervised!(@endpoint)
    :ok
  end

  defp session_conn do
    build_conn()
    |> Plug.Test.init_test_session(%{"tenant_id" => @tenant})
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp seed_incident!(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    defaults = %{
      tenant_id: @tenant,
      severity: "warning",
      status: "open",
      routing_class: "review",
      dedupe_key: Ecto.UUID.generate(),
      first_seen_at: now,
      last_seen_at: now,
      workflow_run_id: Ecto.UUID.generate()
    }

    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()

    incident
  end

  test "renders empty state when the tenant has no incidents" do
    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert html =~ "Incidents"
    assert html =~ "No incidents"
    refute html =~ "Tenant incidents"
  end

  test "lists tenant incidents and renders evidence for the newest by default" do
    _older =
      seed_incident!(%{
        incident_key: "inc-review",
        summary: "CI baseline dip on helpfulness",
        trace_id: "trace-review",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    _newer =
      seed_incident!(%{
        incident_key: "inc-page",
        summary: "Fast burn budget incident",
        severity: "critical",
        routing_class: "page",
        trace_id: "trace-page",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert html =~ "Tenant incidents"
    assert html =~ "CI baseline dip on helpfulness"
    assert html =~ "Fast burn budget incident"
    assert html =~ "Open incidents"
    # The notebook renders for the newest incident's trace.
    assert html =~ "Trace-first incident notebook"
    assert html =~ "trace-page"
  end

  test "select_incident swaps the evidence to the chosen incident" do
    review =
      seed_incident!(%{
        incident_key: "inc-review",
        summary: "CI baseline dip on helpfulness",
        trace_id: "trace-review",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    _page =
      seed_incident!(%{
        incident_key: "inc-page",
        summary: "Fast burn budget incident",
        severity: "critical",
        routing_class: "page",
        trace_id: "trace-page",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, view, html} = live(session_conn(), "/scoria/incidents")
    assert html =~ "trace-page"

    html = render_click(view, "select_incident", %{"id" => review.id})
    assert html =~ "trace-review"
  end
end

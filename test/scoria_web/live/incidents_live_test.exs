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
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
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
    assert html =~ "No open incidents"

    assert html =~
             "Runtime failures, breaker trips, and delivery issues will appear here with links back to the affected run."

    refute html =~ "Tenant incidents"
  end

  test "lists tenant incidents with actionable triage summary and no inline evidence" do
    older =
      seed_incident!(%{
        incident_key: "inc-review",
        summary: "CI baseline dip on helpfulness",
        trace_id: "trace-review",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    newer =
      seed_incident!(%{
        incident_key: "inc-page",
        summary: "Fast burn budget incident",
        severity: "critical",
        routing_class: "page",
        trace_id: "trace-page",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert html =~ "Tenant triage"
    assert html =~ "2 open incidents across 2 incident records"
    assert html =~ "Open paging incident"
    assert triage_hrefs(html) == ["/scoria/incidents/#{newer.id}"]

    assert html =~ "Incident history"
    assert html =~ "2 records, 2 open"
    assert html =~ "CI baseline dip on helpfulness"
    assert html =~ "Fast burn budget incident"
    assert html =~ ~s(href="/scoria/incidents/#{newer.id}")
    assert html =~ ~s(href="/scoria/incidents/#{older.id}")
    refute html =~ "Trace-first incident evidence"

    assert [] =
             html
             |> Floki.parse_document!()
             |> Floki.find(".scoria-metric")

    document = Floki.parse_document!(html)

    assert [_] = Floki.find(document, ".scoria-incident-index__triage.scoria-page-section")
    assert [_] = Floki.find(document, ".scoria-incident-index__history.scoria-page-section")
    assert [] = Floki.find(document, ".scoria-incident-index__triage.scoria-panel")
    assert [] = Floki.find(document, ".scoria-incident-index__history.scoria-panel")
    assert [] = Floki.find(document, ".scoria-incident-index__triage .scoria-incident-signal")
    assert 3 = document |> Floki.find(".scoria-incident-index__triage .scoria-signal") |> length()
  end

  test "triage summary prioritizes open paging incidents over newer review incidents" do
    page =
      seed_incident!(%{
        incident_key: "inc-page-priority",
        summary: "Older paging incident",
        severity: "critical",
        routing_class: "page",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    review =
      seed_incident!(%{
        incident_key: "inc-review-newer",
        summary: "Newer review incident",
        routing_class: "review",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert review.id != page.id
    assert html =~ "Open paging incident"
    assert triage_hrefs(html) == ["/scoria/incidents/#{page.id}"]
  end

  test "triage summary opens newest review incident when no paging incident is open" do
    older =
      seed_incident!(%{
        incident_key: "inc-review-older",
        summary: "Older review incident",
        routing_class: "review",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    newer =
      seed_incident!(%{
        incident_key: "inc-review-newest",
        summary: "Newest review incident",
        routing_class: "review",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert older.id != newer.id
    assert html =~ "Open review incident"
    assert triage_hrefs(html) == ["/scoria/incidents/#{newer.id}"]
  end

  test "triage summary keeps resolved-only incidents as history without an action CTA" do
    resolved =
      seed_incident!(%{
        incident_key: "inc-resolved-history",
        summary: "Resolved billing incident",
        severity: "critical",
        routing_class: "page",
        status: "resolved",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents")

    assert html =~ "No open incidents"
    assert html =~ "1 record, 0 open, 1 no longer open"
    assert html =~ ~s(href="/scoria/incidents/#{resolved.id}")
    assert triage_hrefs(html) == []
    refute html =~ "Open paging incident"
    refute html =~ "Open review incident"
  end

  test "incident detail route renders evidence for the chosen incident" do
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

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{review.id}")
    assert html =~ "trace-review"
    assert html =~ "Trace-first incident evidence"
    assert html =~ "CI baseline dip on helpfulness"
  end

  test "incident severity and status badges include visible text" do
    incident =
      seed_incident!(%{
        incident_key: "inc-visible-state",
        summary: "Pager state needs text",
        severity: "critical",
        routing_class: "page",
        status: "open",
        trace_id: "trace-visible-state"
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{incident.id}")

    badge_text =
      html
      |> Floki.parse_document!()
      |> Floki.find(".scoria-badge")
      |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

    assert "critical" in badge_text
    assert "Open" in badge_text
  end

  test "selected incident detail queue exposes explicit current state" do
    selected =
      seed_incident!(%{
        incident_key: "inc-selected-state",
        summary: "Selected state is explicit",
        trace_id: "trace-selected-state",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    _older =
      seed_incident!(%{
        incident_key: "inc-not-selected",
        summary: "Older incident",
        trace_id: "trace-not-selected",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{selected.id}")

    assert html =~ ~s(href="/scoria/incidents/#{selected.id}")
    assert html =~ ~s(aria-current="page")
    assert html =~ "scoria-selectable-card--selected"
    refute html =~ "Selected incident:"
  end

  test "selected incident renders context-preserving run and trace next-step links" do
    incident =
      seed_incident!(%{
        incident_key: "inc-threading",
        summary: "Trace needs operator review",
        trace_id: "trace-threading"
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{incident.id}")
    decoded_html = URI.decode_www_form(html)

    assert html =~ "Open run"
    assert html =~ "Open trace at failing span"

    assert decoded_html =~
             "/scoria/workflows/#{incident.workflow_run_id}?from=incident:#{incident.id}"

    assert decoded_html =~ "/scoria?from=incident:#{incident.id}#traces-trace-threading"
  end

  test "legacy incident query redirects to the routed detail page" do
    incident =
      seed_incident!(%{
        incident_key: "inc-query",
        summary: "Query selected incident",
        trace_id: "trace-query"
      })

    expected_path = "/scoria/incidents/#{incident.id}"

    assert {:error, {:live_redirect, %{to: ^expected_path}}} =
             live(session_conn(), "/scoria/incidents?incident=#{incident.id}")
  end

  test "legacy run origin query opens the newest linked incident" do
    run_id = Ecto.UUID.generate()

    older =
      seed_incident!(%{
        incident_key: "inc-run-older",
        summary: "Older linked incident",
        workflow_run_id: run_id,
        trace_id: "trace-run-older",
        last_seen_at: ~U[2026-05-10 12:00:00.000000Z]
      })

    newer =
      seed_incident!(%{
        incident_key: "inc-run-newer",
        summary: "Newer linked incident",
        workflow_run_id: run_id,
        trace_id: "trace-run-newer",
        last_seen_at: ~U[2026-05-11 12:00:00.000000Z]
      })

    assert older.id != newer.id

    expected_path =
      "/scoria/incidents/#{newer.id}?#{URI.encode_query([{"from", "run:#{run_id}"}])}"

    assert {:error, {:live_redirect, %{to: ^expected_path}}} =
             live(session_conn(), "/scoria/incidents?from=run:#{run_id}")
  end

  test "incident detail refuses cross-tenant incidents" do
    other =
      seed_incident!(%{
        tenant_id: "other-tenant",
        incident_key: "inc-other-tenant",
        summary: "Other tenant incident",
        trace_id: "trace-other-tenant"
      })

    {:ok, _view, html} = live(session_conn(), "/scoria/incidents/#{other.id}")

    assert html =~ "Incident not found"
    refute html =~ "Other tenant incident"
  end

  defp triage_hrefs(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find(".scoria-incident-index__triage a")
    |> Floki.attribute("href")
  end
end

defmodule ScoriaWeb.ConnectorsLiveTest.Router do
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

defmodule ScoriaWeb.ConnectorsLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_connectors_key",
    signing_salt: "scoria_connectors_salt"
  )

  plug(ScoriaWeb.ConnectorsLiveTest.Router)
end

defmodule ScoriaWeb.ConnectorsLiveTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Repo
  alias Scoria.Runtime.Instance
  alias Scoria.Workflows

  @endpoint ScoriaWeb.ConnectorsLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ConnectorsLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.ConnectorsLiveTest.Endpoint)
    :ok
  end

  defp session_conn do
    build_conn()
    |> Plug.Test.init_test_session(%{"tenant_id" => "tenant-live"})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.ConnectorsLiveTest.Endpoint)
  end

  test "renders fleet empty states when nothing is connected" do
    {:ok, _view, html} = live(session_conn(), "/scoria/connectors")

    assert html =~ "Connectors"
    assert html =~ "Runtime posture"
    assert html =~ "Connector posture"
    assert html =~ "No runtimes connected"
    assert html =~ "No connectors registered"
  end

  test "runtime posture lists instances and the drawer surfaces detail" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "assistant",
        tenant_id: "tenant-live",
        session_id: "session-runtime",
        status: "completed",
        execution_mode: "live",
        metadata: %{
          "runtime" => %{
            "semantic_cache" => %{
              "lookup_status" => "bypass",
              "eligibility_status" => "bypass",
              "eligibility_reason_code" => "approval_required",
              "lane_key" => "account_faq",
              "scope_kind" => "tenant_shared",
              "scope_reason" => "lane_default"
            }
          }
        }
      })

    active_instance =
      Repo.insert!(%Instance{
        tenant_id: "tenant-live",
        host_session_id: "session-runtime",
        current_run_id: run.id,
        first_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        transport_kind: "websocket"
      })

    offline_instance =
      Repo.insert!(%Instance{
        tenant_id: "tenant-live",
        host_session_id: "session-empty-runtime",
        current_run_id: nil,
        first_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        transport_kind: "sse",
        terminal_offline_reason: "Terminal exited"
      })

    {:ok, view, html} = live(session_conn(), "/scoria/connectors")

    refute html =~ "No runtimes connected"

    html =
      view
      |> element("button[phx-click='open_runtime_drawer'][phx-value-id='#{offline_instance.id}']")
      |> render_click()

    assert html =~ "Terminal exited"
    refute html =~ "lookup_status"

    html =
      view
      |> element("button[phx-click='open_runtime_drawer'][phx-value-id='#{active_instance.id}']")
      |> render_click()

    assert html =~ "lookup_status"
    assert html =~ "bypass"
    assert html =~ "approval_required"

    html = render_click(view, "close_runtime_drawer", %{})
    refute html =~ "lookup_status"
  end
end

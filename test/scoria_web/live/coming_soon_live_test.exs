defmodule ScoriaWeb.ComingSoonLiveTest.Router do
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

defmodule ScoriaWeb.ComingSoonLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_coming_soon_key",
    signing_salt: "coming_soon_salt"
  )

  plug(ScoriaWeb.ComingSoonLiveTest.Router)
end

defmodule ScoriaWeb.ComingSoonLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.ComingSoonLiveTest.Endpoint

  @stub_slugs [
    "replay-playground",
    "cost-ledger",
    "feedback-inbox",
    "mcp-gateway",
    "tool-registry"
  ]

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ComingSoonLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/zK6N2e7jW1",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.ComingSoonLiveTest.Endpoint)
    :ok
  end

  test "allowlisted stubs render honest coming-soon pages" do
    for slug <- @stub_slugs do
      {:ok, _view, html} = live(test_conn(), "/scoria/coming/#{slug}")

      assert html =~ "Soon"
      assert html =~ "What works today"
      assert html =~ "Track progress"
      refute html =~ "Dataset Builder"

      downcased =
        html
        |> String.split(~s(<main class="scoria-main">))
        |> List.last()
        |> String.split("</main>")
        |> hd()
        |> String.downcase()

      refute downcased =~ "chart"
      refute downcased =~ "sparkline"
      refute downcased =~ "sample row"
      refute downcased =~ "fake"
      refute downcased =~ "skeleton"
    end
  end

  test "cost ledger and replay playground use approved future-tense copy" do
    {:ok, _view, cost_html} = live(test_conn(), "/scoria/coming/cost-ledger")

    assert cost_html =~
             "Cost Ledger will reconcile model spend per run, tenant, and prompt version"

    {:ok, _view, replay_html} = live(test_conn(), "/scoria/coming/replay-playground")

    assert replay_html =~
             "Replay Playground will let you branch a run from any checkpoint"
  end

  test "unknown stub slug does not echo user-controlled labels" do
    {:ok, _view, html} = live(test_conn(), "/scoria/coming/not-real")

    assert html =~ "Capability not found. Choose a screen from the dashboard navigation."
    assert html =~ "Home"
    refute html =~ "not-real"
    refute html =~ "Not Real"
  end

  defp test_conn do
    build_conn()
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.ComingSoonLiveTest.Endpoint)
  end
end

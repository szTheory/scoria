defmodule ScoriaWeb.DatasetLive.IndexTest.Router do
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

defmodule ScoriaWeb.DatasetLive.IndexTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dataset_live_index_key",
    signing_salt: "dataset_live_index_salt"
  )

  plug(ScoriaWeb.DatasetLive.IndexTest.Router)
end

defmodule ScoriaWeb.DatasetLive.IndexTest do
  use Scoria.EvalCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval

  @endpoint ScoriaWeb.DatasetLive.IndexTest.Endpoint
  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DatasetLive.IndexTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DatasetLive.IndexTest.Endpoint)
    :ok
  end

  test "/scoria/datasets renders the Dataset Builder heading and empty state" do
    {:ok, _view, html} = live(test_conn(), "/scoria/datasets")

    assert html =~ "Dataset Builder"
    assert html =~ "Curate production traces into eval datasets and baseline approval requests."
    assert html =~ "No datasets yet"
    assert html =~ "Promote a flagged trace or workflow source to start a regression dataset."
  end

  test "/scoria/datasets renders real open and sealed dataset rows" do
    {:ok, open_dataset} =
      Eval.create_dataset(%{
        name: "Draft Regression QA",
        version: "1",
        items: [
          %{
            input: %{"prompt" => "summarize"},
            expected_output: %{"answer" => "short"},
            metadata: %{
              "promoted_from_workflow" => true,
              "workflow_run_id" => "run-open-123"
            }
          }
        ]
      })

    {:ok, sealed_dataset} =
      Eval.create_dataset(%{
        name: "Release Baseline QA",
        version: "7",
        items: [
          %{
            input: %{"prompt" => "classify"},
            expected_output: %{"answer" => "approved"},
            metadata: %{
              "promoted_from_review" => true,
              "review_candidate_id" => "review-456"
            }
          }
        ]
      })

    {:ok, _sealed_dataset} = Eval.seal_dataset(sealed_dataset)

    {:ok, _view, html} = live(test_conn(), "/scoria/datasets")

    assert html =~ ~s(id="datasets")
    assert html =~ "Dataset"
    assert html =~ "State"
    assert html =~ "Items"
    assert html =~ "Last promoted"
    assert html =~ "Source"
    assert html =~ "Action"
    assert html =~ open_dataset.name
    assert html =~ sealed_dataset.name
    assert html =~ "Open"
    assert html =~ "Sealed"
    assert html =~ "1"
    assert html =~ "Workflow"
    assert html =~ "Review"
  end

  test "Dataset Builder LiveView has no raw palette classes" do
    path = "lib/scoria_web/live/dataset_live/index.ex"

    assert File.exists?(path)
    assert Regex.scan(@palette_regex, File.read!(path)) == []
  end

  defp test_conn do
    build_conn()
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.DatasetLive.IndexTest.Endpoint)
  end
end

defmodule ScoriaWeb.EvalSpecLive.IndexTest.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
  end
end

defmodule ScoriaWeb.EvalSpecLive.IndexTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  )

  plug(ScoriaWeb.EvalSpecLive.IndexTest.Router)
end

defmodule ScoriaWeb.EvalSpecLive.IndexTest do
  use Scoria.EvalCase, async: false
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.EvalSpecLive.IndexTest.Endpoint

  alias Scoria.Eval

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.EvalSpecLive.IndexTest.Endpoint)
    :ok
  end

  test "renders eval specs and handles editing" do
    {:ok, dataset} = Scoria.Eval.create_dataset(%{name: "Test Dataset", state: :sealed})

    # Create an initial EvalSpec
    {:ok, spec} =
      Scoria.Eval.create_eval_spec(%{
        name: "Helpfulness",
        description: "How helpful is the response?",
        dataset_id: dataset.id,
        dataset_version: dataset.version,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_entity_id: Ecto.UUID.generate(),
          prompt_template_id: Ecto.UUID.generate(),
          prompt_version: 1
        },
        scorers: [
          %{
            metric_key: "accuracy",
            scorer_kind: :llm_judge,
            judge_prompt_template_id: Ecto.UUID.generate(),
            judge_prompt_version: 1,
            judge_provider: "openai",
            judge_model: "gpt-4o-mini",
            weight: 1.0
          }
        ],
        threshold_policy: %{
          pass_rate_gte: 0.8,
          mean_score_gte: 0.8,
          max_latency_ms: 100
        }
      })

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint)

    {:ok, view, html} = live_isolated(conn, ScoriaWeb.EvalSpecLive.Index)

    # Initial render should list the spec
    assert html =~ "Evaluation Rubrics"
    assert html =~ "Helpfulness"
    assert html =~ spec.description

    # Click edit
    html = render_click(view, "edit", %{"id" => spec.id})
    assert html =~ "Edit Rubric: Helpfulness"

    # Submit form
    html =
      render_submit(view, "save", %{
        "eval_spec" => %{
          "name" => "Helpfulness V2",
          "description" => "Updated description"
        }
      })

    # Form disappears and we see updated list
    refute html =~ "Edit Rubric:"
    assert html =~ "Helpfulness V2"
    assert html =~ "Updated description"

    # Verify DB has new version
    specs = Eval.list_eval_specs()
    assert length(specs) == 1
    new_spec = hd(specs)
    assert new_spec.name == "Helpfulness V2"
    assert new_spec.version == 2
    assert new_spec.entity_id == spec.entity_id
  end
end

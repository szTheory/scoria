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
  alias Scoria.PromptRegistry
  alias Scoria.Workflows

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
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

  test "renders an empty state when no eval specs exist" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint)

    {:ok, _view, html} = live_isolated(conn, ScoriaWeb.EvalSpecLive.Index)

    assert html =~ "No evaluation rubrics yet"
    refute html =~ "<tbody>"
  end

  test "renders exact empty state copy when no eval runs exist" do
    {:ok, dataset} = Scoria.Eval.create_dataset(%{name: "Empty Run Dataset", state: :sealed})

    {:ok, _spec} =
      Scoria.Eval.create_eval_spec(%{
        name: "Empty Run Spec",
        description: "No runs have executed yet",
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

    {:ok, _view, html} = live_isolated(conn, ScoriaWeb.EvalSpecLive.Index)

    assert html =~ "No eval runs yet"

    assert html =~
             "Promote a production trace to a dataset, then run an eval to compare prompt behavior against a baseline."
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

  test "renders eval result links to prompt release and regressed source runs" do
    {:ok, prompt} =
      PromptRegistry.create_draft_template(%{
        system_message: "Eval result system",
        user_template: "Eval result user"
      })

    {:ok, dataset} =
      Scoria.Eval.create_dataset(%{
        name: "Regression Dataset",
        items: [
          %{
            input: %{"question" => "ready?"},
            expected_output: %{"answer" => "ready"}
          }
        ]
      })

    {:ok, dataset} = Scoria.Eval.seal_dataset(dataset)

    [dataset_item] = Eval.list_dataset_items(dataset.id)

    {:ok, spec} =
      Scoria.Eval.create_eval_spec(%{
        name: "Regression Spec",
        description: "Finds quality regressions",
        dataset_id: dataset.id,
        dataset_version: dataset.version,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_entity_id: prompt.entity_id,
          prompt_template_id: prompt.id,
          prompt_version: prompt.version
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

    {:ok, source_run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, eval_run} =
      Eval.create_eval_run(%{
        eval_spec_id: spec.id,
        runner_mode: :offline_replay,
        prompt_template_id: prompt.id,
        prompt_version: prompt.version
      })

    {:ok, _eval_run, _scores} =
      Eval.record_eval_scores(eval_run, [
        %{
          dataset_item_id: dataset_item.id,
          scorer_kind: "llm_judge",
          status: "failed",
          score: 0.2,
          explanation: "Regression found",
          evidence_refs: %{"workflow_run_id" => source_run.id}
        }
      ])

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.EvalSpecLive.IndexTest.Endpoint)

    {:ok, _view, html} = live_isolated(conn, ScoriaWeb.EvalSpecLive.Index)
    decoded_html = URI.decode_www_form(html)
    eval_html = eval_workbench_html(html)
    eval_html_downcase = String.downcase(eval_html)

    assert html =~ "Eval results"
    assert html =~ "Open prompt release"
    assert html =~ "Open regressed runs"
    assert eval_html =~ ~s(<table class="scoria-table)
    assert eval_html =~ "scoria-badge"
    assert eval_html =~ "Running"
    assert decoded_html =~ "/prompts/#{prompt.id}/release?from=eval:#{eval_run.id}"
    assert decoded_html =~ "/workflows/#{source_run.id}?from=eval:#{eval_run.id}"

    refute eval_html_downcase =~ "stepper"
    refute eval_html_downcase =~ "wizard"
    refute eval_html_downcase =~ "playground"
    refute eval_html_downcase =~ "current step"
    refute eval_html_downcase =~ "experiment"
    refute eval_html_downcase =~ "chart"
  end

  defp eval_workbench_html(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find(".eval-spec-index")
    |> Floki.raw_html()
  end
end

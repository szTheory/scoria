defmodule ScoriaWeb.DashboardAuthQualityDataTest.Router do
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

defmodule ScoriaWeb.DashboardAuthQualityDataTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_dashboard_auth_quality_data_key",
    signing_salt: "dashboard_auth_quality_data_salt"
  )

  plug(ScoriaWeb.DashboardAuthQualityDataTest.Router)
end

defmodule ScoriaWeb.DashboardAuthQualityDataTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows.{Checkpoint, Event, Run, Step}

  @endpoint ScoriaWeb.DashboardAuthQualityDataTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DashboardAuthQualityDataTest.Endpoint,
      secret_key_base:
        "dQ22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1AuthQualityDataKey0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "445551234"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DashboardAuthQualityDataTest.Endpoint)
    :ok
  end

  test "review queue ignores tenant query hints and excludes foreign review candidates" do
    unique = unique_suffix()
    tenant_a = "dashboard-quality-review-a-#{unique}"
    tenant_b = "dashboard-quality-review-b-#{unique}"

    candidate_a =
      seed_review_candidate!(tenant_a,
        unique: unique,
        rationale: "tenant A review evidence #{unique}"
      )

    candidate_b =
      seed_review_candidate!(tenant_b,
        unique: unique,
        rationale: "tenant B review evidence #{unique}"
      )

    {:ok, _view, html} =
      live(
        scoped_conn(tenant_a),
        "/scoria/reviews?tenant=#{tenant_b}&review_status=pending&severity=low_quality&promotion_state="
      )

    assert html =~ candidate_a.score_explanation
    assert html =~ candidate_a.id
    refute html =~ candidate_b.score_explanation
    refute html =~ candidate_b.id
  end

  test "eval workbench lists tenant-owned eval runs while keeping eval specs global" do
    unique = unique_suffix()
    tenant_a = "dashboard-quality-eval-a-#{unique}"
    tenant_b = "dashboard-quality-eval-b-#{unique}"

    %{eval_run: eval_run_a, source_run: source_run_a} =
      seed_eval_run!(tenant_a,
        unique: unique,
        spec_name: "Global quality rubric #{unique}",
        score_explanation: "tenant A score evidence #{unique}"
      )

    %{eval_run: eval_run_b, source_run: source_run_b} =
      seed_eval_run!(tenant_b,
        unique: unique,
        spec_name: "Tenant B global rubric #{unique}",
        score_explanation: "tenant B score evidence #{unique}"
      )

    {:ok, _view, html} =
      live(scoped_conn(tenant_a), "/scoria/eval_specs?tenant=#{tenant_b}")

    decoded_html = URI.decode_www_form(html)

    assert html =~ "Global quality rubric #{unique}"
    assert html =~ "Tenant B global rubric #{unique}"
    assert html =~ eval_run_a.id
    assert decoded_html =~ source_run_a.id
    refute html =~ eval_run_b.id
    refute decoded_html =~ source_run_b.id
  end

  test "dataset builder refuses foreign review and workflow promotion hints" do
    unique = unique_suffix()
    tenant_a = "dashboard-quality-dataset-a-#{unique}"
    tenant_b = "dashboard-quality-dataset-b-#{unique}"

    foreign_candidate =
      seed_review_candidate!(tenant_b,
        unique: unique,
        rationale: "tenant B dataset review evidence #{unique}"
      )

    {:ok, _view, review_html} =
      live(
        scoped_conn(tenant_a),
        "/scoria/datasets?tenant=#{tenant_b}&promote=review&review_candidate_id=#{foreign_candidate.id}"
      )

    assert review_html =~ "Promotion source not found"
    refute review_html =~ "tenant B dataset review evidence #{unique}"
    refute review_html =~ ~s(id="dataset-promote-drawer")

    %{run: foreign_run, step: foreign_step} =
      seed_workflow_promotion!(tenant_b,
        unique: unique,
        replay_output: "tenant B replay output evidence #{unique}"
      )

    {:ok, _view, workflow_html} =
      live(
        scoped_conn(tenant_a),
        "/scoria/datasets?tenant=#{tenant_b}&promote=workflow&run_id=#{foreign_run.id}&step_id=#{foreign_step.id}&source_variant=replay"
      )

    assert workflow_html =~ "Promotion source not found"
    refute workflow_html =~ "tenant B replay output evidence #{unique}"
    refute workflow_html =~ ~s(id="dataset-promote-drawer")
  end

  defp scoped_conn(tenant_id) do
    build_conn()
    |> Plug.Test.init_test_session(%{
      "tenant_id" => tenant_id,
      "actor_id" => "quality-data-operator"
    })
    |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)
  end

  defp seed_eval_run!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    spec_name = Keyword.fetch!(opts, :spec_name)
    score_explanation = Keyword.fetch!(opts, :score_explanation)

    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "Quality dataset #{tenant_id} #{unique}",
        version: "1",
        items: [
          %{
            input: %{"question" => "ready?"},
            expected_output: %{"answer" => "ready"}
          }
        ]
      })

    {:ok, dataset} = Eval.seal_dataset(dataset)
    [dataset_item] = Eval.list_dataset_items(dataset.id)

    prompt_template_id = Ecto.UUID.generate()

    {:ok, spec} =
      Eval.create_eval_spec(%{
        name: spec_name,
        description: "Global catalog metadata for #{unique}",
        dataset_id: dataset.id,
        dataset_version: dataset.version,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_entity_id: Ecto.UUID.generate(),
          prompt_template_id: prompt_template_id,
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

    source_run =
      Repo.insert!(
        Run.changeset(%Run{}, %{
          root_role_id: "eval-source",
          tenant_id: tenant_id,
          session_id: "eval-source-session-#{unique}",
          status: "completed"
        })
      )

    {:ok, eval_run} =
      Eval.create_eval_run(%{
        eval_spec_id: spec.id,
        runner_mode: :offline_replay,
        tenant_id: tenant_id,
        status: "completed",
        prompt_template_id: prompt_template_id,
        prompt_version: 1
      })

    {:ok, eval_run, _scores} =
      Eval.record_eval_scores(eval_run, [
        %{
          dataset_item_id: dataset_item.id,
          scorer_kind: "llm_judge",
          status: "failed",
          score: 0.2,
          explanation: score_explanation,
          evidence_refs: %{"workflow_run_id" => source_run.id}
        }
      ])

    %{eval_run: eval_run, source_run: source_run}
  end

  defp seed_review_candidate!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    rationale = Keyword.fetch!(opts, :rationale)

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "quality-review-session-#{unique}",
        attributes: %{"tenant_id" => tenant_id}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        actor_id: "operator-review",
        tenant_id: tenant_id,
        session_id: trace.session_id,
        status: "running",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate()
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
        dedupe_key: "#{tenant_id}:#{trace.id}:#{unique}:quality-data",
        status: "needs_review",
        review_status: "pending",
        score: 0.2,
        score_status: "failed",
        score_explanation: rationale,
        scorer_kind: "deterministic_rule",
        scorer_version: "dashboard-auth@2026.07.07",
        sampling_metadata: %{"sample_reason" => "production_sample"},
        evidence_refs: %{"trace_id" => trace.id},
        promotion_snapshot: %{
          "source_variant" => "replay",
          "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "review"}},
          "replay_reason_code" => "historical_stub"
        }
      })
    )
  end

  defp seed_workflow_promotion!(tenant_id, opts) do
    unique = Keyword.fetch!(opts, :unique)
    replay_output = Keyword.fetch!(opts, :replay_output)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    source_run =
      Repo.insert!(
        Run.changeset(%Run{}, %{
          root_role_id: "executor",
          actor_id: "actor-source-dataset",
          tenant_id: tenant_id,
          session_id: "session-source-dataset-#{unique}",
          status: "completed",
          started_at: now,
          completed_at: now
        })
      )

    source_step =
      Repo.insert!(
        Step.changeset(%Step{}, %{
          run_id: source_run.id,
          sequence: 1,
          kind: "tool_call",
          role_id: "executor",
          status: "completed",
          projected_context: %{"prompt" => "original prompt #{unique}"},
          result_envelope: %{"output" => "original output #{unique}"}
        })
      )

    source_checkpoint =
      Repo.insert!(
        Checkpoint.changeset(%Checkpoint{}, %{
          run_id: source_run.id,
          step_id: source_step.id,
          sequence: 1,
          transition: "step_completed",
          status: "completed",
          snapshot: %{"result" => "original output #{unique}"}
        })
      )

    Repo.insert!(
      Event.changeset(%Event{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{"recorded_outcome" => "original output #{unique}"}
      })
    )

    replay_run =
      Repo.insert!(
        Run.changeset(%Run{}, %{
          root_role_id: "executor",
          actor_id: "actor-replay-dataset",
          tenant_id: tenant_id,
          session_id: "session-replay-dataset-#{unique}",
          execution_mode: "replay",
          source_run_id: source_run.id,
          source_checkpoint_id: source_checkpoint.id,
          status: "completed",
          started_at: now,
          completed_at: now
        })
      )

    replay_step =
      Repo.insert!(
        Step.changeset(%Step{}, %{
          run_id: replay_run.id,
          sequence: 1,
          kind: "tool_call",
          role_id: "executor",
          status: "completed",
          projected_context: %{"prompt" => "replay prompt #{unique}"},
          result_envelope: %{"output" => replay_output}
        })
      )

    Repo.insert!(
      Checkpoint.changeset(%Checkpoint{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => replay_output},
        metadata: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id
        },
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      })
    )

    Repo.insert!(
      Event.changeset(%Event{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id,
          "recorded_outcome" => replay_output
        },
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      })
    )

    %{run: replay_run, step: replay_step}
  end

  defp unique_suffix do
    System.unique_integer([:positive]) |> Integer.to_string()
  end
end

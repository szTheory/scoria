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
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows
  alias Scoria.Workflows.{Checkpoint, Event, Run, Step}

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

  test "review promotion params open the Dataset Builder promotion drawer" do
    candidate = review_candidate_fixture()

    {:ok, _view, html} =
      live(test_conn(), "/scoria/datasets?promote=review&review_candidate_id=#{candidate.id}")

    assert html =~ ~s(id="dataset-promote-drawer")
    assert html =~ "Promote traced evidence"
    assert html =~ "Review candidate source"
    assert html =~ candidate.score_explanation
  end

  test "workflow promotion params reconstruct context without encoded JSON params" do
    %{run: run, step: step} = replay_workflow_fixture()

    {:ok, _view, html} =
      live(
        test_conn(),
        "/scoria/datasets?promote=workflow&run_id=#{run.id}&step_id=#{step.id}&source_variant=replay"
      )

    assert html =~ ~s(id="dataset-promote-drawer")
    assert html =~ "Promote traced evidence"
    assert html =~ "Replay trace"
    assert html =~ "replay output"
  end

  test "invalid promotion params render recoverable copy and stay on Dataset Builder" do
    {:ok, view, html} =
      live(
        test_conn(),
        "/scoria/datasets?promote=workflow&run_id=#{Ecto.UUID.generate()}&step_id=#{Ecto.UUID.generate()}&source_variant=original"
      )

    assert html =~ "Promotion source not found"

    assert html =~
             "The source ID no longer resolves. Return to the originating run or review item and open Dataset Builder again."

    assert_patch(view, "/scoria/datasets?promote=workflow")
  end

  test "promotion close and dataset selection use same-LiveView patch semantics" do
    {:ok, dataset} = Eval.create_dataset(%{name: "Patch QA", version: "2"})
    candidate = review_candidate_fixture()

    {:ok, view, _html} =
      live(test_conn(), "/scoria/datasets?promote=review&review_candidate_id=#{candidate.id}")

    view
    |> element("#dataset-promote-drawer button", "Close drawer")
    |> render_click()

    assert_patch(view, "/scoria/datasets")

    view
    |> element("a", "Inspect dataset")
    |> render_click()

    assert_patch(view, "/scoria/datasets?dataset_id=#{dataset.id}")
  end

  defp test_conn do
    build_conn()
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.DatasetLive.IndexTest.Endpoint)
  end

  defp review_candidate_fixture do
    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "dataset-review-session",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "assistant",
        actor_id: "operator-review",
        tenant_id: "tenant-review",
        session_id: trace.session_id,
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate()
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "llm_call",
        role_id: "assistant",
        status: "completed"
      })

    Repo.insert!(
      OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, %{
        tenant_id: "tenant-review",
        trace_id: trace.id,
        workflow_run_id: run.id,
        workflow_step_id: step.id,
        dedupe_key: "tenant-review:#{trace.id}:#{System.unique_integer([:positive])}",
        status: "promotion_candidate",
        review_status: "pending",
        score: 0.31,
        score_status: "failed",
        score_explanation: "Review candidate source",
        scorer_kind: "deterministic_rule",
        scorer_version: "policy-rules@2026.05.23",
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

  defp replay_workflow_fixture do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    source_run =
      Repo.insert!(
        Run.changeset(%Run{}, %{
          root_role_id: "executor",
          actor_id: "actor-source-dataset",
          tenant_id: "tenant-source-dataset",
          session_id: "session-source-dataset",
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
          projected_context: %{"prompt" => "original prompt"},
          result_envelope: %{"output" => "original output"}
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
          snapshot: %{"result" => "original output"}
        })
      )

    Repo.insert!(
      Event.changeset(%Event{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{"recorded_outcome" => "original output"}
      })
    )

    replay_run =
      Repo.insert!(
        Run.changeset(%Run{}, %{
          root_role_id: "executor",
          actor_id: "actor-replay-dataset",
          tenant_id: "tenant-replay-dataset",
          session_id: "session-replay-dataset",
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
          projected_context: %{"prompt" => "replay prompt"},
          result_envelope: %{"output" => "replay output"}
        })
      )

    Repo.insert!(
      Checkpoint.changeset(%Checkpoint{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => "replay output"},
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
          "recorded_outcome" => "replay output"
        },
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      })
    )

    %{run: replay_run, step: replay_step}
  end
end

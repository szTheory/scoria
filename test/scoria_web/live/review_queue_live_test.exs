defmodule ScoriaWeb.ReviewQueueLiveTest.Router do
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

defmodule ScoriaWeb.ReviewQueueLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_review_queue_key",
    signing_salt: "review_queue_salt"
  )

  plug(ScoriaWeb.ReviewQueueLiveTest.Router)
end

defmodule ScoriaWeb.ErrorView do
  def render(_template, assigns), do: inspect(assigns)
end

defmodule ScoriaWeb.ReviewQueueLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows.{Run, Step}

  @endpoint ScoriaWeb.ReviewQueueLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.ReviewQueueLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    start_supervised!(ScoriaWeb.ReviewQueueLiveTest.Endpoint)

    {:ok, open_dataset} = Eval.create_dataset(%{name: "Draft QA", version: "1"})
    {:ok, sealed_dataset} = Eval.create_dataset(%{name: "Release QA", version: "7"})
    {:ok, _sealed_dataset} = Eval.seal_dataset(sealed_dataset)

    %{
      open_dataset: open_dataset,
      sealed_dataset: sealed_dataset
    }
  end

  test "/scoria/reviews renders the queue summary, detail rail, and deep links", _ctx do
    first = candidate_fixture(%{status: "needs_review", sampling_metadata: %{"sample_reason" => "policy_trigger"}})
    second = candidate_fixture(%{status: "promotion_candidate", score_status: "passed", score_explanation: "Ready to promote"})

    {:ok, view, html} = live(test_conn(), "/scoria/reviews")

    assert html =~ "Review flagged traces"
    assert html =~ "policy triggered"
    assert html =~ first.score_explanation
    assert html =~ "Dismiss candidate"
    assert html =~ "Promote candidate"
    assert html =~ "Request baseline approval"
    assert html =~ "phx-disable-with=\"Dismissing candidate...\""
    assert html =~ "phx-disable-with=\"Promoting candidate...\""
    assert html =~ "phx-disable-with=\"Requesting baseline approval...\""
    assert html =~ "Open draft datasets"
    assert html =~ "Sealed baseline"

    html =
      view
      |> element("button[phx-click='select_candidate'][phx-value-id='#{second.id}']")
      |> render_click()

    assert html =~ second.score_explanation
    assert html =~ "/scoria/workflows/#{second.workflow_run_id}?review_candidate_id=#{second.id}"
    assert html =~ "/scoria?runtime="
    assert html =~ "Inspect one scored candidate at a time before promoting or dismissing it."

    render_async(view)
  end

  test "queue actions dismiss, promote, and request baseline approval from the detail rail", %{open_dataset: open_dataset, sealed_dataset: sealed_dataset} do
    candidate = candidate_fixture(%{status: "promotion_candidate", score_status: "passed", score_explanation: "Promote from queue"})
    approval_candidate = candidate_fixture(%{status: "promotion_candidate", score_status: "passed", score_explanation: "Request approval"})
    dismiss_candidate = candidate_fixture(%{status: "needs_review", score_explanation: "Dismiss this"})

    {:ok, view, _html} = live(test_conn(), "/scoria/reviews")

    view
    |> element("button[phx-click='select_candidate'][phx-value-id='#{candidate.id}']")
    |> render_click()

    promoted_html =
      view
      |> element("button[phx-click='promote_candidate']")
      |> render_click()

    assert promoted_html =~ "Candidate promoted"
    assert promoted_html =~ "Promote from queue"
    assert promoted_html =~ "Draft QA"
    assert promoted_html =~ "Promoted to"
    assert [_item] = Eval.list_dataset_items(open_dataset.id)

    view
    |> element("button[phx-click='select_candidate'][phx-value-id='#{approval_candidate.id}']")
    |> render_click()

    view
    |> element("button[phx-click='select_sealed_dataset'][phx-value-dataset-id='#{sealed_dataset.id}']")
    |> render_click()

    approval_html =
      view
      |> element("button[phx-click='request_baseline_approval']")
      |> render_click()

    assert approval_html =~ "Baseline approval requested"
    assert approval_html =~ "Request approval"
    assert approval_html =~ "Sealed baseline"
    assert approval_html =~ "Request baseline approval"
    assert Repo.aggregate(Approval, :count) == 1
    assert [] == Eval.list_dataset_items(sealed_dataset.id)

    view
    |> element("button[phx-click='select_candidate'][phx-value-id='#{dismiss_candidate.id}']")
    |> render_click()

    dismissed_html =
      view
      |> element("button[phx-click='dismiss_candidate']")
      |> render_click()

    assert dismissed_html =~ "Candidate dismissed"
    refute dismissed_html =~ "Dismiss this"

    render_async(view)
  end

  defp test_conn do
    Phoenix.ConnTest.build_conn()
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.ReviewQueueLiveTest.Endpoint)
  end

  defp candidate_fixture(overrides) do
    %{trace: trace, run: run, step: step} = workflow_trace_fixture()

    attrs =
      Map.merge(
        %{
          tenant_id: "tenant-review",
          trace_id: trace.id,
          workflow_run_id: run.id,
          workflow_step_id: step.id,
          dedupe_key: "tenant-review:#{trace.id}:#{System.unique_integer([:positive])}",
          status: "needs_review",
          review_status: "pending",
          score: 0.2,
          score_status: "failed",
          score_explanation: "Needs review",
          scorer_kind: "deterministic_rule",
          scorer_version: "policy-rules@2026.05.23",
          sampling_metadata: %{"sample_reason" => "production_sample", "sample_window" => "2026-05-23T22"},
          evidence_refs: %{"trace_id" => trace.id},
          promotion_snapshot: %{
            "source_variant" => "replay",
            "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "world"}},
            "replay_reason_code" => "historical_stub"
          }
        },
        overrides
      )

    Repo.insert!(OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, attrs))
  end

  defp workflow_trace_fixture do
    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "session-#{System.unique_integer([:positive])}",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        actor_id: "operator-review",
        tenant_id: "tenant-review",
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

    %{trace: trace, run: run, step: step}
  end
end

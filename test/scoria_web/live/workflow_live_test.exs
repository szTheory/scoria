defmodule ScoriaWeb.WorkflowLiveTest.Router do
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

defmodule ScoriaWeb.WorkflowLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_workflow_key",
    signing_salt: "workflow_salt"
  )

  plug(ScoriaWeb.WorkflowLiveTest.Router)
end

defmodule ScoriaWeb.WorkflowLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows

  @endpoint ScoriaWeb.WorkflowLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.WorkflowLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "87654321"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(ScoriaWeb.WorkflowLiveTest.Endpoint)
    :ok
  end

  test "LiveView mounts from persisted workflow records and subscribes for projection updates" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "running"
      })

    {:ok, _checkpoint} =
      Workflows.append_checkpoint(run.id, step.id, %{
        transition: "tool_started",
        status: "running",
        snapshot: %{"tool" => "fetch"}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Workflow Run"
    assert html =~ run.id
    assert html =~ "running"
    assert html =~ "tool"
  end

  test "run page renders lifecycle badges and responds to run and step updates without owning truth" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "running"
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")

    assert render(view) =~ "running"

    {:ok, _step} = Workflows.complete_step(step.id, %{"ok" => true})

    assert render(view) =~ "completed"
    assert render(view) =~ "step_completed"
  end

  test "run page hides the remote invocation evidence notebook when no approvals are projected" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    refute html =~ "remote evidence notebook"
  end

  test "workflow page renders delegated evidence from the curated runtime DTO and keeps step selection on the right rail" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "planner"})

    {:ok, parent_step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "handoff",
        role_id: "planner",
        status: "completed"
      })

    {:ok, _handoff} =
      Workflows.create_handoff(parent_step, %{
        delegated_role_id: "critic",
        delegated_kind: "review",
        capability_tags: ["policy"],
        handoff_input: %{"brief" => "Review the draft answer"},
        status: "pending"
      })

    {:ok, child_step} =
      Workflows.create_step(run.id, %{
        parent_step_id: parent_step.id,
        sequence: 2,
        kind: "review",
        role_id: "critic",
        status: "running",
        projected_context: %{"draft_answer" => "hello", "task" => "policy review", "tone" => "calm"}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Delegated Evidence"
    assert html =~ "Inspect Delegated Evidence"
    assert html =~ "planner"
    assert html =~ "critic"
    assert html =~ "View full context"
    assert html =~ "handoff input"
    assert html =~ "projected context"
    assert html =~ "policy"
    assert html =~ "draft_answer"

    selected_html =
      view
      |> element("button[phx-click='select_step'][phx-value-id='#{child_step.id}']")
      |> render_click()

    assert selected_html =~ "Role"
    assert selected_html =~ "critic"
    assert selected_html =~ "review"
    assert selected_html =~ "Delegated Evidence"
  end

  test "workflow page renders delegated empty and pending states without altering the rest of the page" do
    {:ok, empty_run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, pending_run} = Workflows.create_run(%{root_role_id: "planner"})

    {:ok, parent_step} =
      Workflows.create_step(pending_run.id, %{
        sequence: 1,
        kind: "handoff",
        role_id: "planner",
        status: "completed"
      })

    {:ok, _handoff} =
      Workflows.create_handoff(parent_step, %{
        delegated_role_id: "critic",
        delegated_kind: "review",
        handoff_input: %{"brief" => "Review the draft answer"},
        status: "pending"
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _empty_view, empty_html} = live(conn, "/scoria/workflows/#{empty_run.id}")
    {:ok, _pending_view, pending_html} = live(conn, "/scoria/workflows/#{pending_run.id}")

    assert empty_html =~ "No Delegated Handoffs Recorded"
    assert empty_html =~ "Scoria.start_handoff_run/3"
    assert empty_html =~ "Timeline"

    assert pending_html =~ "child step pending"
    assert pending_html =~ "The handoff is recorded, but delegated execution has not produced a child-step readback yet."
    assert pending_html =~ "Trace-First Workflow Tree"
  end

  test "live-only steps show the typed replay comparison empty state" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, _step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"some" => "context"}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "No Replay Comparison Available"
    assert html =~ "Promote Trace to Draft Dataset"
    assert html =~ "Original trace cannot be promoted until Scoria resolves a frozen promotion snapshot"
  end

  test "replay runs render provenance strip, source toggles, and durable promotion notices" do
    {:ok, source_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        session_id: "source-session"
      })

    {:ok, source_step} =
      Workflows.create_step(source_run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"trace" => "original"},
        result_envelope: %{"output" => "source-output"}
      })

    {:ok, source_checkpoint} =
      Workflows.append_checkpoint(source_run.id, source_step.id, %{
        transition: "tool_completed",
        status: "completed",
        snapshot: %{"recorded_outcome" => "source-output"}
      })

    {:ok, _source_event} =
      Workflows.append_event(source_run.id, source_step.id, %{
        event_type: "step_completed",
        payload: %{"recorded_outcome" => "source-output"}
      })

    {:ok, replay_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        session_id: "replay-session",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        replay_overrides: %{"live_tool_allowlist" => ["publish"]}
      })

    {:ok, replay_step} =
      Workflows.create_step(replay_run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"trace" => "replay"},
        result_envelope: %{"output" => "replay-output"}
      })

    {:ok, _replay_checkpoint} =
      Workflows.append_checkpoint(replay_run.id, replay_step.id, %{
        transition: "tool_completed",
        status: "completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "approval_required",
        snapshot: %{"recorded_outcome" => "replay-output"},
        metadata: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id,
          "replay_scope" => "replay_live"
        }
      })

    {:ok, _replay_event} =
      Workflows.append_event(replay_run.id, replay_step.id, %{
        event_type: "step_completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "approval_required",
        payload: %{
          "recorded_outcome" => "replay-output",
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id,
          "replay_scope" => "replay_live"
        }
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{replay_run.id}")

    assert html =~ "Replay branch"
    assert html =~ "source checkpoint"
    assert html =~ "execution mode"
    assert html =~ "historical_stub"
    assert html =~ "Original trace"
    assert html =~ "Replay trace"
    assert html =~ "Safety Evidence"
    assert html =~ "Promotion Snapshot Summary"
    assert html =~ "Promote Trace to Draft Dataset"

    toggled_html =
      view
      |> element("button[phx-click='select_comparison_source'][phx-value-source='original']")
      |> render_click()

    assert toggled_html =~ "Original trace is active for this draft-dataset promotion."

    send(view.pid, {:promote_successful, %{source_variant: "replay", dataset_name: "Draft QA", dataset_version: "3"}})
    send(view.pid, {:baseline_promotion_requested, %{dataset_name: "Release QA", dataset_version: "7"}})

    promoted_html = render(view)

    assert promoted_html =~ "Promotion succeeded"
    assert promoted_html =~ "Replay trace"
    assert promoted_html =~ "Draft QA"
    assert promoted_html =~ "Baseline approval requested"
    assert promoted_html =~ "Release QA"
  end

  test "promotion modal starts with a blank notes field" do
    {:ok, source_run} = Workflows.create_run(%{root_role_id: "executor", session_id: "source-session"})

    {:ok, source_step} =
      Workflows.create_step(source_run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"trace" => "original"},
        result_envelope: %{"output" => "source-output"}
      })

    {:ok, source_checkpoint} =
      Workflows.append_checkpoint(source_run.id, source_step.id, %{
        transition: "tool_completed",
        status: "completed",
        snapshot: %{"recorded_outcome" => "source-output"}
      })

    {:ok, _source_event} =
      Workflows.append_event(source_run.id, source_step.id, %{
        event_type: "step_completed",
        payload: %{"recorded_outcome" => "source-output"}
      })

    {:ok, replay_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        session_id: "replay-session",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id
      })

    {:ok, replay_step} =
      Workflows.create_step(replay_run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"trace" => "replay"},
        result_envelope: %{"output" => "replay-output"}
      })

    {:ok, _replay_checkpoint} =
      Workflows.append_checkpoint(replay_run.id, replay_step.id, %{
        transition: "tool_completed",
        status: "completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "approval_required",
        snapshot: %{"recorded_outcome" => "replay-output"},
        metadata: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id
        }
      })

    {:ok, _replay_event} =
      Workflows.append_event(replay_run.id, replay_step.id, %{
        event_type: "step_completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "approval_required",
        payload: %{
          "recorded_outcome" => "replay-output",
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id
        }
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{replay_run.id}")

    modal_html =
      view
      |> element("button[phx-click='open_promote_modal'][phx-value-step-id='#{replay_step.id}']")
      |> render_click()

    assert modal_html =~ ~s(name="promotion[notes]")
    refute modal_html =~ ~s(>%{}<)
  end

  test "workflow deep links preserve review candidate evidence on the run page" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor", session_id: "candidate-session"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed"
      })

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "candidate-session",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    candidate =
      Repo.insert!(
        OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, %{
          tenant_id: "tenant-review",
          trace_id: trace.id,
          workflow_run_id: run.id,
          workflow_step_id: step.id,
          dedupe_key: "tenant-review:#{trace.id}:workflow",
          status: "needs_review",
          review_status: "pending",
          score_status: "failed",
          score_explanation: "Workflow page review evidence",
          scorer_kind: "deterministic_rule",
          scorer_version: "policy-rules@2026.05.23",
          sampling_metadata: %{"sample_reason" => "policy_trigger"}
        })
      )

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} =
      live(conn, "/scoria/workflows/#{run.id}?review_candidate_id=#{candidate.id}")

    assert html =~ "Review candidate evidence"
    assert html =~ "Workflow page review evidence"
    assert html =~ candidate.trace_id
  end
end

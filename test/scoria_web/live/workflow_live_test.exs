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
  alias Scoria.PromptRegistry
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.SemanticCache
  alias Scoria.SRE.Incident
  alias Scoria.Workflows

  @endpoint ScoriaWeb.WorkflowLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.WorkflowLiveTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
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

  test "async loading state renders scoria-skeleton in place of bespoke loading markup" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    # UAT-4 (before): the loading slot shows the skeleton, not bespoke loading text.
    assert html =~ "scoria-skeleton"
    assert html =~ ~s(role="status")
    refute html =~ "Loading compacted memories..."

    # UAT-4 (after): once the async assign resolves, the skeleton is REPLACED — it
    # must not linger — and the load did not fall into the failed state. (The pulse
    # animation + prefers-reduced-motion are CSS-driven and asserted in the Tier 2
    # Playwright lane; the lifecycle replacement is the server-observable truth.)
    render_async(view)
    resolved = render(view)
    refute resolved =~ "scoria-skeleton"
    refute resolved =~ "Failed to load memories."
    # The detail page itself remains mounted and rendered around the resolved slot.
    assert resolved =~ "Workflow Run"
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

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Workflow Run"
    assert html =~ run.id
    assert html =~ "Running"
    assert html =~ "tool"

    render_async(view)
  end

  test "run page renders object header identity, copyable ID, status, and allowlisted origin chip" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor", status: "running"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}?from=incident:inc_42")

    assert html =~ "scoria-object-header"
    assert html =~ "Runs"
    assert html =~ "Run"
    assert html =~ ~s(data-copy="#{run.id}")
    assert html =~ "Running"
    assert html =~ "← Back to incident inc_42"

    render_async(view)
  end

  test "run page ignores unknown origins without rendering a return chip or error" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor", status: "running"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}?from=unknown:123")

    assert html =~ "Workflow Run"
    refute html =~ "← Back to unknown"
    refute html =~ "Capability not found"
    refute html =~ "Unknown origin"

    render_async(view)
  end

  test "run page recomputes origin context on route-param updates" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor", status: "running"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    refute html =~ "← Back to incident inc_42"

    html = render_patch(view, "/scoria/workflows/#{run.id}?from=incident:inc_42")
    assert html =~ "← Back to incident inc_42"

    html = render_patch(view, "/scoria/workflows/#{run.id}?from=unknown:123")
    refute html =~ "← Back to incident inc_42"
    refute html =~ "← Back to unknown"

    render_async(view)
  end

  test "run page renders flat quality-loop next-step verbs when backing context exists" do
    {:ok, prompt} =
      PromptRegistry.create_draft_template(%{
        system_message: "Quality loop system",
        user_template: "Quality loop user"
      })

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        status: "running",
        metadata: %{"prompt_template_id" => prompt.id}
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "completed",
        projected_context: %{"input" => "quality-loop"},
        result_envelope: %{"output" => %{"answer" => "ready"}}
      })

    {:ok, _checkpoint} =
      Workflows.append_checkpoint(run.id, step.id, %{
        transition: "tool_completed",
        status: "completed",
        snapshot: %{"recorded_outcome" => %{"answer" => "ready"}}
      })

    {:ok, _event} =
      Workflows.append_event(run.id, step.id, %{
        event_type: "step_completed",
        payload: %{"recorded_outcome" => %{"answer" => "ready"}}
      })

    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {:ok, _incident} =
      %Incident{}
      |> Incident.changeset(%{
        tenant_id: "default",
        incident_key: "quality-loop-threading",
        severity: "warning",
        status: "open",
        summary: "Quality loop incident",
        routing_class: "review",
        dedupe_key: Ecto.UUID.generate(),
        first_seen_at: now,
        last_seen_at: now,
        workflow_run_id: run.id,
        trace_id: "trace-quality-loop"
      })
      |> Repo.insert()

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")
    decoded_html = URI.decode_www_form(html)

    assert html =~ "Replay run"
    assert html =~ "Promote in Dataset Builder"
    assert html =~ "Open incident"
    assert html =~ "Open prompt"
    assert decoded_html =~ "/scoria/coming/replay-playground?from=run:#{run.id}"
    assert decoded_html =~ "/scoria/datasets?"
    assert decoded_html =~ "promote=workflow"
    assert decoded_html =~ "run_id=#{run.id}"
    assert decoded_html =~ "step_id=#{step.id}"
    assert decoded_html =~ "source_variant=original"
    assert decoded_html =~ "from=run:#{run.id}"
    assert decoded_html =~ "/scoria/incidents?from=run:#{run.id}"
    assert decoded_html =~ "/scoria/prompts/#{prompt.id}/release?from=run:#{run.id}"

    html_downcase = String.downcase(html)
    refute html_downcase =~ "stepper"
    refute html_downcase =~ "wizard"
    refute html_downcase =~ "current step"

    render_async(view)
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

    assert render(view) =~ "Running"

    {:ok, _step} = Workflows.complete_step(step.id, %{"ok" => true})

    assert render(view) =~ "completed"
    assert render(view) =~ "step_completed"

    render_async(view)
  end

  test "run page hides the remote invocation evidence notebook when no approvals are projected" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    refute html =~ "remote evidence notebook"

    render_async(view)
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
        projected_context: %{
          "draft_answer" => "hello",
          "task" => "policy review",
          "tone" => "calm"
        }
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Delegated Evidence"
    assert html =~ "Inspect Delegated Evidence"
    assert html =~ ~s(href="#delegated-evidence")
    assert length(Regex.scan(~r/id="delegated-evidence"/, html)) == 1
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

    render_async(view)
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

    {:ok, empty_view, empty_html} = live(conn, "/scoria/workflows/#{empty_run.id}")
    {:ok, pending_view, pending_html} = live(conn, "/scoria/workflows/#{pending_run.id}")

    assert empty_html =~ "No Delegated Handoffs Recorded"

    assert empty_html =~
             "This run stayed on the default runtime lane. No bounded handoff is required for first adoption; use Scoria.start_handoff_run/3 only when a same-run delegation needs narrow projected context."

    assert empty_html =~ "Timeline"

    assert pending_html =~ "child step pending"

    assert pending_html =~
             "The handoff is recorded, but delegated execution has not produced a child-step readback yet."

    assert pending_html =~ "Trace-First Workflow Tree"

    render_async(empty_view)
    render_async(pending_view)
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

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "No Replay Comparison Available"
    assert html =~ "Promote Trace to Draft Dataset"

    assert html =~
             "Original trace cannot be promoted until Scoria resolves a frozen promotion snapshot"

    render_async(view)
  end

  test "workflow page renders the semantic evidence notebook for semantic hits" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-semantic-hit",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.TestLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               policy_key: "default",
               query_text: "what is scoria?",
               query_embedding: [0.1, 0.2, 0.3],
               answer_payload: %{"answer" => "cached answer"}
             })

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "assistant",
        tenant_id: "tenant-semantic-hit",
        session_id: "session-semantic-hit",
        status: "completed",
        metadata: %{
          "runtime" => %{
            "semantic_cache" => %{
              "lookup_status" => "hit",
              "entry_id" => entry.id,
              "origin_run_id" => "run-origin-hit",
              "lane_key" => "account_faq",
              "scope_kind" => "tenant_shared",
              "scope_reason" => "lane_default"
            }
          }
        }
      })

    {:ok, _step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "answer",
        role_id: "assistant",
        status: "completed",
        result_envelope: %{
          "output" => %{"answer" => "cached answer"},
          "semantic_cache" => %{"status" => "hit", "entry_id" => entry.id}
        }
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "semantic evidence notebook"
    assert html =~ "Compatibility"
    assert html =~ "Provenance"
    assert html =~ "Lifecycle"
    assert html =~ "lookup status"
    assert html =~ "hit"
    assert html =~ "active"

    render_async(view)
  end

  test "workflow page keeps rejected candidates inspectable with explicit fallback evidence" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-semantic-reject",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.TestLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               policy_key: "default",
               query_text: "what is scoria?",
               query_embedding: [0.1, 0.2, 0.3],
               answer_payload: %{"answer" => "stale answer"}
             })

    {:ok, invalidated_entry} =
      SemanticCache.invalidate_entry(entry, "prompt_version_mismatch", %{"phase" => "46"})

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "assistant",
        tenant_id: "tenant-semantic-reject",
        session_id: "session-semantic-reject",
        status: "completed",
        metadata: %{
          "runtime" => %{
            "semantic_cache" => %{
              "lookup_status" => "reject",
              "lookup_reason_code" => "prompt_version_mismatch",
              "candidate_entry_id" => invalidated_entry.id,
              "candidate_status" => "invalidated",
              "lane_key" => "account_faq",
              "scope_kind" => "tenant_shared",
              "scope_reason" => "lane_default"
            }
          }
        }
      })

    {:ok, _step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "answer",
        role_id: "assistant",
        status: "completed",
        result_envelope: %{"output" => %{"answer" => "fresh answer"}}
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "semantic evidence notebook"
    assert html =~ "Normal runtime path executed"
    assert html =~ "invalidated"
    assert html =~ "prompt_version_mismatch"
    assert html =~ "Lifecycle"
    assert html =~ "Provenance"

    render_async(view)
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
    assert html =~ "Replayed from run"
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

    send(
      view.pid,
      {:promote_successful,
       %{source_variant: "replay", dataset_name: "Draft QA", dataset_version: "3"}}
    )

    send(
      view.pid,
      {:baseline_promotion_requested, %{dataset_name: "Release QA", dataset_version: "7"}}
    )

    promoted_html = render(view)

    assert promoted_html =~ "Promotion succeeded"
    assert promoted_html =~ "Replay trace"
    assert promoted_html =~ "Draft QA"
    assert promoted_html =~ "Baseline approval requested"
    assert promoted_html =~ "Release QA"

    render_async(view)
  end

  test "promotion modal starts with a blank notes field" do
    {:ok, source_run} =
      Workflows.create_run(%{root_role_id: "executor", session_id: "source-session"})

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

    render_async(view)
  end

  test "workflow deep links preserve review candidate evidence on the run page" do
    {:ok, run} =
      Workflows.create_run(%{root_role_id: "executor", session_id: "candidate-session"})

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

    {:ok, view, html} =
      live(conn, "/scoria/workflows/#{run.id}?review_candidate_id=#{candidate.id}")

    assert html =~ "Review candidate evidence"
    assert html =~ "Workflow page review evidence"
    assert html =~ candidate.trace_id

    render_async(view)
  end
end

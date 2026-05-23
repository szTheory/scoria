defmodule Scoria.RuntimeViewTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.Runtime.{RunDetail, RunSummary}
  alias Scoria.Workflows
  alias Scoria.Workflows.{Checkpoint, Event, Run, Step}
  alias Scoria.Workflows.Runtime, as: WorkflowRuntime

  defmodule Handlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod"},
         reason: "Need approval",
         actor_id: "operator-view",
         tenant_id: "tenant-view",
         trace_id: "trace-#{run.id}"
       }}
    end

    def unexpected_live(_step, _run) do
      send(self(), :unexpected_live_handler_called)
      {:ok, %{"status" => "live"}}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  test "summary exposes the required durable identifiers and approval wait state" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-view",
        tenant_id: "tenant-view",
        session_id: "session-view"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, _approval} =
      WorkflowRuntime.execute_step(step.id, handler: {Handlers, :wait_for_approval})

    assert {:ok, %RunSummary{} = summary} = Runtime.get_run(run.id)

    assert summary.run_id == run.id
    assert summary.session_id == "session-view"
    assert summary.status == "waiting_for_approval"
    assert summary.actor_id == "actor-view"
    assert summary.tenant_id == "tenant-view"
    assert summary.current_step_id == step.id
    assert summary.latest_checkpoint_id
    assert summary.awaiting_approval
    assert summary.started_at
  end

  test "summary marks replay-live approval waits as having executed live" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-replay-live",
        tenant_id: "tenant-replay-live",
        session_id: "session-replay-live",
        execution_mode: "replay",
        replay_overrides: %{"live_tool_allowlist" => ["publish"]}
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _approval} =
             WorkflowRuntime.execute_step(step.id,
               handler: {Handlers, :wait_for_approval},
               replay_seam: %{
                 local_classification: :write,
                 tool_id: "publish",
                 action_class: "write",
                 risk_level: "high",
                 approval_sensitive: true,
                 policy_key: "publish"
               },
               replay_approval_context: %{
                 current_policy_ok?: true,
                 replay_approved?: true
               }
             )

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
    assert detail.summary.awaiting_approval
    assert detail.summary.any_seam_executed_live

    assert [%{transition: "waiting_for_approval", executed_live: true}] =
             Enum.filter(detail.checkpoints, &(&1.transition == "waiting_for_approval"))

    assert [%{event_type: "waiting_for_approval", executed_live: true}] =
             Enum.filter(detail.events, &(&1.event_type == "waiting_for_approval"))
  end

  test "detail view stays curated and excludes raw preload structs" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-detail",
        tenant_id: "tenant-detail",
        session_id: "session-detail"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "draft",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
    step_id = step.id

    assert detail.summary.run_id == run.id
    assert [%{id: ^step_id, kind: "draft"}] = detail.steps
    assert is_map(hd(detail.events))
    refute Enum.any?(Map.values(detail), &match?(%Scoria.Workflows.Run{}, &1))
  end

  test "session grouping returns curated summaries only" do
    {:ok, first} =
      Runtime.start_run(
        %{actor_id: "actor-group", tenant_id: "tenant-group", session_id: "group-session"},
        root_role_id: "executor"
      )

    {:ok, second} =
      Runtime.start_run(
        %{actor_id: "actor-group", tenant_id: "tenant-group", session_id: "group-session"},
        root_role_id: "executor"
      )

    runs = Runtime.list_runs_for_session("group-session")

    assert Enum.map(runs, & &1.run_id) |> Enum.sort() == Enum.sort([first.run_id, second.run_id])
    assert Enum.all?(runs, &match?(%RunSummary{}, &1))
  end

  test "summary keeps execution_mode as run intent while exposing replay posture" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-replay",
        tenant_id: "tenant-replay",
        session_id: "session-replay",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        replay_overrides: %{"live_tool_allowlist" => ["publish"]},
        status: "waiting_for_approval"
      })

    assert {:ok, %RunSummary{} = summary} = Runtime.get_run(run.id)

    assert summary.execution_mode == "replay"
    assert summary.source_run_id == source_run_id
    assert summary.source_checkpoint_id == source_checkpoint_id
    assert summary.replay_posture == "allowlist_live"
    assert summary.live_tool_allowlist == ["publish"]
    assert summary.awaiting_approval
  end

  test "detail exposes replay posture and seam-level replay evidence without raw structs" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()
    source_step_id = Ecto.UUID.generate()
    source_approval_id = Ecto.UUID.generate()
    source_audit_outbox_event_id = Ecto.UUID.generate()

    run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-detail",
        tenant_id: "tenant-detail",
        session_id: "session-detail",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        replay_overrides: %{"live_tool_allowlist" => ["publish", "sync"]},
        status: "running",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed"
      }))

    checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: run.id,
        step_id: step.id,
        sequence: 2,
        transition: "tool_stubbed",
        status: "completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      }))

    event =
      Repo.insert!(Event.changeset(%Event{}, %{
        run_id: run.id,
        step_id: step.id,
        sequence: 2,
        event_type: "tool_completed",
        payload: %{
          "source_run_id" => source_run_id,
          "source_checkpoint_id" => source_checkpoint_id,
          "source_step_id" => source_step_id,
          "source_approval_id" => source_approval_id,
          "executed_live" => true
        },
        replay_disposition: "execute_live",
        replay_reason_code: "live_override_approved"
      }))

    approval =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "approved",
        actor_id: "approver",
        tenant_id: "tenant-detail",
        session_id: "session-detail",
        workflow_run_id: run.id,
        step_id: step.id,
        checkpoint_id: checkpoint.id,
        replay_allowed: true,
        replay_scope: "replay_live",
        replay_disposition: "execute_live",
        replay_reason_code: "live_override_approved",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        source_step_id: source_step_id,
        source_approval_id: source_approval_id,
        source_audit_outbox_event_id: source_audit_outbox_event_id,
        executed_live: true
      }))

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
    checkpoint_id = checkpoint.id

    assert detail.summary.execution_mode == "replay"
    assert detail.summary.replay_posture == "allowlist_live"
    assert detail.summary.live_tool_allowlist == ["publish", "sync"]
    assert detail.summary.any_seam_executed_live

    assert [%{id: ^checkpoint_id, replay_disposition: "historical_stub", replay_reason_code: "exact_source_match"}] =
             detail.checkpoints

    assert [%{
              id: event_id,
              replay_disposition: "execute_live",
              replay_reason_code: "live_override_approved",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              source_approval_id: ^source_approval_id,
              executed_live: true
            }] = detail.events

    assert [%{
              id: approval_id,
              replay_scope: "replay_live",
              replay_disposition: "execute_live",
              replay_reason_code: "live_override_approved",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              source_approval_id: ^source_approval_id,
              source_audit_outbox_event_id: ^source_audit_outbox_event_id,
              executed_live: true
            }] = detail.approvals

    assert event_id == event.id
    assert approval_id == approval.id
    refute Enum.any?(Map.values(detail), &match?(%Run{}, &1))
  end

  test "detail projects persisted replay provenance from the real historical-stub runtime path" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()
    source_step_id = Ecto.UUID.generate()
    source_approval_id = Ecto.UUID.generate()
    source_audit_outbox_event_id = Ecto.UUID.generate()

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-runtime-detail",
        tenant_id: "tenant-runtime-detail",
        session_id: "session-runtime-detail",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        replay_overrides: %{"live_tool_allowlist" => ["publish"]}
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _step} =
             WorkflowRuntime.execute_step(step.id,
               handler: {Handlers, :unexpected_live},
               replay_seam: %{
                 local_classification: :read,
                 tool_id: "repo.read",
                 action_class: "read",
                 risk_level: "low",
                 args_fingerprint: "same",
                 subject_ref: "repo:acme/scoria",
                 required_scopes: ["repo:read"],
                 grant_state: "active",
                 policy_key: "repo.read"
               },
               replay_source_evidence: %{
                 source_run_id: source_run_id,
                 source_checkpoint_id: source_checkpoint_id,
                 source_step_id: source_step_id,
                 source_approval_id: source_approval_id,
                 source_audit_outbox_event_id: source_audit_outbox_event_id,
                 tool_id: "repo.read",
                 args_fingerprint: "same",
                 subject_ref: "repo:acme/scoria",
                 required_scopes: ["repo:read"],
                 grant_state: "active",
                 policy_key: "repo.read",
                 result: %{"status" => "stubbed"}
               }
             )

    refute_received :unexpected_live_handler_called

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)

    assert [%{
              transition: "step_completed",
              replay_disposition: "historical_stub",
              replay_reason_code: "exact_source_match",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              source_approval_id: ^source_approval_id,
              source_audit_outbox_event_id: ^source_audit_outbox_event_id,
              replay_scope: "historical_stub",
              executed_live: false
            }] = Enum.filter(detail.checkpoints, &(&1.transition == "step_completed"))

    assert [%{
              event_type: "step_completed",
              replay_disposition: "historical_stub",
              replay_reason_code: "exact_source_match",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              source_approval_id: ^source_approval_id,
              source_audit_outbox_event_id: ^source_audit_outbox_event_id,
              replay_scope: "historical_stub",
              executed_live: false
            }] = Enum.filter(detail.events, &(&1.event_type == "step_completed"))
  end

  test "replay comparison uses the latest durable evidence for a step" do
    source_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        status: "completed"
      }))

    stale_source_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: source_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed"
      }))

    source_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: source_run.id,
        step_id: stale_source_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"recorded_outcome" => %{"answer" => "source"}}
      }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: source_run.id,
      step_id: stale_source_step.id,
      sequence: 1,
      event_type: "step_completed",
      payload: %{"recorded_outcome" => %{"answer" => "source"}}
    }))

    latest_source_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: source_run.id,
        sequence: 2,
        kind: "tool_call",
        role_id: "executor",
        status: "completed"
      }))

    Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
      run_id: source_run.id,
      step_id: latest_source_step.id,
      sequence: 2,
      transition: "step_completed",
      status: "completed",
      snapshot: %{"recorded_outcome" => %{"answer" => "latest-source"}}
    }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: source_run.id,
      step_id: latest_source_step.id,
      sequence: 2,
      event_type: "step_completed",
      payload: %{"recorded_outcome" => %{"answer" => "latest-source"}}
    }))

    run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        status: "completed"
      }))

    step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: run.id,
        sequence: 99,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        result_envelope: %{"output" => %{"answer" => "latest"}}
      }))

    first_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: run.id,
        step_id: step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        replay_disposition: "blocked",
        replay_reason_code: "fresh_replay_approval_required",
        snapshot: %{"recorded_outcome" => %{"answer" => "stale"}},
        metadata: %{
          "source_checkpoint_id" => "stale-checkpoint",
          "source_step_id" => stale_source_step.id
        }
      }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: run.id,
      step_id: step.id,
      sequence: 1,
      event_type: "step_completed",
      replay_disposition: "blocked",
      replay_reason_code: "fresh_replay_approval_required",
      payload: %{
        "recorded_outcome" => %{"answer" => "stale"},
        "source_checkpoint_id" => "stale-checkpoint",
        "source_step_id" => stale_source_step.id
      }
    }))

    Repo.insert!(Approval.changeset(%Approval{}, %{
      tool_name: "publish",
      status: "pending",
      workflow_run_id: run.id,
      step_id: step.id,
      checkpoint_id: first_checkpoint.id,
      replay_disposition: "blocked",
      replay_reason_code: "fresh_replay_approval_required"
    }))

    latest_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: run.id,
        step_id: step.id,
        sequence: 2,
        transition: "step_completed",
        status: "completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match",
        snapshot: %{"recorded_outcome" => %{"answer" => "latest"}},
        metadata: %{
          "source_checkpoint_id" => "latest-checkpoint",
          "source_step_id" => latest_source_step.id
        }
      }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: run.id,
      step_id: step.id,
      sequence: 2,
      event_type: "step_completed",
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match",
      payload: %{
        "recorded_outcome" => %{"answer" => "latest"},
        "source_checkpoint_id" => "latest-checkpoint",
        "source_step_id" => latest_source_step.id
      }
    }))

    Repo.insert!(Approval.changeset(%Approval{}, %{
      tool_name: "publish",
      status: "approved",
      workflow_run_id: run.id,
      step_id: step.id,
      checkpoint_id: latest_checkpoint.id,
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match"
    }))

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
    comparison = detail.comparison_by_step[step.id].replay

    assert comparison.provenance.source_checkpoint_id == "latest-checkpoint"
    assert comparison.safety.replay_disposition == "historical_stub"
    assert comparison.safety.replay_reason_code == "exact_source_match"
    assert comparison.checkpoint_output.recorded_outcome == %{"answer" => "latest"}
    assert detail.comparison_by_step[step.id].original.provenance.workflow_step_id == latest_source_step.id
    assert detail.comparison_by_step[step.id].original.checkpoint_output.recorded_outcome == %{"answer" => "latest-source"}
  end

  test "detail projects persisted replay provenance from the real blocked runtime path" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()
    source_step_id = Ecto.UUID.generate()

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _step} =
             WorkflowRuntime.execute_step(step.id,
               handler: {Handlers, :unexpected_live},
               replay_seam: %{
                 local_classification: :authority_expanding,
                 tool_id: "admin.grant",
                 action_class: "admin",
                 risk_level: "high",
                 authority_expanding: "re-auth",
                 grant_state: "reauth_required",
                 required_scopes: ["admin:write"],
                 policy_key: "admin.grant",
                 subject_ref: "env:prod"
               },
               replay_source_evidence: %{
                 source_run_id: source_run_id,
                 source_checkpoint_id: source_checkpoint_id,
                 source_step_id: source_step_id,
                 args_fingerprint: "admin-args",
                 subject_ref: "env:prod",
                 required_scopes: ["admin:write"],
                 policy_key: "admin.grant"
               }
             )

    refute_received :unexpected_live_handler_called

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)

    assert [%{
              transition: "step_failed",
              replay_disposition: "blocked",
              replay_reason_code: "authority_expanding_change",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              replay_scope: "replay_default",
              executed_live: false
            }] = Enum.filter(detail.checkpoints, &(&1.transition == "step_failed"))

    assert [%{
              event_type: "step_failed",
              replay_disposition: "blocked",
              replay_reason_code: "authority_expanding_change",
              source_run_id: ^source_run_id,
              source_checkpoint_id: ^source_checkpoint_id,
              source_step_id: ^source_step_id,
              replay_scope: "replay_default",
              executed_live: false
            }] = Enum.filter(detail.events, &(&1.event_type == "step_failed"))
  end

  test "replay detail exposes comparison_by_step with original and replay source variants" do
    source_checkpoint_id = Ecto.UUID.generate()

    source_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-source",
        tenant_id: "tenant-source",
        session_id: "session-source",
        status: "completed",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    source_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: source_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        idempotency_key: "source-idem",
        projected_context: %{"prompt" => "original prompt"},
        result_envelope: %{"output" => "original output"},
        error_envelope: %{"status" => "ok"}
      }))

    source_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => "original output"},
        metadata: %{
          "replay_scope" => "live",
          "executed_live" => true
        }
      }))

    source_event =
      Repo.insert!(Event.changeset(%Event{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{
          "recorded_outcome" => "completed",
          "replay_scope" => "live",
          "executed_live" => true
        }
      }))

    source_approval =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "approved",
        actor_id: "approver-source",
        tenant_id: "tenant-source",
        session_id: "session-source",
        workflow_run_id: source_run.id,
        step_id: source_step.id,
        checkpoint_id: source_checkpoint.id,
        replay_scope: "live",
        replay_disposition: "execute_live",
        replay_reason_code: "source_live",
        executed_live: true
      }))

    replay_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-replay-contract",
        tenant_id: "tenant-replay-contract",
        session_id: "session-replay-contract",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint_id,
        replay_overrides: %{"live_tool_allowlist" => ["publish"]},
        status: "completed",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    replay_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: replay_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        idempotency_key: "replay-idem",
        projected_context: %{"prompt" => "replay prompt"},
        result_envelope: %{"output" => "replay output"},
        error_envelope: %{}
      }))

    replay_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => "replay output"},
        metadata: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id,
          "replay_scope" => "historical_stub",
          "executed_live" => false
        },
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      }))

    replay_event =
      Repo.insert!(Event.changeset(%Event{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{
          "source_run_id" => source_run.id,
          "source_checkpoint_id" => source_checkpoint.id,
          "source_step_id" => source_step.id,
          "recorded_outcome" => "stubbed",
          "replay_scope" => "historical_stub",
          "executed_live" => false
        },
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match"
      }))

    replay_approval =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "approved",
        actor_id: "approver-replay",
        tenant_id: "tenant-replay-contract",
        session_id: "session-replay-contract",
        workflow_run_id: replay_run.id,
        step_id: replay_step.id,
        checkpoint_id: replay_checkpoint.id,
        replay_scope: "historical_stub",
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        source_step_id: source_step.id,
        executed_live: false
      }))

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(replay_run.id)

    assert comparison = detail.comparison_by_step[replay_step.id]
    assert Map.keys(comparison) |> Enum.sort() == [:original, :replay]

    assert Enum.sort(Map.keys(comparison.original)) ==
             [:checkpoint_output, :overrides, :promotion_snapshot, :provenance, :safety]

    assert Enum.sort(Map.keys(comparison.replay)) ==
             [:checkpoint_output, :overrides, :promotion_snapshot, :provenance, :safety]

    assert comparison.original.provenance.workflow_run_id == source_run.id
    assert comparison.original.provenance.workflow_step_id == source_step.id
    assert comparison.original.provenance.source_variant == "original"
    assert comparison.original.checkpoint_output.checkpoint_id == source_checkpoint.id
    assert comparison.original.checkpoint_output.event_id == source_event.id
    assert comparison.original.safety.approval_id == source_approval.id

    assert comparison.replay.provenance.workflow_run_id == replay_run.id
    assert comparison.replay.provenance.workflow_step_id == replay_step.id
    assert comparison.replay.provenance.source_variant == "replay"
    assert comparison.replay.checkpoint_output.checkpoint_id == replay_checkpoint.id
    assert comparison.replay.checkpoint_output.event_id == replay_event.id
    assert comparison.replay.safety.approval_id == replay_approval.id
  end

  test "comparison variants carry promotion snapshot groups and live runs keep comparison_by_step empty" do
    {:ok, live_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-live",
        tenant_id: "tenant-live",
        session_id: "session-live"
      })

    {:ok, live_step} =
      Workflows.create_step(live_run.id, %{
        sequence: 1,
        kind: "draft",
        role_id: "executor",
        status: "completed",
        idempotency_key: "live-idem",
        projected_context: %{"prompt" => "live prompt"},
        result_envelope: %{"output" => "live output"},
        error_envelope: %{"status" => "ok"}
      })

    assert {:ok, %RunDetail{} = live_detail} = Runtime.get_run_detail(live_run.id)

    assert live_detail.comparison_by_step == %{}
    assert live_detail.replay_provenance_strip == %{}

    assert [%{
              id: live_step_id,
              projected_context: %{"prompt" => "live prompt"},
              result_envelope: %{"output" => "live output"},
              error_envelope: %{"status" => "ok"},
              idempotency_key: "live-idem"
            }] = live_detail.steps
    assert live_step_id == live_step.id

    source_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-source-promo",
        tenant_id: "tenant-source-promo",
        session_id: "session-source-promo",
        status: "completed",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    source_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: source_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        projected_context: %{"prompt" => "original prompt"},
        result_envelope: %{"output" => "original output"},
        error_envelope: %{}
      }))

    source_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => "original output"}
      }))

    source_event =
      Repo.insert!(Event.changeset(%Event{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 1,
        event_type: "step_completed",
        payload: %{"recorded_outcome" => "completed"}
      }))

    replay_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-replay-promo",
        tenant_id: "tenant-replay-promo",
        session_id: "session-replay-promo",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        replay_overrides: %{"live_tool_allowlist" => ["publish"]},
        status: "completed",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    replay_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: replay_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        projected_context: %{"prompt" => "replay prompt"},
        result_envelope: %{"output" => "replay output"},
        error_envelope: %{}
      }))

    Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
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
    }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: replay_run.id,
      step_id: replay_step.id,
      sequence: 1,
      event_type: "step_completed",
      payload: %{
        "source_run_id" => source_run.id,
        "source_checkpoint_id" => source_checkpoint.id,
        "source_step_id" => source_step.id,
        "recorded_outcome" => "stubbed"
      },
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match"
    }))

    assert {:ok, %RunDetail{} = replay_detail} = Runtime.get_run_detail(replay_run.id)
    comparison = replay_detail.comparison_by_step[replay_step.id]

    assert comparison.original.promotion_snapshot == %{
             workflow_run_id: source_run.id,
             workflow_step_id: source_step.id,
             source_variant: "original",
             recorded_outcome: "completed",
             replay_reason_code: nil
           }

    assert comparison.replay.promotion_snapshot == %{
             workflow_run_id: replay_run.id,
             workflow_step_id: replay_step.id,
             source_variant: "replay",
             recorded_outcome: "stubbed",
             replay_reason_code: "exact_source_match"
           }

    assert replay_detail.replay_provenance_strip == %{
             source_run_id: source_run.id,
             source_checkpoint_id: source_checkpoint.id,
             execution_mode: "replay",
             replay_posture: "allowlist_live",
             live_tool_allowlist: ["publish"],
             replay_disposition: "historical_stub",
             replay_reason_code: "exact_source_match"
           }

    assert source_event.id
  end

  test "replay comparison uses durable source lineage and forwards replay metadata in promotion groups" do
    source_checkpoint_id = Ecto.UUID.generate()
    source_run_id = Ecto.UUID.generate()

    replay_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "executor",
        actor_id: "actor-replay-contract",
        tenant_id: "tenant-replay-contract",
        session_id: "session-replay-contract",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        status: "completed",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    replay_step =
      Repo.insert!(Step.changeset(%Step{}, %{
        run_id: replay_run.id,
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        projected_context: %{"prompt" => "replay prompt"},
        result_envelope: %{"output" => %{"answer" => "replay"}}
      }))

    replay_checkpoint =
      Repo.insert!(Checkpoint.changeset(%Checkpoint{}, %{
        run_id: replay_run.id,
        step_id: replay_step.id,
        sequence: 1,
        transition: "step_completed",
        status: "completed",
        replay_disposition: "historical_stub",
        replay_reason_code: "exact_source_match",
        metadata: %{
          "source_run_id" => source_run_id,
          "source_checkpoint_id" => source_checkpoint_id
        },
        snapshot: %{
          "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "replay"}}
        }
      }))

    Repo.insert!(Event.changeset(%Event{}, %{
      run_id: replay_run.id,
      step_id: replay_step.id,
      sequence: 1,
      event_type: "step_completed",
      payload: %{
        "source_run_id" => source_run_id,
        "source_checkpoint_id" => source_checkpoint_id,
        "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "replay"}}
      },
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match"
    }))

    comparison =
      Scoria.Runtime.ReplayComparison.build(
        Repo.preload(replay_run, [:steps, :checkpoints, :events, :approvals]),
        %Run{steps: []}
      )

    replay_entry = comparison[replay_step.id].replay

    assert replay_entry.provenance.source_checkpoint_id == source_checkpoint_id
    refute replay_entry.provenance.source_checkpoint_id == replay_checkpoint.id
    assert replay_entry.provenance.source_run_id == source_run_id
    assert replay_entry.provenance.replay_disposition == "historical_stub"
    assert replay_entry.provenance.replay_reason_code == "exact_source_match"
    assert replay_entry.safety.replay_disposition == "historical_stub"
    assert replay_entry.safety.replay_reason_code == "exact_source_match"
    assert Map.take(replay_entry, [:provenance, :checkpoint_output, :safety, :promotion_snapshot]) == %{
             provenance: replay_entry.provenance,
             checkpoint_output: replay_entry.checkpoint_output,
             safety: replay_entry.safety,
             promotion_snapshot: replay_entry.promotion_snapshot
           }
  end
end

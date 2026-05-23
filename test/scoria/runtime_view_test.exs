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
end

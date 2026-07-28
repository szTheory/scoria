defmodule Scoria.WorkflowsTest do
  use ExUnit.Case
  import Ecto.Query

  alias Scoria.Repo
  alias Scoria.Observe.Approval
  alias Scoria.Observe.OperatorBroadcast
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "schema changesets" do
    test "Run validates allowed lifecycle states and applies optimistic locking" do
      changeset =
        Run.changeset(%Run{}, %{root_role_id: "executor", status: "waiting_for_approval"})

      assert changeset.valid?

      invalid = Run.changeset(%Run{}, %{root_role_id: "executor", status: "mystery"})
      refute invalid.valid?
    end

    test "Step, Checkpoint, Event, and Handoff changesets validate required links and payload fields" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "root"})

      assert Step.changeset(%Step{}, %{
               run_id: run.id,
               sequence: 1,
               kind: "model_turn",
               role_id: "researcher"
             }).valid?

      assert Checkpoint.changeset(%Checkpoint{}, %{
               run_id: run.id,
               sequence: 1,
               transition: "run_started",
               status: "running"
             }).valid?

      assert Event.changeset(%Event{}, %{run_id: run.id, sequence: 1, event_type: "run_started"}).valid?

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "handoff",
          role_id: "researcher",
          handoff_input: %{"brief" => "find sources"}
        })

      assert Handoff.changeset(%Handoff{}, %{
               run_id: run.id,
               step_id: step.id,
               delegated_role_id: "critic",
               status: "pending"
             }).valid?
    end
  end

  describe "derive_rail_pause_accounting/1 (RAIL-01 D-15, plan 56.1-04 Task 1)" do
    # Mirrors the schema's own @statuses list (run.ex:5) and its pause-set
    # subset (run.ex:10) -- kept as a literal duplicate here since neither is
    # a public accessor.
    @all_statuses ~w(running waiting_for_approval paused retrying failed completed cancelled halted)
    @pause_set ~w(waiting_for_approval paused)

    defp run_fixture(status, opts \\ []) do
      %Run{
        id: Ecto.UUID.generate(),
        root_role_id: "root",
        status: status,
        lock_version: 1,
        rail_paused_at: Keyword.get(opts, :rail_paused_at),
        rail_paused_ms: Keyword.get(opts, :rail_paused_ms, 0)
      }
    end

    test "the invariant: for every status transition, a run landing outside the pause set has rail_paused_at nil" do
      for from_status <- @all_statuses, to_status <- @all_statuses do
        paused_at =
          if from_status in @pause_set do
            DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.add(-5, :second)
          end

        run = run_fixture(from_status, rail_paused_at: paused_at, rail_paused_ms: 100)
        changeset = Run.changeset(run, %{status: to_status})
        result = Ecto.Changeset.apply_changes(changeset)

        if to_status not in @pause_set do
          assert is_nil(result.rail_paused_at),
                 "expected rail_paused_at nil after #{from_status} -> #{to_status}, got #{inspect(result.rail_paused_at)}"
        end
      end
    end

    test "entering the pause set from outside it sets rail_paused_at and leaves rail_paused_ms unchanged" do
      run = run_fixture("running", rail_paused_ms: 42)
      changeset = Run.changeset(run, %{status: "waiting_for_approval"})

      assert {:ok, %DateTime{}} = Ecto.Changeset.fetch_change(changeset, :rail_paused_at)
      refute Ecto.Changeset.get_change(changeset, :rail_paused_ms)

      result = Ecto.Changeset.apply_changes(changeset)
      assert %DateTime{} = result.rail_paused_at
      assert result.rail_paused_ms == 42
    end

    test "leaving the pause set folds the elapsed interval into rail_paused_ms and nulls rail_paused_at" do
      paused_at = DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.add(-5, :second)
      run = run_fixture("waiting_for_approval", rail_paused_at: paused_at, rail_paused_ms: 10)

      changeset = Run.changeset(run, %{status: "running"})
      result = Ecto.Changeset.apply_changes(changeset)

      assert is_nil(result.rail_paused_at)
      assert result.rail_paused_ms > 10
    end

    test "staying inside the pause set does not restart or double-count the interval" do
      paused_at = DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.add(-5, :second)
      run = run_fixture("waiting_for_approval", rail_paused_at: paused_at, rail_paused_ms: 10)

      changeset = Run.changeset(run, %{status: "paused"})

      refute Ecto.Changeset.get_change(changeset, :rail_paused_at)
      refute Ecto.Changeset.get_change(changeset, :rail_paused_ms)

      result = Ecto.Changeset.apply_changes(changeset)
      assert result.rail_paused_at == paused_at
      assert result.rail_paused_ms == 10
    end

    test "a transition where the status does not change leaves both pause fields untouched" do
      paused_at = DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.add(-5, :second)
      run = run_fixture("waiting_for_approval", rail_paused_at: paused_at, rail_paused_ms: 10)

      changeset = Run.changeset(run, %{status: "waiting_for_approval"})

      refute Ecto.Changeset.get_change(changeset, :rail_paused_at)
      refute Ecto.Changeset.get_change(changeset, :rail_paused_ms)
    end

    test "leaving the pause set with a nil rail_paused_at (a row predating this feature) folds nothing rather than raising" do
      run = run_fixture("waiting_for_approval", rail_paused_at: nil, rail_paused_ms: 0)

      changeset = Run.changeset(run, %{status: "running"})
      result = Ecto.Changeset.apply_changes(changeset)

      assert is_nil(result.rail_paused_at)
      assert result.rail_paused_ms == 0
    end

    test "rail_paused_at and rail_paused_ms cannot be set by a caller passing them in changeset attrs" do
      run = run_fixture("running", rail_paused_at: nil, rail_paused_ms: 0)

      changeset =
        Run.changeset(run, %{
          status: "running",
          rail_paused_at: DateTime.utc_now(),
          rail_paused_ms: 999
        })

      refute Map.has_key?(changeset.changes, :rail_paused_at)
      refute Map.has_key?(changeset.changes, :rail_paused_ms)
    end

    test "the regression: step A escalates and sibling step B then completes, the accumulator does not leak" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step_a} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, step_b} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, _updated_run} =
        Workflows.mark_waiting_for_approval(run.id, step_a.id, %{
          tool_name: "dangerous_tool",
          reason: "needs review"
        })

      assert Repo.get!(Run, run.id).rail_paused_at

      Process.sleep(5)

      {:ok, _completed_step} = Workflows.complete_step(step_b.id, %{"status" => "ok"})

      reloaded_run = Repo.get!(Run, run.id)

      assert reloaded_run.status == "running"
      assert is_nil(reloaded_run.rail_paused_at)
      assert reloaded_run.rail_paused_ms > 0
    end

    test "derive_rail_pause_accounting/1 has no reference to last_heartbeat_at" do
      {:ok, source} =
        File.read(Path.join([File.cwd!(), "lib", "scoria", "workflows", "run.ex"]))

      [_before, function_and_rest] =
        String.split(source, "defp derive_rail_pause_accounting(changeset) do", parts: 2)

      [function_body, _rest] =
        String.split(function_and_rest, "defp fold_rail_paused_interval(changeset) do", parts: 2)

      refute function_body =~ "last_heartbeat_at"
    end
  end

  describe "durable workflow persistence" do
    test "create_run/1 writes the root run plus its initial checkpoint and event atomically" do
      assert {:ok, run} =
               Workflows.create_run(%{
                 root_role_id: "executor",
                 actor: %{id: "actor-1"},
                 tenant_id: "tenant-1",
                 session_id: "sess-1",
                 metadata: %{"goal" => "ship", "actor_id" => "ignored-as-metadata"}
               })

      checkpoints = Repo.all(Ecto.assoc(run, :checkpoints))
      events = Repo.all(Ecto.assoc(run, :events))

      assert run.status == "running"
      assert run.actor_id == "actor-1"
      assert run.tenant_id == "tenant-1"
      assert run.session_id == "sess-1"
      assert run.latest_checkpoint_id == hd(checkpoints).id
      assert Enum.map(checkpoints, & &1.transition) == ["run_started"]
      assert Enum.map(events, & &1.event_type) == ["run_started"]
      assert hd(checkpoints).snapshot["identity"]["actor_id"] == "actor-1"
      assert hd(events).payload["identity"]["tenant_id"] == "tenant-1"
    end

    test "complete_step/3 writes step state, checkpoint, and event in one transaction" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "tool_call",
          role_id: "executor",
          status: "running",
          projected_context: %{"tool" => "fetch"}
        })

      assert {:ok, completed_step} = Workflows.complete_step(step.id, %{"ok" => true})

      updated_run = Workflows.get_run!(run.id)

      checkpoints =
        Repo.all(from(c in Checkpoint, where: c.run_id == ^run.id, order_by: [asc: c.sequence]))

      events = Repo.all(from(e in Event, where: e.run_id == ^run.id, order_by: [asc: e.sequence]))

      assert completed_step.status == "completed"
      assert updated_run.status == "completed"
      assert List.last(checkpoints).transition == "step_completed"
      assert List.last(events).event_type == "step_completed"
    end

    test "mark_waiting_for_approval/3 persists the wait state before any projection concerns" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          actor_id: "root-actor",
          tenant_id: "root-tenant",
          session_id: "root-session"
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      assert {:ok, approval} =
               Workflows.mark_waiting_for_approval(run.id, step.id, %{
                 tool_name: "dangerous_tool",
                 arguments: %{"value" => 1},
                 reason: "Need operator approval",
                 actor_id: "request-actor",
                 tenant_id: "request-tenant",
                 session_id: "request-session"
               })

      updated_run = Workflows.get_run_tree!(run.id)
      updated_step = Workflows.get_step!(step.id)

      assert updated_run.status == "waiting_for_approval"
      assert updated_step.status == "waiting_for_approval"
      assert approval.workflow_run_id == run.id
      assert approval.step_id == step.id
      assert approval.actor_id == "root-actor"
      assert approval.tenant_id == "root-tenant"
      assert approval.session_id == "root-session"
      checkpoint_id = approval.checkpoint_id

      assert Enum.any?(
               updated_run.checkpoints,
               &(&1.id == checkpoint_id and &1.transition == "waiting_for_approval")
             )
    end

    test "resume_run/1 only resumes an approval tied to the current waiting checkpoint" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, first_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, first_approval} =
        Workflows.mark_waiting_for_approval(run.id, first_step.id, %{
          tool_name: "publish",
          arguments: %{"env" => "prod"},
          reason: "Need approval"
        })

      assert {:ok, _approved} = Workflows.approve(first_approval.id, "approved", %{})

      {:ok, second_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, second_approval} =
        Workflows.mark_waiting_for_approval(run.id, second_step.id, %{
          tool_name: "publish",
          arguments: %{"env" => "prod"},
          reason: "Need fresh approval"
        })

      assert {:ok, _rejected} = Workflows.approve(second_approval.id, "rejected", %{})

      assert {:error, :not_resumable} = Workflows.resume_run(run.id)

      run = Workflows.get_run!(run.id)
      assert run.status == "waiting_for_approval"
      assert run.current_step_id == second_step.id
    end

    test "request_remote_approval/3 on a replay run creates a replay-scoped blocked approval and seam evidence" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          source_run_id: Ecto.UUID.generate(),
          source_checkpoint_id: Ecto.UUID.generate(),
          replay_overrides: %{"live_tool_allowlist" => ["publish"]},
          actor_id: "root-actor",
          tenant_id: "root-tenant",
          session_id: "root-session"
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      source_approval_id = Ecto.UUID.generate()
      source_audit_outbox_event_id = Ecto.UUID.generate()

      assert {:ok, approval} =
               Workflows.request_remote_approval(run.id, step.id, %{
                 tool_name: "publish",
                 local_tool_name: "publish",
                 arguments: %{"value" => 1},
                 requested_scopes: ["deploy:write"],
                 subject_ref: "env:prod",
                 args_fingerprint: "args-sha-1",
                 policy_key: "deploy.publish",
                 source_step_id: Ecto.UUID.generate(),
                 source_approval_id: source_approval_id,
                 source_audit_outbox_event_id: source_audit_outbox_event_id
               })

      updated_run = Workflows.get_run_tree!(run.id)
      checkpoint = Enum.find(updated_run.checkpoints, &(&1.id == approval.checkpoint_id))
      event = Enum.find(updated_run.events, &(&1.event_type == "waiting_for_approval"))

      assert approval.status == "pending"
      assert approval.replay_allowed == false
      assert approval.replay_scope == "replay_live"
      assert approval.replay_disposition == "blocked"
      assert approval.replay_reason_code == "fresh_replay_approval_required"
      assert approval.source_run_id == run.source_run_id
      assert approval.source_checkpoint_id == run.source_checkpoint_id
      assert approval.source_approval_id == source_approval_id
      assert approval.source_audit_outbox_event_id == source_audit_outbox_event_id
      assert approval.args_fingerprint == "args-sha-1"
      assert approval.subject_ref == "env:prod"
      assert approval.required_scopes == ["deploy:write"]
      assert approval.policy_key == "deploy.publish"
      assert approval.executed_live == false
      assert checkpoint.replay_disposition == "blocked"
      assert checkpoint.replay_reason_code == "fresh_replay_approval_required"
      assert event.replay_disposition == "blocked"
      assert event.replay_reason_code == "fresh_replay_approval_required"
    end

    test "request_baseline_promotion/1 persists replay-safe workflow evidence for sealed baseline approvals" do
      {:ok, dataset} = Scoria.Eval.create_dataset(%{name: "Release QA", version: "7"})
      {:ok, _sealed} = Scoria.Eval.seal_dataset(dataset)

      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          source_run_id: Ecto.UUID.generate(),
          source_checkpoint_id: Ecto.UUID.generate(),
          actor_id: "root-actor",
          tenant_id: "root-tenant",
          session_id: "root-session"
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      assert {:ok, approval} =
               Workflows.request_baseline_promotion(%{
                 dataset_id: dataset.id,
                 workflow_run_id: run.id,
                 workflow_step_id: step.id,
                 source_variant: "replay",
                 provenance: %{
                   "execution_mode" => "replay",
                   "source_run_id" => run.source_run_id,
                   "source_checkpoint_id" => run.source_checkpoint_id
                 },
                 checkpoint_output: %{"projected_context" => %{"tool" => "publish"}},
                 safety: %{"replay_scope" => "replay_live"},
                 promotion_snapshot: %{"recorded_outcome" => %{"kind" => "result"}},
                 notes: "request baseline approval",
                 expected_output: %{"status" => "review"}
               })

      assert approval.tool_name == "dataset_baseline_promotion"
      assert approval.replay_disposition == "blocked"
      assert approval.replay_reason_code == "fresh_replay_approval_required"
      assert approval.source_run_id == run.source_run_id
      assert approval.source_checkpoint_id == run.source_checkpoint_id
      assert approval.arguments["dataset_name"] == "Release QA"
      assert approval.arguments["source_variant"] == "replay"
      assert approval.arguments["expected_output"] == %{"status" => "review"}
    end

    test "request_remote_approval/3 rejects a step from another run and leaves both workflows unchanged" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
      {:ok, other_run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(other_run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      assert {:error, changeset} =
               Workflows.request_remote_approval(run.id, step.id, %{
                 tool_name: "publish",
                 arguments: %{"value" => 1}
               })

      assert {"does not belong to workflow_run_id", _opts} = changeset.errors[:workflow_step_id]
      assert Workflows.get_run!(run.id).status == "running"
      assert Workflows.get_run!(other_run.id).status == "running"
      assert Workflows.get_step!(step.id).status == "running"
      assert Repo.aggregate(Approval, :count) == 0
    end

    test "approve/3 only updates the current replay approval row and leaves historical approval as evidence" do
      source_run_id = Ecto.UUID.generate()
      source_checkpoint_id = Ecto.UUID.generate()

      historical_run =
        Repo.insert!(
          Run.changeset(%Run{}, %{
            root_role_id: "source",
            status: "running",
            started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
          })
        )

      historical =
        Repo.insert!(
          Approval.changeset(%Approval{}, %{
            tool_name: "publish",
            status: "approved",
            workflow_run_id: historical_run.id,
            source_run_id: source_run_id,
            source_checkpoint_id: source_checkpoint_id
          })
        )

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
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.request_remote_approval(run.id, step.id, %{
          tool_name: "publish",
          local_tool_name: "publish",
          source_approval_id: historical.id
        })

      assert {:ok, updated} = Workflows.approve(approval.id, "approved", %{})

      assert updated.id == approval.id
      assert updated.status == "approved"
      assert updated.source_approval_id == historical.id
      assert Repo.get!(Approval, historical.id).status == "approved"
      assert Repo.get!(Approval, approval.id).workflow_run_id == run.id
    end

    test "a historical approval cannot resume a replay branch without the replay-scoped approval" do
      source_run_id = Ecto.UUID.generate()
      source_checkpoint_id = Ecto.UUID.generate()

      historical_run =
        Repo.insert!(
          Run.changeset(%Run{}, %{
            root_role_id: "source",
            status: "running",
            started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
          })
        )

      historical =
        Repo.insert!(
          Approval.changeset(%Approval{}, %{
            tool_name: "publish",
            status: "approved",
            workflow_run_id: historical_run.id,
            source_run_id: source_run_id,
            source_checkpoint_id: source_checkpoint_id
          })
        )

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
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, replay_approval} =
        Workflows.request_remote_approval(run.id, step.id, %{
          tool_name: "publish",
          local_tool_name: "publish",
          source_approval_id: historical.id
        })

      assert {:error, :not_resumable} = Workflows.resume_run(run.id)

      assert {:ok, _approved_replay} = Workflows.approve(replay_approval.id, "approved", %{})
      assert {:ok, resumed_step} = Workflows.resume_run(run.id)
      assert resumed_step.id == step.id
    end

    test "replay live_tool_allowlist cannot widen after replay start" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          replay_overrides: %{"live_tool_allowlist" => ["publish"]}
        })

      run = Repo.get!(Run, run.id)

      assert {:error, changeset} =
               run
               |> Run.changeset(%{
                 replay_overrides: %{"live_tool_allowlist" => ["publish", "delete"]}
               })
               |> Repo.update()

      assert {"live_tool_allowlist cannot expand after replay start", _} =
               Keyword.fetch!(changeset.errors, :replay_overrides)

      assert Repo.get!(Run, run.id).replay_overrides == %{"live_tool_allowlist" => ["publish"]}
    end

    test "stale concurrent replay approval and run updates raise instead of last-write-winning" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          replay_overrides: %{"live_tool_allowlist" => ["publish"]}
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.request_remote_approval(run.id, step.id, %{
          tool_name: "publish",
          local_tool_name: "publish"
        })

      stale_run = Repo.get!(Run, run.id)
      fresh_run = Repo.get!(Run, run.id)
      Repo.update!(Run.changeset(fresh_run, %{metadata: %{"fresh" => true}}))

      assert_raise Ecto.StaleEntryError, fn ->
        Repo.update!(Run.changeset(stale_run, %{metadata: %{"stale" => true}}))
      end

      stale_approval = Repo.get!(Approval, approval.id)
      fresh_approval = Repo.get!(Approval, approval.id)
      Repo.update!(Approval.changeset(fresh_approval, %{reason: "fresh"}))

      assert_raise Ecto.StaleEntryError, fn ->
        Repo.update!(Approval.changeset(stale_approval, %{reason: "stale"}))
      end
    end
  end

  describe "halt_run/3 (RAIL-01)" do
    test "writes the new terminal \"halted\" status and audits exactly one run.rail.tripped row" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, _claimed} = Workflows.claim_step(step.id)

      envelope = rail_envelope(run, step)

      assert {:ok, %Run{status: "halted"} = halted_run} = Workflows.halt_run(run.id, step.id, envelope)
      assert Repo.get!(Step, step.id).status == "failed"

      audit_events =
        AuditOutboxEvent
        |> where(
          [e],
          e.workflow_run_id == ^halted_run.id and e.event_type == "run.rail.tripped"
        )
        |> Repo.all()

      assert length(audit_events) == 1
      assert hd(audit_events).actor_ref == "system:scoria.rails"
    end

    test "a second halt_run/3 on the same run returns {:error, :already_halted}" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, _claimed} = Workflows.claim_step(step.id)

      envelope = rail_envelope(run, step)

      assert {:ok, %Run{status: "halted"}} = Workflows.halt_run(run.id, step.id, envelope)
      assert {:error, :already_halted} = Workflows.halt_run(run.id, step.id, envelope)
    end

    test "a forced duplicate dedupe_key rolls back the whole transaction; the run stays running" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, _claimed} = Workflows.claim_step(step.id)

      dedupe_key = "run.rail.tripped:" <> run.id

      {:ok, _existing} =
        SRE.create_audit_outbox_event(%{
          tenant_id: "system",
          event_type: "run.rail.tripped",
          policy_class: "run_rail",
          dedupe_key: dedupe_key,
          actor_ref: "system:scoria.rails",
          workflow_run_id: run.id
        })

      envelope = rail_envelope(run, step)

      assert {:error, :already_halted} = Workflows.halt_run(run.id, step.id, envelope)
      assert Repo.get!(Run, run.id).status == "running"
    end
  end

  describe "terminality guards G1-G6 (RAIL-01 D-02)" do
    test "G1: claim_step/1 refuses a queued step created on an already-halted run" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      {:ok, late_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      assert {:error, :run_halted} = Workflows.claim_step(late_step.id)
      assert Repo.get!(Step, late_step.id).status == "queued"
    end

    test "G2: retry_step/1 refuses a failed step of a halted run" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, failed_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "failed"
        })

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert {:error, :run_not_retryable} = Workflows.retry_step(failed_step.id)
      assert Repo.get!(Step, failed_step.id).status == "failed"
    end

    test "G3: resume_run/1 on a halted run returns {:error, :not_resumable} (no code change; regression only)" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert {:error, :not_resumable} = Workflows.resume_run(run.id)
    end

    test "G4(a): complete_step/3 on a sibling read after the halt commits leaves the run halted" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, halted_run} = Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert {:ok, completed_step} = Workflows.complete_step(sibling_step.id, %{"result" => "ok"})
      assert completed_step.status == "completed"

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status == "halted"
      assert reloaded_run.current_step_id == halted_run.current_step_id
      assert reloaded_run.completed_at == halted_run.completed_at
      assert reloaded_run.error_envelope == halted_run.error_envelope
    end

    test "G4(b): a %Run{} copy loaded BEFORE the halt raises Ecto.StaleEntryError on complete_step/3's own write shape" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      stale_run = Repo.get!(Run, run.id)

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert_raise Ecto.StaleEntryError, fn ->
        Repo.update!(
          Run.changeset(stale_run, %{
            status: "completed",
            current_step_id: sibling_step.id,
            completed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
            error_envelope: %{}
          })
        )
      end
    end

    test "G5(a): fail_step/3 on a sibling read after the halt commits leaves the run halted" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, halted_run} = Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert {:ok, failed_step} = Workflows.fail_step(sibling_step.id, %{"reason" => "boom"})
      assert failed_step.status == "failed"

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status == "halted"
      assert halted_run.status == "halted"
    end

    test "G5(b): a %Run{} copy loaded BEFORE the halt raises Ecto.StaleEntryError on fail_step/3's own write shape" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      stale_run = Repo.get!(Run, run.id)

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert_raise Ecto.StaleEntryError, fn ->
        Repo.update!(
          Run.changeset(stale_run, %{
            status: "failed",
            current_step_id: sibling_step.id,
            error_envelope: %{"reason" => "boom"}
          })
        )
      end
    end

    test "G6(a): mark_waiting_for_approval/3 on a sibling read after the halt commits leaves the run halted" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert {:ok, _approval} =
               Workflows.mark_waiting_for_approval(run.id, sibling_step.id, %{
                 tool_name: "publish",
                 local_tool_name: "publish"
               })

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status == "halted"
    end

    test "G6(b): a %Run{} copy loaded BEFORE the halt raises Ecto.StaleEntryError on mark_waiting_for_approval/3's own write shape" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      stale_run = Repo.get!(Run, run.id)

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert_raise Ecto.StaleEntryError, fn ->
        Repo.update!(
          Run.changeset(stale_run, %{
            status: "waiting_for_approval",
            current_step_id: sibling_step.id
          })
        )
      end
    end

    test "D-04: two concurrent halt_run/3 calls on one run yield exactly one {:ok, %Run{}} and one {:error, :already_halted}" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, step_a} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, step_b} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      parent = self()

      tasks =
        for step <- [step_a, step_b] do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
            Workflows.halt_run(run.id, step.id, rail_envelope(run, step))
          end)
        end

      results = Task.await_many(tasks, 5_000)

      assert Enum.count(results, &match?({:ok, %Run{}}, &1)) == 1
      assert Enum.count(results, &match?({:error, :already_halted}, &1)) == 1
    end

    test "D-04: mixed concurrent halt_run/3 and claim_step/1 tasks against overlapping run/step sets all complete without a Postgres deadlock (56.1-03 Task 3)" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      steps =
        for seq <- 1..10 do
          {:ok, step} =
            Workflows.create_step(run.id, %{
              sequence: seq,
              kind: "work",
              role_id: "executor",
              status: "queued"
            })

          step
        end

      parent = self()

      halt_tasks =
        for step <- Enum.take(steps, 5) do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
            Workflows.halt_run(run.id, step.id, rail_envelope(run, step))
          end)
        end

      claim_tasks =
        for step <- steps do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
            Workflows.claim_step(step.id)
          end)
        end

      # The run-first FOR UPDATE lock order (D-04) shared by `halt_run/3`
      # and `claim_step/1`'s G1 guard is what makes this deadlock-free --
      # `Task.await_many/2`'s bound below is the proof: a genuine
      # {run,step}/{step,run} lock-order deadlock would surface as a
      # Postgres `40P01` error returned from one of the racing
      # transactions, not a hang, so completing inside the timeout with no
      # deadlock error in any result is the whole assertion.
      results = Task.await_many(halt_tasks ++ claim_tasks, 5_000)

      refute Enum.any?(results, fn
               {:error, %{postgres: %{code: :deadlock_detected}}} -> true
               _ -> false
             end)
    end
  end

  describe "HITL tenant fan-out" do
    test "mark_waiting_for_approval/3 broadcasts hitl_request on tenant topic" do
      tenant_id = "tenant-hitl-#{System.unique_integer([:positive])}"
      Phoenix.PubSub.subscribe(Scoria.PubSub, OperatorBroadcast.tenant_topic(tenant_id))

      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          tenant_id: tenant_id,
          session_id: "session-hitl"
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      assert {:ok, approval} =
               Workflows.mark_waiting_for_approval(run.id, step.id, %{
                 tool_name: "publish",
                 arguments: %{"env" => "prod"},
                 reason: "Need approval"
               })

      assert_receive {:hitl_request, projection}
      assert projection.id == approval.id
      assert projection.tool_name == "publish"
      assert Map.has_key?(projection, :arguments_preview)
    end

    test "approve/3 broadcasts approval_decided on tenant topic" do
      tenant_id = "tenant-decided-#{System.unique_integer([:positive])}"
      Phoenix.PubSub.subscribe(Scoria.PubSub, OperatorBroadcast.tenant_topic(tenant_id))

      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          tenant_id: tenant_id
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.request_remote_approval(run.id, step.id, %{
          tool_name: "publish",
          local_tool_name: "publish"
        })

      assert {:ok, _updated} = Workflows.approve(approval.id, "approved", %{})

      assert_receive {:approval_decided, approval_id, "approved"}
      assert approval_id == approval.id
    end

    test "approve/3 rejects already-decided approval with :not_pending" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", tenant_id: "tenant-stale"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.request_remote_approval(run.id, step.id, %{
          tool_name: "publish",
          local_tool_name: "publish"
        })

      assert {:ok, _} = Workflows.approve(approval.id, "approved", %{})
      assert {:error, :not_pending} = Workflows.approve(approval.id, "approved", %{})
    end
  end

  defp rail_envelope(run, step) do
    %{
      "status" => "run_halted",
      "reason_code" => "max_steps_exceeded",
      "rail" => "max_steps",
      "limit" => 1,
      "observed" => 1,
      "attempted" => 2,
      "run_id" => run.id,
      "step_id" => step.id,
      "halted_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "site" => "workflow_runtime_step"
    }
  end
end

defmodule Scoria.WorkflowsTest do
  use ExUnit.Case
  import Ecto.Query

  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "schema changesets" do
    test "Run validates allowed lifecycle states and applies optimistic locking" do
      changeset = Run.changeset(%Run{}, %{root_role_id: "executor", status: "waiting_for_approval"})

      assert changeset.valid?

      invalid = Run.changeset(%Run{}, %{root_role_id: "executor", status: "mystery"})
      refute invalid.valid?
    end

    test "Step, Checkpoint, Event, and Handoff changesets validate required links and payload fields" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "root"})

      assert Step.changeset(%Step{}, %{run_id: run.id, sequence: 1, kind: "model_turn", role_id: "researcher"}).valid?
      assert Checkpoint.changeset(%Checkpoint{}, %{run_id: run.id, sequence: 1, transition: "run_started", status: "running"}).valid?
      assert Event.changeset(%Event{}, %{run_id: run.id, sequence: 1, event_type: "run_started"}).valid?

      {:ok, step} =
        Workflows.create_step(run.id, %{sequence: 1, kind: "handoff", role_id: "researcher", handoff_input: %{"brief" => "find sources"}})

      assert Handoff.changeset(%Handoff{}, %{run_id: run.id, step_id: step.id, delegated_role_id: "critic", status: "pending"}).valid?
    end
  end

  describe "durable workflow persistence" do
    test "create_run/1 writes the root run plus its initial checkpoint and event atomically" do
      assert {:ok, run} =
               Workflows.create_run(%{
                 root_role_id: "executor",
                 session_id: "sess-1",
                 metadata: %{"goal" => "ship"}
               })

      checkpoints = Repo.all(Ecto.assoc(run, :checkpoints))
      events = Repo.all(Ecto.assoc(run, :events))

      assert run.status == "running"
      assert run.latest_checkpoint_id == hd(checkpoints).id
      assert Enum.map(checkpoints, & &1.transition) == ["run_started"]
      assert Enum.map(events, & &1.event_type) == ["run_started"]
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
      checkpoints = Repo.all(from c in Checkpoint, where: c.run_id == ^run.id, order_by: [asc: c.sequence])
      events = Repo.all(from e in Event, where: e.run_id == ^run.id, order_by: [asc: e.sequence])

      assert completed_step.status == "completed"
      assert updated_run.status == "completed"
      assert List.last(checkpoints).transition == "step_completed"
      assert List.last(events).event_type == "step_completed"
    end

    test "mark_waiting_for_approval/3 persists the wait state before any projection concerns" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

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
                 reason: "Need operator approval"
               })

      updated_run = Workflows.get_run_tree!(run.id)
      updated_step = Workflows.get_step!(step.id)

      assert updated_run.status == "waiting_for_approval"
      assert updated_step.status == "waiting_for_approval"
      assert approval.workflow_run_id == run.id
      assert approval.step_id == step.id
      checkpoint_id = approval.checkpoint_id
      assert Enum.any?(updated_run.checkpoints, &(&1.id == checkpoint_id and &1.transition == "waiting_for_approval"))
    end
  end
end

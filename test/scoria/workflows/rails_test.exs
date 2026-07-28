defmodule Scoria.Workflows.RailsTest do
  use Scoria.IntegrationCase

  import Ecto.Query

  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.{Rails, Run, Runtime}

  describe "Repo.update_all + select (RESEARCH Open Question 1)" do
    test "returns the POST-increment value, not the pre-increment value" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      run
      |> Ecto.Changeset.change(rail_steps: 5)
      |> Repo.update!()

      query = from(r in Run, where: r.id == ^run.id, select: r.rail_steps)

      # If this were PRE-increment the assertion below would read `{1, [5]}`.
      # It is POST-increment: D-17's observed/attempted arithmetic in the
      # rest of this module assumes this exact shape.
      assert {1, [6]} = Repo.update_all(query, inc: [rail_steps: 1])
    end
  end

  describe "Rails.admit_step/2" do
    test "admits exactly rail_max_steps times, then denies" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 2})

      assert {:ok, 1} = Rails.admit_step(run.id)
      assert {:ok, 2} = Rails.admit_step(run.id)
      assert :denied = Rails.admit_step(run.id)
    end

    test "with rail_max_steps: nil admits and increments unconditionally (never denies)" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
      assert is_nil(run.rail_max_steps)

      assert {:ok, 1} = Rails.admit_step(run.id)
      assert {:ok, 2} = Rails.admit_step(run.id)
      assert {:ok, 3} = Rails.admit_step(run.id)
    end
  end

  describe "end-to-end: a run that exceeds max_steps halts and the halt is audited" do
    test "second dispatch denies, the run reads halted, and exactly one audit row exists" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, step1} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      handler = fn step, _run -> {:ok, %{"step_id" => step.id, "status" => "ok"}} end

      assert {:ok, completed_step} = Runtime.execute_step(step1.id, handler: handler)
      assert completed_step.status == "completed"

      assert {:error, envelope} = Runtime.execute_step(step2.id, handler: handler)
      assert envelope["reason_code"] == "max_steps_exceeded"

      reloaded_run = Workflows.get_run!(run.id)
      assert reloaded_run.status == "halted"

      audit_events =
        AuditOutboxEvent
        |> where([e], e.workflow_run_id == ^run.id and e.event_type == "run.rail.tripped")
        |> Repo.all()

      assert length(audit_events) == 1
      assert hd(audit_events).actor_ref == "system:scoria.rails"
    end
  end

  describe "Workflows.halt_run/3 idempotence" do
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
  end

  describe "Workflows.halt_run/3 audit-failure trade" do
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

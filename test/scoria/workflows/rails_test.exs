defmodule Scoria.Workflows.RailsTest do
  use Scoria.IntegrationCase

  import Ecto.Query

  alias Scoria.Connectors.Invocation
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.{Rails, Run, Runtime}

  # Minimal MCP tool used by the 56.1-03 Task 1/2 admission tests below --
  # its own behavior is irrelevant, only that it is a real
  # `Scoria.MCP.Tool` `execute/2` implementation the executor/invocation
  # seam can dispatch to.
  defmodule RailTestTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "rail_test_tool"

    @impl true
    def description, do: "minimal tool for 56.1-03 rail-admission tests"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

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

  describe "Rails.admit_tool_call/2 (56.1-03 Task 1)" do
    test "admits exactly rail_max_tool_calls times, then denies" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_tool_calls: 2})

      assert {:ok, 1} = Rails.admit_tool_call(run.id)
      assert {:ok, 2} = Rails.admit_tool_call(run.id)
      assert :denied = Rails.admit_tool_call(run.id)
    end

    test "with rail_max_tool_calls: nil admits and increments unconditionally (never denies)" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
      assert is_nil(run.rail_max_tool_calls)

      assert {:ok, 1} = Rails.admit_tool_call(run.id)
      assert {:ok, 2} = Rails.admit_tool_call(run.id)
      assert {:ok, 3} = Rails.admit_tool_call(run.id)
    end
  end

  describe "20 concurrent Rails.admit_tool_call/2 against a limit of 10 (D-09, 56.1-03 Task 3)" do
    test "yield exactly 10 admits, 10 denials, and a persisted counter of exactly 10" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_tool_calls: 10})
      parent = self()

      tasks =
        for _ <- 1..20 do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
            Rails.admit_tool_call(run.id)
          end)
        end

      results = Task.await_many(tasks, 5_000)

      assert Enum.count(results, &match?({:ok, _}, &1)) == 10
      assert Enum.count(results, &(&1 == :denied)) == 10
      assert Repo.get!(Run, run.id).rail_tool_calls == 10
    end
  end

  describe "counter semantics: EXECUTIONS not ROWS (D-06, 56.1-03 Task 3)" do
    test "fan-out: 10 step rows created on one run but only 3 admitted leaves rail_steps at 3, not 10" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      for seq <- 1..10 do
        {:ok, _step} =
          Workflows.create_step(run.id, %{
            sequence: seq,
            kind: "work",
            role_id: "executor",
            status: "queued"
          })
      end

      Enum.each(1..3, fn _ -> assert {:ok, _count} = Rails.admit_step(run.id) end)

      reloaded_run = Repo.get!(Run, run.id)
      # ACCEPTED, DOCUMENTED GAP (56.1-CONTEXT.md D-06): step rows created
      # but never executed do not count -- a fan-out bomb creating 10 000
      # rows halts after max_steps of them START, and the rest sit queued
      # under a halted run, structurally undispatchable. Row-count
      # explosion is a different problem from a runaway loop.
      assert reloaded_run.rail_steps == 3
      assert length(Workflows.list_run_steps(run.id)) == 10
    end

    test "retry loop: retry_step/1 five times on one step leaves rail_steps five higher while the step row count stays 1" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "failed"
        })

      # This is the property a `count(*)` aggregate could not deliver:
      # `retry_step/1` reuses the SAME step row (D-06), so the counter has
      # to count executions (one `Rails.admit_step/2` per dispatch
      # attempt), not rows.
      Enum.each(1..5, fn _ ->
        assert {:ok, _count} = Rails.admit_step(run.id)
        assert {:ok, _retried} = Workflows.retry_step(step.id)
      end)

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.rail_steps == 5
      assert length(Workflows.list_run_steps(run.id)) == 1
    end
  end

  describe "SC#3 -- counting is always on, even for an unconfigured run (56.1-03 Task 3)" do
    test "a run created with no rails executes 50 steps with zero halts, and that SAME run's rail_steps reads 50" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
      assert is_nil(run.rail_max_steps)

      steps =
        for seq <- 1..50 do
          {:ok, step} =
            Workflows.create_step(run.id, %{
              sequence: seq,
              kind: "work",
              role_id: "executor",
              status: "queued"
            })

          step
        end

      handler = fn step, _run -> {:ok, %{"step_id" => step.id, "status" => "ok"}} end

      results = Enum.map(steps, fn step -> Runtime.execute_step(step.id, handler: handler) end)

      # Part 1: zero halts.
      assert Enum.all?(results, &match?({:ok, %{status: "completed"}}, &1))

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status != "halted"
      assert reloaded_run.rail_max_steps == nil

      # Part 2 (the one that actually catches a regression that
      # short-circuits the CAS whenever the limit is nil): the SAME run's
      # rail_steps reads exactly 50, asserted on the same run in the same
      # test body as part 1.
      assert reloaded_run.rail_steps == 50
    end
  end

  describe "post-approval resumption costs 2 against max_steps (RESEARCH Open Question 6, 56.1-03 Task 3)" do
    test "a post-approval resumption counts as a second execution against max_steps -- a round trip costs 2" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 2})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "queued"
        })

      escalate_handler = fn _step, _run ->
        {:waiting_for_approval, %{tool_name: "publish", arguments: %{}, reason: "needs review"}}
      end

      assert {:ok, approval} = Runtime.execute_step(step.id, handler: escalate_handler)
      assert Repo.get!(Run, run.id).rail_steps == 1

      assert {:ok, _approved} = Workflows.approve(approval.id, "approved", %{})
      # `resume_run/1` sets the step back to "queued" (`workflows.ex:893`),
      # so under the locked counting semantics it increments AGAIN on the
      # next admission -- pinning that a human-approval round trip costs 2
      # against `max_steps`, not 1. (Claude's discretion: an exemption for
      # this specific path would be a one-line `WHERE` change, but the
      # locked semantics count executions, and a resumed step is a real
      # re-dispatch.)
      assert {:ok, resumed_step} = Workflows.resume_run(run.id)
      assert resumed_step.id == step.id
      assert resumed_step.status == "queued"

      complete_handler = fn step, _run -> {:ok, %{"step_id" => step.id, "status" => "ok"}} end
      assert {:ok, completed} = Runtime.execute_step(resumed_step.id, handler: complete_handler)
      assert completed.status == "completed"

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.rail_steps == 2
      assert reloaded_run.status != "halted"
    end
  end

  describe "D-10: run_id/step_id forwarded into run.metadata[\"runtime\"] (56.1-03 Task 2)" do
    test "a handler invoked through Runtime.execute_step/2 observes run_id/step_id, and the persisted run never carries them" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{sequence: 1, kind: "work", role_id: "executor", status: "queued"})

      test_pid = self()

      handler = fn handler_step, handler_run ->
        send(test_pid, {:runtime_metadata, Map.get(handler_run.metadata || %{}, "runtime", %{})})
        {:ok, %{"step_id" => handler_step.id, "status" => "ok"}}
      end

      assert {:ok, _completed_step} = Runtime.execute_step(step.id, handler: handler)

      assert_receive {:runtime_metadata, runtime_metadata}
      assert runtime_metadata["run_id"] == run.id
      assert runtime_metadata["step_id"] == step.id

      persisted_run = Repo.get!(Run, run.id)
      refute Map.has_key?(Map.get(persisted_run.metadata || %{}, "runtime", %{}), "run_id")
      refute Map.has_key?(Map.get(persisted_run.metadata || %{}, "runtime", %{}), "step_id")
    end
  end

  describe "Connectors.Invocation.invoke/4 rail admission (D-08, 56.1-03 Task 2)" do
    test "invoke/4 denies at the limit, halts the run, and returns status: :run_halted without reaching the tool" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_tool_calls: 1})

      assert {:ok, %{status: :execute_live}} = Invocation.invoke(RailTestTool, %{}, %{run_id: run.id})

      assert {:error, %{status: :run_halted, reason_code: "max_tool_calls_exceeded"}} =
               Invocation.invoke(RailTestTool, %{}, %{run_id: run.id})

      assert Repo.get!(Run, run.id).status == "halted"
    end

    test "one logical call through invoke/4 -> Executor.execute/4 increments rail_tool_calls exactly once" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_tool_calls: 5})

      assert {:ok, %{status: :execute_live}} = Invocation.invoke(RailTestTool, %{}, %{run_id: run.id})

      assert Repo.get!(Run, run.id).rail_tool_calls == 1
    end

    test "a :historical_stub short-circuit still consumes one unit of max_tool_calls budget" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          rail_max_tool_calls: 5,
          replay_overrides: %{"live_tool_allowlist" => ["allowed.tool"]}
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{sequence: 1, kind: "tool", role_id: "executor", status: "queued"})

      assert {:ok, %{status: :historical_stub}} =
               Invocation.invoke(
                 RailTestTool,
                 %{"action" => "read"},
                 %{
                   run: run,
                   run_id: run.id,
                   step_id: step.id,
                   tool_id: "repo.read",
                   local_classification: :read,
                   action_class: "read",
                   risk_level: "low",
                   args_fingerprint: "same",
                   subject_ref: "repo:acme/scoria",
                   required_scopes: ["repo:read"],
                   grant_state: "active",
                   policy_key: "repo.read",
                   source_evidence: %{
                     source_run_id: run.source_run_id || run.id,
                     source_checkpoint_id: run.source_checkpoint_id || Ecto.UUID.generate(),
                     source_step_id: step.id,
                     source_audit_outbox_event_id: Ecto.UUID.generate(),
                     tool_id: "repo.read",
                     args_fingerprint: "same",
                     subject_ref: "repo:acme/scoria",
                     required_scopes: ["repo:read"],
                     grant_state: "active",
                     policy_key: "repo.read",
                     result: %{"cached" => true}
                   }
                 }
               )

      assert Repo.get!(Run, run.id).rail_tool_calls == 1
    end
  end

  describe "mixed concurrent halt_run/3 and admit_tool_call/2 stay deadlock-free (D-04, 56.1-03 Task 3)" do
    test "N concurrent admit_tool_call/2 tasks racing a concurrent halt_run/3 on the same run all complete inside a bounded timeout" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_tool_calls: 5})

      {:ok, step} =
        Workflows.create_step(run.id, %{sequence: 1, kind: "work", role_id: "executor", status: "queued"})

      parent = self()

      admit_tasks =
        for _ <- 1..10 do
          Task.async(fn ->
            Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
            Rails.admit_tool_call(run.id)
          end)
        end

      halt_task =
        Task.async(fn ->
          Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
          Workflows.halt_run(run.id, step.id, rail_envelope(run, step))
        end)

      results = Task.await_many(admit_tasks ++ [halt_task], 5_000)

      refute Enum.any?(results, fn
               {:error, %{postgres: %{code: :deadlock_detected}}} -> true
               _ -> false
             end)
    end
  end

  describe "the active-time predicate: Rails.admit_step/2 + Rails.deny_reason/2 (56.1-CONTEXT.md D-08/D-09/D-14, plan 56.1-04 Task 2)" do
    test "a run 10 minutes old with a 5-minute ceiling and 0 paused ms is denied with max_active_ms_exceeded" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      backdate_started_at(run, minutes_ago(10))

      assert :denied = Rails.admit_step(run.id)
      assert :max_active_ms_exceeded = Rails.deny_reason(run.id)
    end

    test "the same run with 6 minutes of paused time is admitted -- elapsed active time is 4 minutes, under the ceiling" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      run
      |> Ecto.Changeset.change(rail_paused_ms: :timer.minutes(6))
      |> Repo.update!()

      backdate_started_at(run, minutes_ago(10))

      assert {:ok, 1} = Rails.admit_step(run.id)
    end

    test "with rail_max_active_ms: nil, never denied for time no matter how old the run is" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
      assert is_nil(run.rail_max_active_ms)

      backdate_started_at(run, minutes_ago(1440))

      assert {:ok, 1} = Rails.admit_step(run.id)
    end

    test "anchor fallback: a run whose started_at is nil falls back to inserted_at rather than skipping the rail" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      run
      |> Ecto.Changeset.change(started_at: nil, inserted_at: minutes_ago(10))
      |> Repo.update!()

      assert :denied = Rails.admit_step(run.id)
    end

    test "the computed elapsed value is identical under a non-UTC session TimeZone as under UTC (RESEARCH Pitfall 5)" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      backdate_started_at(run, minutes_ago(10))

      Repo.query!("SET LOCAL TIME ZONE 'America/New_York'")

      assert :denied = Rails.admit_step(run.id)
    end

    test "check order: a run over BOTH its max_active_ms and max_steps budgets reports max_active_ms_exceeded, not max_steps_exceeded" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          rail_max_active_ms: :timer.minutes(5),
          rail_max_steps: 1
        })

      run
      |> Ecto.Changeset.change(rail_steps: 1)
      |> Repo.update!()

      backdate_started_at(run, minutes_ago(10))

      assert :denied = Rails.admit_step(run.id)
      assert :max_active_ms_exceeded = Rails.deny_reason(run.id)
    end

    test "grep-level: no fragment(\"now()\") -- the bound parameter is always an Elixir-side timestamp" do
      {:ok, source} =
        File.read(Path.join([File.cwd!(), "lib", "scoria", "workflows", "rails.ex"]))

      refute String.contains?(source, "fragment(\"now()\")")
      assert source =~ ":utc_datetime_usec"
      assert source =~ "rail_paused_ms"
      assert source =~ "COALESCE"
    end

    defp minutes_ago(minutes) do
      DateTime.utc_now() |> DateTime.add(-minutes * 60, :second) |> DateTime.truncate(:microsecond)
    end

    defp backdate_started_at(run, timestamp) do
      run
      |> Ecto.Changeset.change(started_at: timestamp)
      |> Repo.update!()
    end
  end

  describe "retrying counts as active: a retry loop cannot outrun the timeout rail (D-14, plan 56.1-04 Task 2)" do
    test "a run cycling through retry_step/1 never gets its active-time clock paused or reset" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "failed"
        })

      Enum.each(1..3, fn _ -> assert {:ok, _retried} = Workflows.retry_step(step.id) end)

      reloaded_run = Repo.get!(Run, run.id)
      assert is_nil(reloaded_run.rail_paused_at)
      assert reloaded_run.rail_paused_ms == 0

      six_minutes_ago =
        DateTime.utc_now() |> DateTime.add(-360, :second) |> DateTime.truncate(:microsecond)

      Repo.get!(Run, run.id)
      |> Ecto.Changeset.change(started_at: six_minutes_ago)
      |> Repo.update!()

      # If retrying had (wrongly) paused or reset the clock, this run would
      # still be admitted; it is not -- the clock kept running the whole
      # time, so a retry loop cannot outrun the rail.
      assert :denied = Rails.admit_step(run.id)
    end
  end

  describe "the Phase 57 invariant: a long approval wait never converts into a halt (D-14, 56.1-04 Task 2)" do
    test "a run parked past max_active_ms in waiting_for_approval, then approved and resumed, executes its next step without halting" do
      {:ok, run} =
        Workflows.create_run(%{root_role_id: "executor", rail_max_active_ms: :timer.minutes(5)})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "queued"
        })

      escalate_handler = fn _step, _run ->
        {:waiting_for_approval,
         %{tool_name: "publish", arguments: %{}, reason: "needs review"}}
      end

      assert {:ok, approval} = Runtime.execute_step(step.id, handler: escalate_handler)
      assert %Run{rail_paused_at: %DateTime{}} = Repo.get!(Run, run.id)

      # The human takes 10 minutes to decide -- longer than the 5-minute
      # rail_max_active_ms ceiling. Backdate rail_paused_at so the
      # PAUSED interval genuinely exceeds the budget; approving/resuming
      # folds that whole interval into rail_paused_ms (D-15), so it must
      # never count as active time.
      ten_minutes_ago =
        DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.truncate(:microsecond)

      Repo.get!(Run, run.id)
      |> Ecto.Changeset.change(rail_paused_at: ten_minutes_ago)
      |> Repo.update!()

      assert {:ok, _approved} = Workflows.approve(approval.id, "approved", %{})
      assert {:ok, resumed_step} = Workflows.resume_run(run.id)

      complete_handler = fn step, _run -> {:ok, %{"step_id" => step.id, "status" => "ok"}} end
      assert {:ok, completed_step} = Runtime.execute_step(resumed_step.id, handler: complete_handler)

      assert completed_step.status == "completed"
      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status != "halted"
      assert is_nil(reloaded_run.rail_paused_at)
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

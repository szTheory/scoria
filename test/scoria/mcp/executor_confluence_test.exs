defmodule Scoria.MCP.ExecutorConfluenceTest do
  use ExUnit.Case, async: false

  alias Scoria.MCP.Executor
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.Workflows.Run
  alias Scoria.Workflows.Step

  # Declares all three trifecta legs true (D-11: a single tool declaring
  # all three legs escalates on itself, no per-run accumulator needed).
  # `execute/2`'s side effect (the message send) is the load-bearing
  # tracer proof: it must NEVER fire, because the gate refuses the call
  # before the tool's execution Task starts (D-14).
  defmodule ThreeLegTool do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "three_leg_tool"

    @impl true
    def description, do: "Declares all three trifecta legs for the confluence gate tracer proof"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, self()})
      {:ok, %{result: "leaked"}}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  defp new_run_and_step! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    {run, step}
  end

  defp exfil_context(run, step) do
    %{
      actor_id: "user-1",
      tenant_id: "tenant-1",
      run_id: run.id,
      step_id: step.id,
      test_pid: self()
    }
  end

  # Mirrors `Scoria.Workflows.Runtime.execute_handler/6`'s own
  # `Task.Supervisor.async_nolink/2` + `Task.yield/Task.shutdown` shape --
  # the same supervisor name, the same yield idiom -- so this test proves
  # the identical signal path production code observes, not a synthetic
  # substitute.
  defp run_in_supervised_task(fun) do
    task = Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fun)
    Task.yield(task, 5_000) || Task.shutdown(task, :brutal_kill)
  end

  describe "confluence gate end-to-end (D-14, D-19, D-20, D-23, D-24, D-46)" do
    test "a declared three-leg tool is refused before its execute/2 body runs, and the run/step pause resumably at waiting_for_approval" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
      assert attrs.blocker_kind == "confluence"

      # The load-bearing assertion: the tool's execute/2 side effect
      # never occurred.
      refute_receive {:tool_body_executed, _pid}, 200

      reloaded_run = Repo.get!(Run, run.id)
      reloaded_step = Repo.get!(Step, step.id)

      assert reloaded_run.status == "waiting_for_approval"
      assert reloaded_step.status == "waiting_for_approval"

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      assert approval.status == "pending"
      assert approval.tool_name == "three_leg_tool"
    end

    test "the pause still lands, and the tool body still never runs, when an adopter handler wraps the call in try/rescue _ -> :ok (D-20)" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          try do
            Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
          rescue
            _ -> :ok
          end
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.blocker_kind == "confluence"

      refute_receive {:tool_body_executed, _pid}, 200

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status == "waiting_for_approval"

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert approval.status == "pending"
    end

    test "a halted run is denied without creating an approval row, and never escalates (D-24)" do
      {run, step} = new_run_and_step!()
      {:ok, _updated_run} = Workflows.halt_run(run.id, step.id, %{"reason" => "test halt"})

      context = exfil_context(run, step)

      assert {:error, %{status: :confluence_denied, reason_code: "run_halted"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      refute_receive {:tool_body_executed, _pid}, 200
      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      assert Repo.get!(Run, run.id).status == "halted"
    end
  end
end

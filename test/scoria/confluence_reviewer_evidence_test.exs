defmodule Scoria.ConfluenceReviewerEvidenceTest do
  @moduledoc """
  Plan 57-11: the end-to-end proof that a real `Scoria.MCP.Executor.execute/4`
  confluence escalation renders non-blank evidence rows through the live
  projection -- not a hand-built approval map (D-40, D-48, GATE-02).
  """
  use ExUnit.Case, async: false

  alias Scoria.MCP.Executor
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.Workflows.RemoteApprovalProjection
  alias ScoriaWeb.ApprovalCopy

  # A single tool declaring all three trifecta legs -- reaches
  # `"exfiltration_path"` on its own call, mirroring
  # `Scoria.ConfluenceAuditTest.ThreeLegTool`.
  defmodule ThreeLegTool do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "confluence_reviewer_evidence_three_leg_tool"

    @impl true
    def description, do: "Declares all three trifecta legs for the reviewer evidence test"

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

  defp new_run! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    run
  end

  defp new_step!(run, sequence) do
    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: sequence,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    step
  end

  # Mirrors `Scoria.ConfluenceAuditTest.run_in_supervised_task/1` --
  # `Scoria.Workflows.Runtime.execute_handler/6`'s own
  # `Task.Supervisor.async_nolink/2` + `Task.yield/Task.shutdown` shape, so
  # this proves the identical signal path production code observes.
  defp run_in_supervised_task(fun) do
    task = Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fun)
    Task.yield(task, 5_000) || Task.shutdown(task, :brutal_kill)
  end

  describe "a real escalation's Combination row is non-blank in the drawer's rows (D-40, D-48, GATE-02)" do
    test "Executor.execute/4 through RemoteApprovalProjection.get_approval_lineage!/1 through ApprovalCopy.request_rows/1 renders the named combination" do
      run = new_run!()
      step = new_step!(run, 1)

      context = %{
        actor_id: "user-1",
        tenant_id: "tenant-reviewer-evidence-1",
        run_id: run.id,
        step_id: step.id,
        args_fingerprint: "fp-reviewer-evidence-1",
        test_pid: self()
      }

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      # Nothing here constructs the approval map by hand -- the created
      # approval is loaded by its real identity, then projected through the
      # SAME live path the reviewer drawer reads from.
      approval =
        Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
      rows = ApprovalCopy.request_rows(projection)

      assert {"Combination", "Private data + untrusted content + external egress → exfiltration path"} in rows
    end
  end
end

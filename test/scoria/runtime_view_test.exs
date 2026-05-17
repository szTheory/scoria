defmodule Scoria.RuntimeViewTest do
  use ExUnit.Case, async: false

  alias Scoria.Runtime
  alias Scoria.Runtime.{RunDetail, RunSummary}
  alias Scoria.Workflows
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
end

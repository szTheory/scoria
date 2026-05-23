defmodule Scoria.Workflows.DatasetPromotionTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.Eval
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "operator",
        actor_id: "operator-1",
        tenant_id: "tenant-1",
        session_id: "session-1"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool_call",
        status: "running",
        role_id: "operator"
      })

    %{run: run, step: step}
  end

  test "request_baseline_promotion/1 stores the approval through the workflow boundary", %{run: run, step: step} do
    {:ok, dataset} = Eval.create_dataset(%{name: "Release QA", version: "7"})
    {:ok, _sealed} = Eval.seal_dataset(dataset)

    assert {:ok, approval} =
             Workflows.request_baseline_promotion(%{
               dataset_id: dataset.id,
               workflow_run_id: run.id,
               workflow_step_id: step.id,
               source_variant: "original",
               provenance: %{"execution_mode" => "live"},
               checkpoint_output: %{"projected_context" => %{"foo" => "bar"}},
               safety: %{},
               promotion_snapshot: %{"recorded_outcome" => %{"kind" => "result"}},
               notes: "operator note",
               expected_output: %{"result" => "ok"}
             })

    persisted =
      Repo.one!(
        from request in Approval,
          where: request.id == ^approval.id
      )

    assert persisted.tool_name == "dataset_baseline_promotion"
    assert persisted.workflow_run_id == run.id
    assert persisted.step_id == step.id
    assert persisted.arguments["dataset_name"] == "Release QA"
    assert persisted.arguments["dataset_version"] == "7"
    assert persisted.arguments["notes"] == "operator note"
  end

  test "request_baseline_promotion/1 rejects open datasets", %{run: run, step: step} do
    {:ok, dataset} = Eval.create_dataset(%{name: "Draft QA", version: "1"})

    assert {:error, changeset} =
             Workflows.request_baseline_promotion(%{
               dataset_id: dataset.id,
               workflow_run_id: run.id,
               workflow_step_id: step.id,
               source_variant: "original",
               provenance: %{"execution_mode" => "live"},
               checkpoint_output: %{"projected_context" => %{"foo" => "bar"}},
               safety: %{},
               promotion_snapshot: %{"recorded_outcome" => %{"kind" => "result"}}
             })

    assert {"must reference a sealed dataset", _opts} = changeset.errors[:dataset_id]
  end
end

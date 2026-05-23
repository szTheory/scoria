defmodule Scoria.Workflows.RemoteApprovalProjectionTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.Observe.Approval
  alias Scoria.Workflows
  alias Scoria.Workflows.Run

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "list_pending_approvals/1 exposes replay-safe inbox evidence directly from the projection" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate(),
        actor_id: "operator",
        tenant_id: "tenant-replay",
        session_id: "session-replay"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    source_approval_id = Ecto.UUID.generate()

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
               source_audit_outbox_event_id: Ecto.UUID.generate()
             })

    assert [
             %{
               id: approval_id,
               workflow_run_id: workflow_run_id,
               replay_allowed: false,
               replay_disposition: "blocked",
               replay_scope: "replay_live",
               source_run_id: source_run_id,
               source_checkpoint_id: source_checkpoint_id,
               source_approval_id: projected_source_approval_id,
               required_scopes: ["deploy:write"],
               policy_key: "deploy.publish",
               executed_live: false
             }
           ] = Workflows.list_pending_remote_approvals(%{tenant_id: "tenant-replay"})

    assert approval_id == approval.id
    assert workflow_run_id == run.id
    assert source_run_id == run.source_run_id
    assert source_checkpoint_id == run.source_checkpoint_id
    assert projected_source_approval_id == source_approval_id
  end

  test "get_approval_lineage!/1 keeps replay scope and source lineage explicit without boolean inference" do
    source_run_id = Ecto.UUID.generate()
    source_checkpoint_id = Ecto.UUID.generate()

    historical_run =
      Repo.insert!(Run.changeset(%Run{}, %{
        root_role_id: "source",
        status: "running",
        started_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }))

    historical =
      Repo.insert!(Approval.changeset(%Approval{}, %{
        tool_name: "publish",
        status: "approved",
        workflow_run_id: historical_run.id,
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id
      }))

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        source_run_id: source_run_id,
        source_checkpoint_id: source_checkpoint_id,
        actor_id: "operator",
        tenant_id: "tenant-lineage",
        session_id: "session-lineage"
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

    assert %{
             id: approval_id,
             replay_scope: "replay_live",
             replay_allowed: false,
             replay_disposition: "blocked",
             replay_reason_code: "fresh_replay_approval_required",
             source_run_id: ^source_run_id,
             source_checkpoint_id: ^source_checkpoint_id,
             source_approval_id: projected_source_approval_id,
             executed_live: false
           } = Workflows.get_remote_approval_lineage!(approval.id)

    assert approval_id == approval.id
    assert projected_source_approval_id == historical.id
  end
end

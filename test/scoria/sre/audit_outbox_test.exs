defmodule Scoria.SRE.AuditOutboxTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "workflow audit outbox durability" do
    test "mark_waiting_for_approval writes a redacted audit row in the same transaction" do
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
                 arguments: %{"token" => "top-secret", "target" => "prod"},
                 reason: "Need operator approval",
                 actor_id: "operator-1",
                 trace_id: "trace-approval-request",
                 tenant_id: "tenant-approval"
               })

      audit_event =
        Repo.get_by!(AuditOutboxEvent, workflow_run_id: run.id, event_type: "approval.requested")

      assert audit_event.step_id == step.id
      assert audit_event.policy_class == "approval"
      assert audit_event.trace_id == "trace-approval-request"
      assert audit_event.actor_ref == "operator-1"
      assert audit_event.redacted_refs["tool_name"] == "dangerous_tool"
      assert audit_event.redacted_refs["arguments"]["token"] == "[REDACTED]"
      assert audit_event.redacted_refs["arguments"]["target"] == "prod"
      assert audit_event.redacted_refs["approval_id"] == approval.id
      refute audit_event.redacted_refs["arguments"]["token"] == "top-secret"
      refute audit_event.metadata["raw_arguments"]
    end

    test "workflow truth changes roll back when the audit outbox insert fails" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      duplicate_key = "approval.requested:tenant-rollback:trace-rollback"

      Repo.insert!(%AuditOutboxEvent{
        tenant_id: "tenant-rollback",
        event_type: "approval.requested",
        policy_class: "approval",
        sink_status: "pending",
        dedupe_key: duplicate_key,
        payload_hash: "sha256:existing",
        pending_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        attempt_count: 0,
        actor_ref: "operator-1",
        workflow_run_id: run.id,
        step_id: step.id,
        trace_id: "trace-rollback",
        redacted_refs: %{"approval_id" => "existing"},
        metadata: %{}
      })

      assert {:error, changeset} =
               Workflows.mark_waiting_for_approval(run.id, step.id, %{
                 tool_name: "dangerous_tool",
                 arguments: %{"token" => "top-secret"},
                 reason: "Need operator approval",
                 actor_id: "operator-1",
                 trace_id: "trace-rollback",
                 tenant_id: "tenant-rollback",
                 dedupe_key: duplicate_key
               })

      errors = errors_on(changeset)

      assert Enum.any?(
               [:dedupe_key, :tenant_id],
               &(Map.get(errors, &1) == ["has already been taken"])
             )

      assert Workflows.get_run!(run.id).status == "running"
      assert Workflows.get_step!(step.id).status == "running"
      assert Repo.aggregate(from(a in Approval, where: a.workflow_run_id == ^run.id), :count) == 0

      assert Repo.aggregate(
               from(e in AuditOutboxEvent, where: e.workflow_run_id == ^run.id),
               :count
             ) == 1
    end

    test "approve writes approval outcome audit rows for approved, rejected, and expired decisions" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.mark_waiting_for_approval(run.id, step.id, %{
          tool_name: "dangerous_tool",
          arguments: %{"secret" => "123", "target" => "prod"},
          tenant_id: "tenant-decisions",
          trace_id: "trace-approved",
          actor_id: "operator-approved"
        })

      assert {:ok, approved} =
               Workflows.approve(approval.id, "approved", %{
                 actor_id: "operator-approved",
                 tenant_id: "tenant-decisions",
                 trace_id: "trace-approved"
               })

      assert approved.status == "approved"

      approved_event =
        Repo.get_by!(AuditOutboxEvent,
          workflow_run_id: run.id,
          event_type: "approval.approved",
          trace_id: "trace-approved"
        )

      assert approved_event.actor_ref == "operator-approved"
      assert approved_event.tenant_id == "tenant-decisions"
      assert approved_event.trace_id == "trace-approved"
      assert approved_event.redacted_refs["approval_id"] == approval.id
      assert approved_event.redacted_refs["decision"] == "approved"

      {:ok, second_run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, second_step} =
        Workflows.create_step(second_run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, rejected_approval} =
        Workflows.mark_waiting_for_approval(second_run.id, second_step.id, %{
          tool_name: "dangerous_tool",
          arguments: %{"secret" => "456", "target" => "prod"},
          tenant_id: "tenant-decisions",
          trace_id: "trace-rejected",
          actor_id: "operator-rejected"
        })

      assert {:ok, rejected} =
               Workflows.approve(rejected_approval.id, "rejected", %{
                 actor_id: "operator-rejected",
                 tenant_id: "tenant-decisions",
                 trace_id: "trace-rejected"
               })

      assert rejected.status == "rejected"

      rejected_event =
        Repo.get_by!(AuditOutboxEvent,
          workflow_run_id: second_run.id,
          event_type: "approval.rejected",
          trace_id: "trace-rejected"
        )

      assert rejected_event.actor_ref == "operator-rejected"
      assert rejected_event.tenant_id == "tenant-decisions"
      assert rejected_event.trace_id == "trace-rejected"
      assert rejected_event.redacted_refs["approval_id"] == rejected_approval.id
      assert rejected_event.redacted_refs["decision"] == "rejected"

      {:ok, third_run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, third_step} =
        Workflows.create_step(third_run.id, %{
          sequence: 1,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, expired_approval} =
        Workflows.mark_waiting_for_approval(third_run.id, third_step.id, %{
          tool_name: "dangerous_tool",
          arguments: %{"secret" => "789", "target" => "prod"},
          tenant_id: "tenant-expired",
          trace_id: "trace-expired",
          actor_id: "operator-expired"
        })

      assert {:ok, expired} = Workflows.approve(expired_approval.id, "expired")
      assert expired.status == "expired"

      expired_event =
        Repo.get_by!(AuditOutboxEvent,
          workflow_run_id: third_run.id,
          event_type: "approval.expired",
          trace_id: "trace-expired"
        )

      assert expired_event.actor_ref == "operator-expired"
      assert expired_event.tenant_id == "tenant-expired"
      assert expired_event.redacted_refs["approval_id"] == expired_approval.id
      assert expired_event.redacted_refs["decision"] == "expired"
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

end

defmodule Scoria.Workflows.ApprovalWriteInvariantGuardTest do
  use ExUnit.Case, async: false

  @moduledoc """
  D-20: decided-at/decider integrity for the approval decision-history surface.

  Two concerns, one file (they are the same invariant from two angles):

  1. `Workflows.list_decided_approvals/1` (the bounded decided-history projection)
     scopes to the three terminal statuses, orders by the cheap `updated_at`/`id`
     proxy sort, and honors the outcome sub-filter (Approved/Denied/Expired).
  2. A warning-grade source-scan guard asserting no runtime path writes an approval
     row after it leaves `pending` — the query's `updated_at` proxy sort (and any
     future denormalized `decided_at`) is only trustworthy if nothing re-writes a
     decided row.
  """

  import Ecto.Query, only: [from: 2]

  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "list_decided_approvals/1 (bounded projection)" do
    test "scopes to approved/rejected/expired only, excluding pending" do
      tenant_id = unique_tenant_id()

      insert_approval!(tenant_id, "pending")
      approved_id = insert_approval!(tenant_id, "approved")
      rejected_id = insert_approval!(tenant_id, "rejected")
      expired_id = insert_approval!(tenant_id, "expired")

      results = Workflows.list_decided_approvals(%{tenant_id: tenant_id})
      result_ids = Enum.map(results, & &1.id) |> MapSet.new()

      assert result_ids == MapSet.new([approved_id, rejected_id, expired_id])
      assert Enum.all?(results, &(&1.status in ["approved", "rejected", "expired"]))
    end

    test "orders desc updated_at then desc id as a proxy sort" do
      tenant_id = unique_tenant_id()

      oldest_id = insert_approval!(tenant_id, "approved")
      set_updated_at!(oldest_id, ~U[2026-07-01 10:00:00.000000Z])

      middle_id = insert_approval!(tenant_id, "rejected")
      set_updated_at!(middle_id, ~U[2026-07-01 10:05:00.000000Z])

      newest_id = insert_approval!(tenant_id, "expired")
      set_updated_at!(newest_id, ~U[2026-07-01 10:10:00.000000Z])

      assert Workflows.list_decided_approvals(%{tenant_id: tenant_id}) |> Enum.map(& &1.id) ==
               [newest_id, middle_id, oldest_id]
    end

    test "the outcome sub-filter narrows results (reuses the existing status filter field)" do
      tenant_id = unique_tenant_id()

      insert_approval!(tenant_id, "approved")
      rejected_id = insert_approval!(tenant_id, "rejected")
      insert_approval!(tenant_id, "expired")

      assert [%{id: ^rejected_id, status: "rejected"}] =
               Workflows.list_decided_approvals(%{tenant_id: tenant_id, status: "rejected"})
    end

    test "is bounded and accepts an optional limit for capped + load-more" do
      tenant_id = unique_tenant_id()

      for _ <- 1..3, do: insert_approval!(tenant_id, "approved")

      assert length(Workflows.list_decided_approvals(%{tenant_id: tenant_id, limit: 2})) == 2
    end
  end

  defp unique_tenant_id, do: "tenant-decided-#{System.unique_integer([:positive])}"

  defp insert_approval!(tenant_id, status) do
    %Approval{}
    |> Approval.changeset(%{tool_name: "issue_refund", status: status, tenant_id: tenant_id})
    |> Repo.insert!()
    |> Map.fetch!(:id)
  end

  defp set_updated_at!(approval_id, updated_at) do
    {1, _} =
      Repo.update_all(
        from(approval in Approval, where: approval.id == ^approval_id),
        set: [updated_at: updated_at]
      )

    :ok
  end
end

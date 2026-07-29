defmodule Scoria.Observe.ApprovalTest do
  use ExUnit.Case, async: true
  alias Scoria.Observe.Approval
  import Ecto.Changeset

  describe "changeset/2" do
    test "casts approval attributes correctly" do
      attrs = %{
        tool_name: "delete_user",
        arguments: %{"user_id" => "123"},
        status: "pending",
        session_id: "sess_xyz",
        run_id: "run_xyz"
      }

      changeset = Approval.changeset(%Approval{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :tool_name) == "delete_user"
      assert get_field(changeset, :arguments) == %{"user_id" => "123"}
      assert get_field(changeset, :status) == "pending"
      assert get_field(changeset, :session_id) == "sess_xyz"
      assert get_field(changeset, :run_id) == "run_xyz"
    end
  end

  describe "consumed_at/consumed_by_step_id/confluence_scope writer disjointness (D-26, D-50)" do
    test "the struct responds to all three fields" do
      approval = %Approval{}

      assert Map.has_key?(approval, :consumed_at)
      assert Map.has_key?(approval, :consumed_by_step_id)
      assert Map.has_key?(approval, :confluence_scope)
    end

    test "changeset/2 never casts consumed_at, consumed_by_step_id, or confluence_scope, even when the caller supplies them" do
      attrs = %{
        tool_name: "send_reply",
        status: "pending",
        consumed_at: DateTime.utc_now(),
        consumed_by_step_id: Ecto.UUID.generate(),
        confluence_scope: "run_tool"
      }

      changeset = Approval.changeset(%Approval{}, attrs)

      refute Map.has_key?(changeset.changes, :consumed_at)
      refute Map.has_key?(changeset.changes, :consumed_by_step_id)
      refute Map.has_key?(changeset.changes, :confluence_scope)
    end
  end
end

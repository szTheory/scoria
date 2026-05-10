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
      assert get_change(changeset, :tool_name) == "delete_user"
      assert get_change(changeset, :arguments) == %{"user_id" => "123"}
      assert get_change(changeset, :status) == "pending"
      assert get_change(changeset, :session_id) == "sess_xyz"
      assert get_change(changeset, :run_id) == "run_xyz"
    end
  end
end

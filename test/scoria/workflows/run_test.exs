defmodule Scoria.Workflows.RunTest do
  use ExUnit.Case, async: true

  alias Scoria.Workflows.Run

  describe "confluence_legs writer disjointness (D-15)" do
    test "the struct responds to :confluence_legs with a %{} default" do
      assert %Run{}.confluence_legs == %{}
    end

    test "Run.changeset/2 never casts :confluence_legs, even when the caller supplies it" do
      run = %Run{
        id: Ecto.UUID.generate(),
        root_role_id: "root",
        status: "running",
        lock_version: 1,
        confluence_legs: %{}
      }

      changeset =
        Run.changeset(run, %{
          status: "running",
          confluence_legs: %{"private_data" => %{"source" => "declared"}}
        })

      refute Map.has_key?(changeset.changes, :confluence_legs)
      refute Ecto.Changeset.get_change(changeset, :confluence_legs)
    end
  end
end

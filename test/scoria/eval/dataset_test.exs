defmodule Scoria.Eval.DatasetTest do
  use Scoria.EvalCase

  alias Scoria.Eval.Dataset

  describe "changeset/2" do
    test "validates required fields" do
      changeset = Dataset.changeset(%Dataset{}, %{})
      assert !changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:name]
      assert {"can't be blank", _} = changeset.errors[:version]
    end

    test "modifying an :open dataset works" do
      dataset = %Dataset{state: :open}
      changeset = Dataset.changeset(dataset, %{name: "Test DS", version: "v1"})
      assert changeset.valid?
    end

    test "modifying a :sealed dataset returns an error" do
      dataset = %Dataset{state: :sealed}
      changeset = Dataset.changeset(dataset, %{name: "New Name"})
      
      refute changeset.valid?
      assert {"cannot be modified once sealed", _} = changeset.errors[:state]
    end
  end
end

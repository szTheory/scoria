defmodule Scoria.Eval.DatasetItemTest do
  use Scoria.EvalCase

  alias Scoria.Eval.DatasetItem

  describe "changeset/3" do
    test "validates required fields" do
      changeset = DatasetItem.changeset(%DatasetItem{}, %{})
      assert !changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:input]
    end

    test "validation succeeds when dataset state is :open" do
      changeset = DatasetItem.changeset(%DatasetItem{}, %{dataset_id: 1, input: %{"prompt" => "test"}}, :open)
      assert changeset.valid?
    end

    test "validation fails when dataset state passed is :sealed" do
      changeset = DatasetItem.changeset(%DatasetItem{}, %{dataset_id: 1, input: %{"prompt" => "test"}}, :sealed)
      
      refute changeset.valid?
      assert {"cannot add or modify items in a sealed dataset", _} = changeset.errors[:dataset_id]
    end
  end
end

defmodule Scoria.EvalTest do
  use ExUnit.Case

  alias Scoria.Repo
  alias Scoria.Eval
  alias Scoria.Eval.Dataset
  alias Scoria.Eval.EvalSpec

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  describe "datasets" do
    @valid_dataset_attrs %{name: "Test Dataset", description: "A test dataset"}
    @valid_item_attrs %{input: %{"q" => "hello"}, expected_output: %{"a" => "world"}}

    test "create_dataset/1 creates a dataset with items" do
      attrs = Map.put(@valid_dataset_attrs, :items, [@valid_item_attrs])
      assert {:ok, %Dataset{} = dataset} = Eval.create_dataset(attrs)
      assert dataset.version == 1
      assert dataset.is_current == true
      assert dataset.name == "Test Dataset"
      assert dataset.entity_id != nil

      items = Eval.list_dataset_items(dataset.id)
      assert length(items) == 1
    end

    test "update_dataset/2 creates a new version and deprecates the old one" do
      {:ok, dataset} = Eval.create_dataset(@valid_dataset_attrs)
      assert dataset.version == 1
      assert dataset.is_current == true

      update_attrs = %{name: "Updated Dataset"}
      assert {:ok, %Dataset{} = new_dataset} = Eval.update_dataset(dataset, update_attrs)
      assert new_dataset.version == 2
      assert new_dataset.is_current == true
      assert new_dataset.name == "Updated Dataset"
      assert new_dataset.entity_id == dataset.entity_id

      # Reload old dataset
      old_dataset = Repo.get(Dataset, dataset.id)
      assert old_dataset.is_current == false
      assert old_dataset.version == 1
    end

    test "update_dataset/2 clones associated dataset_items" do
      {:ok, dataset} = Eval.create_dataset(Map.put(@valid_dataset_attrs, :items, [@valid_item_attrs]))
      
      # Make sure we have 1 item initially
      items = Eval.list_dataset_items(dataset.id)
      assert length(items) == 1
      item = hd(items)
      assert item.input == %{"q" => "hello"}

      update_attrs = %{name: "Version 2"}
      assert {:ok, new_dataset} = Eval.update_dataset(dataset, update_attrs)
      
      # The new dataset should have the cloned items
      new_items = Eval.list_dataset_items(new_dataset.id)
      assert length(new_items) == 1
      new_item = hd(new_items)
      assert new_item.input == %{"q" => "hello"}
      assert new_item.id != item.id
    end
  end

  describe "eval_specs" do
    @valid_spec_attrs %{name: "Test Spec", rubric: %{"metrics" => ["accuracy"]}}

    test "create_eval_spec/1 creates a spec" do
      assert {:ok, %EvalSpec{} = spec} = Eval.create_eval_spec(@valid_spec_attrs)
      assert spec.version == 1
      assert spec.is_current == true
      assert spec.name == "Test Spec"
      assert spec.entity_id != nil
    end

    test "update_eval_spec/2 creates a new version and deprecates the old one" do
      {:ok, spec} = Eval.create_eval_spec(@valid_spec_attrs)
      
      update_attrs = %{name: "Updated Spec"}
      assert {:ok, %EvalSpec{} = new_spec} = Eval.update_eval_spec(spec, update_attrs)
      
      assert new_spec.version == 2
      assert new_spec.is_current == true
      assert new_spec.name == "Updated Spec"
      assert new_spec.entity_id == spec.entity_id

      old_spec = Repo.get(EvalSpec, spec.id)
      assert old_spec.is_current == false
    end
  end
end

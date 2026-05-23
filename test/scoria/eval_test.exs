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
    @valid_dataset_attrs %{name: "Test Dataset", description: "A test dataset", version: "1"}
    @valid_item_attrs %{input: %{"q" => "hello"}, expected_output: %{"a" => "world"}}

    test "create_dataset/1 creates an :open dataset" do
      assert {:ok, %Dataset{} = dataset} = Eval.create_dataset(@valid_dataset_attrs)
      assert dataset.state == :open
      assert dataset.version == "1"
    end

    test "create_dataset/1 creates a dataset with items" do
      attrs = Map.put(@valid_dataset_attrs, :items, [@valid_item_attrs])
      assert {:ok, %Dataset{} = dataset} = Eval.create_dataset(attrs)
      assert dataset.state == :open

      items = Eval.list_dataset_items(dataset.id)
      assert length(items) == 1
      assert hd(items).input == %{"q" => "hello"}
    end

    test "seal_dataset/1 updates dataset state to :sealed" do
      {:ok, dataset} = Eval.create_dataset(@valid_dataset_attrs)
      assert {:ok, %Dataset{} = sealed} = Eval.seal_dataset(dataset)
      assert sealed.state == :sealed
    end

    test "add_dataset_item/2 adds an item when dataset is :open" do
      {:ok, dataset} = Eval.create_dataset(@valid_dataset_attrs)
      assert {:ok, item} = Eval.add_dataset_item(dataset.id, @valid_item_attrs)
      assert item.dataset_id == dataset.id
      assert item.input == %{"q" => "hello"}
    end

    test "add_dataset_item/2 returns error changeset when dataset is :sealed" do
      {:ok, dataset} = Eval.create_dataset(@valid_dataset_attrs)
      {:ok, _sealed} = Eval.seal_dataset(dataset)
      
      assert {:error, changeset} = Eval.add_dataset_item(dataset.id, @valid_item_attrs)
      assert {"cannot add or modify items in a sealed dataset", _} = changeset.errors[:dataset_id]
    end

    test "promote_trace_to_dataset/2 creates dataset and item from a given trace struct" do
      trace = %Scoria.Repo.Trace{
        id: Ecto.UUID.generate(),
        session_id: "sess-123",
        attributes: %{"some" => "attr"},
        spans: []
      }

      assert {:ok, %Dataset{} = dataset} = Eval.promote_trace_to_dataset(trace, %{name: "Promoted Trace Dataset", version: "1"})
      assert dataset.name == "Promoted Trace Dataset"
      assert dataset.state == :open

      items = Eval.list_dataset_items(dataset.id)
      assert length(items) == 1
      item = hd(items)
      
      assert item.input["trace_id"] == trace.id
      assert item.input["session_id"] == "sess-123"
      assert item.input["attributes"] == %{"some" => "attr"}
      assert item.metadata["promoted_from_trace"] == true
      assert item.metadata["span_count"] == 0
    end

    test "promote_workflow_source/1 inserts one immutable dataset item for an original source" do
      {:ok, dataset} = Eval.create_dataset(%{name: "Draft Dataset", version: "3"})

      params = %{
        dataset_id: dataset.id,
        workflow_run_id: Ecto.UUID.generate(),
        workflow_step_id: Ecto.UUID.generate(),
        source_variant: "original",
        provenance: %{
          "source_run_id" => nil,
          "source_checkpoint_id" => nil,
          "execution_mode" => "live",
          "replay_disposition" => nil,
          "replay_reason_code" => nil
        },
        checkpoint_output: %{
          "projected_context" => %{"prompt" => "hello"},
          "result" => %{"answer" => "world"}
        },
        safety: %{},
        promotion_snapshot: %{
          "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "world"}}
        },
        notes: "capture original",
        expected_output: %{"answer" => "world"}
      }

      assert {:ok, item} = Eval.promote_workflow_source(params)

      assert item.dataset_id == dataset.id
      assert item.input["workflow_run_id"] == params.workflow_run_id
      assert item.input["workflow_step_id"] == params.workflow_step_id
      assert item.input["checkpoint_output"] == params.checkpoint_output
      assert item.input["promotion_snapshot"] == params.promotion_snapshot
      assert item.input["notes"] == "capture original"
      assert item.expected_output == %{"answer" => "world"}
      assert item.metadata["promoted_from_workflow"] == true
      assert item.metadata["source_variant"] == "original"
      assert item.metadata["workflow_run_id"] == params.workflow_run_id
      assert item.metadata["workflow_step_id"] == params.workflow_step_id
      assert item.metadata["source_run_id"] == nil
      assert item.metadata["source_checkpoint_id"] == nil
      assert item.metadata["execution_mode"] == "live"
      assert item.metadata["replay_disposition"] == nil
      assert item.metadata["replay_reason_code"] == nil
      assert item.metadata["recorded_outcome"] == %{"kind" => "result", "value" => %{"answer" => "world"}}

      assert [persisted] = Eval.list_dataset_items(dataset.id)
      assert persisted.id == item.id
    end

    test "promote_workflow_source/1 preserves replay provenance metadata" do
      {:ok, dataset} = Eval.create_dataset(%{name: "Replay Draft", version: "4"})
      source_run_id = Ecto.UUID.generate()
      source_checkpoint_id = Ecto.UUID.generate()

      params = %{
        dataset_id: dataset.id,
        workflow_run_id: Ecto.UUID.generate(),
        workflow_step_id: Ecto.UUID.generate(),
        source_variant: "replay",
        provenance: %{
          "source_run_id" => source_run_id,
          "source_checkpoint_id" => source_checkpoint_id,
          "execution_mode" => "replay",
          "replay_disposition" => "historical_stub",
          "replay_reason_code" => "tool_write_blocked"
        },
        checkpoint_output: %{
          "projected_context" => %{"tool" => "publish"},
          "error" => %{"message" => "blocked"}
        },
        safety: %{"replay_scope" => "historical_stub"},
        promotion_snapshot: %{
          "recorded_outcome" => %{"kind" => "error", "error" => %{"message" => "blocked"}}
        },
        expected_output: %{"status" => "review"}
      }

      assert {:ok, item} = Eval.promote_workflow_source(params)

      assert item.metadata["source_variant"] == "replay"
      assert item.metadata["source_run_id"] == source_run_id
      assert item.metadata["source_checkpoint_id"] == source_checkpoint_id
      assert item.metadata["execution_mode"] == "replay"
      assert item.metadata["replay_disposition"] == "historical_stub"
      assert item.metadata["replay_reason_code"] == "tool_write_blocked"
      assert item.metadata["recorded_outcome"] == %{"kind" => "error", "error" => %{"message" => "blocked"}}
    end

    test "promote_workflow_source/1 returns the sealed-dataset error and inserts nothing" do
      {:ok, dataset} = Eval.create_dataset(%{name: "Locked Dataset", version: "2"})
      {:ok, sealed} = Eval.seal_dataset(dataset)

      params = %{
        dataset_id: sealed.id,
        workflow_run_id: Ecto.UUID.generate(),
        workflow_step_id: Ecto.UUID.generate(),
        source_variant: "original",
        provenance: %{"execution_mode" => "live"},
        checkpoint_output: %{"projected_context" => %{}},
        safety: %{},
        promotion_snapshot: %{"recorded_outcome" => %{"kind" => "result"}},
        expected_output: %{}
      }

      assert {:error, changeset} = Eval.promote_workflow_source(params)
      assert {"cannot add or modify items in a sealed dataset", _} = changeset.errors[:dataset_id]
      assert [] == Eval.list_dataset_items(sealed.id)
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

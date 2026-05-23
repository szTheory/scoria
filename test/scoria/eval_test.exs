defmodule Scoria.EvalTest do
  use ExUnit.Case

  alias Scoria.Repo
  alias Scoria.Eval
  alias Scoria.Eval.Dataset
  alias Scoria.Eval.EvalSpec
  alias Scoria.Runtime
  alias Scoria.Workflows

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
      params = runtime_replay_promotion_context()
      source_run_id = get_in(params, [:provenance, :source_run_id])
      source_checkpoint_id = get_in(params, [:provenance, :source_checkpoint_id])

      params = %{
        params
        | dataset_id: dataset.id,
          expected_output: %{"status" => "review"}
      }

      assert {:ok, item} = Eval.promote_workflow_source(params)

      assert item.metadata["source_variant"] == "replay"
      assert item.metadata["source_run_id"] == source_run_id
      assert item.metadata["source_checkpoint_id"] == source_checkpoint_id
      assert item.metadata["execution_mode"] == "replay"
      assert item.metadata["replay_disposition"] == "historical_stub"
      assert item.metadata["replay_reason_code"] == "exact_source_match"
      assert item.metadata["workflow_run_id"] == params.workflow_run_id
      assert item.metadata["workflow_step_id"] == params.workflow_step_id
      assert item.metadata["recorded_outcome"] == %{"kind" => "result", "value" => %{"answer" => "replay"}}
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
    setup do
      {:ok, dataset} =
        Eval.create_dataset(%{
          name: "Spec Dataset",
          version: "2026.05.23",
          items: [%{input: %{"question" => "ready?"}, expected_output: %{"answer" => "yes"}}]
        })

      {:ok, dataset} = Eval.seal_dataset(dataset)

      %{dataset: dataset}
    end

    test "create_eval_spec/1 creates a spec", %{dataset: dataset} do
      assert {:ok, %EvalSpec{} = spec} = Eval.create_eval_spec(valid_spec_attrs(dataset))
      assert spec.version == 1
      assert spec.is_current == true
      assert spec.name == "Test Spec"
      assert spec.entity_id != nil
      assert spec.dataset_id == dataset.id
      assert spec.dataset_version == dataset.version
    end

    test "update_eval_spec/2 creates a new version and deprecates the old one", %{dataset: dataset} do
      {:ok, spec} = Eval.create_eval_spec(valid_spec_attrs(dataset))
      
      update_attrs = %{name: "Updated Spec", threshold_policy: %{pass_rate_gte: 0.95, mean_score_gte: 0.9, max_latency_ms: 450}}
      assert {:ok, %EvalSpec{} = new_spec} = Eval.update_eval_spec(spec, update_attrs)
      
      assert new_spec.version == 2
      assert new_spec.is_current == true
      assert new_spec.name == "Updated Spec"
      assert new_spec.entity_id == spec.entity_id
      assert new_spec.dataset_id == dataset.id
      assert new_spec.threshold_policy[:pass_rate_gte] == 0.95

      old_spec = Repo.get(EvalSpec, spec.id)
      assert old_spec.is_current == false
    end
  end

  defp valid_spec_attrs(dataset) do
    %{
      name: "Test Spec",
      dataset_id: dataset.id,
      dataset_version: dataset.version,
      eval_mode: :offline_replay,
      subject: %{
        subject_kind: :prompt_template,
        prompt_template_id: Ecto.UUID.generate(),
        prompt_entity_id: Ecto.UUID.generate(),
        prompt_version: 1
      },
      scorers: [
        %{
          metric_key: "accuracy",
          scorer_kind: :llm_judge,
          judge_prompt_template_id: Ecto.UUID.generate(),
          judge_prompt_version: 1,
          judge_provider: "openai",
          judge_model: "gpt-4o-mini",
          weight: 1.0
        }
      ],
      threshold_policy: %{
        pass_rate_gte: 0.9,
        mean_score_gte: 0.85,
        max_latency_ms: 500
      }
    }
  end

  defp runtime_replay_promotion_context do
    {:ok, source_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-source-dataset",
        tenant_id: "tenant-source-dataset",
        session_id: "session-source-dataset"
      })

    {:ok, source_step} =
      Workflows.create_step(source_run.id, %{
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        projected_context: %{"prompt" => "source prompt"},
        result_envelope: %{"output" => %{"answer" => "source"}}
      })

    source_checkpoint =
      Repo.insert!(Scoria.Workflows.Checkpoint.changeset(%Scoria.Workflows.Checkpoint{}, %{
        run_id: source_run.id,
        step_id: source_step.id,
        sequence: 2,
        transition: "step_completed",
        status: "completed",
        snapshot: %{"result" => %{"answer" => "source"}}
      }))

    Repo.insert!(Scoria.Workflows.Event.changeset(%Scoria.Workflows.Event{}, %{
      run_id: source_run.id,
      step_id: source_step.id,
      sequence: 2,
      event_type: "step_completed",
      payload: %{"recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "source"}}}
    }))

    {:ok, replay_run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-replay-dataset",
        tenant_id: "tenant-replay-dataset",
        session_id: "session-replay-dataset",
        execution_mode: "replay",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id
      })

    {:ok, replay_step} =
      Workflows.create_step(replay_run.id, %{
        sequence: 1,
        kind: "tool_call",
        role_id: "executor",
        status: "completed",
        projected_context: %{"prompt" => "replay prompt"},
        result_envelope: %{"output" => %{"answer" => "replay"}}
      })

    Repo.insert!(Scoria.Workflows.Checkpoint.changeset(%Scoria.Workflows.Checkpoint{}, %{
      run_id: replay_run.id,
      step_id: replay_step.id,
      sequence: 2,
      transition: "step_completed",
      status: "completed",
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match",
      metadata: %{
        "source_run_id" => source_run.id,
        "source_checkpoint_id" => source_checkpoint.id,
        "source_step_id" => source_step.id
      },
      snapshot: %{
        "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "replay"}}
      }
    }))

    Repo.insert!(Scoria.Workflows.Event.changeset(%Scoria.Workflows.Event{}, %{
      run_id: replay_run.id,
      step_id: replay_step.id,
      sequence: 2,
      event_type: "step_completed",
      payload: %{
        "source_run_id" => source_run.id,
        "source_checkpoint_id" => source_checkpoint.id,
        "source_step_id" => source_step.id,
        "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "replay"}}
      },
      replay_disposition: "historical_stub",
      replay_reason_code: "exact_source_match"
    }))

    detail = Runtime.get_run_detail!(replay_run.id)
    selected_entry = detail.comparison_by_step[replay_step.id].replay

    %{
      dataset_id: nil,
      workflow_run_id: selected_entry.provenance.workflow_run_id,
      workflow_step_id: selected_entry.provenance.workflow_step_id,
      source_variant: selected_entry.provenance.source_variant,
      provenance: Map.drop(selected_entry.provenance, [:replay_disposition, :replay_reason_code]),
      checkpoint_output: selected_entry.checkpoint_output,
      safety: selected_entry.safety,
      promotion_snapshot: selected_entry.promotion_snapshot,
      notes: "",
      expected_output: %{}
    }
  end
end

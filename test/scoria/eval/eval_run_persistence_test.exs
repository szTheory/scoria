defmodule Scoria.Eval.EvalRunPersistenceTest do
  use Scoria.EvalCase, async: true

  alias Scoria.Eval
  alias Scoria.Eval.EvalSpec
  alias Scoria.Eval.EvalRun
  alias Scoria.Eval.Score
  alias Scoria.Repo

  describe "canonical eval persistence" do
    test "eval runs and scores attach to the Phase 24 dataset lineage" do
      {:ok, dataset} =
        Eval.create_dataset(%{
          name: "sealed-regression-dataset",
          version: "2026.05.19",
          items: [
            %{
              input: %{"question" => "What is Scoria?"},
              expected_output: %{"answer" => "An embedded Phoenix AI runtime"},
              metadata: %{"case" => "intro"}
            }
          ]
        })

      {:ok, dataset} = Eval.seal_dataset(dataset)
      [dataset_item] = Eval.list_dataset_items(dataset.id)

      prompt_template_id = Ecto.UUID.generate()
      prompt_entity_id = Ecto.UUID.generate()
      judge_prompt_template_id = Ecto.UUID.generate()

      {:ok, eval_spec} = Eval.create_eval_spec(eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id))

      assert {:ok, eval_run} =
               %EvalRun{}
               |> EvalRun.changeset(%{
                 dataset_id: dataset.id,
                 eval_spec_id: eval_spec.id,
                 status: "completed",
                 duration_ms: 42
               })
               |> Repo.insert()

      assert {:ok, _score} =
               %Score{}
               |> Score.changeset(%{
                 eval_run_id: eval_run.id,
                 dataset_item_id: dataset_item.id,
                 score: 0.95,
                 details: %{"metric" => "accuracy"}
               })
               |> Repo.insert()

      persisted_run =
        EvalRun
        |> Repo.get!(eval_run.id)
        |> Repo.preload([:dataset, scores: [:dataset_item]])

      assert persisted_run.dataset.id == dataset.id
      assert [persisted_score] = persisted_run.scores
      assert persisted_score.dataset_item.id == dataset_item.id
    end

    test "create_eval_spec/1 persists a typed immutable contract and update_eval_spec/2 versions it" do
      {:ok, dataset} =
        Eval.create_dataset(%{
          name: "typed-spec-dataset",
          version: "2026.05.20",
          items: [%{input: %{"question" => "ready?"}, expected_output: %{"answer" => "ready"}}]
        })

      {:ok, dataset} = Eval.seal_dataset(dataset)

      prompt_template_id = Ecto.UUID.generate()
      prompt_entity_id = Ecto.UUID.generate()
      judge_prompt_template_id = Ecto.UUID.generate()

      attrs = eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id)

      assert {:ok, %EvalSpec{} = eval_spec} = Eval.create_eval_spec(attrs)
      assert eval_spec.dataset_id == dataset.id
      assert eval_spec.dataset_version == dataset.version
      assert eval_spec.eval_mode == :offline_replay
      assert eval_spec.subject.subject_kind == :prompt_template
      assert eval_spec.subject.prompt_template_id == prompt_template_id
      assert eval_spec.subject.prompt_entity_id == prompt_entity_id
      assert eval_spec.subject.prompt_version == 3
      assert [scorer] = eval_spec.scorers
      assert scorer.metric_key == "answer_correctness"
      assert scorer.scorer_kind == :llm_judge
      assert scorer.judge_prompt_template_id == judge_prompt_template_id
      assert scorer.judge_prompt_version == 2
      assert scorer.judge_provider == "openai"
      assert scorer.judge_model == "gpt-4o-mini"
      assert scorer.weight == 1.0
      assert eval_spec.threshold_policy.pass_rate_gte == 0.9
      assert eval_spec.threshold_policy.mean_score_gte == 0.85
      assert eval_spec.threshold_policy.max_latency_ms == 500

      assert {:ok, updated_spec} =
               Eval.update_eval_spec(eval_spec, %{
                 threshold_policy: %{
                   pass_rate_gte: 0.95,
                   mean_score_gte: 0.9,
                   max_latency_ms: 450
                 }
               })

      old_spec = Repo.get!(EvalSpec, eval_spec.id)

      assert updated_spec.entity_id == eval_spec.entity_id
      assert updated_spec.version == 2
      assert updated_spec.is_current == true
      assert updated_spec.dataset_id == dataset.id
      assert updated_spec.dataset_version == dataset.version
      assert updated_spec.subject.prompt_template_id == prompt_template_id
      assert updated_spec.scorers |> Enum.map(& &1.metric_key) == ["answer_correctness"]
      assert updated_spec.threshold_policy.pass_rate_gte == 0.95
      assert updated_spec.threshold_policy.max_latency_ms == 450
      assert old_spec.is_current == false

      assert {:error, changeset} =
               Eval.create_eval_spec(
                 Map.merge(attrs, %{
                   dataset_alias: "current",
                   default_judge_model: "gpt-4o"
                 })
               )

      assert {"mutable aliases are not durable eval truth", _} = changeset.errors[:base]
    end
  end

  defp eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id) do
    %{
      name: "offline-replay-spec",
      description: "Deterministic replay contract",
      dataset_id: dataset.id,
      dataset_version: dataset.version,
      eval_mode: :offline_replay,
      subject: %{
        subject_kind: :prompt_template,
        prompt_template_id: prompt_template_id,
        prompt_entity_id: prompt_entity_id,
        prompt_version: 3
      },
      scorers: [
        %{
          metric_key: "answer_correctness",
          scorer_kind: :llm_judge,
          judge_prompt_template_id: judge_prompt_template_id,
          judge_prompt_version: 2,
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
end

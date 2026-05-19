defmodule Scoria.Eval.EvalRunPersistenceTest do
  use Scoria.EvalCase, async: true

  alias Scoria.Eval
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

      {:ok, eval_spec} =
        Eval.create_eval_spec(%{
          name: "offline-replay-spec",
          rubric: %{"metrics" => ["accuracy"]}
        })

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
  end
end

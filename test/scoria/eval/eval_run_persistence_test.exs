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

      {:ok, eval_spec} =
        Eval.create_eval_spec(
          eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id)
        )

      assert {:ok, eval_run} =
               Eval.create_eval_run(%{
                 eval_spec_id: eval_spec.id,
                 runner_mode: :offline_replay,
                 provider: "openai",
                 model: "gpt-4o-mini",
                 judge_provider: "openai",
                 judge_model: "gpt-4o",
                 fixture_key: "prompt-v3/dataset-v2026.05.19/spec-v1",
                 fixture_path: "test/fixtures/eval/offline-replay.json",
                 fixture_sha256: "abc123",
                 baseline_eval_run_id: nil
               })

      assert {:ok, eval_run, [%Score{}]} =
               Eval.record_eval_scores(eval_run, [
                 %{
                   dataset_item_id: dataset_item.id,
                   scorer_kind: "llm_judge",
                   status: "passed",
                   score: 0.95,
                   explanation: "Answer matches the sealed expected output",
                   judge_model: "gpt-4o",
                   rubric_version: "judge-rubric-v2",
                   evidence_refs: %{"fixture_key" => "prompt-v3/dataset-v2026.05.19/spec-v1"},
                   metadata: %{"latency_ms" => 42, "cost_usd" => "0.0004"}
                 }
               ])

      assert {:ok, eval_run} =
               Eval.complete_eval_run(eval_run, %{
                 status: "completed",
                 duration_ms: 42,
                 threshold_verdict: "passed"
               })

      persisted_run =
        EvalRun
        |> Repo.get!(eval_run.id)
        |> Repo.preload([:dataset, scores: [:dataset_item]])

      assert persisted_run.runner_mode == :offline_replay
      assert persisted_run.prompt_template_id == prompt_template_id
      assert persisted_run.prompt_version == 3
      assert persisted_run.dataset.id == dataset.id
      assert persisted_run.dataset_version == dataset.version
      assert persisted_run.eval_spec_version == 1
      assert persisted_run.provider == "openai"
      assert persisted_run.model == "gpt-4o-mini"
      assert persisted_run.judge_provider == "openai"
      assert persisted_run.judge_model == "gpt-4o"
      assert persisted_run.fixture_sha256 == "abc123"
      assert persisted_run.total_items == 1
      assert persisted_run.passed_items == 1
      assert persisted_run.failed_items == 0
      assert persisted_run.avg_latency_ms == 42
      assert Decimal.equal?(persisted_run.total_cost_usd, Decimal.new("0.0004"))
      assert persisted_run.threshold_verdict == "passed"
      assert [persisted_score] = persisted_run.scores
      assert persisted_score.dataset_item.id == dataset_item.id
      assert persisted_score.scorer_kind == "llm_judge"
      assert persisted_score.status == "passed"
      assert persisted_score.explanation == "Answer matches the sealed expected output"
      assert persisted_score.judge_model == "gpt-4o"
      assert persisted_score.rubric_version == "judge-rubric-v2"

      assert persisted_score.evidence_refs["fixture_key"] ==
               "prompt-v3/dataset-v2026.05.19/spec-v1"
    end

    test "create_eval_run/1 persists campaign lineage and tenant identity" do
      {:ok, dataset} =
        Eval.create_dataset(%{
          name: "campaign-lineage-dataset",
          version: "2026.05.21",
          items: [
            %{
              input: %{"question" => "ready?"},
              expected_output: %{"answer" => "ready"}
            }
          ]
        })

      {:ok, dataset} = Eval.seal_dataset(dataset)

      {:ok, eval_spec} =
        Eval.create_eval_spec(
          eval_spec_attrs(
            dataset,
            Ecto.UUID.generate(),
            Ecto.UUID.generate(),
            Ecto.UUID.generate()
          )
        )

      assert {:ok, campaign} =
               Eval.create_eval_campaign(%{
                 tenant_id: "tenant-alpha",
                 eval_spec_id: eval_spec.id,
                 targets: [
                   %{
                     tenant_id: "tenant-alpha",
                     provider: "openai",
                     model: "gpt-4o-mini",
                     queue: "evals",
                     priority: 1
                   }
                 ]
               })

      [target] = Eval.list_campaign_targets(campaign.id)

      assert {:ok, eval_run} =
               Eval.create_eval_run(%{
                 eval_spec_id: eval_spec.id,
                 runner_mode: :offline_replay,
                 tenant_id: "tenant-alpha",
                 campaign_id: campaign.id,
                 campaign_target_id: target.id,
                 provider: target.provider,
                 model: target.model
               })

      persisted_run = Repo.get!(EvalRun, eval_run.id)

      assert persisted_run.tenant_id == "tenant-alpha"
      assert persisted_run.campaign_id == campaign.id
      assert persisted_run.campaign_target_id == target.id
      assert persisted_run.provider == "openai"
      assert persisted_run.model == "gpt-4o-mini"
    end

    test "legacy eval runs without campaign lineage remain compatible" do
      {:ok, dataset} =
        Eval.create_dataset(%{
          name: "legacy-run-dataset",
          version: "2026.05.21",
          items: [
            %{
              input: %{"question" => "What is Scoria?"},
              expected_output: %{"answer" => "An embedded Phoenix AI runtime"},
              metadata: %{"case" => "legacy"}
            }
          ]
        })

      {:ok, dataset} = Eval.seal_dataset(dataset)
      [dataset_item] = Eval.list_dataset_items(dataset.id)

      prompt_template_id = Ecto.UUID.generate()
      prompt_entity_id = Ecto.UUID.generate()
      judge_prompt_template_id = Ecto.UUID.generate()

      {:ok, eval_spec} =
        Eval.create_eval_spec(
          eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id)
        )

      legacy_run_id = Ecto.UUID.generate()
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {1, nil} =
               Repo.insert_all(
                 "ai_eval_runs",
                 [
                   %{
                     id: legacy_run_id,
                     runner_mode: "offline_replay",
                     status: "pending",
                     dataset_id: dataset.id,
                     dataset_version: dataset.version,
                     eval_spec_id: eval_spec.id,
                     eval_spec_version: eval_spec.version,
                     prompt_template_id: prompt_template_id,
                     prompt_version: 3,
                     provider: "openai",
                     model: "gpt-4o-mini",
                     inserted_at: now,
                     updated_at: now
                   }
                 ]
               )

      legacy_run = Repo.get!(EvalRun, legacy_run_id)
      assert is_nil(legacy_run.tenant_id)
      assert is_nil(legacy_run.campaign_id)
      assert is_nil(legacy_run.campaign_target_id)

      assert {:ok, updated_run, [%Score{}]} =
               Eval.record_eval_scores(legacy_run, [
                 %{
                   dataset_item_id: dataset_item.id,
                   scorer_kind: "llm_judge",
                   status: "passed",
                   score: 1.0,
                   explanation: "Legacy run still aggregates",
                   judge_model: "gpt-4o",
                   rubric_version: "judge-rubric-v2",
                   metadata: %{"latency_ms" => 20, "cost_usd" => "0.0002"}
                 }
               ])

      assert {:ok, completed_run} =
               Eval.complete_eval_run(updated_run, %{status: "completed", threshold_verdict: "passed"})

      reloaded = Repo.get!(EvalRun, completed_run.id)
      assert reloaded.status == "completed"
      assert reloaded.passed_items == 1
      assert is_nil(reloaded.tenant_id)
      assert is_nil(reloaded.campaign_id)
      assert is_nil(reloaded.campaign_target_id)
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

      attrs =
        eval_spec_attrs(dataset, prompt_template_id, prompt_entity_id, judge_prompt_template_id)

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

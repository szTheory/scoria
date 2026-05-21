defmodule Scoria.Eval.EvalCampaignPersistenceTest do
  use Scoria.EvalCase, async: true

  alias Scoria.Eval
  alias Scoria.Eval.EvalCampaign
  alias Scoria.Repo

  describe "campaign persistence" do
    test "create_eval_campaign/1 persists campaign truth and runtime-only targets" do
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)

      assert {:ok, %EvalCampaign{} = campaign} =
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
                   },
                   %{
                     tenant_id: "tenant-beta",
                     provider: "anthropic",
                     model: "claude-3-5-sonnet",
                     queue: "evals",
                     priority: 2,
                     metadata: %{"lane" => "beta"}
                   }
                 ]
               })

      persisted_campaign = Repo.get!(EvalCampaign, campaign.id)
      persisted_targets = Eval.list_campaign_targets(campaign.id)

      assert persisted_campaign.eval_spec_id == eval_spec.id
      assert persisted_campaign.tenant_id == "tenant-alpha"
      assert persisted_campaign.status == "queued"
      assert persisted_campaign.total_targets == 2
      assert persisted_campaign.queued_targets == 2
      assert persisted_campaign.running_targets == 0
      assert persisted_campaign.completed_targets == 0
      assert persisted_campaign.failed_targets == 0
      assert persisted_campaign.cancelled_targets == 0
      assert is_nil(persisted_campaign.started_at)
      assert is_nil(persisted_campaign.finished_at)

      assert Enum.count(persisted_targets) == 2

      assert Enum.map(persisted_targets, & &1.eval_spec_id) == [eval_spec.id, eval_spec.id]
      assert Enum.map(persisted_targets, & &1.campaign_id) == [campaign.id, campaign.id]
      assert Enum.map(persisted_targets, & &1.status) == ["pending", "pending"]
      assert Enum.map(persisted_targets, & &1.queue) == ["evals", "evals"]
      assert Enum.map(persisted_targets, & &1.tenant_id) == ["tenant-alpha", "tenant-beta"]
    end

    test "target attrs reject semantic override fields" do
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)

      assert {:error, changeset} =
               Eval.create_eval_campaign(%{
                 tenant_id: "tenant-alpha",
                 eval_spec_id: eval_spec.id,
                 targets: [
                   %{
                     tenant_id: "tenant-alpha",
                     provider: "openai",
                     model: "gpt-4o-mini",
                     queue: "evals",
                     priority: 1,
                     prompt_version: 99,
                     dataset_slice: %{"kind" => "shadow"},
                     threshold_policy: %{"pass_rate_gte" => 1.0},
                     judge_definition: %{"model" => "gpt-4o"}
                   }
                 ]
               })

      errors = errors_on(changeset)

      assert "contains unsupported semantic override fields: dataset_slice, judge_definition, prompt_version, threshold_policy" in errors.targets
    end
  end

  defp create_sealed_dataset do
    Eval.create_dataset(%{
      name: "campaign-dataset",
      version: "2026.05.21",
      items: [
        %{
          input: %{"question" => "What is Scoria?"},
          expected_output: %{"answer" => "An embedded Phoenix AI runtime"}
        }
      ]
    })
    |> then(fn {:ok, dataset} -> Eval.seal_dataset(dataset) end)
  end

  defp create_eval_spec(dataset) do
    Eval.create_eval_spec(%{
      name: "campaign-spec",
      description: "Shared immutable contract",
      dataset_id: dataset.id,
      dataset_version: dataset.version,
      eval_mode: :offline_replay,
      subject: %{
        subject_kind: :prompt_template,
        prompt_template_id: Ecto.UUID.generate(),
        prompt_entity_id: Ecto.UUID.generate(),
        prompt_version: 3
      },
      scorers: [
        %{
          metric_key: "answer_correctness",
          scorer_kind: :llm_judge,
          judge_prompt_template_id: Ecto.UUID.generate(),
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
    })
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

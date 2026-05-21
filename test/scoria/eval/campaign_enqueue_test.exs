defmodule Scoria.Eval.CampaignEnqueueTest do
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Scoria.Repo

  import Ecto.Query

  alias Scoria.Eval
  alias Scoria.Eval.{CampaignWorker, EvalCampaign, EvalCampaignTarget, EvalRun}
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "create_and_enqueue_campaign/2" do
    test "persists one campaign, one run per target, and enqueues one eval worker per target" do
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)

      assert {:ok, result} =
               Eval.create_and_enqueue_campaign(
                 %{
                   tenant_id: "tenant-root",
                   eval_spec_id: eval_spec.id,
                   targets: [
                     target_attrs("tenant-alpha", "openai", "gpt-4o-mini"),
                     target_attrs("tenant-beta", "anthropic", "claude-3-5-sonnet"),
                     target_attrs("tenant-gamma", "openai", "gpt-4.1-mini")
                   ]
                 },
                 chunk_size: 2
               )

      assert %EvalCampaign{} = result.campaign
      assert %{"batch_0" => [job_1, job_2], "batch_1" => [job_3]} = result.enqueue_results
      assert job_1.id
      assert job_2.id
      assert job_3.id

      campaign = Repo.get!(EvalCampaign, result.campaign.id)
      targets = Eval.list_campaign_targets(campaign.id)
      eval_runs = Repo.all(from(run in EvalRun, where: run.campaign_id == ^campaign.id, order_by: [asc: run.inserted_at, asc: run.id]))

      assert campaign.eval_spec_id == eval_spec.id
      assert campaign.tenant_id == "tenant-root"
      assert campaign.status == "queued"
      assert campaign.total_targets == 3
      assert campaign.queued_targets == 3
      assert campaign.running_targets == 0
      assert campaign.completed_targets == 0
      assert campaign.failed_targets == 0
      assert campaign.cancelled_targets == 0

      assert Enum.count(targets) == 3
      assert Enum.count(eval_runs) == 3
      assert Enum.map(targets, & &1.status) == ["pending", "pending", "pending"]
      assert Enum.map(eval_runs, & &1.status) == ["pending", "pending", "pending"]
      assert Enum.map(eval_runs, & &1.campaign_target_id) == Enum.map(targets, & &1.id)

      for target <- targets do
        eval_run = Enum.find(eval_runs, &(&1.campaign_target_id == target.id))

        assert eval_run
        assert eval_run.campaign_id == campaign.id
        assert eval_run.eval_spec_id == eval_spec.id
        assert eval_run.tenant_id == target.tenant_id
        assert eval_run.provider == target.provider
        assert eval_run.model == target.model

        assert_enqueued(
          worker: CampaignWorker,
          queue: :evals,
          args: %{
            "campaign_id" => campaign.id,
            "campaign_target_id" => target.id,
            "eval_run_id" => eval_run.id,
            "tenant_id" => target.tenant_id,
            "eval_spec_id" => eval_spec.id,
            "provider" => target.provider,
            "model" => target.model
          }
        )
      end
    end

    test "jobs carry replay-safe identity and queue metadata" do
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)

      assert {:ok, result} =
               Eval.create_and_enqueue_campaign(%{
                 tenant_id: "tenant-root",
                 eval_spec_id: eval_spec.id,
                 targets: [
                   target_attrs("tenant-alpha", "openai", "gpt-4o-mini", %{
                     priority: 7,
                     metadata: %{"lane" => "nightly"}
                   })
                 ]
               })

      campaign = result.campaign
      [target] = Eval.list_campaign_targets(campaign.id)
      [eval_run] = Repo.all(from(run in EvalRun, where: run.campaign_id == ^campaign.id))

      assert target.queue == "evals"
      assert target.priority == 7
      assert target.metadata == %{"lane" => "nightly"}
      assert eval_run.tenant_id == "tenant-alpha"

      assert_enqueued(
        worker: CampaignWorker,
        queue: :evals,
        priority: 7,
        args: %{
          "campaign_id" => campaign.id,
          "campaign_target_id" => target.id,
          "eval_run_id" => eval_run.id,
          "tenant_id" => "tenant-alpha",
          "eval_spec_id" => eval_spec.id,
          "provider" => "openai",
          "model" => "gpt-4o-mini",
          "metadata" => %{"lane" => "nightly"}
        }
      )
    end

    test "rejects semantic overrides and duplicate identical targets during normalization" do
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)

      assert {:error, changeset} =
               Eval.create_and_enqueue_campaign(%{
                 tenant_id: "tenant-root",
                 eval_spec_id: eval_spec.id,
                 targets: [
                   target_attrs("tenant-alpha", "openai", "gpt-4o-mini", %{
                     prompt_version: 99
                   }),
                   target_attrs("tenant-beta", "anthropic", "claude-3-5-sonnet"),
                   target_attrs("tenant-beta", "anthropic", "claude-3-5-sonnet")
                 ]
               })

      errors = errors_on(changeset)

      assert "contains unsupported semantic override fields: prompt_version" in errors.targets
      assert "contains duplicate runtime targets" in errors.targets

      assert Repo.aggregate(EvalCampaign, :count) == 0
      assert Repo.aggregate(EvalCampaignTarget, :count) == 0
      assert Repo.aggregate(EvalRun, :count) == 0
      refute_enqueued(worker: CampaignWorker)
    end
  end

  describe "CampaignWorker.new_job/2" do
    test "normalizes the async contract used by the coordinator" do
      job =
        CampaignWorker.new_job(%{
          "campaign_id" => "campaign-1",
          :campaign_target_id => "target-1",
          "eval_run_id" => "run-1",
          :tenant_id => "tenant-1",
          "eval_spec_id" => "spec-1",
          :provider => "openai",
          "model" => "gpt-4o-mini",
          :metadata => %{lane: "nightly"}
        }, priority: 4)

      assert job.queue == "evals"
      assert job.priority == 4
      assert job.args == %{
               "campaign_id" => "campaign-1",
               "campaign_target_id" => "target-1",
               "eval_run_id" => "run-1",
               "tenant_id" => "tenant-1",
               "eval_spec_id" => "spec-1",
               "provider" => "openai",
               "model" => "gpt-4o-mini",
               "metadata" => %{"lane" => "nightly"}
             }
    end
  end

  defp create_sealed_dataset do
    Eval.create_dataset(%{
      name: "campaign-enqueue-dataset",
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
      name: "campaign-enqueue-spec",
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

  defp target_attrs(tenant_id, provider, model, overrides \\ %{}) do
    Map.merge(
      %{
        tenant_id: tenant_id,
        provider: provider,
        model: model,
        queue: "evals",
        priority: 1,
        metadata: %{}
      },
      overrides
    )
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

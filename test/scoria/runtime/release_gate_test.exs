defmodule Scoria.Runtime.ReleaseGateTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.Runtime.ReleaseGate

  setup do
    original = Application.get_env(:scoria, :require_eval_verdict, false)
    Application.put_env(:scoria, :require_eval_verdict, false)

    on_exit(fn -> Application.put_env(:scoria, :require_eval_verdict, original) end)

    :ok
  end

  describe "check/1" do
    test "returns {:error, :unapproved_draft} for draft prompts before consulting eval verdicts" do
      template = insert_prompt_template(status: "draft")
      insert_completed_eval_run(template, "passed")

      assert {:error, :unapproved_draft} = ReleaseGate.check(template)
    end

    test "returns :ok for active prompts with no persisted id" do
      template = %PromptTemplate{status: "active"}
      assert :ok = ReleaseGate.check(template)
    end

    test "returns :ok if passed nil or unknown" do
      assert :ok = ReleaseGate.check(nil)
    end

    test "allows the latest completed passed verdict for the prompt template" do
      template = insert_prompt_template()
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      insert_completed_eval_run(template, "failed", inserted_at: DateTime.add(now, -60, :second))
      insert_completed_eval_run(template, "passed", inserted_at: now)

      assert :ok = ReleaseGate.check(template)
    end

    test "blocks failed, inconclusive, and unknown completed verdicts with the specific verdict" do
      for verdict <- ["failed", "inconclusive", "unexpected"] do
        template = insert_prompt_template()
        insert_completed_eval_run(template, verdict)

        assert {:error, {:eval_not_passing, ^verdict}} = ReleaseGate.check(template)
      end
    end

    test "emits ungated telemetry and allows by default when no completed verdict exists" do
      template = insert_prompt_template()
      attach_release_gate_telemetry()

      assert :ok = ReleaseGate.check(template)

      assert_receive {:release_gate_telemetry, [:scoria, :release_gate, :ungated], %{},
                      %{prompt_template_id: prompt_template_id}}

      assert prompt_template_id == template.id
    end

    test "requires a completed verdict when strict mode is enabled" do
      template = insert_prompt_template()
      Application.put_env(:scoria, :require_eval_verdict, true)

      assert {:error, :eval_required} = ReleaseGate.check(template)
    end

    test "excludes online-scoring campaigns but counts legit offline campaign runs" do
      template = insert_prompt_template()
      Application.put_env(:scoria, :require_eval_verdict, true)

      insert_completed_eval_run(template, "passed",
        campaign_metadata: %{"source" => "online_scoring"}
      )

      assert {:error, :eval_required} = ReleaseGate.check(template)

      insert_completed_eval_run(template, "passed",
        campaign_metadata: %{"source" => "offline_replay"}
      )

      assert :ok = ReleaseGate.check(template)
    end

    test "propagates lookup database errors instead of allowing the release" do
      template = %PromptTemplate{id: Ecto.UUID.generate(), status: "active"}
      :ok = Ecto.Adapters.SQL.Sandbox.checkin(Repo)

      assert_raise DBConnection.OwnershipError, fn ->
        ReleaseGate.check(template)
      end
    end
  end

  describe "runtime integration" do
    test "Scoria.Runtime invocation fails with :unapproved_draft when attempting to invoke a draft prompt" do
      template =
        Repo.insert!(%PromptTemplate{
          entity_id: Ecto.UUID.generate(),
          version: 1,
          status: "draft",
          system_message: "sys",
          user_template: "user",
          is_current: true
        })

      identity = %{
        actor_id: "actor-1",
        tenant_id: "tenant-1",
        session_id: "session-1"
      }

      opts = [
        runtime: %{
          prompt_policy: %{
            prompt_ref: template.id
          }
        }
      ]

      assert {:error, :unapproved_draft} = Runtime.start_run(identity, opts)
    end
  end

  defp attach_release_gate_telemetry do
    parent = self()
    handler_id = "release-gate-test-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scoria, :release_gate, :ungated],
      fn event, measurements, metadata, _config ->
        send(parent, {:release_gate_telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  defp insert_prompt_template(attrs \\ []) do
    attrs = Enum.into(attrs, %{})

    Repo.insert!(%PromptTemplate{
      entity_id: Map.get(attrs, :entity_id, Ecto.UUID.generate()),
      version: Map.get(attrs, :version, 1),
      status: Map.get(attrs, :status, "active"),
      system_message: Map.get(attrs, :system_message, "sys"),
      user_template: Map.get(attrs, :user_template, "user"),
      is_current: Map.get(attrs, :is_current, true)
    })
  end

  defp insert_completed_eval_run(%PromptTemplate{} = template, verdict, opts \\ []) do
    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "release-gate-#{System.unique_integer([:positive])}",
        version: "1",
        items: [
          %{
            input: %{"question" => "ready?"},
            expected_output: %{"answer" => "ready"}
          }
        ]
      })

    {:ok, dataset} = Eval.seal_dataset(dataset)

    {:ok, eval_spec} =
      Eval.create_eval_spec(%{
        name: "release-gate-spec-#{System.unique_integer([:positive])}",
        dataset_id: dataset.id,
        dataset_version: dataset.version,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_template_id: template.id,
          prompt_entity_id: template.entity_id,
          prompt_version: template.version
        },
        scorers: [
          %{
            metric_key: "answer_correctness",
            scorer_kind: :llm_judge,
            judge_prompt_template_id: Ecto.UUID.generate(),
            judge_prompt_version: 1,
            judge_provider: "openai",
            judge_model: "gpt-4o-mini",
            weight: 1.0
          }
        ],
        threshold_policy: %{
          pass_rate_gte: 1.0,
          mean_score_gte: 1.0,
          max_latency_ms: 500
        }
      })

    campaign_id =
      opts
      |> Keyword.get(:campaign_metadata)
      |> maybe_insert_campaign(eval_spec)

    {:ok, eval_run} =
      Eval.create_eval_run(%{
        eval_spec_id: eval_spec.id,
        runner_mode: :offline_replay,
        tenant_id: "tenant-release-gate",
        campaign_id: campaign_id,
        provider: "openai",
        model: "gpt-4o-mini"
      })

    {:ok, completed_run} =
      Eval.complete_eval_run(eval_run, %{
        status: "completed",
        threshold_verdict: verdict
      })

    inserted_at = Keyword.get(opts, :inserted_at)

    if inserted_at do
      completed_run
      |> Ecto.Changeset.change(inserted_at: inserted_at)
      |> Repo.update!()
    else
      completed_run
    end
  end

  defp maybe_insert_campaign(nil, _eval_spec), do: nil

  defp maybe_insert_campaign(metadata, eval_spec) do
    {:ok, campaign} =
      Eval.create_eval_campaign(%{
        tenant_id: "tenant-release-gate",
        eval_spec_id: eval_spec.id,
        metadata: metadata,
        targets: []
      })

    campaign.id
  end
end

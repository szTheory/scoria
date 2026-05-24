defmodule Scoria.Eval do
  @moduledoc """
  The Eval context for managing datasets, evaluation specs, and runs.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Scoria.Repo

  alias Scoria.Eval.Dataset
  alias Scoria.Eval.DatasetItem
  alias Scoria.Eval.DatasetPromotion
  alias Scoria.Eval.CampaignEnqueuer
  alias Scoria.Eval.EvalCampaign
  alias Scoria.Eval.EvalCampaignTarget
  alias Scoria.Eval.EvalSpec
  alias Scoria.Eval.EvalRun
  alias Scoria.Eval.JudgeRunner
  alias Scoria.Eval.OnlineScoring
  alias Scoria.Eval.OnlineScoreSampler
  alias Scoria.Eval.ReviewQueue
  alias Scoria.Eval.Score

  @doc """
  Returns the list of datasets.
  """
  def list_datasets do
    Repo.all(Dataset)
  end

  @doc """
  Gets a single dataset.
  """
  def get_dataset!(id), do: Repo.get!(Dataset, id)

  @doc """
  Creates a dataset with state `:open`.
  Assigns version to "1" if not provided.
  """
  def create_dataset(attrs \\ %{}) do
    {items, dataset_attrs} = Map.pop(attrs, :items, [])

    attrs_with_defaults =
      dataset_attrs
      |> Map.put_new(:version, "1")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
    |> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
      items_results =
        Enum.map(items, fn item_attrs ->
          item_attrs_with_fk = Map.put(item_attrs, :dataset_id, dataset.id)

          %DatasetItem{}
          |> DatasetItem.changeset(item_attrs_with_fk, dataset.state)
          |> repo.insert()
        end)

      # Check for errors in items
      case Enum.find(items_results, fn {status, _} -> status == :error end) do
        nil -> {:ok, Enum.map(items_results, fn {:ok, item} -> item end)}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{dataset: dataset}} -> {:ok, dataset}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Seals a dataset, making it immutable.
  """
  def seal_dataset(%Dataset{} = dataset) do
    dataset
    |> Ecto.Changeset.change(state: :sealed)
    |> Repo.update()
  end

  @doc """
  Adds an item to a dataset, checking its state.
  """
  def add_dataset_item(dataset_id, attrs) do
    dataset = get_dataset!(dataset_id)

    attrs_with_fk = Map.put(attrs, :dataset_id, dataset.id)

    %DatasetItem{}
    |> DatasetItem.changeset(attrs_with_fk, dataset.state)
    |> Repo.insert()
  end

  @doc """
  Builds a frozen preview for workflow-source promotion into a dataset item.
  """
  def preview_workflow_source_promotion(attrs) when is_map(attrs) do
    DatasetPromotion.preview(attrs)
  end

  @doc """
  Promotes one original or replay workflow source into an existing dataset.
  """
  def promote_workflow_source(attrs) when is_map(attrs) do
    DatasetPromotion.promote(attrs, &get_dataset!/1)
  end

  @doc """
  Returns the list of dataset items for a given dataset id.
  """
  def list_dataset_items(dataset_id) do
    Repo.all(from(i in DatasetItem, where: i.dataset_id == ^dataset_id))
  end

  @doc """
  Promotes a Trace and its Spans into a new Dataset snapshot.
  """
  def promote_trace_to_dataset(trace, dataset_attrs \\ %{}) do
    spans = if Ecto.assoc_loaded?(trace.spans), do: trace.spans, else: []

    item_attrs = %{
      input: %{
        "trace_id" => trace.id,
        "session_id" => trace.session_id,
        "attributes" => trace.attributes || %{}
      },
      expected_output: %{},
      metadata: %{
        "promoted_from_trace" => true,
        "span_count" => length(spans)
      }
    }

    dataset_attrs
    |> Map.put(:items, [item_attrs])
    |> create_dataset()
  end

  @doc """
  Returns the list of current eval specs.
  """
  def list_eval_specs do
    Repo.all(from(s in EvalSpec, where: s.is_current == true, order_by: [desc: s.updated_at]))
  end

  @doc """
  Gets a single eval spec.
  """
  def get_eval_spec!(id), do: Repo.get!(EvalSpec, id)

  @doc """
  Creates an eval spec.
  """
  def create_eval_spec(attrs \\ %{}) do
    attrs_with_defaults =
      attrs
      |> put_new_attr(:entity_id, Ecto.UUID.generate())
      |> put_new_attr(:version, 1)
      |> put_new_attr(:is_current, true)
      |> put_dataset_snapshot!()

    %EvalSpec{}
    |> EvalSpec.changeset(attrs_with_defaults)
    |> Repo.insert()
  end

  @doc """
  Updates an eval spec immutably.
  """
  def update_eval_spec(%EvalSpec{} = old_spec, attrs) do
    old_spec_changeset = Ecto.Changeset.change(old_spec, is_current: false)

    stringified_attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    base_attrs =
      old_spec
      |> EvalSpec.to_attrs()
      |> Map.put(:version, old_spec.version + 1)
      |> Map.put(:is_current, true)
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.merge(stringified_attrs)
      |> put_dataset_snapshot!()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:deprecate_old, old_spec_changeset)
    |> Ecto.Multi.insert(:new_spec, EvalSpec.changeset(%EvalSpec{}, base_attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{new_spec: new_spec}} -> {:ok, new_spec}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Creates an eval run with resolved spec and dataset snapshot facts.
  """
  def create_eval_run(attrs \\ %{}) do
    eval_spec = get_eval_spec!(fetch_attr!(attrs, :eval_spec_id))

    attrs_with_defaults =
      attrs
      |> put_new_attr(:dataset_id, eval_spec.dataset_id)
      |> put_new_attr(:dataset_version, eval_spec.dataset_version)
      |> put_new_attr(:eval_spec_version, eval_spec.version)
      |> put_new_attr(:prompt_template_id, fetch_attr(eval_spec.subject, :prompt_template_id))
      |> put_new_attr(:prompt_version, fetch_attr(eval_spec.subject, :prompt_version))
      |> put_new_attr(:status, "pending")

    %EvalRun{}
    |> EvalRun.changeset(attrs_with_defaults)
    |> Repo.insert()
  end

  @doc """
  Creates a campaign parent row and its runtime-only target rows atomically.
  """
  def create_eval_campaign(attrs \\ %{}) do
    attrs = Map.new(attrs)
    targets = Map.get(attrs, :targets) || Map.get(attrs, "targets") || []
    eval_spec_id = fetch_attr!(attrs, :eval_spec_id)
    tenant_id = fetch_attr!(attrs, :tenant_id)

    campaign_attrs =
      attrs
      |> Map.drop([:targets, "targets"])
      |> Map.put(:tenant_id, tenant_id)
      |> Map.put(:eval_spec_id, eval_spec_id)
      |> Map.put_new(:status, "queued")
      |> Map.put_new(:total_targets, length(targets))
      |> Map.put_new(:queued_targets, length(targets))
      |> Map.put_new(:running_targets, 0)
      |> Map.put_new(:completed_targets, 0)
      |> Map.put_new(:failed_targets, 0)
      |> Map.put_new(:cancelled_targets, 0)
      |> Map.put_new(:metadata, %{})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:campaign, EvalCampaign.changeset(%EvalCampaign{}, campaign_attrs))
    |> Ecto.Multi.run(:targets, fn repo, %{campaign: campaign} ->
      insert_campaign_targets(repo, campaign, eval_spec_id, targets)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{campaign: campaign}} -> {:ok, campaign}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Creates a campaign, child target rows, child eval runs, and batch-enqueues worker jobs.
  """
  def create_and_enqueue_campaign(attrs, opts \\ []) when is_map(attrs) do
    CampaignEnqueuer.enqueue_campaign(attrs, opts)
  end

  @doc """
  Schedules online scoring sampling for a persisted trace on an async boundary.
  """
  def sample_trace_for_online_scoring(attrs, opts \\ []) when is_map(attrs) do
    OnlineScoreSampler.schedule_sample(attrs, opts)
  end

  @doc """
  Lists projected review-queue candidates for the operator UI.
  """
  def list_review_queue(filters \\ %{}) do
    ReviewQueue.list_candidates(filters)
  end

  @doc """
  Returns summary strip counts for the projected review queue.
  """
  def summarize_review_queue(filters \\ %{}) do
    ReviewQueue.summary(filters)
  end

  @doc """
  Returns one projected review candidate or nil.
  """
  def get_review_candidate(candidate_id) do
    ReviewQueue.get_candidate(candidate_id)
  end

  @doc """
  Dismisses one active review candidate without removing durable score evidence.
  """
  def dismiss_review_candidate(candidate_id) do
    ReviewQueue.dismiss_candidate(candidate_id)
  end

  @doc """
  Promotes one review candidate into an open dataset and records durable queue lineage.
  """
  def promote_review_candidate(candidate_id, attrs) when is_map(attrs) do
    ReviewQueue.promote_candidate(candidate_id, attrs)
  end

  @doc """
  Requests sealed-baseline approval from one review candidate and keeps approval lineage visible.
  """
  def request_review_candidate_baseline_approval(candidate_id, attrs) when is_map(attrs) do
    ReviewQueue.request_baseline_approval(candidate_id, attrs)
  end

  @doc """
  Lists campaign targets in insertion order.
  """
  def list_campaign_targets(campaign_id) do
    Repo.all(
      from(target in EvalCampaignTarget,
        where: target.campaign_id == ^campaign_id,
        order_by: [asc: target.inserted_at, asc: target.id]
      )
    )
  end

  @doc """
  Marks an eval run complete and persists final aggregate facts.
  """
  def complete_eval_run(%EvalRun{} = eval_run, attrs) do
    attrs_with_defaults = put_new_attr(attrs, :status, "completed")

    eval_run
    |> EvalRun.changeset(attrs_with_defaults)
    |> Repo.update()
  end

  @doc """
  Persists per-item eval score evidence and updates aggregate run counters.
  """
  def record_eval_scores(%EvalRun{} = eval_run, score_attrs_list)
      when is_list(score_attrs_list) do
    persist_eval_scores(eval_run, score_attrs_list, replace?: false)
  end

  @doc """
  Replaces prior score truth for an eval run, keeping worker retries idempotent.
  """
  def replace_eval_scores(%EvalRun{} = eval_run, score_attrs_list)
      when is_list(score_attrs_list) do
    persist_eval_scores(eval_run, score_attrs_list, replace?: true)
  end

  @doc """
  Resolves the authoritative campaign/target/run lineage for a worker envelope.
  Persisted lineage remains the durable tenant truth even when envelope tenant data differs.
  """
  def load_campaign_execution(args) when is_map(args) do
    campaign_id = fetch_attr!(args, :campaign_id)
    campaign_target_id = fetch_attr!(args, :campaign_target_id)
    eval_run_id = fetch_attr!(args, :eval_run_id)

    with %EvalCampaign{} = campaign <- Repo.get(EvalCampaign, campaign_id),
         %EvalCampaignTarget{} = target <- Repo.get(EvalCampaignTarget, campaign_target_id),
         %EvalRun{} = eval_run <- Repo.get(EvalRun, eval_run_id),
         true <- target.campaign_id == campaign.id,
         true <- eval_run.campaign_id == campaign.id and eval_run.campaign_target_id == target.id,
         %EvalSpec{} = eval_spec <- Repo.get(EvalSpec, target.eval_spec_id) do
      {:ok,
       %{
         campaign: campaign,
         target: target,
         eval_run: eval_run,
         eval_spec: eval_spec,
         envelope: inspectable_envelope(args)
       }}
    else
      nil -> {:error, {:invalid_campaign_contract, :missing_lineage}}
      false -> {:error, {:invalid_campaign_contract, :lineage_mismatch}}
    end
  end

  @doc """
  Moves a pending shard to running and refreshes aggregate campaign counters.
  """
  def mark_campaign_target_running(%{
        campaign: campaign,
        target: %EvalCampaignTarget{} = target,
        eval_run: %EvalRun{} = eval_run
      }) do
    timestamp = now()

    Multi.new()
    |> Multi.run(:target, fn repo, _changes ->
      fresh_target = repo.get!(EvalCampaignTarget, target.id)

      case fresh_target.status do
        "pending" ->
          fresh_target
          |> EvalCampaignTarget.changeset(%{
            status: "running",
            started_at: timestamp,
            last_error: %{}
          })
          |> repo.update()

        _ ->
          {:ok, fresh_target}
      end
    end)
    |> Multi.run(:eval_run, fn repo, _changes ->
      fresh_run = repo.get!(EvalRun, eval_run.id)

      case fresh_run.status do
        "pending" ->
          fresh_run
          |> EvalRun.changeset(%{status: "running"})
          |> repo.update()

        _ ->
          {:ok, fresh_run}
      end
    end)
    |> Multi.run(:campaign, fn repo, _changes ->
      refresh_campaign_rollup(repo, campaign.id, true)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{campaign: updated_campaign}} -> {:ok, updated_campaign}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Executes one campaign target through the shared orchestrator-backed judge path.
  """
  def execute_campaign_target(%{
        target: %EvalCampaignTarget{} = target,
        eval_run: %EvalRun{} = eval_run,
        eval_spec: %EvalSpec{} = eval_spec
      }) do
    cond do
      target.status == "completed" and eval_run.status == "completed" and has_scores?(eval_run.id) ->
        {:ok, %{eval_run: eval_run, scores: list_scores(eval_run.id)}}

      target.status in ["failed", "cancelled"] ->
        {:error, :target_already_terminal}

      online_scoring_target?(target) ->
        OnlineScoring.execute_candidate(eval_run, %{
          target: target,
          eval_spec: eval_spec,
          dataset: get_dataset!(eval_run.dataset_id)
        })

      true ->
        JudgeRunner.run_existing(eval_run, %{
          eval_spec: eval_spec,
          dataset: get_dataset!(eval_run.dataset_id),
          provider: target.provider,
          model: target.model
        })
    end
  end

  @doc """
  Finalizes a successful shard and updates the parent campaign summary row.
  """
  def complete_campaign_target(
        %{campaign: campaign, target: %EvalCampaignTarget{} = target},
        %{eval_run: %EvalRun{}}
      ) do
    timestamp = now()

    Multi.new()
    |> Multi.run(:target, fn repo, _changes ->
      fresh_target = repo.get!(EvalCampaignTarget, target.id)

      case fresh_target.status do
        "completed" ->
          {:ok, fresh_target}

        _ ->
          fresh_target
          |> EvalCampaignTarget.changeset(%{
            status: "completed",
            started_at: fresh_target.started_at || timestamp,
            finished_at: fresh_target.finished_at || timestamp,
            last_error: %{}
          })
          |> repo.update()
      end
    end)
    |> Multi.run(:campaign, fn repo, _changes ->
      refresh_campaign_rollup(repo, campaign.id, true)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{campaign: updated_campaign}} -> {:ok, updated_campaign}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Finalizes a failed shard and narrows campaign-wide fatal state to explicit failure classes.
  """
  def fail_campaign_target(
        %{
          campaign: campaign,
          target: %EvalCampaignTarget{} = target,
          eval_run: %EvalRun{} = eval_run
        },
        reason,
        opts \\ []
      ) do
    timestamp = now()
    fatal? = Keyword.get(opts, :fatal?, false)

    Multi.new()
    |> Multi.run(:eval_run, fn repo, _changes ->
      fresh_run = repo.get!(EvalRun, eval_run.id)

      case fresh_run.status do
        "completed" ->
          {:ok, fresh_run}

        _ ->
          fresh_run
          |> EvalRun.changeset(%{status: "failed"})
          |> repo.update()
      end
    end)
    |> Multi.run(:target, fn repo, _changes ->
      fresh_target = repo.get!(EvalCampaignTarget, target.id)

      case fresh_target.status do
        "completed" ->
          {:ok, fresh_target}

        _ ->
          fresh_target
          |> EvalCampaignTarget.changeset(%{
            status: "failed",
            started_at: fresh_target.started_at || timestamp,
            finished_at: timestamp,
            last_error: failure_details(reason, fatal?)
          })
          |> repo.update()
      end
    end)
    |> Multi.run(:campaign, fn repo, _changes ->
      refresh_campaign_rollup(repo, campaign.id, true)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{campaign: updated_campaign}} -> {:ok, updated_campaign}
      {:error, _step, failed_value, _changes} -> {:error, failed_value}
    end
  end

  def fatal_campaign_failure?(reason) do
    case reason do
      {:invalid_campaign_contract, _detail} -> true
      {:invalid_credentials, _detail} -> true
      {:missing_credentials, _detail} -> true
      {:quota_exhausted, _detail} -> true
      {:configuration_error, _detail} -> true
      {:integrity_error, _detail} -> true
      {:persistence_error, _detail} -> true
      :target_already_terminal -> false
      _ -> false
    end
  end

  defp persist_eval_scores(%EvalRun{} = eval_run, score_attrs_list, opts) do
    replace? = Keyword.get(opts, :replace?, false)

    Ecto.Multi.new()
    |> maybe_delete_scores(eval_run.id, replace?)
    |> Ecto.Multi.run(:scores, fn repo, _changes ->
      insert_scores(repo, eval_run, score_attrs_list)
    end)
    |> Ecto.Multi.update(:eval_run, fn %{scores: scores} ->
      aggregate_attrs = aggregate_score_attrs(eval_run, scores)
      EvalRun.changeset(eval_run, aggregate_attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{scores: scores, eval_run: updated_run}} -> {:ok, updated_run, scores}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  defp insert_scores(repo, eval_run, score_attrs_list) do
    Enum.reduce_while(score_attrs_list, {:ok, []}, fn score_attrs, {:ok, acc} ->
      attrs_with_fk =
        score_attrs
        |> Map.new()
        |> normalize_score_attrs()
        |> Map.put(:eval_run_id, eval_run.id)

      case %Score{} |> Score.changeset(attrs_with_fk) |> repo.insert() do
        {:ok, score} -> {:cont, {:ok, [score | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, scores} -> {:ok, Enum.reverse(scores)}
      error -> error
    end
  end

  defp maybe_delete_scores(multi, _eval_run_id, false), do: multi

  defp maybe_delete_scores(multi, eval_run_id, true) do
    Ecto.Multi.delete_all(
      multi,
      :delete_scores,
      from(score in Score, where: score.eval_run_id == ^eval_run_id)
    )
  end

  defp normalize_score_attrs(attrs) do
    explanation = fetch_attr(attrs, :explanation) || fetch_attr(attrs, :reasoning)
    details = fetch_attr(attrs, :details) || fetch_attr(attrs, :metadata) || %{}
    metadata = fetch_attr(attrs, :metadata) || fetch_attr(attrs, :details) || %{}

    attrs
    |> Map.put_new(:explanation, explanation)
    |> Map.put_new(:reasoning, explanation)
    |> Map.put_new(:details, details)
    |> Map.put_new(:metadata, metadata)
    |> Map.put_new(:evidence_refs, fetch_attr(attrs, :evidence_refs) || %{})
  end

  defp insert_campaign_targets(repo, campaign, eval_spec_id, targets) do
    Enum.reduce_while(targets, {:ok, []}, fn target_attrs, {:ok, acc} ->
      attrs_with_lineage =
        target_attrs
        |> Map.new()
        |> Map.put(:campaign_id, campaign.id)
        |> Map.put(:eval_spec_id, eval_spec_id)
        |> Map.put_new(:status, "pending")
        |> Map.put_new(:metadata, %{})

      case %EvalCampaignTarget{}
           |> EvalCampaignTarget.changeset(attrs_with_lineage)
           |> repo.insert() do
        {:ok, target} -> {:cont, {:ok, [target | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, inserted_targets} -> {:ok, Enum.reverse(inserted_targets)}
      error -> error
    end
  end

  defp aggregate_score_attrs(eval_run, scores) do
    total_items = length(scores)
    passed_items = Enum.count(scores, &(&1.status == "passed"))
    failed_items = Enum.count(scores, &(&1.status == "failed"))
    avg_latency_ms = average_integer(Enum.map(scores, &extract_latency_ms/1))
    total_cost_usd = decimal_sum(Enum.map(scores, &extract_cost_usd/1))

    %{
      runner_mode: eval_run.runner_mode,
      status: if(total_items > 0, do: "running", else: eval_run.status),
      dataset_id: eval_run.dataset_id,
      dataset_version: eval_run.dataset_version,
      eval_spec_id: eval_run.eval_spec_id,
      eval_spec_version: eval_run.eval_spec_version,
      prompt_template_id: eval_run.prompt_template_id,
      prompt_version: eval_run.prompt_version,
      total_items: total_items,
      passed_items: passed_items,
      failed_items: failed_items,
      avg_latency_ms: avg_latency_ms,
      total_cost_usd: total_cost_usd
    }
  end

  defp extract_latency_ms(score) do
    score.metadata
    |> Map.get("latency_ms", Map.get(score.metadata, :latency_ms))
  end

  defp extract_cost_usd(score) do
    score.metadata
    |> Map.get("cost_usd", Map.get(score.metadata, :cost_usd))
  end

  defp average_integer([]), do: nil

  defp average_integer(values) do
    present_values =
      values
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&normalize_integer/1)

    case present_values do
      [] -> nil
      _ -> present_values |> Enum.sum() |> Kernel./(length(present_values)) |> round()
    end
  end

  defp decimal_sum(values) do
    present_values =
      values
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&normalize_decimal/1)

    case present_values do
      [] -> nil
      [head | tail] -> Enum.reduce(tail, head, &Decimal.add/2)
    end
  end

  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(value) when is_float(value), do: trunc(value)
  defp normalize_integer(value) when is_binary(value), do: String.to_integer(value)

  defp normalize_decimal(%Decimal{} = value), do: value
  defp normalize_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp normalize_decimal(value) when is_float(value), do: Decimal.from_float(value)
  defp normalize_decimal(value) when is_binary(value), do: Decimal.new(value)

  defp refresh_campaign_rollup(repo, campaign_id, touch_started?) do
    campaign = repo.get!(EvalCampaign, campaign_id)

    targets =
      repo.all(from(target in EvalCampaignTarget, where: target.campaign_id == ^campaign_id))

    attrs = campaign_rollup_attrs(campaign, targets, touch_started?)

    campaign
    |> EvalCampaign.changeset(attrs)
    |> repo.update()
  end

  defp campaign_rollup_attrs(campaign, targets, touch_started?) do
    counts = %{
      total_targets: length(targets),
      queued_targets: Enum.count(targets, &(&1.status == "pending")),
      running_targets: Enum.count(targets, &(&1.status == "running")),
      completed_targets: Enum.count(targets, &(&1.status == "completed")),
      failed_targets: Enum.count(targets, &(&1.status == "failed")),
      cancelled_targets: Enum.count(targets, &(&1.status == "cancelled"))
    }

    terminal? =
      counts.total_targets > 0 and counts.queued_targets == 0 and counts.running_targets == 0

    Map.merge(counts, %{
      status: derive_campaign_status(counts, targets),
      started_at: campaign.started_at || started_at_from_targets(targets, touch_started?),
      finished_at: if(terminal?, do: finished_at_from_targets(targets), else: nil),
      last_progress_at: now()
    })
  end

  defp derive_campaign_status(counts, targets) do
    cond do
      counts.cancelled_targets == counts.total_targets and counts.total_targets > 0 ->
        "cancelled"

      Enum.any?(targets, &fatal_target?/1) ->
        "failed_fatal"

      counts.completed_targets == counts.total_targets and counts.total_targets > 0 ->
        "completed"

      counts.queued_targets == 0 and counts.running_targets == 0 and counts.failed_targets > 0 ->
        "completed_partial"

      counts.running_targets > 0 or counts.completed_targets > 0 or counts.failed_targets > 0 ->
        "running"

      true ->
        "queued"
    end
  end

  defp started_at_from_targets(targets, touch_started?) do
    started =
      targets
      |> Enum.map(& &1.started_at)
      |> Enum.reject(&is_nil/1)
      |> Enum.min(DateTime, fn -> nil end)

    cond do
      started -> started
      touch_started? -> now()
      true -> nil
    end
  end

  defp finished_at_from_targets(targets) do
    targets
    |> Enum.map(& &1.finished_at)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(DateTime, fn -> nil end)
  end

  defp fatal_target?(target) do
    target.last_error["class"] == "fatal" or target.last_error[:class] == "fatal"
  end

  defp failure_details(reason, fatal?) do
    %{
      "class" => if(fatal?, do: "fatal", else: "shard_local"),
      "reason" => reason_code(reason),
      "details" => inspect(reason)
    }
  end

  defp reason_code({code, _detail}), do: to_string(code)
  defp reason_code(code) when is_atom(code), do: to_string(code)
  defp reason_code(code), do: inspect(code)

  defp online_scoring_target?(%EvalCampaignTarget{} = target) do
    target.metadata
    |> Map.new()
    |> fetch_attr(:source) == "online_scoring"
  end

  defp has_scores?(eval_run_id) do
    Repo.exists?(from(score in Score, where: score.eval_run_id == ^eval_run_id))
  end

  defp list_scores(eval_run_id) do
    Repo.all(
      from(score in Score,
        where: score.eval_run_id == ^eval_run_id,
        order_by: [asc: score.inserted_at, asc: score.id]
      )
    )
  end

  defp inspectable_envelope(args) do
    %{
      tenant_id: fetch_attr(args, :tenant_id),
      provider: fetch_attr(args, :provider),
      model: fetch_attr(args, :model)
    }
  end

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:microsecond)
  end

  defp put_dataset_snapshot!(attrs) do
    dataset_id = fetch_attr(attrs, :dataset_id)
    dataset_version = fetch_attr(attrs, :dataset_version)

    case dataset_id do
      nil ->
        attrs

      id ->
        dataset = get_dataset!(id)

        if dataset.state != :sealed do
          raise ArgumentError, "eval specs must point at sealed datasets"
        end

        if dataset_version && dataset_version != dataset.version do
          raise ArgumentError, "dataset_version must match the sealed dataset version"
        end

        put_new_attr(attrs, :dataset_version, dataset.version)
    end
  end

  defp fetch_attr!(attrs, key) do
    case fetch_attr(attrs, key) do
      nil -> raise ArgumentError, "missing required eval attribute #{key}"
      value -> value
    end
  end

  defp fetch_attr(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp put_new_attr(attrs, key, value) when is_map(attrs) do
    if Map.has_key?(attrs, key) || Map.has_key?(attrs, Atom.to_string(key)) do
      attrs
    else
      Map.put(attrs, key, value)
    end
  end
end

defmodule Scoria.Eval do
  @moduledoc """
  The Eval context for managing datasets, evaluation specs, and runs.
  """

  import Ecto.Query, warn: false
  alias Scoria.Repo

  alias Scoria.Eval.Dataset
  alias Scoria.Eval.DatasetItem
  alias Scoria.Eval.CampaignEnqueuer
  alias Scoria.Eval.EvalCampaign
  alias Scoria.Eval.EvalCampaignTarget
  alias Scoria.Eval.EvalSpec
  alias Scoria.Eval.EvalRun
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
      |> put_new_attr(:prompt_template_id, eval_spec.subject.prompt_template_id)
      |> put_new_attr(:prompt_version, eval_spec.subject.prompt_version)
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
    Ecto.Multi.new()
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

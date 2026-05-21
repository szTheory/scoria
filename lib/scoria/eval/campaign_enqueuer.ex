defmodule Scoria.Eval.CampaignEnqueuer do
  @moduledoc false

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Scoria.Eval
  alias Scoria.Eval.{CampaignWorker, EvalCampaign, EvalCampaignTarget, EvalRun, EvalSpec}
  alias Scoria.Repo
  alias Scoria.Workflows.BatchEnqueue

  @default_queue "evals"
  @semantic_override_fields ~w(
    dataset_slice
    judge
    judge_definition
    judge_model
    judge_prompt_template_id
    judge_prompt_version
    prompt_template_id
    prompt_version
    subject
    threshold_policy
  )

  def enqueue_campaign(attrs, opts \\ []) when is_map(attrs) do
    attrs = Map.new(attrs)
    eval_spec = Eval.get_eval_spec!(fetch_attr!(attrs, :eval_spec_id))

    with {:ok, normalized_targets} <- normalize_targets(attrs),
         {:ok, result} <- persist_and_enqueue(eval_spec, attrs, normalized_targets, opts) do
      {:ok, result}
    end
  end

  defp persist_and_enqueue(eval_spec, attrs, normalized_targets, opts) do
    tenant_id = fetch_attr!(attrs, :tenant_id)
    chunk_size = Keyword.get(opts, :chunk_size)

    multi =
      Multi.new()
      |> Multi.insert(
        :campaign,
        EvalCampaign.changeset(
          %EvalCampaign{},
          campaign_attrs(attrs, tenant_id, eval_spec.id, normalized_targets)
        )
      )
      |> Multi.run(:targets, fn repo, %{campaign: campaign} ->
        insert_targets(repo, campaign, eval_spec.id, normalized_targets)
      end)
      |> Multi.run(:eval_runs, fn repo, %{campaign: campaign, targets: targets} ->
        insert_eval_runs(repo, campaign, eval_spec, targets)
      end)

    with {:ok, %{campaign: campaign, targets: targets, eval_runs: eval_runs}} <-
           Repo.transaction(multi) do
      jobs = build_jobs(campaign, targets, eval_runs)

      batch_opts =
        opts
        |> Keyword.take([:chunk_size])
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)

      case BatchEnqueue.enqueue_all(jobs, batch_opts) do
        {:ok, enqueue_results} ->
          {:ok, campaign} =
            campaign
            |> Ecto.Changeset.change(%{
              status: "queued",
              total_targets: length(targets),
              queued_targets: length(targets),
              running_targets: 0,
              completed_targets: 0,
              failed_targets: 0,
              cancelled_targets: 0,
              last_progress_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
            })
            |> Repo.update()

          {:ok,
           %{
             campaign: campaign,
             targets: targets,
             eval_runs: eval_runs,
             enqueue_results: stringify_batch_keys(enqueue_results),
             chunk_size: chunk_size
           }}

        {:error, _op, reason, _changes} ->
          {:error, reason}
      end
    else
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp campaign_attrs(attrs, tenant_id, eval_spec_id, targets) do
    attrs
    |> Map.drop([:targets, "targets"])
    |> Map.put(:tenant_id, tenant_id)
    |> Map.put(:eval_spec_id, eval_spec_id)
    |> Map.put(:status, "queued")
    |> Map.put(:total_targets, length(targets))
    |> Map.put(:queued_targets, 0)
    |> Map.put(:running_targets, 0)
    |> Map.put(:completed_targets, 0)
    |> Map.put(:failed_targets, 0)
    |> Map.put(:cancelled_targets, 0)
    |> Map.put_new(:metadata, %{})
  end

  defp insert_targets(repo, campaign, eval_spec_id, targets) do
    Enum.reduce_while(targets, {:ok, []}, fn target_attrs, {:ok, acc} ->
      attrs =
        target_attrs
        |> Map.put(:campaign_id, campaign.id)
        |> Map.put(:eval_spec_id, eval_spec_id)
        |> Map.put(:status, "pending")

      case %EvalCampaignTarget{}
           |> EvalCampaignTarget.changeset(attrs)
           |> repo.insert() do
        {:ok, target} -> {:cont, {:ok, [target | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> reverse_ok_list()
  end

  defp insert_eval_runs(repo, campaign, eval_spec, targets) do
    Enum.reduce_while(targets, {:ok, []}, fn target, {:ok, acc} ->
      attrs = eval_run_attrs(campaign, eval_spec, target)

      case %EvalRun{}
           |> EvalRun.changeset(attrs)
           |> repo.insert() do
        {:ok, eval_run} -> {:cont, {:ok, [eval_run | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> reverse_ok_list()
  end

  defp build_jobs(campaign, targets, eval_runs) do
    targets
    |> Enum.zip(eval_runs)
    |> Enum.map(fn {target, eval_run} ->
      CampaignWorker.new_job(
        %{
          campaign_id: campaign.id,
          campaign_target_id: target.id,
          eval_run_id: eval_run.id,
          tenant_id: target.tenant_id,
          eval_spec_id: target.eval_spec_id,
          provider: target.provider,
          model: target.model,
          metadata: target.metadata
        },
        queue: String.to_atom(target.queue || @default_queue),
        priority: target.priority
      )
    end)
  end

  defp eval_run_attrs(campaign, %EvalSpec{} = eval_spec, target) do
    %{
      eval_spec_id: eval_spec.id,
      eval_spec_version: eval_spec.version,
      dataset_id: eval_spec.dataset_id,
      dataset_version: eval_spec.dataset_version,
      prompt_template_id: eval_spec.subject.prompt_template_id,
      prompt_version: eval_spec.subject.prompt_version,
      runner_mode: eval_spec.eval_mode,
      status: "pending",
      tenant_id: target.tenant_id,
      campaign_id: campaign.id,
      campaign_target_id: target.id,
      provider: target.provider,
      model: target.model
    }
  end

  defp normalize_targets(attrs) do
    targets = fetch_attr(attrs, :targets) || []

    Enum.reduce(targets, {:ok, [], MapSet.new(), []}, fn target_attrs, {:ok, acc, seen, errors} ->
      normalized = normalize_target(target_attrs)
      duplicate_key = duplicate_key(normalized)
      target_errors = semantic_override_errors(target_attrs)

      cond do
        target_errors != [] ->
          {:ok, acc, seen, errors ++ target_errors}

        MapSet.member?(seen, duplicate_key) ->
          {:ok, acc, seen, errors ++ ["contains duplicate runtime targets"]}

        true ->
          {:ok, acc ++ [normalized], MapSet.put(seen, duplicate_key), errors}
      end
    end)
    |> case do
      {:ok, normalized_targets, _seen, []} ->
        {:ok, normalized_targets}

      {:ok, _normalized_targets, _seen, errors} ->
        {:error, add_target_errors(errors)}
    end
  end

  defp normalize_target(target_attrs) do
    target_attrs = Map.new(target_attrs)

    metadata =
      target_attrs
      |> fetch_attr(:metadata)
      |> normalize_metadata()

    %{
      tenant_id: fetch_attr!(target_attrs, :tenant_id),
      provider: fetch_attr!(target_attrs, :provider),
      model: fetch_attr!(target_attrs, :model),
      queue: normalize_queue(fetch_attr(target_attrs, :queue)),
      priority: fetch_attr(target_attrs, :priority),
      metadata: metadata
    }
    |> drop_nil_values()
  end

  defp semantic_override_errors(target_attrs) do
    invalid_fields =
      @semantic_override_fields
      |> Enum.filter(&present_key?(target_attrs, &1))

    case invalid_fields do
      [] -> []
      fields -> ["contains unsupported semantic override fields: #{Enum.join(fields, ", ")}"]
    end
  end

  defp add_target_errors(errors) do
    changeset = Changeset.change(%EvalCampaignTarget{})

    Enum.reduce(Enum.uniq(errors), changeset, fn message, acc ->
      Changeset.add_error(acc, :targets, message)
    end)
  end

  defp duplicate_key(target) do
    Map.take(target, [:tenant_id, :provider, :model, :queue, :priority, :metadata])
  end

  defp normalize_queue(nil), do: @default_queue
  defp normalize_queue(""), do: @default_queue
  defp normalize_queue(:evals), do: @default_queue
  defp normalize_queue("evals"), do: @default_queue
  defp normalize_queue(_queue), do: @default_queue

  defp normalize_metadata(nil), do: %{}

  defp normalize_metadata(metadata) when is_map(metadata) do
    Enum.into(metadata, %{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_metadata(_metadata), do: %{}

  defp reverse_ok_list({:ok, values}), do: {:ok, Enum.reverse(values)}
  defp reverse_ok_list(error), do: error

  defp stringify_batch_keys(results) do
    Enum.into(results, %{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp fetch_attr!(attrs, key) do
    case fetch_attr(attrs, key) do
      nil -> raise ArgumentError, "missing campaign enqueue attribute #{key}"
      value -> value
    end
  end

  defp fetch_attr(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp present_key?(attrs, key) when is_map(attrs) do
    Map.has_key?(attrs, key) || Map.has_key?(attrs, String.to_atom(key))
  rescue
    ArgumentError -> Map.has_key?(attrs, key)
  end

  defp drop_nil_values(map) do
    Enum.reject(map, fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end

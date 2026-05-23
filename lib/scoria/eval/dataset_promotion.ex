defmodule Scoria.Eval.DatasetPromotion do
  @moduledoc """
  Builds frozen workflow-source dataset item snapshots and inserts them immutably.
  """

  alias Ecto.Multi
  alias Scoria.Eval.DatasetItem
  alias Scoria.Repo

  @required_keys ~w(
    dataset_id
    workflow_run_id
    workflow_step_id
    source_variant
    provenance
    checkpoint_output
    safety
    promotion_snapshot
  )a

  @optional_keys ~w(notes expected_output)a

  def preview(attrs) when is_map(attrs) do
    attrs = normalize_map(attrs)
    ensure_required_keys!(attrs)

    {:ok,
     %{
       dataset_id: attrs["dataset_id"],
       item_attrs: build_item_attrs(attrs),
       metadata: build_metadata(attrs)
     }}
  end

  def promote(attrs, get_dataset_fun) when is_map(attrs) and is_function(get_dataset_fun, 1) do
    attrs = normalize_map(attrs)
    ensure_required_keys!(attrs)

    Multi.new()
    |> Multi.run(:dataset, fn _repo, _changes ->
      {:ok, get_dataset_fun.(attrs["dataset_id"])}
    end)
    |> Multi.run(:item, fn repo, %{dataset: dataset} ->
      attrs
      |> build_item_attrs()
      |> Map.put("dataset_id", dataset.id)
      |> insert_item(repo, dataset.state)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{item: item}} -> {:ok, item}
      {:error, :item, changeset, _changes} -> {:error, changeset}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_item(attrs, repo, dataset_state) do
    %DatasetItem{}
    |> DatasetItem.changeset(attrs, dataset_state)
    |> repo.insert()
  end

  defp build_item_attrs(attrs) do
    %{
      "input" => %{
        "workflow_run_id" => attrs["workflow_run_id"],
        "workflow_step_id" => attrs["workflow_step_id"],
        "source_variant" => attrs["source_variant"],
        "provenance" => normalize_map(attrs["provenance"]),
        "checkpoint_output" => normalize_map(attrs["checkpoint_output"]),
        "safety" => normalize_map(attrs["safety"]),
        "promotion_snapshot" => normalize_map(attrs["promotion_snapshot"]),
        "notes" => attrs["notes"]
      },
      "expected_output" => normalize_map(attrs["expected_output"]),
      "metadata" => build_metadata(attrs)
    }
  end

  defp build_metadata(attrs) do
    provenance = normalize_map(attrs["provenance"])
    promotion_snapshot = normalize_map(attrs["promotion_snapshot"])

    %{
      "promoted_from_workflow" => true,
      "source_variant" => attrs["source_variant"],
      "workflow_run_id" => attrs["workflow_run_id"],
      "workflow_step_id" => attrs["workflow_step_id"],
      "source_run_id" => provenance["source_run_id"],
      "source_checkpoint_id" => provenance["source_checkpoint_id"],
      "execution_mode" => provenance["execution_mode"],
      "replay_disposition" => provenance["replay_disposition"],
      "replay_reason_code" => provenance["replay_reason_code"],
      "recorded_outcome" => normalize_map(promotion_snapshot["recorded_outcome"])
    }
  end

  defp ensure_required_keys!(attrs) do
    Enum.each(@required_keys, fn key ->
      if Map.get(attrs, Atom.to_string(key)) == nil do
        raise ArgumentError, "missing required workflow promotion attribute #{key}"
      end
    end)

    allowed = MapSet.new(Enum.map(@required_keys ++ @optional_keys, &Atom.to_string/1))

    attrs
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(allowed, &1))
    |> case do
      [] -> :ok
      extra_keys -> raise ArgumentError, "unexpected workflow promotion attributes: #{Enum.join(extra_keys, ", ")}"
    end
  end

  defp normalize_map(nil), do: %{}

  defp normalize_map(value) when is_map(value) do
    Map.new(value, fn
      {key, nested} when is_map(nested) -> {to_string(key), normalize_map(nested)}
      {key, nested} when is_list(nested) -> {to_string(key), normalize_list(nested)}
      {key, nested} -> {to_string(key), nested}
    end)
  end

  defp normalize_map(value), do: value

  defp normalize_list(list) do
    Enum.map(list, fn
      nested when is_map(nested) -> normalize_map(nested)
      nested when is_list(nested) -> normalize_list(nested)
      nested -> nested
    end)
  end
end

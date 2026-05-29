defmodule Scoria.Workflows.DatasetPromotion do
  @moduledoc """
  Workflow-owned approval wrapper for sealed dataset baseline promotion.
  """

  import Ecto.Changeset

  alias Scoria.Eval
  alias Scoria.Workflows

  @tool_name "dataset_baseline_promotion"
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

  def request_baseline_promotion(attrs) when is_map(attrs) do
    attrs = normalize_map(attrs)

    with :ok <- validate_required(attrs),
         {:ok, dataset} <- fetch_sealed_dataset(attrs["dataset_id"]) do
      approval_attrs = %{
        tool_name: @tool_name,
        local_tool_name: @tool_name,
        reason: "Baseline Promotion Approval",
        subject_ref: "dataset:#{dataset.id}",
        arguments: %{
          "dataset_id" => dataset.id,
          "dataset_name" => dataset.name,
          "dataset_version" => dataset.version,
          "workflow_run_id" => attrs["workflow_run_id"],
          "workflow_step_id" => attrs["workflow_step_id"],
          "source_variant" => attrs["source_variant"],
          "provenance" => normalize_map(attrs["provenance"]),
          "checkpoint_output" => normalize_map(attrs["checkpoint_output"]),
          "safety" => normalize_map(attrs["safety"]),
          "promotion_snapshot" => normalize_map(attrs["promotion_snapshot"]),
          "notes" => attrs["notes"],
          "expected_output" => normalize_map(attrs["expected_output"])
        }
      }

      Workflows.request_remote_approval(
        attrs["workflow_run_id"],
        attrs["workflow_step_id"],
        approval_attrs
      )
    end
  end

  defp validate_required(attrs) do
    errors =
      Enum.flat_map(@required_keys, fn key ->
        case Map.get(attrs, Atom.to_string(key)) do
          nil -> [{key, "can't be blank"}]
          _value -> []
        end
      end)

    case errors do
      [] -> :ok
      _ -> {:error, validation_changeset(attrs, errors)}
    end
  end

  defp fetch_sealed_dataset(dataset_id) do
    dataset = Eval.get_dataset!(dataset_id)

    case dataset.state do
      :sealed -> {:ok, dataset}
      _other -> {:error, validation_changeset(%{"dataset_id" => dataset_id}, [dataset_id: "must reference a sealed dataset"])}
    end
  end

  defp validation_changeset(attrs, errors) do
    types =
      @required_keys
      |> Kernel.++(@optional_keys)
      |> Enum.reduce(%{}, fn key, acc ->
        Map.put(acc, key, if(key == :dataset_id, do: :integer, else: :map))
      end)
      |> Map.put(:notes, :string)
      |> Map.put(:source_variant, :string)
      |> Map.put(:workflow_run_id, :binary_id)
      |> Map.put(:workflow_step_id, :binary_id)

    changeset =
      {%{}, types}
      |> cast(attrs, Map.keys(types))

    Enum.reduce(errors, changeset, fn {field, message}, acc ->
      add_error(acc, field, message)
    end)
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

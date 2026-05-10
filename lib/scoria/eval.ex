defmodule Scoria.Eval do
  @moduledoc """
  The Eval context for managing datasets, evaluation specs, and runs.
  """

  import Ecto.Query, warn: false
  alias Scoria.Repo

  alias Scoria.Eval.Dataset
  alias Scoria.Eval.DatasetItem
  alias Scoria.Eval.EvalSpec

  @doc """
  Creates a dataset with optional dataset items.
  Assigns a random UUID to `entity_id` and sets version to 1.
  """
  def create_dataset(attrs \\ %{}) do
    entity_id = Ecto.UUID.generate()
    {items, dataset_attrs} = Map.pop(attrs, :items, [])
    
    attrs_with_defaults = 
      dataset_attrs
      |> Map.put(:entity_id, entity_id)
      |> Map.put(:version, 1)
      |> Map.put(:is_current, true)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
    |> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
      items_results =
        Enum.map(items, fn item_attrs ->
          item_attrs_with_fk = Map.put(item_attrs, :dataset_id, dataset.id)
          %DatasetItem{}
          |> DatasetItem.changeset(item_attrs_with_fk)
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
  Updates a dataset immutably.
  Deprecates the old version and creates a new one with incremented version.
  Clones all associated dataset_items to the new dataset.
  """
  def update_dataset(%Dataset{} = old_dataset, attrs) do
    new_version = old_dataset.version + 1

    old_dataset_changeset = Ecto.Changeset.change(old_dataset, is_current: false)

    # Convert struct to map for the new record, picking relevant fields
    base_attrs = Map.take(old_dataset, [:entity_id, :name, :description])
    
    # Merge with updates and new version info
    new_attrs = 
      base_attrs
      |> Map.merge(attrs)
      |> Map.put(:version, new_version)
      |> Map.put(:is_current, true)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:deprecate_old, old_dataset_changeset)
    |> Ecto.Multi.insert(:new_dataset, Dataset.changeset(%Dataset{}, new_attrs))
    |> Ecto.Multi.run(:clone_items, fn repo, %{new_dataset: new_dataset} ->
      old_items = list_dataset_items(old_dataset.id)
      
      cloned_items_results =
        Enum.map(old_items, fn old_item ->
          item_attrs = %{
            input: old_item.input,
            expected_output: old_item.expected_output,
            metadata: old_item.metadata,
            dataset_id: new_dataset.id
          }
          
          %DatasetItem{}
          |> DatasetItem.changeset(item_attrs)
          |> repo.insert()
        end)

      case Enum.find(cloned_items_results, fn {status, _} -> status == :error end) do
        nil -> {:ok, Enum.map(cloned_items_results, fn {:ok, item} -> item end)}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{new_dataset: new_dataset}} -> {:ok, new_dataset}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Returns the list of dataset items for a given dataset id.
  """
  def list_dataset_items(dataset_id) do
    Repo.all(from i in DatasetItem, where: i.dataset_id == ^dataset_id)
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
  Creates an eval spec.
  """
  def create_eval_spec(attrs \\ %{}) do
    entity_id = Ecto.UUID.generate()
    
    attrs_with_defaults = 
      attrs
      |> Map.put(:entity_id, entity_id)
      |> Map.put(:version, 1)
      |> Map.put(:is_current, true)

    %EvalSpec{}
    |> EvalSpec.changeset(attrs_with_defaults)
    |> Repo.insert()
  end

  @doc """
  Updates an eval spec immutably.
  """
  def update_eval_spec(%EvalSpec{} = old_spec, attrs) do
    new_version = old_spec.version + 1

    old_spec_changeset = Ecto.Changeset.change(old_spec, is_current: false)

    base_attrs = Map.take(old_spec, [:entity_id, :name, :description, :rubric])
    
    new_attrs = 
      base_attrs
      |> Map.merge(attrs)
      |> Map.put(:version, new_version)
      |> Map.put(:is_current, true)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:deprecate_old, old_spec_changeset)
    |> Ecto.Multi.insert(:new_spec, EvalSpec.changeset(%EvalSpec{}, new_attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{new_spec: new_spec}} -> {:ok, new_spec}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end
end

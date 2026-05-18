defmodule Scoria.PromptRegistry do
  @moduledoc """
  The PromptRegistry context for managing prompt templates and their lifecycle.
  """

  import Ecto.Query, warn: false
  alias Scoria.Repo

  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.PromptRegistry.Tokenizer

  @doc """
  Creates a new draft template.
  """
  def create_draft_template(attrs \\ %{}) do
    entity_id = Map.get(attrs, :entity_id) || Map.get(attrs, "entity_id") || Ecto.UUID.generate()
    
    # We apply the attrs via changeset to the default struct to get the final payload
    # for the token estimator, ensuring all text fields are correctly merged.
    temp_changeset = PromptTemplate.changeset(%PromptTemplate{}, attrs)
    merged_struct = Ecto.Changeset.apply_changes(temp_changeset)
    
    estimated_tokens = Tokenizer.estimate_tokens(merged_struct)

    attrs_with_defaults = 
      attrs
      |> Map.put(:entity_id, entity_id)
      |> Map.put(:version, 1)
      |> Map.put(:status, "draft")
      |> Map.put(:is_current, true)
      |> Map.put(:estimated_tokens, estimated_tokens)

    %PromptTemplate{}
    |> PromptTemplate.changeset(attrs_with_defaults)
    |> Repo.insert()
  end

  @doc """
  Updates an active or archived template immutably, bumping the version.
  """
  def update_prompt_template(%PromptTemplate{} = old_template, attrs) do
    new_version = old_template.version + 1
    old_template_changeset = Ecto.Changeset.change(old_template, is_current: false)

    base_attrs = Map.take(old_template, [:entity_id, :system_message, :few_shot_examples, :user_template])
    
    temp_changeset = PromptTemplate.changeset(struct(PromptTemplate, base_attrs), attrs)
    merged_struct = Ecto.Changeset.apply_changes(temp_changeset)
    
    estimated_tokens = Tokenizer.estimate_tokens(merged_struct)

    new_attrs = 
      merged_struct
      |> Map.from_struct()
      |> Map.take([:entity_id, :system_message, :few_shot_examples, :user_template])
      |> Map.put(:version, new_version)
      |> Map.put(:is_current, true)
      |> Map.put(:status, old_template.status)
      |> Map.put(:estimated_tokens, estimated_tokens)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:deprecate_old, old_template_changeset)
    |> Ecto.Multi.insert(:new_template, PromptTemplate.changeset(%PromptTemplate{}, new_attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{new_template: new_template}} -> {:ok, new_template}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Transitions a template's status without bumping the version.
  """
  def transition_status(%PromptTemplate{} = template, new_status) do
    template
    |> Ecto.Changeset.change(status: new_status)
    |> Repo.update()
  end

  @doc """
  Updates a draft template in place. Rejects if not draft.
  """
  def update_draft_template(%PromptTemplate{} = template, attrs) do
    if template.status != "draft" do
      changeset =
        template
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:status, "cannot modify content fields of non-draft template")
      {:error, changeset}
    else
      changeset = PromptTemplate.changeset(template, attrs)
      merged_struct = Ecto.Changeset.apply_changes(changeset)
      estimated_tokens = Tokenizer.estimate_tokens(merged_struct)
      
      changeset
      |> Ecto.Changeset.put_change(:estimated_tokens, estimated_tokens)
      |> Repo.update()
    end
  end
end

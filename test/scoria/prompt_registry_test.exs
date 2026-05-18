defmodule Scoria.PromptRegistryTest do
  use ExUnit.Case

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate

  describe "create_draft_template/1" do
    test "calculates token estimates before saving and inserts a draft version 1 template" do
      attrs = %{
        system_message: "You are a helpful assistant.",
        user_template: "User input: {{input}}"
      }

      assert {:ok, %PromptTemplate{} = template} = PromptRegistry.create_draft_template(attrs)
      assert template.version == 1
      assert template.status == "draft"
      assert template.is_current == true
      assert template.system_message == "You are a helpful assistant."
      assert template.user_template == "User input: {{input}}"
      assert is_binary(template.entity_id)
      # tokens should be > 0 (Tiktoken will calculate it, e.g. 5+4=9 tokens approximately)
      assert template.estimated_tokens > 0
    end
  end

  describe "update_prompt_template/2" do
    test "correctly inserts a new version, decrements the old one via Ecto.Multi" do
      {:ok, draft} = PromptRegistry.create_draft_template(%{
        system_message: "You are a helpful assistant.",
        user_template: "User input: {{input}}"
      })
      {:ok, active_v1} = PromptRegistry.transition_status(draft, "active")

      assert {:ok, active_v2} = PromptRegistry.update_prompt_template(active_v1, %{
        system_message: "You are a VERY helpful assistant."
      })

      assert active_v2.version == 2
      assert active_v2.status == "active"
      assert active_v2.is_current == true
      assert active_v2.entity_id == active_v1.entity_id
      assert active_v2.system_message == "You are a VERY helpful assistant."
      assert active_v2.user_template == "User input: {{input}}"
      assert active_v2.estimated_tokens > 0

      # Check old template was deprecated
      old_template = Scoria.Repo.get(PromptTemplate, active_v1.id)
      assert old_template.is_current == false
      assert old_template.version == 1
    end
  end

  describe "transition_status/2" do
    test "successfully changes a template from draft to active, or active to archived" do
      {:ok, draft} = PromptRegistry.create_draft_template(%{system_message: "Hello"})
      
      assert {:ok, active} = PromptRegistry.transition_status(draft, "active")
      assert active.status == "active"
      assert active.version == 1
      assert active.id == draft.id # Same record, no version bump

      assert {:ok, archived} = PromptRegistry.transition_status(active, "archived")
      assert archived.status == "archived"
      assert archived.version == 1
    end
  end

  describe "update_draft_template/2" do
    test "allows in-place mutations of draft templates" do
      {:ok, draft} = PromptRegistry.create_draft_template(%{system_message: "Hello"})
      
      assert {:ok, updated_draft} = PromptRegistry.update_draft_template(draft, %{system_message: "Hello world"})
      assert updated_draft.id == draft.id
      assert updated_draft.system_message == "Hello world"
      assert updated_draft.version == 1
      assert updated_draft.estimated_tokens > draft.estimated_tokens
    end

    test "rejects direct in-place modification of content fields on active templates" do
      {:ok, draft} = PromptRegistry.create_draft_template(%{system_message: "Hello"})
      {:ok, active} = PromptRegistry.transition_status(draft, "active")

      assert {:error, changeset} = PromptRegistry.update_draft_template(active, %{system_message: "Hacked!"})
      assert "cannot modify content fields of non-draft template" in errors_on(changeset).status
    end
  end

  # Helper for extracting errors
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

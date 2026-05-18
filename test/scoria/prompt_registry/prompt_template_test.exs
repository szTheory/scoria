defmodule Scoria.PromptRegistry.PromptTemplateTest do
  use ExUnit.Case, async: true

  alias Scoria.PromptRegistry.PromptTemplate

  describe "changeset/2" do
    test "requires entity_id, version, is_current, status" do
      changeset = PromptTemplate.changeset(%PromptTemplate{}, %{})

      assert "can't be blank" in errors_on(changeset).entity_id

      changeset = PromptTemplate.changeset(%PromptTemplate{}, %{
        entity_id: nil,
        version: nil,
        is_current: nil,
        status: nil
      })
      
      assert "can't be blank" in errors_on(changeset).entity_id
      assert "can't be blank" in errors_on(changeset).version
      assert "can't be blank" in errors_on(changeset).is_current
      assert "can't be blank" in errors_on(changeset).status
    end

    test "validates status is one of draft, active, archived" do
      changeset = PromptTemplate.changeset(%PromptTemplate{}, %{status: "invalid_status"})
      assert "is invalid" in errors_on(changeset).status

      for status <- ~w(draft active archived) do
        changeset = PromptTemplate.changeset(%PromptTemplate{}, %{status: status})
        refute errors_on(changeset)[:status]
      end
    end

    test "successfully casts the structured fields" do
      attrs = %{
        entity_id: Ecto.UUID.generate(),
        system_message: "You are a helpful assistant.",
        few_shot_examples: %{"user" => "hi", "assistant" => "hello"},
        user_template: "Hello {{name}}",
        estimated_tokens: 120
      }

      changeset = PromptTemplate.changeset(%PromptTemplate{}, attrs)

      assert changeset.valid?
      assert changeset.changes.system_message == "You are a helpful assistant."
      assert changeset.changes.few_shot_examples == %{"user" => "hi", "assistant" => "hello"}
      assert changeset.changes.user_template == "Hello {{name}}"
      assert changeset.changes.estimated_tokens == 120
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

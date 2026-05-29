defmodule Scoria.PromptRegistry.PromptTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_prompt_templates" do
    field :entity_id, :binary_id
    field :version, :integer, default: 1
    field :is_current, :boolean, default: true
    field :status, :string, default: "draft"
    field :system_message, :string
    field :few_shot_examples, :map
    field :user_template, :string
    field :estimated_tokens, :integer

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(prompt_template, attrs) do
    prompt_template
    |> cast(attrs, [
      :entity_id,
      :version,
      :is_current,
      :status,
      :system_message,
      :few_shot_examples,
      :user_template,
      :estimated_tokens
    ])
    |> validate_required([:entity_id, :version, :is_current, :status])
    |> validate_inclusion(:status, ~w(draft active archived))
    |> unique_constraint([:entity_id, :version])
  end
end

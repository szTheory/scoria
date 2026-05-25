defmodule Scoria.SemanticCache.EntryEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_semantic_cache_entry_events" do
    field :event_kind, :string
    field :reason_code, :string
    field :metadata, :map, default: %{}

    belongs_to :entry, Scoria.SemanticCache.Entry
    belongs_to :workflow_run, Scoria.Workflows.Run
    belongs_to :span, Scoria.Repo.Span

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:entry_id, :event_kind, :reason_code, :workflow_run_id, :span_id, :metadata])
    |> validate_required([:entry_id, :event_kind, :metadata])
  end
end

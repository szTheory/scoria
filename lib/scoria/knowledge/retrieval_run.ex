defmodule Scoria.Knowledge.RetrievalRun do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_retrieval_runs" do
    field :query_text, :string
    field :backend, :string
    field :retriever, :string
    field :top_k, :integer, default: 5
    field :filters, :map, default: %{}
    field :trace_id, :binary_id
    field :span_id, :binary_id
    field :status, :string, default: "pending"
    field :latency_ms, :integer
    field :metadata, :map, default: %{}

    has_many :results, Scoria.Knowledge.RetrievalResult
    has_many :grounding_scores, Scoria.Knowledge.GroundingScore

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :query_text,
      :backend,
      :retriever,
      :top_k,
      :filters,
      :trace_id,
      :span_id,
      :status,
      :latency_ms,
      :metadata
    ])
    |> validate_required([:query_text, :backend, :top_k, :status])
  end
end

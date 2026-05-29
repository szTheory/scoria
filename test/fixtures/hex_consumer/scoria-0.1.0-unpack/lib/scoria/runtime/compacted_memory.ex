defmodule Scoria.Runtime.CompactedMemory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_compacted_memories" do
    field(:session_id, :string)
    field(:start_sequence, :integer)
    field(:end_sequence, :integer)
    field(:summary_text, :string)
    field(:embedding, :binary)
    field(:token_count, :integer)

    belongs_to(:run, Scoria.Workflows.Run)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [
      :run_id,
      :session_id,
      :start_sequence,
      :end_sequence,
      :summary_text,
      :embedding,
      :token_count
    ])
    |> validate_required([
      :run_id,
      :session_id,
      :start_sequence,
      :end_sequence,
      :summary_text,
      :token_count
    ])
    |> validate_number(:start_sequence, greater_than_or_equal_to: 0)
    |> validate_number(:end_sequence, greater_than_or_equal_to: 0)
    |> validate_number(:token_count, greater_than_or_equal_to: 0)
    |> validate_sequence_range()
    |> foreign_key_constraint(:run_id)
  end

  defp validate_sequence_range(changeset) do
    start_sequence = get_field(changeset, :start_sequence)
    end_sequence = get_field(changeset, :end_sequence)

    if is_integer(start_sequence) and is_integer(end_sequence) and end_sequence < start_sequence do
      add_error(changeset, :end_sequence, "must be greater than or equal to start_sequence")
    else
      changeset
    end
  end
end

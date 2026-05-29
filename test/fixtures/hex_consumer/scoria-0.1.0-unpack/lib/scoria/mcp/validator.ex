defmodule Scoria.MCP.Validator do
  @moduledoc """
  Validates arguments against a tool's defined schema.
  """

  @doc """
  Validates a map of arguments against a tool's `input_schema/0`.

  Returns `{:ok, validated_args}` if successful, or `{:error, changeset}` if invalid.
  """
  def validate_args(tool_module, raw_args) do
    schema = tool_module.input_schema()
    keys = Map.keys(schema)

    changeset = Ecto.Changeset.cast({%{}, schema}, raw_args, keys)

    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end

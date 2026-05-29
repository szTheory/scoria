defmodule Scoria.Compaction.Tokenizer do
  @moduledoc """
  Lightweight token estimator used by the compaction worker.
  """

  def estimate(value) when is_binary(value) do
    value
    |> String.split(~r/\s+/, trim: true)
    |> length()
  end

  def estimate(value) when is_map(value) or is_list(value), do: value |> Jason.encode!() |> estimate()
  def estimate(value) when is_atom(value), do: value |> Atom.to_string() |> estimate()
  def estimate(value) when is_number(value), do: value |> to_string() |> estimate()
  def estimate(nil), do: 0
  def estimate(value), do: value |> inspect() |> estimate()
end

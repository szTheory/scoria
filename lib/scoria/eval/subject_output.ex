defmodule Scoria.Eval.SubjectOutput do
  @moduledoc """
  Resolves the subject output that eval runners grade.

  Offline replay grades the frozen `captured_output` stored on the dataset item.
  `:live_judge` currently delegates to that same frozen capture; independently
  regenerating a fresh subject response is a deferred slice. Empty or absent
  captures are not scoreable and never fall back to expected output.
  """

  @type mode :: :offline_replay | :live_judge
  @type reason :: :empty_capture | :unsupported_mode
  @type result :: {:ok, map()} | {:not_scored, reason()}

  @spec resolve(map(), mode() | atom()) :: result()
  def resolve(dataset_item, :offline_replay), do: frozen_capture(dataset_item)
  def resolve(dataset_item, :live_judge), do: frozen_capture(dataset_item)
  def resolve(_dataset_item, _mode), do: {:not_scored, :unsupported_mode}

  defp frozen_capture(%{captured_output: %{} = captured_output})
       when map_size(captured_output) > 0 do
    {:ok, captured_output}
  end

  defp frozen_capture(_dataset_item), do: {:not_scored, :empty_capture}
end

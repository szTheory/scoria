defmodule Scoria.WarningRatchet do
  @moduledoc """
  SSOT for high-signal warning-as-errors test paths (WARN-06).

  Paths are composed in code — not derived from warning-inventory.baseline.json.
  """

  @live_glob "test/scoria_web/live/**/*_test.exs"
  @scoria_glob "test/scoria/**/*_test.exs"

  @spec high_signal_wae_paths() :: [String.t()]
  def high_signal_wae_paths do
    adoption = Mix.Tasks.Scoria.Test.Adoption.adoption_test_files()
    scoria = Path.wildcard(@scoria_glob)
    live = Path.wildcard(@live_glob)

    (adoption ++ scoria ++ live)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec high_signal_path?(String.t()) :: boolean()
  def high_signal_path?(file) when is_binary(file) do
    cwd = File.cwd!()
    normalized = Path.expand(file, cwd)
    normalized in path_set(cwd)
  end

  defp path_set(cwd) do
    high_signal_wae_paths()
    |> Enum.map(&Path.expand(&1, cwd))
    |> MapSet.new()
  end
end

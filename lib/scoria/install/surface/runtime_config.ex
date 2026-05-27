defmodule Scoria.Install.Surface.RuntimeConfig do
  @default_target "config/runtime.exs"
  @managed_runtime_block ~r/config\s+:scoria,\s+Scoria\.Runtime/s
  @conflicting_scoria_config ~r/config\s+:scoria,\s+(?!Scoria\.Runtime)[A-Za-z0-9_.]+/s

  def analyze(config_path, _opts \\ []) do
    cond do
      is_nil(config_path) ->
        %{
          target_path: @default_target,
          classification: :manual_review,
          rationale: "Runtime config file could not be discovered automatically.",
          evidence: %{found?: false}
        }

      not File.exists?(config_path) ->
        %{
          target_path: config_path,
          classification: :manual_review,
          rationale: "Runtime config path does not exist on disk.",
          evidence: %{found?: false}
        }

      true ->
        classify_config(config_path, File.read!(config_path))
    end
  end

  defp classify_config(config_path, content) do
    cond do
      Regex.match?(@managed_runtime_block, content) ->
        %{
          target_path: config_path,
          classification: :no_op,
          rationale: "Managed Scoria runtime defaults are already configured.",
          evidence: %{managed_block_present?: true}
        }

      Regex.match?(@conflicting_scoria_config, content) ->
        %{
          target_path: config_path,
          classification: :manual_review,
          rationale: "Scoria config exists but is not owned by the managed runtime block.",
          evidence: %{managed_block_present?: false, conflicting_block?: true}
        }

      true ->
        %{
          target_path: config_path,
          classification: :update,
          rationale: "Runtime config can safely append the managed Scoria runtime defaults.",
          evidence: %{managed_block_present?: false, conflicting_block?: false}
        }
    end
  end
end

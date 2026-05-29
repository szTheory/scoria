defmodule Scoria.Install.Surface.RuntimeConfig do
  @default_target "config/runtime.exs"
  @managed_runtime_block ~r/config\s+:scoria,\s+Scoria\.Runtime/s
  @conflicting_scoria_config ~r/config\s+:scoria,\s+(?!Scoria\.Runtime)[A-Za-z0-9_.]+/s
  @start_marker "# scoria:runtime:start"
  @end_marker "# scoria:runtime:end"
  @verify_command "mix scoria.install --check"

  def analyze(config_path, _opts \\ []) do
    cond do
      is_nil(config_path) ->
        %{
          target_path: @default_target,
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "runtime_config:default",
          fingerprint: "missing",
          drift: %{
            reason_code: "runtime_target_missing",
            marker_state: :missing,
            managed_block_present?: false,
            conflicting_block?: false
          },
          remediation:
            remediation(
              "runtime_target_missing",
              "Runtime config file could not be discovered automatically.",
              [
                "Ensure `config/runtime.exs` exists in this project.",
                "Re-run `mix scoria.install --check` after creating the runtime config file."
              ]
            ),
          rationale: "Runtime config file could not be discovered automatically.",
          evidence: %{found?: false}
        }

      not File.exists?(config_path) ->
        %{
          target_path: config_path,
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "runtime_config:#{config_path}",
          fingerprint: "missing",
          drift: %{
            reason_code: "runtime_target_missing",
            marker_state: :missing,
            managed_block_present?: false,
            conflicting_block?: false
          },
          remediation:
            remediation(
              "runtime_target_missing",
              "Runtime config path does not exist on disk.",
              [
                "Restore the runtime config file path reported in this entry.",
                "Re-run `mix scoria.install --check` after restoring the file."
              ]
            ),
          rationale: "Runtime config path does not exist on disk.",
          evidence: %{found?: false}
        }

      true ->
        classify_config(config_path, File.read!(config_path))
    end
  end

  defp classify_config(config_path, content) do
    marker_state = marker_state(content)
    managed_block_present? = Regex.match?(@managed_runtime_block, content)
    conflicting_block? = Regex.match?(@conflicting_scoria_config, content)

    base_entry = %{
      target_path: config_path,
      ownership_mode: :marker_region,
      manifest_key: "runtime_config:#{config_path}",
      fingerprint: fingerprint(content),
      evidence: %{
        managed_block_present?: managed_block_present?,
        conflicting_block?: conflicting_block?,
        marker_state: marker_state
      }
    }

    case marker_state do
      :owned ->
        cond do
          managed_block_present? ->
            base_entry
            |> Map.put(:classification, :no_op)
            |> Map.put(:operation, :none)
            |> Map.put(:rationale, "Runtime managed region is already configured.")
            |> Map.put(:drift, %{
              reason_code: "managed_region_current",
              marker_state: marker_state,
              managed_block_present?: managed_block_present?,
              conflicting_block?: conflicting_block?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_current",
                "No runtime config changes are required.",
                ["No action required; managed runtime region already matches Scoria defaults."]
              )
            )

          conflicting_block? ->
            base_entry
            |> Map.put(:classification, :manual_review)
            |> Map.put(:operation, :manual_review)
            |> Map.put(
              :rationale,
              "Managed runtime ownership exists, but conflicting Scoria config was detected."
            )
            |> Map.put(:drift, %{
              reason_code: "managed_region_conflict",
              marker_state: marker_state,
              managed_block_present?: managed_block_present?,
              conflicting_block?: conflicting_block?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_conflict",
                "Runtime config contains conflicting Scoria settings.",
                [
                  "Resolve duplicate `config :scoria` declarations so only the managed runtime region remains.",
                  "Keep marker boundaries intact before rerunning the installer."
                ]
              )
            )

          true ->
            base_entry
            |> Map.put(:classification, :update)
            |> Map.put(:operation, :append_managed_region)
            |> Map.put(
              :rationale,
              "Runtime managed region is owned but missing required Scoria defaults."
            )
            |> Map.put(:drift, %{
              reason_code: "managed_region_drift",
              marker_state: marker_state,
              managed_block_present?: managed_block_present?,
              conflicting_block?: conflicting_block?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_drift",
                "Runtime config needs managed Scoria defaults reapplied.",
                [
                  "Run `mix scoria.install` to append the managed runtime defaults.",
                  "Review the updated runtime config and commit once verified."
                ]
              )
            )
        end

      :missing ->
        base_entry
        |> Map.put(:classification, :manual_review)
        |> Map.put(:operation, :manual_review)
        |> Map.put(
          :rationale,
          "Missing runtime ownership markers prevent safe automatic updates."
        )
        |> Map.put(:drift, %{
          reason_code: "missing_ownership_markers",
          marker_state: marker_state,
          managed_block_present?: managed_block_present?,
          conflicting_block?: conflicting_block?
        })
        |> Map.put(
          :remediation,
          remediation(
            "missing_ownership_markers",
            "Runtime config is unmanaged because ownership markers are missing.",
            [
              "Wrap managed runtime defaults with `# scoria:runtime:start` and `# scoria:runtime:end`.",
              "Avoid modifying the managed block outside the marker boundaries."
            ]
          )
        )

      :ambiguous ->
        base_entry
        |> Map.put(:classification, :manual_review)
        |> Map.put(:operation, :manual_review)
        |> Map.put(
          :rationale,
          "Runtime ownership markers are ambiguous and require manual cleanup."
        )
        |> Map.put(:drift, %{
          reason_code: "ambiguous_ownership_markers",
          marker_state: marker_state,
          managed_block_present?: managed_block_present?,
          conflicting_block?: conflicting_block?
        })
        |> Map.put(
          :remediation,
          remediation(
            "ambiguous_ownership_markers",
            "Runtime marker boundaries are incomplete or duplicated.",
            [
              "Ensure exactly one start and one end runtime marker in the file.",
              "Re-run the installer check after normalizing marker placement."
            ]
          )
        )
    end
  end

  defp marker_state(content) do
    start_count = marker_count(content, @start_marker)
    end_count = marker_count(content, @end_marker)

    cond do
      start_count == 1 and end_count == 1 -> :owned
      start_count == 0 and end_count == 0 -> :missing
      true -> :ambiguous
    end
  end

  defp marker_count(content, marker) do
    content
    |> String.split(marker)
    |> length()
    |> Kernel.-(1)
  end

  defp fingerprint(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp remediation(reason_code, summary, steps) do
    %{
      reason_code: reason_code,
      summary: summary,
      steps: steps,
      verify_command: @verify_command
    }
  end
end

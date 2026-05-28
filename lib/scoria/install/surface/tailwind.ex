defmodule Scoria.Install.Surface.Tailwind do
  @tailwind_glob "../deps/scoria/lib/**/*.*ex"
  @default_target "assets/tailwind.config.js"
  @start_marker "// scoria:tailwind:start"
  @end_marker "// scoria:tailwind:end"
  @verify_command "mix scoria.install --check"

  def analyze(tailwind_path, _opts \\ []) do
    cond do
      is_nil(tailwind_path) ->
        %{
          target_path: @default_target,
          classification: :no_op,
          operation: :none,
          ownership_mode: :marker_region,
          manifest_key: "tailwind:default",
          fingerprint: "missing",
          drift: %{
            reason_code: "optional_surface_absent",
            marker_state: :missing,
            glob_present?: false,
            content_anchor?: false
          },
          remediation:
            remediation(
              "optional_surface_absent",
              "Tailwind config is absent and this optional surface is skipped.",
              [
                "No action required unless you want dashboard styles in Tailwind builds.",
                "If needed, add a tailwind config and rerun the installer."
              ]
            ),
          rationale: "Tailwind config is absent; this surface is intentionally skipped.",
          evidence: %{found?: false, optional?: true}
        }

      not File.exists?(tailwind_path) ->
        %{
          target_path: tailwind_path,
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "tailwind:#{tailwind_path}",
          fingerprint: "missing",
          drift: %{
            reason_code: "tailwind_target_missing",
            marker_state: :missing,
            glob_present?: false,
            content_anchor?: false
          },
          remediation:
            remediation(
              "tailwind_target_missing",
              "Tailwind path was provided but does not exist.",
              [
                "Restore the Tailwind config file at the reported path.",
                "Re-run installer check once the path is valid."
              ]
            ),
          rationale: "Tailwind path was provided but does not exist.",
          evidence: %{found?: false, optional?: true}
        }

      true ->
        classify_tailwind(tailwind_path, File.read!(tailwind_path))
    end
  end

  defp classify_tailwind(tailwind_path, content) do
    marker_state = marker_state(content)
    glob_present? = String.contains?(content, @tailwind_glob)
    content_anchor? = Regex.match?(~r/content:\s*\[/s, content)

    base_entry = %{
      target_path: tailwind_path,
      ownership_mode: :marker_region,
      manifest_key: "tailwind:#{tailwind_path}",
      fingerprint: fingerprint(content),
      evidence: %{
        glob_present?: glob_present?,
        content_anchor?: content_anchor?,
        marker_state: marker_state
      }
    }

    case marker_state do
      :owned ->
        cond do
          glob_present? ->
            base_entry
            |> Map.put(:classification, :no_op)
            |> Map.put(:operation, :none)
            |> Map.put(:rationale, "Tailwind managed region already includes the Scoria glob.")
            |> Map.put(:drift, %{
              reason_code: "managed_region_current",
              marker_state: marker_state,
              glob_present?: glob_present?,
              content_anchor?: content_anchor?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_current",
                "No Tailwind changes are required.",
                ["No action required; managed Tailwind content already includes Scoria files."]
              )
            )

          content_anchor? ->
            base_entry
            |> Map.put(:classification, :update)
            |> Map.put(:operation, :patch_managed_region)
            |> Map.put(
              :rationale,
              "Tailwind managed region is owned but missing the Scoria glob."
            )
            |> Map.put(:drift, %{
              reason_code: "managed_region_drift",
              marker_state: marker_state,
              glob_present?: glob_present?,
              content_anchor?: content_anchor?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_drift",
                "Tailwind content list needs the Scoria glob reapplied.",
                [
                  "Run `mix scoria.install` to patch the managed Tailwind content region.",
                  "Verify generated CSS includes Scoria dashboard classes."
                ]
              )
            )

          true ->
            base_entry
            |> Map.put(:classification, :manual_review)
            |> Map.put(:operation, :manual_review)
            |> Map.put(
              :rationale,
              "Tailwind managed region exists but file layout is unsupported."
            )
            |> Map.put(:drift, %{
              reason_code: "managed_region_unpatchable",
              marker_state: marker_state,
              glob_present?: glob_present?,
              content_anchor?: content_anchor?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_unpatchable",
                "Tailwind config cannot be patched safely with current structure.",
                [
                  "Normalize `content: [...]` structure in tailwind config.",
                  "Keep managed Tailwind markers around the Scoria-owned region."
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
          "Missing Tailwind ownership markers prevent safe automatic adoption."
        )
        |> Map.put(:drift, %{
          reason_code: "missing_ownership_markers",
          marker_state: marker_state,
          glob_present?: glob_present?,
          content_anchor?: content_anchor?
        })
        |> Map.put(
          :remediation,
          remediation(
            "missing_ownership_markers",
            "Tailwind config is unmanaged because ownership markers are missing.",
            [
              "Wrap the Scoria Tailwind content entries with `// scoria:tailwind:start` and matching end marker.",
              "Keep the `../deps/scoria/lib/**/*.*ex` glob inside the managed region."
            ]
          )
        )

      :ambiguous ->
        base_entry
        |> Map.put(:classification, :manual_review)
        |> Map.put(:operation, :manual_review)
        |> Map.put(
          :rationale,
          "Tailwind ownership markers are ambiguous and require manual correction."
        )
        |> Map.put(:drift, %{
          reason_code: "ambiguous_ownership_markers",
          marker_state: marker_state,
          glob_present?: glob_present?,
          content_anchor?: content_anchor?
        })
        |> Map.put(
          :remediation,
          remediation(
            "ambiguous_ownership_markers",
            "Tailwind marker boundaries are incomplete or duplicated.",
            [
              "Ensure exactly one start and one end Tailwind marker for the managed region.",
              "Re-run installer check once marker boundaries are corrected."
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

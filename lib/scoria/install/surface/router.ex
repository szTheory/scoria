defmodule Scoria.Install.Surface.Router do
  @default_target "lib/*_web/router.ex"
  @start_marker "# scoria:router:start"
  @end_marker "# scoria:router:end"
  @verify_command "mix scoria.install --check"

  def analyze(router_path, _opts \\ []) do
    cond do
      is_nil(router_path) ->
        %{
          target_path: @default_target,
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "router:default",
          fingerprint: "missing",
          drift: %{
            reason_code: "router_target_missing",
            marker_state: :missing,
            import_present?: false,
            mount_present?: false,
            browser_scope_found?: false
          },
          remediation:
            remediation(
              "router_target_missing",
              "Router file could not be discovered automatically.",
              [
                "Locate your Phoenix router file and re-run `mix scoria.install --check`.",
                "If your router lives in a non-standard location, run from that app root."
              ]
            ),
          rationale: "Router file could not be discovered automatically.",
          evidence: %{found?: false, ambiguous?: true}
        }

      not File.exists?(router_path) ->
        %{
          target_path: router_path,
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "router:#{router_path}",
          fingerprint: "missing",
          drift: %{
            reason_code: "router_target_missing",
            marker_state: :missing,
            import_present?: false,
            mount_present?: false,
            browser_scope_found?: false
          },
          remediation:
            remediation(
              "router_target_missing",
              "Router path does not exist on disk.",
              [
                "Confirm the router path and restore the file.",
                "Re-run `mix scoria.install --check` once the router exists."
              ]
            ),
          rationale: "Router path does not exist on disk.",
          evidence: %{found?: false, ambiguous?: true}
        }

      true ->
        classify_router(router_path, File.read!(router_path))
    end
  end

  defp classify_router(router_path, content) do
    import_present? = String.contains?(content, "import ScoriaWeb.Router")
    mount_present? = Regex.match?(~r/scoria_dashboard\s+"\/scoria"/, content)
    browser_scope_found? = browser_scope_available?(content)
    marker_state = marker_state(content)
    fingerprint = fingerprint(content)

    base_entry = %{
      target_path: router_path,
      ownership_mode: :marker_region,
      manifest_key: "router:#{router_path}",
      fingerprint: fingerprint,
      evidence: %{
        import_present?: import_present?,
        mount_present?: mount_present?,
        browser_scope_found?: browser_scope_found?,
        marker_state: marker_state
      }
    }

    case marker_state do
      :owned ->
        cond do
          import_present? and mount_present? ->
            base_entry
            |> Map.put(:classification, :no_op)
            |> Map.put(:operation, :none)
            |> Map.put(:rationale, "Router managed region is already in sync.")
            |> Map.put(:drift, %{
              reason_code: "managed_region_current",
              marker_state: marker_state,
              import_present?: import_present?,
              mount_present?: mount_present?,
              browser_scope_found?: browser_scope_found?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_current",
                "No router changes are required.",
                ["No action required; ownership markers already match managed content."]
              )
            )

          browser_scope_found? ->
            base_entry
            |> Map.put(:classification, :update)
            |> Map.put(:operation, :patch_managed_region)
            |> Map.put(
              :rationale,
              "Managed router region is owned but drifted from expected content."
            )
            |> Map.put(:drift, %{
              reason_code: "managed_region_drift",
              marker_state: marker_state,
              import_present?: import_present?,
              mount_present?: mount_present?,
              browser_scope_found?: browser_scope_found?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_drift",
                "Router managed region needs a safe update.",
                [
                  "Run `mix scoria.install` to patch the managed router region.",
                  "Review the router diff before committing."
                ]
              )
            )

          true ->
            base_entry
            |> Map.put(:classification, :manual_review)
            |> Map.put(:operation, :manual_review)
            |> Map.put(:rationale, "Managed router region exists but cannot be patched safely.")
            |> Map.put(:drift, %{
              reason_code: "managed_region_unpatchable",
              marker_state: marker_state,
              import_present?: import_present?,
              mount_present?: mount_present?,
              browser_scope_found?: browser_scope_found?
            })
            |> Map.put(
              :remediation,
              remediation(
                "managed_region_unpatchable",
                "Router ownership is present but topology is not safe for automatic edits.",
                [
                  "Restore a root browser scope with `pipe_through :browser`.",
                  "Keep Scoria router markers around the managed region before retrying."
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
          "Missing router ownership markers prevent safe automatic adoption."
        )
        |> Map.put(:drift, %{
          reason_code: "missing_ownership_markers",
          marker_state: marker_state,
          import_present?: import_present?,
          mount_present?: mount_present?,
          browser_scope_found?: browser_scope_found?
        })
        |> Map.put(
          :remediation,
          remediation(
            "missing_ownership_markers",
            "Router is unmanaged because ownership markers are missing.",
            [
              "Wrap the Scoria-managed router region with `# scoria:router:start` and `# scoria:router:end`.",
              "Ensure the region contains `import ScoriaWeb.Router` and `scoria_dashboard \"/scoria\"`."
            ]
          )
        )

      :ambiguous ->
        base_entry
        |> Map.put(:classification, :manual_review)
        |> Map.put(:operation, :manual_review)
        |> Map.put(:rationale, "Router ownership markers are ambiguous and cannot be trusted.")
        |> Map.put(:drift, %{
          reason_code: "ambiguous_ownership_markers",
          marker_state: marker_state,
          import_present?: import_present?,
          mount_present?: mount_present?,
          browser_scope_found?: browser_scope_found?
        })
        |> Map.put(
          :remediation,
          remediation(
            "ambiguous_ownership_markers",
            "Router markers are incomplete or duplicated.",
            [
              "Fix marker pairing so there is one `# scoria:router:start` and one matching end marker.",
              "Re-run the installer check after marker cleanup."
            ]
          )
        )
    end
  end

  defp browser_scope_available?(content) do
    lines = String.split(content, "\n", trim: false)
    match?({:ok, _index, _indent}, browser_scope_index(lines))
  end

  defp browser_scope_index(lines) do
    Enum.reduce_while(Enum.with_index(lines), :error, fn {line, index}, state ->
      trimmed = String.trim(line)
      in_root_scope? = match?({:in_root_scope, _}, state)

      cond do
        root_scope_line?(trimmed) ->
          {:cont, {:in_root_scope, 1}}

        in_root_scope? and browser_pipe_through_line?(trimmed) ->
          [indentation | _] = Regex.run(~r/^\s*/, line)
          {:halt, {:ok, index, indentation <> "  "}}

        in_root_scope? ->
          {:cont, update_scope_depth(state, trimmed)}

        true ->
          {:cont, state}
      end
    end)
  end

  defp root_scope_line?(line) do
    Regex.match?(~r/^scope\s*(?:\(\s*)?"\/"\s*(?:,\s*.*)?(?:\s*\))?\s*do$/, line)
  end

  defp browser_pipe_through_line?(line) do
    Regex.match?(~r/^pipe_through\s*\(?\s*:browser\s*\)?$/, line) or
      Regex.match?(~r/^pipe_through\s*\(?\s*\[[^\]]*:browser[^\]]*\]\s*\)?$/, line)
  end

  defp update_scope_depth({:in_root_scope, depth}, line) do
    delta =
      cond do
        line == "end" -> -1
        String.ends_with?(line, " do") -> 1
        true -> 0
      end

    case depth + delta do
      next_depth when next_depth <= 0 -> :error
      next_depth -> {:in_root_scope, next_depth}
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

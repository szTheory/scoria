defmodule Scoria.Install.Surface.Router do
  @default_target "lib/*_web/router.ex"

  def analyze(router_path, _opts \\ []) do
    cond do
      is_nil(router_path) ->
        %{
          target_path: @default_target,
          classification: :manual_review,
          rationale: "Router file could not be discovered automatically.",
          evidence: %{found?: false, ambiguous?: true}
        }

      not File.exists?(router_path) ->
        %{
          target_path: router_path,
          classification: :manual_review,
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

    cond do
      import_present? and mount_present? ->
        %{
          target_path: router_path,
          classification: :no_op,
          rationale: "Router import and dashboard mount are already present.",
          evidence: %{import_present?: true, mount_present?: true}
        }

      browser_scope_found? ->
        %{
          target_path: router_path,
          classification: :update,
          rationale: "Root browser scope is patchable and Scoria route wiring is incomplete.",
          evidence: %{
            import_present?: import_present?,
            mount_present?: mount_present?,
            browser_scope_found?: true
          }
        }

      true ->
        %{
          target_path: router_path,
          classification: :manual_review,
          rationale: "No unambiguous root browser scope was found for safe patching.",
          evidence: %{
            import_present?: import_present?,
            mount_present?: mount_present?,
            browser_scope_found?: false
          }
        }
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
    String.starts_with?(line, "scope \"/\"") and String.ends_with?(line, "do")
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

    {:in_root_scope, depth + delta}
  end
end

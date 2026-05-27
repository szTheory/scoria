defmodule Scoria.Install.Surface.Tailwind do
  @tailwind_glob "../deps/scoria/lib/**/*.*ex"
  @default_target "assets/tailwind.config.js"

  def analyze(tailwind_path, _opts \\ []) do
    cond do
      is_nil(tailwind_path) ->
        %{
          target_path: @default_target,
          classification: :no_op,
          rationale: "Tailwind config is absent; this surface is intentionally skipped.",
          evidence: %{found?: false, optional?: true}
        }

      not File.exists?(tailwind_path) ->
        %{
          target_path: tailwind_path,
          classification: :manual_review,
          rationale: "Tailwind path was provided but does not exist.",
          evidence: %{found?: false, optional?: true}
        }

      true ->
        classify_tailwind(tailwind_path, File.read!(tailwind_path))
    end
  end

  defp classify_tailwind(tailwind_path, content) do
    cond do
      String.contains?(content, @tailwind_glob) ->
        %{
          target_path: tailwind_path,
          classification: :no_op,
          rationale: "Tailwind Scoria glob is already present.",
          evidence: %{glob_present?: true}
        }

      Regex.match?(~r/content:\s*\[/s, content) ->
        %{
          target_path: tailwind_path,
          classification: :update,
          rationale: "Tailwind content list is present but missing the Scoria glob.",
          evidence: %{glob_present?: false, content_anchor?: true}
        }

      true ->
        %{
          target_path: tailwind_path,
          classification: :manual_review,
          rationale: "Tailwind config format is unsupported for safe automatic updates.",
          evidence: %{glob_present?: false, content_anchor?: false}
        }
    end
  end
end

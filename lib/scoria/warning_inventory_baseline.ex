defmodule Scoria.WarningInventoryBaseline do
  @moduledoc """
  Validates the committed warning inventory baseline JSON (CI-INV-01).

  The baseline must stay checked in with an empty `clusters` map so inventory
  regressions cannot land without an intentional maintainer refresh.
  """

  @default_path ".planning/warning-inventory.baseline.json"
  @required_keys ~w(schema_version git_sha generated_at clusters)
  @schema_version "1.0"

  @spec check!(keyword()) :: :ok
  def check!(opts \\ []) do
    path = Keyword.get(opts, :file, @default_path)
    expanded = resolve_file!(path)

    case File.read(expanded) do
      {:ok, raw} ->
        validate_json!(raw, expanded)

      {:error, reason} ->
        Mix.raise("warning inventory baseline unreadable (#{expanded}): #{inspect(reason)}")
    end
  end

  defp resolve_file!(path) do
    if String.contains?(path, "..") do
      Mix.raise("invalid --file path: path traversal is not allowed")
    end

    cwd = File.cwd!()
    expanded = Path.expand(path, cwd)

    unless String.starts_with?(expanded, cwd) do
      Mix.raise("invalid --file path: must resolve under project root")
    end

    unless File.regular?(expanded) do
      Mix.raise("warning inventory baseline not found: #{path}")
    end

    expanded
  end

  defp validate_json!(raw, path) do
    case Jason.decode(raw) do
      {:ok, %{} = doc} ->
        validate_document!(doc, path)

      {:ok, _} ->
        Mix.raise("warning inventory baseline must be a JSON object: #{path}")

      {:error, reason} ->
        Mix.raise("warning inventory baseline is invalid JSON (#{path}): #{inspect(reason)}")
    end
  end

  defp validate_document!(doc, path) do
    missing = Enum.reject(@required_keys, &Map.has_key?(doc, &1))

    if missing != [] do
      Mix.raise(
        "warning inventory baseline missing keys #{inspect(missing)} in #{path}"
      )
    end

    unless doc["schema_version"] == @schema_version do
      Mix.raise(
        "warning inventory baseline schema_version must be #{inspect(@schema_version)}, got #{inspect(doc["schema_version"])}"
      )
    end

    clusters = doc["clusters"]

    unless is_map(clusters) and map_size(clusters) == 0 do
      Mix.raise(
        "warning inventory baseline clusters must be empty; refresh via mix scoria.warning_inventory --write"
      )
    end

    :ok
  end
end

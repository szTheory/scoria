defmodule Scoria.Install.Manifest do
  @schema_version 1
  @manifest_relative_path Path.join([".scoria", "install", "manifest.json"])

  def path(project_root) when is_binary(project_root) do
    Path.join(project_root, @manifest_relative_path)
  end

  def path(_project_root) do
    @manifest_relative_path
  end

  def load(project_root) do
    manifest_path = path(project_root)

    with true <- File.exists?(manifest_path),
         {:ok, contents} <- File.read(manifest_path),
         {:ok, decoded} <- decode(contents) do
      normalize_manifest(decoded)
    else
      _ -> empty_manifest()
    end
  end

  def write!(project_root, manifest) do
    normalized = normalize_manifest(manifest)
    manifest_path = path(project_root)
    File.mkdir_p!(Path.dirname(manifest_path))
    File.write!(manifest_path, encode!(normalized))
    normalized
  end

  def entry_for(manifest, entry_id) when is_map(manifest) do
    entries = Map.get(manifest, :entries, %{})
    key = to_string(entry_id)

    Map.get(entries, key) || Map.get(entries, entry_id)
  end

  def entry_for(_manifest, _entry_id), do: nil

  defp normalize_manifest(%{"schema_version" => schema_version, "entries" => entries})
       when schema_version == @schema_version and is_map(entries) do
    %{
      schema_version: @schema_version,
      entries: normalize_entries(entries)
    }
  end

  defp normalize_manifest(%{schema_version: schema_version, entries: entries})
       when schema_version == @schema_version and is_map(entries) do
    %{
      schema_version: @schema_version,
      entries: normalize_entries(entries)
    }
  end

  defp normalize_manifest(_), do: empty_manifest()

  defp normalize_entries(entries) do
    entries
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Enum.into(%{})
  end

  defp empty_manifest do
    %{schema_version: @schema_version, entries: %{}}
  end

  defp decode(contents) do
    if Code.ensure_loaded?(Jason) do
      Jason.decode(contents)
    else
      {:error, :jason_unavailable}
    end
  end

  defp encode!(manifest) do
    if Code.ensure_loaded?(Jason) do
      Jason.encode!(manifest, pretty: true)
    else
      raise "Jason is required to write install manifest"
    end
  end
end

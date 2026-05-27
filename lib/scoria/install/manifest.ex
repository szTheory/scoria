defmodule Scoria.Install.Manifest do
  @schema_version 1
  @manifest_relative_path Path.join([".scoria", "install", "manifest.json"])

  def schema_version, do: @schema_version

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

  def validate_freshness(%{entries: entries}, project_root) when is_list(entries) do
    stale_entries =
      entries
      |> Enum.sort_by(&{Map.get(&1, :order, 0), Map.get(&1, :id, "")})
      |> Enum.reduce([], fn entry, acc ->
        expected = to_string(Map.get(entry, :fingerprint, "missing"))
        actual = current_fingerprint(entry, project_root)

        if expected == actual do
          acc
        else
          [
            %{
              id: Map.get(entry, :id, "unknown"),
              surface: Map.get(entry, :surface, :unknown),
              target_path: Map.get(entry, :target_path, "unresolved"),
              expected_fingerprint: expected,
              actual_fingerprint: actual,
              reason_code: "stale_plan_fingerprint"
            }
            | acc
          ]
        end
      end)
      |> Enum.reverse()

    if stale_entries == [] do
      :ok
    else
      {:error, stale_entries}
    end
  end

  def validate_freshness(_plan, _project_root), do: {:error, [%{reason_code: "invalid_plan"}]}

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

  defp current_fingerprint(entry, project_root) do
    case Map.get(entry, :ownership_mode) do
      :structural_set -> structural_fingerprint(entry, project_root)
      _ -> file_fingerprint(Map.get(entry, :target_path))
    end
  end

  defp structural_fingerprint(entry, project_root) do
    drift = Map.get(entry, :drift, %{})
    required = map_value(drift, :required_basenames, [])

    destination_dir =
      case Map.get(entry, :target_path) do
        target when is_binary(target) and target != "" -> target
        _ -> Path.join([project_root || ".", "priv", "repo", "migrations"])
      end

    observed =
      destination_dir
      |> Path.join("*.exs")
      |> Path.wildcard()
      |> Enum.map(&Path.basename/1)
      |> Enum.sort()

    payload = Enum.join(required, ",") <> "|" <> Enum.join(observed, ",")

    :crypto.hash(:sha256, payload)
    |> Base.encode16(case: :lower)
  end

  defp file_fingerprint(target_path) when is_binary(target_path) do
    cond do
      target_path in ["", "unresolved", "n/a"] ->
        "missing"

      File.exists?(target_path) ->
        target_path
        |> File.read!()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)

      true ->
        "missing"
    end
  end

  defp file_fingerprint(_), do: "missing"

  defp map_value(map, key, default) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || default
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

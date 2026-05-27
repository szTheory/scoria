defmodule Scoria.Install.ApplyExecutor do
  alias Scoria.Install.Manifest

  @source_core_migrations Application.app_dir(:scoria, "priv/repo/migrations")
  @optional_lane_migration_basenames MapSet.new([
                                       "20260525070000_create_semantic_cache_tables.exs",
                                       "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                     ])
  @tailwind_glob "../deps/scoria/lib/**/*.*ex"
  @router_start_marker "# scoria:router:start"
  @router_end_marker "# scoria:router:end"
  @runtime_start_marker "# scoria:runtime:start"
  @runtime_end_marker "# scoria:runtime:end"
  @runtime_body """
  config :scoria, Scoria.Runtime,
    defaults: [
      provider: "openai",
      model: "gpt-5-mini",
      prompt_policy: [policy_key: "default"]
    ]
  """
  @tailwind_start_marker "// scoria:tailwind:start"
  @tailwind_end_marker "// scoria:tailwind:end"

  defmodule BlockedApplyError do
    defexception [:status, :message, blockers: []]
  end

  def run(plan, opts \\ []) do
    project_root = Keyword.get(opts, :project_root) || infer_project_root(plan)
    entries = ordered_entries(plan)

    validate_no_blockers!(entries)
    validate_freshness!(plan, project_root)
    Enum.each(entries, &dispatch_operation!(&1, project_root))
    persist_manifest!(project_root, entries)

    %{status: :compliant, exit_code: 0}
  rescue
    error in [BlockedApplyError] ->
      %{status: error.status, exit_code: 1, reason: error.message, blockers: error.blockers}

    error ->
      %{status: :error, exit_code: 2, reason: Exception.message(error)}
  end

  defp ordered_entries(%{entries: entries}) when is_list(entries) do
    Enum.sort_by(entries, &{&1.order, &1.id})
  end

  defp ordered_entries(_plan), do: []

  defp validate_no_blockers!(entries) do
    blockers =
      Enum.filter(entries, fn entry ->
        Map.get(entry, :classification) == :manual_review or
          Map.get(entry, :operation) == :manual_review
      end)

    if blockers == [] do
      :ok
    else
      raise BlockedApplyError,
        status: :manual_review,
        message: "Apply blocked because one or more planner entries require manual review.",
        blockers: Enum.map(blockers, &blocked_entry_payload/1)
    end
  end

  defp validate_freshness!(plan, project_root) do
    case Manifest.validate_freshness(plan, project_root) do
      :ok ->
        :ok

      {:error, stale_entries} ->
        raise BlockedApplyError,
          status: :drift,
          message: "Apply blocked because planner fingerprints are stale.",
          blockers: stale_entries
    end
  end

  defp dispatch_operation!(entry, project_root) do
    case Map.get(entry, :operation) do
      :none ->
        :ok

      :manual_review ->
        raise BlockedApplyError,
          status: :manual_review,
          message: "Apply blocked because a manual-review entry was dispatched.",
          blockers: [blocked_entry_payload(entry)]

      :patch_managed_region ->
        patch_managed_region!(entry)

      :append_managed_region ->
        append_managed_region!(entry)

      :copy_missing_files ->
        copy_missing_migrations!(entry, project_root)

      operation ->
        raise "Unsupported planner operation: #{inspect(operation)} for #{inspect(entry.surface)}"
    end
  end

  defp patch_managed_region!(%{surface: :router, target_path: target_path}) do
    content = File.read!(target_path)
    updated = replace_managed_region!(content, @router_start_marker, @router_end_marker, "import ScoriaWeb.Router")
    final_content = ensure_dashboard_mount!(updated, target_path)
    File.write!(target_path, final_content)
  end

  defp patch_managed_region!(%{surface: :tailwind, target_path: target_path}) do
    content = File.read!(target_path)

    updated =
      update_managed_region!(
        content,
        @tailwind_start_marker,
        @tailwind_end_marker,
        fn managed_region ->
          if String.contains?(managed_region, @tailwind_glob) do
            managed_region
          else
            inject_tailwind_glob!(managed_region)
          end
        end
      )

    File.write!(target_path, updated)
  end

  defp patch_managed_region!(entry) do
    raise "Unsupported patch_managed_region surface: #{inspect(entry.surface)}"
  end

  defp append_managed_region!(%{surface: :runtime_config, target_path: target_path}) do
    content = File.read!(target_path)

    updated =
      replace_managed_region!(
        content,
        @runtime_start_marker,
        @runtime_end_marker,
        @runtime_body
      )

    File.write!(target_path, updated)
  end

  defp append_managed_region!(entry) do
    raise "Unsupported append_managed_region surface: #{inspect(entry.surface)}"
  end

  defp copy_missing_migrations!(entry, project_root) do
    destination_dir =
      case Map.get(entry, :target_path) do
        target when is_binary(target) and target != "" -> target
        _ -> Path.join([project_root || ".", "priv", "repo", "migrations"])
      end

    File.mkdir_p!(destination_dir)
    missing_basenames = drift_value(entry, :missing_basenames, [])

    source_by_basename =
      @source_core_migrations
      |> Path.join("*.exs")
      |> Path.wildcard()
      |> Enum.reject(&(Path.basename(&1) in @optional_lane_migration_basenames))
      |> Enum.map(fn source_path -> {Path.basename(source_path), source_path} end)
      |> Enum.into(%{})

    Enum.each(missing_basenames, fn basename ->
      source_path = Map.get(source_by_basename, basename)

      if is_nil(source_path) do
        raise "Missing canonical migration source for #{basename}"
      end

      destination_path = Path.join(destination_dir, basename)

      unless File.exists?(destination_path) do
        File.cp!(source_path, destination_path)
      end
    end)
  end

  defp persist_manifest!(project_root, entries) do
    manifest_entries =
      entries
      |> Enum.reduce(%{}, fn entry, acc ->
        Map.put(acc, to_string(Map.get(entry, :id, "unknown")), %{
          manifest_key: Map.get(entry, :manifest_key),
          ownership_mode: Map.get(entry, :ownership_mode),
          surface: Map.get(entry, :surface),
          fingerprint: current_fingerprint(entry, project_root)
        })
      end)

    Manifest.write!(project_root, %{schema_version: Manifest.schema_version(), entries: manifest_entries})
  end

  defp blocked_entry_payload(entry) do
    %{
      id: Map.get(entry, :id, "unknown"),
      surface: Map.get(entry, :surface, :unknown),
      target_path: Map.get(entry, :target_path, "unresolved"),
      reason_code: drift_value(entry, :reason_code, "manual_review_required")
    }
  end

  defp infer_project_root(%{entries: entries}) when is_list(entries) do
    entries
    |> Enum.find_value(fn entry -> infer_entry_root(entry) end)
  end

  defp infer_project_root(_plan), do: nil

  defp infer_entry_root(%{surface: :migrations, target_path: target_path}) when is_binary(target_path) do
    target_path |> Path.dirname() |> Path.dirname() |> Path.dirname()
  end

  defp infer_entry_root(%{target_path: target_path}) when is_binary(target_path) do
    expanded = Path.expand(target_path)

    cond do
      String.contains?(expanded, "/config/") ->
        expanded |> Path.dirname() |> Path.dirname()

      String.ends_with?(expanded, "/tailwind.config.js") ->
        maybe_tailwind_root(expanded)

      String.contains?(expanded, "/lib/") ->
        case String.split(expanded, "/lib/", parts: 2) do
          [root, _rest] when root != "" -> root
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp infer_entry_root(_entry), do: nil

  defp maybe_tailwind_root(path) do
    case Path.split(path) |> Enum.reverse() do
      ["tailwind.config.js", "assets" | rest] -> rest |> Enum.reverse() |> Path.join()
      ["tailwind.config.js" | rest] -> rest |> Enum.reverse() |> Path.join()
      _ -> nil
    end
  end

  defp current_fingerprint(entry, project_root) do
    case Map.get(entry, :ownership_mode) do
      :structural_set -> structural_fingerprint(entry, project_root)
      _ -> file_fingerprint(Map.get(entry, :target_path))
    end
  end

  defp structural_fingerprint(entry, project_root) do
    required = drift_value(entry, :required_basenames, [])

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

  defp drift_value(entry, key, default) do
    drift = Map.get(entry, :drift, %{})
    Map.get(drift, key) || Map.get(drift, Atom.to_string(key)) || default
  end

  defp ensure_dashboard_mount!(content, target_path) do
    if Regex.match?(~r/scoria_dashboard\s+"\/scoria"/, content) do
      content
    else
      case inject_dashboard_mount(content) do
        {:ok, updated_content} ->
          updated_content

        :error ->
          raise "Could not patch #{target_path}. Add `scoria_dashboard \"/scoria\"` inside your browser scope manually."
      end
    end
  end

  defp inject_dashboard_mount(content) do
    lines = String.split(content, "\n", trim: false)

    case browser_scope_index(lines) do
      {:ok, index, indent} ->
        injected_lines =
          List.insert_at(lines, index + 1, "#{indent}scoria_dashboard \"/scoria\"")

        {:ok, Enum.join(injected_lines, "\n")}

      :error ->
        :error
    end
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

  defp replace_managed_region!(content, start_marker, end_marker, replacement_body) do
    update_managed_region!(content, start_marker, end_marker, fn _managed_region ->
      "\n" <> String.trim(replacement_body) <> "\n"
    end)
  end

  defp update_managed_region!(content, start_marker, end_marker, updater) do
    case String.split(content, start_marker, parts: 2) do
      [prefix, rest] ->
        case String.split(rest, end_marker, parts: 2) do
          [managed_region, suffix] ->
            updated_region = updater.(managed_region)
            prefix <> start_marker <> updated_region <> end_marker <> suffix

          _ ->
            raise "Managed region end marker #{end_marker} is missing."
        end

      _ ->
        raise "Managed region start marker #{start_marker} is missing."
    end
  end

  defp inject_tailwind_glob!(content) do
    updated =
      Regex.replace(
        ~r/(content:\s*\[)(.*?)(\])/s,
        content,
        fn _, start, inner, ending ->
          inner_trimmed = String.trim_trailing(inner)
          separator = if String.ends_with?(inner_trimmed, ",") or inner_trimmed == "", do: "", else: ","
          "#{start}#{inner}#{separator}\n    \"#{@tailwind_glob}\"\n  #{ending}"
        end
      )

    if updated == content do
      raise "Tailwind managed region is missing a supported content anchor."
    else
      updated
    end
  end
end

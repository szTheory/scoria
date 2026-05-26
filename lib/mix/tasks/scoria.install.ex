defmodule Mix.Tasks.Scoria.Install do
  use Mix.Task

  @shortdoc "Installs the Scoria dashboard, core migrations, and workflow routes into a Phoenix application"
  @tailwind_glob "../deps/scoria/lib/**/*.*ex"
  @source_core_migrations Application.app_dir(:scoria, "priv/repo/migrations")
  @optional_lane_migration_basenames MapSet.new([
                                     "20260525070000_create_semantic_cache_tables.exs",
                                     "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                   ])
  @runtime_config_snippet """

  config :scoria, Scoria.Runtime,
    defaults: [
      provider: "openai",
      model: "gpt-5-mini",
      prompt_policy: [policy_key: "default"]
    ]
  """
  @optional_later_lanes [
    "mix test.adoption",
    "SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path",
    "mix scoria.pgvector.bootstrap",
    "mix test.knowledge"
  ]

  def run(_args) do
    router_paths = Path.wildcard("lib/*_web/router.ex")
    tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]
    config_paths = ["config/runtime.exs", "config/config.exs"]

    router_path = List.first(router_paths)
    tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)
    config_path = Enum.find(config_paths, &File.exists?/1)

    if router_path do
      statuses = do_run(router_path, tailwind_path, config_path)
      print_summary(statuses)
    else
      Mix.shell().error("Could not find router.ex")
    end
  end

  def do_run(router_path, tailwind_path \\ nil, config_path \\ nil) do
    project_root = project_root(router_path, tailwind_path, config_path)

    router_status = inject_router(router_path)
    tailwind_status = maybe_inject_tailwind(tailwind_path)
    migration_status = copy_core_migrations(project_root)
    config_status = inject_runtime_config(config_path)

    %{
      router: router_status,
      tailwind: tailwind_status,
      migrations: migration_status,
      runtime_config: config_status,
      optional_later_lanes: @optional_later_lanes
    }
  end

  defp inject_router(path) do
    content = File.read!(path)

    {content, import_status} =
      if content =~ "import ScoriaWeb.Router" do
        {content, :already_present}
      else
        {Regex.replace(~r/(defmodule .*?\.Router do\n)/, content, "\\1  import ScoriaWeb.Router\n"),
         :installed}
      end

    {content, mount_status} =
      cond do
        content =~ ~r/scoria_dashboard\s+"\/scoria"/ ->
          {content, :already_present}

        true ->
          case inject_dashboard_mount(content) do
            {:ok, updated_content} ->
              {updated_content, :installed}

            :error ->
              raise Mix.Error,
                    "Could not patch #{path}. Add `scoria_dashboard \"/scoria\"` inside your browser scope manually."
          end
      end

    File.write!(path, content)

    cond do
      import_status == :installed or mount_status == :installed -> :installed
      true -> :already_present
    end
  end

  defp maybe_inject_tailwind(nil), do: :skipped

  defp maybe_inject_tailwind(path) do
    content = File.read!(path)
    already_present? = content =~ @tailwind_glob

    content =
      if already_present? do
        content
      else
        Regex.replace(
          ~r/(content:\s*\[)(.*?)(\])/s,
          content,
          fn _, start, inner, ending ->
            inner_trimmed = String.trim_trailing(inner)

            separator =
              if String.ends_with?(inner_trimmed, ",") or inner_trimmed == "", do: "", else: ","

            "#{start}#{inner}#{separator}\n    \"#{@tailwind_glob}\"\n  #{ending}"
          end
        )
      end

    File.write!(path, content)

    if already_present?, do: :already_present, else: :installed
  end

  defp copy_core_migrations(project_root) do
    destination_dir = Path.join([project_root, "priv", "repo", "migrations"])
    File.mkdir_p!(destination_dir)

    copied? =
      @source_core_migrations
      |> Path.join("*.exs")
      |> Path.wildcard()
      |> Enum.reject(&(Path.basename(&1) in @optional_lane_migration_basenames))
      |> Enum.reduce(false, fn source_path, copied? ->
        destination_path = Path.join(destination_dir, Path.basename(source_path))

        if File.exists?(destination_path) do
          copied?
        else
          File.cp!(source_path, destination_path)
          true
        end
      end)

    if copied?, do: :installed, else: :already_present
  end

  defp project_root(router_path, tailwind_path, config_path) do
    [
      config_root(config_path),
      tailwind_root(tailwind_path),
      router_root(router_path)
    ]
    |> Enum.find(& &1)
  end

  defp config_root(nil), do: nil

  defp config_root(path) do
    path
    |> Path.expand()
    |> Path.dirname()
    |> Path.dirname()
  end

  defp tailwind_root(nil), do: nil

  defp tailwind_root(path) do
    expanded = Path.expand(path)

    case Path.split(expanded) |> Enum.reverse() do
      ["tailwind.config.js", "assets" | rest] -> rest |> Enum.reverse() |> Path.join()
      ["tailwind.config.js" | rest] -> rest |> Enum.reverse() |> Path.join()
      _ -> nil
    end
  end

  defp router_root(path) do
    expanded = Path.expand(path)

    case String.split(expanded, "/lib/", parts: 2) do
      [root, _rest] when root != "" -> root
      _ -> Path.dirname(expanded)
    end
  end

  defp inject_runtime_config(nil), do: :skipped

  defp inject_runtime_config(path) do
    content = File.read!(path)

    if content =~ "config :scoria, Scoria.Runtime" do
      :already_present
    else
      File.write!(path, String.trim_trailing(content) <> @runtime_config_snippet <> "\n")
      :installed
    end
  end

  defp print_summary(statuses) do
    Mix.shell().info("Scoria installed for the default Phoenix lane.")
    Mix.shell().info("Default lane verifier: mix test.adoption")
    Mix.shell().info("")
    Mix.shell().info("Installed:")

    Enum.each(installed_lines(statuses), fn line ->
      Mix.shell().info("  - #{line}")
    end)

    Mix.shell().info("")
    Mix.shell().info("Skipped intentionally:")

    Enum.each(skipped_lines(statuses), fn line ->
      Mix.shell().info("  - #{line}")
    end)

    Mix.shell().info("")
    Mix.shell().info("Optional later lanes:")

    Enum.each(statuses.optional_later_lanes, fn line ->
      Mix.shell().info("  - #{line}")
    end)
  end

  defp installed_lines(statuses) do
    [
      status_line(
        statuses.router,
        "Router import and /scoria dashboard mount installed.",
        "Router import and /scoria dashboard mount already present."
      ),
      status_line(
        statuses.migrations,
        "Copied Scoria core migrations into priv/repo/migrations.",
        "Scoria core migrations already present in priv/repo/migrations."
      ),
      status_line(
        statuses.runtime_config,
        "Baseline Scoria runtime defaults installed.",
        "Baseline Scoria runtime defaults already present.",
        nil
      ),
      status_line(
        statuses.tailwind,
        "Tailwind content injection installed.",
        "Tailwind content injection already present.",
        nil
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp skipped_lines(statuses) do
    [
      status_line(
        statuses.tailwind,
        nil,
        nil,
        "Tailwind config not found; skipped intentionally. Default lane still installable."
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp status_line(:installed, installed, _already_present, _skipped), do: installed
  defp status_line(:already_present, _installed, already_present, _skipped), do: already_present
  defp status_line(:skipped, _installed, _already_present, skipped), do: skipped
  defp status_line(nil, _installed, _already_present, _skipped), do: nil

  defp status_line(status, installed, already_present) do
    status_line(status, installed, already_present, nil)
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
    line == "pipe_through :browser" or line == "pipe_through(:browser)"
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

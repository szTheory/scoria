defmodule Scoria.Install.Planner do
  alias Scoria.Install.Surface.Migrations
  alias Scoria.Install.Surface.Router
  alias Scoria.Install.Surface.RuntimeConfig
  alias Scoria.Install.Surface.Tailwind

  @surface_order [:router, :tailwind, :migrations, :runtime_config]

  def build(router_path, tailwind_path, config_path, opts \\ []) do
    mode = Keyword.get(opts, :mode, :dry_run)
    project_root = project_root(router_path, tailwind_path, config_path)

    entries =
      [
        {:router, Router.analyze(router_path, opts)},
        {:tailwind, Tailwind.analyze(tailwind_path, opts)},
        {:migrations, Migrations.analyze(project_root, opts)},
        {:runtime_config, RuntimeConfig.analyze(config_path, opts)}
      ]
      |> annotate_entries()

    %{
      schema_version: 1,
      mode: mode,
      entries: entries,
      summary: summarize(entries)
    }
  end

  defp annotate_entries(entries) do
    order_index =
      @surface_order
      |> Enum.with_index(1)
      |> Enum.into(%{})

    entries
    |> Enum.map(fn {surface, entry} ->
      order = Map.fetch!(order_index, surface)
      target_path = entry.target_path || "unresolved"

      entry
      |> Map.put(:id, stable_id(surface, target_path))
      |> Map.put(:surface, surface)
      |> Map.put(:target_path, target_path)
      |> Map.put(:order, order)
    end)
    |> Enum.sort_by(& &1.order)
  end

  defp stable_id(surface, target_path) do
    digest =
      :crypto.hash(:sha256, "#{surface}:#{target_path}")
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    "#{surface}:#{digest}"
  end

  defp summarize(entries) do
    Enum.reduce(entries, %{create: 0, update: 0, no_op: 0, manual_review: 0}, fn entry, acc ->
      Map.update!(acc, entry.classification, &(&1 + 1))
    end)
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

  defp router_root(nil), do: nil

  defp router_root(path) do
    expanded = Path.expand(path)

    case String.split(expanded, "/lib/", parts: 2) do
      [root, _rest] when root != "" -> root
      _ -> Path.dirname(expanded)
    end
  end
end

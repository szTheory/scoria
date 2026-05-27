defmodule Scoria.Install.Planner do
  alias Scoria.Install.Manifest
  alias Scoria.Install.Surface.Migrations
  alias Scoria.Install.Surface.Router
  alias Scoria.Install.Surface.RuntimeConfig
  alias Scoria.Install.Surface.Tailwind

  @surface_order [:router, :tailwind, :migrations, :runtime_config]

  def build(router_path, tailwind_path, config_path, opts \\ []) do
    mode = Keyword.get(opts, :mode, :dry_run)
    project_root = project_root(router_path, tailwind_path, config_path)
    manifest = Manifest.load(project_root)

    entries =
      [
        {:router, Router.analyze(router_path, opts)},
        {:tailwind, Tailwind.analyze(tailwind_path, opts)},
        {:migrations, Migrations.analyze(project_root, opts)},
        {:runtime_config, RuntimeConfig.analyze(config_path, opts)}
      ]
      |> annotate_entries(manifest)

    %{
      schema_version: 1,
      mode: mode,
      entries: entries,
      summary: summarize(entries)
    }
  end

  defp annotate_entries(entries, manifest) do
    order_index =
      @surface_order
      |> Enum.with_index(1)
      |> Enum.into(%{})

    entries
    |> Enum.map(fn {surface, entry} ->
      order = Map.fetch!(order_index, surface)
      target_path = entry.target_path || "unresolved"
      id = stable_id(surface, target_path)

      entry
      |> Map.put(:id, id)
      |> Map.put(:surface, surface)
      |> Map.put(:target_path, target_path)
      |> Map.put(:order, order)
      |> normalize_contract_fields(surface, id, manifest)
    end)
    |> Enum.sort_by(&{&1.order, &1.id})
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

  defp normalize_contract_fields(entry, surface, id, manifest) do
    manifest_entry = Manifest.entry_for(manifest, id) || %{}

    entry
    |> Map.put_new(:operation, operation_from_classification(entry.classification))
    |> Map.put_new(:ownership_mode, ownership_mode_for_surface(surface))
    |> Map.put_new(:manifest_key, id)
    |> Map.put_new(:fingerprint, manifest_entry[:fingerprint] || "unavailable")
    |> Map.put_new(:drift, %{reason_code: reason_code_for_classification(entry.classification)})
    |> Map.put_new(
      :remediation,
      %{
        reason_code: reason_code_for_classification(entry.classification),
        summary: entry.rationale || "See entry rationale for details.",
        steps: [],
        verify_command: "mix scoria.install --check"
      }
    )
  end

  defp operation_from_classification(:create), do: :create
  defp operation_from_classification(:update), do: :update
  defp operation_from_classification(:no_op), do: :none
  defp operation_from_classification(:manual_review), do: :manual_review
  defp operation_from_classification(_), do: :manual_review

  defp ownership_mode_for_surface(:migrations), do: :structural_set
  defp ownership_mode_for_surface(_), do: :marker_region

  defp reason_code_for_classification(:create), do: "planned_create"
  defp reason_code_for_classification(:update), do: "planned_update"
  defp reason_code_for_classification(:no_op), do: "planned_no_op"
  defp reason_code_for_classification(:manual_review), do: "planned_manual_review"
  defp reason_code_for_classification(_), do: "planned_unknown"
end

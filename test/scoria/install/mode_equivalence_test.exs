defmodule Scoria.Install.ModeEquivalenceTest do
  use ExUnit.Case, async: false

  alias Scoria.Install.Planner
  alias Scoria.TestSupport.HostInstallFixtures

  @tmp_dir "test/tmp/install_equivalence"

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  for kind <- [:compliant, :drift, :manual_review] do
    test "dry_run and check planner bodies match for #{kind}" do
      fixture = HostInstallFixtures.build!(unquote(kind), tmp_parent: @tmp_dir)

      dry_run_plan =
        Planner.build(fixture.router_path, fixture.tailwind_path, fixture.config_path,
          mode: :dry_run
        )

      check_plan =
        Planner.build(fixture.router_path, fixture.tailwind_path, fixture.config_path,
          mode: :check
        )

      assert normalize_plan(dry_run_plan) == normalize_plan(check_plan)
    end
  end

  defp normalize_plan(plan) do
    %{
      entries: Enum.map(plan.entries, &normalize_entry/1),
      summary: plan.summary,
      manifest_state: plan.manifest_state,
      manifest_path: plan.manifest_path
    }
  end

  defp normalize_entry(entry) do
    entry
    |> Map.drop([:id, :order])
    |> Map.update(:evidence, %{}, &normalize_map/1)
    |> Map.update(:drift, %{}, &normalize_map/1)
    |> Map.update(:remediation, %{}, &normalize_map/1)
  end

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {to_string(key), normalize_value(value)}
    end)
    |> Enum.sort()
    |> Enum.into(%{})
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value
end

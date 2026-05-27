defmodule Scoria.Install.PlannerTest do
  use ExUnit.Case, async: false

  alias Scoria.Install.Planner

  @tmp_dir "test/tmp/install_planner"

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(Path.join([@tmp_dir, "lib", "dummy_host_web"]))
    File.mkdir_p!(Path.join([@tmp_dir, "config"]))
    File.mkdir_p!(Path.join([@tmp_dir, "priv", "repo", "migrations"]))

    router_path = Path.join([@tmp_dir, "lib", "dummy_host_web", "router.ex"])
    tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
    config_path = Path.join(@tmp_dir, "config/runtime.exs")

    File.write!(
      router_path,
      """
      defmodule DummyHostWeb.Router do
        use DummyHostWeb, :router

        scope "/", DummyHostWeb do
          pipe_through :browser
        end
      end
      """
    )

    File.write!(
      tailwind_path,
      """
      module.exports = {
        content: ["./js/**/*.js"]
      }
      """
    )

    File.write!(config_path, "import Config\n")

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path, config_path: config_path}
  end

  test "build returns schema and required planner entry keys", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    plan = Planner.build(router_path, tailwind_path, config_path, mode: :dry_run)

    assert plan.schema_version == 1
    assert plan.mode == :dry_run
    assert length(plan.entries) == 4

    Enum.each(plan.entries, fn entry ->
      assert Map.has_key?(entry, :id)
      assert Map.has_key?(entry, :surface)
      assert Map.has_key?(entry, :target_path)
      assert Map.has_key?(entry, :classification)
      assert Map.has_key?(entry, :operation)
      assert Map.has_key?(entry, :ownership_mode)
      assert Map.has_key?(entry, :manifest_key)
      assert Map.has_key?(entry, :fingerprint)
      assert Map.has_key?(entry, :drift)
      assert Map.has_key?(entry, :remediation)
      assert Map.has_key?(entry, :rationale)
      assert Map.has_key?(entry, :evidence)
      assert Map.has_key?(entry, :order)
    end)
  end

  test "build keeps deterministic surface order and stable ids", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    plan = Planner.build(router_path, tailwind_path, config_path, mode: :dry_run)
    plan_again = Planner.build(router_path, tailwind_path, config_path, mode: :dry_run)

    assert Enum.map(plan.entries, & &1.surface) == [
             :router,
             :tailwind,
             :migrations,
             :runtime_config
           ]

    assert Enum.map(plan.entries, & &1.id) == Enum.map(plan_again.entries, & &1.id)
    assert plan.entries == Enum.sort_by(plan.entries, &{&1.order, &1.id})
  end

  test "missing marker ownership falls back to manual_review", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    plan = Planner.build(router_path, tailwind_path, config_path, mode: :check)

    plan.entries
    |> Enum.filter(&(&1.ownership_mode == :marker_region))
    |> Enum.each(fn entry ->
      assert entry.classification == :manual_review
      assert entry.operation == :manual_review
      assert entry.drift.reason_code == "missing_ownership_markers"
      assert entry.remediation.reason_code == "missing_ownership_markers"
      assert entry.remediation.verify_command == "mix scoria.install --check"
    end)
  end
end

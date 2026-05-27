defmodule Mix.Tasks.Scoria.InstallTest do
  use ExUnit.Case, async: false

  alias Scoria.Install.ApplyExecutor
  alias Scoria.Install.Planner

  @tmp_dir "test/tmp/installer"

  setup do
    repo_root = File.cwd!()
    fixture_root = Path.join(@tmp_dir, "fixture-#{System.unique_integer([:positive])}")
    router_path = Path.join([fixture_root, "lib", "dummy_host_web", "router.ex"])
    tailwind_path = Path.join(fixture_root, "tailwind.config.js")
    config_path = Path.join([fixture_root, "config", "runtime.exs"])

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(config_path))
    File.mkdir_p!(Path.join([fixture_root, "priv", "repo", "migrations"]))

    File.write!(
      Path.join([fixture_root, "lib", "dummy_host.ex"]),
      "defmodule DummyHost do\nend\n"
    )

    File.write!(router_path, unmanaged_router())
    File.write!(tailwind_path, unmanaged_tailwind())
    File.write!(Path.join([fixture_root, "config", "config.exs"]), "import Config\n")
    File.write!(config_path, "import Config\n")
    write_host_mix_project!(fixture_root, repo_root)
    File.cp!(Path.join(repo_root, "mix.lock"), Path.join(fixture_root, "mix.lock"))

    on_exit(fn -> File.rm_rf!(fixture_root) end)

    {:ok,
     repo_root: repo_root,
     fixture_root: fixture_root,
     router_path: router_path,
     tailwind_path: tailwind_path,
     config_path: config_path}
  end

  test "mix scoria.install --dry-run does not mutate host files", ctx do
    before_snapshot = snapshot_host_files(ctx)

    {output, exit_code} = run_install_subprocess(ctx, ["--dry-run"])

    after_snapshot = snapshot_host_files(ctx)

    assert exit_code == 0
    assert output =~ "Scoria install plan (mode: dry_run)"
    assert after_snapshot == before_snapshot
  end

  test "mix scoria.install --dry-run output is deterministic across repeated runs", ctx do
    {first_output, first_exit} = run_install_subprocess(ctx, ["--dry-run"])
    {second_output, second_exit} = run_install_subprocess(ctx, ["--dry-run"])

    assert first_exit == 0
    assert second_exit == 0
    assert normalize_install_output(second_output) == normalize_install_output(first_output)
  end

  test "mix scoria.install --check does not mutate host files", ctx do
    before_snapshot = snapshot_host_files(ctx)
    {output, exit_code} = run_install_subprocess(ctx, ["--check"])
    after_snapshot = snapshot_host_files(ctx)

    assert exit_code == 1
    assert output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"
    assert after_snapshot == before_snapshot
  end

  test "mix scoria.install blocks apply with zero writes when manual review exists", ctx do
    before_snapshot = snapshot_host_files(ctx)
    {output, exit_code} = run_install_subprocess(ctx, [])
    after_snapshot = snapshot_host_files(ctx)

    assert exit_code == 1
    assert output =~ "reason_code: missing_ownership_markers"
    assert output =~ "SCORIA_CHECK_RESULT status=manual_review exit_code=1"
    assert after_snapshot == before_snapshot
  end

  test "mix scoria.install apply executes only planner-classified actionable operations", ctx do
    write_owned_managed_files!(ctx)
    before_snapshot = snapshot_host_files(ctx)
    plan = Planner.build(ctx.router_path, ctx.tailwind_path, ctx.config_path, mode: :apply)

    actionable_surfaces =
      plan.entries
      |> Enum.filter(&(&1.classification in [:create, :update]))
      |> Enum.map(& &1.surface)
      |> MapSet.new()

    result = ApplyExecutor.run(plan, project_root: ctx.fixture_root)
    after_snapshot = snapshot_host_files(ctx)

    assert result.exit_code == 0
    assert result.status == :compliant
    assert actionable_surfaces == MapSet.new([:router, :migrations, :runtime_config])
    assert changed_surfaces(before_snapshot, after_snapshot) == actionable_surfaces
  end

  test "mix scoria.install apply avoids router writes when only non-root scope has browser pipeline",
       ctx do
    write_owned_managed_files!(ctx)
    File.write!(ctx.router_path, owned_router_with_non_root_browser_scope())

    before_snapshot = snapshot_host_files(ctx)
    plan = Planner.build(ctx.router_path, ctx.tailwind_path, ctx.config_path, mode: :apply)
    router_entry = Enum.find(plan.entries, &(&1.surface == :router))

    assert router_entry.classification == :manual_review
    assert router_entry.operation == :manual_review
    assert router_entry.drift.reason_code == "managed_region_unpatchable"

    result = ApplyExecutor.run(plan, project_root: ctx.fixture_root)
    after_snapshot = snapshot_host_files(ctx)

    assert result.exit_code == 1
    assert result.status == :manual_review
    assert after_snapshot == before_snapshot

    assert Enum.any?(result.blockers, fn blocker ->
             blocker.surface == :router and blocker.reason_code == "managed_region_unpatchable"
           end)
  end

  test "mix scoria.install blocks stale planner fingerprints before writes", ctx do
    write_owned_managed_files!(ctx)
    plan = Planner.build(ctx.router_path, ctx.tailwind_path, ctx.config_path, mode: :apply)

    File.write!(ctx.router_path, File.read!(ctx.router_path) <> "\n# stale-change")
    before_snapshot = snapshot_host_files(ctx)

    result = ApplyExecutor.run(plan, project_root: ctx.fixture_root)
    after_snapshot = snapshot_host_files(ctx)

    assert result.exit_code == 1
    assert result.status == :drift
    assert after_snapshot == before_snapshot
  end

  defp run_install_subprocess(ctx, args) do
    System.cmd("mix", ["scoria.install" | args],
      cd: ctx.fixture_root,
      stderr_to_stdout: true,
      env: subprocess_mix_env(ctx.repo_root)
    )
  end

  defp snapshot_host_files(ctx) do
    migration_files =
      ctx.fixture_root
      |> Path.join("priv/repo/migrations/*.exs")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(fn path -> {Path.basename(path), File.read!(path)} end)

    %{
      router: File.read!(ctx.router_path),
      tailwind: File.read!(ctx.tailwind_path),
      runtime_config: File.read!(ctx.config_path),
      migration_files: migration_files
    }
  end

  defp changed_surfaces(before_snapshot, after_snapshot) do
    %{
      router: before_snapshot.router != after_snapshot.router,
      tailwind: before_snapshot.tailwind != after_snapshot.tailwind,
      runtime_config: before_snapshot.runtime_config != after_snapshot.runtime_config,
      migrations: before_snapshot.migration_files != after_snapshot.migration_files
    }
    |> Enum.filter(fn {_surface, changed?} -> changed? end)
    |> Enum.map(fn {surface, _changed?} -> surface end)
    |> MapSet.new()
  end

  defp write_owned_managed_files!(ctx) do
    File.write!(
      ctx.router_path,
      """
      defmodule DummyHostWeb.Router do
        use DummyHostWeb, :router

        # scoria:router:start
        import ScoriaWeb.Router
        # scoria:router:end

        pipeline :browser do
          plug :accepts, ["html"]
        end

        scope "/", DummyHostWeb do
          pipe_through :browser
          get "/", PageController, :home
        end
      end
      """
    )

    File.write!(
      ctx.tailwind_path,
      """
      // scoria:tailwind:start
      module.exports = {
        content: [
          "./js/**/*.js",
          "../lib/dummy_host_web.ex",
          "../lib/dummy_host_web/**/*.*ex",
          "../deps/scoria/lib/**/*.*ex"
        ]
      }
      // scoria:tailwind:end
      """
    )

    File.write!(
      ctx.config_path,
      """
      import Config

      # scoria:runtime:start
      # managed by scoria
      # scoria:runtime:end
      """
    )
  end

  defp unmanaged_router do
    """
    defmodule DummyHostWeb.Router do
      use DummyHostWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", DummyHostWeb do
        pipe_through :browser
        get "/", PageController, :home
      end
    end
    """
  end

  defp owned_router_with_non_root_browser_scope do
    """
    defmodule DummyHostWeb.Router do
      use DummyHostWeb, :router

      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", DummyHostWeb do
        get "/", PageController, :home
      end

      scope "/admin", DummyHostWeb do
        pipe_through :browser
        get "/dashboard", AdminController, :index
      end
    end
    """
  end

  defp unmanaged_tailwind do
    """
    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/dummy_host_web.ex",
        "../lib/dummy_host_web/**/*.*ex"
      ]
    }
    """
  end

  defp subprocess_mix_env(repo_root) do
    [
      {"MIX_ENV", "test"},
      {"MIX_BUILD_PATH", Path.join(repo_root, "_build/install_subprocess")},
      {"MIX_DEPS_PATH", Path.join(repo_root, "deps")}
    ]
  end

  defp write_host_mix_project!(tmp_dir, repo_root) do
    File.write!(
      Path.join(tmp_dir, "mix.exs"),
      """
      defmodule DummyHost.MixProject do
        use Mix.Project

        def project do
          [
            app: :dummy_host,
            version: "0.1.0",
            deps: deps()
          ]
        end

        def application do
          [extra_applications: [:logger]]
        end

        defp deps do
          [
            {:scoria, path: #{inspect(repo_root)}}
          ]
        end
      end
      """
    )
  end

  defp normalize_install_output(output) do
    case String.split(output, "Scoria install plan", parts: 2) do
      [_prefix, plan_output] -> "Scoria install plan" <> plan_output
      _ -> output
    end
  end
end

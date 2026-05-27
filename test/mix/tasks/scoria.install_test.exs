defmodule Mix.Tasks.Scoria.InstallTest do
  use ExUnit.Case, async: false
  alias Scoria.VerificationLanes

  @tmp_dir "test/tmp/installer"

  setup do
    repo_root = File.cwd!()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("scoria.install")
    File.mkdir_p!(@tmp_dir)
    File.mkdir_p!(Path.join([@tmp_dir, "lib", "dummy_host_web"]))
    File.mkdir_p!(Path.join(@tmp_dir, "config"))
    File.mkdir_p!(Path.join([@tmp_dir, "priv", "repo", "migrations"]))

    router_content = """
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

    tailwind_content = """
    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/dummy_host_web.ex",
        "../lib/dummy_host_web/**/*.*ex"
      ],
      theme: {
        extend: {},
      },
      plugins: [],
    }
    """

    router_path = Path.join([@tmp_dir, "lib", "dummy_host_web", "router.ex"])
    tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
    config_path = Path.join(@tmp_dir, "config/runtime.exs")

    File.write!(router_path, router_content)
    File.write!(tailwind_path, tailwind_content)
    File.write!(Path.join([@tmp_dir, "config", "config.exs"]), "import Config\n")
    File.write!(config_path, "import Config\n")
    File.write!(Path.join([@tmp_dir, "lib", "dummy_host.ex"]), "defmodule DummyHost do\nend\n")
    write_host_mix_project!(@tmp_dir, repo_root)
    File.cp!(Path.join(repo_root, "mix.lock"), Path.join(@tmp_dir, "mix.lock"))

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok,
     router_path: router_path,
     tailwind_path: tailwind_path,
     config_path: config_path,
     repo_root: repo_root}
  end

  test "mix scoria.install reports installed skipped and optional lanes truthfully on first install",
       %{
         router_path: router_path,
         tailwind_path: tailwind_path,
         config_path: config_path
       } do
    output =
      capture_install_run(%{
        router_path: router_path,
        tailwind_path: tailwind_path,
        config_path: config_path
      })

    assert output =~ "Installed:"
    assert output =~ "Router import and /scoria dashboard mount installed."
    assert output =~ "Copied Scoria core migrations into priv/repo/migrations."
    assert output =~ "Baseline Scoria runtime defaults installed."
    assert output =~ "Skipped intentionally:"
    assert output =~ "Tailwind content injection installed."
    assert output =~ "Optional later lanes:"
    assert output =~ "Default lane verifier: mix test.adoption"
    assert output =~ VerificationLanes.command(:adoption)

    assert output =~ VerificationLanes.command(:semantic_fast_path)

    assert output =~ "mix scoria.pgvector.bootstrap"
    assert output =~ VerificationLanes.command(:knowledge)
  end

  test "mix scoria.install reruns without duplicate mutations and reports already-present state",
       %{
         router_path: router_path,
         tailwind_path: tailwind_path,
         config_path: config_path
       } do
    capture_install_run(%{
      router_path: router_path,
      tailwind_path: tailwind_path,
      config_path: config_path
    })

    output =
      capture_install_run(%{
        router_path: router_path,
        tailwind_path: tailwind_path,
        config_path: config_path
      })

    assert output =~ "Router import and /scoria dashboard mount already present."
    assert output =~ "Scoria core migrations already present in priv/repo/migrations."
    assert output =~ "Baseline Scoria runtime defaults already present."
    assert output =~ "Tailwind content injection already present."

    updated_router = File.read!(router_path)
    assert length(String.split(updated_router, "scoria_dashboard")) == 2

    updated_tailwind = File.read!(tailwind_path)
    assert length(String.split(updated_tailwind, "../deps/scoria/lib/**/*.*ex")) == 2

    updated_config = File.read!(config_path)
    assert length(String.split(updated_config, "config :scoria, Scoria.Runtime")) == 2
  end

  test "mix scoria.install --dry-run does not mutate host files", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    before_snapshot = snapshot_host_files(router_path, tailwind_path, config_path)

    capture_install_run(
      %{
        router_path: router_path,
        tailwind_path: tailwind_path,
        config_path: config_path
      },
      ["--dry-run"]
    )

    after_snapshot = snapshot_host_files(router_path, tailwind_path, config_path)

    assert after_snapshot.router == before_snapshot.router
    assert after_snapshot.tailwind == before_snapshot.tailwind
    assert after_snapshot.runtime_config == before_snapshot.runtime_config
    assert after_snapshot.migration_files == before_snapshot.migration_files
  end

  test "mix scoria.install --dry-run output is deterministic across repeated runs", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    first_output =
      capture_install_run(
        %{
          router_path: router_path,
          tailwind_path: tailwind_path,
          config_path: config_path
        },
        ["--dry-run"]
      )

    second_output =
      capture_install_run(
        %{
          router_path: router_path,
          tailwind_path: tailwind_path,
          config_path: config_path
        },
        ["--dry-run"]
      )

    assert second_output == first_output
  end

  test "mix scoria.install --check does not mutate host files", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path,
    repo_root: repo_root
  } do
    before_snapshot = snapshot_host_files(router_path, tailwind_path, config_path)

    {output, exit_code} = run_check_subprocess(@tmp_dir, repo_root)

    after_snapshot = snapshot_host_files(router_path, tailwind_path, config_path)

    assert exit_code in [0, 1, 2]
    assert output =~ "SCORIA_CHECK_RESULT status="
    assert after_snapshot.router == before_snapshot.router
    assert after_snapshot.tailwind == before_snapshot.tailwind
    assert after_snapshot.runtime_config == before_snapshot.runtime_config
    assert after_snapshot.migration_files == before_snapshot.migration_files
  end

  test "mix scoria.install --dry-run prints classification, target path, and rationale for every surface",
       %{
         router_path: router_path,
         tailwind_path: tailwind_path,
         config_path: config_path
       } do
    output =
      capture_install_run(
        %{
          router_path: router_path,
          tailwind_path: tailwind_path,
          config_path: config_path
        },
        ["--dry-run"]
      )

    assert output =~ "1. router"
    assert output =~ "2. tailwind"
    assert output =~ "3. migrations"
    assert output =~ "4. runtime_config"
    assert length(Regex.scan(~r/classification:/, output)) == 4
    assert length(Regex.scan(~r/target path:/, output)) == 4
    assert length(Regex.scan(~r/rationale:/, output)) == 4
  end

  test "mix scoria.install injects router tailwind and baseline runtime config once", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)

    updated_router = File.read!(router_path)
    assert updated_router =~ "import ScoriaWeb.Router"
    assert updated_router =~ "scoria_dashboard \"/scoria\""
    assert length(String.split(updated_router, "scoria_dashboard")) == 2

    updated_tailwind = File.read!(tailwind_path)
    assert updated_tailwind =~ "\"../deps/scoria/lib/**/*.*ex\""
    assert length(String.split(updated_tailwind, "../deps/scoria/lib/**/*.*ex")) == 2

    updated_config = File.read!(config_path)
    assert updated_config =~ "config :scoria, Scoria.Runtime"
    assert updated_config =~ "provider: \"openai\""
    assert length(String.split(updated_config, "config :scoria, Scoria.Runtime")) == 2

    copied_migrations =
      Path.join([@tmp_dir, "priv", "repo", "migrations", "*.exs"])
      |> Path.wildcard()
      |> Enum.map(&Path.basename/1)

    assert "20260510015813_create_ai_observability_tables.exs" in copied_migrations
    refute "20260525070000_create_semantic_cache_tables.exs" in copied_migrations
    refute "20260525090000_add_semantic_cache_compatibility_fields.exs" in copied_migrations
    assert length(copied_migrations) == length(Enum.uniq(copied_migrations))
  end

  test "mix scoria.install still supports router and tailwind injection without a config file", %{
    router_path: router_path,
    tailwind_path: tailwind_path
  } do
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)

    assert File.read!(router_path) =~ "scoria_dashboard \"/scoria\""
    assert File.read!(tailwind_path) =~ "\"../deps/scoria/lib/**/*.*ex\""
  end

  test "mix scoria.install patches root browser scope when pipe_through uses a browser list", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    File.write!(
      router_path,
      """
      defmodule DummyHostWeb.Router do
        use DummyHostWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
        end

        scope "/", DummyHostWeb do
          pipe_through [:browser, :set_actor]

          get "/", PageController, :home
        end
      end
      """
    )

    output =
      capture_install_run(%{
        router_path: router_path,
        tailwind_path: tailwind_path,
        config_path: config_path
      })

    updated_router = File.read!(router_path)
    assert updated_router =~ "scoria_dashboard \"/scoria\""
    assert output =~ "Router import and /scoria dashboard mount installed."
  end

  test "mix scoria.install patches root browser scope when pipe_through list uses call syntax", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    File.write!(
      router_path,
      """
      defmodule DummyHostWeb.Router do
        use DummyHostWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
        end

        scope "/", DummyHostWeb do
          pipe_through([:browser, :set_actor])

          get "/", PageController, :home
        end
      end
      """
    )

    output =
      capture_install_run(%{
        router_path: router_path,
        tailwind_path: tailwind_path,
        config_path: config_path
      })

    updated_router = File.read!(router_path)
    assert updated_router =~ "scoria_dashboard \"/scoria\""
    assert output =~ "Router import and /scoria dashboard mount installed."
  end

  test "mix scoria.install keeps the default lane installable when tailwind is absent", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    File.rm!(tailwind_path)
    output = capture_install_run(%{router_path: router_path, config_path: config_path})

    assert File.read!(router_path) =~ "scoria_dashboard \"/scoria\""
    assert File.read!(config_path) =~ "config :scoria, Scoria.Runtime"
    assert output =~ "Skipped intentionally:"

    assert output =~
             "Tailwind config not found; skipped intentionally. Default lane still installable."

    copied_migrations =
      Path.join([@tmp_dir, "priv", "repo", "migrations", "*.exs"])
      |> Path.wildcard()

    assert copied_migrations != []
  end

  test "mix scoria.install fails with manual guidance when no browser scope can be patched", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    File.write!(
      router_path,
      """
      defmodule DummyHostWeb.Router do
        use DummyHostWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
        end

        scope "/api", DummyHostWeb do
          pipe_through :api
        end
      end
      """
    )

    assert_raise Mix.Error,
                 ~r/Add `scoria_dashboard "\/scoria"` inside your browser scope manually/,
                 fn ->
                   capture_install_run(%{
                     router_path: router_path,
                     tailwind_path: tailwind_path,
                     config_path: config_path
                   })
                 end

    refute File.read!(router_path) =~ "scoria_dashboard \"/scoria\""
    assert File.read!(tailwind_path) =~ "./js/**/*.js"
    assert File.read!(config_path) == "import Config\n"
  end

  defp capture_install_run(_paths, args \\ []) do
    File.cd!(@tmp_dir, fn ->
      Mix.Task.reenable("scoria.install")
      Mix.Tasks.Scoria.Install.run(args)

      collect_shell_messages([])
      |> Enum.reverse()
      |> Enum.map_join("\n", fn {level, message} -> "[#{level}] #{message}" end)
    end)
  end

  defp run_check_subprocess(fixture_root, repo_root) do
    System.cmd("mix", ["scoria.install", "--check"],
      cd: fixture_root,
      stderr_to_stdout: true,
      env: subprocess_mix_env(repo_root)
    )
  end

  defp snapshot_host_files(router_path, tailwind_path, config_path) do
    %{
      router: File.read!(router_path),
      tailwind: File.read!(tailwind_path),
      runtime_config: File.read!(config_path),
      migration_files: migration_basenames()
    }
  end

  defp migration_basenames do
    @tmp_dir
    |> Path.join("priv/repo/migrations/*.exs")
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
    |> Enum.sort()
  end

  defp collect_shell_messages(messages) do
    receive do
      {:mix_shell, level, message} ->
        collect_shell_messages([{level, message} | messages])
    after
      0 -> messages
    end
  end

  defp subprocess_mix_env(repo_root) do
    [
      {"MIX_ENV", "test"},
      {"MIX_BUILD_PATH", Path.join(repo_root, "_build/test")},
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
end

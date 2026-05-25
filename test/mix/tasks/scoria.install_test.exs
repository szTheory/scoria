defmodule Mix.Tasks.Scoria.InstallTest do
  use ExUnit.Case, async: false

  @tmp_dir "test/tmp/installer"

  setup do
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
    File.write!(config_path, "import Config\n")

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path, config_path: config_path}
  end

  test "mix scoria.install reports installed skipped and optional lanes truthfully on first install", %{
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
    assert output =~ "mix test.adoption"

    assert output =~
             ~s(SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix test.semantic_fast_path)

    assert output =~ "mix scoria.pgvector.bootstrap"
    assert output =~ "mix scoria.test.knowledge"
  end

  test "mix scoria.install reruns without duplicate mutations and reports already-present state", %{
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
    assert "20260525090000_add_semantic_cache_compatibility_fields.exs" in copied_migrations
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
    assert output =~ "Tailwind config not found; skipped intentionally. Default lane still installable."

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

  defp capture_install_run(_paths) do
    File.cd!(@tmp_dir, fn ->
      Mix.Task.reenable("scoria.install")
      Mix.Tasks.Scoria.Install.run([])

      collect_shell_messages([])
      |> Enum.reverse()
      |> Enum.map_join("\n", fn {level, message} -> "[#{level}] #{message}" end)
    end)
  end

  defp collect_shell_messages(messages) do
    receive do
      {:mix_shell, level, message} ->
        collect_shell_messages([{level, message} | messages])
    after
      0 -> messages
    end
  end
end

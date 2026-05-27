defmodule Mix.Tasks.Scoria.InstallCheckTest do
  use ExUnit.Case, async: false

  @tmp_dir "test/tmp/install_check"
  @optional_lane_migration_basenames MapSet.new([
                                       "20260525070000_create_semantic_cache_tables.exs",
                                       "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                     ])

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  test "mix scoria.install --check returns tri-state exits and stable trailers" do
    assert_check_result(:compliant, 0, "SCORIA_CHECK_RESULT status=compliant exit_code=0")
    assert_check_result(:drift, 1, "SCORIA_CHECK_RESULT status=drift exit_code=1")
    assert_check_result(:manual_review, 1, "SCORIA_CHECK_RESULT status=manual_review exit_code=1")
    assert_check_result(:error, 2, "SCORIA_CHECK_RESULT status=error exit_code=2")
  end

  defp assert_check_result(fixture_kind, expected_exit, trailer) do
    fixture_root = build_fixture!(fixture_kind)

    {output, exit_code} =
      System.cmd("mix", ["scoria.install", "--check"],
        cd: fixture_root,
        stderr_to_stdout: true,
        env: subprocess_mix_env()
      )

    assert exit_code == expected_exit
    assert output =~ trailer
  end

  defp build_fixture!(fixture_kind) do
    fixture_root = Path.join(@tmp_dir, "#{fixture_kind}-#{System.unique_integer([:positive])}")
    repo_root = File.cwd!()
    migration_dir = Path.join([fixture_root, "priv", "repo", "migrations"])
    router_path = Path.join([fixture_root, "lib", "fixture_host_web", "router.ex"])
    runtime_config_path = Path.join([fixture_root, "config", "runtime.exs"])
    config_path = Path.join([fixture_root, "config", "config.exs"])
    app_module_path = Path.join([fixture_root, "lib", "fixture_host.ex"])
    root_tailwind_path = Path.join(fixture_root, "tailwind.config.js")
    assets_tailwind_path = Path.join([fixture_root, "assets", "tailwind.config.js"])

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(runtime_config_path))
    File.mkdir_p!(migration_dir)
    File.mkdir_p!(Path.dirname(app_module_path))

    File.write!(Path.join(fixture_root, "mix.exs"), fixture_mix_exs(repo_root))
    File.cp!(Path.join(repo_root, "mix.lock"), Path.join(fixture_root, "mix.lock"))
    File.write!(app_module_path, "defmodule FixtureHost do\nend\n")
    File.write!(config_path, "import Config\n")
    File.write!(runtime_config_path, compliant_runtime_config())
    File.write!(router_path, router_fixture(fixture_kind))

    case fixture_kind do
      :error ->
        File.mkdir_p!(Path.dirname(assets_tailwind_path))
        File.mkdir_p!(assets_tailwind_path)

      _ ->
        File.write!(root_tailwind_path, compliant_tailwind_config())
    end

    copy_required_core_migrations!(migration_dir)
    fixture_root
  end

  defp fixture_mix_exs(repo_root) do
    """
    defmodule FixtureHost.MixProject do
      use Mix.Project

      def project do
        [
          app: :fixture_host,
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
  end

  defp router_fixture(:compliant) do
    ~S'''
    defmodule FixtureHostWeb.Router do
      @router """
      import ScoriaWeb.Router
      scope "/", FixtureHostWeb do
        pipe_through :browser
        scoria_dashboard "/scoria"
      end
      """
    end
    '''
  end

  defp router_fixture(:drift) do
    ~S'''
    defmodule FixtureHostWeb.Router do
      @router """
      scope "/", FixtureHostWeb do
        pipe_through :browser
      end
      """
    end
    '''
  end

  defp router_fixture(:manual_review) do
    ~S'''
    defmodule FixtureHostWeb.Router do
      @router """
      import ScoriaWeb.Router
      scope "/api", FixtureHostWeb do
        pipe_through :api
      end
      """
    end
    '''
  end

  defp router_fixture(:error), do: router_fixture(:compliant)

  defp compliant_runtime_config do
    """
    import Config

    config :scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5-mini",
        prompt_policy: [policy_key: "default"]
      ]
    """
  end

  defp compliant_tailwind_config do
    """
    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/fixture_host_web.ex",
        "../lib/fixture_host_web/**/*.*ex",
        "../deps/scoria/lib/**/*.*ex"
      ]
    }
    """
  end

  defp copy_required_core_migrations!(destination_dir) do
    source_dir = Application.app_dir(:scoria, "priv/repo/migrations")

    source_dir
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.reject(&(Path.basename(&1) in @optional_lane_migration_basenames))
    |> Enum.each(fn source_path ->
      File.cp!(source_path, Path.join(destination_dir, Path.basename(source_path)))
    end)
  end

  defp subprocess_mix_env do
    repo_root = File.cwd!()

    [
      {"MIX_ENV", "test"},
      {"MIX_BUILD_PATH", Path.join(repo_root, "_build/test")},
      {"MIX_DEPS_PATH", Path.join(repo_root, "deps")}
    ]
  end
end

defmodule Scoria.TestSupport.HostInstallFixtures do
  @optional_lane_migration_basenames MapSet.new([
                                       "20260525070000_create_semantic_cache_tables.exs",
                                       "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                     ])

  @doc """
  Builds a subprocess installer host fixture for `kind`.

  Returns `%{root: path, repo_root: path, router_path: ..., tailwind_path: ..., config_path: ...}`.
  """
  def build!(kind, opts \\ []) do
    tmp_parent = Keyword.get(opts, :tmp_parent, "test/tmp/install_check")
    repo_root = Keyword.get(opts, :repo_root, File.cwd!())
    fixture_root = Path.join(tmp_parent, "#{kind}-#{System.unique_integer([:positive])}")

    router_path = Path.join([fixture_root, "lib", host_web_module(kind), "router.ex"])
    runtime_config_path = Path.join([fixture_root, "config", "runtime.exs"])
    config_path = Path.join([fixture_root, "config", "config.exs"])
    app_module_path = Path.join([fixture_root, "lib", host_app_module(kind) <> ".ex"])
    migration_dir = Path.join([fixture_root, "priv", "repo", "migrations"])
    root_tailwind_path = Path.join(fixture_root, "tailwind.config.js")
    assets_tailwind_path = Path.join([fixture_root, "assets", "tailwind.config.js"])

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(runtime_config_path))
    File.mkdir_p!(migration_dir)
    File.mkdir_p!(Path.dirname(app_module_path))

    File.write!(Path.join(fixture_root, "mix.exs"), fixture_mix_exs(repo_root, kind))
    File.cp!(Path.join(repo_root, "mix.lock"), Path.join(fixture_root, "mix.lock"))
    File.write!(app_module_path, "defmodule #{host_app_module(kind)} do\nend\n")
    File.write!(config_path, "import Config\n")
    File.write!(runtime_config_path, runtime_config_fixture(kind))
    File.write!(router_path, router_fixture(kind))

    write_tailwind_fixtures!(kind, root_tailwind_path, assets_tailwind_path)
    copy_required_core_migrations!(migration_dir, repo_root)

    if kind == :drift do
      remove_one_required_migration!(migration_dir)
    end

    %{
      root: fixture_root,
      repo_root: repo_root,
      router_path: router_path,
      tailwind_path: tailwind_path(kind, root_tailwind_path, assets_tailwind_path),
      config_path: runtime_config_path,
      migration_dir: migration_dir
    }
  end

  def subprocess_mix_env(repo_root \\ File.cwd!()) do
    [
      {"MIX_ENV", "test"},
      {"MIX_BUILD_PATH", Path.join(repo_root, "_build/install_subprocess")},
      {"MIX_DEPS_PATH", Path.join(repo_root, "deps")}
    ]
  end

  def snapshot_host_files(%{root: root, router_path: router_path, config_path: config_path} = ctx) do
    tailwind_paths = [
      Path.join(root, "tailwind.config.js"),
      Path.join(root, "assets/tailwind.config.js")
    ]

    tailwind_snapshot =
      tailwind_paths
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(fn path -> {path, File.read!(path)} end)
      |> Enum.into(%{})

    migration_files =
      root
      |> Path.join("priv/repo/migrations/*.exs")
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(fn path -> {Path.basename(path), File.read!(path)} end)

    manifest_path = Path.join(root, ".scoria/install/manifest.json")

    %{
      router: File.read!(router_path),
      runtime_config: File.read!(config_path),
      tailwind: tailwind_snapshot,
      migration_files: migration_files,
      manifest_exists: File.exists?(manifest_path)
    }
    |> Map.merge(Map.take(ctx, [:router_path, :tailwind_path, :config_path, :root]))
  end

  defp host_app_module(:owned_apply_host), do: "OwnedHost"
  defp host_app_module(_), do: "FixtureHost"

  defp host_web_module(:owned_apply_host), do: "owned_host_web"
  defp host_web_module(_), do: "fixture_host_web"

  defp tailwind_path(:optional_surface_absent, _root, _assets), do: nil

  defp tailwind_path(_kind, root_tailwind_path, _assets), do: root_tailwind_path

  defp write_tailwind_fixtures!(:optional_surface_absent, _root, _assets), do: :ok

  defp write_tailwind_fixtures!(:error, _root, assets_tailwind_path) do
    File.mkdir_p!(Path.dirname(assets_tailwind_path))
    File.mkdir_p!(assets_tailwind_path)
  end

  defp write_tailwind_fixtures!(kind, root_tailwind_path, _assets) do
    File.write!(root_tailwind_path, tailwind_fixture(kind))
  end

  defp router_fixture(:compliant) do
    compliant_router_string_form()
  end

  defp router_fixture(:drift), do: router_fixture(:compliant)

  defp router_fixture(:root_list_form_browser) do
    ~S'''
    defmodule FixtureHostWeb.Router do
      @router """
      scope "/", FixtureHostWeb do
        pipe_through [:browser]
        scoria_dashboard "/scoria"
      end
      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end
      """
    end
    '''
  end

  defp router_fixture(:non_root_browser_only) do
    ~S'''
    defmodule FixtureHostWeb.Router do
      use FixtureHostWeb, :router

      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", FixtureHostWeb do
        get "/", PageController, :home
      end

      scope "/admin", FixtureHostWeb do
        pipe_through :browser
        get "/dashboard", AdminController, :index
      end
    end
    '''
  end

  defp router_fixture(:owned_apply_host) do
    ~S'''
    defmodule OwnedHostWeb.Router do
      use OwnedHostWeb, :router

      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", OwnedHostWeb do
        pipe_through :browser
        get "/", PageController, :home
      end
    end
    '''
  end

  defp router_fixture(:manual_review) do
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

  defp router_fixture(:optional_surface_absent), do: router_fixture(:compliant)
  defp router_fixture(:error), do: router_fixture(:compliant)

  defp compliant_router_string_form do
    ~S'''
    defmodule FixtureHostWeb.Router do
      @router """
      scope "/", FixtureHostWeb do
        pipe_through :browser
        scoria_dashboard "/scoria"
      end
      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end
      """
    end
    '''
  end

  defp runtime_config_fixture(:manual_review), do: "import Config\n"

  defp runtime_config_fixture(:owned_apply_host) do
    """
    import Config

    # scoria:runtime:start
    config :scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5-mini",
        prompt_policy: [policy_key: "default"]
      ]
    # scoria:runtime:end
    """
  end

  defp runtime_config_fixture(_fixture_kind) do
    """
    import Config

    # scoria:runtime:start
    config :scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5-mini",
        prompt_policy: [policy_key: "default"]
      ]
    # scoria:runtime:end
    """
  end

  defp tailwind_fixture(:manual_review) do
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

  defp tailwind_fixture(:owned_apply_host) do
    """
    // scoria:tailwind:start
    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/owned_host_web.ex",
        "../lib/owned_host_web/**/*.*ex",
        "../deps/scoria/lib/**/*.*ex"
      ]
    }
    // scoria:tailwind:end
    """
  end

  defp tailwind_fixture(_fixture_kind) do
    """
    // scoria:tailwind:start
    module.exports = {
      content: [
        "./js/**/*.js",
        "../lib/fixture_host_web.ex",
        "../lib/fixture_host_web/**/*.*ex",
        "../deps/scoria/lib/**/*.*ex"
      ]
    }
    // scoria:tailwind:end
    """
  end

  defp fixture_mix_exs(repo_root, :owned_apply_host) do
    """
    defmodule OwnedHost.MixProject do
      use Mix.Project

      def project do
        [
          app: :owned_host,
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

  defp fixture_mix_exs(repo_root, _kind) do
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

  defp copy_required_core_migrations!(destination_dir, repo_root) do
    source_dir = Path.join(repo_root, "priv/repo/migrations")

    source_dir
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.reject(&(Path.basename(&1) in @optional_lane_migration_basenames))
    |> Enum.each(fn source_path ->
      File.cp!(source_path, Path.join(destination_dir, Path.basename(source_path)))
    end)
  end

  defp remove_one_required_migration!(destination_dir) do
    destination_dir
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
    |> List.first()
    |> then(&File.rm!/1)
  end
end

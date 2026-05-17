defmodule Mix.Tasks.Scoria.InstallTest do
  use ExUnit.Case, async: false

  @tmp_dir "test/tmp/installer"

  setup do
    File.mkdir_p!(@tmp_dir)
    File.mkdir_p!(Path.join(@tmp_dir, "config"))

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

    router_path = Path.join(@tmp_dir, "router.ex")
    tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
    config_path = Path.join(@tmp_dir, "config/runtime.exs")

    File.write!(router_path, router_content)
    File.write!(tailwind_path, tailwind_content)
    File.write!(config_path, "import Config\n")

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path, config_path: config_path}
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
  end

  test "mix scoria.install still supports router and tailwind injection without a config file", %{
    router_path: router_path,
    tailwind_path: tailwind_path
  } do
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)

    assert File.read!(router_path) =~ "scoria_dashboard \"/scoria\""
    assert File.read!(tailwind_path) =~ "\"../deps/scoria/lib/**/*.*ex\""
  end
end

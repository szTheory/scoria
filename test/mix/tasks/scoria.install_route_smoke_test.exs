defmodule Mix.Tasks.Scoria.InstallRouteSmokeTest do
  use ExUnit.Case, async: false

  @tmp_dir "test/tmp/installer-route-smoke"

  setup do
    File.mkdir_p!(@tmp_dir)
    File.mkdir_p!(Path.join([@tmp_dir, "config"]))
    File.mkdir_p!(Path.join([@tmp_dir, "priv", "repo", "migrations"]))

    router_content = """
    defmodule DummyHostInstall.Router do
      use Phoenix.Router
      import Plug.Conn

      # scoria:router:start
      import ScoriaWeb.Router
      # scoria:router:end

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
      end

      scope "/" do
        pipe_through(:browser)
      end
    end
    """

    tailwind_content = """
    // scoria:tailwind:start
    module.exports = {
      content: [
        "./js/**/*.js",
        "../deps/scoria/lib/**/*.*ex"
      ],
      theme: {
        extend: {},
      },
      plugins: [],
    }
    // scoria:tailwind:end
    """

    router_path = Path.join(@tmp_dir, "router.ex")
    tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
    config_path = Path.join([@tmp_dir, "config", "runtime.exs"])

    File.write!(router_path, router_content)
    File.write!(tailwind_path, tailwind_content)
    File.write!(Path.join([@tmp_dir, "config", "config.exs"]), "import Config\n")

    File.write!(
      config_path,
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
    )

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path, config_path: config_path}
  end

  test "installed /scoria routes resolve through Phoenix router metadata", %{
    router_path: router_path,
    tailwind_path: tailwind_path,
    config_path: config_path
  } do
    result = Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)
    assert result.exit_code == 0
    Code.compile_string(File.read!(router_path))

    assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
             Phoenix.LiveView.Plug

    assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
             Phoenix.LiveView.Plug
  end
end

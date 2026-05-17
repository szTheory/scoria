defmodule Mix.Tasks.Scoria.InstallRouteSmokeTest do
  use ExUnit.Case, async: false

  @tmp_dir "test/tmp/installer-route-smoke"

  setup do
    File.mkdir_p!(@tmp_dir)

    router_content = """
    defmodule DummyHostInstall.Router do
      use Phoenix.Router
      import Plug.Conn

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
    module.exports = {
      content: [
        "./js/**/*.js"
      ],
      theme: {
        extend: {},
      },
      plugins: [],
    }
    """

    router_path = Path.join(@tmp_dir, "router.ex")
    tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")

    File.write!(router_path, router_content)
    File.write!(tailwind_path, tailwind_content)

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path}
  end

  test "installed /scoria routes resolve through Phoenix router metadata", %{
    router_path: router_path,
    tailwind_path: tailwind_path
  } do
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
    Code.compile_string(File.read!(router_path))

    assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
             Phoenix.LiveView.Plug

    assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
             Phoenix.LiveView.Plug
  end
end

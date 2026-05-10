defmodule Mix.Tasks.Scoria.InstallTest do
  use ExUnit.Case, async: false
  import Mix.Tasks.Scoria.Install

  @tmp_dir "test/tmp/installer"

  setup do
    File.mkdir_p!(@tmp_dir)

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

    File.write!(router_path, router_content)
    File.write!(tailwind_path, tailwind_content)

    on_exit(fn -> File.rm_rf!(@tmp_dir) end)

    {:ok, router_path: router_path, tailwind_path: tailwind_path}
  end

  test "mix scoria.install automatically injects the router macro and tailwind config", %{router_path: router_path, tailwind_path: tailwind_path} do
    # Call the install logic
    # In reality it uses File.cwd!, so we need our install logic to accept paths or we mock them.
    # We will pass the paths to an internal do_run/2 function for testability.
    Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)

    # Verify Router
    updated_router = File.read!(router_path)
    assert updated_router =~ "import ScoriaWeb.Router"
    assert updated_router =~ "scoria_dashboard \"/scoria\""

    # Verify Tailwind
    updated_tailwind = File.read!(tailwind_path)
    assert updated_tailwind =~ "\"../deps/scoria/lib/**/*.*ex\""
  end
end

defmodule ScoriaWeb.RouterTest do
  use ExUnit.Case, async: true

  defmodule HostHook do
    def on_mount(:default, _params, _session, socket), do: {:cont, socket}
  end

  defmodule HostHookOne do
    def on_mount(:default, _params, _session, socket), do: {:cont, socket}
  end

  defmodule HostHookTwo do
    def on_mount(:scoria_access, _params, _session, socket), do: {:cont, socket}
  end

  defmodule ScopeResolver do
    def resolve(_params, _session, _socket),
      do: {:ok, %{tenant_id: "tenant-router", actor_id: "actor-router"}}
  end

  defmodule CallerLayout do
    def render(_template, assigns), do: assigns
  end

  defmodule DummyRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)
      scoria_dashboard("/scoria")
    end
  end

  defmodule SingleHostHookRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)
      scoria_dashboard("/scoria", on_mount: HostHook)
    end
  end

  defmodule HostHookListRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)
      scoria_dashboard("/scoria", on_mount: [HostHookOne, {HostHookTwo, :scoria_access}])
    end
  end

  defmodule ScopeResolverRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      scoria_dashboard("/scoria",
        on_mount: HostHook,
        scope_resolver: ScopeResolver
      )
    end
  end

  defmodule CallerOverrideRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      scoria_dashboard("/scoria",
        on_mount: HostHook,
        root_layout: {CallerLayout, :root},
        live_session_opts: [on_mount: []]
      )
    end
  end

  test "scoria_dashboard macro mounts orchestrator live view" do
    assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria", nil).plug ==
             Phoenix.LiveView.Plug
  end

  test "scoria_dashboard macro mounts workflow run live view" do
    assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/workflows/123", nil).plug ==
             Phoenix.LiveView.Plug
  end

  test "scoria_dashboard macro mounts incident detail live view" do
    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ScoriaWeb.IncidentsLive.Show, :show, _, _}
           } = Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/incidents/123", nil)
  end

  test "scoria_dashboard macro mounts dataset builder live view" do
    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ScoriaWeb.DatasetLive.Index, :index, _, _}
           } = Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/datasets", nil)
  end

  test "scoria_dashboard macro mounts coming-soon live view" do
    assert %{plug: Phoenix.LiveView.Plug} =
             Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/coming/cost-ledger", nil)
  end

  test "bare macro keeps Scoria-owned scope and nav hooks" do
    assert hook_ids(DummyRouter) == [
             {ScoriaWeb.DashboardScope, :default},
             {ScoriaWeb.DashboardNav, :default}
           ]
  end

  test "single hook host form compiles before Scoria hooks" do
    assert hook_ids(SingleHostHookRouter) == [
             {HostHook, :default},
             {ScoriaWeb.DashboardScope, :default},
             {ScoriaWeb.DashboardNav, :default}
           ]
  end

  test "hook list host forms compile before Scoria hooks" do
    assert hook_ids(HostHookListRouter) == [
             {HostHookOne, :default},
             {HostHookTwo, :scoria_access},
             {ScoriaWeb.DashboardScope, :default},
             {ScoriaWeb.DashboardNav, :default}
           ]
  end

  test "hook ordering keeps DashboardNav last after host hooks and dashboard scope" do
    assert List.last(hook_ids(HostHookListRouter)) == {ScoriaWeb.DashboardNav, :default}
    assert Enum.at(hook_ids(HostHookListRouter), -2) == {ScoriaWeb.DashboardScope, :default}
  end

  test "scope_resolver router opt becomes the DashboardScope hook argument" do
    assert hook_ids(ScopeResolverRouter) == [
             {HostHook, :default},
             {ScoriaWeb.DashboardScope, ScopeResolver},
             {ScoriaWeb.DashboardNav, :default}
           ]
  end

  test "caller opts cannot remove DashboardNav or replace Scoria root layout" do
    assert {ScoriaWeb.Layouts, :root} = live_session_extra(CallerOverrideRouter).root_layout
    assert List.last(hook_ids(CallerOverrideRouter)) == {ScoriaWeb.DashboardNav, :default}
  end

  test "invalid hook host shapes fail through Phoenix LiveView validation" do
    assert_raise ArgumentError, ~r/invalid on_mount hook declared/, fn ->
      compile_router_with_opts(on_mount: ["not-a-hook"])
    end
  end

  defp hook_ids(router) do
    router
    |> live_session_extra()
    |> Map.fetch!(:on_mount)
    |> Enum.map(&Map.fetch!(&1, :id))
  end

  defp live_session_extra(router) do
    assert %{phoenix_live_view: {_, _, _, %{extra: extra}}} =
             Phoenix.Router.route_info(router, "GET", "/scoria", nil)

    extra
  end

  defp compile_router_with_opts(opts) do
    module = Module.concat(__MODULE__, "InvalidHookRouter#{System.unique_integer([:positive])}")
    opts = Macro.escape(opts)

    Code.compile_quoted(
      quote do
        defmodule unquote(module) do
          use Phoenix.Router
          import ScoriaWeb.Router

          pipeline :browser do
            plug(:accepts, ["html"])
          end

          scope "/" do
            pipe_through(:browser)
            scoria_dashboard("/scoria", unquote(opts))
          end
        end
      end
    )
  end
end

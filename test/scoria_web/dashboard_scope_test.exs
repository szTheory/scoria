defmodule ScoriaWeb.DashboardScopeTest do
  use ExUnit.Case, async: true

  @unavailable_copy "This Scoria dashboard is not available for this session."

  defmodule ModuleResolver do
    def resolve(_params, session, _socket) do
      {:ok,
       %{
         tenant_id: session["tenant_id"],
         actor_id: session["actor_id"],
         session_id: session["session_id"],
         display_tenant: "Module tenant"
       }}
    end
  end

  defmodule MFAResolver do
    def resolve(_params, _session, _socket, tenant_id, actor_id) do
      {:ok, [tenant_id: tenant_id, actor_id: actor_id, display_tenant: "MFA tenant"]}
    end
  end

  defmodule UnauthorizedResolver do
    def resolve(_params, _session, _socket), do: {:error, :unauthorized}
  end

  defmodule MissingScopeResolver do
    def resolve(_params, _session, _socket), do: {:error, :missing_scope}
  end

  defmodule RedirectResolver do
    def resolve(_params, _session, _socket), do: {:redirect, "/login"}
  end

  defmodule HaltResolver do
    import Phoenix.Component, only: [assign: 3]

    def resolve(_params, _session, socket), do: {:halt, assign(socket, :host_halt, true)}
  end

  defmodule MalformedResolver do
    def resolve(_params, _session, _socket), do: {:ok, %{tenant_id: "tenant-a"}, :extra}
  end

  describe "new!/1" do
    test "normalizes plain maps and keyword lists into a dashboard scope struct" do
      assert_scope(new!(%{"tenant_id" => " tenant-a ", "actor_id" => " actor-a "}), %{
        tenant_id: "tenant-a",
        actor_id: "actor-a"
      })

      assert_scope(
        new!(tenant_id: "tenant-b", session_id: "session-b", display_tenant: "Tenant B"),
        %{
          tenant_id: "tenant-b",
          session_id: "session-b",
          display_tenant: "Tenant B"
        }
      )
    end

    test "raises for missing, blank, or non-string tenant identifiers" do
      assert_raise ArgumentError, ~r/tenant_id is required/, fn -> new!(%{}) end
      assert_raise ArgumentError, ~r/tenant_id is required/, fn -> new!(tenant_id: "   ") end

      assert_raise ArgumentError, ~r/scope identifiers must be strings/, fn ->
        new!(tenant_id: 123)
      end
    end
  end

  describe "from_session/1 and resolve/4" do
    test "default resolver accepts host-set session scope" do
      assert_scope(
        from_session(%{
          "tenant_id" => "tenant-session",
          "actor_id" => "actor-session",
          "session_id" => "session-1"
        }),
        %{
          tenant_id: "tenant-session",
          actor_id: "actor-session",
          session_id: "session-1"
        }
      )
    end

    test "module and MFA resolver forms return normalized dashboard scope data" do
      assert {:ok, module_scope} =
               resolve(ModuleResolver, %{}, %{
                 "tenant_id" => "tenant-module",
                 "actor_id" => "actor-module",
                 "session_id" => "session-module"
               })

      assert_scope(module_scope, %{
        tenant_id: "tenant-module",
        actor_id: "actor-module",
        session_id: "session-module",
        display_tenant: "Module tenant"
      })

      assert {:ok, mfa_scope} =
               resolve({MFAResolver, :resolve, ["tenant-mfa", "actor-mfa"]}, %{}, %{})

      assert_scope(mfa_scope, %{
        tenant_id: "tenant-mfa",
        actor_id: "actor-mfa",
        display_tenant: "MFA tenant"
      })
    end

    test "default resolver ignores query params as tenant authority" do
      assert {:ok, scope} =
               resolve(
                 :default,
                 %{"tenant" => "spoofed-tenant", "tenant_id" => "also-spoofed"},
                 %{"tenant_id" => "trusted-session"}
               )

      assert_scope(scope, %{tenant_id: "trusted-session"})

      assert {:error, :missing_scope} =
               resolve(:default, %{"tenant" => "spoofed-tenant"}, %{})
    end
  end

  describe "on_mount/4" do
    test "valid resolver assigns scoria_scope, tenant_id, actor_id, and session_id" do
      assert {:cont, socket} =
               on_mount(
                 :default,
                 %{"tenant" => "ignored-tenant"},
                 %{
                   "tenant_id" => "tenant-a",
                   "actor_id" => "actor-a",
                   "session_id" => "session-a"
                 },
                 socket()
               )

      assert_scope(socket.assigns.scoria_scope, %{
        tenant_id: "tenant-a",
        actor_id: "actor-a",
        session_id: "session-a"
      })

      assert socket.assigns.tenant_id == "tenant-a"
      assert socket.assigns.actor_id == "actor-a"
      assert socket.assigns.session_id == "session-a"
    end

    test "absent or blank tenant does not continue and uses generic unavailable copy" do
      assert {:halt, missing_socket} = on_mount(:default, %{}, %{}, socket())
      assert missing_socket.assigns.flash["error"] == @unavailable_copy

      assert {:halt, blank_socket} =
               on_mount(:default, %{}, %{"tenant_id" => "   "}, socket())

      assert blank_socket.assigns.flash["error"] == @unavailable_copy
    end

    test "unauthorized and missing resolver outcomes halt before data access" do
      assert {:halt, unauthorized_socket} = on_mount(UnauthorizedResolver, %{}, %{}, socket())
      assert unauthorized_socket.assigns.flash["error"] == @unavailable_copy

      assert {:halt, missing_socket} = on_mount(MissingScopeResolver, %{}, %{}, socket())
      assert missing_socket.assigns.flash["error"] == @unavailable_copy
    end

    test "redirect and halt resolver outcomes stay host-controlled" do
      assert {:halt, redirect_socket} = on_mount(RedirectResolver, %{}, %{}, socket())
      assert {:redirect, %{to: "/login", status: 302}} = redirect_socket.redirected

      assert {:halt, halt_socket} = on_mount(HaltResolver, %{}, %{}, socket())
      assert halt_socket.assigns.host_halt == true
      refute halt_socket.assigns.flash["error"]
    end

    test "malformed resolver returns raise an explicit invalid return error" do
      assert_raise invalid_return_error(), ~r/invalid dashboard scope resolver return/, fn ->
        on_mount(MalformedResolver, %{}, %{}, socket())
      end
    end
  end

  defp new!(attrs), do: apply(scope_module(), :new!, [attrs])
  defp from_session(session), do: apply(scope_module(), :from_session, [session])

  defp on_mount(resolver, params, session, socket),
    do: apply(scope_module(), :on_mount, [resolver, params, session, socket])

  defp resolve(resolver, params, session) do
    apply(scope_module(), :resolve, [resolver, params, session, socket()])
  end

  defp assert_scope(scope, expected) do
    assert scope.__struct__ == scope_module()

    Enum.each(expected, fn {key, value} ->
      assert Map.fetch!(scope, key) == value
    end)
  end

  defp socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, flash: %{}}, assigns),
      view: ScoriaWeb.OrchestratorLive
    }
  end

  defp invalid_return_error, do: ScoriaWeb.DashboardScope.InvalidReturnError
  defp scope_module, do: ScoriaWeb.DashboardScope
end

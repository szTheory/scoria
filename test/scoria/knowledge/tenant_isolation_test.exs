defmodule Scoria.Knowledge.TenantIsolationTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge.Scope

  defp tenant_a_scope do
    Scope.new!(tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared)
  end

  defp tenant_b_scope do
    Scope.new!(tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared)
  end

  defp actor_scope(actor_id) do
    Scope.new!(tenant_id: "tenant-a", actor_id: actor_id, scope_kind: :actor_scoped)
  end

  describe "Scoria.Knowledge.Scope" do
    test "normalizes keyword, map, struct, and shorthand inputs" do
      assert %Scope{tenant_id: "tenant-a", actor_id: nil, scope_kind: "tenant_shared"} =
               Scope.new!(tenant_id: "tenant-a")

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.new!(%{
                 "tenant_id" => "tenant-a",
                 "actor_id" => "actor-a",
                 "scope_kind" => "actor_scoped"
               })

      assert %Scope{} = scope = actor_scope("actor-a")
      assert Scope.new!(scope) == scope

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.from_opts!(scope: scope)

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.from_opts!(
                 scope: scope,
                 tenant_id: "tenant-a",
                 actor_id: "actor-a",
                 scope_kind: :actor_scoped
               )
    end

    test "raises on missing, empty, or conflicting tenant scope" do
      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(%{})
      end

      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(tenant_id: nil)
      end

      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(tenant_id: "   ")
      end

      assert_raise ArgumentError, ~r/conflicting tenant_id/, fn ->
        Scope.from_opts!(scope: tenant_a_scope(), tenant_id: tenant_b_scope().tenant_id)
      end
    end

    test "requires actor_id for actor-scoped writes" do
      assert %Scope{scope_kind: "actor_scoped"} = Scope.for_write!(actor_scope("actor-a"))

      assert_raise ArgumentError, ~r/actor_id is required for actor_scoped scope/, fn ->
        Scope.for_write!(tenant_id: "tenant-a", scope_kind: :actor_scoped)
      end
    end

    test "keeps actor-scoped visibility narrowed by tenant and actor" do
      tenant_shared = %{tenant_id: "tenant-a", actor_id: nil, scope_kind: "tenant_shared"}
      actor_a = %{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"}
      actor_b = %{tenant_id: "tenant-a", actor_id: "actor-b", scope_kind: "actor_scoped"}
      other_tenant = %{tenant_id: "tenant-b", actor_id: nil, scope_kind: "tenant_shared"}

      assert Scope.visible_to(tenant_shared, Scope.new!(tenant_id: "tenant-a"))
      refute Scope.visible_to(actor_a, Scope.new!(tenant_id: "tenant-a"))
      assert Scope.visible_to(actor_a, actor_scope("actor-a"))
      refute Scope.visible_to(actor_b, actor_scope("actor-a"))
      refute Scope.visible_to(other_tenant, actor_scope("actor-a"))
    end
  end
end

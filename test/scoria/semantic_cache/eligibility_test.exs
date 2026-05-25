defmodule Scoria.SemanticCache.EligibilityTest do
  use ExUnit.Case, async: true

  alias Scoria.SemanticCache.Eligibility

  test "returns approval and lane bypass reason codes explicitly" do
    assert {:bypass, :lane_not_registered} =
             Eligibility.evaluate(%{
               tenant_id: "tenant-a",
               prompt_policy: %{approval_required: false}
             })

    assert {:bypass, :approval_required} =
             Eligibility.evaluate(%{
               tenant_id: "tenant-a",
               semantic_cache: %{lane_key: "account_faq", default_scope: :tenant_shared},
               prompt_policy: %{approval_required: true}
             })
  end

  test "returns tenant scope missing and personalized tool bypasses explicitly" do
    assert {:bypass, :tenant_scope_missing} =
             Eligibility.evaluate(%{
               semantic_cache: %{lane_key: "account_faq", default_scope: :tenant_shared}
             })

    assert {:bypass, :personalized_tool} =
             Eligibility.evaluate(%{
               tenant_id: "tenant-a",
               semantic_cache: %{lane_key: "account_faq", default_scope: :tenant_shared},
               personalized_tool: true
             })
  end

  test "defaults scope to tenant_shared and narrows to actor_scoped with explicit reasons" do
    assert {:eligible, attrs} =
             Eligibility.evaluate(%{
               tenant_id: "tenant-a",
               actor_id: "actor-a",
               semantic_cache: %{
                 lane_key: "account_faq",
                 lane_module: "MyApp.AccountFaqLane",
                 default_scope: :tenant_shared,
                 safe_read_only: true
               },
               policy_key: "policy-1",
               provider: "openai",
               model: "gpt-5-mini"
             })

    assert attrs.scope_kind == :tenant_shared
    assert attrs.scope_reason == "lane_default"
    assert attrs.lane_key == "account_faq"

    assert {:eligible_actor_scoped, actor_attrs} =
             Eligibility.evaluate(%{
               tenant_id: "tenant-a",
               actor_id: "actor-a",
               semantic_cache: %{
                 lane_key: "account_faq",
                 lane_module: "MyApp.AccountFaqLane",
                 default_scope: :tenant_shared,
                 safe_read_only: true
               },
               actor_scope_required: true
             })

    assert actor_attrs.scope_kind == :actor_scoped
    assert actor_attrs.scope_reason == "actor_scope_required"
    assert actor_attrs.actor_id == "actor-a"
  end
end

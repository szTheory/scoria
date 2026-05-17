defmodule Scoria.PromptPolicyTest do
  use ExUnit.Case, async: true

  alias Scoria.PromptPolicy

  test "normalizes edge sugar into one canonical public struct" do
    assert PromptPolicy.normalize(:ops_review) == %PromptPolicy{
             policy_key: "ops_review",
             prompt_ref: nil,
             prompt_version: nil,
             tools_allowed: true,
             grounding_required: false,
             approval_required: false,
             metadata: %{}
           }

    policy =
      PromptPolicy.normalize(%{
        "policy_key" => "tenant-default",
        "prompt_ref" => "support/respond",
        "version" => "2026-05-14",
        "constraints" => %{
          "tools_allowed" => false,
          "grounding_required" => true,
          "approval_required" => true
        },
        metadata: %{"source" => "config"}
      })

    assert policy.policy_key == "tenant-default"
    assert policy.prompt_ref == "support/respond"
    assert policy.prompt_version == "2026-05-14"
    refute policy.tools_allowed
    assert policy.grounding_required
    assert policy.approval_required
    assert policy.metadata == %{"source" => "config"}
  end

  test "to_map preserves the canonical prompt-policy shape" do
    policy =
      PromptPolicy.new(%{
        policy: "actor-review",
        ref: "prompt://draft",
        prompt_version: "v3",
        tools_allowed: false
      })

    assert PromptPolicy.to_map(policy) == %{
             policy_key: "actor-review",
             prompt_ref: "prompt://draft",
             prompt_version: "v3",
             tools_allowed: false,
             grounding_required: false,
             approval_required: false,
             metadata: %{}
           }
  end
end

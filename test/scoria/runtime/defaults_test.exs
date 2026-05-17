defmodule Scoria.Runtime.DefaultsTest do
  use ExUnit.Case, async: false

  alias Scoria.Identity
  alias Scoria.Runtime.Defaults

  defmodule Resolver do
    def resolve_defaults(identity, _context) do
      {:ok,
       %{
         tenant_defaults: %{
           provider: "anthropic",
           model: "claude-4-sonnet",
           prompt_policy: %{
             policy_key: "tenant-policy",
             prompt_ref: "prompt://tenant",
             approval_required: true,
             grounding_required: true,
             tools_allowed: false
           }
         },
         actor_defaults:
           if(identity.actor_id == "actor-1",
             do: %{
               model: "claude-4-opus",
               prompt_policy: %{policy_key: "actor-policy", prompt_version: "actor-v2"}
             },
             else: %{}
           )
       }}
    end
  end

  setup do
    previous = Application.get_env(:scoria, Scoria.Runtime)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:scoria, Scoria.Runtime)
      else
        Application.put_env(:scoria, Scoria.Runtime, previous)
      end
    end)

    :ok
  end

  test "reads the boring app-facing config surface and normalizes prompt policy" do
    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5",
        prompt_policy: [
          policy_key: "app-default",
          prompt_ref: "prompt://app",
          prompt_version: "v1"
        ]
      ]
    )

    assert {:ok, resolved} = Defaults.resolve(Identity.new(%{}), %{})
    assert resolved.provider == "openai"
    assert resolved.model == "gpt-5"
    assert resolved.prompt_policy.policy_key == "app-default"
    assert resolved.prompt_policy.prompt_ref == "prompt://app"
    assert resolved.prompt_policy.prompt_version == "v1"
  end

  test "composes tenant actor and per-run defaults in the documented precedence order" do
    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [provider: "openai", model: "gpt-5-mini", prompt_policy: "app-default"],
      resolver: Resolver
    )

    assert {:ok, resolved} =
             Defaults.resolve(
               Identity.new(%{actor_id: "actor-1", tenant_id: "tenant-1"}),
               provider: "openai",
               runtime: [model: "gpt-5.1", prompt_policy: [prompt_version: "run-v3"]]
             )

    assert resolved.provider == "openai"
    assert resolved.model == "gpt-5.1"
    assert resolved.prompt_policy.policy_key == "actor-policy"
    assert resolved.prompt_policy.prompt_ref == "prompt://tenant"
    assert resolved.prompt_policy.prompt_version == "run-v3"
    refute resolved.prompt_policy.tools_allowed
    assert resolved.prompt_policy.grounding_required
    assert resolved.prompt_policy.approval_required
  end

  test "rejects per-run overrides that widen governance-sensitive policy boundaries" do
    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [prompt_policy: "app-default"],
      resolver: Resolver
    )

    assert {:error, {:unsafe_runtime_override, :tools_allowed}} =
             Defaults.resolve(
               Identity.new(%{tenant_id: "tenant-1"}),
               runtime: [prompt_policy: [tools_allowed: true]]
             )
  end
end

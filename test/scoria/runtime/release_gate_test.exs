defmodule Scoria.Runtime.ReleaseGateTest do
  use ExUnit.Case

  alias Scoria.Runtime
  alias Scoria.Runtime.ReleaseGate
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  describe "check/1" do
    test "returns {:error, :unapproved_draft} for draft prompts" do
      template = %PromptTemplate{status: "draft"}
      assert {:error, :unapproved_draft} = ReleaseGate.check(template)
    end

    test "returns :ok for active prompts" do
      template = %PromptTemplate{status: "active"}
      assert :ok = ReleaseGate.check(template)
    end

    test "returns :ok if passed nil or unknown" do
      assert :ok = ReleaseGate.check(nil)
    end
  end

  describe "runtime integration" do
    test "Scoria.Runtime invocation fails with :unapproved_draft when attempting to invoke a draft prompt" do
      template = Repo.insert!(%PromptTemplate{
        entity_id: Ecto.UUID.generate(),
        version: 1,
        status: "draft",
        system_message: "sys",
        user_template: "user",
        is_current: true
      })

      identity = %{
        actor_id: "actor-1",
        tenant_id: "tenant-1",
        session_id: "session-1"
      }

      opts = [
        runtime: %{
          prompt_policy: %{
            prompt_ref: template.id
          }
        }
      ]

      assert {:error, :unapproved_draft} = Runtime.start_run(identity, opts)
    end
  end
end

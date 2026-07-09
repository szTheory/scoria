defmodule Scoria.SemanticCache.ProfileTest do
  use ExUnit.Case, async: false

  alias Scoria.Runtime
  alias Scoria.SemanticCache.Profile
  alias Scoria.Workflows

  defmodule AccountFaqProfile do
    use Scoria.SemanticCache.Profile,
      cache_key: "account_faq",
      default_scope: :tenant_shared,
      safe_read_only: true,
      metadata: %{family: "faq"}
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "profile contract exposes stable metadata with stored lane_key naming" do
    assert {:ok, description} = Profile.describe(AccountFaqProfile)
    assert description.lane_key == "account_faq"
    assert description.default_scope == :tenant_shared
    assert description.safe_read_only
    assert description.metadata == %{family: "faq"}
  end

  test "semantic_cache: [profile: ...] projects stable runtime metadata" do
    assert {:ok, summary} =
             Runtime.start_run(
               %{
                 tenant_id: "tenant-profile",
                 actor_id: "actor-profile",
                 session_id: "session-profile"
               },
               semantic_cache: [profile: AccountFaqProfile]
             )

    run = Workflows.get_run!(summary.run_id)

    semantic_cache = run.metadata["runtime"]["semantic_cache"]

    assert semantic_cache["lane"] ==
             "Elixir.Scoria.SemanticCache.ProfileTest.AccountFaqProfile"

    assert semantic_cache["lane_key"] == "account_faq"
    assert semantic_cache["default_scope"] == "tenant_shared"
    assert semantic_cache["safe_read_only"] == true
    assert semantic_cache["metadata"] == %{"family" => "faq"}
    assert semantic_cache["eligibility_status"] == "bypass"
    assert semantic_cache["eligibility_reason_code"] == "query_text_missing"
    assert semantic_cache["lookup_status"] == "bypass"
  end
end

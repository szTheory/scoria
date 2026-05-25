defmodule Scoria.SemanticCache.LaneTest do
  use ExUnit.Case, async: false

  alias Scoria.Runtime
  alias Scoria.SemanticLane
  alias Scoria.Workflows

  defmodule AccountFaqLane do
    use Scoria.SemanticLane,
      lane_key: "account_faq",
      default_scope: :tenant_shared,
      safe_read_only: true,
      metadata: %{family: "faq"}
  end

  defmodule InvalidLane do
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "lane contract exposes stable metadata through the public noun" do
    assert {:ok, description} = SemanticLane.describe(AccountFaqLane)
    assert description.lane_key == "account_faq"
    assert description.default_scope == :tenant_shared
    assert description.safe_read_only
    assert description.metadata == %{family: "faq"}
  end

  test "semantic_cache: [lane: ...] projects stable runtime metadata" do
    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-lane", actor_id: "actor-lane", session_id: "session-lane"},
               semantic_cache: [lane: AccountFaqLane]
             )

    run = Workflows.get_run!(summary.run_id)

    semantic_cache = run.metadata["runtime"]["semantic_cache"]

    assert semantic_cache["lane"] == "Elixir.Scoria.SemanticCache.LaneTest.AccountFaqLane"
    assert semantic_cache["lane_key"] == "account_faq"
    assert semantic_cache["default_scope"] == "tenant_shared"
    assert semantic_cache["safe_read_only"] == true
    assert semantic_cache["metadata"] == %{"family" => "faq"}
    assert semantic_cache["eligibility_status"] == "bypass"
    assert semantic_cache["eligibility_reason_code"] == "query_text_missing"
    assert semantic_cache["lookup_status"] == "bypass"
  end

  test "invalid lane modules fail normalization deterministically" do
    assert {:error, :invalid_semantic_cache_lane} =
             Runtime.start_run(
               %{tenant_id: "tenant-invalid", actor_id: "actor-invalid"},
               semantic_cache: [lane: InvalidLane]
             )
  end
end

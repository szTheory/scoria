defmodule Scoria.SemanticCache.LookupTest do
  use ExUnit.Case, async: false

  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Compatibility
  alias Scoria.SemanticCache.Entry

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "exact query-text hit wins before semantic fallback" do
    exact_embedding = [0.11, 0.22, 0.33]
    semantic_embedding = [0.12, 0.21, 0.31]

    assert {:ok, %{entry: exact_entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "what is scoria?",
               query_embedding: exact_embedding,
               answer_payload: %{"answer" => "exact"}
             }))

    assert {:ok, %{entry: _semantic_entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "explain scoria",
               query_embedding: semantic_embedding,
               answer_payload: %{"answer" => "semantic"}
             }))

    assert {:hit, %Entry{id: entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               actor_id: "actor-a",
               query_text: "what is scoria?",
               query_embedding: semantic_embedding,
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1"
             })

    assert entry_id == exact_entry.id
  end

  test "semantic fallback reuses only compatibility-matching rows" do
    embedding = [0.20, 0.30, 0.40]

    assert {:ok, %{entry: semantic_entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "how does scoria help?",
               query_embedding: embedding,
               answer_payload: %{"answer" => "fallback"}
             }))

    assert {:hit, %Entry{id: entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               actor_id: "actor-a",
               query_text: "what does scoria do?",
               query_embedding: [0.19, 0.29, 0.39],
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1"
             })

    assert entry_id == semantic_entry.id
  end

  test "policy drift returns a reason-coded reject" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "policy question",
               query_embedding: [0.4, 0.4, 0.4]
             }))

    assert {:reject, "policy_mismatch", %Entry{id: rejected_entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               actor_id: "actor-a",
               query_text: "policy question",
               query_embedding: [0.4, 0.4, 0.4],
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("different"),
               source_fingerprint: "source-v1"
             })

    assert rejected_entry_id == entry.id
  end

  test "source drift returns a reason-coded reject" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "source question",
               query_embedding: [0.5, 0.1, 0.2]
             }))

    assert {:reject, "source_fingerprint_mismatch", %Entry{id: rejected_entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               actor_id: "actor-a",
               query_text: "source question",
               query_embedding: [0.5, 0.1, 0.2],
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v2"
             })

    assert rejected_entry_id == entry.id
  end

  test "persisted state truth stays explicit for stale and invalidated rows" do
    assert {:ok, %{entry: stale_entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "stale question",
               query_embedding: [0.1, 0.1, 0.1],
               status: "stale",
               state_reason_code: "freshness_window_elapsed"
             }))

    assert {:ok, %{entry: invalidated_entry}} =
             SemanticCache.admit(base_entry_attrs(%{
               query_text: "invalidated question",
               query_embedding: [0.2, 0.2, 0.2],
               status: "invalidated",
               state_reason_code: "policy_mismatch",
               invalidated_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
             }))

    assert stale_entry.status == "stale"
    assert stale_entry.state_reason_code == "freshness_window_elapsed"
    assert invalidated_entry.status == "invalidated"
    assert invalidated_entry.state_reason_code == "policy_mismatch"
  end

  defp base_entry_attrs(overrides) do
    Map.merge(
      %{
        tenant_id: "tenant-a",
        actor_id: "actor-a",
        lane_key: "account_faq",
        lane_module: "MyApp.Lanes.AccountFaq",
        scope_kind: "actor_scoped",
        scope_reason: "actor_scope_required",
        prompt_ref: "faq",
        prompt_version: "1",
        policy_fingerprint: policy_fingerprint("default"),
        source_fingerprint: "source-v1",
        query_text: "fallback",
        query_embedding: [0.1, 0.2, 0.3],
        answer_payload: %{"answer" => "cached"},
        evidence_refs: %{},
        status: "active"
      },
      overrides
    )
  end

  defp policy_fingerprint(policy_key) do
    Compatibility.policy_fingerprint(%{policy_key: policy_key, metadata: %{"family" => "faq"}})
  end
end

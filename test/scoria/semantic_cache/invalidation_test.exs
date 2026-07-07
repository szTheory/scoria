defmodule Scoria.SemanticCache.InvalidationTest do
  use ExUnit.Case, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo
  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Compatibility
  alias Scoria.SemanticCache.Entry
  alias Scoria.TestSupport.Migrations

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Scoria.Repo, fn ->
      Migrations.ensure_knowledge_migrated!()
    end)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "invalidate_by_prompt/1 marks matching entries invalidated and appends events" do
    assert {:ok, %{entry: target}} =
             SemanticCache.admit(entry_attrs(%{prompt_ref: "faq", prompt_version: "1"}))

    assert {:ok, _} =
             SemanticCache.invalidate_by_prompt(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               prompt_ref: "faq",
               prompt_version: "2"
             })

    target = Repo.get!(Entry, target.id)
    event = SemanticCache.list_events(target.id) |> List.last()

    assert target.status == "invalidated"
    assert target.state_reason_code == "prompt_version_mismatch"
    assert event.event_kind == "invalidated"
    assert event.reason_code == "prompt_version_mismatch"
  end

  test "invalidate_by_policy/1 stays inside the tenant and lane slice" do
    policy_fingerprint = policy_fingerprint("default")

    assert {:ok, %{entry: target}} =
             SemanticCache.admit(entry_attrs(%{policy_fingerprint: policy_fingerprint}))

    assert {:ok, %{entry: other_lane}} =
             SemanticCache.admit(
               entry_attrs(%{lane_key: "other_lane", policy_fingerprint: policy_fingerprint})
             )

    assert {:ok, _} =
             SemanticCache.invalidate_by_policy(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               policy_fingerprint: policy_fingerprint
             })

    assert Repo.get!(Entry, target.id).status == "invalidated"
    assert Repo.get!(Entry, other_lane.id).status == "active"
  end

  test "invalidate_by_source/1 matches the retrieval-run-derived source fingerprint" do
    source_fingerprint = seeded_source_fingerprint()

    assert {:ok, %{entry: target}} =
             SemanticCache.admit(entry_attrs(%{source_fingerprint: source_fingerprint}))

    assert {:ok, %{entry: other}} =
             SemanticCache.admit(entry_attrs(%{source_fingerprint: "other-source"}))

    assert {:ok, _} =
             SemanticCache.invalidate_by_source(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               source_fingerprint: source_fingerprint
             })

    assert Repo.get!(Entry, target.id).state_reason_code == "source_fingerprint_mismatch"
    assert Repo.get!(Entry, other.id).status == "active"
  end

  test "revoke_entry/2 and mark_stale/3 preserve distinct state truth" do
    assert {:ok, %{entry: stale_entry}} =
             SemanticCache.admit(entry_attrs(%{query_text: "stale me"}))

    assert {:ok, %{entry: revoked_entry}} =
             SemanticCache.admit(entry_attrs(%{query_text: "revoke me"}))

    assert {:ok, %Entry{} = stale_entry} =
             SemanticCache.mark_stale(stale_entry, "freshness_window_elapsed", %{"phase" => "45"})

    assert {:ok, %Entry{} = revoked_entry} =
             SemanticCache.revoke_entry(revoked_entry, %{"phase" => "45"})

    assert stale_entry.status == "stale"
    assert stale_entry.state_reason_code == "freshness_window_elapsed"
    assert is_nil(stale_entry.invalidated_at)

    assert revoked_entry.status == "invalidated"
    assert revoked_entry.state_reason_code == "operator_revoked"
    assert not is_nil(revoked_entry.invalidated_at)
  end

  defp entry_attrs(overrides) do
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
        query_text: "cached answer",
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

  defp seeded_source_fingerprint do
    scope = [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]

    {:ok, source} =
      Knowledge.create_source(%{kind: "doc", digest: "digest-1", metadata: %{}, title: "FAQ"},
        scope: scope
      )

    {:ok, chunk} =
      %Chunk{}
      |> Chunk.changeset(%{
        source_id: source.id,
        tenant_id: source.tenant_id,
        actor_id: source.actor_id,
        scope_kind: source.scope_kind,
        chunk_digest: "chunk-1",
        body: "Scoria answer",
        start_offset: 0,
        end_offset: 12,
        token_count: 2,
        embedding: [0.1, 0.2, 0.3]
      })
      |> Repo.insert()

    {:ok, retrieval_run} =
      Knowledge.create_retrieval_run(%{
        query_text: "what is scoria?",
        backend: "test",
        tenant_id: source.tenant_id,
        actor_id: source.actor_id
      })

    {:ok, _results} =
      Knowledge.append_retrieval_results(retrieval_run.id, [
        %{
          chunk_id: chunk.id,
          source_id: source.id,
          rank: 1,
          score: 0.95,
          tenant_id: source.tenant_id,
          actor_id: source.actor_id
        }
      ])

    Compatibility.source_fingerprint_for_retrieval_run(retrieval_run.id)
  end
end

defmodule Scoria.SemanticCacheTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Entry
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "admit/1 persists both entry and admitted event rows" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "semantic-cache", tenant_id: "tenant-a"})

    assert {:ok, %{entry: %Entry{} = entry, event: event}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               lane_module: "MyApp.Lanes.AccountFaq",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               policy_key: "policy-1",
               prompt_ref: "faq",
               prompt_version: "1",
               provider: "openai",
               model: "gpt-5-mini",
               query_text: "what is scoria?",
               answer_payload: %{"answer" => "phoenix ai runtime"},
               evidence_refs: %{"sources" => ["faq"]},
               origin_run_id: run.id
             })

    persisted_entry = Repo.get!(Entry, entry.id)
    [persisted_event] = SemanticCache.list_events(entry.id)

    assert persisted_entry.tenant_id == "tenant-a"
    assert persisted_entry.origin_run_id == run.id
    assert persisted_event.id == event.id
    assert persisted_event.event_kind == "admitted"
    assert persisted_event.workflow_run_id == run.id
  end

  test "lookup/1 is tenant-filtered and only narrows by actor_id when scope_kind == actor_scoped" do
    assert {:ok, %{entry: shared_entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               query_text: "same question",
               answer_payload: %{"answer" => "tenant shared"}
             })

    assert {:ok, %{entry: actor_entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-a",
               actor_id: "actor-1",
               lane_key: "account_faq",
               scope_kind: "actor_scoped",
               scope_reason: "personalized_tool",
               query_text: "same question",
               answer_payload: %{"answer" => "actor scoped"}
             })

    assert {:ok, %{entry: _other_tenant}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-b",
               lane_key: "account_faq",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               query_text: "same question",
               answer_payload: %{"answer" => "other tenant"}
             })

    assert {:hit, %Entry{id: shared_entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               query_text: "same question"
             })

    assert shared_entry_id == shared_entry.id

    assert {:hit, %Entry{id: actor_entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               actor_id: "actor-1",
               lane_key: "account_faq",
               query_text: "same question"
             })

    assert actor_entry_id == actor_entry.id

    assert :miss =
             SemanticCache.lookup(%{
               tenant_id: "tenant-c",
               lane_key: "account_faq",
               query_text: "same question"
             })
  end

  test "rejected or missing candidates return bypass or miss without inserting extra rows" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               query_text: "reusable question",
               answer_payload: %{"answer" => "reusable"}
             })

    before_count = Repo.aggregate(Entry, :count, :id)

    assert {:bypass, :tenant_scope_missing} =
             SemanticCache.lookup(%{
               lane_key: "account_faq",
               query_text: "reusable question"
             })

    assert {:bypass, :lane_not_registered} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               query_text: "reusable question"
             })

    assert {:bypass, :query_text_missing} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq"
             })

    assert :miss =
             SemanticCache.lookup(%{
               tenant_id: "tenant-a",
               lane_key: "account_faq",
               query_text: "missing question"
             })

    assert {:ok, %{entry: reused_entry, event: reused_event}} =
             SemanticCache.record_reuse(entry, %{reason_code: "tenant_cache_hit"})

    assert reused_entry.hit_count == 1
    assert reused_event.event_kind == "reused"

    assert Repo.aggregate(Entry, :count, :id) == before_count
  end
end

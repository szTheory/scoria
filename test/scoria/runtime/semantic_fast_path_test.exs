defmodule Scoria.Runtime.SemanticFastPathTest do
  use Scoria.IntegrationCase

  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.SemanticCache.Compatibility
  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Entry
  alias Scoria.TestSupport.Migrations
  alias Scoria.Workflows

  defmodule AccountFaqLane do
    use Scoria.SemanticLane, lane_key: "account_faq", default_scope: :tenant_shared, safe_read_only: true
  end

  defmodule ActorLane do
    use Scoria.SemanticLane, lane_key: "actor_help", default_scope: :actor_scoped, safe_read_only: true
  end

  defmodule SourceAwareLane do
    use Scoria.SemanticLane,
      lane_key: "account_faq",
      default_scope: :tenant_shared,
      safe_read_only: true,
      metadata: %{"source_fingerprint" => "source-v2"}
  end

  defmodule Handlers do
    def answer(_step, _run),
      do: {:ok, %{"output" => %{"answer" => "fresh answer"}, "evidence_refs" => %{"docs" => ["faq"]}}}

    def reject_writeback(_step, _run) do
      {:ok,
       %{
         "output" => %{"answer" => "unsafe answer"},
         "semantic_cache" => %{"writeback_rejected" => "approval_required"},
         "evidence_refs" => %{}
       }}
    end
  end

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Scoria.Repo, fn ->
      Migrations.ensure_knowledge_migrated!()
    end)

    Application.put_env(:scoria, :workflow_runtime_handlers, %{"answer" => {Handlers, :answer}})

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

  test "runs without semantic_cache do not call the semantic fast path" do
    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-none", actor_id: "actor-none", session_id: "session-none"},
               root_role_id: "executor",
               input: "what is scoria?",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run_tree!(summary.run_id)

    assert run.metadata["runtime"]["semantic_cache"] == nil
    assert Repo.aggregate(Entry, :count, :id) == 0
  end

  test "eligible tenant-safe lanes reuse only tenant-matching entries" do
    assert {:ok, %{entry: tenant_entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-hit",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.Runtime.SemanticFastPathTest.AccountFaqLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               policy_key: "default",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1",
               provider: "openai",
               model: "gpt-5-mini",
               query_text: "what is scoria?",
               query_embedding: [0.57, 0.54, 0.52],
               answer_payload: %{"answer" => "cached answer"}
             })

    assert {:ok, _other_tenant_entry} =
             SemanticCache.admit(%{
               tenant_id: "tenant-other",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.Runtime.SemanticFastPathTest.AccountFaqLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               policy_key: "default",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1",
               provider: "openai",
               model: "gpt-5-mini",
               query_text: "what is scoria?",
               query_embedding: [0.57, 0.54, 0.52],
               answer_payload: %{"answer" => "wrong tenant"}
             })

    assert {:hit, %Entry{id: lookup_entry_id}} =
             SemanticCache.lookup(%{
               tenant_id: "tenant-hit",
               lane_key: "account_faq",
               policy_key: "default",
               provider: "openai",
               model: "gpt-5-mini",
               query_text: "what is scoria?"
             })

    assert lookup_entry_id == tenant_entry.id

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-hit", actor_id: "actor-hit", session_id: "session-hit"},
               semantic_cache: [lane: AccountFaqLane],
               input: "what is scoria?"
             )

    run = Workflows.get_run_tree!(summary.run_id)
    [step] = run.steps
    detail = Runtime.get_run_detail!(summary.run_id)

    assert run.status == "completed"
    assert step.result_envelope["semantic_cache"]["status"] == "hit"
    assert step.result_envelope["semantic_cache"]["entry_id"] == tenant_entry.id
    assert step.result_envelope["output"] == %{"answer" => "cached answer"}
    assert detail.semantic_evidence.summary.lookup_status == "hit"
    assert detail.semantic_evidence.summary.fallback_executed == false
    assert detail.semantic_evidence.provenance.entry_id == tenant_entry.id
    assert detail.semantic_evidence.provenance.origin_run_id == tenant_entry.origin_run_id
    assert detail.semantic_evidence.lifecycle.status == "active"
    assert Enum.any?(detail.semantic_evidence.events, &(&1.event_kind == "reused"))
  end

  test "approval-sensitive flows bypass and still create the normal workflow run" do
    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [
        prompt_policy: [policy_key: "approval-lane", approval_required: true]
      ]
    )

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-bypass", actor_id: "actor-bypass", session_id: "session-bypass"},
               semantic_cache: [lane: AccountFaqLane],
               input: "approval question",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run!(summary.run_id)
    detail = Runtime.get_run_detail!(summary.run_id)

    assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "bypass"
    assert run.metadata["runtime"]["semantic_cache"]["eligibility_reason_code"] == "approval_required"
    assert Repo.aggregate(Entry, :count, :id) == 0
    assert detail.semantic_evidence.summary.lookup_status == "bypass"
    assert detail.semantic_evidence.summary.eligibility_reason_code == "approval_required"
    assert detail.semantic_evidence.summary.fallback_executed
    assert detail.semantic_evidence.summary.fallback_outcome == "normal_runtime_path_executed"
  end

  test "eligible misses fall through, then safe completions admit entries with lineage" do
    retrieval_run_id = create_retrieval_run!("fresh question")

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-miss", actor_id: "actor-miss", session_id: "session-miss"},
               semantic_cache: [lane: ActorLane],
               input: "fresh question",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{
                 "answer" => fn _step, _run ->
                   {:ok,
                    %{
                      "output" => %{"answer" => "fresh answer"},
                      "evidence_refs" => %{"docs" => ["faq"]},
                      "retrieval_run_id" => retrieval_run_id
                    }}
                 end
               }
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    detail = Runtime.get_run_detail!(summary.run_id)

    [entry] =
      Entry
      |> Repo.all()
      |> Enum.filter(&(&1.tenant_id == "tenant-miss"))

    assert entry.scope_kind == "actor_scoped"
    assert entry.actor_id == "actor-miss"
    assert entry.origin_run_id == summary.run_id
    assert entry.answer_payload["answer"] == "fresh answer"
    assert entry.policy_fingerprint == policy_fingerprint("default")
    assert entry.source_fingerprint == Compatibility.source_fingerprint_for_retrieval_run(retrieval_run_id)
    assert Enum.zip(Pgvector.to_list(entry.query_embedding), Scoria.Knowledge.Embedder.Deterministic.embed_query("fresh question"))
           |> Enum.all?(fn {left, right} -> abs(left - right) < 1.0e-6 end)
    assert not is_nil(entry.expires_at)
    assert detail.semantic_evidence.summary.lookup_status == "miss"
    assert detail.semantic_evidence.summary.fallback_executed
    assert detail.semantic_evidence.summary.fallback_outcome == "live_execution_admitted"
    assert detail.semantic_evidence.provenance.entry_id == entry.id
    assert detail.semantic_evidence.provenance.origin_retrieval_run_id == retrieval_run_id
    assert detail.semantic_evidence.lifecycle.status == "active"
    assert Enum.any?(detail.semantic_evidence.events, &(&1.event_kind == "admitted"))
  end

  test "eligible misses can record writeback_rejected lifecycle lineage" do
    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-reject", actor_id: "actor-reject", session_id: "session-reject"},
               semantic_cache: [lane: AccountFaqLane],
               input: "unsafe question",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :reject_writeback}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)

    entry =
      Entry
      |> Repo.all()
      |> Enum.find(&(&1.tenant_id == "tenant-reject"))

    assert entry.status == "writeback_rejected"
    assert entry.state_reason_code == "approval_required"

    [event | _] = SemanticCache.list_events(entry.id)
    assert event.event_kind == "writeback_rejected"
    assert event.reason_code == "approval_required"
  end

  test "query-text-missing bypass still creates a normal run" do
    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-empty", actor_id: "actor-empty", session_id: "session-empty"},
               semantic_cache: [lane: AccountFaqLane],
               input: "",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run!(summary.run_id)

    assert run.metadata["runtime"]["semantic_cache"]["eligibility_reason_code"] == "query_text_missing"
    assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "bypass"
  end

  test "lookup rejects on prompt mismatch, invalidates the candidate, and falls through to live execution" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-reject",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.Runtime.SemanticFastPathTest.AccountFaqLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               prompt_ref: "faq",
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1",
               query_text: "what is scoria?",
               query_embedding: [0.1, 0.2, 0.3],
               answer_payload: %{"answer" => "stale prompt"}
             })

    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [prompt_policy: [policy_key: "default", prompt_version: "2"]]
    )

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-reject", actor_id: "actor-reject", session_id: "session-reject"},
               semantic_cache: [lane: AccountFaqLane],
               input: "what is scoria?",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run_tree!(summary.run_id)
    [step] = run.steps
    reloaded_entry = Repo.get!(Entry, entry.id)
    detail = Runtime.get_run_detail!(summary.run_id)

    assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "reject"
    assert run.metadata["runtime"]["semantic_cache"]["lookup_reason_code"] == "prompt_version_mismatch"
    assert run.metadata["runtime"]["semantic_cache"]["candidate_status"] == "invalidated"
    assert step.result_envelope["output"]["answer"] == "fresh answer"
    assert reloaded_entry.status == "invalidated"
    assert reloaded_entry.state_reason_code == "prompt_version_mismatch"
    assert detail.semantic_evidence.summary.lookup_status == "reject"
    assert detail.semantic_evidence.summary.lookup_reason_code == "prompt_version_mismatch"
    assert detail.semantic_evidence.summary.candidate_status == "invalidated"
    assert detail.semantic_evidence.summary.fallback_outcome == "normal_runtime_path_executed"
    assert detail.semantic_evidence.candidate.candidate_entry_id == entry.id
    assert detail.semantic_evidence.lifecycle.status == "invalidated"
  end

  test "lookup rejects on source mismatch and still completes the live workflow path" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-source",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.Runtime.SemanticFastPathTest.SourceAwareLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               prompt_ref: "faq",
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1",
               query_text: "what is scoria?",
               query_embedding: [0.1, 0.2, 0.3],
               answer_payload: %{"answer" => "old source"}
             })

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-source", actor_id: "actor-source", session_id: "session-source"},
               semantic_cache: [lane: SourceAwareLane],
               input: "what is scoria?",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run_tree!(summary.run_id)
    [step] = run.steps
    reloaded_entry = Repo.get!(Entry, entry.id)

    assert run.metadata["runtime"]["semantic_cache"]["lookup_reason_code"] == "source_fingerprint_mismatch"
    assert run.metadata["runtime"]["semantic_cache"]["candidate_status"] == "invalidated"
    assert step.result_envelope["output"]["answer"] == "fresh answer"
    assert reloaded_entry.status == "invalidated"
  end

  test "stale candidates are marked stale and the runtime falls through cleanly" do
    assert {:ok, %{entry: entry}} =
             SemanticCache.admit(%{
               tenant_id: "tenant-stale",
               lane_key: "account_faq",
               lane_module: "Elixir.Scoria.Runtime.SemanticFastPathTest.AccountFaqLane",
               scope_kind: "tenant_shared",
               scope_reason: "lane_default",
               prompt_ref: "faq",
               prompt_version: "1",
               policy_fingerprint: policy_fingerprint("default"),
               source_fingerprint: "source-v1",
               query_text: "what is scoria?",
               query_embedding: [0.1, 0.2, 0.3],
               answer_payload: %{"answer" => "expired answer"},
               expires_at: DateTime.add(DateTime.utc_now() |> DateTime.truncate(:microsecond), -60, :second)
             })

    assert {:ok, summary} =
             Runtime.start_run(
               %{tenant_id: "tenant-stale", actor_id: "actor-stale", session_id: "session-stale"},
               semantic_cache: [lane: AccountFaqLane],
               input: "what is scoria?",
               root_role_id: "executor",
               initial_step: %{sequence: 1, kind: "answer", role_id: "executor", status: "queued"},
               handlers: %{"answer" => {Handlers, :answer}}
             )

    eventually(fn -> Workflows.get_run!(summary.run_id).status == "completed" end)
    run = Workflows.get_run_tree!(summary.run_id)
    [step] = run.steps
    reloaded_entry = Repo.get!(Entry, entry.id)

    assert run.metadata["runtime"]["semantic_cache"]["lookup_reason_code"] == "entry_stale"
    assert run.metadata["runtime"]["semantic_cache"]["candidate_status"] == "stale"
    assert step.result_envelope["output"]["answer"] == "fresh answer"
    assert reloaded_entry.status == "stale"
    assert reloaded_entry.state_reason_code == "freshness_window_elapsed"
  end

  defp create_retrieval_run!(query_text) do
    alias Scoria.Knowledge
    alias Scoria.Knowledge.Chunk

    {:ok, source} =
      Knowledge.create_source(%{kind: "doc", digest: "digest-#{query_text}", metadata: %{}, title: "FAQ"})

    {:ok, chunk} =
      %Chunk{}
      |> Chunk.changeset(%{
        source_id: source.id,
        chunk_digest: "chunk-#{query_text}",
        body: query_text,
        start_offset: 0,
        end_offset: String.length(query_text),
        token_count: 3,
        embedding: [0.1, 0.2, 0.3]
      })
      |> Repo.insert()

    {:ok, run} = Knowledge.create_retrieval_run(%{query_text: query_text, backend: "test"})

    {:ok, _results} =
      Knowledge.append_retrieval_results(run.id, [%{chunk_id: chunk.id, source_id: source.id, rank: 1, score: 0.95}])

    run.id
  end

  defp policy_fingerprint(policy_key) do
    Compatibility.policy_fingerprint(%{policy_key: policy_key})
  end
end

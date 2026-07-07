defmodule Scoria.Knowledge.TenantIsolationTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge.Scope
  alias Scoria.TestSupport.Migrations

  @tenant_scope_migration 20_260_705_010_000
  @tenant_scope_columns %{
    "ai_knowledge_sources" => ~w(tenant_id actor_id scope_kind),
    "ai_knowledge_chunks" => ~w(tenant_id actor_id scope_kind),
    "ai_retrieval_runs" => ~w(tenant_id actor_id),
    "ai_retrieval_results" => ~w(tenant_id actor_id),
    "ai_knowledge_citations" => ~w(tenant_id actor_id scope_kind)
  }
  @tenant_scope_indexes ~w(
    ai_knowledge_sources_tenant_id_index
    ai_knowledge_sources_tenant_entity_version_index
    ai_knowledge_chunks_tenant_id_index
    ai_knowledge_chunks_tenant_source_id_index
    ai_retrieval_runs_tenant_status_inserted_at_index
    ai_retrieval_results_tenant_run_rank_index
    ai_knowledge_citations_tenant_source_id_index
    ai_knowledge_citations_tenant_chunk_id_index
  )

  defp tenant_a_scope do
    Scope.new!(tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared)
  end

  defp tenant_b_scope do
    Scope.new!(tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared)
  end

  defp actor_scope(actor_id) do
    Scope.new!(tenant_id: "tenant-a", actor_id: actor_id, scope_kind: :actor_scoped)
  end

  describe "Scoria.Knowledge.Scope" do
    test "normalizes keyword, map, struct, and shorthand inputs" do
      assert %Scope{tenant_id: "tenant-a", actor_id: nil, scope_kind: "tenant_shared"} =
               Scope.new!(tenant_id: "tenant-a")

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.new!(%{
                 "tenant_id" => "tenant-a",
                 "actor_id" => "actor-a",
                 "scope_kind" => "actor_scoped"
               })

      assert %Scope{} = scope = actor_scope("actor-a")
      assert Scope.new!(scope) == scope

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.from_opts!(scope: scope)

      assert %Scope{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"} =
               Scope.from_opts!(
                 scope: scope,
                 tenant_id: "tenant-a",
                 actor_id: "actor-a",
                 scope_kind: :actor_scoped
               )
    end

    test "raises on missing, empty, or conflicting tenant scope" do
      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(%{})
      end

      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(tenant_id: nil)
      end

      assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
        Scope.new!(tenant_id: "   ")
      end

      assert_raise ArgumentError, ~r/conflicting tenant_id/, fn ->
        Scope.from_opts!(scope: tenant_a_scope(), tenant_id: tenant_b_scope().tenant_id)
      end
    end

    test "requires actor_id for actor-scoped writes" do
      assert %Scope{scope_kind: "actor_scoped"} = Scope.for_write!(actor_scope("actor-a"))

      assert_raise ArgumentError, ~r/actor_id is required for actor_scoped scope/, fn ->
        Scope.for_write!(tenant_id: "tenant-a", scope_kind: :actor_scoped)
      end
    end

    test "keeps actor-scoped visibility narrowed by tenant and actor" do
      tenant_shared = %{tenant_id: "tenant-a", actor_id: nil, scope_kind: "tenant_shared"}
      actor_a = %{tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: "actor_scoped"}
      actor_b = %{tenant_id: "tenant-a", actor_id: "actor-b", scope_kind: "actor_scoped"}
      other_tenant = %{tenant_id: "tenant-b", actor_id: nil, scope_kind: "tenant_shared"}

      assert Scope.visible_to(tenant_shared, Scope.new!(tenant_id: "tenant-a"))
      refute Scope.visible_to(actor_a, Scope.new!(tenant_id: "tenant-a"))
      assert Scope.visible_to(actor_a, actor_scope("actor-a"))
      refute Scope.visible_to(actor_b, actor_scope("actor-a"))
      refute Scope.visible_to(other_tenant, actor_scope("actor-a"))
    end
  end

  describe "knowledge tenant-scope migration" do
    setup do
      Migrations.migrate_knowledge!()
      :ok
    end

    test "adds nullable tenant scope columns through the knowledge migration path" do
      assert migration_recorded?(Migrations.knowledge_migration_source(), @tenant_scope_migration)

      for {table_name, column_names} <- @tenant_scope_columns,
          column_name <- column_names do
        assert column_exists?(table_name, column_name), "#{table_name}.#{column_name} is missing"

        refute column_required?(table_name, column_name),
               "#{table_name}.#{column_name} must stay nullable"
      end
    end

    test "creates tenant indexes for knowledge storage and audit rows" do
      for index_name <- @tenant_scope_indexes do
        assert index_exists?(index_name), "#{index_name} is missing"
      end

      refute File.exists?("priv/repo/migrations/20260705010000_add_knowledge_tenant_scope.exs")

      assert File.exists?(
               "priv/repo/knowledge_migrations/20260705010000_add_knowledge_tenant_scope.exs"
             )
    end
  end

  defp column_exists?(table_name, column_name) do
    %{rows: [[exists?]]} =
      Repo.query!(
        """
        select exists (
          select 1
          from information_schema.columns
          where table_schema = current_schema()
            and table_name = $1
            and column_name = $2
        )
        """,
        [table_name, column_name]
      )

    exists?
  end

  defp column_required?(table_name, column_name) do
    %{rows: [[nullable]]} =
      Repo.query!(
        """
        select is_nullable
        from information_schema.columns
        where table_schema = current_schema()
          and table_name = $1
          and column_name = $2
        """,
        [table_name, column_name]
      )

    nullable == "NO"
  end

  defp index_exists?(index_name) do
    %{rows: [[exists?]]} =
      Repo.query!(
        """
        select exists (
          select 1
          from pg_indexes
          where schemaname = current_schema()
            and indexname = $1
        )
        """,
        [index_name]
      )

    exists?
  end

  defp migration_recorded?(table_name, version) do
    %{rows: [[exists?]]} =
      Repo.query!(
        "select exists (select 1 from #{table_name} where version = $1)",
        [version]
      )

    exists?
  end
end

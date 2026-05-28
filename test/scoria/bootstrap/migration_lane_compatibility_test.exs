defmodule Scoria.Bootstrap.MigrationLaneCompatibilityTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.TestSupport.Migrations

  @knowledge_version 20260511000300
  @knowledge_tables [
    "ai_grounding_scores",
    "ai_knowledge_citations",
    "ai_retrieval_results",
    "ai_retrieval_runs",
    "ai_knowledge_chunks",
    "ai_knowledge_sources",
    Migrations.knowledge_migration_source()
  ]

  test "core lane reaches the default schema without creating knowledge tables" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      reset_knowledge_lane!()
      assert migration_recorded?("schema_migrations", @knowledge_version)

      if knowledge_lane_enabled?() do
        assert table_exists?("ai_knowledge_sources")
        assert table_exists?("ai_knowledge_chunks")
        assert migration_recorded?(Migrations.knowledge_migration_source(), @knowledge_version)
      else
        refute table_exists?("ai_knowledge_sources")
        refute table_exists?("ai_knowledge_chunks")
      end
    end)
  end

  test "knowledge lane is idempotent even when the historical core version is already recorded" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      reset_knowledge_lane!()
      assert migration_recorded?("schema_migrations", @knowledge_version)

      if pgvector_available?() do
        # D-11: explicit double-call proves migrate_knowledge!/0 idempotency (not ensure_knowledge_migrated!/0).
        assert :ok = Migrations.migrate_knowledge!()
        assert table_exists?("ai_knowledge_sources")
        assert table_exists?("ai_knowledge_chunks")
        assert migration_recorded?(Migrations.knowledge_migration_source(), @knowledge_version)

        assert :ok = Migrations.migrate_knowledge!()
        assert migration_recorded?(Migrations.knowledge_migration_source(), @knowledge_version)
      else
        if knowledge_lane_enabled?() do
          assert table_exists?("ai_knowledge_sources")
        else
          refute table_exists?("ai_knowledge_sources")
        end

        assert File.exists?(
                 Path.join(Migrations.knowledge_migrations_path(), "20260511000300_create_knowledge_tables.exs")
               )
      end
    end)
  end

  defp knowledge_lane_enabled? do
    System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true"
  end

  defp reset_knowledge_lane! do
    if knowledge_lane_enabled?() do
      :ok
    else
      Enum.each(@knowledge_tables, fn table_name ->
        Repo.query!("DROP TABLE IF EXISTS #{table_name} CASCADE", [])
      end)
    end
  end

  defp table_exists?(table_name) do
    %{rows: [[exists?]]} =
      Repo.query!(
        "select exists (select 1 from information_schema.tables where table_schema = current_schema() and table_name = $1)",
        [table_name]
      )

    exists?
  end

  defp migration_recorded?(table_name, version) do
    %{rows: rows} =
      Repo.query!(
        "select exists (select 1 from #{table_name} where version = $1)",
        [version]
      )

    rows == [[true]]
  end

  defp pgvector_available? do
    case Repo.query("select extname from pg_available_extensions where extname = 'vector'", []) do
      {:ok, %{rows: [["vector"]]}} -> true
      _ -> false
    end
  end
end

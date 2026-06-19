defmodule Mix.Tasks.Scoria.Dev.Db do
  @shortdoc "Create + migrate (core+knowledge, fresh-DB order) the Scoria dev database"
  @moduledoc """
  Dev-only database setup for the local dashboard harness.

  Plain `mix ecto.migrate` cannot stand up a fresh Scoria database: the core and
  knowledge migration sets are interleaved by foreign-key dependencies and even
  share a version number (`20260511000300`), tracked in separate
  `schema_migrations` tables via the test-support migration helper.

  Required order on a fresh DB:

    1. enable the `vector` extension (the knowledge hnsw index needs it)
    2. core migrations UP TO (excluding) `create_semantic_cache_tables`
       — creates `ai_traces` / `ai_spans` / `ai_workflow_runs`, which the
         knowledge migration's FKs reference
    3. knowledge migrations — creates `ai_retrieval_runs`
    4. the remaining core migration (`create_semantic_cache_tables`), whose FK
       references `ai_retrieval_runs`

  This task lives under `dev/` and is compiled only in `:dev` — it never ships
  to Hex. Used by `mix dev.setup` and the Docker entrypoint.
  """
  use Mix.Task

  alias Scoria.TestSupport.Migrations

  # create_semantic_cache_tables: the only core migration that depends on a
  # knowledge table (ai_retrieval_runs), so knowledge must be migrated first.
  @semantic_cache_version 20_260_525_070_000

  @impl Mix.Task
  def run(_args) do
    repo = Scoria.Repo

    # Running a mix task loads config; ecto.create is idempotent.
    Mix.Task.run("ecto.create")

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, fn r ->
        Ecto.Adapters.SQL.query!(r, "CREATE EXTENSION IF NOT EXISTS vector", [])

        # Step 2: early core (everything before the semantic-cache migration).
        Ecto.Migrator.run(r, [Migrations.core_migrations_path()], :up,
          to_exclusive: @semantic_cache_version
        )
      end)

    # Step 3: knowledge set (separate repo / schema_migrations_knowledge tracker).
    Migrations.migrate_knowledge!()

    # Step 4: remaining core, now that ai_retrieval_runs exists.
    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, fn r ->
        Ecto.Migrator.run(r, [Migrations.core_migrations_path()], :up, all: true)
      end)

    Mix.shell().info("==> Scoria dev DB ready (core + knowledge migrations applied)")
  end
end

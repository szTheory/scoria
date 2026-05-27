defmodule Scoria.TestSupport.Migrations do
  @moduledoc false

  alias Scoria.Repo

  defmodule KnowledgeMigrationRepo do
    use Ecto.Repo,
      otp_app: :scoria,
      adapter: Ecto.Adapters.Postgres

    @impl true
    def init(_type, config) do
      base_config =
        Scoria.Repo.config()
        |> Keyword.drop([:name, :telemetry_prefix, :repo])

      {:ok,
       base_config
       |> Keyword.merge(config)
       |> Keyword.put(:migration_source, "schema_migrations_knowledge")}
    end
  end

  @repo_priv Application.compile_env(:scoria, Repo)[:priv] || "priv/repo"
  @core_migrations Path.join(@repo_priv, "migrations")
  @knowledge_migrations Path.join(@repo_priv, "knowledge_migrations")
  @knowledge_source "schema_migrations_knowledge"
  @knowledge_migrated_key {:scoria_test_support, :knowledge_migrated}

  def migrate_core! do
    migrate!([@core_migrations])
  end

  def ensure_knowledge_migrated! do
    if :persistent_term.get(@knowledge_migrated_key, false) && knowledge_tables_exist?() do
      :ok
    else
      migrate_knowledge!()
      :persistent_term.put(@knowledge_migrated_key, true)
      :ok
    end
  end

  defp knowledge_tables_exist? do
    case Repo.query(
           "select exists (select 1 from information_schema.tables where table_schema = current_schema() and table_name = 'ai_knowledge_sources')"
         ) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end

  def migrate_knowledge! do
    previous = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)

    try do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(KnowledgeMigrationRepo, fn repo ->
          Ecto.Migrator.run(repo, [@knowledge_migrations], :up, all: true, log: false)
        end)

      :ok
    after
      Code.put_compiler_option(:ignore_module_conflict, previous)
    end
  end

  def core_migrations_path, do: @core_migrations
  def knowledge_migrations_path, do: @knowledge_migrations
  def knowledge_migration_source, do: @knowledge_source

  defp migrate!(paths, opts \\ []) do
    {:ok, _, _} =
      Ecto.Migrator.with_repo(Repo, fn repo ->
        Ecto.Migrator.run(repo, paths, :up, Keyword.merge([all: true, log: false], opts))
      end)

    :ok
  end
end

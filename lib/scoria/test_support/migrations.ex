defmodule Scoria.TestSupport.Migrations do
  @moduledoc false

  alias Scoria.Repo

  @repo_priv Application.compile_env(:scoria, Repo)[:priv] || "priv/repo"
  @core_migrations Path.join(@repo_priv, "migrations")
  @knowledge_migrations Path.join(@repo_priv, "knowledge_migrations")
  @knowledge_source "schema_migrations_knowledge"

  def migrate_core! do
    migrate!([@core_migrations])
  end

  def migrate_knowledge! do
    migrate!([@knowledge_migrations], migration_source: @knowledge_source)
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

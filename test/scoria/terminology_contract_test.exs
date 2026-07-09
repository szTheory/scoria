defmodule Scoria.TerminologyContractTest do
  use ExUnit.Case, async: true

  @workflow_tables_migration "priv/repo/migrations/20260511000100_create_workflow_tables.exs"
  @semantic_cache_migration "priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs"
  @semantic_cache_entry "lib/scoria/semantic_cache/entry.ex"
  @knowledge_tables_migration "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs"
  @eval_score_migration "priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs"

  test "storage terminology keeps evidence refs, projected context, and lane key fields" do
    assert active_source(@workflow_tables_migration) =~ ~r/add\s+:projected_context\b/

    assert active_source(@semantic_cache_migration) =~ ~r/add\s+:lane_key\b/
    assert active_source(@semantic_cache_entry) =~ ~r/field\s+:lane_key\b/

    assert active_source(@semantic_cache_migration) =~ ~r/add\s+:evidence_refs\b/
    assert active_source(@semantic_cache_entry) =~ ~r/field\s+:evidence_refs\b/
    assert active_source(@knowledge_tables_migration) =~ ~r/add\s+:evidence_refs\b/
    assert active_source(@eval_score_migration) =~ ~r/evidence_refs\b/
  end

  test "storage, schema, and migration sources do not introduce trace refs" do
    refute_storage_identifier!("trace_refs")
  end

  test "final public context and semantic-cache terms are not introduced as storage fields" do
    refute_storage_field!("scoped_context")
    refute_storage_field!("cache_key")
  end

  test "active source scanning ignores comment-only lines" do
    assert active_source_text("""
           # add :trace_refs, :map
           # field :cache_key, :string
           add :evidence_refs, :map
           """) == "add :evidence_refs, :map"
  end

  defp refute_storage_identifier!(identifier) do
    offenders =
      storage_source_paths()
      |> Enum.filter(fn path -> active_source(path) =~ ~r/\b#{Regex.escape(identifier)}\b/ end)

    assert offenders == [],
           "expected no active storage/schema/migration source to contain #{identifier}, found: #{inspect(offenders)}"
  end

  defp refute_storage_field!(identifier) do
    field_pattern =
      ~r/\b(?:add|add_if_not_exists|field|remove|remove_if_exists)\s*\(?\s*:#{Regex.escape(identifier)}\b/

    offenders =
      storage_source_paths()
      |> Enum.filter(fn path -> active_source(path) =~ field_pattern end)

    assert offenders == [],
           "expected no storage/schema/migration field named #{identifier}, found: #{inspect(offenders)}"
  end

  defp storage_source_paths do
    migration_paths =
      ["priv/repo/migrations", "priv/repo/knowledge_migrations"]
      |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*.exs")))

    schema_paths =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.filter(&ecto_schema?/1)

    Enum.sort(migration_paths ++ schema_paths)
  end

  defp ecto_schema?(path) do
    source = File.read!(path)
    source =~ "use Ecto.Schema" or source =~ ~r/\bschema\s+"/
  end

  defp active_source(path) do
    path
    |> File.read!()
    |> active_source_text()
  end

  defp active_source_text(source) do
    source
    |> String.split("\n")
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
    |> String.trim()
  end
end

defmodule Scoria.Install.Surface.Migrations do
  @source_core_migrations Application.app_dir(:scoria, "priv/repo/migrations")
  @optional_lane_migration_basenames MapSet.new([
                                       "20260525070000_create_semantic_cache_tables.exs",
                                       "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                     ])

  def analyze(project_root, _opts \\ []) do
    if is_nil(project_root) do
      %{
        target_path: "priv/repo/migrations",
        classification: :manual_review,
        rationale: "Project root could not be resolved to inspect host migrations.",
        evidence: %{project_root_found?: false}
      }
    else
      destination_dir = Path.join([project_root, "priv", "repo", "migrations"])

      source_paths =
        @source_core_migrations
        |> Path.join("*.exs")
        |> Path.wildcard()
        |> Enum.reject(&(Path.basename(&1) in @optional_lane_migration_basenames))
        |> Enum.sort()

      missing_basenames =
        Enum.reduce(source_paths, [], fn source_path, acc ->
          basename = Path.basename(source_path)
          destination_path = Path.join(destination_dir, basename)

          if File.exists?(destination_path) do
            acc
          else
            [basename | acc]
          end
        end)
        |> Enum.reverse()

      cond do
        source_paths == [] ->
          %{
            target_path: destination_dir,
            classification: :manual_review,
            rationale: "No canonical Scoria core migrations were found in the package source.",
            evidence: %{source_migration_count: 0}
          }

        missing_basenames == [] ->
          %{
            target_path: destination_dir,
            classification: :no_op,
            rationale: "All required Scoria core migrations are already present.",
            evidence: %{missing_files: []}
          }

        true ->
          %{
            target_path: destination_dir,
            classification: :create,
            rationale: "One or more required Scoria core migrations are missing.",
            evidence: %{missing_files: missing_basenames}
          }
      end
    end
  end
end

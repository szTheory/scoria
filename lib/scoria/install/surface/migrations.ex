defmodule Scoria.Install.Surface.Migrations do
  @source_core_migrations Application.app_dir(:scoria, "priv/repo/migrations")
  @optional_lane_migration_basenames MapSet.new([
                                       "20260525070000_create_semantic_cache_tables.exs",
                                       "20260525090000_add_semantic_cache_compatibility_fields.exs"
                                     ])
  @verify_command "mix scoria.install --check"

  def analyze(project_root, _opts \\ []) do
    if is_nil(project_root) do
      %{
        target_path: "priv/repo/migrations",
        classification: :manual_review,
        operation: :manual_review,
        ownership_mode: :structural_set,
        manifest_key: "migrations:core_set",
        fingerprint: "missing",
        drift: %{
          reason_code: "migrations_project_root_missing",
          required_basenames: [],
          observed_basenames: [],
          missing_basenames: []
        },
        remediation:
          remediation(
            "migrations_project_root_missing",
            "Project root could not be resolved to inspect host migrations.",
            [
              "Run the installer from the Phoenix project root.",
              "Confirm `priv/repo/migrations` is present before re-checking."
            ]
          ),
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

      required_basenames = Enum.map(source_paths, &Path.basename/1)

      observed_basenames =
        destination_dir
        |> Path.join("*.exs")
        |> Path.wildcard()
        |> Enum.map(&Path.basename/1)
        |> Enum.sort()

      missing_basenames =
        required_basenames
        |> Enum.reject(&(&1 in observed_basenames))

      base_entry = %{
        target_path: destination_dir,
        ownership_mode: :structural_set,
        manifest_key: "migrations:core_set",
        fingerprint: fingerprint(required_basenames, observed_basenames),
        evidence: %{
          required_basenames: required_basenames,
          observed_basenames: observed_basenames,
          missing_files: missing_basenames
        }
      }

      cond do
        source_paths == [] ->
          base_entry
          |> Map.put(:classification, :manual_review)
          |> Map.put(:operation, :manual_review)
          |> Map.put(
            :rationale,
            "No canonical Scoria core migrations were found in the package source."
          )
          |> Map.put(:drift, %{
            reason_code: "canonical_source_missing",
            required_basenames: required_basenames,
            observed_basenames: observed_basenames,
            missing_basenames: missing_basenames
          })
          |> Map.put(
            :remediation,
            remediation(
              "canonical_source_missing",
              "Scoria package migrations are unavailable.",
              [
                "Reinstall dependencies so Scoria migration source files are available.",
                "Re-run installer check once package migrations are restored."
              ]
            )
          )

        missing_basenames == [] ->
          base_entry
          |> Map.put(:classification, :no_op)
          |> Map.put(:operation, :none)
          |> Map.put(:rationale, "All required Scoria core migrations are already present.")
          |> Map.put(:drift, %{
            reason_code: "structural_set_current",
            required_basenames: required_basenames,
            observed_basenames: observed_basenames,
            missing_basenames: missing_basenames
          })
          |> Map.put(
            :remediation,
            remediation(
              "structural_set_current",
              "Migration set is already complete.",
              ["No action required; all required migration basenames are present."]
            )
          )

        true ->
          base_entry
          |> Map.put(:classification, :create)
          |> Map.put(:operation, :copy_missing_files)
          |> Map.put(:rationale, "One or more required Scoria core migrations are missing.")
          |> Map.put(:drift, %{
            reason_code: "required_migrations_missing",
            required_basenames: required_basenames,
            observed_basenames: observed_basenames,
            missing_basenames: missing_basenames
          })
          |> Map.put(
            :remediation,
            remediation(
              "required_migrations_missing",
              "Required Scoria migrations are missing from the host project.",
              [
                "Run `mix scoria.install` to copy missing core migrations.",
                "Review `priv/repo/migrations` and keep existing host migrations intact."
              ]
            )
          )
      end
    end
  end

  defp fingerprint(required_basenames, observed_basenames) do
    payload = Enum.join(required_basenames, ",") <> "|" <> Enum.join(observed_basenames, ",")

    :crypto.hash(:sha256, payload)
    |> Base.encode16(case: :lower)
  end

  defp remediation(reason_code, summary, steps) do
    %{
      reason_code: reason_code,
      summary: summary,
      steps: steps,
      verify_command: @verify_command
    }
  end
end

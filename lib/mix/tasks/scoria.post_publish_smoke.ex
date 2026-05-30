defmodule Mix.Tasks.Scoria.PostPublishSmoke do
  @moduledoc """
  Post-publish registry attest against live Hex and Postgres.

  Runs fresh-install registry proof and, when the published version is greater
  than `0.1.0`, the conditional registry semver upgrade proof. This task is
  maintainer/release-only — it is not part of `mix test.adoption`.

  ## Environment

  * `SCORIA_REGISTRY_VERSION` — exact published semver to attest (required)
  * `SCORIA_DB_HOST` — Postgres host (default: `localhost`)
  * `SCORIA_DB_PORT` — Postgres port (default: `5432`)
  * `SCORIA_DB_USERNAME` — Postgres user (default: `postgres`)
  * `SCORIA_DB_PASSWORD` — Postgres password (default: `postgres`)
  * `SCORIA_PRESERVE_HOST` — when `1`, `true`, or `yes`, skip host cleanup on exit

  ## Examples

      SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
      SCORIA_REGISTRY_VERSION=0.1.1 mix scoria.post_publish_smoke
  """

  use Mix.Task

  @shortdoc "Runs post-publish live Hex registry consumer attest"

  @registry_proof_test "test/scoria/host_app_registry_proof_test.exs"
  @registry_upgrade_proof_test "test/scoria/host_app_registry_upgrade_proof_test.exs"

  @impl Mix.Task
  def run(args) do
    version = registry_version!()

    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")

    test_files =
      if Scoria.HexConsumerContract.semver_upgrade_eligible?(version) do
        [@registry_proof_test, @registry_upgrade_proof_test]
      else
        [@registry_proof_test]
      end

    Mix.shell().info("==> Post-publish registry attest for #{version}")

    if length(test_files) == 1 do
      Mix.shell().info("==> Skipping registry upgrade leg (version <= 0.1.0)")
    end

    Mix.Task.run("test", args ++ ["--warnings-as-errors"] ++ test_files)
  end

  defp registry_version! do
    case System.get_env("SCORIA_REGISTRY_VERSION") do
      nil ->
        Mix.raise("""
        SCORIA_REGISTRY_VERSION is required — set to the exact published semver, e.g.:

            SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
        """)

      version ->
        version
    end
  end
end

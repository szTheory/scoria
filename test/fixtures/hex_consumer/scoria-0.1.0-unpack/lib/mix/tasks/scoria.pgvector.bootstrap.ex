defmodule Mix.Tasks.Scoria.Pgvector.Bootstrap do
  use Mix.Task

  alias Scoria.Repo

  @shortdoc "Verifies or provisions a pgvector-capable Postgres for Scoria knowledge work"
  @switches [check: :boolean, compose_file: :string]
  @default_compose_file "dev/pgvector-compose.yml"
  @default_port 55432

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} = OptionParser.parse(args, switches: @switches)
    configure_runtime_env()
    Mix.Task.run("app.start")

    compose_file = Keyword.get(opts, :compose_file, @default_compose_file)

    case opts[:check] do
      true -> check_current_database!()
      _ -> provision_or_fail!(compose_file)
    end
  end

  def configure_runtime_env do
    port = System.get_env("SCORIA_DB_PORT")

    if port in [nil, ""] and File.exists?(@default_compose_file) do
      System.put_env("SCORIA_PGVECTOR_COMPOSE_FILE", @default_compose_file)
    end

    :ok
  end

  def ensure_pgvector! do
    case check_vector_support() do
      {:ok, metadata} ->
        metadata

      {:missing_extension, metadata} ->
        raise """
        pgvector prerequisite failed: database #{metadata.database} on #{metadata.hostname}:#{metadata.port} is reachable but does not have the vector extension enabled

        Next step:
          mix scoria.pgvector.bootstrap
          export SCORIA_DB_PORT=#{@default_port}
          MIX_ENV=test mix test test/scoria/knowledge_test.exs
        """

      {:connection_error, message} ->
        raise """
        pgvector prerequisite failed: #{message}

        Next step:
          mix scoria.pgvector.bootstrap
          export SCORIA_DB_PORT=#{@default_port}
          MIX_ENV=test mix test test/scoria/knowledge_test.exs
        """
    end
  end

  defp check_current_database! do
    case check_vector_support() do
      {:ok, metadata} ->
        Mix.shell().info(
          "pgvector is available for #{metadata.database} on #{metadata.hostname}:#{metadata.port}"
        )

      {:missing_extension, metadata} ->
        Mix.raise(
          with_next_steps(
            "database #{metadata.database} on #{metadata.hostname}:#{metadata.port} is reachable but does not have the vector extension enabled"
          )
        )

      {:connection_error, message} ->
        Mix.raise(with_next_steps(message))
    end
  end

  defp provision_or_fail!(compose_file) do
    case check_vector_support() do
      {:ok, metadata} ->
        Mix.shell().info(
          "pgvector is available for #{metadata.database} on #{metadata.hostname}:#{metadata.port}"
        )

      {:missing_extension, metadata} ->
        enable_vector_extension!(metadata)

      {:connection_error, _message} ->
        start_pgvector_service!(compose_file)

        case check_vector_support() do
          {:ok, metadata} ->
            Mix.shell().info(
              "pgvector is available for #{metadata.database} on #{metadata.hostname}:#{metadata.port}"
            )

          {:missing_extension, metadata} ->
            enable_vector_extension!(metadata)

          {:connection_error, message} ->
            Mix.raise(with_next_steps(message))
        end
    end
  end

  defp check_vector_support do
    config = Repo.config()
    hostname = Keyword.get(config, :hostname, "localhost")
    port = Keyword.get(config, :port, 5432)
    database = Keyword.fetch!(config, :database)

    case Ecto.Adapters.SQL.query(
           Repo,
           "select extname from pg_extension where extname = 'vector'",
           []
         ) do
      {:ok, %{rows: [["vector"]]}} ->
        {:ok, %{database: database, hostname: hostname, port: port}}

      {:ok, %{rows: []}} ->
        {:missing_extension, %{database: database, hostname: hostname, port: port}}

      {:error, error} ->
        {:connection_error, Exception.message(error)}
    end
  end

  defp enable_vector_extension!(metadata) do
    case Ecto.Adapters.SQL.query(Repo, "CREATE EXTENSION IF NOT EXISTS vector", []) do
      {:ok, _result} ->
        case check_vector_support() do
          {:ok, _verified} ->
            Mix.shell().info(
              "Enabled pgvector for #{metadata.database} on #{metadata.hostname}:#{metadata.port}"
            )

          {:missing_extension, _} ->
            Mix.raise(
              with_next_steps(
                "database #{metadata.database} on #{metadata.hostname}:#{metadata.port} is reachable but the vector extension could not be enabled"
              )
            )

          {:connection_error, message} ->
            Mix.raise(with_next_steps(message))
        end

      {:error, error} ->
        Mix.raise(with_next_steps(Exception.message(error)))
    end
  end

  defp start_pgvector_service!(compose_file) do
    unless File.exists?(compose_file) do
      Mix.raise("Missing compose asset: #{compose_file}")
    end

    Mix.shell().info("Starting pgvector service via #{compose_file}")

    case System.cmd("docker", ["compose", "-f", compose_file, "up", "-d"], stderr_to_stdout: true) do
      {output, 0} ->
        Mix.shell().info(output)
        Mix.shell().info("""
        pgvector service started.

        Export these environment variables before running migrations or tests:
          export SCORIA_DB_HOST=localhost
          export SCORIA_DB_PORT=#{@default_port}
          export SCORIA_DB_USERNAME=postgres
          export SCORIA_DB_PASSWORD=postgres

        Then verify with:
          mix scoria.pgvector.bootstrap --check
        """)

      {output, status} ->
        Mix.raise("docker compose failed (#{status}):\n#{output}")
    end
  end

  defp with_next_steps(message) do
    """
    #{message}

    Next steps:
      1. Start the bundled pgvector service:
         mix scoria.pgvector.bootstrap
      2. Point Scoria at that database for dev/test commands:
         export SCORIA_DB_HOST=localhost
         export SCORIA_DB_PORT=#{@default_port}
         export SCORIA_DB_USERNAME=postgres
         export SCORIA_DB_PASSWORD=postgres
      3. Re-run the prerequisite check:
         mix scoria.pgvector.bootstrap --check
    """
  end
end

defmodule Scoria.TestSupport.SupportCopilotGallery.Runner do
  @moduledoc false

  @gallery_root Path.join([File.cwd!(), "examples", "support_copilot"])

  def run!(opts \\ []) do
    register_cleanup(opts)

    results = [
      %{step: :deps_get, output: run_mix!(:deps_get, ["deps.get"])},
      %{step: :gallery_db, output: run_gallery_db_setup!()},
      %{step: :gallery_test, output: run_mix!(:gallery_test, ["test", "--no-start", "--trace"])}
    ]

    %{results: results, steps: Enum.map(results, & &1.step)}
  end

  defp run_gallery_db_setup! do
    for args <- [
          ["ecto.create", "-r", "Scoria.Repo", "--quiet"],
          ["ecto.migrate", "-r", "Scoria.Repo", "--to", "20260511000300", "--quiet"],
          ["eval", "Scoria.TestSupport.Migrations.migrate_knowledge!()"],
          ["ecto.migrate", "-r", "Scoria.Repo", "--to", "20260517000200", "--quiet"],
          ["scoria.pgvector.bootstrap"],
          ["ecto.migrate", "-r", "Scoria.Repo", "--quiet"]
        ] do
      run_mix!(:gallery_db, args)
    end

    "gallery database ready"
  end

  def gallery_root, do: @gallery_root

  defp run_mix!(step, args) do
    IO.puts("GALLERY STEP #{step}: mix #{Enum.join(args, " ")}")

    {output, status} =
      System.cmd("mix", args,
        cd: @gallery_root,
        env: gallery_env(),
        stderr_to_stdout: true
      )

    if status != 0 do
      raise """
      support copilot gallery step failed: #{step}
      command: mix #{Enum.join(args, " ")}
      root: #{@gallery_root}

      #{output}
      """
    end

    output
  end

  defp gallery_env do
    defaults = %{
      "MIX_ENV" => "test",
      "SCORIA_DB_HOST" => "localhost",
      "SCORIA_DB_PORT" => "5432",
      "SCORIA_DB_USERNAME" => "postgres",
      "SCORIA_DB_PASSWORD" => "postgres"
    }

    defaults
    |> Map.merge(System.get_env())
    |> Enum.to_list()
  end

  defp register_cleanup(_opts), do: :ok
end

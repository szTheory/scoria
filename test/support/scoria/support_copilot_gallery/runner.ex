defmodule Scoria.TestSupport.SupportCopilotGallery.Runner do
  @moduledoc false

  @gallery_root Path.join([File.cwd!(), "examples", "support_copilot"])

  def run!(opts \\ []) do
    register_cleanup(opts)

    results = [
      %{step: :deps_get, output: run_mix!(:deps_get, ["deps.get"])},
      %{step: :gallery_test, output: run_mix!(:gallery_test, ["test", "--trace"])}
    ]

    %{results: results, steps: Enum.map(results, & &1.step)}
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
    [
      {"MIX_ENV", "test"},
      {"SCORIA_DB_HOST", System.get_env("SCORIA_DB_HOST", "localhost")},
      {"SCORIA_DB_PORT", System.get_env("SCORIA_DB_PORT", "5432")},
      {"SCORIA_DB_USERNAME", System.get_env("SCORIA_DB_USERNAME", "postgres")},
      {"SCORIA_DB_PASSWORD", System.get_env("SCORIA_DB_PASSWORD", "postgres")}
    ]
  end

  defp register_cleanup(_opts), do: :ok
end

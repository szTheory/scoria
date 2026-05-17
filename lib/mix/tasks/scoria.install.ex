defmodule Mix.Tasks.Scoria.Install do
  use Mix.Task

  @shortdoc "Installs the Scoria dashboard and workflow routes into a Phoenix application"
  @tailwind_glob "../deps/scoria/lib/**/*.*ex"
  @runtime_config_snippet """

  config :scoria, Scoria.Runtime,
    defaults: [
      provider: "openai",
      model: "gpt-5-mini",
      prompt_policy: [policy_key: "default"]
    ]
  """

  def run(_args) do
    router_paths = Path.wildcard("lib/*_web/router.ex")
    tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]
    config_paths = ["config/runtime.exs", "config/config.exs"]

    router_path = List.first(router_paths)
    tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)
    config_path = Enum.find(config_paths, &File.exists?/1)

    if router_path && tailwind_path do
      do_run(router_path, tailwind_path, config_path)
      print_next_steps(config_path)
    else
      Mix.shell().error("Could not find router.ex or tailwind.config.js")
    end
  end

  def do_run(router_path, tailwind_path, config_path \\ nil) do
    inject_router(router_path)
    inject_tailwind(tailwind_path)

    if config_path do
      inject_runtime_config(config_path)
    end
  end

  defp inject_router(path) do
    content = File.read!(path)

    content =
      if content =~ "import ScoriaWeb.Router" do
        content
      else
        Regex.replace(~r/(defmodule .*?\.Router do\n)/, content, "\\1  import ScoriaWeb.Router\n")
      end

    content =
      if content =~ "scoria_dashboard" do
        content
      else
        Regex.replace(
          ~r/(scope\s+"\/".*?do\s+.*?pipe_through(?:\s+|\()\:browser\)?\n)/s,
          content,
          "\\1    scoria_dashboard \"/scoria\"\n"
        )
      end

    File.write!(path, content)
  end

  defp inject_tailwind(path) do
    content = File.read!(path)

    content =
      if content =~ @tailwind_glob do
        content
      else
        Regex.replace(~r/(content:\s*\[)(.*?)(\])/s, content, fn _, start, inner, ending ->
          inner_trimmed = String.trim_trailing(inner)

          separator =
            if String.ends_with?(inner_trimmed, ",") or inner_trimmed == "", do: "", else: ","

          "#{start}#{inner}#{separator}\n    \"#{@tailwind_glob}\"\n  #{ending}"
        end)
      end

    File.write!(path, content)
  end

  defp inject_runtime_config(path) do
    content = File.read!(path)

    unless content =~ "config :scoria, Scoria.Runtime" do
      File.write!(path, String.trim_trailing(content) <> @runtime_config_snippet <> "\n")
    end
  end

  defp print_next_steps(config_path) do
    Mix.shell().info("Scoria installed for the default Phoenix lane.")

    if config_path do
      Mix.shell().info("Updated #{config_path} with baseline runtime defaults.")
    end

    Mix.shell().info("""
    Next steps:
      mix ecto.migrate
      mix test
      mix test.adoption
      start one run through Scoria.start_run/2
      inspect it with Scoria.get_run/1
      visit /scoria and /scoria/workflows/:run_id

    Optional knowledge lane:
      mix scoria.pgvector.bootstrap
      mix scoria.test.knowledge
    """)
  end
end

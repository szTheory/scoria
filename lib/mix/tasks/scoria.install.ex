defmodule Mix.Tasks.Scoria.Install do
  use Mix.Task

  @shortdoc "Installs Scoria dashboard into a Phoenix application"

  def run(_args) do
    # In a real app we'd search for the router and tailwind config
    # For now we assume typical paths or find them using Path.wildcard
    router_paths = Path.wildcard("lib/*_web/router.ex")
    tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]

    router_path = List.first(router_paths)
    tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)

    if router_path && tailwind_path do
      do_run(router_path, tailwind_path)
      Mix.shell().info("Scoria installed successfully!")
    else
      Mix.shell().error("Could not find router.ex or tailwind.config.js")
    end
  end

  def do_run(router_path, tailwind_path) do
    inject_router(router_path)
    inject_tailwind(tailwind_path)
  end

  defp inject_router(path) do
    content = File.read!(path)

    # Inject import ScoriaWeb.Router
    content =
      if content =~ "import ScoriaWeb.Router" do
        content
      else
        Regex.replace(~r/(defmodule .*?\.Router do\n)/, content, "\\1  import ScoriaWeb.Router\n")
      end

    # Inject scoria_dashboard
    content =
      if content =~ "scoria_dashboard" do
        content
      else
        # Find scope "/" ... do ... pipe_through :browser and inject there
        Regex.replace(~r/(scope "\/".*? do.*?pipe_through :browser\n)/s, content, "\\1    scoria_dashboard \"/scoria\"\n")
      end

    File.write!(path, content)
  end

  defp inject_tailwind(path) do
    content = File.read!(path)

    scoria_pattern = "../deps/scoria/lib/**/*.*ex"

    content =
      if content =~ scoria_pattern do
        content
      else
        # Find content: [ ... ] and inject our path
        Regex.replace(~r/(content:\s*\[)(.*?)(\])/s, content, fn _, start, inner, ending ->
          inner_trimmed = String.trim_trailing(inner)
          separator = if String.ends_with?(inner_trimmed, ",") or inner_trimmed == "", do: "", else: ","
          
          # Add our path
          "#{start}#{inner}#{separator}\n    \"#{scoria_pattern}\"\n  #{ending}"
        end)
      end

    File.write!(path, content)
  end
end

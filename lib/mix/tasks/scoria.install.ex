defmodule Mix.Tasks.Scoria.Install do
  use Mix.Task
  alias Scoria.Install.ApplyExecutor
  alias Scoria.Install.Planner
  alias Scoria.Install.Report

  @shortdoc "Installs Scoria through planner-led safe apply"
  @switches [dry_run: :boolean, check: :boolean, format: :string]

  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    ensure_valid_args!(argv, invalid)
    ensure_valid_mode_flags!(opts)
    format = parse_format!(opts)

    router_paths = Path.wildcard("lib/*_web/router.ex")
    tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]
    config_paths = ["config/runtime.exs", "config/config.exs"]

    router_path = List.first(router_paths)
    tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)
    config_path = Enum.find(config_paths, &File.exists?/1)

    cond do
      opts[:dry_run] ->
        plan =
          Planner.build(router_path, tailwind_path, config_path,
            mode: :dry_run
          )

        print_report(plan, format, :dry_run)

      opts[:check] ->
        run_check_mode(router_path, tailwind_path, config_path, format)

      true ->
        run_apply_mode(router_path, tailwind_path, config_path, format)
    end
  end

  def do_run(router_path, tailwind_path \\ nil, config_path \\ nil) do
    project_root = project_root(router_path, tailwind_path, config_path)
    plan = Planner.build(router_path, tailwind_path, config_path, mode: :apply)
    ApplyExecutor.run(plan, project_root: project_root)
  end

  defp project_root(router_path, tailwind_path, config_path) do
    [
      config_root(config_path),
      tailwind_root(tailwind_path),
      router_root(router_path)
    ]
    |> Enum.find(& &1)
  end

  defp config_root(nil), do: nil

  defp config_root(path) do
    path
    |> Path.expand()
    |> Path.dirname()
    |> Path.dirname()
  end

  defp tailwind_root(nil), do: nil

  defp tailwind_root(path) do
    expanded = Path.expand(path)

    case Path.split(expanded) |> Enum.reverse() do
      ["tailwind.config.js", "assets" | rest] -> rest |> Enum.reverse() |> Path.join()
      ["tailwind.config.js" | rest] -> rest |> Enum.reverse() |> Path.join()
      _ -> nil
    end
  end

  defp router_root(nil), do: nil

  defp router_root(path) do
    expanded = Path.expand(path)

    case String.split(expanded, "/lib/", parts: 2) do
      [root, _rest] when root != "" -> root
      _ -> Path.dirname(expanded)
    end
  end

  defp run_check_mode(router_path, tailwind_path, config_path, format) do
    {plan, result} =
      try do
        plan =
          Planner.build(router_path, tailwind_path, config_path,
            mode: :check
          )

        {plan, Report.check_result(plan)}
      rescue
        error ->
          {check_error_plan(error), Report.check_result(error)}
      end

    print_report(plan, format, :check)

    exit_code = result.exit_code
    Mix.shell().info(Report.trailer_line(result))
    System.halt(exit_code)
  end

  defp run_apply_mode(router_path, tailwind_path, config_path, format) do
    project_root = project_root(router_path, tailwind_path, config_path)

    {plan, result} =
      try do
        plan =
          Planner.build(router_path, tailwind_path, config_path,
            mode: :apply
          )

        {plan, ApplyExecutor.run(plan, project_root: project_root)}
      rescue
        error ->
          {apply_error_plan(error), %{status: :error, exit_code: 2, reason: Exception.message(error)}}
      end

    print_report(plan, format, :apply)

    exit_code = result.exit_code
    Mix.shell().info(Report.trailer_line(result))
    System.halt(exit_code)
  end

  defp print_report(plan, "human", mode) do
    Mix.shell().info(Report.render_human(plan, mode))
  end

  defp print_report(plan, "json", mode) do
    Mix.shell().info(Report.render_json(plan, mode))
  end

  defp check_error_plan(error) do
    %{
      schema_version: 1,
      mode: :check,
      entries: [
        %{
          id: "check:error",
          surface: :check,
          target_path: "n/a",
          classification: :manual_review,
          rationale: "Check mode failed before planner output was available.",
          evidence: %{error: Exception.message(error)},
          order: 1
        }
      ],
      summary: %{create: 0, update: 0, no_op: 0, manual_review: 1}
    }
  end

  defp apply_error_plan(error) do
    %{
      schema_version: 1,
      mode: :apply,
      entries: [
        %{
          id: "apply:error",
          surface: :apply,
          target_path: "n/a",
          classification: :manual_review,
          operation: :manual_review,
          ownership_mode: :marker_region,
          manifest_key: "apply:error",
          fingerprint: "error",
          drift: %{reason_code: "apply_execution_error", details: Exception.message(error)},
          remediation: %{
            reason_code: "apply_execution_error",
            summary: "Apply mode failed before writes completed.",
            steps: [
              "Inspect the error details in this report output.",
              "Resolve the issue and rerun `mix scoria.install --check` before applying again."
            ],
            verify_command: "mix scoria.install --check"
          },
          rationale: "Apply mode failed before planner execution could complete.",
          evidence: %{error: Exception.message(error)},
          order: 1
        }
      ],
      summary: %{create: 0, update: 0, no_op: 0, manual_review: 1}
    }
  end

  defp ensure_valid_args!([], []), do: :ok

  defp ensure_valid_args!(argv, invalid) do
    invalid_switches =
      invalid
      |> Enum.map(fn {switch, value} -> "--#{switch}=#{value}" end)

    unsupported_args = invalid_switches ++ argv

    raise Mix.Error,
          "Unsupported arguments: #{Enum.join(unsupported_args, ", ")}. " <>
            "Supported options: --dry-run, --check, --format (human|json)."
  end

  defp ensure_valid_mode_flags!(opts) do
    if opts[:dry_run] && opts[:check] do
      raise Mix.Error, "Choose either --dry-run or --check, not both."
    end
  end

  defp parse_format!(opts) do
    format =
      opts
      |> Keyword.get(:format, "human")
      |> to_string()
      |> String.downcase()

    if format in ["human", "json"] do
      format
    else
      raise Mix.Error, "Unsupported --format #{inspect(format)}. Supported values: human, json."
    end
  end
end

defmodule Mix.Tasks.Scoria.WarningBaseline.Check do
  use Mix.Task

  @shortdoc "Fails when accepted warning debt rows are expired or invalid"

  @moduledoc """
  Validates accepted warning debt rows in `.planning/WARNING-BASELINE.md`.

  Expiry uses UTC calendar dates. Rows remain valid through the end of their expiry day.

  ## Examples

      mix scoria.warning_baseline.check
      mix scoria.warning_baseline.check --file test/fixtures/warning_baseline/valid.md --date 2026-01-01

  ## Options

    * `--file` - baseline markdown path (default `.planning/WARNING-BASELINE.md`)
    * `--date` - check date as `YYYY-MM-DD` (default UTC today)
  """

  alias Scoria.WarningBaseline
  alias Scoria.WarningBaseline.Row

  @switches [file: :string, date: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    file = resolve_file!(Keyword.get(opts, :file, ".planning/WARNING-BASELINE.md"))
    date = parse_date!(Keyword.get(opts, :date))

    baseline = WarningBaseline.load(file: file, date: date)

    case {WarningBaseline.invalid_rows(baseline), WarningBaseline.expired_rows(baseline)} do
      {[], []} ->
        Mix.shell().info("==> Warning baseline check passed")
        exit({:shutdown, 0})

      {invalid_rows, _} when invalid_rows != [] ->
        print_invalid_rows(invalid_rows)
        exit({:shutdown, 1})

      {_, expired_rows} ->
        print_expired_rows(expired_rows, date)
        print_remediation()
        exit({:shutdown, 1})
    end
  end

  defp resolve_file!(path) do
    if String.contains?(path, "..") do
      Mix.raise("invalid --file path: path traversal is not allowed")
    end

    cwd = File.cwd!()
    expanded = Path.expand(path, cwd)

    unless String.starts_with?(expanded, cwd) do
      Mix.raise("invalid --file path: must resolve under project root")
    end

    unless File.regular?(expanded) do
      Mix.raise("baseline file not found: #{path}")
    end

    expanded
  end

  defp parse_date!(nil), do: Date.utc_today()

  defp parse_date!(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _} -> Mix.raise("invalid --date value: expected YYYY-MM-DD, got #{inspect(value)}")
    end
  end

  defp print_invalid_rows(rows) do
    Mix.shell().error("==> Warning baseline check failed: invalid accepted rows")

    Mix.shell().error(
      String.pad_trailing("Surface", 36) <>
        String.pad_trailing("Owner", 24) <>
        String.pad_trailing("Expires", 14) <> "Issue"
    )

    for row <- rows do
      expires_label = expires_label(row)

      Mix.shell().error(
        String.pad_trailing(row.surface, 36) <>
          String.pad_trailing(display(row.owner), 24) <>
          String.pad_trailing(expires_label, 14) <> "missing owner or expiry"
      )
    end
  end

  defp print_expired_rows(rows, date) do
    Mix.shell().error("==> Warning baseline check failed: expired accepted rows")

    Mix.shell().error(
      String.pad_trailing("Surface", 36) <>
        String.pad_trailing("Expires", 14) <>
        String.pad_trailing("Owner", 24) <> "Days overdue"
    )

    for row <- rows do
      days_overdue = Date.diff(date, row.expires)

      Mix.shell().error(
        String.pad_trailing(row.surface, 36) <>
          String.pad_trailing(Date.to_iso8601(row.expires), 14) <>
          String.pad_trailing(row.owner, 24) <> Integer.to_string(days_overdue)
      )
    end
  end

  defp print_remediation do
    Mix.shell().error("")
    Mix.shell().error("Remediation:")
    Mix.shell().error("* Fix the warning debt in code and remove the accepted row.")
    Mix.shell().error("* Move the row to the Resolved section with a resolution date.")
    Mix.shell().error("* Re-baseline with a new owner, expiry, and reason in the same PR.")
  end

  defp expires_label(%Row{expires: %Date{} = date}), do: Date.to_iso8601(date)
  defp expires_label(%Row{}), do: ""

  defp display(value) when is_binary(value), do: value
  defp display(_), do: ""
end

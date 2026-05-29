defmodule Scoria.WarningBaseline do
  @moduledoc """
  Parses `.planning/WARNING-BASELINE.md` accepted warning debt rows for executable expiry enforcement.

  Expiry uses UTC calendar dates (`YYYY-MM-DD`). A row is valid through the end of its expiry day;
  it fails when the check date is strictly after the expiry date.
  """

  defmodule Row do
    @moduledoc false
    defstruct [:surface, :warning_debt, :reason, :owner, :expires, :raw_line]
  end

  @accepted_heading "## Accepted Warning Debt"
  @default_file ".planning/WARNING-BASELINE.md"

  @type t :: %{
          file: Path.t(),
          date: Date.t(),
          rows: [Row.t()]
        }

  @doc """
  Loads and parses accepted warning debt rows from the baseline markdown file.

  Options:
    * `:file` - path to baseline markdown (default `.planning/WARNING-BASELINE.md`)
    * `:date` - check date for expiry comparison (default `Date.utc_today/0`)
  """
  @spec load(keyword()) :: t()
  def load(opts \\ []) do
    file = Keyword.get(opts, :file, @default_file)
    date = Keyword.get(opts, :date, Date.utc_today())

    rows = file |> File.read!() |> parse_accepted_rows()

    %{file: file, date: date, rows: rows}
  end

  @doc "Returns rows with non-blank owner and expiry."
  @spec accepted_rows(t()) :: [Row.t()]
  def accepted_rows(%{rows: rows}) do
    Enum.filter(rows, &accepted?/1)
  end

  @doc "Returns rows in the Accepted section with blank owner or expiry."
  @spec invalid_rows(t()) :: [Row.t()]
  def invalid_rows(%{rows: rows}) do
    Enum.filter(rows, &invalid?/1)
  end

  @doc "Returns accepted rows whose expiry date is before the check date."
  @spec expired_rows(t()) :: [Row.t()]
  def expired_rows(%{rows: rows, date: date}) do
    rows
    |> Enum.filter(&accepted?/1)
    |> Enum.filter(fn row -> Date.compare(date, row.expires) == :gt end)
  end

  defp parse_accepted_rows(content) do
    content
    |> String.split("\n")
    |> extract_accepted_section()
    |> parse_table_rows()
  end

  defp extract_accepted_section(lines) do
    case Enum.find_index(lines, &(String.trim(&1) == @accepted_heading)) do
      nil ->
        []

      start_index ->
        lines
        |> Enum.drop(start_index + 1)
        |> Enum.take_while(fn line ->
          trimmed = String.trim(line)
          trimmed == "" or not String.starts_with?(trimmed, "## ")
        end)
    end
  end

  defp parse_table_rows(lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _} -> String.starts_with?(String.trim(line), "|") end)
    |> Enum.reject(fn {line, _} -> separator_row?(line) end)
    |> Enum.reject(fn {line, _} -> header_row?(line) end)
    |> Enum.map(&parse_row/1)
  end

  defp separator_row?(line) do
    line |> String.trim() |> String.match?(~r/^\|[-:\s|]+\|$/)
  end

  defp header_row?(line) do
    normalized =
      line
      |> String.trim()
      |> String.downcase()

    normalized =~ "surface" and normalized =~ "owner" and normalized =~ "expires"
  end

  defp parse_row({line, raw_line}) do
    cells =
      line
      |> String.trim()
      |> String.trim("|")
      |> String.split("|")
      |> Enum.map(&String.trim/1)

    case cells do
      [surface, warning_debt, reason, owner, expires] ->
        %Row{
          surface: surface,
          warning_debt: warning_debt,
          reason: reason,
          owner: owner,
          expires: parse_expires(expires),
          raw_line: raw_line
        }

      _ ->
        %Row{
          surface: Enum.at(cells, 0, ""),
          warning_debt: Enum.at(cells, 1, ""),
          reason: Enum.at(cells, 2, ""),
          owner: Enum.at(cells, 3, ""),
          expires: nil,
          raw_line: raw_line
        }
    end
  end

  defp parse_expires(""), do: nil

  defp parse_expires(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp accepted?(row) do
    not invalid?(row) and not is_nil(row.expires)
  end

  defp invalid?(row) do
    String.trim(row.owner) == "" or is_nil(row.expires)
  end
end

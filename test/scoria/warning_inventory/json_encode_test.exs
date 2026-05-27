defmodule Scoria.WarningInventory.JsonEncodeTest do
  use ExUnit.Case, async: true

  alias Scoria.WarningInventory

  @fixtures Path.join(["test", "fixtures", "warning_inventory"])

  test "classified rows with tuple dedupe_key encode for JSON stdout" do
    rows =
      @fixtures
      |> Path.join("host_overlay_test_path.txt")
      |> File.read!()
      |> WarningInventory.parse_output()
      |> WarningInventory.classify()

    assert [%{dedupe_key: {_, _, _}} | _] = rows
    assert Jason.encode!(%{"rows" => encode_rows(rows)})
  end

  test "mix scoria.warning_inventory --format json does not raise on encode" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Tasks.Scoria.WarningInventory.run(["--format", "json", "--quiet"])
      end)

    assert output =~ "\"rows\""

    json =
      output
      |> String.split("\n")
      |> Enum.drop_while(&(not String.starts_with?(String.trim_leading(&1), "{")))
      |> Enum.join("\n")

    assert Jason.decode!(json)
  end

  defp encode_rows(rows) do
    Enum.map(rows, fn row ->
      Map.new(row, fn {key, value} ->
        {Atom.to_string(key), encode_value(value)}
      end)
    end)
  end

  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)

  defp encode_value(value) when is_list(value) do
    Enum.map(value, &encode_value/1)
  end

  defp encode_value({a, b, c}) when is_atom(a), do: [Atom.to_string(a), b, c]
  defp encode_value(value), do: value
end

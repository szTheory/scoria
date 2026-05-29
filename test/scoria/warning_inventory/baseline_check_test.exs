defmodule Scoria.WarningInventory.BaselineCheckTest do
  use ExUnit.Case, async: true

  alias Scoria.WarningInventoryBaseline

  @baseline ".planning/warning-inventory.baseline.json"

  test "committed warning inventory baseline is empty and well-formed" do
    assert :ok = WarningInventoryBaseline.check!(file: @baseline)
  end

  test "check fails when clusters map is non-empty" do
    File.mkdir_p!("test/tmp")
    tmp = Path.join("test/tmp", "warning-inventory-baseline-bad.json")

    on_exit(fn -> File.rm(tmp) end)

    File.write!(
      tmp,
      Jason.encode!(%{
        "schema_version" => "1.0",
        "git_sha" => "abc",
        "generated_at" => "2026-01-01T00:00:00Z",
        "clusters" => %{"unused_var" => 1}
      })
    )

    assert_raise Mix.Error, ~r/clusters must be empty/, fn ->
      WarningInventoryBaseline.check!(file: tmp)
    end
  end
end

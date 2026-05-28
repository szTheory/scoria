defmodule Scoria.WarningInventory.TmpPreflightTest do
  use ExUnit.Case, async: false

  alias Scoria.WarningInventory

  @tmp_dir Path.join(["test", "tmp"])

  setup do
    WarningInventory.cleanup_transient_tmp!()
    on_exit(fn -> WarningInventory.cleanup_transient_tmp!() end)
    :ok
  end

  test "ensure_clean_tmp!/0 passes when test/tmp is missing or empty" do
    WarningInventory.cleanup_transient_tmp!()
    assert :ok = WarningInventory.ensure_clean_tmp!()

    File.mkdir_p!(@tmp_dir)
    assert :ok = WarningInventory.ensure_clean_tmp!()
  end

  test "ensure_clean_tmp!/0 raises when test/tmp contains entries" do
    installer_dir = Path.join(@tmp_dir, "installer")
    File.mkdir_p!(installer_dir)
    File.write!(Path.join(installer_dir, "marker.txt"), "pollution")

    assert_raise Mix.Error, ~r/test\/tmp contains 1 entries/, fn ->
      WarningInventory.ensure_clean_tmp!()
    end
  end

  @tag timeout: :infinity
  test "ratchet check subprocess cleans test/tmp so inventory preflight passes afterward" do
    WarningInventory.cleanup_transient_tmp!()

    {output, exit_status} =
      System.cmd("mix", ["scoria.warning_ratchet.check"],
        env: [{"MIX_ENV", "test"}],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert exit_status == 0,
           "ratchet check failed: #{output}"

    assert File.ls(@tmp_dir) in [{:ok, []}, {:error, :enoent}]

    Mix.Tasks.Scoria.WarningInventory.run(["--quiet", "--format", "table"])
  end

  test "mix scoria.warning_inventory --format json does not raise on encode" do
    WarningInventory.cleanup_transient_tmp!()

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
end

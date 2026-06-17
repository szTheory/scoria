defmodule Scoria.WarningInventory.CaptureParityTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Parity guard for the compile-only ratchet capture (WARN-06).

  Proves that the optimized `capture_output_standalone!/0` subprocess
  (`mix do compile --force + test --only __ratchet_compile_only__`)
  still surfaces high-signal `:unclassified_compile` warnings even though
  it runs zero tests. Provides two assertions:

    1. A deliberately-injected high-signal test file with an unclassified
       compile warning IS caught by the gate pipeline.
    2. With the temp file removed, the same pipeline yields zero high-signal
       unclassified offenders (clean tree passes).
  """

  alias Scoria.WarningInventory
  alias Scoria.WarningRatchet

  # A high-signal path covered by `test/scoria/**/*_test.exs` glob.
  @parity_tmp_file "test/scoria/__ratchet_parity_tmp_test.exs"

  # Module attribute warning template: sets @_parity_unused_attr but never uses it.
  # `@_parity_unused_attr` generates "module attribute @_parity_unused_attr was set but
  # never used" — not matched by any existing Cluster rule, so it classifies as
  # :unclassified_compile.
  @injected_module_source """
  defmodule Scoria.RatchetParityTmp do
    @moduledoc false
    # Deliberate unclassified compile warning for parity guard (WARN-06).
    @_parity_unused_attr "deliberate_warning"
  end
  """

  setup do
    # Always clean up the temp file, even if the test crashes.
    on_exit(fn ->
      File.rm(@parity_tmp_file)
    end)

    :ok
  end

  @tag timeout: :infinity
  test "optimized compile-only capture catches high-signal unclassified warning (injected)" do
    # STEP 1: inject the high-signal temp file that emits a compile warning.
    File.write!(@parity_tmp_file, @injected_module_source)

    # STEP 2: run the optimized subprocess — same argv as capture_output_standalone!/0.
    # We call System.cmd directly here because capture_output/0 is gated behind
    # nested_ex_unit?/0 (which returns true when called from inside ExUnit).
    {output, _status} =
      System.cmd(
        "mix",
        ["do", "compile", "--force", "+", "test", "--only", "__ratchet_compile_only__"],
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    # STEP 3: run the same pipeline the gate uses.
    offenders =
      output
      |> WarningInventory.parse_output()
      |> WarningInventory.classify()
      |> Enum.filter(fn row ->
        row.cluster_id == :unclassified_compile and WarningRatchet.high_signal_path?(row.file)
      end)

    offender_files = Enum.map(offenders, & &1.file)

    assert Enum.any?(offender_files, &String.contains?(&1, "__ratchet_parity_tmp")),
           """
           Expected the injected high-signal warning to appear in offenders.
           Offenders found: #{inspect(offender_files)}
           Raw output (first 2000 chars):
           #{String.slice(output, 0, 2000)}
           """
  end

  @tag timeout: :infinity
  test "optimized compile-only capture yields zero high-signal unclassified offenders on clean tree" do
    # Ensure the temp file is absent (clean tree).
    File.rm(@parity_tmp_file)

    {output, _status} =
      System.cmd(
        "mix",
        ["do", "compile", "--force", "+", "test", "--only", "__ratchet_compile_only__"],
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    offenders =
      output
      |> WarningInventory.parse_output()
      |> WarningInventory.classify()
      |> Enum.filter(fn row ->
        row.cluster_id == :unclassified_compile and WarningRatchet.high_signal_path?(row.file)
      end)

    assert offenders == [],
           """
           Expected zero high-signal unclassified offenders on clean tree.
           Found: #{inspect(Enum.map(offenders, & &1.file))}
           """
  end
end

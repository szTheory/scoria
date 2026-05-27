defmodule Scoria.WarningInventory.ClusterTest do
  use ExUnit.Case, async: true

  alias Scoria.WarningInventory
  alias Scoria.WarningInventory.Cluster

  @fixtures Path.join(["test", "fixtures", "warning_inventory"])

  test "classifies knowledge migration redefine warnings" do
    assert_classified("knowledge_migration_redefine.txt", :knowledge_migration_redefine)
  end

  test "classifies test unused binding warnings" do
    assert_classified("test_unused_binding.txt", :test_unused_binding)
  end

  test "classifies test dead default args warnings" do
    assert_classified("test_dead_default_args.txt", :test_dead_default_args)
  end

  test "classifies host proof generated compile warnings" do
    assert_classified("host_proof_generated_compile.txt", :host_proof_generated_compile)
  end

  test "classifies host overlay test path warnings" do
    assert_classified("host_overlay_test_path.txt", :host_overlay_test_path)
  end

  test "classifies runtime async teardown noise" do
    output = File.read!(Path.join(@fixtures, "liveview_async_teardown.txt"))

    warning = %{
      file: "test/scoria_web/live/workflow_live_test.exs",
      line: 1,
      message: String.trim(output),
      signal_kind: :runtime_log
    }

    assert Cluster.match(warning) == :liveview_async_teardown
  end

  test "excludes logger and sql warning noise from parse_output" do
    output = """
    [warning] retrying request to upstream
    severity: "warning" from sql query
    """

    assert WarningInventory.parse_output(output) == []
  end

  test "unclassified compile warnings map to p5_out_of_scope" do
    output = """
        warning: unknown compiler warning shape
        │
      1 │ foo()
        │
        └─ lib/scoria/example.ex:1:3
    """

    [row] =
      output
      |> WarningInventory.parse_output()
      |> WarningInventory.classify()

    assert row.cluster_id == :unclassified_compile
    assert row.ratchet_tier == :p5_out_of_scope
  end

  defp assert_classified(fixture, cluster_id) do
    output = File.read!(Path.join(@fixtures, fixture))

    [row | _] =
      output
      |> WarningInventory.parse_output()
      |> WarningInventory.classify()

    assert row.cluster_id == cluster_id
    assert row.ratchet_tier == WarningInventory.ratchet_tier(cluster_id)
  end
end

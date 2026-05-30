defmodule Mix.Tasks.Scoria.Test.ConnectorTest do
  use ExUnit.Case, async: true

  test "the connector lane is discoverable and targets the bounded connector subset" do
    Mix.Task.load_all()

    expected_files = Mix.Tasks.Scoria.Test.Connector.connector_test_files()

    assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Connector)
    assert function_exported?(Mix.Tasks.Scoria.Test.Connector, :run, 1)
    assert function_exported?(Mix.Tasks.Scoria.Test.Connector, :connector_test_files, 0)
    assert function_exported?(Mix.Tasks.Test.Connector, :run, 1)
    assert "test/scoria/connectors/adoption_lane_test.exs" in expected_files
    assert "test/scoria/connectors/schema_test.exs" in expected_files
    refute "test/scoria/adoption_surface_test.exs" in expected_files
    refute "test/scoria/host_app_consumer_proof_test.exs" in expected_files
    assert Mix.Task.get("scoria.test.connector")
    assert Mix.Task.get("test.connector")
  end
end

defmodule Scoria.Observe.Adapters.JidoTest do
  use ExUnit.Case, async: false

  setup do
    :telemetry.detach("scoria-observe-telemetry-test-jido")
    :telemetry.detach("scoria-observe-jido")
    
    parent = self()
    :telemetry.attach(
      "scoria-observe-telemetry-test-jido",
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, metadata, _config ->
        send(parent, {:span, metadata})
      end,
      nil
    )
    
    Scoria.Observe.Adapters.Jido.attach()
    :ok
  end

  test "transforms jido action stop event to scoria span" do
    trace_id = Ecto.UUID.generate()
    metadata = %{
      action_name: "calculate_pi",
      status: "ok",
      trace_id: trace_id
    }
    measurements = %{duration: 500}

    :telemetry.execute([:jido, :action, :stop], measurements, metadata)

    assert_receive {:span, span}
    assert span.name == "jido_action"
    assert span.span_kind == "INTERNAL"
    assert span.trace_id == trace_id
    assert span.attributes["jido.action_name"] == "calculate_pi"
    assert span.attributes["jido.status"] == "ok"
    assert span.attributes["duration_ms"] == 500
  end
end
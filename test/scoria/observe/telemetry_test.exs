defmodule Scoria.Observe.TelemetryTest do
  use ExUnit.Case, async: false
  alias Scoria.Repo
  alias Scoria.Repo.{Span, Trace}
  alias Scoria.Observe.Buffer

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    {:ok, trace} = Repo.insert(%Trace{id: Ecto.UUID.generate()})
    
    # Start Buffer
    pid = start_supervised!({Buffer, [name: :test_telemetry_buffer, flush_interval: 10, max_size: 5]})
    
    # Attach telemetry
    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(:test_telemetry_buffer)
    
    %{trace: trace, buffer: pid}
  end

  test "end-to-end integration: telemetry -> buffer -> db", %{trace: trace} do
    span_data = %{
      name: "e2e_span",
      span_kind: "LLM",
      trace_id: trace.id,
      start_time: DateTime.utc_now(),
      attributes: %{"password" => "secret_value", "public" => "value"}
    }

    # Emit telemetry event
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span_data)

    # Wait for buffer flush
    Process.sleep(50)

    # Query DB
    spans = Repo.all(Span)
    assert length(spans) == 1
    span = hd(spans)
    assert span.name == "e2e_span"
    assert span.attributes["public"] == "value"
    assert span.attributes["password"] == "[REDACTED]"
  end
end
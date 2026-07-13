defmodule Scoria.Observe.TelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.{Buffer, OperatorBroadcast}
  alias Scoria.Repo
  alias Scoria.Repo.{Span, Trace}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, trace} = Repo.insert(%Trace{id: Ecto.UUID.generate()})

    tenant_id = "tenant-#{System.unique_integer([:positive])}"
    OperatorBroadcast.reset_trace_seen!()
    Phoenix.PubSub.subscribe(Scoria.PubSub, OperatorBroadcast.tenant_topic(tenant_id))

    pid =
      start_supervised!({Buffer, [name: :test_telemetry_buffer, flush_interval: 10, max_size: 5]})

    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(:test_telemetry_buffer)

    on_exit(fn ->
      OperatorBroadcast.reset_trace_seen!()
      :telemetry.detach("scoria-observe-telemetry")
    end)

    %{trace: trace, buffer: pid, tenant_id: tenant_id}
  end

  test "end-to-end integration: telemetry -> buffer -> db", %{trace: trace} do
    # "feature" is a registered (SEC-01 closed-registry) key -- it survives
    # Bounds.enforce/2 unchanged, proving redaction + persistence still work
    # end-to-end with Bounds live in the pipeline (plan 53-04). An
    # unregistered bare key like the old "public" fixture is now correctly
    # DROPPED by Bounds, not passed through -- that is the SEC-01 guarantee,
    # not a regression.
    span_data = %{
      name: "e2e_span",
      span_kind: "LLM",
      trace_id: trace.id,
      start_time: DateTime.utc_now(),
      attributes: %{"password" => "secret_value", "feature" => "value"}
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span_data)

    Process.sleep(50)

    spans = Repo.all(Span)
    assert length(spans) == 1
    span = hd(spans)
    assert span.name == "e2e_span"
    assert span.attributes["feature"] == "value"

    # "password" is redacted by Redactor.redact/1 to "[REDACTED]" first, but
    # it is not a SEC-01 registered key, so Bounds.enforce/2 drops it
    # entirely -- neither the raw value nor the "[REDACTED]" placeholder is
    # persisted. Redaction and the closed-registry bound are two
    # independent, stacked defenses; the stricter one (Bounds) wins here.
    refute Map.has_key?(span.attributes, "password")
  end

  test "broadcasts trace_span immediately on span stop before buffer flush", %{
    trace: trace,
    tenant_id: tenant_id
  } do
    span_data = %{
      name: "live_span",
      span_kind: "LLM",
      trace_id: trace.id,
      tenant_id: tenant_id,
      start_time: DateTime.utc_now(),
      attributes: %{"public" => "value"}
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span_data)

    assert_receive {:trace_span, trace_id, span_view} when trace_id == trace.id
    assert span_view.name == "live_span"

    Process.sleep(50)
    assert Repo.aggregate(Span, :count) == 1
  end

  test "redacts span delta chunk before broadcast", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()
    span_id = Ecto.UUID.generate()

    :telemetry.execute(
      [:scoria, :observe, :span, :delta],
      %{},
      %{
        tenant_id: tenant_id,
        trace_id: trace_id,
        span_id: span_id,
        chunk: "leak api_key=super-secret-key",
        attributes: %{"api_key" => "secret"}
      }
    )

    assert_receive {:trace_delta, delta}
    refute delta.chunk =~ "super-secret-key"
    refute Map.has_key?(delta, :attributes)
    refute inspect(delta) =~ "secret"
  end

  test "broadcasts trace_delta on span delta event", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()
    span_id = Ecto.UUID.generate()

    :telemetry.execute(
      [:scoria, :observe, :span, :delta],
      %{},
      %{
        tenant_id: tenant_id,
        trace_id: trace_id,
        span_id: span_id,
        chunk: "partial"
      }
    )

    assert_receive {:trace_delta, delta}
    assert delta == %{trace_id: trace_id, span_id: span_id, chunk: "partial"}
  end
end

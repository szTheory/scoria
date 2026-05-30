defmodule Scoria.Observe.OperatorBroadcastTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.OperatorBroadcast

  setup do
    OperatorBroadcast.reset_trace_seen!()
    tenant_id = "tenant-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(Scoria.PubSub, OperatorBroadcast.tenant_topic(tenant_id))

    on_exit(fn -> OperatorBroadcast.reset_trace_seen!() end)

    %{tenant_id: tenant_id}
  end

  defp base_metadata(tenant_id, trace_id, overrides \\ []) do
    [
      tenant_id: tenant_id,
      trace_id: trace_id,
      name: "llm_call",
      span_kind: "LLM",
      start_time: DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      attributes: %{"model" => "gpt-4"}
    ]
    |> Keyword.merge(overrides)
    |> Map.new()
  end

  test "first span emits trace_opened and trace_span", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()
    metadata = base_metadata(tenant_id, trace_id)

    assert :ok = OperatorBroadcast.span_stopped(metadata)

    assert_receive {:trace_opened, header}
    assert header.id == trace_id
    assert header.tenant_id == tenant_id

    assert_receive {:trace_span, ^trace_id, span_view}
    assert span_view.name == "llm_call"
    assert span_view.span_kind == "LLM"
  end

  test "second span for same trace emits only trace_span", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()

    assert :ok = OperatorBroadcast.span_stopped(base_metadata(tenant_id, trace_id, name: "first"))
    drain_messages()

    assert :ok =
             OperatorBroadcast.span_stopped(base_metadata(tenant_id, trace_id, name: "second"))

    refute_receive {:trace_opened, _}, 10
    assert_receive {:trace_span, ^trace_id, span_view}
    assert span_view.name == "second"
  end

  test "missing tenant_id drops broadcast", %{tenant_id: _tenant_id} do
    trace_id = Ecto.UUID.generate()

    assert :dropped =
             OperatorBroadcast.span_stopped(%{
               trace_id: trace_id,
               name: "orphan_span"
             })

    refute_receive _, 10
  end

  test "span_delta broadcasts trace_delta shape", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()
    span_id = Ecto.UUID.generate()

    assert :ok =
             OperatorBroadcast.span_delta(%{
               tenant_id: tenant_id,
               trace_id: trace_id,
               span_id: span_id,
               chunk: "token"
             })

    assert_receive {:trace_delta, delta}
    assert delta == %{trace_id: trace_id, span_id: span_id, chunk: "token"}
  end

  test "span_delta drops when tenant_id missing" do
    assert :dropped =
             OperatorBroadcast.span_delta(%{
               trace_id: Ecto.UUID.generate(),
               span_id: Ecto.UUID.generate(),
               chunk: "token"
             })

    refute_receive _, 10
  end

  defp drain_messages do
    receive do
      _ -> drain_messages()
    after
      0 -> :ok
    end
  end
end

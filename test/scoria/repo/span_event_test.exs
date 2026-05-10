defmodule Scoria.Repo.SpanEventTest do
  use ExUnit.Case, async: true
  alias Scoria.Repo.SpanEvent
  alias Scoria.Repo.Span
  alias Scoria.Repo.Trace
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "inserts a span event" do
    {:ok, trace} = Repo.insert(Trace.changeset(%Trace{}, %{}))

    {:ok, span} =
      Repo.insert(
        Span.changeset(%Span{}, %{trace_id: trace.id, name: "gen", start_time: DateTime.utc_now()})
      )

    attrs = %{
      span_id: span.id,
      name: "exception",
      time: DateTime.utc_now(),
      attributes: %{"exception.message" => "timeout"}
    }

    changeset = SpanEvent.changeset(%SpanEvent{}, attrs)
    assert {:ok, event} = Repo.insert(changeset)
    assert event.name == "exception"
    assert event.attributes == %{"exception.message" => "timeout"}
    assert event.span_id == span.id
  end
end

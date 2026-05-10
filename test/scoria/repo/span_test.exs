defmodule Scoria.Repo.SpanTest do
  use ExUnit.Case, async: true
  alias Scoria.Repo.Span
  alias Scoria.Repo.Trace
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "inserts a span with relational columns and attributes" do
    # Requires a trace first
    {:ok, trace} = Repo.insert(Trace.changeset(%Trace{}, %{}))

    attrs = %{
      trace_id: trace.id,
      name: "generation",
      span_kind: "LLM",
      status_code: "OK",
      start_time: DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      attributes: %{"llm.model_name" => "gpt-4"}
    }

    changeset = Span.changeset(%Span{}, attrs)
    assert {:ok, span} = Repo.insert(changeset)
    assert span.name == "generation"
    assert span.span_kind == "LLM"
    assert span.status_code == "OK"
    assert span.attributes == %{"llm.model_name" => "gpt-4"}
    assert span.trace_id == trace.id
  end
end

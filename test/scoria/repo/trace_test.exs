defmodule Scoria.Repo.TraceTest do
  use ExUnit.Case, async: true
  alias Scoria.Repo.Trace
  alias Scoria.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "inserts a trace with attributes" do
    attrs = %{session_id: "sess_123", attributes: %{"user_id" => "u_1"}}
    changeset = Trace.changeset(%Trace{}, attrs)
    assert {:ok, trace} = Repo.insert(changeset)
    assert trace.session_id == "sess_123"
    assert trace.attributes == %{"user_id" => "u_1"}
  end
end

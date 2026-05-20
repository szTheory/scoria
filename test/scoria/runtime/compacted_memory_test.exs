defmodule Scoria.Runtime.CompactedMemoryTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.Runtime.CompactedMemory
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "can insert a compacted memory with a workflow run and embedding" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        session_id: "session-compaction"
      })

    assert {:ok, memory} =
             %CompactedMemory{}
             |> CompactedMemory.changeset(%{
               run_id: run.id,
               session_id: "session-compaction",
               start_sequence: 1,
               end_sequence: 3,
               summary_text: "Earlier workflow events were condensed into one memory.",
               embedding: :erlang.term_to_binary([0.1, 0.2, 0.3]),
               token_count: 128
             })
             |> Repo.insert()

    assert memory.run_id == run.id
    assert memory.session_id == "session-compaction"
    assert memory.start_sequence == 1
    assert memory.end_sequence == 3
    assert memory.token_count == 128

    assert [0.1, 0.2, 0.3] = :erlang.binary_to_term(memory.embedding)
  end

  test "requires the summary text for persisted memories" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor", session_id: "session-invalid"})

    changeset =
      CompactedMemory.changeset(%CompactedMemory{}, %{
        run_id: run.id,
        session_id: "session-invalid",
        start_sequence: 1,
        end_sequence: 2,
        token_count: 32
      })

    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).summary_text
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

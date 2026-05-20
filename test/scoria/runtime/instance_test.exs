defmodule Scoria.Runtime.InstanceTest do
  use ExUnit.Case, async: true
  alias Scoria.Runtime.Instance

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  describe "changeset/2" do
    test "inserts successfully with required fields" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      attrs = %{
        tenant_id: "tenant-1",
        first_seen_at: now,
        last_seen_at: now,
        transport_kind: "mcp_sse"
      }

      changeset = Instance.changeset(%Instance{}, attrs)
      assert changeset.valid?

      {:ok, instance} = Scoria.Repo.insert(changeset)
      assert instance.tenant_id == "tenant-1"
      assert instance.transport_kind == "mcp_sse"
    end
    
    test "requires tenant_id, first_seen_at, last_seen_at, transport_kind" do
      changeset = Instance.changeset(%Instance{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).tenant_id
      assert "can't be blank" in errors_on(changeset).transport_kind
    end
  end
end

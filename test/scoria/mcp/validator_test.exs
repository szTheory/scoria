defmodule Scoria.MCP.ValidatorTest do
  use ExUnit.Case, async: true
  
  alias Scoria.MCP.Validator

  defmodule DummyTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_tool"

    @impl true
    def description, do: "A dummy tool for testing"

    @impl true
    def input_schema do
      %{
        name: :string,
        age: :integer
      }
    end

    @impl true
    def execute(_args, _context), do: {:ok, "success"}
  end

  describe "validate_args/2" do
    test "returns {:ok, cast_args} for valid arguments" do
      args = %{"name" => "Alice", "age" => 30}
      assert {:ok, %{name: "Alice", age: 30}} = Validator.validate_args(DummyTool, args)
    end

    test "returns {:error, changeset} for invalid arguments (wrong type)" do
      args = %{"name" => "Alice", "age" => "thirty"}
      assert {:error, %Ecto.Changeset{} = changeset} = Validator.validate_args(DummyTool, args)
      assert {"is invalid", _} = changeset.errors[:age]
    end
  end
end

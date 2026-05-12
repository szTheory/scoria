defmodule Scoria.Workflows.JidoAdapterTest do
  use ExUnit.Case, async: false

  alias Scoria.Workflows
  alias Scoria.Workflows.JidoAdapter

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "Jido directives map into Scoria primitives without changing the root workflow contract" do
    directive = %{
      "type" => "handoff",
      "delegated_role_id" => "critic",
      "handoff_input" => %{"brief" => "review"},
      "projected_context" => %{"task" => "review"}
    }

    assert {:ok, %{kind: :handoff, delegated_role_id: "critic"}} = JidoAdapter.translate_directive(directive)

    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    {:ok, step} = Workflows.create_step(run.id, %{sequence: 1, kind: "handoff", role_id: "executor", status: "running"})

    assert {:ok, handoff} = JidoAdapter.apply_directive(step.id, directive)
    assert handoff.run_id == run.id
    assert handoff.step_id == step.id
  end

  test "unsupported or overly generic directives fail explicitly" do
    assert {:error, :unsupported_directive} = JidoAdapter.translate_directive(%{"type" => "anything"})
    assert {:error, :unsupported_directive} = JidoAdapter.translate_directive(%{"type" => "handoff"})
  end
end

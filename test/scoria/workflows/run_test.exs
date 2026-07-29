defmodule Scoria.Workflows.RunTest do
  use ExUnit.Case, async: true

  alias Scoria.Confluence
  alias Scoria.MCP.Executor
  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.Workflows.Run

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  describe "confluence_legs writer disjointness (D-15)" do
    test "the struct responds to :confluence_legs with a %{} default" do
      assert %Run{}.confluence_legs == %{}
    end

    test "Run.changeset/2 never casts :confluence_legs, even when the caller supplies it" do
      run = %Run{
        id: Ecto.UUID.generate(),
        root_role_id: "root",
        status: "running",
        lock_version: 1,
        confluence_legs: %{}
      }

      changeset =
        Run.changeset(run, %{
          status: "running",
          confluence_legs: %{"private_data" => %{"source" => "declared"}}
        })

      refute Map.has_key?(changeset.changes, :confluence_legs)
      refute Ecto.Changeset.get_change(changeset, :confluence_legs)
    end
  end

  describe "confluence_legs witness shape re-derivability (plan 57-06, cross-phase obligation 1)" do
    test "a folded lit leg's stored map is sufficient to reconstruct a valid Confluence.classify/1 input, proving Phase 58 re-derivability" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "witness-shape-test"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "witness-shape-test",
          status: "running"
        })

      call_input = %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil}

      assert {:ok, legs} =
               Executor.fold_confluence_legs_for_test(run.id, step.id, call_input)

      # 1. The fold's own return already contains the witness shape.
      assert legs.private_data.source == :declared

      # 2. Reading `confluence_legs` back from a FRESH row load (not the
      # fold's own in-process return) proves the stored map -- not just
      # the function's return value -- carries the lit flag, source, and
      # first step id.
      reloaded = Repo.get!(Run, run.id)
      stored = reloaded.confluence_legs["private_data"]

      assert stored["lit"] == true
      assert stored["source"] == "declared"
      assert stored["first_step_id"] == step.id

      # 3. The stored value alone -- reconstructed from the raw jsonb read,
      # not from any in-memory witness the test already holds -- is
      # sufficient to build a valid Confluence.classify/1 input that
      # returns the expected combination. This is the re-derivability
      # proof Phase 58 depends on.
      reconstructed_witness = %{source: String.to_existing_atom(stored["source"])}

      assert {"private_data", _evidence} =
               Confluence.classify(%{
                 private_data: reconstructed_witness,
                 untrusted_content: nil,
                 exfil: nil
               })
    end
  end
end

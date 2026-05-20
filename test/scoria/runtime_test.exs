defmodule Scoria.RuntimeTest do
  use ExUnit.Case, async: false

  alias Scoria.Runtime
  alias Scoria.Runtime.{RunDetail, RunSummary}
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  test "Scoria and Scoria.Runtime expose explicit lifecycle verbs" do
    assert Code.ensure_loaded?(Scoria)
    assert function_exported?(Scoria, :start_run, 2)
    assert function_exported?(Scoria, :resume_run, 2)
    assert function_exported?(Runtime, :start_run, 2)
    assert function_exported?(Runtime, :resume_run, 2)
  end

  test "start_run returns a curated public summary with canonical identity" do
    assert {:ok, %RunSummary{} = summary} =
             Runtime.start_run(
               %{
                 actor: %{id: "actor-runtime"},
                 tenant_id: "tenant-runtime",
                 session_id: "session-runtime"
               },
               root_role_id: "executor"
             )

    assert summary.actor_id == "actor-runtime"
    assert summary.tenant_id == "tenant-runtime"
    assert summary.session_id == "session-runtime"
    assert summary.run_id
    assert summary.status == "running"
    assert is_struct(summary, RunSummary)
  end

  test "get_run and get_run_detail return curated DTOs instead of workflow schemas" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-detail",
        tenant_id: "tenant-detail",
        session_id: "session-detail"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, %RunSummary{} = summary} = Runtime.get_run(run.id)
    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)

    assert summary.run_id == run.id
    assert detail.summary.run_id == run.id
    assert Enum.any?(detail.steps, &(&1.id == step.id))
    assert is_struct(detail, RunDetail)
  end

  test "list_runs_for_session groups continuity by session without becoming a resume shortcut" do
    {:ok, first} =
      Runtime.start_run(
        %{actor_id: "actor-session", tenant_id: "tenant-session", session_id: "shared-session"},
        root_role_id: "executor"
      )

    {:ok, second} =
      Runtime.start_run(
        %{actor_id: "actor-session", tenant_id: "tenant-session", session_id: "shared-session"},
        root_role_id: "executor"
      )

    runs = Runtime.list_runs_for_session("shared-session")

    assert Enum.map(runs, & &1.run_id) |> Enum.sort() == Enum.sort([first.run_id, second.run_id])
    assert Enum.all?(runs, &match?(%RunSummary{}, &1))
    assert first.run_id != second.run_id
  end

  test "resume_run rejects non-run identifiers" do
    assert {:error, :invalid_run_id} = Runtime.resume_run(nil)
    assert {:error, :invalid_run_id} = Runtime.resume_run("")
  end

  test "start_run stores the resolved runtime snapshot exactly once in run metadata" do
    previous = Application.get_env(:scoria, Scoria.Runtime)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:scoria, Scoria.Runtime)
      else
        Application.put_env(:scoria, Scoria.Runtime, previous)
      end
    end)

    Application.put_env(:scoria, Scoria.Runtime,
      defaults: [
        provider: "openai",
        model: "gpt-5-mini",
        prompt_policy: [
          policy_key: "app-default",
          prompt_ref: "prompt://app",
          prompt_version: "v1"
        ]
      ]
    )

    assert {:ok, summary} =
             Runtime.start_run(
               %{actor_id: "actor-policy", tenant_id: "tenant-policy"},
               runtime: [model: "gpt-5.1", prompt_policy: [prompt_version: "v2"]]
             )

    run = Workflows.get_run!(summary.run_id)

    assert run.metadata["runtime"] == %{
             "provider" => "openai",
             "model" => "gpt-5.1",
             "policy_key" => "app-default",
             "prompt_ref" => "prompt://app",
             "prompt_version" => "v2",
             "prompt_policy" => %{
               "approval_required" => false,
               "grounding_required" => false,
               "metadata" => %{},
               "policy_key" => "app-default",
               "prompt_ref" => "prompt://app",
               "prompt_version" => "v2",
               "tools_allowed" => true
             }
           }

    Application.put_env(:scoria, Scoria.Runtime, defaults: [provider: "anthropic"])
    assert Workflows.get_run!(summary.run_id).metadata["runtime"]["provider"] == "openai"
  end

  describe "register_instance/1" do
    test "creates or updates the first_seen_at/last_seen_at" do
      attrs = %{
        "tenant_id" => "tenant-1",
        "transport_kind" => "mcp_sse"
      }
      
      {:ok, instance} = Runtime.register_instance(attrs)
      assert instance.tenant_id == "tenant-1"
      assert instance.first_seen_at != nil
      assert instance.last_seen_at != nil
      assert instance.terminal_offline_reason == nil
      
      # Update
      Process.sleep(1000)
      
      attrs_update = %{
        "id" => instance.id,
        "tenant_id" => "tenant-1",
        "transport_kind" => "mcp_sse"
      }
      {:ok, updated} = Runtime.register_instance(attrs_update)
      assert updated.id == instance.id
      assert updated.first_seen_at == instance.first_seen_at
      assert DateTime.compare(updated.last_seen_at, instance.last_seen_at) == :gt
    end
  end

  describe "mark_offline/2" do
    test "sets the terminal_offline_reason and updates last_seen_at" do
      {:ok, instance} = Runtime.register_instance(%{
        "tenant_id" => "tenant-1",
        "transport_kind" => "mcp_sse"
      })
      
      Process.sleep(1000)
      
      {:ok, offline} = Runtime.mark_offline(instance.id, "transport_closed")
      assert offline.terminal_offline_reason == "transport_closed"
      assert DateTime.compare(offline.last_seen_at, instance.last_seen_at) == :gt
    end
  end
end

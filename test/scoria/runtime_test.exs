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
    assert function_exported?(Scoria, :start_handoff_run, 3)
    assert function_exported?(Scoria, :resume_run, 2)
    assert function_exported?(Scoria.Runtime, :start_run, 2)
    assert function_exported?(Scoria.Runtime, :start_handoff_run, 3)
    assert function_exported?(Scoria.Runtime, :resume_run, 2)
  end

  test "start_handoff_run creates bounded delegated lineage with a queued child step" do
    assert {:ok, summary} =
             Runtime.start_handoff_run(
               %{
                 actor_id: "actor-handoff",
                 tenant_id: "tenant-handoff",
                 session_id: "session-handoff"
               },
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{"task" => "review", "draft_answer" => "hello"}
             )

    detail = Runtime.get_run_detail!(summary.run_id)
    handoff = Enum.find(detail.handoffs, &(&1.delegated_role_id == "critic"))
    child_step = Enum.find(detail.steps, &(&1.parent_step_id != nil and &1.role_id == "critic"))

    assert detail.summary.status == "running"
    assert handoff.delegated_kind == "review"
    assert handoff.handoff_input == %{"brief" => "review draft"}
    assert child_step.kind == "review"
    assert child_step.projected_context["task"] == "review"

    assert [
             %{
               handoff_id: handoff_id,
               parent_step_id: parent_step_id,
               delegated_role_id: "critic",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               child_step_id: child_step_id,
               child_status: "queued",
               status: "queued",
               projected_context: %{"task" => "review", "draft_answer" => "hello"}
             }
           ] = detail.delegated_handoffs

    assert handoff_id == handoff.id
    assert parent_step_id == handoff.step_id
    assert child_step_id == child_step.id
    assert Enum.any?(detail.handoffs, &(&1.id == handoff.id))
    assert Enum.any?(detail.steps, &(&1.id == child_step.id))
  end

  test "get_run_detail returns an empty delegated collection for non-handoff runs" do
    {:ok, summary} =
      Runtime.start_run(
        %{actor_id: "actor-empty-delegated", tenant_id: "tenant-empty-delegated", session_id: "session-empty-delegated"},
        root_role_id: "executor"
      )

    detail = Runtime.get_run_detail!(summary.run_id)

    assert detail.delegated_handoffs == []
    assert detail.handoffs == []
  end

  test "delegated projection keeps sequence order and reports pending child lineage explicitly" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "planner",
        actor_id: "actor-sequenced-handoff",
        tenant_id: "tenant-sequenced-handoff",
        session_id: "session-sequenced-handoff"
      })

    {:ok, first_parent_step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "handoff",
        role_id: "planner",
        status: "completed"
      })

    {:ok, first_handoff} =
      Workflows.create_handoff(first_parent_step, %{
        delegated_role_id: "critic",
        delegated_kind: "review",
        capability_tags: ["policy"],
        handoff_input: %{"brief" => "review first"},
        status: "pending"
      })

    {:ok, second_parent_step} =
      Workflows.create_step(run.id, %{
        sequence: 2,
        kind: "handoff",
        role_id: "planner",
        status: "completed"
      })

    {:ok, second_handoff} =
      Workflows.create_handoff(second_parent_step, %{
        delegated_role_id: "writer",
        delegated_kind: "draft",
        capability_tags: ["copy"],
        handoff_input: %{"brief" => "draft second"},
        status: "pending"
      })

    {:ok, second_child_step} =
      Workflows.create_step(run.id, %{
        parent_step_id: second_parent_step.id,
        sequence: 3,
        kind: "draft",
        role_id: "writer",
        status: "completed",
        projected_context: %{"task" => "draft", "tone" => "calm"}
      })

    detail = Runtime.get_run_detail!(run.id)

    assert [
             %{
               handoff_id: first_handoff_id,
               parent_step_id: first_parent_step_id,
               child_step_id: nil,
               child_status: "child_step_pending",
               status: "child_step_pending",
               capability_tags: ["policy"],
               projected_context: %{},
               sequence: 1
             },
             %{
               handoff_id: second_handoff_id,
               parent_step_id: second_parent_step_id,
               child_step_id: second_child_step_id,
               child_status: "completed",
               status: "completed",
               capability_tags: ["copy"],
               projected_context: %{"task" => "draft", "tone" => "calm"},
               sequence: 2
             }
           ] = detail.delegated_handoffs

    assert first_handoff_id == first_handoff.id
    assert first_parent_step_id == first_parent_step.id
    assert second_handoff_id == second_handoff.id
    assert second_parent_step_id == second_parent_step.id
    assert second_child_step_id == second_child_step.id
  end

  test "start_handoff_run rejects missing explicit contract inputs" do
    identity = %{
      actor_id: "actor-contract",
      tenant_id: "tenant-contract",
      session_id: "session-contract"
    }

    assert {:error, :invalid_root_role_id} =
             Runtime.start_handoff_run(
               identity,
               "critic",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{}
             )

    assert {:error, :invalid_delegated_kind} =
             Runtime.start_handoff_run(
               identity,
               "critic",
               root_role_id: "planner",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{}
             )

    assert {:error, :invalid_handoff_input} =
             Runtime.start_handoff_run(
               identity,
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: "review draft",
               projected_context: %{}
             )

    assert {:error, :invalid_projected_context} =
             Runtime.start_handoff_run(
               identity,
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: "not a map"
             )
  end

  test "start_handoff_run rejects unsafe projected context before any durable write" do
    assert {:error, :unsafe_projected_context} =
             Runtime.start_handoff_run(
               %{
                 actor_id: "actor-unsafe",
                 tenant_id: "tenant-unsafe",
                 session_id: "session-unsafe"
               },
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{"safe" => %{"provider_session" => %{"token" => "secret"}}}
             )

    assert Runtime.list_runs_for_session("session-unsafe") == []
  end

  test "start_handoff_run rejects transcript, headers, and nested history projected context aliases" do
    identity = %{
      actor_id: "actor-unsafe-alias",
      tenant_id: "tenant-unsafe-alias",
      session_id: "session-unsafe-alias"
    }

    assert {:error, :unsafe_projected_context} =
             Runtime.start_handoff_run(
               identity,
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{
                 "transcript" => [%{"role" => "assistant", "content" => "too much"}]
               }
             )

    assert {:error, :unsafe_projected_context} =
             Runtime.start_handoff_run(
               %{identity | session_id: "session-unsafe-headers"},
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{"request_headers" => %{"authorization" => "secret"}}
             )

    assert {:error, :unsafe_projected_context} =
             Runtime.start_handoff_run(
               %{identity | session_id: "session-unsafe-nested"},
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{"safe" => %{"conversation_history" => ["too much state"]}}
             )
  end

  test "start_handoff_run accepts explicit empty or narrow projected context slices" do
    assert {:ok, empty_summary} =
             Runtime.start_handoff_run(
               %{actor_id: "actor-empty", tenant_id: "tenant-empty", session_id: "session-empty"},
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{}
             )

    assert {:ok, narrow_summary} =
             Runtime.start_handoff_run(
               %{
                 actor_id: "actor-narrow",
                 tenant_id: "tenant-narrow",
                 session_id: "session-narrow"
               },
               "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "review draft"},
               projected_context: %{"task" => "review"}
             )

    assert Runtime.get_run_detail!(empty_summary.run_id).summary.status == "running"
    assert Runtime.get_run_detail!(narrow_summary.run_id).summary.status == "running"
  end

  test "runtime-to-handoff adopter example starts default run before bounded handoff" do
    identity =
      Scoria.identity(%{
        actor_id: "actor-example",
        tenant_id: "tenant-example",
        session_id: "session-example"
      })

    draft_answer = "Ship the concise answer."

    assert {:ok, started} = Scoria.start_run(identity, root_role_id: "executor")

    assert {:ok, handoff_run} =
             Scoria.start_handoff_run(identity, "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
               projected_context: %{
                 "task" => "policy-and-accuracy review",
                 "draft_answer" => draft_answer
               }
             )

    assert started.session_id == handoff_run.session_id
    assert started.run_id != handoff_run.run_id

    assert {:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)

    assert [
             %{
               delegated_role_id: "critic",
               delegated_kind: "review",
               handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
               projected_context: %{
                 "task" => "policy-and-accuracy review",
                 "draft_answer" => "Ship the concise answer."
               }
             }
           ] = detail.delegated_handoffs
  end

  test "runtime-to-handoff adopter example rejects host session state in projected context" do
    identity =
      Scoria.identity(%{
        actor_id: "actor-example-rejected",
        tenant_id: "tenant-example-rejected",
        session_id: "session-example-rejected"
      })

    assert {:error, :unsafe_projected_context} =
             Scoria.start_handoff_run(identity, "critic",
               root_role_id: "planner",
               delegated_kind: "review",
               handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
               projected_context: %{"session" => %{"id" => "host-session-1"}}
             )

    assert Scoria.list_runs_for_session("session-example-rejected") == []
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

  test "get_run_detail keeps live runs readable without a source run" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "actor-live-detail",
        tenant_id: "tenant-live-detail",
        session_id: "session-live-detail"
      })

    {:ok, _step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "draft",
        role_id: "executor",
        status: "completed"
      })

    assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(run.id)
    assert detail.comparison_by_step == %{}
    assert detail.replay_provenance_strip == %{}
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
      {:ok, instance} =
        Runtime.register_instance(%{
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

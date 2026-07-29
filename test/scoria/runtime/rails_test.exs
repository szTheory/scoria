defmodule Scoria.Runtime.RailsTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.Runtime.Rails
  alias Scoria.Workflows

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    previous = Application.get_env(:scoria, Scoria.Runtime.Rails)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:scoria, Scoria.Runtime.Rails)
      else
        Application.put_env(:scoria, Scoria.Runtime.Rails, previous)
      end
    end)

    :ok
  end

  describe "resolve/1 -- the two-rung ladder (L1-L5, last-writer-wins per key)" do
    test "L1 -- app max_steps: 10, per-run max_steps: 100 resolves to 100 (per-run wins outright, NOT tighten-only)" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: 10)

      assert {:ok, %{rail_max_steps: 100}} = Rails.resolve(rails: [max_steps: 100])
    end

    test "L2 -- app max_steps: 100, per-run max_steps: 10 resolves to 10" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: 100)

      assert {:ok, %{rail_max_steps: 10}} = Rails.resolve(rails: [max_steps: 10])
    end

    test "L3 -- app max_steps: 10, per-run absent resolves to 10" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: 10)

      assert {:ok, %{rail_max_steps: 10}} = Rails.resolve([])
    end

    test "L4 -- app absent, per-run max_steps: 10 resolves to 10" do
      assert {:ok, %{rail_max_steps: 10}} = Rails.resolve(rails: [max_steps: 10])
    end

    test "L5 -- app absent, per-run absent resolves to nil for all three keys" do
      assert {:ok,
              %{rail_max_steps: nil, rail_max_tool_calls: nil, rail_max_active_ms: nil}} =
               Rails.resolve([])
    end

    test "the three keys resolve independently -- each key follows its own last-writer-wins" do
      fifteen_minutes_ms = :timer.minutes(15)

      Application.put_env(:scoria, Scoria.Runtime.Rails,
        max_steps: 10,
        max_tool_calls: 500,
        max_active_ms: fifteen_minutes_ms
      )

      assert {:ok,
              %{
                rail_max_steps: 100,
                rail_max_tool_calls: 500,
                rail_max_active_ms: ^fifteen_minutes_ms
              }} = Rails.resolve(rails: [max_steps: 100])
    end
  end

  describe "resolve/1 -- validation refusals (D-12)" do
    test "max_steps: 0 returns {:error, {:invalid_rail, :max_steps, 0}}" do
      assert {:error, {:invalid_rail, :max_steps, 0}} = Rails.resolve(rails: [max_steps: 0])
    end

    test "max_steps: -5 returns {:error, {:invalid_rail, :max_steps, -5}}" do
      assert {:error, {:invalid_rail, :max_steps, -5}} = Rails.resolve(rails: [max_steps: -5])
    end

    test "max_steps: 3.5 returns {:error, {:invalid_rail, :max_steps, 3.5}}" do
      assert {:error, {:invalid_rail, :max_steps, 3.5}} = Rails.resolve(rails: [max_steps: 3.5])
    end

    test ~s(max_steps: "ten" returns {:error, {:invalid_rail, :max_steps, "ten"}}) do
      assert {:error, {:invalid_rail, :max_steps, "ten"}} =
               Rails.resolve(rails: [max_steps: "ten"])
    end

    test "an unknown key inside :rails returns {:error, {:unknown_rail, key}} instead of silently becoming unlimited" do
      assert {:error, {:unknown_rail, :max_tool_call}} =
               Rails.resolve(rails: [max_tool_call: 5])
    end
  end

  describe "resolve/1 with no app env and no per-run opts (SC#3)" do
    test "returns all-nil, unconfigured behaviour is unchanged" do
      assert {:ok, %{rail_max_steps: nil, rail_max_tool_calls: nil, rail_max_active_ms: nil}} =
               Rails.resolve([])
    end
  end

  describe "validate_app_env/0" do
    test "returns :ok when config :scoria, Scoria.Runtime.Rails is absent" do
      assert :ok = Rails.validate_app_env()
    end

    test "returns :ok for a valid app env" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: 10, max_tool_calls: 20)

      assert :ok = Rails.validate_app_env()
    end

    test "junk app config (max_steps: \"\") makes validate_app_env/0 return an error tuple and raise nothing" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: "")

      assert {:error, {:invalid_rail, :max_steps, ""}} =
               catch_no_raise(fn -> Rails.validate_app_env() end)
    end

    test "junk app config makes resolve/1 refuse the run" do
      Application.put_env(:scoria, Scoria.Runtime.Rails, max_steps: "")

      assert {:error, {:invalid_rail, :max_steps, ""}} = Rails.resolve([])
    end
  end

  describe "Params.start/2 threading (Scoria.start_run/2)" do
    test "creates a run whose rail_max_steps persists the resolved per-run value" do
      identity = %{
        actor_id: "actor-rails-start",
        tenant_id: "tenant-rails-start",
        session_id: "session-rails-start"
      }

      assert {:ok, summary} = Scoria.start_run(identity, rails: [max_steps: 5])

      run = Workflows.get_run!(summary.run_id)
      assert run.rail_max_steps == 5
    end

    test "an invalid rail value refuses the run and the ai_workflow_runs row count is unchanged" do
      count_before = Repo.aggregate(Workflows.Run, :count)

      identity = %{actor_id: "actor-rails-invalid", tenant_id: "tenant-rails-invalid"}

      assert {:error, {:invalid_rail, :max_steps, 0}} =
               Scoria.start_run(identity, rails: [max_steps: 0])

      assert Repo.aggregate(Workflows.Run, :count) == count_before
    end
  end

  describe "Params.start_handoff/3 threading (Scoria.start_handoff_run/3)" do
    test "a handoff run honours max_steps exactly as a normal run does -- halts on its second dispatched step" do
      identity = %{
        actor_id: "actor-rails-handoff",
        tenant_id: "tenant-rails-handoff",
        session_id: "session-rails-handoff"
      }

      assert {:ok, summary} =
               Scoria.start_handoff_run(identity, "critic",
                 root_role_id: "planner",
                 delegated_kind: "review",
                 handoff_input: %{"brief" => "review draft"},
                 projected_context: %{"task" => "review"},
                 rails: [max_steps: 1]
               )

      run = Workflows.get_run!(summary.run_id)
      assert run.rail_max_steps == 1
      assert run.status == "running"

      detail = Scoria.Runtime.get_run_detail!(summary.run_id)

      child_step =
        Enum.find(detail.steps, &(&1.parent_step_id != nil and &1.role_id == "critic"))

      refute is_nil(child_step)

      handler = fn step, _run -> {:ok, %{"step_id" => step.id, "status" => "ok"}} end

      assert {:error, envelope} =
               Scoria.Workflows.Runtime.execute_step(child_step.id, handler: handler)

      assert envelope["reason_code"] == "max_steps_exceeded"

      reloaded_run = Workflows.get_run!(summary.run_id)
      assert reloaded_run.status == "halted"
    end
  end

  describe "Params.resume/2 cannot change rails (D-11 -- :rails is absent from @dispatch_keys)" do
    test "a rails: option passed to resume is not forwarded into dispatch_opts" do
      assert {:ok, dispatch_opts} =
               Scoria.Runtime.Params.resume("some-run-id", rails: [max_steps: 999])

      refute Keyword.has_key?(dispatch_opts, :rails)
    end
  end

  defp catch_no_raise(fun) do
    fun.()
  rescue
    exception -> flunk("expected no exception, got: #{Exception.format(:error, exception, __STACKTRACE__)}")
  end
end

defmodule Scoria.Workflows.RuntimeSpanTest do
  @moduledoc """
  Wave-0 test (Phase 53 Plan 08, Task 1) for `Workflows.Runtime.execute_step/2`'s
  new step-level parent span, `trace_id` threading (D-03b), and G2/G3/G4's
  guardrail spans (D-05b) -- SC#1's parent-linkage criterion for the workflow
  gates, and SC#3 for a raising step handler.

  Mirrors the real-Postgres, scoped-`Buffer`, `Telemetry.attach/1` scaffold
  from `test/scoria/observe/prompt_span_test.exs` and
  `test/scoria/observe/guardrail_test.exs` -- never a hand-synthesized
  `[:scoria, :observe, :span, :stop]` event for the paths under test
  (D-ATTR01-6). `Scoria.Observe.Adapters.MCP` is attached once at
  `Scoria.Application` boot and stays live across every test in this file;
  `Scoria.Observe.Adapters.ReqLLM` IS ALSO boot-attached at
  `Scoria.Application` boot, exactly like MCP (Phase 54.1). This file's
  per-test `:telemetry.detach("scoria-observe-reqllm")` + re-attach only
  keeps this file's ReqLLM span lifecycle independent of the boot-registered
  handler, mirroring `req_llm_test.exs`, so the scoped assertions here are
  not perturbed by the global handler.
  """

  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Telemetry, as: ObserveTelemetry
  alias Scoria.Observe.TraceProjection
  alias Scoria.Repo
  alias Scoria.Repo.Span
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime

  defmodule Handlers do
    @moduledoc false

    def sleepy_success(_step, _run) do
      Process.sleep(10)
      {:ok, %{"status" => "ok"}}
    end

    def raise_boom(_step, _run), do: raise("boom-span-test")

    # Reads the trace context `execute_handler/6` threaded into `run`
    # (D-03b) and simulates a real host handler forwarding it into a
    # `req_llm` call by hand-emitting the same `[:req_llm, :request,
    # :stop]` shape `Scoria.Observe.Adapters.ReqLLM` consumes -- mirrors
    # `req_llm_test.exs`'s own `realistic_metadata/1` fixture shape.
    def emits_llm_span(_step, run) do
      {trace_id, parent_id} = trace_context(run)

      :telemetry.execute([:req_llm, :request, :stop], %{}, %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        trace_id: trace_id,
        parent_id: parent_id
      })

      {:ok, %{"status" => "ok"}}
    end

    def wait_for_approval(_step, _run) do
      {:waiting_for_approval,
       %{
         tool_name: "approve_publish",
         arguments: %{"target" => "prod"},
         reason: "Requires approval",
         actor_id: "actor-span-test",
         tenant_id: "tenant-span-test",
         trace_id: "trace-span-test"
       }}
    end

    # Test 10: one step whose handler triggers all three legs (tool, LLM,
    # guardrail) SC#1's acceptance bar in one call.
    def full_tree(_step, run) do
      {trace_id, parent_id} = trace_context(run)

      {:ok, _result} =
        Scoria.MCP.Executor.execute(
          Scoria.Workflows.RuntimeSpanTest.DummyTool,
          %{"action" => "success"},
          %{
            trace_id: trace_id,
            parent_id: parent_id,
            tenant_id: run.tenant_id,
            workflow_run_id: run.id
          }
        )

      :telemetry.execute([:req_llm, :request, :stop], %{}, %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        trace_id: trace_id,
        parent_id: parent_id
      })

      {:waiting_for_approval,
       %{
         tool_name: "approve_publish",
         arguments: %{"target" => "prod"},
         reason: "Requires approval",
         actor_id: "actor-tree-test",
         tenant_id: "tenant-tree-test",
         trace_id: "trace-tree-test"
       }}
    end

    defp trace_context(run) do
      runtime = get_in(run.metadata || %{}, ["runtime"]) || %{}
      {Map.get(runtime, "trace_id"), Map.get(runtime, "parent_id")}
    end
  end

  defmodule DummyTool do
    @moduledoc false
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_span_tree_tool"

    @impl true
    def description, do: "dummy tool for the runtime span tree test"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{"result" => "ok"}}
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    for supervisor <- [Scoria.Workflow.TaskSupervisor, Scoria.MCP.TaskSupervisor] do
      if pid = Process.whereis(supervisor) do
        Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)
      end
    end

    Application.put_env(:scoria, :workflow_runtime_handlers, %{})
    :fuse.remove("provider:runtime-span-test-g4")

    if :ets.whereis(:scoria_breaker_registry) != :undefined,
      do: :ets.delete(:scoria_breaker_registry, "provider:runtime-span-test-g4")

    buffer_name = :"runtime_span_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
          id: buffer_name
        )
      )

    :telemetry.detach("scoria-observe-telemetry")
    ObserveTelemetry.attach(buffer_name)

    :telemetry.detach("scoria-observe-reqllm")
    :ok = Scoria.Observe.Adapters.ReqLLM.attach()

    on_exit(fn ->
      :telemetry.detach("scoria-observe-telemetry")
      :telemetry.detach("scoria-observe-reqllm")
    end)

    %{buffer: buffer_name, buffer_pid: pid}
  end

  # -- fixture helpers ------------------------------------------------------

  defp create_run(attrs \\ %{}) do
    {:ok, run} = Workflows.create_run(Map.merge(%{root_role_id: "executor"}, attrs))
    run
  end

  defp create_step(run, kind, attrs \\ %{}) do
    {:ok, step} =
      Workflows.create_step(
        run.id,
        Map.merge(
          %{
            sequence: Workflows.next_step_sequence(run.id),
            kind: kind,
            role_id: "executor",
            status: "queued"
          },
          attrs
        )
      )

    step
  end

  defp step_span_for!(run_id) do
    Repo.one!(
      from(s in Span,
        where: s.trace_id == ^run_id and s.name == "workflow_step" and is_nil(s.parent_id)
      )
    )
  end

  defp guardrail_spans_for(run_id) do
    Repo.all(from(s in Span, where: s.trace_id == ^run_id and s.span_kind == "guardrail"))
  end

  defp guardrail_span_for!(run_id, name) do
    spans = guardrail_spans_for(run_id)
    span = Enum.find(spans, &(&1.attributes["scoria.guardrail.name"] == name))
    refute is_nil(span), "no guardrail span named #{inspect(name)} found for trace #{run_id}"
    span
  end

  # -- Tests 1-2: step parent span exists + is duration-bearing -------------

  describe "Test 1/2: step parent span exists and is duration-bearing" do
    test "executing a step persists ONE step span rooted at the run's trace with a real duration",
         %{buffer: buffer_name} do
      run = create_run()
      step = create_step(run, "tool")

      assert {:ok, completed_step} = Runtime.execute_step(step.id, handler: {Handlers, :sleepy_success})
      assert completed_step.status == "completed"

      :ok = Buffer.flush_now(buffer_name)

      span = step_span_for!(run.id)

      assert span.span_kind == "tool"
      assert span.trace_id == run.id
      assert span.parent_id == nil
      assert span.status_code == "OK"
      assert DateTime.compare(span.end_time, span.start_time) == :gt
    end
  end

  # -- Test 3: step span is failure-bearing (SC#3) ---------------------------

  describe "Test 3: step span is failure-bearing (SC#3)" do
    test "a raising handler produces an ERROR step span with a real duration, and execute_step/2's return is unchanged",
         %{buffer: buffer_name} do
      run = create_run()
      step = create_step(run, "tool")

      assert {:ok, failed_step} = Runtime.execute_step(step.id, handler: {Handlers, :raise_boom})
      assert failed_step.status == "failed"

      :ok = Buffer.flush_now(buffer_name)

      span = step_span_for!(run.id)

      assert span.status_code == "ERROR"
      assert span.trace_id == run.id
      assert span.parent_id == nil
      assert DateTime.compare(span.end_time, span.start_time) == :gt
    end
  end

  # -- Tests 4-5: trace_id threading (D-03b) + parent linkage (SC#1) --------

  describe "Test 4/5: trace_id threading and parent linkage (SC#1)" do
    test "a handler-emitted LLM span shares the step span's trace_id and is parented to it",
         %{buffer: buffer_name} do
      run = create_run()
      step = create_step(run, "tool")

      assert {:ok, _completed} = Runtime.execute_step(step.id, handler: {Handlers, :emits_llm_span})

      :ok = Buffer.flush_now(buffer_name)

      step_span = step_span_for!(run.id)
      llm_span = Repo.get_by!(Span, trace_id: run.id, span_kind: "llm")

      assert llm_span.trace_id == run.id
      assert llm_span.parent_id == step_span.id

      assert Repo.aggregate(from(s in Span, where: s.trace_id == ^run.id), :count) >= 2
    end
  end

  # -- Test 6: G2 escalate ---------------------------------------------------

  describe "Test 6: G2 (approval_gate / escalate)" do
    test "waiting_for_approval emits a guardrail span parented to the step span; execute_step/2's return is unchanged",
         %{buffer: buffer_name} do
      run = create_run()
      step = create_step(run, "approval")

      assert {:ok, approval} = Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})
      assert approval.workflow_run_id == run.id

      :ok = Buffer.flush_now(buffer_name)

      step_span = step_span_for!(run.id)
      guardrail_span = guardrail_span_for!(run.id, "approval_gate")

      assert guardrail_span.attributes["scoria.guardrail.decision"] == "escalate"
      assert guardrail_span.attributes["scoria.guardrail.reason_code"] == "approval_required"
      assert guardrail_span.trace_id == run.id
      assert guardrail_span.parent_id == step_span.id
      assert guardrail_span.status_code == "OK"
    end
  end

  # -- Test 7: G3 budget block ------------------------------------------------

  describe "Test 7: G3 (budget_gate / block)" do
    test "a budget-rejected step emits a guardrail span parented to the step span (design fork PINNED: the step span already opened before reserve_budget/3 runs); execute_step/2's return is unchanged",
         %{buffer: buffer_name} do
      tenant_id = "tenant-g3-#{System.unique_integer([:positive])}"

      {:ok, _policy} =
        SRE.create_budget_policy(%{
          tenant_id: tenant_id,
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:#{tenant_id}",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: Decimal.new("1.0"),
          trip_threshold: Decimal.new("2.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      run = create_run(%{tenant_id: tenant_id})
      step = create_step(run, "tool")

      assert {:ok, failed_step} =
               Runtime.execute_step(
                 step.id,
                 handler: {Handlers, :sleepy_success},
                 budget_context: %{
                   tenant_id: tenant_id,
                   actor_id: "actor-g3",
                   estimated_cost_usd: Decimal.new("5.0"),
                   integration_kind: "provider"
                 }
               )

      assert failed_step.status == "failed"
      assert failed_step.error_envelope["reason_code"] == "trip_threshold_exceeded"

      :ok = Buffer.flush_now(buffer_name)

      step_span = step_span_for!(run.id)
      guardrail_span = guardrail_span_for!(run.id, "budget_gate")

      assert guardrail_span.attributes["scoria.guardrail.decision"] == "block"
      assert guardrail_span.attributes["scoria.guardrail.reason_code"] == "budget_rejected"
      assert guardrail_span.trace_id == run.id
      assert guardrail_span.parent_id == step_span.id
      assert guardrail_span.status_code == "OK"
    end
  end

  # -- Test 8: G4 breaker block -----------------------------------------------

  describe "Test 8: G4 (breaker_gate / block)" do
    test "a breaker-open step emits a guardrail span parented to the step span; execute_step/2's return is unchanged",
         %{buffer: buffer_name} do
      trip_run = create_run()
      trip_step = create_step(trip_run, "external")

      Runtime.execute_step(
        trip_step.id,
        handler: {Handlers, :raise_boom},
        breaker_context: %{integration_kind: "provider", provider_ref: "runtime-span-test-g4"}
      )

      run = create_run()
      step = create_step(run, "external")

      assert {:ok, blocked_step} =
               Runtime.execute_step(
                 step.id,
                 handler: {Handlers, :sleepy_success},
                 breaker_context: %{integration_kind: "provider", provider_ref: "runtime-span-test-g4"}
               )

      assert blocked_step.status == "failed"
      assert blocked_step.error_envelope["reason_code"] == "breaker_open"

      :ok = Buffer.flush_now(buffer_name)

      step_span = step_span_for!(run.id)
      guardrail_span = guardrail_span_for!(run.id, "breaker_gate")

      assert guardrail_span.attributes["scoria.guardrail.decision"] == "block"
      assert guardrail_span.attributes["scoria.guardrail.reason_code"] == "breaker_open"
      assert guardrail_span.trace_id == run.id
      assert guardrail_span.parent_id == step_span.id
      assert guardrail_span.status_code == "OK"
    end
  end

  # -- Test 9: PROMPT span on a live path (JudgeRunner) ----------------------

  describe "Test 9: the JudgeRunner PROMPT span carries no judge explanation" do
    defmodule ReqLLMStub do
      @moduledoc false

      def generate_object(model_spec, prompt, _schema, _opts) do
        send(self(), {:req_llm_called, model_spec, prompt})

        {:ok,
         %{
           object: %{
             "score" => 1.0,
             "status" => "passed",
             "explanation" => "DISTINCTIVE_JUDGE_TOKEN_53_08_9c2f",
             "evidence_refs" => %{"judge" => "stub"}
           }
         }}
      end
    end

    test "run_live/1 produces a duration-bearing PROMPT span whose attributes never carry the judge's free-form explanation",
         %{buffer: buffer_name} do
      {:ok, dataset} =
        Scoria.Eval.create_dataset(%{
          name: "judge-span-dataset-#{System.unique_integer([:positive])}",
          version: "1",
          items: [
            %{
              input: %{"request_kind" => "prompt"},
              expected_output: %{"answer" => "expected"},
              captured_output: %{"answer" => "captured"},
              metadata: %{}
            }
          ]
        })

      {:ok, dataset} = Scoria.Eval.seal_dataset(dataset)

      {:ok, eval_spec} =
        Scoria.Eval.create_eval_spec(%{
          name: "judge-span-spec-#{System.unique_integer([:positive])}",
          description: "Judge span spec",
          dataset_id: dataset.id,
          eval_mode: :live_judge,
          subject: %{
            subject_kind: :prompt_template,
            prompt_template_id: Ecto.UUID.generate(),
            prompt_entity_id: Ecto.UUID.generate(),
            prompt_version: 1
          },
          scorers: [
            %{
              metric_key: "correctness",
              scorer_kind: :llm_judge,
              judge_prompt_template_id: Ecto.UUID.generate(),
              judge_prompt_version: 1,
              judge_provider: "openai",
              judge_model: "gpt-4o-mini",
              weight: 1.0
            }
          ],
          threshold_policy: %{
            pass_rate_gte: 1.0,
            mean_score_gte: 1.0,
            max_latency_ms: 100
          }
        })

      assert {:ok, _result} =
               Scoria.Eval.JudgeRunner.run_live(%{
                 dataset_id: dataset.id,
                 eval_spec_id: eval_spec.id,
                 provider: "openai",
                 model: "gpt-4o-mini",
                 req_llm_module: ReqLLMStub
               })

      assert_received {:req_llm_called, "openai:gpt-4o-mini", _prompt}

      :ok = Buffer.flush_now(buffer_name)

      span = Repo.one!(from(s in Span, where: s.span_kind == "prompt", order_by: [desc: s.inserted_at], limit: 1))

      assert DateTime.compare(span.end_time, span.start_time) == :gt

      encoded = Jason.encode!(span.attributes)
      refute encoded =~ "DISTINCTIVE_JUDGE_TOKEN_53_08_9c2f"

      refute Map.has_key?(span.attributes, "explanation")
      refute Map.has_key?(span.attributes, "reason")
    end
  end

  # -- Test 10: the whole tree (SC#1 end to end) ------------------------------

  describe "Test 10: the whole tree renders (SC#1 end to end)" do
    test "a step triggering an MCP tool call, an LLM call, and a guardrail check produces a tree with the step at depth 0 and its children at depth 1",
         %{buffer: buffer_name} do
      run = create_run()
      step = create_step(run, "tool")

      assert {:ok, _approval} = Runtime.execute_step(step.id, handler: {Handlers, :full_tree})

      :ok = Buffer.flush_now(buffer_name)

      spans = Repo.all(from(s in Span, where: s.trace_id == ^run.id))
      tree = spans |> TraceProjection.with_depths() |> TraceProjection.tree_order()

      step_span = Enum.find(tree, &(&1.name == "workflow_step"))
      refute is_nil(step_span)
      assert step_span.depth == 0
      assert step_span.parent_id == nil

      children = Enum.reject(tree, &(&1.id == step_span.id))
      assert length(children) >= 3

      assert Enum.all?(children, &(&1.depth == 1))
      assert Enum.all?(children, &(&1.parent_id == step_span.id))

      kinds = children |> Enum.map(& &1.span_kind) |> Enum.sort() |> Enum.uniq()
      assert "guardrail" in kinds
      assert "llm" in kinds
      assert "mcp" in kinds
    end
  end

  # -- Test 11: rail denial persists scoria.rail.* attributes (RAIL-01, D-18, plan 56.1-05 Task 1)

  describe "Test 11: a rail-denied step's span carries the three scoria.rail.* attributes; no second span" do
    test "a max_steps denial persists the three attributes onto the step span and creates no additional span",
         %{buffer: buffer_name} do
      run = create_run(%{rail_max_steps: 0})
      step = create_step(run, "tool")

      assert {:error, envelope} = Runtime.execute_step(step.id, handler: {Handlers, :sleepy_success})
      assert envelope["reason_code"] == "max_steps_exceeded"

      :ok = Buffer.flush_now(buffer_name)

      span = step_span_for!(run.id)

      assert span.status_code == "ERROR"
      assert span.attributes["scoria.rail.rail"] == "max_steps"
      assert span.attributes["scoria.rail.limit"] == 0
      assert span.attributes["scoria.rail.observed"] == 0

      assert Repo.aggregate(from(s in Span, where: s.trace_id == ^run.id), :count) == 1

      reloaded_run = Repo.get!(Scoria.Workflows.Run, run.id)
      assert reloaded_run.status == "halted"
    end

    test "a max_active_ms denial persists the three attributes onto the step span and creates no additional span",
         %{buffer: buffer_name} do
      run = create_run(%{rail_max_active_ms: :timer.minutes(5)})
      step = create_step(run, "tool")

      ten_minutes_ago =
        DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.truncate(:microsecond)

      Repo.get!(Scoria.Workflows.Run, run.id)
      |> Ecto.Changeset.change(started_at: ten_minutes_ago)
      |> Repo.update!()

      assert {:error, envelope} = Runtime.execute_step(step.id, handler: {Handlers, :sleepy_success})
      assert envelope["reason_code"] == "max_active_ms_exceeded"

      :ok = Buffer.flush_now(buffer_name)

      span = step_span_for!(run.id)

      assert span.status_code == "ERROR"
      assert span.attributes["scoria.rail.rail"] == "max_active_ms"
      assert span.attributes["scoria.rail.limit"] == :timer.minutes(5)
      assert span.attributes["scoria.rail.observed"] > span.attributes["scoria.rail.limit"]

      assert Repo.aggregate(from(s in Span, where: s.trace_id == ^run.id), :count) == 1

      reloaded_run = Repo.get!(Scoria.Workflows.Run, run.id)
      assert reloaded_run.status == "halted"
    end
  end
end

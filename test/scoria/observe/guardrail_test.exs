defmodule Scoria.Observe.GuardrailTest do
  @moduledoc """
  Wave-0 test (53-07 Task 1) for `Scoria.Observe.Guardrail.emit/1` -- the
  guardrail span shape, the never-free-text guarantee (SEC-01, Test 4 is
  the highest-value test in the phase), the not-applicable-emits-no-span
  rule (D-05d), and G1's wiring into the REAL `Scoria.Runtime.start_run/2`
  (D-03d) -- never a hand-synthesized telemetry event (D-ATTR01-6).

  Mirrors the real-Postgres, scoped-`Buffer`, `Telemetry.attach/1` scaffold
  from `test/scoria/observe/prompt_span_test.exs`.
  """

  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Guardrail
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.Telemetry, as: ObserveTelemetry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Scoria.Repo.Span
  alias Scoria.Repo.SpanEvent
  alias Scoria.Runtime
  alias Scoria.Workflows.Run

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    original_require_verdict = Application.get_env(:scoria, :require_eval_verdict, false)
    Application.put_env(:scoria, :require_eval_verdict, false)

    buffer_name = :"guardrail_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
          id: buffer_name
        )
      )

    # Real production wiring, not a hand-synthesized :telemetry.execute call
    # (D-ATTR01-6): detach the default-named handler and re-attach it onto
    # this test's scoped buffer, exactly as prompt_span_test.exs does.
    :telemetry.detach("scoria-observe-telemetry")
    ObserveTelemetry.attach(buffer_name)

    on_exit(fn ->
      :telemetry.detach("scoria-observe-telemetry")
      Application.put_env(:scoria, :require_eval_verdict, original_require_verdict)
    end)

    %{buffer: buffer_name, buffer_pid: pid}
  end

  # -- shared helpers ------------------------------------------------------

  defp emit_and_flush(input, buffer_name) do
    trace_id = Map.get(input, :trace_id) || Ecto.UUID.generate()
    span_id = Map.get(input, :span_id) || Ecto.UUID.generate()

    :ok =
      input
      |> Map.merge(%{trace_id: trace_id, span_id: span_id})
      |> Guardrail.emit()

    :ok = Buffer.flush_now(buffer_name)

    Repo.get_by!(Span, id: span_id)
  end

  defp guardrail_spans do
    Repo.all(from(s in Span, where: s.span_kind == "guardrail"))
  end

  defp insert_prompt_template(attrs) do
    attrs = Enum.into(attrs, %{})

    Repo.insert!(%PromptTemplate{
      entity_id: Map.get(attrs, :entity_id, Ecto.UUID.generate()),
      version: Map.get(attrs, :version, 1),
      status: Map.get(attrs, :status, "active"),
      system_message: Map.get(attrs, :system_message, "sys"),
      user_template: Map.get(attrs, :user_template, "user"),
      is_current: Map.get(attrs, :is_current, true)
    })
  end

  # -- Tests 1-6: unit tests of Guardrail.emit/1 ---------------------------

  describe "Scoria.Observe.Guardrail.emit/1 (unit)" do
    test "Test 1: block decision persists a GUARDRAIL span with all five scoria.guardrail.* attributes",
         %{buffer: buffer_name} do
      span =
        emit_and_flush(
          %{
            name: "release_gate",
            decision: "block",
            reason_code: :unapproved_draft,
            subject_ref: "prompt-template-1",
            policy_key: "release-gate-policy"
          },
          buffer_name
        )

      assert span.span_kind == "guardrail"
      assert span.name == "guardrail.release_gate"
      assert span.attributes[Semconv.openinference_span_kind_key()] == "GUARDRAIL"

      guardrail_attrs = Map.take(span.attributes, Keyword.values(Semconv.guardrail_keys()))
      assert map_size(guardrail_attrs) == 5

      assert span.attributes["scoria.guardrail.name"] == "release_gate"
      assert span.attributes["scoria.guardrail.decision"] == "block"
      assert span.attributes["scoria.guardrail.reason_code"] == "unapproved_draft"
      assert span.attributes["scoria.guardrail.subject_ref"] == "prompt-template-1"
      assert span.attributes["scoria.guardrail.policy_key"] == "release-gate-policy"
    end

    test "Test 2 (D-05e): status_code is OK on a BLOCK decision -- the evaluation succeeded, only the business decision blocked",
         %{buffer: buffer_name} do
      span =
        emit_and_flush(
          %{name: "release_gate", decision: "block", reason_code: :unapproved_draft},
          buffer_name
        )

      # A block is NOT a span error. Getting this wrong would light every
      # blocked run red in the trace tree AND feed junk into the
      # "ERROR"-status negative-signal sampler at online_scoring.ex:453.
      assert span.status_code == "OK"
      refute span.status_code == "ERROR"
    end

    test "Test 3: escalate decision persists the escalate value with OK status", %{
      buffer: buffer_name
    } do
      span =
        emit_and_flush(
          %{name: "approval_gate", decision: "escalate", reason_code: :approval_required},
          buffer_name
        )

      assert span.attributes["scoria.guardrail.decision"] == "escalate"
      assert span.status_code == "OK"
    end

    test "Test 4 (SEC-01, THE never-free-text regression): a JudgeRunner-shaped free-text payload never reaches the persisted span",
         %{buffer: buffer_name} do
      ssn_string = "The user's SSN 123-45-6789 appears in the prompt"
      judge_token = "DISTINCTIVE_JUDGE_TOKEN_4b2e"

      span =
        emit_and_flush(
          %{
            name: "release_gate",
            decision: "block",
            reason_code: :unapproved_draft,
            reason: ssn_string,
            explanation: judge_token
          },
          buffer_name
        )

      allowed_keys =
        Semconv.guardrail_keys()
        |> Keyword.values()
        |> MapSet.new()
        |> MapSet.put(Semconv.openinference_span_kind_key())
        |> MapSet.put("tenant_id")
        |> MapSet.put("workflow_run_id")
        |> MapSet.put("session_id")

      persisted_keys = span.attributes |> Map.keys() |> MapSet.new()
      unexpected_keys = MapSet.difference(persisted_keys, allowed_keys)

      refute Map.has_key?(span.attributes, "reason"),
             "forbidden key \"reason\" reached the persisted guardrail span"

      refute Map.has_key?(span.attributes, "explanation"),
             "forbidden key \"explanation\" reached the persisted guardrail span"

      assert MapSet.size(unexpected_keys) == 0,
             "unexpected attribute keys reached the persisted guardrail span: #{inspect(MapSet.to_list(unexpected_keys))}"

      encoded = Jason.encode!(span.attributes)

      refute encoded =~ "123-45-6789",
             "the SSN string leaked into the persisted guardrail span attributes"

      refute encoded =~ judge_token,
             "the JudgeRunner-shaped explanation token leaked into the persisted guardrail span attributes"
    end

    test "Test 5: an unrecognized reason_code normalizes to \"unknown\" and emits the fallback telemetry event",
         %{buffer: buffer_name} do
      parent = self()
      handler_id = "guardrail-fallback-test-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:scoria, :observe, :guardrail, :fallback],
        fn event, measurements, metadata, _config ->
          send(parent, {:fallback, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      span =
        emit_and_flush(
          %{
            name: "release_gate",
            decision: "block",
            reason_code: :something_a_future_dev_invented
          },
          buffer_name
        )

      # The enum is not widened at runtime.
      assert span.attributes["scoria.guardrail.reason_code"] == "unknown"

      assert_receive {:fallback, [:scoria, :observe, :guardrail, :fallback], %{},
                      %{value: :something_a_future_dev_invented}}
    end

    test "Test 6: the persisted span is duration-bearing -- end_time strictly after start_time for a real elapsed interval",
         %{buffer: buffer_name} do
      started_wall = DateTime.utc_now()
      start_mono = System.monotonic_time()
      Process.sleep(5)

      span =
        emit_and_flush(
          %{
            name: "release_gate",
            decision: "allow",
            started_wall: started_wall,
            start_mono: start_mono
          },
          buffer_name
        )

      # The span is "it ran", and how long it took is the point.
      assert DateTime.compare(span.end_time, span.start_time) == :gt
    end
  end

  # -- Tests 7-10: G1 integration, driving the REAL Scoria.Runtime.start_run/2

  describe "G1 integration (Scoria.Runtime.start_run/2)" do
    test "Test 7 (D-05d, not_applicable = NO span): no prompt_ref configured emits zero guardrail spans",
         %{buffer: buffer_name} do
      identity = %{
        actor_id: "actor-g1-na",
        tenant_id: "tenant-g1-na",
        session_id: "session-g1-na"
      }

      # XACML's NotApplicable: a host with no prompt policy configured must
      # not get a meaningless guardrail span on every single run.
      assert {:ok, _summary} = Runtime.start_run(identity, root_role_id: "executor")

      :ok = Buffer.flush_now(buffer_name)

      assert guardrail_spans() == []
    end

    test "Test 8 (D-03d, G1 allowed path): a RELEASED prompt template roots the trace at run.id with parent_id nil",
         %{buffer: buffer_name} do
      template = insert_prompt_template(status: "active")

      identity = %{
        actor_id: "actor-g1-allow",
        tenant_id: "tenant-g1-allow",
        session_id: "session-g1-allow"
      }

      opts = [root_role_id: "executor", runtime: %{prompt_policy: %{prompt_ref: template.id}}]

      assert {:ok, summary} = Runtime.start_run(identity, opts)

      :ok = Buffer.flush_now(buffer_name)

      assert [span] = guardrail_spans()
      assert span.attributes["scoria.guardrail.name"] == "release_gate"
      assert span.attributes["scoria.guardrail.decision"] == "allow"
      assert span.trace_id == summary.run_id
      assert span.parent_id == nil

      # Emitted AFTER the run exists -- a run IS a trace (D-03a).
      assert Repo.get(Run, span.trace_id)
    end

    test "Test 9 (D-03d, G1 blocked path): a DRAFT prompt template produces a one-span trace and leaves start_run/2's error tuple unchanged",
         %{buffer: buffer_name} do
      template = insert_prompt_template(status: "draft")

      identity = %{
        actor_id: "actor-g1-block",
        tenant_id: "tenant-g1-block",
        session_id: "session-g1-block"
      }

      opts = [root_role_id: "executor", runtime: %{prompt_policy: %{prompt_ref: template.id}}]

      # start_run/2's return contract is byte-for-byte unchanged by this
      # phase -- the guardrail span is a side effect, never a control-flow
      # change.
      assert {:error, :unapproved_draft} = Runtime.start_run(identity, opts)

      :ok = Buffer.flush_now(buffer_name)

      assert [span] = guardrail_spans()
      assert span.attributes["scoria.guardrail.decision"] == "block"
      assert span.attributes["scoria.guardrail.reason_code"] == "unapproved_draft"
      assert span.parent_id == nil

      # A blocked run produces a legitimate ONE-SPAN TRACE: a freshly-minted
      # trace_id with no corresponding Run row.
      assert {:ok, _uuid} = Ecto.UUID.cast(span.trace_id)
      refute Repo.get(Run, span.trace_id)
    end

    test "Test 10: a raising guardrail-emit telemetry handler does not change start_run/2's return (observability never breaks host business logic)" do
      handler_id = "guardrail-raise-test-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:scoria, :observe, :span, :stop],
        fn _event, _measurements, _metadata, _config ->
          raise "simulated guardrail emit crash"
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      template = insert_prompt_template(status: "draft")

      identity = %{
        actor_id: "actor-g1-raise",
        tenant_id: "tenant-g1-raise",
        session_id: "session-g1-raise"
      }

      opts = [root_role_id: "executor", runtime: %{prompt_policy: %{prompt_ref: template.id}}]

      assert {:error, :unapproved_draft} = Runtime.start_run(identity, opts)
    end
  end

  # -- Task 3 (SC#3): real-call-site guardrail_triggered emission proofs --

  describe "Task 3 (SC#3): guardrail_triggered fires from the real Guardrail.emit/1 producer" do
    test "a real block decision persists a guardrail_triggered event with the closed attribute set",
         %{buffer: buffer_name} do
      span =
        emit_and_flush(
          %{name: "release_gate", decision: "block", reason_code: :unapproved_draft},
          buffer_name
        )

      event = Repo.get_by(SpanEvent, span_id: span.id)

      assert event
      assert event.name == "guardrail_triggered"
      assert event.attributes["scoria.guardrail.name"] == "release_gate"
      assert event.attributes["scoria.guardrail.decision"] == "block"
      assert event.attributes["scoria.guardrail.reason_code"] == "unapproved_draft"
      refute Map.has_key?(event.attributes, "scoria.guardrail.subject_ref")
      refute Map.has_key?(event.attributes, "scoria.guardrail.policy_key")
    end

    test "a real escalate decision persists a guardrail_triggered event", %{buffer: buffer_name} do
      span =
        emit_and_flush(
          %{name: "approval_gate", decision: "escalate", reason_code: :approval_required},
          buffer_name
        )

      event = Repo.get_by(SpanEvent, span_id: span.id)

      assert event
      assert event.name == "guardrail_triggered"
      assert event.attributes["scoria.guardrail.decision"] == "escalate"
    end

    test "a real allow decision persists NO guardrail_triggered event", %{buffer: buffer_name} do
      span = emit_and_flush(%{name: "release_gate", decision: "allow"}, buffer_name)

      refute Repo.get_by(SpanEvent, span_id: span.id)
    end
  end
end

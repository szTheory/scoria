defmodule Scoria.Observe.EventEmitTest do
  @moduledoc """
  The Phase 53B acceptance canary suite (EVENT-02/EVENT-03, D-05, SEC-01).

  Proves all four ROADMAP success criteria plus the D-05 fail-closed
  corollary and the SEC-01 Bounds:event corollary end-to-end against the
  real telemetry -> `Scoria.Observe.Telemetry.handle_event/4` -> `Buffer` ->
  Postgres pipeline, mirroring the DB-backed scaffold from
  `prompt_span_test.exs`/`telemetry_test.exs` (real Sandbox checkout, a
  uniquely-named scoped `Buffer`, detach/re-attach the shared
  `Scoria.Observe.Telemetry` handler onto that scoped buffer, `flush_now`
  instead of `Process.sleep`).

  **SC#1 redaction-key choice (deviation from the plan's literal wording).**
  The plan instructs picking "a deny-listed key from the Redactor's actual
  deny-list." `Scoria.Observe.Redactor`'s hardcoded `@default_deny_list`
  (`password`/`api_key`/`token`/`secret`) contains NO key that is also a
  member of `Scoria.Observe.Semconv.attribute_registry/0` — and
  `telemetry_test.exs`'s existing "end-to-end integration" test already
  documents that an unregistered key, even after `Redactor.redact/1` turns
  its value into `"[REDACTED]"`, is then DROPPED ENTIRELY by
  `Bounds.enforce/2` (the stricter tier wins; neither the raw value nor the
  redaction placeholder survives). Redacting `"password"` here would
  therefore prove the OPPOSITE of SC#1 — the key would be absent, not
  `"[REDACTED]"`. To exercise the identical `Redactor.redact/1` call site on
  a key that also clears the closed-registry tier, this test extends the
  deny list via `Redactor`'s own real adopter-facing config seam
  (`config :scoria, Scoria.Observe.Redactor, deny_list: [...]`) with
  `"session_id"` — a real `attribute_registry/0` member (class `:id`) that
  already appears in production span/event attribute maps via
  `Scoria.Observe.merge_scoped_ids/2`. This is still the real
  `Redactor.redact/1` function, the real config mechanism the module
  documents, and the real `emit_event/1` -> handler -> `Buffer` -> Postgres
  pipeline — nothing is hand-synthesized.

  **D-05 second test wording note.** The plan's task text says both the
  nil-`span_id` and the missing-`time` raw-bus events are "DROPPED." Reading
  `Scoria.Observe.Telemetry.handle_event/4`'s `default_time/1` +
  `reject_if_nil_span_id/2` shows these are two DIFFERENT fail-closed
  mechanisms: a nil `span_id` IS dropped (never reaches `insert_all`,
  D-05a), but a missing/nil `time` is DEFAULTED to `DateTime.utc_now()` and
  DOES persist — it is not dropped, and dropping it isn't necessary because
  the default makes it a valid, insertable row. This test asserts the real
  behavior of each case rather than the plan's literal (and, for the
  missing-time case, inaccurate) wording, while still proving the D-05
  guarantee that actually matters: neither malformed raw-bus event can
  crash or roll back the batch of 50 good sibling events.
  """

  use ExUnit.Case, async: false

  alias Scoria.Observe
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.Repo.Span
  alias Scoria.Repo.SpanEvent

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    buffer_name = :"event_emit_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 200]},
          id: buffer_name
        )
      )

    # Real production wiring, not a hand-synthesized handler: detach the
    # default-named handler and re-attach it onto this test's scoped buffer,
    # exactly as prompt_span_test.exs/telemetry_test.exs do.
    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)

    on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

    %{buffer: buffer_name, buffer_pid: pid}
  end

  describe "SC#1: identical redact integration proof (EVENT-02)" do
    test "a deny-listed event attribute is redacted through the identical Redactor.redact/1 call site spans use; an allow-listed attribute survives intact",
         %{buffer: buffer_name} do
      original_config = Application.get_env(:scoria, Scoria.Observe.Redactor)
      Application.put_env(:scoria, Scoria.Observe.Redactor, deny_list: ["session_id"])

      on_exit(fn ->
        case original_config do
          nil -> Application.delete_env(:scoria, Scoria.Observe.Redactor)
          config -> Application.put_env(:scoria, Scoria.Observe.Redactor, config)
        end
      end)

      span_id = Ecto.UUID.generate()

      :ok =
        Observe.emit_event(%{
          name: :prompt_rendered,
          span_id: span_id,
          time: DateTime.utc_now(),
          attributes: %{
            "session_id" => "sensitive-session-value",
            Semconv.prompt_template_ref_key() => "eval-spec-v1"
          }
        })

      :ok = Buffer.flush_now(buffer_name)

      event = Repo.get_by!(SpanEvent, span_id: span_id)

      assert event.attributes["session_id"] == "[REDACTED]"
      assert event.attributes[Semconv.prompt_template_ref_key()] == "eval-spec-v1"
    end
  end

  describe "SC#2: closed vocabulary rejected on both the direct and raw-bus paths (EVENT-02)" do
    test "direct path: emit_event/1 with an unknown name returns {:error, :unknown_event} and persists nothing",
         %{buffer: buffer_name} do
      span_id = Ecto.UUID.generate()

      assert {:error, :unknown_event} =
               Observe.emit_event(%{
                 name: :not_a_real_event,
                 span_id: span_id,
                 time: DateTime.utc_now(),
                 attributes: %{}
               })

      :ok = Buffer.flush_now(buffer_name)

      refute Repo.get_by(SpanEvent, span_id: span_id)
    end

    test "raw-bus path: a hand-synthesized :telemetry.execute bypass is rejected at the handler and fires [:scoria, :observe, :event, :rejected] (D-03b)",
         %{buffer: buffer_name} do
      :telemetry.attach(
        "event-emit-test-rejected-handler",
        [:scoria, :observe, :event, :rejected],
        fn _event, _measurements, metadata, %{test_pid: test_pid} ->
          send(test_pid, {:rejected, metadata})
        end,
        %{test_pid: self()}
      )

      on_exit(fn -> :telemetry.detach("event-emit-test-rejected-handler") end)

      span_id = Ecto.UUID.generate()

      # The ONE deliberate hand-synthesized :telemetry.execute call in this
      # suite -- the raw bus IS the attack surface SC#2 proves is closed.
      :telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{
        name: :not_a_real_event,
        span_id: span_id,
        time: DateTime.utc_now(),
        attributes: %{}
      })

      :ok = Buffer.flush_now(buffer_name)

      refute Repo.get_by(SpanEvent, span_id: span_id)
      assert_receive {:rejected, %{name: :not_a_real_event, reason: :unknown_name}}
    end
  end

  describe "SEC-01: Bounds.enforce(_, :event) proven wired end-to-end (D-06a/D-06i)" do
    test "an oversized registered attribute value is truncated and an unregistered attribute key is dropped in the persisted event row, exactly as a span attribute would be",
         %{buffer: buffer_name} do
      span_id = Ecto.UUID.generate()
      oversized_value = String.duplicate("x", 300)

      :ok =
        Observe.emit_event(%{
          name: :prompt_rendered,
          span_id: span_id,
          time: DateTime.utc_now(),
          attributes: %{
            Semconv.prompt_template_ref_key() => oversized_value,
            "not_a_registered_key" => "should be dropped"
          }
        })

      :ok = Buffer.flush_now(buffer_name)

      event = Repo.get_by!(SpanEvent, span_id: span_id)

      truncated = event.attributes[Semconv.prompt_template_ref_key()]
      assert is_binary(truncated)
      assert byte_size(truncated) < byte_size(oversized_value)
      assert String.starts_with?(truncated, String.duplicate("x", 256))
      assert String.ends_with?(truncated, "…[TRUNCATED]")

      refute Map.has_key?(event.attributes, "not_a_registered_key")
      assert event.attributes[Semconv.bounds_marker_keys().dropped] == 1
    end
  end

  describe "SC#4: orphan isolation forces the FK drop (D-01/D-05)" do
    test "50 real spans persist; the orphan emit_event/1 row EXISTS with its dangling span_id; no span exists for that id",
         %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()

      span_ids =
        for i <- 1..50 do
          span_id = Ecto.UUID.generate()

          Observe.with_tool(
            "bulk-span-#{i}",
            %{trace_id: trace_id, span_id: span_id},
            fn -> :ok end
          )

          span_id
        end

      orphan_span_id = Ecto.UUID.generate()
      refute orphan_span_id in span_ids

      :ok =
        Observe.emit_event(%{
          name: :prompt_rendered,
          span_id: orphan_span_id,
          time: DateTime.utc_now(),
          attributes: %{Semconv.prompt_template_ref_key() => "orphan-ref"}
        })

      :ok = Buffer.flush_now(buffer_name)

      assert Repo.aggregate(Span, :count) == 50

      orphan_event = Repo.get_by!(SpanEvent, span_id: orphan_span_id)
      assert orphan_event.span_id == orphan_span_id

      refute Repo.get_by(Span, id: orphan_span_id)
    end
  end

  describe "D-05 fail-closed: malformed raw-bus events cannot roll back a batch of good siblings" do
    test "a nil-span_id event is dropped; a missing-time event is defaulted and persists; 50 good sibling events land in the same batch",
         %{buffer: buffer_name} do
      good_span_ids =
        for _ <- 1..50 do
          span_id = Ecto.UUID.generate()

          :ok =
            Observe.emit_event(%{
              name: :prompt_rendered,
              span_id: span_id,
              time: DateTime.utc_now(),
              attributes: %{}
            })

          span_id
        end

      # nil span_id -- the ONE deliberate raw-bus hand-synthesized call this
      # test needs. emit_event/1's own public API always carries whatever
      # span_id the caller passes verbatim, so a nil span_id can only
      # legitimately reach the handler via this direct bus bypass.
      :telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{
        name: :prompt_rendered,
        span_id: nil,
        time: DateTime.utc_now(),
        attributes: %{}
      })

      # missing :time entirely -- Telemetry.handle_event/4's default_time/1
      # fills this with DateTime.utc_now() BEFORE Bounds, so this event is
      # NOT dropped -- it is defaulted and persists (D-05a). This is
      # distinct from the nil-span_id case above, which IS dropped.
      missing_time_span_id = Ecto.UUID.generate()

      :telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{
        name: :prompt_rendered,
        span_id: missing_time_span_id,
        attributes: %{}
      })

      # CR-01 regression: a TYPE-INVALID (not nil) `time` -- a string, as a
      # buggy internal caller or a raw-bus attacker might send instead of a
      # real `DateTime.utc_now()`. Before CR-01 this cleared `default_time/1`
      # untouched and would raise `Ecto.ChangeError` inside the shared
      # `insert_all`, poisoning this whole batch. Now it is coerced to
      # `DateTime.utc_now()` and persists, same as the missing-time case.
      invalid_time_span_id = Ecto.UUID.generate()

      :telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{
        name: :prompt_rendered,
        span_id: invalid_time_span_id,
        time: "2026-01-01",
        attributes: %{}
      })

      # CR-01 regression: a TYPE-INVALID (not nil), non-UUID-castable
      # `span_id`. Before CR-01 this cleared `reject_if_nil_span_id/2`
      # untouched and would raise `Ecto.ChangeError` inside the shared
      # `insert_all`, poisoning this whole batch. Now it is rejected
      # (dropped) at the handler seam, same as the nil-span_id case.
      :telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{
        name: :prompt_rendered,
        span_id: "not-a-uuid",
        time: DateTime.utc_now(),
        attributes: %{}
      })

      :ok = Buffer.flush_now(buffer_name)

      for span_id <- good_span_ids do
        assert Repo.get_by!(SpanEvent, span_id: span_id)
      end

      persisted_time_defaulted = Repo.get_by!(SpanEvent, span_id: missing_time_span_id)
      assert %DateTime{} = persisted_time_defaulted.time

      persisted_invalid_time = Repo.get_by!(SpanEvent, span_id: invalid_time_span_id)
      assert %DateTime{} = persisted_invalid_time.time

      # 50 good siblings + 1 defaulted-time survivor + 1 invalid-time
      # survivor = 52. The nil-span_id and non-UUID-span_id ("not-a-uuid" is
      # not even castable to :binary_id, so it cannot be looked up by
      # Repo.get_by/2 the way the other cases are) events were both dropped
      # at the handler -- asserting the exact total proves nothing extra
      # landed and the batch was not rolled back.
      assert Repo.aggregate(SpanEvent, :count) == 52
    end
  end
end

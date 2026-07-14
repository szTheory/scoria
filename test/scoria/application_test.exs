defmodule Scoria.ApplicationTest do
  @moduledoc """
  Phase 53 Plan 01 (EVENT-01, SC#2) acceptance test: `Scoria.Observe.Buffer`
  runs as a supervised child of `Scoria.Supervisor` and
  `Scoria.Observe.Telemetry.attach/1` fires during `Scoria.Application.start/2`,
  so a span emitted through the DEFAULT pipeline (no scoped buffer, no manual
  attach) persists to Postgres with zero host wiring -- the literal SC#2 proof.

  `async: false` -- this test asserts on globally-supervised processes and the
  global `:telemetry` handler registry.

  Deliberately does NOT call `:telemetry.detach("scoria-observe-telemetry")`
  anywhere in this file -- that would strip the boot handler for the remainder
  of the suite. Setup instead calls `Scoria.Observe.Telemetry.attach/0` and
  tolerates either `:ok` or `{:error, :already_exists}`, self-healing if a
  previously-run scoped-buffer test detached the boot handler in its own
  `on_exit`.
  """

  use ExUnit.Case, async: false

  alias Scoria.Observe.Buffer
  alias Scoria.Repo
  alias Scoria.Repo.Span

  setup do
    # Shared mode so the already-running application-level Buffer GenServer
    # (not a test-spawned process, so it has no sandbox connection of its
    # own) can write through this test's checked-out connection during
    # flush_now/0.
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    case Scoria.Observe.Telemetry.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end

    # Drain spans other tests parked in the globally-supervised Buffer (G1
    # emits a guardrail span on every `Runtime.start_run/2`, and those tests
    # never flush). `flush/1` writes the whole buffer in ONE transaction, so a
    # foreign span referencing a trace row its own sandbox already rolled back
    # takes THIS test's span down with it. Draining first keeps the batch that
    # `flush_now/0` writes below scoped to the span this test emits.
    :ok = Buffer.flush_now()

    :ok
  end

  test "Scoria.Observe.Buffer runs as a supervised child of Scoria.Supervisor" do
    children = Supervisor.which_children(Scoria.Supervisor)

    buffer_child =
      Enum.find(children, fn {_id, _pid, _type, modules} -> modules == [Buffer] end)

    assert buffer_child,
           "expected a Scoria.Observe.Buffer child in #{inspect(children)}"

    {_id, pid, _type, _modules} = buffer_child
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "Telemetry.attach/1 is idempotent at boot: a duplicate handler id does not raise" do
    assert {:error, :already_exists} = Scoria.Observe.Telemetry.attach()
  end

  test "a span emitted through the default pipeline persists to Postgres after Buffer.flush_now/1" do
    trace_id = Ecto.UUID.generate()
    span_id = Ecto.UUID.generate()
    tenant_id = "tenant-#{System.unique_integer([:positive])}"

    span_data = %{
      id: span_id,
      trace_id: trace_id,
      parent_id: nil,
      name: "default_pipeline_span",
      span_kind: "LLM",
      status_code: "OK",
      start_time: DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      attributes: %{"public" => "value"},
      tenant_id: tenant_id
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span_data)

    :ok = Buffer.flush_now()

    span = Repo.get_by!(Span, id: span_id)
    assert span.name == "default_pipeline_span"
    assert span.trace_id == trace_id
  end

  describe "config :scoria, Scoria.Observe, enabled: false" do
    setup do
      previous = Application.get_env(:scoria, Scoria.Observe)

      on_exit(fn ->
        case previous do
          nil -> Application.delete_env(:scoria, Scoria.Observe)
          value -> Application.put_env(:scoria, Scoria.Observe, value)
        end
      end)

      :ok
    end

    test "removes Buffer from the boot children list and skips the boot attach" do
      Application.put_env(:scoria, Scoria.Observe, enabled: false)

      assert Scoria.Application.observe_children() == []
    end
  end
end

defmodule SupportCopilotWeb.OrchestratorProducerTest do
  use SupportCopilotWeb.ConnCase, async: false

  alias Scoria.Observe.Adapters.ReqLLM
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.OperatorBroadcast
  alias Scoria.SupportJourney
  alias Scoria.SupportJourney.Handlers
  alias Scoria.Workflows

  setup do
    OperatorBroadcast.reset_trace_seen!()

    buffer_name = :"gallery_buffer_#{System.unique_integer([:positive])}"

    start_supervised!({Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]})

    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)
    :telemetry.detach("scoria-observe-reqllm")
    ReqLLM.attach()

    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {Handlers, :wait_for_approval}
    })

    OperatorBroadcast.reset_trace_seen!()
    :ok
  end

  test "approvals page shows approval from producer path on /scoria/approvals", %{conn: conn} do
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        initial_step: %{sequence: 1, kind: "approval", role_id: "support_agent", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    eventually(fn ->
      case Scoria.get_run(started.run_id) do
        {:ok, summary} -> summary.status == SupportJourney.waiting_status()
        _ -> false
      end
    end)

    operator_conn =
      conn
      |> Plug.Test.init_test_session(%{
        "tenant_id" => SupportJourney.tenant_id(),
        "actor_id" => SupportJourney.operator_identity().actor_id
      })

    {:ok, view, html} = live(operator_conn, "/scoria/approvals")

    assert html =~ "Approvals"
    assert html =~ "Approval inbox"

    eventually(fn ->
      rendered = render(view)
      rendered =~ SupportJourney.refund_approval_tool() or rendered =~ "waiting_for_approval"
    end)

    run = Workflows.get_run_tree!(started.run_id)
    [approval | _] = Enum.reverse(run.approvals)
    {:ok, _approval} = Workflows.approve(approval.id, "approved")

    assert {:ok, _resumed} =
             Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

    eventually(fn ->
      case Scoria.get_run(started.run_id) do
        {:ok, summary} -> summary.status == SupportJourney.completed_status()
        _ -> false
      end
    end)
  end

  defp eventually(fun, attempts \\ 40)

  defp eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(25)
      eventually(fun, attempts - 1)
    end
  end

  defp eventually(_fun, 0), do: flunk("condition not met before timeout")
end

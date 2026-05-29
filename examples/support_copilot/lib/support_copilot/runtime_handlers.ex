defmodule SupportCopilot.RuntimeHandlers do
  @moduledoc false

  alias Scoria.SupportJourney

  def wait_for_approval(_step, run) do
    {:waiting_for_approval,
     %{
       tool_name: SupportJourney.refund_approval_tool(),
       arguments: %{"ticket_id" => SupportJourney.ticket_fixture()["id"]},
       reason: "Refund requires operator approval",
       actor_id: SupportJourney.operator_identity().actor_id,
       tenant_id: SupportJourney.tenant_id(),
       trace_id: "trace-#{run.id}"
     }}
  end

  def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
end

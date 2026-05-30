defmodule SupportCopilotWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      @endpoint SupportCopilotWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    end

    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {Scoria.SupportJourney.Handlers, :wait_for_approval},
      "tool" => {Scoria.SupportJourney.Handlers, :lookup_support_ticket},
      "answer" => {Scoria.SupportJourney.Handlers, :faq_answer}
    })

    start_supervised!(Scoria.Workflows.Reconciler)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

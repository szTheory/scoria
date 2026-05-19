defmodule ScoriaWeb.Router do
  @moduledoc """
  Provides the scoria_dashboard macro to mount the Scoria LiveView dashboard
  in a host Phoenix application.
  """

  defmacro scoria_dashboard(path, _opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]
        import Phoenix.Router, only: [get: 3]

        get("/connectors/:connector_id/auth/start", ScoriaWeb.ConnectorAuthController, :start)

        get(
          "/connectors/:connector_id/auth/callback",
          ScoriaWeb.ConnectorAuthController,
          :callback
        )

        live_session :scoria_dashboard do
          live("/", ScoriaWeb.OrchestratorLive, :index)
          live("/workflows/:id", ScoriaWeb.WorkflowLive.Show, :show)
          live("/prompts", ScoriaWeb.PromptLive.Index, :index)
          live("/prompts/:id/release", ScoriaWeb.PromptLive.ReleaseWorkbenchLive, :index)
        end
      end
    end
  end
end

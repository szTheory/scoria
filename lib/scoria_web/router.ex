defmodule ScoriaWeb.Router do
  @moduledoc """
  Provides the scoria_dashboard macro to mount the Scoria LiveView dashboard
  in a host Phoenix application.
  """

  defmacro scoria_mcp(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.Router, only: [get: 4, post: 3]

        opts_assigns = %{mcp_tools: Keyword.get(opts, :tools, [])}

        get("/sse", ScoriaWeb.MCPController, :sse, assigns: opts_assigns)
        post("/messages", ScoriaWeb.MCPController, :messages)
      end
    end
  end

  defmacro scoria_dashboard(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]
        import Phoenix.Router, only: [get: 3]

        host_on_mount_hooks = List.wrap(Keyword.get(opts, :on_mount, []))
        scope_resolver = Keyword.get(opts, :scope_resolver, :default)

        dashboard_scope_hook =
          case scope_resolver do
            :default -> ScoriaWeb.DashboardScope
            resolver -> {ScoriaWeb.DashboardScope, resolver}
          end

        on_mount_hooks =
          host_on_mount_hooks ++ [dashboard_scope_hook, ScoriaWeb.DashboardNav]

        get("/connectors/:connector_id/auth/start", ScoriaWeb.ConnectorAuthController, :start)

        get(
          "/connectors/:connector_id/auth/callback",
          ScoriaWeb.ConnectorAuthController,
          :callback
        )

        live_session :scoria_dashboard,
          root_layout: {ScoriaWeb.Layouts, :root},
          on_mount: on_mount_hooks do
          live("/", ScoriaWeb.OrchestratorLive, :index)
          live("/approvals", ScoriaWeb.ApprovalsLive.Index, :index)
          live("/reviews", ScoriaWeb.ReviewQueueLive, :index)
          live("/datasets", ScoriaWeb.DatasetLive.Index, :index)
          live("/workflows", ScoriaWeb.WorkflowLive.Index, :index)
          live("/workflows/:id", ScoriaWeb.WorkflowLive.Show, :show)
          live("/connectors", ScoriaWeb.ConnectorsLive.Index, :index)
          live("/incidents", ScoriaWeb.IncidentsLive.Index, :index)
          live("/incidents/:id", ScoriaWeb.IncidentsLive.Show, :show)
          live("/eval_specs", ScoriaWeb.EvalSpecLive.Index, :index)
          live("/prompts", ScoriaWeb.PromptLive.Index, :index)
          live("/prompts/:id/release", ScoriaWeb.PromptLive.ReleaseWorkbenchLive, :index)
          live("/coming/:screen", ScoriaWeb.ComingSoonLive, :show)
        end
      end
    end
  end
end

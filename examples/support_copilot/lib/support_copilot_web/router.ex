defmodule SupportCopilotWeb.Router do
  use SupportCopilotWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {SupportCopilotWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:assign_support_identity)
  end

  scope "/" do
    pipe_through(:browser)
    live("/", SupportCopilotWeb.ChatLive, :index)
  end

  # scoria:router:start
  import ScoriaWeb.Router

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end

  # scoria:router:end

  defp assign_support_identity(conn, _opts) do
    identity = Scoria.SupportJourney.runtime_identity()

    conn
    |> assign(:current_user_id, identity.actor_id)
    |> assign(:current_account_id, identity.tenant_id)
    |> put_session(:assistant_session_id, identity.session_id)
  end
end

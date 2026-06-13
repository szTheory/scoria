defmodule ScoriaWeb.ConnectorDetailDrawerComponent do
  use Phoenix.Component

  import ScoriaWeb.UI, only: [evidence_rows: 1, evidence_section: 1]

  attr(:drawer, :map, default: nil)

  def render(assigns) do
    ~H"""
    <.evidence_section :if={@drawer} title="Connector detail" description={@drawer.endpoint_url}>
      <.evidence_rows rows={[
        {"Status", "#{@drawer.status} / #{@drawer.health_state}"},
        {"Refresh", @drawer.last_refresh_status},
        {"Transport", @drawer.transport_kind},
        {"Auth mode", @drawer.auth_mode}
      ]} />
    </.evidence_section>
    """
  end
end

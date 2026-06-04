defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [notebook: 1]

  attr :evidence, :map, required: true
  attr :selected_tab, :string, default: "remote_invocation"
  attr :on_tab_change, :string, default: nil

  def render(assigns) do
    assigns =
      assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

    ~H"""
    <.notebook
      id="remote-invocation-notebook"
      title="Remote invocation evidence"
      eyebrow="Remote evidence notebook"
      selected_tab={@selected_tab}
      on_tab_change={@on_tab_change}
    >
      <:tab key="remote_invocation" label="Remote">
        <div class="space-y-3">
          <article
            :for={approval <- @approvals}
            class="scoria-panel scoria-panel--raised"
            style="padding: var(--scoria-space-3) var(--scoria-space-4); font-size: var(--scoria-fs-body);"
          >
            <div class="flex flex-wrap items-center gap-2">
              <span style="font-weight: 600; color: var(--scoria-text);"><%= approval_value(approval, :tool_name) %></span>
              <span style="font-family: var(--scoria-font-mono); font-size: var(--scoria-fs-badge); color: var(--scoria-text-muted);"><%= approval_value(approval, :status) %></span>
            </div>
            <p style="margin-top: var(--scoria-space-2); font-size: var(--scoria-fs-badge); color: var(--scoria-text-muted);">
              Approval ID: <span style="font-family: var(--scoria-font-mono);"><%= approval_value(approval, :id) %></span>
            </p>
          </article>
        </div>
      </:tab>
    </.notebook>
    """
  end

  defp approval_value(approval, key) do
    # WR-06: use explicit key presence rather than `||` so a present-but-falsy
    # value (nil/false) is rendered as itself instead of being collapsed into the
    # literal "unknown", which is indistinguishable from a genuinely absent key.
    cond do
      Map.has_key?(approval, key) -> Map.get(approval, key)
      Map.has_key?(approval, to_string(key)) -> Map.get(approval, to_string(key))
      true -> "unknown"
    end
  end
end

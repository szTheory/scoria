defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:evidence, :map, required: true)
  attr(:selected_tab, :string, default: "remote_invocation")
  attr(:on_tab_change, :string, default: nil)

  def render(assigns) do
    assigns =
      assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

    ~H"""
    <.notebook
      id="remote-invocation-notebook"
      title="Remote invocation trace"
      eyebrow="Remote trace notebook"
      selected_tab={@selected_tab}
      on_tab_change={@on_tab_change}
      empty={@approvals == []}
    >
      <:empty_slot>
        <.evidence_empty title="No remote approvals recorded">
          No remote approvals recorded.
        </.evidence_empty>
      </:empty_slot>

      <:tab key="remote_invocation" label="Remote">
        <div class="space-y-3">
          <.evidence_section
            :for={approval <- @approvals}
            title={to_string(approval_value(approval, :tool_name))}
            badge={to_string(approval_value(approval, :status))}
            tone={tone(approval_value(approval, :status))}
          >
            <.evidence_rows
              rows={[
                {"Status", approval_value(approval, :status)},
                {"Approval ID", approval_value(approval, :id)}
              ]}
            />
          </.evidence_section>
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

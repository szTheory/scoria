defmodule ScoriaWeb.ApprovalInboxComponent do
  use Phoenix.Component

  alias ScoriaWeb.ApprovalCopy

  import ScoriaWeb.UI

  attr(:approvals, :list, required: true)
  attr(:highlight_approval_id, :string, default: nil)
  attr(:select_event, :string, default: nil)
  attr(:scoria_base, :string, default: "")

  def render(assigns) do
    ~H"""
    <.panel flush={true}>
      <.table
        id="approvals"
        aria-label="Pending approval queue"
        rows={@approvals}
      >
        <:col :let={approval} label="Request">
          <span data-highlight={ApprovalCopy.field(approval, :id) == @highlight_approval_id && "true"}>
            <span class="font-semibold"><%= ApprovalCopy.title(approval) %></span>
            <.badge
              :if={ApprovalCopy.field(approval, :id) == @highlight_approval_id}
              tone={:warn}
              label="New"
              dot={false}
              class="ml-2"
            />
          </span>
          <p class="scoria-table__cell-note"><%= ApprovalCopy.target(approval) %></p>
        </:col>
        <:col :let={approval} label="Policy">
          <span><%= ApprovalCopy.detail(approval) %></span>
          <p class="scoria-table__cell-note"><%= ApprovalCopy.impact(approval) %></p>
        </:col>
        <:col :let={approval} label="Requested by">
          <span><%= ApprovalCopy.requested_by(approval) %></span>
          <p :if={ApprovalCopy.context_detail(approval)} class="scoria-table__cell-note"><%= ApprovalCopy.context_detail(approval) %></p>
        </:col>
        <:col :let={approval} label="Waiting">
          <.time at={ApprovalCopy.field(approval, :inserted_at)} mode={:elapsed} />
        </:col>
        <:col :let={approval} label="Run">
          <.run_link approval={approval} scoria_base={@scoria_base} />
        </:col>
        <:action :let={approval}>
          <button
            type="button"
            phx-click={@select_event}
            phx-value-id={@select_event && ApprovalCopy.field(approval, :id)}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Inspect approval
          </button>
        </:action>
        <:mobile_summary :let={approval}>
          <div class="scoria-mobile-summary">
            <div class="scoria-mobile-summary__label">
              <%= ApprovalCopy.title(approval) %>
              <p class="scoria-table__cell-note"><%= ApprovalCopy.target(approval) %></p>
            </div>
            <div class="scoria-mobile-summary__status">
              <.badge tone={tone(ApprovalCopy.field(approval, :status))} label={status_label(ApprovalCopy.field(approval, :status))} />
            </div>
            <div class="scoria-mobile-summary__meta">
              <.time at={ApprovalCopy.field(approval, :inserted_at)} mode={:elapsed} />
              · <%= ApprovalCopy.requested_by(approval) %>
            </div>
            <div class="scoria-mobile-summary__action">
              <button
                type="button"
                phx-click={@select_event}
                phx-value-id={@select_event && ApprovalCopy.field(approval, :id)}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Inspect approval
              </button>
            </div>
          </div>
        </:mobile_summary>
        <:empty>
          <.empty_state title="No approvals waiting">
            Requests appear here when Scoria needs a person to approve or deny an action.
          </.empty_state>
        </:empty>
      </.table>
    </.panel>
    """
  end

  attr(:approval, :map, required: true)
  attr(:scoria_base, :string, default: "")

  defp run_link(assigns) do
    run_id = ApprovalCopy.field(assigns.approval, :workflow_run_id)

    assigns =
      assigns
      |> assign(:run_id, run_id)
      |> assign(:run_href, run_href(assigns.scoria_base, run_id))
      |> assign(:run_label, ApprovalCopy.short_id(run_id))

    ~H"""
    <a
      :if={@run_id}
      href={@run_href}
      class="scoria-link"
      title={"Workflow run #{@run_id}"}
      aria-label={"Open run #{@run_id}"}
    >
      Run <span class="font-mono"><%= @run_label %></span>
    </a>
    <span :if={!@run_id} class="scoria-table__cell-note">Not recorded</span>
    """
  end

  defp run_href(_base, nil), do: nil
  defp run_href(base, run_id), do: "#{base}/workflows/#{run_id}"
end

defmodule ScoriaWeb.ApprovalInboxComponent do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias ScoriaWeb.ApprovalCopy

  import ScoriaWeb.UI

  attr(:approvals, :list, required: true)
  attr(:highlight_approval_id, :string, default: nil)
  attr(:select_event, :string, default: nil)
  attr(:scoria_base, :string, default: "")
  # D-17: same table/1, two scopes — "pending" (default) and "decided". D-18: the
  # Decided scope swaps the Waiting column for a Decision column and never emits
  # a decision affordance; the row action reads "View decision".
  attr(:scope, :string, default: "pending")
  attr(:outcome, :string, default: "all")
  attr(:pending_href, :string, default: "/approvals")
  attr(:decided_href, :string, default: "/approvals?scope=decided")
  attr(:has_more, :boolean, default: false)
  # D-20: approval id -> audit-sourced "Approved by {actor} · {time}"-style
  # receipt text, batch-loaded by the parent LiveView (never per-row queried
  # here). Missing entries render nothing extra beyond the outcome badge.
  attr(:decision_receipts, :map, default: %{})

  def render(assigns) do
    ~H"""
    <.panel flush={true}>
      <.table
        id="approvals"
        aria-label={table_aria_label(@scope)}
        rows={@approvals}
      >
        <:filter>
          <div class="flex items-center gap-2 flex-wrap" role="tablist" aria-label="Approval scope">
            <.link
              patch={@pending_href}
              role="tab"
              aria-selected={to_string(@scope == "pending")}
              class={[
                "scoria-button scoria-button--sm",
                (@scope == "pending" && "scoria-button--primary") || "scoria-button--ghost"
              ]}
            >
              Pending
            </.link>
            <.link
              patch={@decided_href}
              role="tab"
              aria-selected={to_string(@scope == "decided")}
              class={[
                "scoria-button scoria-button--sm",
                (@scope == "decided" && "scoria-button--primary") || "scoria-button--ghost"
              ]}
            >
              Decided
            </.link>
          </div>

          <form :if={@scope == "decided"} phx-change="change_outcome" class="mt-3">
            <.field id="approval-outcome-filter" label="Outcome">
              <select id="approval-outcome-filter" name="outcome" class="scoria-input">
                <option value="all" selected={@outcome == "all"}>All</option>
                <option value="approved" selected={@outcome == "approved"}>Approved</option>
                <option value="denied" selected={@outcome == "denied"}>Denied</option>
                <option value="expired" selected={@outcome == "expired"}>Expired</option>
              </select>
            </.field>
          </form>
        </:filter>

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
        <:col :if={@scope == "pending"} :let={approval} label="Waiting">
          <.time at={ApprovalCopy.field(approval, :inserted_at)} mode={:elapsed} />
        </:col>
        <:col :if={@scope == "decided"} :let={approval} label="Decision">
          <.badge
            tone={tone(ApprovalCopy.field(approval, :status))}
            label={ApprovalCopy.decision_outcome(approval)}
          />
          <p class="scoria-table__cell-note">
            {Map.get(@decision_receipts, ApprovalCopy.field(approval, :id), "Decided · time unavailable")}
          </p>
        </:col>
        <:col :let={approval} label="Run">
          <.run_link approval={approval} scoria_base={@scoria_base} />
        </:col>
        <:action :let={approval}>
          <button
            type="button"
            phx-click={@select_event && (JS.push_focus() |> JS.push(@select_event))}
            phx-value-id={@select_event && ApprovalCopy.field(approval, :id)}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            {action_label(@scope)}
          </button>
        </:action>
        <:mobile_summary :let={approval}>
          <div class="scoria-mobile-summary">
            <div class="scoria-mobile-summary__label">
              <%= ApprovalCopy.title(approval) %>
              <p class="scoria-table__cell-note"><%= ApprovalCopy.target(approval) %></p>
            </div>
            <div class="scoria-mobile-summary__status">
              <.badge tone={tone(ApprovalCopy.field(approval, :status))} label={mobile_status_label(@scope, approval)} />
            </div>
            <div class="scoria-mobile-summary__meta">
              <.time :if={@scope == "pending"} at={ApprovalCopy.field(approval, :inserted_at)} mode={:elapsed} />
              <span :if={@scope == "pending"}>·</span>
              <%= ApprovalCopy.requested_by(approval) %>
            </div>
            <div class="scoria-mobile-summary__action">
              <button
                type="button"
                phx-click={@select_event && (JS.push_focus() |> JS.push(@select_event))}
                phx-value-id={@select_event && ApprovalCopy.field(approval, :id)}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                {action_label(@scope)}
              </button>
            </div>
          </div>
        </:mobile_summary>
        <:empty>
          <.empty_state title={empty_title(@scope)}>
            {empty_body(@scope)}
          </.empty_state>
        </:empty>
      </.table>

      <div :if={@scope == "decided" and @has_more} class="mt-3">
        <button type="button" phx-click="load_more_decided" class="scoria-button scoria-button--ghost scoria-button--sm">
          Load more
        </button>
      </div>
    </.panel>
    """
  end

  defp table_aria_label("decided"), do: "Decided approval history"
  defp table_aria_label(_scope), do: "Pending approval queue"

  defp action_label("decided"), do: "View decision"
  defp action_label(_scope), do: "Inspect approval"

  defp mobile_status_label("decided", approval), do: ApprovalCopy.decision_outcome(approval)
  defp mobile_status_label(_scope, approval), do: status_label(ApprovalCopy.field(approval, :status))

  defp empty_title("decided"), do: "No decided approvals yet"
  defp empty_title(_scope), do: "No approvals waiting"

  defp empty_body("decided"),
    do: "Approved, denied, and expired requests will appear here once a decision is recorded."

  defp empty_body(_scope),
    do: "Requests appear here when Scoria needs a person to approve or deny an action."

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

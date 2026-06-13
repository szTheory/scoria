defmodule ScoriaWeb.ReviewQueueLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias Scoria.Eval

  @impl true
  def mount(params, _session, socket) do
    filters = %{
      "review_status" => Map.get(params, "review_status", "pending"),
      "severity" => Map.get(params, "severity", ""),
      "promotion_state" => Map.get(params, "promotion_state", "")
    }

    {:ok,
     socket
     |> assign(:page_title, "Review Queue")
     |> assign(:filters, filters)
     |> assign(:notice, nil)
     |> assign(:selected_candidate_id, Map.get(params, "review_candidate_id"))
     |> refresh_queue()}
  end

  @impl true
  def handle_event("select_candidate", %{"id" => candidate_id}, socket) do
    {:noreply, assign(socket, :selected_candidate_id, candidate_id) |> refresh_selection()}
  end

  @impl true
  def handle_event("change_filters", %{"filters" => params}, socket) do
    {:noreply, socket |> assign(:filters, params) |> refresh_queue()}
  end

  @impl true
  def handle_event("dismiss_candidate", _params, socket) do
    with %{} = candidate <- socket.assigns.selected_candidate,
         {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
      {:noreply,
       socket
       |> assign(:notice, "Candidate dismissed")
       |> assign(:selected_candidate, updated)
       |> assign(:selected_candidate_id, nil)
       |> refresh_queue()}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen px-6 py-8">
      <div class="mx-auto max-w-7xl">
        <header class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-3xl font-semibold">Review Queue</h1>
            <p class="mt-2 text-sm">Review flagged traces before they become datasets, baselines, or dismissed noise.</p>
          </div>
          <a href={home_path(assigns[:scoria_base] || "")} class="scoria-button scoria-button--ghost scoria-button--sm">Back to dashboard</a>
        </header>

        <section class="mb-6 grid gap-4 md:grid-cols-4">
          <.metric label="Flagged items" value={to_string(@summary.total_flagged)} />
          <.metric label="Low quality" value={to_string(@summary.low_quality_count)} />
          <.metric label="Policy triggered" value={to_string(@summary.policy_triggered_count)} />
          <.metric label="Promotion candidate" value={to_string(@summary.promotion_candidate_count)} />
        </section>

        <%= if @notice do %>
          <section class="mb-6 scoria-panel text-sm">
            <%= @notice %>
          </section>
        <% end %>

        <div class="scoria-page-split">
          <.panel>
            <:title>Flagged traces</:title>
            <.table id="review-queue" rows={@queue_rows} density={:compact}>
              <:filter>
                <form phx-change="change_filters" class="grid gap-3 md:grid-cols-3">
                  <.field id="review-status-filter" label="Review state">
                    <select id="review-status-filter" name="filters[review_status]" class="scoria-input">
                      <option value="pending" selected={@filters["review_status"] == "pending"}>needs review</option>
                      <option value="" selected={@filters["review_status"] in [nil, ""]}>all active</option>
                      <option value="in_review" selected={@filters["review_status"] == "in_review"}>in review</option>
                    </select>
                  </.field>
                  <.field id="severity-filter" label="Severity">
                    <select id="severity-filter" name="filters[severity]" class="scoria-input">
                      <option value="" selected={@filters["severity"] in [nil, ""]}>all severities</option>
                      <option value="policy_triggered" selected={@filters["severity"] == "policy_triggered"}>policy triggered</option>
                      <option value="low_quality" selected={@filters["severity"] == "low_quality"}>low quality</option>
                      <option value="promotion_candidate" selected={@filters["severity"] == "promotion_candidate"}>promotion candidate</option>
                    </select>
                  </.field>
                  <.field id="promotion-state-filter" label="Promotion state">
                    <select id="promotion-state-filter" name="filters[promotion_state]" class="scoria-input">
                      <option value="" selected={@filters["promotion_state"] in [nil, ""]}>all states</option>
                      <option value="promotion_candidate" selected={@filters["promotion_state"] == "promotion_candidate"}>promotion candidate</option>
                      <option value="approval_requested" selected={@filters["promotion_state"] == "approval_requested"}>approval requested</option>
                    </select>
                  </.field>
                </form>
              </:filter>
              <:col :let={row} label="Candidate">
                <p class="font-semibold"><%= row.rationale %></p>
                <p class="mt-1 text-xs">
                  trace <span class="font-mono"><%= row.trace_id %></span> · run <span class="font-mono"><%= row.workflow_run_id %></span>
                </p>
              </:col>
              <:col :let={row} label="Severity">
                <.badge tone={tone(row.severity)} label={status_label(row.severity)} />
              </:col>
              <:col :let={row} label="Score">
                <.badge tone={tone(row.score_status)} label={status_label(row.score_status || row.status)} />
              </:col>
              <:col :let={row} label="Sample">
                <%= row.sample_reason || row.status %>
              </:col>
              <:col :let={row} label="Promotion">
                <%= promotion_label(row) %>
              </:col>
              <:action :let={row}>
                <.button
                  type="button"
                  variant={if(@selected_candidate_id == row.id, do: :primary, else: :ghost)}
                  size={:sm}
                  phx-click="select_candidate"
                  phx-value-id={row.id}
                  aria-current={@selected_candidate_id == row.id && "true"}
                >
                  <%= if @selected_candidate_id == row.id, do: "Selected", else: "Select" %>
                </.button>
              </:action>
              <:mobile_summary :let={row}>
                <div class="scoria-mobile-summary">
                  <div class="scoria-mobile-summary__label">
                    <%= row.rationale %>
                  </div>
                  <div class="scoria-mobile-summary__status">
                    <.badge tone={tone(row.severity)} label={status_label(row.severity)} />
                  </div>
                  <div class="scoria-mobile-summary__meta">
                    <%= promotion_label(row) %>
                  </div>
                  <div class="scoria-mobile-summary__action">
                    <a
                      href={review_run_path(row, assigns[:scoria_base] || "")}
                      class="scoria-button scoria-button--ghost scoria-button--sm"
                    >
                      Open run
                    </a>
                  </div>
                </div>
              </:mobile_summary>
              <:empty>
                <.empty_state title="No review candidates match this view">
                  Adjust your filters or check back when data is available.
                </.empty_state>
              </:empty>
            </.table>
          </.panel>

          <.panel>
            <%= if @selected_candidate do %>
              <p class="scoria-eyebrow">Detail rail</p>
              <h2 class="mt-2 text-2xl font-semibold"><%= @selected_candidate.rationale %></h2>
              <div class="mt-4 flex flex-wrap gap-2 text-xs">
                <.badge tone={tone(@selected_candidate.severity)} label={status_label(@selected_candidate.severity)} />
                <.badge tone={tone(@selected_candidate.status)} label={status_label(@selected_candidate.status)} />
                <.badge tone={:neutral} label={"score #{@selected_candidate.score || "n/a"}"} />
              </div>

              <dl class="mt-6 grid gap-4 text-sm">
                <div class="scoria-panel">
                  <dt class="scoria-eyebrow">Scoring provenance</dt>
                  <dd class="mt-2"><%= @selected_candidate.scorer_kind %> · <%= @selected_candidate.scorer_version %></dd>
                </div>
                <div class="scoria-panel">
                  <dt class="scoria-eyebrow">Sampling provenance</dt>
                  <dd class="mt-2 font-mono text-xs"><%= inspect(@selected_candidate.sampling_provenance) %></dd>
                </div>
              </dl>

              <div class="mt-6 flex flex-wrap gap-3">
                <a href={review_run_path(@selected_candidate, assigns[:scoria_base] || "")} class="scoria-button scoria-button--primary scoria-button--sm">Open run</a>
                <a href={review_runtime_path(@selected_candidate, assigns[:scoria_base] || "")} class="scoria-button scoria-button--ghost scoria-button--sm">View runtime context</a>
              </div>

              <div class="mt-6 flex flex-wrap gap-3">
                <.button type="button" phx-click="dismiss_candidate" phx-disable-with="Dismissing candidate..." variant={:danger} size={:sm}>
                  Dismiss candidate
                </.button>
                <a href={review_dataset_builder_path(@selected_candidate, assigns[:scoria_base] || "")} class="scoria-button scoria-button--primary scoria-button--sm">
                  Promote in Dataset Builder
                </a>
                <a href={review_dataset_builder_path(@selected_candidate, assigns[:scoria_base] || "", "baseline")} class="scoria-button scoria-button--ghost scoria-button--sm">
                  Request baseline approval in Dataset Builder
                </a>
              </div>

              <%= if @selected_candidate.dataset_ref do %>
                <p class="mt-4 text-sm">
                  Promoted to <span class="font-semibold"><%= @selected_candidate.dataset_ref["dataset_name"] %></span>
                  <span class="font-mono">v<%= @selected_candidate.dataset_ref["dataset_version"] %></span>.
                </p>
              <% end %>
            <% else %>
              <div class="scoria-empty">
                Select a queue row to inspect its evidence and actions.
              </div>
            <% end %>
          </.panel>
        </div>
      </div>
    </div>
    """
  end

  defp refresh_queue(socket, reset_selection \\ true) do
    rows = Eval.list_review_queue(socket.assigns.filters)
    summary = Eval.summarize_review_queue(socket.assigns.filters)

    selected_candidate_id =
      if reset_selection do
        socket.assigns.selected_candidate_id || (List.first(rows) && List.first(rows).id)
      else
        socket.assigns.selected_candidate_id
      end

    socket
    |> assign(:queue_rows, rows)
    |> assign(:summary, summary)
    |> assign(:selected_candidate_id, selected_candidate_id)
    |> refresh_selection()
  end

  defp refresh_selection(socket) do
    assign(
      socket,
      :selected_candidate,
      Eval.get_review_candidate(socket.assigns.selected_candidate_id)
    )
  end

  defp review_run_path(candidate, base) do
    query =
      URI.encode_query([
        {"review_candidate_id", candidate.id},
        {"from", review_origin(candidate)}
      ])

    "#{base}/workflows/#{candidate.workflow_run_id}?#{query}"
  end

  defp review_runtime_path(candidate, base) do
    query_params =
      [
        runtime_query_param(candidate),
        {"review_candidate_id", candidate.id},
        {"from", review_origin(candidate)}
      ]
      |> Enum.reject(&is_nil/1)

    "#{home_path(base)}?#{URI.encode_query(query_params)}"
  end

  defp runtime_query_param(%{runtime_id: nil}), do: nil
  defp runtime_query_param(%{runtime_id: runtime_id}), do: {"runtime", runtime_id}

  defp review_dataset_builder_path(candidate, base, intent \\ "promotion") do
    query =
      URI.encode_query([
        {"promote", "review"},
        {"review_candidate_id", candidate.id},
        {"intent", intent},
        {"from", review_origin(candidate)}
      ])

    "#{base}/datasets?#{query}"
  end

  defp promotion_label(%{promotion_state: state}) when is_binary(state), do: status_label(state)
  defp promotion_label(%{status: status}), do: status_label(status)

  defp review_origin(candidate), do: "review:#{candidate.id}"
  defp home_path(""), do: "/"
  defp home_path(base), do: base
end

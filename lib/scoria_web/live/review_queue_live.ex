defmodule ScoriaWeb.ReviewQueueLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias Scoria.Eval
  alias ScoriaWeb.ReviewCopy

  @default_filters %{"review_status" => "pending", "severity" => "", "promotion_state" => ""}
  @review_statuses ~w(pending in_review) ++ [""]
  @severities ~w(policy_triggered low_quality promotion_candidate) ++ [""]
  @promotion_states ~w(promotion_candidate approval_requested) ++ [""]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Review Queue")
     |> assign(:notice, nil)
     |> assign(:filters, @default_filters)
     |> assign(:selected_candidate_id, nil)
     |> assign(:load_error, false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    selected_candidate_id =
      Map.get(params, "review_candidate_id") || socket.assigns.selected_candidate_id

    {:noreply,
     socket
     |> assign(:filters, filters_from_params(params))
     |> assign(:selected_candidate_id, selected_candidate_id)
     |> refresh_queue()}
  end

  @impl true
  def handle_event("select_candidate", %{"id" => candidate_id}, socket) do
    {:noreply, assign(socket, :selected_candidate_id, candidate_id) |> refresh_selection()}
  end

  @impl true
  def handle_event("change_filters", %{"filters" => params}, socket) do
    {:noreply,
     push_patch(socket, to: review_queue_path(socket.assigns[:scoria_base] || "", params))}
  end

  @impl true
  def handle_event("retry_load", _params, socket) do
    {:noreply, refresh_queue(socket)}
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
    else
      _ ->
        {:noreply,
         assign(socket, :notice, "Could not dismiss this candidate. Refresh and try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <.page_header title="Review Queue">
        <:summary>Review flagged traces before they become datasets, baselines, or dismissed noise.</:summary>
        <:actions>
          <a
            href={home_path(assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Back to dashboard
          </a>
        </:actions>
      </.page_header>

      <.overview_stats label="Review queue summary" class="mb-6">
        <:stat label="Needs review" value={review_count(@summary.total_flagged, "flagged item")} tone={if(@summary.total_flagged > 0, do: :info, else: :pass)}>
          Traces sampled from production that still need a human decision.
        </:stat>
        <:stat label="Quality risk" value={review_count(@summary.low_quality_count, "low-quality item")} tone={if(@summary.low_quality_count > 0, do: :warn, else: :neutral)}>
          Candidates where the scorer found a quality regression or weak answer.
        </:stat>
        <:stat label="Policy risk" value={review_count(@summary.policy_triggered_count, "policy-triggered item")} tone={if(@summary.policy_triggered_count > 0, do: :fail, else: :neutral)}>
          Candidates that touched a policy rule and need closer inspection.
        </:stat>
        <:stat label="Ready to promote" value={review_count(@summary.promotion_candidate_count, "promotion candidate")} tone={if(@summary.promotion_candidate_count > 0, do: :trace, else: :neutral)}>
          Strong examples that can become dataset evidence or a baseline request.
        </:stat>
      </.overview_stats>

      <%= if @notice do %>
        <section class="mb-6 scoria-panel text-sm">
          <%= @notice %>
        </section>
      <% end %>

      <div class="scoria-page-split">
        <.panel :if={@load_error}>
          <:title>Flagged traces</:title>
          <div class="scoria-flash scoria-flash--fail" role="alert">
            Review queue could not be loaded right now.
          </div>
          <div class="mt-4">
            <.button type="button" phx-click="retry_load" variant={:ghost} size={:sm}>Retry</.button>
          </div>
        </.panel>

        <.panel :if={!@load_error}>
          <:title>Flagged traces</:title>
          <.table id="review-queue" rows={@queue_rows}>
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
              <%= row.sample_reason || ReviewCopy.status_label(row.status) %>
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
    """
  end

  defp refresh_queue(socket, reset_selection \\ true) do
    case load_queue(socket.assigns.filters) do
      {:ok, rows, summary} ->
        selected_candidate_id =
          if reset_selection do
            socket.assigns.selected_candidate_id || (List.first(rows) && List.first(rows).id)
          else
            socket.assigns.selected_candidate_id
          end

        socket
        |> assign(:load_error, false)
        |> assign(:queue_rows, rows)
        |> assign(:summary, summary)
        |> assign(:selected_candidate_id, selected_candidate_id)
        |> refresh_selection()

      :error ->
        socket
        |> assign(:load_error, true)
        |> assign(:queue_rows, [])
        |> assign(:summary, empty_summary())
        |> refresh_selection()
    end
  end

  # D-08: distinguish a genuine query failure (renders inline scoria-flash--fail + retry)
  # from a legitimately empty queue (renders empty_state/1 via the table's :empty slot)
  # instead of letting an unrescued query crash the LiveView.
  defp load_queue(filters) do
    rows = Eval.list_review_queue(filters)
    summary = Eval.summarize_review_queue(filters)
    {:ok, rows, summary}
  rescue
    _ -> :error
  end

  defp empty_summary do
    %{
      total_flagged: 0,
      low_quality_count: 0,
      policy_triggered_count: 0,
      promotion_candidate_count: 0
    }
  end

  defp refresh_selection(socket) do
    assign(
      socket,
      :selected_candidate,
      Eval.get_review_candidate(socket.assigns.selected_candidate_id)
    )
  end

  # D-09: shareable scan state (filter facets) lives in the URL, validated here against a
  # closed enum allow-list so a tampered/unknown query value falls back to the default
  # rather than being trusted as-is (T-39-05-T).
  defp filters_from_params(params) do
    %{
      "review_status" =>
        validate_facet(Map.get(params, "review_status"), @review_statuses, "pending"),
      "severity" => validate_facet(Map.get(params, "severity"), @severities, ""),
      "promotion_state" =>
        validate_facet(Map.get(params, "promotion_state"), @promotion_states, "")
    }
  end

  defp validate_facet(value, allowed, default) do
    if value in allowed, do: value, else: default
  end

  defp review_queue_path(scoria_base, filters) do
    query =
      filters
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> URI.encode_query()

    base = review_queue_base_path(scoria_base)
    if query == "", do: base, else: "#{base}?#{query}"
  end

  defp review_queue_base_path(""), do: "/reviews"
  defp review_queue_base_path(base), do: "#{base}/reviews"

  defp review_count(1, noun), do: "1 #{noun}"
  defp review_count(count, noun), do: "#{count} #{noun}s"

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

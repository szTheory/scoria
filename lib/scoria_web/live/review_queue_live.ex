defmodule ScoriaWeb.ReviewQueueLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

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
     |> assign(:selected_open_dataset_id, nil)
     |> assign(:selected_sealed_dataset_id, nil)
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
  def handle_event("select_open_dataset", %{"dataset-id" => dataset_id}, socket) do
    {:noreply, assign(socket, :selected_open_dataset_id, parse_id(dataset_id))}
  end

  @impl true
  def handle_event("select_sealed_dataset", %{"dataset-id" => dataset_id}, socket) do
    {:noreply, assign(socket, :selected_sealed_dataset_id, parse_id(dataset_id))}
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
  def handle_event("promote_candidate", _params, socket) do
    with %{} = candidate <- socket.assigns.selected_candidate,
         dataset_id when is_integer(dataset_id) <- socket.assigns.selected_open_dataset_id,
         {:ok, updated} <-
           Eval.promote_review_candidate(candidate.id, %{
             dataset_id: dataset_id,
             notes: "queue promotion",
             expected_output: %{}
           }) do
      {:noreply,
       socket
       |> assign(:notice, "Candidate promoted")
       |> assign(:selected_candidate, updated)
       |> refresh_queue(false)}
    else
      _ -> {:noreply, assign(socket, :notice, "Select an open dataset first")}
    end
  end

  @impl true
  def handle_event("request_baseline_approval", _params, socket) do
    with %{} = candidate <- socket.assigns.selected_candidate,
         dataset_id when is_integer(dataset_id) <- socket.assigns.selected_sealed_dataset_id,
         {:ok, updated} <-
           Eval.request_review_candidate_baseline_approval(candidate.id, %{
             dataset_id: dataset_id,
             notes: "queue baseline request",
             expected_output: %{}
           }) do
      {:noreply,
       socket
       |> assign(:notice, "Baseline approval requested")
       |> assign(:selected_candidate, updated)
       |> refresh_queue(false)}
    else
      _ -> {:noreply, assign(socket, :notice, "Select a sealed dataset first")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-stone-50 px-6 py-8 text-stone-900">
      <div class="mx-auto max-w-7xl">
        <header class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Scoria Reviews</p>
            <h1 class="text-3xl font-semibold">Review flagged traces</h1>
            <p class="mt-2 text-sm text-stone-600">Inspect one scored candidate at a time before promoting or dismissing it.</p>
          </div>
          <a href="/scoria" class="text-sm font-medium text-blue-700 underline">Back to dashboard</a>
        </header>

        <section class="mb-6 grid gap-4 md:grid-cols-4">
          <article class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">flagged items</p>
            <p class="mt-2 text-2xl font-semibold"><%= @summary.total_flagged %></p>
          </article>
          <article class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">low quality</p>
            <p class="mt-2 text-2xl font-semibold"><%= @summary.low_quality_count %></p>
          </article>
          <article class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">policy triggered</p>
            <p class="mt-2 text-2xl font-semibold"><%= @summary.policy_triggered_count %></p>
          </article>
          <article class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">promotion candidate</p>
            <p class="mt-2 text-2xl font-semibold"><%= @summary.promotion_candidate_count %></p>
          </article>
        </section>

        <%= if @notice do %>
          <section class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-900 shadow-sm">
            <%= @notice %>
          </section>
        <% end %>

        <div class="grid gap-6 lg:grid-cols-[minmax(0,1.05fr)_minmax(22rem,0.95fr)]">
          <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
            <form phx-change="change_filters" class="mb-4 grid gap-3 md:grid-cols-3">
              <label class="text-sm text-stone-700">
                Review state
                <select name="filters[review_status]" class="mt-1 w-full rounded-xl border border-stone-300 px-3 py-2 text-sm">
                  <option value="pending" selected={@filters["review_status"] == "pending"}>needs review</option>
                  <option value="" selected={@filters["review_status"] in [nil, ""]}>all active</option>
                  <option value="in_review" selected={@filters["review_status"] == "in_review"}>in review</option>
                </select>
              </label>
              <label class="text-sm text-stone-700">
                Severity
                <select name="filters[severity]" class="mt-1 w-full rounded-xl border border-stone-300 px-3 py-2 text-sm">
                  <option value="" selected={@filters["severity"] in [nil, ""]}>all severities</option>
                  <option value="policy_triggered" selected={@filters["severity"] == "policy_triggered"}>policy triggered</option>
                  <option value="low_quality" selected={@filters["severity"] == "low_quality"}>low quality</option>
                  <option value="promotion_candidate" selected={@filters["severity"] == "promotion_candidate"}>promotion candidate</option>
                </select>
              </label>
              <label class="text-sm text-stone-700">
                Promotion state
                <select name="filters[promotion_state]" class="mt-1 w-full rounded-xl border border-stone-300 px-3 py-2 text-sm">
                  <option value="" selected={@filters["promotion_state"] in [nil, ""]}>all states</option>
                  <option value="promotion_candidate" selected={@filters["promotion_state"] == "promotion_candidate"}>promotion candidate</option>
                  <option value="approval_requested" selected={@filters["promotion_state"] == "approval_requested"}>approval requested</option>
                </select>
              </label>
            </form>

            <div :if={@queue_rows == []} class="rounded-2xl border border-stone-200 bg-stone-50 p-6 text-sm text-stone-600">
              <h2 class="text-lg font-semibold text-stone-900">No traces need review</h2>
              <p class="mt-2">Scoria has not produced any low-quality, policy-triggered, or promotion-ready traces for this filter set yet.</p>
            </div>

            <div :if={@queue_rows != []} class="space-y-3">
              <button
                :for={row <- @queue_rows}
                type="button"
                phx-click="select_candidate"
                phx-value-id={row.id}
                class={[
                  "w-full rounded-2xl border p-4 text-left shadow-sm",
                  if(@selected_candidate_id == row.id,
                    do: "border-blue-300 bg-blue-50",
                    else: "border-stone-200 bg-white"
                  )
                ]}
              >
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <p class="text-sm font-semibold text-stone-900"><%= row.rationale %></p>
                    <p class="mt-1 text-xs uppercase tracking-[0.18em] text-stone-500"><%= row.severity %></p>
                  </div>
                  <span class="rounded-full border border-stone-300 bg-white px-3 py-1 text-xs font-semibold"><%= row.score_status || row.status %></span>
                </div>
                <div class="mt-3 flex flex-wrap gap-2 text-xs text-stone-600">
                  <span>trace <span class="font-mono"><%= row.trace_id %></span></span>
                  <span>run <span class="font-mono"><%= row.workflow_run_id %></span></span>
                  <span><%= row.sample_reason || row.status %></span>
                </div>
              </button>
            </div>
          </section>

          <section class="rounded-2xl border border-stone-200 bg-white p-5 shadow-sm">
            <%= if @selected_candidate do %>
              <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Detail rail</p>
              <h2 class="mt-2 text-2xl font-semibold text-stone-900"><%= @selected_candidate.rationale %></h2>
              <div class="mt-4 flex flex-wrap gap-2 text-xs text-stone-700">
                <span class="rounded-full border border-stone-300 bg-stone-50 px-3 py-1"><%= @selected_candidate.severity %></span>
                <span class="rounded-full border border-stone-300 bg-stone-50 px-3 py-1"><%= @selected_candidate.status %></span>
                <span class="rounded-full border border-stone-300 bg-stone-50 px-3 py-1">score <%= @selected_candidate.score || "n/a" %></span>
              </div>

              <dl class="mt-6 grid gap-4 text-sm text-stone-700">
                <div class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
                  <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Scoring provenance</dt>
                  <dd class="mt-2"><%= @selected_candidate.scorer_kind %> · <%= @selected_candidate.scorer_version %></dd>
                </div>
                <div class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
                  <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Sampling provenance</dt>
                  <dd class="mt-2 font-mono text-xs"><%= inspect(@selected_candidate.sampling_provenance) %></dd>
                </div>
              </dl>

              <div class="mt-6 flex flex-wrap gap-3">
                <a href={review_run_path(@selected_candidate, assigns[:scoria_base] || "")} class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white">Open run</a>
                <a href={review_runtime_path(@selected_candidate, assigns[:scoria_base] || "")} class="rounded-xl border border-blue-200 px-4 py-2 text-sm font-semibold text-blue-700">View runtime context</a>
              </div>

              <div class="mt-6 grid gap-4 lg:grid-cols-2">
                <section class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
                  <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Open draft datasets</p>
                  <div class="mt-3 space-y-2">
                    <button
                      :for={dataset <- @open_datasets}
                      type="button"
                      phx-click="select_open_dataset"
                      phx-value-dataset-id={dataset.id}
                      class={[
                        "w-full rounded-xl border px-3 py-2 text-left text-sm",
                        if(@selected_open_dataset_id == dataset.id,
                          do: "border-blue-300 bg-white text-blue-700",
                          else: "border-stone-300 bg-white text-stone-700"
                        )
                      ]}
                    >
                      <%= dataset.name %> <span class="font-mono">v<%= dataset.version %></span>
                    </button>
                  </div>
                </section>

                <section class="rounded-2xl border border-amber-200 bg-amber-50 p-4">
                  <p class="text-xs uppercase tracking-[0.18em] text-amber-700">Sealed baseline</p>
                  <div class="mt-3 space-y-2">
                    <button
                      :for={dataset <- @sealed_datasets}
                      type="button"
                      phx-click="select_sealed_dataset"
                      phx-value-dataset-id={dataset.id}
                      class={[
                        "w-full rounded-xl border px-3 py-2 text-left text-sm",
                        if(@selected_sealed_dataset_id == dataset.id,
                          do: "border-amber-300 bg-white text-amber-800",
                          else: "border-amber-200 bg-white text-stone-700"
                        )
                      ]}
                    >
                      <%= dataset.name %> <span class="font-mono">v<%= dataset.version %></span>
                    </button>
                  </div>
                </section>
              </div>

              <div class="mt-6 flex flex-wrap gap-3">
                <button type="button" phx-click="dismiss_candidate" phx-disable-with="Dismissing candidate..." class="rounded-xl border border-rose-200 px-4 py-2 text-sm font-semibold text-rose-700">
                  Dismiss candidate
                </button>
                <button type="button" phx-click="promote_candidate" phx-disable-with="Promoting to dataset..." class="rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white">
                  Promote to dataset
                </button>
                <button type="button" phx-click="request_baseline_approval" phx-disable-with="Requesting baseline approval..." class="rounded-xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white">
                  Request baseline approval
                </button>
              </div>

              <%= if @selected_candidate.dataset_ref do %>
                <p class="mt-4 text-sm text-emerald-700">
                  Promoted to <span class="font-semibold"><%= @selected_candidate.dataset_ref["dataset_name"] %></span>
                  <span class="font-mono">v<%= @selected_candidate.dataset_ref["dataset_version"] %></span>.
                </p>
              <% end %>
            <% else %>
              <div class="rounded-2xl border border-stone-200 bg-stone-50 p-6 text-sm text-stone-600">
                Select a queue row to inspect its evidence and actions.
              </div>
            <% end %>
          </section>
        </div>
      </div>
    </div>
    """
  end

  defp refresh_queue(socket, reset_selection \\ true) do
    rows = Eval.list_review_queue(socket.assigns.filters)
    summary = Eval.summarize_review_queue(socket.assigns.filters)

    {open_datasets, sealed_datasets} =
      Eval.list_datasets() |> Enum.split_with(&(&1.state == :open))

    selected_candidate_id =
      if reset_selection do
        socket.assigns.selected_candidate_id || (List.first(rows) && List.first(rows).id)
      else
        socket.assigns.selected_candidate_id
      end

    socket
    |> assign(:queue_rows, rows)
    |> assign(:summary, summary)
    |> assign(:open_datasets, open_datasets)
    |> assign(:sealed_datasets, sealed_datasets)
    |> assign(:selected_candidate_id, selected_candidate_id)
    |> assign(
      :selected_open_dataset_id,
      socket.assigns.selected_open_dataset_id ||
        (List.first(open_datasets) && List.first(open_datasets).id)
    )
    |> assign(
      :selected_sealed_dataset_id,
      socket.assigns.selected_sealed_dataset_id ||
        (List.first(sealed_datasets) && List.first(sealed_datasets).id)
    )
    |> refresh_selection()
  end

  defp refresh_selection(socket) do
    assign(
      socket,
      :selected_candidate,
      Eval.get_review_candidate(socket.assigns.selected_candidate_id)
    )
  end

  defp parse_id(nil), do: nil
  defp parse_id(""), do: nil
  defp parse_id(value) when is_integer(value), do: value
  defp parse_id(value) when is_binary(value), do: String.to_integer(value)

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

  defp review_origin(candidate), do: "review:#{candidate.id}"
  defp home_path(""), do: "/"
  defp home_path(base), do: base
end

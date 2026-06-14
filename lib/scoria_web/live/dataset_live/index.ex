defmodule ScoriaWeb.DatasetLive.Index do
  @moduledoc """
  Dataset Builder index: the canonical destination for dataset curation and
  promotion entry from review and workflow surfaces.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias Scoria.Eval
  alias Scoria.Runtime

  @promotion_modes ~w(review workflow)
  @workflow_source_variants ~w(original replay)
  @promotion_not_found %{
    title: "Promotion source not found",
    body:
      "The source ID no longer resolves. Return to the originating run or review item and open Dataset Builder again."
  }

  @impl true
  def mount(_params, _session, socket) do
    rows = dataset_rows()

    {:ok,
     socket
     |> assign(:page_title, "Dataset Builder")
     |> assign(:density, :compact)
     |> assign(:sort_by, :updated_at)
     |> assign(:sort_dir, :desc)
     |> assign(:dataset_rows, rows)
     |> assign(:datasets, sort_rows(rows, :updated_at, :desc))
     |> assign(:metrics, metrics(rows))
     |> assign(:promotion_context, nil)
     |> assign(:promotion_source, nil)
     |> assign(:promotion_error, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign_promotion_params(socket, params)}
  end

  @impl true
  def handle_event("set_density", %{"density" => density}, socket) do
    {:noreply, assign(socket, :density, density_value(density))}
  end

  def handle_event("sort", %{"by" => by}, socket) do
    sort_by = sort_key(by)
    sort_dir = next_sort_dir(socket.assigns.sort_by, socket.assigns.sort_dir, sort_by)

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> assign(:datasets, sort_rows(socket.assigns.dataset_rows, sort_by, sort_dir))}
  end

  def handle_event("close_promote", _params, socket) do
    {:noreply, push_patch(socket, to: dataset_path(socket.assigns[:scoria_base] || ""))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-pagehead">
      <div class="scoria-pagehead__title">
        <h1>Dataset Builder</h1>
      </div>
      <p>Curate production traces into eval datasets and baseline approval requests.</p>
    </div>

    <div class="grid gap-4 md:grid-cols-3">
      <.panel variant={:raised}>
        <.metric label="Open datasets" value={Integer.to_string(@metrics.open)} />
      </.panel>
      <.panel variant={:raised}>
        <.metric label="Sealed datasets" value={Integer.to_string(@metrics.sealed)} />
      </.panel>
      <.panel variant={:raised}>
        <.metric label="Dataset items" value={Integer.to_string(@metrics.items)} />
      </.panel>
    </div>

    <.panel variant={:flat} class="scoria-panel--flush mt-6">
      <:title>Datasets</:title>
      <.table
        id="datasets"
        rows={@datasets}
        density={@density}
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort="sort"
        on_density_change="set_density"
      >
        <:empty>
          <.empty_state title="No datasets match this view">
            Adjust your filters or check back when data is available.
          </.empty_state>
        </:empty>
        <:col :let={dataset} label="Dataset" key={:name}>
          <div>
            <strong>{dataset.name}</strong>
            <div><.id value={"v#{dataset.version}"} title="Dataset version" /></div>
          </div>
        </:col>
        <:col :let={dataset} label="State" key={:state}>
          <.badge tone={state_tone(dataset.state)} label={state_label(dataset.state)} />
        </:col>
        <:col :let={dataset} label="Items" key={:item_count}>
          {dataset.item_count}
        </:col>
        <:col :let={dataset} label="Last promoted" key={:last_promoted_at}>
          {format_ts(dataset.last_promoted_at)}
        </:col>
        <:col :let={dataset} label="Source" key={:source}>
          {dataset.source}
        </:col>
        <:col :let={dataset} label="Action">
          <.link patch={dataset_path(assigns[:scoria_base] || "", dataset.id)} class="scoria-button scoria-button--ghost scoria-button--sm">
            Inspect dataset
          </.link>
        </:col>
        <:mobile_summary :let={dataset}>
          <div class="scoria-mobile-summary">
            <div class="scoria-mobile-summary__label">
              <strong>{dataset.name}</strong>
              <span class="font-mono"> v{dataset.version}</span>
            </div>
            <div class="scoria-mobile-summary__status">
              <.badge tone={state_tone(dataset.state)} label={state_label(dataset.state)} />
            </div>
            <div class="scoria-mobile-summary__meta">
              {dataset.item_count} items
            </div>
            <div class="scoria-mobile-summary__action">
              <.link patch={dataset_path(assigns[:scoria_base] || "", dataset.id)} class="scoria-button scoria-button--ghost scoria-button--sm">
                Open dataset
              </.link>
            </div>
          </div>
        </:mobile_summary>
      </.table>
    </.panel>

    <.panel :if={@promotion_error} variant={:flat} class="mt-6">
      <.empty_state title={@promotion_error.title}>
        {@promotion_error.body}
      </.empty_state>
    </.panel>

    <.drawer
      id="dataset-promote-drawer"
      show={@promotion_context != nil}
      on_dismiss="close_promote"
      title="Promote traced evidence"
    >
      <:eyebrow>Dataset Builder</:eyebrow>
      <.panel :if={@promotion_source} variant={:raised} class="mb-4">
        <:eyebrow>{@promotion_source.eyebrow}</:eyebrow>
        <:title>{@promotion_source.title}</:title>
        <p>{@promotion_source.body}</p>
      </.panel>
      <.live_component
        module={ScoriaWeb.DatasetLive.PromoteComponent}
        id="dataset-builder-promote"
        promotion_context={@promotion_context}
        scoria_base={assigns[:scoria_base] || ""}
      />
    </.drawer>
    """
  end

  defp assign_promotion_params(socket, %{"promote" => promote} = params)
       when promote in @promotion_modes do
    case promotion_from_params(promote, params) do
      {:ok, promotion_context, promotion_source} ->
        socket
        |> assign(:promotion_context, promotion_context)
        |> assign(:promotion_source, promotion_source)
        |> assign(:promotion_error, nil)

      :error ->
        socket
        |> assign(:promotion_context, nil)
        |> assign(:promotion_source, nil)
        |> assign(:promotion_error, @promotion_not_found)
    end
  end

  defp assign_promotion_params(socket, _params) do
    socket
    |> assign(:promotion_context, nil)
    |> assign(:promotion_source, nil)
    |> assign(:promotion_error, nil)
  end

  defp promotion_from_params("review", %{"review_candidate_id" => review_candidate_id})
       when is_binary(review_candidate_id) and review_candidate_id != "" do
    case Eval.get_review_candidate(review_candidate_id) do
      %{promotion_context: promotion_context} = candidate when is_map(promotion_context) ->
        {:ok, promotion_context,
         %{
           eyebrow: "Review candidate",
           title: "Review candidate source",
           body: candidate.rationale || "Scored review evidence is ready for dataset promotion."
         }}

      _ ->
        :error
    end
  end

  defp promotion_from_params("workflow", %{
         "run_id" => run_id,
         "step_id" => step_id,
         "source_variant" => source_variant
       })
       when is_binary(run_id) and run_id != "" and is_binary(step_id) and step_id != "" and
              source_variant in @workflow_source_variants do
    with {:ok, context} <- workflow_promotion_context(run_id, step_id, source_variant) do
      {:ok, context,
       %{
         eyebrow: "Workflow evidence",
         title: variant_label(source_variant),
         body: "Promotion context was reconstructed from persisted run and step evidence."
       }}
    else
      _ -> :error
    end
  end

  defp promotion_from_params(_promote, _params), do: :error

  defp workflow_promotion_context(run_id, step_id, source_variant) do
    detail = Runtime.get_run_detail!(run_id)
    source_key = String.to_existing_atom(source_variant)

    detail.comparison_by_step
    |> Map.get(step_id)
    |> selected_comparison_entry(source_key)
    |> promotion_context()
  rescue
    _ -> :error
  end

  defp selected_comparison_entry(nil, _source_key), do: nil
  defp selected_comparison_entry(comparison, source_key), do: Map.get(comparison, source_key)

  defp promotion_context(nil), do: :error

  defp promotion_context(selected_entry) do
    provenance = Map.get(selected_entry, :provenance, %{})
    checkpoint_output = Map.get(selected_entry, :checkpoint_output, %{})
    safety = Map.get(selected_entry, :safety, %{})
    promotion_snapshot = Map.get(selected_entry, :promotion_snapshot, %{})

    with %{
           workflow_run_id: workflow_run_id,
           workflow_step_id: workflow_step_id,
           source_variant: source_variant
         } <- provenance do
      {:ok,
       %{
         workflow_run_id: workflow_run_id,
         workflow_step_id: workflow_step_id,
         source_variant: source_variant,
         provenance: provenance,
         checkpoint_output: checkpoint_output,
         safety: safety,
         promotion_snapshot: promotion_snapshot,
         notes: "",
         expected_output: %{}
       }}
    else
      _ -> :error
    end
  end

  defp dataset_rows do
    Eval.list_datasets()
    |> Enum.map(&dataset_row/1)
  rescue
    _ -> []
  end

  defp dataset_row(dataset) do
    items = Eval.list_dataset_items(dataset.id)

    %{
      id: dataset.id,
      name: dataset.name,
      version: dataset.version,
      state: dataset.state,
      item_count: length(items),
      last_promoted_at: last_promoted_at(items),
      source: source_label(items),
      updated_at: dataset.updated_at || dataset.inserted_at
    }
  end

  defp metrics(rows) do
    %{
      open: Enum.count(rows, &(&1.state == :open)),
      sealed: Enum.count(rows, &(&1.state == :sealed)),
      items: Enum.reduce(rows, 0, &(&1.item_count + &2))
    }
  end

  defp sort_rows(rows, sort_by, sort_dir) do
    rows
    |> Enum.sort_by(&sort_value(&1, sort_by), sorter(sort_dir))
  end

  defp sort_value(row, key), do: Map.get(row, key)

  defp sorter(:desc), do: :desc
  defp sorter(_), do: :asc

  defp next_sort_dir(current_by, current_dir, sort_by)
  defp next_sort_dir(sort_by, :asc, sort_by), do: :desc
  defp next_sort_dir(sort_by, :desc, sort_by), do: :asc
  defp next_sort_dir(_current_by, _current_dir, _sort_by), do: :asc

  defp sort_key("name"), do: :name
  defp sort_key("state"), do: :state
  defp sort_key("item_count"), do: :item_count
  defp sort_key("last_promoted_at"), do: :last_promoted_at
  defp sort_key("source"), do: :source
  defp sort_key(_), do: :updated_at

  defp density_value("compact"), do: :compact
  defp density_value("comfortable"), do: :comfortable
  defp density_value(_), do: :default

  defp state_tone(:open), do: :info
  defp state_tone(:sealed), do: :pass
  defp state_tone(_), do: :neutral

  defp state_label(:open), do: "Open"
  defp state_label(:sealed), do: "Sealed"
  defp state_label(_), do: "Unknown"

  defp last_promoted_at([]), do: nil

  defp last_promoted_at(items) do
    items
    |> Enum.map(&(&1.inserted_at || &1.updated_at))
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      timestamps -> Enum.max(timestamps, DateTime)
    end
  end

  defp source_label([]), do: "No source yet"

  defp source_label(items) do
    items
    |> Enum.map(&source_from_item/1)
    |> Enum.find(&(&1 != nil))
    |> case do
      nil -> "Manual"
      source -> source
    end
  end

  defp source_from_item(item) do
    metadata = item.metadata || %{}

    cond do
      metadata["promoted_from_workflow"] || metadata["workflow_run_id"] -> "Workflow"
      metadata["promoted_from_review"] || metadata["review_candidate_id"] -> "Review"
      metadata["promoted_from_trace"] || metadata["trace_id"] -> "Trace"
      true -> nil
    end
  end

  defp format_ts(nil), do: "Never"
  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_ts(other), do: to_string(other)

  defp dataset_path(base_path) do
    base_path
    |> to_string()
    |> String.trim_trailing("/")
    |> Kernel.<>("/datasets")
  end

  defp dataset_path(base_path, dataset_id) do
    dataset_path(base_path) <> "?dataset_id=#{dataset_id}"
  end

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"
end

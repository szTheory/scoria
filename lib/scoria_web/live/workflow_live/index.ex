defmodule ScoriaWeb.WorkflowLive.Index do
  @moduledoc """
  Runs index — recent durable workflow runs (Trace Explorer entry point).
  Operator job: find a run to inspect.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import Ecto.Query, warn: false
  import ScoriaWeb.UI

  alias Scoria.Repo
  alias Scoria.Workflows.Run

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Runs")
     |> assign(:run_table_density, :compact)
     |> assign(:runs, list_runs())}
  end

  @impl true
  def handle_event("set_density", %{"density" => density}, socket) do
    density =
      case density do
        "compact" -> :compact
        "comfortable" -> :comfortable
        _ -> :default
      end

    {:noreply, assign(socket, :run_table_density, density)}
  end

  defp list_runs do
    Repo.all(from(r in Run, order_by: [desc: r.inserted_at], limit: 50))
  rescue
    _ -> []
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-pagehead">
      <div class="scoria-pagehead__title">
        <h1>Runs</h1>
      </div>
      <p>Inspect recorded workflow runs and open the trace that explains them.</p>
    </div>

    <.panel variant={:flat} class="scoria-panel--flush">
      <.table id="runs" rows={@runs} density={@run_table_density}>
        <:col :let={run} label="Run">
          <.id value={short_id(run.id)} copy={run.id} />
        </:col>
        <:col :let={run} label="Status">
          <.badge tone={tone(run.status)} label={status_label(run.status)} />
        </:col>
        <:col :let={run} label="Runtime">
          <span class="font-mono">{runtime_label(run)}</span>
        </:col>
        <:col :let={run} label="Started">
          {format_ts(run.started_at || run.inserted_at)}
        </:col>
        <:action :let={run}>
          <.link navigate={(assigns[:scoria_base] || "") <> "/workflows/#{run.id}"} class="scoria-button scoria-button--ghost scoria-button--sm">
            Open trace
          </.link>
        </:action>
        <:empty>
          <.empty_state title="No runs yet">
            The first durable workflow run will appear here with its trace, status, and runtime context.
          </.empty_state>
        </:empty>
      </.table>
    </.panel>
    """
  end

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp runtime_label(run) do
    [run.execution_mode, run.session_id]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" / ")
    |> case do
      "" -> "—"
      label -> label
    end
  end

  defp format_ts(nil), do: "—"
  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_ts(other), do: to_string(other)
end

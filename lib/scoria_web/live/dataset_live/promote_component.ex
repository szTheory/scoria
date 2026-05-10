defmodule ScoriaWeb.DatasetLive.PromoteComponent do
  use Phoenix.LiveComponent
  import Phoenix.Component

  alias Scoria.Eval

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <header>
        <h2>Promote Trace to Dataset</h2>
        <p>Create a new dataset snapshot from this execution trace for future evaluation.</p>
      </header>

      <.form
        for={@form}
        id="promote-form"
        phx-target={@myself}
        phx-submit="promote"
      >
        <label>
          Dataset Name:
          <input type="text" name={@form[:name].name} value={@form[:name].value} required />
        </label>
        
        <button type="submit" phx-disable-with="Promoting...">Promote</button>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(%{"name" => ""}))}
  end

  @impl true
  def handle_event("promote", %{"name" => name}, socket) do
    trace = socket.assigns.trace
    dataset_attrs = %{name: name}

    case Eval.promote_trace_to_dataset(trace, dataset_attrs) do
      {:ok, _dataset} ->
        send(self(), {:trace_promoted, name})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end

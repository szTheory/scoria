defmodule ScoriaWeb.EvalSpecLive.Index do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  alias Scoria.Eval
  alias Scoria.Eval.EvalSpec

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(:eval_specs, Eval.list_eval_specs())
     |> assign(:edit_spec, nil)
     |> assign(:form, nil)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    spec = Eval.get_eval_spec!(id)
    changeset = EvalSpec.changeset(spec, %{})
    {:noreply,
     socket
     |> assign(:edit_spec, spec)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, edit_spec: nil, form: nil)}
  end

  @impl true
  def handle_event("save", %{"eval_spec" => spec_params}, socket) do
    spec = socket.assigns.edit_spec
    
    # We might need to decode rubric if it comes as JSON string, but for now
    # let's try to pass it directly. Ecto might need map for JSONB.
    parsed_params = 
      case Map.get(spec_params, "rubric") do
        rubric_str when is_binary(rubric_str) and rubric_str != "" ->
          case Jason.decode(rubric_str) do
            {:ok, json} -> Map.put(spec_params, "rubric", json)
            {:error, _} -> spec_params # Will let Ecto validation catch it
          end
        _ -> spec_params
      end

    case Eval.update_eval_spec(spec, parsed_params) do
      {:ok, _new_spec} ->
        {:noreply,
         socket
         |> assign(:edit_spec, nil)
         |> assign(:form, nil)
         |> assign(:eval_specs, Eval.list_eval_specs())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="eval-spec-index">
      <h1>Evaluation Rubrics (EvalSpecs)</h1>

      <%= if @edit_spec do %>
        <div class="edit-form">
          <h2>Edit Rubric: <%= @edit_spec.name %> (v<%= @edit_spec.version %>)</h2>
          <.form for={@form} phx-submit="save">
            <div>
              <label>Name</label>
              <input type="text" name={@form[:name].name} value={@form[:name].value} required />
              <%= for error <- Keyword.get_values(@form.errors || [], :name) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>

            <div>
              <label>Description</label>
              <textarea name={@form[:description].name} required><%= @form[:description].value %></textarea>
              <%= for error <- Keyword.get_values(@form.errors || [], :description) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>

            <div>
              <label>Rubric (JSON string)</label>
              <textarea name={@form[:rubric].name} rows="5"><%= encode_rubric(@form[:rubric].value) %></textarea>
              <%= for error <- Keyword.get_values(@form.errors || [], :rubric) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>

            <button type="submit" phx-disable-with="Saving...">Save New Version</button>
            <button type="button" phx-click="cancel_edit">Cancel</button>
          </.form>
        </div>
      <% else %>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Version</th>
              <th>Description</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for spec <- @eval_specs do %>
              <tr id={"spec-#{spec.id}"}>
                <td><%= spec.name %></td>
                <td><%= spec.version %></td>
                <td><%= spec.description %></td>
                <td>
                  <button phx-click="edit" phx-value-id={spec.id}>Edit</button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp encode_rubric(nil), do: ""
  defp encode_rubric(val) when is_map(val), do: Jason.encode!(val, pretty: true)
  defp encode_rubric(val), do: to_string(val)

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

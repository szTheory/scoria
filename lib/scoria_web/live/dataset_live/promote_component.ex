defmodule ScoriaWeb.DatasetLive.PromoteComponent do
  use Phoenix.LiveComponent
  import Ecto.Changeset
  alias Scoria.Eval

  @impl true
  def update(assigns, socket) do
    step = assigns[:step] || %{}
    
    # Extract input context for the initial form
    input_json = 
      case Map.get(step, :projected_context) do
        nil -> "{}"
        context -> Jason.encode!(context, pretty: true)
      end
      
    datasets = 
      Eval.list_datasets()
      |> Enum.filter(&(&1.state == :open))
      
    initial_params = %{
      "input" => input_json,
      "expected_output" => "{}"
    }
    
    changeset = dataset_item_form(initial_params)
    
    {:ok, 
     socket
     |> assign(assigns)
     |> assign(:datasets, datasets)
     |> assign(:form, to_form(changeset, as: "item"))}
  end
  
  @impl true
  def handle_event("validate", %{"item" => params}, socket) do
    changeset = 
      params
      |> dataset_item_form()
      |> Map.put(:action, :validate)
      
    {:noreply, assign(socket, :form, to_form(changeset, as: "item"))}
  end
  
  @impl true
  def handle_event("save", %{"item" => params}, socket) do
    changeset = dataset_item_form(params)
    
    if changeset.valid? do
      dataset_id = Ecto.Changeset.get_field(changeset, :dataset_id)
      
      input_json = Ecto.Changeset.get_field(changeset, :input)
      exp_json = Ecto.Changeset.get_field(changeset, :expected_output)
      
      with {:ok, input_map} <- Jason.decode(input_json),
           {:ok, exp_map} <- Jason.decode(exp_json) do
           
        attrs = %{input: input_map, expected_output: exp_map}
        
        case Eval.add_dataset_item(dataset_id, attrs) do
          {:ok, _item} ->
            send(self(), {:promote_successful})
            {:noreply, socket}
          {:error, _} ->
            changeset = add_error(changeset, :dataset_id, "failed to save to dataset")
            {:noreply, assign(socket, :form, to_form(changeset, as: "item"))}
        end
      else
        {:error, _} ->
          # Add JSON parse errors
          changeset = 
            changeset
            |> add_error(:input, "must be valid JSON")
            |> add_error(:expected_output, "must be valid JSON")
          {:noreply, assign(socket, :form, to_form(changeset, as: "item"))}
      end
    else
      {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate), as: "item"))}
    end
  end

  defp dataset_item_form(params) do
    types = %{dataset_id: :integer, input: :string, expected_output: :string}
    
    {%{}, types}
    |> cast(params, [:dataset_id, :input, :expected_output])
    |> validate_required([:dataset_id, :input, :expected_output])
    |> validate_json(:input)
    |> validate_json(:expected_output)
  end
  
  defp validate_json(changeset, field) do
    validate_change(changeset, field, fn current_field, value ->
      case Jason.decode(value) do
        {:ok, _} -> []
        {:error, _} -> [{current_field, "must be valid JSON"}]
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="promote-dataset-modal">
      <h2 class="text-xl font-bold mb-4">Promote to Dataset</h2>
      
      <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <div class="mb-4">
          <label class="block font-medium mb-1">Select Dataset</label>
          <select name={@form[:dataset_id].name} class="w-full border p-2 rounded">
            <option value="">-- Select an open dataset --</option>
            <%= for dataset <- @datasets do %>
              <option value={dataset.id} selected={@form[:dataset_id].value == to_string(dataset.id)}>
                <%= dataset.name %> (v<%= dataset.version %>)
              </option>
            <% end %>
          </select>
          <%= for error <- Keyword.get_values(@form.errors || [], :dataset_id) do %>
            <span class="text-red-500 text-sm"><%= translate_error(error) %></span>
          <% end %>
        </div>

        <div class="mb-4">
          <label class="block font-medium mb-1">Input Context (JSON)</label>
          <textarea name={@form[:input].name} rows="8" class="w-full font-mono text-sm border p-2 rounded"><%= @form[:input].value %></textarea>
          <%= for error <- Keyword.get_values(@form.errors || [], :input) do %>
            <span class="text-red-500 text-sm"><%= translate_error(error) %></span>
          <% end %>
        </div>

        <div class="mb-4">
          <label class="block font-medium mb-1">Expected Output (JSON)</label>
          <textarea name={@form[:expected_output].name} rows="5" class="w-full font-mono text-sm border p-2 rounded"><%= @form[:expected_output].value %></textarea>
          <%= for error <- Keyword.get_values(@form.errors || [], :expected_output) do %>
            <span class="text-red-500 text-sm"><%= translate_error(error) %></span>
          <% end %>
        </div>

        <div class="flex justify-end gap-2">
          <button type="button" phx-click="close_modal" class="px-4 py-2 border rounded">Cancel</button>
          <button type="submit" phx-disable-with="Saving..." class="px-4 py-2 bg-blue-600 text-white rounded">Promote</button>
        </div>
      </.form>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

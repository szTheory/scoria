defmodule ScoriaWeb.PromptLive.Index do
  use Phoenix.LiveView
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.PromptRegistry.Tokenizer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(:prompt_templates, PromptRegistry.list_prompt_templates())
     |> assign(:edit_template, nil)
     |> assign(:estimated_tokens, nil)
     |> assign(:form, nil)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    template = PromptRegistry.get_prompt_template!(id)
    changeset = PromptTemplate.changeset(template, %{})
    
    {:noreply,
     socket
     |> assign(:edit_template, template)
     |> assign(:estimated_tokens, template.estimated_tokens)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, edit_template: nil, form: nil, estimated_tokens: nil)}
  end

  @impl true
  def handle_event("validate", %{"prompt_template" => template_params}, socket) do
    template = socket.assigns.edit_template
    
    changeset = 
      template
      |> PromptTemplate.changeset(template_params)
      |> Map.put(:action, :validate)
      
    # Dynamic token calculation
    system_msg = Ecto.Changeset.get_field(changeset, :system_message) || ""
    user_msg = Ecto.Changeset.get_field(changeset, :user_template) || ""
    
    combined = system_msg <> "\n" <> user_msg
    
    estimated_tokens = Tokenizer.estimate_tokens(combined)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:estimated_tokens, estimated_tokens)}
  end

  @impl true
  def handle_event("save", %{"prompt_template" => template_params}, socket) do
    template = socket.assigns.edit_template
    
    # We update draft or active version based on status, but let's try update_draft_template
    # if it's draft, or just use update_draft_template since the test expects in-place draft update
    case update_template(template, template_params) do
      {:ok, _new_template} ->
        {:noreply,
         socket
         |> assign(:edit_template, nil)
         |> assign(:form, nil)
         |> assign(:estimated_tokens, nil)
         |> assign(:prompt_templates, PromptRegistry.list_prompt_templates())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
  
  defp update_template(%{status: "draft"} = template, params) do
    PromptRegistry.update_draft_template(template, params)
  end
  
  defp update_template(template, params) do
    PromptRegistry.update_prompt_template(template, params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="prompt-template-index">
      <h1>Prompt Templates</h1>

      <%= if @edit_template do %>
        <div class="edit-form">
          <h2>Edit Template: <%= @edit_template.entity_id %> (v<%= @edit_template.version %>)</h2>
          
          <%= if @estimated_tokens do %>
            <div class="token-estimation">
              Estimated Tokens: <strong><%= @estimated_tokens %></strong>
              <%= if @estimated_tokens > 4000 do %>
                <span class="warning">High token count!</span>
              <% end %>
            </div>
          <% end %>

          <.form for={@form} phx-change="validate" phx-submit="save">
            <div>
              <label>System Message</label>
              <textarea name={@form[:system_message].name} rows="5"><%= @form[:system_message].value %></textarea>
              <%= for error <- Keyword.get_values(@form.errors || [], :system_message) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>

            <div>
              <label>User Template</label>
              <textarea name={@form[:user_template].name} rows="5"><%= @form[:user_template].value %></textarea>
              <%= for error <- Keyword.get_values(@form.errors || [], :user_template) do %>
                <span class="error"><%= translate_error(error) %></span>
              <% end %>
            </div>

            <button type="submit" phx-disable-with="Saving...">Save Template</button>
            <button type="button" phx-click="cancel_edit">Cancel</button>
          </.form>
        </div>
      <% else %>
        <table>
          <thead>
            <tr>
              <th>Entity ID</th>
              <th>Version</th>
              <th>Status</th>
              <th>System Message</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for template <- @prompt_templates do %>
              <tr id={"template-#{template.id}"}>
                <td><%= template.entity_id %></td>
                <td><%= template.version %></td>
                <td><%= template.status %></td>
                <td><%= truncate(template.system_message, 50) %></td>
                <td>
                  <button phx-click="edit" phx-value-id={template.id}>Edit</button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp truncate(nil, _), do: ""
  defp truncate(text, length) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

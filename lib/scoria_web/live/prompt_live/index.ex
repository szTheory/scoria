defmodule ScoriaWeb.PromptLive.Index do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import ScoriaWeb.UI
  alias Scoria.PromptRegistry
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.PromptRegistry.Tokenizer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Prompt Registry")
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
    <div class="scoria-page">
      <div class="scoria-page__header">
        <p class="scoria-eyebrow">Prompt Registry</p>
        <h1>Prompt Registry</h1>
      </div>

      <%= if @edit_template do %>
        <.panel>
          <:eyebrow>Prompt version</:eyebrow>
          <:title>Edit Template: <%= @edit_template.entity_id %> (v<%= @edit_template.version %>)</:title>
          
          <%= if @estimated_tokens do %>
            <p>
              Estimated Tokens: <strong><%= @estimated_tokens %></strong>
              <%= if @estimated_tokens > 4000 do %>
                <.badge tone={:warn} label="High token count" />
              <% end %>
            </p>
          <% end %>

          <.form for={@form} phx-change="validate" phx-submit="save">
            <.form_section
              title="Prompt content"
              description="Edit the backed prompt messages while preserving version history and token estimation."
            >
              <.field
                id="prompt-template-system-message"
                label="System Message"
                error={field_error(@form, :system_message)}
              >
                <textarea id="prompt-template-system-message" name={@form[:system_message].name} rows="5"><%= @form[:system_message].value %></textarea>
              </.field>

              <.field
                id="prompt-template-user-template"
                label="User Template"
                error={field_error(@form, :user_template)}
              >
                <textarea id="prompt-template-user-template" name={@form[:user_template].name} rows="5"><%= @form[:user_template].value %></textarea>
              </.field>
            </.form_section>

            <div class="flex flex-wrap gap-2">
              <.button type="submit" phx-disable-with="Saving...">Save Template</.button>
              <.button variant={:ghost} type="button" phx-click="cancel_edit">Cancel</.button>
            </div>
          </.form>
        </.panel>
      <% else %>
        <.table id="prompt-versions" rows={@prompt_templates} density={:compact}>
          <:col :let={template} label="Prompt"><%= template.entity_id %></:col>
          <:col :let={template} label="Version">v<%= template.version %></:col>
          <:col :let={template} label="State">
            <.badge tone={tone(template.status)} label={status_label(template.status)} />
          </:col>
          <:col :let={template} label="System Message">
            <%= truncate(template.system_message, 50) %>
          </:col>
          <:action :let={template}>
            <.button size={:sm} variant={:ghost} phx-click="edit" phx-value-id={template.id}>
              Edit
            </.button>
          </:action>
          <:empty>
            <.empty_state title="No prompt versions yet">
              Prompt versions appear after backed prompt edits are recorded.
            </.empty_state>
          </:empty>
        </.table>
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

  defp field_error(form, field) do
    form.errors
    |> Keyword.get_values(field)
    |> List.first()
    |> case do
      nil -> nil
      error -> translate_error(error)
    end
  end
end

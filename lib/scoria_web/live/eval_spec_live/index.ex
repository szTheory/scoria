defmodule ScoriaWeb.EvalSpecLive.Index do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}
  import Ecto.Query, warn: false
  import ScoriaWeb.UI
  alias Scoria.Eval
  alias Scoria.Eval.{EvalRun, EvalSpec}
  alias Scoria.Repo

  @regressed_score_statuses ~w(failed regressed regression)
  @run_id_keys [
    {"workflow_run_id", :workflow_run_id},
    {"run_id", :run_id},
    {"source_run_id", :source_run_id},
    {"regressed_run_id", :regressed_run_id}
  ]
  @run_ids_keys [
    {"workflow_run_ids", :workflow_run_ids},
    {"run_ids", :run_ids},
    {"regressed_run_ids", :regressed_run_ids}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Eval Workbench")
     |> assign(:eval_specs, Eval.list_eval_specs())
     |> assign(:eval_runs, list_eval_runs())
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
            # Will let Ecto validation catch it
            {:error, _} -> spec_params
          end

        _ ->
          spec_params
      end

    case Eval.update_eval_spec(spec, parsed_params) do
      {:ok, _new_spec} ->
        {:noreply,
         socket
         |> assign(:edit_spec, nil)
         |> assign(:form, nil)
         |> assign(:eval_specs, Eval.list_eval_specs())
         |> assign(:eval_runs, list_eval_runs())}

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
        <.panel>
          <:eyebrow>Evaluation</:eyebrow>
          <:title>Rubrics</:title>
          <.empty_state :if={@eval_specs == []} title="No evaluation rubrics yet">
            Define a rubric with scorers and a threshold policy and it will appear here,
            ready to gate releases on measurable eval deltas.
          </.empty_state>

          <.table :if={@eval_specs != []} id="eval-specs" rows={@eval_specs} density={:compact}>
            <:col :let={spec} label="Name" key={:name}>{spec.name}</:col>
            <:col :let={spec} label="Version" key={:version}>
              <.badge tone={:neutral} label={"v#{spec.version}"} />
            </:col>
            <:col :let={spec} label="Description">{spec.description}</:col>
            <:action :let={spec}>
              <.button variant={:ghost} size={:sm} phx-click="edit" phx-value-id={spec.id}>
                Edit
              </.button>
            </:action>
          </.table>
        </.panel>

        <.panel id="eval-results">
          <:eyebrow>Results</:eyebrow>
          <:title>Eval results</:title>

          <.empty_state :if={@eval_runs == []} title="No eval runs yet">
            Promote a production trace to a dataset, then run an eval to compare prompt behavior against a baseline.
          </.empty_state>

          <.table :if={@eval_runs != []} id="eval-runs" rows={@eval_runs} density={:compact}>
            <:col :let={run} label="Run">
              <.id id={"eval-run-id-#{run.id}"} value={run.id} />
            </:col>
            <:col :let={run} label="Status" key={:status}>
              <.badge tone={tone(run.status)} label={status_label(run.status)} />
            </:col>
            <:col :let={run} label="Prompt">
              <%= if run.prompt_version do %>
                v<%= run.prompt_version %>
              <% else %>
                n/a
              <% end %>
            </:col>
            <:action :let={run}>
              <a
                :if={run.prompt_template_id}
                href={prompt_release_path(run, assigns[:scoria_base] || "")}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Open prompt release
              </a>
              <a
                :if={regressed_run_ids(run) != []}
                href={regressed_runs_path(run, assigns[:scoria_base] || "")}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Open regressed runs
              </a>
            </:action>
          </.table>
        </.panel>
      <% end %>
    </div>
    """
  end

  defp list_eval_runs do
    EvalRun
    |> order_by([run], desc: run.inserted_at)
    |> limit(20)
    |> preload(:scores)
    |> Repo.all()
  end

  defp prompt_release_path(run, base_path) do
    "#{base_path}/prompts/#{run.prompt_template_id}/release?#{origin_query(run)}"
  end

  defp regressed_runs_path(run, base_path) do
    run_id = run |> regressed_run_ids() |> List.first()
    "#{base_path}/workflows/#{run_id}?#{origin_query(run)}"
  end

  defp origin_query(run), do: URI.encode_query([{"from", "eval:#{run.id}"}])

  defp regressed_run_ids(run) do
    run.scores
    |> Enum.filter(&(&1.status in @regressed_score_statuses))
    |> Enum.flat_map(fn score ->
      run_ids_from_map(score.evidence_refs || %{}) ++ run_ids_from_map(score.metadata || %{})
    end)
    |> Enum.uniq()
  end

  defp run_ids_from_map(map) when is_map(map) do
    single_ids =
      Enum.flat_map(@run_id_keys, fn {string_key, atom_key} ->
        map |> read_map_value(string_key, atom_key) |> normalize_run_ids()
      end)

    multi_ids =
      Enum.flat_map(@run_ids_keys, fn {string_key, atom_key} ->
        map |> read_map_value(string_key, atom_key) |> normalize_run_ids()
      end)

    single_ids ++ multi_ids
  end

  defp run_ids_from_map(_value), do: []

  defp read_map_value(map, string_key, atom_key),
    do: Map.get(map, string_key) || Map.get(map, atom_key)

  defp normalize_run_ids(nil), do: []

  defp normalize_run_ids(values) when is_list(values),
    do: Enum.flat_map(values, &normalize_run_ids/1)

  defp normalize_run_ids(value) when is_binary(value) do
    case Ecto.UUID.cast(value) do
      {:ok, run_id} -> [run_id]
      :error -> []
    end
  end

  defp normalize_run_ids(_value), do: []

  defp encode_rubric(nil), do: ""
  defp encode_rubric(val) when is_map(val), do: Jason.encode!(val, pretty: true)
  defp encode_rubric(val), do: to_string(val)

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

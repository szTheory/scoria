defmodule ScoriaWeb.DatasetLive.PromoteComponent do
  use Phoenix.LiveComponent

  import Ecto.Changeset
  import ScoriaWeb.UI

  alias Scoria.Eval
  alias Scoria.Workflows

  @impl true
  def update(assigns, socket) do
    promotion_context = assigns[:promotion_context] || %{}
    form_params = socket.assigns[:form_params] || initial_form_params(promotion_context)
    {open_datasets, sealed_datasets} = load_dataset_groups()

    source_run_links_by_dataset_id =
      source_run_links_by_dataset_id(open_datasets ++ sealed_datasets)

    selected_open_dataset_id = selected_open_dataset_id(form_params, open_datasets)
    baseline_target_id = socket.assigns[:baseline_target_id]
    baseline_target = find_dataset(sealed_datasets, baseline_target_id)

    mode =
      if(socket.assigns[:mode] == :baseline_confirm and baseline_target,
        do: :baseline_confirm,
        else: :draft
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:promotion_context, promotion_context)
     |> assign(:open_datasets, open_datasets)
     |> assign(:sealed_datasets, sealed_datasets)
     |> assign(:source_run_links_by_dataset_id, source_run_links_by_dataset_id)
     |> assign(:scoria_base, assigns[:scoria_base] || Map.get(socket.assigns, :scoria_base, ""))
     |> assign(:selected_open_dataset_id, selected_open_dataset_id)
     |> assign(:baseline_target_id, baseline_target_id)
     |> assign(:mode, mode)
     |> assign(:form_params, form_params)
     |> assign(:form, to_form(promotion_form(form_params), as: "promotion"))}
  end

  @impl true
  def handle_event("validate", %{"promotion" => params}, socket) do
    {:noreply, assign_form(socket, params, promotion_form(params, action: :validate))}
  end

  @impl true
  def handle_event("select_open_dataset", %{"dataset-id" => dataset_id}, socket) do
    params =
      socket.assigns.form_params
      |> Map.put("dataset_id", dataset_id)

    {:noreply,
     socket
     |> assign(:mode, :draft)
     |> assign(:baseline_target_id, nil)
     |> assign(:selected_open_dataset_id, parse_dataset_id(dataset_id))
     |> assign_form(params, promotion_form(params))}
  end

  @impl true
  def handle_event("select_sealed_dataset", %{"dataset-id" => dataset_id}, socket) do
    {:noreply,
     socket
     |> assign(:mode, :baseline_confirm)
     |> assign(:baseline_target_id, parse_dataset_id(dataset_id))}
  end

  @impl true
  def handle_event("back_to_draft", _params, socket) do
    {:noreply, socket |> assign(:mode, :draft) |> assign(:baseline_target_id, nil)}
  end

  @impl true
  def handle_event("save", %{"promotion" => params}, socket) do
    changeset = promotion_form(params, require_dataset: true, action: :validate)

    with true <- changeset.valid?,
         {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
         dataset_id when is_integer(dataset_id) <- get_field(changeset, :dataset_id),
         promotion_attrs <-
           Eval.DatasetPromotion.build_promotion_attrs(
             socket.assigns.promotion_context,
             dataset_id,
             get_field(changeset, :notes),
             expected_output
           ),
         {:ok, _item} <- Eval.promote_workflow_source(promotion_attrs) do
      dataset = Eval.get_dataset!(dataset_id)

      send(
        self(),
        {:promote_successful,
         %{
           source_variant: read_context_value(socket.assigns.promotion_context, :source_variant),
           dataset_name: dataset.name,
           dataset_version: dataset.version
         }}
      )

      {:noreply, socket}
    else
      false ->
        {:noreply, assign_form(socket, params, changeset)}

      {:error, %Jason.DecodeError{}} ->
        {:noreply,
         assign_form(socket, params, add_error(changeset, :expected_output, "must be valid JSON"))}

      {:error, %Ecto.Changeset{} = result_changeset} ->
        message = first_error(result_changeset, :dataset_id, "failed to promote snapshot")
        params = Map.put(params, "dataset_id", "")

        {:noreply,
         socket
         |> refresh_datasets()
         |> assign(:mode, :draft)
         |> assign(:baseline_target_id, nil)
         |> assign(:selected_open_dataset_id, nil)
         |> assign_form(params, add_error(changeset, :dataset_id, message))}

      _other ->
        {:noreply,
         assign_form(
           socket,
           params,
           add_error(changeset, :dataset_id, "failed to promote snapshot")
         )}
    end
  end

  @impl true
  def handle_event("request_baseline_approval", _params, socket) do
    params = socket.assigns.form_params
    changeset = promotion_form(params, action: :validate)

    baseline_target =
      find_dataset(socket.assigns.sealed_datasets, socket.assigns.baseline_target_id)

    with true <- changeset.valid?,
         %{} = dataset <- baseline_target,
         {:ok, expected_output} <- decode_expected_output(get_field(changeset, :expected_output)),
         request_attrs <-
           Eval.DatasetPromotion.build_promotion_attrs(
             socket.assigns.promotion_context,
             dataset.id,
             get_field(changeset, :notes),
             expected_output
           ),
         {:ok, _approval} <- Workflows.request_baseline_promotion(request_attrs) do
      send(
        self(),
        {:baseline_promotion_requested,
         %{dataset_name: dataset.name, dataset_version: dataset.version}}
      )

      {:noreply, socket}
    else
      false ->
        {:noreply, assign_form(socket, params, changeset)}

      nil ->
        {:noreply,
         socket
         |> refresh_datasets()
         |> assign(:mode, :draft)
         |> assign_form(
           params,
           add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
         )}

      {:error, %Jason.DecodeError{}} ->
        {:noreply,
         assign_form(socket, params, add_error(changeset, :expected_output, "must be valid JSON"))}

      {:error, %Ecto.Changeset{} = result_changeset} ->
        message =
          first_error(result_changeset, :dataset_id, "failed to request baseline approval")

        {:noreply,
         socket
         |> refresh_datasets()
         |> assign_form(params, add_error(changeset, :dataset_id, message))}

      _other ->
        {:noreply,
         assign_form(
           socket,
           params,
           add_error(changeset, :dataset_id, "failed to request baseline approval")
         )}
    end
  end

  @impl true
  def render(assigns) do
    baseline_target = find_dataset(assigns.sealed_datasets, assigns.baseline_target_id)

    assigns =
      assigns
      |> assign(:baseline_target, baseline_target)
      |> assign(
        :source_variant,
        read_context_value(assigns.promotion_context, :source_variant) || "original"
      )
      |> assign(
        :source_label,
        variant_label(read_context_value(assigns.promotion_context, :source_variant))
      )
      |> assign(
        :snapshot,
        read_context_value(assigns.promotion_context, :promotion_snapshot) || %{}
      )

    ~H"""
    <div id={@id} class="promote-dataset-modal">
      <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
        <input type="hidden" name={@form[:dataset_id].name} value={@form[:dataset_id].value || ""} />

        <.panel variant={:raised}>
          <:eyebrow>Draft promotion</:eyebrow>
          <:title>
            <%= if @mode == :baseline_confirm, do: "Baseline Promotion Approval", else: "Promote Trace to Draft Dataset" %>
          </:title>
          <p>
            <%= @source_label %> stays frozen as one dataset snapshot, with workflow provenance preserved on insert or approval request.
          </p>
        </.panel>

        <.form_section
          title="Source evidence"
          description="Stable workflow identifiers and escaped source evidence reconstructed by Dataset Builder."
        >
          <div class="flex flex-wrap items-center gap-2">
            <.badge tone={:trace} label={@source_label} />
            <.badge tone={:neutral} label={"run #{read_context_value(@promotion_context, :workflow_run_id)}"} />
            <.badge tone={:neutral} label={"step #{read_context_value(@promotion_context, :workflow_step_id)}"} />
          </div>

          <.raw_evidence label="Promotion snapshot summary">
            {Jason.encode_to_iodata!(@snapshot, pretty: true)}
          </.raw_evidence>
        </.form_section>

        <.form_section
          title="Promotion details"
          description="Operator notes and expected output are stored with the dataset item or approval request."
        >
          <div class="grid gap-4 lg:grid-cols-2">
            <.field id={@form[:notes].id} label="Operator Notes">
              <textarea
                id={@form[:notes].id}
                name={@form[:notes].name}
                rows="5"
                class="w-full rounded-xl border px-3 py-2 text-sm"
              ><%= @form[:notes].value %></textarea>
            </.field>

            <.field
              id={@form[:expected_output].id}
              label="Expected Output (JSON)"
              error={field_error(@form, :expected_output)}
            >
              <textarea
                id={@form[:expected_output].id}
                name={@form[:expected_output].name}
                rows="7"
                class="w-full rounded-xl border px-3 py-2 font-mono text-sm"
              ><%= @form[:expected_output].value %></textarea>
            </.field>
          </div>
        </.form_section>

        <%= if @mode == :baseline_confirm do %>
          <.panel variant={:raised}>
            <:eyebrow>Approval required</:eyebrow>
            <:title>Baseline Promotion Approval</:title>
            <p>
              Promote this draft evidence into a sealed release-driving baseline?
              The baseline dataset will remain immutable until an explicit approval workflow records the decision.
            </p>

            <div :if={@baseline_target} class="mt-4">
              <p><strong><%= @baseline_target.name %></strong></p>
              <p class="font-mono">v<%= @baseline_target.version %></p>
            </div>
          </.panel>
        <% else %>
          <div class="space-y-4">
            <.form_section title="Open draft datasets" description="Only draft/open datasets accept direct promotion.">
              <.badge tone={:pass} label="Draft open" />

              <.empty_state :if={@open_datasets == []} title="No open datasets">
                Only draft/open datasets accept direct promotion; sealed baselines require approval.
              </.empty_state>

              <div :if={@open_datasets != []} class="mt-4 space-y-3">
                <div :for={dataset <- @open_datasets} class="space-y-2">
                  <.button
                    type="button"
                    variant={if(@selected_open_dataset_id == dataset.id, do: :primary, else: :ghost)}
                    phx-click="select_open_dataset"
                    phx-value-dataset-id={dataset.id}
                    phx-target={@myself}
                    class="w-full justify-between"
                  >
                    <span>
                      <span><%= dataset.name %></span>
                      <span class="ml-2 font-mono">v<%= dataset.version %></span>
                    </span>
                    <span><%= if @selected_open_dataset_id == dataset.id, do: "Selected", else: "Select" %></span>
                  </.button>

                  <div :if={source_run_links(@source_run_links_by_dataset_id, dataset.id) != []} class="flex flex-wrap gap-2">
                    <a
                      :for={source <- source_run_links(@source_run_links_by_dataset_id, dataset.id)}
                      href={source_run_path(source, @scoria_base)}
                      class="scoria-button scoria-button--ghost scoria-button--sm"
                    >
                      Open source run
                    </a>
                  </div>
                </div>
              </div>
            </.form_section>

            <.form_section
              title="Sealed baseline"
              description="Sealed baselines stay immutable until an explicit approval workflow records the decision."
            >
              <.badge tone={:warn} label="Approval required" />

              <.empty_state :if={@sealed_datasets == []} title="No sealed baselines">
                Only draft/open datasets accept direct promotion; sealed baselines require approval.
              </.empty_state>

              <div :if={@sealed_datasets != []} class="mt-4 space-y-3">
                <div
                  :for={dataset <- @sealed_datasets}
                  class="flex flex-wrap items-center justify-between gap-4 rounded-xl border px-4 py-3"
                >
                  <div>
                    <p><strong><%= dataset.name %></strong></p>
                    <p class="font-mono">v<%= dataset.version %></p>
                    <p>This sealed baseline is immutable until an explicit approval workflow records the decision.</p>
                  </div>

                  <.button
                    type="button"
                    variant={:ghost}
                    size={:sm}
                    phx-click="select_sealed_dataset"
                    phx-value-dataset-id={dataset.id}
                    phx-target={@myself}
                  >
                    Request baseline approval
                  </.button>

                  <div :if={source_run_links(@source_run_links_by_dataset_id, dataset.id) != []} class="flex flex-wrap gap-2">
                    <a
                      :for={source <- source_run_links(@source_run_links_by_dataset_id, dataset.id)}
                      href={source_run_path(source, @scoria_base)}
                      class="scoria-button scoria-button--ghost scoria-button--sm"
                    >
                      Open source run
                    </a>
                  </div>
                </div>
              </div>
            </.form_section>
          </div>
        <% end %>

        <.field :if={field_error(@form, :dataset_id)} id={@form[:dataset_id].id} label="Dataset target" error={field_error(@form, :dataset_id)}>
          <input type="hidden" />
        </.field>

        <div class="flex justify-end gap-3">
          <.button
            :if={@mode == :baseline_confirm}
            type="button"
            variant={:ghost}
            phx-click="back_to_draft"
            phx-target={@myself}
          >
            Back
          </.button>

          <.button type="button" variant={:ghost} phx-click="close_modal">
            Cancel
          </.button>

          <.button
            :if={@mode == :draft}
            type="submit"
            variant={:primary}
            phx-disable-with="Promoting snapshot..."
          >
            Promote snapshot
          </.button>

          <.button
            :if={@mode == :baseline_confirm}
            type="button"
            variant={:primary}
            phx-click="request_baseline_approval"
            phx-target={@myself}
          >
            Confirm baseline request
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  defp initial_form_params(promotion_context) do
    %{
      "dataset_id" => "",
      "notes" => normalize_string(read_context_value(promotion_context, :notes)),
      "expected_output" =>
        promotion_context
        |> read_context_value(:expected_output)
        |> normalize_map()
        |> Jason.encode!(pretty: true)
    }
  end

  defp promotion_form(params, opts \\ []) do
    types = %{dataset_id: :integer, notes: :string, expected_output: :string}

    changeset =
      {%{}, types}
      |> cast(params, [:dataset_id, :notes, :expected_output])
      |> maybe_validate_required(opts)
      |> validate_expected_output()

    case Keyword.get(opts, :action) do
      nil -> changeset
      action -> Map.put(changeset, :action, action)
    end
  end

  defp maybe_validate_required(changeset, opts) do
    if Keyword.get(opts, :require_dataset, false) do
      validate_required(changeset, [:dataset_id])
    else
      changeset
    end
  end

  defp validate_expected_output(changeset) do
    validate_change(changeset, :expected_output, fn :expected_output, value ->
      case decode_expected_output(value) do
        {:ok, _map} -> []
        {:error, _reason} -> [expected_output: "must be valid JSON"]
      end
    end)
  end

  defp decode_expected_output(value) when value in [nil, ""], do: {:ok, %{}}

  defp decode_expected_output(value) do
    Jason.decode(value)
  end

  defp load_dataset_groups do
    Eval.list_datasets()
    |> Enum.split_with(&(&1.state == :open))
  end

  defp refresh_datasets(socket) do
    {open_datasets, sealed_datasets} = load_dataset_groups()

    source_run_links_by_dataset_id =
      source_run_links_by_dataset_id(open_datasets ++ sealed_datasets)

    socket
    |> assign(:open_datasets, open_datasets)
    |> assign(:sealed_datasets, sealed_datasets)
    |> assign(:source_run_links_by_dataset_id, source_run_links_by_dataset_id)
  end

  defp assign_form(socket, params, changeset) do
    socket
    |> assign(:form_params, params)
    |> assign(:form, to_form(changeset, as: "promotion"))
  end

  defp selected_open_dataset_id(params, datasets) do
    dataset_id = params |> Map.get("dataset_id") |> parse_dataset_id()

    if Enum.any?(datasets, &(&1.id == dataset_id)), do: dataset_id, else: nil
  end

  defp parse_dataset_id(nil), do: nil
  defp parse_dataset_id(""), do: nil
  defp parse_dataset_id(value) when is_integer(value), do: value
  defp parse_dataset_id(value) when is_binary(value), do: String.to_integer(value)

  defp find_dataset(_datasets, nil), do: nil
  defp find_dataset(datasets, dataset_id), do: Enum.find(datasets, &(&1.id == dataset_id))

  defp source_run_links_by_dataset_id(datasets) do
    Map.new(datasets, fn dataset -> {dataset.id, source_run_links_for_dataset(dataset)} end)
  end

  defp source_run_links_for_dataset(dataset) do
    dataset.id
    |> Eval.list_dataset_items()
    |> Enum.flat_map(fn item ->
      case item_source_run_id(item) do
        nil -> []
        run_id -> [%{run_id: run_id, origin_id: item.id}]
      end
    end)
    |> Enum.uniq_by(&{&1.run_id, &1.origin_id})
  end

  defp item_source_run_id(item) do
    metadata = item.metadata || %{}
    read_context_value(metadata, :source_run_id) || read_context_value(metadata, :workflow_run_id)
  end

  defp source_run_links(source_run_links_by_dataset_id, dataset_id) do
    Map.get(source_run_links_by_dataset_id, dataset_id, [])
  end

  defp source_run_path(source, base_path) do
    query = URI.encode_query([{"from", "dataset:#{source.origin_id}"}])
    "#{base_path}/workflows/#{source.run_id}?#{query}"
  end

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"

  defp normalize_map(nil), do: %{}
  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_value), do: %{}

  defp normalize_string(nil), do: ""
  defp normalize_string(value), do: to_string(value)

  defp read_context_value(context, key) when is_map(context),
    do: Map.get(context, key, Map.get(context, to_string(key)))

  defp read_context_value(_context, _key), do: nil

  defp first_error(changeset, field, fallback) do
    case changeset.errors[field] do
      {message, _opts} -> message
      _other -> fallback
    end
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

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

defmodule Scoria.Install.Report do
  @summary_order [:create, :update, :no_op, :manual_review]

  def check_result(plan) do
    do_check_result(plan)
  end

  def render_human(plan, mode) do
    mode_label = mode_label(mode)

    entry_lines =
      plan.entries
      |> Enum.flat_map(fn entry ->
        remediation = remediation_payload(entry)

        [
          "#{entry.order}. #{entry.surface}",
          "   classification: #{classification_label(entry.classification)}",
          "   target path: #{entry.target_path}",
          "   rationale: #{entry.rationale}"
        ] ++
          human_remediation_lines(remediation) ++
          [
            ""
          ]
      end)

    summary_lines =
      @summary_order
      |> Enum.map(fn key ->
        "  #{classification_label(key)}: #{Map.get(plan.summary, key, 0)}"
      end)

    [
      "Scoria install plan (mode: #{mode_label})",
      "",
      entry_lines,
      "Summary:",
      summary_lines
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  def render_json(plan, mode) do
    payload =
      plan
      |> normalize_plan_for_json()
      |> Map.put(:mode, mode_label(mode))

    if Code.ensure_loaded?(Jason) do
      Jason.encode!(payload, pretty: true)
    else
      inspect(payload, pretty: true)
    end
  end

  def trailer_line(%{status: status, exit_code: exit_code}) do
    "SCORIA_CHECK_RESULT status=#{status} exit_code=#{exit_code}"
  end

  defp do_check_result(%{entries: entries}) when is_list(entries) do
    classifications = MapSet.new(Enum.map(entries, & &1.classification))

    cond do
      MapSet.member?(classifications, :manual_review) ->
        %{status: :manual_review, exit_code: 1}

      MapSet.member?(classifications, :create) or MapSet.member?(classifications, :update) ->
        %{status: :drift, exit_code: 1}

      Enum.all?(entries, &(&1.classification == :no_op)) ->
        %{status: :compliant, exit_code: 0}

      true ->
        %{status: :error, exit_code: 2}
    end
  end

  defp do_check_result(_), do: %{status: :error, exit_code: 2}

  defp normalize_plan_for_json(plan) do
    %{
      schema_version: plan.schema_version,
      mode: mode_label(plan.mode),
      entries: Enum.map(plan.entries, &normalize_entry_for_json/1),
      summary: normalize_json_value(plan.summary)
    }
  end

  defp normalize_entry_for_json(entry) do
    normalized_entry = Map.put(entry, :remediation, remediation_payload(entry))

    normalized_entry
    |> Enum.map(fn {key, value} -> {key, normalize_json_value(value)} end)
    |> Enum.into(%{})
  end

  defp normalize_json_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested_value} -> {key, normalize_json_value(nested_value)} end)
    |> Enum.into(%{})
  end

  defp normalize_json_value(value) when is_list(value),
    do: Enum.map(value, &normalize_json_value/1)

  defp normalize_json_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_json_value(value), do: value

  defp human_remediation_lines(remediation) do
    [
      "   remediation:",
      "     reason_code: #{remediation.reason_code}",
      "     summary: #{remediation.summary}",
      "     steps:"
    ] ++
      Enum.map(remediation.steps, &"       - #{&1}") ++
      ["     verify_command: #{remediation.verify_command}"]
  end

  defp remediation_payload(entry) do
    remediation = Map.get(entry, :remediation) || %{}

    %{
      reason_code:
        remediation
        |> Map.get(:reason_code)
        |> fallback(Map.get(remediation, "reason_code"), "unknown"),
      summary:
        remediation
        |> Map.get(:summary)
        |> fallback(Map.get(remediation, "summary"), "No remediation summary provided."),
      steps:
        remediation
        |> Map.get(:steps)
        |> fallback(Map.get(remediation, "steps"), [])
        |> normalize_steps(),
      verify_command:
        remediation
        |> Map.get(:verify_command)
        |> fallback(Map.get(remediation, "verify_command"), "mix scoria.install --check")
    }
  end

  defp fallback(primary, secondary, default) do
    cond do
      present?(primary) -> primary
      present?(secondary) -> secondary
      true -> default
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_), do: true

  defp normalize_steps(steps) when is_list(steps), do: steps
  defp normalize_steps(step) when is_binary(step), do: [step]
  defp normalize_steps(_), do: []

  defp mode_label(:check), do: "check"
  defp mode_label(:dry_run), do: "dry_run"
  defp mode_label(mode) when is_binary(mode), do: mode
  defp mode_label(mode) when is_atom(mode), do: Atom.to_string(mode)
  defp mode_label(mode), do: to_string(mode)

  defp classification_label(:no_op), do: "no-op"
  defp classification_label(:manual_review), do: "manual-review"
  defp classification_label(classification), do: Atom.to_string(classification)
end

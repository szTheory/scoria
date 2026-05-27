defmodule Scoria.Install.Contract do
  @moduledoc """
  Canonical installer contract: planner classifications, operator projection,
  automation trailer prefix, and default verify command.

  Optional top-level `manifest` JSON metadata is additive and does not affect
  `check_result/1` or tri-state exit semantics.
  """

  @operator_summary_keys [:would_change, :already_present, :skipped, :manual_review]

  def trailer_prefix, do: "SCORIA_CHECK_RESULT"

  def default_verify_command, do: "mix scoria.install --check"

  def planner_classifications, do: [:create, :update, :no_op, :manual_review]

  def operator_summary_keys, do: @operator_summary_keys

  def schema_version, do: "1.0"

  def manifest_check_role, do: "informational"

  def manifest_apply_role, do: "freshness_baseline"

  def manifest_json_keys, do: [:present, :path, :schema_version, :check_role, :apply_role]

  def project_entry(classification, drift_reason_code, mode)
      when classification in [:create, :update, :no_op, :manual_review] and
             mode in [:dry_run, :check, :apply] do
    cond do
      classification == :manual_review ->
        :manual_review

      classification == :no_op and drift_reason_code == "optional_surface_absent" ->
        :skipped

      classification == :no_op ->
        :already_present

      classification in [:create, :update] and mode in [:dry_run, :check] ->
        :would_change

      classification in [:create, :update] and mode == :apply ->
        :already_present
    end
  end

  def project_summary(entries, mode) when is_list(entries) do
    Enum.reduce(entries, empty_operator_summary(), fn entry, acc ->
      bucket =
        project_entry(
          entry.classification,
          drift_reason_code(entry),
          mode
        )

      Map.update!(acc, bucket, &(&1 + 1))
    end)
  end

  defp empty_operator_summary do
    %{would_change: 0, already_present: 0, skipped: 0, manual_review: 0}
  end

  defp drift_reason_code(entry) do
    case Map.get(entry, :drift) do
      %{reason_code: code} when is_binary(code) -> code
      %{"reason_code" => code} when is_binary(code) -> code
      _ -> nil
    end
  end
end

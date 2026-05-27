defmodule Scoria.WarningInventory.Cluster do
  @moduledoc """
  Stable cluster registry for compiler warning classification.

  Rules are evaluated in declaration order; the first match wins.
  """

  @type signal_kind :: :compile_warning | :ex_unit | :runtime_log
  @type warning_map :: %{
          file: String.t(),
          line: non_neg_integer(),
          message: String.t(),
          signal_kind: signal_kind()
        }

  @doc """
  Returns a stable `cluster_id` atom for a parsed warning map.
  """
  @spec match(warning_map()) :: atom()
  def match(%{file: file, message: message, signal_kind: signal_kind}) do
    cond do
      knowledge_migration_redefine?(file, message) -> :knowledge_migration_redefine
      test_unused_binding?(file, message) -> :test_unused_binding
      test_dead_default_args?(file, message) -> :test_dead_default_args
      host_overlay_test_path?(file) -> :host_overlay_test_path
      host_proof_generated_compile?(file) -> :host_proof_generated_compile
      liveview_async_teardown?(message, signal_kind) -> :liveview_async_teardown
      signal_kind == :compile_warning -> :unclassified_compile
      true -> :unclassified_compile
    end
  end

  defp knowledge_migration_redefine?(file, message) do
    String.contains?(file, "priv/repo/knowledge_migrations/") or
      String.contains?(String.downcase(message), "redefining module")
  end

  defp test_unused_binding?(file, message) do
    test_file?(file) and Regex.match?(~r/variable ".*" is unused/u, message)
  end

  defp test_dead_default_args?(file, message) do
    test_file?(file) and
      Regex.match?(~r/default arguments .* never used/u, message)
  end

  defp host_proof_generated_compile?(file) do
    String.contains?(file, "test/support/scoria/host_app_proof/") and
      not String.contains?(file, "host_app_proof/overlay/test/")
  end

  defp host_overlay_test_path?(file) do
    String.contains?(file, "host_app_proof/overlay/test/")
  end

  defp liveview_async_teardown?(message, signal_kind) do
    signal_kind in [:runtime_log, :ex_unit] and
      Regex.match?(~r/(async|teardown|sandbox)/iu, message)
  end

  defp test_file?(file), do: String.starts_with?(file, "test/")
end

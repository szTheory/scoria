defmodule ScoriaWeb.ScanConventionGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  D-11 scan-convention guard (warning-grade, Phase-38 source-scan style — mirrors
  `ui_drift_guard_test.exs` + `ds06_drift_guard_test.exs`).

  Asserts filter/scope state on scan pages is not held ONLY in socket assigns —
  it must be sourced from and written back to the URL via `push_patch` +
  `handle_params`, so it survives reconnect and is shareable/deep-linkable
  (D-09). Migration target: `review_queue_live.ex` (previously socket-only
  `:filters`). `approvals_live/index.ex`'s Pending|Decided `:scope` is the
  existing exemplar (D-09/D-17, Plan 07).

  **SORT is explicitly EXEMPT** (D-09 option (B), locked in Plan 05): sort stays
  in socket assigns as a per-session view preference. `dataset_live/index.ex`'s
  `:sort_by`/`:sort_dir` must NOT be red-flagged by this guard — it holds no
  `@url_backed_state` entry and is confirmed as the sort exemplar below.

  Explicit-list, warning-grade style; Phase-41 hardens into a LiveViewTest proof.
  """

  # Scan pages that hold real filter/scope state (not sort). Each entry names the
  # assign key(s) that must be sourced from the URL inside handle_params/3.
  @url_backed_state %{
    "lib/scoria_web/live/review_queue_live.ex" => ~w(filters),
    "lib/scoria_web/live/approvals_live/index.ex" => ~w(scope)
  }

  @dataset_live_path "lib/scoria_web/live/dataset_live/index.ex"
  @sort_exempt_keys ~w(sort_by sort_dir)

  test "filter/scope state on scan pages is assigned inside handle_params/3 (URL-sourced, not mount-only)" do
    offenders =
      for {path, keys} <- @url_backed_state, key <- keys, reduce: [] do
        acc ->
          if handle_params_assigns_key?(path, key) do
            acc
          else
            [{path, key} | acc]
          end
      end

    assert offenders == [],
           """
           D-11 drift guard: scan-page filter/scope state is not sourced from the URL
           inside handle_params/3 (D-09):
           #{Enum.map_join(offenders, "\n", fn {path, key} -> "  #{path}: :#{key}" end)}
             Fix: assign the key inside handle_params/3 from the incoming URL params
             (see review_queue_live.ex / approvals_live/index.ex for the idiom).
           """
  end

  test "handle_event clauses never mutate filter/scope state directly without push_patch (socket-only regression)" do
    offenders =
      for {path, keys} <- @url_backed_state, reduce: [] do
        acc ->
          case socket_only_mutations(path, keys) do
            [] -> acc
            clauses -> [{path, clauses} | acc]
          end
      end

    assert offenders == [],
           """
           D-11 drift guard: found a handle_event clause that assigns filter/scope
           state directly (socket-only) instead of routing through push_patch + the
           URL (D-09):
           #{Enum.map_join(offenders, "\n", fn {path, clauses} -> "  #{path}: #{Enum.join(clauses, ", ")}" end)}
           """
  end

  test "sort (D-09 option B) is explicitly exempt — dataset_live is not red-flagged" do
    refute Map.has_key?(@url_backed_state, @dataset_live_path),
           "D-11 drift guard: dataset_live must not gain a @url_backed_state entry — " <>
             "sort is D-09 option (B), explicitly exempt from this guard."

    source = File.read!(@dataset_live_path)

    for key <- @sort_exempt_keys do
      assert Regex.match?(~r/assign\((?:socket, )?:#{key},/, source),
             "dataset_live no longer assigns :#{key} — update @sort_exempt_keys " <>
               "(or this test) if the D-09 option (B) sort implementation changed."
    end

    # The sort handle_event must remain a plain socket assign (no push_patch) —
    # confirms this file legitimately stays outside URL-backed scan state.
    sort_clause = clause(source, "def handle_event(\"sort\"")

    assert sort_clause,
           "dataset_live's sort handle_event clause was not found — update this test " <>
             "if the D-09 option (B) sort handler was renamed."

    refute String.contains?(sort_clause, "push_patch"),
           "dataset_live's sort handler now calls push_patch — sort would need to " <>
             "move into @url_backed_state (D-09 option A) and this exemption removed."
  end

  defp handle_params_assigns_key?(path, key) do
    source = File.read!(path)

    source
    |> function_clauses()
    |> Enum.filter(&String.starts_with?(&1, "def handle_params("))
    |> Enum.any?(&Regex.match?(~r/assign\((?:socket, )?:#{key},/, &1))
  end

  defp socket_only_mutations(path, keys) do
    source = File.read!(path)

    source
    |> function_clauses()
    |> Enum.filter(&String.starts_with?(&1, "def handle_event("))
    |> Enum.flat_map(fn clause ->
      for key <- keys,
          Regex.match?(~r/assign\((?:socket, )?:#{key},/, clause),
          not String.contains?(clause, "push_patch") do
        clause_name(clause)
      end
    end)
  end

  defp clause(source, prefix) do
    source
    |> function_clauses()
    |> Enum.find(&String.starts_with?(&1, prefix))
  end

  defp clause_name(clause) do
    case Regex.run(~r/^def handle_event\("([^"]+)"/, clause) do
      [_, name] -> "handle_event(#{inspect(name)}, ...)"
      nil -> "handle_event(...)"
    end
  end

  # Splits a module's source into top-level (2-space-indented) function-clause
  # chunks, each starting at "def "/"defp " and running to (not including) the
  # next top-level def/defp. Source-scan-only: doesn't distinguish multiple
  # clauses of the same name (fine for this guard's currently single-clause
  # handle_params/handle_event targets).
  defp function_clauses(source) do
    ("\n" <> source)
    |> String.split(~r/\n  (?=def |defp )/)
    |> Enum.reject(&(&1 == ""))
  end
end

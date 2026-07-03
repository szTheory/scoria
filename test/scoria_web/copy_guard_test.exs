defmodule ScoriaWeb.CopyGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  D-26 copy guard (warning-grade, Phase-38 source-scan style — mirrors
  `ui_drift_guard_test.exs` + `ds06_drift_guard_test.exs`'s allow-list /
  descriptive-failure style). Scoped to page LiveViews only
  (`lib/scoria_web/live/**/*.ex`).

  Three assertions:

  1. No schema/module names (a CamelCase compound, e.g. `EvalSpecs`,
     `PromptTemplate`) in a static-literal page-outline title or region
     `:title`/`:eyebrow` — catches the fixed `eval_spec (EvalSpecs)` offender
     (D-23) class.
  2. No opaque ID (`entity_id` / `*_run_id` / `*_session_id`) interpolated bare
     into a page-outline title, or a region `:title`/`:eyebrow` slot — catches
     the fixed `prompt entity_id` offender (D-23) class. Usage wrapped in the
     sanctioned `<.id>` evidence primitive (labelled, copyable, truncated) is
     NOT an offender — `<.id>` is the correct way to surface an opaque ID.
  3. Status renders only via the allow-list of approved label functions
     (`status_label`, `state_label`, `delegated_status_label`, `ApprovalCopy.*`,
     and the `*Copy.*` per-domain modules) — never a raw status/severity/state
     atom passed straight to `label={}`. Catches the `connectors runtime.status`
     offender (D-23) class (and, discovered during this plan, the equivalent
     `incidents severity` raw-atom badges — fixed alongside this guard so it is
     green on arrival).

  Warning-grade, explicit-offender style; Phase-41 hardens into a LiveViewTest
  DOM assertion.
  """

  @page_glob "lib/scoria_web/live/**/*.ex"
  # dataset_live/promote_component.ex is dialog-scoped (rendered as a
  # <.live_component> inside dataset_live/index.ex's <.drawer
  # id="dataset-promote-drawer">) — excluded for the same D-03 reason
  # single_header_guard_test.exs excludes it.
  @excluded ~w(lib/scoria_web/live/dataset_live/promote_component.ex)

  # A CamelCase compound word: an internal lowercase->uppercase transition
  # (e.g. "EvalSpecs", "PromptTemplate"). A single capitalized word ("Dataset",
  # "Approvals") does NOT match — avoids flagging ordinary Title Case copy.
  @module_name_regex ~r/\b[A-Z][a-zA-Z0-9]*[a-z][A-Z][a-zA-Z0-9]*\b/

  @opaque_id_regex ~r/(?:entity_id|\w*_run_id|\w*_session_id)/

  # A `label={...}` binding whose ENTIRE content is a bare dotted field access
  # ending in status/severity/state (e.g. `label={runtime.status}`) — no
  # function call. Any wrapping function call (status_label(...),
  # ConnectorCopy.runtime_status_label(...), a local *_label(...) helper, ...)
  # introduces "(" before the closing "}" and cannot match this pattern, so it
  # is trusted per the allow-list convention rather than name-enumerated.
  @raw_status_label_regex ~r/label=\{([a-zA-Z0-9_.@]+\.(?:status|severity|state))\}/

  test "no schema/module name (CamelCase compound) in a static-literal page-outline or region heading" do
    offenders =
      for path <- page_files(),
          text <- heading_literal_texts(path),
          Regex.match?(@module_name_regex, text) do
        {path, text}
      end

    assert offenders == [],
           """
           D-26 copy guard: schema/module name found in a page-outline title or
           region :title/:eyebrow — orientation copy must never leak an Elixir
           module name (e.g. "Evaluation Rubrics (EvalSpecs)" -> "Evaluation Rubrics").
           #{Enum.map_join(offenders, "\n", fn {path, text} -> "  #{path}: #{inspect(text)}" end)}
           """
  end

  test "no opaque ID interpolated bare into a page-outline title or region :title/:eyebrow" do
    offenders =
      for path <- page_files(),
          chunk <- heading_slot_chunks(path),
          Regex.match?(@opaque_id_regex, chunk),
          not String.contains?(chunk, "<.id") do
        {path, chunk}
      end

    assert offenders == [],
           """
           D-26 copy guard: an opaque ID (entity_id / *_run_id / *_session_id) is
           interpolated bare into a page-outline title or region :title/:eyebrow
           slot. Wrap it in the sanctioned <.id> evidence primitive instead (or
           lead with a human-readable name and demote the ID to evidence).
           #{Enum.map_join(offenders, "\n", fn {path, chunk} -> "  #{path}: #{inspect(String.slice(chunk, 0, 120))}" end)}
           """
  end

  test "status/severity/state renders only via an approved label function, never a raw atom" do
    offenders =
      for path <- page_files(),
          source = File.read!(path),
          [_, expr] <- Regex.scan(@raw_status_label_regex, source) do
        {path, expr}
      end

    assert offenders == [],
           """
           D-26 copy guard: a badge/label renders a raw status/severity/state field
           directly, bypassing the approved label-function allow-list (status_label,
           state_label, delegated_status_label, ApprovalCopy.*, *Copy.*):
           #{Enum.map_join(offenders, "\n", fn {path, expr} -> "  #{path}: label={#{expr}}" end)}
             Fix: wrap the raw value in an approved *Copy label function
             (e.g. label={IncidentCopy.severity_label(incident.severity)}).
           """
  end

  defp page_files, do: @page_glob |> Path.wildcard() |> Enum.reject(&(&1 in @excluded))

  # Static-literal text only: title="..." attrs on page_header/stub_page, and
  # <:title>/<:eyebrow> slot bodies containing neither "{" (HEEx interpolation)
  # nor "<" (nested tags / EEx <%= %>). Matches the D-05 guard's "static
  # literals only" convention for the module-name check (rule 1), which only
  # cares about hardcoded copy — a dynamic expression can't literally spell a
  # module name as source text.
  defp heading_literal_texts(path) do
    source = File.read!(path)

    title_attr =
      Regex.scan(~r/<\.(?:page_header|stub_page)\s[^>]*?title="([^"]+)"/s, source)
      |> Enum.map(fn [_, title] -> title end)

    slot_text =
      Regex.scan(~r/<:(?:title|eyebrow)>([^{<][^{<]*)<\/:(?:title|eyebrow)>/, source)
      |> Enum.map(fn [_, text] -> text end)

    title_attr ++ slot_text
  end

  # Full slot content (static or dynamic) for the opaque-ID check — the
  # offending shape IS a dynamic interpolation (e.g. <%= @x.entity_id %>), so
  # unlike rule 1 this must not filter out dynamic content.
  defp heading_slot_chunks(path) do
    source = File.read!(path)

    title_attr_dynamic =
      Regex.scan(~r/<\.(?:page_header|stub_page|object_header)\s[^>]*?title=\{(.*?)\}/s, source)
      |> Enum.map(fn [_, chunk] -> chunk end)

    slots =
      Regex.scan(~r/<:(?:title|eyebrow)>(.*?)<\/:(?:title|eyebrow)>/s, source)
      |> Enum.map(fn [_, chunk] -> chunk end)

    title_attr_dynamic ++ slots
  end
end

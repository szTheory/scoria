defmodule ScoriaWeb.MotionDriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  MOTION-01 browserless source-scan guard (Phase 40, D-19 — warning-grade).

  Proves the CSS motion layer stays tokenized and keyframe-disciplined without a
  browser, modeled directly on `ui_drift_guard_test.exs`'s `Path.wildcard` +
  `Regex.match?` + collect-offenders idiom:

    (i)   zero `transition: all` / `transition-property: all` anywhere in
          `assets/css/**` (already green — this guard proves it stays zero);
    (ii)  every `animation:` declaration uses `--scoria-dur-*` AND
          `--scoria-ease-*` EXCEPT declarations whose animation-NAME is in the
          two-entry allow-list (keyed on NAME, not the literal duration
          string, so a future duration edit on either exception can't
          silently defeat the guard — research Open Question #1);
    (iii) every `@keyframes` body animates ONLY transform/opacity/border-color
          (border-color is the documented D-21 exception — this is a
          KEYFRAME rule only; transitions legitimately animate paint props
          like background-color/box-shadow/filter and must NOT be flagged);
    (iv)  no `@keyframes` at-rule appears in any file other than
          `assets/css/05-motion.css`.

  Both `scoria-skeleton-pulse` (D-20, opacity-only loading exception,
  `04-components.css:1610`) AND `scoria-approval-pulse` (D-21, border-color
  pulse whose 600ms duration has no matching `--scoria-dur-*` token,
  `05-motion.css:46`) MUST be allow-listed — missing either produces a
  false-RED the moment this guard lands (research addendum).

  Warning-grade this phase: proves the already-green baseline, does not add a
  blocking ratchet beyond it. Phase 41 hardens. `ds06_drift_guard_test.exs`
  and `token_contrast_guard_test.exs` are untouched by this file and must stay
  green independently.
  """

  # Keyed on animation NAME, not the literal duration string (research Open
  # Question #1 resolution) — a future duration edit on either exception must
  # not silently defeat this guard.
  @allow_listed_animation_names ~w(scoria-skeleton-pulse scoria-approval-pulse)

  @keyframe_allowed_props ~w(transform opacity border-color)

  @css_glob "assets/css/**/*.css"
  @motion_file "assets/css/05-motion.css"

  test "no transition: all / transition-property: all anywhere in assets/css/** (D-19(i))" do
    offenders =
      for path <- css_files(),
          source = strip_comments(File.read!(path)),
          matches = source |> then(&Regex.scan(~r/\btransition(?:-property)?\s*:\s*all\b/, &1)) |> List.flatten(),
          matches != [] do
        {path, matches}
      end

    assert offenders == [],
           """
           MOTION-01 drift guard: found `transition: all` / `transition-property: all`.
           D-19(i) requires zero — this is an already-green baseline invariant, do not
           reintroduce a catch-all transition:

           #{inspect(offenders, pretty: true)}
           """
  end

  test "every animation: declaration is tokenized except the two D-20/D-21 allow-listed exceptions (D-19(ii))" do
    offenders =
      for path <- css_files(),
          {name, decl} <- animation_declarations(path),
          name not in @allow_listed_animation_names,
          not tokenized?(decl) do
        {path, name, decl}
      end

    assert offenders == [],
           """
           MOTION-01 drift guard: non-tokenized `animation:` declaration found outside the
           two documented allow-listed exceptions (scoria-skeleton-pulse / scoria-approval-pulse).
           Every animation must use both --scoria-dur-* AND --scoria-ease-* tokens unless its
           animation-name is explicitly allow-listed:

           #{inspect(offenders, pretty: true)}
           """
  end

  test "both allow-listed animation names are present on the current tree (false-RED guard, research addendum)" do
    all_names =
      css_files()
      |> Enum.flat_map(&animation_declarations/1)
      |> Enum.map(fn {name, _decl} -> name end)

    missing = @allow_listed_animation_names -- all_names

    assert missing == [],
           """
           MOTION-01 drift guard: expected BOTH allow-listed animation names present on the
           current tree (scoria-skeleton-pulse AND scoria-approval-pulse) — missing:
           #{inspect(missing)}.

           Allow-listing only one of the two exceptions is a documented false-RED (research
           addendum #3) — if one was legitimately removed from the CSS, shrink the allow-list
           in this test file to match; do not let it silently rot as a dead entry.
           """
  end

  test "every @keyframes body animates only transform/opacity/border-color (D-19(iii))" do
    offenders =
      for path <- css_files(),
          {name, body} <- keyframe_blocks(path),
          prop <- keyframe_properties(body),
          prop not in @keyframe_allowed_props do
        {path, name, prop}
      end

    assert offenders == [],
           """
           MOTION-01 drift guard: @keyframes animating a disallowed property. Only
           transform/opacity/border-color are permitted inside a @keyframes body
           (border-color is the documented D-21 scoria-approval-pulse exception; paint
           properties like background-color/box-shadow/filter are legitimate on
           *transitions*, not keyframes):

           #{inspect(offenders, pretty: true)}
           """
  end

  test "no @keyframes at-rule exists outside assets/css/05-motion.css (D-19(iv))" do
    offenders =
      for path <- css_files(),
          path != @motion_file,
          source = strip_comments(File.read!(path)),
          String.contains?(source, "@keyframes") do
        path
      end

    assert offenders == [],
           """
           MOTION-01 drift guard: found @keyframes outside #{@motion_file}. All keyframes
           must be centralized in the motion layer (D-19(iv)) — no one-off keyframes in
           components/LiveViews:

           #{inspect(offenders, pretty: true)}
           """
  end

  # -- helpers --------------------------------------------------------------

  defp css_files, do: Path.wildcard(@css_glob)

  # Grep-gate hygiene: strip CSS comments first so header/prose mentions of
  # "transition: all" or "@keyframes" inside a doc comment cannot self-invalidate
  # a count gate (T-40-02 mitigation).
  defp strip_comments(source), do: Regex.replace(~r/\/\*.*?\*\//s, source, "")

  defp tokenized?(decl) do
    String.contains?(decl, "var(--scoria-dur-") and String.contains?(decl, "var(--scoria-ease-")
  end

  defp animation_declarations(path) do
    source = strip_comments(File.read!(path))

    ~r/animation:\s*([a-zA-Z0-9_-]+)\s+([^;]+);/
    |> Regex.scan(source)
    |> Enum.map(fn [_whole, name, rest] -> {name, "animation: #{name} #{rest};"} end)
  end

  # Extract every `@keyframes <name> { ... }` block's full body via balanced-brace
  # scanning (a non-greedy regex would stop at the FIRST nested `}` — e.g. the
  # close of a `0%, 100% { ... }` rule — not the keyframes block's own close).
  defp keyframe_blocks(path) do
    source = strip_comments(File.read!(path))

    ~r/@keyframes\s+([a-zA-Z0-9_-]+)\s*\{/
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{whole_start, whole_len}, {name_start, name_len}] ->
      name = binary_part(source, name_start, name_len)
      open_brace_pos = whole_start + whole_len - 1
      body = extract_balanced(source, open_brace_pos)
      {name, body}
    end)
  end

  defp extract_balanced(source, open_pos) do
    do_extract_balanced(source, open_pos + 1, 1, open_pos + 1)
  end

  defp do_extract_balanced(source, pos, depth, start) do
    case :binary.at(source, pos) do
      ?{ ->
        do_extract_balanced(source, pos + 1, depth + 1, start)

      ?} ->
        if depth == 1 do
          binary_part(source, start, pos - start)
        else
          do_extract_balanced(source, pos + 1, depth - 1, start)
        end

      _ ->
        do_extract_balanced(source, pos + 1, depth, start)
    end
  end

  defp keyframe_properties(body) do
    ~r/([a-z-]+)\s*:/
    |> Regex.scan(body)
    |> Enum.map(fn [_, prop] -> prop end)
    |> Enum.uniq()
  end
end

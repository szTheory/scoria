defmodule ScoriaWeb.A11yStructuralGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  A11Y-01/A11Y-02 browserless structural-presence source-scan guard (Phase 40,
  D-08 — warning-grade). Modeled on `ui_drift_guard_test.exs`'s `Path.wildcard`
  + `Regex.match?` + collect-offenders idiom.

  Proves, without a browser, the structural invariants that are this guard's
  PRIMARY OWNERSHIP per the D-07 coverage map:

    - every icon-only button carries an accessible name (aria-label);
    - no color-only status — every `<.badge>` call site supplies a text label
      (this guard is the PRIMARY OWNER of the brand §7/§9 status-not-color-only
      invariant, D-08(c));
    - native-semantics presence: every `role="dialog"` overlay pairs with
      `aria-modal="true"`; every native `<details>` disclosure is paired with
      a `<summary>` (never a JS-toggled div); the table scroll viewport stays
      keyboard-reachable (`tabindex="0"`); filter controls are real
      `<button>`/`<a>`/`<select>`/`<form>` elements, never a bare clickable
      `<div>`;
    - the A11Y-01 calm-surface structural contract: copy controls
      (`<.id>`, the raw-evidence copy button) expose an accessible name AND a
      live-region node; forms (`<.field>`) associate labels via `for`, mark
      required fields via sr-only text, and render errors with an icon
      alongside text (never color alone).

  Per D-12 (the browserless-vs-browser line), this guard asserts
  STRUCTURE/semantics presence ONLY — actual focus movement, tab order, and
  geometry are Playwright's job (keyboard-e2e, Plan 03/04). It does not
  attempt to assert that a `role="dialog"` overlay's Escape key literally
  closes it, only that the structural markers are present.

  Warning-grade this phase: proves the already-accessible-by-construction
  baseline (Phases 36-39 built accessibly on purpose), does not add a
  blocking ratchet beyond it. Phase 41 hardens.
  """

  @source_glob "lib/scoria_web/**/*.{ex,heex}"
  @ui_file "lib/scoria_web/ui.ex"

  test "every icon-only button call site carries an accessible name (D-08(b))" do
    offenders =
      for path <- source_files(),
          block <- tag_blocks(path, "icon_button"),
          not String.contains?(block, "aria-label=") do
        {path, block}
      end

    assert offenders == [],
           """
           A11Y structural guard: found <.icon_button> call site(s) with no aria-label.
           Every icon-only button must carry an accessible name (D-08(b)):

           #{inspect(offenders, pretty: true)}
           """
  end

  test "no color-only status — every <.badge> call site supplies a text label (PRIMARY OWNER, D-07/D-08(c))" do
    offenders =
      for path <- source_files(),
          block <- tag_blocks(path, "badge"),
          not String.contains?(block, "label=") do
        {path, block}
      end

    assert offenders == [],
           """
           A11Y structural guard: found <.badge> call site(s) with no label attribute.
           This guard is the PRIMARY OWNER of the brand §7/§9 status-not-color-only
           invariant — every status badge must carry a text label alongside its tone
           color, never color alone:

           #{inspect(offenders, pretty: true)}
           """
  end

  test "every role=\"dialog\" overlay pairs with aria-modal=\"true\" (native-semantics presence, D-08(a))" do
    offenders =
      for path <- source_files(),
          source = File.read!(path),
          start <- match_starts(source, ~r/role="dialog"/),
          window = window_after(source, start, 250),
          not String.contains?(window, ~s(aria-modal="true")) do
        {path, start}
      end

    assert offenders == [],
           """
           A11Y structural guard: found role="dialog" without a paired aria-modal="true"
           nearby. Every dialog/drawer/overlay shell must expose both (D-08(a)):

           #{inspect(offenders, pretty: true)}
           """
  end

  test "every native <details> disclosure is paired with a <summary> (never a JS-toggled div, D-08(a))" do
    offenders =
      for path <- source_files(),
          source = File.read!(path),
          String.contains?(source, "<details"),
          not String.contains?(source, "<summary") do
        path
      end

    assert offenders == [],
           """
           A11Y structural guard: found <details> without a paired <summary> in the same
           file. Disclosures must use native <details>/<summary> semantics, never a
           JS-toggled <div> (D-11 calmer-surface contract):

           #{inspect(offenders, pretty: true)}
           """
  end

  test "the table scroll viewport stays keyboard-reachable (tabindex=\"0\", D-11 calmer-surface contract)" do
    source = File.read!(@ui_file)

    # Matches the viewport <div> tag itself, whichever attribute order it's
    # written in (class-then-tabindex or tabindex-then-class), without
    # crossing into an unrelated later tag.
    assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*tabindex="0"[^>]*>/s, source) or
             Regex.match?(~r/<div\b[^>]*tabindex="0"[^>]*scoria-table__viewport[^>]*>/s, source),
           """
           A11Y structural guard: expected the .scoria-table__viewport <div> to carry
           tabindex="0" in #{@ui_file} so keyboard users can reach the horizontal-scroll
           container (D-11 calmer-surface contract, table sort/filter/scroll surface).
           """

    assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*aria-label="[^"]+"[^>]*>/s, source) or
             Regex.match?(~r/<div\b[^>]*aria-label="[^"]+"[^>]*scoria-table__viewport[^>]*>/s, source),
           """
           A11Y structural guard: expected the .scoria-table__viewport <div> to carry an
           aria-label in #{@ui_file} so screen-reader users know the region is scrollable
           (D-18).
           """
  end

  test "filter controls are real interactive elements, never a bare clickable <div> (D-08(a)/D-11)" do
    offenders =
      for path <- source_files(),
          source = File.read!(path),
          block <- Regex.scan(~r/<:filter>(.*?)<\/:filter>/s, source) |> Enum.map(&Enum.at(&1, 1)),
          Regex.match?(~r/<div\b[^>]*\sphx-click=/, block) do
        {path, block}
      end

    assert offenders == [],
           """
           A11Y structural guard: found a <:filter> slot using a bare clickable <div> in
           place of a real <button>/<a>/<select>/<form> control:

           #{inspect(offenders, pretty: true)}
           """
  end

  test "copy controls expose an accessible name and a live-region node (D-11 calmer-surface contract)" do
    source = File.read!(@ui_file)

    id_component = extract_around(source, ~r/def id\(assigns\) do/, 400)

    assert id_component != nil and String.contains?(id_component, "aria-label="),
           "A11Y structural guard: <.id> (copy control) must carry an accessible name (aria-label) in #{@ui_file}"

    assert id_component != nil and String.contains?(id_component, "aria-live="),
           "A11Y structural guard: <.id> (copy control) must expose a live-region (aria-live) in #{@ui_file}"

    raw_evidence = extract_around(source, ~r/def raw_evidence\(assigns\) do/, 2000)

    assert raw_evidence != nil and String.contains?(raw_evidence, "aria-label={@copy_label}"),
           "A11Y structural guard: raw_evidence copy button must carry an accessible name in #{@ui_file}"

    assert raw_evidence != nil and String.contains?(raw_evidence, ~s(aria-live="polite")),
           "A11Y structural guard: raw_evidence copy control must expose a live-region status node in #{@ui_file}"
  end

  test "forms associate labels via for, mark required via sr-only text, and render icon+text errors (D-11 calmer-surface contract)" do
    source = File.read!(@ui_file)

    field_component = extract_around(source, ~r/def field\(assigns\) do/, 1200)

    assert field_component != nil and String.contains?(field_component, "for={@id}"),
           "A11Y structural guard: <.field> label must associate via for={@id} in #{@ui_file}"

    assert field_component != nil and String.contains?(field_component, "sr-only") and
             String.contains?(field_component, "required"),
           "A11Y structural guard: <.field> must mark required fields via sr-only text in #{@ui_file}"

    assert field_component != nil and String.contains?(field_component, "<svg") and
             String.contains?(field_component, "{@error}"),
           """
           A11Y structural guard: <.field> error state must render an icon alongside the
           error text (never color-alone) in #{@ui_file}
           """
  end

  # -- helpers --------------------------------------------------------------

  defp source_files, do: Path.wildcard(@source_glob)

  defp tag_blocks(path, tag) do
    source = File.read!(path)

    ~r/<\.#{tag}\b.*?>/s
    |> Regex.scan(source)
    |> List.flatten()
  end

  defp match_starts(source, regex) do
    regex
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{start, _len}] -> start end)
  end

  # Regex :index offsets are BYTE offsets into the source binary — use
  # binary_part/3 (not String.slice/3, which counts graphemes) so a
  # multi-byte UTF-8 character earlier in the file (an en dash, arrow, etc.
  # in a doc comment) cannot desync the window from the actual match position.
  defp window_after(source, start, window_size) do
    len = min(window_size, byte_size(source) - start)
    binary_part(source, start, len)
  end

  # Extracts a fixed-size text window starting at the given def's match, so
  # per-component structural checks scope to that component's own render body
  # rather than the whole ui.ex file. Returns nil if the def is not found
  # (would itself be a real drift — the assertion callers surface a clear
  # failure message rather than silently skipping).
  defp extract_around(source, def_regex, window_size) do
    case Regex.run(def_regex, source, return: :index) do
      [{start, _len}] -> window_after(source, start, window_size)
      _ -> nil
    end
  end
end

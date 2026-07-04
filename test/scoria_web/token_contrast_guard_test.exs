defmodule ScoriaWeb.TokenContrastGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Single-SSOT AA contrast floor guard — D-31.

  Reads color values EXCLUSIVELY from `assets/css/02-tokens.css` (the single token
  source of truth). Parses primitive and semantic token declarations, resolves
  `var()` references within the same file for both dark (default) and light themes,
  and asserts WCAG AA contrast floors for body text and non-text/focus indicator pairs.

  This guard is a floor, not a replacement for visual review (D-31). It covers the
  semantically significant pairs where token drift could silently break AA contrast.

  Floors:
    - Body text pairs:   ≥ 4.5:1 in both themes (WCAG AA normal text)
    - Non-text/focus:    ≥ 3.0:1 in both themes (WCAG AA non-text indicator)

  If a pair cannot be resolved from 02-tokens.css alone (e.g. uses color-mix()),
  it is skipped with a notation rather than hardcoding an out-of-file value.

  Contrast math: WCAG 2.1 relative luminance formula (inline, no external dependency).
  """

  @token_css_path "assets/css/02-tokens.css"

  # Body text AA floor: 4.5:1 (WCAG 2.1 §1.4.3)
  @text_floor 4.5
  # Non-text indicator / focus ring AA floor: 3.0:1 (WCAG 2.1 §1.4.11)
  @nontext_floor 3.0

  # Semantic token pairs to assert, per-theme.
  # Format: {foreground_token, background_token, min_ratio, description}
  @checked_pairs [
    {"--scoria-text", "--scoria-surface-app", @text_floor, "body text on app background"},
    {"--scoria-text-muted", "--scoria-surface-panel", @text_floor,
     "muted text on panel background"},
    {"--scoria-focus-ring", "--scoria-surface-panel", @nontext_floor,
     "focus ring on panel surface"},
    {"--scoria-focus-ring", "--scoria-surface-panel-raised", @nontext_floor,
     "focus ring on raised surface"},
    # Phase 40 (D-31/A11Y-02): guards the axe-surfaced sidebar/breadcrumb
    # contrast defect fixed by repointing --scoria-text-subtle off
    # --scoria-pumice-500 (see assets/css/02-tokens.css). Both backgrounds
    # this token actually renders against (sidebar/panel surface + app
    # surface, e.g. the breadcrumb separator) must stay guarded so this pair
    # cannot silently regress.
    {"--scoria-text-subtle", "--scoria-surface-panel", @text_floor,
     "subtle text on panel/sidebar background"},
    {"--scoria-text-subtle", "--scoria-surface-app", @text_floor,
     "subtle text on app background (e.g. breadcrumb separator)"}
  ]

  # ──────────────────────────────────────────────────────────────────────────
  # Tests
  # ──────────────────────────────────────────────────────────────────────────

  describe "D-31 AA contrast floor (dark theme — default .scoria-root)" do
    setup do
      {:ok, tokens: load_tokens(:dark)}
    end

    test "body text and focus pairs meet AA floor", %{tokens: tokens} do
      assert_pairs(@checked_pairs, tokens, "dark")
    end
  end

  describe "D-31 AA contrast floor (light theme — .scoria-root[data-theme=light])" do
    setup do
      {:ok, tokens: load_tokens(:light)}
    end

    test "body text and focus pairs meet AA floor", %{tokens: tokens} do
      assert_pairs(@checked_pairs, tokens, "light")
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Assertion helper
  # ──────────────────────────────────────────────────────────────────────────

  defp assert_pairs(pairs, tokens, theme_label) do
    for {fg_token, bg_token, min_ratio, description} <- pairs do
      fg_hex = resolve_token(fg_token, tokens)
      bg_hex = resolve_token(bg_token, tokens)

      cond do
        is_nil(fg_hex) ->
          flunk("""
          Token contrast guard: could not resolve #{fg_token} from #{@token_css_path} \
          (theme: #{theme_label}). Either the token name changed or it uses color-mix() \
          which is not resolvable from a single CSS file without a browser. \
          Update the pair list in #{__MODULE__} to reflect the current token structure.
          """)

        is_nil(bg_hex) ->
          flunk("""
          Token contrast guard: could not resolve #{bg_token} from #{@token_css_path} \
          (theme: #{theme_label}). Either the token name changed or it uses color-mix().
          """)

        true ->
          ratio = contrast_ratio(fg_hex, bg_hex)

          assert ratio >= min_ratio,
                 """
                 D-31 contrast floor FAILED: #{description} (theme: #{theme_label})
                   #{fg_token} → #{fg_hex}
                   #{bg_token} → #{bg_hex}
                   Ratio: #{Float.round(ratio, 2)}:1 (required ≥ #{min_ratio}:1)
                   Source: #{@token_css_path}
                 """
      end
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # Token parsing — reads ONLY assets/css/02-tokens.css
  # ──────────────────────────────────────────────────────────────────────────

  # Returns a flat map of %{"--token-name" => "#hexvalue"} for the given theme.
  # Dark theme: combines .scoria-root block.
  # Light theme: combines .scoria-root block (primitives) THEN overrides with
  #              .scoria-root[data-theme="light"] block so semantic tokens resolve
  #              to their light-mode values.
  defp load_tokens(theme) do
    css = File.read!(@token_css_path)

    # Extract primitives and dark-default semantic values from the base .scoria-root block.
    # We match the block that starts with `.scoria-root {` and ends before the next
    # top-level block. Since the light block uses an attribute selector, we can split on
    # `.scoria-root[data-theme` to isolate the dark block.
    dark_block = extract_block(css, ~r/\.scoria-root\s*\{/, ~r/\.scoria-root\[data-theme/)
    dark_tokens = parse_declarations(dark_block)

    case theme do
      :dark ->
        dark_tokens

      :light ->
        # Light overrides come from the `.scoria-root[data-theme="light"]` block.
        light_block = extract_block(css, ~r/\.scoria-root\[data-theme="light"\]\s*\{/, ~r/\A\z/)
        light_tokens = parse_declarations(light_block)
        # Merge: start with dark primitives (which light shares), then apply light overrides.
        Map.merge(dark_tokens, light_tokens)
    end
  end

  # Extract the content between the opening `{` after the pattern match and the next
  # occurrence of `stop_pattern` (or end of string). Returns the declarations inside.
  defp extract_block(css, start_pattern, stop_pattern) do
    case Regex.run(start_pattern, css, return: :index) do
      [{start_idx, _match_len}] ->
        # Find the opening `{` at or after the match
        from = start_idx

        rest = String.slice(css, from, String.length(css) - from)

        # Find where to stop: the next occurrence of stop_pattern after the block opens,
        # or the end of the string if no stop found.
        stop_idx =
          case Regex.run(stop_pattern, rest, return: :index) do
            [{idx, _}] when idx > 0 -> idx
            _ -> String.length(rest)
          end

        String.slice(rest, 0, stop_idx)

      _ ->
        ""
    end
  end

  # Parse `--token-name: value;` lines from a CSS block.
  # Returns %{"--token-name" => "value"} with trimmed values.
  # Skips color-mix() values since they are not resolvable without a browser.
  defp parse_declarations(block) do
    ~r/(--([\w-]+))\s*:\s*([^;]+);/
    |> Regex.scan(block)
    |> Enum.reduce(%{}, fn [_, name, _bare_name, value], acc ->
      trimmed = String.trim(value)

      # Skip color-mix() — not resolvable from static parse
      if String.starts_with?(trimmed, "color-mix(") do
        acc
      else
        Map.put(acc, name, trimmed)
      end
    end)
  end

  # Resolve a token name to a hex string by:
  # 1. Looking up the token in the map.
  # 2. If the value is `var(--other-token)`, recursively resolve that token.
  # 3. If the value is a hex string, return it.
  # 4. Returns nil if unresolvable (color-mix, unrecognised value, missing token).
  defp resolve_token(token_name, tokens), do: resolve_token(token_name, tokens, 0)

  defp resolve_token(_token_name, _tokens, depth) when depth >= 8, do: nil

  defp resolve_token(token_name, tokens, depth) do
    value = Map.get(tokens, token_name)

    cond do
      is_nil(value) ->
        nil

      String.starts_with?(value, "var(") ->
        # Extract the referenced token name: var(--name) or var(--name, fallback)
        case Regex.run(~r/var\((--[\w-]+)/, value) do
          [_, ref_name] -> resolve_token(ref_name, tokens, depth + 1)
          _ -> nil
        end

      String.starts_with?(value, "#") ->
        value

      # rgba() / color-mix() / other non-hex — skip
      true ->
        nil
    end
  end

  # ──────────────────────────────────────────────────────────────────────────
  # WCAG 2.1 contrast ratio math (inline, no external library)
  # Source: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
  # ──────────────────────────────────────────────────────────────────────────

  defp contrast_ratio(hex1, hex2) do
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)
    {lighter, darker} = if l1 > l2, do: {l1, l2}, else: {l2, l1}
    (lighter + 0.05) / (darker + 0.05)
  end

  defp relative_luminance(hex) do
    {r, g, b} = parse_hex(hex)
    linearize(r / 255) * 0.2126 + linearize(g / 255) * 0.7152 + linearize(b / 255) * 0.0722
  end

  # sRGB linearization per WCAG spec
  defp linearize(c) when c <= 0.04045, do: c / 12.92
  defp linearize(c), do: :math.pow((c + 0.055) / 1.055, 2.4)

  # Parse 6-digit hex string (#rrggbb) to {r, g, b} integers
  defp parse_hex("#" <> hex) when byte_size(hex) == 6 do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = hex
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end
end

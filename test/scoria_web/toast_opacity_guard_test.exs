defmodule ScoriaWeb.ToastOpacityGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Toast opacity guard — Phase 38 D-04/D-17a.

  Approval warning/error toasts previously rendered the shared translucent
  `--scoria-tone-*-bg` tint directly (a `color-mix(..., transparent)` formula),
  so dense page content bled through behind the toast (Criterion 4). The fix
  introduces dedicated `--scoria-toast-<tone>-bg` tokens composited opaquely
  over a solid elevated surface.

  This guard exists as its own file (not folded into
  `token_contrast_guard_test.exs`) because that guard's `resolve_token/3`
  returns `nil` — and its caller `flunk`s, not skips — for any
  `color-mix()`-valued token (RESEARCH.md Pitfall 1). The new toast tokens are
  intentionally `color-mix()`-valued, so they must be verified by source-scan
  instead of the WCAG contrast resolver.

  Mirrors `ds06_drift_guard_test.exs`'s File.read! + Regex source-scan style
  and its `.scoria-root` block-scoping discipline.

  Checks, for each of the five tones `toast/1` supports (neutral, pass, info,
  warn, fail — brand/trace are excluded from toasts):
    1. A `--scoria-toast-<tone>-bg` custom property is DECLARED in BOTH the
       dark (`.scoria-root`) and light (`.scoria-root[data-theme="light"]`)
       token blocks.
    2. Each such declaration's value is opaque: it does not composite toward
       the see-through `transparent` keyword, and it is not an
       `rgba(...)`/`hsla(...)` form with a trailing alpha channel below 1.
  """

  @token_css_path "assets/css/02-tokens.css"

  @toast_tones ~w(neutral pass info warn fail)

  test "--scoria-toast-<tone>-bg tokens are declared and opaque in BOTH theme blocks" do
    css = File.read!(@token_css_path)

    dark_block = extract_block(css, ~r/\.scoria-root\s*\{/, ~r/\.scoria-root\[data-theme/)
    light_block = extract_block(css, ~r/\.scoria-root\[data-theme="light"\]\s*\{/, ~r/\A\z/)

    violations =
      for tone <- @toast_tones,
          {theme_label, block} <- [{"dark", dark_block}, {"light", light_block}] do
        token_name = "--scoria-toast-#{tone}-bg"

        case declared_value(block, token_name) do
          nil ->
            {token_name, theme_label, :missing}

          value ->
            if opaque?(value) do
              nil
            else
              {token_name, theme_label, {:not_opaque, value}}
            end
        end
      end
      |> Enum.reject(&is_nil/1)

    assert violations == [],
           """
           Toast opacity guard FAILED: #{@token_css_path} is missing or has a non-opaque
           declaration for one or more --scoria-toast-<tone>-bg tokens:
           #{Enum.map_join(violations, "\n", &format_violation/1)}
             Fix: declare --scoria-toast-<tone>-bg in BOTH the dark (.scoria-root) and
             light (.scoria-root[data-theme="light"]) blocks as an opaque composite over
             a solid surface, e.g.:
               --scoria-toast-warn-bg: color-mix(in srgb, var(--scoria-tone-warn-fg) 16%, var(--scoria-surface-panel-raised));
             never toward `transparent`, and never an rgba()/hsla() with alpha < 1.
           """
  end

  defp format_violation({token_name, theme_label, :missing}) do
    "  #{token_name} (#{theme_label} theme): not declared"
  end

  defp format_violation({token_name, theme_label, {:not_opaque, value}}) do
    "  #{token_name} (#{theme_label} theme): declared as `#{value}` (not opaque)"
  end

  # Extract the content between the opening `{` after start_pattern matches and the
  # next occurrence of stop_pattern (or end of string). Mirrors
  # token_contrast_guard_test.exs's extract_block/3.
  defp extract_block(css, start_pattern, stop_pattern) do
    case Regex.run(start_pattern, css, return: :index) do
      [{start_idx, _match_len}] ->
        rest = String.slice(css, start_idx, String.length(css) - start_idx)

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

  # Find `--token-name: value;` inside a block and return the trimmed value, or nil
  # if the token is not declared in that block.
  defp declared_value(block, token_name) do
    escaped = Regex.escape(token_name)

    case Regex.run(~r/#{escaped}\s*:\s*([^;]+);/, block) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  # A declaration is opaque unless:
  #   - it is (or ends in) the bare `transparent` keyword, or
  #   - it is a color-mix(...) whose final color argument is `transparent`, or
  #   - it is an rgba()/hsla() form whose alpha channel is < 1.
  defp opaque?(value) do
    not see_through_composite?(value) and not translucent_rgba_or_hsla?(value)
  end

  defp see_through_composite?(value) do
    trimmed = String.trim(value)

    trimmed == "transparent" or
      Regex.match?(~r/,\s*transparent\s*\)\s*\z/, trimmed) or
      Regex.match?(~r/,\s*transparent\s*\)/, trimmed)
  end

  defp translucent_rgba_or_hsla?(value) do
    case Regex.run(~r/\b(?:rgba|hsla)\(\s*[^,]+,\s*[^,]+,\s*[^,]+,\s*([0-9.]+)\s*\)/, value) do
      [_, alpha_str] ->
        case Float.parse(alpha_str) do
          {alpha, _} -> alpha < 1.0
          :error -> false
        end

      _ ->
        false
    end
  end
end

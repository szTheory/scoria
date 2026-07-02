defmodule DevLab.Sections.Foundations do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Foundations` IA section (D-07): a read-only inspection surface for
  the EXISTING token/type/spacing/motion system. This module invents
  nothing — every value rendered here resolves through a `--scoria-*`
  custom property already declared in `assets/css/02-tokens.css` /
  `assets/css/05-motion.css`, or repeats an already-shipped type/spacing/
  motion constant documented in `37-UI-SPEC.md`. There is no editing
  affordance and no second color/spacing/motion mechanism.

  Built only from existing `ScoriaWeb.UI` chrome primitives
  (`page_section/1`, `panel/1`, `eyebrow/1`, `kbd/1`, `id/1`) per the
  UI-SPEC "Component Inventory For Lab Chrome" — no new primitives, no raw
  hex, no raw Tailwind palette (guarded by the DS-06 dev/lab/** extension,
  D-26).
  """

  use Phoenix.Component
  import ScoriaWeb.UI, only: [page_section: 1, panel: 1, eyebrow: 1, kbd: 1, id: 1]

  # ---------------------------------------------------------------------
  # Read-only specimen data. Every entry names an existing --scoria-*
  # custom property (token SSOT: assets/css/02-tokens.css /
  # assets/css/05-motion.css) plus the already-shipped value it currently
  # resolves to, so a maintainer can see token name <-> value <-> usage
  # without opening the CSS source. No new value is introduced anywhere
  # below.
  # ---------------------------------------------------------------------

  @color_tokens [
    %{
      token: "--scoria-surface-app",
      label: "Surface app",
      usage: "Lab shell background, page canvas"
    },
    %{
      token: "--scoria-surface-panel",
      label: "Surface panel",
      usage: "Lab section panels, specimen cards"
    },
    %{
      token: "--scoria-action",
      label: "Action / accent",
      usage: "Primary lab commands, active nav item, brand-tone badges"
    },
    %{
      token: "--scoria-text-muted",
      label: "Text muted",
      usage: "Secondary/non-active lab chrome text"
    },
    %{
      token: "--scoria-border",
      label: "Border",
      usage: "Panel, table, and field borders"
    },
    %{
      token: "--scoria-focus-ring",
      label: "Focus ring",
      usage: "Keyboard focus ring on any focusable lab control"
    }
  ]

  @type_scale [
    %{role: "Badge / eyebrow", token: "--scoria-fs-badge", size: "11px", weight: 600, lh: "1.2 (tight)"},
    %{role: "Label", token: "--scoria-fs-label", size: "12px", weight: 600, lh: "1.2 (tight)"},
    %{role: "Body", token: "--scoria-fs-body", size: "14px", weight: 400, lh: "1.5 (body)"},
    %{role: "Panel heading", token: "--scoria-fs-panel", size: "18px", weight: 600, lh: "1.2 (tight)"},
    %{role: "Title", token: "--scoria-fs-title", size: "24px", weight: 600, lh: "1.2 (tight)"},
    %{role: "Display / Metric", token: "--scoria-fs-display", size: "30px", weight: 600, lh: "1.2 (tight)"}
  ]

  @spacing_steps [
    %{name: "space-1", token: "--scoria-space-1", value: "4px"},
    %{name: "space-2", token: "--scoria-space-2", value: "8px"},
    %{name: "space-3", token: "--scoria-space-3", value: "12px"},
    %{name: "space-4", token: "--scoria-space-4", value: "16px"},
    %{name: "space-5", token: "--scoria-space-5", value: "24px"},
    %{name: "space-6", token: "--scoria-space-6", value: "32px"}
  ]

  @motion_durations [
    %{name: "dur-fast", token: "--scoria-dur-fast", value: "100ms"},
    %{name: "dur-mid", token: "--scoria-dur-mid", value: "150ms"},
    %{name: "dur-slow", token: "--scoria-dur-slow", value: "200ms"}
  ]

  attr(:class, :string, default: nil)

  @doc """
  Renders the `Foundations` IA section: semantic color token swatches, the
  type scale, the in-lab spacing scale (`space-1`-`space-6`), motion
  durations, and a `Reduced motion` affordance that reflects the browser's
  own `prefers-reduced-motion` media feature (D-14) — displayed via the
  SAME media query the existing kill switch in `assets/css/05-motion.css`
  already consumes, never a second/invented motion mechanism.
  """
  def foundations(assigns) do
    assigns =
      assigns
      |> assign(:color_tokens, @color_tokens)
      |> assign(:type_scale, @type_scale)
      |> assign(:spacing_steps, @spacing_steps)
      |> assign(:motion_durations, @motion_durations)

    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Foundations</:eyebrow>
      <:title>Foundations</:title>
      <:description>
        Read-only specimens of the existing token, type, spacing, and motion
        system. Nothing on this page is a new value — every specimen below
        resolves through a token already shipped to the runtime dashboard.
      </:description>

      <.panel>
        <:eyebrow>Color</:eyebrow>
        <:title>Semantic Color Tokens</:title>
        <div class="scoria-lab-foundation-grid" data-lab-foundation="color">
          <div :for={entry <- @color_tokens} class="scoria-lab-token-row" data-lab-token={entry.token}>
            <span
              class="scoria-lab-token-swatch"
              style={"background: var(#{entry.token}); border: 1px solid var(--scoria-border);"}
              aria-hidden="true"
            ></span>
            <.eyebrow>{entry.label}</.eyebrow>
            <.id value={entry.token} title={entry.usage} />
            <span class="scoria-lab-token-usage">{entry.usage}</span>
          </div>
        </div>
      </.panel>

      <.panel>
        <:eyebrow>Type</:eyebrow>
        <:title>Type Scale</:title>
        <div data-lab-foundation="type">
          <div :for={entry <- @type_scale} class="scoria-lab-token-row" data-lab-token={entry.token}>
            <span style={"font-size: var(#{entry.token}); font-weight: #{entry.weight}; line-height: var(--scoria-lh-tight);"}>
              {entry.role}
            </span>
            <.kbd>{entry.size}</.kbd>
            <span class="scoria-lab-token-usage">{entry.weight} · line-height {entry.lh}</span>
            <.id value={entry.token} />
          </div>
        </div>
      </.panel>

      <.panel>
        <:eyebrow>Spacing</:eyebrow>
        <:title>Spacing Scale (space-1 – space-6, in-lab)</:title>
        <div data-lab-foundation="spacing">
          <div :for={entry <- @spacing_steps} class="scoria-lab-token-row" data-lab-token={entry.token}>
            <span
              class="scoria-lab-space-swatch"
              style={"width: var(#{entry.token}); height: var(#{entry.token}); background: var(--scoria-action);"}
              aria-hidden="true"
            ></span>
            <.eyebrow>{entry.name}</.eyebrow>
            <.kbd>{entry.value}</.kbd>
            <.id value={entry.token} />
          </div>
        </div>
      </.panel>

      <.panel>
        <:eyebrow>Motion</:eyebrow>
        <:title>Motion Durations</:title>
        <div data-lab-foundation="motion">
          <div :for={entry <- @motion_durations} class="scoria-lab-token-row" data-lab-token={entry.token}>
            <.eyebrow>{entry.name}</.eyebrow>
            <.kbd>{entry.value}</.kbd>
            <.id value={entry.token} />
          </div>
        </div>

        <div class="scoria-lab-motion-signal" data-lab-motion-signal="true">
          <.eyebrow>Reduced motion</.eyebrow>
          <span class="scoria-lab-motion-off">
            Not requested — this browser/OS is not signaling prefers-reduced-motion: reduce.
          </span>
          <span class="scoria-lab-motion-on">
            Requested — the existing prefers-reduced-motion kill switch
            (assets/css/05-motion.css) is collapsing lab and dashboard motion to near-zero.
          </span>
        </div>
        <style>
          .scoria-lab-motion-on { display: none; }
          @media (prefers-reduced-motion: reduce) {
            .scoria-lab-motion-off { display: none; }
            .scoria-lab-motion-on { display: inline; }
          }
        </style>
      </.panel>
    </.page_section>
    """
  end
end

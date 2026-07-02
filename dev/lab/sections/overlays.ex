defmodule DevLab.Sections.Overlays do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Overlays` IA section (D-07): the curated D-10 flow probes — cases
  where isolated components are insufficient because the risk only appears
  when several primitives interact (stacked overlays, mobile collapse,
  focus/dismissal, keyboard navigation). Per D-10 this is EXACTLY seven
  probes, no more and no fewer (an eighth would be scope creep; D-06
  curated-probe ceiling):

    1. Dense approvals list with a toast overlay stacked over it
       (RISK-TOAST-LEGIBILITY stress fixture — surfaced, NOT fixed; the fix
       is Phase 38 scope).
    2. Mobile table/list summary (the responsive table→card collapse,
       RISK-RESPONSIVE-SCAN).
    3. Drawer/modal focus and dismissal probes (RISK-OVERLAY-FOCUS).
    4. Command palette.
    5. Mobile nav.
    6. Raw-evidence copy controls near a payload ("Copy fixture payload").
    7. A long unbroken evidence payload.

  Every probe reuses an EXISTING mechanism — the `assets/js/scoria.js`
  hooks (`CommandPalette`, `MobileNav`, `CopyId` via `id/1`, the
  `raw_evidence/1` copy click-listener) or the runtime's own
  `drawer/1`/`modal/1`/`toast/1` dismiss/positioning contract (including the
  fixed `.scoria-toast-region` stacking container already used by
  `lib/scoria_web/live/approvals_live/index.ex`). Nothing here reimplements
  dismissal, focus-trap, or motion, and no new motion duration is invented
  (D-14). This module never builds a second `/scoria/approvals` page — only
  the narrow cross-cutting slice D-10 calls out.

  Long-evidence and raw-evidence probes reuse the existing evidence-notebook
  group (`raw_evidence/1`/`notebook/1`, default `open: false`) — no new
  disclosure widget.
  """

  use Phoenix.Component
  import ScoriaWeb.UI

  alias ScoriaWeb.ApprovalInboxComponent

  attr(:class, :string, default: nil)

  @doc """
  Renders the `Overlays` IA section: the seven curated D-10 flow probes.
  """
  def overlays(assigns) do
    dense = dense_approvals()

    assigns =
      assigns
      |> assign(:dense_approvals, dense)
      |> assign(:mobile_summary_approvals, Enum.take(dense, 3))
      |> assign(:nav_groups, ScoriaWeb.Layouts.nav_groups())
      |> assign(:command_sections, lab_command_sections())
      |> assign(:copy_payload, DevLab.Fixtures.scenario(:approval_requested))
      |> assign(:long_evidence, long_evidence_payload())

    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Overlays</:eyebrow>
      <:title>Overlay &amp; Flow Probes</:title>
      <:description>
        The curated D-10 flow probes — cross-cutting risks that only appear
        when several primitives interact. Exactly seven probes (D-10
        ceiling AND floor). Every probe reuses an existing scoria.js hook or
        the runtime's own overlay dismiss contract; this is a stress
        fixture, never a fix — toast legibility stays Phase 38 scope,
        approval decision history stays Phase 39 scope.
      </:description>

      <%!-- 1. Dense approvals + toast overlay (RISK-TOAST-LEGIBILITY) --%>
      <.panel>
        <:eyebrow>Dense data + toast</:eyebrow>
        <:title>Dense approvals with a toast overlay</:title>
        <:actions>
          <.id value="RISK-TOAST-LEGIBILITY" title="Stress fixture only — the fix is Phase 38 scope" />
        </:actions>
        <p class="scoria-page-section__description">
          A dense approval inbox with the same fixed
          <code>.scoria-toast-region</code>
          stacking container <code>approvals_live/index.ex</code> already uses, holding two toasts. This is the exact overlap
          RISK-TOAST-LEGIBILITY tracks for Phase 38 — this probe surfaces the
          problem, it does not fix toast legibility.
        </p>
        <div class="scoria-lab-overlay-stage">
          <ApprovalInboxComponent.render approvals={@dense_approvals} scoria_base="" />
          <div id="lab-toast-region" class="scoria-toast-region">
            <.toast id="lab-toast-1" tone={:warn} message="Refund request denied: amount exceeds tenant policy ceiling" />
            <.toast id="lab-toast-2" tone={:fail} message="Approval evidence failed to load for appr-9b1d4e2a" />
          </div>
        </div>
      </.panel>

      <%!-- 2. Mobile table/list summary --%>
      <.panel>
        <:eyebrow>Responsive collapse</:eyebrow>
        <:title>Mobile table/list summary</:title>
        <:actions>
          <.id value={DevLab.Fixtures.inventory_id(:approval_inbox)} />
          <.id value="RISK-RESPONSIVE-SCAN" />
        </:actions>
        <p class="scoria-page-section__description">
          The same approval inbox, framed at the 375px mobile proof target
          so the existing table/1 mobile_summary collapse (card layout,
          no new breakpoint) is directly inspectable.
        </p>
        <div class="scoria-lab-overlay-frame" style="width: 100%; max-width: 375px; margin-inline: auto;">
          <ApprovalInboxComponent.render approvals={@mobile_summary_approvals} scoria_base="" />
        </div>
      </.panel>

      <%!-- 3. Drawer/modal focus & dismissal probes --%>
      <.panel>
        <:eyebrow>Focus &amp; dismissal</:eyebrow>
        <:title>Drawer / modal focus and dismissal probes</:title>
        <:actions>
          <.id value={DevLab.Fixtures.inventory_id(:drawer)} />
          <.id value={DevLab.Fixtures.inventory_id(:modal)} />
          <.id value="RISK-OVERLAY-FOCUS" />
        </:actions>
        <p class="scoria-page-section__description">
          Both overlays render genuinely open — close button, scrim click,
          and Escape all route through the existing
          <code>drawer/1</code>
          /<code>modal/1</code>
          dismiss contract; no reimplemented focus-trap or motion.
        </p>
        <.drawer id="lab-overlay-drawer" show={true} on_dismiss="lab-noop-dismiss" title="Billing MCP">
          <:eyebrow>Connector detail</:eyebrow>
          <p>Elevated latency over the last 15 minutes.</p>
        </.drawer>
        <.modal id="lab-overlay-modal" show={true} on_dismiss="lab-noop-dismiss" title="Workflow step failed">
          <p>Connector timeout after 3 retries.</p>
          <:footer>
            <.button variant={:ghost} phx-click="lab-noop-dismiss">Close</.button>
          </:footer>
        </.modal>
      </.panel>

      <%!-- 4. Command palette --%>
      <.panel>
        <:eyebrow>Keyboard command</:eyebrow>
        <:title>Command palette</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:command_palette)} /></:actions>
        <p class="scoria-page-section__description">
          Open with <.kbd>Cmd K</.kbd>
          / <.kbd>Ctrl K</.kbd>
          or the button below — the existing <code>CommandPalette</code>
          hook (client-side filter, arrow-key nav, Escape dismiss),
          unmodified.
        </p>
        <button
          type="button"
          class="scoria-button scoria-button--ghost scoria-button--sm"
          aria-label="Open command palette"
          aria-controls="lab-command-palette"
          data-command-open
        >
          Open command palette
        </button>
        <.command_palette id="lab-command-palette" sections={@command_sections} />
      </.panel>

      <%!-- 5. Mobile nav --%>
      <.panel>
        <:eyebrow>Off-canvas navigation</:eyebrow>
        <:title>Mobile nav</:title>
        <p class="scoria-page-section__description">
          The existing off-canvas <code>MobileNav</code>
          hook (open/close/focus-trap, desktop auto-close), rendered
          against the real dashboard nav groups.
        </p>
        <button
          type="button"
          class="scoria-button scoria-button--ghost scoria-button--sm"
          aria-label="Open navigation"
          aria-controls="lab-mobile-nav"
          aria-expanded="false"
          data-mobile-nav-open
        >
          Open navigation
        </button>
        <div
          id="lab-mobile-nav"
          class="scoria-mobile-drawer-shell"
          role="dialog"
          aria-modal="true"
          aria-label="Dashboard navigation (lab specimen)"
          data-state="closed"
          hidden
          phx-hook="MobileNav"
        >
          <div class="scoria-mobile-drawer__scrim" data-mobile-nav-close aria-hidden="true"></div>
          <div class="scoria-mobile-drawer" tabindex="-1">
            <div class="scoria-mobile-drawer__header">
              <span class="scoria-eyebrow">Dashboard navigation</span>
              <button
                type="button"
                class="scoria-button scoria-button--ghost scoria-button--sm scoria-mobile-drawer__close"
                aria-label="Close navigation"
                data-mobile-nav-close
              >
                Close navigation
              </button>
            </div>
            <nav class="scoria-mobile-drawer__nav" aria-label="Dashboard sections">
              <div :for={group <- @nav_groups} class="scoria-navgroup">
                <p class="scoria-navgroup__label">{group.label}</p>
                <span :for={item <- group.items} class="scoria-nav">{item.label}</span>
              </div>
            </nav>
          </div>
        </div>
      </.panel>

      <%!-- 6. Raw-evidence copy controls near a payload --%>
      <.panel>
        <:eyebrow>Evidence disclosure</:eyebrow>
        <:title>Copy fixture payload</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:raw_evidence)} /></:actions>
        <p class="scoria-page-section__description">
          Copy controls next to a raw fixture payload, reusing the existing
          <code>raw_evidence/1</code>
          copy affordance (document-level click listener in
          <code>assets/js/scoria.js</code>
          — no new JS).
        </p>
        <.raw_evidence
          label="Approval fixture payload"
          value={inspect(@copy_payload, pretty: true)}
          open={false}
          copyable
          copy_label="Copy fixture payload"
        />
      </.panel>

      <%!-- 7. Long unbroken evidence payload --%>
      <.panel>
        <:eyebrow>Ugly data</:eyebrow>
        <:title>Long unbroken evidence payload</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:notebook)} /></:actions>
        <p class="scoria-page-section__description">
          A genuinely long, unbroken (no whitespace) evidence string — the
          <code>approval_requested</code>
          scenario's <code>policy_name</code>
          from <code>DevLab.Fixtures</code>
          — inside the existing evidence-notebook group, to stress
          overflow/wrap handling.
        </p>
        <.notebook id="lab-overlay-long-evidence" title="Policy Evidence" eyebrow="approvals" empty={false}>
          <:tab key="evidence" label="Technical evidence">
            <.evidence_section title="Long unbroken value" description="policy_name (no whitespace)">
              <.raw_evidence
                label="Raw policy name"
                value={@long_evidence}
                open={false}
                copyable
                copy_label="Copy fixture payload"
              />
            </.evidence_section>
          </:tab>
        </.notebook>
      </.panel>
    </.page_section>
    """
  end

  # ---------------------------------------------------------------------
  # Probe 1/2 data — a short deterministic list of dense approval rows
  # built from the two existing approval scenarios (D-17: no randomness,
  # same input -> same output). Mirrors the field enrichment
  # DevLab.Sections.Groups.approval_inbox_fixture/1 applies for the real
  # ApprovalInboxComponent, since ApprovalCopy reads the same fields here.
  # ---------------------------------------------------------------------
  @dense_approval_count 8
  @demo_time ~U[2026-07-02 12:00:00Z]

  defp dense_approvals do
    requested = DevLab.Fixtures.scenario(:approval_requested)
    denied = DevLab.Fixtures.scenario(:approval_denied)

    for n <- 1..@dense_approval_count do
      source = if rem(n, 3) == 0, do: denied, else: requested
      approval_row(source, n)
    end
  end

  defp approval_row(fixture, n) do
    fixture
    |> Map.put(:id, "#{fixture.approval_id}-#{n}")
    |> Map.put(:inserted_at, @demo_time)
    |> Map.put(:workflow_run_id, "run-33#{90 + n}")
    |> Map.put_new(:arguments_preview, %{
      "ticket_id" => "tick-#{4470 + n}",
      "amount_cents" => 5200 + n * 25,
      "customer" => "acme-support"
    })
  end

  # ---------------------------------------------------------------------
  # Probe 4 data — one deep-link row per D-07 IA section. Paths are the
  # /scoria/_lab/:section route Plan 05 mounts next; forward-referencing
  # them here matches the same convention DevLab.Sections.Groups/Primitives
  # already use for their own :item deep-link filters.
  # ---------------------------------------------------------------------
  @lab_sections ~w(foundations primitives groups states viewports overlays fixtures)

  defp lab_command_sections do
    [
      %{
        label: "Lab sections",
        rows: for(section <- @lab_sections, do: %{label: String.capitalize(section), path: "/scoria/_lab/" <> section})
      }
    ]
  end

  # ---------------------------------------------------------------------
  # Probe 7 data — the approval_requested scenario's own policy_name: a
  # real, already-deterministic long unbroken (dot/dash-separated, no
  # whitespace) string, not an invented literal.
  # ---------------------------------------------------------------------
  defp long_evidence_payload, do: DevLab.Fixtures.scenario(:approval_requested).policy_name
end

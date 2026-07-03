defmodule ScoriaWeb.UIComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  @moduledoc """
  Unit test scaffold for Phase 12 design-system components in ScoriaWeb.UI.

  This module is created in plan 12-01 as the shared test header so that downstream
  component plans (12-02, 12-03, 12-04) add assertions here instead of scaffolding.

  Test groups to be filled in by later plans:

    DS-01: <.table> — sortable, filterable, paginated operator scan table (plan 12-02)
      - renders column headers
      - renders rows
      - renders empty state when rows == []
      - uses one canonical compact scan density with no user-facing density toggle

    DS-02: <.drawer> and <.modal> — slot-based overlay shells (plan 12-02)
      - drawer renders title and content
      - modal renders title, content, and footer slots

    DS-03: <.field> and <.form_section> — form control wrappers (plan 12-03)
      - field renders label with for= binding
      - field renders error message when error attr present
      - field renders help text below input
      - form_section renders title and description

    DS-04: <.notebook> — unified evidence panel shell (plan 12-03)
      - notebook renders tab bar with correct aria roles
      - notebook panel has correct background surface class

    DS-05: <.skeleton>, <.toast>, flash_group fix (plan 12-04)
      - skeleton renders with scoria-skeleton class
      - toast renders with correct tone modifier
      - flash_group renders scoria-flash--fail for error kind
      - flash_group renders scoria-flash--info for info kind

    DS-06: drift guard (plan 12-01 — see ds06_drift_guard_test.exs)
      - Covered in test/scoria_web/ds06_drift_guard_test.exs

    flash_group (DS-05): See also integration tests in approvals_live_test.exs

  render_component usage notes (from PATTERNS.md):
    - Pure attr-only components: render_component(&ScoriaWeb.UI.skeleton/1, assigns)
    - Slot-bearing components: render_component(ScoriaWeb.UI, assigns) form NOT available
      for function components; use a wrapper helper or the function-capture form with
      slot content constructed via Phoenix.Component helpers.
    - Module-reference form (render_component(Module, assigns)) is for defmodule components
      that export render/1 (e.g. MemoryNotebookComponent), not for function components in ui.ex.
  """

  # ---------------------------------------------------------------------------
  # DS-05: flash_group (plan 12-02)
  # ---------------------------------------------------------------------------

  describe "flash_group/1" do
    test "renders scoria-flash--fail for string kind 'error'" do
      html = render_component(&ScoriaWeb.UI.flash_group/1, flash: %{"error" => "boom"})
      assert html =~ "scoria-flash--fail"
      assert html =~ "boom"
    end

    test "renders scoria-flash--info for string kind 'info'" do
      html = render_component(&ScoriaWeb.UI.flash_group/1, flash: %{"info" => "fyi"})
      assert html =~ "scoria-flash--info"
      assert html =~ "fyi"
    end

    test "renders scoria-flash--pass for string kind 'success'" do
      html = render_component(&ScoriaWeb.UI.flash_group/1, flash: %{"success" => "done"})
      assert html =~ "scoria-flash--pass"
      assert html =~ "done"
    end

    test "renders scoria-flash--warn for unknown/warning kind" do
      html = render_component(&ScoriaWeb.UI.flash_group/1, flash: %{"warning" => "watch out"})
      assert html =~ "scoria-flash--warn"
      assert html =~ "watch out"
    end

    test "each flash div carries role=alert" do
      html = render_component(&ScoriaWeb.UI.flash_group/1, flash: %{"error" => "boom"})
      assert html =~ ~s(role="alert")
    end
  end

  # ---------------------------------------------------------------------------
  # DS-02: <.modal> and <.drawer> (plan 12-03)
  # ---------------------------------------------------------------------------

  # Helper: a minimal slot inner_block entry that renders a static string
  defp slot_block(content),
    do: [%{inner_block: fn _changed, _arg -> content end, __slot__: :inner_block}]

  defp safe_slot_block(content),
    do: [%{inner_block: fn _changed, _arg -> {:safe, content} end, __slot__: :inner_block}]

  describe "panel/1 design-system surface contract" do
    test "flush option emits the flush modifier without requiring callsite class strings" do
      html =
        render_component(&ScoriaWeb.UI.panel/1,
          flush: true,
          inner_block: slot_block("Panel body")
        )

      assert html =~ "scoria-panel"
      assert html =~ "scoria-panel--flush"
      assert html =~ "Panel body"
    end
  end

  describe "page_section/1 design-system surface contract" do
    test "renders open-air top-level section chrome without panel classes" do
      html =
        render_component(&ScoriaWeb.UI.page_section/1,
          class: "custom-section",
          eyebrow: slot_block("posture"),
          title: slot_block("Tenant triage"),
          description: slot_block("Current queue posture."),
          actions: slot_block(~s(<a href="/incidents">Open</a>)),
          inner_block: slot_block("Section body")
        )

      assert html =~ "scoria-page-section"
      assert html =~ "custom-section"
      assert html =~ "scoria-page-section__header"
      assert html =~ "Tenant triage"
      assert html =~ "Current queue posture."
      assert html =~ "Section body"
      refute html =~ "scoria-panel"
    end
  end

  describe "page_header/1 design-system surface contract (D-01, Phase 39)" do
    test "renders exactly one <h1> equal to the title string" do
      html = render_component(&ScoriaWeb.UI.page_header/1, title: "Datasets")

      assert html =~ "<h1>Datasets</h1>"
      assert html |> String.split("<h1") |> length() == 2
    end

    test "renders a :summary slot as a <p class=\"scoria-pagehead__description\"> below the title" do
      html =
        render_component(&ScoriaWeb.UI.page_header/1,
          title: "Datasets",
          summary: slot_block("Curate production traces into eval datasets.")
        )

      assert html =~ ~s(<p class="scoria-pagehead__description">)
      assert html =~ "Curate production traces into eval datasets."
    end

    test "no :summary slot renders no description <p>" do
      html = render_component(&ScoriaWeb.UI.page_header/1, title: "Datasets")

      refute html =~ "scoria-pagehead__description"
    end

    test "a single :actions entry renders in the action region with the --with-actions modifier" do
      html =
        render_component(&ScoriaWeb.UI.page_header/1,
          title: "Review Queue",
          actions: safe_slot_block(~s(<a href="/">Back to dashboard</a>))
        )

      assert html =~ "scoria-pagehead__title--with-actions"
      assert html =~ "Back to dashboard"
    end

    test "zero :actions entries render no action region and no --with-actions modifier" do
      html = render_component(&ScoriaWeb.UI.page_header/1, title: "Datasets")

      refute html =~ "scoria-pagehead__title--with-actions"
    end

    test "reuses only existing .scoria-pagehead* classes, no new CSS class" do
      html =
        render_component(&ScoriaWeb.UI.page_header/1,
          title: "Datasets",
          summary: slot_block("Summary."),
          actions: safe_slot_block(~s(<a href="/">Back</a>))
        )

      assert html =~ "scoria-pagehead"
      assert html =~ "scoria-pagehead__title"
      assert html =~ "scoria-pagehead__title--with-actions"
      assert html =~ "scoria-pagehead__description"
    end
  end

  describe "status_label/1 additive curated upgrade (D-24a/D-25, Phase 39)" do
    test "curates the D-25 canonical status vocabulary" do
      curated = %{
        "pending" => "Pending",
        "approved" => "Approved",
        "expired" => "Expired",
        "passed" => "Passed",
        "failed" => "Failed",
        "regressed" => "Regressed",
        "running" => "Running",
        "promoted" => "Promoted",
        "draft" => "Draft",
        "published" => "Published",
        "connected" => "Connected",
        "disconnected" => "Disconnected",
        "idle" => "Idle"
      }

      for {status, label} <- curated do
        assert ScoriaWeb.UI.status_label(status) == label
      end
    end

    test "an unseen status still returns a titleized string via the retained generic clause, never raises" do
      assert ScoriaWeb.UI.status_label("some_unseen_status") == "Some unseen status"
    end

    test "atom input delegates through the binary path unchanged" do
      assert ScoriaWeb.UI.status_label(:pending) == "Pending"
    end

    test "does not curate \"rejected\" to \"Denied\" (D-24d, approval-domain only)" do
      assert ScoriaWeb.UI.status_label("rejected") == "Rejected"
    end

    test "still returns \"Unknown\" for non-atom, non-binary input" do
      assert ScoriaWeb.UI.status_label(123) == "Unknown"
    end

    test "curated clauses are structurally above the retained generic fallback (D-24a)" do
      ui_source = File.read!("lib/scoria_web/ui.ex")

      [_before, after_start] =
        String.split(ui_source, "def status_label(status) when is_binary(status) do", parts: 2)

      [binary_clause_body, _rest] =
        String.split(after_start, "\n  def status_label(_), do: \"Unknown\"", parts: 2)

      assert binary_clause_body =~ "case status do"
      assert binary_clause_body =~ ~s("approved" -> "Approved")
      assert binary_clause_body =~ "String.replace(\"_\", \" \")"
      refute binary_clause_body =~ ~s("rejected" -> "Denied")

      {case_index, _} = :binary.match(binary_clause_body, "case status do")
      {fallback_index, _} = :binary.match(binary_clause_body, "String.replace(\"_\", \" \")")
      assert fallback_index > case_index
    end
  end

  describe "time/1 design-system primitive" do
    test "renders accessible exact time with operator-friendly elapsed text" do
      html =
        render_component(&ScoriaWeb.UI.time/1,
          at: ~U[2026-06-19 20:01:00Z],
          mode: :elapsed
        )

      assert html =~ ~s(<time)
      assert html =~ ~s(datetime="2026-06-19T20:01:00Z")
      assert html =~ ~s(title="2026-06-19 20:01 UTC")
      assert html =~ "Waiting "
      assert html =~ "scoria-time"
    end

    test "renders fallback text when a timestamp is not recorded" do
      html =
        render_component(&ScoriaWeb.UI.time/1,
          at: nil,
          fallback: "Not requested yet"
        )

      refute html =~ ~s(<time)
      assert html =~ ~s(<span)
      assert html =~ "Not requested yet"
      assert html =~ "scoria-time"
    end
  end

  describe "dashboard theme and CSS source contracts" do
    test "theme defaults to system mode before the LiveView hook mounts" do
      root_source = File.read!("lib/scoria_web/components/layouts/root.html.heex")
      app_source = File.read!("lib/scoria_web/components/layouts/app.html.heex")
      js_source = File.read!("assets/js/scoria.js")

      assert root_source =~ ~s(data-theme-mode="system")
      assert root_source =~ "var mode ="
      assert root_source =~ ~s(pref : "system")
      assert root_source =~ "document.documentElement.setAttribute(\"data-theme-mode\", mode);"
      assert app_source =~ ~s(title="Theme: System)
      refute app_source =~ ~s(<span data-theme-label>Theme</span>)
      assert js_source =~ "return THEME_MODES.indexOf(v) >= 0 ? v : \"system\";"
      assert js_source =~ "document.documentElement.setAttribute(\"data-theme-mode\", mode);"
      refute js_source =~ "textContent = label"
    end

    test "flush panel gutters use component variables instead of deep structural selectors" do
      css_source = File.read!("assets/css/04-components.css")
      docs_source = File.read!("docs/MAINTAINERS.md")

      assert css_source =~ "--scoria-panel-header-padding-inline"
      assert css_source =~ "--scoria-table-control-padding-inline"
      assert css_source =~ ".scoria-page-section"
      assert css_source =~ ".scoria-overview-stats"
      assert css_source =~ ".scoria-theme-label::before"
      assert css_source =~ ".scoria-raw-evidence__copy"
      assert css_source =~ ".scoria-button--icon-md"
      assert css_source =~ ".scoria-button--icon-sm"
      assert css_source =~ "transition:\n      opacity var(--scoria-dur-fast)"
      refute css_source =~ ".scoria-panel--flush > .scoria-table-shell >"
      assert docs_source =~ "prefer block classes, BEM modifiers"
      assert docs_source =~ "avoid reaching"
      assert docs_source =~ "through unrelated components"
    end

    test "raw evidence copy control has a delegated clipboard behavior" do
      js_source = File.read!("assets/js/scoria.js")

      assert js_source =~ "[data-raw-evidence-copy]"
      assert js_source =~ ".scoria-raw-evidence__pre"
      assert js_source =~ "navigator.clipboard.writeText(text)"
      assert js_source =~ "event.stopPropagation()"
      assert js_source =~ "Copy unavailable"
    end

    test "responsive shell chrome keeps mobile navigation out of desktop layout" do
      css_source = File.read!("assets/css/04-components.css")
      js_source = File.read!("assets/js/scoria.js")

      assert css_source =~ ".scoria-mobile-topbar {\n    display: flex;\n    grid-area: topbar;"
      assert css_source =~ ".scoria-topbar {\n    grid-area: topbar;"
      assert css_source =~ "    display: none;\n    align-items: center;"
      assert css_source =~ "@media (min-width: 768px)"
      assert css_source =~ ".scoria-topbar {\n      display: flex;\n    }"

      assert css_source =~
               ".scoria-mobile-topbar,\n    .scoria-mobile-drawer-shell {\n      display: none;"

      {mobile_topbar_pos, _} =
        :binary.match(css_source, ".scoria-mobile-topbar {\n    display: flex;")

      {desktop_override_pos, _} =
        :binary.match(css_source, "/* Desktop layout restored at >=768px")

      assert desktop_override_pos > mobile_topbar_pos
      assert js_source =~ "window.matchMedia(\"(min-width: 768px)\")"
      assert js_source =~ "forceCloseForDesktop"
      assert js_source =~ "this.desktopMedia.addEventListener(\"change\", this.mediaHandler)"
    end
  end

  # ---------------------------------------------------------------------------
  # IA-02/03/04/06: Orientation spine primitives (phase 13-01)
  # ---------------------------------------------------------------------------

  describe "attention_card/1" do
    test "overview_stats renders contextual overview signals without bare metric cards" do
      html =
        render_component(&ScoriaWeb.UI.overview_stats/1,
          label: "Queue summary",
          stat: [
            %{
              __slot__: :stat,
              label: "Needs review",
              value: "3 flagged items",
              tone: :warn,
              inner_block: fn _changed, _arg ->
                "Traces sampled from production that still need a decision."
              end
            },
            %{
              __slot__: :stat,
              label: "Ready to promote",
              value: "1 promotion candidate",
              tone: :trace,
              inner_block: fn _changed, _arg ->
                "Strong examples that can become dataset evidence."
              end
            }
          ]
        )

      assert html =~ "scoria-overview-stats"
      assert html =~ ~s(aria-label="Queue summary")
      assert html =~ "Needs review"
      assert html =~ "3 flagged items"
      assert html =~ "Traces sampled from production"
      assert html =~ "scoria-overview-stat--warn"
      assert html =~ "scoria-overview-stat--trace"
      refute html =~ "scoria-metric"
    end

    test "renders a count, detail copy, and one-click destination without chart language" do
      html =
        render_component(&ScoriaWeb.UI.attention_card/1,
          count: "3",
          label: "Approvals pending",
          detail: "3 tool calls require approval.",
          cta: "Review approvals",
          path: "/approvals"
        )

      assert html =~ "3"
      assert html =~ "Approvals pending"
      assert html =~ "3 tool calls require approval."
      assert html =~ "Review approvals"
      assert html =~ ~s(href="/approvals")
      refute html =~ "chart"
      refute html =~ "sparkline"
    end
  end

  describe "object_header/1" do
    test "selectable_card renders routed current object with stable selected classes" do
      html =
        render_component(&ScoriaWeb.UI.selectable_card/1,
          href: "/incidents/inc_42",
          selected: true,
          tone: :warn,
          "aria-current": "page",
          title: slot_block("Incident summary"),
          status: slot_block("Warning"),
          meta: slot_block("route review - open")
        )

      assert html =~ ~s(href="/incidents/inc_42")
      assert html =~ ~s(aria-current="page")
      assert html =~ "scoria-selectable-card"
      assert html =~ "scoria-selectable-card--warn"
      assert html =~ "scoria-selectable-card--selected"
      assert html =~ "Incident summary"
      assert html =~ "route review - open"
    end

    test "renders breadcrumbs, copyable id, status, and origin return chip" do
      html =
        render_component(&ScoriaWeb.UI.object_header/1,
          parent_label: "Runs",
          parent_path: "/workflows",
          object_type: "Run",
          object_id: "trc_01J8ABCDEFGQK4",
          status: "failed",
          key_scalar: "support_agent",
          origin: %{noun: "incident", id: "inc_42", path: "/incidents"},
          provenance: "Replayed from run trc_01J8ABC via prompt pr_9 - Jun 9"
        )

      assert html =~ "Runs"
      assert html =~ "trc_01J8...QK4"
      assert html =~ ~s(data-copy="trc_01J8ABCDEFGQK4")
      assert html =~ ~s(title="trc_01J8ABCDEFGQK4")
      assert html =~ "Run"
      assert html =~ "Failed"
      assert html =~ "support_agent"
      assert html =~ "Replayed from run"
      assert html =~ "← Back to incident inc_42"
    end
  end

  describe "stub_page/1" do
    test "renders honest coming-soon copy and no fake populated surface" do
      html =
        render_component(&ScoriaWeb.UI.stub_page/1,
          title: "Cost Ledger",
          description:
            "Cost Ledger will reconcile model spend per run, tenant, and prompt version.",
          tracking_url: "https://github.com/szTheory/scoria/issues?q=is%3Aissue+Cost+Ledger",
          works_today: [
            %{label: "Inspect per-span usage in Runs", path: "/workflows"},
            %{label: "Review campaign cost in Eval Workbench", path: "/eval_specs"}
          ]
        )

      assert html =~ "Cost Ledger"
      assert html =~ "Soon"
      assert html =~ "What works today"
      assert html =~ "Track progress"
      assert html =~ "Inspect per-span usage in Runs"
      refute html =~ "mock chart"
      refute html =~ "sample row"
      refute html =~ "skeleton"
    end
  end

  describe "kbd/1" do
    test "renders shortcut text in a semantic keyboard chip" do
      html = render_component(&ScoriaWeb.UI.kbd/1, inner_block: slot_block("Cmd K"))

      assert html =~ "<kbd"
      assert html =~ "scoria-kbd"
      assert html =~ "Cmd K"
    end
  end

  describe "command_palette/1" do
    test "renders accessible dialog, listbox rows, shortcuts, and locked empty copy" do
      html =
        render_component(&ScoriaWeb.UI.command_palette/1,
          id: "scoria-command",
          sections: [
            %{
              label: "Navigate",
              rows: [
                %{
                  id: "nav-runs",
                  label: "Runs",
                  path: "/workflows",
                  aliases: ["workflows"],
                  kbd: "g r"
                }
              ]
            }
          ]
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(role="option")
      assert html =~ ~s(aria-activedescendant)
      assert html =~ "Runs"
      assert html =~ "g r"

      assert html =~
               "No matches. The palette covers screens, recent objects, and actions — full object search lands in a later release."
    end
  end

  describe "modal/1" do
    test "show: true renders role=dialog and aria-modal=true" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("Modal content")
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "title gives the dialog an accessible name via aria-labelledby (WR-02)" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          title: "Confirm deletion",
          on_dismiss: "close_modal",
          inner_block: slot_block("Modal content")
        )

      assert html =~ ~s(aria-labelledby="test-modal-title")
      assert html =~ ~s(id="test-modal-title")
    end

    test "show: true renders aria-label=Close dialog on close button" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("Modal content")
        )

      assert html =~ ~s(aria-label="Close dialog")
      assert html =~ "scoria-button--icon-md"
    end

    test "show: false renders nothing (no panel, no scrim)" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: false,
          on_dismiss: "close_modal",
          inner_block: slot_block("Modal content")
        )

      refute html =~ "scoria-modal__panel"
      refute html =~ "scoria-scrim"
    end

    test "binds phx-window-keydown and phx-key=Escape to on_dismiss" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "my_dismiss_event",
          inner_block: slot_block("Modal content")
        )

      assert html =~ ~s(phx-window-keydown="my_dismiss_event")
      assert html =~ ~s(phx-key="Escape")
    end

    test "footer slot rendered when provided" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("Body"),
          footer: slot_block("Save button")
        )

      assert html =~ "scoria-modal__footer"
      assert html =~ "Save button"
    end

    test "no footer rendered when footer slot is absent" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("Body")
        )

      refute html =~ "scoria-modal__footer"
    end
  end

  describe "drawer/1" do
    test "show: true renders an accessible icon close button" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: slot_block("Drawer content")
        )

      assert html =~ ~s(aria-label="Close drawer")
      assert html =~ ~s(title="Close drawer")

      assert html =~
               ~s(class="scoria-button scoria-button--ghost scoria-button--sm scoria-button--icon scoria-button--icon-md")

      assert html =~ ~s(aria-hidden="true")
      refute html =~ ">Close drawer</button>"
    end

    test "show: true renders role=dialog and aria-modal=true" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: slot_block("Drawer content")
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "title gives the dialog an accessible name via aria-labelledby (WR-02)" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          title: "Connector detail",
          on_dismiss: "close_drawer",
          inner_block: slot_block("Drawer content")
        )

      assert html =~ ~s(aria-labelledby="test-drawer-title")
      assert html =~ ~s(id="test-drawer-title")
    end

    test "show: false renders nothing (no drawer, no scrim)" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: false,
          on_dismiss: "close_drawer",
          inner_block: slot_block("Drawer content")
        )

      refute html =~ "scoria-drawer"
      refute html =~ "scoria-scrim"
    end

    test "scrim binds phx-window-keydown and phx-key=Escape to on_dismiss" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "my_dismiss_event",
          inner_block: slot_block("Drawer content")
        )

      assert html =~ ~s(phx-window-keydown="my_dismiss_event")
      assert html =~ ~s(phx-key="Escape")
    end
  end

  # ---------------------------------------------------------------------------
  # DS-03: <.field> and <.form_section> (plan 12-03)
  # ---------------------------------------------------------------------------

  describe "field/1" do
    test "renders label with for= binding" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "email",
          label: "Email address",
          inner_block: slot_block(~s(<input id="email" />))
        )

      assert html =~ ~s(for="email")
      assert html =~ "Email address"
    end

    test "required: true renders aria-hidden asterisk and sr-only (required)" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "email",
          label: "Email",
          required: true,
          inner_block: slot_block(~s(<input id="email" />))
        )

      assert html =~ ~s(aria-hidden="true")
      assert html =~ "*"
      assert html =~ "(required)"
    end

    test "error renders error text and inline svg icon" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "email",
          label: "Email",
          error: "Email is required.",
          inner_block: slot_block(~s(<input id="email" />))
        )

      assert html =~ "Email is required."
      assert html =~ "<svg"
      assert html =~ "scoria-field__error"
    end

    test "help text renders below the input slot when @help is set" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "email",
          label: "Email",
          help: "We never share it.",
          inner_block: slot_block(~s(<input id="email" />))
        )

      assert html =~ "We never share it."
      assert html =~ "scoria-field__help"
    end

    test "caller inner_block content is rendered inside the field wrapper" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "myinput",
          label: "Name",
          inner_block: slot_block("my-inner-content")
        )

      assert html =~ "my-inner-content"
      assert html =~ "scoria-field"
    end
  end

  describe "form_section/1" do
    test "renders title heading" do
      html =
        render_component(&ScoriaWeb.UI.form_section/1,
          title: "Contact Details",
          inner_block: slot_block("")
        )

      assert html =~ "Contact Details"
      assert html =~ "scoria-form-section"
    end

    test "renders description when provided" do
      html =
        render_component(&ScoriaWeb.UI.form_section/1,
          title: "Contact Details",
          description: "Your public contact info.",
          inner_block: slot_block("")
        )

      assert html =~ "Your public contact info."
    end

    test "no description element when description is nil" do
      html =
        render_component(&ScoriaWeb.UI.form_section/1,
          title: "Contact Details",
          inner_block: slot_block("")
        )

      refute html =~ "Your public contact info."
    end
  end

  # ---------------------------------------------------------------------------
  # DS-04: <.notebook> and <.raw_evidence> (plan 12-04)
  # ---------------------------------------------------------------------------

  defp tab_slot(key, label, content) do
    [
      %{
        key: key,
        label: label,
        inner_block: fn _changed, _arg -> content end,
        __slot__: :tab
      }
    ]
  end

  describe "notebook/1" do
    test "renders role=tablist nav and one role=tab button per :tab slot" do
      html =
        render_component(&ScoriaWeb.UI.notebook/1,
          id: "nb-1",
          title: "Evidence",
          selected_tab: "trace",
          on_tab_change: "change_tab",
          tab:
            tab_slot("trace", "Trace", "trace content") ++
              tab_slot("memory", "Memory", "memory content")
        )

      assert html =~ ~s(role="tablist")
      assert html =~ ~s(role="tab")
      # Two tab buttons present
      assert html |> String.split(~s(role="tab")) |> length() > 2
      assert html =~ "Trace"
      assert html =~ "Memory"
    end

    test "active tab carries aria-selected=true; others carry aria-selected=false" do
      html =
        render_component(&ScoriaWeb.UI.notebook/1,
          id: "nb-2",
          title: "Evidence",
          selected_tab: "trace",
          on_tab_change: "change_tab",
          tab:
            tab_slot("trace", "Trace", "trace content") ++
              tab_slot("memory", "Memory", "memory content")
        )

      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(aria-selected="false")
    end

    test "tab buttons emit phx-value-tab with the tab key" do
      html =
        render_component(&ScoriaWeb.UI.notebook/1,
          id: "nb-3",
          title: "Evidence",
          selected_tab: "trace",
          on_tab_change: "change_tab",
          tab: tab_slot("trace", "Trace", "trace content")
        )

      assert html =~ ~s(phx-value-tab="trace")
    end

    test "active tab panel carries role=tabpanel" do
      html =
        render_component(&ScoriaWeb.UI.notebook/1,
          id: "nb-4",
          title: "Evidence",
          selected_tab: "trace",
          on_tab_change: "change_tab",
          tab: tab_slot("trace", "Trace", "trace content")
        )

      assert html =~ ~s(role="tabpanel")
    end

    test "empty: true renders :empty_slot content and no tab buttons" do
      html =
        render_component(&ScoriaWeb.UI.notebook/1,
          id: "nb-5",
          title: "Evidence",
          empty: true,
          tab: [],
          empty_slot: slot_block("No evidence yet")
        )

      assert html =~ "No evidence yet"
      refute html =~ ~s(role="tablist")
      refute html =~ ~s(role="tab")
    end
  end

  describe "raw_evidence/1" do
    test "renders <details> + <summary> + <pre>" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          label: "Advanced raw evidence",
          inner_block: slot_block("{\"key\": \"value\"}")
        )

      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ "<pre"
      assert html =~ "Advanced raw evidence"
      assert html =~ "{&quot;key&quot;: &quot;value&quot;}"
    end

    test "can render open by default for primary payload evidence" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          label: "Request payload",
          value: "%{amount_cents: 12900}",
          open: true
        )

      assert html =~ ~r/<details[^>]*class="[^"]*scoria-raw-evidence[^"]*"[^>]*open/
      assert html =~ "Request payload"
      assert html =~ "%{amount_cents: 12900}"
    end

    test "can render a copy control without nesting it inside the disclosure summary" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          label: "Request payload",
          value: "%{amount_cents: 12900}",
          copyable: true,
          copy_label: "Copy request payload"
        )

      assert html =~ "scoria-raw-evidence--copyable"
      assert html =~ "scoria-button--icon-sm"
      refute html =~ "scoria-button--icon-md scoria-raw-evidence__copy"
      assert html =~ ~s(data-raw-evidence-copy)
      assert html =~ ~s(aria-label="Copy request payload")
      assert html =~ ~s(title="Copy request payload")
      assert html =~ "scoria-raw-evidence__copy-icon--copy"
      assert html =~ "scoria-raw-evidence__copy-icon--check"

      [summary_fragment, _after_summary] = String.split(html, "</summary>", parts: 2)
      refute summary_fragment =~ "data-raw-evidence-copy"
    end

    test "renders default label when not provided" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          inner_block: slot_block("raw data")
        )

      assert html =~ "Advanced raw evidence"
    end
  end

  # ---------------------------------------------------------------------------
  # SCREEN-04: Evidence primitives (phase 15-01)
  # ---------------------------------------------------------------------------

  describe "evidence_section/1" do
    test "renders title, description, actions, badge, and body content" do
      html =
        render_component(&ScoriaWeb.UI.evidence_section/1,
          title: "Semantic summary",
          description: "Compatibility, provenance, and lifecycle evidence.",
          tone: :trace,
          badge: "Trace",
          inner_block: slot_block("Evidence body"),
          actions: safe_slot_block(~s(<a href="/workflows/run_123">Open trace</a>))
        )

      assert html =~ "scoria-evidence-section"
      assert html =~ "scoria-evidence-section__header"
      assert html =~ "Semantic summary"
      assert html =~ "Compatibility, provenance, and lifecycle evidence."
      assert html =~ "Trace"
      assert html =~ ~s(href="/workflows/run_123")
      assert html =~ "Evidence body"
    end
  end

  describe "evidence_rows/1" do
    test "renders stable tuple and map rows in list order" do
      html =
        render_component(&ScoriaWeb.UI.evidence_rows/1,
          rows: [
            {"Runtime", "worker-1"},
            %{label: "Status", value: "active"},
            %{"label" => "Tokens", "value" => 42}
          ]
        )

      assert html =~ "scoria-evidence-rows"
      assert html =~ "scoria-evidence-row"
      assert html =~ "Runtime"
      assert html =~ "worker-1"
      assert html =~ "Status"
      assert html =~ "active"
      assert html =~ "Tokens"
      assert html =~ "42"

      assert String.match?(
               html,
               ~r/Runtime.*worker-1.*Status.*active.*Tokens.*42/s
             )
    end

    test "escapes unsafe row values" do
      html =
        render_component(&ScoriaWeb.UI.evidence_rows/1,
          rows: [{"Unsafe", ~S|<script>alert("x")</script>|}]
        )

      assert html =~ "Unsafe"
      assert html =~ "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;"
      refute html =~ ~S|<script>alert("x")</script>|
    end
  end

  describe "evidence_action_row/1" do
    test "renders caller-provided compact action content" do
      html =
        render_component(&ScoriaWeb.UI.evidence_action_row/1,
          inner_block:
            safe_slot_block(
              ~s(<a class="scoria-button scoria-button--ghost" href="/runs">Open trace</a>)
            )
        )

      assert html =~ "scoria-evidence-action-row"
      assert html =~ "Open trace"
      assert html =~ ~s(href="/runs")
    end
  end

  describe "evidence_empty/1" do
    test "renders notebook-scoped empty title and body copy" do
      html =
        render_component(&ScoriaWeb.UI.evidence_empty/1,
          title: "No memory evidence",
          inner_block: slot_block("Memory summaries appear after the runtime archives context.")
        )

      assert html =~ "scoria-evidence-empty"
      assert html =~ "No memory evidence"
      assert html =~ "Memory summaries appear after the runtime archives context."
    end
  end

  describe "evidence primitive CSS" do
    test "declares token-bound class families without raw hex colors" do
      css = File.read!("assets/css/04-components.css")

      assert css =~ ".scoria-evidence-section"
      assert css =~ ".scoria-evidence-rows"
      assert css =~ ".scoria-evidence-action-row"
      assert css =~ ".scoria-evidence-empty"

      evidence_css =
        css
        |> String.split("/* ---------- Evidence primitives ---------- */")
        |> List.last()
        |> String.split("/* ---------- End evidence primitives ---------- */")
        |> List.first()

      refute evidence_css =~ ~r/#[0-9a-fA-F]{3,8}\b/

      refute evidence_css =~
               ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/
    end
  end

  # ---------------------------------------------------------------------------
  # DS-05: <.skeleton> and <.toast> (plan 12-04)
  # ---------------------------------------------------------------------------

  describe "skeleton/1" do
    test "renders aria-label=Loading… and scoria-skeleton class" do
      html = render_component(&ScoriaWeb.UI.skeleton/1, rows: 1)
      assert html =~ ~s(aria-label="Loading…")
      assert html =~ "scoria-skeleton"
    end

    test "skeleton rows={3} renders 3 skeleton line elements" do
      html = render_component(&ScoriaWeb.UI.skeleton/1, rows: 3)
      count = html |> String.split("scoria-skeleton--text") |> length() |> Kernel.-(1)
      assert count == 3
    end

    test "skeleton carries role=status" do
      html = render_component(&ScoriaWeb.UI.skeleton/1, rows: 1)
      assert html =~ ~s(role="status")
    end

    test "skeleton rows={0} renders zero line elements (WR-01)" do
      # 1..0//1 is an empty range; the legacy 1..0 was a decreasing [1, 0] and
      # rendered 2 rows. Guard against that regression.
      html = render_component(&ScoriaWeb.UI.skeleton/1, rows: 0)
      count = html |> String.split("scoria-skeleton--text") |> length() |> Kernel.-(1)
      assert count == 0
    end
  end

  describe "toast/1" do
    test "tone={:pass} renders scoria-toast--pass" do
      html =
        render_component(&ScoriaWeb.UI.toast/1,
          id: "toast-1",
          tone: :pass,
          message: "Saved"
        )

      assert html =~ "scoria-toast--pass"
    end

    test "renders role=status and message text" do
      html =
        render_component(&ScoriaWeb.UI.toast/1,
          id: "toast-2",
          tone: :neutral,
          message: "Saved"
        )

      assert html =~ ~s(role="status")
      assert html =~ "Saved"
    end

    test "renders phx-mounted with JS.hide directive" do
      html =
        render_component(&ScoriaWeb.UI.toast/1,
          id: "toast-3",
          tone: :neutral,
          message: "Saved",
          duration_ms: 2000
        )

      assert html =~ "phx-mounted"
    end

    test "renders manual dismiss button with aria-label=Dismiss" do
      html =
        render_component(&ScoriaWeb.UI.toast/1,
          id: "toast-4",
          tone: :neutral,
          message: "Saved"
        )

      assert html =~ ~s(aria-label="Dismiss")
    end

    test "manual dismiss targets the toast by id, not the button itself" do
      # A bare JS.hide on the dismiss button would hide the button and leave the
      # toast on screen; it must target the toast div (to: \"#id\").
      html =
        render_component(&ScoriaWeb.UI.toast/1,
          id: "toast-dismiss",
          tone: :neutral,
          message: "Saved"
        )

      # The JS.hide target id (#toast-dismiss) appears only in the button's encoded
      # phx-click — the plain id attribute is "toast-dismiss" without the leading #.
      assert html =~ "#toast-dismiss"
    end
  end

  # ---------------------------------------------------------------------------
  # DS-04 proof adapter: RemoteInvocationEvidenceComponent (plan 12-05)
  # ---------------------------------------------------------------------------

  describe "RemoteInvocationEvidenceComponent/1 notebook adapter" do
    test "renders scoria-notebook shell and Remote tab label" do
      html =
        render_component(
          &ScoriaWeb.RemoteInvocationEvidenceComponent.render/1,
          evidence: %{
            approvals: [
              %{id: "ap-1", tool_name: "test_tool", status: "approved"}
            ]
          }
        )

      assert html =~ "scoria-notebook"
      assert html =~ "Remote"
    end

    test "renders approval tool_name inside the notebook tab" do
      html =
        render_component(
          &ScoriaWeb.RemoteInvocationEvidenceComponent.render/1,
          evidence: %{
            approvals: [
              %{id: "ap-2", tool_name: "my_tool", status: "pending"}
            ]
          }
        )

      assert html =~ "my_tool"
      assert html =~ "pending"
    end

    test "renders empty approvals list without errors" do
      html =
        render_component(
          &ScoriaWeb.RemoteInvocationEvidenceComponent.render/1,
          evidence: %{approvals: []}
        )

      assert html =~ "scoria-notebook"
    end

    test "uses shared evidence sections and rows instead of local panel chrome" do
      source = File.read!("lib/scoria_web/components/remote_invocation_evidence_component.ex")

      assert source =~ "evidence_section"
      assert source =~ "evidence_rows"
      refute source =~ "scoria-panel scoria-panel--raised"
    end
  end

  # ---------------------------------------------------------------------------
  # DS-01: <.table> (plan 12-02)
  # ---------------------------------------------------------------------------

  describe "table/1" do
    test "renders column header from :col label" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      assert html =~ "Status"
    end

    test "total_pages > 1 without on_page_change raises (WR-05)" do
      assert_raise ArgumentError, ~r/on_page_change/, fn ->
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          total_pages: 3,
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )
      end
    end

    test "sortable column emits phx-value-by with key" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          on_sort: "sort",
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      assert html =~ ~s(phx-click="sort")
      assert html =~ ~s(phx-value-by="status")
    end

    test "sortable headers are opt-in to avoid unowned LiveView events" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      refute html =~ ~s(phx-click="sort")
      refute html =~ ~s(phx-value-by="status")
    end

    test "table uses one canonical class with no density modifiers" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      assert html =~ ~s(<table class="scoria-table" id="test-table">)
      refute html =~ "scoria-table--compact"
      refute html =~ "scoria-table--comfortable"
    end

    test "table does not expose row density controls" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      refute html =~ "Row density"
      refute html =~ ~s(phx-click="set_density")
      refute html =~ "phx-value-density"
      refute html =~ "aria-pressed"
    end

    test "table source and CSS keep density out of the public API" do
      ui_source = File.read!("lib/scoria_web/ui.ex")
      css_source = File.read!("assets/css/04-components.css")
      docs_source = File.read!("docs/MAINTAINERS.md")

      refute ui_source =~ "on_density_change"
      refute ui_source =~ "density_class"
      refute ui_source =~ "phx-value-density"
      refute css_source =~ ".scoria-table__density-toggle"
      refute css_source =~ ".scoria-table--compact"
      refute css_source =~ ".scoria-table--comfortable"
      assert docs_source =~ "canonical compact scan density"
    end

    test "rows=[] renders default empty state 'No records found'" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      assert html =~ "No records found"
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 16-02: table/1 overflow viewport + opt-in mobile_summary slot
  # ---------------------------------------------------------------------------

  describe "table/1 responsive viewport (16-02)" do
    test "wraps <table> in scoria-table__viewport div with tabindex=0 (default, no mobile_summary)" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      assert html =~ ~s(class="scoria-table__viewport")
      assert html =~ ~s(tabindex="0")
      assert html =~ "<table"
    end

    test "no mobile_summary slot => no scoria-table__mobile-summaries container" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [%{name: "Alice"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ]
        )

      refute html =~ "scoria-table__mobile-summaries"
    end

    test "mobile_summary slot => scoria-table__mobile-summaries container rendered" do
      summary_slot = [
        %{
          inner_block: fn _changed, row -> "Summary: #{row.name}" end,
          __slot__: :mobile_summary
        }
      ]

      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [%{name: "Alice"}, %{name: "Bob"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ],
          mobile_summary: summary_slot
        )

      assert html =~ "scoria-table__mobile-summaries"
      assert html =~ "Summary: Alice"
      assert html =~ "Summary: Bob"
    end

    test "mobile_summary with two rows yields two summary blocks" do
      summary_slot = [
        %{
          inner_block: fn _changed, row -> ~s(<div class="summary-item">#{row.name}</div>) end,
          __slot__: :mobile_summary
        }
      ]

      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [%{name: "Alice"}, %{name: "Bob"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ],
          mobile_summary: summary_slot
        )

      assert html =~ "Alice"
      assert html =~ "Bob"
    end

    test "<table> element is still present when mobile_summary slot is provided (desktop semantics preserved)" do
      summary_slot = [
        %{
          inner_block: fn _changed, _row -> "summary" end,
          __slot__: :mobile_summary
        }
      ]

      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [%{name: "Alice"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ],
          mobile_summary: summary_slot
        )

      assert html =~ "<table"
      assert html =~ "scoria-table__viewport"
    end

    test "sorted column header carries aria-sort=ascending when sort_dir is :asc" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          sort_by: :name,
          sort_dir: :asc,
          on_sort: "sort",
          col: [%{label: "Name", key: :name, class: nil, inner_block: []}]
        )

      assert html =~ ~s(aria-sort="ascending")
    end

    test "sorted column header carries aria-sort=descending when sort_dir is :desc" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          sort_by: :name,
          sort_dir: :desc,
          on_sort: "sort",
          col: [%{label: "Name", key: :name, class: nil, inner_block: []}]
        )

      assert html =~ ~s(aria-sort="descending")
    end

    test "unsorted sortable column header carries aria-sort=none" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          sort_by: :name,
          sort_dir: :asc,
          on_sort: "sort",
          col: [
            %{label: "Name", key: :name, class: nil, inner_block: []},
            %{label: "Status", key: :status, class: nil, inner_block: []}
          ]
        )

      # sorted column gets ascending
      assert html =~ ~s(aria-sort="ascending")
      # non-sorted sortable column gets none
      assert html =~ ~s(aria-sort="none")
    end

    test "scoria-table-shell gets has-summary modifier class when mobile_summary slot is provided" do
      summary_slot = [
        %{
          inner_block: fn _changed, _row -> "summary" end,
          __slot__: :mobile_summary
        }
      ]

      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [%{name: "Alice"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ],
          mobile_summary: summary_slot
        )

      assert html =~ "scoria-table-shell--has-summary"
    end

    test "scoria-table-shell does NOT get has-summary modifier when mobile_summary slot is absent" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      refute html =~ "scoria-table-shell--has-summary"
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 16-05: Focus/status/motion hardening (D-23/D-24/MOTION-02)
  # ---------------------------------------------------------------------------

  describe "badge/1 non-color-only status (16-05 D-24)" do
    test "renders visible label text alongside tone class (never color-alone)" do
      html =
        render_component(&ScoriaWeb.UI.badge/1,
          tone: :pass,
          label: "Completed"
        )

      # tone class carries color
      assert html =~ "scoria-badge--pass"
      # visible text label is present — not color alone
      assert html =~ "Completed"
    end

    test "inner_block content renders as visible text when label is nil" do
      html = render_component(&ScoriaWeb.UI.badge/1, inner_block: slot_block("Running"))

      assert html =~ "scoria-badge"
      assert html =~ "Running"
    end

    test "bare dot-less badge still carries visible label text" do
      html =
        render_component(&ScoriaWeb.UI.badge/1,
          tone: :warn,
          label: "Pending",
          dot: false
        )

      assert html =~ "scoria-badge--bare"
      assert html =~ "Pending"
    end
  end

  describe "workflow_tree/1 selected-row ARIA (16-05 D-24)" do
    test "selected step carries aria-current=true (non-color-only selection)" do
      html =
        render_component(&ScoriaWeb.WorkflowTreeComponent.workflow_tree/1,
          steps: [
            %{id: "step-1", kind: "llm", role_id: "generate", status: "completed", depth: 0}
          ],
          selected_step_id: "step-1"
        )

      assert html =~ ~s(aria-current="true")
      assert html =~ "scoria-row-selected"
    end

    test "unselected step carries no aria-current and no scoria-row-selected" do
      html =
        render_component(&ScoriaWeb.WorkflowTreeComponent.workflow_tree/1,
          steps: [
            %{id: "step-1", kind: "llm", role_id: "generate", status: "completed", depth: 0}
          ],
          selected_step_id: nil
        )

      refute html =~ ~s(aria-current="true")
      refute html =~ "scoria-row-selected"
    end
  end

  describe "table/1 aria-sort non-color-only sort (16-05 D-24 / MOTION-02)" do
    test "sorted column header carries aria-sort (non-color-only sort direction)" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          sort_by: :status,
          sort_dir: :asc,
          on_sort: "sort",
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      # aria-sort is the non-color ARIA complement to the SVG sort icon
      assert html =~ ~s(aria-sort="ascending")
    end

    test "sort indicator SVG is present alongside aria-sort on sortable columns" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          sort_by: :status,
          sort_dir: :desc,
          on_sort: "sort",
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      # Both visual (SVG icon) and semantic (aria-sort) cues are present
      assert html =~ "<svg"
      assert html =~ ~s(aria-sort="descending")
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 38-02: stat singularity, copy-control a11y, size scale + focus (D-05/D-07/
  # D-08/D-09/D-12/D-13/D-15)
  # ---------------------------------------------------------------------------

  describe "stat component singularity (DS-03/D-05/D-08)" do
    test "signal_strip/1 is no longer exported; overview_stats/1 and metric/1 remain" do
      refute function_exported?(ScoriaWeb.UI, :signal_strip, 1)
      assert function_exported?(ScoriaWeb.UI, :overview_stats, 1)
      assert function_exported?(ScoriaWeb.UI, :metric, 1)
    end

    test "no .scoria-signal class token remains in the component CSS" do
      css_source = File.read!("assets/css/04-components.css")

      # Class-boundary anchor: matches `.scoria-signal` / `.scoria-signal__x` /
      # `.scoria-signal--x` but must NOT match `.scoria-incident-signal` (a
      # different, in-use component whose token merely contains the substring).
      refute Regex.match?(~r/\.scoria-signal(?:[_-]|\s|,|\{)/, css_source)

      # Sanity anchor: confirm the regex isn't accidentally matching (or the
      # file isn't accidentally empty) by asserting the unrelated component
      # this guard must NOT key on is still present.
      assert css_source =~ ".scoria-incident-signal"
    end
  end

  describe "copy controls (DS-02/DS-03/D-09/D-12)" do
    test "raw_evidence copy control renders at :sm icon scale, never :md" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          copyable: true,
          copy_label: "Copy raw evidence",
          value: "x",
          label: "Evidence"
        )

      assert html =~ "scoria-button--icon-sm"
      refute html =~ "scoria-button--icon-md"
    end

    test "raw_evidence copy control carries a non-empty accessible-name verb" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          copyable: true,
          copy_label: "Copy raw evidence",
          value: "x",
          label: "Evidence"
        )

      assert html =~ ~s(aria-label="Copy raw evidence")
    end

    test "raw_evidence copy-status span announces updates via aria-live" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          copyable: true,
          copy_label: "Copy raw evidence",
          value: "x",
          label: "Evidence"
        )

      assert html =~ ~s(data-raw-evidence-copy-status aria-live="polite")
    end

    test ".scoria-id carries a \"Copy <value>\" aria-label and aria-live" do
      html = render_component(&ScoriaWeb.UI.id/1, value: "appr-9b1d4e2a")

      assert html =~ ~s(aria-label="Copy appr-9b1d4e2a")
      assert html =~ ~s(aria-live="polite")
    end
  end

  describe "primitive size scale + focus uniformity (DS-02/D-13/D-15)" do
    test "button/1 and icon_button/1 expose only the :md/:sm size scale" do
      ui_source = File.read!("lib/scoria_web/ui.ex")

      size_attr_lines =
        ~r/attr\(:size, :atom, default: :\w+, values: \[[^\]]*\]\)/
        |> Regex.scan(ui_source)
        |> Enum.map(&hd/1)

      assert length(size_attr_lines) == 2

      for line <- size_attr_lines do
        assert line =~ "values: [:md, :sm]"
      end

      refute ui_source =~ ~s(style="width:)
      refute ui_source =~ ~s(style="height:)
    end

    test "component layer does not locally override :focus-visible or outline" do
      css_source = File.read!("assets/css/04-components.css")

      # Only forbid actual rule declarations (`:focus-visible {` / `:focus-visible,`),
      # not prose comments that merely mention the pseudo-class (e.g. explaining why
      # overflow-clip-margin exists so the global ring can paint at scroll edges).
      refute Regex.match?(~r/:focus-visible\s*[,{]/, css_source)
      refute Regex.match?(~r/(?<!text-)outline(?:-\w+)?:\s/, css_source)
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 38-03: remaining Criterion 2 primitive coherence guards
  # (links, badges, timestamps, metadata rows, panels, drawers, modals, forms,
  #  tables, lists — 38-01/38-02 covered toasts, stats, copy controls, and the
  #  button size/focus scale only)
  # ---------------------------------------------------------------------------

  describe "primitive accessible-name + structure coverage (DS-02/DS-03/Criterion 2)" do
    test "modal exposes role=dialog, aria-labelledby, and an aria-labelled close control" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "m",
          title: "Confirm",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("body")
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-labelledby="m-title")
      assert html =~ ~s(aria-label="Close dialog")
    end

    test "drawer exposes role=dialog, aria-labelledby, and an aria-labelled close control" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "d",
          title: "Details",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: slot_block("body")
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-labelledby="d-title")
      assert html =~ ~s(aria-label="Close drawer")
    end

    test "field renders a <label for> bound to the input's id" do
      html =
        render_component(&ScoriaWeb.UI.field/1,
          id: "f",
          label: "Name",
          inner_block: slot_block("<input/>")
        )

      assert html =~ ~s(<label for="f")
    end

    test "table renders scoria-table__th column headers and an aria-labelled pagination nav" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "coverage-table",
          rows: [%{name: "Alice"}],
          col: [
            %{label: "Name", key: nil, class: nil, inner_block: fn _changed, row -> row.name end}
          ],
          total_pages: 2,
          page: 1,
          on_page_change: "page"
        )

      assert html =~ ~s(<th class="scoria-table__th)
      assert html =~ "Name"
      assert html =~ ~s(<nav aria-label="Pagination")
    end

    test "badge always renders a visible text label alongside tone (never color-alone)" do
      html =
        render_component(&ScoriaWeb.UI.badge/1,
          tone: :warn,
          label: "Blocked"
        )

      assert html =~ "Blocked"
    end

    test "time renders a machine-readable <time datetime> with an exact-time title" do
      html =
        render_component(&ScoriaWeb.UI.time/1,
          at: ~U[2026-01-01 00:00:00Z]
        )

      assert html =~ "<time"
      assert html =~ ~s(datetime="2026-01-01T00:00:00Z")
      assert html =~ ~s(title="2026-01-01 00:00 UTC")
    end

    test "evidence_rows (metadata rows) renders a <dl> of dt/dd pairs" do
      html =
        render_component(&ScoriaWeb.UI.evidence_rows/1,
          rows: [%{label: "Actor", value: "svc-1"}]
        )

      assert html =~ ~s(<dl class="scoria-evidence-rows)
      assert html =~ "<dt"
      assert html =~ "Actor"
      assert html =~ "<dd"
      assert html =~ "svc-1"
    end
  end

  describe "primitive spacing / variant / link-token coherence (DS-02/DS-03/D-13/D-14)" do
    test "no ad-hoc pixel-valued inline style attribute in ui.ex (D-14)" do
      ui_source = File.read!("lib/scoria_web/ui.ex")

      # Matches a `style="..."` or `style={"..."}` attribute whose literal source text
      # contains digits immediately followed by the `px` unit. Dynamic style bindings
      # that merely reference a variable (e.g. `style={"max-width: #{@max_width}"}`)
      # do NOT match since the interpolated value isn't literal source text here.
      refute Regex.match?(~r/style=(?:"|\{")[^"]*?\d+px/, ui_source)
    end

    test "button/1 variant vocabulary stays locked to [:primary, :ghost, :danger]" do
      ui_source = File.read!("lib/scoria_web/ui.ex")

      # default: :primary uniquely identifies button/1's attr (icon_button/1 shares the
      # same values list but defaults to :ghost).
      assert Regex.match?(
               ~r/attr\(:variant, :atom, default: :primary, values: \[:primary, :ghost, :danger\]\)/,
               ui_source
             )
    end

    test "size scale stays locked to [:md, :sm] (reinforces 38-02's D-13/D-15 guard)" do
      ui_source = File.read!("lib/scoria_web/ui.ex")

      size_attr_lines =
        ~r/attr\(:size, :atom, default: :\w+, values: \[[^\]]*\]\)/
        |> Regex.scan(ui_source)
        |> Enum.map(&hd/1)

      assert length(size_attr_lines) == 2

      for line <- size_attr_lines do
        assert line =~ "values: [:md, :sm]"
      end
    end

    test "tone vocabulary stays within the locked 7-atom set; no new tone atom introduced" do
      ui_source = File.read!("lib/scoria_web/ui.ex")
      locked_tones = MapSet.new([:neutral, :pass, :info, :warn, :fail, :trace, :brand])

      tone_values_lists =
        ~r/attr\(:tone,\s*:atom,?\s*(?:\n\s*default: :\w+,)?\s*values:\s*\[([^\]]*)\]/
        |> Regex.scan(ui_source)
        |> Enum.map(fn [_full, list] -> list end)

      # At least the toast/1 and evidence_section/1 tone attrs must be found — a
      # regex that stops matching entirely (e.g. after a refactor) would silently
      # pass an empty for-loop, so pin a non-empty result.
      assert tone_values_lists != []

      for list_str <- tone_values_lists do
        atoms =
          list_str
          |> String.split(",")
          |> Enum.map(fn s -> s |> String.trim() |> String.trim_leading(":") |> String.to_atom() end)

        assert Enum.all?(atoms, &(&1 in locked_tones)),
               "found a tone atom outside the locked vocabulary in: #{list_str}"
      end
    end

    test "--scoria-link / --scoria-link-hover are declared in both theme blocks and consumed by .scoria-link (DS-01/DS-03)" do
      tokens_source = File.read!("assets/css/02-tokens.css")
      components_source = File.read!("assets/css/04-components.css")

      [dark_block, light_block] =
        Regex.split(~r/\.scoria-root\[data-theme="light"\]\s*\{/, tokens_source, parts: 2)

      assert dark_block =~ "--scoria-link:"
      assert dark_block =~ "--scoria-link-hover:"
      assert light_block =~ "--scoria-link:"
      assert light_block =~ "--scoria-link-hover:"

      assert Regex.match?(
               ~r/\.scoria-link\s*\{[^}]*color:\s*var\(--scoria-link\)/,
               components_source
             )
    end

    test "panel/drawer/modal/form-section/table/evidence-rows/list rules reference spacing tokens (D-14)" do
      components_source = File.read!("assets/css/04-components.css")

      checks = [
        ~r/\.scoria-panel\s*\{([^}]*)\}/,
        ~r/\.scoria-drawer\s*\{([^}]*)\}/,
        ~r/\.scoria-modal__panel\s*\{([^}]*)\}/,
        ~r/\.scoria-form-section\s*\{([^}]*)\}/,
        ~r/\.scoria-table-shell\s*\{([^}]*)\}/,
        ~r/\.scoria-evidence-rows\s*\{([^}]*)\}/,
        ~r/\.scoria-evidence-row\s*\{([^}]*)\}/,
        ~r/\.scoria-selectable-list\s*\{([^}]*)\}/,
        ~r/\.scoria-command__list,\s*\n\s*\.scoria-command__section,\s*\n\s*\.scoria-command__rows\s*\{([^}]*)\}/
      ]

      for regex <- checks do
        assert [_full, body] = Regex.run(regex, components_source), "no rule matched #{inspect(regex)}"
        assert body =~ "var(--scoria-space"
      end
    end
  end
end

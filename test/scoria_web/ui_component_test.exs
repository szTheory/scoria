defmodule ScoriaWeb.UIComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  @moduledoc """
  Unit test scaffold for Phase 12 design-system components in ScoriaWeb.UI.

  This module is created in plan 12-01 as the shared test header so that downstream
  component plans (12-02, 12-03, 12-04) add assertions here instead of scaffolding.

  Test groups to be filled in by later plans:

    DS-01: <.table> — sortable, filterable, paginated data table (plan 12-02)
      - renders column headers
      - renders rows
      - renders empty state when rows == []
      - applies density modifier classes (compact/default/comfortable)

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

  describe "modal/1" do
    test "show: true renders role=dialog and aria-modal=true" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: [%{inner_block: "Modal content"}]
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "show: true renders aria-label=Close dialog on close button" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: [%{inner_block: "Modal content"}]
        )

      assert html =~ ~s(aria-label="Close dialog")
    end

    test "show: false renders nothing (no panel, no scrim)" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: false,
          on_dismiss: "close_modal",
          inner_block: [%{inner_block: "Modal content"}]
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
          inner_block: [%{inner_block: "Modal content"}]
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
          inner_block: [%{inner_block: "Body"}],
          footer: [%{inner_block: "Save button"}]
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
          inner_block: [%{inner_block: "Body"}]
        )

      refute html =~ "scoria-modal__footer"
    end
  end

  describe "drawer/1" do
    test "show: true renders Close drawer button" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: [%{inner_block: "Drawer content"}]
        )

      assert html =~ "Close drawer"
    end

    test "show: true renders role=dialog and aria-modal=true" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: [%{inner_block: "Drawer content"}]
        )

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "show: false renders nothing (no drawer, no scrim)" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: false,
          on_dismiss: "close_drawer",
          inner_block: [%{inner_block: "Drawer content"}]
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
          inner_block: [%{inner_block: "Drawer content"}]
        )

      assert html =~ ~s(phx-window-keydown="my_dismiss_event")
      assert html =~ ~s(phx-key="Escape")
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

    test "sortable column emits phx-value-by with key" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          col: [%{label: "Status", key: :status, class: nil, inner_block: []}]
        )

      assert html =~ ~s(phx-value-by="status")
    end

    test "density :compact yields scoria-table--compact" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          density: :compact,
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      assert html =~ "scoria-table--compact"
    end

    test "density :default yields no compact or comfortable modifier" do
      html =
        render_component(&ScoriaWeb.UI.table/1,
          id: "test-table",
          rows: [],
          density: :default,
          col: [%{label: "Name", key: nil, class: nil, inner_block: []}]
        )

      refute html =~ "scoria-table--compact"
      refute html =~ "scoria-table--comfortable"
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
end

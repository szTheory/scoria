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

  # Helper: a minimal slot inner_block entry that renders a static string
  defp slot_block(content),
    do: [%{inner_block: fn _changed, _arg -> content end, __slot__: :inner_block}]

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

    test "show: true renders aria-label=Close dialog on close button" do
      html =
        render_component(&ScoriaWeb.UI.modal/1,
          id: "test-modal",
          show: true,
          on_dismiss: "close_modal",
          inner_block: slot_block("Modal content")
        )

      assert html =~ ~s(aria-label="Close dialog")
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
    test "show: true renders Close drawer button" do
      html =
        render_component(&ScoriaWeb.UI.drawer/1,
          id: "test-drawer",
          show: true,
          on_dismiss: "close_drawer",
          inner_block: slot_block("Drawer content")
        )

      assert html =~ "Close drawer"
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
          tab: tab_slot("trace", "Trace", "trace content") ++ tab_slot("memory", "Memory", "memory content")
        )

      assert html =~ ~s(role="tablist")
      assert html =~ ~s(role="tab")
      # Two tab buttons present
      assert (html |> String.split(~s(role="tab")) |> length()) > 2
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
          tab: tab_slot("trace", "Trace", "trace content") ++ tab_slot("memory", "Memory", "memory content")
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

    test "renders default label when not provided" do
      html =
        render_component(&ScoriaWeb.UI.raw_evidence/1,
          inner_block: slot_block("raw data")
        )

      assert html =~ "Advanced raw evidence"
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

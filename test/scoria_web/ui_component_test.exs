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

  # This smoke test confirms the scaffold is present and the test header compiles.
  # Downstream plans replace this placeholder with real render_component assertions.
  test "ui_component_test scaffold present" do
    assert true
  end
end

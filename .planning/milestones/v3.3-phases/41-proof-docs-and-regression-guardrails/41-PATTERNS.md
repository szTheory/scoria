# Phase 41: Proof, Docs, And Regression Guardrails - Pattern Map

**Mapped:** 2026-07-04
**Files analyzed:** 13 code files (+ 3 planning-markdown artifacts with no code analog, listed separately)
**Analogs found:** 13 / 13

This phase is a **lock-and-document phase**: nearly every new/modified file has a strong, cited
1:1 analog already in the repo (confirmed by RESEARCH.md's direct source reads). This map adds the
exact excerpts + line numbers the planner needs to write actions without re-deriving them.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria_web/live/review_queue_live.ex` (fix `handle_event/3` `else`) | controller (LiveView callback) | event-driven | same file, existing `handle_event` clauses | exact (self) |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` (fix `mount/2`) | controller (LiveView callback) | request-response | same file, existing `mount/2` | exact (self) |
| `lib/scoria_web/ui.ex` (D-18 aria-label at ~1320) | component (shared HEEx function component) | request-response | same file, existing `table/1` markup | exact (self) |
| `test/scoria_web/live/review_queue_live_test.exs` (CR-01 regression test) | test (LiveViewTest) | event-driven | same file (existing tests) | exact (self, extend) |
| `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` (WR-04 regression test) | test (direct-callback) | request-response | `test/scoria_web/live/review_queue_live_test.exs` (Router/Endpoint boilerplate shape) | role-match |
| `test/scoria_web/a11y_structural_guard_test.exs` (D-18 guard tightening) | test (source-scan guard) | transform | same file, existing tabindex test (`:116-129`) | exact (self, extend) |
| `test/scoria_web/single_header_guard_test.exs` or sibling (D-06 rendered-DOM Floki assertion) | test (integration, LiveViewTest+Floki) | transform | same file's source-scan tests (pattern to extend) + `review_queue_live_test.exs` (Router/Endpoint+Floki render boilerplate) | role-match |
| `docs/design_system.md` | doc (markdown) | — | `docs/docker_dev_dx.md` / `docs/uat_automation.md` | exact (sibling idiom) |
| `docs/MAINTAINERS.md` (one cross-link line) | doc (markdown) | — | same file, existing cross-link at `:3` + catalog `:255-336` | exact (self, extend) |
| `test/scoria_web/design_system_doc_contract_test.exs` | test (doc-contract, `File.read!`) | transform | `test/scoria/docker_dx_doc_contract_test.exs` | exact |
| `test/scoria/ci_policy_contract_test.exs` (add `@design_system_doc_contract` + assertion) | test (CI policy contract) | transform | same file, existing `@docker_dx_doc_contract` pattern (`:19-21`, `:654-663`) | exact (self, extend) |
| `.github/workflows/ci-verify.yml` (add test path to policy lane-contract step) | config (CI workflow) | batch | same file, `:56` existing `mix test --no-start ...` line | exact (self, extend) |
| `priv/dev/shots.mjs` (SCREENS += `/_lab/overlays`, toast-timing fix) | utility (Node/Playwright capture script) | file-I/O | same file, existing `prompt_release` special-case navigation branch | exact (self, extend) |
| `priv/dev/contact_sheet.mjs` (mirror SCREENS entry) | utility (Node manifest renderer) | file-I/O | same file's duplicate `SCREENS` array | exact (self, extend) |

## Pattern Assignments

### `lib/scoria_web/live/review_queue_live.ex` (controller, event-driven) — CR-01(39-review) fix

**Analog:** itself (`:53-64`), fix already fully specified in RESEARCH.md Code Examples.

**Current (buggy) — no `else`:**
```elixir
def handle_event("dismiss_candidate", _params, socket) do
  with %{} = candidate <- socket.assigns.selected_candidate,
       {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
    {:noreply,
     socket
     |> assign(:notice, "Candidate dismissed")
     |> assign(:selected_candidate, updated)
     |> assign(:selected_candidate_id, nil)
     |> refresh_queue()}
  end
end
```

**Fix — add `else` returning a valid `{:noreply, socket}`:**
```elixir
  else
    _ ->
      {:noreply,
       assign(socket, :notice, "Could not dismiss this candidate. Refresh and try again.")}
  end
```
Copy verbatim (already matches `39-REVIEW.md`'s own suggested fix per RESEARCH.md).

---

### `lib/scoria_web/live/prompt_live/release_workbench_live.ex` (controller, request-response) — WR-04 fix

**Analog:** itself, `mount/2` lines 16-48; `render/1` line 178 reads `@origin_context` unconditionally.

**Fix — one defensive assign in `mount/2`, `handle_params/3` still overrides it later:**
```elixir
def mount(%{"id" => id}, session, socket) do
  # ... existing assigns ...
  socket = assign(socket, :origin_context, nil)
  {:ok, socket}
end
```

---

### `lib/scoria_web/ui.ex` (component) — D-18 aria-label

**Analog:** itself, `:1320` current markup:
```elixir
<div class="scoria-table__viewport" tabindex="0">
```
**Fix:**
```elixir
<div class="scoria-table__viewport" tabindex="0" aria-label="Scrollable table content">
```
(Exact label copy is Claude's discretion per D-11/D-18.)

---

### `test/scoria_web/live/review_queue_live_test.exs` (test) — CR-01 regression test

**Analog:** itself — imports/Router/Endpoint boilerplate already present at top of file (read directly):
```elixir
defmodule ScoriaWeb.ReviewQueueLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end
  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.ReviewQueueLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria
  plug(Plug.Session, store: :cookie, key: "_review_queue_key", signing_salt: "review_queue_salt")
  plug(ScoriaWeb.ReviewQueueLiveTest.Router)
end

defmodule ScoriaWeb.ErrorView do
  def render(_template, assigns), do: inspect(assigns)
end

defmodule ScoriaWeb.ReviewQueueLiveTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Observe.Approval
```

**New test to add (RESEARCH.md Pattern 1, view-form `render_click/3` bypasses the DOM):**
```elixir
test "dismiss_candidate with no selected candidate does not crash the LiveView", %{} do
  {:ok, view, _html} = live(test_conn(), "/scoria/reviews")
  html = render_click(view, "dismiss_candidate", %{})
  assert html =~ "Could not dismiss"
end
```
Use the existing `test_conn/0` helper already defined later in this file (grep it, do not redefine).

---

### `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` (test) — WR-04 regression test

**Analog:** `review_queue_live_test.exs`'s Router/Endpoint boilerplate shape (same convention, every `*_live_test.exs` duplicates its own); this file's own existing `setup` block already provisions `draft`/`active`/`dataset`/`spec` fixtures — reuse them.

**New test (RESEARCH.md Pattern 2 — direct callback, isolates load-order coupling; a full `live/2` nav test would falsely pass both before/after the fix since `handle_params/3` always runs first under the real router):**
```elixir
test "mount/2 assigns a default :origin_context so render/1 never depends on handle_params having run" do
  session = %{"actor_id" => "op-1", "tenant_id" => "default"}
  {:ok, socket} = ScoriaWeb.PromptLive.ReleaseWorkbenchLive.mount(%{"id" => draft.id}, session, %Phoenix.LiveView.Socket{})
  assert %Phoenix.LiveView.Rendered{} =
           ScoriaWeb.PromptLive.ReleaseWorkbenchLive.render(socket.assigns)
end
```
**Caveat (RESEARCH.md A1):** spike the bare `%Phoenix.LiveView.Socket{}` + `Phoenix.Component.assign/3` compatibility against pinned `phoenix_live_view` 1.1.30 first; if brittle, fall back to a source-scan guard (`File.read!` + regex asserting `mount/2` contains `assign(:origin_context, nil)`), mirroring the guard-suite idiom below.

---

### `test/scoria_web/a11y_structural_guard_test.exs` (test, source-scan) — D-18 tightening

**Analog:** itself, existing test `:116-129` ("the table scroll viewport stays keyboard-reachable"):
```elixir
test "the table scroll viewport stays keyboard-reachable (tabindex=\"0\", D-11 calmer-surface contract)" do
  source = File.read!(@ui_file)
  assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*tabindex="0"[^>]*>/s, source) or
           Regex.match?(~r/<div\b[^>]*tabindex="0"[^>]*scoria-table__viewport[^>]*>/s, source), "..."

  # ADD:
  assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*aria-label="[^"]+"[^>]*>/s, source) or
           Regex.match?(~r/<div\b[^>]*aria-label="[^"]+"[^>]*scoria-table__viewport[^>]*>/s, source),
         "A11Y structural guard: expected .scoria-table__viewport to carry an aria-label (D-18)."
end
```
**Byte-offset pitfall:** this file's own `window_after/2` helper already uses `binary_part/3` (not `String.slice/3`) to stay UTF-8-safe — reuse that helper if the new assertion needs any windowing.

---

### `test/scoria_web/single_header_guard_test.exs` or sibling (test, integration) — D-06 GAP-A

**Analog (source-scan half already present, full file read):** the moduledoc at `:1-31` **self-declares** the exact deferral (`:28-30`: "The true rendered-DOM assertion is deferred to Phase-41 PROOF-03"). Existing helper conventions to mirror:
```elixir
@page_glob "lib/scoria_web/live/**/*.ex"
@excluded ~w(lib/scoria_web/ui.ex lib/scoria_web/live/dataset_live/promote_component.ex)
@dialog_scoped_fragments ~w(drawer modal palette notebook)

defp page_files do
  @page_glob |> Path.wildcard() |> Enum.reject(&(&1 in @excluded)) |> Enum.reject(&dialog_scoped?/1)
end
```

**New rendered-DOM half (RESEARCH.md Pattern 3 — own module, `async: false`, needs real render, so put it in its own file or a sibling module in the same file since ExUnit requires one async setting per module and the existing module is `async: true`/no-DB):**
```elixir
defmodule ScoriaWeb.SingleHeaderRenderedGuardTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @routes [
    {"/scoria", "/"},
    {"/scoria/approvals", "/approvals"},
    {"/scoria/reviews", "/reviews"}
    # ... every router-registered live route (12 total; see lib/scoria_web/router.ex)
  ]

  for {path, _route} <- @routes do
    test "#{path}: rendered region titles never restate the rendered page title" do
      {:ok, _view, html} = live(test_conn(), unquote(path))
      doc = Floki.parse_document!(html)
      page_title =
        doc |> Floki.find(".scoria-pagehead__title, .scoria-object-header__title, .scoria-stub-page__title")
            |> Floki.text() |> String.trim()
      region_titles =
        doc |> Floki.find("[class*='__title']:not(.scoria-pagehead__title):not(.scoria-object-header__title)")
            |> Enum.map(&(&1 |> Floki.text() |> String.trim()))
      refute Enum.any?(region_titles, &(String.downcase(&1) == String.downcase(page_title))),
             "rendered region title restates page title #{inspect(page_title)} on #{unquote(path)}"
    end
  end
end
```
**Must verify before landing (A2):** the exact CSS class names against `ui.ex`'s real `page_header/1`/`object_header/1`/`stub_page/1`/`panel/1` `:title` slot markup (`scoria-pagehead__title` confirmed at `ui.ex:260`; others inferred, not individually grepped). Router+Endpoint boilerplate: reuse the shape shown above from `review_queue_live_test.exs`.

---

### `docs/design_system.md` (doc) — new maintainer conventions doc

**Analog:** `docs/docker_dev_dx.md` / `docs/uat_automation.md` — sibling one-topic-per-file idiom, both absent from ExDoc `extras` (`mix.exs:127-139`) and `package.files` (`mix.exs:146-179`). Mirror that same exclusion for `design_system.md`.

**Shape per D-10/D-11 (11 sections, each ~6-12 lines, Rule → SSOT → Guard → Example):**
```
## <Section name, e.g. "Page headers">
Rule: <one sentence>
SSOT: <file[s], file:line where useful — e.g. lib/scoria_web/ui.ex object_header/1>
Guard: <enforcing test> — `mix test test/scoria_web/single_header_guard_test.exs`
Example: <one real snippet/class name, never invented>
```
11 sections required: BEM/selectors, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, screenshot-proof + drift-guard roster.

---

### `docs/MAINTAINERS.md` (doc, one cross-link line)

**Analog:** itself — existing cross-link precedent at `:3` (the docker-DX cross-link) and the catalog section at `:255-336`. Add one line in the catalog section pointing to `docs/design_system.md`, mirroring the `:3` cross-link's exact phrasing/format.

---

### `test/scoria_web/design_system_doc_contract_test.exs` (test, doc-contract)

**Analog:** `test/scoria/docker_dx_doc_contract_test.exs` (full file read above) — modeled 1:1. Key shape to copy:
```elixir
defmodule ScoriaWeb.DesignSystemDocContractTest do
  use ExUnit.Case, async: true

  @doc_path "docs/design_system.md"

  test "pins the N required section headings" do
    docs = File.read!(@doc_path)
    for heading <- ["## BEM", "## Tokens", "## Page headers", ...] do
      assert String.contains?(docs, heading), "design_system.md lost section #{inspect(heading)}"
    end
  end

  test "every guard path the doc names actually exists" do
    docs = File.read!(@doc_path)
    guard_paths = Regex.scan(~r/`(test\/[^`]+_test\.exs)`/, docs) |> Enum.map(&List.last/1)
    for path <- guard_paths do
      assert File.exists?(path), "design_system.md names guard #{path} that no longer exists"
    end
  end

  test "a sample of cited token names still appear in 02-tokens.css" do
    tokens_css = File.read!("assets/css/02-tokens.css")
    for token <- ["--scoria-text-subtle", ...] do
      assert String.contains?(tokens_css, token)
    end
  end
end
```
Three checks only (D-12): guard-path existence, token-name sample, section-heading pin. No heavier (no token-by-token/DOM diff).

---

### `test/scoria/ci_policy_contract_test.exs` (test, CI policy) — wire in the new doc-contract test

**Analog:** itself, confirmed exact lines `:19-21` and `:654-663`:
```elixir
@ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
@docker_dx_doc_contract "test/scoria/docker_dx_doc_contract_test.exs"
@lane_contract "test/scoria/verification_lanes_test.exs"
# ADD:
@design_system_doc_contract "test/scoria_web/design_system_doc_contract_test.exs"
```
```elixir
test "policy job runs ci_policy_contract_test and Docker DX doc contract in lane-contract step" do
  ci_verify = File.read!(@ci_verify)
  [policy_section, _test_section] = split_jobs(ci_verify)
  lane_step = lane_contract_step(policy_section)

  assert lane_step =~ @ci_policy_contract
  assert lane_step =~ @docker_dx_doc_contract
  assert lane_step =~ @design_system_doc_contract   # ADD
  assert lane_step =~ @lane_contract
  # ... plus ordering assertions, mirroring the existing index_of/2 pattern
end
```

---

### `.github/workflows/ci-verify.yml` (config) — add test path to lane-contract step

**Analog:** itself, `:56` current line:
```
run: mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/docker_dx_doc_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```
Add `test/scoria_web/design_system_doc_contract_test.exs` to the space-separated list, adjacent to `docker_dx_doc_contract_test.exs`.

---

### `priv/dev/shots.mjs` (utility, file-I/O) — D-14/D-15 SCREENS + toast-timing fix

**Analog:** itself — existing `prompt_release` special-case (re-navigate before each overlay capture, per RESEARCH.md ~lines 247-264) is the precedent for a screen-specific navigation branch.

**New SCREENS entry:**
```javascript
{
  name: 'lab_overlays',
  path: '/_lab/overlays',
  tenantScoped: false,
  overlays: [],
  freshMountPerCapture: true,   // NEW flag
},
```
**Capture-loop branch:**
```javascript
for (const theme of THEMES) {
  for (const vp of VIEWPORTS) {
    if (screen.freshMountPerCapture) {
      await page.goto(url);
      await waitForReady(page);   // resets the toast's phx-mounted timer to "now"
    }
    await setTheme(page, theme);
    await page.setViewportSize({ width: vp.width, height: vp.height });
    const filename = `${presence}_${theme}_${vp.name}`;
    await page.screenshot({ path: join(screenDir, `${filename}.png`), fullPage: false });
  }
}
```
Real static toast fixture confirmed at `dev/lab/sections/overlays.ex:91-94` (`RISK-TOAST-LEGIBILITY`, `<.toast tone={:warn}/>`+`{:fail}`) — **not** `states.ex` (badges only, GA-3's proposed fix was rejected).

---

### `priv/dev/contact_sheet.mjs` (utility) — mirror SCREENS entry

**Analog:** itself, duplicate `SCREENS` array. Add the name-only mirror:
```javascript
{ name: 'lab_overlays', tenantScoped: false },
```

## Shared Patterns

### `with`/`case` exhaustiveness in `handle_event/3`
**Source:** `lib/scoria_web/live/review_queue_live.ex` (the CR-01 fix itself)
**Apply to:** any new/modified LiveView callback in this phase — always end a `with` with an `else` returning `{:noreply, socket}`.

### Per-file Router+Endpoint test boilerplate (no shared ConnCase)
**Source:** `test/scoria_web/live/review_queue_live_test.exs:1-40` (and all 15 `*_live_test.exs` files)
**Apply to:** the WR-04 regression test file and the new D-06 rendered-DOM guard test.
**Explicit anti-pattern (RESEARCH.md):** do NOT introduce a shared `ConnCase`/test helper as a side effect of this phase — that is scope creep beyond "boring, minimal."

### Doc-contract precedent (`File.read!` + `String.contains?`/regex, no DB)
**Source:** `test/scoria/docker_dx_doc_contract_test.exs` (full file)
**Apply to:** `test/scoria_web/design_system_doc_contract_test.exs`.

### Byte-offset-safe source scanning
**Source:** `test/scoria_web/a11y_structural_guard_test.exs`'s `window_after/2` helper (`binary_part/3`, not `String.slice/3`)
**Apply to:** any new/modified guard doing regex-index-based windowing (D-06, D-18).

### Sibling-doc exclusion from ExDoc/package.files
**Source:** `mix.exs:127-139` (extras), `:146-179` (package.files) — `docker_dev_dx.md`/`uat_automation.md` both excluded
**Apply to:** `docs/design_system.md`.

## No Analog Found (planning-markdown artifacts — no code analog, skip pattern mapping)

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/phases/41-.../41-GAP-REGISTER.md` | doc (planning artifact) | — | Pure planning bookkeeping; structural precedent is `.planning/MILESTONES.md`'s "v3.0 Known Gaps" + `v3.0-MILESTONE-AUDIT.md:131-138`, already fully described in CONTEXT.md D-17 — no source-code analog to extract. |
| `.planning/phases/41-.../41-SUMMARY.md` (evidence manifest section) | doc (planning artifact) | — | Same as above; content is a manifest of pointers, not code. |
| `41-VERIFICATION.md` | doc (produced by `/gsd-verify-phase`, not this phase) | — | Downstream artifact, not authored in this phase. |

## Metadata

**Analog search scope:** `lib/scoria_web/live/**`, `lib/scoria_web/ui.ex`, `test/scoria_web/**`, `test/scoria/**`, `docs/**`, `priv/dev/**`, `.github/workflows/**` — all directly read this session (RESEARCH.md's Sources section), no additional Glob/Grep needed beyond confirming exact excerpts.
**Files scanned:** 13 (all read directly; 3 planning-markdown artifacts intentionally skipped per task instructions).
**Pattern extraction date:** 2026-07-04

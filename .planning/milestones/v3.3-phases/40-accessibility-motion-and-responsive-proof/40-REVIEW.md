---
phase: 40-accessibility-motion-and-responsive-proof
reviewed: 2026-07-03T00:00:00Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - assets/css/02-tokens.css
  - assets/css/04-components.css
  - brandbook/tokens.css
  - brandbook/tokens.json
  - lib/mix/tasks/scoria.ui.e2e.ex
  - lib/scoria_web/components/approval_inbox_component.ex
  - lib/scoria_web/components/workflow_detail_panel_component.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - lib/scoria_web/live/connectors_live/index.ex
  - lib/scoria_web/live/prompt_live/release_workbench_live.ex
  - lib/scoria_web/ui.ex
  - priv/dev/e2e/a11y_axe.spec.mjs
  - priv/dev/e2e/drawer_focus.spec.mjs
  - priv/dev/e2e/ia_orientation.spec.mjs
  - priv/dev/e2e/lib/axe.mjs
  - priv/dev/e2e/lib/boxes_intersect.mjs
  - priv/dev/e2e/lib/instant_duration.mjs
  - priv/dev/e2e/modal_focus.spec.mjs
  - priv/dev/e2e/phase16_parity.spec.mjs
  - priv/dev/e2e/reduced_motion.spec.mjs
  - priv/dev/e2e/responsive_scan.spec.mjs
  - priv/dev/e2e/uat.spec.mjs
  - priv/dev/package.json
  - priv/dev/shots.mjs
  - test/scoria_web/a11y_structural_guard_test.exs
  - test/scoria_web/live/approvals_live_integration_test.exs
  - test/scoria_web/live/approvals_live_test.exs
  - test/scoria_web/live/connectors_live_test.exs
  - test/scoria_web/live/workflow_live_test.exs
  - test/scoria_web/motion_drift_guard_test.exs
  - test/scoria_web/token_contrast_guard_test.exs
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 40: Code Review Report

**Reviewed:** 2026-07-03
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Phase 40 delivers focus-trap/restore for the modal/drawer shells, an axe WCAG-2.2 e2e scan, reduced-motion and responsive proofs, and a token-SSOT contrast fix. The token contrast fix is correct and consistent across all three SSOTs (`02-tokens.css`, `brandbook/tokens.css`, `brandbook/tokens.json`) — I hand-verified the dark-theme `--scoria-text-subtle` → `--scoria-muted-warm` (#bdaea3 on #181513 ≈ 8.4:1) and light-theme `--scoria-graphite-700` repoints, and both clear the 4.5:1 floor the new `token_contrast_guard_test.exs` asserts against both surfaces. The `pumice-500` primitive is correctly left untouched for `--scoria-span-redacted`. The e2e/motion/responsive specs and helper libraries are sound.

The focus-trap wiring itself (`focus_wrap` + `phx-mounted={JS.focus_first()}` + `phx-remove={JS.pop_focus()}` paired with `JS.push_focus()` at each opener) is correctly built. However, the phase hardened the *single-overlay* dismiss contract without accounting for the one shipped surface that stacks a **modal on top of a drawer** — the approvals decision flow — where two window-level Escape listeners now coexist. That is the one correctness defect below. The remaining findings are robustness/UX issues around approval decision error-reporting and pagination.

## Critical Issues

### CR-01: Escape in the approvals decision modal also dismisses the drawer beneath it (stacked window-keydown collision)

**File:** `lib/scoria_web/ui.ex:724` (modal) and `lib/scoria_web/ui.ex:794` (drawer); triggered by `lib/scoria_web/live/approvals_live/index.ex:239,357`

**Issue:** `modal/1` binds `phx-window-keydown={@on_dismiss}` `phx-key="Escape"` on its outer `.scoria-modal` div, and `drawer/1` binds the same on its scrim. Both are **window-scoped** listeners, so every DOM instance carrying one fires on a single Escape keypress. In the approvals flow the drawer (`show={@active_approval != nil}`) stays mounted while the decision modal (`show={@decision_modal != nil && !decided?(...)}`) opens on top of it — the drawer's Deny/Approve buttons open the modal via `JS.push` without clearing `@active_approval`. As a result, pressing Escape to cancel the confirm modal fires **both** `close_decision_modal` *and* `dismiss_approval`: the operator is thrown all the way out of the approval drawer back to the inbox (and `dismiss_approval` push_patches the `?approval=` param away), instead of the expected "cancel the confirm, stay in the drawer." This is exactly the highest-stakes keyboard surface this phase set out to harden, and the new `drawer_focus.spec.mjs`/`modal_focus.spec.mjs` specs only exercise each overlay in isolation, so the stacked case is untested and the regression is invisible to the gate. (The same double-teardown also fires two `phx-remove={JS.pop_focus()}` on the approve-success path, making post-decision focus restoration land on an already-removed element.)

**Fix:** Scope the modal's Escape dismissal so a nested modal consumes the key before the drawer sees it, rather than relying on two competing window listeners. Either move the drawer's `phx-window-keydown` off `window` when a modal is open, or gate the drawer's Escape so it no-ops while `@decision_modal != nil`, e.g.:

```elixir
# approvals_live/index.ex — make the drawer's dismiss a no-op while the modal owns Escape
def handle_event("dismiss_approval", _, socket) do
  if socket.assigns.decision_modal do
    {:noreply, socket}            # modal is on top; let close_decision_modal handle Escape
  else
    {:noreply,
     socket
     |> assign(:decision_modal, nil)
     |> push_patch(to: approvals_path(socket.assigns[:scoria_base] || "", patch_params(socket, %{})))}
  end
end
```

Prefer a general fix in `ui.ex` (e.g. only the topmost overlay carries an active window-keydown) and add a stacked-overlay Escape assertion to `drawer_focus.spec.mjs`.

## Warnings

### WR-01: Resume failure after a recorded approval reports "Could not record ... approval decision" — the decision WAS recorded

**File:** `lib/scoria_web/live/approvals_live/index.ex:643-669` (with `maybe_resume_approval/3` at 673-685, `approval_error_message/2` at 719-721)

**Issue:** `record_approval_decision/2` runs `Workflows.approve/3` then `maybe_resume_approval/3` inside one `with`. If `approve/3` succeeds (the decision + audit event are persisted, and for an approve the tool side-effect is authorized) but `Resume.resume_run/1` returns `{:error, reason}`, control falls to the `else` clause which surfaces `approval_error_message(status, reason)` → "Could not record #{status} approval decision: #{inspect(reason)}". That message is false: the decision was recorded — only the run resume failed. On a safety-relevant approval surface this misleads the operator into thinking nothing happened (they may retry and hit `:not_pending`, or believe an approved action did not proceed). It also leaks internal `inspect(reason)` detail into the UI.

**Fix:** Distinguish "decision failed to record" from "decision recorded, resume failed." Only route pre-decision failures through `approval_error_message/2`; for a post-approval resume failure, keep/confirm the recorded decision and show a distinct message (e.g. "Approval recorded, but the run could not be resumed automatically — retry resume from the run page"). Do not surface raw `inspect(reason)` to operators.

### WR-02: "Load more" appears when the decided page is exactly full even if no more rows exist

**File:** `lib/scoria_web/live/approvals_live/index.ex:235`

**Issue:** `has_more={@scope == "decided" and length(@approval_inbox) >= @decided_limit}`. `list_decided_approvals/1` is called with `limit: @decided_limit`, so it returns at most `decided_limit` rows. When the total happens to equal a multiple of the page size, `length == decided_limit` is true and the "Load more" button renders even though the next page is empty. Clicking it re-queries, gets the same rows, bumps `decided_limit`, and the button silently disappears — a dead click that suggests missing data exists when it does not.

**Fix:** Fetch `limit + 1`, render only `limit`, and set `has_more` from whether the extra row came back:

```elixir
filters = %{tenant_id: ..., limit: socket.assigns.decided_limit + 1}
rows = Workflows.list_decided_approvals(filters)
{visible, has_more} = Enum.split(rows, socket.assigns.decided_limit) |> then(fn {v, extra} -> {v, extra != []} end)
```

### WR-03: Connectors drawers do not clear each other; two window-Escape drawers can coexist

**File:** `lib/scoria_web/live/connectors_live/index.ex:44-59, 191-201`

**Issue:** `open_runtime_drawer` assigns `:runtime_drawer` and `open_connector_drawer` assigns `:connector_drawer` without clearing the other. Both drawers render under `:if={@runtime_drawer}` / `:if={@connector_drawer}`, each with its own window-level Escape (via `drawer/1`). If both assigns are ever set simultaneously (e.g. a broadcast-driven re-render, or future code opening one without closing the other), a single Escape fires both `close_*` events — the same class of collision as CR-01. Today the scrim usually blocks reaching the second opener, so this is latent rather than always-reproducible, but it is a fragile invariant.

**Fix:** Make opening one drawer clear the other (`assign(socket, runtime_drawer: runtime, connector_drawer: nil)` and vice versa), so at most one overlay is mounted at a time.

### WR-04: `handle_params/3` and `render/1` depend on `@origin_context` that `mount/2` never assigns

**File:** `lib/scoria_web/live/prompt_live/release_workbench_live.ex:33-48 (mount), 51-58 (handle_params), 178 (render)`

**Issue:** `mount/2` builds the socket without `:origin_context`; `render/1` reads `origin={@origin_context}`. This works only because Phoenix invokes `handle_params/3` after `mount/2` for routed LiveViews on initial load, assigning `:origin_context` before the first render. That is an implicit ordering dependency — if this view is ever mounted in a context where `handle_params` does not run before render (e.g. embedded/live_component reuse, or a refactor), `render/1` raises `KeyError` on `@origin_context`. Every other assign the template reads is initialized in `mount/2`.

**Fix:** Initialize `:origin_context` defensively in `mount/2` (`|> assign(:origin_context, nil)`), then let `handle_params/3` override it. This removes the load-order coupling at no cost.

## Info

### IN-01: Redundant per-clause `alias Scoria.Workflows.PromptRelease` shadows the module-level alias

**File:** `lib/scoria_web/live/prompt_live/release_workbench_live.ex:106, 120, 145` (module-level alias already at line 11)

**Issue:** `PromptRelease` is aliased at the module top (line 11), then re-aliased inside `request_release/`, `approve_release/`, and `reject_release/` handlers. The inner aliases are dead — they resolve to the same module — and invite the reader to think the local scope differs. (`fetch_pending_approval/1` similarly aliases `Scoria.Observe.Approval` inline, which is at least the only reference.)

**Fix:** Delete the three redundant inline `alias Scoria.Workflows.PromptRelease` lines; keep only the module-level alias.

### IN-02: `.scoria-kbd` min-height is 22px — below the 24px note the button fix cites

**File:** `assets/css/04-components.css:434`

**Issue:** The D-16(6) fix correctly floors `.scoria-button--sm` at 24px (`--scoria-space-5`, line 695), but `.scoria-kbd` still sets `min-height: 22px`. This is not a WCAG 2.5.8 violation (`<kbd>` is a non-interactive display element and is not matched by `responsive_scan.spec.mjs`'s `TARGET_SELECTOR`), so it is intentionally out of scope — but the 22px magic number sitting next to a 24px-floor fix is easy to misread as an oversight.

**Fix:** Optional — if kbd chips are meant to visually align with the 24px control floor, use `min-height: var(--scoria-space-5)` and a short comment noting it is cosmetic, not a target-size requirement. Otherwise leave as-is.

### IN-03: `undersizedTargets` filters `< 23` for a "24px floor" — relies on rounding, not the stated 1px tolerance

**File:** `priv/dev/e2e/responsive_scan.spec.mjs:128`

**Issue:** The comment declares "minimum target size: 24x24 CSS px" with "1px tolerance," but the predicate is `Math.min(r.w, r.h) < 23` applied to `Math.round(r.height)`. A control rendered at 23.4px rounds to 23 and passes; the effective floor is ~22.5px, not 24px−1px. The intent (24 − 1 = 23) is met only because of the rounding, which is coincidental rather than explicit.

**Fix:** Compute against the unrounded rect with an explicit tolerance, e.g. `.filter((r) => Math.min(r.w, r.h) < 24 - 1)` on raw `getBoundingClientRect()` values, matching the `boxesIntersect` tolerance idiom the file references.

## Narrative Findings (AI reviewer)

All findings above are from direct adversarial code review. No `<structural_findings>` substrate was provided for this phase. Positive verification notes retained for the record:

- **Token contrast fix is correct and SSOT-consistent.** Dark `--scoria-text-subtle` (#bdaea3 on panel #181513 ≈ 8.4:1) and light (#3a332f on white ≈ 11.4:1) both clear 4.5:1; hex values match across `02-tokens.css`, `brandbook/tokens.css`, and `brandbook/tokens.json`; the `pumice-500` primitive is preserved for `--scoria-span-redacted`. The guard test correctly checks both backgrounds the token renders against.
- **Focus-trap primitives are wired correctly for the single-overlay case** — `focus_wrap` nested inside `role="dialog"` at a distinct `#{id}-focus` id, `phx-mounted={JS.focus_first()}`, `phx-remove={JS.pop_focus()}`, and `JS.push_focus()` at every opener (`approvals`, `connectors`, `release_workbench`, `workflow_detail_panel`). CR-01 is a stacked-overlay interaction, not a defect in the primitives themselves.
- **e2e injection surface is safe** — `scoria.ui.e2e.ex` passes discrete arg lists to `System.cmd` and forwards the operator base URL via env var, never shell-interpolated.
- **No XSS / secret-leak** — raw payloads render through HEEx auto-escaping in `<pre>`, and the integration tests assert `super-secret-key` is redacted upstream.

---

_Reviewed: 2026-07-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

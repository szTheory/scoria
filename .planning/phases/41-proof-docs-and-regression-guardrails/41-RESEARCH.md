# Phase 41: Proof, Docs, And Regression Guardrails - Research

**Researched:** 2026-07-04
**Domain:** ExUnit/Phoenix.LiveViewTest regression testing, Playwright/axe-core browser proof, doc-contract drift guards, gap-register bookkeeping — for an Elixir/Phoenix LiveView admin dashboard
**Confidence:** HIGH

## Summary

Phase 41 is a **thin lock-and-document phase**, not a build phase — CONTEXT.md already resolved every gray area via research + red-team, and the owner resolved D-16b (option a: bounded 2-crash fix lane). This research does not re-litigate those decisions; it verifies the **implementation mechanics** the planner needs: the exact defect and minimal fix for the two crash-class bugs, the exact test-authoring pattern for each new test (mirroring live conventions already in the repo), the exact toast-timing race in the screenshot harness, and the exact wiring points for the two new guards/docs.

**Both crash fixes were read directly from current source and confirmed:**
- **CR-01(39-review)** (`lib/scoria_web/live/review_queue_live.ex:54-64`): `handle_event("dismiss_candidate", ...)` uses a `with` with no `else`. If `socket.assigns.selected_candidate` is `nil` (fails `%{} = candidate <-`) or `Eval.dismiss_review_candidate/1` returns `{:error, changeset}` (fails `{:ok, updated} <-`), the `with` expression returns that non-matching value directly from `handle_event/3` — not a valid `{:noreply, socket}` — and the LiveView process crashes. **Confirmed reachable**: the "no candidate selected" case is directly testable via `Phoenix.LiveViewTest.render_click(view, "dismiss_candidate", %{})` (pushed straight to the view, bypassing the DOM — the dismiss button isn't even rendered without a selection).
- **WR-04** (`lib/scoria_web/live/prompt_live/release_workbench_live.ex:16-58,178`): `mount/2` never assigns `:origin_context`; only `handle_params/3` does. `render/1` reads `@origin_context` unconditionally at line 178. Under the real router (`live("/prompts/:id/release", ...)`), Phoenix always calls `handle_params/3` after `mount/2` and before the first render, so this **does not crash today under normal navigation** (confirmed: existing `release_workbench_live_test.exs` passes). The defect is a **load-order coupling**, not a currently-reachable crash via `live/2` — Phase-40's own code review (`40-REVIEW.md:117-123`) already named the exact minimal fix: `mount/2` should `|> assign(:origin_context, nil)` defensively, then let `handle_params/3` override it. The regression test must therefore test the **callback contract directly** (see Code Examples), not rely on a reproducible-today browser crash.

**Primary recommendation:** Reuse 100% of the existing harness (Phoenix.LiveViewTest + ExUnit + Floki + Playwright/axe-core, already pinned) for every deliverable. Add exactly: one Floki rendered-DOM assertion (D-06 GAP-A), one doc + one doc-contract test (D-08–D-12), two `shots.mjs`/`contact_sheet.mjs` `SCREENS` entries + a toast-timing-safe capture loop (D-14/D-15), two regression tests for the crash fixes + the D-18 aria-label + guard tightening, and the `41-GAP-REGISTER.md` + evidence manifest. No new dependency, no new test framework, no new CI job.

## User Constraints (from CONTEXT.md)

### Locked Decisions

Requirements **PROOF-01, PROOF-02, PROOF-03** and the five Phase-41 success criteria are the locked spec.

- **D-01 (Proof-Lock Stance):** Phase 41 PROVES and LOCKS; it does not remediate, except the one owner-gated D-16b exception. No new toolchain, no new primitive, no new runtime dep.
- **D-02 (revised):** The "flip pass" is a near no-op — all browserless ExUnit guards already throw (`assert offenders == []`) and run in the CI-gated `verify` lane. Do not invent a flip pass.
- **D-03:** Axe full-lab scan and `target-size` stay report-only forever, by design (specimen gallery legitimately fires `color-contrast`; dense-table intent fights `target-size`). Do not ratchet either.
- **D-04:** `drawer_focus.spec.mjs` D-13 (live-PubSub focus-survival, `:280-329`) is the sole genuine report-only-collector flip candidate — VERIFY-THEN-DEFER. If the executor cannot run `mix scoria.ui.e2e`, default to defer/register, never flip-blind.
- **D-05:** 7 of 8 PROOF-03 regressions already have a live blocking guard (mapped exactly). The 8th (GAP-A) is D-06.
- **D-06 (the one required net-new guard):** Add a rendered-DOM Floki/LiveViewTest assertion proving region titles never restate the page title in the *rendered* output (today `single_header_guard_test.exs:28-30` is source-scan only and self-declares this deferral).
- **D-07:** Focused ExUnit criterion-1 is already satisfied. Do not author broad new suites — only the D-06 GAP-A assertion is net-new.
- **D-08:** Create exactly ONE new `docs/design_system.md`. Do NOT extend `MAINTAINERS.md`, do NOT fan out to multiple files. Keep it OUT of ExDoc `extras` and OUT of `package.files` (mirrors `docker_dev_dx.md`/`uat_automation.md`). Add ONE cross-link line from `MAINTAINERS.md`'s catalog section.
- **D-09:** Adopter-facing API = ExDoc on `ScoriaWeb.UI`. Maintainer-facing how/why = `docs/design_system.md`.
- **D-10:** 11 sections (BEM/selectors, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, screenshot-proof + drift-guard roster), each naming a real enforcing guard. Documents existing convention only — invents no new rule.
- **D-11:** Each section is Rule → SSOT (file:line) → Guard (test + `mix test <path>`) → Example (real snippet), ~6-12 lines.
- **D-12:** Add `test/scoria_web/design_system_doc_contract_test.exs` modeled 1:1 on `test/scoria/docker_dx_doc_contract_test.exs` (async, no DB, `File.read!`). Three checks: guard paths `File.exists?`, a sample of token names appear in `02-tokens.css`, the 11 section headings are pinned present. Wire into `ci-verify.yml`'s policy lane-contract step + `ci_policy_contract_test.exs` alongside `@docker_dx_doc_contract`. Runs for free in default `test` lane too. No heavier (no token-by-token/DOM diff).
- **D-13:** Screenshot proof = dated human-reviewable contact-sheet baseline via existing `mix scoria.ui.shots` + `priv/dev/contact_sheet.mjs`. No pixel diff, no CI screenshot assertion. PNGs/JSON/HTML gitignored; committed proof-of-record = `priv/shots/contact_sheet_index.md`. Zero Hex footprint (both `priv/shots` and `priv/dev` excluded from `package.files`).
- **D-14 (revised, red-team corrected):** Two real matrix gaps: component-lab states + toast legibility. GA-3's original fix (targeting `states.ex`) is REJECTED — `states.ex` renders badges, not a toast. Locked: add `/_lab/overlays` to `shots.mjs`'s `SCREENS` (optionally `/_lab/primitives`; `/_lab/states` may be added for "component lab states" but does not satisfy toasts). Mirror into `contact_sheet.mjs`'s duplicate `SCREENS`.
- **D-15:** `ScoriaWeb.UI.toast/1` auto-hides ~4000ms after mount (`phx-mounted={JS.hide(time: @duration_ms)}`, default 4000). The plan must name and verify this race — capture inside the pre-hide window or before JS settles. Do NOT ship a plan asserting determinism without proving the shot lands before the 4s hide.
- **D-16-shots (optional, deferred-in-place):** A browserless shots-manifest coverage guard is optional/premature until D-14's `SCREENS` is corrected; don't double-count it as the PROOF-03 guard.
- **D-16 / D-16a / D-16b (✅ RESOLVED 2026-07-04, owner picked (a)):** Open a bounded fix lane for exactly the two CRASH-class bugs — CR-01(39-review) + WR-04 — each moves to Gap-Register **Section A (fixed-in-v3.3)**, each **locked by a regression test**. D-18 (table-scroll aria-label) rides this lane. WR-01/WR-02 (UX/cosmetic) + minor IN-* items stay deferred in Section B2 as accepted debt. **Plan this fix lane as its own bounded wave/plan — do not expand beyond these two crashes + D-18.**
- **D-17:** Final gap register at `.planning/phases/41-.../41-GAP-REGISTER.md` (a phase artifact, not the milestone audit). Three sections: A (fixed-in-v3.3, including CR-01(40) stacked-Escape, WR-03, `--scoria-text-subtle` repoint, `.scoria-button--sm` 24px floor, toast legibility [P38], decision-history [P39], swept 37/39/40 fixes, and now the two D-16b crash fixes + D-18); B (explicitly-deferred future work: STORYBOOK-01, UNDO-01, AXE-PIPELINE-01, VISUAL-CI-01, GAP-40-000, SEED-004, D-04's D-13 collector if it defers, e2e-harness flakes); B2 (surfaced-but-unfixed: WR-01/WR-02 + minor IN-* items, with live proof + escalation note).
- **D-18:** `ui.ex:1320` `.scoria-table__viewport tabindex="0"` has no `aria-label`. Rides the D-16b lane: add an internal `aria-label`, tighten `a11y_structural_guard_test.exs`'s existing tabindex test to also assert it.
- **D-19:** Criterion-5 evidence = a verification-evidence manifest (recommend a section in `41-SUMMARY.md`) mapping PROOF-01/02/03 → existing green artifacts. Record/point — do not re-prove 36-40. Phase 41 gets its own `41-VERIFICATION.md` via gsd-verify-phase.
- **D-20:** Phase 41 PRODUCES; `/gsd-audit-milestone` + `/gsd-complete-milestone` CONSUME/ARCHIVE. Must NOT touch `MILESTONES.md`, write the audit doc, or archive `REQUIREMENTS.md`.
- **D-21:** The evidence manifest must cite the 3 confirmed pre-existing red `mix test` failures (unrelated to this milestone) or any "suite green" claim is false. See Common Pitfalls for the confirmed identities.

### Claude's Discretion

Exact file/section names; the precise Floki assertion shape for D-06 GAP-A; whether the D-16-shots manifest guard earns its keep after D-14 corrects `SCREENS`; the exact wording of the 11 doc sections (must name a real guard, invent no rule); how to capture the toast before its 4s auto-hide (D-15). Do NOT expand the tone/size/state vocabularies locked in 36-39, add a runtime dep, add a blocking pixel gate, apply D-16/D-18 remediation beyond the owner-opened D-16b lane, or archive the milestone. Prefer boring, minimal additions that reuse the existing harness.

### Deferred Ideas (OUT OF SCOPE)

VISUAL-CI-01 (blocking screenshot-diff pixel gate), STORYBOOK-01 (PhoenixStorybook), UNDO-01 (approval reversal/undo), AXE-PIPELINE-01 (promote axe to required CI lane) — Future Requirements, later milestones. GAP-40-000 (`prefers-contrast`/`forced-colors`, Windows High Contrast) — explicit non-goal. SEED-004 (test-code determinism, async `IntegrationCase`, `Process.sleep`→`eventually/2`) — carried deferred, Section-B row only. WR-01/WR-02 (false approve-error toast, `has_more` off-by-one) — UX/cosmetic, deferred to Section B2. The optional shots-manifest coverage guard (D-16-shots) — premature. Milestone archival (`MILESTONES.md`, `v3.3-MILESTONE-AUDIT.md`, tagging) — belongs to `/gsd-audit-milestone` + `/gsd-complete-milestone`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| PROOF-01 | Maintainer can run focused tests and browser proofs covering component lab states, theme switching, overlays, mobile shell, copy affordances, toast legibility, and core operator flows. | D-06 GAP-A Floki test (Code Examples); D-14/D-15 shots.mjs `/_lab/overlays` addition + toast-timing-safe capture loop (Code Examples); D-07 confirms existing operator-flow ExUnit suites already satisfy the focused-test half. |
| PROOF-02 | Maintainer docs define conventions for BEM, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, and screenshot proof. | `docs/design_system.md` 11-section shape (D-10/D-11) + `design_system_doc_contract_test.exs` modeled on the verified `docker_dx_doc_contract_test.exs` precedent (Code Examples); MAINTAINERS.md cross-link precedent confirmed at file top + catalog section. |
| PROOF-03 | Drift guards prevent regressions to duplicate density controls, inconsistent stats, redundant single-region headers, raw palette leakage, inaccessible icon buttons, unreadable toasts, oversized copy buttons, and untested component states. | D-05 confirms 7/8 already blocking (exact test:line mapped in CONTEXT); D-06 GAP-A closes the 8th; D-18 aria-label + `a11y_structural_guard_test.exs` tightening rides the D-16b lane. |

The two crash fixes (CR-01(39-review), WR-04) and D-18 do not map to a REQUIREMENTS.md ID directly — they are the owner-approved D-16b bounded fix lane, justified by PROOF-01's "core operator flows" clause (a proof milestone should not ship known crashes on the flows it proves).
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Crash-class LiveView bug fixes (CR-01, WR-04) | Backend/LiveView (Phoenix.LiveView callback layer) | — | Both defects are `handle_event/3`/`mount+render` callback-contract violations inside `lib/scoria_web/live/**`; fix stays entirely server-side, no client JS involved. |
| Regression tests for the crash fixes | Backend (ExUnit + Phoenix.LiveViewTest) | — | Phoenix.LiveViewTest drives the LiveView process server-side (Floki over rendered HTML, no browser); this is the correct tier for callback-contract regressions. |
| D-06 rendered-DOM header/region-title assertion | Backend (ExUnit + Phoenix.LiveViewTest + Floki) | — | Requires a real LiveView render (server-rendered HTML) per routed page; no browser/JS needed since HEEx output is fully server-rendered. |
| D-18 table-viewport aria-label | Backend/LiveView (`lib/scoria_web/ui.ex`, a shared function component) | — | Static HEEx markup change; the enforcing guard is also backend (source-scan ExUnit), no CSS/JS involved. |
| `docs/design_system.md` + doc-contract test | Docs / Backend (ExUnit `File.read!`) | — | Pure Markdown + a file-read-only ExUnit contract; no runtime code path. |
| Screenshot proof (`/_lab/overlays` capture, toast-timing fix) | Dev tooling (Node/Playwright, `priv/dev/shots.mjs`) | Browser (renders the real client-side JS `phx-mounted`/`JS.hide` toast auto-hide) | The capture script is Node-side automation, but the *defect being captured* (toast auto-hide timing) is a client-side JS/CSS transition — the fix for D-15 lives entirely in the capture script's navigation/timing strategy, never in `ui.ex`'s toast markup (D-01 forbids remediation of the toast's own auto-hide behavior). |
| Drift guards (existing + D-06/D-18 additions) | Backend (ExUnit, browserless source-scan) | CI (`.github/workflows/ci-verify.yml` `verify` lane) | All guards are Elixir source-scan/render assertions; the CI tier only gates on their pass/fail, no CI topology change needed. |
| Final gap register + evidence manifest | Docs (Markdown planning artifact) | — | `.planning/phases/41-.../41-GAP-REGISTER.md` and the `41-SUMMARY.md` evidence-manifest section are planning-layer documents, not runtime code. |

## Standard Stack

### Core (all already pinned — zero new dependencies this phase)

| Library | Version (verified) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 (mix.lock) | LiveView runtime + `Phoenix.LiveViewTest` (`live/2`, `render_click/3`, `element/2`) | Already the project's LiveView engine; `render_click(view, event, params)` (view-form, not element-form) is the standard technique for pushing an event the DOM doesn't currently render — exactly what the CR-01 regression test needs. [VERIFIED: mix.lock] |
| `floki` | 0.38.1 (mix.lock) | HTML parsing for rendered-DOM assertions | Already used throughout `test/scoria_web/live/**` (`Floki.parse_document!`, `Floki.find`) and is the natural tool for D-06's rendered-DOM title-restatement check. [VERIFIED: mix.lock] |
| `ex_unit` (stdlib) | bundled with Elixir/OTP in use | All new regression tests, guard tests, doc-contract test | No new test framework — `use ExUnit.Case, async: true/false` per existing convention. [VERIFIED: existing test suite] |
| `playwright` (npm, `priv/dev`) | 1.60.0 pinned (`priv/dev/package.json`) | `mix scoria.ui.e2e` + `mix scoria.ui.shots` browser automation | Already the pinned e2e/screenshot engine; `overrides.axe-core` pins the transitive axe version. [VERIFIED: priv/dev/package.json] |
| `@axe-core/playwright` | 4.12.1 pinned | Accessibility scan assertions (report-only + curated assert-zero tiers) | Already wired via `priv/dev/e2e/lib/axe.mjs`; no change needed this phase. [VERIFIED: priv/dev/package.json] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| N/A | — | — | This phase adds no new library dependency of any kind (Hex or npm). Confirmed by D-01's explicit constraint and by every code example below reusing only already-imported modules. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct callback-level test for WR-04 (`mount/2` + `render/1` called in isolation) | A full `live/2` navigation test asserting no crash | Rejected — under the real router, `handle_params/3` always runs before the first render, so a full-navigation test cannot reproduce the load-order defect; it would pass today even without the fix (false confidence). The direct-callback test is the only one that actually distinguishes "mount assigns a safe default" from "mount relies on handle_params." |
| Re-navigating (`page.goto`+`waitForReady`) before each theme/viewport toast capture in `shots.mjs` | Reducing the toast screen's matrix to one representative shot | Both are valid per D-15's discretion; re-navigating is recommended as the default because it stays inside the existing capture-loop shape (small, bounded, no new toolchain) and produces the full theme/viewport matrix deterministically rather than trading off coverage for speed. |
| A shared LiveView test `ConnCase` for the D-06 GAP-A test | Continuing the established per-file inline Router+Endpoint duplication | Every existing `test/scoria_web/live/**/*_test.exs` file (15 files) duplicates its own throwaway `Router`/`Endpoint` module — there is no shared `ConnCase` for these tests in this codebase today. Introducing one for D-06 alone would be an unrequested refactor outside this phase's "boring, minimal" mandate; mirror the existing duplication instead. |

**Installation:** None required — no `npm install` or `mix deps.get` changes for this phase.

**Version verification:** `phoenix_live_view` 1.1.30 and `floki` 0.38.1 confirmed directly from `mix.lock` (project's committed lockfile — authoritative, not a registry lookup). `playwright` 1.60.0 / `@axe-core/playwright` 4.12.1 confirmed from `priv/dev/package.json` (committed, pinned exact versions with an `overrides` entry forcing the transitive `axe-core` version). No version bump needed or recommended this phase.

## Package Legitimacy Audit

**Not applicable — this phase installs zero new packages** (Hex or npm). D-01 explicitly forbids adding a runtime dependency, and every deliverable (regression tests, D-06 guard, docs, doc-contract test, shots.mjs additions, gap register) reuses modules/tools already present in `mix.lock` and `priv/dev/package.json`. No `package-legitimacy check` run was needed or performed.

**Packages removed due to [SLOP] verdict:** none (n/a — no packages evaluated).
**Packages flagged as suspicious [SUS]:** none (n/a — no packages evaluated).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────────┐
                    │  Phase 41 deliverables (5 independent lanes) │
                    └─────────────────────────────────────────────┘

Lane A: Crash-fix lane (D-16b)                    Lane B: D-06 GAP-A rendered-DOM guard
──────────────────────────────                    ─────────────────────────────────────
review_queue_live.ex handle_event                  Router+Endpoint boilerplate (per-file,
  "dismiss_candidate" (with/else fix)                mirrors existing *_live_test.exs)
        │                                                    │
        ▼                                                    ▼
Phoenix.LiveViewTest.render_click(view, ...)       Phoenix.LiveViewTest.live(conn, path)
  reproduces crash → assert graceful notice           for each routed page LiveView
        │                                                    │
release_workbench_live.ex mount/2                            ▼
  (defensive :origin_context assign)                Floki.parse_document! → extract
        │                                              sanctioned-header title text +
        ▼                                              region :title slot text
render/1 called directly on mount-only assigns              │
  → KeyError today → nil-safe after fix                     ▼
        │                                            assert no rendered-DOM restatement
        ▼                                              (closes single_header_guard_test.exs
D-18: ui.ex table viewport aria-label +                self-declared deferral)
  a11y_structural_guard_test.exs tightening

Lane C: Docs + doc-contract                        Lane D: Screenshot proof (D-14/D-15)
────────────────────────────                       ──────────────────────────────────
docs/design_system.md (11 sections,                shots.mjs SCREENS += /_lab/overlays
  Rule→SSOT→Guard→Example)                            (mirrors existing screen-entry shape)
        │                                                    │
        ▼                                                    ▼
design_system_doc_contract_test.exs                 Toast-timing-safe capture: re-navigate
  (File.read!, modeled on                              before each theme×viewport shot so
  docker_dx_doc_contract_test.exs)                     every capture lands within the fresh
        │                                               4000ms phx-mounted window
        ▼                                                    │
ci-verify.yml policy lane-contract step                       ▼
  + ci_policy_contract_test.exs                       contact_sheet.mjs SCREENS mirrored
  (@design_system_doc_contract entry,                  (name-only, reads shots.mjs's output
  alongside @docker_dx_doc_contract)                    dir by matching `name`)

Lane E: Gap register + evidence manifest
─────────────────────────────────────────
41-GAP-REGISTER.md (Section A: fixed-in-v3.3 incl. the 2 crash fixes + D-18;
  Section B: deferred future work; Section B2: surfaced-but-unfixed WR-01/WR-02/IN-*)
        │
        ▼
41-SUMMARY.md verification-evidence manifest
  (pointers to: guard suites, mix scoria.ui.e2e green run, contact_sheet_index.md,
  docs/design_system.md, 41-GAP-REGISTER.md — cites the 3 pre-existing red tests, D-21)
```

### Recommended Project Structure (no new top-level directories)

```
docs/
└── design_system.md                       # NEW (D-08) — 11 sections, out of ExDoc extras + package.files

test/scoria_web/
├── single_header_guard_test.exs            # EXTEND (D-06) — add rendered-DOM Floki assertion (own module in same file, or a sibling file)
├── a11y_structural_guard_test.exs          # EXTEND (D-18) — tighten table-viewport test to assert aria-label
├── design_system_doc_contract_test.exs     # NEW (D-12) — modeled on docker_dx_doc_contract_test.exs
└── live/
    ├── review_queue_live_test.exs          # EXTEND — CR-01 regression test
    └── prompt_live/
        └── release_workbench_live_test.exs # EXTEND — WR-04 regression test

lib/scoria_web/
├── live/review_queue_live.ex               # FIX — add `else` clause to dismiss_candidate/2
├── live/prompt_live/release_workbench_live.ex  # FIX — assign(:origin_context, nil) in mount/2
└── ui.ex                                   # FIX (D-18) — aria-label on .scoria-table__viewport

priv/dev/
├── shots.mjs                               # EXTEND (D-14/D-15) — SCREENS += /_lab/overlays, toast-timing-safe capture
└── contact_sheet.mjs                       # EXTEND (D-14) — mirror SCREENS entry

.github/workflows/ci-verify.yml             # EXTEND (D-12) — add design_system_doc_contract_test.exs to lane-contract step
test/scoria/ci_policy_contract_test.exs     # EXTEND (D-12) — @design_system_doc_contract attr + assertion

.planning/phases/41-.../41-GAP-REGISTER.md  # NEW (D-17)
.planning/phases/41-.../41-SUMMARY.md       # NEW (D-19, produced at execution close)
docs/MAINTAINERS.md                          # EXTEND (D-08) — one cross-link line in the catalog section
```

### Pattern 1: Reproducing an unreachable-via-DOM `handle_event` crash with `render_click/3`'s view-form

**What:** `Phoenix.LiveViewTest.render_click/3` accepts either an `%Element{}` (scoped to a real rendered DOM node, via `element/2`) or a bare `%View{}`. When given the view directly, it pushes the named event straight to the LiveView process's `handle_event/3`, without requiring any matching element to exist in the current render. This is the standard technique for testing "what if the client sends an event the current DOM doesn't expose" (stale DOM, race condition, or — as here — an event whose triggering button is conditionally absent).

**When to use:** Whenever a `handle_event/3` clause's crash condition depends on socket assign state (e.g., `nil` selection) that the UI normally prevents by not rendering the trigger, but a `with`/`case` without an exhaustive branch still leaves the handler reachable in principle (concurrent client, replay, or future markup change).

**Example:**
```elixir
# Source: existing test/scoria_web/live/review_queue_live_test.exs conventions
# (Phoenix.LiveViewTest already `import`ed; test_conn/0 helper already defined)
test "dismiss_candidate with no selected candidate does not crash the LiveView", %{} do
  {:ok, view, _html} = live(test_conn(), "/scoria/reviews")
  # No candidate_fixture/1 created -> @selected_candidate is nil -> the
  # "Dismiss candidate" button is not even in the rendered detail rail.
  html = render_click(view, "dismiss_candidate", %{})
  assert html =~ "Could not dismiss"  # or whatever the else-branch notice says
end
```

### Pattern 2: Testing a `mount/2` defensive-assign contract independent of `handle_params/3` ordering

**What:** Because Phoenix always runs `handle_params/3` after `mount/2` and before the first render for router-mounted LiveViews, a full `live/2` navigation test cannot distinguish "mount/2 assigns a safe default" from "mount/2 relies on handle_params/3 to assign it." Call `mount/2` and `render/1` directly (both are plain, testable functions — `render/1` is not private) to isolate the invariant.

**When to use:** Any time a code-review finding describes an "implicit ordering dependency" between two LiveView callbacks where the currently-wired router happens to mask the defect.

**Example:**
```elixir
# Source: Phoenix.LiveView.Socket is a public struct already a transitive
# dependency (phoenix_live_view 1.1.30) — no new dependency required.
test "mount/2 assigns a default :origin_context so render/1 never depends on handle_params having run" do
  session = %{"actor_id" => "op-1", "tenant_id" => "default"}
  {:ok, socket} = ScoriaWeb.PromptLive.ReleaseWorkbenchLive.mount(%{"id" => draft.id}, session, %Phoenix.LiveView.Socket{})

  # Simulates a render that happens before handle_params/3 runs (a future
  # live_component/embedded reuse, or any refactor that changes callback order).
  assert %Phoenix.LiveView.Rendered{} =
           ScoriaWeb.PromptLive.ReleaseWorkbenchLive.render(socket.assigns)
end
```
Before the fix: `render(socket.assigns)` raises `KeyError, key :origin_context not found`. After `mount/2` adds `|> assign(:origin_context, nil)`: the call succeeds. **Verify against the pinned `phoenix_live_view` 1.1.30`** that a bare `%Phoenix.LiveView.Socket{}` struct has enough default `assigns` shape (`__changed__`, etc.) for `Phoenix.Component.assign/3` to succeed inside `mount/2` — spike this once before committing to the pattern; if the bare struct proves brittle across the pinned version, fall back to a source-scan guard (`File.read!` + regex asserting `mount/2`'s body contains `assign(:origin_context, nil)` or equivalent) mirroring the existing guard-suite idiom, which is weaker but zero-risk.

### Pattern 3: Rendered-DOM title-restatement check (D-06 GAP-A)

**What:** `single_header_guard_test.exs` already does the *source-scan* half (static string literals only, self-declared as a partial proof at `:28-30`). The GAP-A net-new assertion renders each routed page LiveView for real (via `live/2`, mirroring the per-file Router+Endpoint boilerplate already duplicated across `review_queue_live_test.exs`/`release_workbench_live_test.exs`/etc.) and Floki-parses the actual DOM, comparing the sanctioned header's rendered title text against every region `:title` slot's rendered text — catching dynamic/interpolated titles the static-literal scan cannot see (exactly the gap the guard's own moduledoc names).

**When to use:** For the one PROOF-03 item without a live blocking guard.

**Example:**
```elixir
# Source: mirrors the Router/Endpoint boilerplate already duplicated in
# test/scoria_web/live/review_queue_live_test.exs (own module, own file or
# a sibling file — ExUnit requires one async setting per module, and the
# existing single_header_guard_test.exs module is `async: true` with no DB;
# this new assertion needs a real LiveView render, so it belongs in its own
# `async: false` module).
defmodule ScoriaWeb.SingleHeaderRenderedGuardTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @routes [
    {"/scoria", "/"},
    {"/scoria/approvals", "/approvals"},
    {"/scoria/reviews", "/reviews"},
    # ... every router-registered live route (12 total; see lib/scoria_web/router.ex)
  ]

  for {path, _route} <- @routes do
    test "#{path}: rendered region titles never restate the rendered page title" do
      {:ok, _view, html} = live(test_conn(), unquote(path))
      doc = Floki.parse_document!(html)

      page_title =
        doc
        |> Floki.find(".scoria-pagehead__title, .scoria-object-header__title, .scoria-stub-page__title")
        |> Floki.text()
        |> String.trim()

      region_titles =
        doc
        |> Floki.find("[class*='__title']:not(.scoria-pagehead__title):not(.scoria-object-header__title)")
        |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

      refute Enum.any?(region_titles, &(String.downcase(&1) == String.downcase(page_title))),
             "rendered region title restates page title #{inspect(page_title)} on #{unquote(path)}"
    end
  end
end
```
The exact CSS-class selectors above must be verified against `lib/scoria_web/ui.ex`'s actual rendered markup for `page_header/1`/`object_header/1`/`stub_page/1`/`panel/1`'s `:title` slot before landing (Claude's Discretion per D-11) — this sketch demonstrates the *shape* (render real page → Floki-parse → compare rendered text), not the final selector strings.

### Pattern 4: Doc-contract test modeled 1:1 on an existing precedent (D-12)

**What:** `test/scoria/docker_dx_doc_contract_test.exs` (verified, read in full) is `async: true`, does only `File.read!(@doc_path)`, and asserts fragment presence/absence via `String.contains?`/regex — no DB, no compile-path risk.

**Example (confirmed exact wiring points):**
```elixir
# ci_policy_contract_test.exs already has this pattern at lines 19-21:
@ci_policy_contract "test/scoria/ci_policy_contract_test.exs"
@docker_dx_doc_contract "test/scoria/docker_dx_doc_contract_test.exs"
@lane_contract "test/scoria/verification_lanes_test.exs"
# ADD:
@design_system_doc_contract "test/scoria_web/design_system_doc_contract_test.exs"

# and the existing test at :654-663 asserts ordered presence in the lane-contract step:
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
`.github/workflows/ci-verify.yml:56` currently reads:
```
run: mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/docker_dx_doc_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```
Add `test/scoria_web/design_system_doc_contract_test.exs` to that space-separated list (exact position: Claude's Discretion, but keep it adjacent to `docker_dx_doc_contract_test.exs` since both are doc-contract tests).

### Pattern 5: Toast-timing-safe screenshot capture (D-15)

**What:** `shots.mjs`'s `captureScreen/3` navigates ONCE per screen (`page.goto` + `waitForReady`), then loops sequentially through 2 themes × 6 viewports (12 screenshots) on that single page load. `ScoriaWeb.UI.toast/1`'s `phx-mounted={JS.hide(time: @duration_ms)}` (default 4000ms) starts its hide-timer at that single initial mount — so later iterations in the 12-shot loop risk landing after the toast has auto-hidden, silently producing "toast legibility" screenshots with no toast in them (a flake, not a hard failure, since `page.screenshot` never asserts toast presence — the evidence would just be quietly wrong).

**Fix shape (recommended default — re-navigate per capture, for this one screen only):**
```javascript
// Source: mirrors the existing prompt_release special-case already in
// shots.mjs's captureScreen (re-navigate before each overlay, lines ~247-264)
// New SCREENS entry:
{
  name: 'lab_overlays',
  path: '/_lab/overlays',
  tenantScoped: false,
  overlays: [],
  freshMountPerCapture: true,   // NEW flag — re-navigate before every theme/viewport shot
},

// In captureScreen's base-state loop, branch on the new flag:
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
This guarantees every one of the 12 captures happens within ~100-300ms of a fresh `phx-mounted` firing — comfortably inside the 4000ms budget — without asserting exact timing determinism (D-15's explicit ask). Mirror the same `SCREENS` entry (name-only: `{ name: 'lab_overlays', tenantScoped: false }`) into `contact_sheet.mjs`.

### Anti-Patterns to Avoid

- **Asserting exact toast-timing determinism** (e.g., "the shot is always taken at exactly 500ms post-mount"): D-15 explicitly forbids this — Playwright timing across CI runners is not that deterministic. Re-navigating resets the clock rather than racing it.
- **Introducing a shared ConnCase/test helper "while you're in there"**: every existing `*_live_test.exs` duplicates its own Router+Endpoint; do not refactor this as a side effect of D-06 or the crash-fix tests — that is scope creep beyond this lock-and-document phase.
- **Fixing WR-01/WR-02/IN-* inline** because "it's a one-liner too": D-16b is bounded to exactly CR-01(39-review) + WR-04 + D-18. Anything else is a scope violation of the owner's explicit decision.
- **Constructing a raw `%Phoenix.LiveView.Socket{}` without first spiking it against the pinned 1.1.30**: `Phoenix.Component.assign/3`'s internals can be version-sensitive about the socket's `assigns` map shape; verify before committing the pattern to the plan.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Doc-drift enforcement | A new bespoke doc-linting mechanism | `File.read!` + `String.contains?`/regex ExUnit test, 1:1 modeled on `docker_dx_doc_contract_test.exs` | Proven, already CI-wired precedent; zero new tooling. |
| Rendered-DOM assertions | A custom HTML-diffing library | `Floki` (already a dependency) | Already the project's HTML-assertion tool throughout `test/scoria_web/live/**`. |
| Screenshot evidence | A CI screenshot-diff pixel gate | The existing `mix scoria.ui.shots` + `contact_sheet.mjs` human-review manifest | VISUAL-CI-01 is explicitly deferred; D-13 locks screenshots as evidence, never a gate. |
| Toast auto-hide "fix" | Rewriting `toast/1`'s dismiss mechanism | Fix the *capture script's* navigation timing instead | The toast's 4000ms auto-hide is intentional product behavior (already documented in `ui.ex`'s own moduledoc, "Pitfall 3"); D-01 forbids remediating it — only the screenshot harness needs to adapt. |

**Key insight:** Every "problem" this phase touches already has a proven in-repo solution one directory over. The research task was to *find and cite* those solutions precisely (file:line), not invent new ones.

## Common Pitfalls

### Pitfall 1: Assuming WR-04 is reproducible via a normal `live/2` navigation test
**What goes wrong:** A regression test written as `{:ok, view, _html} = live(conn, "/scoria/prompts/#{id}/release")` will pass both before and after the fix, because `handle_params/3` always runs before the first render under the real router — giving false confidence that the fix is "tested" when it isn't exercised at all.
**Why it happens:** The defect is a load-order *coupling*, not a currently-triggered crash; the router's contract happens to mask it today.
**How to avoid:** Test `mount/2` + `render/1` directly (Pattern 2), which isolates the invariant from the router's callback-ordering guarantee.
**Warning signs:** A "regression test" that never fails on the unfixed code is not a regression test.

### Pitfall 2: Regex byte-offsets vs. grapheme offsets when scanning source with UTF-8 content
**What goes wrong:** `String.slice/3` counts graphemes; `Regex.scan(..., return: :index)` returns byte offsets. Mixing them (e.g., in a new D-06 or D-18 guard) silently desyncs on any file containing a multi-byte character (en dash, arrow, curly quote) before the match.
**Why it happens:** Elixir strings are UTF-8 binaries; byte offset != codepoint offset != grapheme offset whenever non-ASCII bytes appear earlier in the file.
**How to avoid:** `a11y_structural_guard_test.exs`'s own `window_after/2` helper already documents and solves this (`binary_part/3`, not `String.slice/3`) — reuse that helper's pattern for any new byte-offset-based guard logic.
**Warning signs:** A guard that works in local testing but produces `nil`/garbage windows once a doc-comment with a "→" or "—" is added upstream in the same file.

### Pitfall 3: Citing "suite green" without naming the 3 confirmed pre-existing failures (D-21)
**What goes wrong:** The evidence manifest asserts `mix test` is fully green, but 3 tests are confirmed pre-existing failures unrelated to this milestone — an unqualified "green" claim is false and would be caught by any independent audit.
**Confirmed identities (verified via `deferred-items.md:79-114`):**
1. `Scoria.CiPolicyContractTest` — `assert roadmap =~ "v2.15"` — stale because ROADMAP is now v3.3; confirmed pre-existing at baseline commit `bc22ffa8` (pre-Phase-40).
2. `Scoria.WarningInventory.CaptureParityTest` — compile-cache/environment-dependent flake, unrelated to any Phase 40/41 file.
3. `Scoria.SupportCopilotGalleryTest` (+ cascaded `SupportCopilotWeb.OrchestratorProducerTest`) — `DBConnection.ConnectionError` sandbox-ownership race in a nested-mix gallery runner.
**How to avoid:** The `41-SUMMARY.md` evidence manifest must explicitly list these 3 by name and cite them as "pre-existing, unrelated to v3.3, not fixed in this phase" — matching the exact language already used in `40-.../deferred-items.md`.

### Pitfall 4: The toast capture loop silently producing "toast" screenshots with no toast
**What goes wrong:** Without Pattern 5's fix, later theme/viewport iterations in the 12-shot loop capture the page *after* the 4000ms auto-hide has already fired — the screenshot succeeds (no exception), so nothing alerts anyone that the "toast legibility" evidence is actually just an empty overlay stage.
**Why it happens:** `page.screenshot()` never asserts DOM content; it captures whatever is currently rendered, hidden toast included.
**How to avoid:** Re-navigate before each capture for this one screen (Pattern 5), or add a lightweight sanity check in the capture script (`await page.locator('.scoria-toast').count()` before screenshotting, logging a warning if zero) — cheap, no new dependency, catches the silent-empty-shot failure mode during authoring.

### Pitfall 5: `with`/`case` in `handle_event/3` without an exhaustive `else`
**What goes wrong:** Exactly CR-01's root cause — a `with` that only handles the success path silently returns a non-callback-shaped value on any failure branch, crashing the LiveView instead of degrading gracefully.
**Why it happens:** Easy to write in the "happy path" mindset; Elixir's compiler does not warn about a non-exhaustive `with` (unlike `case`, which does warn on missing clauses when the compiler can determine exhaustiveness).
**How to avoid:** Any new `handle_event/3` using `with` in this phase's touched files must include an `else` clause that returns `{:noreply, socket}`. This is exactly the pattern `39-REVIEW.md`'s own suggested fix already demonstrates for CR-01 — reuse it verbatim rather than inventing new error-notice copy.
**Warning signs:** A `with` inside any `handle_event/3`/`handle_info/2`/`handle_params/3` with no trailing `else`.

## Code Examples

### CR-01(39-review) fix (verified minimal, matches `39-REVIEW.md`'s own suggested fix)
```elixir
# Source: lib/scoria_web/live/review_queue_live.ex:53-64 (current, buggy)
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

# FIX — add the else clause (does not cross any locked public boundary;
# purely a private handle_event/3 body change):
def handle_event("dismiss_candidate", _params, socket) do
  with %{} = candidate <- socket.assigns.selected_candidate,
       {:ok, updated} <- Eval.dismiss_review_candidate(candidate.id) do
    {:noreply,
     socket
     |> assign(:notice, "Candidate dismissed")
     |> assign(:selected_candidate, updated)
     |> assign(:selected_candidate_id, nil)
     |> refresh_queue()}
  else
    _ ->
      {:noreply,
       assign(socket, :notice, "Could not dismiss this candidate. Refresh and try again.")}
  end
end
```

### WR-04 fix (verified minimal, matches `40-REVIEW.md:123`'s own suggested fix)
```elixir
# Source: lib/scoria_web/live/prompt_live/release_workbench_live.ex:16-48 (current)
def mount(%{"id" => id}, session, socket) do
  # ... existing assigns, no :origin_context ...
  {:ok, socket}
end

# FIX — add one defensive assign; handle_params/3 (unchanged) still overrides it:
def mount(%{"id" => id}, session, socket) do
  # ... existing assigns ...
  socket = assign(socket, :origin_context, nil)
  {:ok, socket}
end
```

### D-18 fix + guard tightening
```elixir
# Source: lib/scoria_web/ui.ex:1320 (current)
<div class="scoria-table__viewport" tabindex="0">

# FIX — add an internal aria-label (exact copy: Claude's discretion, e.g.):
<div class="scoria-table__viewport" tabindex="0" aria-label="Scrollable table content">
```
```elixir
# Source: test/scoria_web/a11y_structural_guard_test.exs:116-129 (current test to tighten)
test "the table scroll viewport stays keyboard-reachable (tabindex=\"0\", D-11 calmer-surface contract)" do
  source = File.read!(@ui_file)

  assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*tabindex="0"[^>]*>/s, source) or
           Regex.match?(~r/<div\b[^>]*tabindex="0"[^>]*scoria-table__viewport[^>]*>/s, source), "..."

  # ADD (D-18 hardening — attribute-order-agnostic, like the existing checks above):
  assert Regex.match?(~r/<div\b[^>]*scoria-table__viewport[^>]*aria-label="[^"]+"[^>]*>/s, source) or
           Regex.match?(~r/<div\b[^>]*aria-label="[^"]+"[^>]*scoria-table__viewport[^>]*>/s, source),
         "A11Y structural guard: expected .scoria-table__viewport to carry an aria-label (D-18)."
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| "Warning-grade" guards described as non-blocking | Warning-grade = detection *style* (source-scan vs. rendered/browser), not non-blocking — all such guards already `assert offenders == []` and gate CI | Phase 40 (confirmed, D-02) | Phase 41 must not "flip" anything that already throws; only D-13's live-PubSub collector remains a genuine report-only case. |
| Screenshot proof imagined as a future CI pixel gate | Screenshots are permanent human-review evidence (committed manifest, gitignored pixels); pixel-diff gating is a separate, deferred future requirement (VISUAL-CI-01) | Phase 40 (D-14 precedent) locked further in Phase 41 (D-13) | Do not plan toward a pixel-diff gate as an implicit "next step" of this phase's screenshot work. |

**Deprecated/outdated:** None specific to this phase's domain — all patterns cited above are the current, live conventions in the codebase (verified by direct file reads, not training-data assumption).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A bare `%Phoenix.LiveView.Socket{}` struct has sufficient default `assigns` shape for `Phoenix.Component.assign/3` (called inside `mount/2`) to succeed without additional setup, on the pinned `phoenix_live_view` 1.1.30. | Pattern 2 (WR-04 regression test) | If wrong, the direct-callback test needs extra socket setup (or a small test-only helper) before it compiles/runs; flagged explicitly in Pattern 2 with a fallback (source-scan guard) already provided. |
| A2 | The exact CSS-class selectors used in the D-06 GAP-A Floki example (`.scoria-pagehead__title`, `.scoria-object-header__title`, `.scoria-stub-page__title`, `[class*='__title']`) match the real rendered markup of `page_header/1`/`object_header/1`/`stub_page/1`/`panel/1`'s `:title` slot in `lib/scoria_web/ui.ex`. | Pattern 3 (D-06 GAP-A test) | Selectors were inferred from the class-naming convention observed elsewhere (`scoria-pagehead__title` confirmed at `ui.ex:260`), not individually grepped for every header variant; the planner/executor must verify the exact class names against `ui.ex` before finalizing the test. |
| A3 | Re-navigating (`page.goto` + `waitForReady`) before each theme/viewport capture is fast enough in practice (well under the 4000ms toast-hide budget) that the toast is reliably visible in every one of the 12 re-navigated captures. | Pattern 5 (D-15 toast-timing fix) | If a given CI runner's page load + `waitForReady` round-trip approaches or exceeds 4s, even the re-navigated captures could occasionally miss the toast — the plan should note this as a possible flake and consider the "reduce matrix to 1-2 representative shots" fallback mentioned in Alternatives Considered if re-navigation proves too slow in practice. |

## Open Questions

1. **Does `mount/2`'s existing session/param handling in `release_workbench_live.ex` (e.g. `PromptRegistry.get_prompt_template!(id)`, which raises `Ecto.NoResultsError` on a bad id) interfere with a bare-socket direct-callback test?**
   - What we know: `mount/2` calls `PromptRegistry.get_prompt_template!(id)` — this needs a real, valid `draft.id` from the test's DB sandbox (already how `release_workbench_live_test.exs`'s existing `setup` block provisions fixtures).
   - What's unclear: Whether any other part of `mount/2` (e.g., `session["actor_id"]`, `Repo.one` calls) needs socket fields beyond what a bare `%Phoenix.LiveView.Socket{}` provides.
   - Recommendation: Reuse the existing `setup` block's `draft`/`active`/`dataset`/`spec` fixtures (already provisioned in `release_workbench_live_test.exs`) when constructing the direct-callback test, so only the socket/session shape is new, not the data fixtures.

2. **Should the D-06 GAP-A test iterate literally all 12 routed pages, or a representative subset?**
   - What we know: `single_header_guard_test.exs`'s existing source-scan test already iterates the full `page_files()` glob (12 files after exclusions).
   - What's unclear: Whether every one of the 12 pages needs real seeded data to render without error (some, like `/reviews` empty-state, may render fine with zero fixtures; others may need at least one record).
   - Recommendation: Start with the full 12-route matrix (mirrors the existing guard's completeness), degrading gracefully to a documented subset only if specific routes prove to need heavy fixture setup disproportionate to the check's value — note any skips explicitly in the test's moduledoc, mirroring `dev_lab_boundary_test.exs`'s "Guard #7 honesty caveat" precedent.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Erlang toolchain + Postgres | All new/extended ExUnit tests (CR-01, WR-04, D-06, D-18) | ✓ (existing project, already running full test suite per STATE.md) | project-pinned | — |
| Node.js ≥ 18 + `priv/dev` npm deps + Playwright/Chromium | `mix scoria.ui.e2e`, `mix scoria.ui.shots` (D-13/D-14/D-15 screenshot work, D-04 e2e verify-then-defer) | Must be verified by the executor at plan-execution time (`npm --prefix priv/dev ci` + `npx --prefix priv/dev playwright install --with-deps chromium`) | playwright 1.60.0 pinned | D-04's own locked fallback: if the executor cannot run `mix scoria.ui.e2e`, D-13's drawer live-patch collector defaults to defer/register rather than flip-blind. The screenshot/e2e proof work itself has no fallback — it is the deliverable — but its *absence* is handled by D-19/D-21's evidence-manifest honesty requirement (record what could/couldn't be run). |

**Missing dependencies with no fallback:** None outright blocking — if Node/Playwright are unavailable in the execution environment, the locked D-04 fallback and D-19's "record, don't re-prove" framing already handle graceful degradation of the browser-proof deliverables specifically.

**Missing dependencies with fallback:** See above row — D-04's defer-not-flip-blind rule is the only environment-conditional fallback this phase defines.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) + Phoenix.LiveViewTest + Floki 0.38.1, for server-side proof; Playwright 1.60.0 + `@axe-core/playwright` 4.12.1, for browser proof |
| Config file | `mix.exs` (ExUnit, no separate config file); `priv/dev/e2e/playwright.config.mjs` (Playwright) |
| Quick run command | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/single_header_guard_test.exs test/scoria_web/design_system_doc_contract_test.exs` |
| Full suite command | `mix test` (ExUnit); `mix scoria.ui.e2e` (Playwright, requires `make dev` running in a second shell) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 (crash-free core operator flows) | `dismiss_candidate` degrades gracefully with no selected candidate | unit (LiveViewTest) | `mix test test/scoria_web/live/review_queue_live_test.exs` | ✅ extend existing |
| PROOF-01 (crash-free core operator flows) | `mount/2` assigns a safe `:origin_context` default | unit (direct callback) | `mix test test/scoria_web/live/prompt_live/release_workbench_live_test.exs` | ✅ extend existing |
| PROOF-01 (toast legibility browser proof) | Toast captured before 4000ms auto-hide across theme×viewport matrix | manual/dev-tool (Playwright screenshot, human-reviewed) | `mix scoria.ui.shots --out-dir priv/shots/<date>` then eyeball `contact_sheet.mjs` output | ✅ extend `shots.mjs`/`contact_sheet.mjs` |
| PROOF-03 (untested-restatement guard) | Rendered region title never restates rendered page title | integration (LiveViewTest + Floki) | `mix test test/scoria_web/single_header_guard_test.exs` (or sibling file) | ❌ Wave 0 — net-new (D-06 GAP-A) |
| PROOF-03 (table-viewport SR label) | `.scoria-table__viewport` carries `aria-label` | unit (source-scan) | `mix test test/scoria_web/a11y_structural_guard_test.exs` | ✅ extend existing |
| PROOF-02 (doc/guard matched pair) | `docs/design_system.md` cites real, existing guards/tokens/sections | unit (`File.read!` contract) | `mix test test/scoria_web/design_system_doc_contract_test.exs` | ❌ Wave 0 — net-new (D-12) |

### Sampling Rate
- **Per task commit:** `mix test <touched test files>` (fast, no DB needed for the doc-contract test; DB needed for the two LiveView regression tests and the D-06 test).
- **Per wave merge:** `mix test` (full ExUnit suite) — note the 3 confirmed pre-existing failures (D-21) will still be red; do not treat them as this phase's regressions.
- **Phase gate:** Full `mix test` green (modulo the 3 cited pre-existing failures) + `mix scoria.ui.e2e` green (or D-04's documented defer fallback) + a fresh `mix scoria.ui.shots` capture with the corrected `SCREENS` before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/scoria_web/single_header_guard_test.exs` (or a new sibling file) — needs the D-06 rendered-DOM assertion module (net-new, no existing coverage for this specific check).
- [ ] `test/scoria_web/design_system_doc_contract_test.exs` — net-new file, framework already present (ExUnit), no install needed.
- [ ] `docs/design_system.md` — the file the doc-contract test reads; must be authored in the same plan/wave as the contract test (the contract will fail on a missing file).

## Security Domain

`security_enforcement` is absent from `.planning/config.json` → treated as enabled per protocol, though this phase's domain is UI proof/docs/regression-guard work, not new security surface.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase touches no auth code path. |
| V3 Session Management | No | Phase touches no session code path. |
| V4 Access Control | No | Both crash fixes are within-tenant UI-flow bugs (no authorization boundary crossed); `review_queue_live.ex`'s existing `validate_facet/3` allow-list pattern (already present, untouched) remains the access-control-adjacent control for filter params. |
| V5 Input Validation | Marginal | The CR-01 fix's `else` branch does not introduce new user input parsing — it only changes what `handle_event/3` returns on an already-existing failure path. No new validation surface. |
| V6 Cryptography | No | Not touched. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unhandled `with`/`case` branch in a LiveView callback crashing the process (availability impact — a malicious or buggy client could reliably kill a shared LiveView session) | Denial of Service | Exhaustive `else`/`case` branches returning a valid `{:noreply, socket}` — exactly the CR-01 fix; this phase's crash-fix lane is itself the mitigation for this pattern, not a new control to add elsewhere. |
| `KeyError` on a missing socket assign, crashing the LiveView on render | Denial of Service | Defensive `assign(socket, :key, default)` in `mount/2` for every assign `render/1` unconditionally reads — the WR-04 fix. No broader sweep of other LiveViews is in scope for this phase (D-01's no-remediation-budget line); if the planner wants to generalize this pattern, that is out-of-scope commentary for the gap register (Section B), not a Phase-41 task. |

## Sources

### Primary (HIGH confidence — read directly from the live repo this session)
- `lib/scoria_web/live/review_queue_live.ex` (full file) — confirmed CR-01(39-review) exact defect at lines 53-64.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` (full file) — confirmed WR-04 exact defect: `mount/2` lines 16-48, `render/1` line 178.
- `test/scoria_web/live/review_queue_live_test.exs`, `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` — confirmed existing Router/Endpoint/Phoenix.LiveViewTest conventions; confirmed no existing test exercises the `dismiss_candidate` no-selection or error-return path.
- `test/scoria_web/single_header_guard_test.exs` (full file) — confirmed exact D-06 self-declared deferral text and existing source-scan assertion shape.
- `test/scoria_web/a11y_structural_guard_test.exs` (full file) — confirmed exact D-18 target test ("table scroll viewport stays keyboard-reachable") and its byte-offset-safety helper pattern.
- `lib/scoria_web/ui.ex:1280-1320,920-957` — confirmed `.scoria-table__viewport tabindex="0"` (no aria-label) and `toast/1`'s exact `phx-mounted={JS.hide(..., time: @duration_ms)}` with `duration_ms` default 4000.
- `dev/lab/sections/overlays.ex:75-96`, `dev/dev_router.ex` (full file) — confirmed the real static toast fixture location (`/scoria/_lab/overlays`, not `states.ex`) and the exact mount path shape for `shots.mjs`'s `SCREENS` addition.
- `priv/dev/shots.mjs` (full file), `priv/dev/contact_sheet.mjs` (SCREENS + header) — confirmed current `SCREENS` matrix (no `_lab` entries), the single-navigation-then-loop capture shape that creates the D-15 toast race, and the existing `prompt_release` special-case precedent for screen-specific navigation branching.
- `test/scoria/docker_dx_doc_contract_test.exs` (full file) — confirmed the exact 1:1 precedent pattern for D-12.
- `test/scoria/ci_policy_contract_test.exs:19-21,654-663` — confirmed exact module-attribute + lane-contract-step wiring pattern.
- `.github/workflows/ci-verify.yml:10-56` — confirmed exact policy-lane-contract `mix test` command line to extend.
- `mix.exs:123-179` — confirmed `docs/design_system.md`'s sibling docs (`docker_dev_dx.md`, `uat_automation.md`) are absent from both `extras` and `package.files`, confirming the D-08 precedent.
- `docs/MAINTAINERS.md:1-3,255-336` — confirmed the cross-link precedent (line 3) and the exact catalog-section location/content for the new cross-link line.
- `.planning/phases/39-.../39-REVIEW.md:63-106` — confirmed CR-01's own suggested fix (reused verbatim in Code Examples) and WR-01/WR-02's exact defect descriptions.
- `.planning/phases/40-.../40-REVIEW.md:117-123` — confirmed WR-04's own suggested fix (reused verbatim) and the exact "load-order dependency, not currently-reachable crash" framing.
- `.planning/phases/40-.../deferred-items.md:79-114` — confirmed the exact identities and root causes of the 3 pre-existing red `mix test` failures (D-21).
- `.planning/MILESTONES.md:57-91`, `.planning/milestones/v3.0-MILESTONE-AUDIT.md:100-138` — confirmed the exact v3.0 "Known Gaps" fixed-vs-partial table structure to mirror for `41-GAP-REGISTER.md`.
- `mix.lock` — confirmed `phoenix_live_view` 1.1.30, `floki` 0.38.1. `priv/dev/package.json` — confirmed `playwright` 1.60.0, `@axe-core/playwright` 4.12.1.
- `test/scoria_web/ui_component_test.exs:357,1273-1300,1610,1632-1665` — spot-confirmed the D-05 guard-mapping claims in CONTEXT.md (stat singularity, density-control absence, oversized-copy assertions) and the `render_component/2` isolated-component-test convention.
- `test/scoria_web/dev_lab_boundary_test.exs` (head + moduledoc) — confirmed the pure-`File.read!`-no-`alias` boundary-guard convention and its "honesty caveat" precedent for documenting coverage-floor limitations.

### Secondary (MEDIUM confidence)
- None — every claim in this document was directly verified against the live repository this session; no WebSearch or external documentation lookup was needed (this is an entirely in-repo implementation-mechanics research task).

### Tertiary (LOW confidence)
- A2 (exact D-06 Floki CSS-class selectors) and A1 (bare-socket `assign/3` compatibility) — flagged explicitly in the Assumptions Log; both are inferred from adjacent evidence, not individually grepped/spiked this session.

## Metadata

**Confidence breakdown:**
- Crash-fix defects and minimal fixes: HIGH — read directly from source, cross-confirmed against `39-REVIEW.md`/`40-REVIEW.md`'s own prior code-review findings (which already proposed the identical fixes).
- Test-authoring patterns: HIGH for Patterns 1, 3, 4, 5 (directly mirror existing, running code in the repo); MEDIUM for Pattern 2 (the bare-socket technique is standard Phoenix/LiveView practice but not previously used in this specific codebase — flagged as A1).
- Screenshot/doc/guard wiring points: HIGH — every file:line citation was read directly this session.

**Research date:** 2026-07-04
**Valid until:** 30 days (stable domain — in-repo mechanics research, not fast-moving external ecosystem; re-verify if `phoenix_live_view`/`floki`/`playwright` are bumped before this phase executes).

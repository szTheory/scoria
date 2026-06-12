# Phase 13: Orientation Spine (IA) - Research

**Researched:** 2026-06-11
**Domain:** Phoenix LiveView embedded dashboard information architecture, token-first UI components, scoped client hooks, LiveViewTest verification
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Status Home (IA-02)**
- **D-01:** `ScoriaWeb.OrchestratorLive` stays mounted at `/`; do not add `/home`, `/live_ops`, or route/base-derivation changes for the home split. Nav relabels Live Ops to Home.
- **D-02:** Home template restructures top-down: identity line, needs-attention strip, then existing live run stream. Cards show only nonzero actionable states; all-clear collapses to one line. No charts or sparklines.
- **D-03:** Day-0 empty state copy is exact: "No traces yet. Run your first chat response or MCP request to see the run tree."
- **D-04:** Counts should load with non-blocking query semantics where they are not already cheap; reuse PubSub where available. Attention strip is an orientation device, not a vanity dashboard.

**Command palette + shortcuts (IA-04)**
- **D-05:** Server renders the full command list into the DOM; one vanilla JS hook in `assets/js/scoria.js` handles open/filter/keyboard navigation. No socket traffic while typing, no npm dependency, no LiveComponent round trips.
- **D-06:** Empty query sections: Recent (max 5 objects), Navigate (all screens from `DashboardNav.groups/0`, stubs included and labeled Soon), Actions (Toggle theme, Keyboard shortcuts, Copy current page URL). Filter is case-insensitive substring over label and aliases.
- **D-07:** Recency storage stays browser-local: `scoria:recents:<mount-base>`, cap 8 stored / 5 shown. No assigns, ETS, or DB table for UI state.
- **D-08:** Global key listeners are dashboard-scoped and cleaned up on hook destroy. Ignore inputs, textareas, contenteditable, and IME composition. Only preventDefault for owned keys.
- **D-09:** v1 chords: `g h`, `g a`, `g r`, `g i`, `g c`, `g q`, `g e`, `g p`; no approve/deny/escalate global keys. Discover via visible `Cmd+K` hint, `?` overlay, and row kbd chips.
- **D-10:** Palette is an accessible dialog with focus trap, `aria-activedescendant`, focus restoration, opacity-only <=200ms motion, reduced-motion support, and an empty state string from CONTEXT.md.

**Nav groups + stubs (IA-01, IA-06)**
- **D-11:** Final groups: Operate = Home, Approvals, Runs, Incidents. Improve = Review Queue, Eval Workbench, Prompt Registry, Replay Playground (Soon), Cost Ledger (Soon), Feedback Inbox (Soon). Configure = Connectors, MCP Gateway (Soon), Tool Registry (Soon).
- **D-12:** A noun appears in exactly one nav group. Other-tempo surfaces become in-page links, not duplicate nav items.
- **D-13:** Stub items are muted, text-badged "Soon", clickable, routed to one shared stub LiveView at `/coming/:screen`, and registered in `DashboardNav.@views` so active state works. `derive_base/2` and `strip_known_prefixes/1` need updates for the stub route.
- **D-14:** Stub page anatomy is fixed: screen name + Soon badge, one evidence-verb sentence, "What works today" with deep links, and GitHub tracking issue link. No mock charts, placeholder rows, or skeleton screens.
- **D-15:** Dataset Builder is not a stub; it belongs to Phase 14.
- **D-16:** Fix active state by adding `ScoriaWeb.WorkflowLive.Index` to `DashboardNav.@views`, then audit the map covers all routed views including the stub.

**Breadcrumbs + quality-loop threading (IA-03, IA-05)**
- **D-17:** Add `ScoriaWeb.UI.object_header/1`. Index screens get no crumb. Object screens get parent crumb, truncated object ID with full `title` + copy, identity row, and optional provenance/origin context.
- **D-18:** No persistent loop rail or stepper.
- **D-19:** Threading is a consistent next-step verbs cluster per object page.
- **D-20:** Standard provenance grammar: `{Verb-ed} from {noun} {id} via {noun} {id} - {date}`. Generalize the replay provenance pattern already in `lib/scoria_web/live/workflow_live/show.ex`.
- **D-21:** Origin context uses allowlisted `?from={noun}:{id}` query params, rendered as a dismissible return chip. Unknown nouns are ignored.

### Scope Fences

- UI/IA only. Do not add net-new runtime/eval/connector capability families.
- Stubs are honest "coming soon" pages with no fabricated data.
- All new UI flows through `lib/scoria_web/ui.ex` and semantic token CSS. Do not grow raw Tailwind palette usage; DS-06 is active.
- No route split for Home; preserve embedded dashboard mount-prefix behavior.
- No new JavaScript package, no new LiveComponent for command filtering, and no backend persistence for recents.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IA-01 | Sidebar grouped into Operate / Improve / Configure and active screen always reflected | `DashboardNav.groups/0` is the SSOT. It currently has Operate/Improve only, keeps Connectors under Operate, labels `/` as Live Ops, and misses `ScoriaWeb.WorkflowLive.Index` in `@views`. |
| IA-02 | Status Home at `/` explains Scoria and surfaces attention states without extra click | `OrchestratorLive` already owns `/`, live traces, PubSub, and summary counts via `OperatorSurface`. The top task cards + ops-summary are the correct insertion point, but need status-first copy and nonzero-only behavior. |
| IA-03 | Object-aware breadcrumbs | App layout currently renders a global topbar breadcrumb `Scoria / {page_title}` for every page. Phase 13 should move object orientation into page-level `object_header/1` so object pages can show parent/object identity without giving index pages fake crumbs. |
| IA-04 | Cmd+K palette and keyboard shortcuts | `assets/js/scoria.js` already has self-contained hooks (`CopyId`, `ThemeToggle`, `Dismissable`) and no bundler. Add a dashboard-scoped hook there and render command data in the app layout from `DashboardNav.groups/0`. |
| IA-05 | Related screens threaded through the quality loop | Existing links already cover some loop edges: review queue -> workflow run, run show -> promote modal/replay evidence, release workbench -> eval evidence. Phase 13 should standardize next-step verb clusters and `?from=` return context. |
| IA-06 | Reserved brand-name capabilities appear as honest stubs | Router macro can add `live("/coming/:screen", ScoriaWeb.ComingSoonLive, :show)`. Stub metadata should live beside nav data so palette, sidebar, and route validation share one source. |

</phase_requirements>

---

## Summary

Phase 13 is primarily an IA integration pass over an existing Phoenix LiveView dashboard, not a backend feature build. The codebase already has the right seams: `DashboardNav.groups/0` for sidebar/palette SSOT, `ScoriaWeb.Layouts.app` for the shell and topbar, `OrchestratorLive` for `/`, `OperatorSurface` for read-only attention counts, `ScoriaWeb.UI` for shared components, and `assets/js/scoria.js` for local hooks.

The main implementation risk is letting this phase become a screen-polish sweep. Several target screens still contain raw Tailwind palette classes, but Phase 13 should only touch them for IA affordances and should not attempt the Phase 14/15/17 migrations. The safest plan shape is five vertical slices: nav/stub SSOT, Status Home, command palette/shortcuts, object header + origin context, and quality-loop threading tests. Each slice should include tests and avoid schema changes.

Primary recommendation: implement from the shell inward. First make `DashboardNav` the complete route/nav/stub command source, add the stub route, and fix active-state coverage. Then update `/` Status Home. Then add the command palette hook and layout rendering, using the same nav data. Finally introduce `object_header/1` and wire it into object pages plus next-step/origin links.

## Standard Stack

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| Phoenix | 1.8.7 | Router + LiveView hosting | Locked in `mix.lock`; no router macro redesign needed. |
| Phoenix LiveView | 1.1.30 | HEEx, function components, hooks, LiveViewTest | Supports the existing component/test style. |
| Phoenix HTML | 4.3.0 | HEEx rendering | Existing dependency. |
| Floki | 0.38.1 | HTML assertions in tests | Available in test dependency graph. |
| Vanilla JS | n/a | Palette/filter/keyboard hook | Existing `assets/js/scoria.js`; no npm install. |
| ExUnit + LiveViewTest | built-in | Verification | Existing web tests mount dashboard under `/scoria`. |

### Package Legitimacy Audit

No new package is needed. A command palette with fewer than 30 items does not justify Fuse.js, cmdk, live_select, or server-side filtering. Keeping the hook in `scoria.js` preserves the no-bundler embedded-library asset model.

## Existing Architecture

### Navigation and Shell

- `lib/scoria_web/dashboard_nav.ex` owns `groups/0`, `active_key/1`, on-mount assigns, and mount-prefix derivation.
- Current gaps:
  - `ScoriaWeb.WorkflowLive.Index` is absent from `@views`, so Runs index does not light the nav.
  - Groups are only Operate/Improve and Connectors sits in Operate.
  - `derive_base/2` has explicit suffixes only for index routes and falls back to `strip_known_prefixes/1` for show routes.
  - `strip_known_prefixes/1` does not know `/coming`.
- `lib/scoria_web/components/layouts/app.html.heex` renders sidebar groups and a global topbar breadcrumb. It is also the right place for visible palette affordances, palette dialog markup, and `?` shortcut help.
- `lib/scoria_web/components/layouts.ex` has icon names limited to `:pulse`, `:tree`, `:flag`, `:grid`, `:doc`, `:inbox`, `:plug`, `:alert`, plus fallback. New nav items can reuse current icons or extend this list.

### Status Home

- `lib/scoria_web/live/orchestrator_live.ex` already mounts at `/` and assigns `:tenant_id`, `:approval_count`, `:fleet_summary`, and `:incidents_summary`.
- `OperatorSurface.pending_approval_count/1`, `fleet_summary/1`, and `incidents_summary/1` are pure read helpers with rescue-to-zero fallbacks.
- Existing `/` render has task cards, `ops-summary`, and live trace stream. This can be refactored in place without breaking PubSub or trace streaming.
- Review queue depth is not currently exposed through `OperatorSurface`; planner can either add a small read helper using existing `Eval` APIs or keep IA-02 to the existing pending approvals/incidents/connectors/failing-gate data if no cheap reviewed-backed count exists. Do not add new persistence.

### Command Palette and Shortcuts

- `assets/js/scoria.js` already uses an IIFE, a `Hooks` object, mounted/destroyed lifecycle callbacks, and localStorage.
- New hook should follow the same style:
  - `Hooks.CommandPalette` mounted on a shell element that contains JSON/DOM command data.
  - Register window keydown handlers in `mounted`, remove them in `destroyed`.
  - Filter against DOM rows or parsed JSON; no LiveView event during typing.
  - Use `window.location.assign()` or link click for navigation so mount-prefix paths work.
- Palette data should be rendered from `DashboardNav.groups/0`, not duplicated in JS. Alias strings can live in nav item metadata.
- Recency can be recorded by a tiny hook on object pages with `data-scoria-recent-id`, `data-scoria-recent-label`, `data-scoria-recent-path`, and mount-base awareness.

### Object Header and Threading

- `ScoriaWeb.UI.id/1` already provides copyable monospace identifiers through `CopyId`.
- `WorkflowLive.Show` currently renders bespoke page header markup and an existing replay provenance strip. It is the first target for `object_header/1`.
- Candidate downstream object pages:
  - `WorkflowLive.Show` for run identity and replay provenance.
  - `PromptLive.ReleaseWorkbenchLive` for prompt release identity.
  - Future object pages can adopt the same component after Phase 13.
- Existing quality-loop links:
  - Review queue links to workflow run and runtime context.
  - Workflow show includes promote/replay behavior and remote evidence.
  - Release workbench compares draft/active eval evidence.
- The plan should make links explicit and consistent, not invent a stepper.

### Stub Screens

- `ScoriaWeb.Router.scoria_dashboard/2` can add a new route inside the existing `live_session`.
- A new `ScoriaWeb.ComingSoonLive` or `ScoriaWeb.Live.ComingSoonLive` should render a single shared stub from allowlisted screen metadata. Avoid dynamic arbitrary labels from params.
- Nav metadata should include `soon?: true`, `aliases`, and an internal stub key so sidebar, palette, and stub lookup stay in sync.
- GitHub tracking issue links can be placeholders only if the existing project has no issue IDs, but the link label should be honest and not fabricate issue numbers.

## File Map

| File | Role in Phase 13 | Notes |
|------|------------------|-------|
| `lib/scoria_web/dashboard_nav.ex` | Central IA source | Add 3 groups, stubs metadata, active map coverage, `/coming` base derivation, command helpers if useful. |
| `lib/scoria_web/router.ex` | Dashboard route table | Add one shared coming-soon route inside existing `live_session`; router tests should assert it mounts. |
| `lib/scoria_web/components/layouts/app.html.heex` | Sidebar/topbar/palette shell | Add Soon badge rendering, visible Cmd+K affordance, palette dialog/help overlay containers. Reconsider global breadcrumb text. |
| `lib/scoria_web/components/layouts.ex` | Shell helpers/icons | Add icons only if current fallback is insufficient; keep icons stroke-based. |
| `lib/scoria_web/ui.ex` | Shared components | Add `object_header/1`; possibly add small `kbd/1`, `attention_card/1`, `command_palette/1`, or `stub_page/1` helpers if the planner chooses componentization. |
| `assets/css/04-components.css` | Semantic component classes | Add command palette, shortcut help, object header, stubs, attention strip classes using semantic tokens only. |
| `assets/css/05-motion.css` | Motion | Add opacity-only <=200ms palette transitions if no existing fade utility fits. Respect reduced motion. |
| `assets/js/scoria.js` | Hooks | Add command palette/filter/chords/recents hooks; keep no-bundler style. |
| `lib/scoria_web/live/orchestrator_live.ex` | Status Home | Preserve `/` mount, existing PubSub and trace stream; update title/copy and attention strip. |
| `lib/scoria_web/operator_surface.ex` | Read-only counts | Add only cheap, read-only helpers if needed for review/failing-eval counts. No new schemas. |
| `lib/scoria_web/live/workflow_live/show.ex` | Object header + quality loop | First `object_header/1` adopter; handle allowlisted `?from=` param if planner scopes it here. |
| `lib/scoria_web/live/review_queue_live.ex` | Loop links | Existing workflow links can gain `?from=review:<id>` and consistent verb copy. |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | Release object surface | Candidate for object header and eval-result links; may be deferred if plan splits the object-header adoption. |
| `test/scoria_web/dashboard_nav_test.exs` | New unit tests | Add focused tests for groups, active keys, route suffix behavior, stubs, and command metadata. |
| `test/scoria_web/live/orchestrator_live_test.exs` | Status Home tests | Assert identity line, nonzero cards, all-clear copy, and no extra route. |
| `test/scoria_web/router_test.exs` | Route tests | Assert `/scoria/coming/:screen` mounts. |
| `test/scoria_web/ui_component_test.exs` | Component tests | Add `object_header/1` and any shell component tests. |
| `test/scoria_web/live/workflow_live_test.exs` | Object header tests | Assert crumb, copyable ID, identity row, provenance/origin handling. |

## Implementation Patterns

### Pattern 1: Nav SSOT Extensions

Add metadata to nav items instead of parallel maps. Example target shape:

```elixir
%{
  key: :replay_playground,
  label: "Replay Playground",
  path: "/coming/replay-playground",
  icon: :tree,
  soon?: true,
  aliases: ["replay", "branch run", "compare evidence"]
}
```

Then build sidebar, palette Navigate rows, and stub allowlist from the same groups.

### Pattern 2: Existing Hook Lifecycle

Follow the current `Dismissable` pattern in `assets/js/scoria.js`: store handlers on `this`, bind on mount, remove on destroy. This is mandatory for host-page safety because the embedded dashboard may be mounted under arbitrary host routes.

### Pattern 3: LiveViewTest Route Harness

Existing tests define small routers that call `scoria_dashboard("/scoria")` and start a local endpoint. Reuse that pattern for active nav, stubs, and palette shell assertions instead of introducing browser-only tests for server-rendered markup.

### Pattern 4: Token-First CSS

Use semantic classes such as `.scoria-command`, `.scoria-object-header`, `.scoria-stub`, and `.scoria-attention`. Avoid `stone-*`, `blue-*`, `emerald-*`, etc. The DS-06 guard will fail if new files or changed counts grow raw palette usage.

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Active-state/base derivation regression under embedded mount prefixes | `scoria_dashboard("/scoria")` must work under host paths; hardcoded `/scoria` links already exist in older screens. | Keep nav paths relative to `@scoria_base`; add tests for `/scoria/workflows`, `/scoria/workflows/:id`, `/scoria/coming/:screen`. |
| Palette hijacks host-app keyboard input | Dashboard is embedded; global listeners must be scoped and cleaned up. | Hook loaded only in dashboard layout; ignore editable targets and IME composition; remove listeners in `destroyed`. |
| Status Home becomes a vanity dashboard | IA-02 rejects charts and metric sprawl. | Cards only for actionable nonzero states; all-clear single line; retain live stream below. |
| Stub screens imply fake capability | Reserved names are brand-significant and not implemented. | One shared allowlisted stub page, Soon text badge, "What works today", no fake rows/charts. |
| Raw Tailwind palette count grows | DS-06 guard is active and phase success depends on token gateway discipline. | New UI through `ui.ex` + semantic CSS. Run `mix test test/scoria_web/ds06_drift_guard_test.exs` after affected slices. |
| Object-header scope balloons across all screens | Phase 14/15 handle broader screen polish. | Wire first to object pages needed for IA-03/IA-05, especially Run show and release workbench; leave index screen migrations out. |
| Query param `from` can render unsafe/untrusted text | Params are user-controlled. | Allowlist nouns, truncate/escape IDs through HEEx, ignore unknown nouns silently. |

## Plan Shape Recommendation

1. **Nav + stub SSOT:** `DashboardNav` groups, Home relabel, Connectors move, stubs metadata, active-state fix, stub route/page, router/nav tests.
2. **Status Home:** refactor `OrchestratorLive` top section into identity + attention strip + existing stream; add all-clear and day-0 copy tests.
3. **Palette + shortcuts:** render command data from nav SSOT in the layout; implement `CommandPalette` and recents/chord hooks in `scoria.js`; add server-rendered markup tests and a small JS unit/smoke test if a project JS test path exists, otherwise verify via LiveView markup + manual browser lane.
4. **Object header + origin context:** add `object_header/1` and first adopters (`WorkflowLive.Show`, possibly release workbench); implement allowlisted `?from=` chip; component and LiveView tests.
5. **Quality-loop threading:** add explicit next-step verb clusters and `?from=` links across review/run/release surfaces without building a stepper.

## Validation Architecture

### Automated Test Targets

| Requirement | Behavior | Test Type | Automated Command |
|-------------|----------|-----------|-------------------|
| IA-01 | Groups are Operate / Improve / Configure; Connectors is Configure; Workflow index active key is `:runs`; stub route maps active key | unit + route | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs` |
| IA-02 | `/scoria` renders Home copy, exact identity line, nonzero attention cards or all-clear, and still streams traces | LiveView | `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs` |
| IA-03 | Object page renders parent crumb, truncated copyable ID, identity row, and optional origin chip | component + LiveView | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/workflow_live_test.exs` |
| IA-04 | Layout renders command palette dialog data from nav SSOT; hook IDs/ARIA are present; shortcut help is discoverable | component/Layout + manual keyboard lane | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/orchestrator_live_test.exs` |
| IA-05 | Review -> run, run -> promote/replay/open prompt, release -> eval/baseline links use consistent verb clusters and preserve `?from=` | LiveView | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live_test.exs` |
| IA-06 | Five reserved capabilities appear in nav/palette as Soon, route to shared stub, and show honest "What works today" copy | unit + route + LiveView | `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/live/coming_soon_live_test.exs` |
| DS-06 guard | Phase 13 adds no raw-palette regressions | unit | `mix test test/scoria_web/ds06_drift_guard_test.exs` |

### Manual / Browser Lane

Some IA-04 behavior is client-side only and not fully observable in LiveViewTest:

- Press `Cmd+K` / `Ctrl+K`, verify dialog opens, focus enters the search field, Escape closes, and focus returns.
- Type aliases like `runs`; verify substring filtering hides empty sections and highlights the correct rows.
- Press `g h`, `g a`, `g r`, `g i`, `g c`, `g q`, `g e`, `g p`; verify navigation and 1.5s timeout.
- Open `?` shortcut overlay and verify it does not open while typing in a form field.
- Verify reduced-motion preference removes nonessential animation.

### Feedback Sampling

- Quick per-slice command: `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- LiveView slice command: `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/review_queue_live_test.exs`
- Full web suite before verification: `mix test test/scoria_web/`
- Full suite before closeout: `mix test`

## Open Questions for Planner

- Whether to implement a small `ComingSoonLive` module under `lib/scoria_web/live/coming_soon_live.ex` or keep it as a component-backed LiveView. A LiveView module is preferred because router macro route_info tests can assert the plug.
- Whether Status Home review queue depth should be a new `OperatorSurface.review_queue_summary/1` helper or deferred to Phase 14 if the existing Eval query shape is not cheap enough.
- Whether `object_header/1` lands only on `WorkflowLive.Show` in this phase or also on `PromptLive.ReleaseWorkbenchLive`. IA-03 says every object screen; there are few object screens, so doing both is feasible.
- Exact GitHub tracking issue URLs for stubs. If no canonical issue IDs exist, use a generic repository issue-search link or omit numeric IDs rather than inventing numbers.

---

*Phase: 13-orientation-spine-ia*
*Research complete: 2026-06-11*

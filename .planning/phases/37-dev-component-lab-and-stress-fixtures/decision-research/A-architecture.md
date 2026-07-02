# Phase 37 Decision Research — A: Lab Architecture & Catalog Shape

**Scope:** D-06 (hybrid inventory-driven catalog) and D-04 (no PhoenixStorybook in Phase 37).
**Status of these decisions:** LOCKED. This document pressure-tests them, extracts ecosystem lessons, and pins down the exact architecture that realizes them — it does not propose overturning either.
**Author's stance up front:** both decisions are correct for Scoria at this stage. The rest of this document is the evidence and the concrete shape, so no further deliberation is needed.

---

## 1. Decision pressure-test

### D-06 — hybrid inventory-driven catalog (component spine + state bands + flow probes)

**The claim being tested:** a three-layer catalog (per-component ownership pages, a reusable state-coverage mechanism, a small curated set of cross-component flow probes) beats the two obvious alternatives: (a) a pure "story per state" flat catalog (Storybook/PhoenixStorybook's native shape), or (b) a pure "rebuild every dashboard page in miniature" clone.

**Why (a) alone is wrong for Scoria:** A pure story-per-state catalog optimizes for *browsing breadth* (every state of every component, independently discoverable) but has no answer for D-10's cross-component risks: toast legibility over a dense approval table, drawer/modal focus stacking, mobile nav collapsing table headers. Storybook's own ecosystem answer to this is "compose stories inside a page-level story" or an interaction/play-function addon — both are real weight (see §2) that D-04 explicitly declines to add. Without *some* curated cross-component layer, RISK-TOAST-LEGIBILITY (36-inventory.json) and RISK-OVERLAY-FOCUS are structurally invisible to the lab, because no single component's isolated state band can reproduce "toast fires while an approval table is at 40 dense rows." D-06's third layer exists specifically to close this gap D-10 already anticipated.

**Why (b) alone is wrong for Scoria:** D-10 explicitly forbids "recreate every dashboard page as a second app," and the research/pattern-map agree this is the single most expensive failure mode available (Pitfall analogues in `37-RESEARCH.md` — Common Pitfalls). A full-page clone catalog inherits every dashboard dependency (Ecto reads, PubSub, session/tenant plumbing) that D-17 explicitly keeps out of the lab, and it produces exactly the "second app" maintenance liability that made teams abandon heavier catalogs in the JS ecosystem (see Fractal/Pattern Lab and Storybook-maintenance evidence in §2 — "library-first mentality... leads to shelfware," and "components diverge from production due to poor governance" — mykolaaleksandrov.dev, 2025). A page clone also **can never be complete**: the day it's built it's already stale relative to the real page, and staleness is worse than absence because a stale specimen misleads a maintainer into shipping a regression believing it's covered.

**Why the hybrid is right, concretely, for this repo:**
- The spine (component-first ownership pages keyed to `PRIM-*`/`GROUP-*` inventory IDs) gives D-23's secondary persona (a future contributor) exactly one place to look — "find the canonical component, copy pattern, state name, and fixture example without reverse-engineering older pages." A flat, unowned story list doesn't give you an owner; a per-component page does, by construction (one page = one `ScoriaWeb.UI` function or one `lib/scoria_web/components/*.ex` module).
- The state bands (D-11's 10-name vocabulary, rendered by one shared function component) give D-22's primary persona (maintainer touching shared UI) the actual payoff: seeing all 10 states of `badge/1` or `table/1` side by side *before* changing the CSS/HEEx that all of them share. This is the direct, load-bearing value D-06 buys — it is the one thing a naive "add fixtures to dev_seed.exs and click around" approach cannot give you, because dev_seed.exs cannot cheaply put one table into 10 simultaneous states.
- The flow probes (D-10's explicit short list: dense approvals+toast, mobile table/list summary, drawer/modal focus, command palette, mobile nav, raw-evidence copy, long evidence) are *curated*, not generated — this is the tell that D-06 is not secretly re-deriving (a) or (b). Curation is a maintainer judgment call about which cross-component interactions are actually risky (per the risk register), not a mechanical sweep.

**Tradeoff accepted, stated honestly:** the hybrid is *three things to maintain* instead of one. A maintainer adding a new primitive must decide "does this also need a flow probe?" — that's a small but real judgment tax D-06 imposes that a flat catalog doesn't. The mitigation is D-10's own text: flow probes are added "only where isolated components are insufficient," i.e., the default answer is no, and the curated list is short (7 items) and enumerated in CONTEXT, not open-ended.

**Verdict:** D-06 is correct. It is not a compromise between two failed extremes; each of its three layers answers a distinct, named requirement (D-23 discoverability, D-22 state-parity inspection, D-10 cross-component risk) that the other two layers structurally cannot answer.

### D-04 — no PhoenixStorybook in Phase 37

**The claim being tested:** proving whether a repo-local lab is sufficient should come *before* adopting a dependency that models stories via its own DSL and file convention.

**Evidence for D-04 being right, not just cautious:**

1. **Scoria is a Hex library, not an app.** PhoenixStorybook mounts as a *second* Phoenix router/endpoint concern with its own `.story.exs` convention, `use PhoenixStorybook.Story, :component` macro, and (per hexdocs, verified above) a `variations/0` DSL with `VariationGroup`, `template/0`, `psb-assign`/`psb-toggle` event wiring for interactive state. Every one of those is new surface Scoria's package boundary would have to model around — and D-02/D-03 already treat "new public macro option" and "new Hex footprint" as first-order footguns. Adding a real dependency (even `only: :dev`) to prove out a *maintainer-only* tool is disproportionate before proving the primitives even need cross-component browsing.
2. **Single-maintainer risk is real and verifiable, not hypothetical.** `phenixdigital/phoenix_storybook`'s own docs state it is maintained by a sole maintainer in their free time (confirmed via hex.pm/hexdocs search in this research pass). For a library whose own CI/release discipline is unusually rigorous (release-please pipeline, required `ci-gate`, warnings-as-errors policy lane — see STATE.md/MAINTAINERS.md), taking on a `:dev`-only dependency with single-maintainer bus-factor is a cost that should be paid only once the repo-local approach has demonstrably failed, not preemptively.
3. **The DSL genuinely buys little for Scoria's actual pain point.** PhoenixStorybook's core value proposition — auto-generated docs from `@moduledoc`, a shared sidebar/browsing chrome, args/controls editing live in the browser — mostly ports value from a *component-library-as-product* posture (many consumers browsing many components they didn't write) which is Surface's/JS-Storybook's original use case. Scoria's lab has exactly one primary persona group (the maintainer who *is* the author of `ScoriaWeb.UI`) and does not need runtime-editable controls; deterministic fixtures already answer "what does this look like with X data" without needing a live args-editing UI. The state-band mechanism this research recommends (function component, `attr`/`slot`, no macro) reproduces PhoenixStorybook's *only* mechanism that Scoria actually needs — grouped variation rendering — natively, in ~40 lines, with zero new dependency surface (Pattern 3, `37-RESEARCH.md`).
4. **D-04 is explicitly reversible and cheap to re-evaluate.** `STORYBOOK-01` stays on the books as a deferred, named evaluation path. Nothing in the repo-local architecture below is a dead end that would need to be thrown away if the team later adopts PhoenixStorybook — the `dev/lab/fixtures.ex` catalog, the D-20 domain-noun scenario names, and the D-11 state vocabulary all port directly into `.story.exs` `variations/0` bodies if that day comes. The repo-local lab is not a rival bet against Storybook; it is the cheapest possible experiment that produces a fully migratable artifact either way.

**Tradeoff accepted, stated honestly:** the repo-local lab does not get PhoenixStorybook's browsing chrome (searchable sidebar, breadcrumb, auto-generated docs table from `@moduledoc`) for free — D-07's IA (`Foundations/Primitives/Groups/States/Viewports/Overlays/Fixtures`) has to be hand-built as nav, and it will be visibly plainer than a mature Storybook instance. That is an acceptable and *correct* trade at this phase: D-25's own visual motif ("field-engineer bench... specimens under stress, not marketing demo cards") explicitly does not want Storybook's polished-gallery aesthetic anyway.

**Verdict:** D-04 is correct, and for a stronger reason than "avoid a new dependency" — the one mechanism PhoenixStorybook would contribute that Scoria's lab actually needs (grouped state variation rendering) is cheap to build natively, while everything else it contributes is either irrelevant to a single-author maintainer tool or actively mismatched to the lab's intended aesthetic.

---

## 2. Ecosystem lessons table

| Tool | What it got right (adopt the *idea*, not the dependency) | Footgun (avoid) | Citation |
|---|---|---|---|
| **Storybook (JS)** | Args/controls model: separate a component's *shape* (fixture data) from its *rendering* — the lab's `DevLab.Fixtures` module plays exactly this role, statically instead of live-editable. Autodocs pulling from existing doc comments (`@moduledoc`) rather than hand-authored docs prevents drift between the doc and the code. | Ecosystem/addon sprawl (200+ addons) becomes the product; teams that adopt for "just component preview" end up maintaining a documentation platform. Storybook 9's own messaging frames the *previous* several majors as needing a "bloat fix" — i.e., the tool's own maintainers acknowledge the weight accreted. Autodocs primary-story duplication (shown "twice — above the controls and in the list below") is a concrete instance of DSL magic producing a surprising, hard-to-diagnose render. | storybook.js.org/docs/writing-docs/autodocs; storybook.js.org/docs/essentials/controls; talent500.com "Storybook 9 Drastically Reduces Bloat" |
| **Phoenix Storybook (Elixir)** | Proves the concept translates to Phoenix/LiveView natively (`.story.exs`, live component variations) — validates that a Phoenix-native catalog is buildable at all, and that "variation" is a good primitive name/mental-model. `VariationGroup` for related-state clustering is the direct ecosystem precedent for this phase's `states_band/1`. | It is a macro/DSL (`use PhoenixStorybook.Story, :component`, `variations/0` callback contract, `template/0`, `psb-assign`/`psb-toggle` custom event wiring for interactive state) — exactly the "clever DSL" CONTEXT.md's Claude's Discretion tells downstream agents to avoid. Sole-maintainer bus factor is a real, stated risk for a dependency this phase declines to add. | phoenix-storybook.hexdocs.pm/components.html; hex.pm/packages/phoenix_storybook (maintainer note) |
| **Surface Catalogue (Elixir, `surface_catalogue`)** | Mounts at `/catalogue` as a sibling route — same "second router scope, not a rewrite of the app" shape this phase's `dev/dev_router.ex` addition already uses. Confirms the "mount as a scope, not a new endpoint" pattern is idiomatic Phoenix, independently converged on by two different Elixir ecosystems. | Tightly coupled to the Surface component model (`Surface.Component`/`~F` sigil), which Scoria does not use (Scoria uses plain `Phoenix.Component`/`~H`). Adopting the *pattern* (sibling scope) is free; adopting the *library* would require adopting Surface itself first — a non-starter. Also a smaller, less active ecosystem than Storybook/PhoenixStorybook, compounding the bus-factor concern from the row above. | surface-ui.org/getting_started; github.com/surface-ui/surface_catalogue |
| **ViewComponent + Lookbook (Rails)** | The strongest transferable lesson in this table: **preview classes stay in the same conceptual home as their component** (`button_component_preview.rb` next to `button_component.rb`, mirrored directory structure) rather than a centralized, disconnected stories folder. This is exactly D-06's "component-first ownership as the spine" — Lookbook independently arrived at the same answer for a completely different framework. Public-method-per-scenario ("each public method... represents a unique scenario") is a clean, boring, DSL-free way to enumerate states — closely analogous to this phase's plan to key `DevLab.Fixtures.scenario/1` clauses by D-20 domain-noun atoms. | Namespace/subdirectory drift: "the class namespace must reflect the relative path... just like classes in the main Rails app directory" — an easy-to-violate convention with a confusing failure mode (silently orphaned/unreachable preview) if not enforced. Scoria's equivalent risk is a `dev/lab/sections/*.ex` file whose module name and route/nav wiring silently diverge — worth a guard test, not just a convention. | lookbook.build/guide/previews; lookbook.build/guide/components/view_component; viewcomponent.org/guide/previews.html |
| **Histoire / Ladle (Vue/React lightweight labs)** | Directly validates D-04's core bet: a deliberately smaller, faster, less-featured alternative to Storybook is a legitimate, mainstream engineering choice, not a corner-cutting one — Ladle explicitly markets "control versus simplicity... keeps the workshop minimal and gets out of the way," and ships without Storybook's addon ecosystem by design, not by omission. Cold-start/iteration-speed gap (Storybook 8s vs. Ladle 1.2s in independent 2026 benchmarking) is the same "heavy tool slows the exact iteration loop it exists to support" risk this phase's repo-local, zero-new-dependency lab avoids entirely (the lab boots as part of the existing `mix phx.server`, no separate process/build step). | Both are still framework-specific single-purpose tools with their own config file and CLI — even the "lightweight" alternatives are still *tools*, i.e., new things to learn and keep working. Directly supports D-04: the true zero-cost option is a plain LiveView route inside the app that already runs, not even the lightest external tool. | pkgpulse.com "Storybook 8 vs Ladle vs Histoire 2026"; ladle.dev/blog/introducing-ladle |
| **Pattern Lab / Fractal (atomic-design catalogs)** | "Patterns operate like Russian nesting dolls" (atoms→molecules→organisms) is a genuinely useful vocabulary for *talking about* composition — Scoria's own D-07 IA (`Foundations → Primitives → Groups`) is a flattened, three-tier version of the same idea, deliberately simplified. | The most directly transferable failure mode in this entire table: **categorization overhead** — "teams get stuck debating taxonomy... and lose momentum on actual shipping," **library-first shelfware** — "building a component catalog without real product use cases leads to components nobody actually adopts," and **governance drift** — "components diverge from production due to poor governance" without a single source of truth. All three map directly onto why D-08 anchors every lab entry to a *real, already-shipped* `36-inventory.json` row (never a speculative future component) and why D-17 forbids the lab fixture catalog from becoming its own parallel "product." | mykolaaleksandrov.dev/posts/2025/11/atomic-design-in-practice; patternlab.io; creativebloq.com "Document your design systems with Fractal" |
| **"One-file preview route" pattern (general, informal industry practice)** | The pattern this phase already lands on independently: a single authenticated/dev-gated route in the real app that renders real components with fixture props, with no separate build tool, config file, or process. This is the de facto response many teams reach for specifically to dodge Storybook's config/build-tool surface area for internal-only tools — directly evidenced by the existence of Ladle/Histoire as "lighter Storybook," and by Phoenix precedent: `Phoenix.LiveDashboard.Router.live_dashboard/2` and now this phase's own `live_session :scoria_lab` are both exactly this shape (a route mounted as a sibling scope in the app that already runs). | Without *any* shared convention (state vocabulary, fixture-domain naming, nav structure), a one-file route degenerates into an unstructured pile of ad hoc `<div>`s that nobody can navigate — the exact failure D-07 (fixed IA) and D-11 (fixed state vocabulary) exist to prevent. The lesson is: the one-file-route pattern is right, but it still needs the *minimum* structural discipline (D-06/D-07/D-11/D-20), or it degrades into worse-than-nothing (a maze no one trusts). | hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html (structural precedent); synthesis of Ladle/Histoire/Lookbook evidence above |

**Cross-cutting pattern across every "got it right" cell:** every successful lighter-weight tool (Lookbook, Ladle/Histoire, LiveDashboard's mount pattern) converges on the same two moves Scoria's D-06/D-04 already make: (1) co-locate the catalog entry with the thing it catalogs rather than centralizing into a disconnected stories tree, and (2) treat the catalog as a thin rendering layer over data that already has a canonical shape, not a new data-modeling DSL. The one place every *heavier* tool (Storybook, PhoenixStorybook, Pattern Lab/Fractal) fails is exactly where it invents a second vocabulary (a DSL, an atomic-design taxonomy, an addon config) parallel to the app's own component/type vocabulary — this is the generalized form of D-12's specific rule ("never derive tone from a lab state name").

---

## 3. Concrete recommendation: architecture, state-band mechanism, inventory tie-in

This section states the exact shape and the rationale, including what was rejected. It matches (and is grounded in) `37-RESEARCH.md`'s "Recommended Project Structure" and Pattern 1-3, and `37-PATTERNS.md`'s per-file analog mapping — both already verified against the live repo (`dev/dev_router.ex`, `dev/dev_endpoint.ex`, `lib/scoria_web/ui.ex`, `lib/scoria_web/components/layouts/root.html.heex` all read directly in this research pass). Where this document adds value beyond RESEARCH.md is the explicit rejection rationale for the alternatives, which the planner should not have to re-derive.

### 3.1 Route/LiveView topology: **one param-driven `DevLab.LabLive`, not one LiveView per section**

**Recommended:** a single LiveView mounted three ways in `dev/dev_router.ex` (`/`, `/:section`, `/:section/:item`), with `handle_params/3` selecting which section-renderer function component to call. Section bodies (`Foundations`, `Primitives`, `Groups`, `States`, `Viewports`, `Overlays`, `Fixtures`) are plain function components under `dev/lab/sections/*.ex`, not separate LiveViews and not `live_component`s (unless/until a single section's `render/1` exceeds ~300 lines, per RESEARCH.md's Open Question 1 — a size-based escape hatch, not a default).

**Rejected alternative A — one LiveView per top-level section (7 LiveViews):**
- *Argument for:* isolates each section's assigns/lifecycle; a maintainer editing `Overlays` cannot accidentally break `Foundations`.
- *Why rejected:* seven LiveViews means seven `live/3` route declarations, seven mount/handle_params boilerplate blocks, and — critically — seven places where the shared chrome (D-07 nav rail, theme/motion indicator, D-27 primary/secondary commands) would need to be either duplicated or extracted into a shared layout component anyway, which just re-adds the coupling this alternative was trying to avoid, with more files. It also fights D-25/D-27: the lab's chrome (nav rail showing current section, "Run lab proof"/"Open fixture matrix" commands) needs to persist across section navigation without a full page reload flash — trivial with one LiveView + `handle_params`-driven patches (`<.link patch={...}>`), awkward with `live_redirect` between independently-mounted LiveViews (full remount, socket churn, and loss of any transient lab-local UI state like "which viewport width am I previewing"). CONTEXT's Claude's Discretion explicitly prefers "small modules" over more *ceremony* — module count and route-declaration count both go up under this alternative without a matching gain.

**Rejected alternative B — a macro/DSL that auto-registers "specimens" (PhoenixStorybook-style):**
- *Argument for:* less per-primitive boilerplate; a `defspecimen :badge do ... end`-style macro could auto-wire state bands, nav entries, and coverage-check registration in one declaration.
- *Why rejected:* this is precisely what D-04 and Claude's Discretion forbid, for the reasons in §1 — it recreates PhoenixStorybook's DSL cost inside the repo instead of avoiding it, and it makes the coverage-guard tests (§5) harder, not easier, because `test/` cannot execute `dev/`-scoped macros to introspect the registry (the compile-path split — `37-RESEARCH.md` Pitfall 1) forces coverage proof back to source-text scanning regardless of whether a macro exists. A macro would add indirection with no corresponding testability win.

**Verdict:** single `DevLab.LabLive`, `handle_params`-driven, function-component sections. This is not a compromise; it strictly dominates both alternatives on the axes that matter here (route-declaration count, chrome-sharing, and testability under the `test/`-can't-see-`dev/` constraint).

### 3.2 The "reusable state band" mechanism — plain `attr`/`slot` function component, no DSL

**Recommended shape** (verified pattern, `37-RESEARCH.md` Pattern 3 / `37-PATTERNS.md` states.ex section):

```elixir
defmodule DevLab.Sections.States do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1]

  attr :inventory_id, :string, required: true   # D-08 coverage anchor, e.g. "PRIM-BADGE"
  attr :states, :list, required: true            # [{:normal, fixture}, {:empty, fixture}, ...]
  slot :render, required: true do
    attr :fixture, :any
  end

  def states_band(assigns) do
    ~H"""
    <div class="scoria-lab-states" data-inventory-id={@inventory_id}>
      <div :for={{state, fixture} <- @states} class="scoria-lab-state" data-lab-state={state}>
        <.badge tone={state_tone(state)} label={to_string(state)} />
        <div class="scoria-lab-state__specimen">{render_slot(@render, fixture)}</div>
      </div>
    </div>
    """
  end

  # D-12: the ONE explicit lab-state -> visual-tone table. Never call
  # ScoriaWeb.UI.tone/1 on a lab state name — that function maps a different
  # (domain status) vocabulary and would silently produce wrong/unstyled tones.
  defp state_tone(:warning), do: :warn
  defp state_tone(:danger), do: :fail
  defp state_tone(:error), do: :fail
  defp state_tone(:selected), do: :brand
  defp state_tone(_), do: :neutral
end
```

Caller side, one primitive across all 10 states, zero new syntax beyond ordinary HEEx slots:

```heex
<DevLab.Sections.States.states_band inventory_id="PRIM-BADGE" states={DevLab.Fixtures.states_for(:badge)}>
  <:render :let={fixture}><.badge tone={fixture.tone} label={fixture.label} /></:render>
</DevLab.Sections.States.states_band>
```

**Why this is the correct level of abstraction (not less, not more):**
- **Not less** (i.e., not "just inline 10 copies of `<.badge>` per primitive page"): that would violate D-11's own premise — a *canonical* state vocabulary implies one rendering path that enforces it, so a typo'd or skipped state is structurally visible (missing from the loop's data) rather than silently missing from a hand-written list of 10 near-identical blocks. It also means the D-12 state→tone mapping lives in exactly one place instead of being re-decided ad hoc at every call site (this is precisely Pitfall 4 in `37-RESEARCH.md`: `tone={:warning}` typo'd for `tone={:warn}`, silently unstyled).
- **Not more** (i.e., not a macro that also auto-registers nav entries / coverage rows / doc strings): see §3.1's rejected alternative B. The slot+attr shape is the same contract every other primitive in `lib/scoria_web/ui.ex` already uses (`panel/1`'s `slot(:eyebrow)`/`slot(:title)`/`slot(:actions)` is the direct in-repo precedent, confirmed by reading `ui.ex` lines 145-176 in this pass) — so a maintainer who already knows how to read `ui.ex` needs to learn *nothing new* to read or extend `states_band/1`. This is the strongest form of "no clever DSL": it's not just DSL-free, it's using the *exact same* component contract idiom the rest of the codebase already teaches.

**This is the direct, correctly-scaled-down analog of PhoenixStorybook's `VariationGroup`/Lookbook's per-scenario preview method** — same conceptual job (render one component across N named variants, in one place), implemented as ~25 lines of ordinary `Phoenix.Component` code with zero new dependency, zero new file-naming convention, and zero new callback contract to learn.

### 3.3 Fixture catalog and inventory tie-in

**Recommended:** `dev/lab/fixtures.ex` (`DevLab.Fixtures`) is the single fixture-data module, with two responsibilities kept explicitly separate:
- `states_for(component_atom)` → the 10-state band data for state-parity inspection (D-11/D-12).
- `scenario(domain_atom)` → D-20's domain-noun-named realistic (and ugly) payloads (`approval_requested`, `dataset_empty`, etc., D-19's domain coverage).

**Inventory tie-in (D-08):** every section-page and every `states_band` call site carries its `36-inventory.json` ID (`PRIM-TABLE`, `GROUP-APPROVAL-INBOX-COMPONENT`, ...) as a literal string, both as a visible evidence-disclosure chip (`id/1`, per D-29) in the rendered page and as the anchor a text-scan coverage test greps for. This is deliberately *not* a live cross-reference that parses `36-inventory.json` at runtime or compile time — see §5 for why literal-string coverage-by-grep is the correct verification method, not a weaker one, given the `test/`-can't-compile-`dev/` constraint (`37-RESEARCH.md` Pitfall 1).

**Rejected alternative — generate lab entries from `36-inventory.json` at compile/runtime:** D-18 already forbids this explicitly ("Use `36-inventory.json` for coverage alignment, not as a rich domain data generator... inventory IDs can drive navigation and coverage checks; curated fixture examples must provide the actual domain payloads"). The reasoning holds up under this pressure test: the inventory is a *coverage checklist*, not a data source — its rows describe *that* `PRIM-TABLE` exists and what layer it's in, not what a realistic dense-approvals table row looks like. Conflating the two would make the inventory JSON responsible for two jobs with different failure modes (missing a row vs. wrong domain data), and would reintroduce exactly the "second app" data-plumbing risk D-17 keeps out.

---

## 4. DX guarantees: what makes "add one specimen" a 1-file, low-ceremony edit

CONTEXT's stated goal (D-23, "the lab makes the canonical path easier than local invention") is testable against a concrete scenario: *a maintainer adds a new `ScoriaWeb.UI` primitive, say `stat_delta/1`, and wants it lab-covered.*

Under the recommended architecture, the edit sequence is:

1. Add one `states_for(:stat_delta)` clause to `dev/lab/fixtures.ex` (10 map literals, copy-paste-edit from any existing clause — same shape every time, per §3.2).
2. Add one `<DevLab.Sections.States.states_band inventory_id="PRIM-STAT-DELTA" ...>` block to `dev/lab/sections/primitives.ex`, in the existing list of primitive entries.
3. Add the `PRIM-STAT-DELTA` ID string once (it's already in `36-inventory.json` from Phase 36, or the maintainer adds it there as part of introducing the primitive — a separate, pre-existing discipline this phase doesn't invent).

That's it — **two files touched, zero new modules, zero new route declarations, zero new nav wiring** (the section page it's added to already exists; the nav rail already lists `Primitives`). This is the concrete, falsifiable form of "1-file, low-ceremony": the *fixture* is one file (`fixtures.ex`), the *specimen callsite* is one existing file (the relevant `sections/*.ex`), and nothing else in the tree needs to change. Compare this to what PhoenixStorybook would require for the same addition (a new `.story.exs` file, a `variations/0` callback, sidebar auto-discovery to trust) — comparable file count, but with a DSL contract to get right versus HEEx the maintainer already knows.

**What makes the canonical path *actually* easier than local invention (not just theoretically):**
- The state vocabulary is fixed and finite (D-11's 10 names) — a maintainer who wants "does this look right when the data is ugly" has a named slot (`long_text`, `dense`) to drop a fixture into, rather than inventing a one-off `<div style="width: 50ch">` test harness in a scratch LiveView, which is the "local invention" D-23 is explicitly guarding against. The lab isn't just *a* place to check this — for maintainers who've internalized D-11, it is measurably *less typing* than rigging up an ad hoc check.
- Because the shared chrome (nav, theme toggle, viewport labels) and the readiness sentinel are inherited for free from `{ScoriaWeb.Layouts, :root}` (verified: `lib/scoria_web/components/layouts/root.html.heex`, `ScoriaWeb.Assets.css/0`/`.js/0`), a maintainer never has to think about "how do I get dark mode / the CSS bundle / LiveSocket into my scratch page" — the single largest source of local-invention friction (a one-off page that renders unstyled or without hooks) is structurally eliminated.
- The guard test (§5) makes drift *visible*, not just discouraged: a state or domain scenario silently dropped from lab source fails `mix test`, so "the lab still lists this as covered but it's actually stale" cannot happen quietly the way it could in a purely documentation-based catalog (this is the direct fix for the Pattern-Lab/Fractal "governance drift... components diverge from production due to poor governance" failure mode from §2).

---

## 5. Coverage-gate classification

For a GSD plan's `must_haves` block, D-06 and D-04 are structurally different kinds of claims and should be encoded differently:

### D-06 → `must_haves.truths` (positive, observable)

D-06 is a *shape* claim about what got built, and it decomposes into three independently checkable positive facts. Recommend three separate truths (not one compound one — a compound truth that OR's three unrelated checks together is harder to debug when it fails):

1. **One-line statement:** "Every `Primitives`/`Groups` lab entry is a component-owned page keyed to a stable `36-inventory.json` ID (D-06 spine + D-08 anchor)."
   **Verification method:** text-scan `test/scoria_web/dev_lab_boundary_test.exs` asserting every `PRIM-*`/`GROUP-*` ID referenced in `dev/lab/**/*.ex` source is a literal string also present in `36-inventory.json`'s row IDs (or, minimally, that the required inventory IDs enumerated in D-08/CONTEXT appear at least once in `dev/lab/**/*.ex` — the weaker but still-automatable form RESEARCH.md's Open Question 2 flags as acceptable for Phase 37).
2. **One-line statement:** "A single reusable state-band renderer (not per-primitive hand-written state markup) renders all 10 D-11 states for every covered primitive/group (D-06 state-coverage layer)."
   **Verification method:** text-scan asserting all 10 D-11 state names (`normal`, `long_text`, `empty`, `dense`, `disabled`, `selected`, `loading`, `warning`, `danger`, `error`) appear in `dev/lab/**/*.ex` source, *combined with* a grep-count check that `states_band(` (or the chosen function name) call sites outnumber hand-rolled per-state `<div data-lab-state=...>` occurrences outside `dev/lab/sections/states.ex` itself (a cheap structural proxy that the shared mechanism, not copy-paste, is doing the rendering).
3. **One-line statement:** "The curated flow-probe set matches D-10's named list exactly (dense approvals+toast, mobile table/list summary, drawer/modal focus, command palette, mobile nav, raw-evidence copy, long evidence) — no more, no fewer, without a recorded reason."
   **Verification method:** text-scan asserting each of the 7 named D-10 probe topics has a corresponding entry under `dev/lab/sections/overlays.ex` (or wherever probes land); this is a coverage-*ceiling* check as much as a floor check — D-10 explicitly bounds the probe set, so an eighth undocumented probe should be treated as scope creep to flag, not silently accept.

### D-04 → `must_haves.prohibitions` (must-NOT)

D-04 is fundamentally a negative claim ("do not add X"), and forcing it into `truths` phrasing ("the lab uses zero external component-catalog dependencies") is technically possible but loses the audit trail of *what was checked for and not found*. Recommend `prohibitions`:

**One-line statement:** "Phase 37 must not add `phoenix_storybook`, `phx_live_storybook`, `surface_catalogue`, `surface`, or any other component-catalog/story dependency to `mix.exs` `deps/0` (D-04)."
**Verification method:** a `mix.exs` deps-list diff/grep guard — either (a) a text-scan in the same `dev_lab_boundary_test.exs` asserting `File.read!("mix.exs")` does not match `~r/:phoenix_storybook|:phx_live_storybook|:surface_catalogue|:surface\b/`, or (b) simpler and equally valid: rely on the existing "Package Legitimacy Audit" step in the phase's own research/planning discipline (already run in `37-RESEARCH.md`, confirmed "Not applicable — zero new deps") plus a `git diff mix.exs` review at plan-merge time. Given this is a one-time structural fact (not something later code changes could silently regress without deps.lock changing, which is itself loudly visible in `git diff`), a lightweight CI/review check is proportionate; a dedicated ExUnit assertion is optional hardening, not required, but is cheap enough (3 lines) to include alongside the D-06 guard test in the same file for a single source of truth.

**Why not `[informational]` for either:** both decisions have a concrete, machine-checkable failure mode (a stray dependency line; a lab page with no inventory ID; a hand-rolled state block bypassing the shared renderer) — "informational" should be reserved for decisions that are true by construction of the plan's own file list and have no independent way to regress (e.g., "this phase targets Elixir ~> 1.19" is informational because it's asserted by `mix.exs` itself, already covered elsewhere). D-06 and D-04 both describe *shape* that a later, unrelated edit could silently violate without anyone noticing — that is exactly the class of fact a coverage gate exists to protect.

---

## 6. Risks/footguns specific to Scoria

Beyond the five pitfalls already verified in `37-RESEARCH.md` (compile-path split, e2e-file-is-a-CI-gate, missing `live`/`live_session` import, state/tone drift, fixture-as-hidden-business-rule — all confirmed against live source in this pass and not repeated here), this pressure-test surfaces three additional risks specific to the D-06/D-04 architecture:

1. **Inventory-ID drift is a silent two-way street.** D-08 anchors lab entries to `36-inventory.json` IDs, but Phase 36's inventory is a point-in-time snapshot. If a later phase (38-41) renames or splits a component (e.g., `GROUP-APPROVAL-INBOX-COMPONENT` becomes two components), the lab's literal-string ID references will still "pass" the D-06 truth's text-scan (the string still exists somewhere in `dev/lab/`) while actually describing a component that no longer exists in that shape. The text-scan guard proves *presence*, not *correctness* — this is an accepted, bounded risk (full semantic cross-referencing was explicitly deferred, RESEARCH.md Open Question 2), but it should be logged as a known blind spot rather than assumed away: a future phase touching shared components should re-run a manual "does every lab inventory-ID chip still point at a real component" pass, not rely solely on the automated guard.
2. **The flow-probe layer is the one part of D-06 with no structural forcing function to stay small.** D-10's list is short and named, but nothing in the architecture *prevents* a well-meaning contributor from adding an 8th, 9th, 10th probe "while they're in there," each one adding real e2e runtime (Playwright, a required CI gate per Pitfall 2) and real render-stability risk (many specimens on one page — see risk 3 below). The `must_haves.prohibitions`-style ceiling check in §5.3 is the recommended guardrail; without it, D-06's "small, curated" framing has no teeth beyond code review discipline.
3. **Render-stability of one LiveView rendering many specimens is untested at this phase's actual scale.** `Foundations`/`Primitives`/`Groups` sections, each rendering ~10 states × N primitives via `states_band/1`, plus `Overlays`' curated probes with live JS hooks (drawer/modal/command-palette), all inside one `live_session`, is a meaningfully large single-page render — larger than any existing dashboard page today (confirmed: `lib/scoria_web/live/` pages are all narrower, single-domain views). Two concrete mitigations, both cheap and consistent with the recommended architecture: (a) `handle_params`-driven **section-scoped rendering** (only the active section's function components actually render into the DOM — not all seven sections mounted simultaneously) is already implied by the single-LiveView-with-patch-navigation design in §3.1, so this risk is already substantially addressed by the recommendation, not introduced by it; (b) if a specific section (most likely `Primitives`, given it iterates every `ScoriaWeb.UI` primitive) still proves slow to render or diff, the escape hatch is splitting *that one section* into a `live_component` for isolated re-render scoping — the size-based escape hatch already named in §3.1, not a wholesale architecture change.

None of these three risks are reasons to revisit D-06/D-04 — they are implementation-discipline items for the plan/execute phases: (1) is a documentation/process note, (2) is a one-line addition to the guard test in §5, and (3) is already mitigated by the recommended single-LiveView-with-patch-navigation shape and has a named, bounded escape hatch if it isn't enough.

---

## Summary for the maintainer

- **D-06 is right** because its three layers each answer a distinct, already-named requirement (D-23, D-22, D-10) that the other two layers cannot answer; the accepted cost is a small judgment tax on "does this need a flow probe too," bounded by D-10's short enumerated list.
- **D-04 is right**, and for a reason stronger than dependency-avoidance: the one mechanism PhoenixStorybook would contribute that this lab actually needs (grouped state-variation rendering) costs ~25 lines to build natively with the same `attr`/`slot` idiom the codebase already teaches, while everything else PhoenixStorybook brings (DSL, sole-maintainer dependency, browsing chrome mismatched to the field-engineer-bench aesthetic) is a cost with no matching benefit at this phase.
- **Architecture:** one `DevLab.LabLive`, `handle_params`-driven section dispatch, function-component sections, one `states_band/1` reusable renderer, one `DevLab.Fixtures` catalog split into `states_for/1` (state-parity) and `scenario/1` (D-20 domain payloads) — all verified buildable from code already read in this repo, zero new dependencies.
- **DX guarantee:** adding a new specimen touches exactly two existing files, no new modules or routes, because chrome/theme/motion/readiness are inherited for free from the existing root layout.
- **Coverage-gate encoding:** D-06 → three `must_haves.truths` (spine/inventory-ID anchoring, shared state-band mechanism, bounded flow-probe set); D-04 → one `must_haves.prohibitions` (no catalog dependency added to `mix.exs`).
- **Watch-items, not blockers:** inventory-ID staleness after future phases, flow-probe-count creep, and single-page render scale — all have cheap, already-designed-in mitigations.

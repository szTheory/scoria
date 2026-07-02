# C — Brand, UI/UX, JTBD, Design-Pillar Research: Phase 37 Component Lab

**Scope:** decisions D-22–D-29 (brand/JTBD/UI/microcopy), with D-26 as primary focus. Pressure-tests the locked decisions, does not relitigate them. Sources: `brandbook/brand-book.md` (canonical), `brandbook/tokens.json`, `brandbook/README.md`, `.planning/phases/37-.../37-UI-SPEC.md` (binding), `.planning/phases/37-.../37-CONTEXT.md`, `lib/scoria_web/ui.ex`, `assets/css/02-tokens.css`/`04-components.css`/`05-motion.css`, `test/scoria_web/ds06_drift_guard_test.exs`. External research cited inline with URLs.

---

## 1. Brand/creative pressure-test (D-26)

**Verdict: the evidence-bench / notebook motif is not just appropriate, it is the brand's own reference case, already implemented as a component group.**

The brand book's archetype section says the product "should feel like Phoenix LiveDashboard, Oban Web, a trace waterfall, a lab console, **a field notebook during a production incident** — a control room that stays calm when things break" (`brand-book.md` §1). Phase 37's motif (D-25: "field-engineer bench or evidence notebook... specimens under stress, not marketing demo cards") is a direct, narrow-scope instantiation of that sentence, not a new creative direction. It also fits the "field engineer, not oracle" archetype precisely: a maintainer inspecting primitives before touching shared UI *is* "the person who catches the regression before it ships" (§1), just scoped to the design system itself rather than a production AI run.

A second, stronger finding: **the motif is already an implemented primitive, not just a metaphor.** `lib/scoria_web/ui.ex` ships `notebook/1` (DS-04, "unified tabbed evidence panel shell"), `evidence_section/1`, `evidence_rows/1`, `evidence_action_row/1`, `evidence_empty/1`, and `raw_evidence/1` ("Advanced raw evidence" details/pre block). These exist today for rendering AI-run evidence in the operator dashboard. D-25's "evidence notebook" framing for the lab and these components share a name and a shape by design — reusing them for the lab's own evidence disclosures (fixture-source labels, inventory refs, trace/actor IDs) is simultaneously the correct brand expression *and* the path of least implementation effort. This is a rare case where creative direction and reuse-only constraint reinforce each other instead of trading off.

**Pros of the motif:**
- Reinforces "grounded / composed / operator-grade" personality traits (§1) — a lab that treats its own UI as specimens under inspection, not a showcase, models the brand's own values reflexively.
- Distinct from the explicit competitive contrast the brand book draws: "Explicit competitors to differentiate from: Arize Phoenix, Langfuse, Braintrust — all modern blue-purple SaaS" (§1). A polished component-gallery aesthetic (which is what most internal design-system sites default to — bright cards, generous whitespace, marketing-style empty-state illustrations) would drift toward exactly that genre. The bench/notebook framing pushes the opposite way: dense, evidentiary, typographically driven.
- Matches the voice formula "calm + exact + useful" (§6) and the evidence-verb word bank (traced, scored, compared, promoted, gated...) — "specimens under stress" is evidence-led language, not demo-led language.

**Cons / tradeoffs to manage:**
- **Skeuomorphism risk.** "Notebook" and "bench" are evocative words; the failure mode is someone reaching for literal decoration — paper texture, ruled-grid backgrounds, a magnifying-glass icon system, stitched-binding borders. None of that exists in the token system and none of it should be invented. The motif must stay entirely *structural and typographic*: `eyebrow/1` category labels, `badge/1` state chips, `id/1` monospace refs, `kbd/1` hints, and the existing `--scoria-shadow-panel`/`--scoria-shadow-raised` tokens for panel depth. If a specimen "looks like a lab" it should be because of information density and labeling discipline, not illustration.
- **Persona 2 (contributor, D-23) friction risk.** A contributor who just wants "the canonical badge variant" fast could find an evidence-bench tone slower to scan than a bright component gallery. Mitigate through *information architecture* (canonical examples easy to find via `Groups`/`Fixtures`, inventory-ID anchors, a command-palette-style jump — see §2), not by softening the tone. The brand book's own resolution for this tension is "senior-engineer register" — dense and calm reads as trustworthy to an expert audience under time pressure, which is exactly D-22/D-23/D-24's psychographic (see §6, Storybook/Polaris citations on why expert users prefer scannable evidence over delight).
- **Motif vs. maintainability.** A bench/notebook metaphor invites bespoke chrome per section. UI-SPEC already fences this: any new lab-only chrome (nav rail, viewport-simulator frame) "must still consume semantic tokens only... never a raw hex or a new spacing/type value." That constraint should be read as *part of* the brand expression, not a limitation on it — the brand book's own "Do" list (§10) says "keep the palette dark-first and warm" and its "Don't" list forbids inventing visual language. A lab that resists the temptation to add a fifth typeface-weight or a new shadow "for the lab specifically" is *more* on-brand, not less.

**How to express the motif with existing tokens/primitives only:**
| Motif element | Existing primitive/token |
|---|---|
| Specimen identity ("what am I looking at") | `eyebrow/1` (category) + panel `title` slot |
| State-band label | `badge/1` with explicit `tone` (not inferred — see §4) |
| Inventory/fixture-source/trace ref | `id/1` (copyable monospace, `--scoria-font-mono`) |
| Evidence disclosure ("go deeper") | `notebook/1`, `evidence_section/1`, `raw_evidence/1` (already `open: false` default — evidence is opt-in) |
| Keyboard/viewport hints | `kbd/1` |
| Dark-basalt-first ground | `--scoria-surface-app`/`-panel`/`-panel-raised` as-is, both themes |
| Depth/emphasis | `--scoria-shadow-panel` / `--scoria-shadow-raised` only |

No new hex, no new type size, no new spacing step, no new shadow, no new motion curve. This is the correct reading of D-26 for this phase.

---

## 2. JTBD map

IA sections available: `Foundations`, `Primitives`, `Groups`, `States`, `Viewports`, `Overlays`, `Fixtures` (D-07).

### Persona 1 — Scoria maintainer improving shared UI primitives (D-22)

- **Who:** the person about to edit `lib/scoria_web/ui.ex` or `assets/css/04-components.css`.
- **What:** see every meaningful state and breakpoint of the primitive *before* changing it.
- **Where (primary IA):** `Primitives` (component-first spine, D-06) cross-referenced with `States` (the 10-item state-band vocabulary applied per component) and `Viewports` (the 6 proof widths).
- **Where (secondary):** `Foundations` for the token legend that explains *why* a value is what it is, so a change is judged against the token contract, not eyeballed.
- **When:** pre-change inspection and mid-refactor self-review.
- **Why (JTBD):** "so they do not fix one page while breaking five others" (D-22, verbatim) — the job is regression-prevention across every consumer of a shared primitive, not admiring one page.
- **Domain nouns/verbs:** primitive, token, tone, state, drift, ratchet, regression, coverage.
- **What they need back:** a state×viewport×theme matrix per primitive dense enough to scan in one sitting, with `:disabled`/`:selected`/`:loading`/`:error` bands rendered as real components (not prose descriptions) — this is the literal purpose of D-15's "expose visual stress failures with real constraints."

### Persona 2 — future contributor touching a LiveView page (D-23)

- **Who:** a contributor authoring or modifying a page under `lib/scoria_web/live/`.
- **What:** find the canonical component, copy pattern, state name, and fixture example without reverse-engineering an older page.
- **Where (primary IA):** `Groups` (recurring component groups — approval inbox, workflow tree/detail, connector drawer, incident evidence, per D-09) and `Fixtures` (canonical domain-fixture catalog with D-20 naming).
- **Where (secondary):** `Primitives` when the need is a bare control, not a composed group.
- **When:** at the moment of "do I build this or does it already exist" — usually early in a change, under time pressure.
- **Why (JTBD):** avoid local invention drift — every ad-hoc "just this once" component/copy variant is a future DS-06-style ratchet violation waiting to happen.
- **Domain nouns/verbs:** component owner (e.g. `ScoriaWeb.UI.table/1`), fixture scenario name (`approval_requested`, `dataset_promoted`...), inventory ref (`GROUP-APPROVAL-INBOX-COMPONENT`).
- **What they need back:** a specimen header that names its own owning module/function and inventory ref (evidence-oriented per D-29), plus copy-pasteable fixture shape. This is exactly what `object_header/1` already does for domain objects in the dashboard — reuse the same pattern for specimen headers instead of inventing a lab-only header shell.

### Persona 3 — release/verifier maintainer (D-24)

- **Who:** the maintainer producing browser proof, screenshots, or a future regression guard.
- **What:** deterministic local surfaces — no DB reset, no flaky network state, no clock-dependent fixtures.
- **Where (primary IA):** `Viewports` (explicit width targets) and `Overlays` (drawer/modal/toast focus-and-dismissal probes, D-10), reinforced by `States` for dense/loading/empty determinism.
- **When:** pre-release verification and when authoring `priv/dev/e2e/` specs.
- **Why (JTBD):** confidence that a screenshot or interaction proof is reproducible, so it's usable as a regression baseline later (D-30/D-33/D-32 all point at this).
- **Domain nouns/verbs:** fixture determinism, e2e probe, ready-state, reduced-motion toggle, theme toggle.
- **What they need back:** stable DOM ids (already a documented `id/1` requirement — "must be stable across renders" for hook re-mount safety — the same stability property matters for e2e selectors), an explicit `Reduced motion` toggle and theme toggle as durable chrome (not per-specimen state), and overlay probes that exercise the real `assets/js/scoria.js` focus-trap/dismiss hooks rather than a lab-only reimplementation.

**Cross-persona note:** all three personas are the *same person at different moments* (the Scoria maintainer), which is why the IA should not silo them into separate "modes" — `Foundations → Primitives → Groups → States → Viewports → Overlays → Fixtures` should read as one coherent inspection path that any of the three jobs can enter and exit at the relevant node.

---

## 3. Design-pillar assessment

Pillars enumerated from the brief plus `37-CONTEXT.md` "Specific Ideas": accessibility, responsive behavior, theme parity, motion & reduced motion, performance/render stability, information hierarchy, affordance clarity, density/scannability, microcopy quality, evidence discoverability, keyboard/focus behavior, brand fit (§1 above), and the cross-cutting principle of least surprise / hide-backend-guts.

| Pillar | How the lab should satisfy it |
|---|---|
| **Accessibility (WCAG, status-not-color-alone)** | Every state-band specimen uses `badge/1` with its text `label` rendered (never `dot`-only) — brand-book §7 hard rule ("Every badge and span carries a text label... Color is secondary confirmation"). This matters *more* in the lab than elsewhere: a maintainer scanning a dense state grid by color position alone is exactly the failure the brand rule exists to prevent. Reuse only the 52 already-AA-audited token pairings (`brand-book.md` §4) — do not compose new background/foreground combinations for lab chrome that haven't been through `tools/contrast-check.mjs`. |
| **Keyboard/focus behavior** | Focus ring is `--scoria-focus-ring` (Molten-400 dark / Scoria-600 light), 2px solid + 2px offset, never suppressed (§9). Because `Overlays` is a dedicated IA section whose entire job is proving drawer/modal/toast focus-trap and Escape-dismiss (D-10, D-33), the lab's *own* interactive chrome (nav rail, viewport-simulator controls, theme/reduced-motion toggles) must model the same discipline — a lab that stress-tests focus behavior in specimens while its own toolbar has broken tab order would undercut the tool's credibility for Persona 3. |
| **Responsive behavior** | `Viewports` is a first-class IA node with the exact 6 widths (320/375/768/1024/1440/wide desktop, D-13) and maintainer-proof-target labels, never device marketing names (UI-SPEC explicit example: not "iPhone SE"). A viewport-simulator frame is permitted as new lab-only chrome per UI-SPEC but must consume `--scoria-*` tokens only. |
| **Theme parity (light/dark/system)** | Reuse the existing `.scoria-root[data-theme]` toggle mechanism (`assets/js/scoria.js`) — do not add a second theme mechanism inside the lab (UI-SPEC explicit prohibition). Make the theme toggle durable chrome (persists across sections), not a per-specimen control, so all three personas can hold theme constant while varying state/viewport — the two axes should be independently controllable, not coupled. |
| **Motion & reduced motion** | `05-motion.css`'s reduced-motion kill switch already collapses all animation/transition duration to `0.001ms` under `prefers-reduced-motion: reduce`, unlayered so it "reliably wins." The lab needs a **`Reduced motion`** toggle (D-27's exact label) that lets a maintainer force this state without changing OS settings, making the two named exceptions in the motion layer — the infinite `scoria-skeleton-pulse` loading exception and the 2-cycle `scoria-approval-pulse` attention cue — visibly testable in both the normal and reduced states. This directly serves D-14's "visible and testable enough to support Phase 40" without inventing new motion language. |
| **Performance/render stability** | Large fixture matrices (state × tone × viewport × theme) risk becoming their own unbounded page. Reuse `table/1`'s existing pagination for large fixture-row listings rather than rendering every row flat; prefer `notebook/1`'s tab-based disclosure over rendering every state band fully expanded simultaneously for a "big" primitive like `table/1` itself. |
| **Information hierarchy** | Reuse the established `eyebrow` (category) → `title` (identity) → body pattern already used by `panel/1`/`page_section/1`, and reuse `object_header/1`'s parent-crumb + copyable-ID + status shape for specimen headers instead of inventing a lab-only header. This keeps the lab's own hierarchy legible using the same visual grammar a contributor already knows from the dashboard. |
| **Affordance clarity / least surprise** | Buttons are `button/1` variants exactly as used elsewhere (`:primary`/`:ghost`/`:danger`); the lab must not invent new interaction idioms — e.g. specimen cards should not become click-navigable unless the real component they represent is. Icon buttons use only the already-defined `scoria-button--icon` sizes (UI-SPEC explicit: "do not redefine touch target sizing for the lab"). |
| **Density/scannability** | The bench motif licenses higher density than a marketing page — `panel/1`'s `flush` variant and compact `space-1`–`space-3` rhythm are appropriate defaults for a specimen grid. Body text still holds at 14px/1.5 (the `Body` role) — density comes from layout compaction and disclosure (collapsed evidence by default), never from shrinking below the type scale. |
| **Microcopy quality** | See §4. |
| **Evidence discoverability** | See §4. `raw_evidence/1`'s `open: false` default is the structural mechanism that keeps evidence discoverable-but-not-ambient. |
| **Brand fit** | See §1. |
| **Hide backend guts (D-28) as a pillar** | Treated as a first-visible-text rule, not a total-exposure rule: Ecto schema names, PubSub topics, private helpers, raw `inspect`'d maps, and macro/route internals never appear as specimen titles, section headers, or nav labels. They may appear *inside* a `raw_evidence/1`/`notebook/1` disclosure if genuinely useful for debugging — the dividing line is public-contract-vs-implementation, not visible-vs-hidden absolutely. |

**Mutual consistency check:** the recommendations above are self-reinforcing rather than competing — disclosure-by-default (`raw_evidence/1` closed) simultaneously serves accessibility (less visual noise), density/scannability (specimen grid stays scannable), evidence discoverability (still one click away), and D-28/D-29's hide/expose split. No pillar recommendation here requires a new token, primitive, or interaction pattern.

---

## 4. Microcopy + affordance guidance

**D-27 copy validated against brand-book voice formula (calm + exact + useful, §6):**

| String | Assessment |
|---|---|
| `Component Lab` | On-brand: plain, functional naming, no "Design System Showcase"/"Style Guide" marketing register. |
| `Inspect Scoria primitives, groups, fixtures, themes, and stress states before changing shared UI.` | States the JTBD directly in the subtitle (mirrors D-22's own wording) — this is unusually good practice: the subtitle *is* the job story. "Inspect" isn't literally in the brand's evidence-verb word bank (traced/scored/compared/replayed/promoted/gated/approved/denied — those are *domain-run* verbs), but that word bank governs runtime/product copy, not tooling copy about the design system itself; "Inspect" is the correct register extension, not a violation. |
| `Run lab proof` | Strong brand echo: "proof" ties directly to the hero headline's "Prove the change" (§1 tagline hierarchy) — this is the single best piece of D-27 copy for brand coherence. |
| `Open fixture matrix` | Verb+object CTA pattern matching `Get started`/`View on GitHub` (§2) — consistent length and register. |
| Empty state: `No fixture rows for this state. Add deterministic dev fixture data before using this state for proof.` | Matches the canonical empty-state shape exactly: state-what's-missing + next-action, same as brand-book's own example ("No eval datasets yet. Promote a production trace to start building a regression suite."). |
| Error state: `Lab fixture failed to render. Check the fixture builder and component attrs before changing runtime UI.` | Follows "say what happened" (§6 principle 1), but is necessarily more generic than the brand's canonical run-failure example (which names run/tool/actor/policy/trace ID). **Recommendation:** treat the locked D-27 string as the *fallback wrapper*, and interpolate the specific failing component/fixture name when the render exception provides one (e.g. `Lab fixture failed to render: ScoriaWeb.UI.table/1 / dense fixture. Check the fixture builder and component attrs before changing runtime UI.`) — this keeps the locked copy intact while honoring "specific diagnostics over vague errors" when data is available. Not a change to D-27, an implementation note for how the string is assembled. |
| Chrome labels (`Reduced motion`, `Ugly data`, `Dense data`, `Long text`, `Technical evidence`, `Copy fixture payload`) | Short, imperative-or-noun, no hype — consistent with the brand's explicit avoid-list (revolutionary, seamless, powerful, magic, 10x). No changes recommended. |

**Evidence-disclosure/label pattern recommendations (using existing `id/1`/`badge/1`/`eyebrow/1`/`kbd/1`):**

- **`id/1`** for every inventory ref (`PRIM-TABLE`, `GROUP-APPROVAL-INBOX-COMPONENT`, risk refs like `RISK-OVERLAY-FOCUS`) and every trace/run/actor/approval ID surfaced inside a fixture specimen. This is literally the component's documented purpose ("Copyable monospace identifier (run/trace/actor IDs)") — reuse verbatim, do not build a second copy-chip.
- **`eyebrow/1`** above each specimen title for the category label (e.g. "SPECIMEN" / "FIXTURE SOURCE" / "OWNER"), consistent with the existing panel/object-header pattern rather than a new lab-only label style.
- **`badge/1`** for state-band names — with one important nuance: **the state-band tone must be assigned explicitly, not inferred through `tone/1`.** `tone/1`'s status→tone mapping is a domain-status classifier (it maps strings like `pending`, `failed`, `approved`); most of the D-11 lab state vocabulary (`dense`, `long_text`, `selected`, `disabled`) has no domain-status meaning and would silently fall through to `tone/1`'s `:neutral` catch-all if passed through it, while a few (`warning`, `danger`, `error`) *do* coincide with domain-status words and would resolve "correctly" by accident. Passing an explicit `tone:` per state band (matching D-12's separation of state names from visual tones) avoids both the silent-neutral case and the accidental-coincidence case.
- **`kbd/1`** for viewport-simulator width shortcuts (if keyboard-resizable) and for any command-palette-style "jump to component" shortcuts serving Persona 2's fast-lookup job.
- **`notebook/1` + `evidence_section/1` + `raw_evidence/1` + `evidence_rows/1`** as the literal implementation of the `Technical evidence` chrome label (D-27) — reuse the existing DS-04 evidence-notebook group rather than building a new disclosure widget. See §1: this is the strongest reuse win in the whole phase.

**Hiding backend guts (D-28) while exposing evidence (D-29) — concrete boundary:**

Primary/first-visible specimen text may show: component owner (`ScoriaWeb.UI.table/1`), inventory ref, fixture scenario name (domain-language per D-20), and the rendered domain payload itself. It must never show, as first-visible text: Ecto schema module names, PubSub topic strings, `defp`-only helper names, raw `inspect`'d maps, or router/macro internals. Those belong exclusively inside a `raw_evidence/1`/`notebook/1` disclosure (default closed), and only when they're genuinely useful evidence for *why* a fixture renders a given state — not as decoration or completeness-for-its-own-sake.

---

## 5. Coverage-gate classification

| Decision | Classification | Exact one-line statement | Verification method |
|---|---|---|---|
| **D-26** (brand direction) | `must_haves.truths` **+** `must_haves.prohibitions` (split — see below) | — | — |
| D-26, truths half | `must_haves.truths` | "Lab-authored chrome (`dev/` lab LiveViews/components) emits zero raw hex values and zero raw Tailwind palette classes; all color, type, spacing, and motion values resolve through existing `--scoria-*` tokens and `ScoriaWeb.UI` primitives." | Extend the existing DS-06 drift guard (`test/scoria_web/ds06_drift_guard_test.exs`) — add a parallel "lab-zero" assertion mirroring the current "`ui.ex` has zero raw palette matches" test, scanning `dev/` lab paths with the same `@palette_regex`, plus a new regex for literal hex (`#[0-9a-fA-F]{3,8}`) since raw hex isn't caught by the palette-class regex alone. |
| D-26, prohibitions half | `must_haves.prohibitions` | "Lab-authored chrome and copy never use phoenix-bird/flame imagery, hype language (revolutionary/magic/10x/seamless/powerful/next-generation — the brand-book §6 avoid-list), or a marketing-gallery visual treatment (shadows/gradients outside `--scoria-shadow-panel`/`-raised`, decorative illustration, stock photography)." | Partially automatable: a grep guard over lab copy strings for the brand-book §6 avoid-list word bank (mirrors DS-06's regex-guard pattern) catches the language half. The visual "gallery vibe" half is not booleanizable — flag it as a manual `gsd-ui-review`/design-review checklist line item, not a CI gate. |
| **D-25** (motif) | [informational] | "The lab's visual motif is field-engineer-bench/evidence-notebook, expressed via `notebook/1`/`evidence_section/1`/`raw_evidence/1` disclosure patterns and `eyebrow`/`badge`/`id` labeling — never skeuomorphic decoration." | Not independently gate-able as a boolean; carry as design-rationale narrative feeding D-26's prohibitions above (the "no gallery, no decoration" rule is D-26's testable proxy for D-25's intent). |
| **D-27** (copy) | `must_haves.truths` | "Page title renders exactly `Component Lab`; primary CTA renders exactly `Run lab proof`; secondary command renders exactly `Open fixture matrix`; top-level nav renders exactly `Foundations`/`Primitives`/`Groups`/`States`/`Viewports`/`Overlays`/`Fixtures`; every state-band label is drawn only from the canonical 10-item D-11 vocabulary (no synonyms)." | ExUnit LiveView copy-contract test asserting exact literal strings appear in rendered HTML (same style as `test/scoria_web/ui_component_test.exs`), plus a state-name enum guard (already called for by D-32) asserting no string outside the canonical list is used as a state-band label anywhere in lab source. |
| **D-28** (hide backend guts) | `must_haves.prohibitions` | "Primary lab orientation (specimen titles, section headers, nav labels — i.e. everything outside a `raw_evidence/1`/`notebook/1` disclosure) never renders raw Ecto schema names, PubSub topic strings, private (`defp`) helper names, raw `inspect`'d maps, or route/macro internals as first-visible text." | Partially automatable: grep lab render output/templates for common leakage signatures (`%Scoria.*Schema{`, `Phoenix.PubSub`, bare `inspect(` calls) appearing *outside* elements carrying the raw-evidence/notebook DOM markers; treat any hit as a violation. Full precision requires a manual review pass at `gsd-ui-review` time since "first-visible" is a rendering-order judgment, not purely a string match. |
| **D-29** (expose evidence) | `must_haves.truths` | "Every rendered specimen exposes, via evidence disclosure, at least a fixture-source label and an inventory ref; specimens modeling a domain object additionally expose actor/trace/run/policy identifiers via `id/1`." | Coverage-checker test in the D-32 style: iterate the fixture catalog, assert each fixture's rendered specimen contains the required evidence keys (fixture-source label, inventory ref, and for domain-object fixtures, at least one `id/1`-rendered identifier). |

---

## 6. Footguns

1. **Accessibility deferred until after visual polish.** The single most likely failure mode for *any* internal lab, and directly named as a footgun in `37-CONTEXT.md`. Mitigate by making focus-ring visibility, status-never-color-alone, and contrast part of each `Primitive`/`Group` entry's definition-of-done from its first commit — not a final accessibility pass. This is self-undermining if skipped: the lab exists specifically to prevent this class of regression for the *rest* of the dashboard (D-22); building the lab itself accessibility-last would be the exact anti-pattern it's meant to catch.
2. **Brand drift via skeuomorphism.** "Notebook"/"bench" as literal decoration (paper texture, ruled grids, magnifying-glass iconography, stitched borders) — none of it exists in tokens, none of it should be invented. Hold the motif to typographic/structural expression only (§1).
3. **Marketing-gallery tone.** Symmetric card grids, generous whitespace, feel-good empty-state illustrations, hover-lift shadows beyond `--scoria-shadow-*`. `37-CONTEXT.md`'s own specifics explicitly reject this ("not a beautiful gallery"). Concretely: default to `panel/1` flush + table-like density over a grid of glossy tiles.
4. **Over-exposing internals.** Direct tension between D-28 and D-29's "expose evidence" mandate — easy to over-correct toward "show everything, it's a dev tool anyway." The `raw_evidence/1` `open: false` default is the structural enforcement mechanism: evidence is opt-in-visible, never ambient. If a future contributor finds themselves adding a new "just print the whole struct" affordance outside that disclosure pattern, that's the signal D-28 is being violated.
5. **State-name/tone conflation (D-12 risk).** A state band labeled `dense` or `long_text` passed through `tone/1`'s domain-status inference will silently render `:neutral` (harmless but meaningless), while `warning`/`danger`/`error` will *coincidentally* resolve correctly through the same function — inconsistent behavior that looks correct in spot-checks and breaks under a full state-band sweep. Require explicit `tone:` assignment per state band; never rely on `tone/1` string-matching the D-11 vocabulary.
6. **Storybook/Polaris/Carbon envy at the visual layer.** The external research below is valuable for *information-architecture* lessons (one story per state, accessibility surfaced inline as a first-class panel, controls/toggles as durable chrome) — it is not license to import Storybook's blue accent UI or Carbon's IBM-blue palette. Take the structural lesson, leave the visual language; Scoria's dark-basalt/warm-ember system is the explicit differentiator from "modern blue-purple SaaS" (§1) and that holds inside the lab too.

**External research applied (structural lessons only, cited):**

- Storybook's accessibility addon runs automated a11y checks *inline with every story/state* and groups violations by rule rather than a flat list — the lesson: surface accessibility evidence per-specimen, not as a separate audit pass. [Accessibility tests | Storybook docs](https://storybook.js.org/docs/writing-tests/accessibility-testing), [Sneak peek: Accessibility Addon refresh](https://storybook.js.org/blog/preview-the-new-accessibility-addon/)
- Storybook's interaction/play-function model treats "stories" (states) as reusable both for visual review and behavioral/a11y test cases — the same underlying fixture drives documentation and proof. Directly supports D-30's screenshot/proof reuse intent. [Interaction tests | Storybook docs](https://storybook.js.org/docs/writing-tests/interaction-testing)
- Shopify Polaris frames accessibility as testable do's/don'ts tied to specific component states (labels on every form control, no programmatic focus-stealing, clear error states with next steps) rather than a general principle — the lesson: the lab's error/empty specimens should demonstrate the *recovery guidance*, not just the visual failure state. [Accessibility — Shopify Polaris](https://polaris-react.shopify.com/foundations/accessibility), [Accessibility testing.md](https://github.com/Shopify/polaris/blob/main/documentation/Accessibility%20testing.md)
- IBM Carbon's loading/empty-state patterns define explicit state machines (inactive/active/finished/error for loading; empty states scoped to "the context of the data that's missing") — reinforces D-11's discrete state vocabulary as the right shape, and that empty/error states should be evaluated in the context of the surrounding component, not as generic global states. [Empty states pattern](https://carbondesignsystem.com/patterns/empty-states-pattern/), [Inline loading usage](https://carbondesignsystem.com/components/inline-loading/usage/)
- GitHub Primer's content guidelines for empty/error states: no playful graphics on error, be specific about what failed, and offer a recovery path forward rather than a dead end — directly reinforces the recommendation in §4 to interpolate the specific failing component into the D-27 error string when available. [Empty states | Primer](https://primer.style/ui-patterns/empty-states), [Content | Primer](https://primer.style/foundations/content/)
- Material Design 3's state model (hover/focus/pressed/dragged/disabled, each independently and combinatorially specified) is the precedent for treating "state" as an orthogonal axis from any single component's visual variants — supports D-12's hard separation of lab state names from visual tone names. [States – Material Design 3](https://m3.material.io/foundations/interaction/states/applying-states)

---

*Research artifact for Phase 37 planning. Produced by decision-research stream C (brand/UX/JTBD/design-pillar). Does not modify locked decisions D-22–D-29; pressure-tests and operationalizes them for the executing plan.*

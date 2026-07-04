# Phase 37 — Decision Synthesis & Recommendations

> One coherent, cross-checked recommendation set produced from four parallel expert research
> streams (A: architecture, B: fixtures, C: brand/UX, D: proof/CI). Each stream read the live
> repo + `brandbook/` + `prompts/` and researched how successful tools in this space (Storybook,
> Phoenix Storybook, Lookbook/ViewComponent, Ladle/Histoire, Pattern Lab/Fractal, Percy/Chromatic/
> BackstopJS, ExMachina, Polaris/Carbon/Primer/Material) solved the same problems. Full findings in
> `A-architecture.md`, `B-fixtures.md`, `C-brand-ux.md`, `D-proof-ci.md`.

## Headline

All five decisions the coverage gate flagged as "uncovered" (**D-04, D-06, D-17, D-26, D-30**) are
**correct and should stay locked**. They were uncovered by the *gate*, not wrong in the *plans* —
the plans honor them implicitly but never cite the IDs in `must_haves`. **Recommendation: cite them
(Option 1), and while revising, fold in the ~8 concrete refinements below.** No decision is
overturned; the direction is confirmed and sharpened.

The through-line across every stream: **the lab is a thin rendering + coverage layer over
vocabulary that already exists (tokens, primitives, domain nouns, states) — never a second app, a
DSL, a new visual language, or a new data model.** That is exactly what D-04/D-06/D-12/D-17/D-26
already say; the research just proves it with ecosystem evidence and pins the exact shape.

---

## Part 1 — The five decisions: verdicts + how to cite them

### D-04 — no PhoenixStorybook this phase ✓ CORRECT
Stronger reason than "avoid a dependency": the *one* mechanism Storybook would contribute that this
lab needs (grouped state-variation rendering) is ~25 lines of plain `attr`/`slot` `Phoenix.Component`
using the **same idiom `ui.ex` already teaches**; everything else it brings (a real
`use PhoenixStorybook.Story` DSL, single-maintainer bus-factor dependency, polished-gallery chrome)
is either irrelevant to a single-author maintainer tool or actively mismatched to the field-bench
aesthetic (D-25). Fully reversible — `STORYBOOK-01` stays on the books; the repo-local fixtures/
state-vocabulary port directly into `.story.exs` if that day comes.
- **Cite as** `must_haves.prohibitions`: *"Phase 37 adds no `phoenix_storybook`/`phx_live_storybook`/
  `surface_catalogue`/`surface` (or any component-catalog) dependency to `mix.exs`."*
  **Verify:** source-scan `mix.exs` for those dep atoms (3-line `refute` in the boundary test).

### D-06 — hybrid inventory-driven catalog ✓ CORRECT
Not a compromise between two failed extremes — each of its three layers answers a **distinct, named
requirement the other two structurally cannot**: component-first spine → D-23 discoverability; shared
state bands → D-22 state-parity inspection; curated flow probes → D-10 cross-component risk (toast-
over-dense-table, overlay focus stacking). Lookbook (Rails) independently converged on the same
"co-locate the catalog entry with the thing it catalogs" answer. Accepted cost: a small "does this
need a flow probe too?" judgment tax, bounded by D-10's short enumerated list.
- **Cite as three `must_haves.truths`:**
  1. *"Every Primitives/Groups lab entry is a component-owned page keyed to a stable `36-inventory.json`
     ID (D-06 spine + D-08 anchor)."* — verify: required inventory IDs appear as literal strings under
     `dev/lab/**/*.ex`.
  2. *"One reusable state-band renderer (not per-primitive hand-written state markup) renders all 10
     D-11 states for every covered primitive/group."* — verify: all 10 state names present + the shared
     `states_band(` call sites outnumber ad-hoc per-state blocks.
  3. *"The curated flow-probe set matches D-10's named list (dense-approvals+toast, mobile table/list
     summary, drawer/modal focus, command palette, mobile nav, raw-evidence copy, long evidence) — no
     more, no fewer, without a recorded reason."* — verify: each named probe topic present; treat an
     8th undocumented probe as scope creep (ceiling check, not just floor).

### D-17 — fixtures deterministic/reset-free, seed is DB-projection only ✓ CORRECT (provably)
The codebase itself proves it: `priv/repo/dev_seed.exs` inserts real Ecto rows with DB-generated
UUIDs, `utc_now()` timestamps, and additive (non-idempotent) cardinality — three independent
nondeterminism axes, by design, because its job is believable click-through proof, not byte-stable
fixtures. Lab fixtures need the opposite. Nuance: reusing `SupportJourney`'s **pure scalar identity
constants** (`tenant_id/0`, `connector_key/0`) is fine and good for continuity; mutating its JSON
fixtures is not (different module's contract + drift guards).
- **Cite as two `must_haves.truths`:**
  1. *"`DevLab.Fixtures` never references `Scoria.Repo`/`Ecto.Query`/a DB-backed context — every
     scenario is a pure literal-data read."* — verify: source-scan denylist over `dev/lab/**/*.ex`.
  2. *"Fixture reads are deterministic: no `DateTime.utc_now`/`NaiveDateTime.utc_now`/`Ecto.UUID.generate`/
     `System.unique_integer`/`:rand.*`/`Enum.random` under `dev/lab/fixtures*`."* — verify: denylist regex.

### D-26 — keep the brandbook direction ✓ CORRECT (it's the brand's own reference case)
`brand-book.md` §1 literally names "a field notebook during a production incident" as the product's
archetype — D-25's evidence-bench motif is a narrow instantiation of the brand, not a new direction.
Better still, the motif is **already an implemented primitive**: `notebook/1`, `evidence_section/1`,
`raw_evidence/1` exist today (for AI-run evidence) — reusing them for the lab's disclosures is
simultaneously the correct brand expression and the least-effort path. Main risk: skeuomorphic
overreach (paper texture, ruled grids) — hold the motif to purely typographic/structural expression.
- **Cite as `must_haves.truths` + `must_haves.prohibitions`:**
  - truths: *"Lab-authored `dev/` chrome emits zero raw hex and zero raw palette classes; all color/
    type/spacing/motion resolve through `--scoria-*` tokens and `ScoriaWeb.UI` primitives."* — verify:
    extend the existing DS-06 drift guard to scan `dev/` lab paths + add a raw-hex regex.
  - prohibitions: *"Lab chrome/copy use no phoenix-bird/flame imagery, no hype word-bank
    (revolutionary/magic/10x/seamless/powerful), and no marketing-gallery treatment (decorative
    illustration, shadows/gradients outside `--scoria-shadow-panel`/`-raised`)."* — verify: grep the
    §6 avoid-list word bank (language half automatable); "gallery vibe" half → manual `gsd-ui-review` line.

### D-30 — no screenshot-diff CI gate this phase ✓ CORRECT (repo already ran this experiment)
`priv/dev/shots.mjs` has existed 25+ phases and deliberately **never** became a required gate. Visual
diffing also structurally conflicts with the lab's purpose: it renders *intentionally ugly* stress
states, so a day-1 baseline would encode "today's imperfections" and turn every Phase 38–41 fix into a
diff, punishing the exact work the lab exists to enable. Adopt visual diffing (VISUAL-CI-01, ~Phase 41)
only when: lab IA stable + Docker-pinned deterministic renderer + measured <2% flake in an advisory
trial + a named baseline-review owner + explicit phase scope.
- **Cite as `must_haves.prohibitions`** (*"no screenshot-diff step added to the required `ci-gate`
  this phase"*) **+ `must_haves.truths`** (positive: lab renders at `/scoria/_lab`, covers all 10 states
  + required fixture domains, stays dev-only, preserves Hex/macro boundary). — verify: guard test +
  active e2e probes (both already in required lanes); a `VERIFICATION.md` note that no visual-diff job
  was added to `ci.yml`/`ci-verify.yml`.

---

## Part 2 — Concrete plan refinements to fold in while revising

These are net-new improvements the research surfaced (not just citations). Highest-value first:

1. **Close the D-19 empty/error coverage gap (from B).** The D-20 example list gives `dataset_empty`
   and `workflow_failed_step` but **no named empty/error scenario for reviews or prompts**. D-19 requires
   empty/error paths for *all* domains. Add `review_queue_empty` and `prompt_registry_empty` so every
   D-19 domain has both a normal and an empty-or-error named scenario. (Real coverage fix, not a
   decision change — D-20's list is illustrative per its own "instead of" framing.)

2. **Decouple "domain scenario" from "render state" (from A+B).** `scenario/1` returns one realistic
   record per domain noun (D-20); `states_for/2` **derives** the 10 D-11 state bands generically. Never
   hand-author a 13×10 fixture matrix — that's the ExMachina/FactoryBot "factory explosion" footgun.
   Keeps "add one ugly scenario" at O(1) (one map literal), the DX guarantee D-23 wants.

3. **Bulky JSON payloads live in `priv/dev/lab_fixtures/`, never `priv/fixtures/` (from B).** `mix.exs`
   `package/0` ships `priv/fixtures` to Hex but excludes `priv/dev` — a one-segment path slip would leak
   dev stress-data to adopters. Declare `@external_resource` per JSON file so a malformed/edited fixture
   fails `mix compile` under `:dev` instead of at first render.

4. **Fixtures carry domain-truth fields only — never a `:tone` key (from B+C).** Tone is always
   *derived* at render (real `ScoriaWeb.UI.tone/1` for domain-status components; the lab's own explicit
   `state_tone/1` for state-band chrome). This closes the tone/state-drift pitfall at the data layer, not
   just the call site. Corollary (C): state-band `badge/1` tone must be assigned **explicitly per band** —
   never inferred through `tone/1`, which silently maps `dense`/`long_text` to `:neutral` and coincidentally
   "passes" for `warning`/`danger`/`error`.

5. **The boundary guard test is the D-21 enforcement mechanism, not defense-in-depth (from B+D).**
   `elixirc_paths(:dev) = ["lib","dev"]` means a `lib/ → DevLab.Fixtures` reference **compiles fine under a
   maintainer's everyday `mix phx.server`** and only fails under `:test` or an adopter's prod build. The
   `test/scoria_web/dev_lab_boundary_test.exs` zero-`lib/`-reference scan is the *only* check that fires
   where the violation is both present and caught. Guard #4 also catches the `Code.ensure_loaded?(DevLab…)`
   lazy-load pattern (still a string match). Elevate from "add a guard" to "this guard is the enforcement."

6. **Add the inventory-ID cross-reference guard (#7) (from D).** Beyond asserting the 10 state names +
   scenario names appear, assert every `canonical`-status `PRIM-*`/`GROUP-*` row ID from `36-inventory.json`
   that D-08 says the lab covers appears under `dev/lab/**/*.ex`. ~20 lines, reads already-parsed JSON, turns
   D-32's "tie to inventory IDs where practical" from prose into an enforced contract. **Honesty caveat to
   record in the guard's `@moduledoc` and keep in VALIDATION.md:** string-presence is a coverage *floor*, not
   proof every primitive renders every state — the manual walkthrough stays the complement, don't let a future
   phase delete it.

7. **Reuse the existing evidence-notebook group for disclosures (from C).** `notebook/1` +
   `evidence_section/1` + `raw_evidence/1` (default `open: false`) *is* the implementation of the
   `Technical evidence` chrome label — don't build a new disclosure widget. `id/1` for every inventory/trace/
   actor ref (copyable monospace); `eyebrow/1` for category labels; `object_header/1`'s shape for specimen
   headers. `open:false` default is the structural enforcement of the D-28-hide / D-29-expose split (evidence
   opt-in, never ambient).

8. **Keep D-27 error copy as the locked wrapper, interpolate specifics when available (from C).** Render
   the exact locked string `Lab fixture failed to render. Check the fixture builder and component attrs
   before changing runtime UI.` but, when the render exception names the component/fixture, prepend it
   (`… failed to render: ScoriaWeb.UI.table/1 / dense fixture.`). Honors "specific diagnostics over vague
   errors" without changing the locked copy — an assembly note, not a copy change.

## Part 3 — Architecture (confirmed, for the executor)
Single `DevLab.LabLive`, `handle_params`-driven section dispatch (rejected: 7 per-section LiveViews —
duplicates chrome + route churn; rejected: a specimen-registration macro — recreates the D-04 DSL cost and
`test/` can't introspect it anyway). Sections are plain function components under `dev/lab/sections/*.ex`
(escape hatch: split one section to a `live_component` only if its `render/1` exceeds ~300 lines). One
`states_band/1` reusable renderer. One `DevLab.Fixtures` facade (`scenario/1`, `scenarios/0`, `domains/0`,
`states_for/2`), split into per-domain private modules only past ~300–400 lines. Reuse `{ScoriaWeb.Layouts,
:root}` verbatim (inherits CSS/JS/theme/readiness sentinel). Render-stability watch-item: only the active
section renders (patch navigation), which already substantially bounds the single-page scale.

## Part 4 — Out-of-scope items to log (Reviewed, not folded)
- **CI correctness bug (from D):** `ci-verify.yml`'s `connector` job step labeled "(advisory)"
  (`mix scoria.test.support_copilot`) has **no `continue-on-error: true`** yet feeds `verify-summary`'s
  `needs:`, so it actually blocks the required `verify` workflow. Not Phase 37 scope, but file it — and
  Phase 37's own docs must not repeat the "advisory-as-comment ≠ advisory-as-topology" mistake when
  explaining the lab's proof surfaces.
- **VISUAL-CI-01 promotion criteria** (Part 1 / D-30) for whoever picks it up (~Phase 41).
- **`@external_resource` on `SupportJourney`'s own JSON** — a small drift-detection improvement worth a
  follow-up there too, out of Phase 37 scope.

## Coverage-gate resolution
Apply **Option 1**: a targeted planner revision that adds the citations in Part 1 to the relevant plans'
`must_haves` (D-04 → Plan 01/05 prohibitions; D-06 → Plan 01/02/03/05 truths; D-17 → Plan 01 truths;
D-26 → Plan 02/03/04/05 truths+prohibitions, wired to the DS-06 guard; D-30 → Plan 06 prohibitions+truths),
and folds in the Part 2 refinements. Re-run the decision-coverage gate + plan-checker after.

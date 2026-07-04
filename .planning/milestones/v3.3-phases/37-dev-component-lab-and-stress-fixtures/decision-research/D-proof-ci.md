# D-proof-ci: Phase 37 Proof / Testing / CI Strategy for the Component Lab

**Domain:** Proof & Documentation Shape (D-30..D-34, focus D-30)
**Author:** principal test/QA + DevOps/SRE pressure-test
**Date:** 2026-07-02
**Verdict up front:** D-30 is correct. Ship structural/coverage guards + a `mix test`-visible
suite as the required proof; keep `lab.spec.mjs` deliberately narrow inside the already-required
`e2e` job (near-zero-flake truths only, `test.fixme` for the rest); do **not** add screenshot-diff
gating in Phase 37. VISUAL-CI-01 should stay unopened until Scoria has a *second* independent
signal that visual drift is being missed by the guard+e2e suite — not before.

---

## 1. Decision pressure-test — is "no screenshot-diff required gate this phase" correct?

### The claim in D-30

> "Phase 37 proof should prioritize whether the lab renders, covers required states/domains,
> stays dev-only, preserves package boundaries, and provides useful browser-inspection surfaces.
> Do not turn screenshot diffs into a required CI gate in this phase."

### Why this is correct, with evidence from this exact repo

**1a. Scoria already has a real, working advisory screenshot pipeline — and it deliberately
never became a required gate.** `priv/dev/shots.mjs` + `lib/mix/tasks/scoria.ui.shots.ex`
capture 9 dashboard screens × {theme × viewport × overlay} and optionally run an LLM critique
pass into `priv/shots/gap_register.md`. This has existed since Phase 11/12 and is *still*
advisory — invoked via `make shots`/`make critique`, never wired into `ci.yml`. That is strong
in-repo evidence the maintainer already made this call once, deliberately, and it held up over
25+ phases. Phase 37 is not the first time this question has been asked; it's the same answer
applied to a new surface.

**1b. The component lab is the wrong artifact to pixel-diff even if the maintainer wanted to.**
Visual regression tools compare a page/component against a *stable baseline*. The lab's entire
purpose (D-15) is to show state combinations that are *supposed to look stressed/ugly* — long
unbroken IDs, dense rows, empty datasets — specifically so a human eye can judge them before
Phase 38 fixes anything. A snapshot baseline captured on day 1 of Phase 37 would just be "today's
imperfect rendering," and every future improvement in Phase 38-41 would show up as a *diff*,
not a *regression*. Gating on that inverts the phase's purpose: it would punish the fixes the lab
exists to enable. Diffing pays off once a surface is meant to be *stable*; the lab is deliberately
the opposite of stable during v3.3.

**1c. The lab has zero DB dependency by design (D-17), which removes the primary lever visual
tools use for determinism, but doesn't buy determinism back for free.** `dev/lab/fixtures.ex` is
static in-memory Elixir data — good, this avoids the classic "seed drift" flake source. But
Playwright screenshots are still sensitive to font-rendering differences between local (macOS)
and CI (Ubuntu) runners, sub-pixel anti-aliasing, and animation timing — sources unrelated to
seed determinism. The existing `05-motion.css` durations (100/150/200ms) are exactly the kind of
"looks fine to the eye, fails a 0.1% pixel diff" hazard documented broadly in the visual-testing
ecosystem (see §2). Scoria has not yet done the Docker-pinned-renderer work (aligning the
screenshot runner's OS/fonts with CI) that teams report is the single highest-leverage fix for
this class of flake — until it has, gating on pixel diff is importing flake, not catching
regressions.

**1d. CI cost/topology argument.** `priv/dev/e2e/*.spec.mjs` is *already* `testDir`-driven and
picked up automatically into the required `e2e` job (Pitfall 2 in 37-RESEARCH.md is exactly
right about this). A visual-diff step is a structurally different kind of gate — it needs a
committed baseline directory, a review/approval UI or manual `--update-snapshots` workflow, and
non-trivial CI minutes for image comparison across every PR touching UI. None of that
infrastructure exists yet in this repo. Building it *and* proving it's low-noise *and* wiring it
into `ci-gate` in the same phase that's also building the lab itself is scope-stacking risk on
top of a phase whose actual goal (LAB-01/LAB-02/FIXT-01) is coverage and inspection surfaces, not
pixel-perfect regression detection.

### Tradeoffs — steelmanning the other side

The strongest argument *for* gating now: the lab is precisely the place where a future regression
(e.g., someone changes `--scoria-space-4` and every panel silently gets wrong padding) would be
easiest to catch automatically, because the lab renders every primitive in one place. Waiting
until Phase 41 means Phases 38-40 modify shared controls (`DS-02`/`DS-03` mentioned in
37-UI-SPEC.md) with only human eyes and the guard/e2e suite watching. That's a real cost — visual
regressions in shared CSS are exactly the class of bug pixel diffing is best at catching, and the
lab (once built) is the cheapest place to point a screenshot tool at, because it's already a
comprehensive state matrix in one route.

This is a legitimate reason to *not* defer visual diffing indefinitely — it's a reason to treat
`VISUAL-CI-01` as a live backlog item to revisit right after the lab ships and stabilizes (see
§1e), not a reason to build it inside Phase 37 before the lab's own shape has settled. You cannot
tune diff thresholds, masking, or baseline review workflow against a target that is still being
actively authored in the same phase.

### When SHOULD Scoria adopt visual diffs (VISUAL-CI-01 framing)

Promote to a required (or even advisory-first) visual-diff gate only when **all** of these hold,
mirroring the "advisory-first rollout" pattern documented across Percy/Chromatic/BackstopJS
adoption guides:

1. **The lab's IA and fixture catalog are stable** — not still absorbing new sections/states each
   phase. Diffing against a moving target guarantees constant baseline churn.
2. **The screenshot runner is deterministic across environments** — CI and local produce
   byte-identical (or diff-tool-equivalent) renders. This likely means pinning the official
   Playwright Docker image for both the existing `shots.mjs` harness and any lab-targeted
   variant, disabling CSS animations (`page.emulateMedia`/`animations: 'disabled'`), and masking
   any inherently non-deterministic region (timestamps, IDs that aren't fixed in fixtures —
   though D-16/D-17 static fixtures mostly solve this one already).
3. **A trial advisory run has measured a real flake rate.** Run the diff step for a few weeks as
   a non-blocking CI job (or `continue-on-error: true`, see §6 for why this must be literal, not
   just a comment) and confirm the false-positive rate is low enough to trust — the flaky-test
   literature converges on <1-2% as the threshold where a required gate keeps developer trust
   (see §2 citations).
4. **There's a designated owner for baseline review** — someone has to approve intentional diffs
   (Phase 38 changing a token, e.g.) before merge. Without an owner, a required visual gate
   becomes a "click approve to unblock myself" rubber stamp, which is worse than no gate — it
   creates false confidence.
5. **Phase 41 (or whichever phase inherits `VISUAL-CI-01`) explicitly scopes it**, rather than it
   arriving as an unplanned addition mid-phase. This keeps the "advisory-first, promote-later"
   discipline that already worked for `shots.mjs`.

Until 1-4 hold, D-30's prohibition is correct engineering conservatism, not scope-avoidance.

---

## 2. Ecosystem lessons table

| Tool / approach | What teams adopt it for | Footgun teams hit | Citation |
|---|---|---|---|
| **Playwright `toHaveScreenshot`** | Built-in, no third-party service, pixel-diff with configurable threshold/mask | Cross-OS font/anti-aliasing rendering differences between local (macOS/Windows) and CI (Ubuntu) runners are the single biggest flake source; animations and dynamic content are the next two | [TestQuality: Playwright Visual Regression Guide](https://testquality.com/playwright-visual-regression-guide/), [turntrout.com: 428-Day Battle Against Flaky Playwright Screenshots](https://turntrout.com/playwright-tips) |
| **Docker-pinned Playwright image** | Eliminates the #1 flake source above by making CI and local byte-identical | Requires discipline to *always* run visual tests through the pinned image, including locally when updating baselines — a shortcut here reintroduces the exact drift it fixes | [TestQuality: Playwright Visual Regression Guide](https://testquality.com/playwright-visual-regression-guide/) |
| **Masking dynamic regions / disabling animations** | Removes non-deterministic areas (timestamps, spinners, motion) from the diff surface before comparing | Over-masking hides real regressions in the masked region; under-masking reintroduces flake — this is an ongoing tuning cost, not a one-time setup | [TestQuality: Playwright Visual Regression Guide](https://testquality.com/playwright-visual-regression-guide/) |
| **Chromatic (Storybook-native)** | Component-level visual review tightly coupled to Storybook stories, PR-level per-story approve/reject workflow | Requires Storybook as a prerequisite investment (exactly what D-04 defers) — adopting Chromatic without Storybook means building an equivalent story/variation layer from scratch first | [Medium: Percy vs Chromatic](https://medium.com/@crissyjoshua/percy-vs-chromatic-which-visual-regression-testing-tool-to-use-6cdce77238dc) |
| **Percy** | Broadest framework compatibility, page-level diff review dashboard, easier bolt-on to an existing Playwright/Cypress suite than Chromatic | Page-level granularity is coarser than component-level — one CSS token change can touch dozens of pages/snapshots at once, producing large "diff storms" that erode reviewer trust in the tool | [Medium: Percy vs Chromatic](https://medium.com/@crissyjoshua/percy-vs-chromatic-which-visual-regression-testing-tool-to-use-6cdce77238dc) |
| **BackstopJS / Loki / reg-suit** (self-hosted, no SaaS) | Full control over baseline storage/review, no per-snapshot billing, good fit for teams unwilling to add a paid SaaS dependency to a library's CI | Self-hosted baseline management (storage, diff review UI, CI wiring) is now the *team's* maintenance burden — the exact "maintenance cost" D-30 is avoiding by deferring. Loki specifically assumes a Storybook story layer already exists | [Loki docs](https://loki.js.org/), [TestDriver: BackstopJS Alternatives](https://testdriver.ai/articles/top-3-alternatives-to-backstopjs-for-visual-regression) |
| **Test quarantine pattern (general CI flake mgmt)** | Keep a flaky/uncertain test *running and visible* but remove it from the required-check set, so signal isn't lost but merges aren't blocked | Quarantining without a tracking ticket + owner + expiry becomes a permanent graveyard — tests silently rot in "advisory" status forever with no one accountable for fixing or deleting them | [Mergify: Test Quarantine](https://mergify.com/learn/test-quarantine), [DeFlaky: Quarantine Strategy Guide](https://deflaky.com/blog/test-quarantine-strategy-guide) |
| **Near-zero-flake bar for required gates** | Industry convergence: <1% flake rate is "excellent," <2% "very good," >5% is where developer trust in CI collapses and people start reflexively re-running red builds instead of investigating | A required gate that isn't near-zero-flake trains the team to ignore red CI — the exact failure mode a required gate exists to prevent | [Mergify: Test Quarantine](https://mergify.com/learn/test-quarantine) |
| **Architecture fitness functions / source-scan guards** | Automated, fast (seconds), static checks that fail the build when an architectural boundary (module/layer/dependency-direction) is violated — exactly `ds06_drift_guard_test.exs`'s shape | Overly broad regex/text-scan rules produce false positives on unrelated string matches (e.g. a comment containing `"_lab"` would trip a naive `refute source =~ "_lab"` guard) — rules need to be scoped tightly to the actual violation shape, not just substring presence | [Lukas Niessen: Architecture Fitness Functions](https://lukasniessen.com/blog/12-architecture-fitness-functions/), [continuous-architecture.org: Fitness Functions](https://continuous-architecture.org/practices/fitness-functions/) |
| **Storybook coverage addon (Istanbul-based)** | Line/branch coverage of *code exercised by stories* — closest ecosystem analog to D-32's "every state/domain represented" | This measures code coverage, not *state* coverage — a component can be 100% line-covered by one story and still be missing 9 of 10 D-11 states. Scoria's text-scan-for-scenario-names approach (§3a) is actually a closer fit to what D-32 asks for than the Storybook-native tool would be | [Storybook: Test Coverage docs](https://storybook.js.org/docs/8/writing-tests/test-coverage) |

**Overall ecosystem lesson for Scoria:** every mature visual-diff adoption story requires (a) a
stable component-boundary layer to diff against (Storybook or equivalent) and (b) deterministic
rendering (Docker-pinned browser). Scoria has neither yet — D-04 defers (a), and no Phase has
built (b). Adopting visual diffing before those exist would import the exact flakiness/noise
failure mode the sources above document, onto a required gate, which is the worst place for it
per the near-zero-flake bar.

---

## 3. Concrete recommendation — the exact Phase 37 proof suite

### (a) Source-scan ExUnit guards — `test/scoria_web/dev_lab_boundary_test.exs`

This is one file with independently-assertable test cases, all pure `File.read!/1` + `Regex`/
string-match (never `alias`/`import` a `dev/`-scoped module — Pitfall 1). Recommended concrete
assertions, each mapped to the requirement it proves:

| # | Assertion | Proves | Anti-false-positive note |
|---|---|---|---|
| 1 | `lib/scoria_web/router.ex` never contains `_lab` or a reference to any `DevLab`/lab module name | D-01/D-03/D-31: public macro untouched | Match the specific route-string literal `"/scoria/_lab"` or module prefix, not a bare substring `"lab"` (would false-positive on words like "collab", "label" in comments) |
| 2 | `mix.exs` `package/0`'s `files:` list contains no `"dev"` or `"priv/dev"` entry | D-02/D-31: Hex footprint untouched | Assert against the parsed list shape (`~r/"dev"(?!_)/` as in RESEARCH.md, refined to also reject `"priv/dev"` explicitly) rather than a loose substring, since `"priv/repo/migrations"` etc. must not trip it |
| 3 | `lib/scoria_web/dashboard_nav.ex` and `lib/scoria_web/components/layouts.ex` never reference the lab route/module | D-05/D-31: no public nav/command-palette link | Same literal-match discipline as #1 |
| 4 | Zero files under `lib/**/*.{ex,heex}` reference `DevLab.`/`ScoriaWeb.DevLabFixtures` (whichever prefix is chosen) | D-21: fixture data never becomes runtime truth | This is the single most important guard in the file — see §6 footgun discussion |
| 5 | All 10 canonical D-11 state names (`normal`, `long_text`, `empty`, `dense`, `disabled`, `selected`, `loading`, `warning`, `danger`, `error`) appear as literal atoms/strings somewhere under `dev/lab/**/*.ex` | D-32/LAB-02: state vocabulary coverage | Text-presence is a floor, not a guarantee every *primitive* renders every state — see the coverage-gate honesty note in §5 |
| 6 | All D-20 fixture scenario names (`approval_requested`, `incident_opened`, `dataset_empty`, etc. — the 13 named in 37-CONTEXT.md D-20) appear under `dev/lab/**/*.ex` | D-32/FIXT-01: fixture-domain coverage | Same floor caveat |
| 7 | *(stretch, optional this phase)* Every `canonical`-status `PRIM-*`/`GROUP-*` row ID from `36-inventory.json` that D-08 says the lab should reference appears as a literal string under `dev/lab/**/*.ex` | D-08/D-32 "tie to inventory IDs where practical" | This is the closest Phase 37 gets to a real coverage *manifest* rather than a fixed string list — see §5 for why this is worth the extra ~20 lines even though 37-RESEARCH.md's Open Question 2 treats it as optional |

Recommend implementing #7: it costs one more `Path.wildcard`/`File.read!` pass over the same
already-read `dev/lab/**/*.ex` corpus, reads `36-inventory.json` (already `Jason`-parseable, no
new dependency), and turns D-32's "if practical, tie coverage to inventory IDs" from aspirational
prose into an enforced contract. It is the difference between "the lab mentions 10 state words
somewhere" and "the lab has a section for every canonical-status inventory row." Given 37-RESEARCH.md
already confirms `Jason` is a dependency and inventory ID strings (`PRIM-TABLE`,
`GROUP-APPROVAL-INBOX-COMPONENT`, etc.) are meant to appear as literal evidence labels per D-29,
this is genuinely practical, not a stretch.

### (b) Playwright `lab.spec.mjs` probes

Given the Pitfall-2 reality (any `.spec.mjs` file under `priv/dev/e2e/` is **immediately** picked
up by the required `e2e` job with zero additional CI wiring), the file must be authored
defensively: every *active* assertion must be true of what ships in Phase 37, full stop.

**Active (near-zero-flake, join `ci-gate` via the existing `e2e` job automatically):**

| Probe | Why it's safe to gate | Pattern source |
|---|---|---|
| Route loads at `/scoria/_lab` and reaches `data-scoria-ready="true"` | Deterministic — no DB, no timing race, reuses the proven sentinel | `waitForReady` (`priv/dev/e2e/lib/ready.mjs`), used unmodified |
| Theme toggle (`data-theme` attribute flips light↔dark↔system) | CSS-only state change, already proven low-flake in `uat.spec.mjs`/`shots.mjs` | `setTheme` pattern in `shots.mjs` |
| `page.emulateMedia({ reducedMotion: 'reduce' })` — assert the reduced-motion indicator/label is visible | Playwright's `emulateMedia` sets a real OS-level media-query signal; `05-motion.css` already keys off it — deterministic | `phase16_parity.spec.mjs` |
| `page.setViewportSize(...)` scan across the 6 D-13 widths — assert the nav/section shell doesn't overflow horizontally at each | Pure layout assertion (e.g. `scrollWidth <= clientWidth` or no horizontal scrollbar), no animation/timing dependency | `phase16_parity.spec.mjs` |
| Dense table/list state band renders and its row count matches the fixture | Static fixture data (D-16/D-17), no DB — fully deterministic | New, but same shape as `uat.spec.mjs`'s "renders X" assertions |
| Copy-control (`[data-raw-evidence-copy]` or the lab's copy-fixture-payload control) sets the expected clipboard text or visible confirm state | Existing hook (`assets/js/scoria.js` `navigator.clipboard.writeText`), already covered structurally elsewhere — a route-load-level smoke check here is deterministic | `ui_component_test.exs` "raw evidence copy control" + `scoria.js` hook |

**`test.fixme` (registered, not silently dropped — per `docs/uat_automation.md` convention):**

| Probe | Why it's `fixme`, not active | Named unlock |
|---|---|---|
| Overlay/focus probe — drawer/modal focus trap and Escape-dismiss inside the lab's Overlays section | `uat.spec.mjs` already has an *identical* open `fixme` for the dashboard proper ("Escape key dismisses an open ui.ex overlay — needs a screen using `<.modal>`/`<.drawer>`") — until that's resolved anywhere in the app, treat the lab's version as the same open risk, not a new proven truth, unless the lab's Overlays section is the first place `<.drawer>`/`<.modal>` are wired to a working dismiss handler (likely true here since the lab IS a dedicated overlay showcase — flip to active if so, see note below) | Flip to active once the lab's own Overlays section wires `on_dismiss` for real (this may in fact land in Phase 37 itself — if so, this row moves to Active, not fixme) |
| Toast-region-over-dense-UI legibility fixture — any pixel/contrast assertion | D-30 explicitly forbids treating this as a pass/fail visual judgment in Phase 37; `RISK-TOAST-LEGIBILITY` fix is Phase 38 scope. The *fixture exists* (assert the DOM structure/labels render) but do not assert it "looks legible" — that's a human/visual-critique judgment, not a CI truth | Phase 38 lands the actual toast-legibility fix; a real contrast/legibility assertion can be authored then against the fixed CSS |
| Command-palette curated flow probe (open via `⌘K`, search, select) | Only include if D-10's curated command-palette probe actually ships as an interactive flow in Phase 37; if it's static (renders the palette fixture but doesn't wire real keyboard search), `fixme` until wired | Flip when the lab's command-palette probe is interactive, not just a static render |

The rule from `docs/uat_automation.md` applies without modification: **never a bare
assertion expected to fail — everything not fully proven is `test.fixme('<reason> — <unlock>')`.**
This is not a Phase-37-specific policy; it is the existing repo convention, and the lab file must
follow it exactly like `uat.spec.mjs` does today.

### (c) Advisory / local-only vs. `ci-gate`

| Surface | Tier | Why |
|---|---|---|
| `dev_lab_boundary_test.exs` | **`mix test`, required (already gated via the `verify` reusable workflow → `ci-gate`)** | Pure text-scan, zero DB/browser dependency, sub-second runtime — this is exactly the profile of a required gate: fast, deterministic, structural |
| `lab.spec.mjs` active probes | **`priv/dev/e2e/`, required (already gated via the `e2e` job → `ci-gate`, automatically)** | No opt-out exists structurally (Pitfall 2) — the only lever is *which assertions are active*, not *whether the file is required*. Keep the active set to the near-zero-flake list in §3b |
| `lab.spec.mjs` `test.fixme` probes | **Registered but non-executing** — visible in the Playwright report, does not block | Matches existing `uat.spec.mjs` convention exactly |
| Toast-legibility / dense-UI *visual judgment* | **Manual-only**, per 37-VALIDATION.md's own "Manual-Only Verifications" table (`make dev` + walk the lab) | D-30 explicit prohibition; this is the correct home, already documented in 37-VALIDATION.md |
| `mix scoria.ui.shots` extended to cover `/scoria/_lab`, if ever added | **Advisory, local-only (`make shots`/`make critique`), never `ci.yml`** | Matches the existing dashboard screenshot harness's own placement exactly — not new policy, just don't regress it by accidentally wiring shots into CI while touching this area |
| Any future screenshot-diff step (`VISUAL-CI-01`) | **Not built this phase.** When built, must land as a genuinely non-blocking job — a separate GitHub Actions `job:` with no entry in `ci-gate`'s `needs:` list, or (if inside an existing required job) an explicit `continue-on-error: true` step | See §6 for why "advisory" must be structural, not just a code comment — Scoria's own `ci-verify.yml` has a step literally labeled "(advisory)" that is **not** actually non-blocking today (see §6) |

**Justification against the near-zero-flake bar:** both guard-test and e2e-probe placements above
already satisfy the "would I bet developer trust in CI on this" test — the guard tests are
deterministic string matches with no environment sensitivity, and the *active* e2e probes are
restricted to exactly the assertion types 37-RESEARCH.md's own Pitfall list and the ecosystem
table in §2 identify as low-flake (readiness-sentinel-gated route loads, CSS-only theme swaps,
`emulateMedia`, `setViewportSize`, static-fixture-backed DOM assertions). Nothing pixel-diff-based
is proposed as active, which is the actual mechanism D-30 is warning against.

---

## 4. DX guarantees — the 1-command local proof habit

Phase 37 should ship a maintainer proof habit with the same shape as the existing
`mix test --warnings-as-errors` / `mix scoria.ui.e2e` two-liner in `docs/uat_automation.md`.
Concretely:

```sh
# Fast local proof (structural — seconds)
mix test --no-start test/scoria_web/dev_lab_boundary_test.exs

# Full local proof (structural + browser — after `make dev` is already running)
make dev
mix scoria.ui.e2e --base-url http://localhost:4799/scoria
```

Both commands already exist in the repo's proof vocabulary — Phase 37 adds no new mix task, no
new CI step, no new script. This is a deliberate DX win worth calling out explicitly in
`docs/MAINTAINERS.md` (D-34): a contributor who already knows "`mix test` + `mix scoria.ui.e2e`
is how I prove a phase" gets lab coverage for free by that same habit, because the new files slot
into the existing `test/` and `priv/dev/e2e/` discovery mechanisms without any new invocation
syntax to learn.

### D-34 docs shape — map probes to Phases 38-41

`docs/MAINTAINERS.md`'s new "Component Lab" section should include a table (mirroring the shape
already used for the CI lane map elsewhere in that doc) that makes the lab legible as
infrastructure for *later* phases, not just this one:

| Lab section / probe | What it proves today (Phase 37) | What it will support later |
|---|---|---|
| `Foundations` | Tokens/type/spacing/motion render as declared | Phase 38 DS-02/DS-03 typography-weight-drift fixes — the lab is where the fix gets visually confirmed |
| `Primitives` × state bands | Every `ScoriaWeb.UI` primitive renders across all 10 D-11 states | Phase 38's shared-control changes get regression-checked by eye against the same matrix |
| `Groups` | Recurring component groups (approval inbox, workflow tree, connector drawer, evidence notebook) render with realistic + ugly fixture data | Phase 39's approval-decision-history feature reasons from the `workflow_waiting_for_approval`/decided-approval fixtures already staged here |
| `States` (reusable band renderer) | Canonical state vocabulary is enforced at the rendering layer, not just by convention | Anchors any later automated coverage tooling (a stronger `dev/mix_tasks/` semantic check, if ever built) to one render path |
| `Viewports` | 320-1440+wide widths are inspectable without a second app | Phase 40 (if it targets `RISK-RESPONSIVE-SCAN`) verifies fixes against the same six widths |
| `Overlays` | Drawer/modal/toast/command-palette/mobile-nav focus and dismissal are inspectable in isolation | Directly feeds `RISK-OVERLAY-FOCUS`; Phase 38's toast-legibility fix (`RISK-TOAST-LEGIBILITY`) gets its "before" state from this section's dense-toast fixture |
| `Fixtures` | Maintainers can browse/copy the raw fixture catalog | Contributors extending fixture domains (new domain nouns) have one file (`dev/lab/fixtures.ex`) to edit, discoverable from this section |
| `test.fixme` entries in `lab.spec.mjs` | Explicitly documents what's *not yet* proven, and why | Each `fixme` names its own unlock condition — Phase 38-41 planning can grep `lab.spec.mjs` for `fixme` to find exactly which browser truths are still owed |

Also document explicitly (D-34 requirement): how to start the dev server (`make dev`), open the
lab (`http://localhost:4799/scoria/_lab`), inspect states (walk the nav rail), update fixtures
(edit `dev/lab/fixtures.ex`, never `lib/`), run focused proof (the two commands above), and —
critically — a one-paragraph explanation of *why* there's no screenshot-diff step, linking to
this decision doc or `VISUAL-CI-01`'s REQUIREMENTS.md entry, so a future contributor doesn't
"helpfully" wire one in without re-litigating the tradeoff in §1.

---

## 5. Coverage-gate classification (D-30..D-34)

| Decision | Classification | One-line statement | Verification method |
|---|---|---|---|
| **D-30** | **`must_haves.prohibitions`** | "No screenshot-diff step is added to the required `ci-gate` (via `verify` or `e2e`) in Phase 37." | Assert `.github/workflows/ci.yml` and `.github/workflows/ci-verify.yml` contain no new job/step invoking a visual-diff tool (`toHaveScreenshot`, Percy, Chromatic, BackstopJS, or equivalent) — a guard test reading both workflow files as text and asserting absence of those tool names, OR (lighter-weight) a manual diff-review note in the phase's VERIFICATION.md confirming no such job was added. Given this is a *negative* infra claim rather than a source-code boundary, a one-line CI-diff check in `VERIFICATION.md` is proportionate; a full guard test is optional, not required, since `ci.yml`/`ci-verify.yml` changes are already reviewed in every PR diff. |
| **D-30 (positive half)** | **`must_haves.truths`** | "The lab renders at `/scoria/_lab`, covers all 10 D-11 states and all required D-20/D-19 fixture domains, stays dev-only, and preserves the Hex/public-macro boundary." | `mix test test/scoria_web/dev_lab_boundary_test.exs` (guards #1-6, §3a) + `mix scoria.ui.e2e` active probes (§3b) — both already run in required CI lanes, so this is enforced automatically, not just documented |
| **D-31** | **`must_haves.prohibitions`** | "The lab is not reachable through `scoria_dashboard/2`, not shipped via `package.files`, and not linked from public dashboard nav or the command palette." | `dev_lab_boundary_test.exs` guards #1-3 (§3a) |
| **D-32** | **`must_haves.truths`** (with an explicit note that text-presence is a coverage *floor*, not a rendering guarantee) | "Every canonical D-11 state name and every D-20 fixture-domain scenario name is present in `dev/lab/**/*.ex` source, and canonical-status Phase-36 inventory row IDs referenced by the lab are represented." | `dev_lab_boundary_test.exs` guards #5-7 (§3a). **Honesty caveat to carry into any downstream plan:** a string-presence assertion proves the *word* exists in the file, not that a given primitive *actually renders* in that state at runtime — Phase 37 planning should note this is intentionally a cheap/fast floor (per D-32's own "if practical" framing and the compile-boundary constraint in Pitfall 1), not a substitute for the human walkthrough in 37-VALIDATION.md's Manual-Only table |
| **D-33** | **[informational]**, with the specific active/`fixme` split promoted to `must_haves.truths` per-probe | "Browser proof (`lab.spec.mjs`) is deterministic and advisory-scoped to Phase 37: route load, theme, reduced motion, viewport scan, dense-table rendering, and copy controls are active assertions; overlay-focus/toast-legibility/command-palette-interactivity are `test.fixme` until their named unlock lands." | D-33 itself is a design principle (advisory-vs-active split), not a single boolean fact — classify the principle as informational context for planners, but each *individual probe's* active/fixme status is a `must_haves.truths` line item verified by `mix scoria.ui.e2e` output (active probes pass, fixme probes are listed as fixme, not silently absent) |
| **D-34** | **[informational]** for the phase's own must-haves (docs aren't a runtime truth), but **`must_haves.truths`** if the phase wants doc completeness enforced | "`docs/MAINTAINERS.md` documents how to start the dev server, open the lab, inspect states, update fixtures, run focused proof, and how each lab section maps to Phases 38-41." | If enforced: a guard test asserting `docs/MAINTAINERS.md` contains the lab section heading + the two proof commands from §4 (cheap, same shape as existing `ui_component_test.exs` "dashboard theme and CSS source contracts" tests that already assert on `docs/MAINTAINERS.md` content). If not enforced: leave as a plan checklist item reviewed at `/gsd-verify-work` time |

---

## 6. Footguns specific to Scoria

### 6a. The required-gate e2e trap — confirmed structurally true, not hypothetical

37-RESEARCH.md's Pitfall 2 is exactly right and deserves reinforcement: `priv/dev/e2e/`'s
`playwright.config.mjs` is `testDir: '.', testMatch: '**/*.spec.mjs'`-driven, and `ci.yml`'s `e2e`
job runs `mix scoria.ui.e2e` unconditionally, feeding `ci-gate` via `needs: [verify, e2e]`. There
is no staging lane — the moment `priv/dev/e2e/lab.spec.mjs` exists with a single bare (non-fixme)
assertion, it gates every PR in the repository, not just lab-related PRs. Concretely: if a
contributor commits `lab.spec.mjs` with the Overlays probe active before the lab's Overlays
section actually wires `on_dismiss`, every unrelated PR (e.g. a knowledge-lane bugfix) starts
failing `ci-gate` with a Playwright timeout that has nothing to do with what that PR touched.
**Mitigation:** author `lab.spec.mjs` in the *same commit* as the lab sections it probes, run
`mix scoria.ui.e2e` locally against `make dev` before pushing (already the documented workflow in
`docs/uat_automation.md`), and default every probe whose underlying feature isn't 100% certain to
`test.fixme` rather than active — it is always cheaper to promote a `fixme` to active in a
follow-up commit than to revert a red required gate.

### 6b. "Advisory" as a label vs. "advisory" as a structural guarantee — Scoria already has a
near-miss of this exact confusion

`.github/workflows/ci-verify.yml`'s `connector` job has a step literally named "Run support
copilot gallery lane (advisory)" (`mix scoria.test.support_copilot`) — but that step has **no**
`continue-on-error: true`, and the `connector` job feeds `verify-summary`'s `needs:` list
(`needs: [policy, build, test, ratchet, knowledge, connector, full-suite]`), which fails outright
if any dependency result isn't `success`. In other words: today, if `mix scoria.test.support_copilot`
fails, the entire required `verify` workflow fails, and `ci-gate` fails — despite the step's own
name promising "advisory." This is a live example in this exact repo of the trap D-30/D-33 are
trying to avoid: a comment or job name that *says* "advisory" without the CI topology *enforcing*
non-blocking behavior.

**Direct implication for Phase 37 and any future `VISUAL-CI-01` work:** if a maintainer ever adds
a visual-diff step under a comment like `# advisory — visual regression, not yet gating`, that
comment is **not sufficient**. It must be either (a) a separate top-level job with no entry in
`ci-gate`'s `needs:` array, or (b) a step carrying literal `continue-on-error: true` inside an
existing job, with the job's own success/failure logic (like `verify-summary`'s `if [[ "$result"
!= "success" ]]` pattern) explicitly excluding that step's outcome. Recommend filing a follow-up
(outside Phase 37's scope, but worth a `Reviewed, not folded` note) to either add
`continue-on-error: true` to the existing `support_copilot` "(advisory)" step or rename it to
stop claiming a guarantee the topology doesn't provide — this is a correctness bug in the CI
config independent of Phase 37, but Phase 37's own docs (D-34) should not repeat the same mistake
when explaining what "advisory" means for the lab's own proof surfaces.

### 6c. Snapshot rot (pre-emptive, since no snapshots exist yet)

Not yet applicable — Phase 37 adds no snapshot baselines. Flagging pre-emptively for whoever picks
up `VISUAL-CI-01`: the `ds06_drift_guard_test.exs` baseline-staleness test (`WR-01`, "baseline is
not stale") is the right *pattern* to reuse if a visual baseline is ever committed — a stale image
baseline (one that's higher-tolerance than the current rendered state) has the exact same
one-way-ratchet failure mode as a stale palette-count baseline: it silently allows regressions
back up to the old, worse value. Any future visual-diff baseline needs the equivalent of DS-06's
two-test pattern (regression check + staleness check), not just a regression check.

### 6d. Gating coverage too rigidly — the D-32 text-scan floor

The recommended `dev_lab_boundary_test.exs` guards #5/#6 (state-name and scenario-name string
presence) are deliberately loose: they prove a word appears in `dev/lab/`'s source text, not that
every `ScoriaWeb.UI` primitive renders every state, or that every fixture scenario is wired to a
visible section. This is a conscious tradeoff (matching 37-RESEARCH.md's Open Question 2
recommendation to start with text-regex) — the alternative (parsing the actual lab section tree
at runtime) requires a `dev/mix_tasks/`-scoped Elixir check that can't run inside `mix test`
(Pitfall 1), adding real complexity for marginal precision gain in Phase 37. **The footgun is
treating this floor as if it were a ceiling** — a future contributor (or agent) seeing "coverage
guard tests: green" might assume full rendering coverage is proven, when only string-presence is.
Recommend the guard test's own `@moduledoc` say so explicitly (mirroring how
`token_contrast_guard_test.exs`'s moduledoc says "a floor, not a replacement for visual review"),
and that 37-VALIDATION.md's Manual-Only Verifications table (already present, already correctly
scoped) remains the documented complement — do not let a future phase quietly delete the manual
walkthrough step because "the guard tests already cover it."

### 6e. Fixture leakage as a slow-burn footgun, not just a compile error

Pitfall 5 in 37-RESEARCH.md (D-21 fixture leakage) is framed as "guaranteed compile error outside
`:dev`" — true for an *unconditional* reference, but note the escape hatch it names:
`Code.ensure_loaded?(DevLab.Fixtures)`-style lazy/conditional loading would compile fine
everywhere and only fail at *runtime* in a host app's `:prod` env, potentially long after the
introducing PR merged. The `dev_lab_boundary_test.exs` guard #4 (zero `lib/` references to the
fixture module) is the correct structural defense specifically *because* it catches this pattern
too (a `Code.ensure_loaded?(DevLab.Fixtures)` string literal still matches the module-name regex)
— worth calling out in the guard test's own comments so a reviewer understands the guard isn't
just "catch a typo," it's "catch a deliberate-looking but broken lazy-load pattern."

---

## Summary for the maintainer

- **D-30 holds.** No visual-diff CI gate in Phase 37. The repo's own 25+-phase history
  (`shots.mjs` staying advisory) and the ecosystem evidence (visual diffing needs a stable
  component boundary + deterministic renderer, neither of which exists yet) both support this.
- **Ship one guard-test file** (`test/scoria_web/dev_lab_boundary_test.exs`, pure text-scan, 7
  assertions incl. the inventory-ID cross-reference) and **one e2e spec**
  (`priv/dev/e2e/lab.spec.mjs`, ~6 active near-zero-flake probes + 2-3 `test.fixme` entries).
  Both slot into already-required CI lanes with zero new CI/task wiring — this is a feature of
  the existing topology, not something Phase 37 needs to build.
- **The single most important operational discipline:** every `lab.spec.mjs` assertion must be
  true of what ships in the same commit — there is no advisory lane for `priv/dev/e2e/`
  structurally, so `test.fixme` is the only safety valve, and it must be used liberally for
  anything not fully wired.
- **A real, live example already exists in this repo** (`ci-verify.yml`'s mislabeled "(advisory)"
  connector step) of "advisory" as a comment failing to be "advisory" as CI behavior — Phase 37's
  own docs and any future `VISUAL-CI-01` work must not repeat it.
- **`VISUAL-CI-01` promotion criteria** (for whoever picks it up, likely Phase 41): lab IA
  stable, Docker-pinned deterministic renderer, a multi-week advisory trial with measured <2%
  flake rate, a named baseline-review owner, and an explicit phase scope — not an unplanned
  mid-phase addition.

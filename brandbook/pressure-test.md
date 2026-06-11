# Scoria Brand Book Pressure-Test Audit

**Audit version:** 1.0 — Phase 18 (v2.17 Vesicle)
**Brand book audited:** `prompts/scoria-brand-book-deep-research.md` v0.1
**Auditor posture:** senior brand systems director / product designer / design-token architect / Elixir OSS practitioner
**Suite lens:** szTheory ecosystem (`prompts/sztheory-elixir-dna.md`) + Threadline precedent (`/Users/jon/projects/threadline/brandbook/`)
**Scope (this document):** Sections 1–7 of the canonical 14-section audit. Sections 8–14 and Decisions Locked are in 18-02.

---

## SECTION 1 — Executive judgment

**Is it strong enough to build from?** Yes, clearly. This is one of the more complete AI-generated brand books I have seen for an OSS library. It has a specific conceptual center (volcanic clarity, porous structure, field-engineer archetype), a coherent palette with justifiable hex values, an actual two-tier type system, semantic color roles, voice examples, and a micro-copy lexicon. Most OSS library brand books are six paragraphs and a mood board. This one is 1,618 lines with implementation-level detail in typography, token structure, component anatomy, trace-explorer color mapping, and landing-page copy. The shipped `assets/css/02-tokens.css` confirms the system is actually being built.

**Is it distinct enough?** Conditionally yes. The volcanic metaphor is genuinely uncommon in the Elixir devtools space. Langfuse, Arize Phoenix, and Braintrust all look like modern blue-purple SaaS. Scoria's dark-basalt-first, warm-accented, field-engineer aesthetic puts it in a different register — closer to Phoenix LiveDashboard and Oban Web than to an AI startup. The risk is that the distinctiveness depends entirely on the metaphor being executed well. If the actual logo ends up as a generic polygon and the color system drifts to generic dark-mode grey, the volcanic idea evaporates. The concept is strong; execution is the threat.

**Is it implementation-ready?** Mostly. Palette and typography are production-ready. Token structure is tokenizable but exists only as a brand-book spec; `assets/css/02-tokens.css` is the only shipped implementation and it is a strong start. What is missing for full implementation readiness: (1) the logo does not exist yet (four concept directions, none executed), (2) the brand book does not specify a minimal SVG structure or favicon simplification rule beyond "3–5 holes at small sizes," (3) semantic state tokens for focus, disabled, selected, and hover exist conceptually but are not exhaustively listed.

**Is it over-specified, under-specified, or balanced?** Balanced with a slight lean toward over-specified in places that don't need it (Section 8 UI component anatomy, Section 12 motion personality — these are implementation details that belong downstream) and under-specified where it matters most: logo execution, favicon test, and the exact propagation path between the brand-book palette and the shipped tokens. Sections 1–7 are excellent; Sections 8–17 start to feel like a UI guide that belongs with the shipped components, not the brand book.

**Highest-leverage improvement:** Execute and commit the logo. Everything else is opinion until there is a mark. The contrast checker confirms no shipped pairings fail WCAG AA — the color system is sound — so the logo is the single most unblocked and highest-ROI thing. Once the mark exists, the favicon test, social-card test, README header test, and monochrome-survival test all become answerable. Right now they are guesses.

**What should absolutely NOT change:**
- The "volcanic not fiery" brand archetype and the specific prohibition on phoenix birds, flames, and robots.
- The dark-first color strategy with warm scoria/ember accents — it is genuinely different and the token system already implements it correctly.
- The voice formula: calm + exact + useful. The microcopy examples in §7 are the strongest section; "Running support_agent: rendering prompt, calling model, waiting for tool result" over "The AI is thinking" is exactly right.
- The "Scoria" name (never "Scoria AI") and the "field engineer" archetype — both are specific enough to guide real decisions.
- The IBM Plex Sans + JetBrains Mono type pairing — correct choice, no reason to change.

**What is up for discussion (TIGHTEN-level, not REWORK):**
- The tagline. "Trace the run. Prove the change. Ship the agent." is strong but a bit long for the most prominent placement. "AI ops for Phoenix apps." is cleaner as the hero headline, with the longer form as the second-hit subheadline. The audit section on taglines should confirm the preferred hierarchy.
- The secondary lockup includes "AI ops for Phoenix" as a subtitle — but §4.4 says no subtitle in the main lockup. That is a small internal contradiction to clean up.
- The one-liner ("Scoria is the Phoenix-native AI ops layer for...") could be sharpened. The brand-book version is accurate but reads like a spec, not a hook.

---

## SECTION 2 — Brand DNA extraction

**Brand essence**
Volcanic clarity for production AI systems. AI runs are porous; Scoria makes the structure visible.

**Audience**
Phoenix/Elixir backend engineers building chat, copilots, RAG, tool-using agents, or MCP workflows. Specifically: small teams, indie engineers, and platform/SRE engineers who need to debug, replay, and govern AI behavior in production — not enterprise compliance buyers, not AI researchers, not Python-first developers. The szTheory DNA confirms an "operator-first DX" bias: solo entrepreneurs and small teams who want batteries-included tooling with observable, auditable defaults.

**Emotional tone**
Grounded. Composed. Operator-grade. The emotional target is "calm during an incident." Not exciting. Not aspirational. Reliable. The product should feel like the person who catches the regression before it ships, not the person who promises to eliminate regressions forever.

**Technical promise**
Scoria makes Phoenix AI behavior observable, evaluable, replayable, and governable without adding a black-box dependency. Traces, spans, prompt versions, eval datasets, tool approvals, and cost/latency numbers are first-class citizens — not afterthoughts in a logs tab.

**Visual metaphor**
Volcanic scoria rock: dark, porous, pressure-formed, with visible internal structure (vesicles). The cavities map to the internal structure of an AI run: prompt renders, model calls, tool calls, retrieval events, guardrails, eval scores. The mark should show a cinder fragment with negative-space holes, not an erupting volcano.

**Personality traits**
- Grounded: claims are evidence-based; the UI shows traces, scores, costs, versions, policies
- Composed: stays calm when runs fail, tools are blocked, or evals regress
- Operator-grade: built for production debugging, not demos
- Open-source practical: clear docs, copy-pasteable examples, no corporate fog
- Volcanic not fiery: warmth and texture are allowed; flames and lava gimmicks are not
- Technical but humane: uses real terms (trace, span, scorer, baseline, policy) and defines them

**Anti-traits**
[explicitly stated in brand book]
- Magical / autonomous-feeling
- Hype-coded ("revolutionary," "10x," "sentient")
- Phoenix-bird or flame imagery
- Generic AI aesthetics (neon blue-purple, glassmorphism, sparkles)
- Black-box oracle positioning
- Enterprise compliance drag

**Design principles**
1. Evidence over intuition — every claim points to a trace, score, cost number, or policy
2. Visible structure — show the run tree, tool calls, approvals, what changed
3. Production before spectacle — reliability, replay, governance sell before "cool agents"
4. Phoenix-native not Phoenix-branded — built for Phoenix but doesn't borrow its visual identity
5. Calm heat — warm, dark, high-contrast but never aggressive or crypto-coded

**Voice principles**
1. Say what happened — specific diagnostics over vague errors
2. Prefer evidence verbs — traced, scored, compared, replayed, promoted, gated, approved, denied
3. Do not anthropomorphize the model — "Running support_agent" not "The agent is thinking"
4. Do not expose hidden chain-of-thought — show process summaries, not private reasoning
5. Make safety and governance normal — tool approval is part of the workflow, not an alarm

**This should feel like**
- Phoenix LiveDashboard
- Oban Web
- A trace waterfall
- A lab console
- A field notebook during a production incident
- A control room that is calm during incidents
- An SRE who understands evals

**This should never feel like**
- A chatbot toy
- A generic AI SaaS dashboard
- A crypto console
- A sci-fi HUD
- A BI dashboard with rainbow charts
- A startup that promises to "revolutionize" AI
- Arize Phoenix, Langfuse, or Braintrust (competitors to differentiate from)

---

## SECTION 3 — Pressure-test scorecard

| Dimension | Score | Why | Risk | Recommended fix |
|---|---:|---|---|---|
| Distinctiveness | 8 | The volcanic metaphor is genuinely uncommon in Elixir AI tooling. "Field engineer, not oracle" separates it from the competitor cluster. Dark-basalt-first aesthetic is different. | Depends entirely on execution. A generic polygon mark or blue-drifting palette collapses the differentiation instantly. | Commit the logo mark. Keep the color-discipline rule explicit: no neon, no blue-purple, no glassmorphism. |
| Developer credibility | 9 | Voice is precise, low-hype, and grounded in real technical artifacts. Microcopy examples ("Running support_agent: rendering prompt, calling model...") are excellent. Brand explicitly prohibits "hallucination-free," "revolutionary," "fully autonomous." | Landing page copy can slip into SaaS-speak if edited by non-technical collaborators. | Add a voice-drift checklist to the brand book. Keep §7 microcopy examples as the canonical anchor. |
| Elixir ecosystem fit | 9 | Phoenix-native positioning is explicit and accurate. Type choice (IBM Plex Sans) is consistent with Threadline and the broader szTheory style. Embedded LiveView dashboard, Ecto-native state, and telemetry hooks match the szTheory Architectural DNA perfectly. | Risk of looking "too SaaS-like" if the landing page over-invests in hero imagery vs. code examples. | Lead with code snippets and real UI crops in README and docs. The brand book already says this; enforce it at execution. |
| Visual coherence | 7 | Palette, type, and metaphor are aligned. Component anatomy, trace-explorer color mapping, and badge palette are all consistent. | Multiple sections describe overlapping surface guidance without a clear hierarchy: §4 (logo), §5 (color), §8 (UI), §10 (imagery) partially contradict each other on surface priority. | Add a single "visual precedence ladder": mark > palette > typography > iconography > texture. Surfaces follow, not lead. |
| Logo readiness | 4 | Four concept directions are well-described conceptually. The porous-cinder-mark idea is exactly right for the brand. | **No mark exists yet.** Four directions is three too many without execution. The favicon test, sidebar test, monochrome test, and social-card test cannot be answered. | Phase 19 must produce at minimum the Cinder Mark and Trace Vesicle Mark as committed SVG, tested at 16px. The audit's Section 8 should rank the four directions. |
| Color-system readiness | 9 | Two-tier token structure (primitive + semantic) is implemented in `assets/css/02-tokens.css`. Dark-default with light re-point is architecturally correct. All shipped semantic pairings pass at minimum PASS-LARGE; no FAIL. Warm accents (#E65A32, #FF7A4D) are distinct and calibrated. | `--scoria-text-subtle` (#88786D Pumice-500) is PASS-LARGE (4.29–4.48:1) across all surfaces — it fails normal-text AA by a small margin. If it is used for body text it is an accessibility defect; if used only for muted labels and UI elements it is acceptable. | Clarify the semantic role of `--scoria-text-subtle` in the brand book: "UI components and large muted labels only; do not use for running body text." Document that it is intentionally below normal-text AA. |
| Typography readiness | 9 | IBM Plex Sans + JetBrains Mono is the correct pairing. Type scale covers marketing and product UI with realistic size ranges. Weight selection is restrained. | Brand book lacks explicit type tokens for the product dashboard beyond the narrative description. | Add `--scoria-fs-*` token mapping to the type-scale table. `assets/css/02-tokens.css` already defines these; they just need to be reflected back into the brand book. |
| Design-token readiness | 8 | `assets/css/02-tokens.css` is ahead of most OSS brand books at this stage: primitive + semantic, two-tier, carbon-contextual light/dark model, tone family, state tokens. | Token file lacks explicit state tokens (focus, disabled, selected) and code-block / callout tokens. These gaps may cause inconsistency in the doc site build. | Add state and code-block tokens in Phase 21. Section 7 of this audit specifies the direction. |
| UI component readiness | 6 | Buttons, cards, badges, trace explorer, and eval workbench are described with enough specificity to implement. | Component guidance is spread across §8 (buttons), §8.3 (cards), §8.7 (badges), §8.8 (trace), §8.9 (eval), §9 (iconography) — no single-component-spec table. Dark-mode-only components are described but light-mode variants are not always specified. | Not a blocker at this stage. When Phase 21 builds `tokens.css`, add a component usage table. The brand book does not need to be a Storybook. |
| Docs/README usefulness | 8 | §14 (docs identity) has a working README title block, docs IA, tone guidance, and good-docs-phrases / bad-docs-phrases examples. §7.6 (documentation style) has a concrete copy+explain pattern. | The README hero section is described but not rendered. There is no spec for README badge style or ExDoc theme direction. | Add a README badge style rule (which badges, what order, whether to use shields.io or Hex.pm native). Low effort, high practical value. |
| Marketing usefulness | 8 | §13 (landing page) and §20 (final copy set) are detailed and copyable. The flywheel ("Capture → Annotate → Promote → Evaluate → Compare → Gate → Deploy → Monitor") is a genuinely useful visual structure. The "do not" list is specific and enforced. | No social-card spec beyond §17.1 description. Conference-slide guidance is a single line. | Not urgent. Social-card is a Phase 22 concern; conference slide is Phase-21-adjacent. |
| Voice/microcopy usefulness | 9 | This is the strongest section. §7.5 microcopy examples are production-ready for the current implemented screens (run status, tool approval, eval regression, redaction, replay). The "say this / not this" examples throughout §7 are concrete and specific. The word bank (§7.4) is one of the best I have seen in an OSS brand book. | New surfaces (CLI output, MCP gateway UI, dataset builder) will need voice examples. The current examples are dashboard-focused. | Add voice examples when surfaces ship. The existing §7 examples are the correct anchor; future additions should follow the same structure. |
| Accessibility | 6 | The brand-book text calls for WCAG AA. The shipped token pairs all pass (see Section 7 contrast table). IBM Plex Sans is legible and license-safe. | `--scoria-text-subtle` (#88786D) is PASS-LARGE on all surfaces (4.06–4.48:1 depending on surface), not PASS-AA. This is a **shipped accessibility concern** for any use of the subtle text role in normal-size body text. §18 (accessibility) commits to WCAG AA but does not acknowledge this known-boundary pair. The brand book also lacks non-color status guidance for badges and trace spans. | (1) Clarify text-subtle usage: PASS-LARGE is acceptable for muted UI labels and secondary metadata, not running text. (2) Add a non-color-status rule for trace spans and badges: every state must have a text label, not just a color fill. |
| Repo/source-control readiness | 7 | The brand book explicitly commits to `brandbook/` as the canonical source. Token CSS is committed. The budget constraint (<500KB total) is documented. | `brandbook/` does not yet exist (this plan creates it). The brand book's §5.7 has raw CSS tokens that partially overlap with `assets/css/02-tokens.css` — the relationship between the two is undocumented. | Document that `assets/css/02-tokens.css` is the upstream source; `brandbook/tokens.css` (Phase 21) will be the downstream export for non-dashboard consumers. |
| Long-term maintainability | 7 | The brand book acknowledges the szTheory multi-library context. The BRAND-09 conditional (only touch `assets/css/02-tokens.css` on material failures) is the right policy. Token naming is consistent and stable. | Brand book is a 1,618-line monolith. Once committed to `brandbook/brand-book.md` it will be hard to update incrementally. The audit document (this file) will be the primary navigation aid for future maintainers. | After Phase 21 brand-book rewrite, keep the core identity sections (1–7) in a compact `brand-book.md` (~500 lines) and move deep-dive UI guidance to separate `ui-guide.md` and `voice-guide.md` files. |

---

## SECTION 4 — Stress tests

### GitHub repo header
**Brand book guidance:** Adequate. §17.2 specifies mark + one-line descriptor + dark background + subtle vesicle texture + no product screenshots unless readable.
**Gap:** No spec for the GitHub Open Graph image dimensions (1280×640) or the exact text layout. The mark doesn't exist yet, so the header is blocked on Phase 19.
**Verdict:** TIGHTEN — add OG image dimension spec; add a "lock in the mark first" note. The copy is ready: "Scoria / Phoenix-native AI ops / traces · evals · prompts · tools · MCP."

### README hero section
**Brand book guidance:** Good. §14.1 has a working README title block with a code example. §14.3 tone guidance is specific.
**Gap:** The README hero should show the elixir code snippet as the *visual lead*, not a logo. The brand book's emphasis is on the product UI hero (§10.4), which is right for the landing page but not for a GitHub README. OSS README heroes on dark projects typically render better with a compact horizontal logo + one-line description + version/CI badges + Elixir code snippet.
**What to add:** Specify that the README hero is: `[logo-horizontal.svg] Scoria` as `<img>`, then one-liner, then badges, then `mix deps.get` snippet, then 5-line `Scoria.run/2` example. No hero image in the README body.
**Verdict:** TIGHTEN — split "landing page hero" guidance from "README hero" guidance.

### README badges
**Brand book guidance:** Missing. Not covered.
**Gap:** No badge stack specified. Critical for OSS credibility on Hex.pm repos.
**What to add:** `hex.pm version` + `CI` + `License` + optionally `HexDocs`. Standard shields.io style. No custom badge colors. Keep to the left, in this order.
**Verdict:** ADD — one paragraph, under §14.

### Hex.pm package page
**Brand book guidance:** Present but light. §14.1 has a title block. §14.2 has IA.
**Gap:** Hex.pm renders the README as the package page; no special Hex.pm-specific assets needed beyond a correct `description:` in `mix.exs`. The brand book does not specify the `description:` field format (140 chars max, plain text only).
**What to add:** Specify `description:` field: "Phoenix-native AI ops: traces, evals, prompt versions, replay, tool governance, and MCP workflows." (77 chars, stays within Hex.pm's display.)
**Verdict:** TIGHTEN — add the Hex.pm description field spec.

### HexDocs page
**Brand book guidance:** §14 covers docs tone but not HexDocs visual identity.
**Gap:** HexDocs uses ExDoc and supports custom themes via `:extras` and `:before_closing_head_tag`. Scoria should have a simple ExDoc custom CSS that applies the `--scoria-*` font tokens and maybe a subtle color hint, but not a full redesign. The brand book does not mention ExDoc at all.
**What to add:** Note in Phase 21 token plan: ship a minimal `priv/static/hexdocs.css` that sets `--ex-doc-*` font overrides to IBM Plex Sans + JetBrains Mono. Avoid touching colors until the ExDoc theme API stabilizes.
**Verdict:** ADD — minimal ExDoc font override note.

### Docs sidebar
**Brand book guidance:** §8.1 mentions sidebar mark at 24px minimum. No sidebar-specific guidance.
**Gap:** The sidebar mark test is blocked on Phase 19 (mark doesn't exist). Beyond the mark, the sidebar brand expression is: correct font tokens, active-state in Ember-500 or Scoria-600 (for light), correct heading weights.
**Verdict:** TIGHTEN — confirm sidebar is mark-only (24px) + font tokens; no color splashing.

### Code block styling
**Brand book guidance:** §8.1 ("lab console") implies dark code blocks. §6.2 specifies JetBrains Mono. No token for code-block surface.
**Gap:** Code blocks are a critical trust surface for an Elixir library. The brand book does not specify: code-block background token, syntax highlight palette, Elixir-specific token colors (keywords, atoms, modules, strings).
**What to add in token spec:** `--scoria-code-bg`, `--scoria-code-border`, `--scoria-code-text` tokens. Syntax highlight: atoms in Fumarole (#7DD8D1), strings in Cinder (#F8D6C8), modules in Ash (#FAF5EF), keywords in Molten-400 (#FF7A4D), comments in Pumice-500 (#88786D).
**Verdict:** ADD — code-block token section. High value for HexDocs and README code examples.

### Terminal snippet
**Brand book guidance:** §7.6 has a copy-paste code example. No terminal styling spec.
**Gap:** Terminal snippets (e.g., `mix scoria.install`, `mix scoria.eval`) need a minimal dark-terminal treatment: dark background (#11100F or #0C0B0A), prompt in Ember-500, command in Ash-50, output in Pumice-500. No fake dramatic output.
**Verdict:** ADD — terminal snippet token spec under Section 7.

### API reference page
**Brand book guidance:** §14.2 has a docs IA with a reference section.
**Gap:** HexDocs API reference is ExDoc-generated. The brand expression here is entirely through font tokens + minimal color. The brand book does not need to specify this further.
**Verdict:** KEEP — ExDoc handles this; brand expression via font tokens is sufficient.

### Landing page hero
**Brand book guidance:** Very strong. §10.4 hero image direction is specific (dark LiveView trace explorer emerging from porous scoria surface, headline left, product UI right with a run tree). §13 has a complete landing page structure. §20 has the final copy set.
**Gap:** The hero requires a real product screenshot. This is a Phase 22 concern.
**Verdict:** KEEP — excellent guidance, blocked on having the real UI to photograph.

### Feature section
**Brand book guidance:** §13.1 has four feature sections with specific copy. The flywheel visualization concept is strong.
**Gap:** No visual spec for the feature-card component itself. The brand book describes the copy but not the card layout tokens.
**Verdict:** TIGHTEN — add a feature-card token spec (icon, eyebrow, body, layout). Should follow the trace-explorer card anatomy from §8.6.

### Comparison section
**Brand book guidance:** §1.0 (naming note) mentions Langfuse, Arize Phoenix, Braintrust. §3.4 (what Scoria is not) covers the category. No "why not X" copy.
**Gap:** The comparison section ("why not just use Langfuse?") is missing from the brand book. This is a legitimate OSS concern: Scoria is Phoenix-native, OSS, embedded, and governance-first. Langfuse is hosted-first, Python-adjacent, and eval-first. Arize Phoenix is tracing-first. Braintrust is production-traces-to-evals. These are differentiators worth stating.
**What to add:** "Why not…" bullet set in §13 or §3. Not adversarial; just specific.
**Verdict:** ADD — "Why not just use Langfuse / Arize Phoenix / Braintrust" comparison paragraph. High value for landing page conversion.

### Blog post header
**Brand book guidance:** §17.1 social card format applies. §7 voice guidance covers release notes.
**Gap:** Blog post headers need a consistent treatment: mark + title + author + date. The brand book doesn't specify this, which is fine — it's a Phase-21-later concern.
**Verdict:** KEEP — defer until there are actual blog posts to render.

### Release announcement
**Brand book guidance:** §7.3 tone guidance for release notes: "maintainer-like, transparent." §15.3 release codename table is useful.
**Gap:** No release-announcement copy template. The codename table (Ash, Vesicle, Baseline, Gateway, Caldera, Seismograph) is excellent — this should be surfaced more prominently.
**Verdict:** TIGHTEN — add a release-announcement template in §7.5 UX microcopy examples.

### Social preview card
**Brand book guidance:** §17.1 is specific: dark basalt background, mark top left, one large sentence, one trace/eval UI crop, footer. Good.
**Gap:** No SVG template, no dimension spec (1200×630 for OG, 800×418 for Twitter). Mark doesn't exist.
**Verdict:** TIGHTEN — add OG/Twitter card dimensions to §17.1. Phase 22 delivers the actual SVG.

### Favicon
**Brand book guidance:** §4.6 specifies 16px minimum mark, 3–5 holes at small size. The conceptual direction is clear.
**Gap:** No favicon SVG exists. At 16px, the difference between a readable cinder mark and a blob depends entirely on the geometry of the SVG. This cannot be verified until Phase 19 delivers the mark.
**The real risk:** If the mark has organic irregular holes it will likely smear at 16px. The "trace vesicle" layout (holes subtly aligned like trace nodes) is more disciplined than the generic cinder fragment and is likely to survive at 16px better.
**Verdict:** TIGHTEN — add an explicit rule: "at 16px favicon, reduce to exactly 3 holes in a vertical or diagonal arrangement." Phase 19 must test this.

### App icon
**Brand book guidance:** §4.6 has a sidebar mark spec at 24px.
**Gap:** App icon (for PWA or native) implies a larger format (512×512) with a rounded rectangle container. The brand book prohibits container shapes behind marks. For an app icon, the container *is* the shape — this needs a specific ruling.
**Verdict:** ADD — clarify that for app icons and PWA manifests, the `background_color` in `manifest.json` should be Basalt-950 (#11100F), the mark fills the safe zone, and no additional container rectangle should be added.

### Small monochrome logo
**Brand book guidance:** Good direction in §4.2. "Geometric enough to render at favicon size."
**Gap:** The brand book does not specify what "monochrome" means: is it the mark in Basalt-950 on transparent? In Ash-50 on transparent? Both? The answer is: both, as separate assets.
**Verdict:** TIGHTEN — specify two monochrome variants: `logo-mark-dark.svg` (Basalt-950 mark for light surfaces) and `logo-mark-light.svg` (Ash-50 mark for dark surfaces). Phase 19 produces these.

### Dark-mode page
**Brand book guidance:** Excellent. §8.2 specifies dark-first for product UI, §8.4 has dark surfaces, §5 has the full palette.
**Gap:** None significant. The shipped `assets/css/02-tokens.css` implements this correctly.
**Verdict:** KEEP — the dark-mode spec is one of the brand book's strongest sections.

### Light-mode page
**Brand book guidance:** Good. §8.2 specifies light for docs. §8.4 has light surface CSS. The shipped token file has a correct light re-point.
**Gap:** Light-mode panel background is `--scoria-surface-panel: var(--scoria-white-hot)` (#FFF9F3) which is *warmer* than the standard white. This is correct and intentional — it maintains the warm volcanic character. However, the brand book does not explicitly call this out as an intentional brand decision.
**Verdict:** TIGHTEN — add a note: "Light panel background (#FFF9F3 White-Hot) is intentionally warm. Do not substitute neutral white (#FFFFFF) — it breaks the palette warmth."

### Conference slide
**Brand book guidance:** One line in §17.4. Insufficient.
**Gap:** Not critical — conference slides are infrequent. The rule is simple: mark top-left, dark background, one claim, one code snippet or trace diagram, no decorative lava.
**Verdict:** KEEP as-is — not worth spending depth on this surface.

### Diagram or architecture illustration
**Brand book guidance:** §8.8 trace-explorer visual language is good. §10.4 hero direction gives a run-tree example.
**Gap:** No general diagramming style for architecture illustrations (e.g., "how Scoria fits into your Phoenix app" diagrams, MCP gateway topology). These need a spec: node shapes, arrow styles, label fonts.
**What to add:** Architecture diagram style: nodes in Char-850 (#211C19) with Tuff-300 borders, labels in Ash-50 or JetBrains Mono for IDs, Ember-500 for the "Scoria" node(s), Olivine for healthy/passing nodes, Lava for failing nodes, connecting lines in Graphite-700.
**Verdict:** ADD — short architecture diagram style block. Useful for docs and README.

### Error, empty, and success states
**Brand book guidance:** §7.5 UX microcopy covers empty states (traces, datasets), run status states, tool approval, eval regression. §8.9 eval UI specifies what to show/avoid. Good depth.
**Gap:** No color-independent treatment specified. Section 18.1 says "do not rely on color alone" and "use label text" — but the badge mapping in §8.7 is purely color-keyed with no label-text rule.
**Verdict:** TIGHTEN — add explicit rule: every badge must have a text label (Pass, Fail, Warning, etc.) visible at all times; color is secondary confirmation only.

### Example UI component library
**Brand book guidance:** §8 covers the primitive components. Not a full component library.
**Gap:** The brand book is not trying to be a component library. This is appropriate.
**Verdict:** KEEP — Phase 21 delivers `examples/*.svg`; that is the right scope.

### Mobile landing page
**Brand book guidance:** Implicit — 12-column grid collapses, but no explicit mobile guidance.
**Gap:** The flywheel visualization and trace-tree hero are both complex enough to need mobile breakpoints specified.
**Verdict:** TIGHTEN — add a note: "On mobile (<640px), collapse the run-tree hero to a single highlighted span card and the flywheel to a vertical list." Not critical until landing page build.

### Printed sticker or small swag
**Brand book guidance:** §17.3 has excellent sticker phrases ("evals or it didn't happen," "not magic; measured," "promote the trace"). These are genuinely good.
**Gap:** The sticker copy is good; the visual format for stickers isn't specified. Stickers need a high-contrast monochrome option.
**Verdict:** KEEP — the phrase list is better than 90% of OSS sticker copy. The monochrome logo rule covers the visual side.

---

## SECTION 5 — Gaps and risks

### Critical

**C1: Logo does not exist**
All visual-identity claims about the brand are unverifiable until the mark is executed. The favicon test, sidebar test, monochrome test, social-card test, and README-header test are all blocked. Four concept directions exist but none is committed. This is the #1 execution risk for the entire milestone.
**Linked phases:** Phase 19 (logo divergence), Phase 20 (logo convergence).

**C2: `--scoria-text-subtle` (#88786D Pumice-500) is PASS-LARGE, not PASS-AA, on all shipped surfaces**
Shipped ratios (from `assets/css/02-tokens.css`):
- `--scoria-text-subtle` on `--scoria-surface-app` (dark, #11100F): **4.48:1 — PASS-LARGE**
- `--scoria-text-subtle` on `--scoria-surface-panel` (dark, #181513): **4.29:1 — PASS-LARGE**
- `--scoria-text-subtle` on `--scoria-surface-app` (light, #FAF5EF): **3.91:1 — PASS-LARGE**
- `--scoria-text-subtle` on `--scoria-surface-panel` (light, #FFF9F3): **4.06:1 — PASS-LARGE**

PASS-LARGE is acceptable for large text (≥18px regular or ≥14px bold) and UI components (e.g., icons, decorative borders, placeholder chips), but **fails for normal-size running text at any weight**. If `--scoria-text-subtle` is currently used for body text in the shipped dashboard, it is a WCAG AA defect. The propagation verdict for 18-02 depends on whether this is used in normal-text contexts.

**The brand book's §5.5 warning about Pumice-500 as "muted labels on light" actually undersells the risk on dark.** The dark-theme ratios (4.48:1 and 4.29:1) are closer to the AA boundary than the light-theme ratios. This is counterintuitive and warrants a note in the brand book.

**Action required for 18-02:** Audit the shipped dashboard to determine if `--scoria-text-subtle` is used for any text content ≤18px regular or ≤14px bold. If yes: propagation required (tighten pumice or add a new `--scoria-text-subtle-aa` token using a lighter value). If it is used only for icons, decorative elements, and large metadata labels: propagation not required, but the brand book must document the intent.

**C3: No propagation policy document**
The 18-CONTEXT.md locks in the propagation policy ("touched only on material failures"), but this policy is not written into the brand book itself. Future maintainers modifying `assets/css/02-tokens.css` may not know the constraint.
**Fix:** Add a "Token propagation" note to the brand book's token section: "The shipped `assets/css/02-tokens.css` is the runtime implementation. Cosmetic brand-book updates do not automatically propagate. Only WCAG AA failures, accessibility defects, or genuine coherence breaks trigger a propagation pass."

---

### Important

**I1: No `--scoria-focus-ring` semantic for light mode**
In dark mode: `--scoria-focus-ring: var(--scoria-molten-400)` (#FF7A4D, ratio vs Basalt-950 = **7.37:1**). In light mode: `--scoria-focus-ring: var(--scoria-600)` (#B94F31, ratio vs Ash-50 = **4.58:1**). Both pass AA for the focus indicator (3:1 required for non-text UI components per WCAG 1.4.11). However, the brand book does not specify focus-ring usage rules or minimum width, which matters for keyboard-navigation audits.
**Fix:** Add a focus-ring rule in §18: "Focus ring minimum: 2px solid, offset 2px. Use `--scoria-focus-ring` token. Never suppress focus styles."

**I2: `--scoria-span-*` color tokens on Basalt-950 dark surfaces**
Span-kind colors in `assets/css/02-tokens.css` dark mode are the dark-variant primitives (ember, scoria-600, cinder-100, success-dark, info-dark, etc.). These are used as colored labels/indicators on trace spans. Most pass comfortably, but `--scoria-span-llm: var(--scoria-600)` (#B94F31) on Basalt-950 = **3.82:1** — PASS-LARGE, not PASS-AA. If Scoria-600 span indicators appear as normal-size text labels next to span names, this is an accessibility concern. As a color-coded icon or dot indicator (UI component context), PASS-LARGE is acceptable.
**Fix:** Ensure span-kind labels always pair Scoria-600 with a text label in a legible color; the color chip is decorative, not the primary differentiator.

**I3: Brand book Section 8 (UI component anatomy) should be separated from the brand guide**
The deep UI-component guidance (button anatomy, card anatomy, trace-explorer color mapping, eval workbench rules) belongs in a separate "UI Guide" rather than the brand book. Brand books govern identity; UI guides govern component implementation. Mixing them creates a maintenance problem: the brand book should rarely change, but the UI guide will evolve with every feature.
**Fix:** After Phase 21 brand-book rewrite, split §8–§12 into `brandbook/ui-guide.md`. Keep §1–§7 (identity) in `brandbook/brand-book.md`.

**I4: Suite-coherence underdocumented**
The szTheory architectural DNA (`prompts/sztheory-elixir-dna.md`) specifies ecosystem integration (Sigra for auth, Threadline for audit, Chimeway for notifications, Parapet for SRE). The brand book does not address how Scoria positions relative to these siblings. A user discovering Scoria on Hex.pm should be able to understand that it belongs to a deliberate ecosystem, not just a lone library.
**Fix:** Add a brief "Suite context" note in the brand book's §1 or §15: "Scoria is part of the szTheory Elixir ecosystem. It integrates with Sigra (auth), Threadline (audit), Chimeway (notifications), and Parapet (SRE). Each library is visually distinct but shares a common typographic system (IBM Plex Sans / JetBrains Mono) and an operator-first DX philosophy."

**I5: Brand book does not specify SVG favicon simplification geometry**
"3–5 holes at small sizes" (§4.6) is a reduction rule, not a geometry spec. A 16px favicon with three misaligned holes will read as noise. Phase 19 needs a specific simplification grid: "At 16px: 1 large center hole (7–8px), 2 smaller satellite holes (2–3px) in a diagonal configuration. The mark outline must be a single closed path."

---

### Nice-to-have

**N1: "Why not Langfuse / Arize Phoenix / Braintrust" comparison**
Missing from the brand book and valuable for landing-page conversion. Not blocking anything.

**N2: Release-announcement template**
The codename table is good. A brief announcement template ("Here's what shipped in Vesicle and why it matters for Phoenix AI ops teams") would help future release posts stay on-brand.

**N3: ExDoc font-override CSS**
A minimal ExDoc theme that applies IBM Plex Sans and JetBrains Mono would significantly improve HexDocs brand coherence. Low effort, high visibility.

**N4: README badge order spec**
Simple, actionable, takes one sentence to add.

**N5: Architecture diagram style spec**
Needed when the docs site gets a "how Scoria works" diagram. Not blocking Phase 18.

---

## SECTION 6 — Recommended brand book upgrades

The following sections are strong enough to KEEP without change:
- §2 (brand personality) — KEEP
- §3 (brand narrative) — KEEP
- §7 (voice and writing system) — KEEP. Best section of the document.
- §8.8 (trace explorer visual language) — KEEP
- §8.9 (eval workbench visual language) — KEEP
- §11 (data visualization) — KEEP
- §15.2 (feature naming) — KEEP
- §15.3 (release codenames) — KEEP
- §19 (brand do/don't) — KEEP

Sections needing TIGHTEN or REWORK:

**§1 (naming note) — TIGHTEN**
Add a brief suite-context note: Scoria belongs to the szTheory ecosystem alongside Threadline, Sigra, and others. One sentence. This makes the library feel less like a lone project and establishes ecosystem credibility.

**§4 (visual identity) — TIGHTEN in §4.4 lockups**
The secondary lockup includes "AI ops for Phoenix" as a subtitle under the mark. §4.4 also says "main lockup has no subtitle." This is contradictory. Resolve: the *primary horizontal lockup* is `[mark] Scoria` with no subtitle. The *secondary stacked lockup* is `[mark] / Scoria / AI ops for Phoenix`, used only for social cards, slide titles, and stickers. Add: "The logotype-only / integrated-typemark variant (motif worked into letterforms) is a first-class variant, not a fallback — explore this in Phase 19."

**§5.5 (accessibility rules) — REWORK**
The brand book promises WCAG AA compliance but does not acknowledge the Pumice-500 boundary case. Rework the accessibility rules table to explicitly call out the nuance:

```
Foreground        Background    Ratio   Safe use
#88786D Pumice-500  #11100F Basalt-950  4.48:1  Muted labels, UI metadata, icons — NOT running body text
#88786D Pumice-500  #181513 Basalt-900  4.29:1  Same constraint
#88786D Pumice-500  #FAF5EF Ash-50      3.91:1  Icon labels, caption-weight only
```

Add the explicit rule: "Pumice-500 / `--scoria-text-subtle` is a PASS-LARGE pairing on all surfaces. Use it only for secondary UI metadata (12–13px monospaced trace IDs, timestamps, icon labels). Do not use for paragraph text, names, or any user-generated content."

**§6 (typography) — TIGHTEN in §6.4 product UI scale**
The product UI type scale is missing token references. The brand book specifies sizes (13–14px table body, 12–13px badge) but doesn't link them to `--scoria-fs-*` tokens. Add a mapping column:

| Role | Size | Token |
|---|---|---|
| Page title | 24px | `--scoria-fs-title` |
| Panel title | 18px | `--scoria-fs-panel` |
| Table body | 14px | `--scoria-fs-body` |
| Badge | 11px | `--scoria-fs-badge` |
| Code/meta | 12px | `--scoria-fs-label` |
| Metric number | 30px | `--scoria-fs-metric` |

**§14 (documentation identity) — ADD badge spec**
Under §14.1, add:
```markdown
## README badges (left to right)
[![Hex.pm](https://img.shields.io/hexpm/v/scoria.svg)](https://hex.pm/packages/scoria)
[![CI](https://github.com/sztheory/scoria/actions/workflows/ci.yml/badge.svg)](...)
[![License](https://img.shields.io/hexpm/l/scoria.svg)](LICENSE)
```
Keep badge colors standard (no custom Ember-500 badge fills). Custom badge styling adds maintenance burden with minimal brand benefit.

**§15 (brand architecture) — ADD: propagation policy and token lane rule**
Add: "`brandbook/tokens.css` (Phase 21) is the source-of-truth export for non-dashboard consumers. `assets/css/02-tokens.css` is the runtime implementation. They should be kept in sync but are not automatically coupled. Propagation from brand book to runtime tokens is gated on the Phase 18 audit verdict."

**New section: ADD §5.8 Token propagation policy**
Document the BRAND-09 conditional: "Only WCAG AA failures, accessibility defects, or genuine coherence breaks (not cosmetic preference changes) trigger a propagation pass to `assets/css/02-tokens.css`. The rationale: Phase 12's DS-06 baseline guard means token changes require a test-baseline update. This cost is only justified by material failures."

---

## SECTION 7 — Design token specification

### Scope note
The token specification direction is provided here. Phase 21 will produce `brandbook/tokens.json` and `brandbook/tokens.css` as committed source artifacts. The shipped `assets/css/02-tokens.css` already implements most of these tokens correctly and is the current source of truth.

### Gaps in the existing token layer (additions needed in Phase 21)

**1. Focus ring tokens (missing detail)**
```css
--scoria-focus-ring-width: 2px;
--scoria-focus-ring-offset: 2px;
--scoria-focus-ring-style: solid;
/* --scoria-focus-ring already exists (Molten-400 dark / Scoria-600 light) */
```

**2. State tokens (not yet in shipped tokens.css)**
```css
/* Hover states — resolved from action tokens */
--scoria-state-hover-bg: color-mix(in srgb, var(--scoria-ember-500) 10%, transparent);     /* dark */
--scoria-state-active-bg: color-mix(in srgb, var(--scoria-ember-500) 18%, transparent);
--scoria-state-selected-bg: color-mix(in srgb, var(--scoria-ember-500) 14%, transparent);
--scoria-state-disabled-opacity: 0.38;
--scoria-state-disabled-cursor: not-allowed;
/* Light equivalents */
/* dark: --scoria-state-hover-bg = ember tint; light = scoria-600 tint */
```

**3. Code-block tokens (missing from shipped)**
```css
--scoria-code-bg:         var(--scoria-surface-sunken);   /* #0C0B0A dark / #F1E8DE light */
--scoria-code-border:     var(--scoria-border);
--scoria-code-text:       var(--scoria-text);
--scoria-code-comment:    var(--scoria-pumice-500);        /* #88786D */
--scoria-code-keyword:    var(--scoria-molten-400);        /* #FF7A4D */
--scoria-code-string:     var(--scoria-cinder-100);        /* #F8D6C8 */
--scoria-code-atom:       var(--scoria-info-dark);         /* #7DD8D1 */
--scoria-code-module:     var(--scoria-ash-50);            /* #FAF5EF */
--scoria-code-function:   var(--scoria-tone-pass-fg);      /* #A7C76F */
```

**4. Callout tokens (docs callouts, not shipped)**
```css
--scoria-callout-note-bg:      color-mix(in srgb, var(--scoria-info-dark) 10%, transparent);
--scoria-callout-note-border:  var(--scoria-info-dark);
--scoria-callout-note-fg:      var(--scoria-text);
--scoria-callout-warn-bg:      color-mix(in srgb, var(--scoria-warning-dark) 10%, transparent);
--scoria-callout-warn-border:  var(--scoria-warning-dark);
--scoria-callout-warn-fg:      var(--scoria-text);
--scoria-callout-danger-bg:    color-mix(in srgb, var(--scoria-danger-dark) 10%, transparent);
--scoria-callout-danger-border:var(--scoria-danger-dark);
--scoria-callout-danger-fg:    var(--scoria-text);
--scoria-callout-tip-bg:       color-mix(in srgb, var(--scoria-success-dark) 10%, transparent);
--scoria-callout-tip-border:   var(--scoria-success-dark);
--scoria-callout-tip-fg:       var(--scoria-text);
```

### Semantic token inventory (reconciliation with shipped)

The following semantic tokens from `assets/css/02-tokens.css` are correctly specified and should be carried forward to `brandbook/tokens.css` without change:

```
Surface:        --scoria-surface-app / -panel / -panel-raised / -sunken / -overlay
Text:           --scoria-text / -muted / -subtle / -onaccent
Links:          --scoria-link / -link-hover
Borders:        --scoria-border / -border-strong
Action:         --scoria-action / -action-hover / -action-fg / -danger-action
Focus:          --scoria-focus-ring
Shadows:        --scoria-shadow-panel / -shadow-raised / -glow-ember
Tone family:    --scoria-tone-{neutral,pass,info,warn,fail,trace,brand}-{fg,bg,border}
Span kinds:     --scoria-span-{agent,llm,prompt,tool,mcp,retriever,guardrail,eval,error,redacted}
```

The tone and span-kind tokens are the biggest design-token differentiator vs. generic design systems — they reflect the product's domain (eval lifecycle, span taxonomy) and should be highlighted in the brand book as a key system feature, not buried in a CSS comment.

### Naming reconciliation with brand book §5.7

The brand book's §5.7 uses slightly different naming from the shipped file:
- Book uses `--scoria-white-hot: #FFF9F3` — shipped uses `--scoria-white-hot: #fff9f3` (lowercase, functionally identical)
- Book uses `--scoria-900`, `--scoria-800`, etc. for the warm scale — shipped uses the same (no change needed)
- Book does not list `--scoria-muted-warm` (#BDAEA3) as a named primitive — shipped adds it as `--scoria-muted-warm`. **KEEP the addition**; it fills a gap the brand book implicitly needed.

### Accessibility / contrast verdict

The contrast table below is the verbatim output of `brandbook/tools/contrast-check.mjs` (run at plan-execution time). It covers all documented brand-book pairings (§5.4 and §5.5) and all resolved semantic pairings from `assets/css/02-tokens.css` for both dark and light themes.

**Interpretation:**

The good news: no shipped pairing fails WCAG AA outright. All 52 pairings produce either PASS-AA or PASS-LARGE. This means the color system is fundamentally sound and **no emergency propagation to `assets/css/02-tokens.css` is required on accessibility grounds**.

The documented-only concern: The negative-control pairing (Scoria-600 #B94F31 on Basalt-950 #11100F) produces **3.82:1 — PASS-LARGE** — confirming the brand book's §5.5 warning is technically accurate. It is not a FAIL, but it is clearly below the normal-text AA threshold. The warning stands: do not use Scoria-600 as normal-size dark-mode body text.

The shipped concern: **`--scoria-text-subtle` (#88786D Pumice-500) is PASS-LARGE across all four surface pairings** (4.48:1, 4.29:1, 3.91:1, 4.06:1). This is the only shipped token that does not clear normal-text AA. It is below AA on light surfaces more than on dark surfaces, which is counterintuitive. The token is appropriate for muted UI labels, 12px metadata, icon labels, and decorative elements — it must not be used for running text. The brand book should state this constraint explicitly.

The Warning-light surprise: `--scoria-tone-warn-fg` (#7A5A16 Sulfur) on Ash-50 produces **5.87:1 — PASS-AA**. The brand book flagged this as a "known risk on light surfaces" (18-CONTEXT specifics), but the actual ratio is comfortably passing. No action needed.

The Trace-dark pair: `--scoria-trace-dark` (#B798FF) on Basalt-950 = **8.10:1 — PASS-AA**. Purple on very dark backgrounds performs better than expected.

---

<!-- contrast table begins — verbatim output of node brandbook/tools/contrast-check.mjs -->

# Scoria WCAG 2.1 Contrast Audit

Generated: 2026-06-11

Verdicts: PASS-AA = ≥4.5:1 · PASS-LARGE = ≥3.0:1 · FAIL = <3.0:1

---

### DOCUMENTED — Brand-book §5.4 / §5.5 pairings

| Foreground | Background | Ratio | Verdict | Source | Usage |
|---|---|---:|---|---|---|
| White-Hot | Basalt-950 | 18.19:1 | PASS-AA | §5.5 | White-Hot on Basalt-950 (main text, dark) |
| Ash-50 | Basalt-950 | 17.53:1 | PASS-AA | §5.5 | Ash-50 on Basalt-950 (main text, dark) |
| Ash-100 | Basalt-900 | 14.75:1 | PASS-AA | §5.5 | Ash-100 on Basalt-900 (body text, dark) |
| Muted-warm | Basalt-950 | 8.82:1 | PASS-AA | §5.5 | Muted-warm on Basalt-950 (muted text, dark) |
| Basalt-950 | Ash-50 | 17.53:1 | PASS-AA | §5.5 | Basalt-950 on Ash-50 (main text, light) |
| Graphite-700 | Ash-50 | 11.43:1 | PASS-AA | §5.5 | Graphite-700 on Ash-50 (secondary text, light) |
| Scoria-600 | Ash-50 | 4.58:1 | PASS-AA | §5.5 | Scoria-600 on Ash-50 (links, light) |
| Scoria-700 | Ash-50 | 7.11:1 | PASS-AA | §5.5 | Scoria-700 on Ash-50 (outlines/links, light) |
| Ember-500 | Basalt-950 | 5.32:1 | PASS-AA | §5.5 | Ember-500 on Basalt-950 (links/actions, dark) |
| Molten-400 | Basalt-950 | 7.37:1 | PASS-AA | §5.5 | Molten-400 on Basalt-950 (high-emphasis, dark) |
| Pumice-500 | Basalt-950 | 4.48:1 | PASS-LARGE | §5.5 | Pumice-500 on Basalt-950 (RISK: muted labels, dark) |
| Scoria-600 | Basalt-950 | 3.82:1 | PASS-LARGE | §5.5 | Scoria-600 on Basalt-950 (NEGATIVE CONTROL: §5.5 warns against) |
| Success-dark (#A7C76F) | Basalt-950 | 9.99:1 | PASS-AA | §5.4 | Success-dark on Basalt-950 |
| Info-dark (#7DD8D1) | Basalt-950 | 11.42:1 | PASS-AA | §5.4 | Info-dark on Basalt-950 |
| Warning-dark (#FFD166) | Basalt-950 | 13.18:1 | PASS-AA | §5.4 | Warning-dark on Basalt-950 |
| Danger-dark (#FF6B4A) | Basalt-950 | 6.75:1 | PASS-AA | §5.4 | Danger-dark on Basalt-950 |
| Trace-dark (#B798FF) | Basalt-950 | 8.10:1 | PASS-AA | §5.4 | Trace-dark on Basalt-950 |
| Success-light (#536A39) | Ash-50 | 5.55:1 | PASS-AA | §5.4 | Success-light on Ash-50 |
| Info-light (#2A6C69) | Ash-50 | 5.62:1 | PASS-AA | §5.4 | Info-light on Ash-50 |
| Warning-light (#7A5A16) | Ash-50 | 5.87:1 | PASS-AA | §5.4 | Warning-light on Ash-50 (RISK: Sulfur) |
| Danger-light (#9E2F20) | Ash-50 | 6.72:1 | PASS-AA | §5.4 | Danger-light on Ash-50 |
| Trace-light (#6A55A7) | Ash-50 | 5.58:1 | PASS-AA | §5.4 | Trace-light on Ash-50 |

### SHIPPED — Resolved semantic pairings from assets/css/02-tokens.css

| Foreground | Background | Ratio | Verdict | Source | Usage |
|---|---|---:|---|---|---|
| --scoria-text (#FAF5EF) | --scoria-surface-app (#11100F) | 17.53:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-text on --scoria-surface-app |
| --scoria-text-muted (#BDAEA3) | --scoria-surface-app (#11100F) | 8.82:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-text-muted on --scoria-surface-app |
| --scoria-text-subtle (#88786D) | --scoria-surface-app (#11100F) | 4.48:1 | PASS-LARGE | tokens.css:dark | shipped dark: --scoria-text-subtle on --scoria-surface-app |
| --scoria-link (#E65A32) | --scoria-surface-app (#11100F) | 5.32:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-link on --scoria-surface-app |
| --scoria-text (#FAF5EF) | --scoria-surface-panel (#181513) | 16.77:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-text on --scoria-surface-panel |
| --scoria-text-muted (#BDAEA3) | --scoria-surface-panel (#181513) | 8.44:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-text-muted on --scoria-surface-panel |
| --scoria-text-subtle (#88786D) | --scoria-surface-panel (#181513) | 4.29:1 | PASS-LARGE | tokens.css:dark | shipped dark: --scoria-text-subtle on --scoria-surface-panel |
| --scoria-action-fg (#11100F) | --scoria-action (#E65A32) | 5.32:1 | PASS-AA | tokens.css:dark | shipped dark: --scoria-action-fg on --scoria-action |
| --scoria-tone-neutral-fg (#CDBBAC) | Basalt-950 (#11100F) | 10.23:1 | PASS-AA | tokens.css:dark | shipped dark: tone-neutral-fg (#CDBBAC) on Basalt-950 |
| --scoria-tone-pass-fg (#A7C76F) | Basalt-950 (#11100F) | 9.99:1 | PASS-AA | tokens.css:dark | shipped dark: tone-pass-fg (#A7C76F) on Basalt-950 |
| --scoria-tone-info-fg (#7DD8D1) | Basalt-950 (#11100F) | 11.42:1 | PASS-AA | tokens.css:dark | shipped dark: tone-info-fg (#7DD8D1) on Basalt-950 |
| --scoria-tone-warn-fg (#FFD166) | Basalt-950 (#11100F) | 13.18:1 | PASS-AA | tokens.css:dark | shipped dark: tone-warn-fg (#FFD166) on Basalt-950 |
| --scoria-tone-fail-fg (#FF6B4A) | Basalt-950 (#11100F) | 6.75:1 | PASS-AA | tokens.css:dark | shipped dark: tone-fail-fg (#FF6B4A) on Basalt-950 |
| --scoria-tone-trace-fg (#B798FF) | Basalt-950 (#11100F) | 8.10:1 | PASS-AA | tokens.css:dark | shipped dark: tone-trace-fg (#B798FF) on Basalt-950 |
| --scoria-tone-brand-fg (#FF7A4D) | Basalt-950 (#11100F) | 7.37:1 | PASS-AA | tokens.css:dark | shipped dark: tone-brand-fg (#FF7A4D) on Basalt-950 |
| --scoria-text (#11100F) | --scoria-surface-app (#FAF5EF) | 17.53:1 | PASS-AA | tokens.css:light | shipped light: --scoria-text on --scoria-surface-app |
| --scoria-text-muted (#3A332F) | --scoria-surface-app (#FAF5EF) | 11.43:1 | PASS-AA | tokens.css:light | shipped light: --scoria-text-muted on --scoria-surface-app |
| --scoria-text-subtle (#88786D) | --scoria-surface-app (#FAF5EF) | 3.91:1 | PASS-LARGE | tokens.css:light | shipped light: --scoria-text-subtle on --scoria-surface-app |
| --scoria-link (#B94F31) | --scoria-surface-app (#FAF5EF) | 4.58:1 | PASS-AA | tokens.css:light | shipped light: --scoria-link on --scoria-surface-app |
| --scoria-text (#11100F) | --scoria-surface-panel (#FFF9F3) | 18.19:1 | PASS-AA | tokens.css:light | shipped light: --scoria-text on --scoria-surface-panel |
| --scoria-text-muted (#3A332F) | --scoria-surface-panel (#FFF9F3) | 11.86:1 | PASS-AA | tokens.css:light | shipped light: --scoria-text-muted on --scoria-surface-panel |
| --scoria-text-subtle (#88786D) | --scoria-surface-panel (#FFF9F3) | 4.06:1 | PASS-LARGE | tokens.css:light | shipped light: --scoria-text-subtle on --scoria-surface-panel |
| --scoria-action-fg (#FFF9F3) | --scoria-action (#B94F31) | 4.76:1 | PASS-AA | tokens.css:light | shipped light: --scoria-action-fg on --scoria-action |
| --scoria-tone-neutral-fg (#3A332F) | Ash-50 (#FAF5EF) | 11.43:1 | PASS-AA | tokens.css:light | shipped light: tone-neutral-fg (#3A332F) on Ash-50 |
| --scoria-tone-pass-fg (#536A39) | Ash-50 (#FAF5EF) | 5.55:1 | PASS-AA | tokens.css:light | shipped light: tone-pass-fg (#536A39) on Ash-50 |
| --scoria-tone-info-fg (#2A6C69) | Ash-50 (#FAF5EF) | 5.62:1 | PASS-AA | tokens.css:light | shipped light: tone-info-fg (#2A6C69) on Ash-50 |
| --scoria-tone-warn-fg (#7A5A16) | Ash-50 (#FAF5EF) | 5.87:1 | PASS-AA | tokens.css:light | shipped light: tone-warn-fg (#7A5A16) on Ash-50 |
| --scoria-tone-fail-fg (#9E2F20) | Ash-50 (#FAF5EF) | 6.72:1 | PASS-AA | tokens.css:light | shipped light: tone-fail-fg (#9E2F20) on Ash-50 |
| --scoria-tone-trace-fg (#6A55A7) | Ash-50 (#FAF5EF) | 5.58:1 | PASS-AA | tokens.css:light | shipped light: tone-trace-fg (#6A55A7) on Ash-50 |
| --scoria-tone-brand-fg (#8D3826) | Ash-50 (#FAF5EF) | 7.11:1 | PASS-AA | tokens.css:light | shipped light: tone-brand-fg (#8D3826) on Ash-50 |

---

**Summary:** 52 pairings — PASS-AA: 46 · PASS-LARGE: 6 · FAIL: 0

**PASS-LARGE (borderline, requires large text or UI context):**
- Pumice-500 on Basalt-950 (RISK: muted labels, dark) — 4.48:1 (§5.5)
- Scoria-600 on Basalt-950 (NEGATIVE CONTROL: §5.5 warns against) — 3.82:1 (§5.5)
- shipped dark: --scoria-text-subtle on --scoria-surface-app — 4.48:1 (tokens.css:dark)
- shipped dark: --scoria-text-subtle on --scoria-surface-panel — 4.29:1 (tokens.css:dark)
- shipped light: --scoria-text-subtle on --scoria-surface-app — 3.91:1 (tokens.css:light)
- shipped light: --scoria-text-subtle on --scoria-surface-panel — 4.06:1 (tokens.css:light)

<!-- contrast table ends -->

---

*Sections 8–14 and Decisions Locked are written in Phase 18-02.*

---

## SECTION 8 — Logo and mark system

### What type of logo does Scoria need?

**Recommendation: Combination lockup (mark + logotype) as the primary form, with integrated typemark as a first-class variant.**

Scoria should not be a logotype-only brand. The volcanic-cinder mark is central to the identity and meaningfully distinct. A logotype-alone approach would look like any other developer tool library on Hex.pm. The mark works at all sizes the product needs — favicon, sidebar, README header, social card — and it encodes the core metaphor (vesicles = internal AI run structure) in a way that a wordmark cannot.

The mark is not ready as a mascot (too literal) and not appropriate as a monogram (S has no unique geometric resonance with volcanic imagery). The correct system:

1. **Combination lockup** (mark + "Scoria" in IBM Plex Sans SemiBold): primary form for landing pages, README hero, docs header, GitHub OG image.
2. **Mark only**: favicon, sidebar, package avatar, conference badge.
3. **Integrated typemark** (the vesicle aperture geometry worked INTO a letterform — the 'o' as a hollow vesicle, or the letterforms with a porous interior): wanted as a first-class variant, not a consolation option. This is the most distinctive execution and is worth attempting in Phase 19 alongside the classical mark-plus-logotype approach.
4. **Logotype only** (clean wordmark, no mark): acceptable for situations where the mark is too small (email header sub-nav, narrow sidebars). NOT the primary identity.

---

### Logo direction ranking

The four brand-book directions are evaluated against 16px favicon scalability, monochrome survival, distinctiveness vs adjacent OSS/devtools marks, and distinctiveness vs Threadline's mark.

| Rank | Direction | Favicon 16px | Monochrome | Distinctiveness (OSS/devtools) | Distinctiveness (vs Threadline) | Recommended use |
|---:|---|:---:|:---:|:---:|:---:|---|
| **#1** | **Trace Vesicle Mark** | ★★★★ | ★★★★ | ★★★★★ | ★★★★★ | PRIMARY — all contexts |
| **#2** | **Cinder Mark** | ★★★★★ | ★★★★ | ★★★★ | ★★★★ | Strong favicon/icon fallback |
| **#3** | **Aperture/Vesicle Mark** | ★★★ | ★★★ | ★★★ | ★★★★ | Alternative study for Phase 19 |
| **#4** | **Cutaway Cone Mark** | ★★ | ★★★ | ★★★ | ★★★ | De-prioritize; weak at small sizes |

**Why Trace Vesicle Mark is #1:** The discipline of aligning holes in a trace-node hierarchy (root → LLM → tool → eval) gives the mark a readable internal logic. At 16px, regularity reads better than organic irregularity. At monochrome, the structured layout survives because the negative-space holes are geometrically distinct, not randomly placed. Against devtools competitors (Langfuse, Arize Phoenix, Braintrust — all using abstract nodes or colorful blobs), a mark with a traceable internal structure is genuinely different. Against Threadline (which uses a path/line motif), the porous cinder silhouette is orthogonal — same studio feel but completely different shape vocabulary.

**Why Cinder Mark is #2:** Simpler geometry = better favicon survival. A loose irregular-polygon cinder with 5–7 holes is highly legible at 16px if the holes are sufficiently sized (≥2px rendered). Easier to execute well than the Trace Vesicle. Use as the fallback if the Trace Vesicle proves too complex to read at ≤20px.

**Why Aperture/Vesicle is #3 not #1:** A central cavity with surrounding smaller cavities risks reading as a camera aperture or eye — both generic and off-metaphor. The "observability" interpretation is too literal and puts it in the same visual space as Arize Phoenix's circular marks. Worth attempting as a study; not recommended as the primary direction.

**Why Cutaway Cone is #4:** At 16px, a cross-section of a cone with visible voids loses the shape silhouette entirely. It is more distinctive at large sizes but distinctiveness at large sizes is the easy problem; the hard one is favicon survival. De-prioritize unless the Phase 19 studies reveal a surprisingly legible simplification.

---

### Phase-19 logo constraints (hard rules — Phase 19 must obey these)

These constraints are locked from 18-CONTEXT and are encoded here as named rules:

**RULE LOGO-01 — No rectangular background shapes.**
Marks must not use a bounding rectangle, square, rounded square, circle, or any filled container shape as a backdrop. The silhouette of the mark IS the shape. Negative space is created via `fill-rule="evenodd"` punched holes inside the outer path. Any AI tool or generation step that adds a background container must be explicitly rejected and re-run.

**RULE LOGO-02 — Negative space via fill-rule="evenodd" only.**
All interior holes in the mark are created as inner paths with `fill-rule="evenodd"` or equivalent compound path subtraction. No separate white-filled shapes. This ensures the mark works on any background color without revealing a hidden white rectangle.

**RULE LOGO-03 — Logotype optically tight to mark.**
In the combination lockup, the gap between the right edge of the mark and the left edge of the "S" in "Scoria" should be approximately 0.35–0.5× the cap height of the logotype. Anything wider reads as two unrelated elements. No decorative spacing, no rule lines between mark and logotype.

**RULE LOGO-04 — No subtitle in the primary lockup.**
The primary horizontal lockup is `[mark] Scoria` — nothing below, nothing to the right of the wordmark except air. A *separate* subtitle variant (`[mark] / Scoria / AI ops for Phoenix`) is allowed for social cards, slide titles, and conference stickers. The main lockup must never include the tagline or any descriptor text as a mandatory element.

**RULE LOGO-05 — Integrated typemark is a first-class option, not a fallback.**
Phase 19 must produce at least one typemark study where the vesicle motif is worked INTO the letterforms of "Scoria" — e.g., the 'o' as a hollow vesicle aperture, or the whole word with porous negative-space holes. This is not a font trick; it requires custom path work. It should be evaluated on equal footing with the mark-plus-logotype combination.

**RULE LOGO-06 — 16px favicon test is pass/fail.**
Every mark candidate produced in Phase 19 must be tested at exactly 16×16px browser-rendered size before it is eligible for advancement to Phase 20. A mark that is attractive at 64px but unreadable at 16px does not pass. The "Trace Vesicle" interpretation must simplify to exactly 3 holes in a vertical or diagonal arrangement at 16px — this is a geometry instruction, not a preference.

**RULE LOGO-07 — Monochrome test is pass/fail.**
Every mark candidate must be tested in flat monochrome (Basalt-950 fill on transparent, and Ash-50 fill on transparent) before advancement. The mark must be readable without color.

**Phase 19 does not generate production SVGs in Phase 18.** Phase 19 owns all SVG generation. This section defines the constraints and recommendation only. The user approves the direction at gate #2 after Phase 19 produces the options gallery.

---

### Logo system components (to be produced in Phase 19–20)

| Asset | File | Context |
|---|---|---|
| Primary lockup | `brandbook/logo-primary.svg` | Landing page, README header, OG image |
| Mark only | `brandbook/logo-mark.svg` | Favicon source, sidebar, avatar |
| Logotype only | `brandbook/logo-logotype.svg` | Narrow contexts, email nav |
| Monochrome (dark) | `brandbook/logo-mark-dark.svg` | Dark mark on transparent (for light surfaces) |
| Monochrome (light) | `brandbook/logo-mark-light.svg` | Light mark on transparent (for dark surfaces) |
| Favicon SVG | `brandbook/favicon.svg` | 16px source, simplified 3-hole geometry |
| Typemark study | `brandbook/logo-typemark.svg` | Integrated letterform variant |
| Social card | `brandbook/social-card.svg` | OG/Twitter card, 1200×630 |

**Clear space:** Use the largest vesicle in the mark as the unit `v`. Minimum clear space around mark: 1v. Minimum around full lockup: 1.5v.

**Minimum sizes:** Mark 16px (favicon), sidebar 24px, full lockup 112px wide, README/social 240px wide.

---

## SECTION 9 — Visual examples and screenshot guidance

The principle: every visual example in `brandbook/examples/` must be reproducible from source (SVG or CSS-rendered text) by any maintainer without design software. No fake product screenshots. No screenshots of a running dashboard. All examples are either SVG constructions or browser-rendered static HTML.

### Color palette specimen

**Purpose:** Verify the palette at a glance; catch drift when the brand book is updated.
**Layout:** Two rows — dark surfaces (Basalt-950 through Char-850) in row 1, light surfaces (Ash-50 through Ash-100) in row 2. Below: warm scale (Scoria-900 through Molten-400) in a single row. Below: functional accent pairs (success, info, warning, danger, trace) as light/dark columns.
**Dimensions:** 1200×400px SVG, responsive.
**File:** `brandbook/examples/palette.svg`
**When worth it:** Now. This is the single most useful verification artifact. Run the SVG against the hex values in `assets/css/02-tokens.css` when tokens change.

### Typography specimen

**Purpose:** Confirm typeface rendering, weight ramp, and scale at a glance.
**Layout:** IBM Plex Sans weight ramp (Regular → SemiBold → Bold) at heading sizes, with the brand tagline as specimen text. JetBrains Mono at 13px with a representative Scoria code snippet. Show fallback rendering note.
**Dimensions:** 900×500px SVG.
**File:** `brandbook/examples/typography.svg`
**When worth it:** Phase 21 (when brand-book.md is written). Not before.

### Component example: buttons and cards

**Purpose:** Reference for engineers building the landing page and docs.
**Layout:** Primary button, danger button, ghost button in dark and light variants side by side. One eval-regression card (eyebrow + title + metric + monospace metadata) in dark. One docs card in light.
**Dimensions:** 800×400px SVG.
**File:** `brandbook/examples/components.svg`
**When worth it:** Phase 21. Document the anatomy; the dashboard already has the shipped components.

### Code block example

**Purpose:** Canonical code block style reference for README, HexDocs, and landing page.
**Layout:** Dark code block background (`--scoria-code-bg`), syntax-highlighted Elixir snippet (`Scoria.run/2` example with actor, options), JetBrains Mono 13px. Show Elixir keyword coloring (atoms in Fumarole, strings in Cinder-100, keywords in Molten-400, comments in Pumice-500).
**Dimensions:** 700×200px SVG (or static HTML fragment).
**File:** `brandbook/examples/code-block.svg`
**When worth it:** Phase 21. This is the highest-visibility example for OSS credibility.

### README header mock

**Purpose:** Show how the primary lockup, one-liner, and badge stack should look in a GitHub README.
**Layout:** Primary logo SVG (centered or left-aligned), one-liner below, badge row (hex.pm, CI, License), then first 5 lines of quickstart code. Dark background (#11100F) or transparent.
**Dimensions:** 1200×240px SVG.
**File:** `brandbook/examples/readme-header.svg`
**When worth it:** Phase 22 (after logo exists). Blocked on Phase 19–20.

### Landing page hero mock

**Purpose:** Show hero layout for landing page build reference.
**Layout:** Dark basalt background, primary hero gradient, headline left (one sentence, ~3 lines at 56px), product UI trace waterfall right (schematic, not actual screenshot), primary CTA below headline.
**Content:** Headline: "Trace the run. Prove the change. Ship the agent." Subhead: "Scoria gives Phoenix teams observable, evaluable, production-grade AI ops without the black box." CTA: "Get started" + "View on GitHub".
**Dimensions:** 1440×700px design reference (SVG or static HTML mock).
**File:** `brandbook/examples/landing-hero.svg`
**When worth it:** Phase 22. Blocked on logo and real product UI crops.

### Docs page mock

**Purpose:** Light-mode docs page reference for ExDoc theme work.
**Layout:** Light ash background, IBM Plex Sans body, JetBrains Mono code blocks, sidebar with mark at 24px, active state in Ember-500 (light mode: Scoria-600).
**Dimensions:** 1280×800px.
**File:** `brandbook/examples/docs-page.svg`
**When worth it:** Phase 21 (when ExDoc theme is being built). Not before.

### Social card (OG/Twitter)

**Purpose:** Standard Open Graph card for GitHub, Twitter, blog posts.
**Layout:** Dark basalt background with subtle hero gradient, mark top-left, "Scoria" wordmark top-left below mark, one short sentence ("Phoenix-native AI ops"), trace/eval UI fragment bottom-right, footer with URL.
**Dimensions:** 1200×630 (OG), 800×418 (Twitter). Both from the same SVG template.
**File:** `brandbook/social-card.svg` (production) + `brandbook/examples/social-card-example.svg` (reference).
**When worth it:** Phase 22. Blocked on logo.

### Terminal style

**Purpose:** Reference for terminal snippets in README and docs.
**Layout:** Dark surface (#0C0B0A), prompt in Ember-500 (`$`), command in Ash-50, output in Pumice-500 / `--scoria-text-subtle`. No fake dramatic output; real `mix scoria.install` output.
**Dimensions:** 700×160px.
**File:** `brandbook/examples/terminal.svg`
**When worth it:** Phase 22 (when install commands are stable).

---

**What NOT to produce:** Dashboard screenshots, animated GIFs, raster illustrations, anything that requires a running server, product UI mocks with fake data. These are maintenance traps. If a surface needs a visual example, either (a) produce it as a static SVG schematic or (b) document the layout and let the actual product provide it.

---

## SECTION 10 — Brand voice and microcopy

### Voice system

**KEEP** the brand book's §7 voice system wholesale. It is the strongest section of the document. The principles (calm + exact + useful), the evidence-verb list, the anti-anthropomorphization rules, and the existing microcopy examples are production-ready. The section below confirms the existing system and adds the concrete copy blocks that are missing.

**Voice verdict by context:**

| Context | Current state | Verdict |
|---|---|---|
| §7.1 Voice formula | "Calm + exact + useful" | KEEP |
| §7.2 Voice principles | Evidence verbs, no anthropomorphizing | KEEP |
| §7.3 Tone-by-context table | Good coverage | KEEP — add: CLI output and MCP gateway UI |
| §7.4 Word bank | Comprehensive | KEEP |
| §7.5 Microcopy examples | Production-ready for shipped screens | KEEP + ADD: new surfaces below |
| §7.6 Docs style | Copy+explain pattern | KEEP |
| §1.2 One-liner | Accurate but reads like a spec | TIGHTEN (see below) |
| §1.5 Tagline | Good primary; hierarchy unclear | TIGHTEN (confirmed below) |

---

### Confirmed naming rule

**Product name:** Scoria (never "Scoria AI").
**Package name:** `:scoria` (Elixir atom/module casing).
**Feature names:** Trace Explorer, Eval Workbench, Prompt Registry, Replay Playground, Tool Governance, MCP Gateway — unchanged.
**Suite context note:** Scoria is part of the szTheory Elixir ecosystem alongside Threadline (audit), Sigra (auth), Chimeway (notifications), and Parapet (SRE). This gives adopters context that Scoria is not a lone library but part of a deliberate, operator-first ecosystem.

---

### Concrete copy blocks (ready to use)

**One-line project description (TIGHTENED)**
Before: "Scoria is the Phoenix-native AI ops layer for tracing, evaluating, replaying, and governing LLM apps."
After: "Scoria is the Phoenix-native AI ops layer for LLM traces, evals, prompt versions, and tool governance."
Rationale: "Replaying" is a capability, not a selling point in the one-liner. "Tool governance" is more specific and distinctive than "governing."

**140-character description (for Hex.pm `description:` field)**
```
Phoenix-native AI ops: LLM traces, evals, prompt versions, replay, tool governance, and MCP workflows. Ecto-backed, LiveView-included.
```
(136 chars — within Hex.pm's 140-char display.)

**GitHub repo description**
```
Phoenix-native AI ops: trace, eval, replay, govern. LLM runs, tool approvals, prompt versions, and MCP workflows wired into Phoenix + Ecto + LiveView.
```

**Hex.pm package description**
```
Phoenix-native AI ops: LLM traces, evals, prompt versions, replay, tool governance, and MCP workflows. Ecto-backed, LiveView-included.
```
*(Same as 140-char — Hex.pm and the tagline canonical copy should stay in sync.)*

**README opening paragraph**
```
Scoria is a batteries-included Phoenix library for production AI features. It records every run — prompt renders, model calls, tool calls, retrieval events, approvals, and eval scores — as structured, queryable traces. You get a LiveView operator UI, an eval flywheel, a prompt version registry, and a tool/MCP governance layer, all wired into Phoenix, Ecto, and OTP without a black-box dependency.
```

**Landing page hero headline**
```
Trace the run.
Prove the change.
Ship the agent.
```
Three-line treatment; each line is a complete verb phrase. Line 2 is the differentiator (most AI ops tools trace; fewer force you to prove before shipping). Strongly recommended as the primary headline — not the alternate "AI ops for Phoenix apps."

**Landing page subheadline**
```
Scoria gives Phoenix teams observable, evaluable, production-grade AI ops: traces, evals, prompt versions, replay, and tool governance — wired into Phoenix, Ecto, and OTP.
```

**Primary CTA**
```
Get started
```
*(Not "Try Scoria", not "Start free", not "Book a demo". The library is open source; adopters install it.)*

**Secondary CTA**
```
View on GitHub
```

**Three feature blurbs**

Feature 1 — Trace Explorer
```
See inside every run.
Every prompt render, model call, tool call, retrieval event, and span is recorded as a structured trace. Filter by actor, latency, cost, or eval outcome. Replay any run with a different prompt or model.
```

Feature 2 — Eval Workbench
```
Prove it before you ship it.
Score runs against baseline datasets. Detect regressions before they reach users. Promote candidates that pass; gate those that don't. The flywheel turns: production traces become eval datasets automatically.
```

Feature 3 — Tool Governance
```
Approve tool calls. Govern MCP actions.
Dangerous tools require human approval. Non-dangerous tools run automatically. Every approval, denial, and policy version is recorded in the trace. You decide what "safe enough to autoship" means.
```

**Three "why this exists" bullets**
```
• Phoenix teams building AI features needed production observability, not just a logging wrapper.
• Every AI incident Scoria was designed to prevent has the same cause: invisible behavior. Show the structure.
• Governance is not a feature you add later. Tool approvals, eval gates, and prompt versions belong in the runtime, not bolted on after the fact.
```

**Example error message (correct voice)**
```
Run failed during lookup_order.
The tool returned 403 for actor usr_184. Policy refunds_v7 requires actor to have :ops role. Trace ID: trc_8f2a.
[View trace]  [Open policy]
```

**Example empty state**
```
No eval datasets yet.
Promote a production trace to start building a regression suite, or add a test case manually.
[Promote a trace]  [Add manually]
```

**Example success state**
```
Candidate promoted.
support_refunds@v4 is now the baseline. 12 new dataset items captured from this run.
[View eval history]
```

**Example release announcement**
```
Scoria v0.2 — Vesicle

This release ships the Eval Workbench: dataset management, scorer configuration, and baseline comparison directly in the LiveView operator UI. It also adds prompt version pinning and a structured MCP approval log.

What changed:
• Eval datasets: promote traces, add items, edit labels
• Prompt versions: pin and compare via the registry UI
• MCP approval log: every gateway decision recorded with actor, tool, and policy version
• [Migration note: run mix scoria.migrate after upgrading]

If something broke: open an issue with the trace ID and the tool call that failed. Scoria records enough context to help you debug without guessing.
```

---

**Voice drift prevention:** The §7.5 microcopy examples are the canonical anchor. When a new UI surface ships, add 2–3 microcopy examples in the same format before writing any landing page copy for that surface. The voice is correct; the risk is drift from non-technical collaborators.

---

## SECTION 11 — Landing page and docs blueprint

### Landing page architecture

The landing page should be buildable from the brand book's copy blocks and visual direction without any additional decisions. Every section maps to a brand-system artifact.

**Hero**
- Dark basalt background with primary hero gradient
- Headline: "Trace the run. Prove the change. Ship the agent." (three-line, left-aligned)
- Subheadline: "Scoria gives Phoenix teams observable, evaluable, production-grade AI ops — wired into Phoenix, Ecto, and OTP."
- Primary CTA: "Get started" → hex.pm or docs. Secondary CTA: "View on GitHub"
- Visual: trace waterfall or run tree SVG schematic right of headline (NOT a fake dashboard screenshot; a genuine SVG diagram of a run tree with span-kind colors)
- Voice: confident, concrete, no "powerful" or "seamless"

**Problem**
- Headline: "AI behavior is invisible by default."
- Body: 3-bullet problem statement. Bullet 1: You can see the final answer, not the run that produced it. Bullet 2: Regressions are invisible until a user files a ticket. Bullet 3: Tool policies live in code comments, not in a governance layer.
- Voice: no drama; just what is missing

**Solution**
- Headline: "Make the fire inspectable."
- Three-column cards: Trace → Eval → Govern. Each card has an eyebrow (the workflow step), a one-sentence description, and a feature name link.
- Voice: operator-grade, not aspirational

**Install snippet**
```
{:scoria, "~> 0.2"}
```
One-liner. Then: `mix scoria.install` and the LiveView router mount. JetBrains Mono, dark code block. Copy button.

**Minimal example**
```elixir
{:ok, run} =
  Scoria.run(MyApp.AI.SupportAgent,
    input: "Can I get a refund for order A123?",
    actor: current_user
  )
```
Explain in 2 sentences. Do not pad. Voice: §7.6 copy+explain pattern.

**Core benefits**
Three compact statements:
1. Traces are Ecto records — queryable, exportable, not trapped in a vendor.
2. Evals gate deployments — catch regressions before users do.
3. Tool approvals are first-class — governance is in the runtime, not a comment.

**How it works**
Flywheel visualization: Capture → Annotate → Promote → Evaluate → Compare → Gate → Deploy → Monitor. SVG diagram, not an animated graphic. Dark surface. Each node labeled with a feature name. One sentence per node explaining what Scoria does at that step.

**Use cases**
Four horizontal cards:
1. Support copilot with tool approvals
2. RAG pipeline with eval gates
3. Prompt A/B testing with baseline comparison
4. MCP agent with full governance log
Each card: one-sentence description + one `Scoria.run/2` call variant. No screenshots.

**Why not just use Langfuse / Arize Phoenix / Braintrust?**
Inline comparison table (not adversarial):

| | Scoria | Langfuse | Arize Phoenix | Braintrust |
|---|---|---|---|---|
| Phoenix-native | Yes | No | No | No |
| Ecto-backed storage | Yes | No | No | No |
| LiveView UI included | Yes | No | No | No |
| Tool governance | Yes | Limited | No | No |
| Open source, self-hosted | Yes | Yes (core) | Yes | Partial |
| Eval flywheel | Yes | Yes | Yes | Yes |

Caption: "Scoria is not a replacement for every AI observability tool. It is the right choice when your stack is Phoenix and you need governance-first, embedded AI ops without a vendor dependency."

**Documentation CTA**
"Read the docs → hex.pm/packages/scoria or hexdocs.pm/scoria"

**GitHub CTA**
"View source, open issues, contribute → github.com/sztheory/scoria"

**Community/contribution CTA**
"Join the szTheory Elixir ecosystem discussion → GitHub Discussions"

**Footer**
Logo mark (24px) + "Scoria" wordmark. Copyright. Links: Docs, GitHub, Hex.pm, License. No cookie banner unless needed for analytics.

---

### Docs/README architecture

**README structure (binding order):**

1. **Promise** — Primary lockup SVG + one-liner + badges (hex.pm, CI, License). 3 lines max before the first code block. Voice: §7.6.
2. **Installation** — `mix.exs` deps entry + `mix scoria.install`. One paragraph.
3. **Quickstart** — 10-line `Scoria.run/2` example. No explanation padding. Copy+explain pattern.
4. **Example** — A complete, runnable minimal scenario: one agent, one eval, one tool policy. Shows the flywheel in 30 lines of code.
5. **Concepts** — 5 concepts, one paragraph each: Runs, Traces, Evals, Prompt Versions, Tool Policies. No flowery language.
6. **API overview** — Link to HexDocs. Do not reproduce the API in the README.
7. **Common recipes** — 3–5 copy-pasteable code snippets for common patterns: replay, promote, gate, approve.
8. **Troubleshooting** — 5 known gotchas with exact error messages and fixes. Voice: §7.1 diagnostic.
9. **Design rationale** — 2 paragraphs: why Phoenix-native, why Ecto-backed. Not marketing; actual engineering reasoning.
10. **Contribution** — One paragraph + link to CONTRIBUTING.md.
11. **License** — Apache 2.0 or MIT, one line.

**Tone:** Every README section should feel like a colleague wrote it. Not a landing page. Not a manual. Clear, fast, useful.

---

## SECTION 12 — Repo-ready artifact plan

### Directory structure

```
brandbook/
  README.md              — Maintenance rules + usage guide (Phase 21)
  brand-book.md          — Post-audit brand book rewrite, ~500 lines (Phase 21)
  pressure-test.md       — This document — the audit (Phase 18, DO NOT MODIFY retroactively)
  tokens.json            — Structured raw + semantic tokens (Phase 21)
  tokens.css             — CSS custom properties for non-dashboard consumers (Phase 21)
  favicon.svg            — 16px-optimized mark (Phase 19–20)
  logo-primary.svg       — Combination lockup: mark + "Scoria" (Phase 19–20)
  logo-mark.svg          — Mark only (Phase 19–20)
  logo-logotype.svg      — Wordmark only (Phase 19–20)
  logo-mark-dark.svg     — Monochrome: dark mark on transparent (Phase 19–20)
  logo-mark-light.svg    — Monochrome: light mark on transparent (Phase 19–20)
  social-card.svg        — OG/Twitter card 1200×630 (Phase 22)
  tools/
    contrast-check.mjs   — WCAG checker (Phase 18-01, committed)
  examples/
    palette.svg          — Color palette specimen (Phase 21)
    typography.svg       — Type specimen (Phase 21)
    components.svg       — Button + card examples (Phase 21)
    code-block.svg       — Code block style reference (Phase 21)
    readme-header.svg    — README header mock (Phase 22)
    landing-hero.svg     — Landing hero design reference (Phase 22)
    terminal.svg         — Terminal snippet style (Phase 22)
```

### File commitment rules

| Status | Files | Rule |
|---|---|---|
| Committed now | `pressure-test.md`, `tools/contrast-check.mjs` | Done (Phase 18) |
| Committed Phase 19–20 | Logo SVG variants (7 files) | After user gate #2 |
| Committed Phase 21 | `brand-book.md`, `tokens.json`, `tokens.css`, `examples/` (5 files), `README.md` | After audit-driven rewrite |
| Committed Phase 22 | `social-card.svg`, `examples/readme-header.svg`, `examples/landing-hero.svg`, `examples/terminal.svg` | After integration pass |
| NOT committed | Raster exports (PNG/WebP), AI generation prompts, intermediate WIP SVG variants | Prevent binary bloat; keep <500KB total |
| Needs manual review | Any SVG containing embedded raster, any file >50KB | Flag in PR; audit against budget |
| Historical input — DO NOT TOUCH | `prompts/scoria-brand-book-deep-research.md` | Source-of-truth seed document; read-only forever |

### Budget constraint

Total `brandbook/` budget: **<500KB** for all text and SVG artifacts combined. Raster exports go to `priv/static/images/` only if needed for a shipped product surface (README OG image); they are not part of the brandbook/ canon.

### Naming conventions

- All files: lowercase, hyphen-separated, no version suffixes in filenames (git history tracks versions)
- Logo variants: `logo-{type}-{variant}.svg` pattern (e.g., `logo-mark-dark.svg`, `logo-primary.svg`)
- Examples: `{subject}.svg` (descriptive, not numbered)
- Tools: `{function}.mjs` (ESM, no npm install required)

### CI/lint checks (add to `mix test` or a dedicated task)

```bash
# LOGO-01 compliance: reject any SVG with a rectangle wrapping the mark
grep -rn '<rect' brandbook/logo-*.svg && echo "FAIL: rectangular background shape found" || echo "PASS: no rect in logo files"

# LOGO-02 compliance: every logo SVG should use evenodd
grep -rn 'fill-rule="evenodd"' brandbook/logo-*.svg | wc -l

# Budget check
du -sh brandbook/ && [ "$(du -sk brandbook/ | cut -f1)" -lt 512 ] && echo "PASS: within 500KB" || echo "FAIL: brandbook/ exceeds 500KB"

# Hex consistency check (logo hex values match token file)
# — Phase 21 task: write a mjs script that reads tokens.json and validates logo SVG hex values
```

---

## SECTION 13 — Prioritized action plan

### Do now (Phase 19 — unblocked, highest leverage)

**1. Execute Trace Vesicle Mark and Cinder Mark as committed SVG options.**
Both are the top-ranked directions. Phase 19 should produce ≥6 mark/lockup variants (at minimum: Trace Vesicle + Cinder as marks, each with combination lockup and integrated typemark study) plus the options gallery (`options-gallery.html`). Test every candidate at 16px favicon and monochrome before including in the gallery. Value: unblocks every visual-identity test that is currently blocked.

**2. Implement LOGO-01 through LOGO-05 constraints in the Phase 19 generation process.**
The no-rect / evenodd / tight-lockup / no-subtitle / integrated-typemark rules are hard constraints, not preferences. Any generation step (manual or AI-assisted) that violates them produces disqualified output. Encoding them as named rules (as this section does) means Phase 19 can reference them by ID rather than re-litigating.

**3. Test at 16px favicon explicitly.**
At least one revision pass on each mark candidate must happen at exactly 16px rendered size. The 3-hole simplification rule is a specific instruction: reduce to exactly 3 holes in a vertical or diagonal arrangement at 16px.

### Do next (Phase 20 — after gate #2)

**4. Produce the full variant set from the approved direction.**
Primary lockup, mark only, logotype only, two monochrome variants, favicon SVG, social card template. Clear-space spec and minimum-size documentation. Manual optical correction pass — particularly the tight tracking between mark and logotype.

**5. Clarify §5.5 accessibility rules in `brand-book.md`.**
The Pumice-500 / `--scoria-text-subtle` boundary case is now fully documented here (Section 5 of this audit). When Phase 21 rewrites `brand-book.md`, the §5.5 accessibility rules table must be reworked to explicitly state: "Pumice-500 / `--scoria-text-subtle` is PASS-LARGE only (3.91–4.48:1). Use exclusively for UI icons, sort indicators, and muted metadata (≥18px or ≥14px bold). Never for body text." The shipped usage (sort icon fill in `ui.ex:653`) is compliant.

### Do next (Phase 21 — parallel-eligible with Phase 20)

**6. Build `brandbook/tokens.json` and `brandbook/tokens.css` from the token direction in Section 7 of this audit.**
The gap tokens (focus-ring width/offset, state tokens, code-block tokens, callout tokens) are specified in Section 7 and should be added. The existing `assets/css/02-tokens.css` is the upstream source; `brandbook/tokens.css` is the downstream export for non-dashboard consumers.

**7. Rewrite `brand-book.md` post-audit.**
Target: ~500 lines. Keep §1–§7 (identity, personality, narrative, visual, color, typography, voice). Split §8–§12 UI guidance into a separate `brandbook/ui-guide.md`. The brand book should rarely change; the UI guide will evolve with features.

**8. Add §5.8 "Token propagation policy" to the brand book.**
Document the BRAND-09 conditional explicitly: cosmetic brand-book updates do not propagate; WCAG AA failures, accessibility defects, and coherence breaks do.

**9. Produce `examples/palette.svg`, `examples/typography.svg`, `examples/components.svg`, `examples/code-block.svg`.**
Static SVG verification artifacts. The code-block example is the most useful for README and HexDocs.

**10. Add suite-context note in brand-book.md §1.**
"Scoria is part of the szTheory Elixir ecosystem alongside Threadline (audit), Sigra (auth), Chimeway (notifications), and Parapet (SRE). Each library is visually distinct but shares IBM Plex Sans / JetBrains Mono and an operator-first DX philosophy."

### Defer (Phase 22)

**11. Wire README header, badges, social card, and favicon into the repo.**
Phase 22 delivers: `mix.exs` description update, GitHub repo description, HexDocs intro, README header SVG, `favicon.svg` in `priv/static/`, `social-card.svg`. These all depend on the logo existing (Phase 19–20).

**12. Phase 22 contrast propagation check.**
Re-run `brandbook/tools/contrast-check.mjs` against the final token set and confirm the verdict has not changed. If tokens changed materially in Phase 21, the propagation verdict must be re-evaluated.

**13. Architecture diagram style spec and "Why not Langfuse" copy.**
Both are Nice-to-have (N1, N5 in Section 5 gaps). Add to landing page and brand-book.md when the landing page build begins.

### Do not do

**14. Do NOT generate a logo that uses a rectangular background container.**
No exceptions. If AI-assisted generation produces container shapes, the output is discarded and regenerated. This is not a style preference; it is a hard identity rule (LOGO-01).

**15. Do NOT create PNG/WebP brand artifacts until a specific shipped surface requires them.**
Rasters bloat git history and cannot be trivially updated. Every brandbook artifact is SVG-first. Raster exports are generated at build time from SVG sources, not committed.

**16. Do NOT touch `assets/css/02-tokens.css`, `test/support/ds06_baseline.txt`, or `priv/static` CSS in Phase 19–21.**
Propagation verdict is `not-required` (see Decisions Locked). These files are only touched in Phase 22 BRAND-09 conditional, and only if a new contrast audit discovers a material failure.

**17. Do NOT redesign the color system.**
The palette is sound. 46/52 pairings PASS-AA; 6 PASS-LARGE with no FAIL. The warm volcanic palette is a genuine differentiator. No material change is warranted. Cosmetic preferences (e.g., "I prefer a slightly warmer Ash-50") stay brandbook-only and do not trigger a token rewrite.

**18. Do NOT add a tagline or subtitle to the primary lockup.**
The "AI ops for Phoenix" subtitle in the brand book's §4.4 secondary stacked lockup is allowed for social cards and stickers. It must not appear in the primary horizontal lockup. LOGO-04 is a hard rule.

---

## SECTION 14 — Final quality gate

**Eight questions. Direct answers.**

---

**1. Could a designer build from this?**

Yes — after Section 8's logo ranking and constraint encoding, a designer has: ranked direction (#1 Trace Vesicle Mark), hard rules (LOGO-01 through LOGO-07), the full palette with hex values, the typography system (IBM Plex Sans + JetBrains Mono with weight ramp and scale), spacing/radius tokens, clearspace and minimum-size rules, and the visual examples plan. The one remaining gap is that no SVG files exist yet — that is Phase 19's job, not this audit's.

**2. Could an engineer implement from this?**

Yes — an engineer gets: `assets/css/02-tokens.css` (already committed, already the source of runtime tokens), the Section 7 token gap spec (focus-ring width, state tokens, code-block tokens, callout tokens), the component anatomy from §8 of the brand book (buttons, cards, badges, trace explorer), the voice system (§7), and the copy blocks from Section 10. The README structure and landing page architecture (Section 11) are immediately actionable.

**3. Could a maintainer keep it consistent?**

Yes — with one condition: the brand book needs the §5.8 propagation policy written into it explicitly (Phase 21 task). Right now the policy lives in 18-CONTEXT.md and this audit document. Once it is in `brand-book.md`, future maintainers have a clear rule: cosmetic delta stays brand-book-only; WCAG failure triggers propagation. The LOGO-01 through LOGO-07 rules encoded in this section, plus the planned CI grep check, provide a lightweight enforcement layer.

**4. Could a contributor understand it?**

Yes — the brand DNA (Section 2) is extractable and memorable. "Volcanic clarity for production AI systems." "The field engineer." "Calm + exact + useful." "Trace the run. Prove the change. Ship the agent." These are not corporate brand-book filler; they are decision-making tools. A contributor who reads Sections 1–2 of this audit (and §1–§7 of the brand book) understands the identity well enough to write a PR description, a README improvement, or an error message without drifting.

**5. Could it support marketing without becoming cheesy?**

Yes — the brand book explicitly prohibits the cheesy patterns. "No 'revolutionary.'" "No 'seamless.'" "No 'next-generation.'" "No anthropomorphizing the model." The word bank and anti-trait list are unusually specific. The copy blocks in Section 10 are production-ready and don't cheat by using vague claims. The comparison table in Section 11 is factual, not adversarial. The risk is drift — not the starting point.

**6. Could it survive dark mode, small sizes, docs pages, and social previews?**

Dark mode: yes — dark-first color system with full semantic re-point for light. Small sizes: pending Phase 19 logo execution, but the 16px test rule (LOGO-06) is now a hard gate. Docs pages: yes — light-mode surface spec is correct (intentionally warm Ash-50/#FAF5EF, confirmed in Section 4). Social previews: blocked on logo; the social card spec in Section 9 is ready to build from. Token pairings are sound (52 pairings, 0 FAIL).

**7. Does it feel specific to this library?**

Yes — and this is the most important answer. The volcanic metaphor is not borrowed from a competitor. "Vesicle" names the milestone. "Scoria" names the library and is also a real geological material. The trace-node vesicle alignment in the logo direction is the brand differentiator at the smallest size (16px favicon). The word bank — trace, span, scorer, baseline, gate, replay, approval, redaction — is this library's domain language, not generic AI tool language. The "do not anthropomorphize the model" voice principle is a direct response to the actual product context.

**8. Does it avoid unnecessary brand thrash?**

Yes — the propagation verdict is `not-required`. No changes to `assets/css/02-tokens.css`. No changes to `priv/static`. No changes to `test/support/ds06_baseline.txt`. The color system is confirmed sound. Typography is confirmed keep. Voice is confirmed keep. The only net-new work is the logo (Phase 19–20), the brand-book rewrite and token export (Phase 21), and the integration pass (Phase 22). None of these constitute thrash; they are additive work on a system that is already strong.

---

## Decisions Locked

*Approved at gate #1 before Phase 19 begins. Phases 19, 21, and 22 read back this section.*

---

### Final tagline

**Locked: "Trace the run. Prove the change. Ship the agent."**

The brand book's primary candidate is confirmed as the final tagline. Rationale: it is the only option that is both action-verb-led AND encodes the product's unique differentiation. "AI ops for Phoenix apps" is the strongest single-line descriptor for the hero subheadline or Hex.pm description but is too narrow for the top position — it tells you what category, not why Scoria over any other AI ops tool. "Make the fire inspectable" is poetic and true but opaque on first read for a developer landing on the page from a search. The three-line treatment ("Trace the run. / Prove the change. / Ship the agent.") reads as a landing hero headline; the single-line form is the full sentence.

Alternate taglines (approved for secondary contexts):
- "AI ops for Phoenix apps." — hero subheadline, Hex.pm description prefix, social card footer
- "Make the fire inspectable." — stickers, conference slide backgrounds, release announcement tagline
- "A Phoenix-native control plane for LLM traces, evals, prompts, tools, and MCP." — full technical positioning, README intro, HexDocs meta description

Do-not-use list stands unchanged from §1.5 of the brand book.

---

### One-liner

**Locked (TIGHTENED):** "Scoria is the Phoenix-native AI ops layer for LLM traces, evals, prompt versions, and tool governance."

Before: "Scoria is the Phoenix-native AI ops layer for tracing, evaluating, replaying, and governing LLM apps."
Change: "tool governance" (specific, distinctive) replaces "governing LLM apps" (generic). "LLM traces, evals, prompt versions" (nouns) replace "tracing, evaluating, replaying" (gerunds). Nouns are scannable in the Hex.pm listing and README one-liner context; gerunds are slower.

---

### Naming confirmation

- Product name: **Scoria** — never "Scoria AI", never "ScoriaAI", never "SCORIA", never "Scoria Platform"
- Package atom: `:scoria` — never `:scoria_ai`
- Feature names: **unchanged** — Trace Explorer, Eval Workbench, Prompt Registry, Replay Playground, Tool Governance, MCP Gateway
- Suite context: Scoria belongs to the szTheory Elixir ecosystem alongside Threadline, Sigra, Chimeway, and Parapet. This context should appear in §1 of the brand book rewrite and in the README design-rationale section, not in the product UI.

---

### Palette deltas

**Palette deltas: none** (cosmetic preferences stay brandbook-only).

The 52-pairing contrast audit confirms the palette is fundamentally sound. No FAIL verdicts. The six PASS-LARGE pairings are all `--scoria-text-subtle` on various surfaces and the Scoria-600 negative-control pairing — both are documented constraints, not defects. No hex value changes are warranted.

Brandbook-only notes (do not propagate):
- The warm panel background (#FFF9F3 White-Hot) is intentional. Do not substitute neutral white (#FFFFFF).
- Pumice-500 (#88786D) as `--scoria-text-subtle` is intentionally below normal-text AA. Use for UI icons, sort indicators, and 12–13px monospaced metadata only.

---

### Typography confirmation

**Typography: IBM Plex Sans + JetBrains Mono — confirmed KEEP.**

No material reason to change. IBM Plex Sans is technically neutral, license-safe (OFL), has sufficient weight range for marketing and product UI, and is consistent with the szTheory ecosystem. JetBrains Mono is explicitly designed for developer contexts, handles Elixir code identifiers well, and is the correct choice for trace IDs, model IDs, token counts, and span labels.

Optional accessibility mode: Atkinson Hyperlegible as a docs/UI opt-in body font. Not the default. Not a priority until a user need is documented.

No font changes needed in `assets/css/02-tokens.css`. The shipped font-family stacks are correct.

---

### Logo-direction guidance for Phase 19

**Ranked recommendation (from Section 8 of this audit):**

1. **Trace Vesicle Mark** — RECOMMENDED PRIMARY. Holes in a trace-node hierarchy (root → LLM → tool → eval). Most distinctive vs. competitors and Threadline. Best favicon-survival discipline (regularity reads better than organic randomness at 16px). Phase 19 must execute this direction and the integrated typemark variant.
2. **Cinder Mark** — RECOMMENDED AS FALLBACK. Irregular-polygon cinder with 5–7 holes. Simpler geometry = more reliable favicon survival. If Trace Vesicle proves too complex at ≤20px, Cinder Mark is the approved fallback.
3. **Aperture/Vesicle Mark** — STUDY ONLY. Worth including in the options gallery for comparison. Not recommended as primary due to generic "camera aperture / eye" visual overlap with competitor marks.
4. **Cutaway Cone Mark** — DEPRIORITIZE. Poor favicon survival at 16px; weak silhouette when simplified. Include in gallery only if the Phase 19 exploration reveals a surprising simplification.

**Hard constraints that Phase 19 must enforce (see Section 8 rules):**
- LOGO-01: No rectangular background shapes
- LOGO-02: Negative space via fill-rule="evenodd" punched holes
- LOGO-03: Logotype optically tight to mark (~0.35–0.5× cap height gap)
- LOGO-04: No subtitle in primary lockup (subtitle variant allowed)
- LOGO-05: Integrated typemark is a first-class option (motif INTO letterforms)
- LOGO-06: 16px favicon test is pass/fail before advancement
- LOGO-07: Monochrome test (mark-on-transparent) is pass/fail before advancement

**No SVG is generated in Phase 18.** Phase 19 owns all logo generation.

---

### Propagation verdict

**Usage audit:** `--scoria-text-subtle` (#88786D Pumice-500) appears in `lib/scoria_web/ui.ex:653` as the fill color for a 16×16px SVG sort-direction icon in the table header component. This is a UI component context (icon fill), not running body text. PASS-LARGE (≥3:1) is sufficient for non-text UI components per WCAG 2.1 SC 1.4.11 (Non-text Contrast, threshold 3:1). No other usage of `--scoria-text-subtle` found in `lib/scoria_web/`.

**Verdict:**

```
propagation: not-required
```

Rule satisfied: no shipped fg/bg pairing falls below WCAG AA for its context of use. The four `--scoria-text-subtle` pairings (4.48:1, 4.29:1, 3.91:1, 4.06:1) are PASS-LARGE; the single shipped usage is a UI icon fill, not body text. WCAG 2.1 SC 1.4.11 requires ≥3:1 for non-text UI components; all four ratios satisfy this.

**What this means:**
- `assets/css/02-tokens.css` is NOT touched in Phase 19, 20, or 21.
- `test/support/ds06_baseline.txt` is NOT updated.
- `priv/static` CSS is NOT modified.
- Phase 22's BRAND-09 conditional does NOT fire.

If future development adds `--scoria-text-subtle` to body text, running text, or any text content smaller than 18px regular / 14px bold, the propagation verdict must be re-evaluated and a new token (`--scoria-text-subtle-aa`) added at a higher contrast value before that usage ships.

---

*Contrast evidence: Section 5 (C2) and Section 7 contrast table of this document. Usage evidence: `lib/scoria_web/ui.ex:653` (Phase 18-02 grep audit, 2026-06-11). Tool: `brandbook/tools/contrast-check.mjs`.*

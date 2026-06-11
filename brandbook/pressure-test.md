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

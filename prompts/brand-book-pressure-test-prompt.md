# Brand Book Pressure-Test Prompt

> Canonical copy of the 14-section pressure-test prompt used to audit `scoria-brand-book-deep-research.md` (v2.17 Vesicle, Phase 18). Same prompt family used for the Threadline brandbook audit.

---

You are acting as a senior brand systems director, product designer, UI/UX lead, developer advocate, design-token architect, and OSS maintainer with strong taste in developer tools, Elixir libraries, technical documentation, and high-signal marketing.

I am going to provide one or more existing brand books, plus deep-research markdown files that were originally used to make each library feel distinct in the OSS/devtools space.

Your task is NOT to blindly rewrite or "make it prettier."

Your task is to pressure-test the brand book as if it were about to be committed to the repository and used to produce real assets: landing pages, GitHub READMEs, Hex.pm/HexDocs presentation, UI components, marketing copy, screenshots, design tokens, logos, SVGs, social cards, launch materials, and future product surfaces.

The goal is: all killer, no filler.

Do not create churn for no reason. Preserve what is already strong. Only recommend changes when they materially improve clarity, distinctiveness, usability, accessibility, developer trust, implementation readiness, or brand-system coherence.

Analyze the supplied brand book through these lenses:

1. Strategic distinctiveness
   - Does this brand feel meaningfully distinct from adjacent OSS/devtools/Elixir projects?
   - Does it avoid generic "developer tool" tropes such as abstract gradients, meaningless nodes, fake futurism, hexagons without reason, blue-purple sameness, vague innovation language, or startup-template copy?
   - Is there a strong conceptual center that can guide design decisions?
   - Could someone recognize this library from its tone, visuals, or positioning without seeing the name?

2. Developer credibility
   - Does the brand feel trustworthy to engineers?
   - Does it avoid over-marketing, hype, enterprise fluff, and visual gimmicks?
   - Does the voice fit OSS norms: precise, useful, confident, generous, technically literate, and low-BS?
   - Would it look credible on GitHub, Hex.pm, HexDocs, conference slides, blog posts, and social previews?

3. Elixir ecosystem fit
   - Does the brand feel appropriate for Elixir, Erlang/BEAM-adjacent audiences, Phoenix/LiveView users, library maintainers, and pragmatic backend/frontend engineers?
   - Does it respect the ecosystem's taste: thoughtful, durable, somewhat understated, technically elegant?
   - Does it avoid looking like a random SaaS product when it is actually an OSS library?
   - Does it support use cases like README hero sections, HexDocs pages, Livebook examples, changelogs, release notes, GitHub discussions, and package metadata?

4. Graphic design quality
   - Is the visual language coherent?
   - Are the colors, typography, spacing, iconography, layout principles, logo ideas, and imagery direction specific enough to execute?
   - Are the visual decisions justified by the brand concept, or are they arbitrary?
   - Does the palette work in light mode, dark mode, print, low contrast environments, and small UI surfaces?
   - Are there enough constraints to prevent inconsistent future design work?
   - Are there too many constraints that would make implementation tedious or fragile?

5. UI/UX buildout usefulness
   - Can a designer or engineer use this brand book to build real interfaces?
   - Does it define design tokens or at least tokenizable primitives?
   - Does it include semantic color roles, not just raw colors?
   - Does it define states: hover, active, focus, disabled, success, warning, error, info, selected, muted, subtle, emphasized?
   - Does it cover components likely needed for docs and marketing pages: buttons, cards, alerts, code blocks, callouts, nav, tabs, badges, feature grids, comparison tables, install snippets, terminal blocks, diagrams, empty states, and error states?
   - Does it give enough guidance for screenshots, diagrams, code examples, and demo flows?

6. Accessibility and durability
   - Are colors likely to meet WCAG contrast expectations?
   - Are there accessible alternatives for decorative color usage?
   - Does the logo work at favicon size?
   - Does it work in monochrome?
   - Does it work on transparent, light, dark, and colored backgrounds?
   - Are typography choices practical, readable, and license-safe?
   - Does the brand avoid relying on proprietary assets, inaccessible colors, or hard-to-reproduce design effects?

7. Brand voice and UX microcopy
   - Is the voice specific enough to guide README copy, docs copy, error messages, landing pages, release notes, issue templates, CLI output, and UI labels?
   - Does it include "say this / not this" examples?
   - Does it distinguish between marketing voice, docs voice, error voice, success states, warnings, and empty states?
   - Is the tone appropriate for engineers: concise, exact, helpful, calm, and memorable?
   - Are there taglines, one-liners, short descriptions, long descriptions, and package blurbs ready for use?

8. Marketing and positioning
   - Can this brand book produce a compelling landing page?
   - Does it clarify audience, problem, promise, proof, differentiators, use cases, objections, and calls to action?
   - Does it include copy blocks for:
     - GitHub repo description
     - README intro
     - Hex.pm package description
     - HexDocs intro
     - landing page hero
     - social preview
     - launch post
     - changelog/release announcement
   - Does it avoid vague claims like "powerful," "simple," "robust," "seamless," "next-generation," unless backed by specifics?

9. Artifact readiness
   - Could this brand book be converted into committed files in a repo?
   - Identify which artifacts should exist and where they should live.
   - Prefer durable, text-based, source-controllable artifacts: SVG, JSON tokens, CSS variables, markdown docs, config files, templates, and simple examples.
   - Avoid binary-heavy or vendor-locked assets unless there is a strong reason.
   - Recommend file names, directory structure, and asset formats.

10. Multi-library brand architecture
   - If multiple OSS libraries are involved, analyze whether each brand is distinct enough while still feeling like it belongs to the same author/studio/ecosystem.
   - Define what should be shared across the suite and what should be unique per library.
   - Consider shared typography, layout grid, docs patterns, repo conventions, badge styles, icon geometry, naming conventions, and release-note style.
   - Avoid making every project look identical.
   - Avoid making every project feel unrelated.

Your workflow:

First, read the supplied original prompt, brand book, and deep-research markdown carefully.

Then produce a critical audit before generating or rewriting anything.

Do not start by inventing new assets. Start by determining whether the existing brand system is strong, weak, incomplete, generic, overdesigned, under-specified, or hard to implement.

Use this decision framework:

- KEEP: Existing elements that are strong and should not be changed.
- TIGHTEN: Elements that are directionally right but need sharper wording, better constraints, clearer examples, or implementation details.
- REWORK: Elements that are generic, contradictory, inaccessible, hard to execute, or off-strategy.
- ADD: Missing sections or artifacts that would make the brand book more useful.
- REMOVE: Fluff, vague language, decorative rules, redundant sections, or anything that creates maintenance burden without value.

Be especially skeptical of:
- Generic palettes
- Unjustified gradients
- Trendy but fragile visual effects
- Logo concepts that do not scale
- Mascots without a strong reason
- Abstract geometric marks with no meaning
- Voice guidelines that sound like every other SaaS brand
- Marketing copy that hides the actual technical value
- Design tokens that are only raw colors rather than semantic roles
- Brand books that are inspirational but not buildable
- Artifact lists that are huge but not actually useful
- Any recommendation that causes design thrash without a clear payoff

Deliver the response in the following structure.

SECTION 1 — Executive judgment

Give a direct, opinionated assessment.

Answer:
- Is the current brand book strong enough to build from?
- Is it distinct enough?
- Is it implementation-ready?
- Is it over-specified, under-specified, or balanced?
- What is the highest-leverage improvement?
- What should absolutely not be changed?

Use plain language. Be candid.

SECTION 2 — Brand DNA extraction

Extract the core brand identity into a compact decision-making model:

- Brand essence
- Audience
- Emotional tone
- Technical promise
- Visual metaphor
- Personality traits
- Anti-traits
- Design principles
- Voice principles
- "This should feel like…"
- "This should never feel like…"

If the existing brand book lacks these, infer them from the materials and mark them as inferred.

SECTION 3 — Pressure-test scorecard

Score the brand book from 1–10 on:

- Distinctiveness
- Developer credibility
- Elixir ecosystem fit
- Visual coherence
- Logo readiness
- Color-system readiness
- Typography readiness
- Design-token readiness
- UI component readiness
- Docs/README usefulness
- Marketing usefulness
- Voice/microcopy usefulness
- Accessibility
- Repo/source-control readiness
- Long-term maintainability

For each score, provide:
- Score
- Why
- Risk
- Recommended fix, if needed

SECTION 4 — Stress tests

Test the brand against real-world surfaces.

For each surface, explain whether the brand book gives enough guidance and what needs to be added.

Surfaces to test:
- GitHub repo header
- README hero section
- README badges
- Hex.pm package page
- HexDocs page
- Docs sidebar
- Code block styling
- Terminal snippet
- API reference page
- Landing page hero
- Feature section
- Comparison section
- Blog post header
- Release announcement
- Social preview card
- Favicon
- App icon
- Small monochrome logo
- Dark-mode page
- Light-mode page
- Conference slide
- Diagram or architecture illustration
- Error/empty/success states
- Example UI component library
- Mobile landing page
- Printed sticker or small swag use case, only if actually appropriate

SECTION 5 — Gaps and risks

Identify missing or weak areas.

Group them by severity:

- Critical: blocks execution or creates major inconsistency
- Important: likely to cause quality issues later
- Nice-to-have: useful, but not worth derailing the project

Be strict. Do not inflate this list with filler.

SECTION 6 — Recommended brand book upgrades

Rewrite or expand only the sections that need work.

Possible sections to add or refine:
- Positioning
- Audience
- Brand principles
- Visual principles
- Logo system
- Color system
- Typography
- Iconography
- Layout
- Illustration/imagery
- Motion, if relevant
- UI components
- Design tokens
- Accessibility
- Voice and tone
- UX microcopy
- Marketing copy
- Docs/README style
- Repo artifact structure
- Do/don't examples
- QA checklist

Do not rewrite strong sections just to rewrite them.

SECTION 7 — Design token specification

Create a practical token system that could be committed to the repo.

Include:

- Raw palette tokens
- Semantic color tokens
- Typography tokens
- Spacing tokens
- Radius tokens
- Border tokens
- Shadow/elevation tokens, only if needed
- Focus ring tokens
- Code block tokens
- Callout tokens
- State tokens:
  - default
  - hover
  - active
  - focus
  - disabled
  - selected
  - success
  - warning
  - error
  - info
  - subtle
  - muted

Provide suggested file outputs such as:

- brand/tokens.json
- brand/tokens.css
- brand/tokens.tailwind.js or tailwind.config excerpt, if relevant
- brand/README.md

Use valid code blocks where possible.

Favor simple, maintainable tokens over a giant design system.

SECTION 8 — Logo and mark system

Evaluate whether the brand needs:
- Logotype only
- Symbol/icon only
- Combination lockup
- Monogram
- Abstract mark
- Mascot
- No logo beyond a strong wordmark

Recommend the best option.

Then define a logo system:

- Primary logo
- Secondary logo
- Icon-only mark
- Monochrome mark
- Dark background version
- Light background version
- Favicon
- Social avatar
- Minimum size
- Clearspace
- Usage rules
- Misuse rules

If generating SVGs is appropriate, produce simple, valid, editable SVG source code that can be committed.

SVG requirements:
- Use clean semantic structure
- Avoid unnecessary path complexity
- Avoid embedded raster images
- Avoid proprietary fonts
- Use text converted only if necessary; otherwise specify font fallback
- Include accessible title/desc where appropriate
- Work on transparent background
- Be usable in light and dark contexts
- Keep it simple enough for maintainers to understand

Provide filenames for each asset, for example:

- brand/logo-primary.svg
- brand/logo-mark.svg
- brand/logo-monochrome.svg
- brand/favicon.svg
- brand/social-card.svg

If a logo should not be generated yet because the concept is too weak, say so and explain what decision is needed first.

SECTION 9 — Visual examples and screenshot guidance

Define how to produce visual examples without creating fake product UI.

Include guidance for:
- Color palette specimen
- Typography specimen
- Button/card examples
- Code block examples
- README header mock
- Landing page hero mock
- Docs page mock
- Social card
- Architecture diagram style
- Terminal screenshot style
- Empty/error/success states

For each, specify:
- Purpose
- Layout
- Content
- Dimensions
- Export format
- File path
- When it is actually worth creating

Avoid generating decorative screenshots that do not help implementation.

SECTION 10 — Brand voice and microcopy

Create a usable voice system.

Include:
- Voice principles
- Tone sliders
- Vocabulary to use
- Vocabulary to avoid
- Writing rules
- README intro style
- Docs explanation style
- Error message style
- Success message style
- Warning/caution style
- Release note style
- GitHub issue/PR style
- Social launch style

Provide concrete examples:

- One-line project description
- 140-character description
- GitHub repo description
- Hex.pm package description
- README opening paragraph
- Landing page hero headline
- Landing page subheadline
- Primary CTA
- Secondary CTA
- Three feature blurbs
- Three "why this exists" bullets
- Example error message
- Example empty state
- Example success state
- Example release announcement

Keep the voice technically credible. No hype unless the project genuinely earns it.

SECTION 11 — Landing page and docs blueprint

Produce a practical page architecture.

For a landing page, include:
- Hero
- Problem
- Solution
- Install snippet
- Minimal example
- Core benefits
- How it works
- Use cases
- Comparison or "why not just…"
- Documentation CTA
- GitHub CTA
- Community/contribution CTA
- Footer

For docs/README, include:
- Opening promise
- Installation
- Quickstart
- Example
- Concepts
- API overview
- Common recipes
- Troubleshooting
- Design rationale, if relevant
- Contribution
- License

Tie each section back to the brand voice and visual system.

SECTION 12 — Repo-ready artifact plan

Create a source-control-ready plan.

Recommend a directory structure like:

brand/
  README.md
  brand-book.md
  tokens.json
  tokens.css
  logo-primary.svg
  logo-mark.svg
  favicon.svg
  social-card.svg
  examples/
    palette.svg
    typography.svg
    readme-header.svg
    landing-hero.svg
    docs-page.svg

docs/
  brand-usage.md

assets/
  brand/
    ...

Include:
- Which files should be committed
- Which files should be generated
- Which files should not be committed
- Which files need manual review
- Which assets should be exported as SVG, PNG, or both
- Suggested naming conventions
- Suggested README links
- Suggested CI/lint checks, if useful

SECTION 13 — Prioritized action plan

End with a concise action plan.

Group actions into:

- Do now
- Do next
- Defer
- Do not do

Each action should be concrete and tied to value.

Avoid vague recommendations like "improve the color palette." Instead say exactly what to change and why.

SECTION 14 — Final quality gate

Provide a final checklist that answers:

- Could a designer build from this?
- Could an engineer implement from this?
- Could a maintainer keep it consistent?
- Could a contributor understand it?
- Could it support marketing without becoming cheesy?
- Could it survive dark mode, small sizes, docs pages, and social previews?
- Does it feel specific to this library?
- Does it avoid unnecessary brand thrash?

Important behavior constraints:

- Do not flatter the existing brand book unless it earns it.
- Do not invent false certainty.
- Mark assumptions explicitly.
- Prefer fewer, stronger recommendations.
- Be concrete.
- Be tastefully critical.
- Preserve good existing work.
- Do not recommend a full redesign unless the existing brand system truly fails.
- Do not create huge artifact lists for ego. Only recommend artifacts that will actually help.
- Favor durable, source-controlled, OSS-friendly artifacts.
- Avoid proprietary fonts or assets.
- Do not embed font files.
- Use license-safe font recommendations and document any licensing assumptions.
- If you propose imagery, make it reproducible and not dependent on copyrighted or hard-to-source visuals.
- If legal/trademark concerns appear, flag them as requiring human review rather than pretending to resolve them.

Your output should be comprehensive but not bloated. Every section should help us make the brand book more useful, more distinct, more buildable, or more maintainable.

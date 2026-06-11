# Scoria Brand Book

**The canonical brand guide** — the source of truth for identity, copy, color, type, and voice.
Every line here is meant to be buildable: if a section does not help someone make a real
decision, it does not belong.

Companion artifacts: `tokens.css` / `tokens.json` (the design tokens), `examples/*.svg` (visual
specimens), `index.html` (the standalone brand book), `pressure-test.md` (historical QA record —
the audit whose verdicts this guide absorbed), and the eight shipped logo SVGs at the root of
`brandbook/`.

---

## 1. Identity & positioning

### Essence

**Volcanic clarity for production AI systems.** AI runs are porous — prompt renders, model
calls, tool calls, retrieval events, guardrails, eval scores. Scoria makes that internal
structure visible, inspectable, and governable. The name is a real geological material: dark,
pressure-formed cinder rock with visible internal cavities (vesicles). The cavities map to the
internal structure of an AI run. That is the whole metaphor, and it is load-bearing.

### Audience

Phoenix/Elixir backend engineers building chat, copilots, RAG, tool-using agents, or MCP
workflows. Specifically: small teams, indie engineers, and platform/SRE engineers who need to
debug, replay, and govern AI behavior in production. **Not** enterprise compliance buyers, AI
researchers, or Python-first developers. Operator-first DX: batteries-included tooling with
observable, auditable defaults.

### The archetype: field engineer, not oracle

Scoria is the person who catches the regression before it ships — not the one who promises to
eliminate regressions forever. Grounded, composed, operator-grade. The emotional target is
**calm during an incident.** Not exciting. Not aspirational. Reliable.

This should feel like Phoenix LiveDashboard, Oban Web, a trace waterfall, a lab console, a
field notebook during a production incident — a control room that stays calm when things break.
It should **never** feel like a chatbot toy, a generic AI SaaS dashboard, a crypto console, a
sci-fi HUD, or a startup promising to "revolutionize" AI. Explicit competitors to differentiate
from: Arize Phoenix, Langfuse, Braintrust — all modern blue-purple SaaS. Scoria's dark-basalt-first,
warm-accented register is deliberately different.

### Personality traits

- **Grounded** — claims are evidence-based: the UI shows traces, scores, costs, versions, policies
- **Composed** — stays calm when runs fail, tools are blocked, or evals regress
- **Operator-grade** — built for production debugging, not demos
- **Open-source practical** — clear docs, copy-pasteable examples, no corporate fog
- **Volcanic not fiery** — warmth and texture are allowed; flames and lava gimmicks are not
- **Technical but humane** — uses real terms (trace, span, scorer, baseline, policy) and defines them

### Anti-traits (hard prohibitions)

Magical / autonomous-feeling · hype-coded ("revolutionary," "10x," "sentient") · phoenix-bird or
flame imagery · generic AI aesthetics (neon blue-purple, glassmorphism, sparkles) · black-box
oracle positioning · enterprise compliance drag.

### Naming rule (binding)

- **Product name: Scoria.** Never "Scoria AI", "ScoriaAI", "SCORIA", or "Scoria Platform".
- **Package atom: `:scoria`.** Never `:scoria_ai`.
- **Feature names (unchanged):** Trace Explorer, Eval Workbench, Prompt Registry, Replay
  Playground, Tool Governance, MCP Gateway.

### Suite context

Scoria is part of the **szTheory Elixir ecosystem** alongside Threadline (audit), Sigra (auth),
Chimeway (notifications), and Parapet (SRE). Each library is visually distinct but shares a
common typographic system (IBM Plex Sans / JetBrains Mono) and an operator-first DX philosophy.
This belongs in the README design-rationale section and §1 here — not in the product UI.

### Tagline hierarchy

- **Primary tagline: "AI ops for Phoenix apps."** — the canonical one-phrase descriptor.
  Use anywhere a single short line is required: subtitle lockup variant, Hex.pm description
  prefix, social-card footer, GitHub repo description.
- **Hero headline (secondary): "Trace the run. Prove the change. Ship the agent."** — the
  three-line verb-triplet treatment. Landing-page hero, launch post, README hero. Line 2 is
  the differentiator: most AI ops tools trace; fewer force you to prove before shipping.
- **Sticker / slide (secondary): "Make the fire inspectable."**
- **Full technical positioning (secondary):** "A Phoenix-native control plane for LLM traces,
  evals, prompts, tools, and MCP."

### One-liner

> Scoria is the Phoenix-native AI ops layer for LLM traces, evals, prompt versions, and tool
> governance.

Nouns ("LLM traces, evals, prompt versions") are scannable in a Hex.pm listing; the earlier
gerund form ("tracing, evaluating, replaying") read slower. "Tool governance" is more
distinctive than "governing LLM apps".

---

## 2. Ready-to-paste copy blocks

These are **final** — paste them verbatim into `mix.exs`, the GitHub repo description,
the README, HexDocs, and the landing page. Do not reduce any block to a "v1" or placeholder.

### 140-character description (Hex.pm `description:` field)

```
Phoenix-native AI ops: LLM traces, evals, prompt versions, replay, tool governance, and MCP workflows. Ecto-backed, LiveView-included.
```

*(136 chars — within Hex.pm's 140-char display. Hex.pm and the canonical tagline copy stay in sync.)*

### GitHub repo description

```
Phoenix-native AI ops: trace, eval, replay, govern. LLM runs, tool approvals, prompt versions, and MCP workflows wired into Phoenix + Ecto + LiveView.
```

### README opening paragraph

```
Scoria is a batteries-included Phoenix library for production AI features. It records every run — prompt renders, model calls, tool calls, retrieval events, approvals, and eval scores — as structured, queryable traces. You get a LiveView operator UI, an eval flywheel, a prompt version registry, and a tool/MCP governance layer, all wired into Phoenix, Ecto, and OTP without a black-box dependency.
```

### Landing-page hero headline

```
Trace the run.
Prove the change.
Ship the agent.
```

Three-line treatment; each line a complete verb phrase. This is the hero headline, distinct
from the primary tagline ("AI ops for Phoenix apps.").

### Landing-page subheadline

```
Scoria gives Phoenix teams observable, evaluable, production-grade AI ops: traces, evals, prompt versions, replay, and tool governance — wired into Phoenix, Ecto, and OTP.
```

### CTAs

- **Primary CTA:** `Get started` — *(not "Try Scoria", "Start free", or "Book a demo". The
  library is open source; adopters install it.)*
- **Secondary CTA:** `View on GitHub`

### Three feature blurbs

**Trace Explorer**

```
See inside every run.
Every prompt render, model call, tool call, retrieval event, and span is recorded as a structured trace. Filter by actor, latency, cost, or eval outcome. Replay any run with a different prompt or model.
```

**Eval Workbench**

```
Prove it before you ship it.
Score runs against baseline datasets. Detect regressions before they reach users. Promote candidates that pass; gate those that don't. The flywheel turns: production traces become eval datasets automatically.
```

**Tool Governance**

```
Approve tool calls. Govern MCP actions.
Dangerous tools require human approval. Non-dangerous tools run automatically. Every approval, denial, and policy version is recorded in the trace. You decide what "safe enough to autoship" means.
```

### Three "why this exists" bullets

```
• Phoenix teams building AI features needed production observability, not just a logging wrapper.
• Every AI incident Scoria was designed to prevent has the same cause: invisible behavior. Show the structure.
• Governance is not a feature you add later. Tool approvals, eval gates, and prompt versions belong in the runtime, not bolted on after the fact.
```

### Microcopy — error / empty / success

**Error message** (correct voice):

```
Run failed during lookup_order.
The tool returned 403 for actor usr_184. Policy refunds_v7 requires actor to have :ops role. Trace ID: trc_8f2a.
[View trace]  [Open policy]
```

**Empty state:**

```
No eval datasets yet.
Promote a production trace to start building a regression suite, or add a test case manually.
[Promote a trace]  [Add manually]
```

**Success state:**

```
Candidate promoted.
support_refunds@v4 is now the baseline. 12 new dataset items captured from this run.
[View eval history]
```

### Release announcement

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

## 3. Logo & mark system

Eight SVG variants ship at the root of `brandbook/`. The mark does not sit beside the wordmark —
it is **fused into it as the 'o' in "Scoria"**, so the logo is one object, not an icon plus text.
The mark itself is a porous cinder whose vesicle holes trace a downward span rail
(root → LLM → tool → eval): the brand metaphor at every size, including the 16px favicon.
**The geometry is canonical** — recolor and derive from it; never redraw it.

### The eight variants

| File | Role |
|---|---|
| `logo-primary.svg` | Fused lockup, **dark** ground (two-tone) — landing, README hero, OG image |
| `logo-primary-light.svg` | Fused lockup, **light** ground (two-tone) — docs header, light marketing |
| `logo-mark.svg` | Mark only — favicon source (≥20px), sidebar, package avatar |
| `logo-monochrome.svg` | Single-`currentColor` fused lockup — any ground, print, embeds |
| `logotype-integrated.svg` | Byte-identical to `logo-monochrome.svg` (the fused lockup *is* the integrated typemark) |
| `favicon.svg` | 16px-tuned mark: 3 holes, even-grid snap, all radii ≥1.5px at 16px |
| `social-card.svg` | OG/Twitter card, `1280×640` (the one documented `<rect>` exemption) |
| *mono pair* | Dark mark / light mark on transparent, derived from `logo-mark.svg` |

### Two-tone primary rule (ship)

The primary lockup is **two-tone**: surface-ink letters with the mark-'o' in the brand accent.

| Surface | Letters | Mark-'o' |
|---|---|---|
| Dark (`logo-primary.svg`) | White-Hot `#FFF9F3` | Ember-500 `#E65A32` |
| Light (`logo-primary-light.svg`) | Basalt-950 `#11100F` | Scoria-600 `#B94F31` |

The accent 'o' is ~7% denser than the round letters — within the band that reads as a
*deliberate focal accent*, not as a heavier glyph. The color, not weight, carries the accent.
`logo-monochrome.svg` and `logotype-integrated.svg` are single-tone by definition.

The wordmark letterforms are IBM Plex Sans SemiBold (600) converted to outlines — the logo
SVGs are self-contained and never require the font to be installed.

### Monochrome usage

`logo-monochrome.svg` is drawn in `currentColor`: one artwork that takes whatever ink you give
it. There is no separate black file and white file.

- **When:** single-ink contexts only — print, engraving and embossing, stamps, partner
  co-branding strips, embedded badges, and anywhere brand color is unavailable or would clash.
  When full color is available, use the two-tone primary; monochrome is the fallback, never
  the default.
- **Which ink:** near-black Basalt-950 `#11100F` on light grounds; warm white White-Hot
  `#FFF9F3` on dark grounds. Never mid-gray, and never an ink that fails 3:1 contrast against
  its ground.
- **Embedding:** loaded via `<img>`, `currentColor` renders black — fine on light surfaces.
  On dark surfaces, inline the SVG (or reference it with `<use>`) so it inherits the CSS
  `color` you set.

### Usage rules

- **Clear space = cap-height / 2 ≈ 38.4u** of empty margin on all four sides of the lockup
  bounding box. No element, text, or edge intrudes. (An acceptable looser approximation is
  "1.5× the largest vesicle ≈ 21.9u"; the cap-height/2 rule ships because it scales with the
  lockup, not with a single internal feature.)
- **Minimum sizes:** primary lockup **≥120px wide**; mark alone **≥20px** (below this the
  trace-tree holes merge); favicon **exact at 16px and 32px**.
- **Logotype optically tight to mark** — the mark is fused as the 'o'; the word reads as one object.

### Misuse (do not)

- No rectangular / square / circular **background container** behind the mark. The silhouette
  IS the shape; holes are punched with `fill-rule="evenodd"`. (The only `<rect>` exemption is
  `social-card.svg`, where the card itself is the bounded artwork.)
- No subtitle or tagline inside the **primary** lockup. A separate stacked subtitle variant
  (`[mark] / Scoria / AI ops for Phoenix apps.`) is allowed only for social cards and stickers.
- No redrawing hole coordinates, no added strokes, no recoloring outside the two-tone pairs.
- No phoenix bird, flame, or "S" monogram substitution.

---

## 4. Color

The palette is **fixed**. A 52-pairing WCAG audit (`tools/contrast-check.mjs`)
found zero FAIL verdicts. Hex values here are identical to `assets/css/02-tokens.css` (the
dashboard runtime SSOT) and `brandbook/tokens.css` (the docs/marketing SSOT). The warm,
dark-first volcanic palette is a genuine differentiator — do not redesign it.

### Primitives

**Dark neutrals (basalt / char / graphite):**

| Token | Hex | Use |
|---|---|---|
| Basalt-950 | `#11100F` | App ground (dark) |
| Basalt-900 | `#181513` | Panel (dark) |
| Char-850 | `#211C19` | Raised panel, diagram nodes |
| Graphite-700 | `#3A332F` | Borders, connecting lines |
| Surface-sunken | `#0C0B0A` | Code block / terminal ground (dark) |

**Warm text scale (pumice / tuff / ash / white-hot):**

| Token | Hex | Use |
|---|---|---|
| Pumice-500 | `#88786D` | Muted metadata **only** (see constraint below) |
| Muted-warm | `#BDAEA3` | Muted text (dark) |
| Tuff-300 | `#CDBBAC` | Neutral tone fg, soft borders |
| Ash-100 | `#EFE6DE` | Body text (dark, on panel) |
| Ash-50 | `#FAF5EF` | App ground (light) / main text (dark) |
| White-Hot | `#FFF9F3` | Panel (light) / highest-emphasis text (dark) |

**Warm brand scale (scoria / ember / molten / cinder):**

| Token | Hex | Use |
|---|---|---|
| Scoria-900 | `#3B1912` | Deepest brand wash |
| Scoria-700 | `#8D3826` | Brand tone fg (light), outlines |
| Scoria-600 | `#B94F31` | Action / link (light), mark-'o' (light) |
| Ember-500 | `#E65A32` | Action / link (dark), mark-'o' (dark) — the signature accent |
| Molten-400 | `#FF7A4D` | High-emphasis, focus ring (dark), code keywords |
| Cinder-100 | `#F8D6C8` | Code strings, soft warm wash |

**Functional accent pairs (light / dark):**

| Role | Light fg | Dark fg | Use |
|---|---|---|---|
| Success (pass) | `#536A39` | `#A7C76F` | Eval pass, healthy span |
| Info | `#2A6C69` | `#7DD8D1` | Notes, atoms in code |
| Warning | `#7A5A16` | `#FFD166` | Caution, degraded |
| Danger (fail) | `#9E2F20` | `#FF6B4A` | Eval fail, errored span |
| Trace | `#6A55A7` | `#B798FF` | Trace/span emphasis |

### Semantic roles

`surface-app / -panel / -panel-raised / -sunken / -overlay` · `text / -muted / -subtle /
-onaccent` · `link / -link-hover` · `border / -border-strong` · `action / -action-hover /
-action-fg / -danger-action` · `focus-ring` · `code-*` · `callout-*`. Dark is the default;
light is a full semantic re-point. The light panel background (`#FFF9F3` White-Hot) is
**intentionally warm** — never substitute neutral `#FFFFFF`; it breaks the palette warmth.

### The domain differentiator: tone & span-kind families

The biggest design-token differentiator vs. generic design systems is the **tone** family
(`--scoria-tone-{neutral,pass,info,warn,fail,trace,brand}-{fg,bg,border}`) and the **span-kind**
family (`--scoria-span-{agent,llm,prompt,tool,mcp,retriever,guardrail,eval,error,redacted}`).
These reflect the product's domain — the eval lifecycle and the span taxonomy — and are a
first-class system feature, not a CSS afterthought. Use them; do not invent ad-hoc status colors.

### Contrast constraints that matter

The full 52-pairing table lives in `index.html`. Two constraints are load-bearing:

- **Pumice-500 / `--scoria-text-subtle` (`#88786D`) is PASS-LARGE only** (3.91–4.48:1 across
  all four surfaces — counterintuitively *closer* to the AA boundary on light than on dark).
  Use **only** for muted UI metadata: 12–13px monospaced trace IDs, timestamps, icon labels,
  sort indicators. **Never** for running body text, names, or user-generated content.
- **Scoria-600 on Basalt-950 = 3.82:1 — PASS-LARGE (negative control).** Do not use Scoria-600
  as normal-size dark-mode body text. It is a links/actions color on *light* surfaces.

All other 46 pairings are PASS-AA. No emergency propagation to `assets/css/02-tokens.css` is
required on accessibility grounds.

### Token propagation policy

`assets/css/02-tokens.css` (`.scoria-root`-scoped) is the **runtime SSOT**; `brandbook/tokens.css`
(`:root`-scoped) is the **docs/marketing SSOT**. Hex values must stay identical (enforced by
`tools/check-consistency.mjs`). **Only** WCAG AA failures, accessibility defects, or genuine
coherence breaks trigger a propagation pass to the runtime tokens — never cosmetic preference.
Rationale: a token change requires a DS-06 test-baseline update; that cost is only justified by
material failures. The current audit (`tools/contrast-check.mjs`, 52 pairings) found none.

---

## 5. Typography

**IBM Plex Sans + JetBrains Mono — two typefaces, never a third.** Plex Sans is technically neutral,
license-safe (OFL), and consistent across the szTheory ecosystem. JetBrains Mono is designed
for developer contexts and handles Elixir identifiers, trace IDs, model IDs, and token counts well.

Font stacks (use these literal fallback chains in any host page):

```css
--scoria-font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif;
--scoria-font-mono: "JetBrains Mono", ui-monospace, "SFMono-Regular", monospace;
```

**Weights:** Regular (400) body, Medium (500) UI labels, SemiBold (600) headings & wordmark,
Bold (700) display only. Restraint is the rule — no weight below 400, no decorative weights.

**Type scale (marketing + product UI):**

| Role | Size | Token |
|---|---|---|
| Display / hero | 56px | `--scoria-fs-display` |
| Page title | 24px | `--scoria-fs-title` |
| Panel title | 18px | `--scoria-fs-panel` |
| Table / body | 14px | `--scoria-fs-body` |
| Metric number | 30px | `--scoria-fs-metric` |
| Badge | 11px | `--scoria-fs-badge` |
| Code / meta | 12px | `--scoria-fs-label` |

Trace IDs, span labels, timestamps, token counts, and code are **always** JetBrains Mono.
Optional accessibility mode: Atkinson Hyperlegible as a docs/UI opt-in body font — not the
default, not a priority until a user need is documented.

---

## 6. Voice & microcopy

**Voice formula: calm + exact + useful.** This is the strongest part of the brand and the
canonical anchor — when a new surface ships, write 2–3 microcopy examples in this format
*before* writing any landing-page copy for it. The risk is drift from non-technical
collaborators, not the starting point.

### Principles

1. **Say what happened** — specific diagnostics over vague errors.
2. **Prefer evidence verbs** — traced, scored, compared, replayed, promoted, gated, approved, denied.
3. **Do not anthropomorphize the model** — "Running support_agent: rendering prompt, calling
   model, waiting for tool result" — never "The AI is thinking."
4. **Do not expose hidden chain-of-thought** — show process summaries, not private reasoning.
5. **Make safety & governance normal** — tool approval is part of the workflow, not an alarm.

### Say this, not this

| Say this | Not this |
|---|---|
| Run failed during `lookup_order`. The tool returned 403 for actor usr_184. | Something went wrong. |
| support_refunds@v4 is now the baseline. | Successfully updated! |
| No eval datasets yet. Promote a production trace to start a regression suite. | Nothing here. |
| Running support_agent: rendering prompt, calling model, waiting for tool result. | The AI is thinking… |
| 3 tool calls require approval. | Action needed! ⚠️ |
| Scored 47/50 against baseline `support_v3`. 3 regressions. | Evaluation complete. |

### Word bank

Use the product's domain language: **runs, spans, traces, evals, scorers, baselines, prompts,
prompt versions, approvals, denials, policies, connectors, replay, promote, gate, redaction.**
Avoid: revolutionary, seamless, powerful, next-generation, magic, autonomous, hallucination-free, 10x.

### Microcopy styles

Real Scoria nouns, every state. Error states name the run, the span, the actor, the policy, and
the trace ID. Empty states offer the next action. Success states state the concrete change and a
number. (Final examples: see §2 copy blocks — those are the canonical anchors.)

---

## 7. UI guidance

The shipped dashboard components live in `lib/scoria_web/ui.ex` — that file is the implementation
SSOT for buttons, cards, badges, the Trace Explorer, and the Eval Workbench. This section governs
brand expression, not component anatomy.

### States

Every interactive element has an explicit state token set: `default / hover / active / focus /
disabled / selected`. Hover/active/selected resolve to ember (dark) / scoria-600 (light) tints;
disabled is `opacity: 0.38` + `cursor: not-allowed`.

### Status is never color-only

**Every badge and span carries a text label** (Pass, Fail, Warning, Pending) visible at all
times. Color is secondary confirmation, not the primary differentiator. Scoria-600 span chips
pair with a legible text label — the chip is decorative. This is a hard accessibility rule.

### Code blocks & terminals

Code blocks use `--scoria-code-bg` (`#0C0B0A` dark / `#F1E8DE` light) with Elixir syntax mapping:
atoms in Info-dark `#7DD8D1`, strings in Cinder-100 `#F8D6C8`, keywords in Molten-400 `#FF7A4D`,
comments in Pumice-500 `#88786D`, modules in Ash-50 `#FAF5EF`. Terminals: ground `#0C0B0A`,
prompt `$` in Ember-500, command in Ash-50, output in Pumice-500. No fake dramatic output — real
`mix scoria.install` results only.

---

## 8. Landing page & docs blueprints

### Landing page (section order)

1. **Hero** — dark basalt ground; the verb-triplet headline; subheadline; `Get started` +
   `View on GitHub`; a genuine run-tree SVG schematic (span-kind colors), never a fake screenshot.
2. **Problem** — "AI behavior is invisible by default." Three bullets: you see the answer not the
   run; regressions are invisible until a ticket; tool policies live in code comments.
3. **Solution** — "Make the fire inspectable." Three cards: Trace → Eval → Govern.
4. **Install** — `{:scoria, "~> 0.2"}`, then `mix scoria.install` + router mount, dark code block.
5. **Minimal example** — a 6-line `Scoria.run/2` call, explained in two sentences, no padding.
6. **Core benefits** — traces are Ecto records; evals gate deployments; tool approvals are first-class.
7. **How it works** — flywheel SVG: Capture → Annotate → Promote → Evaluate → Compare → Gate →
   Deploy → Monitor. Static diagram, not animated.
8. **Use cases** — four cards, each one sentence + one `Scoria.run/2` variant. No screenshots.
9. **Why not Langfuse / Arize Phoenix / Braintrust?** — factual comparison table (Phoenix-native,
   Ecto-backed, LiveView-included, tool governance). Caption: not a replacement for every tool;
   the right choice when your stack is Phoenix and you need governance-first embedded AI ops.
10. **Footer** — mark (24px) + wordmark, links: Docs · GitHub · Hex.pm · License.

### README (binding order)

Promise (lockup + one-liner + badges) → Installation → Quickstart (10-line `Scoria.run/2`) →
Example (one agent, one eval, one tool policy in ~30 lines) → Concepts (Runs, Traces, Evals,
Prompt Versions, Tool Policies) → API overview (link to HexDocs, do not reproduce) → Common
recipes (replay, promote, gate, approve) → Troubleshooting (5 gotchas with exact errors) →
Design rationale (why Phoenix-native, why Ecto-backed) → Contribution → License.

**README badges (left to right, standard shields.io, no custom Ember fills):**
Hex.pm version · CI · License. Optionally HexDocs. Tone: every section reads like a colleague
wrote it — not a landing page, not a manual. Clear, fast, useful.

---

## 9. Accessibility

- **WCAG 2.1 AA** is the target; all 52 shipped pairings clear AA for their context of use.
- **Pumice-500 / text-subtle** is PASS-LARGE only — muted metadata, never running text (§4).
- **Focus ring:** minimum 2px solid, 2px offset, `--scoria-focus-ring` (Molten-400 dark /
  Scoria-600 light). Never suppress focus styles.
- **Status is never color-only** — every badge/span has a text label (§7).
- **Non-text UI contrast** (icons, borders, chips) clears the WCAG 1.4.11 ≥3:1 threshold.
- Light panel stays warm (`#FFF9F3`) — a deliberate brand decision, not an oversight.
- On mobile (<640px), collapse the run-tree hero to a single highlighted span card and the
  flywheel to a vertical list.

---

## 10. Do / Don't

**Do**

- Lead with evidence: traces, scores, costs, versions, policies.
- Use real domain nouns (runs, spans, evals, prompts, approvals, connectors).
- Keep the palette dark-first and warm; reserve the ember 'o' for the primary lockup.
- Pair every status color with a text label.
- Keep copy calm, exact, useful — say what happened, then the next action.
- Treat `brandbook/` as SVG/text only; regenerate logos from `tools/`, never hand-edit geometry.

**Don't**

- Don't write "Scoria AI", add a tagline to the primary lockup, or substitute an "S" monogram.
- Don't use phoenix birds, flames, lava gimmicks, neon blue-purple, glassmorphism, or sparkles.
- Don't use Pumice-500 or Scoria-600 for normal-size body text on dark.
- Don't substitute neutral white for the warm `#FFF9F3` panel.
- Don't anthropomorphize the model or expose hidden chain-of-thought.
- Don't ship raster brand artifacts (PNG/WebP) or commit intermediate WIP SVGs.
- Don't touch `assets/css/02-tokens.css` for cosmetic preference — propagation is gated on
  material WCAG failures only.

---

*Canonical guide. Copy blocks in §2 are final — paste them verbatim.*

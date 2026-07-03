---
id: SEED-005
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as docs / DX / adoption / Hex-release readiness
scope: large
enriched: 2026-07-03 (jargon catalog + szTheory blueprint + clean-spot diagnosis, from a 3-agent research session)
enriched_2: 2026-07-03 (terminology benchmarked vs peer tools; maintainer chose FULL sense-aware rename — see Final Canonical Rename Map)
enriched_3: 2026-07-03 (AI-eval posture audit added scope doctrine, persona strategy, differentiators + 5 docs deltas — see "Positioning & Scope Doctrine")
---

# SEED-005: Documentation overhaul → clean Hex release

> **Numbering note:** `SEED-004` is reserved for the deferred **test-code determinism**
> work (async `IntegrationCase`, `Process.sleep`→`eventually/2`, raise shard count) —
> referenced across `STATE.md`, `PROJECT.md`, `REQUIREMENTS.md`, `MILESTONES.md` though no
> file exists yet. This docs seed took the next free id, `005`, to avoid collision.

## Why This Matters

Scoria's docs read **jargon-first**. Load-bearing terms — **"run", "operator",
"evidence"** — are used before they are ever defined, and the README front-loads coined
vocabulary (**"adoption lanes", "default runtime", "bounded handoff", "semantic fast path",
"optional knowledge", "boring", "projected context", "grounding"**) before a newcomer knows
what Scoria even is. Docs are the adoption funnel; this jargon blocks **both humans and the
LLMs** that increasingly read docs to help people adopt a library. Hex is stuck at **0.1.2**
and the next release is overdue. The maintainer wants a systematic overhaul — learning from
their own best-in-class published Elixir libs — to make Scoria clear and *"AI-accessible
while still technically correct"*, then get the repo to a clean spot and cut a fresh Hex
release.

**The single most valuable artifact this milestone produces is a plain-English opening
paragraph. Here it is, ready to drop in:**

> **Scoria** is an Elixir/Phoenix library you add to an *existing* Phoenix app to run
> AI/LLM work **durably and inspectably**. Every **run** — one execution: a prompt render,
> model call, tool call, retrieval, approval, or eval score — is recorded as a queryable
> Postgres/Ecto **trace**. A mounted LiveView dashboard at **`/scoria`** lets a human
> **reviewer** inspect, debug, approve, and resume that work. Scoria runs entirely inside your
> app's BEAM; it is **not** a hosted SaaS agent platform.
>
> *(Terminology note: uses the post-rename vocabulary — see Final Canonical Rename Map. Old
> terms map: reviewer←operator, trace←evidence[surface sense].)*

*Who it's for:* Phoenix teams shipping production AI features who want runtime governance,
durable workflow state, human-in-the-loop approvals, and reviewer-visible traces — without
adopting a black-box third-party agent platform. *Problem it solves:* AI features are
normally opaque and hard to debug/audit/resume; Scoria gives one boring, inspectable way to
start, resume, debug, and verify identity-aware AI work.

## Positioning & Scope Doctrine (from 2026-07-03 eval-posture audit)

A 6-agent adjudicated audit ([[SEED-006]]…[[SEED-011]]) validated Scoria's direction and produced
the positioning spine the docs rewrite must carry. **Category story:** LangSmith/Langfuse/Phoenix/
Braintrust all *observe* and are *a separate service you ship data to*; Scoria *governs inside the
request path* as *an embedded dependency* — the record never leaves your Postgres and the guardrails
actually stop things.

**Scope doctrine (6 principles) — "Scoria owns the verb (record, gate, surface, reconstruct); the host
owns the noun (identity, business truth, policy value, end-user)":**
- P1 — Scoria owns the durable *record*; host owns business truth (reference by host ID).
- P2 — Scoria owns the governance *mechanism* (budgets/breakers/gates/approvals); host supplies *policy values* via hooks. **Hooks, not opinions.**
- P3 — Scoria owns the *reviewer/operator* surface (`/scoria`); host owns the *end-user* surface.
- P4 — Identity/authz are *delegated by reference, never modeled*.
- P5 — Everything persisted is reconstructable in the host's own Postgres/BEAM, **zero required egress** (anti-SaaS invariant).
- P6 — Prefer BEAM-native primitives (Ecto/Oban/PubSub/OTP/Telemetry); don't re-implement platform infra.
*(These belong in `.planning/PROJECT.md` as the decisions SSOT — add post-v3.3 to avoid the live-window collision; also flagged in [[SEED-006]].)*

**Persona strategy:**
- **CORE (first-class surface):** AI/product engineer, software architect, backend/platform, SRE/devops, reviewer/approver/operator, prompt-writers, eval-checkers, MCP-/workflow-configurers, model-pickers (mechanism only).
- **ADJACENT (hooks/docs, no dedicated surface):** Trust & Safety, security engineer, privacy/legal/compliance (the 3 highest-leverage underserved), data scientist, domain expert, feature PM, support/CS.
- **NOT-OURS (explicitly out of scope):** end user of the LLM flows, product designer of the host feature, finance/exec dashboards.

**Persona posture — roles-not-headcount (n=1 default):** the CORE roles above are *hats one person wears*, not separate people. Docs must speak to the **smallest-viable team (n=1)** — a solo SWE running an AI feature in their Phoenix SaaS with no dedicated ML/platform/T&S team — while degrading gracefully to a few (n=1 is the default *lens*, not an invariant). Now recorded in `PROJECT.md` Core Value; headline it in the "Who it's for" rewrite. Source: `.planning/research/ai-architectural-patterns.md`.

**Differentiators to headline:** embedded-not-SaaS (data ownership by default); governance that *blocks*, not observability that watches; **lethal-trifecta-as-policy** (the flagship bet — [[SEED-010]]); BEAM-native durable runs + branch-and-replay.

### 5 concrete docs deltas from the audit
- **(a)** Add an adopter-facing **"What Scoria owns vs what your app owns"** table (the scope doctrine made concrete — this IS the "without guessing where Scoria begins" promise).
- **(b)** Persona-scope "Who it's for" with an explicit **NOT-OURS** line (not for end users; not a FinOps/exec cost dashboard).
- **(c)** Reframe Phase C's comparison page as **"Scoria vs hosted LLM-ops (LangSmith/Langfuse/Braintrust)"** — lead with embedded / governs-in-path / no-egress; honestly cede warehousing + cross-language + eval-leaderboards via OTel export.
- **(d)** Governance value prop gets **teeth in paragraph one** (verb-forward: budgets/loops/breakers/tool-safety that *enforce*), and **headline the lethal-trifecta differentiator**: "the first embedded framework to enforce Meta's Rule-of-Two — when a run touches private data, untrusted content, and an exfil channel at once, it escalates to a human approver."
- **(e)** `operator→reviewer` rename aligns with the persona doctrine; keep "operator/on-call" for the SRE *job*, use "reviewer" for the *persona*.

**Direction note (sequencing):** the audit flagged that more dashboard polish is lower adoption-leverage
than this docs work — the *front door* is the bottleneck. Recommend **this docs milestone be the next
milestone after v3.3**, and note that the release cut (Phase E) is now **gated behind [[SEED-006]]** (P0
trust/security fixes) — new order: SEED-006 → this docs milestone's clean-spot/release → publish.

## When to Surface

**Trigger:** next milestone planning with a docs, DX, adoption, or Hex-release-readiness
theme. Surface during `/gsd-new-milestone` scope discovery.

## Scope Estimate

**Large** — a full milestone (≈5 phases, see breakdown). Mostly `README.md`, `docs/` +
`guides/`, `mix.exs` ExDoc config, `@moduledoc`s, plus a release-clean phase. Low product
risk (docs + config + git hygiene), high adoption payoff. The Hex release cut is gated on
the clean-spot phase.

## Deconfliction (READ BEFORE PLANNING)

This milestone owns **adopter-facing docs**: README, `guides/`, glossary, ExDoc sidebar
grouping, public `@moduledoc`s, and a curated `llms.txt`/`AGENTS.md`.

The **current v3.3 milestone's Phase 41 ("Proof, Docs, And Regression Guardrails") owns
maintainer/design-system docs** (BEM/tokens/headers/overlays/fixtures/motion/a11y/screenshot
proof). **Do not duplicate or collide.** If v3.3 has shipped by the time this surfaces,
verify what Phase 41 actually produced and build on it rather than redoing it.

## Docs sequencing & interleaving (reconciled with the eval-posture roadmap, 2026-07-03)

This milestone ships ONLY the **stable adopter docs** that don't go stale as [[SEED-006]]…[[SEED-011]]
build features. **Feature-specific docs are interleaved** — written as each feature lands, and they
already live as doc-deltas INSIDE their build seeds. Do NOT pre-write feature guides here (that was the
obsolescence risk).

- **STABLE — in scope for this milestone (Phases A–D below):** terminology sense-aware rename, README
  first-screen + plain-English what/who/why, the **owns-vs-delegates / scope-doctrine** table + persona
  NOT-OURS line + the "vs hosted LLM-ops" comparison reframe (the 5 audit deltas above), ExDoc
  grouping/structure, glossary, curated `llms.txt`. These are the adoption bottleneck; independent of
  feature build order.
- **BUILD-DEPENDENT — write in the owning build milestone, NOT here:** RAG eval guide → [[SEED-009]];
  tool/trifecta governance + `SECURITY-BOUNDARY.md` → [[SEED-010]] (+ [[SEED-006]]); the
  "OpenInference-compatible" trace claim (only flip it once true) → [[SEED-007]]; retention/feedback/
  privacy guides → [[SEED-011]]; the "trustworthy eval" story → [[SEED-006]]/[[SEED-008]].
- **Release cut (Phase E) is GATED behind [[SEED-006]]** (P0 trust/security fixes). Cadence:
  SEED-006 → this docs milestone + release cut → feature milestones.

## Proposed Milestone Phase Breakdown (draft for `/gsd-new-milestone`)

- **Phase A — Terminology rename + first-screen clarity.** Execute the **Final Canonical
  Rename Map** (see "Terminology Strategy — DECIDED" below) in the code-rename-before-docs order
  specified there: `operator`→reviewer, sense-aware `evidence`→trace, `lane`→capabilities +
  verification suites, scoped context / semantic cache / knowledge base. Drop the plain-English
  what/who/why paragraph (above) atop the README, *before* any coined vocabulary; define KEEP
  terms on first use. Add a **Glossary** guide mapping each final term → industry equivalent
  (doubles as LLM grounding — see Phase D). Scrub leaked code-names (**"Keystone"**
  `docs/phoenix_runtime_example.md:3`, **"v2.0 Relay"** `docs/bounded_handoffs.md:142`); fix the
  "Four Lanes"-lists-five bug. Bump stale README version (`0.1.1` → current) at `README.md`
  ~60, ~279. Ship a CHANGELOG breaking-change entry + short upgrade note.
- **Phase B — ExDoc structure.** Add `mix.exs` module attrs (`@version/@source_url/
  @source_ref/@hexdocs_url/@release_docs_url`) with `source_ref` falling back to `"main"` for
  `-dev` versions (avoids "View source" 404s). Add **`groups_for_modules`** (by domain area —
  Runtime, Eval, Knowledge, Orchestrator, Connectors, SRE, Install, Web/LiveView, Internals)
  and **`groups_for_extras`** (Diátaxis or audience buckets). Point `main:` at the best
  first-success page (not necessarily README). Add `logo`/`favicon` from `brandbook/assets/`,
  `formatters: ["html","markdown"]`. Add `docs --warnings-as-errors` to the `ci:` alias so
  broken cross-links fail CI. *(Today `mix.exs` docs/0 ≈ lines 123–141 has none of this →
  ~200 modules + 9 guides render as one flat, ungrouped sidebar.)*
- **Phase C — Guides restructure (Diátaxis) — STABLE guides only.** Reshape `docs/`/`guides/` into
  `introduction/ flows/ reference/ recipes/` (+ `recipes/companion-libs/` cross-linking sibling
  szTheory libs). Add the **stable** archetypes: getting-started, golden-path, jtbd-and-user-flows,
  troubleshooting, a **comparison-vs-alternative** page (the "vs hosted LLM-ops" reframe from delta c),
  and a `cheatsheet.cheatmd`. Explain the *stable* LLM-integration basics (how you make a model call,
  where `req_llm` fits, what MCP governance does at a high level).
  **DEFER to build milestones (don't write here):** the RAG eval guide ([[SEED-009]]), the security/
  trifecta guide + `SECURITY-BOUNDARY.md` ([[SEED-010]]), the retention/privacy/feedback guides
  ([[SEED-011]]), the production-hardening checklist (depends on 010/011), and the
  "OpenInference-compatible" trace-capture claim — only assert it once [[SEED-007]] makes it true
  (until then use the softened wording from README delta, per [[SEED-007]]).
- **Phase D — AI-accessibility surface (first-class goal).** Author a **curated root
  `llms.txt`** (public facade + guides index — NOT the auto-generated `doc/llms.txt` build
  artifact) and/or an `AGENTS.md`, so the library is genuinely LLM-navigable. The Phase A
  glossary doubles as grounding here.
- **Phase E — Clean spot & release. ⛔ GATED behind [[SEED-006]] (P0 trust/security fixes) — do NOT
  publish before 006 lands.** Resolve the release blockers (below) → green; push / reconcile the
  unpushed `main` commits; prune stale branches; confirm green main CI; cut the next Hex release via
  release-please. The `bootstrap-elixir-hex-lib` skill codifies this pipeline.

## szTheory Docs Blueprint (breadcrumbs — what "best-in-class" looks like)

The maintainer's own published libs are the template. **Clone the combination of:**
`lattice_stripe` (best `groups_for_modules`, "Docs Ladder" + "Choose Your Route" README nav)
+ `sigra` (cleanest Diátaxis `guides/` tree: introduction/flows/reference/recipes) +
`scrypath` (versioned-link `mix.exs` package config, 4-audience `groups_for_extras`).

- **mix.exs pattern:** `lattice_stripe/mix.exs:4-5`, `:107-258` (module groups), `:275-277`
  (`docs_source_ref/0` "main"-for-dev guard), `:318-328` (`ci:` alias with
  `docs --warnings-as-errors`); `scrypath/mix.exs:4-8` (`@hexdocs_url`/`@release_docs_url`).
- **README canonical order:** brand header → italic tagline → 4 badges (Hex / CI / HexDocs /
  License) → one-paragraph what+why → in/out scope → requirements → demo → install →
  quickstart → **"Docs Ladder" + "Choose Your Route"** nav (reference-style links) →
  features-by-domain with guide links. See `mailglass/README.md:14-55`,
  `lattice_stripe/README.md:8-54`.
- **guides/ Diátaxis tree:** `sigra/guides/{introduction,flows,reference,recipes}/`; comparison
  guides like `oban_powertools/.../powertools-vs-oban-pro.md`, `mailglass migration-from-swoosh`.
- **moduledoc as mini-README:** summary → `## Getting Started` → `## Architecture` →
  `## Configuration`; doctests on pure public functions only (`sigra/lib/sigra.ex`).
- **Release automation** (already the house pattern here): release-please + hex-publish +
  release-PR auto-merge + `pr-title.yml`. Codified in the `bootstrap-elixir-hex-lib` skill.
- Local exemplar paths: `/Users/jon/projects/{lattice_stripe,sigra,scrypath,mailglass,relyra,oban_powertools}`.

## Clean-Spot Checklist (release blockers, pre-diagnosed 2026-07-03)

1. **PR #12 "chore(main): release 0.1.3"** — OPEN, `mergeStateStatus: UNSTABLE`,
   `mergeable`. A **duplicated CI run** where one copy FAILED (`verify/test`,
   `verify-summary`, `ci-gate` on run **`27834033548`**) while the parallel run passed
   identically → almost certainly the **known Postgres fixed-host-port flake** (see SEED-003
   flake #1, `-p 55432:5432` in `ci.yml` + `ci-verify.yml`). Re-run failed jobs
   (`gh run rerun --failed`), get green, let release-please auto-merge (or merge manually).
   **This is the primary release blocker.**
2. **Local `main` is ~90 commits ahead of `origin/main`, unpushed** (mostly `docs(...)`
   planning commits for phases 35–39). Biggest cleanliness signal. Decide: push as-is
   (`.planning/` is tracked, so it goes up) or filter via the `gsd-pr-branch` skill. Re-verify
   main CI after pushing.
3. **Stale branches to prune** — locals: `phase-72-hex-publish-enablement`,
   `worktree-agent-phase14-14-03-1781288251`. Origin (9 lingering): `chore/seed-003-flake-evidence`,
   `docker-dx-multi-instance`, `fix/ci-actions-node24-bump`, `fix/flaky-promote-component-test`,
   `phase-72-hex-publish-enablement`, `ui/design-system-overhaul`, `v2.17-brand-vesicle`,
   `v2.9-adoption-journey` (+ the release-please branch). Triage/delete already-absorbed ones.
4. **No open GitHub issues.** `.planning/` is intentionally **tracked** (not ignored) and
   `.gitignore` is well-scoped — **no gitignore work needed**.
5. **Do not touch the in-flight Phase 39 files** (`.planning/phases/39-component-groups-and-
   operator-flows/39-01-PLAN.md`, `39-PATTERNS.md`) — they belong to the other window's active
   work. A milestone-level clean cut isn't imminent until v3.3 finishes (was 50% at plant time).

## Full Terminology Inventory (so Phase A doesn't re-research)

Verdicts from the research session — for each term: is it defined? where? how bad?

| Term | Status today | Where | Verdict |
|---|---|---|---|
| **run** | Never plainly defined up front | inferable from `lib/scoria.ex` ("`run_id` is Scoria's exact durable handle for one run") | Define: "one execution of AI work." |
| **operator** | **Undefined** load-bearing term | only hint: `dashboard_nav.ex` ("grouped by operator job") | Define: the human inspecting `/scoria`. |
| **operator flows** | Internal planning only, not in adopter docs | `.planning/` Phase 39 | N/A to adopters. |
| **evidence** | Meaning emerges from usage, never stated | `docs/operator_verification.md`, `phoenix_runtime_example.md` | Define: the read-only inspection surface. |
| **default runtime** | Reasonably clear once you reach the lane guide | README:16-18, `docs/adoption_lanes.md` §1 | OK; define earlier. |
| **bounded handoff** | Best-defined term | `docs/bounded_handoffs.md:3` | Keep; but "projected context"/"lineage" are sub-jargon. |
| **semantic fast path** | Concept clear, vocabulary dense | `docs/semantic_fast_path.md` | Trim the 4 outcome nouns (hit/bypass/miss/reject) + 4 states. |
| **optional knowledge** | Clear enough; "grounding" undefined | README:21, `adoption_lanes.md` §4 | Define "grounding". |
| **adoption lanes** | Metaphor intuitive but never unpacked | `docs/adoption_lanes.md` | Define the "lane" metaphor explicitly, or reconsider it. |
| **component groups** | Maintainer/internal only | `docs/MAINTAINERS.md`, `.planning/` | N/A to adopters. |
| **"boring"** (as adjective) | Idiosyncratic; means stable/uneventful | pervasive | Keep sparingly or gloss it. |
| **projected context** | Core to handoffs, never plainly defined | `docs/bounded_handoffs.md` | Define: the least-privilege data slice. |
| **grounding / citations** | Undefined knowledge-lane jargon | knowledge guide | Define. |
| **Keystone / v2.0 Relay** | **Internal code-names leaked** into adopter docs | `phoenix_runtime_example.md:3`, `bounded_handoffs.md:142` | **Scrub.** |

## Terminology Strategy — DECIDED (2026-07-03): full, sense-aware rename

Benchmarked against peer tools (LangSmith, Langfuse, OTel GenAI, Temporal, LangGraph, OpenAI
Agents SDK, GPTCache, AWS/Azure/Google grounding, MCP spec). Scoria was ~55% aligned; the
strongest terms (`run`, `grounding`, `handoff`, `runtime`, `"boring"`) already sit on the
standard, the damage is concentrated in a few coined metaphors + one overloaded word (`lane`).
Maintainer chose a **full rename in one pass** with `lane`(capability) → **capabilities**.

**⚠ "evidence" is polysemous — the rename is SENSE-AWARE, not a global find-replace:**
- *Inspection/audit surface* sense ("operator evidence page", the `/scoria` run view) → **trace**.
- *Citation/grounding* sense (`evidence_refs` schema field, `citation_evidence_component`,
  `grounding_score`) → **KEEP "evidence"** — it's correct standard RAG usage. **No DB migration**
  (the only `evidence`-named persisted field, `evidence_refs`, stays under this sense).

**Blast radius (read-only grep, 2026-07-03):** `operator` = 116 lib (`.ex`/`.heex`) + 79 docs,
2 modules (`lib/scoria_web/operator_surface.ex`, `lib/scoria/observe/operator_broadcast.ex`),
no schema fields. `evidence` = 762 lib + 60 docs, 6 `*_evidence_component.ex` modules, 2
`evidence_refs` schema fields (RAG sense → kept).

### FINAL CANONICAL RENAME MAP (drives Phase A)

| Current | → Final | Sense / scope | Blast radius |
|---|---|---|---|
| `projected context` | **scoped context** | least-privilege slice to a delegate (Anthropic/LangChain term) | docs + keyword |
| `semantic fast path` | **semantic cache** | tenant-scoped answer reuse (GPTCache category) | docs + `Scoria.SemanticLane` |
| `optional knowledge` | **optional knowledge base** | RAG/retrieval capability | docs |
| `adoption lanes` / `lane` (capability) | **capabilities** | the thing you adopt | docs |
| `lane` (`mix test.X`) | **verification suite** | the proof command | docs |
| `operator` (persona) | **reviewer** | human who inspects/approves/resumes (avoids OpenAI "Operator" collision) | 116 lib + 79 docs; 2 modules |
| `evidence` (surface sense) | **trace** | the `/scoria` run inspection view (OTel/observability vocab) | subset of 762 lib + 60 docs |
| `evidence` (RAG sense) | **KEEP `evidence`** | citation/grounding sources | `evidence_refs`, citation/grounding comps |
| `evidence_refs` (schema field) | **KEEP** — RAG sense, no migration | — | — |
| cache outcomes | **hit/miss** primary; `bypass`/`reject` demoted to documented sub-states | — | docs |
| `"Keystone"`, `"v2.0 Relay"` | **remove** (leaked code-names) | — | 2 doc files |
| `"The Four Lanes"` (lists 5) | **fix count** → "Capabilities" | outright doc bug | `docs/adoption_lanes.md` |

**KEEP as-is, just define on first use:** `run` (≈LangSmith run), `grounding` (≈AWS/Azure),
`bounded handoff` (opt: → `scoped handoff` for consistency), `default runtime`, `approvals`,
actor/tenant/session `identity`, `"boring"` (sparingly). Brand: **"AI ops for Phoenix apps"
tagline stays** — only the *persona* renames (operator→reviewer), not the category.

### Revised Phase A execution order (code-rename BEFORE docs rewrite, so docs describe final names)
1. `operator`→reviewer (rename the 2 modules + UI copy).
2. Sense-aware `evidence`→trace for the **surface sense only** (run-inspection views); leave
   `evidence_refs` + citation/grounding components untouched.
3. Tier-1 renames (scoped context / semantic cache / knowledge base) + `lane`→capabilities +
   `mix test` "verification suite" language.
4. Scrub code-names; fix the four/five bug.
5. CHANGELOG breaking-change entry + short upgrade note (pre-1.0, renames acceptable).
6. THEN the docs/ExDoc/glossary/`llms.txt` phases describe the final vocabulary; glossary maps
   each final term → industry equivalent.

**Two defaults set with the maintainer away** (flip cheaply if wanted): sense-aware evidence
(vs. literal-all + migration) and `operator`→**reviewer** (vs. keeping "operator" for the
ops-console brand — only cost there is the OpenAI collision).

**Other decisions confirmed:** (a) this session = seed-only; (b) **dedicated** milestone (not
folded into Phase 41); (c) terminology strategy = **full sense-aware rename** (above);
(d) AI-accessibility surface = first-class yes.

## Breadcrumbs

- **Scoria docs surface:** `README.md` (288 lines, hexdocs landing), `docs/` (9 shipped
  extras: adoption_lanes, phoenix_runtime_example, bounded_handoffs, semantic_fast_path,
  operator_verification, connector_adoption, support_copilot_gallery, MAINTAINERS, +
  dev-only docker_dev_dx/uat_automation), `CHANGELOG.md`, `lib/scoria.ex` (strongest existing
  onboarding moduledoc).
- **ExDoc config to expand:** `mix.exs` `docs/0` (≈ lines 123–141), `package/0` (desc line
  ~120), `@version` line 4.
- **Version drift:** `README.md:~60` (`tag: "v0.1.1"`), `README.md:~279` ("Current release:
  `0.1.1`") vs `mix.exs:4` + `.release-please-manifest.json` + CHANGELOG top = `0.1.2`.
- **AI integration (undocumented):** deps `req_llm ~> 1.13`, `tiktoken`, `pgvector`;
  `lib/scoria/orchestrator.ex` ("recursive fallback for LLM requests"); README:272
  ("OpenInference-style trace capture").
- **Blueprint exemplars:** `/Users/jon/projects/{lattice_stripe,sigra,scrypath,mailglass,relyra,oban_powertools}`.
- **Release pipeline skill:** `bootstrap-elixir-hex-lib`. Seed exemplar shape: `SEED-003-ci-efficiency-overhaul.md`.
- **Full session plan:** `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`.

## AI-Architecture-Patterns cross-ref (2026-07-03)

Source memo: `.planning/research/ai-architectural-patterns.md` (a 14-pattern field guide + decision-tree
+ ladder + cheat-sheet). Highest adoption ROI of the whole ingest — this is the *front-door* concept.

- **Fold the pattern map into the "Choose Your Route" onboarding nav** (the szTheory blueprint's
  `lattice_stripe` "Docs Ladder"/"Choose Your Route" pattern, referenced above): a **"Which pattern is
  your AI feature? → which Scoria surface you'll use"** table. The memo's §17 architecture-ladder *is*
  that nav; §15 decision-tree, §16 "how these compose", §19 cheat-sheet, and §20 "taste test" are the
  content. Pure docs — P3/P5-safe.
- **Add two glossary disambiguation entries** (same class of naming-hazard the operator→reviewer rename
  already handles): **(1) `Orchestrator`** — `Scoria.Orchestrator` = single-call generation + model
  fallback chains (LOW agency) ≠ the memo's §9 "orchestrator-workers" pattern (HIGH agency, dynamic
  delegation). Prevents durable adopter mis-mapping the moment this memo becomes onboarding material.
  **(2) RAG-vs-agent (Rule 1)** — RAG answers *"what should the model know?"*; an agent answers *"what
  should the system do next?"*.
- **Ladder ethos in positioning:** Scoria supports the full ladder but defaults/educates toward
  workflows + RAG + tools + gates (Rule 4). Now a `PROJECT.md` Key Decision; carry it into the
  positioning page.
- Cross-ref §15 / §17 / §19 / §20. Sibling memo `prompts/ai-eval-best-practices-deep-research.md` is a
  candidate for the same ingest treatment later (not done yet).

## Operator-UI North-Star cross-ref (2026-07-03)

Source memo: `.planning/research/operator-ui-north-star.md` (from the operator-UI storyboard ingest).
The docs rewrite **owns the vocabulary + copy standards** that the [[SEED-013]] IA pivot depends on:
- **The "AI Feature" concept** — the operator-facing grouping object (`support_copilot`,
  `billing_refund_assistant`) that ties runs/prompts/evals/tools/knowledge/budgets/policies together.
  Glossary + positioning must define it as a **host-declared attribute Scoria segments by**, never a
  Scoria-modeled business noun (same posture as `archetype`/`route`/`intent`).
- **The operator-moments framing** (Orient → Act → Investigate → Recover → Improve → Govern → Audit) —
  the mental model the nav and docs onboarding ("Choose Your Route") should share.
- **Plain-language operator-grade copy standards** — consequence-first microcopy that always distinguishes
  **proposed / completed / blocked / approved / denied** ("Run paused before calling send_email. No
  external message has been sent."), so the operator knows whether damage happened or was prevented. This
  is a docs/positioning deliverable AND the copy contract the UI pivot enforces. No new work here beyond
  folding these terms + standards into the rename map + glossary + first-screen.

## Notes

Planted during v3.3 (design-system milestone, phase 39 live in a parallel window) from a
dedicated 3-agent research session (Scoria docs/jargon audit · szTheory blueprint extraction
· GSD-seed + repo-cleanliness diagnosis). The maintainer was away during the confirmation
questions, so this seed encodes the recommended defaults *and* flags the open decisions
(terminology strategy chiefly) for resolution at surface time. Enrich further with
`/gsd-capture --seed --enrich SEED-005` if the picture changes before it surfaces.

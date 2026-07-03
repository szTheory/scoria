---
id: SEED-005
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as docs / DX / adoption / Hex-release readiness
scope: large
enriched: 2026-07-03 (jargon catalog + szTheory blueprint + clean-spot diagnosis, from a 3-agent research session)
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
> model call, tool call, retrieval, approval, or eval score — is recorded as queryable
> Postgres/Ecto traces. A mounted LiveView dashboard at **`/scoria`** lets a human
> **operator** inspect, debug, approve, and resume that work — that read-only surface is the
> **evidence**. Scoria runs entirely inside your app's BEAM; it is **not** a hosted SaaS
> agent platform.

*Who it's for:* Phoenix teams shipping production AI features who want runtime governance,
durable workflow state, human-in-the-loop approvals, and operator-visible evidence — without
adopting a black-box third-party agent platform. *Problem it solves:* AI features are
normally opaque and hard to debug/audit/resume; Scoria gives one boring, inspectable way to
start, resume, debug, and verify identity-aware AI work.

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

## Proposed Milestone Phase Breakdown (draft for `/gsd-new-milestone`)

- **Phase A — Terminology & first-screen clarity.** Drop the plain-English what/who/why
  paragraph (above) atop the README, *before* any coined vocabulary. Define-on-first-use for
  run / operator / evidence / lane / projected context / grounding. Add a **Glossary** guide
  (doubles as LLM grounding — see Phase D). Scrub leaked internal code-names (**"Keystone"**
  in `docs/phoenix_runtime_example.md:3`, **"v2.0 Relay"** in `docs/bounded_handoffs.md:142`).
  Bump the stale README version (`0.1.1` → current) at `README.md` lines ~60 and ~279.
- **Phase B — ExDoc structure.** Add `mix.exs` module attrs (`@version/@source_url/
  @source_ref/@hexdocs_url/@release_docs_url`) with `source_ref` falling back to `"main"` for
  `-dev` versions (avoids "View source" 404s). Add **`groups_for_modules`** (by domain area —
  Runtime, Eval, Knowledge, Orchestrator, Connectors, SRE, Install, Web/LiveView, Internals)
  and **`groups_for_extras`** (Diátaxis or audience buckets). Point `main:` at the best
  first-success page (not necessarily README). Add `logo`/`favicon` from `brandbook/assets/`,
  `formatters: ["html","markdown"]`. Add `docs --warnings-as-errors` to the `ci:` alias so
  broken cross-links fail CI. *(Today `mix.exs` docs/0 ≈ lines 123–141 has none of this →
  ~200 modules + 9 guides render as one flat, ungrouped sidebar.)*
- **Phase C — Guides restructure (Diátaxis).** Reshape `docs/`/`guides/` into
  `introduction/ flows/ reference/ recipes/` (+ `recipes/companion-libs/` cross-linking sibling
  szTheory libs). Add the missing archetypes: getting-started, golden-path,
  jtbd-and-user-flows, troubleshooting, production-checklist, a **comparison-vs-alternative**
  page, and a `cheatsheet.cheatmd`. **Wire the currently-unexplained LLM-integration story:**
  how you actually make a model call, where `req_llm` fits, what "OpenInference-style trace
  capture" means, what MCP governance does.
- **Phase D — AI-accessibility surface (first-class goal).** Author a **curated root
  `llms.txt`** (public facade + guides index — NOT the auto-generated `doc/llms.txt` build
  artifact) and/or an `AGENTS.md`, so the library is genuinely LLM-navigable. The Phase A
  glossary doubles as grounding here.
- **Phase E — Clean spot & release.** Resolve the release blockers (below) → green; push /
  reconcile the unpushed `main` commits; prune stale branches; confirm green main CI; cut the
  next Hex release via release-please. The `bootstrap-elixir-hex-lib` skill codifies this
  pipeline.

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

**Decisions the maintainer had NOT confirmed at plant time** (research questions asked, user
away — resolve at surface time): (a) session scope confirmed seed-only; (b) dedicated
milestone vs fold into Phase 41 — planted as **dedicated**; (c) **terminology strategy**:
define-in-place + glossary (chosen default) vs aggressive rename/simplify vs hybrid — this is
the biggest open product-voice call, decide first; (d) AI surface first-class — chosen yes.

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

## Notes

Planted during v3.3 (design-system milestone, phase 39 live in a parallel window) from a
dedicated 3-agent research session (Scoria docs/jargon audit · szTheory blueprint extraction
· GSD-seed + repo-cleanliness diagnosis). The maintainer was away during the confirmation
questions, so this seed encodes the recommended defaults *and* flags the open decisions
(terminology strategy chiefly) for resolution at surface time. Enrich further with
`/gsd-capture --seed --enrich SEED-005` if the picture changes before it surfaces.

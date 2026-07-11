# Roadmap: Scoria

## Milestones

- ✅ **v2.15 Connector Adoption Lane** — named connector verification suite and docs/CI parity (shipped 2026-05-30)
- ✅ **v2.17 Vesicle** — Phases 18–22, canonical brand system (shipped 2026-06-11)
- ✅ **v3.0 Control Room** — Phases 11–17, dashboard design-system / IA / motion / proof (shipped 2026-06-14)
- ✅ **v3.1 CI/CD Velocity** — Phases 23–28, PR CI 77m → 7m38s (shipped 2026-06-17)
- ✅ **v3.2 Drydock** — Phases 29–35, Docker dev-DX hardening + `0.1.2` maintenance release (shipped 2026-06-19)
- ✅ **v3.3 Design System Stress Test** — Phases 36–41.1, `/scoria` UI coherence foundation→proof (shipped 2026-07-04)
- ✅ **v3.4 Pre-1.0 Trust & Security Hardening** — Phases 42–45, SEED-006 P0 trust/security gate (shipped 2026-07-09)
- ◆ **v3.5 Documentation & Release Readiness** — Phases 46–50, SEED-005 stable docs + clean `0.1.3` release (active)

## Phases

### v3.5 Documentation & Release Readiness — ACTIVE

**Goal:** Make Scoria adoption-ready again after the v3.4 trust/security fixes by replacing jargon-first adopter docs with stable positioning, repairing release-blocking CI/browser drift, and cutting the honest `0.1.3` Hex release.

**Selected seed:** `SEED-005 Documentation overhaul → clean Hex release`.

**Boundary:** Stable adopter docs and release readiness only. Feature-specific docs for trace foundation, lethal-trifecta governance, eval depth, retrieval depth, and privacy/feedback stay with their owning future seeds.

- [x] **Phase 46: Terminology and public vocabulary migration** — final sense-aware rename map, glossary, code-name cleanup, and upgrade note. (completed 2026-07-09)
- [x] **Phase 47: README first-screen positioning and scope doctrine** — plain-English front door, persona/not-ours framing, owns-vs-delegates table, and hosted LLM-ops comparison. (completed 2026-07-10)
- [x] **Phase 48: ExDoc and guide ladder restructure** — grouped modules/extras, version-aware docs metadata, stable guide tree, and public moduledoc alignment. (completed 2026-07-10)
- [ ] **Phase 49: AI-accessible docs and docs verification gate** — curated `llms.txt`/`AGENTS.md`, guide index for coding agents, and warning-clean docs command.
- [ ] **Phase 50: Release readiness and `0.1.3` cut** — policy/e2e release blockers, stale version refs, green release PR, Hex publish, and post-publish smoke.

### Phase 46: Terminology and public vocabulary migration

**Goal:** Public language uses the final SEED-005 vocabulary before the README/guides explain it, so docs describe the product users will actually see.

**Depends on:** Nothing.

**Requirements:** TERM-01, TERM-02, TERM-03, TERM-04

**Plans:** 8/8 plans complete

Plans:
**Wave 1**

- [x] 46-01-PLAN.md — Public verification suite/reviewer broadcast aliases, call-site migration, and early storage guard
- [x] 46-02-PLAN.md — Reviewer surface and LiveView alias migration
- [x] 46-03-PLAN.md — Semantic cache profile and scoped-context runtime aliases

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 46-04-PLAN.md — Private run-inspection trace adapter rename
- [x] 46-05-PLAN.md — Remote invocation and incident trace/evidence copy boundary

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 46-06-PLAN.md — Glossary creation plus package, release-preview, and Hex consumer exposure

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 46-07-PLAN.md — README and stable guide final vocabulary migration

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 46-08-PLAN.md — README/CHANGELOG upgrade notes and focused phase verification

**Success Criteria:**

1. A committed glossary maps final Scoria terms to industry equivalents and defines `run`, reviewer/operator, trace, evidence, capability, verification suite, scoped context, semantic cache, knowledge base, grounding, and bounded handoff.
2. Adopter-facing docs and user-visible copy apply the final terminology strategy, including reviewer for the persona and trace for run-inspection surface sense.
3. RAG/citation use of evidence remains intact; no schema migration or global `evidence_refs` rename is introduced.
4. Leaked internal code names (`Keystone`, `v2.0 Relay`) and the `Four Lanes` count bug are removed from adopter docs.
5. CHANGELOG/upgrade notes explain pre-1.0 terminology changes and any renamed documented modules or user-visible copy.

### Phase 47: README first-screen positioning and scope doctrine

**Goal:** A Phoenix adopter immediately understands what Scoria is, who it is for, where its boundary is, and why embedded governance differs from hosted LLM-ops.

**Depends on:** Phase 46.

**Requirements:** POS-01, POS-02, POS-03, POS-04

**Success Criteria:**

1. README opens with a plain-English paragraph before coined vocabulary, using the SEED-005 wording as the baseline.
2. README and stable docs state the n=1 default lens, CORE/ADJACENT/NOT-OURS persona boundaries, and the reviewer/operator role clearly.
3. An adopter-facing owns-vs-delegates table makes the P1–P6 scope doctrine concrete.
4. A stable comparison page explains Scoria vs hosted LLM-ops with honest strengths and ceded tradeoffs.
5. README version references and install fallback examples no longer point at stale `0.1.1` guidance.

### Phase 48: ExDoc and guide ladder restructure

**Goal:** HexDocs becomes a navigable product surface instead of a flat dump of modules and historical guides.

**Depends on:** Phase 47.

**Requirements:** DOCS-01, DOCS-02, DOCS-03

**Plans:** 15 plans

Plans:
**Wave 1**

- [x] 48-01-PLAN.md — RED ExDoc/package/release-preview contracts for guide groups, source metadata, redirects, and package assets
- [x] 48-02-PLAN.md — RED canonical guide, stable-doc, glossary, scope, and public moduledoc contracts

**Wave 2** *(blocked on Wave 1 contracts)*

- [x] 48-03-PLAN.md — Start Here guide ladder: Getting Started, Golden Path, JTBD, ownership boundary, and cheatsheet
- [x] 48-04-PLAN.md — Capability and reference guides: default runtime, handoffs, semantic cache, connectors/MCP, support gallery, and glossary
- [x] 48-05-PLAN.md — Operate/verify, troubleshooting, comparison, and maintainer guides

**Wave 3** *(blocked on Wave 2 guides)*

- [x] 48-06-PLAN.md — README canonical guide links
- [x] 48-11-PLAN.md — Old start/reference/runtime/comparison docs compatibility stubs for copied source links
- [x] 48-14-PLAN.md — Old capability docs compatibility stubs for copied source links
- [x] 48-15-PLAN.md — Old reviewer verification and maintainer docs compatibility stubs for copied source links
- [x] 48-08-PLAN.md — Public moduledocs for start/install/runtime facade entry points
- [x] 48-12-PLAN.md — Public moduledocs for router, dashboard scope, reviewer surface, broadcast, and verification suites
- [x] 48-09-PLAN.md — Public moduledocs for capability and integration modules
- [x] 48-13-PLAN.md — Public moduledocs for SRE/governance and compatibility alias modules

**Wave 4** *(blocked on Wave 3 docs and module docs)*

- [x] 48-07-PLAN.md — ExDoc docs config, module groups, redirects, dynamic source refs, package files, and release-preview paths

**Wave 5** *(blocked on Wave 4 config)*

- [x] 48-10-PLAN.md — Focused contract suite, release preview, generated docs inspection, and validation closeout

**Success Criteria:**

1. `mix.exs` docs config groups modules by domain area and extras by adopter/maintainer guide ladder.
2. Source/ref/doc links handle dev versions without pointing to missing tag URLs, and brand logo/favicon metadata is wired where supported.
3. Stable guides are organized around getting started, golden path, JTBD/user flows, troubleshooting, hosted LLM-ops comparison, and cheatsheet content.
4. Public moduledocs and README links point to the reorganized guide structure without stale file paths.

### Phase 49: AI-accessible docs and docs verification gate

**Goal:** Humans and coding agents can reliably navigate Scoria's public surface, and docs drift is caught before release.

**Depends on:** Phase 48.

**Requirements:** DOCS-04, AI-01, AI-02

**Plans:** 2 plans

Plans:
**Wave 1**

- [x] 49-01-PLAN.md — Root AI docs entry points and AI docs source contracts

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 49-02-PLAN.md — Package AI docs and harden release preview as docs warning gate

**Success Criteria:**

1. A curated root `llms.txt` and/or `AGENTS.md` points to the public facade, guide ladder, glossary, capabilities, and verification suites.
2. The AI-accessibility surface distinguishes curated source docs from generated ExDoc artifacts.
3. The docs verification command runs warning-clean locally and is wired into the appropriate CI/policy path or documented release gate.
4. New docs/source contracts cover the glossary, guide index, and docs command enough to prevent silent front-door drift.

### Phase 50: Release readiness and `0.1.3` cut

**Goal:** The release train is green, the package truth is current, and Hex `0.1.3` is published with post-publish proof.

**Depends on:** Phases 46–49.

**Requirements:** REL-01, REL-02, REL-03, REL-04

**Plans:** 11 plans (50-01..04 original; 50-05..11 gap closure for CI verify-lane debt exposed by the release push)

Plans:
**Wave 1** *(original — complete)*

- [x] 50-01-PLAN.md — REL-01: repoint docs-contract constants to canonical guides/ and restore dropped maintainer content (policy lane green)
- [x] 50-02-PLAN.md — REL-02: fix dev_seed.exs arity-3 tenant-scoped call sites + theme-toggle visible-locator (e2e lane green)
- [x] 50-03-PLAN.md — REL-03: version/docs-truth polish (stale docs/ comments, 0.1.1 example, HexDocs subdomain URL)

**Wave 2** *(original — blocked pending gap closure)*

- [ ] 50-04-PLAN.md — REL-04: gate on ci-gate green, release-please publish 0.1.3, post-publish smoke proof (maintainer checkpoints)

**Gap closure — Wave 1** *(REL-04 CI verify-lane debt, parallel; ~30 failures across Buckets A–G)*

- [x] 50-05-PLAN.md — Bucket G: DashboardScope mount-halt regression (14 failures, 1 root cause) — fail-closed redirect + seed scope in shared test conns
- [x] 50-06-PLAN.md — Bucket A: docs-source alignment — repoint example-source + SupportJourney doc surfaces to canonical guides/ SSOT (7 cases)
- [x] 50-07-PLAN.md — Bucket C: runtime/LiveView seeded-run + rendered contracts (tenant-scoped run lookup, notebook primitives, incident evidence)
- [x] 50-08-PLAN.md — Bucket D: UI/dev-lab contracts — repoint docs/MAINTAINERS.md reads to guides/maintainers.md + guard #7 inventory-ID reference
- [x] 50-09-PLAN.md — Bucket E: SupportCopilot nested-gallery journeys (knowledge-lane grounding, producer→approvals)
- [ ] 50-10-PLAN.md — Buckets B+F: package-surface subdomain SSOT + warning-inventory verify-first

**Gap closure — Wave 2** *(release re-entry; depends on 50-05..10)*

- [ ] 50-11-PLAN.md — Full-suite + connector green → push → refresh PR #12 → confirm ci-gate green → hand off to 50-04 maintainer checkpoint

**Success Criteria:**

1. The current policy failure is fixed: `ROADMAP.md` keeps the archived `v2.15 Connector Adoption Lane` breadcrumb required by `CiPolicyContractTest`.
2. Browser e2e failures observed on PR #12 are fixed or legitimately descoped with guard updates: IA orientation, release-workbench modal focus, and theme-toggle visibility/clickability.
3. README, maintainer docs, CHANGELOG, release automation, and package metadata agree on live `0.1.2` baseline and `0.1.3` target.
4. The release PR reaches green `ci-gate` and merges through the intended release-please path or a documented maintainer recovery path.
5. Hex lists `0.1.3`, and post-publish smoke proves fresh install plus live-lineage upgrade.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 46. Terminology and public vocabulary migration | v3.5 | 8/8 | Complete    | 2026-07-09 |
| 47. README first-screen positioning and scope doctrine | v3.5 | 3/3 | Complete    | 2026-07-10 |
| 48. ExDoc and guide ladder restructure | v3.5 | 15/15 | Complete    | 2026-07-10 |
| 49. AI-accessible docs and docs verification gate | v3.5 | 2/2 | Complete    | 2026-07-11 |
| 50. Release readiness and `0.1.3` cut | v3.5 | 8/11 | In Progress|  |

## Archived Milestones

<details>
<summary>✅ v3.4 Pre-1.0 Trust & Security Hardening (Phases 42–45) — SHIPPED 2026-07-09</summary>

**Goal:** Fix the three P0 correctness/security bugs live in shipped `0.1.2` — eval fail-open, knowledge cross-tenant retrieval leak, and dashboard auth bypass — plus the scoped correctness sweep. Fix + prove only; no Hex publish.

- [x] Phase 42: Eval fails closed (7/7 plans) — completed 2026-07-05
- [x] Phase 43: Knowledge tenant isolation (5/5 plans) — completed 2026-07-07
- [x] Phase 44: Dashboard auth seam (7/7 plans) — completed 2026-07-07
- [x] Phase 45: Correctness sweep + fail-closed proof & closeout (5/5 plans) — completed 2026-07-07

Full phase detail archived in `.planning/milestones/v3.4-ROADMAP.md`; requirements in `.planning/milestones/v3.4-REQUIREMENTS.md`; audit in `.planning/milestones/v3.4-MILESTONE-AUDIT.md`; phase artifacts in `.planning/milestones/v3.4-phases/`.

</details>

<details>
<summary>✅ v3.3 Design System Stress Test (Phases 36–41.1) — SHIPPED 2026-07-04</summary>

**Goal:** Make the embedded `/scoria` admin/operator UI internally coherent at the foundation, component, component-group, page-flow, copy, accessibility, motion, fixture, and proof levels without regressing the recent cleanup work.

- [x] Phase 36: Baseline And Inventory (2/2 plans) — completed 2026-06-20
- [x] Phase 37: Dev Component Lab And Stress Fixtures (6/6 plans) — completed 2026-07-02
- [x] Phase 38: Foundations And Primitive Controls (3/3 plans) — completed 2026-07-02
- [x] Phase 39: Component Groups And Operator Flows (8/8 plans) — completed 2026-07-03
- [x] Phase 40: Accessibility, Motion, And Responsive Proof (5/5 plans) — completed 2026-07-03
- [x] Phase 41: Proof, Docs, And Regression Guardrails (5/5 plans) — completed 2026-07-04
- [x] Phase 41.1: Wire orphaned ScoriaWeb.Copy/DatasetCopy into dataset page — COPY-01 SSOT (INSERTED) (1/1 plan) — completed 2026-07-04

Full phase detail archived in `.planning/milestones/v3.3-ROADMAP.md`; requirements in `.planning/milestones/v3.3-REQUIREMENTS.md`; audit in `.planning/milestones/v3.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ Earlier milestones</summary>

Archived under `.planning/milestones/`:

- **v3.2 Drydock** — Phases 29–35 (`v3.2-ROADMAP.md`)
- **v3.1 CI/CD Velocity** — Phases 23–28 (`v3.1-ROADMAP.md`)
- **v3.0 Control Room** — Phases 11–17 (`v3.0-ROADMAP.md`)
- **v2.17 Vesicle** — Phases 18–22 (`v2.17-ROADMAP.md`)
- **v2.15 Connector Adoption Lane** — named connector verification suite and docs/CI parity (`MILESTONES.md`)

See `.planning/MILESTONES.md` for full closeout history.

</details>

## Backlog

> Forward roadmap of planned milestones. Each item's full rationale, adjudicated verdicts, peer
> precedent, and file breadcrumbs live in its backing seed under `.planning/seeds/` (see
> `.planning/seeds/README.md` for the index + dependency graph). This section is the durable
> recall surface: `/gsd-complete-milestone` preserves `## Backlog` verbatim across milestone
> rewrites, so it survives context clears. Promote items one at a time via `/gsd-review-backlog`
> or scope them directly in `/gsd-new-milestone`.

### Planned milestone order

Sequenced (dependency + priority). Order was set by a 2026-07-03 AI-eval posture audit
(6-agent adjudication vs LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel). Cadence
decision: **P0 fixes → docs/positioning → feature milestones**, each feature milestone
interleaving its own feature docs + a release as it lands. SEED-005 has been promoted into
active milestone v3.5.

1. **999.3 → SEED-007 — Trace Foundation (OTel-GenAI / OpenInference interop)**  (foundational for eval attribution)
   Semconv as a naming convention over the existing attrs map (not a schema rewrite) + span_kind +
   model config + structured spans/events + RETRIEVER span + README claim fix. → see `SEED-007`.

2. **999.4 → SEED-010 — Lethal-Trifecta Governance**  ⭐ **[FLAGSHIP DIFFERENTIATOR]**
   Content trust tiers + spotlighting + tool-declared trifecta classification + confluence
   escalation policy (Meta Rule-of-Two) + moderation/output hooks + SECURITY-BOUNDARY.md. No peer
   ships this as a runtime seam; Scoria is 2/3 built. Sequence early (after 006 + 007). → see `SEED-010`.

3. **999.5 → SEED-008 — Trustworthy Eval Depth**  (after 006 + 007)
   Real scorer library + regression-comparison engine + judge calibration (the unique join Scoria
   already captures but discards) + versioned rubric + typed risk/intent taxonomy slots. → see `SEED-008`.

4. **999.6 → SEED-009 — Retrieval Eval Depth & Seams**  (after 006)
   precision@k/NDCG/abstention/staleness (model-free, Scoria-owned) + faithfulness/rerank as
   host-supplied hooks (no model in-lib) + tiny gold set. → see `SEED-009`.

5. **999.7 → SEED-011 — Privacy & Feedback Governance**
   Trace/memory retention/TTL/purge + right-to-erasure (Scoria owns the tables → owns deletion) +
   PII masking contract + regex pack + human-feedback capture → flywheel + memory forget/expire.
   Unblocks the currently-unserved privacy/legal/compliance persona. → see `SEED-011`.

6. **999.8 → SEED-012 — Architecture-Archetype Awareness (Rule-8 lens)**  (small capstone; after 007 + 008)
   Host-declared `archetype`/`route` on runs (Scoria records/segments, never infers) + a
   segment-by-attribute dashboard facet (per-archetype/per-route cost/latency/scores) + per-archetype
   Rule-8 eval presets + Router observability (routing accuracy via the SEED-008 confusion-matrix reuse).
   A thin composition over the SEED-007 attribute convention + SEED-008 eval machinery — not new infra.
   From the 2026-07-03 AI-architecture-patterns ingest (memo: `.planning/research/ai-architectural-patterns.md`,
   which validated ~85% of Scoria as-built). → see `SEED-012`.

7. **999.9 → SEED-013 — Operator IA Pivot (Control-Room v2)**  (dashboard coherence; sequence after 006, alongside/after 005)
   The **structural** operator-UI pivot buildable on today's backend: a tighter nav re-group
   (Home · Queue · Features · Runs · Quality · Govern · [Data & Privacy] · [Audit]), a **unified Queue**
   (one ranked human-work inbox over existing approvals+incidents+reviews), a persistent scope contract
   (Tenant/Feature/Time/Live, cross-tenant loud), a 3-pane **Run Workbench**, the progressive-disclosure
   law + receipts + "create policy rule from this," a **Feature Cockpit shell** (host-declared feature
   attribute), and the "story-spine-with-vesicles" trace viz. It is the umbrella the feature-specific
   screens fold into: Govern/blast-radius rides `SEED-010`, Data & Privacy rides `SEED-011`, Quality depth
   rides `SEED-008`/`SEED-009`, Feature Cockpit content rides `SEED-012`. From the 2026-07-03 operator-UI
   storyboard ingest (**UI source-of-record: `.planning/research/operator-ui-north-star.md`**, which
   doctrine-filtered a blank-slate/maximalist storyboard down to this one structural seed + annotations —
   ~40% of its ideas already ship). → see `SEED-013`.

### Carried-forward deferred work (pre-audit)

- **SEED-004 — Test-code determinism** (async `IntegrationCase`, remove `Process.sleep`→`eventually/2`,
  raise shard count). Deferred at v3.1 close; keep separate unless a release-blocking test failure requires a narrow fix. *(No seed
  file on disk — tracked only here + STATE.md Deferred Items.)*

- **FLEET-01** — migrate sibling repos onto the shared Traefik + unpublished-DB standard. Deferred v3.2.
- **FLEET-02** — `make nuke-all` fleet-wide teardown (high blast radius). Deferred v3.2.

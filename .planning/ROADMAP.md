# Roadmap: Scoria

## Milestones

- ✅ **v2.17 Vesicle** — Phases 18–22, canonical brand system (shipped 2026-06-11)
- ✅ **v3.0 Control Room** — Phases 11–17, dashboard design-system / IA / motion / proof (shipped 2026-06-14)
- ✅ **v3.1 CI/CD Velocity** — Phases 23–28, PR CI 77m → 7m38s (shipped 2026-06-17)
- ✅ **v3.2 Drydock** — Phases 29–35, Docker dev-DX hardening + `0.1.2` maintenance release (shipped 2026-06-19)
- ✅ **v3.3 Design System Stress Test** — Phases 36–41.1, `/scoria` UI coherence foundation→proof (shipped 2026-07-04)
- 📋 **Next** — see `## Backlog` (999.1 SEED-006 Trust & Security Hardening gates the next Hex release)

## Phases

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
<summary>✅ Earlier milestones (v2.17 → v3.2)</summary>

Archived under `.planning/milestones/`:
- **v3.2 Drydock** — Phases 29–35 (`v3.2-ROADMAP.md`)
- **v3.1 CI/CD Velocity** — Phases 23–28 (`v3.1-ROADMAP.md`)
- **v3.0 Control Room** — Phases 11–17 (`v3.0-ROADMAP.md`)
- **v2.17 Vesicle** — Phases 18–22 (`v2.17-ROADMAP.md`)

See `.planning/MILESTONES.md` for full closeout history.

</details>

## Progress

| Phase                                    | Milestone | Plans Complete | Status   | Completed  |
| ---------------------------------------- | --------- | -------------- | -------- | ---------- |
| 36. Baseline And Inventory               | v3.3      | 2/2            | Complete | 2026-06-20 |
| 37. Dev Component Lab And Stress Fixtures | v3.3      | 6/6            | Complete | 2026-07-02 |
| 38. Foundations And Primitive Controls   | v3.3      | 3/3            | Complete | 2026-07-02 |
| 39. Component Groups And Operator Flows  | v3.3      | 8/8            | Complete | 2026-07-03 |
| 40. Accessibility, Motion, Responsive    | v3.3      | 5/5            | Complete | 2026-07-03 |
| 41. Proof, Docs, And Regression Guardrails | v3.3    | 5/5            | Complete | 2026-07-04 |
| 41.1 Wire Copy/DatasetCopy (COPY-01 SSOT) | v3.3     | 1/1            | Complete | 2026-07-04 |

## Previous Milestones

- Shipped **v3.3 Design System Stress Test** - Phases 36-41.1, `/scoria` UI coherence foundation→proof - 2026-07-04.
- Shipped **v3.2 Drydock** - Phases 29-35, Docker dev-DX hardening and maintenance release - 2026-06-19.
- Shipped **v3.1 CI/CD Velocity** - Phases 23-28, PR CI 77m to 7m38s measured - 2026-06-17.
- Shipped **v3.0 Control Room** - Phases 11-17, dashboard design-system, IA, motion, and proof - 2026-06-14.
- Shipped **v2.17 Vesicle** - Phases 18-22, canonical brand system - 2026-06-11.

See `.planning/MILESTONES.md` for full closeout history.

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
interleaving its own feature docs + a release as it lands.

1. **999.1 → SEED-006 — Pre-1.0 Trust & Security Hardening**  🔴 **[P0 · GATES THE NEXT HEX RELEASE]**
   Fix 3 live bugs in shipped 0.1.2: eval fail-open (fake-green scorers + judge grades
   expected-vs-expected + decorative release gate), knowledge cross-tenant retrieval leak,
   dashboard auth bypass; + correctness bugs (fake-cosine score_chunk, citation_presence
   abstention penalty, chunker overlap no-op, latency-vs-0). The pending 0.1.3 release PR (#12)
   is held until this lands. → see `SEED-006`.

2. **999.2 → SEED-005 — Documentation & Positioning overhaul**  (adoption bottleneck; the *front door*)
   STABLE docs only (terminology sense-aware rename, scope-doctrine + owns-vs-delegates table,
   ExDoc grouping, glossary, README first-screen) + the honest release cut (gated on 999.1).
   Feature-specific guides are interleaved into the build milestones below, NOT pre-written here.
   → see `SEED-005`.

3. **999.3 → SEED-007 — Trace Foundation (OTel-GenAI / OpenInference interop)**  (foundational for eval attribution)
   Semconv as a naming convention over the existing attrs map (not a schema rewrite) + span_kind +
   model config + structured spans/events + RETRIEVER span + README claim fix. → see `SEED-007`.

4. **999.4 → SEED-010 — Lethal-Trifecta Governance**  ⭐ **[FLAGSHIP DIFFERENTIATOR]**
   Content trust tiers + spotlighting + tool-declared trifecta classification + confluence
   escalation policy (Meta Rule-of-Two) + moderation/output hooks + SECURITY-BOUNDARY.md. No peer
   ships this as a runtime seam; Scoria is 2/3 built. Sequence early (after 006 + 007). → see `SEED-010`.

5. **999.5 → SEED-008 — Trustworthy Eval Depth**  (after 006 + 007)
   Real scorer library + regression-comparison engine + judge calibration (the unique join Scoria
   already captures but discards) + versioned rubric + typed risk/intent taxonomy slots. → see `SEED-008`.

6. **999.6 → SEED-009 — Retrieval Eval Depth & Seams**  (after 006)
   precision@k/NDCG/abstention/staleness (model-free, Scoria-owned) + faithfulness/rerank as
   host-supplied hooks (no model in-lib) + tiny gold set. → see `SEED-009`.

7. **999.7 → SEED-011 — Privacy & Feedback Governance**
   Trace/memory retention/TTL/purge + right-to-erasure (Scoria owns the tables → owns deletion) +
   PII masking contract + regex pack + human-feedback capture → flywheel + memory forget/expire.
   Unblocks the currently-unserved privacy/legal/compliance persona. → see `SEED-011`.

8. **999.8 → SEED-012 — Architecture-Archetype Awareness (Rule-8 lens)**  (small capstone; after 007 + 008)
   Host-declared `archetype`/`route` on runs (Scoria records/segments, never infers) + a
   segment-by-attribute dashboard facet (per-archetype/per-route cost/latency/scores) + per-archetype
   Rule-8 eval presets + Router observability (routing accuracy via the SEED-008 confusion-matrix reuse).
   A thin composition over the SEED-007 attribute convention + SEED-008 eval machinery — not new infra.
   From the 2026-07-03 AI-architecture-patterns ingest (memo: `.planning/research/ai-architectural-patterns.md`,
   which validated ~85% of Scoria as-built). → see `SEED-012`.

9. **999.9 → SEED-013 — Operator IA Pivot (Control-Room v2)**  (dashboard coherence; sequence after 006, alongside/after 005)
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
  raise shard count). Deferred at v3.1 close; leading pre-audit next-milestone candidate. *(No seed
  file on disk — tracked only here + STATE.md Deferred Items.)*

- **FLEET-01** — migrate sibling repos onto the shared Traefik + unpublished-DB standard. Deferred v3.2.
- **FLEET-02** — `make nuke-all` fleet-wide teardown (high blast radius). Deferred v3.2.

### Post-v3.3 housekeeping follow-ups (do when the v3.3 window is idle — collision-avoidance)

- Record the 6-principle **scope doctrine** (Scoria owns the verb; host owns the noun — P1–P6,
  detailed in `SEED-005` / `SEED-006`) into `PROJECT.md` `## Key Decisions` + `## Constraints`.

- ~~Clean up `STATE.md` `## Deferred Items` (stray per-plan metric rows)~~ — done at v3.3 close (2026-07-04);
  SEED-005…013 rows now present in STATE.md's Deferred Items / acknowledged-at-close block.

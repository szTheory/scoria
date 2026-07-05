# Roadmap: Scoria

## Milestones

- ✅ **v2.17 Vesicle** — Phases 18–22, canonical brand system (shipped 2026-06-11)
- ✅ **v3.0 Control Room** — Phases 11–17, dashboard design-system / IA / motion / proof (shipped 2026-06-14)
- ✅ **v3.1 CI/CD Velocity** — Phases 23–28, PR CI 77m → 7m38s (shipped 2026-06-17)
- ✅ **v3.2 Drydock** — Phases 29–35, Docker dev-DX hardening + `0.1.2` maintenance release (shipped 2026-06-19)
- ✅ **v3.3 Design System Stress Test** — Phases 36–41.1, `/scoria` UI coherence foundation→proof (shipped 2026-07-04)
- 🚧 **v3.4 Pre-1.0 Trust & Security Hardening** — Phases 42–45, fix 3 P0 bugs (eval fail-open, knowledge cross-tenant leak, dashboard auth bypass) + correctness sweep 🔴 **[P0 · GATES THE NEXT HEX RELEASE]** (active, started 2026-07-04)

## Phases

**Current milestone: v3.4 Pre-1.0 Trust & Security Hardening** 🔴 P0 — SEED-006 / Backlog 999.1. Fix + prove only; no Hex publish (that release cut belongs to SEED-005 / 999.2). Phases 42/43/44 are independent subsystems (eval / knowledge / web) and can run in parallel or any order; Phase 45 depends on 42 + 43.

- [ ] **Phase 42: Eval fails closed** - Kill the fake-green shortcuts so eval runs a real subject output, a real deterministic scorer, `:not_scored`, and a verdict-consulting release gate
- [ ] **Phase 43: Knowledge tenant isolation** - Add tenant/actor/scope columns + a mandatory fail-closed retrieval filter (nil tenant RAISES) so no tenant reads another tenant's chunks
- [ ] **Phase 44: Dashboard auth seam** - Pass-through `on_mount:` + host-asserted tenant resolution so `?tenant=` is no longer spoofable (authz stays delegated)
- [ ] **Phase 45: Correctness sweep + fail-closed proof & closeout** - Real cosine `score_chunk`, label-aware citation scoring, dead chunker param removed, real latency gate, and scope-doctrine cross-link

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

## Phase Details

### Phase 42: Eval fails closed

**Goal**: Scoria's eval engine fails CLOSED — no run is ever reported green without a real subject output scored by a real deterministic scorer, and the release gate consults the verdict instead of the prompt's draft flag.
**Depends on**: Nothing (independent subsystem — eval)
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05
**Success Criteria** (what must be TRUE):

  1. Offline/judge eval executes or replays the real subject prompt so the "Actual" output is a real result — an eval whose real output differs from the sealed expectation yields `failed`/`:not_scored`, never `passed` (the `expected_output["answer"]` self-grading shortcut in `build_subject_output` is gone).
  2. At least one real deterministic scorer compares actual vs expected output, in the `Scoria.Knowledge.Grounding` scorer style, writing through the existing `Scoria.Eval.Score` sink.
  3. When no real scorer is configured, eval emits `:not_scored` and `threshold_verdict` / `ReleaseGate` return `failed`/`inconclusive` — a run is never reported green by default.
  4. `Runtime.ReleaseGate` blocks a release when `threshold_verdict` is not passing, not only when the prompt is `status: "draft"`.
  5. Online scoring no longer fabricates pass/fail from `sample_reason == "policy_trigger"` alone — it inspects real trace output or marks the candidate `:not_scored`.

**Plans**: 7/7 plans complete

- [x] 42-01-PLAN.md — Verdict spine (compute/blocks_release?/item_scored?) + honest tri-state vocabulary (Score not_scored, dashboard amber) [D-01, D-02]
- [x] 42-02-PLAN.md — Subject-output capture: captured_output fields + migration, promotion population, SubjectOutput.resolve/2 [D-04]
- [x] 42-03-PLAN.md — ExactMatch deterministic scorer (binary, not_scored on couldn't-run) [D-03]
- [x] 42-04-PLAN.md — Offline runner: scorer_kind dispatch + Verdict, kill hardcoded pass, rewrite offline_runner_test [D-03, D-04]
- [x] 42-05-PLAN.md — Judge runner: kill self-grade → SubjectOutput.resolve + Verdict [D-01, D-04]
- [x] 42-06-PLAN.md — Online scoring negative-signal detector (no fabricated pass; span/step signals) [D-01, D-06]
- [x] 42-07-PLAN.md — ReleaseGate verdict consult (allowlist, online-exclusion, ungated telemetry, index) [D-05]

### Phase 43: Knowledge tenant isolation

**Goal**: Knowledge retrieval is tenant-isolated end to end — a nil tenant raises rather than matching all — so no tenant's query embedding can retrieve another tenant's raw chunk body or citation quote.
**Depends on**: Nothing (independent subsystem — knowledge)
**Requirements**: KNOW-01, KNOW-02, KNOW-03, KNOW-04
**Success Criteria** (what must be TRUE):

  1. Running the new knowledge migration adds `tenant_id` (+ optional `actor_id`/`scope_kind`, mirroring `SemanticCache`) with `[tenant_id]` and `[tenant_id, source_id]` indexes to sources + chunks; the production run path (`KnowledgeMigrationRepo` / `schema_migrations_knowledge`) is documented.
  2. `retrieval_runs`, `retrieval_results`, and `citations` carry tenant/actor for audit.
  3. A retrieval call with a nil tenant RAISES (mirrors `SemanticCache.Lookup.base_query`'s `Map.fetch!`) across `similar_chunks`, `Scrypath.retrieve`, `list_source_chunks`, and `Knowledge.retrieve/ingest` — never a silent match-all.
  4. A cross-tenant isolation test proves tenant A's query returns zero of tenant B's chunks.

**Plans**: 5 plans

- [ ] 43-01-PLAN.md — Scope contract and tenant isolation test spine
- [ ] 43-02-PLAN.md — Additive knowledge migration and schema fields
- [ ] 43-03-PLAN.md — Public Knowledge API write/list/run/result enforcement
- [ ] 43-04-PLAN.md — Pgvector and Scrypath tenant-qualified retrieval
- [ ] 43-05-PLAN.md — Citation/grounding scope, docs, and full knowledge proof

### Phase 44: Dashboard auth seam

**Goal**: The host can inject its own auth hook and Scoria resolves `tenant_id` from a host-asserted source, so a `?tenant=<victim>` spoof no longer reads foreign data — while authz stays delegated (no in-lib RBAC).
**Depends on**: Nothing (independent subsystem — web)
**Requirements**: AUTH-01, AUTH-02, AUTH-03
**Success Criteria** (what must be TRUE):

  1. `scoria_dashboard/2` accepts a pass-through `on_mount:` list — a host hook runs before `DashboardNav` (which stays in the chain) — and the bare `scoria_dashboard "/scoria"` form still compiles (installer, dev router, and example host all emit it).
  2. A documented tenant-resolution/authorization callback makes `tenant_id` host-asserted, not a spoofable `?tenant=` param; no in-lib role/RBAC model is added.
  3. Dashboard LiveViews resolve tenant from the host-asserted source; the unauthenticated `params["tenant"] → "default"` spoof path is closed (a `?tenant=<victim>` request no longer returns another tenant's data).

**Plans**: TBD

### Phase 45: Correctness sweep + fail-closed proof & closeout

**Goal**: Retrieval scoring and the latency gate report real numbers instead of fabricated ones, and the scope doctrine is confirmed and cross-linked — closing out the fix milestone on the fail-closed foundations from Phases 42 + 43.
**Depends on**: Phase 42 (FIX-04's real-latency gate is enabled by EVAL's real scorers), Phase 43 (FIX-01/FIX-02 layer on the knowledge tenant-isolation work)
**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04, DOC-01
**Success Criteria** (what must be TRUE):

  1. `Knowledge.Backends.Pgvector.score_chunk/2` persists a real cosine similarity that matches the `cosine_distance` ranking metric — the fake `1/(1+|Σemb−Σquery|)` component-sum score is gone.
  2. `Knowledge.Grounding.score_citation_presence` is label-aware — a correct abstention on an unanswerable query is no longer penalized as `0.0/"failed"`.
  3. `Chunker.Default`'s dead `overlap` param (the `max(end - overlap, end)` no-op) is removed and the chunker is documented as non-overlapping.
  4. The `max_latency_ms` gate operates on real recorded latency (enabled once EVAL's real scorers record actual latency instead of a hardcoded 0).
  5. The 6-principle scope doctrine ("Scoria owns the verb; host owns the noun", P1–P6) is confirmed present in `PROJECT.md ## Constraints` + `## Key Decisions` and cross-linked from the eval / knowledge / dashboard fix rationale (confirm-and-cross-link — the doctrine was already recorded at v3.3 close).

**Plans**: TBD

## Progress

| Phase                                          | Milestone | Plans Complete | Status      | Completed |
| ---------------------------------------------- | --------- | -------------- | ----------- | --------- |
| 42. Eval fails closed                          | v3.4      | 7/7 | Complete    | 2026-07-05 |
| 43. Knowledge tenant isolation                 | v3.4      | 0/5            | Not started | -         |
| 44. Dashboard auth seam                        | v3.4      | 0/?            | Not started | -         |
| 45. Correctness sweep + fail-closed proof      | v3.4      | 0/?            | Not started | -         |

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

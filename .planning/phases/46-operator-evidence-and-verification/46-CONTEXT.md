# Phase 46: Operator evidence and verification - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Project semantic-cache behavior into Scoria's operator surfaces and close `v2.1 Tenant-scoped semantic fast path` with checked proof.

Phase 46 owns operator-visible evidence for cache hit, miss, stale, reject, and bypass outcomes, plus the verification lane and milestone docs that prove partitioning, fallback, and invalidation semantics. It does not reopen the Phase 44 public lane contract or the Phase 45 compatibility/invalidation policy.

</domain>

<decisions>
## Implementation Decisions

### Operator surface ownership
- **D-01:** The workflow run page is the canonical deep-inspection surface for semantic-cache evidence. The runtime presence surface stays summary-first and links into workflow evidence rather than duplicating the full notebook.
- **D-02:** The runtime surface should answer only the first-line operator questions: what happened, was the answer reused or did Scoria fall back, why, and where should the operator click next.
- **D-03:** The runtime surface should show a compact semantic summary with explicit `lookup_status`, fallback outcome, `lane_key`, `scope_kind`, `scope_reason`, one decisive reason chip, and deep links to the workflow evidence view and origin run when relevant.
- **D-04:** The workflow run page should expose the full semantic-evidence notebook because it already owns the trace tree, step detail, replay context, promotion flows, and other durable run-level evidence.

### Evidence contract and vocabulary
- **D-05:** Phase 46 must not invent a second semantic taxonomy. Operator-visible evidence should reuse the Phase 44 and Phase 45 nouns directly: `bypass`, `miss`, `reject`, `hit`; `active`, `stale`, `invalidated`, `writeback_rejected`; `eligibility_reason_code`; `lookup_reason_code`.
- **D-06:** Fallback is evidence, not absence. The UI and DTOs should explicitly show that Scoria evaluated the fast path and intentionally continued through the normal runtime path when reuse did not qualify.
- **D-07:** The operator story should remain reason-coded and stage-separated. `bypass`, `miss`, `reject`, and `stale` must stay distinct in UI copy, DTOs, and verification.
- **D-08:** Phase 46 should lead with operator-proof fields, not internals. Show verdict, fallback, scope, reason, and provenance first; embeddings and similarity internals are secondary debug detail.

### Evidence density and progressive disclosure
- **D-09:** Semantic evidence should use progressive disclosure in four layers:
  1. verdict, reason, age, lane, tenant/actor scope, fallback outcome
  2. compatibility checklist: prompt, policy, source, freshness, similarity
  3. provenance links: source run, cache entry, writeback event, invalidation event
  4. raw metadata / JSON escape hatch
- **D-10:** The workflow evidence notebook should present a dense but one-screen-understandable summary strip before any raw payloads or long metadata blocks.
- **D-11:** The runtime surface should stay concise enough for incident triage and should not absorb the full compatibility matrix, lifecycle timeline, or raw JSON view.
- **D-12:** Actor identity should only be surfaced prominently when scope is narrowed to `actor_scoped` or when it materially explains why reuse was fenced. Tenant-shared outcomes should not over-emphasize actor data.

### Provenance and lifecycle visibility
- **D-13:** Every reusable semantic entry should surface version-rooted provenance: source run/trace linkage, prompt identity/version, policy fingerprint snapshot, source fingerprint, lane, scope, created/reused times, and invalidation or stale reason when applicable.
- **D-14:** Workflow evidence should show entry lifecycle truth as first-class operator evidence: current status, `expires_at`, `invalidated_at`, `hit_count`, `last_hit_at`, and append-only semantic entry events.
- **D-15:** Rejected or stale candidates should remain inspectable as candidates that were found and refused, not flattened into a generic miss.

### Verification lane and support truth
- **D-16:** `PROOF-01` should ship as a dedicated checked verification lane, preferred task name `mix test.semantic_fast_path`, instead of being folded into `mix test.adoption` or left implicit in the full suite.
- **D-17:** The semantic verification lane should prove tenant partitioning, explicit fallback and bypass semantics, invalidation visibility, and the operator-surface projection of semantic outcomes.
- **D-18:** `mix test.adoption` should remain the public-runtime/adoption proof lane. `mix test` remains the release-confidence umbrella. The semantic lane becomes the canonical troubleshooting and support-truth answer for `v2.1`.
- **D-19:** Milestone docs should ship one boring golden path for semantic fast-path verification and troubleshooting so the support story, operator UI vocabulary, and test lane all say the same thing.

### Shift-left defaults
- **D-20:** Future GSD planning for semantic-cache work should treat these as locked defaults unless a later phase changes product shape, security or policy boundary, durable truth, tenant blast radius, or materially different operator UX:
  - workflow page is canonical deep-inspection surface
  - runtime surface is summary-first with strong deep links
  - semantic evidence uses the Phase 44/45 noun set without a second taxonomy
  - semantic proof ships as a dedicated named verification lane
- **D-21:** Later discuss/planning steps should not re-ask about duplicating full semantic detail across runtime and workflow surfaces, leading with analytics or hit-rate dashboards, or collapsing semantic proof into broader test lanes unless milestone scope changes.

### the agent's Discretion
- Exact component/module names for the semantic evidence panel, summary cards, and supporting function components.
- Exact DTO field names or grouping as long as they preserve the single semantic-evidence contract.
- Exact chip/badge copy and visual treatment as long as verdict, fallback, scope, reason, and provenance remain primary.
- Exact verification task module naming (`Mix.Tasks.Test.SemanticFastPath` vs a namespaced twin) so long as one canonical user-facing command exists.
- Exact split between LiveView async loading and eager assigns, provided summary truth renders immediately and heavier evidence loads without blocking the page.

</decisions>

<specifics>
## Specific Ideas

- Desired operator sentence on a hit: `Scoria reused entry E123 because tenant scope, prompt version, policy fingerprint, source fingerprint, freshness, and similarity all matched.`
- Desired operator sentence on a non-hit: `Scoria found candidate E123 but rejected it: source_fingerprint_mismatch. Normal runtime path executed.`
- The workflow page should feel like a calm field-engineer notebook, not a magical cache dashboard.
- The runtime drawer should feel like a posture summary with a strong “view workflow evidence” escape hatch, not a second trace explorer.
- The milestone closeout should leave behind one exact verification answer for adopters and maintainers: `mix test.semantic_fast_path`.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Requirement Contract
- `.planning/ROADMAP.md` — Phase 46 boundary and success criteria.
- `.planning/PROJECT.md` — milestone posture: embedded, Phoenix-first, operator-visible, evidence-first.
- `.planning/REQUIREMENTS.md` — authoritative wording for `EVID-01` and `PROOF-01`.
- `.planning/STATE.md` — current milestone state and semantic-fast-path progress.
- `.planning/METHODOLOGY.md` — decisive-defaults lens; low-impact semantic-cache decisions should stay shifted left.

### Prior Phase Contract
- `.planning/phases/44-semantic-cache-contract-and-persistence/44-CONTEXT.md` — locked lane, scope, persistence, and evidence nouns.
- `.planning/phases/45-compatibility-and-invalidation-engine/45-CONTEXT.md` — locked compatibility, invalidation, freshness, and reason-code posture.

### Project Research And Product Posture
- `.planning/research/SUMMARY.md` — milestone recommendation for a Scoria-owned, operator-visible semantic fast path.
- `.planning/research/liveview-operator-ux.md` — embedded operator dashboard guidance and progressive disclosure posture.
- `.planning/research/evals-and-observability.md` — trace/eval flywheel and operator evidence framing.
- `.planning/research/elixir-ai-ecosystem.md` — product-shape guidance for Scoria as a Phoenix-native AI ops layer.
- `prompts/scoria-brand-book-deep-research.md` — brand and UX posture: calm, operator-grade, evidence over magic.
- `prompts/phoenix-ai-lib-deep-research.md` — ecosystem lessons from Phoenix-native AI ops and adjacent platforms.
- `prompts/scoria-gsd-kickoff.md` — project vision and control-plane priorities.
- `prompts/sztheory-elixir-dna.md` — batteries-included but composable, Ecto-native, operator-first architectural DNA.

### Existing Code Surfaces
- `lib/scoria/runtime.ex` — public curated runtime summary/detail surface.
- `lib/scoria/runtime/run_detail.ex` — current run-detail DTO that should remain the canonical workflow evidence source.
- `lib/scoria/workflows/runtime.ex` — semantic fast-path lookup, fallback, and writeback evidence seam.
- `lib/scoria/semantic_cache.ex` — entry and lifecycle-event persistence.
- `lib/scoria/semantic_cache/entry.ex` — semantic entry durable truth.
- `lib/scoria/semantic_cache/entry_event.ex` — append-only semantic lifecycle evidence.
- `lib/scoria_web/live/workflow_live/show.ex` — current workflow trace page that should host the deep semantic notebook.
- `lib/scoria_web/components/workflow_detail_panel_component.ex` — current right-rail detail seam for richer evidence projection.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` — current runtime summary surface to extend conservatively.
- `lib/mix/tasks/test.adoption.ex` — existing named checked lane pattern to preserve while adding semantic proof.
- `test/scoria/runtime/semantic_fast_path_test.exs` — current runtime semantic-path proof seam.
- `test/scoria/semantic_cache/lookup_test.exs` — current compatibility and lookup proof seam.
- `test/scoria/semantic_cache/invalidation_test.exs` — current invalidation and lifecycle proof seam.
- `test/scoria_web/live/workflow_live_test.exs` — current workflow evidence projection test seam for Phase 46 UI proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime.get_run_detail!/1` and `Scoria.Runtime.RunDetail`: already establish the curated DTO pattern Scoria uses when a LiveView needs stable operator truth rather than ad hoc raw rows.
- `Scoria.Workflows.Runtime.prepare_semantic_fast_path/1`: already emits the stage-separated semantic outcome facts that Phase 46 should project instead of recomputing in the UI.
- `Scoria.SemanticCache`, `Entry`, and `EntryEvent`: already provide the durable entry/lifecycle truth needed for provenance, status, and event timelines.
- `WorkflowLive.Show` and `WorkflowDetailPanelComponent`: already provide the canonical trace-first inspection surface and right-rail detail shell.
- `RuntimeDetailDrawerComponent`: already provides a compact runtime summary shell and is the right place for a terse semantic verdict panel.
- Existing Mix task pattern in `test.adoption`: already shows how Scoria expresses checked proof as a named bounded lane.

### Established Patterns
- Curated public DTOs over raw schema spelunking in LiveViews.
- Explicit status and reason codes over boolean or prose-only explanation.
- Durable Ecto truth plus append-only evidence events over inferred UI state.
- Workflow page as the canonical deep-inspection artifact; secondary surfaces summarize and link.
- Named verification lanes for support truth instead of relying on accidental full-suite coverage.

### Integration Points
- Runtime summary projection: extend runtime presence/detail surfaces with summary semantic verdict fields and workflow deep links.
- Workflow deep evidence projection: extend the workflow page/right rail with the semantic evidence notebook and lifecycle/provenance panels.
- DTO seam: enrich `RunDetail` or adjacent curated runtime/workflow DTOs with typed semantic evidence so multiple UI areas render the same truth.
- Verification seam: add a dedicated semantic Mix task that composes the existing runtime, lookup, invalidation, and new operator-evidence tests.
- Docs seam: align milestone verification and troubleshooting docs to the same operator vocabulary and verification command.

</code_context>

<deferred>
## Deferred Ideas

- A second full semantic trace explorer inside the runtime surface.
- Symmetric deep semantic notebooks on both runtime and workflow pages.
- Analytics-first cache dashboards, hit-rate-first operator stories, or dense metric walls before the evidence notebook is proven boring.
- Annotation queues, review inboxes, or broader semantic evidence triage workflows beyond what is needed to satisfy `EVID-01` and `PROOF-01`.
- Hosted-style observability control-plane features, external cache evidence services, or non-Ecto primary truth paths.
- Broad proof-lane consolidation into `mix test.adoption` or `mix test` unless a later milestone intentionally redefines those contracts.

</deferred>

---

*Phase: 46-operator-evidence-and-verification*
*Context gathered: 2026-05-25*

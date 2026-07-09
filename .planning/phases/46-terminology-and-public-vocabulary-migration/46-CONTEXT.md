# Phase 46: Terminology and public vocabulary migration - Context

**Gathered:** 2026-07-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Scoria's public vocabulary match the final SEED-005 language before the README, guides,
ExDoc structure, AI-readable docs, and release cut build on it.

This phase delivers TERM-01..04 only:

1. Add a committed glossary mapping final Scoria terms to industry equivalents and defining
   `run`, reviewer/operator, trace, evidence, capability, verification suite, scoped context,
   semantic cache, knowledge base, grounding, and bounded handoff.
2. Apply the final terminology strategy to adopter-facing docs and user-visible copy:
   reviewer for the human persona, trace for run-inspection surfaces, capabilities for
   adoption scope, verification suite for proof commands, scoped context, semantic cache,
   and optional knowledge base.
3. Preserve correct RAG/citation use of evidence. Do not introduce a schema migration or a
   global `evidence_refs` rename.
4. Remove leaked internal code names (`Keystone`, `v2.0 Relay`) and fix the `Four Lanes`
   count bug in adopter docs.
5. Add CHANGELOG/README upgrade notes explaining the pre-1.0 terminology migration and any
   renamed documented modules, options, or user-visible copy.

**In scope:** terminology docs, public/user-visible copy, targeted documented-surface code
renames with compatibility aliases, glossary, drift contracts, and upgrade notes.

**Out of scope:** full README positioning rewrite (Phase 47), ExDoc/guide ladder restructure
(Phase 48), curated root `llms.txt`/`AGENTS.md` (Phase 49), release cut and final published
release notes (Phase 50), OpenInference-compatible trace substrate (SEED-007), deeper RAG eval
docs (SEED-009), or structural reviewer UI pivot (SEED-013).

</domain>

<decisions>
## Implementation Decisions

Hard constraints carried forward:

- **Sense-aware rename, not global find/replace.** The final vocabulary is locked by
  SEED-005, but implementation must preserve meanings that are already correct.
- **No schema migration.** `evidence_refs` and citation/grounding evidence remain as-is.
- **Pre-1.0 honesty with compatibility.** Phase 46 may rename public/discoverable surfaces,
  but should keep compatibility aliases unless the release target changes from `0.1.3` to a
  breaking `0.2.0`-style release in Phase 50.
- **Docs are public API.** Anything exposed in README, guides, ExDoc, or copy-paste examples
  must use final vocabulary or clearly mark legacy names.
- **Scoria owns the verb; host owns the noun.** Terminology must keep identity, policy values,
  business truth, and end-user semantics host-owned.

### D-01 - Rename blast radius: targeted documented-surface rename with aliases

- Do not do a full internal grep rename. It is too much regression risk for a documentation and
  release-readiness phase.
- Do not stop at docs/UI copy only. That would leave ExDoc and examples teaching stale names.
- Rename public/discoverable code symbols where the old vocabulary appears as a documented
  concept:
  - `ScoriaWeb.OperatorSurface` -> `ScoriaWeb.ReviewerSurface`
  - `Scoria.Observe.OperatorBroadcast` -> `Scoria.Observe.ReviewerBroadcast`
  - `Scoria.VerificationLanes` -> `Scoria.VerificationSuites`
- Keep old module names as compatibility wrappers for the `0.1.x` line. Prefer `@moduledoc false`
  or explicit legacy docs on wrappers so ExDoc discovery leads with final names.
- Do not emit hard deprecation warnings unless the replacement has shipped and the planner decides
  warning noise is worth it. Elixir-style soft deprecation through docs/CHANGELOG is enough for this
  pre-1.0 terminology cleanup.
- Replace the public semantic-cache admission surface with a final-vocabulary API while keeping
  compatibility:
  - Preferred new public shape: `use Scoria.SemanticCache.Profile, cache_key: "account_faq"`.
  - Preferred new runtime option: `semantic_cache: [profile: MyApp.AI.AccountFaqCache]`.
  - Keep `Scoria.SemanticLane`, `lane:`, and internal `lane_key` storage accepted as legacy aliases.
  - Do not rename persisted `lane_key` fields unless a later breaking release chooses to migrate data.
- For bounded handoff context:
  - Preferred public option: `scoped_context: %{...}`.
  - Keep `projected_context:` accepted as a legacy alias.
  - Keep underlying storage field names unless the planner can prove a no-risk private-only rename.
- Rename UI/copy nouns:
  - `operator` persona -> `reviewer`.
  - Use `operator` only for an SRE/on-call job sense or in legacy mapping text.
  - `adoption lanes` / capability `lane` -> `capabilities`.
  - proof-command `lane` -> `verification suite`.
- Add contract tests so adopter docs and generated docs prefer final vocabulary and do not regress
  to old public terms.

Rejected alternatives:

- **Docs/UI copy only:** fastest, but leaves ExDoc and copy-paste examples inconsistent.
- **Full internal rename:** cleanest grep result, but likely to delay release readiness and break
  consumers without enough value in Phase 46.
- **Defer all code names to Phase 48:** keeps Phase 46 too shallow for TERM-04 and lets Phase 47
  build positioning on stale public symbols.

### D-02 - Evidence vs trace: hybrid boundary rename

- Use **trace** for the reviewer-visible execution story of a run: spans, model calls, retrievals,
  tool calls, approvals, eval scores, replay branches, and workflow inspection.
- Keep **evidence** where it means support/proof material:
  - RAG/citation evidence
  - grounding evidence
  - `evidence_refs`
  - citation/grounding components and schemas
  - eval score references that point to supporting trace/citation material
- Rename user-visible run-inspection labels from evidence to trace:
  - "operator evidence page" -> "reviewer trace page" or "run trace"
  - "delegated evidence" -> "delegated trace" when describing same-run handoff inspection
  - "replay evidence" -> "replay trace" when comparing original/replay run branches
  - "semantic evidence" -> "semantic cache trace" when rendering cache provenance inside a run
- Rename private dashboard adapter modules/files where they are clearly run-inspection adapters and
  not RAG/citation schemas:
  - `DelegatedEvidenceComponent` -> `DelegatedTraceComponent`
  - `ReplayEvidenceNotebookComponent` -> `ReplayTraceNotebookComponent`
  - `SemanticEvidenceNotebookComponent` -> `SemanticCacheTraceNotebookComponent`
- For `RemoteInvocationEvidenceComponent` and `IncidentEvidenceComponent`, the planner should
  inspect current labels and rename first-level run/workflow inspection copy to trace while
  preserving local "audit evidence", "incident evidence", or "policy evidence" wording only when
  it names proof material rather than the whole run surface.
- Keep generic UI helper primitives such as `evidence_rows`, `evidence_section`, and `raw_evidence`
  unless the planner can add aliases cleanly. These are internal component vocabulary and still
  serve proof-material layouts.
- Add a terminology guard that allowlists RAG/citation/grounding/policy evidence while rejecting
  surface-sense strings such as "operator evidence", "semantic evidence notebook", and "default
  runtime lane" in adopter-facing docs.
- Add a no-schema-rename guard proving no `trace_refs` migration or `evidence_refs` rename was
  introduced.
- Glossary must explicitly say: trace aligns with OTel/OpenInference-style observability vocabulary,
  but OpenInference-compatible export/substrate is not claimed until SEED-007.

Rejected alternatives:

- **Label-only evidence rename:** low-risk, but leaves private adapters and test names teaching the
  wrong model to future contributors.
- **Broad code-symbol evidence rename:** risks schemas, migrations, DTO fields, and RAG correctness.

### D-03 - Glossary: standalone adopter reference now

- Create `docs/glossary.md` in Phase 46 as the canonical adopter glossary.
- Include `docs/glossary.md` immediately in:
  - `mix.exs` `docs/0` `extras`
  - `mix.exs` package files, if package docs surface tests require explicit file inclusion
  - README docs list
- Do not wait for Phase 48. Phase 46's success criteria require a committed glossary, and Phase 47
  needs a stable vocabulary anchor.
- Do not bury the glossary inside README or `docs/adoption_lanes.md`. Those are onboarding/how-to
  surfaces; the glossary is reference material.
- Entry shape should be compact and repeated for every term:
  - Scoria term
  - short definition
  - industry equivalent or adjacent term
  - use when / do not use when
  - related Scoria APIs/docs
- Required entries:
  - `run`
  - `reviewer` with `operator` as legacy/persona alias
  - `trace`
  - `evidence`
  - `capability`
  - `verification suite`
  - `scoped context`
  - `semantic cache`
  - `knowledge base`
  - `grounding`
  - `bounded handoff`
- Include a short "legacy terms" table mapping old docs to final vocabulary:
  - operator -> reviewer
  - projected context -> scoped context
  - semantic fast path -> semantic cache
  - optional knowledge -> optional knowledge base
  - adoption lane / capability lane -> capability
  - proof lane / verification lane -> verification suite
  - surface-sense evidence -> trace
  - RAG/citation evidence -> unchanged
- Phase 48 may later group/move this page under a Reference/Glossary section with ExDoc
  `groups_for_extras`; Phase 46 should avoid folder reshuffles or guide ladder work.

Rejected alternatives:

- **README glossary section:** visible, but bloats the front door and becomes harder for agents to
  target.
- **Embedded in adoption_lanes:** hides non-capability terms in the wrong guide type.
- **Future-only:** fails Phase 46 and causes Phase 47/48 to re-litigate vocabulary.

### D-04 - Upgrade notes: hybrid, explicit, unreleased

- Add `## [Unreleased]` near the top of `CHANGELOG.md` before `## [0.1.2]`.
- Under `### Changed`, add a "Pre-1.0 terminology migration" note.
- Do not label the whole change as "Breaking Changes" unless old documented APIs/options are
  removed without aliases.
- Include an old-to-new table with compatibility status:
  - operator -> reviewer
  - surface-sense evidence -> trace
  - adoption lanes -> capabilities
  - proof/verification lane -> verification suite
  - projected context -> scoped context
  - semantic fast path -> semantic cache
  - optional knowledge -> optional knowledge base
  - Keystone / v2.0 Relay -> removed internal code names
- Explicitly state:
  - current Hex release remains `0.1.2` until Phase 50 cuts the next release
  - these notes describe unreleased main-branch changes
  - RAG/citation evidence and `evidence_refs` stay unchanged
  - no DB migration is introduced by the terminology migration
  - legacy aliases remain accepted during the `0.1.x` line, where implemented
- Add a short README upgrade note under `## Install` before "Upgrading or re-running install" so
  adopters do not miss the rename while copying install examples.
- Phase 50 owns final release-section placement, version/status reconciliation, release-preview
  proof, Hex publish, and post-publish smoke.

Rejected alternatives:

- **Strict breaking-note:** honest if removing APIs, but conflicts with target `0.1.3` unless the
  release plan changes.
- **Light cleanup note:** too vague for docs-as-contract changes and weak against TERM-04.

### D-05 - Coherent implementation order

Use this order so docs never describe names that do not exist:

1. Add new compatibility surfaces and aliases (`ReviewerSurface`, `ReviewerBroadcast`,
   `VerificationSuites`, semantic-cache profile alias, `scoped_context:` option).
2. Rename private run-inspection UI adapters and rendered labels where low-risk.
3. Add `docs/glossary.md` and wire it into ExDoc/package/docs navigation.
4. Update README and stable docs to final vocabulary.
5. Add CHANGELOG and README upgrade notes.
6. Add terminology drift guards and no-schema-rename guards.
7. Run focused docs/contract tests and a docs build or release-preview command if available.

### Claude's Discretion

- Exact compatibility wrapper implementation and whether wrappers are `@moduledoc false` or have
  a short legacy note.
- Exact new semantic-cache module name, provided docs expose a final-vocabulary API such as
  `Scoria.SemanticCache.Profile` and old `Scoria.SemanticLane` remains accepted.
- Exact helper/test module names for terminology guards.
- Exact phrasing of glossary entries, provided they preserve the decisions above and the brand voice:
  clear, operator-grade, no hype, no backend-guts-first explanations.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning and Requirements

- `.planning/ROADMAP.md` - Phase 46 goal, success criteria, and dependency chain into Phases 47-50.
- `.planning/REQUIREMENTS.md` - TERM-01..04 and milestone out-of-scope boundaries.
- `.planning/PROJECT.md` - v3.5 core value, n=1 reviewer/operator persona lens, and P1-P6 scope
  doctrine.
- `.planning/seeds/SEED-005-documentation-overhaul.md` - final canonical rename map, glossary
  inventory, docs sequencing, and public vocabulary strategy.

### Prior Phase Context

- `.planning/milestones/v3.4-phases/43-knowledge-tenant-isolation/43-CONTEXT.md` - tenant/actor
  scope posture, knowledge evidence, and RAG/citation boundaries.
- `.planning/milestones/v3.4-phases/44-dashboard-auth-seam/44-CONTEXT.md` - host-owned auth/scope
  wording and dashboard operator/reviewer surface boundary.
- `.planning/milestones/v3.4-phases/45-correctness-sweep-fail-closed-proof-closeout/45-CONTEXT.md`
  - no-fake-measurement doctrine, evidence correctness, and SEED-005 docs deferral.

### Product Voice and Research

- `.planning/research/ai-architectural-patterns.md` - domain vocabulary for runs, traces, spans,
  RAG, grounding, handoff, gates, and review.
- `.planning/research/operator-ui-north-star.md` - reviewer/operator moments, trace workbench
  language, scope contract, copy standards, and future UI deferrals.
- `brandbook/brand-book.md` - canonical copy, word bank, tagline, accessibility/copy rules, and
  final README/Hex positioning blocks.
- `prompts/ai-architectural-patterns-deep-research.md` - detailed architecture terminology and
  trace/RAG/handoff mental models.
- `prompts/ai-eval-best-practices-deep-research.md` - eval/RAG/reviewer vocabulary and
  traceability guardrails.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native library posture, embedded LiveView UI,
  trace/eval store, and ecosystem lessons.

### Current Public Docs

- `README.md` - front-door vocabulary, install examples, capability list, status/version drift, and
  user-visible terminology to migrate.
- `CHANGELOG.md` - add `[Unreleased]` terminology migration note.
- `mix.exs` - ExDoc extras, package files, Hex description, and future docs grouping integration.
- `docs/adoption_lanes.md` - main capability/proof-language cleanup, `Four Lanes` count bug, and
  dashboard scope wording.
- `docs/bounded_handoffs.md` - `projected context` -> `scoped context` migration.
- `docs/operator_verification.md` - proof-command `lane` -> `verification suite` migration and
  reviewer trace language.
- `docs/phoenix_runtime_example.md` - `Keystone` codename leak and operator evidence wording.
- `docs/semantic_fast_path.md` - `semantic fast path` -> `semantic cache` migration.
- `docs/connector_adoption.md` - connector capability and verification-suite wording.
- `docs/support_copilot_gallery.md` - gallery capability labels and reviewer/persona wording.

### Public and Discoverable Code

- `lib/scoria.ex` - public facade docs; add `scoped_context` language for handoffs.
- `lib/scoria/semantic_lane.ex` - old public semantic-cache admission behavior to wrap/alias.
- `lib/scoria/verification_lanes.ex` - old proof-command vocabulary to rename/wrap.
- `lib/scoria/observe/operator_broadcast.ex` - old reviewer live-event broadcast naming.
- `lib/scoria_web/operator_surface.ex` - old reviewer dashboard read-model naming.
- `lib/scoria_web/components/delegated_evidence_component.ex` - run-inspection component rename
  candidate.
- `lib/scoria_web/components/replay_evidence_notebook_component.ex` - run-inspection component
  rename candidate.
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex` - semantic-cache trace
  component rename candidate.
- `lib/scoria_web/components/citation_evidence_component.ex` - RAG/citation evidence component to
  keep as evidence.
- `lib/scoria/eval/score.ex` - `evidence_refs` schema field to keep unchanged.
- `lib/scoria/knowledge/grounding_score.ex` - `evidence_refs` schema field to keep unchanged.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Scoria.AdopterDocContract` - existing docs drift-contract style; extend or mirror it for final
  terminology assertions.
- `Scoria.HexConsumerContract.adopter_doc_surfaces/0` - existing package/docs surface list; likely
  needs `docs/glossary.md`.
- `Scoria.VerificationLanes` - command SSOT; create `VerificationSuites` wrapper/new module rather
  than duplicating proof command data.
- `Scoria.SemanticLane` - existing behavior/macro; can become a compatibility wrapper around the
  new semantic-cache profile surface.
- `ScoriaWeb.Copy` and domain copy modules - existing single-source copy pattern from v3.3; use for
  reviewer-facing labels where possible.
- Existing component tests under `test/scoria_web/components/` - focused proof path for renamed
  run-inspection adapters.

### Established Patterns

- Scoria uses explicit contracts and tests to prevent docs drift rather than relying on manual copy
  review.
- Public docs and installer/package files are contract-tested because Hex adoption depends on
  packaged truth, not repo-only paths.
- The project prefers compatibility aliases over surprise breakage when a release target is still
  `0.1.x`.
- v3.4 locked fail-closed/no-fake-evidence semantics; terminology must not relabel unknown or
  unsupported proof as reassuring trace output.
- v3.3 locked component-native, accessible, dark/light coherent UI; Phase 46 copy changes should
  not add new UI primitives or visual motifs.

### Integration Points

- README docs list and install/upgrade sections.
- ExDoc extras in `mix.exs`.
- Package file list in `mix.exs`.
- Adopter docs under `docs/`.
- Public facade and documented modules in `lib/scoria*.ex`.
- Dashboard components under `lib/scoria_web/components/`.
- Contract tests that scan docs/source for stale terms and package inclusion.

</code_context>

<specifics>
## Specific Ideas

- User selected all gray areas and asked for subagent research across architecture, ecosystem
  precedent, DX, SRE/security, UI/UX, JTBD, brand, and prompt-corpus lenses.
- Four research slices were used:
  - rename blast radius
  - evidence vs trace boundary
  - glossary/docs IA
  - upgrade-note strictness
- Coherent recommendation:
  - make final vocabulary real in public docs, ExDoc, examples, and user-visible copy now
  - keep compatibility aliases for old public names during the `0.1.x` line
  - keep persisted/schema/internal evidence and lane fields stable unless a future breaking release
    intentionally migrates them
  - create a standalone glossary now and defer larger docs architecture
  - communicate changes as unreleased pre-1.0 terminology migration with an explicit old-to-new map
- External primary/current references considered during discussion:
  - ExDoc docs: extras and modules can be grouped via `groups_for_extras` and `groups_for_modules`.
  - Elixir docs: documentation is first-class; soft deprecation can live in docs/CHANGELOG before
    warning-emitting deprecation.
  - SemVer: `0.y.z` public API may change, but public API should still be declared through code or
    documentation; breaking changes should be communicated clearly.
  - Keep a Changelog: changelogs are for humans, keep `[Unreleased]`, and list deprecations/removals
    clearly.
  - OpenInference/OpenTelemetry/Langfuse/LangSmith: trace/span vocabulary is standard for AI
    execution observability; RAG/citation evidence remains a separate useful concept.

</specifics>

<deferred>
## Deferred Ideas

- **README first-screen positioning and owns-vs-delegates table** - Phase 47.
- **ExDoc grouping, guide ladder, folder moves, and full docs IA** - Phase 48.
- **Curated root `llms.txt` and/or `AGENTS.md`** - Phase 49.
- **Release PR, final version/status reconciliation, Hex publish, and post-publish smoke** -
  Phase 50.
- **OpenInference-compatible trace substrate/export claims** - SEED-007.
- **Retrieval/RAG eval depth, faithfulness, reranking, and richer citation maps** - SEED-009.
- **Persistent scope bar, unified queue, 3-pane Run Workbench, story-spine visualization, and
  structural reviewer UI pivot** - SEED-013.
- **Global internal source cleanup for every old word occurrence** - only worth doing in a future
  breaking cleanup if compatibility wrappers become too expensive.

</deferred>

---

*Phase: 46-Terminology and public vocabulary migration*
*Context gathered: 2026-07-09*

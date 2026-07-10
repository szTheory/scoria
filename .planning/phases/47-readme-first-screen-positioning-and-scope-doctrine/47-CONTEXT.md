# Phase 47: README first-screen positioning and scope doctrine - Context

**Gathered:** 2026-07-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 47 makes Scoria's front door understandable before the release cut. It rewrites the
README first screen and stable adopter docs so a Phoenix adopter can answer four questions
without reading planning history:

1. What is Scoria?
2. Who is it for, and who is it not for?
3. What does Scoria own versus what the host Phoenix app owns?
4. Why choose embedded Phoenix governance instead of, or alongside, external LLM-ops platforms?

This phase delivers POS-01..04 only. It may update README, stable docs, comparison copy,
scope-doctrine copy, version/install fallback references, and docs drift contracts. It does
not restructure ExDoc or the guide ladder, add AI-readable `llms.txt`/`AGENTS.md`, cut the
Hex release, or implement deferred feature seeds.

</domain>

<decisions>
## Implementation Decisions

Hard constraints carried forward:

- Phase 46 locked the public vocabulary: reviewer, trace, capabilities, verification suite,
  scoped context, semantic cache, and optional knowledge base.
- The P1-P6 scope doctrine is locked in `.planning/PROJECT.md`, but adopter docs should
  translate it into concrete product boundaries rather than expose planning labels first.
- Brandbook copy is useful, but newer SEED-005/Phase 46 terminology overrides older
  `operator` language in prompt and brandbook artifacts.
- Scoria's comparison posture must be honest: embedded Phoenix governance, host Postgres/Ecto,
  `/scoria`, in-path gates, and zero required egress for Scoria governance records are real;
  warehouse-scale analytics, broad cross-language SDK maturity, prompt playground depth, and
  mature external observability ecosystems are ceded strengths.

### D-01 - README first screen: plain-English embedded Phoenix front door

Use the plain-English SEED-005 front door, not the current capability-ladder-first shape.
README must open, after logo/tagline/badges, with one paragraph that says:

> Scoria is an Elixir/Phoenix library you add to an existing Phoenix app to run AI/LLM
> work durably and inspectably. Every run - one execution such as a prompt render, model
> call, tool call, retrieval, approval, or eval score - is recorded as a queryable
> Postgres/Ecto trace. A mounted LiveView dashboard at `/scoria` lets a human reviewer
> inspect, debug, approve, and resume that work. Scoria runs inside your app's BEAM and
> database boundary; it is not a hosted SaaS agent platform.

Do not introduce capabilities, verification suites, or internal milestone vocabulary before
this paragraph. Those concepts can appear after the adopter knows the product category and
boundary.

Rejected alternatives:

- **Refined capability ladder first:** smallest diff, but still asks adopters to understand
  coined taxonomy before the product category.
- **Code/quickstart first:** familiar for small libraries, but Scoria's trust boundary is the
  product. Code first makes it look like another LLM client.
- **Competitor comparison first:** strong differentiation, but defensive and stale-prone.

### D-02 - README first-screen order

Use this public README order:

1. Brand mark, `# Scoria`, tagline, badges.
2. Plain-English "what this is" paragraph from D-01.
3. Short "who this is for" paragraph using n=1 roles-not-headcount language.
4. Short "not for" line or compact boundary list.
5. Link or compact preview of "What Scoria owns vs what your app owns."
6. Only then: capability ladder, install, quickstart, verification suites.

This keeps the first screen adopter-focused and moves backend/source-of-truth details into
tables or guide sections where they help rather than overwhelm.

### D-03 - Scope doctrine table: adopter-readable owns-vs-delegates rows

Do not show P1-P6 labels as the main public table. Use an adopter-readable table with this
schema:

| Boundary | Scoria owns | Your Phoenix app owns | Why this boundary exists | Example / verification |
|----------|-------------|-----------------------|--------------------------|------------------------|

Recommended row set:

- **Run records and traces** - Scoria owns durable run records, trace projection, exact
  `run_id` readback, and reviewer inspection. The host owns ticket/order/customer/domain
  truth and references it by host IDs.
- **Reviewer dashboard scope** - Scoria owns `/scoria`, the dashboard scope seam, and
  trusted scope reads. The host owns authentication, authorization, tenant membership, and
  role values.
- **Governance gates** - Scoria owns approval, budget, breaker, eval-gate, and tool-policy
  mechanisms. The host owns thresholds, policy values, escalation rules, and business risk
  interpretation.
- **Eval and release proof** - Scoria owns scorer execution, persisted score evidence,
  fail-closed verdict posture, and verification-suite commands. The host owns prompts,
  product success definitions, expected outputs, and release intent.
- **Knowledge retrieval and grounding** - Scoria owns tenant-scoped retrieval filtering,
  citation validation, grounding checks, and persisted evidence. The host owns the corpus,
  business meaning, metadata semantics, and end-user answer surface.
- **Bounded handoff scoped context** - Scoria owns same-run handoff records, scoped-context
  validation, and delegated lineage readback. The host owns which facts may be passed and
  which role should receive them.
- **Remote connectors and tools** - Scoria owns registration, grants, health state, trace
  evidence, and approval pauses. The host owns which tools exist, what credentials mean,
  and whether a side effect is allowed in its product.
- **Phoenix/BEAM infrastructure** - Scoria owns library defaults, Ecto migrations,
  Telemetry/PubSub/Oban-friendly integration points, and dashboard assets. The host owns
  deployment topology, repo config, secrets, app supervision, and non-Scoria UI.

Keep the table copy concrete. Avoid backend guts unless the detail is needed to explain a
fundamental boundary, such as authz delegation or host-owned policy values.

### D-04 - Persona framing: roles, not headcount

State that the reviewer is a role, not a department. The default reader is the smallest
viable Phoenix team: one engineer may wear AI/product, platform, SRE, prompt, eval, and
reviewer hats. The docs should degrade gracefully to a few people, but never imply that a
dedicated ML platform, Trust and Safety, or compliance team is required.

Recommended README/guide wording:

> Scoria is for Phoenix teams where one engineer may need to ship prompts, inspect runs,
> approve risky tool calls, run evals, and debug incidents without adopting a separate
> hosted control plane.

Add a compact audience boundary after the opening:

- **Core:** Phoenix AI/product engineers, backend/platform engineers, SRE/devops hats,
  reviewers/approvers, prompt writers, eval checkers, and MCP/workflow configurators.
- **Adjacent:** security, privacy/legal, Trust and Safety, domain experts, PMs, and support
  teams consume hooks, docs, exported proof, or review outputs, but are not the first
  dedicated Scoria surface in this phase.
- **Not Scoria's surface:** end users of host AI flows, host product designers, finance or
  executive dashboards, a general data warehouse, and host auth/policy administration.

### D-05 - Hosted/external LLM-ops comparison: hybrid framing

Use a hybrid comparison:

- README stays category-level: Scoria is embedded Phoenix governance, not a hosted or
  external LLM-ops control plane.
- A stable comparison guide names common peers in a source-linked section: LangSmith,
  Langfuse, Braintrust, and Arize Phoenix.
- The guide title should avoid inaccurate shorthand such as "hosted-only tools." Prefer
  **Scoria vs external LLM-ops platforms** or **Scoria vs hosted and external LLM-ops**.

Safe claims now:

- Scoria runs inside the host Phoenix app.
- Scoria records its governance/runtime data in the host's Postgres/Ecto boundary.
- Scoria ships an embedded LiveView reviewer dashboard at `/scoria`.
- Scoria delegates identity, authorization, role values, and business truth to the host.
- Scoria supports durable runs, reviewer-visible traces, approvals, fail-closed eval posture,
  tenant-scoped knowledge retrieval, and upgrade-safe verification suites.
- Scoria requires no separate Scoria-hosted control plane and no required egress for Scoria
  governance records beyond whatever model/tool providers the host app already calls.

Ceded strengths:

- External platforms may be better when the team needs cross-language SDK coverage, managed
  warehouse-scale analytics, hosted dashboards across many services, mature prompt
  playgrounds, broad team collaboration around evals, or non-Phoenix stacks.

Deferred or forbidden claims:

- Do not claim OpenInference-compatible export until SEED-007 ships.
- Do not claim Rule-of-Two/lethal-trifecta enforcement until SEED-010 ships.
- Do not claim mature scorer calibration or regression depth beyond current fail-closed
  posture until SEED-008 ships.
- Do not claim deep retrieval eval/rerank/faithfulness metrics until SEED-009 ships.
- Do not claim full retention, masking, purge, or feedback governance until SEED-011 ships.
- Do not call all peers "hosted SaaS"; several official docs describe self-hosted, hybrid,
  local, or open-source options.
- Always write **Arize Phoenix** when referring to the LLM-ops tool to avoid confusion with
  the Phoenix web framework.

### D-06 - Version and install fallback cleanup

Phase 47 should clean stale README version references that currently conflict with the live
release baseline:

- README GitHub fallback example must not point at `v0.1.1`.
- README status must not say current release is `0.1.1`.
- Current released Hex baseline is `0.1.2`; `0.1.3` is the target release cut owned by
  Phase 50.
- Prefer Hex-primary install guidance. GitHub fallback should be framed as fork/pinned-patch
  guidance, not a recommended release path.

Docs/maintainer release-command drift outside README may be handled here if it directly blocks
POS-01/POS-04 clarity, otherwise Phase 50 owns final release reconciliation.

### D-07 - Docs contracts and drift guards

Add or extend focused docs contracts so the positioning does not regress:

- README first screen contains the plain-English embedded-Phoenix paragraph before capability
  ladder or verification-suite language.
- README has no stale `0.1.1` current-release or fallback guidance.
- Scope table includes Scoria-owned and host-owned rows for dashboard scope, governance gates,
  eval proof, knowledge retrieval, and run records.
- Adopter-facing docs do not expose P1-P6 as the primary public table labels.
- Comparison docs separate safe current claims from deferred seed claims and avoid
  "all peers are hosted SaaS" wording.

Prefer the existing contract-test style around `Scoria.AdopterDocContract`,
`Scoria.HexConsumerContract`, `scope_doctrine_contract_test.exs`,
`changelog_contract_test.exs`, and `terminology_contract_test.exs`.

### D-08 - UX, design, and microcopy posture for docs

The docs UI is text-first, but UX still matters:

- Use progressive disclosure: plain-language promise first; raw API, storage, policy, and
  verification details one level deeper.
- Make tables scannable and accessible. Keep cells short; move long rationale below the table.
- Use brand voice: calm, exact, operator-grade, low hype.
- Do not add new brand assets or decorative visuals in this phase. Preserve the existing logo,
  tagline, and brandbook direction.
- Avoid exposing backend internals as adopter-facing nouns unless they explain a real contract
  the adopter must honor.
- Copy should answer who/what/where/when/why for each JTBD:
  - Who: Phoenix teams, often one engineer wearing several hats.
  - What: run, inspect, approve, resume, and verify AI/LLM work.
  - Where: inside the existing Phoenix app, BEAM, Ecto/Postgres, and `/scoria`.
  - When: after adding Scoria to an app and before adopting optional capabilities.
  - Why: make AI behavior durable, inspectable, recoverable, and gateable without adopting a
    separate control plane.

### Claude's Discretion

- Exact README paragraph editing is flexible as long as D-01's facts stay intact and the text
  remains shorter than the current jargon-first opening.
- Exact table row count can be 6-8 rows. Do not add rows for unbuilt seeds unless clearly marked
  deferred.
- Exact comparison guide filename is flexible. Suggested names: `docs/llm_ops_comparison.md` or
  `docs/scoria_vs_external_llm_ops.md`.
- Exact test module names are flexible; prefer extending existing docs contract modules before
  creating a new broad scanner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning and Requirements

- `.planning/ROADMAP.md` - Phase 47 goal, success criteria, dependency on Phase 46, and
  Phase 48-50 boundaries.
- `.planning/REQUIREMENTS.md` - POS-01..04 plus milestone out-of-scope table and traceability.
- `.planning/PROJECT.md` - current core value, n=1 persona lens, constraints, key decisions,
  and P1-P6 scope doctrine.
- `.planning/STATE.md` - current phase status and release-readiness context.
- `.planning/seeds/SEED-005-documentation-overhaul.md` - plain-English README paragraph,
  scope doctrine, persona strategy, comparison reframing, and stale-version diagnosis.

### Prior Phase Context

- `.planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md` - final
  terminology, compatibility aliases, glossary decisions, and docs-as-public-API constraints.
- `.planning/milestones/v3.4-phases/45-correctness-sweep-fail-closed-proof-closeout/45-CONTEXT.md`
  - fail-closed correctness posture, no-fake-measurement doctrine, and scope-doctrine proof.
- `.planning/milestones/v3.4-phases/44-dashboard-auth-seam/44-CONTEXT.md` - host-owned auth,
  dashboard scope resolver, and URL tenant values as hints only.
- `.planning/milestones/v3.4-phases/43-knowledge-tenant-isolation/43-CONTEXT.md` - tenant-scoped
  retrieval, knowledge evidence, and RAG/citation boundary.

### Brand, Prompt, and Research Corpus

- `brandbook/brand-book.md` - canonical tagline, brand voice, README/Hex positioning blocks,
  visual direction, and copy style. Newer reviewer/trace terminology overrides old operator
  wording where they conflict.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first DX,
  Ecto-native state, embedded LiveView dashboards, and zero-configuration onboarding.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops gap, trace/eval/control-plane
  positioning, LiveView/Ecto/Plug ecosystem fit, DX lessons, and external AI-ops lessons.
- `prompts/ai-architectural-patterns-deep-research.md` - trace-first architecture, guardrails,
  eval posture, prompt/version/tool/retrieval vocabulary, and production AI footguns.
- `prompts/ai-eval-best-practices-deep-research.md` - eval, dataset, regression, and scorer
  concepts that inform safe comparison claims.
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` - n=1 reviewer/operator
  JTBD, progressive disclosure, control-room UX, and microcopy guidance.
- `prompts/scoria-brand-book-deep-research.md` - older brand research and positioning; useful
  for rationale, but superseded by committed `brandbook/brand-book.md` and Phase 46 terminology.
- `prompts/brand-book-pressure-test-prompt.md` - quality lenses for README, docs, brand voice,
  DX, accessibility, and marketing surface review.

### Current Public Docs

- `README.md` - primary front-door surface to rewrite; contains stale `v0.1.1` fallback and
  `0.1.1` status references to fix.
- `docs/glossary.md` - final vocabulary source of truth from Phase 46.
- `docs/adoption_lanes.md` - current capability ladder and existing dashboard scope language.
- `docs/operator_verification.md` - verification-suite guidance, dashboard scope proof, eval
  proof, and knowledge proof language.
- `docs/bounded_handoffs.md` - scoped-context and bounded handoff wording.
- `docs/semantic_fast_path.md` - semantic cache wording and legacy filename caveat.
- `docs/connector_adoption.md` - remote connector capability and reviewer trace wording.
- `docs/MAINTAINERS.md` - release and maintainer command references that may need Phase 50 or
  direct stale-version reconciliation.
- `CHANGELOG.md` - unreleased terminology note and historical version context.

### Code and Test Anchors

- `lib/scoria/adopter_doc_contract.ex` - existing adopter docs contract source.
- `lib/scoria/hex_consumer_contract.ex` - current package/version/adopter surface SSOT.
- `test/scoria/adoption_surface_test.exs` - adopter docs drift guard.
- `test/scoria/scope_doctrine_contract_test.exs` - scope-doctrine guard and current required
  doc fragments.
- `test/scoria/changelog_contract_test.exs` - README/CHANGELOG terminology migration guard.
- `test/scoria/terminology_contract_test.exs` - final-vocabulary and storage-rename guard.
- `test/scoria/hex_consumer_contract_test.exs` - Hex version and registry upgrade contract.
- `test/scoria/package_surface_test.exs` - README/package surface checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `README.md` already has the logo/tagline/badge shell, capability ladder, install section,
  quickstart, and glossary link. Phase 47 should reorder and rewrite, not invent a new README
  architecture from scratch.
- `docs/glossary.md` already defines the final terms and compatibility aliases. Link to it
  rather than duplicating all terminology in README.
- `docs/adoption_lanes.md` already carries the capability ladder. README should summarize
  and link to it after the first-screen positioning.
- `docs/operator_verification.md` already has dashboard, eval, and knowledge scope-proof copy
  that can seed the owns-vs-delegates rows.
- `Scoria.AdopterDocContract` and related tests provide the preferred drift-guard style for
  docs truth.

### Established Patterns

- Scoria treats docs as public API and locks important wording with contract tests.
- The project prefers Hex-primary adoption copy with GitHub fallback only for forks or pinned
  patches.
- Phoenix ecosystem docs normally show concrete mount/config/auth seams rather than hiding
  integration shape. Follow this, but keep first-screen copy adopter-oriented.
- Existing GSD decisions favor compatibility and explicit boundary docs over broad internal
  churn in this milestone.

### Integration Points

- README first screen and status/install fallback examples.
- New or updated stable comparison guide under `docs/`.
- Cross-links from README, `docs/adoption_lanes.md`, `docs/operator_verification.md`, and
  possibly `docs/glossary.md`.
- Docs/package surface list if a new guide is added to packaged docs.
- Contract tests under `test/scoria/*doc*`, `test/scoria/*contract*`, and package surface tests.

</code_context>

<specifics>
## Specific Ideas

User selected all gray areas and requested subagent-backed research, pros/cons/tradeoffs,
idiomatic Phoenix/Plug/Ecto/LiveView ecosystem guidance, lessons from successful adjacent
tools, deep DX/JTBD/user psychology consideration, UI/UX and microcopy where applicable, and
a one-shot coherent recommendation set.

Four parallel research slices were used:

- README first-screen positioning.
- Owns-vs-delegates/scope-doctrine presentation.
- Persona and NOT-OURS framing.
- Hosted/external LLM-ops comparison.

External primary/current references considered:

- Phoenix Plug docs - composable boundaries and Phoenix request lifecycle:
  https://hexdocs.pm/phoenix/plug.html
- Phoenix LiveDashboard README - embedded LiveView operational dashboard, installation, and
  production auth framing:
  https://preview.hex.pm/preview/phoenix_live_dashboard/show/README.md
- Oban README/docs - Ecto-backed reliability/observability and host-app integration posture:
  https://github.com/oban-bg/oban and https://oban.hexdocs.pm/
- Ecto docs - repository/data-store boundary and adapter-backed persistence:
  https://hexdocs.pm/ecto/Ecto.Repo.html
- LangSmith docs - observability, tracing, monitoring, and online evaluation:
  https://docs.langchain.com/langsmith/observability
- Langfuse docs - open-source AI engineering platform with observability, prompts, evals,
  and platform/export features:
  https://langfuse.com/docs
- Braintrust docs - eval lifecycle, CI/CD, production scoring, and datasets:
  https://www.braintrust.dev/docs/evaluate and
  https://www.braintrust.dev/docs/annotate/datasets
- Arize Phoenix docs - tracing, evaluation, prompt engineering, datasets/experiments,
  OpenTelemetry/OpenInference integrations, and cross-language support:
  https://arize.com/docs/phoenix
- OpenInference semantic conventions - trace span kinds for LLM, retriever, tool, agent,
  guardrail, evaluator, and prompt:
  https://arize-ai.github.io/openinference/spec/semantic_conventions.html

Core synthesis:

- Lead with the product category and boundary, not internal capability taxonomy.
- Translate doctrine into adopter decisions: what Scoria records/gates/surfaces/reconstructs,
  and what the host app must still own.
- Treat reviewer as a role one Phoenix engineer can wear, not a separate org function.
- Compare peers respectfully. Name them in a stable guide, not in the README opening.
- Mark future feature claims explicitly instead of letting comparison copy imply they already
  shipped.

</specifics>

<deferred>
## Deferred Ideas

- **ExDoc grouping, guide ladder, and docs IA restructure** - Phase 48.
- **Curated root `llms.txt` and/or `AGENTS.md`** - Phase 49.
- **Final release reconciliation, PR #12, Hex `0.1.3`, and post-publish smoke** - Phase 50.
- **OpenInference-compatible trace export/substrate** - SEED-007.
- **Trustworthy eval depth, scorer calibration, and regression comparison maturity** - SEED-008.
- **Retrieval/RAG eval depth, faithfulness, reranking, and richer citation maps** - SEED-009.
- **Rule-of-Two/lethal-trifecta governance** - SEED-010.
- **Privacy, retention, purge, masking, and feedback governance** - SEED-011.
- **Persistent AI Feature grouping, unified queue, Run Workbench, and structural reviewer UI
  pivot** - SEED-013.

</deferred>

---

*Phase: 47-README first-screen positioning and scope doctrine*
*Context gathered: 2026-07-09*

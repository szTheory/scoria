# Phase 46: Terminology and public vocabulary migration - Research

**Researched:** 2026-07-09  
**Domain:** Elixir/Phoenix public terminology, ExDoc packaging, compatibility aliases, docs drift contracts, and no-migration vocabulary cleanup [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]  
**Confidence:** HIGH for repository inventory and phase constraints; MEDIUM for external documentation precedent because official docs were fetched through the configured websearch/jina providers [VERIFIED: codebase grep] [CITED: https://semver.org/] [CITED: https://keepachangelog.com/en/1.1.0/]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for every copied constraint in this section: `.planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md` [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]

### Locked Decisions

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

### the agent's Discretion

- Exact compatibility wrapper implementation and whether wrappers are `@moduledoc false` or have
  a short legacy note.
- Exact new semantic-cache module name, provided docs expose a final-vocabulary API such as
  `Scoria.SemanticCache.Profile` and old `Scoria.SemanticLane` remains accepted.
- Exact helper/test module names for terminology guards.
- Exact phrasing of glossary entries, provided they preserve the decisions above and the brand voice:
  clear, operator-grade, no hype, no backend-guts-first explanations.

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

## Summary

Phase 46 should be planned as a public vocabulary migration with compatibility aliases, not as a repository-wide refactor. The phase context locks a sense-aware rename, no schema migration, and `0.1.x` compatibility aliases for documented public/discoverable surfaces such as `OperatorSurface`, `OperatorBroadcast`, `VerificationLanes`, `SemanticLane`, `lane:`, and `projected_context:` [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].

The highest-risk boundary is the evidence/trace split. `evidence_refs` appears in persisted schemas and migrations for eval/knowledge/runtime proof material, while reviewer-facing run inspection copy and selected private dashboard adapters should move to `trace` vocabulary [VERIFIED: codebase grep] [VERIFIED: psql scoria_dev sample]. The planner should explicitly sequence code aliases before docs changes so the glossary and examples never describe names that do not exist [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].

No new package is needed. The work should use existing Elixir/Mix, ExDoc, ExUnit, Phoenix LiveView, docs contract, and release-preview machinery already present in the repository [VERIFIED: mix.lock] [VERIFIED: mix.exs] [VERIFIED: codebase grep]. External documentation supports the chosen approach: ExDoc supports extras/grouping, Elixir supports doc-level and warning-emitting deprecation mechanisms, SemVer treats public docs as part of API communication even before 1.0, Keep a Changelog recommends an Unreleased section, and OpenTelemetry/OpenInference support `trace`/`span` terminology for AI execution inspection without implying export implementation [CITED: https://ex-doc.hexdocs.pm/0.28.2/Mix.Tasks.Docs.html] [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html] [CITED: https://semver.org/] [CITED: https://keepachangelog.com/en/1.1.0/] [CITED: https://opentelemetry.io/docs/concepts/signals/traces/] [CITED: https://arize-ai.github.io/openinference/spec/].

**Primary recommendation:** Plan Wave 0 as test/guard and alias scaffolding, then migrate docs/copy through the glossary and upgrade-note path, while proving no `trace_refs`, `evidence_refs` rename, `projected_context` storage rename, or `lane_key` storage rename is introduced [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].

## Project Constraints (from AGENTS.md / CLAUDE.md)

No `AGENTS.md`, `CLAUDE.md`, or `.claude/CLAUDE.md` file exists in the repository root or `.claude` path requested by the phase prompt [VERIFIED: file lookup]. No project-local `.claude/skills/**/SKILL.md` or `.agents/skills/**/SKILL.md` files were found [VERIFIED: file lookup]. No project knowledge graph exists at `.planning/graphs/graph.json`, so graph-derived semantic relationship context was unavailable for this research [VERIFIED: file lookup].

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TERM-01 | A Phoenix adopter can learn final canonical terms from a glossary that maps Scoria terms to industry equivalents. [VERIFIED: .planning/REQUIREMENTS.md] | Add `docs/glossary.md`, include required entries, add README docs-list link, include in `mix.exs` `docs/0` extras and package files [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: mix.exs]. |
| TERM-02 | Adopter-facing docs use the final terminology strategy: reviewer, trace, capabilities, verification suite, scoped context, semantic cache, and optional knowledge base. [VERIFIED: .planning/REQUIREMENTS.md] | Use compatibility aliases for public/discoverable code symbols first, then update README/docs/UI copy and add terminology drift guards [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep]. |
| TERM-03 | Adopter-facing docs preserve correct RAG/citation use of evidence while removing leaked internal milestone code names and stale lane/count/version wording. [VERIFIED: .planning/REQUIREMENTS.md] | Keep citation/grounding evidence and `evidence_refs`, remove `Keystone`, `v2.0 Relay`, and `Four Lanes`, and allowlist evidence only where it means proof material [VERIFIED: codebase grep]. |
| TERM-04 | Public README and CHANGELOG include a pre-1.0 upgrade note for terminology changes that affect documented names, modules, or user-visible copy. [VERIFIED: .planning/REQUIREMENTS.md] | Add `[Unreleased]` before `[0.1.2]`, a Changed note with old-to-new table, and README install-adjacent upgrade note that says current Hex remains `0.1.2` until Phase 50 [VERIFIED: CHANGELOG.md] [VERIFIED: README.md] [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Glossary and adopter vocabulary | Docs / Static | Mix / ExDoc | The canonical artifact is `docs/glossary.md`, while ExDoc and Hex packaging must expose it through `mix.exs` [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: mix.exs]. |
| Public compatibility aliases | Elixir library API | Docs / Static | Public modules/options must exist before README, guides, or ExDoc recommend them [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| Reviewer-facing trace labels | Frontend Server / LiveView | Elixir API read models | User-visible dashboard copy lives in LiveView/components, while read models such as `OperatorSurface` provide backing data [VERIFIED: codebase grep]. |
| Evidence and persisted field protection | Database / Storage | Elixir schemas | Migrations and schemas persist `evidence_refs`, `projected_context`, and `lane_key`; Phase 46 must not rename those storage fields [VERIFIED: codebase grep] [VERIFIED: psql scoria_dev sample]. |
| Drift prevention | Test / CI | Docs / Static | Existing docs contracts already guard adopter surfaces, and Phase 46 should extend that pattern for final vocabulary and no-schema-rename checks [VERIFIED: test/scoria/adoption_surface_test.exs] [VERIFIED: test/scoria/package_surface_test.exs]. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, Erlang/OTP 28 | Compile, test, docs, and release-preview commands | This is the installed project runtime on the target machine [VERIFIED: elixir --version] [VERIFIED: mix --version]. |
| ExUnit | Built into Elixir 1.19.5 | Contract tests and source/docs guards | The repo already uses ExUnit tests for docs, package, changelog, and verification-lane contracts [VERIFIED: test directory grep]. |
| ExDoc | 0.40.3 | Generated API docs and guide extras | The project already depends on ExDoc for docs generation, and ExDoc supports extras plus grouping options [VERIFIED: mix.lock] [CITED: https://ex-doc.hexdocs.pm/0.28.2/Mix.Tasks.Docs.html]. |
| Phoenix LiveView | 1.1.30 | Reviewer-facing dashboard labels and components | The run-inspection UI surfaces are LiveView/component modules in `lib/scoria_web` [VERIFIED: mix.lock] [VERIFIED: codebase grep]. |
| Ecto SQL / PostgreSQL | Ecto SQL 3.13.5, local psql 14.17 | Persisted-field inventory and no-migration proof | The schemas and migrations use Ecto/PostgreSQL fields that Phase 46 must preserve [VERIFIED: mix.lock] [VERIFIED: psql --version] [VERIFIED: codebase grep]. |
| ripgrep | 15.1.0 | Vocabulary inventory and drift-guard authoring | The repo-wide terminology audit used `rg`, and contract tests can mirror targeted grep allowlists [VERIFIED: rg --version]. |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `mix scoria.release_preview` | Project Mix task | Package/docs surface preview | Use after glossary/docs/package-list edits to prove the packaged docs surface matches adopter-facing expectations [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]. |
| Docker | 29.5.2 | Local database fallback | Use `make native-db` or existing project DB flow if full suite or app-starting tests need the configured pgvector Postgres on the project port [VERIFIED: docker --version] [VERIFIED: Makefile]. |
| PostgreSQL readiness probe | `/tmp:5432` accepting connections during research | Runtime-state inventory sample | Use only as local sample evidence; the no-migration decision comes from migrations/schemas and phase constraints, not this dev database alone [VERIFIED: pg_isready] [VERIFIED: psql scoria_dev sample]. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing ExDoc extras | New docs generator or folder restructure | Rejected because Phase 48 owns guide ladder and ExDoc IA; Phase 46 only needs `docs/glossary.md` exposed now [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| Soft docs/CHANGELOG deprecation | Warning-emitting `@deprecated` on every wrapper | Rejected unless the planner accepts warning noise, because Elixir `@deprecated` emits warnings while `@doc deprecated:` can annotate docs without compile warnings [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html] [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| Compatibility aliases | Breaking removal of old names | Rejected for the `0.1.x` line unless Phase 50 changes the release target to a breaking release [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |

**Installation:**
```bash
# No new packages are recommended for Phase 46.
```

**Version verification:** Existing stack versions were verified from `mix.lock`, `elixir --version`, `mix --version`, `psql --version`, `docker --version`, and `rg --version`; no new registry install target was identified [VERIFIED: mix.lock] [VERIFIED: local CLI probes].

## Package Legitimacy Audit

No external package installation is recommended for Phase 46, so the package-legitimacy gate is not required for this phase [VERIFIED: research inventory].

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | N/A | N/A | N/A | N/A | N/A | No new package install [VERIFIED: research inventory]. |

**Packages removed due to [SLOP] verdict:** none because no package candidates were proposed [VERIFIED: research inventory].  
**Packages flagged as suspicious [SUS]:** none because no package candidates were proposed [VERIFIED: research inventory].

## Architecture Patterns

### System Architecture Diagram

```text
Phase 46 input
  -> Locked SEED-005 vocabulary and TERM-01..04 requirements
  -> Runtime-state inventory decision point
      -> persisted evidence_refs / projected_context / lane_key found
      -> choose aliases and docs, not database migrations
  -> Compatibility alias wave
      -> ReviewerSurface / ReviewerBroadcast / VerificationSuites
      -> SemanticCache.Profile plus legacy SemanticLane
      -> scoped_context public option plus legacy projected_context
  -> User-visible vocabulary wave
      -> docs/glossary.md
      -> README and stable guides
      -> dashboard labels and run-inspection adapter names
  -> Upgrade note wave
      -> CHANGELOG [Unreleased] Changed note
      -> README install-adjacent note
  -> Verification wave
      -> terminology guard
      -> no-schema-rename guard
      -> package/docs preview
```

This diagram follows the implementation order locked in D-05 and keeps persisted storage checks before copy edits [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].

### Recommended Project Structure

```text
docs/
├── glossary.md                 # canonical adopter glossary for final vocabulary
├── adoption_lanes.md           # migrate to capabilities wording, fix Four Lanes count bug
├── bounded_handoffs.md         # scoped context language, legacy projected_context mapping
├── operator_verification.md    # verification suite and reviewer trace language
└── semantic_fast_path.md       # semantic cache language; filename rename is optional unless aliases and links are handled

lib/scoria/
├── verification_suites.ex      # final-vocabulary command SSOT or wrapper around existing data
├── verification_lanes.ex       # legacy compatibility wrapper
├── semantic_cache/profile.ex   # final-vocabulary semantic-cache admission API
└── semantic_lane.ex            # legacy compatibility wrapper

lib/scoria/observe/
├── reviewer_broadcast.ex       # final-vocabulary PubSub helper
└── operator_broadcast.ex       # legacy compatibility wrapper

lib/scoria_web/
├── reviewer_surface.ex         # final-vocabulary dashboard read model
└── operator_surface.ex         # legacy compatibility wrapper

test/scoria/
├── terminology_contract_test.exs       # new or extended drift guard
└── no_schema_rename_contract_test.exs  # new or folded into terminology guard
```

The structure above is a planning target derived from locked phase decisions and current public/discoverable code inventory [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].

### Pattern 1: Public Alias First, Docs Second

**What:** Add final-vocabulary modules/options first and keep legacy wrappers so docs can promote new names without breaking existing consumers [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**When to use:** Use this pattern for `ReviewerSurface`, `ReviewerBroadcast`, `VerificationSuites`, `SemanticCache.Profile`, and `scoped_context:` [VERIFIED: codebase grep].  
**Example:**

```elixir
# Source: proposed Phase 46 pattern from existing module inventory [VERIFIED: codebase grep]
defmodule ScoriaWeb.ReviewerSurface do
  @moduledoc """
  Reviewer-facing read model for Scoria dashboard run traces.
  """

  # Move or delegate current OperatorSurface implementation here.
end

defmodule ScoriaWeb.OperatorSurface do
  @moduledoc false

  defdelegate list_tenant_runs(tenant_id), to: ScoriaWeb.ReviewerSurface
end
```

### Pattern 2: Option Alias Without Storage Rename

**What:** Accept final public names at API boundaries and normalize them into existing storage/internal fields [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**When to use:** Use for `scoped_context:` -> `projected_context`, and `semantic_cache: [profile: ...]` -> existing `lane`/`lane_key` internals [VERIFIED: codebase grep].  
**Example:**

```elixir
# Source: proposed Phase 46 pattern from Runtime.Params inventory [VERIFIED: codebase grep]
defp scoped_context(opts) do
  Keyword.get(opts, :scoped_context) || Keyword.get(opts, :projected_context)
end
```

### Pattern 3: Sense-Aware Evidence Allowlist

**What:** Treat `trace` as the run-inspection story and keep `evidence` where the noun means proof material or citations [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**When to use:** Use for docs guards, component renames, glossary entries, and no-schema-rename tests [VERIFIED: codebase grep].  
**Example:**

```elixir
# Source: proposed Phase 46 test pattern from existing docs contract style [VERIFIED: test/scoria/adoption_surface_test.exs]
@allowed_evidence_contexts [
  "RAG/citation evidence",
  "grounding evidence",
  "evidence_refs",
  "policy evidence"
]

@rejected_surface_terms [
  "operator evidence",
  "semantic evidence notebook",
  "default runtime lane"
]
```

### Anti-Patterns to Avoid

- **Global regex replace:** It would risk corrupting RAG/citation evidence, migrations, schema fields, historical changelog entries, and compatibility wrappers [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].
- **Docs-only rename:** It would leave ExDoc and copy-paste examples teaching stale public modules/options [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].
- **Migration for vocabulary fields:** It would violate the explicit no-schema-migration constraint and break existing records without product value in this release-readiness phase [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].
- **OpenInference overclaim:** The glossary may align wording with OTel/OpenInference, but the implementation claim is deferred to SEED-007 [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://arize-ai.github.io/openinference/spec/].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs navigation for the glossary | Custom docs/sidebar tooling | ExDoc `extras` now; Phase 48 can use `groups_for_extras` | ExDoc already supports extras and grouping options [CITED: https://ex-doc.hexdocs.pm/0.28.2/Mix.Tasks.Docs.html]. |
| Deprecation mechanism | Custom compile warnings or ad hoc runtime warnings | Soft docs/CHANGELOG notes, with `@doc deprecated:` or `@deprecated` only if warning noise is intentional | Elixir documents warning-emitting `@deprecated` and doc metadata options [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html]. |
| Terminology migration | One-shot global replace script | Sense-aware contracts plus targeted aliases | Persisted fields and evidence meanings require boundary-aware handling [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep]. |
| Run trace substrate | Homemade OpenInference exporter in Phase 46 | Glossary alignment only; defer substrate/export to SEED-007 | Phase 46 excludes OpenInference-compatible trace substrate work [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://arize-ai.github.io/openinference/spec/]. |
| Database vocabulary cleanup | Ecto migration renaming `evidence_refs`, `projected_context`, or `lane_key` | Public alias normalization and compatibility wrappers | The phase explicitly forbids schema migration and local inventory found existing persisted fields [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep] [VERIFIED: psql scoria_dev sample]. |

**Key insight:** The old vocabulary is not uniformly wrong; `evidence` remains correct for citations/grounding and `lane_key`/`projected_context` remain storage compatibility fields, so the planner must split user-facing language from persisted/runtime compatibility [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Migrations and schemas define `ai_workflow_steps.projected_context`, `ai_semantic_cache_entries.lane_key`, and multiple `evidence_refs` fields; local `scoria_dev` sample had 14 non-empty `projected_context` workflow rows, 0 semantic-cache rows, 1 non-empty eval `evidence_refs` row, and 0 non-empty grounding `evidence_refs` rows [VERIFIED: codebase grep] [VERIFIED: psql scoria_dev sample]. | Code edit only: add public aliases and tests; do not write a data migration or rename existing persisted columns/fields [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| Live service config | Repo CI/workflow and verification command surfaces reference `VerificationLanes`/lane vocabulary; no repo evidence of n8n, Datadog, Tailscale, Cloudflare, or other external live-service config was found during research [VERIFIED: codebase grep]. | Update repository docs/tests/module aliases only; do not change CI required-check names such as `CI / ci-gate` [VERIFIED: .planning/STATE.md]. |
| OS-registered state | `launchctl` search found no Scoria-specific OS registrations containing Scoria terminology; unrelated Apple relay entries were ignored [VERIFIED: launchctl grep]. | No OS re-registration task required [VERIFIED: launchctl grep]. |
| Secrets/env vars | Current process environment did not expose `SCORIA`, `OPERATOR`, `EVIDENCE`, `LANE`, `PROJECTED`, `TRACE`, `KEYSTONE`, or `RELAY` variables; repo configuration uses `SCORIA_DB_*`, which is not part of the terminology rename [VERIFIED: env grep] [VERIFIED: codebase grep]. | No secret-key or env-var rename required; keep database environment names stable [VERIFIED: codebase grep]. |
| Build artifacts | Generated preview directories under `tmp/scoria-hex-preview/` and `tmp/scoria-release-preview/` contain old docs names; these are build artifacts rather than source of truth [VERIFIED: file lookup]. | Regenerate preview/docs artifacts via `mix scoria.release_preview` or docs build after source docs change; do not patch generated preview files manually [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]. |

**Nothing found in category:** no Scoria OS registrations were found [VERIFIED: launchctl grep]. No terminology-related secret/env rename was found [VERIFIED: env grep]. No external live-service configuration source outside repo was found in the checked project files [VERIFIED: codebase grep].

## Common Pitfalls

### Pitfall 1: Renaming `evidence_refs` to `trace_refs`

**What goes wrong:** Existing eval, grounding, and semantic-cache references break or require a migration that Phase 46 explicitly forbids [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].  
**Why it happens:** A broad `evidence -> trace` rename misses that citation/grounding evidence remains correct vocabulary [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**How to avoid:** Add a no-schema-rename guard and allowlist RAG/citation/grounding evidence contexts [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**Warning signs:** New migrations containing `trace_refs`, changed schema field names, or failing fixtures around eval/grounding references [VERIFIED: codebase grep].

### Pitfall 2: Publishing docs for names before aliases exist

**What goes wrong:** README/ExDoc examples tell adopters to call `ReviewerSurface`, `VerificationSuites`, `SemanticCache.Profile`, `profile:`, or `scoped_context:` before those names compile [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**Why it happens:** Docs copy is easier to edit than public compatibility surfaces [VERIFIED: codebase grep].  
**How to avoid:** Follow D-05 order: aliases first, docs second, drift tests third [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
**Warning signs:** Updated docs tests pass by string scan but examples fail under compiler or package-preview smoke [VERIFIED: test/scoria/package_surface_test.exs].

### Pitfall 3: Treating historical or fixture text as current adopter copy

**What goes wrong:** The planner wastes time rewriting historical changelog entries or packaged fixtures rather than current public surfaces [VERIFIED: codebase grep].  
**Why it happens:** Broad grep counts include `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` and historical release notes [VERIFIED: codebase grep].  
**How to avoid:** Scan current adopter docs, README, public moduledocs, and generated-package inputs first; use explicit fixture/history allowlists [VERIFIED: test fixture lookup].  
**Warning signs:** Diff churn in old unpack fixtures without corresponding contract reason [VERIFIED: codebase grep].

### Pitfall 4: Overclaiming trace substrate support

**What goes wrong:** Glossary language implies OpenInference export or tracing infrastructure that this phase does not implement [VERIFIED: .planning/REQUIREMENTS.md].  
**Why it happens:** OpenTelemetry/OpenInference use trace/span vocabulary, but Phase 46 only changes public vocabulary [CITED: https://opentelemetry.io/docs/concepts/signals/traces/] [CITED: https://arize-ai.github.io/openinference/spec/].  
**How to avoid:** State that Scoria uses `trace` as reviewer vocabulary now and that OpenInference-compatible substrate/export remains SEED-007 [VERIFIED: .planning/REQUIREMENTS.md].  
**Warning signs:** New docs mention exporters, instrumentation completeness, or OpenInference compatibility outside a deferred/future note [VERIFIED: .planning/REQUIREMENTS.md].

### Pitfall 5: Breaking stable CI policy names

**What goes wrong:** Renaming verification lanes everywhere changes CI or policy surfaces that prior phases explicitly kept stable [VERIFIED: .planning/STATE.md].  
**Why it happens:** `VerificationLanes` is both public vocabulary and an internal command SSOT [VERIFIED: codebase grep].  
**How to avoid:** Introduce `VerificationSuites` as the final public surface while preserving command ordering and CI required-check names [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: .planning/STATE.md].  
**Warning signs:** Diffs in workflow topology, required-check strings, or `closeout_order/0` semantics [VERIFIED: .planning/STATE.md].

## Code Examples

Verified and cited patterns the planner should translate into tasks:

### ExDoc Extra Inclusion

```elixir
# Source: ExDoc docs support :extras; current mix.exs already owns docs/0 [CITED: https://ex-doc.hexdocs.pm/0.28.2/Mix.Tasks.Docs.html] [VERIFIED: mix.exs]
defp docs do
  [
    main: "readme",
    extras: [
      "README.md",
      "docs/glossary.md"
    ]
  ]
end
```

### Soft Compatibility Wrapper

```elixir
# Source: Elixir supports documentation metadata and @deprecated warnings; use soft docs unless warnings are chosen [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html]
defmodule Scoria.Observe.OperatorBroadcast do
  @moduledoc false

  defdelegate subscribe(tenant_id), to: Scoria.Observe.ReviewerBroadcast
end
```

### No-Schema-Rename Guard

```elixir
# Source: Phase constraint and current migrations/schemas preserve evidence_refs, projected_context, and lane_key [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep]
test "terminology migration does not rename persisted evidence fields" do
  migration_text =
    Path.wildcard("priv/repo/migrations/*.exs")
    |> Enum.map(&File.read!/1)
    |> Enum.join("\n")

  refute migration_text =~ "trace_refs"
  assert migration_text =~ "evidence_refs"
  assert migration_text =~ "projected_context"
  assert migration_text =~ "lane_key"
end
```

### README/CHANGELOG Upgrade Note Shape

```markdown
<!-- Source: Keep a Changelog recommends [Unreleased] and Changed/Deprecated categories [CITED: https://keepachangelog.com/en/1.1.0/] -->
## [Unreleased]

### Changed

- Pre-1.0 terminology migration: public docs now use reviewer, trace, capability, verification suite, scoped context, semantic cache, and knowledge base. Legacy aliases remain accepted during the 0.1.x line where implemented.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flat or implicit docs vocabulary | Explicit adopter glossary with term, definition, equivalent, use/do-not-use guidance, and related APIs/docs | Phase 46 planning scope on 2026-07-09 | Gives Phase 47/48 a stable vocabulary anchor [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| `operator` as general persona label | `reviewer` for human reviewer persona, with `operator` reserved for legacy mapping or SRE/on-call sense | Locked in Phase 46 context on 2026-07-09 | Aligns public copy with final SEED-005 vocabulary [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md]. |
| Run-inspection surfaces labeled as evidence | Reviewer-visible execution story labeled as trace, while citation/grounding proof remains evidence | Locked in Phase 46 context on 2026-07-09 | Prevents RAG/citation schema breakage while matching AI observability vocabulary [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [CITED: https://opentelemetry.io/docs/concepts/signals/traces/] [CITED: https://arize-ai.github.io/openinference/spec/]. |
| `adoption lanes` and proof `lane` wording | `capabilities` for adoption scope and `verification suite` for proof commands | Locked in Phase 46 context on 2026-07-09 | Removes stale count bug and reduces overloaded `lane` language [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: docs/adoption_lanes.md]. |
| Hard breaking rename before release | Pre-1.0 compatibility aliases with explicit Unreleased notes | Locked in Phase 46 context on 2026-07-09 | Preserves `0.1.x` adopters while making docs honest [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [CITED: https://semver.org/] [CITED: https://keepachangelog.com/en/1.1.0/]. |

**Deprecated/outdated:**
- `Keystone` and `v2.0 Relay` are leaked internal code names in adopter docs and should be removed [VERIFIED: docs/phoenix_runtime_example.md] [VERIFIED: docs/bounded_handoffs.md].
- `The Four Lanes` is stale because the current adoption guide lists five capability rows under that heading [VERIFIED: docs/adoption_lanes.md].
- README still contains stale `0.1.1` references while live Hex baseline is `0.1.2` and Phase 50 owns the `0.1.3` release cut [VERIFIED: README.md] [VERIFIED: .planning/STATE.md].

## Assumptions Log

Project facts were checked against repository files, local probes, or the local dev database sample, and external practice claims were tied to official docs or configured research providers [VERIFIED: research inventory]. One metadata freshness estimate is tagged `[ASSUMED]` because it is a planning horizon, not a source fact [ASSUMED].

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The research should be treated as fresh until 2026-08-08 unless Phase 46 code changes begin earlier. [ASSUMED] | Metadata | Planner may rely on stale inventory if repository vocabulary changes before planning starts. |

## Open Questions

1. **Should legacy wrapper modules be hidden or documented with a short legacy note?**  
   What we know: D-01 allows `@moduledoc false` or explicit legacy docs on wrappers [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
   What is unclear: The exact ExDoc discoverability balance is left to implementation discretion [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
   Recommendation: Default wrappers to `@moduledoc false` when final modules are fully documented; use a short legacy note only where hiding the wrapper would make upgrade discovery harder [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html].

2. **Should `docs/semantic_fast_path.md` be renamed now or only retitled internally?**  
   What we know: Public vocabulary must say semantic cache, and Phase 48 owns folder/guide ladder reshuffles [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
   What is unclear: Whether a filename rename creates link churn that belongs in Phase 46 or Phase 48 [VERIFIED: codebase grep].  
   Recommendation: Prefer content/title/link updates in Phase 46 and only rename the file if all inbound links and package tests are updated in the same task [VERIFIED: mix.exs] [VERIFIED: codebase grep].

3. **Should historical changelog sections be rewritten?**  
   What we know: D-04 requires a new Unreleased note and Phase 50 owns final release-section placement [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].  
   What is unclear: Whether older historical entries should retain old names as history [VERIFIED: CHANGELOG.md].  
   Recommendation: Do not rewrite historical entries unless they are current upgrade guidance; put current terminology in the new Unreleased note and README upgrade note [CITED: https://keepachangelog.com/en/1.1.0/].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/test/docs | yes | 1.19.5 with Erlang/OTP 28 | None needed [VERIFIED: elixir --version]. |
| Mix | Test/docs/release preview | yes | 1.19.5 | None needed [VERIFIED: mix --version]. |
| PostgreSQL client | Runtime inventory and DB-backed tests | yes | psql 14.17 | File-only tests can run without DB where configured [VERIFIED: psql --version]. |
| Local PostgreSQL service | Runtime-state sample | partial | `/tmp:5432` accepting connections; project defaults use separate configured ports in Makefile/config | Use Docker/native DB flow for app-starting tests [VERIFIED: pg_isready] [VERIFIED: Makefile]. |
| Docker | Local DB fallback | yes | 29.5.2 | Use existing local Postgres if configured [VERIFIED: docker --version]. |
| ripgrep | Terminology audit | yes | 15.1.0 | Elixir file scans in tests [VERIFIED: rg --version]. |
| Git | Commit research and later phase work | yes | 2.41.0 | None needed [VERIFIED: git --version]. |

**Missing dependencies with no fallback:**
- None identified for planning and file-level contract work [VERIFIED: environment probes].

**Missing dependencies with fallback:**
- Project-specific database service on the exact configured app port was not proven by `pg_isready`, but Docker is available and file-only docs contracts do not require a running DB [VERIFIED: pg_isready] [VERIFIED: docker --version] [VERIFIED: Makefile].

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Mix 1.19.5 [VERIFIED: mix --version] |
| Config file | `mix.exs`, `config/test.exs`, and `test/test_helper.exs` [VERIFIED: file lookup] |
| Quick run command | `mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/changelog_contract_test.exs test/scoria/terminology_contract_test.exs` [VERIFIED: test directory grep] |
| Full suite command | `mix test --warnings-as-errors` plus `mix scoria.release_preview` for package/docs preview [VERIFIED: Makefile] [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TERM-01 | Glossary exists, is packaged, is in ExDoc extras, and contains required final terms plus industry equivalents | contract/unit | `mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/terminology_contract_test.exs` | `package_surface_test.exs` yes; `terminology_contract_test.exs` Wave 0 gap [VERIFIED: test directory grep]. |
| TERM-02 | Current adopter docs and user-visible copy use reviewer, trace, capabilities, verification suite, scoped context, semantic cache, and knowledge base | contract/unit | `mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` | `adoption_surface_test.exs` yes; terminology guard gap [VERIFIED: test/scoria/adoption_surface_test.exs]. |
| TERM-03 | Evidence is preserved for RAG/citation/grounding while stale code names and lane/count/version wording are removed from adopter docs | contract/unit | `mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` | Wave 0 gap [VERIFIED: codebase grep]. |
| TERM-04 | README and CHANGELOG explain the pre-1.0 terminology migration and compatibility status | contract/unit | `mix test --warnings-as-errors test/scoria/changelog_contract_test.exs test/scoria/hex_consumer_contract_test.exs` | Existing tests yes, updates required [VERIFIED: test/scoria/changelog_contract_test.exs] [VERIFIED: test/scoria/hex_consumer_contract_test.exs]. |

### Sampling Rate

- **Per task commit:** Run the focused test covering the changed surface, usually docs/package/changelog/terminology contracts [VERIFIED: test directory grep].
- **Per wave merge:** Run the quick command above and any focused component tests touched by run-inspection adapter renames [VERIFIED: test/scoria_web/components directory lookup].
- **Phase gate:** Run `mix scoria.release_preview` and the full focused Phase 46 contract set before `$gsd-verify-work`; run full `mix test --warnings-as-errors` if DB availability is confirmed or the implementation touches shared runtime code [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] [VERIFIED: environment probes].

### Wave 0 Gaps

- [ ] `test/scoria/terminology_contract_test.exs` - scan current adopter docs, README, selected public moduledocs, and copy surfaces for final vocabulary and blocked legacy strings [VERIFIED: codebase grep].
- [ ] `test/scoria/no_schema_rename_contract_test.exs` or a section inside `terminology_contract_test.exs` - prove no `trace_refs` migration or `evidence_refs` rename was introduced [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md].
- [ ] `docs/glossary.md` - committed glossary required by TERM-01 [VERIFIED: .planning/REQUIREMENTS.md].
- [ ] Update existing `test/scoria/package_surface_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/changelog_contract_test.exs`, and `test/scoria/hex_consumer_contract_test.exs` to match final vocabulary and upgrade-note expectations [VERIFIED: test directory grep].

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 46 does not change authentication; retain host-owned dashboard auth/scope resolver boundaries from Phase 44 [VERIFIED: .planning/STATE.md]. |
| V3 Session Management | no | Phase 46 does not introduce sessions or cookies [VERIFIED: .planning/REQUIREMENTS.md]. |
| V4 Access Control | yes | Terminology changes must preserve dashboard tenant authority from `DashboardScope` and must not make URL/query tenant values authoritative [VERIFIED: .planning/STATE.md]. |
| V5 Input Validation | yes | New `scoped_context:` and `semantic_cache: [profile: ...]` aliases must reuse existing validation behavior rather than bypassing `projected_context` or semantic-cache module checks [VERIFIED: codebase grep]. |
| V6 Cryptography | no | Phase 46 does not add crypto, secrets, token storage, or key handling [VERIFIED: .planning/REQUIREMENTS.md]. |

### Known Threat Patterns for Elixir/Phoenix Terminology Migration

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Schema rename causing data loss or broken proof references | Tampering / Denial of Service | No migration; add source-scan guard for `trace_refs` and `evidence_refs` preservation [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep]. |
| Copy changes weakening tenant authority language | Elevation of Privilege | Keep Phase 44 host-owned scope doctrine and avoid wording that treats URL tenant as authority [VERIFIED: .planning/STATE.md]. |
| Alias accepting unsafe scoped context values | Tampering / Information Disclosure | Normalize aliases through existing validation and reject unsafe projected/scoped context keys through current runtime params path [VERIFIED: codebase grep]. |
| Observability overclaim hiding missing trace substrate | Repudiation | State trace vocabulary alignment only and defer OpenInference-compatible export/substrate to SEED-007 [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://arize-ai.github.io/openinference/spec/]. |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md` - locked decisions, boundaries, implementation order, and deferred ideas [VERIFIED: file read].
- `.planning/REQUIREMENTS.md` - TERM-01..04 and milestone out-of-scope boundaries [VERIFIED: file read].
- `.planning/STATE.md` - release baseline, CI stability decisions, and Phase 44 host-owned scope decisions [VERIFIED: file read].
- `.planning/seeds/SEED-005-documentation-overhaul.md` - final vocabulary map and documentation sequencing [VERIFIED: file read].
- `README.md`, `CHANGELOG.md`, `mix.exs`, `mix.lock`, `docs/*.md`, `lib/scoria*.ex`, `lib/scoria_web/**/*.ex`, and `test/**/*.exs` - current public docs/code/test inventory [VERIFIED: codebase grep].
- Local CLI probes: `elixir --version`, `mix --version`, `psql --version`, `docker --version`, `rg --version`, `git --version`, `pg_isready` [VERIFIED: local CLI probes].
- Local dev database sample for runtime-state inventory counts in `scoria_dev` [VERIFIED: psql scoria_dev sample].

### Secondary (MEDIUM confidence)

- ExDoc Mix.Tasks.Docs official docs - extras and grouping options [CITED: https://ex-doc.hexdocs.pm/0.28.2/Mix.Tasks.Docs.html].
- Elixir `Module` official docs and writing documentation guide - docs metadata and deprecation behavior [CITED: https://elixir.hexdocs.pm/1.18.1/Module.html] [CITED: https://hexdocs.pm/elixir/writing-documentation.html].
- Semantic Versioning 2.0.0 - public API declaration, 0.y.z status, and deprecation communication [CITED: https://semver.org/].
- Keep a Changelog 1.1.0 - `[Unreleased]` and change categories [CITED: https://keepachangelog.com/en/1.1.0/].
- OpenTelemetry traces docs - trace/span vocabulary [CITED: https://opentelemetry.io/docs/concepts/signals/traces/].
- OpenInference official specification and semantic conventions - AI trace/span vocabulary over OpenTelemetry [CITED: https://arize-ai.github.io/openinference/spec/] [CITED: https://arize-ai.github.io/openinference/spec/semantic_conventions.html].

### Tertiary (LOW confidence)

- One `[ASSUMED]` metadata freshness estimate is present; no planning recommendation depends on it [ASSUMED].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and tools were verified locally from `mix.lock` and CLI probes [VERIFIED: mix.lock] [VERIFIED: local CLI probes].
- Architecture: HIGH - phase boundaries, alias strategy, and no-migration rules are locked in CONTEXT.md and confirmed by code inventory [VERIFIED: .planning/phases/46-terminology-and-public-vocabulary-migration/46-CONTEXT.md] [VERIFIED: codebase grep].
- Pitfalls: HIGH for repo-specific pitfalls and MEDIUM for ecosystem precedent because external documentation was official but fetched through configured web/jina providers [VERIFIED: codebase grep] [CITED: https://semver.org/] [CITED: https://keepachangelog.com/en/1.1.0/].

**Research date:** 2026-07-09 [VERIFIED: system date].  
**Valid until:** 2026-08-08 for repository inventory unless Phase 46 code changes begin earlier; external docs precedent should be rechecked before release notes if Phase 50 moves the release target [ASSUMED].

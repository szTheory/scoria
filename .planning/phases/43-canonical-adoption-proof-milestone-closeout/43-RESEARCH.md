# Phase 43: Canonical Adoption Proof & Milestone Closeout - Research

**Researched:** 2026-05-24
**Domain:** Canonical adoption verification, milestone closeout, and proof classification for the bounded handoff lane [VERIFIED: .planning/ROADMAP.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo-local proof surfaces, CI wiring, and local test runs were all inspected directly on 2026-05-24]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Canonical proof scope
- **D-01:** `mix test.adoption` is the canonical proof lane for Phase 43. It is the explicit `ADPT-02` acceptance harness for the default public-runtime and bounded-handoff adoption story.
- **D-02:** `mix test` remains maintainer repo-health context, not the canonical phase-proof gate. The phase should report broader suite status separately instead of redefining bounded-handoff proof around unrelated red.
- **D-03:** The canonical proof story stays runtime-first and adopter-shaped: install, migration compatibility, public runtime facade, bounded handoff docs/source alignment, exact readback, and operator evidence.
- **D-04:** Optional knowledge-lane setup must stay outside the canonical proof. Phase 43 should preserve the existing distinction between the default runtime lane and optional knowledge features.

### Proof artifact shape
- **D-05:** Phase 43 should produce one thin canonical closeout ledger rather than many sibling proof docs or implicit state-only closure.
- **D-06:** The ledger should be pointer-first, not transcript-first. Link the exact proof sources, tests, docs, and prior phase verification artifacts instead of duplicating their content.
- **D-07:** The closeout ledger should answer four questions in one place:
  - what the canonical proof lane is
  - what evidence proves docs/source/runtime alignment
  - whether broader suite noise exists and why it does or does not matter to `ADPT-02`
  - whether Scoria should stop bounded-handoff work after Relay or carry one narrow follow-up
- **D-08:** The recommended artifact shape is a single Phase 43 closeout/proof document such as `43-CLOSEOUT.md` or equivalent planner-selected name, provided it serves as the canonical synthesis object for this phase.

### Closeout bar
- **D-09:** The default closeout recommendation after Relay is: stop touching bounded handoffs for now unless the canonical proof exposes a concrete adopter-facing failure in the default lane.
- **D-10:** A follow-up is justified only when the proof shows a specific failure in the runtime-first adoption path, such as confusing `run_id`/`session_id` semantics, missing delegated lineage visibility, broken docs/source alignment, or unclear operator evidence for the same durable run.
- **D-11:** “Would be nice” examples, richer delegated notebooks, broader orchestration UX, or general handoff marketing polish do not justify keeping bounded handoffs open after Relay.
- **D-12:** If a follow-up is needed, it should be exactly one narrow adopter-facing fix tied to the failed proof seam, not a vague bucket of possible handoff work.

### Policy for unrelated failures and noise
- **D-13:** Only failures that break `mix test.adoption` or falsify the bounded-handoff support story block `ADPT-02`.
- **D-14:** Broader full-suite failures, warning noise, or adjacent regressions must be named explicitly in the closeout ledger when present, but they should be recorded as unrelated repo debt unless they affect:
  - compile stability
  - migrations
  - the public `Scoria` runtime facade
  - bounded-handoff behavior
  - docs/source fragments in the adoption lane
  - security/trust invariants
- **D-15:** The closeout policy must not use fuzzy “seems unrelated” judgment. Escalation triggers should be explicit so future maintainers can apply the same rule consistently.
- **D-16:** The ledger should preserve repo-health honesty without letting unrelated failures hijack a narrowly defined milestone proof.

### Shift-left and escalation posture
- **D-17:** Planning and future GSD flows should shift low-impact closeout choices left by default. For this lane, the default bias is:
  - one canonical adoption proof command
  - one canonical synthesis ledger
  - one stop-by-default closeout recommendation
  - one explicit unrelated-failure policy
- **D-18:** Only escalate to the user when a choice changes product shape, durable truth, security/policy boundary, tenant blast radius, or the meaning of the canonical proof claim itself.
- **D-19:** This phase should encode those defaults clearly enough that downstream research/planning/execution agents do not need to re-ask routine closeout-structure or proof-scope questions.

### the agent's Discretion
- Exact ledger filename and section naming, provided there is one obvious canonical closeout artifact.
- Exact wording for the final closeout recommendation, provided it remains decisive and falsifiable.
- Exact presentation of broader suite debt, provided the distinction between `ADPT-02` proof and repo-health context stays explicit.
- Exact cross-links into prior verification artifacts, provided downstream readers can follow the proof chain without archaeology.

### Deferred Ideas (OUT OF SCOPE)
- Richer delegated notebook-style forensics or heavier operator UX beyond the current runtime/detail and workflow evidence surfaces.
- Stronger bounded-handoff example families beyond the current runtime example and bounded-handoff guide unless canonical proof shows a real adoption failure.
- Any broader multi-agent or orchestration positioning beyond the narrow bounded-handoff lane.
- Turning Phase 43 into a repo-wide cleanup project for unrelated eval, prompt, replay, or operator-surface failures.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-02 | `mix test.adoption` canonically covers the public runtime facade, bounded handoff guide/source alignment, and adoption-lane verification without requiring optional knowledge-lane setup. [VERIFIED: .planning/REQUIREMENTS.md] | `mix test.adoption` is a named Mix task over a fixed 10-file adoption subset; CI runs it separately; it passed locally on 2026-05-24 with `3 doctests, 34 tests, 0 failures`; the selected files cover install, migration compatibility, docs/source alignment, runtime integration, and bounded handoff contract proof. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; .github/workflows/ci.yml; mix test.adoption local run 2026-05-24] |
</phase_requirements>

## Summary

Phase 43 is a proof-and-closeout phase over an already-implemented runtime-first bounded handoff lane, not a feature-build phase. [VERIFIED: .planning/ROADMAP.md; .planning/PROJECT.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] The core planning job is to preserve `mix test.adoption` as the one canonical `ADPT-02` acceptance claim, then synthesize existing tests, docs, and prior phase artifacts into one pointer-first closeout ledger. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; lib/mix/tasks/test.adoption.ex]

The repo already has the right proof substrate. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/adoption_surface_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_test.exs; test/scoria/handoff_example_source_test.exs; docs/operator_verification.md; README.md] `mix test.adoption` runs a fixed adoption-facing file list and passed locally on 2026-05-24 with `3 doctests, 34 tests, 0 failures`. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; mix test.adoption local run 2026-05-24] The broader suite is currently noisy outside the adoption lane, with local `mix test` failures on 2026-05-24 in eval persistence, offline runner, and Orchestrator LiveView approval inbox tests. [VERIFIED: mix test local run 2026-05-24; mix test --failed --trace local run 2026-05-24] None of those failing files are in the adoption task file list, so the planner should treat them as repo-health context to classify explicitly, not as automatic blockers for `ADPT-02`. [VERIFIED: lib/mix/tasks/test.adoption.ex; mix test local run 2026-05-24]

**Primary recommendation:** Use Phase 43 to keep `mix test.adoption` as the only milestone-proof gate, classify current full-suite failures against the explicit escalation triggers, and write one canonical closeout ledger that ends with a default “stop touching bounded handoffs for now” recommendation unless the proof itself fails. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; mix test.adoption local run 2026-05-24; mix test local run 2026-05-24]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical proof command ownership | API / Backend [VERIFIED: lib/mix/tasks/test.adoption.ex] | Database / Storage [VERIFIED: test/scoria/bootstrap/migration_lane_compatibility_test.exs; config/test.exs] | The proof entrypoint is a Mix task that runs backend/runtime tests and migration checks against the repo runtime and database-backed workflow state. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] |
| Docs/source alignment proof | CDN / Static [VERIFIED: README.md; docs/bounded_handoffs.md; docs/phoenix_runtime_example.md; docs/operator_verification.md] | API / Backend [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] | The primary artifacts are repo docs and checked source fragments, while tests enforce that those docs still match the public runtime facade and handoff contract. [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] |
| Public runtime facade coverage | API / Backend [VERIFIED: test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] | Database / Storage [VERIFIED: test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] | `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`, and `Scoria.resume_run/2` are exercised through backend tests backed by durable workflow rows. [VERIFIED: test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] |
| Operator evidence proof for the same run | Frontend Server (SSR) [VERIFIED: test/scoria/runtime_integration_test.exs] | API / Backend [VERIFIED: test/scoria/runtime_integration_test.exs; docs/operator_verification.md] | The proof checks the LiveView workflow page at `/scoria/workflows/:run_id`, but it is still driven by runtime DTOs and workflow truth from the backend. [VERIFIED: test/scoria/runtime_integration_test.exs; README.md] |
| Closeout ledger and recommendation | CDN / Static [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | — | The ledger is a planning artifact that synthesizes evidence and policy decisions; it should point at existing tests and docs rather than own new executable behavior. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version` 2026-05-24] | Runtime and test execution for the repo proof lane [VERIFIED: mix.exs; test/test_helper.exs] | The project targets `~> 1.19`, and the local environment matches that target exactly. [VERIFIED: mix.exs; `elixir --version` 2026-05-24] |
| Mix + custom `test.adoption` task | Mix 1.19.5 and repo-local task [VERIFIED: `mix --version` 2026-05-24; lib/mix/tasks/test.adoption.ex] | Canonical Phase 43 acceptance entrypoint [VERIFIED: .planning/REQUIREMENTS.md; lib/mix/tasks/test.adoption.ex] | The milestone requirement and locked decisions both name this command as the proof lane. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |
| ExUnit | project test framework [VERIFIED: test/test_helper.exs; mix test.adoption local run 2026-05-24] | Executes docs/source, runtime, install, and migration proofs [VERIFIED: lib/mix/tasks/test.adoption.ex] | The adoption lane is already encoded as normal ExUnit files, which keeps proof executable and boring. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs] |
| Phoenix | 1.8.7 [VERIFIED: mix.lock] | Powers the mounted operator evidence route under `/scoria` [VERIFIED: README.md; test/scoria/runtime_integration_test.exs] | The canonical proof includes the operator evidence page for the same durable run. [VERIFIED: README.md; docs/operator_verification.md; test/scoria/runtime_integration_test.exs] |
| Phoenix LiveView | 1.1.30 [VERIFIED: mix.lock] | Renders the workflow page used in the operator-evidence proof [VERIFIED: test/scoria/runtime_integration_test.exs] | The adoption story explicitly includes `/scoria/workflows/:run_id` as the operator-visible surface. [VERIFIED: README.md; docs/phoenix_runtime_example.md; docs/operator_verification.md] |
| Ecto SQL + PostgreSQL | `ecto_sql` 3.13.5 and `postgrex` 0.22.1 [VERIFIED: mix.lock] | Supports migration compatibility and durable workflow/runtime state in the proof lane [VERIFIED: config/test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs; test/scoria/runtime_test.exs] | The proof lane is not pure unit testing; it proves real persisted runtime and migration behavior. [VERIFIED: test/scoria/runtime_integration_test.exs; test/scoria/runtime_test.exs; config/test.exs] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Floki | 0.38.1 [VERIFIED: mix.lock] | HTML parser configured for LiveView tests [VERIFIED: test/test_helper.exs] | Needed when the proof touches rendered operator surfaces or docs-derived HTML assertions. [VERIFIED: test/test_helper.exs; test/scoria/runtime_integration_test.exs] |
| LazyHTML | 0.1.11 [VERIFIED: mix.lock] | Test-only LiveView HTML support dependency [VERIFIED: mix.exs; mix.lock] | Present because the repo already uses LiveView component and page tests in the broader suite. [VERIFIED: mix.exs; mix.lock] |
| Oban | 2.22.1 [VERIFIED: mix.lock] | Present in the stack but not a primary Phase 43 proof seam [VERIFIED: mix.lock; config/test.exs] | Only relevant if broader suite failures need classification against escalation triggers. [VERIFIED: mix test local run 2026-05-24] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix test.adoption` as the canonical proof lane [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | `mix test` as the milestone gate [VERIFIED: docs/operator_verification.md; .github/workflows/ci.yml] | Rejected because the full suite is currently noisy outside `ADPT-02`, while the adoption lane is a fixed, green, milestone-scoped subset. [VERIFIED: mix test.adoption local run 2026-05-24; mix test local run 2026-05-24] |
| One pointer-first closeout ledger [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | Multiple phase-closeout notes or transcript dumps [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | Rejected because the locked decision is one obvious canonical synthesis artifact, not a scavenger hunt across sibling docs. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |

**Installation:** [VERIFIED: .github/workflows/ci.yml; docs/operator_verification.md]
```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix test.adoption
```

**Version verification:** Versions above were verified from the local runtime and the checked-in lockfile, not from training data. [VERIFIED: `elixir --version` 2026-05-24; `mix --version` 2026-05-24; mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Developer / CI
    |
    v
mix test.adoption
    |
    +--> install + route smoke tests
    |
    +--> migration compatibility test
    |
    +--> docs/source alignment tests
    |       |
    |       +--> README.md
    |       +--> docs/bounded_handoffs.md
    |       +--> docs/phoenix_runtime_example.md
    |       +--> docs/operator_verification.md
    |
    +--> runtime facade + handoff contract tests
    |       |
    |       +--> Scoria.start_run / start_handoff_run / resume_run
    |       +--> same-run delegated evidence readback
    |
    +--> operator evidence integration test
            |
            +--> /scoria/workflows/:run_id
            +--> same durable run visible end-to-end

mix test
    |
    +--> broader repo-health context
            |
            +--> if failure touches compile / migrations / public runtime / bounded handoff /
            |    docs-source fragments / security-trust invariants => escalate into ADPT-02 blocker
            |
            +--> else record as unrelated debt in the closeout ledger

All evidence
    |
    v
one canonical closeout ledger
```
[VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/adoption_surface_test.exs; test/scoria/runtime_integration_test.exs; test/scoria/runtime_test.exs; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

### Recommended Project Structure
```text
.planning/phases/43-canonical-adoption-proof-milestone-closeout/
├── 43-RESEARCH.md       # phase research and planning constraints
├── 43-01-PLAN.md        # proof lane + failure classification work
├── 43-02-PLAN.md        # canonical closeout ledger work
└── 43-CLOSEOUT.md       # recommended canonical synthesis artifact

lib/mix/tasks/
└── test.adoption.ex     # canonical proof command

test/
├── mix/tasks/           # adoption command discoverability + install smoke
├── scoria/              # runtime, docs/source, migration, handoff proof files
└── support/             # shared checked fragments and helper constants

docs/
├── operator_verification.md
├── bounded_handoffs.md
└── phoenix_runtime_example.md
```
[VERIFIED: .planning/ROADMAP.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs]

### Pattern 1: Fixed Adoption Subset via a Named Mix Task
**What:** Keep the acceptance claim encoded as one named Mix task over a frozen file list. [VERIFIED: lib/mix/tasks/test.adoption.ex]  
**When to use:** Use this when a milestone needs one boring proof lane that is faster and narrower than the full suite but still runs normal ExUnit tests. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; .planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md]  
**Example:**
```elixir
defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @adoption_test_files [
    "test/scoria_test.exs",
    "test/scoria/identity_doctest_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/handoff_example_source_test.exs",
    "test/scoria/phoenix_example_source_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/scoria/runtime_test.exs",
    "test/mix/tasks/scoria.install_test.exs",
    "test/mix/tasks/scoria.install_route_smoke_test.exs",
    "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
  ]

  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @adoption_test_files)
  end
end
```
Source: `lib/mix/tasks/test.adoption.ex` [VERIFIED: lib/mix/tasks/test.adoption.ex]

### Pattern 2: Pointer-First Closeout Ledger
**What:** Write one canonical markdown artifact that points at commands, test files, docs, and prior verification artifacts instead of re-copying their contents. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; .planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md; .planning/v1.3-MILESTONE-AUDIT.md]  
**When to use:** Use this when the proof already exists in executable and documentary seams, and the missing work is synthesis plus explicit go/no-go classification. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; test/scoria/adoption_surface_test.exs; mix test.adoption local run 2026-05-24]  
**Example:**
```markdown
## Canonical Proof
- Command: `mix test.adoption`
- Local result: `3 doctests, 34 tests, 0 failures` on 2026-05-24

## Alignment Evidence
- README runtime-first story
- bounded handoff guide fragments
- Phoenix runtime example
- operator verification guide

## Broader Suite Context
- `mix test`: record failures and classify each against the escalation triggers

## Recommendation
- Stop bounded-handoff work for now unless the canonical proof itself failed
```
Source pattern: `42-GAP-LEDGER.md` plus Phase 43 locked artifact-shape decisions [VERIFIED: .planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

### Anti-Patterns to Avoid
- **Using `mix test` as the `ADPT-02` gate:** This contradicts the locked decision and currently lets unrelated eval and Orchestrator LiveView failures hijack the milestone claim. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; mix test local run 2026-05-24]
- **Leaking knowledge-lane prerequisites into the proof story:** The README, operator guide, and requirement all keep knowledge optional for this acceptance lane. [VERIFIED: README.md; docs/operator_verification.md; .planning/REQUIREMENTS.md]
- **Writing a transcript-first closeout artifact:** The user explicitly locked a pointer-first ledger over duplicated logs. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]
- **Reopening bounded handoffs on “nice to have” polish:** The closeout bar allows follow-up only for a concrete adopter-facing failure in the default proof lane. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical acceptance proof [VERIFIED: .planning/REQUIREMENTS.md] | A new browser-E2E or bespoke proof harness [VERIFIED: repo scan; no such lane is required by current milestone docs] | `mix test.adoption` [VERIFIED: lib/mix/tasks/test.adoption.ex] | The task already encodes the correct acceptance subset and passed locally. [VERIFIED: lib/mix/tasks/test.adoption.ex; mix test.adoption local run 2026-05-24] |
| Docs/source alignment [VERIFIED: .planning/ROADMAP.md] | A second manual checklist or prose-only reconciliation doc [VERIFIED: repo docs/test surfaces] | Existing adoption-surface and checked-fragment tests [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] | The repo already keeps support truth executable. [VERIFIED: test/scoria/adoption_surface_test.exs; test/mix/tasks/test.adoption_test.exs] |
| Closeout synthesis [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | Multiple sibling proof notes [VERIFIED: locked artifact-shape decision] | One canonical closeout ledger [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | The user wants one obvious place to answer the milestone question. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |
| Bounded handoff truth readback [VERIFIED: .planning/ROADMAP.md] | Raw workflow-table archaeology [VERIFIED: phase boundary docs] | Existing runtime/detail tests and delegated evidence surfaces [VERIFIED: test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs; docs/bounded_handoffs.md] | Phase 41 and 42 already established the public truth surface; Phase 43 should prove it, not redesign it. [VERIFIED: .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md; .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md] |

**Key insight:** The fastest safe plan is to prove and classify existing truth, not to create new proof machinery. [VERIFIED: .planning/PROJECT.md; lib/mix/tasks/test.adoption.ex; mix test.adoption local run 2026-05-24]

## Common Pitfalls

### Pitfall 1: Full-Suite Gate Drift
**What goes wrong:** The phase starts treating `mix test` as the acceptance claim and blocks closeout on unrelated failures. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Why it happens:** CI runs `mix test` and `mix test.adoption`, and the operator guide still mentions both maintainer closeout and host-app proof flows. [VERIFIED: .github/workflows/ci.yml; docs/operator_verification.md]  
**How to avoid:** Keep the ledger explicit that `mix test.adoption` is the `ADPT-02` gate and `mix test` is repo-health context to classify. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Warning signs:** The plan starts requiring full-suite green before writing the closeout recommendation, or it stops naming which failures are outside the adoption file list. [VERIFIED: lib/mix/tasks/test.adoption.ex; mix test local run 2026-05-24]

### Pitfall 2: Optional Knowledge Leakage
**What goes wrong:** The canonical proof story accidentally requires `pgvector`, knowledge tables, or `mix test.knowledge`. [VERIFIED: README.md; docs/operator_verification.md; test/test_helper.exs]  
**Why it happens:** The repo has multiple lanes, and CI also runs `mix test.knowledge`. [VERIFIED: .github/workflows/ci.yml]  
**How to avoid:** Keep Phase 43 commands, ledger sections, and success criteria centered on `mix test.adoption` and the default runtime surfaces only. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Warning signs:** The closeout artifact or verification steps reference knowledge bootstrap commands as proof prerequisites. [VERIFIED: README.md; docs/operator_verification.md]

### Pitfall 3: Fuzzy “Unrelated Failure” Judgment
**What goes wrong:** The closeout artifact hand-waves failures as unrelated without naming a rule. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Why it happens:** The broader suite currently has failures in adjacent surfaces, and it is tempting to dismiss them informally. [VERIFIED: mix test local run 2026-05-24; mix test --failed --trace local run 2026-05-24]  
**How to avoid:** Use the locked escalation triggers verbatim: compile stability, migrations, public runtime facade, bounded handoff behavior, docs/source adoption fragments, and security/trust invariants. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Warning signs:** The ledger says “seems unrelated” instead of mapping each failure to an explicit trigger. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

### Pitfall 4: Reopening the Milestone Without a Failed Seam
**What goes wrong:** The planner creates a follow-up bucket for general handoff polish even when the canonical proof is green. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; .planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md]  
**Why it happens:** The repo still has broader work available, and milestone closeout can drift into backlog gardening. [VERIFIED: .planning/STATE.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**How to avoid:** Default the recommendation to stop touching bounded handoffs unless the proof exposes one concrete adopter-facing failure. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]  
**Warning signs:** The final recommendation mentions “future improvements” without tying them to a failed proof seam. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

## Code Examples

Verified patterns from repo-local primary sources:

### Canonical Proof Lane Entry Point
```elixir
defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria adoption verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```
Source: `lib/mix/tasks/test.adoption.ex` [VERIFIED: lib/mix/tasks/test.adoption.ex]

### Docs/Source Alignment Guard
```elixir
test "bounded handoff guide stays aligned with the checked adoption fragments" do
  content = File.read!(@handoff_guide)

  for fragment <- AdoptionExample.handoff_doc_fragments() do
    assert content =~ fragment
  end
end
```
Source: `test/scoria/handoff_example_source_test.exs` [VERIFIED: test/scoria/handoff_example_source_test.exs]

### Runtime + Operator Evidence Proof
```elixir
{:ok, started} =
  Scoria.start_run(
    %{actor_id: "live-actor", tenant_id: "live-tenant", session_id: "live-session"},
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

{:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))

assert render(view) =~ started.run_id
assert render(view) =~ AdoptionExample.waiting_status()
```
Source: `test/scoria/runtime_integration_test.exs` [VERIFIED: test/scoria/runtime_integration_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad suite status or prose-only confidence as adoption proof [VERIFIED: older milestone-closeout patterns contrasted in current context] | Named `mix test.adoption` acceptance lane plus pointer-backed proof artifacts [VERIFIED: lib/mix/tasks/test.adoption.ex; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | Established in Phase 18 and reaffirmed for Relay on 2026-05-24. [VERIFIED: .planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | The planner can prove `ADPT-02` without waiting on unrelated repo debt. [VERIFIED: .planning/REQUIREMENTS.md; mix test.adoption local run 2026-05-24; mix test local run 2026-05-24] |
| Bounded handoffs as a possible second adoption branch [VERIFIED: current docs intentionally reject that shape] | Bounded handoffs taught as an extension of `identity -> start -> inspect -> resume` [VERIFIED: README.md; docs/phoenix_runtime_example.md; docs/bounded_handoffs.md; test/scoria/adoption_surface_test.exs] | Locked in Phase 42 and carried into Phase 43 closeout. [VERIFIED: .planning/phases/42-delegated-evidence-adoption-story/42-CONTEXT.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | The closeout ledger should prove one runtime-first story, not reconcile competing onboarding flows. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |

**Deprecated/outdated:**
- Treating optional knowledge setup as part of the default adoption proof is outdated for `ADPT-02`. [VERIFIED: .planning/REQUIREMENTS.md; README.md; docs/operator_verification.md]
- Treating richer handoff follow-up as automatically warranted after Phase 42 is outdated; Phase 42 already recorded “no remaining adopter-facing gap” absent a failed proof seam. [VERIFIED: .planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited from repo-local primary sources or local command output. [VERIFIED: this document’s source tags]

## Open Questions (RESOLVED)

1. **What exact filename should hold the canonical closeout ledger?** [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]
   - What we know: The user locked one canonical closeout artifact and explicitly left filename/naming to agent discretion. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]
   - Resolution: the generated Phase 43 plans now explicitly use `.planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CLOSEOUT.md` as the canonical synthesis artifact, which matches the pointer-first closeout shape recommended in this research and the mapped analogs in `43-PATTERNS.md`. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-01-PLAN.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-02-PLAN.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-PATTERNS.md]
   - Recommendation: Keep `43-CLOSEOUT.md` unless execution exposes a stronger repo-local reason to collapse the artifact into a verification report; no such reason is currently present. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | all proof commands [VERIFIED: mix.exs; lib/mix/tasks/test.adoption.ex] | ✓ [VERIFIED: `elixir --version` 2026-05-24] | 1.19.5 [VERIFIED: `elixir --version` 2026-05-24] | — |
| Mix | `mix test.adoption`, `mix test`, migrations [VERIFIED: lib/mix/tasks/test.adoption.ex; docs/operator_verification.md] | ✓ [VERIFIED: `mix --version` 2026-05-24] | 1.19.5 [VERIFIED: `mix --version` 2026-05-24] | — |
| PostgreSQL | runtime/migration/integration tests [VERIFIED: config/test.exs; test/scoria/runtime_integration_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] | ✓ [VERIFIED: `pg_isready` 2026-05-24] | accepting on `localhost:5432` [VERIFIED: `pg_isready` 2026-05-24; config/test.exs] | CI uses `pgvector/pg16` on port `55432` via env overrides. [VERIFIED: .github/workflows/ci.yml] |
| Knowledge-lane dependencies | optional knowledge proof only [VERIFIED: README.md; docs/operator_verification.md] | not required for Phase 43 canonical proof [VERIFIED: .planning/REQUIREMENTS.md; README.md; docs/operator_verification.md; test/test_helper.exs] | — | Keep them outside `ADPT-02`. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None for the canonical Phase 43 proof lane. [VERIFIED: mix test.adoption local run 2026-05-24; `pg_isready` 2026-05-24]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment checks on 2026-05-24]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox [VERIFIED: test/test_helper.exs; config/test.exs] |
| Config file | `test/test_helper.exs` and `config/test.exs` [VERIFIED: test/test_helper.exs; config/test.exs] |
| Quick run command | `mix test.adoption` [VERIFIED: lib/mix/tasks/test.adoption.ex; mix test.adoption local run 2026-05-24] |
| Full suite command | `mix test` [VERIFIED: .github/workflows/ci.yml; mix test local run 2026-05-24] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADPT-02 | Adoption lane stays canonical, knowledge-free, and docs/runtime aligned. [VERIFIED: .planning/REQUIREMENTS.md] | integration + source guard [VERIFIED: lib/mix/tasks/test.adoption.ex] | `mix test.adoption` [VERIFIED: lib/mix/tasks/test.adoption.ex] | ✅ [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs] |
| ADPT-02 | Public runtime facade and exact-run operator evidence stay covered. [VERIFIED: .planning/REQUIREMENTS.md] | integration [VERIFIED: test/scoria/runtime_integration_test.exs; test/scoria/runtime_test.exs] | `mix test test/scoria/runtime_integration_test.exs test/scoria/runtime_test.exs` [VERIFIED: lib/mix/tasks/test.adoption.ex] | ✅ [VERIFIED: test/scoria/runtime_integration_test.exs; test/scoria/runtime_test.exs] |
| ADPT-02 | README, bounded handoff guide, Phoenix example, and operator guide stay aligned with checked fragments. [VERIFIED: .planning/REQUIREMENTS.md] | source guard [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] | `mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs` [VERIFIED: lib/mix/tasks/test.adoption.ex] | ✅ [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] |
| ADPT-02 | Install and migration compatibility remain part of the proof lane. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | smoke + compatibility [VERIFIED: test/mix/tasks/scoria.install_test.exs; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] | `mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs` [VERIFIED: lib/mix/tasks/test.adoption.ex] | ✅ [VERIFIED: test/mix/tasks/scoria.install_test.exs; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test.adoption` [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; mix test.adoption local run 2026-05-24]
- **Per wave merge:** `mix test.adoption` plus any targeted full-suite failure repro commands being classified in the ledger. [VERIFIED: mix test.adoption local run 2026-05-24; mix test --failed --trace local run 2026-05-24]
- **Phase gate:** `mix test.adoption` green, plus the closeout ledger explicitly classifies current `mix test` failures against the locked escalation policy. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; mix test.adoption local run 2026-05-24; mix test local run 2026-05-24]

### Wave 0 Gaps
- None for executable proof infrastructure; the named task, CI lane, and required test files already exist. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; .github/workflows/ci.yml]
- The only missing artifact is the Phase 43 closeout ledger itself, which is documentation work rather than a test-framework gap. [VERIFIED: repo scan of `.planning/phases/43-canonical-adoption-proof-milestone-closeout/` on 2026-05-24]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; README.md] | Host-app auth remains outside this phase’s proof scope. [VERIFIED: README.md; .planning/PROJECT.md] |
| V3 Session Management | no [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; README.md] | `session_id` continuity is part of the runtime contract, but Phase 43 does not change session-management code. [VERIFIED: README.md; docs/phoenix_runtime_example.md] |
| V4 Access Control | yes [VERIFIED: README.md; docs/operator_verification.md; test/scoria/runtime_integration_test.exs] | Keep operator-evidence and approval-related regressions visible in the full-suite classification, and escalate only if they affect the public runtime/handoff proof claim. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; mix test local run 2026-05-24] |
| V5 Input Validation | yes [VERIFIED: test/scoria/runtime_test.exs; docs/bounded_handoffs.md] | Continue proving explicit bounded-handoff validation through the runtime test lane. [VERIFIED: test/scoria/runtime_test.exs; docs/bounded_handoffs.md] |
| V6 Cryptography | no [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] | No cryptographic seam is being added or changed in this phase. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs/source drift causes false adoption claims [VERIFIED: README.md; docs/bounded_handoffs.md; test/scoria/adoption_surface_test.exs] | Tampering | Keep docs and checked fragments under executable tests in the adoption lane. [VERIFIED: test/scoria/adoption_surface_test.exs; test/scoria/handoff_example_source_test.exs; test/scoria/phoenix_example_source_test.exs] |
| Unsafe projected context stops being covered by the canonical proof [VERIFIED: test/scoria/runtime_test.exs; docs/bounded_handoffs.md] | Information Disclosure | Keep `start_handoff_run` contract and unsafe-context rejection in the adoption subset. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/runtime_test.exs] |
| Unrelated full-suite failures are misreported as proof success or proof failure [VERIFIED: mix test.adoption local run 2026-05-24; mix test local run 2026-05-24] | Repudiation | The closeout ledger must classify each broader failure against the explicit escalation triggers. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md] |
| Approval/operator UI regressions create noise near the milestone boundary [VERIFIED: mix test local run 2026-05-24; mix test --failed --trace local run 2026-05-24] | Denial of Service | Record current Orchestrator LiveView approval-inbox failures as broader repo-health debt unless they are shown to affect the public bounded-handoff runtime lane. [VERIFIED: mix test local run 2026-05-24; lib/mix/tasks/test.adoption.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md` - locked decisions, escalation policy, artifact shape, and closeout bar. [VERIFIED: file read 2026-05-24]
- `.planning/ROADMAP.md` - Phase 43 goal, success criteria, and plan split. [VERIFIED: file read 2026-05-24]
- `.planning/REQUIREMENTS.md` - `ADPT-02` requirement text. [VERIFIED: file read 2026-05-24]
- `.planning/PROJECT.md` and `.planning/STATE.md` - milestone posture and accepted repo-health debt context. [VERIFIED: file read 2026-05-24]
- `lib/mix/tasks/test.adoption.ex` and `test/mix/tasks/test.adoption_test.exs` - canonical proof command and fixed file list. [VERIFIED: file read 2026-05-24]
- `test/scoria/adoption_surface_test.exs`, `test/scoria/handoff_example_source_test.exs`, `test/scoria/phoenix_example_source_test.exs`, `test/scoria/runtime_integration_test.exs`, `test/scoria/runtime_test.exs` - executable proof surfaces. [VERIFIED: file read 2026-05-24]
- `README.md`, `docs/operator_verification.md`, `docs/bounded_handoffs.md`, `docs/phoenix_runtime_example.md` - public support-truth surfaces. [VERIFIED: file read 2026-05-24]
- `.github/workflows/ci.yml`, `test/test_helper.exs`, `config/test.exs`, `mix.exs`, `mix.lock` - CI lanes, test infra, runtime versions, and dependency versions. [VERIFIED: file read 2026-05-24]
- Local commands on 2026-05-24: `elixir --version`, `mix --version`, `pg_isready`, `mix test.adoption`, `mix test`, and `mix test --failed --trace`. [VERIFIED: local command output 2026-05-24]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: source review 2026-05-24]

### Tertiary (LOW confidence)
- None. [VERIFIED: source review 2026-05-24]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase reuses an existing repo-local stack whose versions and commands were verified directly from the runtime, lockfile, and CI config. [VERIFIED: `elixir --version` 2026-05-24; `mix --version` 2026-05-24; mix.lock; .github/workflows/ci.yml]
- Architecture: HIGH - the proof lane, docs surfaces, and closeout policy are all locked in local planning artifacts and executable tests. [VERIFIED: .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md; lib/mix/tasks/test.adoption.ex; test/scoria/runtime_integration_test.exs]
- Pitfalls: HIGH - the main risks are observable in current repo behavior and user-locked policy, especially the separation between green adoption proof and red broader suite context. [VERIFIED: mix test.adoption local run 2026-05-24; mix test local run 2026-05-24; .planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CONTEXT.md]

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 for repo-local planning truth unless the adoption task file list, CI lanes, or closeout policy changes earlier. [VERIFIED: source set above]

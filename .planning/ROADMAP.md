# Roadmap: Scoria (v1.6 Flightpath)

## Milestones

- ✅ **v1.0 MVP** — Phases 1-4 (shipped 2026-05-10)
- ✅ **v1.1 Caldera** — Phase 5 (shipped 2026-05-11)
- ✅ **v1.2 Corpus** — Phase 6 (shipped 2026-05-11)
- ✅ **v1.3 Seismograph** — Phases 7-11 (shipped 2026-05-12)
- ✅ **v1.4 Keystone** — Phases 12-18 (shipped 2026-05-17)
- ✅ **v1.5 Switchyard** — Phases 19-22 (shipped 2026-05-18)
- 🚧 **v1.6 Flightpath** — Phases 23-26 (active)

## Current Milestone

**v1.6 Flightpath**

- Theme: Release gates, prompt lifecycle, and evaluation operations
- Goal: Establish a closed-loop LLM evaluation flywheel within the embedded Scoria architecture.
- Requirements: 12 defined requirements (REG, DATA, EVAL, GATE)
- Status: Active milestone planning

## Phases

- [ ] **Phase 23: Ecto-backed Prompt Registry & Lifecycle** - Single durable Ecto source of truth for structured, versioned prompts.
- [ ] **Phase 24: Trace-to-Dataset Curation via LiveView** - Promote real production traces into baseline datasets.
- [ ] **Phase 25: CI/CD Regression & Evaluation Framework** - Deterministic and cost-effective ExUnit evaluation runs with VCR cassettes.
- [ ] **Phase 26: Release Gates & Approvals** - Enforce workflow-backed policies for prompt activation and production rollout.

## Phase Details

### Phase 23: Ecto-backed Prompt Registry & Lifecycle
**Goal**: Developers and operators have a single durable Ecto source of truth for structured, versioned prompts independent of code deployment cycles.
**Depends on**: Phase 22 (from v1.5 Switchyard)
**Requirements**: REG-01, REG-02, REG-03
**Success Criteria** (what must be TRUE):
  1. Operator can save a structured prompt template and it persists as an immutable, versioned Ecto record.
  2. System rejects in-place edits to active prompts, forcing a new version instead.
  3. System calculates and displays token count estimations when saving a prompt.
**Plans**: 3 plans
Plans:
- [ ] 23-01-PLAN.md — Setup the Tiktoken dependency and create the token estimation utility for prompt templates.
- [ ] 23-02-PLAN.md — Create the Ecto schema and database migration for storing versioned, structured prompt templates.
- [ ] 23-03-PLAN.md — Implement the primary context interface for prompt registry operations, including token estimation injection and immutable lifecycle transitions.

### Phase 24: Trace-to-Dataset Curation via LiveView
**Goal**: Operators can seamlessly promote real production traces into durable, baseline datasets for future testing.
**Depends on**: Phase 23
**Requirements**: DATA-01, DATA-02
**Success Criteria** (what must be TRUE):
  1. Operator can view a production trace in the LiveView dashboard and click to save it as a dataset.
  2. The resulting dataset successfully retains the multi-turn context and expected output formats natively.
**Plans**: TBD
**UI hint**: yes

### Phase 25: CI/CD Regression & Evaluation Framework
**Goal**: Developers can run offline evaluation test suites in CI that are fast, deterministic, and cost-effective using standard ExUnit tools.
**Depends on**: Phase 24
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04
**Success Criteria** (what must be TRUE):
  1. Developer can run `mix test` and ExUnit will execute dataset assertions against a prompt version using VCR cassettes (no live network calls).
  2. System can perform LLM-as-a-judge qualitative evaluations using structured outputs when live evaluations are requested.
  3. Evaluation metrics (pass rate, latency) are saved as durable `EvalRun` records linked to the executed prompt version.
**Plans**: TBD

### Phase 26: Release Gates & Approvals
**Goal**: Organizations can enforce policies that new prompts cannot serve production traffic until evaluated and explicitly approved by an operator.
**Depends on**: Phase 25
**Requirements**: GATE-01, GATE-02, GATE-03
**Success Criteria** (what must be TRUE):
  1. A newly created prompt version remains in "draft" state and cannot be invoked by `Scoria.Runtime` for production traffic.
  2. Operator can view an embedded LiveView workbench comparing the draft prompt's EvalRun metrics against the active prompt.
  3. Operator can explicitly approve the draft using Scoria's workflow system, promoting it to active and gating future invocations.
**Plans**: TBD
**UI hint**: yes

## Coverage

| Phase | Requirements Covered |
|-------|----------------------|
| 23 | REG-01, REG-02, REG-03 |
| 24 | DATA-01, DATA-02 |
| 25 | EVAL-01, EVAL-02, EVAL-03, EVAL-04 |
| 26 | GATE-01, GATE-02, GATE-03 |

All 12 active v1.6 milestone requirements are mapped exactly once.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 23. Ecto-backed Prompt Registry & Lifecycle | 0/3 | Planned | - |
| 24. Trace-to-Dataset Curation via LiveView | 0/0 | Not started | - |
| 25. CI/CD Regression & Evaluation Framework | 0/0 | Not started | - |
| 26. Release Gates & Approvals | 0/0 | Not started | - |

## Forward Look

- `v1.7 Outrider` remains a future-bet milestone for deeper ecosystem/runtime expansion.
- Next step: `/gsd-execute-phase 23`

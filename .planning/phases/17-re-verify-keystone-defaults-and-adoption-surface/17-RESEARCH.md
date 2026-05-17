# Phase 17: Re-verify Keystone Defaults and Adoption Surface - Research

**Researched:** 2026-05-16 [VERIFIED: repo-local planning artifacts and current code/test seams were inspected directly]
**Domain:** Verification backfill and live-truth reconciliation for Keystone defaults/install ergonomics and adoption-surface docs/example flows [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: current repo artifacts, tests, docs, and prior verification precedents were inspected directly]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `POLY-01`, `POLY-02`, and `POLY-03` should be proven primarily by requirement-mapped targeted seam tests, not by a monolithic green suite alone. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-02:** Phase 14 targeted proof should reuse the existing seams that already express the real contract: prompt-policy normalization, runtime default precedence, runtime metadata projection, installer mutation/idempotence, installed `/scoria` route viability, explicit knowledge-lane contract, and migration-lane compatibility. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-03:** One `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` pass should still be recorded for Phase 14, but only as secondary regression-confidence evidence. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-04:** Phase 14 verification also requires one bounded manual walkthrough for the adopter-visible success lane: install, migrate, test, start one run, read it back, and confirm `/scoria` and `/scoria/workflows/:run_id` expose the same durable run. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-05:** The manual walkthrough must stay short, date-stamped, and observation-based. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-06:** `ADOP-01` through `ADOP-04` should be proven by a layered repo-native proof matrix: targeted runtime/install tests, bounded semantic content assertions against README/docs, and compile/doc-presence checks for the public modules. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-07:** The existing runtime integration suite remains the strongest behavioral anchor for the Phase 15 docs/example story. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-08:** Because `/scoria/workflows/:run_id` is part of the promised operator-evidence lane, Phase 15 canonical verification should include one bounded manual operator walkthrough in addition to automation. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-09:** Raw wording-grep checks are acceptable only as a narrow semantic backfill tactic and must not be mistaken for behavioral proof. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-10:** Executable docs or a sample Phoenix app are future hardening layers, not required for Phase 17 closeout. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-11:** Canonical verification must be restored inside the original phase directories as `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md` and `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md`. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-12:** Any Phase 17 aggregate artifact must be clearly derived from the canonical phase-local verification files rather than competing with them. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-13:** Verification files should follow the chronology-aware shape established in Phases 12, 13, and 7: explicit `verified_on`, explicit `verified_by_phase`, requirement coverage tied to real proof commands, and evidence-chain notes that preserve backfill history. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-15:** Reconciliation must cover all non-historical live truth surfaces that still imply the defaults/adoption work is pending or only summary-closed. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-16:** At minimum, reconcile `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, `MILESTONES.md`, and the relevant phase `VALIDATION.md` files. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-17:** Current public docs may be updated when they still speak in a speculative or pre-verification posture, but only to align present truth. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-18:** Historical milestone audits and dated summaries remain immutable forensic snapshots. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-19:** The verification shape should stay idiomatic to an embedded Phoenix/Ecto/Plug library: explicit install/config/router proof, test-first public seams, and minimal bespoke harnesses. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-20:** Avoid treating “green tests” or a dashboard screenshot as sufficient proof of adoption success. Canonical proof must connect the public runtime seam, durable truth, and operator evidence chain. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-21:** Avoid over-building a second sample product or generator-heavy fixture app just to prove a narrow backfill. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-22:** Future GSD defaults should shift this verification pattern left: targeted requirement proof, one secondary full-suite pass, bounded manual acceptance only where the promise is inherently human-visible, canonical phase-local verification files, and broad current-truth reconciliation. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- **D-23:** User interruption should be reserved for materially product-shaping exceptions, not artifact-placement or proof-matrix conventions. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]

### Claude's Discretion
- Exact grouping of the Phase 14 and Phase 15 proof commands, provided each requirement still maps to a primary seam-specific lane. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- Exact wording of bounded manual walkthrough scripts, provided they record explicit expected observations and durable identifiers. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- Exact aggregate summary filename and structure for Phase 17, provided it stays clearly derived from the phase-local verification artifacts. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Adding doctest-backed executable docs or long-lived fixture apps as Phase 18+ hardening layers. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- Introducing machine-readable verification manifests before a concrete CI or agent-enforcement need exists. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
- Rewriting historical milestone audits or dated summaries to erase that the verification gaps existed. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `POLY-01` | Provider, model, and prompt-policy defaults can be configured through a documented application-facing Scoria surface. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse prompt-policy normalization, runtime defaults, and runtime metadata projection seams from the existing Phase 14 validation matrix to prove the public defaults surface still behaves as documented. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; test/scoria/prompt_policy_test.exs; test/scoria/runtime/defaults_test.exs; test/scoria/runtime_test.exs] |
| `POLY-02` | Runtime policy defaults compose cleanly with tenant or actor identity so host apps have a predictable place to attach governance. [VERIFIED: .planning/REQUIREMENTS.md] | Treat identity-aware overlay precedence and runtime metadata survival as the canonical proof seams, with public runtime paths as the truth anchor. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; test/scoria/runtime/defaults_test.exs; test/scoria/runtime_test.exs; test/scoria/runtime_integration_test.exs] |
| `POLY-03` | The default configuration path stays installable without forcing optional subsystems beyond the existing documented baseline. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse installer mutation/idempotence, installed `/scoria` route viability, migration-lane compatibility, and explicit knowledge-lane command seams, then add one bounded manual install-to-run walkthrough. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs; test/mix/tasks/scoria.test_knowledge_test.exs; docs/operator_verification.md] |
| `ADOP-01` | `README.md` and install guidance reflect the actual shipped milestone state and public runtime entrypoints. [VERIFIED: .planning/REQUIREMENTS.md] | Use targeted README and installer-content assertions plus compile/doc-presence checks, but treat runtime integration tests as the behavioral anchor that docs must align to. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; README.md; lib/mix/tasks/scoria.install.ex; test/scoria/runtime_integration_test.exs] |
| `ADOP-02` | Scoria exposes at least one end-to-end documented Phoenix integration flow showing how request/session context maps into Scoria identity and runtime APIs. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `test/scoria/runtime_integration_test.exs` as the canonical proof seam for identity normalization, stored `run_id`, same-session continuity, and operator evidence route alignment. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; test/scoria/runtime_integration_test.exs; docs/phoenix_runtime_example.md] |
| `ADOP-03` | Default verification guidance tells a Phoenix team how to prove the core lane is working without unexpectedly requiring the knowledge lane. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse installer/route/migration compatibility tests and semantic assertions against `README.md` and `docs/operator_verification.md`, then add one bounded manual operator walkthrough because `/scoria/workflows/:run_id` is part of the public proof contract. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; docs/operator_verification.md; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
| `ADOP-04` | The top-level public module surface is no longer placeholder-only and instead reflects the library's intended entrypoints. [VERIFIED: .planning/REQUIREMENTS.md] | Use compile-backed moduledoc checks and semantic assertions against `lib/scoria.ex`, `lib/scoria/runtime.ex`, `lib/scoria/identity.ex`, and `lib/scoria/prompt_policy.ex`, anchored by the already-shipped public facade behavior. [VERIFIED: .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/identity.ex; lib/scoria/prompt_policy.ex] |
</phase_requirements>

## Summary

Phase 17 is another verification-and-reconciliation phase, not a feature-design phase. The defaults/install ergonomics work from Phase 14 and the docs/example-flow work from Phase 15 already shipped with strong validation matrices and code/test seams; the missing layer is the canonical verification chain in the original phase directories plus milestone-wide live-truth reconciliation. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]

The main planning implication is to avoid rediscovery. Phase 14 already names the exact defaults/install seams worth rerunning, and Phase 15 already names the strongest docs/runtime proof lanes. The plan should promote those validation inventories into canonical `14-VERIFICATION.md` and `15-VERIFICATION.md` artifacts, add the two bounded manual walkthrough closures required by the phase context, and then reconcile every non-historical truth surface that still reports `POLY-*` and `ADOP-*` as pending or summary-only. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/PROJECT.md; .planning/STATE.md; .planning/MILESTONES.md]

The biggest risk is false closeout by summary. If Phase 17 only updates the roadmap or adds a Phase 17 summary, the repo will still lack canonical verification artifacts for the original shipped phases, and milestone truth will remain split between green validation rows, summary prose, and pending requirement status. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md; .planning/ROADMAP.md; .planning/REQUIREMENTS.md]

**Primary recommendation:** keep the roadmap’s existing three-way split: `17-01` backfills Phase 14 verification, `17-02` backfills Phase 15 verification, and `17-03` reconciles live-truth surfaces to those canonical artifacts. That matches the repo’s previous re-verification pattern and preserves a clean provenance chain. [VERIFIED: .planning/ROADMAP.md; .planning/phases/16-re-verify-keystone-identity-and-runtime-api/16-01-PLAN.md; .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Defaults/install contract proof | API / Backend | Developer tooling | The canonical seams are prompt-policy normalization, runtime defaults, installer behavior, and migration-lane compatibility. [VERIFIED: test/scoria/prompt_policy_test.exs; test/scoria/runtime/defaults_test.exs; test/mix/tasks/scoria.install_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
| Public docs/example-flow proof | Static / Docs | API / Backend | The docs are the edited artifact, but the runtime integration suite is the behavior source of truth they must mirror. [VERIFIED: README.md; docs/phoenix_runtime_example.md; test/scoria/runtime_integration_test.exs] |
| Operator-evidence walkthroughs | Frontend Server (SSR) | API / Backend | `/scoria` and `/scoria/workflows/:run_id` are human-visible evidence surfaces backed by durable runtime truth. [VERIFIED: docs/operator_verification.md; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/runtime_integration_test.exs] |
| Canonical verification artifact placement | Static / Docs | — | The required deliverables are phase-local markdown artifacts in the original phase directories. [VERIFIED: .planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-CONTEXT.md] |
| Milestone-state reconciliation | Static / Docs | — | The drift now lives in roadmap, requirements, project, milestones, state, and validation records rather than in unimplemented runtime behavior. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/PROJECT.md; .planning/MILESTONES.md; .planning/STATE.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ExUnit` | bundled with repo toolchain [VERIFIED: prior phase validation docs and test files] | Primary automated proof runner for defaults, installer, runtime, and route seams. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md] | Every required proof lane already exists as an ExUnit or compile/content assertion. [VERIFIED: referenced validation docs and test files] |
| `Phoenix` + LiveView | repo stack [VERIFIED: mix.exs; router and tests] | Installed `/scoria` evidence route and workflow operator proof. [VERIFIED: lib/scoria_web/router.ex; test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/runtime_integration_test.exs] | The manual acceptance seams are explicitly about the installed route and workflow evidence UI, not a second sample app. [VERIFIED: docs/operator_verification.md; phase context] |
| Phase-local verification markdown | repo-local planning convention [VERIFIED: .planning/phases/07-seismograph/07-VERIFICATION.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md] | Canonical closeout evidence chain. [VERIFIED: prior phase artifacts] | The audit gap exists specifically because these files are missing for Phases 14 and 15. [VERIFIED: phase context and current phase directories] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Scoria` public facade | repo-local [VERIFIED: lib/scoria.ex] | Behavioral truth anchor for docs and operator proof. [VERIFIED: lib/scoria.ex; test/scoria/runtime_integration_test.exs] | Use whenever a docs or manual proof lane must connect public adoption language to real runtime behavior. |
| `Scoria.PromptPolicy` and runtime defaults modules | repo-local [VERIFIED: lib/scoria/prompt_policy.ex; test files] | Canonical defaults noun and precedence logic. [VERIFIED: lib/scoria/prompt_policy.ex; test/scoria/prompt_policy_test.exs; test/scoria/runtime/defaults_test.exs] | Use for `POLY-01` and `POLY-02` requirement proof mapping. |
| Installer mix tasks | repo-local [VERIFIED: lib/mix/tasks/scoria.install.ex; tests] | Install-path truth and optional knowledge-lane messaging. [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/scoria.test_knowledge_test.exs] | Use for `POLY-03` and `ADOP-03` proof mapping. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical phase-local verification files | A Phase 17-only summary or verification note | Leaves the original shipped phases without their required evidence chain and repeats the same closure defect Phase 17 exists to fix. [VERIFIED: phase context; current phase directories] |
| Targeted seam-specific proof plus one full-suite closeout pass | Full `mix test` as the only evidence | A green suite cannot directly prove requirement-to-seam mapping or docs alignment, and it misses the required manual operator evidence lane. [VERIFIED: phase context; existing validation docs] |
| Bounded semantic content assertions | Prose-only summaries that say docs align | Summary prose is too weak for backfill verification because Phase 17 must preserve exact present-truth evidence. [VERIFIED: phase context; existing validation docs] |

## Recommended Plan Breakdown

### `17-01: Backfill Phase 14 Verification`
**Goal:** Create `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md` and update `14-VALIDATION.md` to terminal truth using the existing Phase 14 proof matrix plus one bounded manual install-to-run walkthrough. [VERIFIED: .planning/ROADMAP.md; .planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md]  
**Likely files to touch:** `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VERIFICATION.md`, `.planning/phases/14-policy-defaults-and-install-ergonomics/14-VALIDATION.md`, possibly one small Phase 17 summary or note if the planner wants a breadcrumb. [VERIFIED: phase context]  
**Proof points:** requirement-to-command coverage for `POLY-01` through `POLY-03`, explicit `verified_on` and `verified_by_phase`, one recorded full-suite confidence pass, and one short manual operator note tied to an install/run/readback flow. [VERIFIED: phase context; 14 validation matrix; prior verification precedent]  
**Risk to guard:** treating install-route smoke or full-suite green as sufficient without recording the bounded user-visible walkthrough. [VERIFIED: phase context; docs/operator_verification.md]

### `17-02: Backfill Phase 15 Verification`
**Goal:** Create `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md` and update `15-VALIDATION.md` to terminal truth using the shipped runtime/docs proof lanes plus one bounded operator walkthrough. [VERIFIED: .planning/ROADMAP.md; .planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md]  
**Likely files to touch:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VERIFICATION.md`, `.planning/phases/15-adoption-surface-docs-and-example-flow/15-VALIDATION.md`, and only current-truth wording in README/docs if needed to reflect the verification record accurately. [VERIFIED: phase context; README.md; docs/operator_verification.md; docs/phoenix_runtime_example.md]  
**Proof points:** requirement-to-command coverage for `ADOP-01` through `ADOP-04`, semantic assertions against README/docs that match the runtime integration seam, compile-backed public module checks, and one manual `/scoria/workflows/:run_id` observation note. [VERIFIED: phase context; 15 validation matrix]  
**Risk to guard:** mistaking `rg` assertions alone for behavioral proof or reopening docs design work that belongs to the original feature phase rather than the backfill. [VERIFIED: phase context]

### `17-03: Reconcile Defaults and Adoption Traceability`
**Goal:** Update every non-historical live truth surface so Phase 14 and 15 no longer appear pending or summary-only once their canonical verification artifacts exist. [VERIFIED: .planning/ROADMAP.md; phase context]  
**Likely files to touch:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and any still-stale current docs or validation files that speak in a pre-verification posture. [VERIFIED: phase context; inspected planning files]  
**Proof points:** all `POLY-*` and `ADOP-*` traceability rows move to verified/completed status, current milestone summaries mention the backfill closure, and no active truth surface contradicts the new canonical `14-VERIFICATION.md` and `15-VERIFICATION.md` artifacts. [VERIFIED: phase context; inspected planning files]  
**Risk to guard:** touching historical milestone audit snapshots or drifting into Phase 18 executable-guard work. [VERIFIED: phase context]

## Architecture Patterns

### Pattern 1: Backfill verification into the original phase directory
**What:** Write the missing verification artifact inside the original phase directory with explicit backfill chronology. [VERIFIED: .planning/phases/07-seismograph/07-VERIFICATION.md; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md]  
**When to use:** Any re-verification phase closing an evidence-chain gap after feature execution already shipped. [VERIFIED: Phase 16 and 17 contexts]  
**Example:**
```markdown
---
phase: 14-policy-defaults-and-install-ergonomics
status: passed
verified_on: 2026-05-16
verified_by_phase: 17-re-verify-keystone-defaults-and-adoption-surface
---
```

### Pattern 2: Requirement-to-command verification matrix
**What:** Map each requirement directly to its proof seam, command, and evidence notes rather than relying on phase-summary prose. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-VERIFICATION.md; phase context]  
**When to use:** Especially for defaults/docs phases where it would be easy to collapse everything into “tests passed and docs look right.” [VERIFIED: phase context]  
**Example:**
```markdown
| Requirement | Proof seam | Evidence |
|-------------|------------|----------|
| `ADOP-03` | installer core-lane split plus operator route evidence | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test ...` + recorded `/scoria/workflows/:run_id` walkthrough note |
```

### Pattern 3: Terminal-truth validation cleanup
**What:** Convert validation files from planned/executed matrices into terminal-truth references once canonical verification is written. [VERIFIED: prior re-verification precedent; inspected validation docs]  
**When to use:** After rerunning the targeted proof lanes and manual acceptance notes, so current validation records stop implying future work. [VERIFIED: phase context]

### Anti-Patterns to Avoid
- **Summary-only closure:** Do not let Phase 17 close with only Phase 17 notes or state-file edits. [VERIFIED: phase context]
- **Prose-only docs proof:** Do not treat README or docs wording alone as sufficient for `ADOP-*` requirement closure. [VERIFIED: phase context; 15 validation matrix]
- **Historical audit rewrites:** Do not mutate dated milestone audits or older summaries to hide the original gap. [VERIFIED: phase context]
- **Fixture-app sprawl:** Do not build a second sample Phoenix app or generator-heavy harness just to backfill this narrow proof chain. [VERIFIED: phase context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Defaults verification structure | A new one-off Phase 17 evidence format | Existing chronology-aware verification shape from Phases 7, 12, and 13 | The repo already has a working canonical backfill pattern. [VERIFIED: prior verification files] |
| New proof harnesses for Phase 14 | Ad hoc scripts outside the existing test seams | The exact test commands already named in `14-VALIDATION.md` plus one bounded manual walkthrough | The validation file already identifies the right seams. [VERIFIED: 14 validation matrix] |
| New proof harnesses for Phase 15 | A sample app or executable docs project | The runtime integration suite, docs assertions, compile/doc checks, and one bounded operator walkthrough | The shipped repo already proves the public semantics directly. [VERIFIED: 15 validation matrix; test/scoria/runtime_integration_test.exs] |
| Reconciliation by implication | “Everyone knows these are done now” edits | Explicit updates to each live truth surface listed in the context | This phase exists because implicit completion left contradictory artifacts behind. [VERIFIED: phase context; planning files] |

**Key insight:** The hard part is not designing new defaults or docs behavior. The hard part is restoring a single canonical evidence chain for what Phase 14 and Phase 15 already shipped, then making every active truth surface point to that chain without mutating forensic history. [VERIFIED: phase context; current planning files]

## Common Pitfalls

### Pitfall 1: Treating green validation rows as equivalent to canonical verification
**What goes wrong:** The repo still lacks `14-VERIFICATION.md` or `15-VERIFICATION.md`, so requirement closure remains orphaned even though the validation files look green. [VERIFIED: current phase directories and validation files]  
**How to avoid:** Write the canonical verification file first-class in the original phase directory and let validation become a terminal-truth companion, not the sole artifact. [VERIFIED: phase context]

### Pitfall 2: Reconciling only `ROADMAP.md`
**What goes wrong:** One surface says the work is verified while `REQUIREMENTS.md`, `PROJECT.md`, `STATE.md`, `MILESTONES.md`, or the validation files still imply pending/default-only closure. [VERIFIED: inspected planning files]  
**How to avoid:** Build a fixed reconciliation checklist from `D-15` through `D-18` and clear every current-truth surface systematically. [VERIFIED: phase context]

### Pitfall 3: Letting manual operator proof stay vague
**What goes wrong:** The backfill closes without explicit user-visible evidence that install/run/readback and `/scoria/workflows/:run_id` still line up. [VERIFIED: phase context]  
**How to avoid:** Convert the manual lane into a short numbered script with the durable identifiers and expected observations already named. [VERIFIED: phase context; docs/operator_verification.md]

### Pitfall 4: Reopening product-shape decisions from Phases 14 and 15
**What goes wrong:** The verification phase drifts into redesigning docs, defaults, or adoption structure instead of proving what shipped. [VERIFIED: phase context]  
**How to avoid:** Keep changes limited to verification artifacts, terminal-truth validation updates, and current-truth reconciliation unless a present-tense doc statement is factually wrong. [VERIFIED: phase context]

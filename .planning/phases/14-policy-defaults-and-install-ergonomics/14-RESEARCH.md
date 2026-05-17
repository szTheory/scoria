# Phase 14: Policy Defaults and Install Ergonomics - Research

**Researched:** 2026-05-14 [VERIFIED: repo]  
**Domain:** Phoenix-facing runtime defaults, prompt-policy normalization, and boring install lanes [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: repo]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Application-facing policy configuration surface
- **D-01:** `config :scoria, Scoria.Runtime, defaults: ...` is the obvious happy-path configuration surface.
- **D-02:** The happy path stays plain: maps, keywords, and structs, not a macro DSL, hosted control plane, or hidden config process.
- **D-03:** Host apps may optionally attach identity-aware policy composition through one explicit resolver module.
- **D-04:** Per-run runtime options remain the final explicit override layer.

### Identity-aware default composition
- **D-05:** Effective defaults resolve exactly once at the public runtime entrypoint before workflow, MCP, telemetry, or audit execution.
- **D-06:** Root identity remains separate from runtime policy/config and is immutable once a run starts.
- **D-07:** Precedence order is built-in defaults < app defaults < tenant defaults < actor defaults < per-run overrides.
- **D-08:** Governance-sensitive fields must be validated explicitly rather than widened accidentally through merge order.

### Prompt-policy shape
- **D-09:** Introduce one canonical prompt-policy noun as a small explicit struct.
- **D-10:** Boundary sugar may accept atoms/strings/maps, but runtime code must normalize immediately into the canonical struct.
- **D-11:** The prompt-policy struct must carry stable identity and resolved governance data for audit and telemetry traceability.
- **D-12:** Advanced resolver behavior may exist, but it must still resolve into the canonical struct before execution.

### Install and verification lane
- **D-13:** `mix scoria.install` should wire the boring Phoenix lane by default.
- **D-14:** The default install lane must not require pgvector or the optional knowledge subsystem.
- **D-15:** Core verification success means normal Postgres, `mix ecto.migrate`, `mix test`, and a working `/scoria` route.
- **D-16:** Knowledge/retrieval verification remains a separate explicit lane.

### DX posture and decision policy
- **D-17:** The product should preserve a least-surprise Phoenix-library posture.
- **D-18:** Effective provider/model/prompt-policy choices must project into runtime metadata, telemetry, and audit evidence.
- **D-19:** Low-impact defaults should be shifted left inside planning and implementation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLY-01 | Provider, model, and prompt-policy defaults can be configured through a documented application-facing Scoria surface. | Use `Application.get_env/3`-backed runtime defaults plus a canonical `Scoria.PromptPolicy` struct resolved through `Scoria.Runtime.Params` and a dedicated defaults helper [VERIFIED: lib/scoria/runtime.ex; lib/scoria/runtime/params.ex; lib/scoria.ex] |
| POLY-02 | Runtime policy defaults compose cleanly with tenant or actor identity so host apps have a predictable place to attach governance. | Resolve overlays once at the public runtime boundary using canonical `Scoria.Identity`, then project the chosen provider/model/policy fields through workflow, MCP, telemetry, and audit seams [VERIFIED: lib/scoria/identity.ex; lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex; lib/scoria/sre/telemetry.ex] |
| POLY-03 | The default configuration path stays installable without forcing optional subsystems beyond the existing documented baseline. | Harden `mix scoria.install`, preserve the core-vs-knowledge split already expressed in dedicated Mix tasks and migration tests, and align verification guidance to the existing baseline [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/mix/tasks/scoria.install_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
</phase_requirements>

## Summary

Phase 14 should productize runtime defaults, not invent a new runtime subsystem. The repo already has the correct structural seams: `Scoria` is the happy-path public API, `Scoria.Runtime` owns public lifecycle flow, `Scoria.Runtime.Params` normalizes public input, `Scoria.Identity` canonicalizes host-app identity, and downstream workflow/MCP/SRE code already knows how to project provider/model/policy-like fields once they exist in context. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; lib/scoria/runtime/params.ex; lib/scoria/identity.ex; lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex]

The cleanest implementation is to add one dedicated defaults-composition seam, likely `Scoria.Runtime.Defaults`, plus one canonical prompt-policy struct, likely `Scoria.PromptPolicy`. `Params.start/2` should normalize identity, collect app config, apply resolver overlays by canonical identity, validate governance-sensitive fields, normalize prompt policy, and stamp the resolved snapshot into run metadata before `Workflows.create_run/1` executes. That satisfies the "resolve once, persist once, project many times" rule already implied by the context and by current runtime design. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md; lib/scoria/runtime/params.ex; lib/scoria/runtime.ex]

The installer side is also a hardening problem, not a greenfield one. The repo already distinguishes a core lane from an optional knowledge lane with dedicated tasks and tests; Phase 14 should preserve that split, make the default lane more explicit and reliable, and ensure the user-facing verification story matches the current shipped baseline. [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs]

**Primary recommendation:** plan the phase around three vertical slices:
1. canonical public defaults and prompt-policy types,
2. single-pass identity-aware resolution plus metadata projection,
3. installer and verification lane hardening for the boring Phoenix path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| App-config defaults lookup | API / Backend | — | Public runtime config belongs at the library boundary and already fits the repo’s `Application.get_env/3` usage pattern [VERIFIED: lib/scoria/workflows/runtime.ex] |
| Identity-aware overlay resolution | API / Backend | Host-app module callback | Canonical identity is already normalized in-library, while host apps can supply tenant/actor-specific overlays through one explicit resolver contract [VERIFIED: lib/scoria/identity.ex; .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md] |
| Prompt-policy normalization | API / Backend | — | The same repo pattern used by `Scoria.Identity` should keep edge sugar out of durable runtime code [VERIFIED: lib/scoria/identity.ex] |
| Governance-sensitive override validation | API / Backend | — | Validation must happen before runtime execution fans out into workflow, MCP, and telemetry seams [VERIFIED: lib/scoria/runtime.ex; lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex] |
| Projection into workflow/MCP/SRE metadata | API / Backend | Operator UI consumers | Downstream seams already consume `provider`, `model`, `policy_key`, `actor_id`, and `tenant_id` from canonical context [VERIFIED: lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex; lib/scoria/sre/telemetry.ex] |
| Core-lane install scaffolding | Developer tooling | — | `mix scoria.install` is already the intended entrypoint for onboarding and should remain boring and additive [VERIFIED: lib/mix/tasks/scoria.install.ex] |
| Knowledge-lane bootstrap and verification | Developer tooling | — | Optional knowledge work already lives behind explicit tasks and must stay separate from the default lane [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | repo current | Installation and runtime defaults should feel like a normal Phoenix library integration [VERIFIED: mix.lock; README.md] | The milestone’s product goal is Phoenix-first, embedded ergonomics rather than managed-platform indirection [VERIFIED: .planning/PROJECT.md] |
| `ecto` / `ecto_sql` | repo current | Durable run metadata remains the source of truth for resolved policy and runtime evidence [VERIFIED: mix.lock; lib/scoria/workflows.ex] | Current runtime and SRE code already project decisions from durable run and reservation records [VERIFIED: lib/scoria/workflows/runtime.ex; lib/scoria/sre/budget_engine.ex] |
| `repo-local Scoria.Identity` | repo-local | Canonical actor/tenant/session normalization | Phase 14 should copy this normalization posture for prompt policy rather than invent a new config shape [VERIFIED: lib/scoria/identity.ex] |
| `repo-local Scoria.Runtime.Params` | repo-local | Public input normalization seam | This is already the single best place to attach defaults composition before a run is created [VERIFIED: lib/scoria/runtime/params.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `repo-local Scoria.Workflows.Runtime` | repo-local | Downstream runtime execution context | Consume pre-resolved policy/runtime metadata without re-reading app config [VERIFIED: lib/scoria/workflows/runtime.ex] |
| `repo-local Scoria.MCP.Executor` | repo-local | Policy-sensitive tool invocation | Consume canonical `policy_key`, `provider`, and identity context after boundary resolution [VERIFIED: lib/scoria/mcp/executor.ex] |
| `repo-local Scoria.SRE.Telemetry` | repo-local | Operator-visible telemetry projection | Emit the chosen runtime defaults as labels/refs only after canonical resolution [VERIFIED: lib/scoria/sre/telemetry.ex] |
| `ExUnit` | bundled | Installer, runtime, and migration-lane verification | Existing tests already provide direct seams for core-vs-knowledge verification and install mutation coverage [VERIFIED: test/mix/tasks/scoria.install_test.exs; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain app config plus explicit resolver | Macro DSL or DB-managed config | More magical, more stateful, and violates the least-surprise Phoenix posture [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md] |
| One canonical prompt-policy struct | Free-form maps throughout runtime code | Faster short term, but repeats the exact drift problem that `Scoria.Identity` already solved for identity [VERIFIED: lib/scoria/identity.ex] |
| Resolve once in `Params.start/2` | Merge piecemeal in runtime, workflow, MCP, and telemetry seams | Creates drift, double resolution, and policy widening risk [VERIFIED: lib/scoria/runtime/params.ex; lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex] |
| Core install lane separated from knowledge lane | Default install that silently assumes pgvector or knowledge tables | Violates the milestone requirement that the boring path works without optional subsystems [VERIFIED: test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

## Architecture Patterns

### Pattern 1: Boundary normalization before durable writes
**What:** Normalize edge-shaped identity and policy input into canonical runtime nouns before creating a run.  
**When to use:** `Scoria.start_run/2` and any future public runtime entrypoint that creates durable work.  
**Example source:** `Scoria.Identity.normalize/1` and `Scoria.Runtime.Params.start/2` [VERIFIED: lib/scoria/identity.ex; lib/scoria/runtime/params.ex].

### Pattern 2: Resolve once, then project into downstream seams
**What:** Compose provider/model/policy defaults one time at the runtime boundary, persist the result in run metadata, and pass the same fields into workflow, MCP, and SRE context.  
**When to use:** Any policy-sensitive execution or telemetry path.  
**Example source:** workflow/MCP/SRE already read pre-shaped context maps for `provider`, `model`, `policy_key`, and identity [VERIFIED: lib/scoria/workflows/runtime.ex; lib/scoria/mcp/executor.ex; lib/scoria/sre/telemetry.ex].

### Pattern 3: Explicit core lane versus optional knowledge lane
**What:** Keep the default onboarding and verification story independent from knowledge-only dependencies and tasks.  
**When to use:** Installer output, README guidance, migration commands, and verification commands.  
**Example source:** separate pgvector bootstrap task, separate knowledge test task, and migration lane compatibility test [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs].

### Pattern 4: Small public nouns over bags of attrs
**What:** Use explicit structs and narrow helper modules for public contracts rather than letting raw maps become durable API shape.  
**When to use:** Prompt policy, resolved defaults snapshots, and any future app-facing runtime config DTO.  
**Example source:** `Scoria.Identity`, `Scoria.Runtime.RunSummary`, and `Scoria.Runtime.RunDetail` [VERIFIED: lib/scoria/identity.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Identity-aware policy composition | Ad hoc merges in every subsystem | One boundary helper under `Scoria.Runtime` | Prevents precedence drift and duplicated validation [VERIFIED: lib/scoria/runtime/params.ex] |
| Prompt-policy contract | Untyped string/map conventions everywhere | Canonical `%Scoria.PromptPolicy{}` | Mirrors the repo’s existing identity normalization strategy [VERIFIED: lib/scoria/identity.ex] |
| Installer verification | One giant “full stack” install lane | Separate core and knowledge verification lanes | The repo already encodes this split and the milestone explicitly depends on it [VERIFIED: test/scoria/bootstrap/migration_lane_compatibility_test.exs] |
| Telemetry/audit lookup of app config | Late config reads inside telemetry or tool execution | Pre-resolved metadata on run/context | Downstream seams should remain consumers, not policy composers [VERIFIED: lib/scoria/mcp/executor.ex; lib/scoria/sre/telemetry.ex] |

## Common Pitfalls

### Pitfall 1: Re-resolving defaults after the run is created
**What goes wrong:** Workflow, MCP, and telemetry disagree about which provider/model/policy was actually chosen.  
**How to avoid:** Resolve once at the public runtime boundary and stamp the chosen snapshot into run metadata before execution. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/runtime/params.ex]

### Pitfall 2: Treating identity and policy as the same thing
**What goes wrong:** Tenant or actor overlays mutate root identity or make durable evidence ambiguous.  
**How to avoid:** Keep identity canonical and immutable, and treat policy overlays as separate resolved config attached to that identity. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md; lib/scoria/identity.ex]

### Pitfall 3: Letting per-run overrides widen governance accidentally
**What goes wrong:** A caller bypasses tenant or actor constraints by sending a looser provider/model/policy override.  
**How to avoid:** Validate sensitive fields explicitly and reject or narrow widening changes before the run executes. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md]

### Pitfall 4: Making the installer prove optional subsystems by default
**What goes wrong:** A normal Phoenix app has to solve pgvector or knowledge-table setup just to validate the basic lane.  
**How to avoid:** Keep `mix scoria.install`, core migrations, and default `mix test` on the boring lane; teach knowledge work as an explicit follow-up lane. [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/scoria.test.knowledge.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs]

### Pitfall 5: Copying the current knowledge task naming mismatch
**What goes wrong:** New install or verification guidance encodes the wrong Mix task name and creates confusion.  
**How to avoid:** Treat the mismatch between `Mix.Tasks.Test.Knowledge` and `scoria.test.knowledge` as an existing repo quirk to fix or isolate, not a pattern to spread. [VERIFIED: lib/mix/tasks/scoria.test.knowledge.ex]

## Key Insight

The hard part of Phase 14 is contract discipline, not raw implementation volume. The repo already contains most of the downstream plumbing needed for operator-visible policy decisions and separate verification lanes. The phase should therefore spend its effort on defining one canonical public config story, one canonical prompt-policy noun, one exact resolution seam, and one unambiguous boring install path. [VERIFIED: .planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md; lib/scoria/runtime/params.ex; lib/mix/tasks/scoria.install.ex]

# Phase 10: Wire Production SRE Telemetry and Fix Default Verification Bootstrap - Research

**Researched:** 2026-05-12 [VERIFIED: system date]  
**Domain:** Phoenix/Ecto SRE telemetry wiring and repo bootstrap boundaries for Scoria [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/telemetry.ex; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]  
**Confidence:** MEDIUM [VERIFIED: author assessment]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Telemetry producer coverage
- **D-01:** Phase 10 should wire and prove live SRE telemetry at the real execution seams: `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor`.
- **D-02:** Phase 10 should also emit separate post-commit incident lifecycle telemetry from the durable incident seam so Scoria can prove the path from bad runtime event to durable operator evidence.
- **D-03:** Delivery and relay outcomes remain DB-first truth in this phase. They may expose coarse health telemetry later, but Phase 10 should not treat transport outcomes as first-class SLI coverage or pager-grade SRE signals.
- **D-04:** Runtime and incident telemetry must be separate namespaces or categories with clear semantics so one semantic failure is not counted twice as SLO burn.

### Telemetry identity contract
- **D-05:** Scoria should use canonical operational identity as the primary live telemetry contract, not incident lifecycle identity.
- **D-06:** Every live SRE telemetry event should carry one shared low-cardinality operational identity shape built from stable dimensions such as `tenant_id`, `subject_kind`, `policy_key`, `reason_code`, and `window_bucket`.
- **D-07:** Introduce a deterministic shared `identity_key` derived from those operational dimensions. This becomes the grouping handle across runtime, incidenting, and external consumers.
- **D-08:** `incident_key` is optional at raw runtime emission time and becomes a derived projection of the same shared identity when an alert or incident is materialized.
- **D-09:** `trace_id` and `run_id` remain correlation refs, not grouping labels.
- **D-10:** Parapet-facing helpers should group on canonical identity fields and `identity_key`, not require every raw event to pretend it already belongs to an incident.

### Verification bootstrap and repo ergonomics
- **D-11:** The boring default for Scoria core and SRE work should be ordinary `mix test` with no manual Docker/bootstrap ritual and no test-local schema patching.
- **D-12:** The knowledge/pgvector path remains first-class but explicit. It should live behind a blessed optional bootstrap/test path rather than being an unconditional prerequisite for unrelated SRE verification.
- **D-13:** The split must happen at the migration/bootstrap boundary, not only in documentation or test tags.
- **D-14:** Remove the architectural need for `ensure_*` table helpers in focused tests; those helpers are evidence of a broken bootstrap boundary, not a long-term pattern.
- **D-15:** CI should exercise at least two explicit lanes:
  - core/SRE on the boring default path
  - knowledge/full on the pgvector-aware path

### DX and GSD preference posture
- **D-16:** Planning for this phase should optimize for least surprise, batteries-included defaults, and narrow explicit escape hatches instead of host-app ceremony.
- **D-17:** Push low-impact defaults left inside Scoria and future GSD flows wherever possible; reserve user interruptions for decisions that are genuinely product-defining, architecture-shaping, or otherwise materially consequential.
- **D-18:** User-facing and operator-facing behavior should keep reading like a calm lab notebook: durable truth first, explicit evidence second, telemetry as a public seam rather than magical hidden glue.

### the agent's Discretion
- Exact module/helper extraction for shared SRE identity building, provided runtime, incident, and adapter layers all use one canonical implementation.
- Exact telemetry event names and namespace splits, provided execution SLI events remain distinct from incident lifecycle events.
- Exact command/alias naming for the explicit knowledge/pgvector test path, provided ordinary `mix test` stays the boring default for non-knowledge work.
- Exact CI workflow naming and matrix layout, provided both the boring core path and the explicit knowledge path are exercised continuously.

### Deferred Ideas (OUT OF SCOPE)
- Making delivery or relay transport outcomes first-class pager/SLO sources by default.
- Forcing every raw runtime telemetry event to carry incident lifecycle identity.
- Treating pgvector as mandatory baseline infrastructure for all Scoria contributors and all core/SRE test paths.
- Auto-starting Docker or mutating local environment implicitly from ordinary `mix test`.
- A deeper Parapet runtime dependency or a larger observability product surface in this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRE-04 | Reason-coded telemetry is defined but not wired into live paths. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | `Summary`, `Standard Stack`, `Architecture Patterns`, `Common Pitfalls`, and `Validation Architecture` prescribe the real emitters, identity contract, and verification suites. |
| SRE-08 | Default local verification still requires manual bootstrap work. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | `Summary`, `Standard Stack`, `Runtime State Inventory`, `Environment Availability`, and `Validation Architecture` prescribe the migration split, explicit knowledge lane, and removal of test-local DDL. |
</phase_requirements>

## Summary

Phase 10 should not add more telemetry surfaces. It should turn the existing `Scoria.SRE.Telemetry` helper into a production seam by emitting from `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor`, and it should emit a second, separate namespace from `Scoria.SRE.IncidentManager` only after durable incident rows commit. Today `Scoria.SRE.Telemetry` is referenced only by `test/scoria/sre/telemetry_test.exs`, while runtime and MCP execution paths still emit generic tool events or none of the SRE helper events at all. [VERIFIED: `rg -n "Scoria\\.SRE\\.Telemetry|emit_latency|emit_cost|emit_quality|emit_budget_burn|emit_breaker_state|emit_tool_reliability" lib test`; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex; VERIFIED: lib/scoria/sre/incident_manager.ex]

The bootstrap defect is also narrower than the milestone audit originally described: default local verification fails because the repo’s default migration chain still places `20260511000300_create_knowledge_tables.exs` ahead of both SRE migrations, that migration unconditionally runs `CREATE EXTENSION IF NOT EXISTS vector`, and the local Postgres on this machine does not even expose the `vector` extension. `mix ecto.migrations` shows the knowledge and both later SRE migrations as `down`, and `MIX_ENV=test mix test test/scoria/sre_test.exs --trace` still fails on missing `ai_alert_policies`, while many other suites pass only because they create ad hoc tables in test setup. [VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs; VERIFIED: `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"` returned `0` on 2026-05-12; VERIFIED: `mix ecto.migrations` run on 2026-05-12; VERIFIED: `MIX_ENV=test mix test test/scoria/sre_test.exs --trace` run on 2026-05-12; VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`]

**Primary recommendation:** plan this phase around two repo-native changes: 1) a canonical SRE identity builder used by runtime, MCP, incident, and Parapet helpers, and 2) a core-vs-knowledge migration split implemented with standard Ecto migration paths so default `mix test` exercises only core/SRE tables while pgvector-backed knowledge remains an explicit second lane. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; CITED: https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html; CITED: https://hexdocs.pm/telemetry/readme.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Runtime step SLI telemetry emission | API / Backend | Database / Storage | `Scoria.Workflows.Runtime` owns the real workflow execution seam; telemetry observes outcomes while Ecto rows remain truth. [VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |
| MCP execution SLI telemetry emission | API / Backend | Database / Storage | `Scoria.MCP.Executor` owns paid and side-effecting tool execution, including budget and breaker context. [VERIFIED: lib/scoria/mcp/executor.ex] |
| Incident lifecycle telemetry after durable writes | API / Backend | Database / Storage | `Scoria.SRE.IncidentManager` already owns incident, alert, event, and delivery transactions, so post-commit lifecycle emission belongs there. [VERIFIED: lib/scoria/sre/incident_manager.ex] |
| Canonical operational identity derivation | API / Backend | — | The same low-cardinality shape must be shared before any DB projection or adapter translation. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/adapters/parapet.ex] |
| Default test bootstrap and migration routing | Database / Storage | API / Backend | The defect sits at the migration chain, not the LiveView or docs layer. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs; VERIFIED: `mix ecto.migrations` run on 2026-05-12] |
| Knowledge/full verification lane | Database / Storage | API / Backend | pgvector remains explicit infrastructure behind an opt-in bootstrap path. [VERIFIED: test/support/knowledge_case.exs; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `3.13.5` (released 2026-03-03) [VERIFIED: `mix hex.info ecto_sql`] | Owns migrations and runtime schema management. | Ecto’s current migrator supports custom migration sources and multiple directories, which is the clean repo-native way to split core and knowledge bootstrap. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; CITED: https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html] |
| `telemetry` | locked `1.4.1`, latest `1.4.2` released 2026-05-11 [VERIFIED: `mix hex.info telemetry`; VERIFIED: `grep -n '"telemetry"' mix.lock`] | Emits runtime and incident observation events. | `:telemetry.execute/3` and `:telemetry.attach_many/4` are the standard BEAM instrumentation seam; Scoria already uses them elsewhere. [CITED: https://hexdocs.pm/telemetry/telemetry; CITED: https://hexdocs.pm/telemetry/readme.html; VERIFIED: lib/scoria/sre/telemetry.ex] |
| PostgreSQL + Ecto migrations | local `psql 14.17` [VERIFIED: `psql --version`] | Default durable store for Scoria core and SRE tables. | Scoria’s core and SRE truth is already Ecto-first, and default verification must run against ordinary Postgres without requiring vector support. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `pgvector` | `0.3.1` (released 2025-06-23) [VERIFIED: `mix hex.info pgvector`] | Knowledge embeddings and vector columns. | Use only in the explicit knowledge/full lane after the `vector` extension is present. [CITED: https://github.com/pgvector/pgvector/blob/master/README.md; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |
| `hammer` | `7.3.0` (released 2026-03-31) [VERIFIED: `mix hex.info hammer`] | Existing short-window budget support. | Keep as-is; Phase 10 should reuse its runtime context rather than introduce new rate-limiter code. [VERIFIED: mix.exs; VERIFIED: .planning/phases/07-seismograph/07-CONTEXT.md] |
| `fuse` | `2.5.0` (released 2021-07-01) [VERIFIED: `mix hex.info fuse`] | Existing breaker support. | Keep as-is; emit breaker-related SRE telemetry from the same runtime seam that already invokes the breaker. [VERIFIED: mix.exs; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Split migration paths with `Ecto.Migrator` / `--migrations-path` | Keep one default chain and guard SQL conditionally inside the knowledge migration | Reject. Conditional SQL still leaves knowledge infrastructure in the boring default path and keeps `mix test` coupled to vector capability. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs] |
| Emit SRE telemetry from narrow runtime and incident seams | Scatter calls across callers or UI projection code | Reject. That would drift semantics and violate the existing “narrow seam emission” pattern. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |
| Shared canonical identity builder | Recompute labels independently in runtime, incident, and Parapet code | Reject. `incident_key`, `trace_id`, and adapter labels will drift or double-count without one implementation. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/adapters/parapet.ex] |

**Installation:**
```bash
mix deps.get
mix ecto.migrate
# explicit knowledge/full lane after Phase 10 should use a separate migration path or task
```

**Version verification:** Verified current package versions with `mix hex.info ecto_sql`, `mix hex.info telemetry`, `mix hex.info pgvector`, `mix hex.info hammer`, and `mix hex.info fuse` on 2026-05-12. [VERIFIED: shell commands run on 2026-05-12]

## Architecture Patterns

### System Architecture Diagram

```text
mix test
  |
  v
default repo bootstrap
  |
  +--> core migrations only ----------------------------+
  |                                                     |
  |                                                     v
  |                                           SRE + workflow tables available
  |                                                     |
  |                                                     v
  |                                   Workflow runtime / MCP executor tests run normally
  |
  +--> explicit knowledge/full bootstrap --------------> pgvector check/bootstrap
                                                        |
                                                        v
                                             knowledge migrations + knowledge tests

workflow step / MCP tool input
  |
  v
Scoria.Workflows.Runtime / Scoria.MCP.Executor
  |
  +--> canonical identity builder
  |       |
  |       +--> shared low-cardinality labels + identity_key
  |
  +--> Scoria.SRE.Telemetry.emit_* ---------------> :telemetry event bus
  |                                                   |
  |                                                   v
  |                                         Parapet translation / handlers
  |
  +--> durable failure / alert path ----------------> Scoria.SRE.IncidentManager
                                                      |
                                                      +--> ai_incidents / ai_alert_events / ai_incident_events / ai_notification_deliveries
                                                      |
                                                      +--> post-commit incident lifecycle telemetry
```

### Recommended Project Structure
```text
priv/repo/
├── migrations/             # default core chain: observability, approvals, workflows, SRE
└── knowledge_migrations/   # explicit pgvector-backed knowledge chain

lib/scoria/sre/
├── telemetry.ex            # public emitters
├── telemetry_identity.ex   # canonical identity + identity_key builder
└── adapters/parapet.ex     # translation keeps labels/refs discipline

lib/mix/tasks/
├── scoria.pgvector.bootstrap.ex
└── scoria.test.knowledge.ex   # or equivalent alias/task for explicit full lane

test/support/
└── knowledge_case.exs      # explicit opt-in knowledge bootstrap only
```

### Pattern 1: Emit SRE telemetry only at real execution seams
**What:** `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor` should derive one canonical identity map, classify the outcome once, and call `Scoria.SRE.Telemetry` immediately around the real execution result. Runtime SLI events and incident lifecycle events must use separate namespaces. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex]
**When to use:** On completed, timeout, handler-error, execution-failed, budget-trip, and breaker-open outcomes at the runtime seam, and on post-commit incident transitions at the incident seam. [VERIFIED: lib/scoria/workflows/runtime.ex; VERIFIED: lib/scoria/mcp/executor.ex; VERIFIED: lib/scoria/sre/incident_manager.ex]
**Example:**
```elixir
# Source: https://hexdocs.pm/telemetry/readme.html
:telemetry.execute(
  [:scoria, :sre, :runtime, :latency],
  %{duration_ms: 245},
  %{tenant_id: "tenant-1", policy_key: "provider:openai", reason_code: "latency_budget_burn"}
)
```

### Pattern 2: Split core and knowledge migration lanes with standard Ecto migration sources
**What:** Keep the default migration path free of pgvector requirements and move knowledge-specific migrations behind an explicit second path or task. Ecto’s migrator supports a directory or a list of directories as the migration source. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html]
**When to use:** For repo bootstrap, CI lane setup, and any future optional infrastructure that should not block core verification. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html
{:ok, _, _} =
  Ecto.Migrator.with_repo(Scoria.Repo, fn repo ->
    Ecto.Migrator.run(repo, ["priv/repo/migrations", "priv/repo/knowledge_migrations"], :up, all: true)
  end)
```

### Pattern 3: Keep knowledge bootstrap explicit in tests
**What:** Default `test/test_helper.exs` should not invoke pgvector bootstrap or require knowledge migrations. `Scoria.KnowledgeCase` remains the explicit opt-in seam for knowledge tests. [VERIFIED: test/test_helper.exs; VERIFIED: test/support/knowledge_case.exs]
**When to use:** Any test suite that touches embeddings, vector indexes, retrieval, or knowledge citations. [VERIFIED: test/support/knowledge_case.exs; VERIFIED: .planning/phases/06-corpus/06-VALIDATION.md]
**Example:**
```elixir
# Source: test/support/knowledge_case.exs
setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()
  :ok
end
```

### Anti-Patterns to Avoid
- **Test-only telemetry contract:** `Scoria.SRE.Telemetry` currently proves its shape only in tests; Phase 10 must add live emitters, not more helper tests. [VERIFIED: `rg -n "Scoria\\.SRE\\.Telemetry|emit_latency|emit_cost|emit_quality|emit_budget_burn|emit_breaker_state|emit_tool_reliability" lib test`]
- **One-chain bootstrap with unconditional vector DDL:** leaving `CREATE EXTENSION IF NOT EXISTS vector` in the default path keeps core verification blocked on optional infra. [VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs; VERIFIED: `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"` returned `0`]
- **Ad hoc test-local table creation as steady state:** the `ensure_*` helpers are currently compensating for broken bootstrap boundaries and should be retired from core/SRE tests. [VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`]
- **Using `trace_id`, `run_id`, approval IDs, or raw arguments as grouping labels:** keep them as refs only; canonical grouping must stay low cardinality. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/adapters/parapet.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Event bus / metrics fanout | Custom GenServer dispatcher or log parsing | `:telemetry.execute/3` + `:telemetry.attach_many/4` | The BEAM standard already provides synchronous handler invocation and stable conventions. [CITED: https://hexdocs.pm/telemetry/telemetry; CITED: https://hexdocs.pm/telemetry/readme.html] |
| Migration orchestration for optional schema lanes | Homegrown SQL runner in tests or bespoke bootstrap shell scripts | `Ecto.Migrator.run/4` and `mix ecto.migrate --migrations-path ...` | Current Ecto SQL directly supports custom migration directories and lists of paths. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; CITED: https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html] |
| Vector capability detection | Manual `psql` instructions scattered across docs/tests | `Mix.Tasks.Scoria.Pgvector.Bootstrap` as the explicit knowledge gate | The repo already has a dedicated task that checks extension availability and prints next steps. [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |
| Core/SRE test schema setup | Repeated `CREATE TABLE IF NOT EXISTS` helpers in each suite | Default migrated core path before tests start | Ecto migrations are the durable source of schema truth; hand-written test DDL is already drifting. [VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`] |

**Key insight:** the repo already contains the right primitives; the planning job is to connect them through standard seams, not to invent a second bootstrap or observability framework. [VERIFIED: lib/scoria/sre/telemetry.ex; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex; VERIFIED: lib/scoria/sre/incident_manager.ex]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `schema_migrations` already records all earlier core migrations, while `20260511000300_create_knowledge_tables`, `20260511170000_create_sre_budget_and_breaker_tables`, and `20260511171000_create_sre_incident_and_audit_tables` are still `down` in the local default DB. Pgvector-capable environments may already have run the knowledge migration and created knowledge tables. [VERIFIED: `mix ecto.migrations` run on 2026-05-12; VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs] | Plan a migration-path split without rewriting a previously-run migration version in place. This is a bootstrap/migration-routing change, not an SRE data migration. Existing version IDs must stay compatible with already-migrated environments. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html] |
| Live service config | CI currently lacks the Phase 10-required explicit two-lane contract; the context requires a boring core lane and an explicit knowledge/full lane. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] | Add CI workflow/config updates as code changes; no external UI-only service state was found in the researched files. [VERIFIED: user-provided file list; VERIFIED: repo scan during research] |
| OS-registered state | None found in the repo or requested artifacts. [VERIFIED: user-provided file list; VERIFIED: repo scan during research] | None. |
| Secrets/env vars | `SCORIA_DB_*` env vars control the repo connection, and `SCORIA_PGVECTOR_COMPOSE_FILE` plus bootstrap defaults support the explicit pgvector path. [VERIFIED: config/test.exs; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] | No secret rename is needed. Keep env names stable and ensure the core lane does not require pgvector-only vars. [VERIFIED: config/test.exs; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |
| Build artifacts | Existing `_build` artifacts and any old test DBs can cache stale migration state after a migration-path split. [VERIFIED: workspace listing showed `_build`; VERIFIED: `mix ecto.migrations` run on 2026-05-12] | Recreate or reset test DBs as part of verification after the migration split; no packaged artifact rename was found. [VERIFIED: author assessment based on Ecto migration state; CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html] |

## Common Pitfalls

### Pitfall 1: Double-counting one bad execution as both runtime burn and incident burn
**What goes wrong:** the runtime seam emits a failure event and the incident seam later emits another event with the same semantics, so one failure appears as two SLO-burn datapoints. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**Why it happens:** callers reuse `incident_key` or incident lifecycle semantics too early instead of distinguishing raw execution telemetry from durable incident lifecycle telemetry. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**How to avoid:** use separate namespaces and emit runtime telemetry from runtime/MCP seams, incident telemetry from `IncidentManager` only after commit. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/incident_manager.ex]
**Warning signs:** tests assert the same label set for raw runtime and incident lifecycle events, or runtime telemetry requires an `incident_key` before any incident exists. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]

### Pitfall 2: High-cardinality telemetry metadata leaks into labels
**What goes wrong:** `trace_id`, `run_id`, raw arguments, or approval IDs become grouping labels, making Parapet-facing data noisy and operationally useless. [VERIFIED: lib/scoria/sre/adapters/parapet.ex; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**Why it happens:** the current telemetry helper metadata list mixes identity, correlation refs, and provider/tool fields, but `Parapet.translate/3` still needs a stable label/ref split. [VERIFIED: lib/scoria/sre/telemetry.ex; VERIFIED: lib/scoria/sre/adapters/parapet.ex]
**How to avoid:** centralize identity building and explicitly map low-cardinality labels separately from refs. Add `identity_key` beside the shared dimensions and keep `trace_id` / `run_id` in refs only. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**Warning signs:** tests start asserting labels on `trace_id`, `run_id`, or tool argument content. [VERIFIED: test/scoria/sre/telemetry_test.exs]

### Pitfall 3: Fixing bootstrap in tests instead of at the migration boundary
**What goes wrong:** focused suites pass by creating local tables, but the repo bootstrap remains broken and `mix test` stays non-boring. [VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`; VERIFIED: `MIX_ENV=test mix test test/scoria/sre_test.exs --trace`]
**Why it happens:** migrations are still coupled to pgvector, so tests compensate with `ensure_*` helpers. [VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs; VERIFIED: test/scoria/sre/incident_test.exs; VERIFIED: test/scoria/sre/relay_test.exs]
**How to avoid:** split the migration paths, make core migrations the default test bootstrap, and remove hand-written DDL from core/SRE suites as Phase 10 work completes. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
**Warning signs:** `mix ecto.migrations` still shows SRE tables as `down`, or `test/scoria/sre_test.exs` fails because a table exists only in suite-local setup. [VERIFIED: `mix ecto.migrations`; VERIFIED: `MIX_ENV=test mix test test/scoria/sre_test.exs --trace`]

### Pitfall 4: Running migrations dynamically inside sandboxed tests
**What goes wrong:** tests become flaky or impossible to isolate because the migrator needs separate connections and is not compatible with sandbox execution inside each test process. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html]
**Why it happens:** it is tempting to “just run migrations” from `test_helper` or case setup after discovering missing tables. [VERIFIED: current use of ad hoc DDL in multiple tests]
**How to avoid:** bootstrap schema outside per-test sandbox flows and reserve `KnowledgeCase` for explicit pgvector verification. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; VERIFIED: test/support/knowledge_case.exs]
**Warning signs:** any plan proposes `Ecto.Migrator.run/4` from a sandboxed case template or individual test. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html]

## Code Examples

Verified patterns from official sources:

### Explicit migration source selection
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html
{:ok, _, _} =
  Ecto.Migrator.with_repo(Scoria.Repo, fn repo ->
    Ecto.Migrator.run(repo, "priv/repo/migrations", :up, all: true)
  end)
```

### Telemetry emission with measurements and metadata
```elixir
# Source: https://hexdocs.pm/telemetry/readme.html
:telemetry.execute(
  [:scoria, :sre, :incident, :opened],
  %{count: 1},
  %{tenant_id: "tenant-1", reason_code: "breaker_open", workflow_run_id: "run-123"}
)
```

### Telemetry handler registration for multiple events
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry
:ok =
  :telemetry.attach_many(
    "scoria-sre-handler",
    [
      [:scoria, :sre, :runtime, :latency],
      [:scoria, :sre, :runtime, :tool_reliability],
      [:scoria, :sre, :incident, :opened]
    ],
    &MyHandler.handle_event/4,
    nil
  )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single migration chain with unconditional `CREATE EXTENSION vector` ahead of later SRE tables | Use Ecto’s supported custom migration sources so core and knowledge lanes can be run independently | Current Ecto SQL docs verified on 2026-05-12 support directory lists and custom migration paths. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; CITED: https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html] | Lets default `mix test` stay pgvector-free while preserving an explicit full lane. |
| Telemetry helper proven only in unit tests | Emit from real runtime/MCP seams and separate post-commit incident lifecycle seam | Phase 10 context locked on 2026-05-12. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] | SRE-04 becomes observable in production paths instead of only in helper tests. |
| Test-local `ensure_*` schema helpers compensate for missing migrations | Default test bootstrap provides core/SRE schema; knowledge bootstrap stays explicit in `KnowledgeCase` | Required by Phase 10 decisions on 2026-05-12. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: test/support/knowledge_case.exs] | SRE-08 can be closed without keeping schema drift hidden in tests. |

**Deprecated/outdated:**
- Test-local `CREATE TABLE IF NOT EXISTS` helpers as the primary way to make SRE suites pass. [VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`]
- Treating the default repo migration chain as knowledge-aware by default. [VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs; VERIFIED: `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"`]
- Leaving `Scoria.SRE.Telemetry` disconnected from production call sites. [VERIFIED: `rg -n "Scoria\\.SRE\\.Telemetry|emit_latency|emit_cost|emit_quality|emit_budget_burn|emit_breaker_state|emit_tool_reliability" lib test`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All substantive claims in this research were verified in the repo or cited from current docs. | — | — |

## Open Questions (RESOLVED)

1. **How should the repo preserve compatibility for environments that already ran the knowledge migration?**
   - Decision: keep migration version `20260511000300` valid for the explicit knowledge lane, but move the active migration routing to lane-specific directories instead of renumbering or replacing that version. The default core lane uses migration paths that omit knowledge migrations entirely, while the explicit knowledge/full lane includes the existing knowledge migration version `20260511000300` in its own path plus any later knowledge follow-up migrations. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html; VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs]
   - Compatibility effect: environments that already recorded `20260511000300` keep that `schema_migrations` entry and will skip it when the knowledge lane runs, while fresh core-only environments never see that version until they opt into the knowledge lane. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migrator.html]
   - Planning requirement: verification must cover both cases: a fresh core-only bootstrap and an already-migrated knowledge environment that re-runs the new explicit knowledge lane safely. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]

2. **What exact event names should represent runtime vs incident telemetry?**
   - Decision: lock the public split as `[:scoria, :sre, :runtime, ...]` for live execution telemetry and `[:scoria, :sre, :incident, ...]` for post-commit incident lifecycle telemetry. `:sli` should no longer be the top-level category for Phase 10 deliverables. [VERIFIED: lib/scoria/sre/telemetry.ex; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
   - Contract effect: runtime events carry canonical low-cardinality operational identity and ref-only correlation fields even before an incident exists; incident events may add derived `incident_key` after durable materialization, but they must stay in the incident namespace. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]
   - Planning requirement: tests must assert namespace separation and canonical metadata reuse across runtime, MCP, incident, and Parapet translation. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | all phase work | ✓ [VERIFIED: `elixir --version`] | `1.19.5` | — |
| Mix | migrations, tests, explicit bootstrap tasks | ✓ [VERIFIED: `mix --version`] | `1.19.5` | — |
| PostgreSQL CLI | local DB inspection | ✓ [VERIFIED: `psql --version`] | `14.17` | — |
| Docker | explicit pgvector bootstrap path | ✓ [VERIFIED: `docker --version`] | `29.4.1` | If Docker is unavailable elsewhere, keep knowledge lane manual and non-default. [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |
| `vector` PostgreSQL extension in the default local DB | knowledge/full lane only | ✗ [VERIFIED: `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"` returned `0`] | — | Keep core/SRE lane vector-free and use the explicit pgvector bootstrap path for knowledge verification. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex] |

**Missing dependencies with no fallback:**
- None for the core/SRE default lane. [VERIFIED: local tool audit on 2026-05-12]

**Missing dependencies with fallback:**
- `vector` extension on the default local Postgres; fallback is the explicit knowledge/full bootstrap lane instead of blocking default `mix test`. [VERIFIED: `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"`; VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test runner. [VERIFIED: test/test_helper.exs; VERIFIED: mix.exs] |
| Config file | none dedicated; bootstrap lives in `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs test/scoria/sre_test.exs -x` [VERIFIED: existing files and seams] |
| Full suite command | `MIX_ENV=test mix test` for the boring core lane, plus an explicit knowledge/full lane command or alias added by this phase. [VERIFIED: Phase 10 decision D-15; VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRE-04 | Runtime and MCP seams emit canonical, reason-coded live SRE telemetry, and incident lifecycle emits a distinct post-commit namespace. [VERIFIED: requirement + context] | unit + integration | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs -x` | ✅ [VERIFIED: `rg --files test/scoria/sre test/scoria/workflows test/scoria/mcp`] |
| SRE-08 | Default local verification runs core/SRE suites without pgvector bootstrap or test-local schema patching, while knowledge/full verification remains explicit. [VERIFIED: requirement + context] | bootstrap + integration | `MIX_ENV=test mix test test/scoria/sre_test.exs test/scoria/workflows/runtime_test.exs test/scoria/sre/relay_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs -x` | ✅ existing files; they need bootstrap cleanup. [VERIFIED: `rg --files test/scoria test/scoria_web/live`] |

### Sampling Rate
- **Per task commit:** run the quick Phase 10 suite above on the boring default lane. [VERIFIED: author recommendation grounded in touched seams]
- **Per wave merge:** run `MIX_ENV=test mix test` plus the explicit knowledge/full lane command once it exists. [VERIFIED: Phase 10 decision D-15]
- **Phase gate:** both explicit CI lanes must pass: core/SRE default and knowledge/full. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md]

### Wave 0 Gaps
- [ ] Add a bootstrap implementation for the default core lane that migrates core/SRE schema without pgvector. [VERIFIED: `mix ecto.migrations`; VERIFIED: priv/repo/migrations/20260511000300_create_knowledge_tables.exs]
- [ ] Add an explicit knowledge/full lane command or alias that checks/bootstrap pgvector before running knowledge migrations/tests. [VERIFIED: lib/mix/tasks/scoria.pgvector.bootstrap.ex; VERIFIED: test/support/knowledge_case.exs]
- [ ] Remove or drastically shrink test-local `ensure_*` DDL helpers from core/SRE suites so schema truth comes from migrations. [VERIFIED: `rg -n "ensure_.*table|CREATE TABLE IF NOT EXISTS ai_alert_policies|CREATE TABLE IF NOT EXISTS ai_audit_outbox_events|CREATE TABLE IF NOT EXISTS ai_notification_deliveries|ai_alert_policies" test lib`]
- [ ] Expand runtime and MCP tests to assert live SRE telemetry emission, not only business outcomes. [VERIFIED: current runtime/MCP tests lack `Scoria.SRE.Telemetry` assertions; VERIFIED: `rg -n "Scoria\\.SRE\\.Telemetry|emit_latency|emit_cost|emit_quality|emit_budget_burn|emit_breaker_state|emit_tool_reliability" test/scoria/workflows test/scoria/mcp test/scoria/sre`] |

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 10 does not introduce new auth flows. [VERIFIED: phase scope in 10-CONTEXT.md] |
| V3 Session Management | no | Phase 10 does not alter session handling. [VERIFIED: phase scope in 10-CONTEXT.md] |
| V4 Access Control | yes | Preserve tenant- and actor-attributed evidence at runtime and incident seams; do not move approval or incident truth into client code. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/incident_manager.ex] |
| V5 Input Validation | yes | Canonical identity builder plus existing changesets must constrain telemetry metadata and incident envelopes to stable, expected fields. [VERIFIED: lib/scoria/sre/telemetry.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre.ex] |
| V6 Cryptography | yes | Reuse existing payload hashing and redacted refs for durable evidence; do not invent new hashing schemes in telemetry wiring. [VERIFIED: lib/scoria/sre.ex] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Telemetry metadata cardinality explosion leaks sensitive refs or destroys aggregation quality | Information Disclosure / DoS | Centralize low-cardinality identity and keep `trace_id`, `run_id`, and raw arguments out of grouping labels. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md; VERIFIED: lib/scoria/sre/adapters/parapet.ex] |
| Broken bootstrap hides missing durable tables until runtime | Tampering / DoS | Make migrations the only schema truth for core lanes; remove ad hoc test DDL reliance. [VERIFIED: `mix ecto.migrations`; VERIFIED: test/scoria/sre/incident_test.exs; VERIFIED: test/scoria/sre/relay_test.exs] |
| Incident and runtime telemetry semantics diverge | Repudiation | Emit from one canonical identity builder and separate namespaces; verify both in tests. [VERIFIED: .planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md` - locked phase scope and decisions. [VERIFIED: file read on 2026-05-12]
- `lib/scoria/workflows/runtime.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria/sre/telemetry.ex`, `lib/scoria/sre/incident_manager.ex`, `lib/scoria/sre/adapters/parapet.ex`, `test/test_helper.exs`, `test/support/knowledge_case.exs`, `priv/repo/migrations/20260511000300_create_knowledge_tables.exs`, `priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs` - current implementation seams and bootstrap constraints. [VERIFIED: files read on 2026-05-12]
- `mix ecto.migrations`, `MIX_ENV=test mix test test/scoria/sre_test.exs --trace`, `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs --trace`, `psql -d postgres -Atqc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector';"` - current local state and failure evidence. [VERIFIED: commands run on 2026-05-12]
- https://hexdocs.pm/ecto_sql/Ecto.Migrator.html - multiple migration sources, custom directories, and sandbox limitations. [CITED]
- https://hexdocs.pm/ecto_sql/Mix.Tasks.Ecto.Migrate.html - `--migrations-path` support and default migration path behavior. [CITED]
- https://hexdocs.pm/telemetry/telemetry and https://hexdocs.pm/telemetry/readme.html - `:telemetry.execute/3` and `:telemetry.attach_many/4` usage. [CITED]
- https://github.com/pgvector/pgvector/blob/master/README.md - extension enable/verify requirements. [CITED]

### Secondary (MEDIUM confidence)
- `mix hex.info ecto_sql`, `mix hex.info telemetry`, `mix hex.info pgvector`, `mix hex.info hammer`, `mix hex.info fuse`, `mix hex.info phoenix_live_view` - current package release verification. [VERIFIED: commands run on 2026-05-12]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all stack claims were verified in the repo or current official docs. [VERIFIED: sources above]
- Architecture: MEDIUM - the seams and constraints are clear, but the exact migration-path compatibility implementation still needs one Wave 0 decision. [VERIFIED: open questions above]
- Pitfalls: HIGH - all listed pitfalls are grounded in current code, test failures, or official Ecto migration constraints. [VERIFIED: sources above]

**Research date:** 2026-05-12  
**Valid until:** 2026-06-11 for repo-specific findings, or earlier if migration/bootstrap layout changes. [VERIFIED: author assessment]

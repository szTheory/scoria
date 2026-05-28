# Phase 52: Runtime-to-handoff example contract - Research

**Researched:** 2026-05-27 [VERIFIED: system date]
**Domain:** Phoenix/Elixir adopter-facing runtime example, Scoria public facade, bounded delegated handoff safety [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: codebase grep]

## User Constraints

No `52-CONTEXT.md` exists for this phase, so there are no locked discuss-phase decisions to copy verbatim. [VERIFIED: `gsd-sdk query init.phase-op 52`]

The active milestone constrains the phase to one runtime-to-handoff adopter example, bounded projected-context guidance, and executable truth; broad example catalogs, hosted onboarding, package-family decomposition, semantic/retrieval prerequisites, and new public runtime APIs are out of scope unless a blocking gap is discovered. [VERIFIED: .planning/REQUIREMENTS.md]

## Summary

Phase 52 should plan a narrow adopter-facing example that starts with the existing default runtime lane through `Scoria.start_run/2`, then shows the host app deciding to escalate into `Scoria.start_handoff_run/3` for bounded review/classification-style work. [VERIFIED: docs/phoenix_runtime_example.md:9] [VERIFIED: docs/phoenix_runtime_example.md:113] The current code already exposes the needed public facade, delegated handoff creation path, projected-context rejection rules, and curated readback through `Scoria.get_run_detail/1`. [VERIFIED: lib/scoria.ex:43] [VERIFIED: lib/scoria/runtime.ex:50] [VERIFIED: lib/scoria/runtime/params.ex:88] [VERIFIED: lib/scoria/runtime/run_detail.ex:60]

The smallest safe plan is documentation/example plus tests that pin the example fragments and rejection behavior; do not add runtime APIs unless the implementation pass proves that the example cannot truthfully express the path with `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, and `Scoria.get_run_detail/1`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria.ex:43] The example must make host-app ownership explicit: the Phoenix host owns identity, policy decision, prompt/draft selection, and bounded projected context; Scoria owns durable run creation, handoff lineage, rejection of broad runtime-state keys, and curated operator/readback evidence. [VERIFIED: docs/bounded_handoffs.md:15] [VERIFIED: docs/bounded_handoffs.md:61]

**Primary recommendation:** Plan Phase 52 as an example-contract tightening phase: inspect existing docs/tests first, add a canonical runtime-to-handoff example module or doc section, and pin both accepted and rejected projected-context behavior with ExUnit tests. [VERIFIED: test/scoria/adoption_surface_test.exs] [VERIFIED: test/scoria/runtime_test.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Host identity and lane-escalation decision | Phoenix host app | Scoria public facade | The existing example normalizes identity from controller/session state before calling `Scoria`; bounded handoff docs say the host app passes the explicit contract fields. [VERIFIED: docs/phoenix_runtime_example.md:26] [VERIFIED: docs/bounded_handoffs.md:25] |
| Default durable runtime start | API / Backend | Database / Storage | `Scoria.start_run/2` delegates to `Scoria.Runtime.start_run/2`, which normalizes params and creates a workflow run. [VERIFIED: lib/scoria.ex:43] [VERIFIED: lib/scoria/runtime.ex:27] |
| Bounded delegated handoff | API / Backend | Database / Storage | `Scoria.start_handoff_run/3` validates explicit handoff inputs, creates a run, creates a root handoff step, executes handoff creation, and queues child dispatch. [VERIFIED: lib/scoria/runtime.ex:50] [VERIFIED: lib/scoria/runtime/params.ex:37] |
| Projected-context safety | API / Backend | Phoenix host app | Scoria validates projected context and rejects unsafe key aliases; the host app must choose a narrow context slice before calling the handoff API. [VERIFIED: lib/scoria/runtime/params.ex:88] [VERIFIED: lib/scoria/runtime/params.ex:280] [VERIFIED: docs/bounded_handoffs.md:61] |
| Curated delegated readback | API / Backend | Operator UI | `RunDetail.from_run_tree/2` derives `delegated_handoffs`, and the docs point host/support flows at `Scoria.get_run_detail/1` and `/scoria/workflows/:run_id`. [VERIFIED: lib/scoria/runtime/run_detail.ex:49] [VERIFIED: docs/bounded_handoffs.md:78] |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXMP-01 | Phoenix developer can follow one adopter-facing example that starts a default Scoria run and escalates into `Scoria.start_handoff_run/3` without needing maintainer folklore. | Existing docs already show `Scoria.start_run/2` and a handoff branch, but Phase 52 should make the path one cohesive contract instead of two loosely related sections. [VERIFIED: docs/phoenix_runtime_example.md:43] [VERIFIED: docs/phoenix_runtime_example.md:117] |
| EXMP-02 | The example shows the bounded projected-context shape, including what can be passed safely and what Scoria rejects or excludes by default. | Runtime params require `projected_context` to be a map, accept empty/narrow maps, and reject broad runtime-state keys and aliases before durable write. [VERIFIED: lib/scoria/runtime/params.ex:50] [VERIFIED: lib/scoria/runtime/params.ex:88] [VERIFIED: test/scoria/runtime_test.exs:169] |

## Project Constraints

No `AGENTS.md` or `CLAUDE.md` exists in the repository root, so no project-specific instruction file adds directives beyond the planning docs and codebase conventions. [VERIFIED: shell `test -f AGENTS.md`; `test -f CLAUDE.md`]

No `.claude/skills/` or `.agents/skills/` project skill `SKILL.md` files were found, so there are no project-local skill patterns to incorporate. [VERIFIED: shell `find .claude/skills .agents/skills -name SKILL.md`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Runtime language and build/test runner | The project declares `elixir: "~> 1.19"` and the local toolchain is Elixir/Mix 1.19.5. [VERIFIED: mix.exs] [VERIFIED: `elixir --version`] |
| Phoenix | locked 1.8.7 | Phoenix-hosted adopter example and route/controller conventions | Scoria is Phoenix-first, and the current lock uses Phoenix 1.8.7; Hex reports 1.8.7 as a recent release from 2026-05-06. [VERIFIED: mix deps] [VERIFIED: `mix hex.info phoenix`] |
| Ecto SQL | locked 3.13.5 | Durable workflow/run persistence and SQL sandbox tests | Scoria uses `Scoria.Repo` with Ecto SQL sandbox in tests; Hex reports Ecto SQL 3.14.0 exists, so planner should not upgrade during this scoped phase. [VERIFIED: mix deps] [VERIFIED: config/test.exs] [VERIFIED: `mix hex.info ecto_sql`] |
| Oban | locked 2.22.1 | Background queues/runtime dispatch support | The project configures Oban queues and locks Oban 2.22.1; Phase 52 should not alter queue architecture. [VERIFIED: mix deps] [VERIFIED: config/config.exs] |
| ExUnit | 1.19.5 | Focused unit/integration/doc-source tests | The existing test harness uses ExUnit and Ecto sandbox; focused docs tests passed in this research session. [VERIFIED: test/test_helper.exs] [VERIFIED: command output `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | locked 1.4.5 | JSON/map payload support in persisted runtime metadata | Use existing map/JSON-compatible examples; do not introduce custom serialization for projected context. [VERIFIED: mix deps] [VERIFIED: lib/scoria/runtime/params.ex:108] |
| Floki / LazyHTML | Floki locked by deps; LazyHTML declared test-only | HTML/source assertions for docs/operator components | Use only if Phase 52 touches rendered docs or LiveView/component evidence; current doc-source tests mostly use string assertions. [VERIFIED: mix.exs] [VERIFIED: test/scoria/adoption_surface_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `Scoria` facade | Direct `Scoria.Runtime` or `Scoria.Workflows` calls | Direct runtime/workflow calls contradict the adopter-facing surface; docs already tell host apps to use public `Scoria` first and avoid direct `Scoria.Workflows` as the normal entrypoint. [VERIFIED: docs/phoenix_runtime_example.md:180] |
| ExUnit source-alignment tests | A sample Phoenix app | A sample app would widen scope; the active milestone says one narrow example and excludes hosted onboarding/broad examples. [VERIFIED: .planning/REQUIREMENTS.md] |
| Existing projected-context validator | New sanitizer/redactor layer | Runtime already rejects unsafe keys and aliases; adding sanitization risks hiding excluded inputs instead of demonstrating truthful rejection. [VERIFIED: lib/scoria/runtime/params.ex:88] [VERIFIED: test/scoria/runtime_test.exs:215] |

**Installation:**

No new packages are recommended for Phase 52. [VERIFIED: mix.exs] If dependencies are missing locally, run:

```bash
mix deps.get
```

**Version verification:** Versions above were verified with `mix deps`, `elixir --version`, `mix --version`, and `mix hex.info phoenix/ecto_sql` rather than training knowledge. [VERIFIED: command output]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix controller/session state
  -> Scoria.identity/1
  -> Scoria.start_run/2
  -> persist returned run_id in host app
  -> host app detects bounded delegation need
      -> build explicit handoff_input + narrow projected_context
      -> Scoria.start_handoff_run/3
          -> Runtime.Params.start_handoff/3 validates required fields
          -> validate_projected_context/1 rejects broad runtime-state keys
          -> Workflows.create_run/1 creates durable run
          -> root handoff step records delegation
          -> child delegated step is queued
      -> Scoria.get_run_detail/1
          -> RunDetail.delegated_handoffs exposes curated lineage/context
      -> /scoria/workflows/:run_id for operator evidence
```

Every arrow above maps to existing code or docs. [VERIFIED: lib/scoria/runtime.ex:27] [VERIFIED: lib/scoria/runtime.ex:50] [VERIFIED: lib/scoria/runtime/run_detail.ex:60] [VERIFIED: docs/bounded_handoffs.md:89]

### Recommended Project Structure

```text
docs/
├── phoenix_runtime_example.md        # default runtime lane and cohesive escalation example [VERIFIED: codebase]
├── bounded_handoffs.md               # projected-context safety and delegated lineage contract [VERIFIED: codebase]
test/support/scoria/
├── adoption_example.ex               # shared source fragments for doc drift checks [VERIFIED: codebase]
test/scoria/
├── runtime_test.exs                  # API behavior and rejection tests [VERIFIED: codebase]
├── handoff_example_source_test.exs   # bounded handoff doc alignment [VERIFIED: codebase]
└── adoption_surface_test.exs         # public docs lane hierarchy assertions [VERIFIED: codebase]
```

### Pattern 1: Public Facade First

**What:** Examples should call `Scoria.identity/1`, `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, and `Scoria.get_run_detail/1` instead of `Scoria.Workflows` internals. [VERIFIED: lib/scoria.ex:31] [VERIFIED: lib/scoria.ex:43]

**When to use:** Use this pattern for all adopter-facing examples in Phase 52. [VERIFIED: .planning/ROADMAP.md]

**Example:**

```elixir
# Source: docs/phoenix_runtime_example.md and docs/bounded_handoffs.md [VERIFIED: codebase]
identity =
  Scoria.identity(%{
    actor_id: conn.assigns.current_user.id,
    tenant_id: conn.assigns.current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })

{:ok, started} = Scoria.start_run(identity, root_role_id: "executor")

{:ok, handoff_run} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer"},
    projected_context: %{"task" => "policy review", "draft_answer" => draft_answer}
  )

{:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)
delegated = detail.delegated_handoffs
```

### Pattern 2: Rejection Is Part of the Example Contract

**What:** The example should show that `projected_context: %{}` and narrow host-controlled slices are valid, while `transcript`, `messages`, `history`, `provider_session`, `runtime_state`, `session`, `socket_state`, `headers`, `cookies`, and `secrets` are rejected directly or through aliases/suffixes. [VERIFIED: docs/bounded_handoffs.md:65] [VERIFIED: lib/scoria/runtime/params.ex:280]

**When to use:** Use this pattern in both docs and tests for EXMP-02. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: test/scoria/runtime_test.exs and lib/scoria/runtime/params.ex [VERIFIED: codebase]
assert {:error, :unsafe_projected_context} =
         Scoria.start_handoff_run(identity, "critic",
           root_role_id: "planner",
           delegated_kind: "review",
           handoff_input: %{"brief" => "review draft"},
           projected_context: %{"safe" => %{"provider_session" => %{"token" => "secret"}}}
         )
```

### Anti-Patterns to Avoid

- **Starting the example at handoff:** This would skip the milestone requirement that the example starts from the default runtime lane. [VERIFIED: .planning/ROADMAP.md]
- **Implicitly projecting payload/transcript into handoff context:** Existing docs explicitly refute implicit payload projection, and runtime validation rejects broad runtime-state keys. [VERIFIED: test/scoria/adoption_surface_test.exs] [VERIFIED: lib/scoria/runtime/params.ex:280]
- **Creating a separate handoff verifier lane in Phase 52:** Phase 54 owns executable proof; Phase 52 should prepare examples/tests without claiming final canonical proof. [VERIFIED: .planning/ROADMAP.md]
- **Using semantic fast path, knowledge, retrieval, or pgvector in the example path:** The active requirements exclude optional semantic/retrieval prerequisites from the default proof path. [VERIFIED: .planning/REQUIREMENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable run creation | Custom workflow insertion in example code | `Scoria.start_run/2` | The public facade already creates normalized durable runs and returns stable summaries. [VERIFIED: lib/scoria/runtime.ex:27] |
| Bounded delegation | Direct `Workflows.create_handoff/2` in adopter docs | `Scoria.start_handoff_run/3` | The public API validates required handoff inputs and projected-context safety before durable writes. [VERIFIED: lib/scoria/runtime.ex:50] [VERIFIED: lib/scoria/runtime/params.ex:44] |
| Context safety | Custom redactor/sanitizer for example payloads | `Runtime.Params.validate_projected_context/1` through `start_handoff_run/3` | Existing validation rejects unsafe nested keys and aliases; custom sanitization would make behavior less truthful. [VERIFIED: lib/scoria/runtime/params.ex:88] |
| Delegated readback | Raw workflow table reconstruction | `Scoria.get_run_detail/1` and `detail.delegated_handoffs` | The DTO already derives parent/child same-run lineage and projected context for public inspection. [VERIFIED: lib/scoria/runtime/run_detail.ex:161] |
| Doc drift checks | Manual reviewer memory | `test/support/scoria/adoption_example.ex` fragments plus ExUnit tests | Existing source tests pin public examples to known fragments. [VERIFIED: test/support/scoria/adoption_example.ex] [VERIFIED: test/scoria/handoff_example_source_test.exs] |

**Key insight:** The hard part is not a new runtime capability; it is presenting the already-shipped runtime and handoff lanes as one truthful adopter path with explicit host ownership and explicit rejection behavior. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/scoria/runtime/params.ex]

## Common Pitfalls

### Pitfall 1: Treating `session_id` as the handoff parent

**What goes wrong:** The example could imply that delegation attaches to a host session rather than to one durable run. [VERIFIED: docs/phoenix_runtime_example.md:17]

**Why it happens:** The runtime guide reuses `session_id` for conversation continuity, while `run_id` is the exact durable handle. [VERIFIED: docs/phoenix_runtime_example.md:19]

**How to avoid:** Persist and inspect `run_id`, and use `session_id` only to group related turns. [VERIFIED: docs/phoenix_runtime_example.md:76]

**Warning signs:** Example code resumes or links operator evidence using `session_id`. [VERIFIED: docs/phoenix_runtime_example.md:80]

### Pitfall 2: Hiding projected-context rejection behind docs-only wording

**What goes wrong:** EXMP-02 would remain unverifiable if the docs mention unsafe keys but tests do not assert actual runtime behavior. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** The public docs and runtime tests currently live in separate files. [VERIFIED: docs/bounded_handoffs.md] [VERIFIED: test/scoria/runtime_test.exs]

**How to avoid:** Plan source-alignment tests that assert both accepted narrow context and rejected unsafe aliases. [VERIFIED: test/scoria/runtime_test.exs:215] [VERIFIED: test/scoria/runtime_test.exs:273]

**Warning signs:** New example text says "excluded" without naming the returned error or demonstrating no durable write. [VERIFIED: test/scoria/runtime_test.exs:215]

### Pitfall 3: Reopening semantic/knowledge setup by accident

**What goes wrong:** The example could become harder to run by requiring pgvector, knowledge tables, retrieval, or semantic cache setup. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** The repo already has semantic and knowledge lanes, and `start_run/2` contains semantic fast-path preparation when configured. [VERIFIED: lib/scoria/runtime.ex:31]

**How to avoid:** Omit `semantic_cache`, knowledge, retrieval, and pgvector from the Phase 52 example path. [VERIFIED: .planning/REQUIREMENTS.md]

**Warning signs:** Example code imports `Scoria.SemanticLane`, uses `semantic_cache:`, or references `mix test.semantic_fast_path`. [VERIFIED: docs/semantic_fast_path.md]

### Pitfall 4: Adding new public APIs before proving a blocker

**What goes wrong:** The phase could expand the public surface when existing `Scoria` APIs already satisfy the example. [VERIFIED: .planning/ROADMAP.md]

**Why it happens:** A runtime-to-handoff narrative may feel like it needs a linking helper, but the current APIs expose summaries, exact run ids, and delegated detail. [VERIFIED: lib/scoria.ex:43] [VERIFIED: lib/scoria.ex:63]

**How to avoid:** Make Plan 52-01 an inspection gate; only add an API if a concrete example gap is found and documented. [VERIFIED: .planning/ROADMAP.md]

**Warning signs:** A plan starts with new functions rather than doc/test changes around `Scoria.start_run/2` and `Scoria.start_handoff_run/3`. [VERIFIED: .planning/ROADMAP.md]

## Code Examples

### Accepted Narrow Handoff Context

```elixir
# Source: docs/bounded_handoffs.md [VERIFIED: codebase]
{:ok, started} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
    projected_context: %{
      "task" => "policy-and-accuracy review",
      "draft_answer" => draft_answer
    }
  )
```

### Empty Context Is Explicit And Valid

```elixir
# Source: test/scoria/runtime_test.exs [VERIFIED: codebase]
{:ok, empty_summary} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "review draft"},
    projected_context: %{}
  )
```

### Unsafe Context Rejection

```elixir
# Source: test/scoria/runtime_test.exs [VERIFIED: codebase]
assert {:error, :unsafe_projected_context} =
         Scoria.start_handoff_run(identity, "critic",
           root_role_id: "planner",
           delegated_kind: "review",
           handoff_input: %{"brief" => "review draft"},
           projected_context: %{"request_headers" => %{"authorization" => "secret"}}
         )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Start with raw workflow internals or separate handoff docs | Start with public `Scoria` facade and branch into bounded handoff from the same runtime-first story | Shipped by `v2.0 Relay` and carried into `v2.3` context [VERIFIED: .planning/STATE.md] | Phase 52 can plan example tightening, not runtime invention. [VERIFIED: .planning/ROADMAP.md] |
| Broad hidden context transfer | Explicit `projected_context` map with unsafe key rejection | Present in current `Runtime.Params` implementation [VERIFIED: lib/scoria/runtime/params.ex:50] | EXMP-02 should demonstrate accepted and rejected shapes. [VERIFIED: .planning/REQUIREMENTS.md] |
| Raw table inspection for delegation | Curated `detail.delegated_handoffs` and operator evidence surface | Present in current `RunDetail` implementation and docs [VERIFIED: lib/scoria/runtime/run_detail.ex:60] [VERIFIED: docs/bounded_handoffs.md:87] | Planner should map evidence readback through public DTOs. [VERIFIED: lib/scoria.ex:63] |

**Deprecated/outdated:**

- A handoff-first onboarding path is outdated for this milestone because the roadmap requires default runtime start before escalation. [VERIFIED: .planning/ROADMAP.md]
- A semantic/knowledge-backed proof path is out of scope for this phase because the requirements keep optional semantic, retrieval, grounding, and knowledge setup out of the default proof path. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The final cohesive example can live in existing docs/tests rather than a new sample app. [ASSUMED] | Summary / Standard Stack | If a generated host app is required for product positioning, the planner would need to add a larger example artifact and more proof plumbing. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should Phase 52 create a new dedicated doc file or tighten `docs/phoenix_runtime_example.md` and `docs/bounded_handoffs.md`?**
   - What we know: The existing docs already contain the runtime start and bounded handoff pieces. [VERIFIED: docs/phoenix_runtime_example.md:43] [VERIFIED: docs/bounded_handoffs.md:35]
   - What's unclear: The roadmap names an "example contract" but does not prescribe the artifact shape. [VERIFIED: .planning/ROADMAP.md]
   - Resolution: Phase 52 will tighten the existing docs plus shared source fragments instead of creating a new dedicated doc file, unless Plan 52-01 discovers a concrete blocker. [VERIFIED: .planning/phases/52-runtime-to-handoff-example-contract/52-01-PLAN.md]

2. **RESOLVED: Should rejection behavior be demonstrated in docs, tests, or both?**
   - What we know: The runtime already has rejection tests and docs list unsafe keys. [VERIFIED: test/scoria/runtime_test.exs:215] [VERIFIED: docs/bounded_handoffs.md:65]
   - What's unclear: EXMP-02 says "documented or demonstrated," so either can satisfy the wording. [VERIFIED: .planning/ROADMAP.md]
   - Resolution: Phase 52 will do both narrowly: docs must name the accepted bounded context and `{:error, :unsafe_projected_context}` behavior, while tests assert accepted and rejected examples without expanding into a broad verification lane. [VERIFIED: .planning/phases/52-runtime-to-handoff-example-contract/52-02-PLAN.md] [VERIFIED: .planning/phases/52-runtime-to-handoff-example-contract/52-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile and tests | Yes | 1.19.5 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Test/doc proof commands | Yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| PostgreSQL client | DB-backed runtime tests | Yes | psql 14.17 | None for DB tests; docs-only tests can run without DB. [VERIFIED: `psql --version`] |
| PostgreSQL server on `localhost:55432` | Existing semantic proof lane and possible DB-backed focused tests | No | no response | Use default `5432` if configured locally, or start the test DB before DB-backed tests. [VERIFIED: `pg_isready -h localhost -p 55432`] |
| Hex package registry access | Version checks | Yes | `mix hex.info phoenix` succeeded | Use locked `mix.lock` if network unavailable. [VERIFIED: command output] |

**Missing dependencies with no fallback:**

- A reachable PostgreSQL test database is required for DB-backed runtime tests such as `test/scoria/runtime_test.exs`; it was not reachable at `localhost:55432` during research. [VERIFIED: `pg_isready -h localhost -p 55432`] [VERIFIED: config/test.exs]

**Missing dependencies with fallback:**

- Docs/source-alignment tests can run without a reachable DB; `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` passed with 9 tests and 0 failures. [VERIFIED: command output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit 1.19.5 with Ecto SQL sandbox for DB-backed tests. [VERIFIED: `mix --version`] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html] |
| Config file | `test/test_helper.exs`, `config/test.exs`. [VERIFIED: codebase] |
| Quick run command | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` [VERIFIED: command output] |
| Full phase-relevant command | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs` after test DB is reachable. [VERIFIED: codebase] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| EXMP-01 | Example starts from `Scoria.start_run/2` and escalates to `Scoria.start_handoff_run/3` through public facade | docs/source alignment + integration | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs` | Yes [VERIFIED: codebase] |
| EXMP-02 | Bounded projected context accepts empty/narrow maps and rejects unsafe broad runtime-state keys | unit/integration | `MIX_ENV=test mix test test/scoria/runtime_test.exs --only test` or focused named tests after DB is reachable | Yes, but Phase 52 likely needs additional example-specific assertions. [VERIFIED: test/scoria/runtime_test.exs] |

### Sampling Rate

- **Per task commit:** Run docs/source quick command for doc-only changes. [VERIFIED: command output]
- **Per wave merge:** Run phase-relevant command with DB reachable. [VERIFIED: config/test.exs]
- **Phase gate:** Full suite or `mix test.adoption` once DB prerequisites are ready; the existing adoption lane includes runtime, handoff example source, Phoenix example source, and host consumer proof tests. [VERIFIED: lib/mix/tasks/test.adoption.ex:5]

### Wave 0 Gaps

- [ ] Add or update an example-specific test file if the final artifact is not already covered by `test/scoria/handoff_example_source_test.exs` and `test/scoria/phoenix_example_source_test.exs`. [VERIFIED: codebase]
- [ ] Ensure DB-backed rejection tests can run by documenting/start-checking the test database prerequisite before claiming Phase 52 behavior verification. [VERIFIED: `pg_isready -h localhost -p 55432`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No direct auth implementation in Phase 52 | Host app owns authenticated actor mapping into `Scoria.identity/1`; do not add auth logic to the example. [VERIFIED: docs/phoenix_runtime_example.md:35] |
| V3 Session Management | Yes, conceptually | Keep `session_id` as host-owned continuity and `run_id` as Scoria-owned durable execution handle. [VERIFIED: docs/phoenix_runtime_example.md:17] |
| V4 Access Control | Yes, conceptually | Host app owns lane escalation policy; Scoria only receives explicit role/kind/input/context. [VERIFIED: docs/bounded_handoffs.md:17] |
| V5 Input Validation | Yes | Use existing `Runtime.Params` required field and projected-context validation; do not hand-roll sanitizer behavior. [VERIFIED: lib/scoria/runtime/params.ex:44] |
| V6 Cryptography | No new crypto in Phase 52 | Existing project has Cloak/Cloak Ecto configured, but this phase should not alter encryption. [VERIFIED: mix.exs] [VERIFIED: config/config.exs] |

### Known Threat Patterns for Phoenix Runtime-to-Handoff Examples

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Over-broad context leakage into delegated role | Information Disclosure | Pass only explicit bounded `projected_context`; rely on Scoria rejection for unsafe broad runtime-state keys. [VERIFIED: lib/scoria/runtime/params.ex:280] |
| Confusing host session with exact run | Repudiation / Tampering | Persist `run_id` for inspection/resume and use `session_id` only for grouping related turns. [VERIFIED: docs/phoenix_runtime_example.md:76] |
| Hidden policy transfer from Scoria to host | Elevation of Privilege | Keep escalation decision in host app; Scoria records explicit delegated role/kind/input/context. [VERIFIED: docs/bounded_handoffs.md:15] |
| Raw table inspection leaking internals | Information Disclosure | Use curated `Scoria.get_run_detail/1` and operator route instead of raw workflow rows. [VERIFIED: lib/scoria/runtime/run_detail.ex:49] [VERIFIED: docs/bounded_handoffs.md:87] |

## Sources

### Primary (HIGH confidence)

- `.planning/REQUIREMENTS.md` - active milestone requirements and out-of-scope boundaries. [VERIFIED: file read]
- `.planning/STATE.md` - milestone history and prior lane decisions. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 52 goal, success criteria, and plan split. [VERIFIED: file read]
- `lib/scoria.ex` - public facade functions. [VERIFIED: codebase]
- `lib/scoria/runtime.ex` - runtime start and handoff implementation. [VERIFIED: codebase]
- `lib/scoria/runtime/params.ex` - handoff input validation and unsafe projected-context rejection. [VERIFIED: codebase]
- `lib/scoria/runtime/run_detail.ex` - curated delegated handoff readback. [VERIFIED: codebase]
- `docs/phoenix_runtime_example.md` and `docs/bounded_handoffs.md` - current public examples. [VERIFIED: codebase]
- `test/scoria/runtime_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/handoff_example_source_test.exs` - current behavior/source checks. [VERIFIED: codebase]
- `mix deps`, `elixir --version`, `mix --version`, `mix hex.info phoenix`, `mix hex.info ecto_sql` - stack/version checks. [VERIFIED: command output]

### Secondary (MEDIUM confidence)

- https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html - Ecto SQL sandbox behavior for transactional tests. [CITED: official docs]
- https://hexdocs.pm/ex_unit/ExUnit.html - ExUnit current docs. [CITED: official docs]
- https://hexdocs.pm/phoenix/controllers.html - Phoenix controller docs for host-app controller framing. [CITED: official docs]

### Tertiary (LOW confidence)

- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - verified from `mix.exs`, `mix.lock`/`mix deps`, local toolchain, and Hex info output. [VERIFIED: command output]
- Architecture: HIGH - verified against current public facade, runtime params, handoff implementation, and run detail DTO. [VERIFIED: codebase]
- Pitfalls: HIGH - grounded in active requirements, existing docs, and current tests. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/scoria/runtime_test.exs]

**Research date:** 2026-05-27 [VERIFIED: system date]
**Valid until:** 2026-06-26 for internal codebase findings; re-check Hex versions after 30 days or before dependency changes. [ASSUMED]

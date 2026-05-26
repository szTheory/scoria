# Phase 48: Host-app install contract and consumer proof - Research

**Researched:** 2026-05-25
**Domain:** Phoenix host-app adoption proof, installer mutation hardening, and default-lane runtime verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Installer contract
- **D-01:** `mix scoria.install` remains Scoria's canonical one-command installer for the default Phoenix lane. Scoria should not fall back to a docs-only/manual-first install path for the primary adopter story.
- **D-02:** The installer contract should stay explicit and host-owned: patch the host router to mount `scoria_dashboard "/scoria"`, copy core migrations into the host app, inject baseline runtime defaults once, and patch Tailwind only when a Tailwind config exists.
- **D-03:** The installer should be hardened rather than widened in Phase 48: idempotency, duplicate prevention, explicit mutation reporting, and truthful fallback/manual guidance for nonstandard host layouts matter more than switching to a heavier installer framework now.
- **D-04:** Copied host-local migrations remain the default-lane posture in Phase 48. Scoria should not introduce a migration-helper abstraction or dependency-path migration contract yet; upgrade-oriented migration abstractions are a later concern.

### Consumer proof harness
- **D-05:** The canonical consumer proof should start from a fresh generated Phoenix app, not a large checked-in dummy host app.
- **D-06:** The recommended proof shape is a hybrid generated-host harness: create a fresh Phoenix app, apply a tiny bounded Scoria patch/template layer, then prove `deps.get`, `mix scoria.install`, `mix ecto.migrate`, and `/scoria` route visibility.
- **D-07:** The generated-host harness must stay deliberately small and Phoenix-version-pinned. It is a proof harness for public adoption truth, not a second long-lived sample application.

### Default-lane proof orchestration
- **D-08:** Scoria should expose one canonical default-lane verification command for adopters and maintainers, but implement it as layered focused proofs under the hood rather than one monolithic end-to-end test.
- **D-09:** The layered proof should combine:
  dependency fetch and host-app install/migrate/route smoke from the generated host harness,
  installer mutation/idempotency tests,
  migration-lane compatibility proof,
  and the existing public runtime/operator-evidence proof around `Scoria.start_run/2`, readback, and workflow visibility.
- **D-10:** The generated-host proof only needs bounded adoption assertions. Deep runtime semantics remain owned by Scoria's existing repo-internal runtime integration and adoption tests rather than being duplicated inside the host harness.

### Optional surfaces and lane messaging
- **D-11:** The installer and proof surfaces must treat Tailwind, knowledge, and semantic-fast-path setup as optional lanes, not hidden prerequisites for the default lane.
- **D-12:** `mix scoria.install` should print a compact lane inventory with three truths:
  what it installed,
  what it intentionally skipped,
  and what remains optional by lane.
- **D-13:** Missing Tailwind should produce explicit "skipped intentionally; default lane still installable" messaging, not silent omission and not a failure.
- **D-14:** Knowledge and semantic-fast-path surfaces should be named as later optional lanes with their own commands. Default-lane output should not imply that adopters must enable pgvector, retrieval, or semantic caching before Scoria is usable.

### Shift-left defaults for GSD
- **D-15:** Future GSD discuss/planning for adoption-path work should treat the following as locked defaults unless a later milestone changes product shape, blast radius, or support posture:
  keep the one-command installer shape,
  keep host-owned copied migrations for the default lane,
  prefer a fresh generated-host proof over a checked-in sample app,
  prefer one canonical umbrella verifier implemented as layered focused checks,
  and make optional surfaces explicit instead of silently assumed.

### the agent's Discretion
- Exact implementation technique for hardening the installer in Phase 48, including whether to stay regex-based with tighter guards or adopt a more semantic patching helper, as long as the public contract above stays unchanged.
- Exact naming and file layout of the generated-host proof harness and any helper scripts/templates.
- Exact composition of the canonical default-lane verification task, as long as adopters get one boring command and the layered seams remain bounded and debuggable.
- Exact wording of the compact lane inventory, as long as installed/skipped/optional truth stays explicit and consistent.

### Deferred Ideas (OUT OF SCOPE)
- Moving from copied host migrations to a library-owned migration-helper/version contract — valuable for future upgrade ergonomics, but broader than the first default-lane consumer proof.
- Replacing the installer with a full Igniter-based semantic codemod framework — potentially attractive later if Scoria accumulates more installer and upgrader mutations.
- Expanding the generated-host harness into a full long-lived sample app — would increase maintenance surface and drift risk without improving the Phase 48 proof goal enough.
- Full docs/support-language reconciliation across every lane — Phase 49 owns the final convergence of installer, README, verification, and support wording.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INST-01 | A Phoenix host app can run `mix scoria.install` once to mount the dashboard, copy core migrations, and inject baseline runtime defaults without duplicate or misleading mutations. [VERIFIED: .planning/REQUIREMENTS.md] | Harden router/config mutation detection, add explicit mutation reporting, and keep idempotency plus route smoke inside `mix test.adoption`. [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_test.exs; lib/mix/tasks/test.adoption.ex] |
| INST-02 | The default Phoenix lane installs cleanly when Tailwind or optional knowledge surfaces are absent, and the installer states the skipped or optional steps explicitly. [VERIFIED: .planning/REQUIREMENTS.md] | Treat missing Tailwind as expected on fresh Phoenix 1.8 hosts, and print installed/skipped/optional lane inventory that keeps knowledge and semantic lanes outside the default path. [VERIFIED: /tmp/scoria_phase48_default via `mix phx.new`; lib/mix/tasks/scoria.install.ex; docs/adoption_lanes.md] |
| PROOF-01 | A fresh Phoenix consumer app or equivalent host-app harness can prove dependency fetch, install, migration, and `/scoria` route visibility through the public adoption path. [VERIFIED: .planning/REQUIREMENTS.md] | Generate a fresh Phoenix app with `mix phx.new`, apply a tiny bounded patch layer, run `mix deps.get`, `mix scoria.install`, `mix ecto.migrate`, and assert `/scoria` routes and runtime pages resolve. [VERIFIED: 48-CONTEXT.md; mix help phx.new; test/mix/tasks/scoria.install_route_smoke_test.exs] |
| PROOF-02 | That same consumer proof path can start one durable run through `Scoria.start_run/2`, read it back through the public runtime facade, and inspect operator evidence without enabling optional knowledge or semantic lanes. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the generated-host runtime smoke narrow, and reuse repo-local runtime semantics tests for approval resume, session continuity, and workflow evidence details. [VERIFIED: test/scoria/runtime_integration_test.exs; lib/mix/tasks/test.adoption.ex; 48-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 48 is a proof-and-hardening phase, not a runtime-expansion phase. The existing repo already has the right public seams: `mix scoria.install` mutates router, migrations, Tailwind, and runtime config; `mix test.adoption` is the named default-lane verifier; `test/scoria/runtime_integration_test.exs` already proves `Scoria.start_run/2`, readback, same-session behavior, exact-`run_id` resume, and `/scoria/workflows/:run_id` operator evidence. [VERIFIED: lib/mix/tasks/scoria.install.ex; lib/mix/tasks/test.adoption.ex; test/scoria/runtime_integration_test.exs]

The missing evidence is a real fresh-host consumer proof. A local `mix phx.new` probe against Phoenix generator `1.8.7` produced a normal app with the expected router and `config/runtime.exs`, but no `tailwind.config.js`; Phoenix now generates an `AGENTS.md` file by default and explicitly documents that Tailwind v4 no longer needs a `tailwind.config.js`. That means Scoria's Tailwind patch path is already optional in the current fresh-host baseline and should be treated as an expected skip, not as an exceptional path. [VERIFIED: mix help phx.new; mix hex.info phx_new; /tmp/scoria_phase48_default/AGENTS.md; /tmp/scoria_phase48_default/lib/scoria_phase48_default_web/router.ex; /tmp/scoria_phase48_default/config/runtime.exs]

The best bounded implementation is a generated-host harness that lives in test support, generates a fresh Phoenix app on demand with `--no-install --no-agents-md`, overlays the smallest Scoria-specific patch set, and runs only host-wiring and one-run smoke assertions. Keep deep runtime semantics in the existing repo-local tests, then extend `mix test.adoption` to include the generated-host proof file instead of creating a second canonical verifier. [VERIFIED: 48-CONTEXT.md; lib/mix/tasks/test.adoption.ex; test/scoria/runtime_integration_test.exs] [ASSUMED]

**Primary recommendation:** Use a generated Phoenix 1.8.7 host harness with a tiny overlay, keep `mix test.adoption` as the one canonical default-lane verifier, and harden `mix scoria.install` around explicit mutation reporting and nonstandard-layout denial instead of adding a new installer framework. [VERIFIED: 48-CONTEXT.md; lib/mix/tasks/scoria.install.ex; lib/mix/tasks/test.adoption.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Host router mount at `/scoria` | Frontend Server (SSR) | Browser / Client | Router macros and LiveView mounting belong to the host Phoenix router, while the browser only consumes the mounted pages. [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_route_smoke_test.exs] |
| Core migration copying and execution | Database / Storage | API / Backend | The installer copies migrations into the host repo, and `mix ecto.migrate` owns schema state. [VERIFIED: lib/mix/tasks/scoria.install.ex; .planning/REQUIREMENTS.md] |
| Baseline runtime defaults injection | API / Backend | Frontend Server (SSR) | Scoria writes runtime config for the host app's backend runtime, not for browser code. [VERIFIED: lib/mix/tasks/scoria.install.ex] |
| Fresh-host consumer proof generation | API / Backend | Frontend Server (SSR) | The harness is created and driven by Mix/ExUnit, then proves router wiring and runtime pages in the generated host. [VERIFIED: 48-CONTEXT.md; mix help phx.new; test/scoria/runtime_integration_test.exs] |
| `/scoria` and `/scoria/workflows/:run_id` operator evidence | Frontend Server (SSR) | API / Backend | LiveView pages render evidence from durable runtime state, but route ownership and proof entrypoint are in the host router. [VERIFIED: test/scoria/runtime_integration_test.exs; docs/operator_verification.md] |
| Optional-lane messaging for Tailwind, semantic, and knowledge | API / Backend | Frontend Server (SSR) | The installer task output is the authoritative contract for what was installed versus skipped or deferred. [VERIFIED: lib/mix/tasks/scoria.install.ex; 48-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phx_new` | `1.8.7` published `2026-05-06` [VERIFIED: mix hex.info phx_new] | Generate the fresh Phoenix host harness. [VERIFIED: mix help phx.new] | This is the official Phoenix generator and already exists in the environment, so it proves the real adopter layout instead of a hand-rolled fixture. [VERIFIED: mix help phx.new; elixir/mix environment probe] |
| `phoenix` | `1.8.7` locked, release `2026-05-06` [VERIFIED: mix.lock; mix hex.info phoenix] | Host router, endpoint, and LiveView mount surface. [VERIFIED: mix.lock] | Scoria already targets Phoenix and the fresh-host proof should pin to the same generator/runtime family. [VERIFIED: mix.exs; /tmp/scoria_phase48_default via `mix phx.new`] |
| `phoenix_live_view` | `1.1.30` locked, release `2026-05-05` [VERIFIED: mix.lock; mix hex.info phoenix_live_view] | Drives `/scoria` and workflow evidence pages. [VERIFIED: mix.lock; test/scoria/runtime_integration_test.exs] | Current route smoke and operator-evidence tests already depend on this surface, so the consumer proof should reuse it rather than introduce a second UI proof mechanism. [VERIFIED: test/mix/tasks/scoria.install_route_smoke_test.exs; test/scoria/runtime_integration_test.exs] |
| `ecto_sql` | `3.13.5` locked, latest release `3.14.0` on `2026-05-19` [VERIFIED: mix.lock; mix hex.info ecto_sql] | Powers migration execution in both repo-local and generated-host proofs. [VERIFIED: mix.lock; lib/scoria/test_support/migrations.ex] | The phase needs copied host migrations and `mix ecto.migrate`, not a new migration abstraction. [VERIFIED: 48-CONTEXT.md; .planning/REQUIREMENTS.md] |
| `ExUnit` + Mix tasks | `Elixir 1.19.5` [VERIFIED: elixir --version; mix --version] | Orchestrate installer tests, generated-host proof, and adoption-lane aggregation. [VERIFIED: test files; lib/mix/tasks/test.adoption.ex] | No extra harness framework is required because the repo already has passing install, route, and runtime proof seams in ExUnit. [VERIFIED: SCORIA_DB_PORT=55432 MIX_ENV=test targeted test run; lib/mix/tasks/test.adoption.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix.ConnTest` | bundled with `phoenix 1.8.7` [VERIFIED: mix.lock; test/scoria/runtime_integration_test.exs] | Build host-side conn/session state for operator route checks. [VERIFIED: test/scoria/runtime_integration_test.exs] | Use in the generated-host runtime smoke after the host app compiles and migrations run. [VERIFIED: test/scoria/runtime_integration_test.exs] |
| `Phoenix.LiveViewTest` | bundled with `phoenix_live_view 1.1.30` [VERIFIED: mix.lock; test/scoria/runtime_integration_test.exs] | Assert `/scoria` and `/scoria/workflows/:run_id` render the same durable run. [VERIFIED: test/scoria/runtime_integration_test.exs] | Use for one bounded evidence-page assertion; do not duplicate all runtime semantics here. [VERIFIED: 48-CONTEXT.md; test/scoria/runtime_integration_test.exs] |
| `Scoria.TestSupport.Migrations` | repo-local helper [VERIFIED: lib/scoria/test_support/migrations.ex] | Reuse migration setup logic and lane boundaries in repo-local verification. [VERIFIED: lib/scoria/test_support/migrations.ex; test/scoria/bootstrap/migration_lane_compatibility_test.exs] | Keep migration-lane compatibility proof separate from generated-host smoke. [VERIFIED: 48-CONTEXT.md; test/scoria/bootstrap/migration_lane_compatibility_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generated temp host harness [VERIFIED: 48-CONTEXT.md] | Checked-in sample Phoenix app [VERIFIED: 48-CONTEXT.md] | A checked-in app would drift, widen maintenance surface, and violate D-05/D-07. [VERIFIED: 48-CONTEXT.md] |
| Hardened regex/guarded patcher on the current installer [VERIFIED: 48-CONTEXT.md; lib/mix/tasks/scoria.install.ex] | Igniter or another semantic installer framework [VERIFIED: 48-CONTEXT.md] | Igniter may reduce regex brittleness later, but D-03 explicitly prioritizes hardening over widening in Phase 48. [VERIFIED: 48-CONTEXT.md] |
| Existing `mix test.adoption` umbrella verifier [VERIFIED: lib/mix/tasks/test.adoption.ex] | New standalone proof task | A new task would split the support story and violate D-08 unless it only became an internal helper. [VERIFIED: 48-CONTEXT.md] |

**Installation:**
```bash
mix archive.install hex phx_new
```

No new Scoria runtime dependency is recommended for Phase 48; reuse Phoenix, LiveView, Ecto SQL, Mix, and ExUnit already in the repo. [VERIFIED: mix.exs; mix.lock] [ASSUMED]

## Architecture Patterns

### System Architecture Diagram

```text
mix phx.new temp_host
        |
        v
bounded Scoria overlay
  - dep entry
  - tiny runtime smoke module
  - no full sample app
        |
        v
mix deps.get
        |
        v
mix scoria.install
        |
        +--> router patch -> scoria_dashboard "/scoria"
        +--> config patch -> Scoria.Runtime defaults
        +--> migration copy -> priv/repo/migrations
        +--> tailwind patch only if config exists
        |
        v
mix ecto.migrate
        |
        v
host proof test
  - route smoke
  - one Scoria.start_run/2
  - one Scoria.get_run/1 readback
  - one /scoria/workflows/:run_id evidence check
        |
        v
mix test.adoption
  + existing installer tests
  + migration lane compatibility
  + existing runtime integration suite
```

Diagram reflects the current phase contract and existing proof seams. [VERIFIED: 48-CONTEXT.md; lib/mix/tasks/scoria.install.ex; lib/mix/tasks/test.adoption.ex; test/scoria/runtime_integration_test.exs]

### Recommended Project Structure

```text
test/
├── mix/tasks/                              # existing installer + task contract tests
├── scoria/
│   ├── host_app_consumer_proof_test.exs    # new generated-host proof entrypoint
│   └── runtime_integration_test.exs        # existing deep runtime proof, keep authoritative
└── support/
    └── scoria/
        ├── host_app_proof/
        │   ├── generator.ex                # temp-dir generation + cleanup
        │   ├── overlay/                    # tiny template patch layer only
        │   └── runner.ex                   # deps/install/migrate/test shell orchestration
        ├── adoption_example.ex             # existing runtime proof constants
        └── migrations.ex                   # existing migration helpers
```

This structure keeps the generated-host harness small, test-only, and adjacent to existing adoption/runtime helpers instead of creating a second sample application tree. [VERIFIED: 48-CONTEXT.md; current `test/support/scoria` layout] [ASSUMED]

### Pattern 1: Generated-host overlay harness

**What:** Generate a fresh Phoenix app into a temp directory, then apply only the minimal Scoria-specific files needed to prove dependency wiring, install, migrate, and one runtime smoke. [VERIFIED: 48-CONTEXT.md; mix help phx.new]

**When to use:** Use for PROOF-01 and PROOF-02, because the requirement is about a fresh consumer app, not about repo-local synthetic files. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```elixir
# Source: 48-CONTEXT.md + mix help phx.new
System.cmd("mix", [
  "phx.new",
  host_dir,
  "--no-install",
  "--no-agents-md",
  "--database",
  "postgres"
])

overlay_scoria_patch!(host_dir)
run_in_host!(host_dir, ["mix", "deps.get"])
run_in_host!(host_dir, ["mix", "scoria.install"])
run_in_host!(host_dir, ["mix", "ecto.migrate"])
run_in_host!(host_dir, ["mix", "test", "test/scoria_adoption_smoke_test.exs"])
```

### Pattern 2: Layered verifier, single public command

**What:** Keep `mix test.adoption` as the single named default-lane verification command, but extend its file list with the generated-host proof file instead of folding everything into one giant test. [VERIFIED: lib/mix/tasks/test.adoption.ex; 48-CONTEXT.md]

**When to use:** Use whenever a new default-lane assertion belongs to the adopter story and should be discoverable by maintainers and adopters. [VERIFIED: docs/adoption_lanes.md; docs/operator_verification.md]

**Example:**
```elixir
# Source: lib/mix/tasks/test.adoption.ex
@adoption_test_files [
  "test/mix/tasks/scoria.install_test.exs",
  "test/mix/tasks/scoria.install_route_smoke_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs",
  "test/scoria/runtime_integration_test.exs",
  "test/scoria/host_app_consumer_proof_test.exs"
]
```

### Pattern 3: Explicit install inventory output

**What:** Replace the current mostly free-form next-steps text with three explicit sections: installed, skipped intentionally, optional later lanes. [VERIFIED: lib/mix/tasks/scoria.install.ex; 48-CONTEXT.md]

**When to use:** Use on every successful `mix scoria.install` run so the installer itself tells the truth about Tailwind, semantic fast path, and knowledge prerequisites. [VERIFIED: 48-CONTEXT.md; .planning/REQUIREMENTS.md]

**Example:**
```text
Installed:
  - router import + /scoria dashboard mount
  - copied core migrations
  - baseline Scoria.Runtime defaults

Skipped intentionally:
  - Tailwind content source injection (no Tailwind config found; default lane still installable)

Optional later lanes:
  - semantic fast path: mix test.semantic_fast_path
  - knowledge lane: mix scoria.pgvector.bootstrap && mix scoria.test.knowledge
```

### Anti-Patterns to Avoid

- **Checked-in demo host app:** It violates the locked generated-host direction and creates drift-heavy maintenance work. [VERIFIED: 48-CONTEXT.md]
- **Deep runtime duplication inside the host harness:** PROOF-02 only needs one bounded durable-run smoke; same-session/resume semantics already belong to `test/scoria/runtime_integration_test.exs`. [VERIFIED: 48-CONTEXT.md; test/scoria/runtime_integration_test.exs]
- **Assuming Tailwind config exists in a fresh Phoenix host:** Fresh Phoenix `1.8.7` generation did not create `tailwind.config.js`, so a missing Tailwind config is the normal baseline. [VERIFIED: /tmp/scoria_phase48_default via `mix phx.new`; /tmp/scoria_phase48_default/AGENTS.md]
- **Silent mutation failure on nonstandard layouts:** The current installer errors only when no router is found and otherwise writes files even if no regex replacement happened, which can create misleading success output. [VERIFIED: lib/mix/tasks/scoria.install.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fresh Phoenix host fixture | A permanent sample app in-repo | `mix phx.new` at test time plus a tiny overlay | The official generator is the real adopter baseline and already showed layout details that differ from assumptions, including no default `tailwind.config.js`. [VERIFIED: mix help phx.new; /tmp/scoria_phase48_default via `mix phx.new`] |
| Runtime semantics proof | A second custom runtime simulator inside the harness | Existing `test/scoria/runtime_integration_test.exs` plus one host smoke | The repo already proves run creation, readback, resume, and operator evidence; duplicating it raises drift risk. [VERIFIED: test/scoria/runtime_integration_test.exs; 48-CONTEXT.md] |
| Migration contract abstraction | Library-owned migration runner for the host app | Copied host migrations + `mix ecto.migrate` | D-04 keeps host-owned copied migrations as the default-lane posture. [VERIFIED: 48-CONTEXT.md] |
| New proof command | Another public verifier name | `mix test.adoption` | Lane naming is already present and documented; splitting the default proof would dilute support truth. [VERIFIED: lib/mix/tasks/test.adoption.ex; docs/adoption_lanes.md; docs/operator_verification.md] |

**Key insight:** The phase gap is reality-proofing the host boundary, not inventing new runtime or installer infrastructure. [VERIFIED: .planning/ROADMAP.md; 48-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Tailwind as part of the fresh-host happy path

**What goes wrong:** Planning assumes the generator will create a Tailwind config, so the harness or installer expects content-glob mutation to happen on a brand-new host. [VERIFIED: current installer path search in lib/mix/tasks/scoria.install.ex]

**Why it happens:** The installer still looks for `assets/tailwind.config.js` or `tailwind.config.js`, but a Phoenix `1.8.7` app generated locally had neither file and shipped an `AGENTS.md` note that Tailwind v4 no longer needs a `tailwind.config.js`. [VERIFIED: lib/mix/tasks/scoria.install.ex; /tmp/scoria_phase48_default via `mix phx.new`; /tmp/scoria_phase48_default/AGENTS.md]

**How to avoid:** Make missing Tailwind the expected fresh-host baseline and assert explicit skip messaging rather than attempting to force a Tailwind patch in the consumer proof. [VERIFIED: 48-CONTEXT.md; .planning/REQUIREMENTS.md]

**Warning signs:** The harness creates or expects a Tailwind config solely to make the installer "pass." [ASSUMED]

### Pitfall 2: Reporting installer success when a regex patch did not actually land

**What goes wrong:** The task can print success even if the router shape did not match the replacement regex or if the runtime config already contains adjacent but not identical Scoria config. [VERIFIED: lib/mix/tasks/scoria.install.ex]

**Why it happens:** `inject_router/1` and `maybe_inject_tailwind/1` do plain string/regex replacement and do not emit structured mutation results. [VERIFIED: lib/mix/tasks/scoria.install.ex]

**How to avoid:** Return mutation outcomes for each target file and fail or warn explicitly when a required patch could not be applied. [VERIFIED: 48-CONTEXT.md] [ASSUMED]

**Warning signs:** Installer output says "installed" but the host router still lacks `import ScoriaWeb.Router` or `scoria_dashboard "/scoria"`. [VERIFIED: lib/mix/tasks/scoria.install.ex; test/mix/tasks/scoria.install_test.exs]

### Pitfall 3: Duplicating deep runtime behavior in the generated host

**What goes wrong:** The host harness turns into a second runtime integration suite and becomes expensive and brittle. [VERIFIED: 48-CONTEXT.md]

**Why it happens:** PROOF-02 can tempt implementers to restate same-session semantics, approval resume, and policy metadata checks already covered elsewhere. [VERIFIED: test/scoria/runtime_integration_test.exs; 48-CONTEXT.md]

**How to avoid:** In the generated host, prove only one durable run, one readback, and one operator-evidence page. Keep the rest in existing repo-local runtime tests. [VERIFIED: 48-CONTEXT.md; test/scoria/runtime_integration_test.exs]

**Warning signs:** New host-proof files assert `next_run.session_id == started.session_id`, approval resume loops, or policy snapshot details already asserted in `runtime_integration_test`. [VERIFIED: test/scoria/runtime_integration_test.exs]

### Pitfall 4: DB-port drift between compile time and runtime

**What goes wrong:** Targeted tests fail before assertions because the repo was compiled against one `SCORIA_DB_PORT` but is run against another. [VERIFIED: targeted `mix test` run on 2026-05-25]

**Why it happens:** `config/test.exs` defaults to `5432`, but this checkout had compile-time repo config at `55432`, and no server was listening on `55432` in the environment probe. [VERIFIED: config/test.exs; targeted `mix test` failure on 2026-05-25; `pg_isready -p 55432`]

**How to avoid:** Normalize phase validation commands on `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}"` plus `mix do clean, ...` for repo-local tests, and isolate the generated host with its own explicit DB settings. [VERIFIED: local postgres probe on `5432`; 48-VALIDATION.md] [ASSUMED]

**Warning signs:** `Mix` raises `validate_compile_env` repo mismatch before any ExUnit tests run. [VERIFIED: targeted `mix test` failure on 2026-05-25]

## Code Examples

Verified patterns from official or repo sources:

### Router mutation target

```elixir
# Source: lib/mix/tasks/scoria.install.ex
if content =~ "scoria_dashboard" do
  content
else
  Regex.replace(
    ~r/(scope\s+"\/".*?do\s+.*?pipe_through(?:\s+|\()\:browser\)?\n)/s,
    content,
    "\\1    scoria_dashboard \"/scoria\"\n"
  )
end
```

This is the current mutation seam Phase 48 must harden. [VERIFIED: lib/mix/tasks/scoria.install.ex]

### Existing route smoke style

```elixir
# Source: test/mix/tasks/scoria.install_route_smoke_test.exs
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
Code.compile_string(File.read!(router_path))

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug
```

Use the same route-info style in the generated-host proof after the host compiles. [VERIFIED: test/mix/tasks/scoria.install_route_smoke_test.exs]

### Existing runtime smoke style worth reusing

```elixir
# Source: test/scoria/runtime_integration_test.exs
{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

{:ok, summary} = Scoria.get_run(started.run_id)
{:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))
```

The generated-host proof should stop near this depth, not beyond it. [VERIFIED: test/scoria/runtime_integration_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trust repo-local synthetic install/runtime tests alone | Add a generated fresh-Phoenix host proof on top of repo-local tests | Phase 48 contract defined `2026-05-25` [VERIFIED: 48-CONTEXT.md; .planning/ROADMAP.md] | Closes the adopter reality gap without replacing existing deep runtime proof. [VERIFIED: 48-CONTEXT.md] |
| Assume Phoenix assets imply a patchable `tailwind.config.js` | Phoenix `1.8.7` generator no longer creates `tailwind.config.js` by default, and its generated guidance says Tailwind v4 does not need one | `phx_new 1.8.7` released `2026-05-06` and probed locally `2026-05-25` [VERIFIED: mix hex.info phx_new; /tmp/scoria_phase48_default/AGENTS.md; /tmp/scoria_phase48_default via `mix phx.new`] | Tailwind absence is part of the normal default-lane adoption baseline now. [VERIFIED: local generator probe] |
| Broad suite as the only support answer | Named lane tasks (`mix test.adoption`, `mix test.semantic_fast_path`, `mix scoria.test.knowledge`) | Current repo state on `2026-05-25` [VERIFIED: lib/mix/tasks/test.adoption.ex; docs/operator_verification.md; docs/adoption_lanes.md] | Default-lane work should extend the existing named verifier rather than invent a new public command. [VERIFIED: lib/mix/tasks/test.adoption.ex; 48-CONTEXT.md] |

**Deprecated/outdated:**

- Fresh-host planning that treats Tailwind config mutation as mandatory for success is outdated against the current Phoenix generator baseline. [VERIFIED: /tmp/scoria_phase48_default via `mix phx.new`; /tmp/scoria_phase48_default/AGENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The generated-host harness inside this repo should use a local deterministic dependency source rather than a network Git/Hex fetch, because Phase 48's gap is host-install/runtime truth rather than release transport. | Summary / Architecture Patterns | If wrong, the proof may miss a package-distribution-specific failure mode and require a separate networked acceptance lane. |
| A2 | No new harness dependency is needed beyond Phoenix/Mix/ExUnit primitives already present. | Standard Stack | If wrong, implementation may burn time re-creating orchestration helpers that a small library would have provided safely. |
| A3 | Generated-host support code should live under `test/support/scoria/host_app_proof/` rather than a phase-local script directory. | Recommended Project Structure | If wrong, the final file layout may not fit the repo's preferred long-term maintenance shape. |

## Open Questions (RESOLVED)

1. **Should the generated-host proof exercise a local path dependency or a networked package source?**
   - Decision: use a deterministic local `path:` dependency back to the repo root for Phase 48's generated-host harness. [RESOLVED 2026-05-25]
   - Why: Phase 47 already owns publish/package transport truth through `mix scoria.release_preview`, while Phase 48's contract is host-install/runtime realism from a fresh Phoenix app. A local path dependency removes network flake and keeps the proof focused on installer, migration, route, and runtime truth. [VERIFIED: README.md; .planning/ROADMAP.md; 48-CONTEXT.md]
   - Follow-up boundary: if Scoria later needs a transport-realism acceptance lane for tagged GitHub or Hex fetches, that should be added as a separate proof concern instead of widening the default-lane host harness in this phase. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, ExUnit, generated-host proof | ✓ | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Installer and verifier commands | ✓ | `1.19.5` [VERIFIED: mix --version] | — |
| `phx_new` archive | Fresh Phoenix host generation | ✓ | `1.8.7` [VERIFIED: mix help phx.new; mix hex.info phx_new] | None; planner must keep generation strategy tied to `phx_new` availability. |
| Node.js | Phoenix host asset/deps setup if the harness ever runs full host tests | ✓ | `v22.14.0` [VERIFIED: node --version] | For a bounded server-side proof, keep asset compilation out of scope if not needed. [ASSUMED] |
| npm | Phoenix asset tooling if needed | ✓ | `11.1.0` [VERIFIED: npm --version] | Same as above. [ASSUMED] |
| PostgreSQL CLI | DB preflight and host app migration proof | ✓ | `14.17` [VERIFIED: psql --version] | — |
| Local PostgreSQL on `5432` | Fresh host default DB path | ✓ | accepting connections [VERIFIED: pg_isready] | — |
| Local PostgreSQL on `55432` | Previous repo-compiled targeted test lane | ✗ | no response [VERIFIED: pg_isready -p 55432] | Phase 48 verification should stop assuming this port and should instead compile/test against the available local port on `5432` unless the operator explicitly overrides it. [VERIFIED: targeted `mix test` failure and rerun] |

**Missing dependencies with no fallback:**

- None for planning the phase itself. [VERIFIED: environment probe on 2026-05-25]

**Missing dependencies with fallback:**

- PostgreSQL on `55432` is missing locally. Phase 48 verification should normalize on `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}"` and clean/recompile inside verification commands so the documented lane is executable in the observed environment. [VERIFIED: targeted `mix test` failure and `--trace` rerun; pg probes] [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs; elixir --version] |
| Config file | none; repo uses `test/test_helper.exs` and env-specific Mix config. [VERIFIED: test/test_helper.exs; config/test.exs] |
| Quick run command | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/mix/tasks/test.adoption_test.exs --trace` [VERIFIED: 48-VALIDATION.md] |
| Full suite command | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test.adoption` after the new generated-host proof is added. [VERIFIED: lib/mix/tasks/test.adoption.ex; 48-VALIDATION.md] [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INST-01 | Installer mounts `/scoria`, copies migrations, injects runtime defaults once, and avoids duplicates. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` [VERIFIED: 48-VALIDATION.md] | ✅ |
| INST-02 | Installer succeeds without Tailwind or optional knowledge prerequisites and reports skip/optional truth. [VERIFIED: .planning/REQUIREMENTS.md] | unit/source | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/mix/tasks/scoria.install_test.exs test/scoria/adoption_surface_test.exs` [VERIFIED: 48-VALIDATION.md] | ✅, but messaging assertions are incomplete. [VERIFIED: test/mix/tasks/scoria.install_test.exs; test/scoria/adoption_surface_test.exs] |
| PROOF-01 | Fresh generated Phoenix host proves `deps.get`, install, migrate, and route visibility. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/scoria/host_app_consumer_proof_test.exs --trace` [VERIFIED: 48-VALIDATION.md] | Created by Task 48-02-01 |
| PROOF-02 | Same host proof starts one durable run, reads it back, and inspects operator evidence without optional lanes. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix do clean, test test/scoria/host_app_consumer_proof_test.exs test/scoria/runtime_integration_test.exs --trace` [VERIFIED: 48-VALIDATION.md] | Extended by Task 48-03-01; `runtime_integration_test.exs` already exists. [VERIFIED: test/scoria/runtime_integration_test.exs] |

### Sampling Rate

- **Per task commit:** Run the focused installer/runtime subset plus the generated-host proof once it exists. [VERIFIED: current test seams and roadmap requirements] [ASSUMED]
- **Per wave merge:** Run `mix test.adoption` with the required DB env exported. [VERIFIED: lib/mix/tasks/test.adoption.ex] [ASSUMED]
- **Phase gate:** `mix test.adoption` green, with the generated-host proof included and installer output assertions covering installed/skipped/optional truth. [VERIFIED: 48-CONTEXT.md; .planning/ROADMAP.md] [ASSUMED]

### Producer Gaps Closed

- [x] `test/scoria/host_app_consumer_proof_test.exs` is planned as a direct Task 48-02-01 output covering PROOF-01 and the host-owned slice of PROOF-02. [VERIFIED: 48-02-PLAN.md; 48-VALIDATION.md]
- [x] `test/support/scoria/host_app_proof/generator.ex` is planned as a direct Task 48-02-01 output for temp-app generation, overlay, cleanup, and shell orchestration. [VERIFIED: 48-02-PLAN.md]
- [x] Installer output assertions for installed/skipped/optional inventory are owned by Plan 48-01. [VERIFIED: 48-01-PLAN.md]
- [x] DB-port expectations are normalized in the phase validation commands so compile-time/runtime mismatch does not masquerade as a Phase 48 failure. [VERIFIED: 48-VALIDATION.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope and current installer/runtime proof files] | Host app continues to own auth; this phase only mounts routes and proves visibility. [VERIFIED: README.md; docs/operator_verification.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Existing runtime tests already prove `session_id` continuity semantics; Phase 48 does not introduce a new session layer. [VERIFIED: test/scoria/runtime_integration_test.exs] |
| V4 Access Control | no [VERIFIED: phase scope] | No new authorization surface is introduced beyond the existing mounted dashboard proof. [VERIFIED: .planning/ROADMAP.md; 48-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: installer mutates host files based on discovered paths] | Constrain router/config/Tailwind path discovery and report failed mutations explicitly. [VERIFIED: lib/mix/tasks/scoria.install.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | Installer should not inject secrets or new crypto primitives. [VERIFIED: lib/mix/tasks/scoria.install.ex] |

### Known Threat Patterns for Phoenix installer + generated-host proof

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-file mutation from overly broad path or regex matching | Tampering | Restrict path discovery, assert expected replacements occurred, and deny with manual guidance when host layout is unsupported. [VERIFIED: lib/mix/tasks/scoria.install.ex] [ASSUMED] |
| Silent partial install that claims success | Repudiation | Emit per-target mutation results and keep assertions around router/config/migrations/output inventory. [VERIFIED: current installer output and tests] [ASSUMED] |
| Temp harness leaking host state into repo or developer machine | Information Disclosure / Tampering | Use temp directories, unique DB names, and cleanup on exit. [VERIFIED: current installer tests clean temp dirs] [ASSUMED] |
| Optional-lane confusion causing adopters to enable extra surfaces unnecessarily | Spoofing / Misconfiguration | Keep Tailwind, semantic fast path, and knowledge lane explicitly labeled as skipped or optional. [VERIFIED: 48-CONTEXT.md; docs/adoption_lanes.md] |

## Sources

### Primary (HIGH confidence)

- `lib/mix/tasks/scoria.install.ex` - current installer path discovery, mutation behavior, and output contract.
- `lib/mix/tasks/test.adoption.ex` - current canonical default-lane verifier.
- `test/mix/tasks/scoria.install_test.exs` - current installer idempotency and no-config/no-tailwind coverage.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - current route-resolution proof seam.
- `test/scoria/runtime_integration_test.exs` - current runtime/operator-evidence proof seam.
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - current default-vs-knowledge migration boundary proof.
- `.planning/phases/48-host-app-install-contract-and-consumer-proof/48-CONTEXT.md` - locked decisions and recommended proof shape.
- `.planning/REQUIREMENTS.md` - authoritative wording for INST-01, INST-02, PROOF-01, PROOF-02.
- `mix help phx.new` - official local generator options and Phoenix generator location.
- `mix hex.info phx_new`, `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql` - current package versions and release dates.
- Local `mix phx.new` probes in `/tmp/scoria_phase48_default` and `/tmp/scoria_phase48_no_tailwind` - actual fresh-host layout on Phoenix `1.8.7`.
- `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, `docs/phoenix_runtime_example.md` - current adopter-facing lane and verification contract.

### Secondary (MEDIUM confidence)

- `/tmp/scoria_phase48_default/AGENTS.md` - generated Phoenix guidance noting Tailwind v4 no longer requires `tailwind.config.js`.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and generator behavior were verified locally through `mix lock`/`mix hex.info` and fresh `mix phx.new` probes.
- Architecture: HIGH - the phase contract, existing test seams, and generated-host layout all point to the same bounded overlay strategy, with only dependency-source choice left as an assumption.
- Pitfalls: HIGH - the biggest risks were reproduced directly: missing default Tailwind config, regex-only installer mutation, and DB compile/runtime port mismatch.

**Research date:** 2026-05-25
**Valid until:** 2026-06-24

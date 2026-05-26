# Phase 51: Default-lane verifier hardening and support-truth re-closeout - Research

**Researched:** 2026-05-26 [VERIFIED: local run 2026-05-26]
**Domain:** Elixir/Phoenix verifier hardening, generated-host proof orchestration, and support-truth closeout. [VERIFIED: .planning/ROADMAP.md; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: local run 2026-05-26; .planning/v2.2-MILESTONE-AUDIT.md]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Timeout contract
- **D-01:** `mix test.adoption` remains the single canonical default-lane verifier. Scoria should not hide the generated-host proof behind a second public command or a maintainer-only verifier.
- **D-02:** The current implicit ExUnit default timeout is false for the generated-host proof. Phase 51 should replace that accidental contract with an explicit scoped timeout budget for the fresh-host proof itself, while leaving the rest of the suite on normal defaults.
- **D-03:** The published budget should be honest and boring rather than aspirational. Downstream planning should assume a narrow verifier-specific budget on the order of minutes, not the default `60_000ms`, unless implementation work proves a shorter real budget with margin.
- **D-04:** `mix test.adoption --trace` is a debugging tool, not part of the support contract. Phase 51 proof and docs must use the non-trace command path only.

### Fresh-host proof strictness
- **D-05:** The fresh generated-host proof stays inside `mix test.adoption`. Phase 51 must preserve real proof that a fresh Phoenix host can adopt Scoria through the public install and runtime path.
- **D-06:** Scoria may accelerate the verifier only by reducing duplicated harness cost, not by downgrading the proof to a checked-in sample app, a purely synthetic fixture, or a hidden warm post-install host.
- **D-07:** The generated-host proof should collapse to the smallest honest host-side assertion set:
  current dependency wiring,
  `mix scoria.install`,
  `mix ecto.create`,
  `mix ecto.migrate`,
  `/scoria` route visibility,
  and one durable run/readback/operator-evidence smoke.
- **D-08:** Deeper runtime semantics should remain owned by repo-local adoption/runtime tests instead of being redundantly reproven inside multiple expensive host-side boots.
- **D-09:** A cached pristine Phoenix skeleton is acceptable only as a fail-closed implementation detail if each verifier run still copies it into a fresh workspace, reapplies the current Scoria overlay, reruns the public commands, and invalidates on generator-relevant drift. Cached post-install or post-migrate hosts are not acceptable.

### Phase 49 re-closeout evidence bar
- **D-10:** Re-closing Phase 49 should stay bounded to the already-locked maintainer proof chain:
  `mix scoria.release_preview`
  `mix test.adoption`
- **D-11:** `49-VERIFICATION.md` should not be a prose-only summary. It must explicitly map what the two commands machine-check and cite the source-truth seams that keep README, installer output, and verification guides aligned.
- **D-12:** `49-VERIFICATION.md` should state clearly that `mix test.semantic_fast_path`, `mix test.knowledge`, and `mix test` are not part of the canonical Phase 49 closeout proof.
- **D-13:** Phase 51 should prefer a command-plus-source-truth evidence bar over either extreme:
  not command-only with vague claims,
  and not a broadened “run everything” repo-health sweep.

### Ecosystem posture and DX
- **D-14:** Scoria should stay aligned with idiomatic Phoenix/Elixir library ergonomics: explicit installer/task seams, bounded verification commands, Ecto-backed durable truth, and explicit optional-lane expansion rather than magical sample-app demos.
- **D-15:** Principle of least surprise wins over aggressive speed claims. A real 2-3 minute canonical verifier is preferable to a “fast” verifier that silently depends on hidden caches or no longer proves fresh-host adoption.
- **D-16:** Future optimization work should treat the current host harness like a field proof, not a benchmark target. Cheap structural wins are encouraged; weakening the product claim is not.

### the agent's Discretion
- Exact verifier timeout value and whether it is applied per-test or per-module, as long as the budget is explicit, scoped, and reflected truthfully in docs and verification artifacts.
- Exact host-harness restructuring technique, as long as it preserves one fresh-host proof inside `mix test.adoption` and reduces duplicated host-side boot cost.
- Exact structure of `49-VERIFICATION.md`, as long as it cites the command proof and the source-truth seams that enforce `DOCS-01` and `DOCS-02`.
- Exact implementation of any pristine-host caching optimization, provided it fails closed on drift and never reuses a patched or migrated host as proof.

### Deferred Ideas (OUT OF SCOPE)
- Replacing the fresh generated-host proof with a checked-in sample app or long-lived fixture.
- Introducing a second public verifier to hide or bypass the slow host proof.
- Treating hidden warm caches, prepatched hosts, or `--trace`-only success as acceptable default-lane proof.
- Folding semantic or knowledge verification into the default-lane or Phase 49 closeout chain.
- Broader repo-health closure based on `mix test` instead of the bounded milestone proof chain.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | README, operator verification, and installer output describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast-path, and optional knowledge surfaces. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `README.md`, `docs/operator_verification.md`, and `lib/mix/tasks/scoria.install.ex` as the public truth surfaces; keep `test/scoria/adoption_surface_test.exs` and `test/mix/tasks/scoria.install_test.exs` as drift guards; rerun `mix test.adoption` only after the host-proof timeout and duplication seams are repaired. [VERIFIED: README.md; docs/operator_verification.md; lib/mix/tasks/scoria.install.ex; test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs; local run 2026-05-26] |
| DOCS-02 | Scoria names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing. [VERIFIED: .planning/REQUIREMENTS.md] | Preserve `mix test.adoption` as the only default-lane verifier, leave semantic/knowledge as separate lanes, and make `49-VERIFICATION.md` explicitly exclude `mix test.semantic_fast_path`, `mix test.knowledge`, and `mix test`. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; docs/operator_verification.md; test/mix/tasks/test.adoption_test.exs; test/mix/tasks/test.semantic_fast_path_test.exs] |
</phase_requirements>

## Summary

The Phase 49 wording work is largely already in place: `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, installer output, and `test/scoria/adoption_surface_test.exs` already agree that the default lane is `mix scoria.install -> mix ecto.migrate -> mix test.adoption`, while semantic and knowledge remain separate follow-on lanes. [VERIFIED: README.md:165-192; docs/adoption_lanes.md:33-117; docs/operator_verification.md:17-25,151-165; lib/mix/tasks/scoria.install.ex:200-223; test/scoria/adoption_surface_test.exs:150-186]

The live blocker is operational truth, not copy drift: `mix test.adoption` currently wraps the generated-host proof inside a normal ExUnit run with the default 60_000 ms timeout, and the current host harness shells out through repeated host-side `mix` invocations. A local run on 2026-05-26 reproduced the exact audit failure: `MIX_ENV=test mix test.adoption` failed after `67.6 seconds` with `ExUnit.TimeoutError` in `Scoria.HostAppConsumerProofTest`, and the isolated host-proof test also took `96.1 seconds` before failing inside host `mix ecto.create`. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/host_app_consumer_proof_test.exs; test/support/scoria/host_app_proof/runner.ex; .planning/v2.2-MILESTONE-AUDIT.md:136-142; local run 2026-05-26]

Phase 51 should therefore do three things in one bounded pass: give the generated-host proof an explicit scoped timeout budget, collapse duplicate host-side Mix boot cost without hiding any public proof step, and then write `49-VERIFICATION.md` from fresh reruns of `mix scoria.release_preview` and repaired non-trace `mix test.adoption`, with explicit source-of-truth mapping back to README, installer output, operator docs, and adoption-surface assertions. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; docs/operator_verification.md:153-165; test/scoria/adoption_surface_test.exs; .planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md]

**Primary recommendation:** Keep `mix test.adoption` as the only public verifier, apply an explicit host-proof-only ExUnit timeout, reduce host cost by batching host-side proof work into fewer `mix` boots on a fresh copied skeleton, and make `49-VERIFICATION.md` a command-to-truth ledger rather than a prose recap. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/runner.ex; local run 2026-05-26]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical verifier orchestration (`mix test.adoption`) | API / Backend | Database / Storage | The command is a Mix task that selects the bounded test file set and exits on verifier truth; it is not a browser concern, but several selected tests prove database-backed runtime state. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; test/scoria/runtime_integration_test.exs] |
| Fresh Phoenix host generation and overlay | API / Backend | — | The host proof is created entirely in test support via `mix phx.new`, file patching, overlay copy, and `System.cmd/3` orchestration. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; test/support/scoria/host_app_proof/runner.ex; mix help phx.new] |
| Durable run/readback/operator-evidence smoke | Frontend Server (SSR) | API / Backend | The smoke uses the public runtime facade plus a LiveView route at `/scoria/workflows/:run_id`; route rendering is SSR/LiveView, while the run itself is backend-owned durable state. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs; test/scoria/runtime_integration_test.exs; mix.lock] |
| Public lane wording and closeout truth | CDN / Static | API / Backend | README/docs are static truth surfaces, but their validity is enforced by repo-side ExUnit assertions and task output tests. [VERIFIED: README.md; docs/operator_verification.md; lib/mix/tasks/scoria.install.ex; test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir + ExUnit | `1.19.5` local runtime; ExUnit started from `test/test_helper.exs`. [VERIFIED: elixir --version; mix --version; test/test_helper.exs] | Owns the scoped timeout contract and the repo’s test harness. [VERIFIED: test/test_helper.exs; local run 2026-05-26] | Phase 51 does not need a new harness framework because the failure is already visible as a normal ExUnit timeout and ExUnit supports per-test/per-module timeout overrides directly. [VERIFIED: local run 2026-05-26; CITED: https://hexdocs.pm/elixir/ExUnit.Case.html; CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Phoenix | `1.8.7`, released `2026-05-06`. [VERIFIED: mix.lock; mix hex.info phoenix] | Provides the generated host skeleton and router metadata proof surface. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs] | The current proof already depends on `mix phx.new` and `Phoenix.Router.route_info/4`, so the honest optimization path is to keep Phoenix as the host-proof substrate rather than replacing it with a fixture. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; mix help phx.new; test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs] |
| Phoenix LiveView | `1.1.30`, released `2026-05-05`. [VERIFIED: mix.lock; mix hex.info phoenix_live_view] | Owns the `/scoria` and `/scoria/workflows/:run_id` operator-evidence path exercised by the host smoke. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs; test/scoria/runtime_integration_test.exs] | The host smoke should keep one LiveView/operator-evidence assertion because Phase 51 must still prove a real operator surface, not only route metadata. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |
| Ecto SQL + Postgrex | `ecto_sql 3.13.5` released `2026-03-03`; `postgrex 0.22.1` released `2026-05-05`. [VERIFIED: mix.lock; mix hex.info ecto_sql; mix hex.info postgrex] | Own the host proof’s `mix ecto.create`/`mix ecto.migrate` steps and the durable runtime state Scoria reads back. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; test/support/scoria/host_app_proof/generator.ex; test/scoria/runtime_integration_test.exs] | Phase 51 must preserve these explicit DB-backed steps because D-07 requires real install/create/migrate/run proof, not a memory-only smoke. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/runner.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phx_new` | `1.8.7`, released `2026-05-06`. [VERIFIED: mix hex.info phx_new] | Generates the pristine Phoenix skeleton used for the fresh-host proof. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; mix help phx.new] | Use as the freshness anchor; if Phase 51 adds caching, cache only a pristine generated skeleton and always copy it into a fresh temp workspace before overlay and public commands. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/generator.ex] |
| Custom Mix task wrappers | Existing repo tasks only. [VERIFIED: mix.exs; lib/mix/tasks/test.adoption.ex; lib/mix/tasks/scoria.install.ex] | Define public lane boundaries and task discoverability contracts. [VERIFIED: test/mix/tasks/test.adoption_test.exs; test/mix/tasks/scoria.install_test.exs] | Use whenever support truth must stay executable; the planner should avoid inventing new public task names for this phase. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/mix/tasks/test.adoption_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scoped timeout on `Scoria.HostAppConsumerProofTest` | Global `mix test --timeout ...` or `ExUnit.start(timeout: ...)` | Global timeout changes would widen the contract for unrelated tests, while D-02 explicitly wants the fresh-host proof budget scoped to the proof itself. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/test_helper.exs; CITED: https://hexdocs.pm/elixir/ExUnit.Case.html; CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Fresh copied pristine skeleton | Checked-in sample app or cached patched/migrated host | A checked-in or prepatched host weakens the freshness claim that D-05 through D-09 preserve. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/generator.ex] |
| Fewer host `mix` boots with the same public steps | Second public verifier or trace-only support story | A new public verifier or `--trace`-only success would violate D-01 and D-04 even if it is faster. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |

**Installation:** No new Hex dependencies are required for Phase 51; the work stays inside the existing test support, docs, and Mix-task stack. [VERIFIED: mix.exs; mix deps.tree]

```bash
mix deps.get
mix compile
```

**Version verification:** `mix.lock`, `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql`, `mix hex.info postgrex`, and `mix hex.info phx_new` were checked on 2026-05-26. [VERIFIED: local run 2026-05-26]

## Architecture Patterns

### System Architecture Diagram

```text
mix scoria.release_preview
        |
        v
package/docs truth --------------------------------------+
                                                         |
mix test.adoption                                        |
        |                                                |
        v                                                |
Mix.Tasks.Scoria.Test.Adoption                           |
        |                                                |
        +--> repo-local docs/task guards ----------------+--> 49-VERIFICATION.md command map
        |     - test/scoria/adoption_surface_test.exs
        |     - test/mix/tasks/test.adoption_test.exs
        |     - test/mix/tasks/scoria.install_test.exs
        |
        +--> repo-local runtime/migration tests
        |     - runtime_integration_test
        |     - runtime_test
        |     - migration_lane_compatibility_test
        |
        +--> generated-host proof
              |
              v
         mix phx.new pristine host
              |
              v
         patch mix/config + copy overlay
              |
              v
         host public commands
         deps.get -> scoria.install -> ecto.create -> ecto.migrate
              |
              v
         host smoke assertions
         route_info -> durable run/readback -> LiveView operator evidence
```

Diagram reflects the current verifier/task layout and the required re-closeout flow. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/support/scoria/host_app_proof/generator.ex; test/support/scoria/host_app_proof/runner.ex; test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs; test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs; .planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md]

### Recommended Project Structure

```text
lib/mix/tasks/                     # Public verifier and installer task seams
test/scoria/                       # Repo-local adoption/runtime/source-truth assertions
test/support/scoria/host_app_proof # Fresh-host generator, runner, and host overlay
docs/                              # Public lane/verification truth surfaces
.planning/phases/49-*/             # Phase 49 plans/summaries/validation to re-close
```

The existing layout is already the right ownership split for Phase 51. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/scoria/host_app_consumer_proof_test.exs; test/support/scoria/host_app_proof; docs; .planning/phases/49-support-truth-and-adoption-closeout]

### Pattern 1: Scoped Host-Proof Timeout

**What:** Put the explicit timeout on `Scoria.HostAppConsumerProofTest` or its one slow test, not on the whole suite. [VERIFIED: test/scoria/host_app_consumer_proof_test.exs; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; CITED: https://hexdocs.pm/elixir/ExUnit.Case.html]

**When to use:** Use when the canonical lane must stay non-trace and truthful, but only one generated-host proof needs minutes instead of the ExUnit default `60_000`. [VERIFIED: local run 2026-05-26; .planning/v2.2-MILESTONE-AUDIT.md:136-142; CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]

**Example:**

```elixir
# Source: https://hexdocs.pm/elixir/ExUnit.Case.html + test/scoria/host_app_consumer_proof_test.exs
defmodule Scoria.HostAppConsumerProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  test "generated Phoenix host proves the bounded Scoria adoption path" do
    host = Generator.create_host!(cleanup: &on_exit/1)
    proof = Runner.run_full_proof!(host)
    assert proof.steps == [:deps_get, :scoria_install, :ecto_create, :ecto_migrate, :route_smoke, :runtime_smoke]
  end
end
```

The exact `180_000` value is a starting planning recommendation, not a verified final contract. [ASSUMED]

### Pattern 2: Collapse Duplicate Host-Side Mix Boots, Not Proof Scope

**What:** Keep the same fresh host and the same public proof steps, but reduce repeated host-side `mix` process startup where the current runner shells out once per step and once per smoke file. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; local run 2026-05-26]

**When to use:** Use whenever the planner touches `test/support/scoria/host_app_proof/runner.ex` or `generator.ex`; this is the main honest speed seam in the current verifier. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/runner.ex]

**Example:**

```elixir
# Source: test/support/scoria/host_app_proof/runner.ex + mix test file-arg behavior already used in the repo
def host_smoke!(host) do
  run_mix!(host, :host_smoke, ["test", host.route_smoke_test, host.runtime_smoke_test, "--trace"])
end
```

The key planning rule is that this is an internal batching optimization only; the proof still has to come from one fresh copied host after `mix scoria.install`, `mix ecto.create`, and `mix ecto.migrate`. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/runner.ex]

### Pattern 3: Source-Truth Seam Map for Re-closeout

**What:** Treat four files as the closeout truth chain and one test suite as the enforcement seam. [VERIFIED: README.md; docs/operator_verification.md; lib/mix/tasks/scoria.install.ex; test/scoria/adoption_surface_test.exs]

**When to use:** Use when drafting `49-VERIFICATION.md` and when deciding which files any Phase 51 plan must touch together. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; .planning/phases/49-support-truth-and-adoption-closeout/49-03-SUMMARY.md]

**Seam map:**

| Surface | Owns | Drift Guard |
|--------|------|-------------|
| `README.md` | First-adopter lane order and prerequisite boundaries. [VERIFIED: README.md:163-192] | `test/scoria/adoption_surface_test.exs` README assertions. [VERIFIED: test/scoria/adoption_surface_test.exs:14-46] |
| `docs/operator_verification.md` | Closeout chain and lane hierarchy. [VERIFIED: docs/operator_verification.md:17-25,134-165] | `test/scoria/adoption_surface_test.exs` operator-guide assertions. [VERIFIED: test/scoria/adoption_surface_test.exs:150-186] |
| `lib/mix/tasks/scoria.install.ex` | Installer CLI wording and optional-lane inventory. [VERIFIED: lib/mix/tasks/scoria.install.ex:20-25,200-223] | `test/mix/tasks/scoria.install_test.exs`. [VERIFIED: test/mix/tasks/scoria.install_test.exs:61-88] |
| `lib/mix/tasks/test.adoption.ex` | Canonical verifier file boundary. [VERIFIED: lib/mix/tasks/test.adoption.ex] | `test/mix/tasks/test.adoption_test.exs`. [VERIFIED: test/mix/tasks/test.adoption_test.exs] |

### Anti-Patterns to Avoid

- **Global timeout inflation:** Raising suite-wide timeout hides the real problem and violates the phase constraint that only the generated-host proof should receive a special budget. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; CITED: https://hexdocs.pm/elixir/ExUnit.Case.html]
- **Second public verifier:** A separate “slow adopter proof” task would weaken the support story and violate D-01. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
- **Warm host proof:** Reusing a patched or migrated host would make the proof green for the wrong reason. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
- **Trace-only success:** `mix test.adoption --trace` is a debugging escape hatch, not a supported closeout proof. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Host-proof timeout budgeting | Custom shell watchdog or second wrapper task | ExUnit `@tag timeout` / `@moduletag timeout` on the host proof. [CITED: https://hexdocs.pm/elixir/ExUnit.Case.html] | ExUnit already owns the failure mode being repaired and supports scoped budgets directly. [VERIFIED: local run 2026-05-26; CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Fresh-host realism | Checked-in sample app or hidden warm cache | `mix phx.new` pristine skeleton plus current overlay and current public commands. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; mix help phx.new] | The phase’s product claim is “fresh host can adopt Scoria now,” and only a fresh copied host preserves that claim. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |
| Support-truth verification | Manual doc review alone | `test/scoria/adoption_surface_test.exs`, `test/mix/tasks/scoria.install_test.exs`, and `test/mix/tasks/test.adoption_test.exs`. [VERIFIED: test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/test.adoption_test.exs] | The repo already has executable drift guards for the exact surfaces Phase 49 claimed to close. [VERIFIED: .planning/phases/49-support-truth-and-adoption-closeout/49-03-SUMMARY.md; .planning/phases/49-support-truth-and-adoption-closeout/49-02-SUMMARY.md] |
| Route/operator proof | Browser-level e2e suite | `Phoenix.Router.route_info/4` route smoke plus one LiveView runtime smoke. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs; test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs] | This keeps proof bounded while still covering both route visibility and real operator evidence. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs; test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs] |

**Key insight:** The verifier is already testing the right product claim; the phase should tighten timeout honesty and execution shape, not redesign the proof surface. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; lib/mix/tasks/test.adoption.ex; local run 2026-05-26]

## Common Pitfalls

### Pitfall 1: Publishing the ExUnit default as if it were the support budget

**What goes wrong:** `mix test.adoption` is advertised as canonical, but the fresh-host proof times out at `60_000ms` in non-trace mode. [VERIFIED: docs/operator_verification.md:21-35,153-165; local run 2026-05-26]
**Why it happens:** The host proof test currently has no scoped timeout tag, so it inherits the ExUnit default. [VERIFIED: test/scoria/host_app_consumer_proof_test.exs; test/test_helper.exs; local run 2026-05-26]
**How to avoid:** Put an explicit timeout on the host proof and publish the command budget truthfully in docs and verification artifacts. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; CITED: https://hexdocs.pm/elixir/ExUnit.Case.html]
**Warning signs:** The only green run is `mix test.adoption --trace` or a focused test with a longer timeout. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; .planning/v2.2-MILESTONE-AUDIT.md:136-142]

### Pitfall 2: Paying repeated host-side Mix startup cost

**What goes wrong:** The host proof spends most of its wall time inside nested host `mix` invocations rather than only on product behavior. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; local run 2026-05-26]
**Why it happens:** `Runner.run_full_proof!/1` calls `System.cmd("mix", ...)` separately for `deps.get`, `scoria.install`, `ecto.create`, `ecto.migrate`, route smoke, and runtime smoke. [VERIFIED: test/support/scoria/host_app_proof/runner.ex]
**How to avoid:** Batch compatible host-side steps where doing so does not hide the public proof sequence, especially the two smoke files. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
**Warning signs:** The proof logs multiple `HOST STEP ... mix ...` entries with long idle gaps between them. [VERIFIED: local run 2026-05-26]

### Pitfall 3: Mixing the semantic-lane environment story into the default-lane proof

**What goes wrong:** The repo currently has both `5432`-defaulted default-lane materials and `55432`-documented semantic-lane materials, which can confuse closeout evidence if the exact env is not written down. [VERIFIED: config/test.exs; lib/mix/tasks/scoria.install.ex; docs/semantic_fast_path.md; .planning/STATE.md; local run 2026-05-26]
**Why it happens:** The semantic lane explicitly documents `SCORIA_DB_PORT=55432`, while default-lane files and host harness defaults still assume `${SCORIA_DB_PORT:-5432}`. [VERIFIED: docs/semantic_fast_path.md:104-107; lib/mix/tasks/scoria.install.ex:20-25; test/support/scoria/host_app_proof/runner.ex:66-73; config/test.exs:3-13]
**How to avoid:** Make the exact supported env for the repaired `mix test.adoption` rerun explicit in `49-VERIFICATION.md` and keep semantic-lane env guidance scoped to `mix test.semantic_fast_path`. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; docs/operator_verification.md:38-50,153-165]
**Warning signs:** Proof commands only pass after ad hoc env overrides that are not captured in the verification artifact. [VERIFIED: local run 2026-05-26; .planning/v2.2-MILESTONE-AUDIT.md:136-142]

## Code Examples

Verified patterns from official sources and current repo seams:

### Scoped timeout on the one slow verifier

```elixir
# Source: https://hexdocs.pm/elixir/ExUnit.Case.html
defmodule Scoria.HostAppConsumerProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000
end
```

### Fresh host generator with explicit Phoenix options

```elixir
# Source: test/support/scoria/host_app_proof/generator.ex
run!(
  File.cwd!(),
  [
    "phx.new",
    host_root,
    "--app", app_name,
    "--module", @host_module,
    "--database", "postgres",
    "--no-assets",
    "--no-dashboard",
    "--no-mailer",
    "--no-gettext",
    "--no-install",
    "--no-agents-md"
  ]
)
```

### Source-truth task boundary

```elixir
# Source: lib/mix/tasks/test.adoption.ex
@adoption_test_files [
  "test/scoria/adoption_surface_test.exs",
  "test/scoria/runtime_integration_test.exs",
  "test/scoria/runtime_test.exs",
  "test/scoria/host_app_consumer_proof_test.exs",
  "test/mix/tasks/scoria.install_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit suite-wide default timeout for the host proof | Explicit scoped timeout on the generated-host proof. [CITED: https://hexdocs.pm/elixir/ExUnit.Case.html] | Phase 51 should introduce it now. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] | Keeps the canonical verifier honest without widening unrelated test budgets. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |
| Repeated host `mix` boots for each smoke file | Batched smoke execution on the same fresh host. [VERIFIED: test/support/scoria/host_app_proof/runner.ex] | Phase 51 opportunity. [VERIFIED: local run 2026-05-26] | Reduces duplicate cost while preserving the same public proof steps. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |
| Summary-only Phase 49 closeout | `49-VERIFICATION.md` with rerun commands, truth map, and explicit exclusions. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] | Required now. [VERIFIED: .planning/ROADMAP.md:120-133] | Turns support truth back into executable proof instead of claimed completion. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md:115-124,159-167] |

**Deprecated/outdated:**

- Treating `mix test.adoption --trace` as the support contract is outdated for this phase; the locked decision is explicit non-trace support truth. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
- Treating Phase 49 as complete from summaries alone is outdated because the milestone audit still marks `49-VERIFICATION.md` missing and DOCS requirements unsatisfied. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md:45-59,115-124]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `180_000ms` is a reasonable starting scoped timeout budget to plan around before final measurement on the repaired harness. [ASSUMED] | Architecture Patterns | Low-to-medium: the exact number may need adjustment after batching or env normalization, but the planner still needs to reserve “minutes, not 60s.” |

## Open Questions (RESOLVED)

1. **What exact env string should Phase 51 publish for the repaired non-trace `mix test.adoption` rerun?**
   - Resolved planning answer: the target published default-lane verifier remains plain `MIX_ENV=test mix test.adoption`, with the host harness continuing to default to `localhost:5432`, `postgres`, and `postgres` unless execution proves the canonical lane truly needs additional DB env. [VERIFIED: config/test.exs; test/support/scoria/host_app_proof/runner.ex; lib/mix/tasks/scoria.install.ex]
   - Execution rule: if the repaired verifier only passes with extra DB env such as `SCORIA_DB_PORT=55432` or explicit password overrides, that exact command line must be recorded verbatim in `49-VERIFICATION.md` and treated as support truth rather than hidden local state. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md:136-142; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
   - Planning consequence: Plan 51-03 should rerun the closeout chain starting from `MIX_ENV=test mix test.adoption`, then record any proven deviations explicitly in the verification artifact instead of widening README or installer guidance speculatively. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]

2. **How far should batching go inside the host runner?**
   - Resolved planning answer: the first batching cut should stop at combining the two host smoke files into one host-side `mix test ... --trace` invocation while leaving `deps.get`, `scoria.install`, `ecto.create`, and `ecto.migrate` as explicit separate proof steps. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]
   - Reason: this removes the clearest duplicate Mix boot without hiding the public proof sequence or weakening the fresh-host claim. Larger batching such as `mix do ...` across install/create/migrate is intentionally deferred until measurements prove the smaller change is insufficient. [VERIFIED: test/support/scoria/host_app_proof/runner.ex; local run 2026-05-26]
   - Planning consequence: Plan 51-01 should preserve step visibility in returned proof data, keep the host fresh for every run, and treat pristine-skeleton caching as a later optimization only if this smaller batching win is not enough. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All verifier/task/test work. [VERIFIED: mix.exs; test/test_helper.exs] | ✓ [VERIFIED: elixir --version] | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | `mix test.adoption`, `mix scoria.release_preview`, `mix phx.new`. [VERIFIED: lib/mix/tasks/test.adoption.ex; .planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md; test/support/scoria/host_app_proof/generator.ex] | ✓ [VERIFIED: mix --version] | `1.19.5` [VERIFIED: mix --version] | — |
| Phoenix installer task (`mix phx.new`) | Fresh generated-host proof. [VERIFIED: test/support/scoria/host_app_proof/generator.ex] | ✓ [VERIFIED: mix help phx.new] | `phx_new 1.8.7` [VERIFIED: mix hex.info phx_new] | None without weakening proof. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md] |
| PostgreSQL | Repo-local and generated-host `ecto.create`/`ecto.migrate` proof. [VERIFIED: config/test.exs; test/support/scoria/host_app_proof/runner.ex] | ✓ [VERIFIED: pg_isready -h localhost -p 5432; pg_isready -h localhost -p 55432] | `psql 14.17`; listeners accepted on `5432` and `55432`. [VERIFIED: psql --version; pg_isready -h localhost -p 5432; pg_isready -h localhost -p 55432] | None. [VERIFIED: test/support/scoria/host_app_proof/runner.ex] |

**Missing dependencies with no fallback:**

- None found in the current workspace. [VERIFIED: local run 2026-05-26]

**Missing dependencies with fallback:**

- None found in the current workspace. [VERIFIED: local run 2026-05-26]

## Validation Architecture

This section is required because `.planning/config.json` does not disable `workflow.nyquist_validation`; the key is absent, so validation stays enabled. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs; elixir --version] |
| Config file | `test/test_helper.exs`; there is no separate `pytest`/`jest`-style config file. [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/scoria.install_test.exs --trace` for copy/task-boundary changes. [VERIFIED: test/scoria/adoption_surface_test.exs; test/mix/tasks/test.adoption_test.exs; test/mix/tasks/scoria.install_test.exs] |
| Full suite command | `MIX_ENV=dev mix scoria.release_preview && MIX_ENV=test mix test.adoption` after the host-proof timeout and harness cost are repaired. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; .planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md] [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | README, operator guide, and installer output stay aligned on lane order and prerequisite boundaries. [VERIFIED: .planning/REQUIREMENTS.md] | source + unit | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs --trace` [VERIFIED: test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs] | ✅ [VERIFIED: files on disk] |
| DOCS-02 | One canonical verifier per lane remains executable after timeout hardening. [VERIFIED: .planning/REQUIREMENTS.md] | integration + task boundary | `MIX_ENV=test mix test.adoption` plus `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs test/mix/tasks/test.semantic_fast_path_test.exs --trace` [VERIFIED: lib/mix/tasks/test.adoption.ex; test/mix/tasks/test.adoption_test.exs; test/mix/tasks/test.semantic_fast_path_test.exs] | ✅ [VERIFIED: files on disk] |

### Sampling Rate

- **Per task commit:** Run the smallest focused ExUnit suite for the changed seam; for docs/task-copy edits that is `adoption_surface_test`, `scoria.install_test`, or `test.adoption_test`. [VERIFIED: .planning/phases/49-support-truth-and-adoption-closeout/49-VALIDATION.md; test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/test.adoption_test.exs]
- **Per wave merge:** Run the generated-host proof file directly with its scoped timeout plus the relevant source-truth/task tests. [VERIFIED: test/scoria/host_app_consumer_proof_test.exs; local run 2026-05-26] [ASSUMED]
- **Phase gate:** `MIX_ENV=dev mix scoria.release_preview` and repaired non-trace `MIX_ENV=test mix test.adoption` must both be green before writing `49-VERIFICATION.md`. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; docs/operator_verification.md:153-165]

### Wave 0 Gaps

- [ ] `49-VERIFICATION.md` does not exist yet and must be created from fresh reruns. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md:45-59,120-124; ls .planning/phases/49-support-truth-and-adoption-closeout]
- [ ] The current `mix test.adoption` contract is still red at the default ExUnit budget and must be repaired before any archival closeout claim. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md:136-142; local run 2026-05-26]
- [ ] The exact passing env for the repaired default-lane proof must be written down in the verification artifact because both `5432` and `55432` are live on this machine. [VERIFIED: config/test.exs; docs/semantic_fast_path.md; pg_isready -h localhost -p 5432; pg_isready -h localhost -p 55432]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope and current files] | Host-app auth remains out of scope for Phase 51; the phase only verifies existing operator surfaces. [VERIFIED: .planning/ROADMAP.md; docs/operator_verification.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Session continuity is already proven in runtime tests; Phase 51 is not changing session semantics. [VERIFIED: test/scoria/runtime_integration_test.exs] |
| V4 Access Control | yes [VERIFIED: host runtime smoke touches operator session setup] | Preserve one operator-evidence smoke that initializes an operator session and renders the exact run page. [VERIFIED: test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs] |
| V5 Input Validation | yes [VERIFIED: host generator/patcher mutates files and env-sensitive config] | Keep generator patching narrow, keep fresh-host invalidation fail-closed, and keep docs/task truth enforced by source assertions. [VERIFIED: test/support/scoria/host_app_proof/generator.ex; test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new crypto behavior is introduced by verifier hardening. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Warm-cache false positive for fresh-host adoption | Spoofing / Repudiation | Only cache a pristine pre-overlay skeleton, always copy into a new temp dir, and always rerun the public install/create/migrate path. [VERIFIED: .planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md; test/support/scoria/host_app_proof/generator.ex] |
| Docs/task drift causing false support claims | Repudiation | Keep `adoption_surface_test`, installer-output tests, and task-boundary tests green before closeout. [VERIFIED: test/scoria/adoption_surface_test.exs; test/mix/tasks/scoria.install_test.exs; test/mix/tasks/test.adoption_test.exs] |
| Env-port mismatch causing verifier failure | Denial of Service / Misconfiguration | Record the exact supported env for the passing rerun in `49-VERIFICATION.md`; do not rely on hidden local state. [VERIFIED: config/test.exs; docs/semantic_fast_path.md; local run 2026-05-26] |

## Sources

### Primary (HIGH confidence)

- Local codebase files:
  - `lib/mix/tasks/test.adoption.ex`
  - `lib/mix/tasks/scoria.install.ex`
  - `test/scoria/host_app_consumer_proof_test.exs`
  - `test/support/scoria/host_app_proof/{generator,runner}.ex`
  - `test/support/scoria/host_app_proof/overlay/test/{host_route_smoke_test.exs,host_runtime_smoke_test.exs}`
  - `test/scoria/runtime_integration_test.exs`
  - `test/scoria/adoption_surface_test.exs`
  - `README.md`
  - `docs/adoption_lanes.md`
  - `docs/operator_verification.md`
  - `.planning/ROADMAP.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md`
  - `.planning/v2.2-MILESTONE-AUDIT.md`
  - `.planning/phases/49-support-truth-and-adoption-closeout/49-VALIDATION.md`
  - `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md`
  - `.planning/phases/51-default-lane-verifier-hardening-and-support-truth-re-closeout/51-CONTEXT.md`
- Local tool verification on 2026-05-26:
  - `elixir --version`
  - `mix --version`
  - `mix help phx.new`
  - `mix deps.tree`
  - `mix hex.info phoenix`
  - `mix hex.info phoenix_live_view`
  - `mix hex.info ecto_sql`
  - `mix hex.info postgrex`
  - `mix hex.info phx_new`
  - `pg_isready -h localhost -p 5432`
  - `pg_isready -h localhost -p 55432`
  - `MIX_ENV=test mix test.adoption`
  - `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace`

### Secondary (MEDIUM confidence)

- ExUnit timeout docs: https://hexdocs.pm/elixir/ExUnit.Case.html
- `mix test` docs: https://hexdocs.pm/mix/Mix.Tasks.Test.html

### Tertiary (LOW confidence)

- None. [VERIFIED: this research file]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions and tool availability were verified directly from `mix.lock`, `mix hex.info`, local commands, and repo files. [VERIFIED: mix.lock; mix hex.info phoenix; mix hex.info phoenix_live_view; mix hex.info ecto_sql; mix hex.info postgrex; mix hex.info phx_new; elixir --version; mix --version]
- Architecture: HIGH - the verifier composition, host harness, and source-truth seams are explicit in repo code and were reproduced by local runs. [VERIFIED: lib/mix/tasks/test.adoption.ex; test/support/scoria/host_app_proof/runner.ex; test/scoria/adoption_surface_test.exs; local run 2026-05-26]
- Pitfalls: HIGH - the timeout failure, duplicate host-step structure, and verification-gap state were all reproduced or directly documented by the milestone audit. [VERIFIED: local run 2026-05-26; .planning/v2.2-MILESTONE-AUDIT.md]

**Research date:** 2026-05-26 [VERIFIED: local run 2026-05-26]
**Valid until:** 2026-06-25 for repo-local structure; rerun the timing measurements sooner if the host harness changes. [VERIFIED: local run 2026-05-26] [ASSUMED]

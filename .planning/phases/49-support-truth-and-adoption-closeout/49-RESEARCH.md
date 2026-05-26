# Phase 49: Support truth and adoption closeout - Research

**Researched:** 2026-05-26
**Domain:** Support-truth alignment across Mix task UX, docs, and bounded verification lanes for a Phoenix/Elixir library [VERIFIED: codebase grep]
**Confidence:** HIGH [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `mix test.adoption` is the single canonical default-lane verifier everywhere Scoria describes the default Phoenix adoption path.
- **D-02:** `mix test` remains broader repo-health context only. It should not be described as the canonical default-lane proof in README, operator docs, installer output, or milestone closeout language.
- **D-03:** The boring default-lane order should read as `mix scoria.install` -> `mix ecto.migrate` -> `mix test.adoption` -> inspect `/scoria` and `/scoria/workflows/:run_id`.
- **D-04:** Default-lane wording must continue to state explicitly that pgvector, retrieval, grounding, semantic-fast-path setup, and knowledge-lane verification are not prerequisites for first adoption.
- **D-05:** Bounded handoffs stay inside the canonical default runtime adoption story. Scoria should not create a separate public handoff verification lane in Phase 49.
- **D-06:** Public docs should clarify that adopters validate the base runtime lane with `mix test.adoption`, then exercise `Scoria.start_handoff_run/3` only when they intentionally expand into the bounded-handoff lane.
- **D-07:** Handoffs remain an additive same-run runtime capability, not a separate prerequisite tier or a fourth mandatory proof command.
- **D-08:** Scoria's public verification family should converge on `mix test.*` for lane verifiers and reserve `mix scoria.*` for installers, setup/bootstrap tasks, and implementation aliases.
- **D-09:** `mix test.semantic_fast_path` remains the canonical semantic-fast-path verifier. `mix scoria.test.semantic_fast_path` remains a compatibility/implementation alias.
- **D-10:** `mix test.knowledge` should become the canonical public verifier for the optional knowledge lane. `mix scoria.test.knowledge` should remain supported as a compatibility alias, but not promoted as the primary public command.
- **D-11:** Phase 49 should avoid presenting multiple equivalent public names for the same verifier. One canonical command per lane is part of the support contract.
- **D-12:** The bounded maintainer closeout proof chain for `v2.2 OSS adopter onramp` should be exactly:
  `mix scoria.release_preview`
  `mix test.adoption`
- **D-13:** `mix scoria.release_preview` proves publish-facing docs and package-inventory truth; `mix test.adoption` proves the default host-app adoption boundary. These two commands together are the canonical milestone closeout answer.
- **D-14:** `mix test.semantic_fast_path` and `mix test.knowledge` are lane-specific validation commands, not part of the canonical `v2.2` closeout chain.
- **D-15:** `mix test` remains advisory repo-health context for maintainers, not canonical support proof.
- **D-16:** Docs and task output should use a four-tier hierarchy:
  canonical closeout proof,
  canonical default adoption lane,
  lane-specific optional/troubleshooting verifiers,
  broader repo-health context.
- **D-17:** The installer's "Optional later lanes" inventory should remain truthful and compact, but surrounding docs should make `mix test.adoption` visually primary for first adoption and `mix test.knowledge`/`mix test.semantic_fast_path` clearly secondary.
- **D-18:** Public wording should favor least surprise over historical consistency when the two conflict. That means removing wording drift even if backward-compatible aliases remain in code.
- **D-19:** Future discuss/planning work in this repo should research gray areas before escalating them: phase artifacts, prior contexts, `.planning/research/*`, and relevant `prompts/*` files should be consulted automatically when they shape product posture, DX, or support truth.
- **D-20:** Future discuss/planning should compare serious alternatives against idiomatic Phoenix/Plug/Ecto/LiveView library conventions and strong adjacent OSS prior art, then recommend one cohesive answer by default.
- **D-21:** User escalation should be reserved for decisions that still lack a clear winner after research and that materially affect product shape, security/policy boundary, durable truth, tenant blast radius, or a meaningfully different adopter/operator workflow.

### the agent's Discretion
- Exact sentence-level rewrite strategy across `README.md`, `docs/operator_verification.md`, `docs/adoption_lanes.md`, installer output, and source tests.
- Whether Phase 49 updates public docs to mention the compatibility aliases explicitly or leaves aliases undocumented.
- Whether the installer's "Optional later lanes" heading stays as-is or is retitled slightly, as long as the default-lane primacy and optional-lane boundaries stay clear.

### Deferred Ideas
- A dedicated public handoff verifier such as `mix test.handoffs` — defer unless real support evidence shows `mix test.adoption` is insufficient.
- Any attempt to fold semantic or knowledge verification into the default adoption or milestone closeout chain.
- Renaming internal implementation tasks or removing compatibility aliases immediately; public naming convergence is higher leverage than alias removal.
- Broader “all green” repo-health sweeps as canonical closeout language; keep them secondary unless a future milestone intentionally redefines support posture.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | README, operator verification, and installer output describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast-path, and optional knowledge surfaces. | Use `mix test.adoption` as the visually primary default-lane proof everywhere; keep bounded handoffs additive to that lane; keep semantic and knowledge verifiers explicitly secondary; preserve installer “Optional later lanes” as inventory only. [VERIFIED: codebase grep] |
| DOCS-02 | Scoria names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing. | Promote `mix test.adoption`, `mix test.semantic_fast_path`, and `mix test.knowledge`; keep `mix scoria.test.*` aliases supported but unpromoted; keep explicit “not required for first adoption” wording for pgvector/knowledge/semantic prerequisites. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] |
</phase_requirements>

## Summary

Scoria already has the right implementation primitives for Phase 49: the default adoption lane exists as `Mix.Tasks.Test.Adoption`, the semantic lane exists as `Mix.Tasks.Test.SemanticFastPath`, the knowledge lane already has both `test.knowledge` and `scoria.test.knowledge`, the installer already inventories later lanes, and the release-closeout lane already exists as `mix scoria.release_preview`. The remaining work is support-truth alignment across prose and assertions, not runtime expansion. [VERIFIED: codebase grep]

The main wording drift is concentrated in public docs, not task plumbing. `README.md` still presents `mix test` as the default verification command, `docs/operator_verification.md` still mixes canonical and advisory language in the same sections, and both README/operator docs still publicly promote `mix scoria.test.knowledge` where the locked Phase 49 posture wants `mix test.knowledge` as the one public lane name. By contrast, `docs/adoption_lanes.md` already uses the intended default-lane command and mostly needs knowledge-lane naming convergence. [VERIFIED: codebase grep]

The planner should treat this phase as a bounded docs-and-assertions closeout with three seams: public docs copy, installer summary copy, and adoption-surface/task discoverability tests. The canonical milestone closeout chain should stay exactly `mix scoria.release_preview` then `mix test.adoption`, while `mix test.semantic_fast_path`, `mix test.knowledge`, and `mix test` remain explicitly secondary for troubleshooting, optional expansion, or repo-health context. [VERIFIED: codebase grep]

**Primary recommendation:** Rewrite every adopter-facing surface to follow one four-tier hierarchy: `mix scoria.release_preview` for maintainer closeout, `mix test.adoption` for first adoption, `mix test.semantic_fast_path` and `mix test.knowledge` for optional lanes, and `mix test` only as broader repo-health context. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical lane naming | API / Backend | Browser / Client | Mix task modules and `mix.exs` own task discovery and CLI naming; docs only describe those names. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] |
| Installer support truth | API / Backend | — | `lib/mix/tasks/scoria.install.ex` prints the lane inventory and is the authoritative CLI messaging seam. [VERIFIED: codebase grep] |
| Public adoption docs | Frontend Server (SSR) | Browser / Client | Markdown guides are the public source of truth for lane order and prerequisite boundaries, while browser/operator pages are only the inspected outcome. [VERIFIED: codebase grep] |
| Maintainer closeout proof | API / Backend | Database / Storage | `mix scoria.release_preview` and `mix test.adoption` are bounded Mix lanes; they validate shipped files and host-app adoption proof rather than UI behavior alone. [VERIFIED: codebase grep] |
| Drift prevention | API / Backend | — | ExUnit source assertions in `test/scoria/adoption_surface_test.exs` and task tests are the right enforcement seam for command wording and public-lane naming. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Language/runtime for Mix tasks, docs tests, and ExUnit verification in this repo. [VERIFIED: local command] | The repo itself targets `~> 1.19`, and the local environment is already on 1.19.5, so planning can rely on current Mix/ExUnit behavior. [VERIFIED: codebase grep] [VERIFIED: local command] |
| Mix | 1.19.5 | Custom task system for canonical verifier names and CLI env mapping. [VERIFIED: local command] | Mix natively maps `Mix.Tasks.Foo.Bar` to `mix foo.bar`, and `cli/0` `preferred_envs` is the modern way to bind task names to `:test`. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] |
| ExUnit | bundled with Elixir 1.19.5 | Drift-prevention tests for docs and task discoverability. [VERIFIED: local command] | ExUnit is already the repo test framework, and `use ExUnit.Case, async: true` matches the existing adoption-surface/task test pattern. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |
| ExDoc | 0.40.3 | Publish-facing docs build used by `mix scoria.release_preview`. [VERIFIED: mix.lock] | ExDoc natively supports `extras` and `source_ref`, which matches the current docs packaging contract in `mix.exs`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | 1.8.7 | Host-app/operator surface context for `/scoria` and `/scoria/workflows/:run_id`. [VERIFIED: mix.lock] | Use as contextual product surface only; Phase 49 should not change Phoenix runtime behavior. [VERIFIED: codebase grep] |
| PostgreSQL | 14.17 local client; localhost `5432` accepting | Default-lane and optional semantic/knowledge proofs depend on Postgres availability. [VERIFIED: local command] | Needed when validating installer/migrate/adoption proofs; the current machine does not answer on `55432`, so semantic-lane commands using that port need local override or service startup. [VERIFIED: local command] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit source assertions | Manual docs review checklist | Manual review is weaker because wording drift already exists despite repo knowledge; the existing `adoption_surface_test.exs` seam is purpose-built to prevent regressions. [VERIFIED: codebase grep] |
| Canonical `mix test.*` names with compatibility aliases | Removing aliases immediately | Immediate alias removal would widen scope and risk support churn; the locked phase posture wants public convergence first and compatibility retention second. [VERIFIED: codebase grep] |
| Bounded closeout chain (`release_preview` + `test.adoption`) | Full `mix test` as closeout proof | Full-suite proof is broader but less support-truthful for this milestone because it mixes unrelated repo-health failures into the adopter closeout answer. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Elixir/Mix versions were verified locally with `elixir --version` and `mix --version`; dependency versions were verified from `mix.lock` for `ex_doc 0.40.3` and `phoenix 1.8.7`. [VERIFIED: local command] [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

The diagram below reflects the current support-truth flow encoded by the repo’s docs, Mix tasks, and ExUnit guards. [VERIFIED: codebase grep]

```text
Maintainer / Adopter
        |
        v
README.md + docs/*.md
        |
        | describes one lane hierarchy
        v
Mix task entrypoints
  - mix scoria.install
  - mix test.adoption
  - mix test.semantic_fast_path
  - mix test.knowledge
  - mix scoria.release_preview
        |
        +------------------------------+
        |                              |
        v                              v
Installer / release-preview output   Lane-specific test subsets
        |                              |
        |                              v
        |                        ExUnit assertions
        |                  - adoption_surface_test
        |                  - task discoverability tests
        |                              |
        +---------------> Drift caught before merge
```

### Recommended Project Structure
```text
docs/
├── adoption_lanes.md          # Lane vocabulary and adoption order
├── operator_verification.md   # Canonical proof chains and fallback language
├── bounded_handoffs.md        # Additive handoff posture inside default lane
└── semantic_fast_path.md      # Troubleshooting/optional semantic lane

lib/mix/tasks/
├── scoria.install.ex          # Installer summary and optional-lane inventory
├── scoria.release_preview.ex  # Bounded maintainer closeout proof
├── test.adoption.ex           # Canonical default-lane public verifier
└── test.semantic_fast_path.ex # Canonical semantic public verifier

test/
├── scoria/adoption_surface_test.exs   # Public wording drift guard
└── mix/tasks/*.exs                    # Canonical-task/alias discoverability guards
```

### Pattern 1: One Canonical Public Command Per Lane
**What:** Promote exactly one `mix test.*` command per public lane and keep `mix scoria.*` names as compatibility or setup-only seams. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]
**When to use:** Any adopter-facing README, guide, installer output, or closeout checklist. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: lib/mix/tasks/scoria.test.knowledge.ex [VERIFIED: codebase grep]
defmodule Mix.Tasks.Test.Knowledge do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria knowledge verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Knowledge.run(args)
end
```

### Pattern 2: Keep Optional Lanes Additive, Not Prerequisite
**What:** State the base runtime lane first, then describe handoff, semantic, and knowledge surfaces as intentional expansions. [VERIFIED: codebase grep]
**When to use:** README verification sections, operator guide step order, and installer “Optional later lanes” output. [VERIFIED: codebase grep]
**Example:**
```text
# Source: docs/adoption_lanes.md and lib/mix/tasks/scoria.install.ex [VERIFIED: codebase grep]
mix scoria.install
mix ecto.migrate
mix test.adoption

# Later only if needed:
mix test.semantic_fast_path
mix scoria.pgvector.bootstrap
mix test.knowledge
```

### Pattern 3: Assert Public Copy in Tests
**What:** Treat user-facing command names and prerequisite boundaries as testable product behavior. [VERIFIED: codebase grep]
**When to use:** Any time docs, README, or task summary copy changes. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: test/scoria/adoption_surface_test.exs [VERIFIED: codebase grep]
assert content =~ "mix test.adoption"
assert content =~ "mix test.semantic_fast_path"
refute content =~ "pgvector, retrieval, or semantic caching before Scoria is usable"
```

### Anti-Patterns to Avoid
- **Equivalent-command buffet:** Do not document both `mix test.knowledge` and `mix scoria.test.knowledge` as equally primary; keep one public name and one compatibility alias. [VERIFIED: codebase grep]
- **Default-lane dilution:** Do not place `mix test` in the same visual role as `mix test.adoption`; `mix test` should stay advisory context only. [VERIFIED: codebase grep]
- **Separate handoff verifier invention:** Do not create `mix test.handoffs` or equivalent in this phase; the locked scope keeps handoffs inside the default lane story. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public command aliasing | Custom shell scripts or README-only indirection | Mix task wrappers plus `cli/0` `preferred_envs` | Mix already provides stable task naming and CLI env routing; duplicating that in scripts adds drift surface. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] |
| Docs drift detection | Ad hoc manual proofreading | `test/scoria/adoption_surface_test.exs` and task tests | Existing source assertions already encode the support story and are cheap to extend. [VERIFIED: codebase grep] |
| Milestone closeout proof | New orchestration task for Phase 49 | Existing `mix scoria.release_preview` + `mix test.adoption` chain | The repo already has both bounded proof lanes; Phase 49 only needs to converge wording and checklist hierarchy. [VERIFIED: codebase grep] |

**Key insight:** The repo already contains the right bounded proof primitives, so Phase 49 should concentrate on naming convergence and test-backed wording truth rather than introducing new verification mechanics. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Leaving `mix test` in first-adoption prose
**What goes wrong:** Adopters see `mix test` as the canonical first proof and cannot tell which failures matter for OSS onramp support. [VERIFIED: codebase grep]
**Why it happens:** README and operator docs still contain older broader-suite wording alongside the newer bounded-lane language. [VERIFIED: codebase grep]
**How to avoid:** Make `mix test.adoption` the only promoted default-lane verifier and reframe `mix test` as optional broader context everywhere it appears. [VERIFIED: codebase grep]
**Warning signs:** Any section listing `mix test` directly under default verification without also placing `mix test.adoption` first. [VERIFIED: codebase grep]

### Pitfall 2: Publicly promoting both knowledge-lane names
**What goes wrong:** Support answers become inconsistent because docs and tests point at different knowledge commands. [VERIFIED: codebase grep]
**Why it happens:** The code intentionally supports both `test.knowledge` and `scoria.test.knowledge`, but the docs currently still promote the legacy namespaced variant. [VERIFIED: codebase grep]
**How to avoid:** Keep the alias in code and task tests, but update adopter-facing copy to `mix test.knowledge` only unless explicitly documenting backwards compatibility. [VERIFIED: codebase grep]
**Warning signs:** README, operator docs, or adoption-lane docs mention `mix scoria.test.knowledge` without explaining it is a compatibility alias. [VERIFIED: codebase grep]

### Pitfall 3: Turning bounded handoffs into a separate prerequisite lane
**What goes wrong:** The product story widens and first adopters infer they need extra proof steps before the default runtime is usable. [VERIFIED: codebase grep]
**Why it happens:** Handoffs have their own guide and API, so docs can accidentally read like a second quickstart. [VERIFIED: codebase grep]
**How to avoid:** Keep handoff guidance explicitly downstream of the proven default lane and tie it to `Scoria.start_handoff_run/3`, not a new verifier. [VERIFIED: codebase grep]
**Warning signs:** Any new checklist or command block that frames handoffs as a required lane before `/scoria` runtime proof. [VERIFIED: codebase grep]

### Pitfall 4: Forgetting the maintainer closeout hierarchy
**What goes wrong:** Milestone closeout balloons into “run everything” instead of a bounded proof chain support can actually cite. [VERIFIED: codebase grep]
**Why it happens:** The operator guide currently lists five commands in “Maintainer closeout,” including advisory and optional lanes. [VERIFIED: codebase grep]
**How to avoid:** Reduce closeout language to `mix scoria.release_preview` then `mix test.adoption`, and move other lanes into “when troubleshooting or extending” wording. [VERIFIED: codebase grep]
**Warning signs:** Closeout sections that include `mix test.semantic_fast_path`, `mix test`, or knowledge-lane commands as mandatory. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from current repo sources:

### Canonical CLI env mapping for public lane tasks
```elixir
# Source: mix.exs [VERIFIED: codebase grep]
def cli do
  [
    preferred_envs: [
      "scoria.test.adoption": :test,
      "test.adoption": :test,
      "scoria.test.semantic_fast_path": :test,
      "test.semantic_fast_path": :test,
      "scoria.test.knowledge": :test,
      "test.knowledge": :test
    ]
  ]
end
```

### Bounded adoption verifier built on `mix test`
```elixir
# Source: lib/mix/tasks/test.adoption.ex [VERIFIED: codebase grep]
@adoption_test_files [
  "test/scoria/adoption_surface_test.exs",
  "test/scoria/runtime_integration_test.exs",
  "test/scoria/host_app_consumer_proof_test.exs",
  "test/mix/tasks/scoria.install_test.exs"
]

def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.reenable("test")
  Mix.Task.run("test", args ++ @adoption_test_files)
end
```

### Installer inventory should stay additive
```elixir
# Source: lib/mix/tasks/scoria.install.ex [VERIFIED: codebase grep]
@optional_later_lanes [
  "mix test.adoption",
  ~s(SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix test.semantic_fast_path),
  "mix scoria.pgvector.bootstrap",
  "mix scoria.test.knowledge"
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad `mix test` cited as default proof | Bounded named verifier `mix test.adoption` for the adopter lane | Present in current repo state by 2026-05-26; still not fully propagated through README/operator docs. [VERIFIED: codebase grep] | Lets support point adopters at one bounded green lane instead of full-suite noise. [VERIFIED: codebase grep] |
| Namespaced implementation names shown publicly | `mix test.*` public lane family with `mix scoria.*` reserved for installer/setup/compatibility | Present in `mix.exs` and Mix task modules as of 2026-05-26. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] | Reduces user confusion while preserving backwards compatibility. [VERIFIED: codebase grep] |
| Docs as advisory prose only | Docs backed by source assertions and bounded release-preview/adoption task tests | Present in `test/scoria/adoption_surface_test.exs` and `test/mix/tasks/*.exs`. [VERIFIED: codebase grep] | Makes support-truth regressions merge-visible instead of support-ticket-visible. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Publicly promoting `mix scoria.test.knowledge` as the canonical knowledge verifier is outdated for Phase 49’s locked command-family posture, even though the alias should remain supported in code. [VERIFIED: codebase grep]
- Treating “Maintainer closeout” as a five-command everything-green list is outdated for the locked `v2.2` bounded closeout chain. [VERIFIED: codebase grep]

## Assumptions Log

All claims in this research were verified or cited — no user confirmation needed. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]

## Open Questions

1. **Should public docs mention compatibility aliases explicitly?**
   - What we know: Both `test.knowledge` and `scoria.test.knowledge` resolve today, and the locked context allows either documenting or omitting the alias. [VERIFIED: codebase grep]
   - What's unclear: Whether explicit alias mention helps existing maintainers more than it harms first-adopter clarity. [VERIFIED: codebase grep]
   - Recommendation: Keep public prose on canonical names only and mention aliases, if at all, in maintainer-focused notes or changelog-style copy. [VERIFIED: codebase grep]

2. **Should the installer heading stay `Optional later lanes`?**
   - What we know: The heading already encodes the intended additive posture, and the locked context allows a small retitle only if clarity improves. [VERIFIED: codebase grep]
   - What's unclear: Whether “later” is sufficiently explicit about “not required for first adoption.” [VERIFIED: codebase grep]
   - Recommendation: Keep the heading unless adjacent summary copy is too cramped; spend change budget on command ordering and prerequisite language first. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, ExUnit, docs build | ✓ | 1.19.5 | — [VERIFIED: local command] |
| Mix | Custom verifier tasks and test execution | ✓ | 1.19.5 | — [VERIFIED: local command] |
| PostgreSQL on `5432` | Default-lane migrate/proof commands | ✓ | 14.17 client; `pg_isready` accepting on `5432` | Use current local DB for default-lane planning. [VERIFIED: local command] |
| PostgreSQL on `55432` | Exact semantic fast-path example command as currently documented | ✗ | — | Override the port to a running DB or start the expected service before semantic-lane validation. [VERIFIED: local command] |
| Docker | Optional local service orchestration if planner wants isolated DB setup | ✓ | 29.4.1 | — [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None for Phase 49 research/planning itself. [VERIFIED: local command]

**Missing dependencies with fallback:**
- Semantic fast-path validation on port `55432` is not available on this machine, but the planner can either start that service or override the env vars to a reachable Postgres instance. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: local command] [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html] |
| Config file | [mix.exs](/Users/jon/projects/scoria/mix.exs:1), [test/test_helper.exs](/Users/jon/projects/scoria/test/test_helper.exs:1), [config/test.exs](/Users/jon/projects/scoria/config/test.exs:1) [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/scoria.test_knowledge_test.exs test/mix/tasks/test.semantic_fast_path_test.exs test/mix/tasks/scoria.release_preview_test.exs -x` [VERIFIED: codebase grep] |
| Full suite command | `mix test` [VERIFIED: local command] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | README, operator guide, and lane docs share one lane order and prerequisite boundary story. [VERIFIED: codebase grep] | unit/source-assertion | `mix test test/scoria/adoption_surface_test.exs -x` | ✅ [VERIFIED: codebase grep] |
| DOCS-02 | One canonical command per lane is documented and discoverable, with optional-lane denial/fallback wording preserved. [VERIFIED: codebase grep] | unit/source-assertion + task-discoverability | `mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/scoria.test_knowledge_test.exs test/mix/tasks/test.semantic_fast_path_test.exs test/mix/tasks/scoria.release_preview_test.exs -x` | ✅ [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/scoria.test_knowledge_test.exs test/mix/tasks/test.semantic_fast_path_test.exs -x` [VERIFIED: codebase grep]
- **Per wave merge:** `mix test.adoption` plus `mix test test/mix/tasks/scoria.release_preview_test.exs -x` [VERIFIED: codebase grep]
- **Phase gate:** `mix scoria.release_preview` and `mix test.adoption` green before `/gsd-verify-work`, with optional lane commands run only if the edited wording touches those lanes directly. [VERIFIED: codebase grep]

### Wave 0 Gaps
- [ ] `test/scoria/adoption_surface_test.exs` still asserts the old public knowledge-lane name and still tolerates README/operator-guide `mix test` prominence, so it must be updated alongside docs copy. [VERIFIED: codebase grep]
- [ ] `test/mix/tasks/scoria.install_test.exs` or a nearby installer-output assertion seam may need one extra assertion if the installer heading or lane ordering text changes. Existing research did not inspect that file, so planner should budget a small verification adjustment. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 49 changes support copy and verifier naming, not auth behavior. [VERIFIED: codebase grep] |
| V3 Session Management | no | Existing `session_id`/`run_id` semantics are documented but not altered in this phase. [VERIFIED: codebase grep] |
| V4 Access Control | no | Bounded-handoff scope remains documentation-only here; no permission logic changes are planned. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Preserve explicit denial/fallback wording for missing optional prerequisites so operators are not misled into unsafe or undefined setup paths. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No crypto primitives or secret-handling changes are in scope. [VERIFIED: codebase grep] |

### Known Threat Patterns for docs-plus-Mix-task support surfaces

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Support-truth drift between docs and executable lanes | Tampering | Keep lane wording under ExUnit source assertions and bounded task tests. [VERIFIED: codebase grep] |
| Hidden optional prerequisites presented as mandatory | Denial of service | Preserve explicit “not required for first adoption” wording for pgvector, retrieval, grounding, and semantic lanes. [VERIFIED: codebase grep] |
| Ambiguous alias promotion causing wrong verifier use | Repudiation | Document one canonical command per lane and reserve aliases for compatibility only. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- [mix.exs](/Users/jon/projects/scoria/mix.exs:1) - verified `cli/0` `preferred_envs`, docs extras, and package surface. [VERIFIED: codebase grep]
- [README.md](/Users/jon/projects/scoria/README.md:1) - verified current default-lane/knowledge-lane wording drift. [VERIFIED: codebase grep]
- [docs/adoption_lanes.md](/Users/jon/projects/scoria/docs/adoption_lanes.md:1) - verified current canonical default-lane posture. [VERIFIED: codebase grep]
- [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:1) - verified current maintainer closeout and repo-health wording drift. [VERIFIED: codebase grep]
- [docs/bounded_handoffs.md](/Users/jon/projects/scoria/docs/bounded_handoffs.md:1) - verified additive handoff posture. [VERIFIED: codebase grep]
- [docs/semantic_fast_path.md](/Users/jon/projects/scoria/docs/semantic_fast_path.md:1) - verified semantic lane separation and current knowledge-lane naming. [VERIFIED: codebase grep]
- [lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:1) - verified installer summary and optional-lane inventory. [VERIFIED: codebase grep]
- [lib/mix/tasks/scoria.release_preview.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.release_preview.ex:1) - verified maintainer closeout lane. [VERIFIED: codebase grep]
- [lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:1) - verified canonical default-lane verifier implementation. [VERIFIED: codebase grep]
- [lib/mix/tasks/test.semantic_fast_path.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.semantic_fast_path.ex:1) - verified canonical semantic verifier wrapper. [VERIFIED: codebase grep]
- [lib/mix/tasks/scoria.test.knowledge.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:1) - verified knowledge-lane canonical/compatibility alias shape. [VERIFIED: codebase grep]
- [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:1) - verified current public truth assertions and gaps. [VERIFIED: codebase grep]
- [test/mix/tasks/test.adoption_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.adoption_test.exs:1) - verified adoption-lane discoverability contract. [VERIFIED: codebase grep]
- [test/mix/tasks/test.semantic_fast_path_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.semantic_fast_path_test.exs:1) - verified semantic-lane discoverability contract. [VERIFIED: codebase grep]
- [test/mix/tasks/scoria.test_knowledge_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.test_knowledge_test.exs:1) - verified knowledge-lane alias discoverability contract. [VERIFIED: codebase grep]
- [mix.lock](/Users/jon/projects/scoria/mix.lock:1) - verified dependency versions used in this repo. [VERIFIED: mix.lock]
- `elixir --version`, `mix --version`, `pg_isready`, `psql --version`, `docker --version` - verified local environment availability. [VERIFIED: local command]
- https://hexdocs.pm/mix/main/Mix.Project.html - verified `cli/0` and `preferred_envs` guidance. [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]
- https://hexdocs.pm/mix/main/Mix.Task.html - verified Mix task naming and wrapper conventions. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]
- https://hexdocs.pm/mix/Mix.Tasks.Test.html - verified `mix test` semantics as the broad test runner. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]
- https://hexdocs.pm/ex_unit/main/ExUnit.Case.html - verified ExUnit case and `async: true` behavior. [CITED: https://hexdocs.pm/ex_unit/main/ExUnit.Case.html]
- https://hexdocs.pm/ex_doc/ExDoc.html - verified ExDoc `extras` and `source_ref` behavior. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The relevant stack is small and directly verified from local versions, `mix.lock`, and official Elixir docs. [VERIFIED: local command] [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]
- Architecture: HIGH - The support-truth flow is explicit in current docs, Mix tasks, and ExUnit assertions. [VERIFIED: codebase grep]
- Pitfalls: HIGH - The current repo already exhibits the exact wording drift and alias ambiguity this phase is meant to close. [VERIFIED: codebase grep]

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 for repo-local planning; re-check docs/task wording if Phase 48 lands additional surface changes first. [VERIFIED: codebase grep]

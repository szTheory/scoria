# Phase 18: Add Executable Adoption Flow Guards - Pattern Map

**Mapped:** 2026-05-16
**Phase source:** `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md`
**Files analyzed:** 14
**Strong analogs:** 8

## File Classification

| Phase 18 Target | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `18-01` README/public-surface guards | test + docs | transform + request-response contract | `test/scoria/adoption_surface_test.exs` | exact |
| `18-01` pure facade snippet execution | test | transform | `test/scoria_test.exs` | role-match |
| `18-01` public contract wording/source alignment | plan | transform | `15-01-PLAN.md` | exact |
| `18-02` Phoenix example verification lane | test + docs | request-response | `test/scoria/runtime_integration_test.exs` | exact |
| `18-02` docs/example flow planning | plan | request-response | `15-01-PLAN.md` | role-match |
| `18-03` operator verification acceptance harness | test + docs | request-response + event-driven | `test/scoria/runtime_integration_test.exs` | exact |
| `18-03` installer/route baseline guard | test | file-I/O + request-response | `test/mix/tasks/scoria.install_test.exs` and `test/mix/tasks/scoria.install_route_smoke_test.exs` | exact |
| `18-03` focused adoption lane | config + task | batch | `.github/workflows/ci.yml` and `lib/mix/tasks/scoria.test.knowledge.ex` | role-match |
| `18-03` verification-story planning | plan | request-response | `15-03-PLAN.md` | exact |
| Phase-level verification shape | validation | batch | `17-VALIDATION.md` | exact |

## Analogous Planning Patterns To Reuse

### `18-01` should copy the Phase 15 docs-contract plan shape

**Analog:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md`

**Why it matches**
- It frames docs as contract surfaces tied to runtime truth, not standalone prose.
- It uses `must_haves.truths`, `artifacts`, and `key_links` to bind docs to code/tests.
- Its verification style is exactly the Phase 18 posture: targeted ExUnit plus `rg` contract checks.

**Pattern to copy**
- Frontmatter + `must_haves` block at [15-01-PLAN.md:1](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md:1)
- Artifact/link mapping at [15-01-PLAN.md:18](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md:18)
- Task structure with `<read_first>`, `<acceptance_criteria>`, `<action>`, `<verify>` at [15-01-PLAN.md:111](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md:111)

**Concrete verification pattern**
```text
SCORIA_DB_PORT=55432 MIX_ENV=test mix test ... && rg -n "Scoria.start_run|Scoria.resume_run|session_id|run_id|/scoria/workflows/:run_id|Optional knowledge lane" README.md
```
Source: [15-01-PLAN.md:117](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md:117)

### `18-03` should copy the Phase 15 operator-story plan shape

**Analog:** `.planning/phases/15-adoption-surface-docs-and-example-flow/15-03-PLAN.md`

**Why it matches**
- It already models the exact layered proof Phase 18 wants: installer preflight, one real run, operator evidence, optional knowledge lane after core proof.
- It ties installer copy, runtime docs, and tests together with explicit key links.

**Pattern to copy**
- Truth/artifact/link layout at [15-03-PLAN.md:17](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-03-PLAN.md:17)
- Task split between docs verification lane and installer alignment at [15-03-PLAN.md:104](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-03-PLAN.md:104)
- Threat model focused on drift and false proof at [15-03-PLAN.md:130](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-03-PLAN.md:130)

### Phase 18 validation should copy the Phase 17 sampling model

**Analog:** `.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-VALIDATION.md`

**Why it matches**
- It already treats adoption closure as a focused subset inside normal `mix test`.
- It defines quick-run, full-suite, and per-task commands without adding new infrastructure.

**Pattern to copy**
- Test infra table at [17-VALIDATION.md:16](/Users/jon/projects/scoria/.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-VALIDATION.md:16)
- Per-task command matrix at [17-VALIDATION.md:41](/Users/jon/projects/scoria/.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-VALIDATION.md:41)
- Closure note that manual lanes should be replaced by executable tests at [17-VALIDATION.md:62](/Users/jon/projects/scoria/.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-VALIDATION.md:62)

## Analogous Code/Test Patterns To Reuse

### Semantic doc guard pattern

**Analog:** `test/scoria/adoption_surface_test.exs`

**Use for:** `18-01` README/public surface assertions, `18-02` markdown example assertions, and any narrow operator-guide contract checks that should stay wording-light.

**Core pattern** at [test/scoria/adoption_surface_test.exs:8](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:8)
```elixir
test "README documents the runtime-first adoption lane and optional knowledge lane" do
  content = File.read!(@readme)

  assert content =~ "Scoria.start_run"
  assert content =~ "Scoria.resume_run"
  assert content =~ "session_id"
  assert content =~ "run_id"
  assert content =~ "/scoria/workflows/:run_id"
  assert content =~ "Optional knowledge lane"
end
```

**Pattern note**
- This is semantic-contract checking, not snapshot testing.
- Phase 18 should extend this style with stable contract strings or extracted shared snippets, not whole-doc rendering diffs.

### Runtime-truth integration pattern

**Analog:** `test/scoria/runtime_integration_test.exs`

**Use for:** `18-02` checked Phoenix example helpers and `18-03` operator acceptance proof.

**Router/endpoint harness** at [test/scoria/runtime_integration_test.exs:1](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:1)
```elixir
defmodule Scoria.RuntimeIntegrationTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end
```

**Same-session vs exact-run contract** at [test/scoria/runtime_integration_test.exs:111](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:111)
```elixir
{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

assert {:ok, resumed} =
         Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

assert resumed.run_id == started.run_id
```

**Operator-page alignment pattern** at [test/scoria/runtime_integration_test.exs:159](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:159)
```elixir
{:ok, view, _html} = live(conn, "/scoria/workflows/#{started.run_id}")

assert render(view) =~ started.run_id
assert render(view) =~ "waiting_for_approval"

{:ok, _summary} =
  Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

assert render(view) =~ "completed"
assert render(view) =~ "step_completed"
```

**Pattern note**
- Phase 18 should keep public `Scoria` as the driver and use `Runtime.get_run/1` only as supporting truth checks, same as the existing test.

### Installer mutation and idempotence pattern

**Analog:** `test/mix/tasks/scoria.install_test.exs`

**Use for:** `18-03` install-preflight guard and any future adoption lane that must prove docs and installer output still match shipped mutations.

**Core pattern** at [test/mix/tasks/scoria.install_test.exs:44](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:44)
```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)

updated_router = File.read!(router_path)
assert updated_router =~ "import ScoriaWeb.Router"
assert updated_router =~ "scoria_dashboard \"/scoria\""
assert length(String.split(updated_router, "scoria_dashboard")) == 2
```

**Pattern note**
- Re-run the installer and assert one insertion only.
- Favor idempotence and mutation truth over output-copy assertions.

### Route smoke pattern

**Analog:** `test/mix/tasks/scoria.install_route_smoke_test.exs`

**Use for:** `18-03` proving installed routes still resolve after mutation.

**Core pattern** at [test/mix/tasks/scoria.install_route_smoke_test.exs:41](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_route_smoke_test.exs:41)
```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
Code.compile_string(File.read!(router_path))

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
         Phoenix.LiveView.Plug
```

### Focused lane task wrapper pattern

**Analog:** `lib/mix/tasks/scoria.test.knowledge.ex`

**Use for:** optional `18-03` adoption lane task if Phase 18 adds `mix scoria.test.adoption` or `mix test.adoption`.

**Core pattern** at [lib/mix/tasks/scoria.test.knowledge.ex:1](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:1)
```elixir
defmodule Mix.Tasks.Scoria.Test.Knowledge do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("app.start")
    ...
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end
end
```

**Pattern note**
- For adoption, keep the wrapper thinner than knowledge: likely just `Mix.Task.run("test", adoption_files ++ args)` with no extra env/bootstrap.
- Also mirror the compatibility alias pattern from [lib/mix/tasks/scoria.test.knowledge.ex:24](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:24) if both task names are desired.

### Existing doctest entry pattern

**Analog:** `test/scoria_test.exs`

**Use for:** `18-01` pure stable snippets moved into `@moduledoc` examples for `Scoria`, and possibly `Scoria.Identity` if examples stay pure.

**Core pattern** at [test/scoria_test.exs:1](/Users/jon/projects/scoria/test/scoria_test.exs:1)
```elixir
defmodule ScoriaTest do
  use ExUnit.Case
  doctest Scoria
```

**Pattern note**
- This is the right scope for pure examples only.
- Do not push controller/session/router/LiveView walkthroughs into doctests.

### CI focused-lane pattern

**Analog:** `.github/workflows/ci.yml`

**Use for:** `18-03` adding a discoverable adoption command while keeping the same pre-full-suite posture.

**Core pattern** at [.github/workflows/ci.yml:68](/Users/jon/projects/scoria/.github/workflows/ci.yml:68)
```yaml
- name: Run adoption closure lane
  run: mix test test/scoria/runtime_integration_test.exs test/scoria/adoption_surface_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs
```

**Pattern note**
- Phase 18 should prefer replacing this long command with a named adoption task, not adding a second parallel philosophy.

## Recommended File Touch Points

### `18-01` Add README and Public Surface Guardrails

**Primary analogs**
- `test/scoria/adoption_surface_test.exs`
- `test/scoria_test.exs`
- `README.md`
- `15-01-PLAN.md`

**Recommended touch points**
- `test/scoria/adoption_surface_test.exs`
  - Tighten semantic assertions around stable public contract terms already in [test/scoria/adoption_surface_test.exs:8](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:8).
  - Good place for README contract checks and narrow docs-file assertions.
- `test/scoria_test.exs`
  - Expand existing `doctest Scoria` at [test/scoria_test.exs:3](/Users/jon/projects/scoria/test/scoria_test.exs:3) if the pure facade examples move into moduledocs.
- `lib/scoria.ex`
  - Best home for pure facade examples that should execute via doctest.
- `lib/scoria/identity.ex`
  - Good secondary home for identity normalization examples if they remain pure and deterministic.
- `README.md`
  - Only if Phase 18 chooses to replace prose snippets with shared fragments or tighten exact stable snippets.

**Avoid touching first**
- `docs/phoenix_runtime_example.md`
- `docs/operator_verification.md`
These belong to `18-02` and `18-03`, not the README/public-surface guard slice.

### `18-02` Add Phoenix Example Verification Lane

**Primary analogs**
- `test/scoria/runtime_integration_test.exs`
- `test/scoria/adoption_surface_test.exs`
- `docs/phoenix_runtime_example.md`
- `15-01-PLAN.md`

**Recommended touch points**
- `test/scoria/runtime_integration_test.exs`
  - Canonical truth source for any reusable example helper/module because it already proves the exact behaviors the example teaches.
- `docs/phoenix_runtime_example.md`
  - Keep as docs-first output, but derive stable code fragments from checked helpers rather than hand-maintained prose.
- `test/scoria/adoption_surface_test.exs`
  - Keep a narrow semantic assertion pass over the rendered guide even if source fragments move elsewhere.
- `test/support/` helper module or shared example module
  - Best place for reusable example snippets consumed by both tests and docs if implementation chooses a shared-source approach.

**Likely new file if needed**
- `test/support/adoption_examples.ex` or similar
  - Preferred over a fixture Phoenix app.

### `18-03` Add Operator Verification Acceptance Harness

**Primary analogs**
- `test/scoria/runtime_integration_test.exs`
- `test/mix/tasks/scoria.install_test.exs`
- `test/mix/tasks/scoria.install_route_smoke_test.exs`
- `lib/mix/tasks/scoria.install.ex`
- `.github/workflows/ci.yml`
- `lib/mix/tasks/scoria.test.knowledge.ex`
- `15-03-PLAN.md`

**Recommended touch points**
- `test/scoria/runtime_integration_test.exs`
  - Main acceptance harness for run start, readback, operator page mount, and approval resume.
- `test/mix/tasks/scoria.install_test.exs`
  - Baseline installer mutation and idempotence proof.
- `test/mix/tasks/scoria.install_route_smoke_test.exs`
  - Route viability proof after installer mutation.
- `lib/mix/tasks/scoria.install.ex`
  - Only if operator-verification messaging or next-step hints need to stay aligned with the new named lane.
- `lib/mix/tasks/scoria.test.adoption.ex`
  - Recommended new file if a focused adoption command is added.
- `.github/workflows/ci.yml`
  - Replace the inline adoption subset command with the new task if one is introduced.

## Shared Patterns

### Layered adoption proof

**Source combination**
- [test/mix/tasks/scoria.install_test.exs:44](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:44)
- [test/mix/tasks/scoria.install_route_smoke_test.exs:41](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_route_smoke_test.exs:41)
- [test/scoria/runtime_integration_test.exs:111](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:111)
- [test/scoria/runtime_integration_test.exs:159](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:159)

**Apply to**
- All of `18-03`
- The verification sections of `18-02`

**Rule**
- Installer mutation proof first.
- Route smoke second.
- Real public-facade run plus exact `run_id` resume third.
- LiveView operator-page assertion fourth.

### Semantic-grep plus executable-test pairing

**Source combination**
- [test/scoria/adoption_surface_test.exs:8](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:8)
- [17-VALIDATION.md:45](/Users/jon/projects/scoria/.planning/phases/17-re-verify-keystone-defaults-and-adoption-surface/17-VALIDATION.md:45)
- [15-01-PLAN.md:117](/Users/jon/projects/scoria/.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md:117)

**Apply to**
- `18-01` and `18-02`

**Rule**
- Keep docs guards semantic and lightweight.
- Pair them with executable runtime truth from ExUnit, not with broader markdown snapshots.

### Boring default lane, explicit heavier lane

**Source combination**
- [lib/mix/tasks/scoria.test.knowledge.ex:1](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:1)
- [.github/workflows/ci.yml:68](/Users/jon/projects/scoria/.github/workflows/ci.yml:68)
- [docs/operator_verification.md:98](/Users/jon/projects/scoria/docs/operator_verification.md:98)

**Apply to**
- `18-03`

**Rule**
- Adoption guards remain eligible under plain `mix test`.
- A named focused lane improves discoverability and CI readability.
- Do not move default adoption coverage behind opt-in tags.

## Patterns To Avoid

- Whole-README or whole-guide snapshot tests.
  - Current analogs use semantic assertions and targeted greps, not rendered-doc snapshots.
- A fixture Phoenix host app as the main source of truth.
  - The repo already has a stronger canonical seam in `test/scoria/runtime_integration_test.exs`.
- Browser E2E infrastructure for the default operator lane.
  - Existing `Phoenix.LiveViewTest` coverage already proves the mounted operator surface.
- Brittle copy assertions on every sentence of public docs.
  - Prefer stable API symbols, identifier semantics, routes, and lane names.
- Teaching or testing `Scoria.Workflows` as the normal adoption entrypoint.
  - Public docs and runtime tests are already centered on `Scoria`.
- Hiding adoption guards behind tags or a separate non-default test universe.
  - Context and CI both treat adoption as first-class.
- Duplicated source-of-truth snippets maintained independently in README/docs/tests.
  - Prefer checked shared helpers or pure moduledoc examples.

## Short Implementation-Shape Recommendation

Build Phase 18 as a thin hardening layer over the current seams, not as a new product surface. `18-01` should extend `test/scoria/adoption_surface_test.exs` and existing doctest coverage for pure facade/identity snippets. `18-02` should derive the canonical Phoenix example from a checked helper or example module exercised by `test/scoria/runtime_integration_test.exs`, while keeping a lightweight semantic guard on the markdown file. `18-03` should keep the layered harness already implicit in the repo: installer mutation test, route smoke test, runtime integration test, and LiveView operator assertion, then package that subset behind a thin named task such as `mix scoria.test.adoption` and wire CI to call it instead of inlining the file list.

## No Analog Needed

No new framework or external harness is justified from the current repo patterns. The existing ExUnit, `Phoenix.LiveViewTest`, file-mutation tests, and focused Mix task wrapper pattern are sufficient for Phase 18.

## Metadata

**Analog search scope:** `.planning/phases/15-*`, `.planning/phases/17-*`, `test/scoria`, `test/mix/tasks`, `lib/mix/tasks`, `docs`, `.github/workflows`
**Pattern extraction date:** 2026-05-16

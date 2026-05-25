# Phase 43: Canonical Adoption Proof & Milestone Closeout - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CLOSEOUT.md` | config | transform | `.planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md` | role-match |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |

## Pattern Assignments

### `.planning/phases/43-canonical-adoption-proof-milestone-closeout/43-CLOSEOUT.md` (config, transform)

**Primary analog:** `.planning/phases/42-delegated-evidence-adoption-story/42-GAP-LEDGER.md`

**Secondary analogs:**
- `.planning/phases/40-online-scoring-review-queue/40-VERIFICATION.md`
- `.planning/phases/18-add-executable-adoption-flow-guards/18-VERIFICATION.md`
- `.planning/v1.3-MILESTONE-AUDIT.md`

**Decision-first skeleton** (from `42-GAP-LEDGER.md`, lines 1-15):
```markdown
# Phase 42 Gap Ledger

## Closeout Decision

There is no remaining adopter-facing gap required to ship the runtime-first bounded handoff lane for `v2.0 Relay` closeout.

## Why

- ...

## Deferred Follow-Up
```

**Observable-truth evidence table** (from `40-VERIFICATION.md`, lines 24-45):
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | ... | ✓ VERIFIED | `...` |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| ... | `mix test ...` | `... tests, 0 failures` | ✓ PASS |
```

**Adoption-lane proof bullets** (from `18-VERIFICATION.md`, lines 12-17):
```markdown
## Verification Evidence
- `test/scoria_test.exs`, `test/scoria/identity_doctest_test.exs`, and `test/scoria/adoption_surface_test.exs` prove the pure `Scoria` and `Scoria.Identity` public surface stays executable and semantically anchored.
- `test/support/scoria/adoption_example.ex`, `test/scoria/runtime_integration_test.exs`, and `test/scoria/phoenix_example_source_test.exs` keep the Phoenix guide tied to checked runtime truth.
- `lib/mix/tasks/test.adoption.ex`, `test/mix/tasks/test.adoption_test.exs`, `.github/workflows/ci.yml`, `docs/operator_verification.md`, and `lib/mix/tasks/scoria.install.ex` prove the bounded adoption lane and the maintainer/operator docs remain aligned.
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption` passed on 2026-05-17 with `2 doctests, 12 tests, 0 failures` in the current closeout rerun.
```

**Explicit noise/debt classification** (from `40-VERIFICATION.md`, lines 55-64):
```markdown
### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `40-VALIDATION.md` | Full-suite `mix test` remained red on 2026-05-24 because of unrelated failures outside the milestone-owned lanes. | ⚠️ Warning | This remains project-level tech debt, but it does not invalidate the owned Phase 40 proof chain. |

### Closure Summary

Phase 40 now has a canonical proof chain.
```

**Concrete blocker classification notes** (from `v1.3-MILESTONE-AUDIT.md`, lines 168-190):
```markdown
## Verification Notes
- Local focused verification run surfaced concrete failures:
  - `MIX_ENV=test mix test ... --trace`
  - Result: `11 tests, 3 failures`
  - Failures: ...

## Recommended Closure Path
1. Add a follow-up gap phase for the four integration defects:
```

**Apply these patterns in Phase 43:**
- Start with a decisive `## Closeout Decision` section, not a narrative introduction.
- Add one compact evidence section that points to `mix test.adoption`, the adoption docs/tests, and prior phase artifacts instead of duplicating transcripts.
- Record broader `mix test` noise in a dedicated classification section with explicit blocker rules, not vague prose.
- End with either `## Deferred Follow-Up` or an equivalent narrow recommendation section.

---

### `.planning/ROADMAP.md` (config, transform)

**Analog:** `.planning/ROADMAP.md`

**Phase checklist pattern** (lines 15-18):
```markdown
- [x] **Phase 41: Bounded Handoff Contract & Safety** - Lock the public handoff contract, same-run lineage, and projected-context guardrails as explicit shipped truth. (completed 2026-05-24)
- [x] **Phase 42: Delegated Evidence & Adoption Story** - Make delegated lineage inspectable and keep the docs/source examples aligned with the actual handoff lane. (completed 2026-05-24)
- [ ] **Phase 43: Canonical Adoption Proof & Milestone Closeout** - Prove the bounded handoff lane through the default adoption verification path and decide whether any remaining handoff work is real follow-on value.
```

**Phase detail block pattern** (lines 47-57):
```markdown
### Phase 43: Canonical Adoption Proof & Milestone Closeout
**Goal**: The bounded handoff lane has one boring canonical proof path and a clean closeout decision.
**Depends on**: Phase 42
**Requirements**: ADPT-02
**Success Criteria**:
1. ...
2. ...
3. ...
**Plans**: 2 plans
- [ ] `43-01-PLAN.md` — ...
- [ ] `43-02-PLAN.md` — ...
```

**Progress table pattern** (lines 59-65):
```markdown
## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 43. Canonical Adoption Proof & Milestone Closeout | 0/2 | Not Started | — |
```

**Apply these patterns in Phase 43:**
- When the phase closes, update the phase checkbox line and progress row in place rather than adding a new section.
- Keep the existing one-line phase description style and `(completed YYYY-MM-DD)` suffix format.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Analog:** `.planning/REQUIREMENTS.md`

**Requirement checkbox pattern** (lines 22-25):
```markdown
### Adoption Proof

- [x] **ADPT-01**: Adoption docs and checked source fragments show how bounded handoffs fit into the normal identity -> start -> inspect -> resume runtime flow for Phoenix apps.
- [ ] **ADPT-02**: `mix test.adoption` canonically covers the public runtime facade, bounded handoff guide/source alignment, and adoption-lane verification without requiring optional knowledge-lane setup.
```

**Traceability table pattern** (lines 44-55):
```markdown
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADPT-01 | Phase 42 | Complete |
| ADPT-02 | Phase 43 | Pending |
```

**Footer update pattern** (lines 61-63):
```markdown
---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after milestone initialization*
```

**Apply these patterns in Phase 43:**
- Flip the `ADPT-02` checkbox and traceability status in place.
- Preserve the existing requirement wording unless the proof changes the claim itself.
- Update only the `Last updated` footer line; do not add closeout prose here.

---

### `.planning/STATE.md` (config, transform)

**Analog:** `.planning/STATE.md`

**Frontmatter progress pattern** (lines 1-15):
```yaml
---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Relay
status: ready_to_plan
last_updated: 2026-05-24T17:02:24.101Z
last_activity: 2026-05-24
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 6
  completed_plans: 128
  percent: 33
stopped_at: Phase 42 complete (3/3) — ready to discuss Phase 43
---
```

**Current focus / position block** (lines 21-33):
```markdown
**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Phase 43 — canonical adoption proof & milestone closeout

## Current Position

Phase: 42 (delegated-evidence-adoption-story) — EXECUTING
Plan: 1 of 3
**Milestone:** `v2.0 Relay`
**Phase:** 43
**Plan:** Not started
**Status:** Ready to plan
```

**Apply these patterns in Phase 43:**
- Update frontmatter counters/status instead of appending a separate closeout note.
- Keep `Current Focus` as the milestone/phase headline and make `Current Position` match the same closed state.
- Preserve the existing mixed YAML-plus-markdown structure; do not convert this file into a narrative verification report.

## Shared Patterns

### Canonical proof command
**Source:** `lib/mix/tasks/test.adoption.ex` (lines 1-25)
**Apply to:** `43-CLOSEOUT.md` evidence and command sections
```elixir
defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @shortdoc "Runs the adoption-focused default verification lane"
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

### Docs/source alignment guard
**Source:** `test/scoria/adoption_surface_test.exs` (lines 12-27, 29-54, 83-96)
**Apply to:** `43-CLOSEOUT.md` alignment evidence section
```elixir
test "README documents the runtime-first adoption lane and optional knowledge lane" do
  content = File.read!(@readme)

  assert content =~ "identity -> start -> inspect -> resume"
  assert content =~ "Scoria.start_run"
  assert content =~ "Scoria.start_handoff_run"
  assert content =~ "Scoria.get_run_detail"
  assert content =~ "delegated_handoffs"
  assert content =~ "Scoria.resume_run"
  assert content =~ "session_id"
  assert content =~ "run_id"
  assert content =~ "/scoria/workflows/:run_id"
  assert content =~ "Optional knowledge lane"
end

test "bounded handoff guide documents the narrow public delegation lane" do
  content = File.read!(@handoff_guide)

  assert content =~ "same durable run"
  assert content =~ "Delegated Evidence"
  assert content =~ "No remaining adopter-facing gap"
  refute content =~ "implicit payload projection"
end

test "operator verification guide documents the core automated lane without knowledge requirements" do
  content = File.read!(@operator_guide)

  assert content =~ "mix test"
  assert content =~ "mix test.adoption"
  assert content =~ "Optional knowledge lane"
  assert content =~ "mix scoria.test.knowledge"
end
```

### Exact-run runtime and operator evidence
**Source:** `test/scoria/runtime_integration_test.exs` (lines 120-162, 164-209)
**Apply to:** `43-CLOSEOUT.md` runtime proof references
```elixir
test "public runtime proves same-session new runs and exact run_id resume" do
  identity = AdoptionExample.runtime_identity()

  {:ok, started} =
    Scoria.start_run(identity,
      root_role_id: "executor",
      initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
      handlers: %{"approval" => {Handlers, :wait_for_approval}}
    )

  assert {:ok, resumed} =
           Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

  assert resumed.run_id == started.run_id

  {:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

  assert next_run.session_id == started.session_id
  assert next_run.run_id != started.run_id
end

test "operator-visible workflow page stays aligned with the public runtime contract" do
  {:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))
  assert render(view) =~ started.run_id
  assert render(view) =~ AdoptionExample.waiting_status()
  assert render(view) =~ AdoptionExample.completed_status()
  assert render(view) =~ "step_completed"
end
```

### Bounded handoff detail / delegated readback
**Source:** `test/scoria/runtime_test.exs` (lines 25-69, 169-217)
**Apply to:** `43-CLOSEOUT.md` bounded-handoff behavior references
```elixir
test "start_handoff_run creates bounded delegated lineage with a queued child step" do
  assert {:ok, summary} =
           Runtime.start_handoff_run(
             %{actor_id: "actor-handoff", tenant_id: "tenant-handoff", session_id: "session-handoff"},
             "critic",
             root_role_id: "planner",
             delegated_kind: "review",
             handoff_input: %{"brief" => "review draft"},
             projected_context: %{"task" => "review", "draft_answer" => "hello"}
           )

  detail = Runtime.get_run_detail!(summary.run_id)
  assert detail.summary.status == "running"
  assert [%{delegated_role_id: "critic", delegated_kind: "review"}] = detail.delegated_handoffs
end

test "start_handoff_run rejects missing explicit contract inputs" do
  assert {:error, :invalid_root_role_id} = Runtime.start_handoff_run(...)
  assert {:error, :invalid_delegated_kind} = Runtime.start_handoff_run(...)
  assert {:error, :invalid_handoff_input} = Runtime.start_handoff_run(...)
  assert {:error, :invalid_projected_context} = Runtime.start_handoff_run(...)
end
```

### Operator-guide wording for default-vs-optional lane separation
**Source:** `docs/operator_verification.md` (lines 7-16, 21-35, 99-121)
**Apply to:** `43-CLOSEOUT.md` proof-scope and unrelated-failure sections
```markdown
You have proven the default lane when all of these are true:

- `mix scoria.install` has wired the dashboard and baseline runtime defaults
- `mix ecto.migrate` and `mix test` pass for the host app
- one real run starts through `Scoria.start_run/2`
- that same run can be read back through `Scoria.get_run/1` or found via `list_runs_for_session/1`
- `/scoria/workflows/:run_id` shows operator evidence for that exact run

You do not need pgvector, knowledge tables, retrieval, grounding, or `mix scoria.test.knowledge` to prove the core lane.

Use `mix test.adoption` for fast feedback over the install, route, runtime, docs, and migration-lane guards that make up the bounded acceptance harness.
Use `mix scoria.test.knowledge` only when you are intentionally validating the full knowledge lane.
```

## No Analog Found

None. Phase 43 is a documentation-and-closeout pass over existing proof surfaces; the repo already contains strong analogs for the ledger and status updates.

## Metadata

**Analog search scope:** `.planning/`, `docs/`, `lib/mix/tasks/`, `test/scoria/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-24

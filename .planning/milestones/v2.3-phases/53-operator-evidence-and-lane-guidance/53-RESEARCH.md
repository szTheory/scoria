# Phase 53: Operator Evidence and Lane Guidance - Research

**Researched:** 2026-05-27 [VERIFIED: system date]
**Domain:** Phoenix LiveView operator evidence, Scoria runtime DTO projection, adoption documentation drift checks [VERIFIED: 53-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: local code/docs/tests + HexDocs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Operator evidence projection
- **D-01:** Tighten the existing curated `DelegatedEvidenceComponent` on `/scoria/workflows/:run_id`; do not introduce a new public API, raw table readback path, or separate notebook-style delegated forensics surface in Phase 53.
- **D-02:** "Easy to inspect" means one stable delegated-evidence anchor that shows the three scan-depth evidence dimensions together: same-run lineage, bounded projected-context summary, and delegated outcome/status.
- **D-03:** Empty, pending, and completed delegated states should remain explicit. Empty state should reinforce that normal default-lane runs are valid; pending state should show that the handoff is recorded even before delegated child execution completes; completed/running/failed states should keep status visible without hiding lineage or projected context.
- **D-04:** Operator evidence should continue to flow through the curated `Scoria.get_run_detail/1` DTO and `detail.delegated_handoffs`, not through adopter-facing raw workflow internals.

### Lane decision wording
- **D-05:** Use evidence-triggered escalation wording across docs: start with the default runtime lane; escalate to bounded handoff only when there is a real same-run delegation need with narrow, host-controlled projected context and operator-visible delegated lineage.
- **D-06:** Bounded handoff must not be framed as required for first adoption. The docs should be blunt that `mix test.adoption` and the default runtime lane prove the first adoption boundary before optional lanes are layered in.
- **D-07:** Preserve the Phase 52 ownership split: the host app owns identity, escalation policy, prompt/draft selection, and projected-context selection; Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback.
- **D-08:** Prefer precise modal language over loose "should" guidance where support truth matters. Use direct phrasing such as "start here", "add this only when", and "you do not need" for prerequisite boundaries.

### Drift checks
- **D-09:** Pin Phase 53 drift at the public-contract layer using existing ExUnit patterns, not snapshots or new rendered-doc tooling.
- **D-10:** `test/scoria/adoption_surface_test.exs` should own broad docs invariants: default lane first, bounded handoff as escalation, no first-adoption handoff requirement, v2.2 lane hierarchy, public facade over raw internals.
- **D-11:** `Scoria.TestSupport.AdoptionExample` and existing source-doc tests should pin example API fragments: `Scoria.identity/1`, `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`, `delegated_handoffs`, and `session_id` versus `run_id`.
- **D-12:** Existing LiveView/runtime tests should pin operator-visible evidence vocabulary and DTO behavior: `Delegated Evidence`, handoff input, projected context, parent/child same-run lineage, and empty/pending delegated states.

### Phase 54 boundary
- **D-13:** Phase 53 stops after evidence-surface tightening, lane wording alignment, and source/docs drift checks for those contracts.
- **D-14:** Phase 54 owns the canonical runtime-to-handoff proof command, prerequisite-denial proof, support-surface command naming, generated-host or bounded executable proof mechanics, and milestone closeout truth.
- **D-15:** Phase 53 docs may reference current truth such as `mix test.adoption` as the default-lane verifier, but must not publish a placeholder runtime-to-handoff proof command or imply that Phase 54 proof already exists.

### Claude's Discretion
- Exact UI copy, visual hierarchy, and component factoring are left to the planner/executor as long as the evidence dimensions and lane-boundary decisions above remain intact.
- Exact test grouping is left to the planner/executor as long as public-contract drift checks stay lightweight and do not absorb Phase 54 executable proof scope.

### Deferred Ideas (OUT OF SCOPE)
- Canonical runtime-to-handoff proof command and executable proof lane - Phase 54.
- Optional semantic/knowledge prerequisite-denial proof for the runtime-to-handoff lane - Phase 54.
- Support-surface command naming and milestone closeout verification ledger - Phase 54.
- Notebook-style delegated forensics or richer audit workbench - defer unless real operator confusion proves the curated evidence digest insufficient.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVID-01 | Operator can inspect the default run, delegated handoff lineage, projected-context summary, and delegated outcome from the existing Scoria operator surfaces. [VERIFIED: .planning/REQUIREMENTS.md] | Use `Scoria.get_run_detail/1` -> `Runtime.get_run_detail!/1` -> `RunDetail.from_run_tree/2` -> `detail.delegated_handoffs`, rendered by `ScoriaWeb.DelegatedEvidenceComponent` on `/scoria/workflows/:run_id`. [VERIFIED: lib/scoria.ex, lib/scoria/runtime.ex, lib/scoria/runtime/run_detail.ex, lib/scoria_web/live/workflow_live/show.ex] |
| DOCS-01 | README, operator verification, or adopter guide wording explains when a Phoenix team should stay on the default runtime lane versus escalate into bounded handoff. [VERIFIED: .planning/REQUIREMENTS.md] | Update `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, `docs/phoenix_runtime_example.md`, and `docs/bounded_handoffs.md` with default-first, evidence-triggered escalation wording, then pin through `test/scoria/adoption_surface_test.exs` and source-fragment tests. [VERIFIED: 53-CONTEXT.md, README.md, docs/adoption_lanes.md, docs/operator_verification.md, test/scoria/adoption_surface_test.exs] |
</phase_requirements>

## Summary

Phase 53 should be planned as a tightening phase, not a new capability phase: the runtime DTO, LiveView component, docs pages, and ExUnit drift-check seams already exist and match the locked scope. [VERIFIED: 53-CONTEXT.md, lib/scoria/runtime/run_detail.ex, lib/scoria_web/components/delegated_evidence_component.ex, test/scoria/adoption_surface_test.exs]

The operator evidence path should stay on the curated public readback surface: `Scoria.get_run_detail/1` delegates to `Runtime.get_run_detail/1`, `RunDetail.from_run_tree/2` constructs `delegated_handoffs`, and `WorkflowLive.Show` assigns that list into `DelegatedEvidenceComponent`. [VERIFIED: lib/scoria.ex, lib/scoria/runtime.ex, lib/scoria/runtime/run_detail.ex, lib/scoria_web/live/workflow_live/show.ex]

The docs work should preserve the `v2.2` lane hierarchy: default runtime lane first, bounded handoff as an escalation only for real same-run delegation with narrow projected context, semantic fast path as optional safe read-only reuse, and knowledge as optional retrieval/grounding. [VERIFIED: README.md, docs/adoption_lanes.md, docs/operator_verification.md, .planning/STATE.md]

**Primary recommendation:** Plan three small tracks: tighten the existing `DelegatedEvidenceComponent` labels/states, align lane wording across public docs, and add public-contract ExUnit drift checks without adding Phase 54 proof-command scope. [VERIFIED: 53-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Curated delegated evidence DTO | API / Backend | Database / Storage | `Runtime.get_run_detail!/1` loads the persisted run tree and `RunDetail.from_run_tree/2` derives the public `delegated_handoffs` projection from workflow steps and handoffs. [VERIFIED: lib/scoria/runtime.ex, lib/scoria/runtime/run_detail.ex] |
| Operator evidence rendering | Frontend Server (SSR/LiveView) | API / Backend | `WorkflowLive.Show` assigns `detail.delegated_handoffs` and renders `DelegatedEvidenceComponent` in the server-rendered LiveView page. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex, lib/scoria_web/components/delegated_evidence_component.ex] |
| Lane guidance docs | Static docs / Package extras | Test layer | README and `docs/*.md` are included as docs/package extras, while ExUnit file assertions pin support-truth wording. [VERIFIED: mix.exs, test/scoria/adoption_surface_test.exs] |
| Drift checks | Test layer | Static docs / Frontend Server | Existing tests use `File.read!` for docs invariants and LiveView render assertions for operator vocabulary/state coverage. [VERIFIED: test/scoria/adoption_surface_test.exs, test/scoria_web/live/workflow_live_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Build, compile, and run ExUnit tests. [VERIFIED: `elixir --version`, `mix --version`] | Project declares `elixir: "~> 1.19"` and the local toolchain satisfies it. [VERIFIED: mix.exs, shell probe] |
| Phoenix | 1.8.7 locked | Router/endpoint foundation for dashboard LiveView tests. [VERIFIED: mix.lock, `mix deps`] | Existing dashboard test endpoint and routes use Phoenix Router/Endpoint patterns. [VERIFIED: test/scoria_web/live/workflow_live_test.exs] |
| Phoenix LiveView | 1.1.30 locked | Server-rendered workflow page and function component rendering. [VERIFIED: mix.lock, `mix deps`] | Existing evidence UI uses `Phoenix.Component` with `attr` and HEEx, and official docs define `attr/3`, `~H`, and component compile-time validation behavior. [VERIFIED: lib/scoria_web/components/delegated_evidence_component.ex; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| Ecto SQL / Postgrex | Ecto SQL 3.13.5 locked, Postgrex 0.22.1 locked | DB-backed runtime and LiveView tests. [VERIFIED: mix.lock, `mix deps`] | Existing tests use SQL sandbox checkout/shared mode around persisted workflow records. [VERIFIED: test/scoria_web/live/workflow_live_test.exs, test/scoria/runtime_test.exs; CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html] |
| ExUnit | bundled with Elixir 1.19.5 | Unit, docs-invariant, and LiveView tests. [VERIFIED: `elixir --version`, test files] | Existing phase patterns use ExUnit assertions, `File.read!`, and LiveViewTest helpers rather than snapshot tooling. [VERIFIED: test/scoria/adoption_surface_test.exs, test/scoria_web/live/workflow_live_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix.LiveViewTest | 1.1.30 via `phoenix_live_view` | Mount `/scoria/workflows/:run_id`, assert rendered text, and click workflow tree elements. [VERIFIED: mix.lock, test/scoria_web/live/workflow_live_test.exs] | Use for operator-visible vocabulary/state assertions; official docs show `live(conn, "/path")`, `element/3`, and `render_click/1` patterns. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Floki | 0.38.1 locked | HTML parser configured for LiveView tests. [VERIFIED: mix.lock, test/test_helper.exs] | Keep existing parser setup; no new rendered-doc tooling is needed. [VERIFIED: test/test_helper.exs, 53-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `DelegatedEvidenceComponent` | New delegated forensics notebook | Out of scope because D-01 and deferred ideas explicitly reject a new notebook-style surface in Phase 53. [VERIFIED: 53-CONTEXT.md] |
| `Scoria.get_run_detail/1` DTO | Raw `workflow_steps` / `workflow_handoffs` reads | Out of scope because public docs/tests already refute raw internals and D-04 requires curated readback. [VERIFIED: 53-CONTEXT.md, test/scoria/adoption_surface_test.exs] |
| ExUnit file/render assertions | Snapshots or generated rendered-doc tooling | Out of scope because D-09 locks existing ExUnit public-contract patterns. [VERIFIED: 53-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```
[VERIFIED: mix.exs]

**Version verification:** `mix deps` verified the locked versions for Phoenix, Phoenix LiveView, Ecto SQL, Postgrex, and Floki; `mix hex.info` showed newer releases for some packages, but Phase 53 should use the project-locked versions rather than introduce dependency upgrades. [VERIFIED: `mix deps`, `mix hex.info phoenix_live_view`, `mix hex.info phoenix`, `mix hex.info ecto_sql`, `mix hex.info floki`]

## Architecture Patterns

### System Architecture Diagram

```text
Host/adopter run
  |
  v
Scoria public facade
  |-- default lane: Scoria.start_run/2
  |-- escalation lane: Scoria.start_handoff_run/3
  v
Workflow persistence
  |-- run identity: actor_id / tenant_id / session_id
  |-- handoff row: delegated role / kind / input
  |-- child step: parent_step_id / projected_context / status
  v
Curated readback: Scoria.get_run_detail/1
  v
RunDetail.delegated_handoffs
  |-- no handoffs -> valid default-lane empty state
  |-- handoff without child readback -> pending state
  |-- child status present -> completed/running/failed state
  v
/scoria/workflows/:run_id
  v
DelegatedEvidenceComponent
  |-- same-run lineage
  |-- projected-context preview/full context
  |-- delegated outcome/status
```
[VERIFIED: lib/scoria.ex, lib/scoria/runtime.ex, lib/scoria/runtime/run_detail.ex, lib/scoria_web/live/workflow_live/show.ex, lib/scoria_web/components/delegated_evidence_component.ex]

### Recommended Project Structure

```text
lib/scoria/runtime/run_detail.ex                  # Curated DTO projection for delegated_handoffs. [VERIFIED: local file]
lib/scoria_web/components/delegated_evidence_component.ex # Operator evidence component to tighten. [VERIFIED: local file]
lib/scoria_web/live/workflow_live/show.ex         # Existing /scoria/workflows/:run_id integration point. [VERIFIED: local file]
docs/adoption_lanes.md                            # Lane hierarchy and default-to-handoff decision wording. [VERIFIED: local file]
docs/operator_verification.md                     # Default lane proof and operator verification wording. [VERIFIED: local file]
README.md                                         # Public support hierarchy summary. [VERIFIED: local file]
test/scoria/adoption_surface_test.exs             # Broad public docs invariants. [VERIFIED: local file]
test/support/scoria/adoption_example.ex           # Shared docs/source fragments. [VERIFIED: local file]
test/scoria_web/live/workflow_live_test.exs       # Operator evidence render/state assertions. [VERIFIED: local file]
```

### Pattern 1: Curated DTO Before UI

**What:** Build operator evidence from `RunDetail.from_run_tree/2` and pass `detail.delegated_handoffs` into the LiveView component. [VERIFIED: lib/scoria/runtime/run_detail.ex, lib/scoria_web/live/workflow_live/show.ex]

**When to use:** Use this whenever Phase 53 needs additional operator-facing delegated evidence fields or wording. [VERIFIED: 53-CONTEXT.md]

**Example:**
```elixir
detail = Runtime.get_run_detail!(run_id)

socket
|> assign(:run_detail, detail)
|> assign(:delegated_handoffs, detail.delegated_handoffs)
```
[VERIFIED: lib/scoria_web/live/workflow_live/show.ex]

### Pattern 2: Explicit Empty / Pending / Populated Evidence States

**What:** The component already renders an empty state, a pending child-step status, and populated cards for delegated evidence. [VERIFIED: lib/scoria_web/components/delegated_evidence_component.ex]

**When to use:** Keep all three states visible when tightening copy so default-lane adoption remains valid and handoff progress remains inspectable. [VERIFIED: 53-CONTEXT.md, test/scoria_web/live/workflow_live_test.exs]

**Example:**
```elixir
assert empty_html =~ "No Delegated Handoffs Recorded"
assert pending_html =~ "child step pending"
assert html =~ "Delegated Evidence"
assert html =~ "projected context"
```
[VERIFIED: test/scoria_web/live/workflow_live_test.exs]

### Pattern 3: Public Docs Invariants via File Assertions

**What:** Public docs drift is pinned by reading Markdown files and asserting required/forbidden strings. [VERIFIED: test/scoria/adoption_surface_test.exs]

**When to use:** Use this for lane hierarchy, default-first wording, no raw internals, no placeholder Phase 54 command, and no implication that handoff is required for first adoption. [VERIFIED: 53-CONTEXT.md]

**Example:**
```elixir
content = File.read!("docs/adoption_lanes.md")

assert content =~ "Default runtime lane"
assert content =~ "Bounded handoff lane"
refute content =~ "mix scoria.test.knowledge"
```
[VERIFIED: test/scoria/adoption_surface_test.exs]

### Anti-Patterns to Avoid

- **New public API for evidence readback:** Phase 53 is locked to `Scoria.get_run_detail/1` and `detail.delegated_handoffs`. [VERIFIED: 53-CONTEXT.md]
- **Raw workflow internals in adopter docs:** Existing tests refute `Scoria.Workflows.create_run`, `Repo.all`, `workflow_steps`, and `workflow_handoffs` in public handoff docs. [VERIFIED: test/scoria/adoption_surface_test.exs]
- **Placeholder runtime-to-handoff proof command:** Phase 54 owns the canonical proof command, so Phase 53 docs must not publish one. [VERIFIED: 53-CONTEXT.md]
- **Framing bounded handoff as first-adoption work:** D-06 requires default runtime lane and `mix test.adoption` to remain the first adoption boundary. [VERIFIED: 53-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Delegated evidence readback | Raw table readback or ad hoc SQL DTO | `Scoria.get_run_detail/1` and `RunDetail.delegated_handoffs` | Existing DTO already combines handoff input, parent/child lineage, child status, projected context, and capability tags. [VERIFIED: lib/scoria/runtime/run_detail.ex] |
| Operator evidence surface | Separate forensics notebook | Existing `DelegatedEvidenceComponent` on `/scoria/workflows/:run_id` | D-01 locks the surface and the component already renders empty/pending/populated states. [VERIFIED: 53-CONTEXT.md, lib/scoria_web/components/delegated_evidence_component.ex] |
| Docs drift detection | Snapshot framework or rendered-doc generator | ExUnit `File.read!` assertions and shared fragment lists | Existing docs tests already pin public wording and forbidden internals. [VERIFIED: test/scoria/adoption_surface_test.exs, test/support/scoria/adoption_example.ex] |
| LiveView behavior testing | Browser automation for this phase | `Phoenix.LiveViewTest.live/2`, `element/3`, `render_click/1` | Existing tests cover `/scoria/workflows/:run_id` render output without a browser, and official LiveViewTest docs support these helpers. [VERIFIED: test/scoria_web/live/workflow_live_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

**Key insight:** The planner should treat Phase 53 as public-contract tightening over already persisted truth; custom tooling would widen scope and reduce alignment with existing phase patterns. [VERIFIED: 53-CONTEXT.md, 52-PATTERNS.md]

## Common Pitfalls

### Pitfall 1: Mixing Phase 53 And Phase 54 Proof Scope

**What goes wrong:** Docs accidentally name a new runtime-to-handoff proof command before it exists. [VERIFIED: 53-CONTEXT.md]
**Why it happens:** Operator verification docs already contain several proof lanes, which makes it easy to add a plausible but unsupported command. [VERIFIED: docs/operator_verification.md]
**How to avoid:** Reference `mix test.adoption` only as the current default-lane verifier and state that runtime-to-handoff proof is separate Phase 54 work if needed. [VERIFIED: 53-CONTEXT.md]
**Warning signs:** New wording near `docs/operator_verification.md` closeout or README verification sections that implies bounded handoff has a canonical proof command. [VERIFIED: docs/operator_verification.md, README.md]

### Pitfall 2: Making Empty Delegated Evidence Look Like Failure

**What goes wrong:** Operators may read a default run with no handoffs as incomplete adoption. [VERIFIED: 53-CONTEXT.md]
**Why it happens:** The evidence component has a prominent empty-state block. [VERIFIED: lib/scoria_web/components/delegated_evidence_component.ex]
**How to avoid:** Keep empty copy explicit that no bounded handoff is recorded yet and default-lane runs remain valid. [VERIFIED: 53-CONTEXT.md]
**Warning signs:** Empty state uses warning/error language or says an adopter should add handoff to complete setup. [VERIFIED: 53-CONTEXT.md]

### Pitfall 3: Hiding Pending Child-Step State

**What goes wrong:** A handoff row can exist before child-step readback completes, and hiding that state loses operator evidence. [VERIFIED: 53-CONTEXT.md, lib/scoria/runtime/run_detail.ex]
**Why it happens:** `RunDetail.child_step_status(nil)` returns `child_step_pending`, which is a synthetic curated state rather than a database status. [VERIFIED: lib/scoria/runtime/run_detail.ex]
**How to avoid:** Keep `child step pending` visible in UI and test it. [VERIFIED: lib/scoria_web/components/delegated_evidence_component.ex, test/scoria_web/live/workflow_live_test.exs]
**Warning signs:** Tests only assert completed handoff cards and stop asserting pending copy. [VERIFIED: test/scoria_web/live/workflow_live_test.exs]

### Pitfall 4: Raw Internal Leakage In Docs

**What goes wrong:** Adoption docs may tell users to inspect workflow tables or call internal workflow APIs. [VERIFIED: test/scoria/adoption_surface_test.exs]
**Why it happens:** The evidence originates from workflow rows, but the public contract is curated readback. [VERIFIED: lib/scoria/runtime/run_detail.ex, 53-CONTEXT.md]
**How to avoid:** Keep examples on `Scoria.start_run/2`, `Scoria.start_handoff_run/3`, `Scoria.get_run_detail/1`, and `/scoria/workflows/:run_id`. [VERIFIED: 53-CONTEXT.md, test/support/scoria/adoption_example.ex]
**Warning signs:** Public docs mention `Scoria.Workflows.create_run`, `Repo.all`, `workflow_steps`, or `workflow_handoffs`. [VERIFIED: test/scoria/adoption_surface_test.exs]

## Code Examples

### Delegated DTO Shape

```elixir
%{
  handoff_id: handoff.id,
  parent_step_id: handoff.step_id,
  parent_step_sequence: parent_step && parent_step.sequence,
  delegated_role_id: handoff.delegated_role_id,
  delegated_kind: handoff.delegated_kind,
  handoff_input: handoff.handoff_input,
  child_step_id: child_step && child_step.id,
  child_status: child_step_status(child_step),
  status: child_step_status(child_step),
  projected_context: child_projected_context(child_step)
}
```
[VERIFIED: lib/scoria/runtime/run_detail.ex]

### LiveView Evidence Assertions

```elixir
{:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

assert html =~ "Delegated Evidence"
assert html =~ "Lineage"
assert html =~ "Projected Context Preview"
assert html =~ "child step pending"
```
[VERIFIED: test/scoria_web/live/workflow_live_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Docs Drift Assertion

```elixir
content = File.read!("README.md")

assert content =~ "Default runtime lane"
assert content =~ "Bounded handoff lane"
assert content =~ "mix test.adoption"
refute content =~ "workflow_handoffs"
```
[VERIFIED: test/scoria/adoption_surface_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prose-only adoption guidance | ExUnit-pinned docs/source fragments | Established before Phase 53 and reused by Phase 52. [VERIFIED: 52-PATTERNS.md, 52-03-SUMMARY.md] | Planner should add assertions near existing docs tests rather than introduce separate tooling. [VERIFIED: 53-CONTEXT.md] |
| Raw workflow reconstruction for delegated evidence | Curated `RunDetail.delegated_handoffs` readback | Existing repo truth before Phase 53. [VERIFIED: lib/scoria/runtime/run_detail.ex] | UI/docs should describe curated evidence, not internal tables. [VERIFIED: 53-CONTEXT.md] |
| Broad optional-lane adoption story | `v2.2` lane hierarchy with default first | Shipped in `v2.2` on 2026-05-26. [VERIFIED: .planning/STATE.md, .planning/PROJECT.md] | Phase 53 wording must not imply semantic/knowledge/handoff prerequisites for first adoption. [VERIFIED: 53-CONTEXT.md] |

**Deprecated/outdated:**
- `mix scoria.test.knowledge` is refuted by existing docs tests; use `mix test.knowledge` for the optional knowledge lane. [VERIFIED: test/scoria/adoption_surface_test.exs, docs/operator_verification.md]
- Raw workflow internals in public handoff docs are refuted by existing tests. [VERIFIED: test/scoria/adoption_surface_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No new dependency installation is needed for Phase 53 beyond the existing locked project stack. [ASSUMED] | Standard Stack | If wrong, planner may omit an install/setup task for a hidden docs or UI tool. |

## Open Questions (RESOLVED)

1. **Should the UI add a stronger default-lane-valid empty-state sentence or only adjust existing copy?** [RESOLVED]
   - What we know: D-03 requires the empty state to reinforce that normal default-lane runs are valid. [VERIFIED: 53-CONTEXT.md]
   - Resolution: Add the stronger default-lane-valid empty-state sentence from `53-UI-SPEC.md`: "This run stayed on the default runtime lane. No bounded handoff is required for first adoption; use `Scoria.start_handoff_run/3` only when a same-run delegation needs narrow projected context." [VERIFIED: 53-UI-SPEC.md]
   - Plan impact: `53-01-PLAN.md` should include a copy-only acceptance check in `test/scoria_web/live/workflow_live_test.exs` that pins the default-lane-valid empty state. [VERIFIED: existing test pattern]

2. **Should `docs/operator_verification.md` get a bounded-handoff decision subsection in Phase 53?** [RESOLVED]
   - What we know: DOCS-01 can be satisfied through README, operator verification, or adopter guide wording. [VERIFIED: .planning/REQUIREMENTS.md]
   - Resolution: Add a concise default-to-handoff decision point in `docs/operator_verification.md` and keep README/adopter-guide wording aligned. The wording must say to start with the default runtime lane, add bounded handoff only for same-run delegation with narrow projected context and operator-visible delegated lineage, and avoid naming any new Phase 54 proof command. [VERIFIED: 53-CONTEXT.md, 53-UI-SPEC.md]
   - Plan impact: `53-02-PLAN.md` should cover `docs/operator_verification.md`, `README.md`, `docs/adoption_lanes.md`, `docs/phoenix_runtime_example.md`, and `docs/bounded_handoffs.md` with a docs-invariant verification path. [VERIFIED: 53-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile and run ExUnit tests. [VERIFIED: mix.exs] | yes [VERIFIED: shell probe] | 1.19.5 / OTP 28 [VERIFIED: `elixir --version`] | None needed. [VERIFIED: local availability] |
| Mix | Dependency and test commands. [VERIFIED: mix.exs] | yes [VERIFIED: shell probe] | 1.19.5 / OTP 28 [VERIFIED: `mix --version`] | None needed. [VERIFIED: local availability] |
| PostgreSQL server | DB-backed runtime and LiveView tests. [VERIFIED: config/test.exs, test files] | yes [VERIFIED: `pg_isready`] | Server accepting on `/tmp:5432`; client `psql` 14.17. [VERIFIED: `pg_isready`, `psql --version`] | Docs-only tests can run without DB, but EVID-01 tests require DB. [VERIFIED: test/scoria/runtime_test.exs, test/scoria_web/live/workflow_live_test.exs] |

**Missing dependencies with no fallback:** None found for Phase 53 research. [VERIFIED: shell probes]

**Missing dependencies with fallback:** None found for Phase 53 research. [VERIFIED: shell probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5. [VERIFIED: `elixir --version`, test/test_helper.exs] |
| Config file | `config/test.exs`; `test/test_helper.exs` starts Scoria and configures LiveView HTML parser as Floki. [VERIFIED: config/test.exs, test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` [VERIFIED: existing tests] |
| Full phase command | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria_web/live/workflow_live_test.exs` [VERIFIED: existing tests] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| EVID-01 | Operator can inspect default empty state, delegated lineage, projected context, and delegated outcome/status on `/scoria/workflows/:run_id`. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView integration + runtime unit | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria_web/live/workflow_live_test.exs` [VERIFIED: existing tests] | yes [VERIFIED: rg/files] |
| DOCS-01 | Public docs explain default runtime lane versus bounded handoff escalation without making handoff first-adoption required. [VERIFIED: .planning/REQUIREMENTS.md] | Docs invariant + source-fragment tests | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` [VERIFIED: existing tests] | yes [VERIFIED: rg/files] |

### Sampling Rate

- **Per task commit:** Run the most targeted changed-test command from the map above. [VERIFIED: existing phase patterns in 52-03-SUMMARY.md]
- **Per wave merge:** Run the full phase command above. [VERIFIED: 52-03-SUMMARY.md]
- **Phase gate:** Full phase command green before `/gsd-verify-work`. [VERIFIED: GSD workflow expectation]

### Wave 0 Gaps

- None: existing test infrastructure covers the Phase 53 files and requirements. [VERIFIED: test/scoria/adoption_surface_test.exs, test/scoria_web/live/workflow_live_test.exs, test/scoria/runtime_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct Phase 53 change [VERIFIED: 53-CONTEXT.md] | Preserve host-owned identity boundary in docs; do not add auth flow. [VERIFIED: 53-CONTEXT.md] |
| V3 Session Management | yes, wording only [VERIFIED: docs/phoenix_runtime_example.md] | Keep `session_id` as continuity key and `run_id` as exact execution handle. [VERIFIED: docs/phoenix_runtime_example.md, test/support/scoria/adoption_example.ex] |
| V4 Access Control | no direct Phase 53 change [VERIFIED: 53-CONTEXT.md] | Do not introduce new public API or raw internals path. [VERIFIED: 53-CONTEXT.md] |
| V5 Input Validation | yes, existing projected-context contract [VERIFIED: lib/scoria/runtime/params.ex] | Preserve `Params.validate_projected_context/1` and docs around `{:error, :unsafe_projected_context}`. [VERIFIED: lib/scoria/runtime/params.ex, docs/bounded_handoffs.md] |
| V6 Cryptography | no direct Phase 53 change [VERIFIED: 53-CONTEXT.md] | Do not add cryptographic behavior. [VERIFIED: 53-CONTEXT.md] |

### Known Threat Patterns for Scoria Runtime-to-Handoff Docs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hidden transcript/session/header leakage through projected context | Information Disclosure | Keep docs and tests aligned to unsafe-key rejection and host-controlled narrow context. [VERIFIED: lib/scoria/runtime/params.ex, test/scoria/runtime_test.exs, docs/bounded_handoffs.md] |
| Raw workflow table guidance becoming public support path | Information Disclosure / Tampering | Keep adopter guidance on `Scoria.get_run_detail/1` and refute raw internals in docs tests. [VERIFIED: 53-CONTEXT.md, test/scoria/adoption_surface_test.exs] |
| Unsupported proof command in docs | Repudiation | Keep Phase 54 proof command out of Phase 53 docs and pin with public docs assertions if wording changes. [VERIFIED: 53-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/53-operator-evidence-and-lane-guidance/53-CONTEXT.md` - locked decisions, discretion, deferred scope. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - EVID-01 and DOCS-01 requirement text. [VERIFIED: local file]
- `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md` - milestone state, lane hierarchy, Phase 53/54 boundary. [VERIFIED: local files]
- `lib/scoria.ex`, `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_detail.ex`, `lib/scoria/runtime/params.ex` - public facade, runtime readback, DTO, projected-context validation. [VERIFIED: local files]
- `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/components/delegated_evidence_component.ex` - operator route integration and delegated evidence UI. [VERIFIED: local files]
- `test/scoria/runtime_test.exs`, `test/scoria_web/live/workflow_live_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/support/scoria/adoption_example.ex` - existing verification patterns. [VERIFIED: local files]
- Phoenix Component docs - `attr/3`, HEEx/function component validation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html]
- Phoenix LiveViewTest docs - `live/2`, `element/3`, `render_click/1`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Ecto SQL Sandbox docs - checkout/shared-mode test connection behavior and `start_owner!/2` guidance. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html]

### Secondary (MEDIUM confidence)

- `mix hex.info phoenix_live_view`, `mix hex.info phoenix`, `mix hex.info ecto_sql`, `mix hex.info floki` - current Hex release metadata and locked version comparison. [VERIFIED: shell command]

### Tertiary (LOW confidence)

- None. [VERIFIED: source list]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `mix.exs`, `mix.lock`, `mix deps`, local toolchain probes, and Hex metadata. [VERIFIED: local commands]
- Architecture: HIGH - verified from source files and tests named by Phase 53 context. [VERIFIED: local files]
- Pitfalls: HIGH - derived from locked decisions, existing docs tests, and Phase 52 summary. [VERIFIED: 53-CONTEXT.md, 52-03-SUMMARY.md]

**Project constraints:** No `AGENTS.md`, `CLAUDE.md`, `.claude/skills`, or `.agents/skills` files were found in the project root during research. [VERIFIED: shell probes]
**Graph context:** `.planning/graphs/graph.json` was not found, so no graph context was injected. [VERIFIED: shell probe]
**Research date:** 2026-05-27 [VERIFIED: system date]
**Valid until:** 2026-06-26 for code/test patterns; re-check Hex versions before dependency changes. [ASSUMED]

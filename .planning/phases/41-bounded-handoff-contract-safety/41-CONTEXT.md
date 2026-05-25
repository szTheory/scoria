# Phase 41: Bounded Handoff Contract & Safety - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the public bounded handoff lane as one narrow, explicit, same-run runtime contract with durable lineage truth and projected-context guardrails. This phase formalizes the public `Scoria.start_handoff_run/3` contract and the minimum truthful readback needed to verify it. It does not widen Scoria into a general orchestration platform, and it does not absorb the richer operator-surface/docs coherence work already scoped to Phase 42.

</domain>

<decisions>
## Implementation Decisions

### Public handoff contract strictness
- **D-01:** `Scoria.start_handoff_run/3` stays the public happy-path facade shape, but its handoff semantics become explicit rather than inferred.
- **D-02:** The public contract should require explicit `root_role_id`, explicit `delegated_kind`, explicit `handoff_input` semantics, and explicit `projected_context` semantics. The host app should intentionally state the delegated contract Scoria will persist and later display.
- **D-03:** Remove semantic defaults that hide intent at the public boundary. In particular, do not treat default `root_role_id: "executor"` or default `delegated_kind: "delegated_task"` as the shipped public contract.
- **D-04:** Stop implicitly copying `payload` / `input` into `projected_context`. If the host wants something inside `projected_context`, it must opt into that exact slice explicitly.
- **D-05:** `projected_context: %{}` is valid when the host intentionally wants no delegated context. The public contract should not force fake content just to satisfy a required field.

### Projected-context safety boundary
- **D-06:** `projected_context` remains a flexible map, but the public lane must validate and normalize it before durable persistence, not only during step execution.
- **D-07:** Phase 41 should not ship a pure narrow top-level denylist as the full safety model. Instead, use a denylist-plus-semantic-boundary posture: reject obviously broad or platform-owned delegated state while preserving a narrow host-controlled slice.
- **D-08:** Unsafe or out-of-bounds projected state includes broad transcript/history/messages/session blobs, provider-session/runtime state, Plug/LiveView/socket state, assigns/private/session/cookies/headers, secrets-bearing state, and similarly broad delegated context aliases or nested equivalents.
- **D-09:** Validation should recurse through the projected context structure deeply enough to avoid false safety from simple renaming or nesting tricks.
- **D-10:** Validation failures should be explicit and user-oriented. This is a contract error, not a mysterious runtime outcome. The error should explain that bounded handoffs require a small projected slice rather than broad runtime state.

### Public truth vs adjunct metadata
- **D-11:** The core public handoff truth for Phase 41 is: root role, delegated role, delegated kind, handoff input, same-run lineage, and projected-context safety.
- **D-12:** `capability_tags` may remain persisted and surfaced as optional adjunct metadata, but they are not execution truth, not approval truth, not policy truth, and not a completeness promise about delegated capabilities.
- **D-13:** Public docs and examples must teach the narrow core contract first. If `capability_tags` remain public at all, they should be framed as optional host-supplied labels/hints with no implied ontology or authorization meaning.

### Phase 41 vs Phase 42 boundary
- **D-14:** Phase 41 must ship the minimum inspectability baseline required to make the public contract honest. A caller should be able to read back, through public runtime/detail surfaces, the root role, delegated role, delegated kind, bounded projected-context slice, same-run parent/child lineage, and explicit unsafe-context failure outcome.
- **D-15:** Phase 42 remains responsible for richer DTO shaping, operator-surface coherence, docs/source/example alignment, and determining whether any remaining adopter-facing rough edges are real follow-on value.
- **D-16:** Do not let Phase 41 absorb broad operator UX polish or broader adoption-story cleanup. The goal here is contract honesty and safety, not a full delegated-lineage presentation pass.

### DX and shift-left posture
- **D-17:** For this public lane, Scoria should prefer an ergonomic shell with an explicit domain contract. The public call shape should stay simple, but hidden semantic magic should move out of the contract.
- **D-18:** Shift low-impact handoff decisions left inside Scoria and future GSD flows wherever possible. Reserve user interruption for product-shape, security-boundary, durable-truth, or support-truth decisions, not routine naming/normalization choices.
- **D-19:** Phase 41 should improve principle-of-least-surprise DX with strong validation and clear errors rather than with silent defaults. “Fast to type” is not more valuable than “obvious when inspected” for this lane.

### the agent's Discretion
- Exact validation implementation and helper decomposition, provided validation happens before durable persistence and clearly enforces the bounded projected-context contract.
- Exact error tuple / changeset / exception shape, provided the failure is explicit, actionable, and public-surface-safe.
- Exact DTO field naming for minimum inspectability, provided the baseline readback remains boring and stable across Phase 41 and does not force Phase 42 to redefine the contract.
- Exact treatment of `capability_tags` in docs/types/tests, provided they remain clearly secondary to the core handoff truth.

</decisions>

<specifics>
## Specific Ideas

- The public runtime story should feel like `Req` or `Oban`: one obvious high-level call, deeper layers available if needed, but no requirement for host apps to understand workflow-engine internals.
- The bounded handoff lane should feel closer to “explicit Phoenix library boundary” than to “general agent SDK magic.”
- The useful adopter story is not “Scoria can hand work to another role”; it is “Scoria can hand work to another role with explicit, inspectable, least-privilege context under the same durable run.”
- If migration pressure exists from the current looser behavior, a short deprecation bridge is acceptable, but the shipped truth for Relay should still be the explicit contract above.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 41 scope, success criteria, and the split between Phase 41 and Phase 42.
- `.planning/PROJECT.md` - active `v2.0 Relay` milestone thesis, bounded-handoff product boundary, and explicit support-truth goals.
- `.planning/REQUIREMENTS.md` - `HAND-01`, `HAND-02`, `SAFE-01`, and `SAFE-02`.
- `.planning/STATE.md` - current strategic decisions, especially the narrow public handoff posture and projected-context boundary.
- `.planning/METHODOLOGY.md` - decisive-defaults lens; shift low-impact choices left and interrupt only on meaningful boundary decisions.

### Prior locked Scoria decisions and local lessons
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - public runtime APIs should use runtime nouns, not raw workflow-engine nouns; boring explicit app-facing contracts outrank magic.
- `.planning/memory/bounded-handoff-productization-lessons.md` - projected context is the real product boundary; support truth is part of productization; public handoffs should stay narrow.
- `.planning/research/milestone-options-2026-05-12.md` - least-surprise Phoenix adoption means public runtime clarity before adding breadth.
- `.planning/research/elixir-ai-ecosystem.md` - Scoria should own the operator-facing control plane and keep broad orchestration scope constrained.
- `.planning/research/agentcore-lessons.md` - keep runtime state, auth, tool access, and observability explicit; avoid catch-all platform drift.

### Product and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria’s operator-grade Phoenix-native product framing.
- `prompts/phoenix-ai-lib-deep-research.md` - small primitive set, trace-first defaults, explicit handoff/runtime nouns, and Phoenix-native control-plane lessons.
- `prompts/scoria-brand-book-deep-research.md` - calm operator-grade, evidence-first tone; avoid confusing platform sprawl.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first DX, embedded dashboards, and Ecto-native state.

### Current code and docs surface
- `lib/scoria.ex` - top-level public facade that should remain the happy-path entrypoint.
- `lib/scoria/runtime.ex` - public handoff start and run-detail readback surface.
- `lib/scoria/runtime/params.ex` - current public-input normalization, including the defaults and implicit payload projection that Phase 41 should tighten.
- `lib/scoria/workflows/runtime.ex` - current handoff execution seam and projected-context safety enforcement.
- `lib/scoria/workflows/handoff.ex` - durable handoff row shape, including adjunct metadata such as `capability_tags`.
- `lib/scoria/runtime/run_detail.ex` - current public detail DTO and the minimum inspectability surface that must become truthful in Phase 41.
- `docs/bounded_handoffs.md` - current public handoff guide and inspectability promise.
- `test/scoria/adoption_surface_test.exs` - adoption-lane support-truth assertions for the bounded handoff guide.
- `test/scoria/handoff_example_source_test.exs` - checked source fragment alignment for bounded handoff docs.
- `test/support/scoria/adoption_example.ex` - canonical checked handoff example fragments.
- `test/scoria/workflows/runtime_test.exs` - durable handoff/root-ownership and projected-context behavior expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Runtime.Params.start_handoff/3` already centralizes the public handoff input normalization seam; it is the right place to tighten the explicit contract and move validation earlier.
- `Scoria.Runtime.start_handoff_run/3` already provides the correct happy-path facade shape and should remain the top-level entrypoint.
- `Scoria.Workflows.Runtime.handle_handoff/3` already owns same-run delegated-step creation and is the substrate for durable lineage truth.
- `Scoria.Runtime.RunDetail` already provides a curated detail DTO and is the natural place for the minimum truthful readback baseline required in Phase 41.
- `Scoria.Workflows.Handoff` already persists adjunct metadata such as `capability_tags`, which means the phase should classify it cleanly rather than pretend it does not exist.

### Established Patterns
- Scoria favors durable Ecto truth over process-local or UI-only state.
- Public runtime APIs should be narrow, explicit, and app-facing, while workflow-engine seams remain substrate.
- Operator surfaces should read curated DTOs rather than force callers to inspect raw workflow rows.
- Support truth matters: docs, examples, public DTOs, and runtime behavior should all describe the same lane.

### Integration Points
- Phase 41 changes should center on `lib/scoria/runtime/params.ex`, `lib/scoria/runtime.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/runtime/run_detail.ex`, the bounded handoff guide, and the checked adoption/source tests.
- Public handoff validation should happen before run/step persistence so unsafe context does not become durable truth first and a runtime failure later.
- Minimum inspectability should project through the existing public runtime detail path and the existing workflow evidence route instead of inventing a new read surface in this phase.
- Phase 42 will build on the stable Phase 41 readback fields rather than redefining them.

</code_context>

<deferred>
## Deferred Ideas

- Broad autonomous multi-agent orchestration surface or platform-like handoff expansion - explicitly out of scope for Relay.
- A strict fully typed `projected_context` schema or rich allowlisted envelope - potentially valuable later, but too rigid for this phase’s intended host-controlled slice.
- Richer delegated-lineage operator UX polish, docs/source alignment, and any adopter-facing handoff-story expansion beyond the minimum truthful readback baseline - belongs to Phase 42.
- Stronger bounded-handoff examples beyond the current guide and adoption lane unless later phases prove real adopter confusion remains.

</deferred>

---

*Phase: 41-bounded-handoff-contract-safety*
*Context gathered: 2026-05-24*

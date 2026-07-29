# Phase 56 Discussion Log

**Date:** 2026-07-28
**Method:** 3 parallel research agents + 1 adversarial red-team pass, synthesized into a locked spec. No interactive Q&A (standing user preference).
**Human input:** one instruction — "follow ur recs auto get us on track." No gray areas were put to the user; all were resolved by research + red-team.

## Gray areas identified

| ID | Area | Resolved as |
|----|------|-------------|
| GA-1 | Declaration surface | D-01 — `@optional_callbacks classification/0` + `use` macro |
| GA-2 | What "unclassified" resolves to | D-03 — maximal fallback, still runs, default-off strict flag |
| GA-3 | Rails enforcement + halt | Deferred to Phase 56.1 (D-56.1-A..H) |
| GA-4 | Declaration vs host override | D-04 — tighten-only join, fallback is not an operand |

## What the red-team pass changed

The first synthesis was materially wrong in three ways. All three would have shipped as silent regressions:

1. **Self-annihilating default (B-1).** The draft set the unclassified default to the *maximal* lattice element AND made the join `max`, so the default dominated every declaration — clamping a host's `action_class: "read"` to `"admin"`, flipping `effectful_or_remote?/1` true, and turning working replay calls into `{:error, :replay_blocked}`. Fixed: the default is a fallback, never a join operand.
2. **False "replay-inert" justification (B-2/B-3).** The draft justified the maximal default via `effectful_or_remote?/1`, having examined only one `cond` clause. Two clauses above read `approval_sensitive`, which gates `live_override_ready?/2`. Separately `:local_classification` gates `pure_local?/1`. The write-prohibition list grew from two keys to five, and the inertness claim was retracted outright.
3. **A fifth fail-open site (B-4).** `workflows/runtime.ex:474` defaults `%{local_classification: :pure}` — a total replay bypass at step granularity, worse than the four the draft listed and absent from the requirement text.

It also caught that the phase-56 rails half claimed a terminal halt that `retry_step/1` silently reverses (B-5), and that `count(*)` for `max_steps` cannot see a retry loop because `retry_step/1` reuses the row (B-6).

## Scope decision

**Split.** RAIL-01 moved to a new Phase 56.1. Decisive evidence: `ROADMAP.md:72` states Phase 57 depends on Phase 56 for *"the taint substrate and the tool-declared classification"* — not rails. The halves share no files or failure modes, and rails need a schema migration classification does not. Splitting unblocks Phase 57 earlier.

Rails research was **not discarded** — D-56.1-A..H are recorded in CONTEXT.md `<deferred>` so 56.1 starts researched.

## Incidental finding (not phase 56 scope)

Phase 55's `scoria.trust.*` attributes never reach the persisted MCP tool span — `Adapters.MCP.emit_tool_span/4` uses a fixed projector and `merge_host_declared` only carries `~w(feature route archetype intent)a`. The RETRIEVER chokepoint is unaffected. Tracked in CONTEXT.md `<deferred>` as a phase-55 follow-up; it blocks Phase 57 from reading the tool-output leg off spans.

## Deferred ideas

None raised — no scope creep occurred, since there was no open-ended conversation to drift.

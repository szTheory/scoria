---
id: SEED-011
status: deferred
planted: 2026-07-03
deferred_on: 2026-07-09
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as privacy / compliance / human-in-the-loop feedback
scope: medium-large
priority: medium
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-011: Privacy & Feedback Governance

## Why This Matters

Two audit gaps that together unlock the **currently-unserved Privacy/legal/compliance persona** and
close the human-in-the-loop flywheel:
- **Privacy/retention MISSING.** `Observe.Redactor` is a tiny static deny-list; **no PII detection, no
  trace/span retention/TTL/purge** anywhere. An adopter on defaults accumulates sensitive traces
  indefinitely — a GDPR/right-to-erasure landmine. Because **Scoria creates and owns the trace/span/
  memory tables** in the host's Postgres, deletion is Scoria's job (the host has no natural seam to purge
  rows it doesn't model). *Peer precedent is unambiguous for the self-hostable tier: Langfuse owns a
  nightly retention-purge job (3-day min) + a data-deletion API; Arize Phoenix owns project-level trace
  retention purge.*
- **Human-feedback capture MISSING (stubbed).** Feedback Inbox is a `/coming/feedback-inbox` stub;
  thumbs/accept/edit/regenerate are not captured, so the flywheel ingests only *automated* scorer signals
  — even though the memo and Scoria's own methodology call human feedback the flywheel's core. The
  provenance rails already exist (`origin_context`, `evidence_refs`, `from=run:/incident:/review:`) and
  the promote-to-dataset path exists — feedback is the missing *source*, not the plumbing.

## When to Surface

**Trigger:** privacy/compliance or human-in-the-loop milestone. (The access-control *seam* half overlaps
[[SEED-006]] P0-3 — if 006 already shipped the `on_mount` pass-through + tenant callback, this seed only
adds the masking-contract + retention.)

## Scope Estimate

**Medium-Large.** `lib/scoria/observe/**`, `lib/scoria.ex` (facade APIs), `lib/scoria/eval.ex` (flywheel),
an Oban purge job (Scoria already runs Oban), the trace/memory migrations.

## What to build

1. **Trace/memory retention/TTL/purge + right-to-erasure (BUILD).** Per-tenant retention policy config
   (TTL; default off but loudly documented), an **Oban purge job** that nightly deletes traces/spans/
   span-events/compacted-memories past TTL (cascading via existing `on_delete: :delete_all` FKs), and an
   operator **"forget this trace / forget this memory"** single-record action. `ai_compacted_memories` is
   Scoria's table too — forget/expire controls belong here (the `MemoryNotebookComponent` is visibility-
   only today; forget-and-recompact is safer than mutating a summary → defer inline edit).
2. **PII masking contract + regex pack (DELEGATE+DOC + small BUILD).** Do NOT build a names/emails/cards
   classifier — Langfuse explicitly doesn't either; it ships a masking *hook* + "bring Presidio." Scoria
   already has the hook (`Redactor` `:mfa`). Deliverable: (a) **document `:mfa` as THE PII-masking
   contract** with a "bring Presidio" example, (b) ship an opt-in regex pattern pack (email/CC/SSN) as a
   saner default, (c) confirm/extend coverage beyond span attrs + stream text.
3. **Structured human-feedback capture → flywheel (BUILD).** A public `Scoria` facade capture API the host
   calls on a thumbs/accept/edit/regenerate/report event, writing a feedback record keyed to
   `trace_id`/`run_id`/`span_id` (reuse `origin_context`/`evidence_refs`); de-stub `/coming/feedback-inbox`
   into a real inbox; wire feedback into the existing `promote_review_candidate` → dataset path (a
   thumbs-down becomes a dataset row / baseline request). Reuse the OnlineScoreCandidate/ReviewQueue
   machinery — not a parallel stack. *Peers: LangSmith annotation queues + feedback API; Langfuse scores/annotations.*
4. **Dashboard authorization seam (BUILD seam + DOC) — if not already shipped in [[SEED-006]] P0-3.**
   Pass-through `on_mount:` + documented tenant-resolution/authorization callback so `tenant_id` is
   host-asserted, not a `"default"`-fallback param. Explicitly **no in-lib role model** (host owns authz).

## Disagreements with the memo (recorded)
- The memo (hosted-platform lens) implies Scoria should ship full RBAC + a PII-classification engine —
  both are host duties for an embedded lib; Scoria ships *hooks/contracts* (masking hook, authz seam), not
  a role model or classifier. (Langfuse's self-hosted design — masking hook, not classifier — is the precedent.)
- Inverse: the memo may *under*-weight retention/purge as optional ops nicety — but because Scoria *owns*
  the tables, right-to-erasure is non-negotiable. You can delegate RBAC/PII; you cannot delegate deletion
  of tables you own.

## Scope doctrine reference
P1/P5 (Scoria owns the durable *record* in the host's own DB → owns its lifecycle/deletion; zero egress) +
P2/P4 (masking + authz are *hooks/contracts*, not opinions — host supplies the classifier + the authz decision).

## Breadcrumbs
- `lib/scoria/observe/redactor.ex` (`:mfa` masking hook to formalize + regex pack),
  `lib/scoria/eval.ex` (`sample_trace_for_online_scoring`, `promote_review_candidate` — flywheel to extend),
  `lib/scoria.ex` (facade for feedback-capture + retention/forget APIs),
  `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs` (trace/span tables + cascade FKs for purge),
  `lib/scoria_web/components/memory_notebook_component.ex` (visibility-only; add forget/expire),
  `lib/scoria_web/router.ex` (`scoria_dashboard/2` authz seam — shared with [[SEED-006]] P0-3).
- Sources: memo §7,13; Langfuse data-retention/deletion/masking docs; LangSmith annotation queues. Full audit: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`. Related: [[SEED-006]], [[SEED-007]], [[SEED-005]].

## AI-Architecture-Patterns cross-ref (2026-07-03)

Source memo: `.planning/research/ai-architectural-patterns.md` §12 (memory / personalization). Validates
this seed's stance that **memory is a database, not a bigger prompt** — scoped, permissioned, reviewable,
and deletable; the memory-types table (preference / project-fact / user-profile / task-state) with
per-type write policy; and the hard rule **"never store account state as memory — fetch it fresh"**
(cross-tenant/stale-memory hazards). Directly reinforces item 1 (forget/expire on `ai_compacted_memories`)
and item 2 (masking contract). No new work; the memo is the "why" for the retention/forget deliverables.

## Operator-UI North-Star cross-ref (2026-07-03)

Source memo: `.planning/research/operator-ui-north-star.md`. This seed owns the **Data & Privacy section**
the [[SEED-013]] IA pivot reserves as a top-level home:
- **Forget-actor / forget-tenant / purge-run flow** — enter a reference → **impact preview** (affected
  traces / memory / cache / eval cases / audit constraints) → choose purge policy → confirm → receipt.
  **Purge must preserve an anonymized audit receipt** even while deleting payloads (reconciles
  right-to-erasure with immutable audit — directly item 1 of this seed).
- **Retention + PII-masking display** — retention windows (raw prompts / redacted traces / eval cases /
  memory / cache) and masking coverage surfaced as **operational controls, not hidden config** (item 2's
  `:mfa` masking contract made visible).
- **Memory & semantic-cache made inspectable-like-a-run** — memory records (scope/subject-ref/source-run/
  last-used/PII flag) with edit/delete/forget; cache entries with eligibility + invalidation reasons.
- **Human-feedback capture feeds the unified Queue** — thumbs/accept/edit/report events (item 3) become
  **Queue "review case" items** in the North-Star inbox and flow to the promote-to-dataset flywheel. No
  new work; the memo is the "why" for giving these a first-class operational home.

## Notes
Planted during v3.3 from a 6-agent adjudicated audit. Serves the "your AI audit trail never leaves your
own Postgres" embedded story — a killer compliance differentiator vs every SaaS competitor, low build
cost, high trust payoff.

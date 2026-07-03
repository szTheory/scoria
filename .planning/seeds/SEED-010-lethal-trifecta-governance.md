---
id: SEED-010
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as agent security / governance — sequence early (after SEED-006 + SEED-007)
scope: large
priority: high
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-010: Lethal-Trifecta Governance ⭐ FLAGSHIP DIFFERENTIATOR

> **Maintainer decision (2026-07-03): FLAGSHIP BET.** Sequence early (right after [[SEED-006]] P0s +
> [[SEED-007]] trace foundation) and headline it in docs/positioning ([[SEED-005]]). This is the
> category-defining wedge Scoria is uniquely positioned for.

## Why This Matters

The "lethal trifecta" (Simon Willison) / Meta's "Agents Rule of Two": an agent that combines **private
data access + untrusted-content exposure + external-communication (exfil)** in one path is exploitable;
the named mitigation is to allow at most two, and **require human supervision when all three co-occur**.
Every peer treats this as *advice* (Willison, Meta Rule of Two, HiddenLayer, Oso) — **no mainstream
LLM-ops library ships it as a reusable runtime enforcement seam.**

Scoria is ~one-and-a-half pieces away from being first: it **already owns two of the three legs as
enforcement seams** — the exfil leg (audit outbox + effectful tool classes + `ReplayDisposition` gating)
and the private-data leg (connector grants + knowledge) — plus an audited two-step approval mechanism.
It's missing (a) the untrusted-content leg and (b) a confluence policy that escalates. This aligns
perfectly with the embedded positioning: the *mechanism* (escalate-on-confluence) is Scoria's; the
*decision* (approve/deny) stays with the host approver.

## When to Surface

**Trigger:** agent-security/governance milestone, sequenced **early** per the flagship decision (after
[[SEED-006]] P0s + [[SEED-007]] traces provide the taint-tracking substrate).

## Scope Estimate

**Large.** `lib/scoria/mcp/**`, `lib/scoria/workflows/replay_disposition.ex`, `lib/scoria/knowledge/chunk.ex`,
plus a SECURITY-BOUNDARY.md doc.

## What to build

1. **Content trust tiers + spotlighting (BUILD substrate).** Add a trust-tier/taint tag on
   `Knowledge.Chunk` metadata + a tool-output envelope (retrieved chunks and tool outputs are currently
   never treated as untrusted). Add **spotlighting/delimiting/datamarking** at prompt assembly in the
   orchestrator — the standard cheap model-agnostic untrusted-content defense. Add a `scan/2` behaviour
   **hook** (default no-op) for BYO Rebuff/LlamaGuard. **Do NOT ship a detector/classifier** — that's the
   model layer / host (observability peers ship none; Anthropic hardens at the model via RL). This supplies
   the missing untrusted-content leg.
2. **Tool-declared trifecta classification (BUILD).** Extend the `Tool` behaviour with the three legs
   (`reads_private_data` / `sees_untrusted_content` / `can_exfiltrate`) + `action_class`, **declared once
   on the tool** instead of passed per-call. This kills the concrete footgun where
   `Executor.build_replay_seam/2` defaults an *unclassified* tool to `approval_sensitive: false`
   (`executor.ex:150-165`) — so today the trifecta exfil signal can't rely on host defaults. Per-user/
   per-intent *allowlist* stays DELEGATED (host identity/policy).
3. **Confluence escalation policy (BUILD — the differentiator).** A confluence evaluator (mirroring
   `ReplayDisposition`'s seam-classification style) that, when private-data + untrusted-content + exfil
   co-occur in one tainted execution path, **escalates to approval / human-in-the-loop** — enforced at
   `MCP.Executor`, audited + replayable. This is Meta's Rule-of-Two as actual policy.
4. **Safety hook surface (DOCS + BYO via existing seam).** Wire a **moderation** scorer + an
   **output-scanner** hook through the *already-existing* `Eval.online_scoring`/`judge_runner` scorer seam
   (cheap — the seam exists); tag model output "untrusted" in traces. Do NOT ship opinionated moderation
   or an output sanitizer (sinks + content policy = host/jurisdiction). Write **SECURITY-BOUNDARY.md** — a
   shared-responsibility doc (what Scoria enforces vs what the host must) — the real deliverable spanning
   improper-output-handling + moderation + system-prompt-leakage + per-user allowlists.

## Disagreements with the memo (recorded)
- Prompt-injection "MISSING → Scoria should defend": partial DISAGREE. Detection/classification is NOT
  Scoria's — it owns the *taint substrate + delimiting + BYO hook*, not a scanner. Building a detector is
  the over-reach anti-pattern.
- "Per-user/intent allowlist": that's host identity/policy — delegating it is *correct*, not a gap. Only
  tool-*declared* classification is Scoria's.
- Improper-output-handling: sinks belong to the host; the deliverable is DOCS + an optional hook, not a
  Scoria sanitizer library.

## Scope doctrine reference
P2 (Scoria owns the governance *mechanism* — the confluence gate; host owns the approve/deny *decision*) +
P4 (per-user allowlist = host identity). The mechanism/decision split is exactly what makes this
in-scope for an embedded lib without over-reaching into host policy.

## Breadcrumbs
- `lib/scoria/mcp/tool.ex` (extend behaviour with declared trifecta classification),
  `lib/scoria/mcp/executor.ex` (enforcement point + the `approval_sensitive: false` default footgun at :150-165),
  `lib/scoria/workflows/replay_disposition.ex` (mirror this seam-classification pattern),
  `lib/scoria/knowledge/chunk.ex` (attach trust-tier/taint tag), `lib/scoria/eval/online_scoring.ex`
  (existing scorer seam for BYO moderation/injection scanners), `lib/scoria/observe/redactor.ex`.
- Sources: memo §11,12; Willison "lethal trifecta"; Meta "Agents Rule of Two" (Nov 2025); OWASP LLM Top 10
  2025; MSRC spotlighting. Full audit: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`. Related: [[SEED-006]], [[SEED-007]], [[SEED-005]] (headline in docs).

## AI-Architecture-Patterns cross-ref (2026-07-03)

Source memo: `.planning/research/ai-architectural-patterns.md` §6 (tool-calling) + §13 (guardrail/safety
harness) + **Rule 3 ("a tool is a loaded interface")**. Reinforces the tool-declared-classification bet:
prefer **narrow / typed / permission-aware / idempotent / reversible / dry-run-capable** tools that make
mistakes harder; expose a safer intermediate (`draft_refund_request`) not the raw effectful op
(`send_money_now`). The memo's "the real defense is the agent does not have the blast radius" is exactly
this seed's mechanism-over-prompt thesis.

- **One addition — per-run agent-rails note (§10 agentic loop):** the memo hammers `max_steps` /
  `max_tool_calls` / `timeout` scoped to a *single run* ("an agent without a step limit is a fork bomb
  with prose"). This is **distinct** from SRE's *tenant-level* budgets/breakers — it's a per-run rail.
  Fold as a small addition to the confluence-escalation / executor work here (or note for the host
  contract); do NOT spin a new seed.

## Operator-UI North-Star cross-ref (2026-07-03)

Source memo: `.planning/research/operator-ui-north-star.md`. **Richest UI match in the storyboard** — this
flagship seed owns the **Govern section** the [[SEED-013]] IA pivot elevates to first-class ("don't bury
the differentiator under Settings"):
- **Tools & blast-radius panel** — per tool/connector, the compound-risk facts *reads private data ·
  reads untrusted content · external egress · side effect · irreversible · approval required* — this is
  the tool-declared trifecta classification (item in "What to build") rendered visually.
- **The "exfiltration path" framing** — the UI must **name dangerous combinations**, not just label "high
  risk": "private data + untrusted content + external egress → **exfiltration path**." That is the
  confluence/Meta-Rule-of-Two escalation shown to a human.
- **Approval-policy builder + policy test-on-past-runs** — plain-language `When … Then pause & require
  approval`, plus a **simulate-on-history** step ("would have matched 38 runs — 32 correct, 4 unnecessary,
  2 need review") as an explicit **approval-fatigue preventer**. Mechanism, not opinion (P2).
- **Guardrail screens** — gate location (input/context/tool/output/memory), decision (allow/warn/block/
  escalate), triggering evidence, FP/FN feedback. Reinforces the seam that Scoria's edge is **inline
  blocking, not passive observation**. The North-Star doc is the UI "why"; the enforcement seams are this
  seed's build.

## Notes
Planted during v3.3 from a 6-agent adjudicated audit; elevated to **flagship** by maintainer decision.
The safety adjudicator's verdict: Scoria is "one leg (untrusted-content taint) and one confluence
evaluator away from being the first embedded framework to enforce Rule-of-Two as audited, replayable
policy." Headline framing for [[SEED-005]]: *"the first embedded framework that escalates to a human
when a run touches private data, untrusted content, and an exfil channel at once."*

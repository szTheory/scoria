# Phase 47: README first-screen positioning and scope doctrine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-09
**Phase:** 47-README first-screen positioning and scope doctrine
**Areas discussed:** README first screen, owns-vs-delegates table, persona and NOT-OURS framing, hosted/external LLM-ops comparison

---

## README First Screen

| Option | Description | Selected |
|--------|-------------|----------|
| Plain-English embedded Phoenix library front door | Explain existing-app install, durable runs, traces, `/scoria`, reviewer, BEAM/Postgres boundary, and not-hosted posture before capability vocabulary. | yes |
| Refined capability ladder front door | Smallest diff from current README, but still teaches coined taxonomy too early. | |
| Quickstart/code-first front door | Familiar library pattern, but buries Scoria's trust boundary and makes it look like another LLM client. | |
| Hosted LLM-ops comparison front door | Strong differentiation, but defensive and stale-prone as an opening. | |

**User's choice:** Discuss/consider all with subagent-backed research and one coherent recommendation.
**Notes:** Recommendation is to lead with the SEED-005 plain-English paragraph, then who/not-for, then scope/comparison links, then capability ladder and install.

---

## Owns-vs-Delegates Table

| Option | Description | Selected |
|--------|-------------|----------|
| P1-P6 doctrine rows | Complete and traceable to PROJECT.md, but too abstract and planning-coded for adopters. | |
| Scenario/capability rows | Concrete adoption flow, but can duplicate the capability guide and go stale. | |
| Boundary / Scoria owns / Your app owns / Why / Example | Translates doctrine into adopter decisions and keeps backend guts behind useful product boundaries. | yes |
| Scope table plus hosted-comparison columns | Connects POS-03/POS-04, but overloads one table. | |

**User's choice:** Discuss/consider all with subagent-backed research and one coherent recommendation.
**Notes:** Recommendation is a 6-8 row public table covering run records, dashboard scope, governance gates, eval proof, knowledge, bounded handoffs, connectors, and Phoenix/BEAM infrastructure.

---

## Persona and NOT-OURS Framing

| Option | Description | Selected |
|--------|-------------|----------|
| Roles-not-headcount, n=1 default | Treat reviewer as a hat one Phoenix engineer may wear; matches PROJECT.md and SEED-005. | yes |
| JTBD-first Phoenix adopter framing | Strong readable surface, but needs explicit boundary table to avoid ambiguity. | yes |
| CORE / ADJACENT / NOT-OURS table | Durable scope boundary, but too heavy before the plain-English pitch. | yes |
| Hosted LLM-ops contrast as persona frame | Useful in comparison guide, not primary persona framing. | |

**User's choice:** Discuss/consider all with subagent-backed research and one coherent recommendation.
**Notes:** Recommendation combines the first three: what Scoria is, who uses it in n=1 terms, what the reviewer role does, then compact CORE/ADJACENT/NOT-OURS boundary.

---

## Hosted/External LLM-ops Comparison

| Option | Description | Selected |
|--------|-------------|----------|
| Direct named-competitor page | Useful for objections and SEO, but high drift and overclaim risk. | |
| Category-level only | Durable and clean in README, but evasive for people comparing named peers. | |
| Hybrid category-led README plus named peer guide | Keeps README clean while allowing honest source-linked comparison to LangSmith, Langfuse, Braintrust, and Arize Phoenix. | yes |

**User's choice:** Discuss/consider all with subagent-backed research and one coherent recommendation.
**Notes:** Recommendation is category-level README copy plus a stable comparison guide. Do not call every peer hosted SaaS; several offer self-hosted, hybrid, local, or open-source options.

---

## Claude's Discretion

- User explicitly asked for subagent research and a one-shot recommendation set so they would not need to decide every subchoice manually.
- Exact README copy can be tightened during planning/implementation if it preserves the locked facts.
- Exact table row count and comparison guide filename are left to planner/executor judgment.

## Deferred Ideas

- ExDoc/guide ladder restructure - Phase 48.
- AI-readable root docs - Phase 49.
- Hex release cut and final release reconciliation - Phase 50.
- OpenInference export, lethal-trifecta governance, eval-depth, RAG-depth, privacy/retention, and structural reviewer UI pivot - future seeds.

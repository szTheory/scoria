---
status: archived
archived_on: 2026-05-22
title: Future High-Value Scoria JTBDs and Capabilities
---

# SEED-002: Future High-Value Scoria JTBDs & Capabilities

**Created:** 2026-05-19
**Context:** Brainstorming session for high-value future roadmap items beyond `v1.7 Outrider`.
**Purpose:** Ensure these deeply researched capabilities are considered for future milestones, preserving architectural intent, trade-offs, and ecosystem lessons learned.

---

## 1. JTBD: "The What-If Sandbox" (Time-Travel Replay & Branching)
**The Problem:** A user complains the AI hallucinated an answer. You find the trace in Scoria. You see the AI called the "Lookup Order" tool, got a weird JSON response, and panicked. How do you test a fix without pushing code to production?
**The Flow:** In the Scoria Trace Explorer, the operator clicks **"Branch & Replay"** on a failed step. They tweak the system prompt (or mock a tool response) and hit "Run". Scoria forks the trace context and executes the rest of the workflow in the dashboard to verify the fix.

*   **Idiomatic Architecture:** Since runs and steps are immutable Ecto records, branching is trivial. Duplicate the execution graph up to the breakpoint, initialize a new `Scoria.Workflows.Run` struct in memory, and re-inject the context.
*   **Pros:** Turns "debugging" directly into "solution creation." Incredible operator DX.
*   **Cons/Tradeoffs:** Replaying a trace might accidentally trigger side-effecting tools (like sending an email twice).
*   **Lessons Learned (LangSmith):** Platforms offer trace replay, but users often accidentally re-trigger live APIs.
*   **The Scoria UX Solution:** When a trace is in "Replay" mode, Scoria's MCP Gateway automatically mocks all tool calls marked as `side_effect: :external_write`, returning the historical JSON from the original trace unless explicitly overridden.

## 2. JTBD: Multi-Agent Handoffs (The Context Router)
**The Problem:** A single massive prompt trying to be a Support Agent, a Billing Agent, and a Tech Agent simultaneously results in a confused, expensive, and slow LLM.
**The Flow:** A user asks to change their credit card. The "Triage Agent" analyzes the intent, realizes it lacks billing permissions, and yields. Scoria seamlessly suspends the Triage Run, initializes a "Billing Agent" run, passes a summarized context payload, and streams output back to the Phoenix socket seamlessly.

*   **Idiomatic Architecture:** Leverage OTP and the actor model. Agents are functional data structures (cf. Jido's v2 design). The Scoria runtime handles the `yield` and `resume` lifecycle, ensuring strict tool policies are enforced per agent.
*   **Pros:** Massive cost savings (smaller prompts), better security (least privilege per agent).
*   **Cons/Tradeoffs:** Risk of infinite routing loops (Agent A routes to B, which routes to A).
*   **Lessons Learned (OpenAI Swarm/LangGraph):** Handoffs are powerful but notoriously hard to debug.
*   **The Scoria UX Solution:** The LiveView Trace Explorer gets a "Subway Map" visualization, showing exactly which agent held the baton. The runtime enforces a hard `max_handoffs_per_session` limit.

## 3. JTBD: Semantic Caching (The 50ms Fast Path)
**The Problem:** 40% of users ask the exact same question. The host app pays $0.01 and waits 4 seconds to generate the exact same answer repeatedly.
**The Flow:** Scoria intercepts the incoming message, performs a fast vector similarity search in Ecto, finds a 98% similar question from 10 minutes ago, bypasses the LLM entirely, and returns the cached answer in 50ms.

*   **Idiomatic Architecture:** Utilize the existing `pgvector` RAG setup. Add a `Scoria.Cache` Plug/middleware. Save embeddings for high-confidence answers.
*   **Pros:** Drastically reduces latency and token costs. Makes the app feel magically fast.
*   **Cons/Tradeoffs:** Caching highly personalized data is a massive security risk.
*   **Lessons Learned (GPTCache):** Global caches leak PII across tenants.
*   **The Scoria UX Solution:** The cache is strictly partitioned by `tenant_id` and `actor_id` at the Ecto query level. If an answer relies on a tool call marked `personalized: true`, Scoria refuses to cache it. Safety over speed.

## 4. JTBD: "The Auto-QA" (Online Scoring & Dataset Promotion)
**The Problem:** 99% of AI interactions are never read by humans. There is no visibility into tone degradation or subtle unhelpfulness.
**The Flow:** Configure an "Online Eval". An Oban worker samples 5% of production traces hourly, using a cheap model (like Haiku) to score them for helpfulness. Poorly scored traces are flagged in LiveView and promoted to an ExUnit "Regression Dataset".

*   **Idiomatic Architecture:** Pure Elixir synergy. `Oban` handles cron scheduling. `Phoenix.PubSub` streams results. `Ecto` stores `Scoria.EvalScore` records.
*   **Pros:** Shifts QA from reactive to proactive. Builds a massive regression dataset automatically.
*   **Cons/Tradeoffs:** "LLM-as-a-judge" can drift or be biased.
*   **Lessons Learned (Arize Phoenix / Braintrust):** Blind trust in automated scores leads to alert fatigue when they get noisy.
*   **The Scoria UX Solution:** Require operators to occasionally perform "Calibration Reviews." The UI compares human scores to LLM scores to detect judge drift.

## Resolution

Archived as a future-ideas reference on 2026-05-22.

This document captures valid long-range product ideas, but none is committed as active milestone work. Keeping it archived preserves the research without treating it as unresolved planning debt during milestone close. Revisit it explicitly during future milestone discovery if one of these JTBDs becomes the highest-priority next bet.

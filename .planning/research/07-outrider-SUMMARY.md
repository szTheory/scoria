# Research Summary: Scoria v1.7 Outrider

**Domain:** Embedded Phoenix-native AI Application Quality Layer
**Researched:** 2024-05-28
**Overall confidence:** HIGH

## Executive Summary

The "v1.7 Outrider" milestone aims to extend Scoria's reach by integrating with external agent runtimes and implementing advanced memory/session compaction, all without compromising its embedded Phoenix architecture. Research indicates that the Model Context Protocol (MCP) is the prevailing industry standard for multi-runtime interoperability. By adopting MCP via SSE (Server-Sent Events) or WebSockets, Scoria can act as an orchestration or quality layer for external Python/Node runtimes without the instability risks of in-process execution (NIFs). 

For memory compaction, idiomatic Elixir dictates pushing heavy LLM summarization out of the web request lifecycle. Utilizing Oban for asynchronous compaction jobs, combined with Ecto and `pgvector` (already present in the Scoria environment) for semantic retrieval, provides a robust, scalable solution.

## Key Findings

**Stack:** Standard Phoenix + LiveView, Oban (async jobs), Req (HTTP/SSE), Ecto + `pgvector`. No external frameworks like Ash.
**Architecture:** Out-of-process multi-runtime integration (HTTP/SSE/WebSockets) and Async Compaction Pipelines.
**Critical pitfall:** Blocking BEAM schedulers with synchronous memory compaction LLM calls or relying on unstable NIFs for Python/JS interoperability.

## Implications for Roadmap

Based on research, suggested phase structure for v1.7:

1. **Phase: Out-of-Process Interoperability Standard (MCP)** - Implement SSE/HTTP-based MCP Client/Host interfaces.
   - Addresses: Multi-runtime interoperability without giving up the embedded Phoenix shape.
   - Avoids: Crashing the BEAM with untrusted Python/JS NIFs.

2. **Phase: Async Session Compaction Engine** - Introduce Oban-backed workers to summarize and vectorize old context.
   - Addresses: Advanced memory/session compaction strategies.
   - Avoids: Memory leaks and prompt token-limit exhaustion.

3. **Phase: External Runtime Telemetry & LiveView Tooling** - Extend existing LiveView operator UX to monitor external runtimes.
   - Addresses: Deep integrations with external agent runtimes while keeping observability local.

**Phase ordering rationale:**
- Protocol and integration boundaries must be established first so that memory compaction can be tested against real multi-runtime data payloads.

**Research flags for phases:**
- Phase 1: May need deep-dive into standardizing MCP (Model Context Protocol) specifically for Elixir, as SDKs are still maturing. Standard Phoenix Plugs and `Req` are sufficient.
- Phase 2: Standard patterns (Oban + Ecto + pgvector), unlikely to need deep technical research, primarily product decisions on compaction triggers (time-based vs. token-based).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Elixir's concurrency and Oban/Req are perfectly suited for these tasks. |
| Features | HIGH | Clear mapping between goals and Phoenix capabilities. |
| Architecture | HIGH | Standard distributed systems boundaries apply perfectly here. |
| Pitfalls | MEDIUM | LLM compaction lossiness is an industry-wide open problem, requires careful prompt engineering. |

## Gaps to Address

- Determining the optimal heuristic for triggering compaction (e.g., sliding window of N tokens vs. inactivity timeouts).
- Deciding whether Scoria acts primarily as an MCP Host (calling out to tools) or an MCP Client (providing tools/memory to external agents), or both.

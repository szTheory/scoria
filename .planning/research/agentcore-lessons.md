# AWS AgentCore Lessons for Scoria

**Researched:** 2026-05-11
**Domain:** Managed agent runtime / tool governance / agent observability
**Confidence:** HIGH

## Executive Summary

Amazon Bedrock AgentCore is best understood as a managed boundary layer for agents, not a monolithic framework. Its core design centers on explicit runtime sessions, separate memory and identity services, governed tool access through Gateway, and first-class observability and policy controls. That shape is useful for Scoria as a reference, but only if we preserve Scoria’s embedded Phoenix identity and avoid drifting into an AWS-shaped platform.

The strongest lesson is to keep agent logic portable while externalizing runtime state, auth, tool access, and observability. The strongest caution is that “enterprise-grade” does not mean “safe by default”: AWS’s own docs and the public feedback both show that identity scoping, IAM least privilege, session mapping, and sandbox boundaries still need careful engineering.

## What AgentCore Gets Right

- Clear separation of concerns: runtime, memory, gateway, identity, observability, policy, registry, and built-in tools are distinct services.
- Session-first execution: each user session is sticky, isolated, and correlated through explicit session IDs.
- Tool governance: Gateway and Identity make tool access an explicit policy boundary instead of a hidden implementation detail.
- Observability as a product surface: traces, metrics, and logs are part of the platform contract, not an afterthought.
- Managed prototype path: the harness and CLI reduce infrastructure friction for teams that want to test an idea quickly.

## Tradeoffs and Costs

- Strong AWS coupling: the platform is opinionated about runtime contract, IAM, regions, quotas, and deployment workflow.
- Python-centered ergonomics: the official quickstarts and SDK surface are heavily Python-first, which does not map cleanly to an embedded Elixir product.
- Operational complexity remains: identity, session mapping, policy sizing, and runtime limits still require real discipline.
- Convenience vs control: the managed harness is faster to start with, but it is less aligned with an architecture that wants transparent, embedded control.

## Lessons Scoria Should Adopt

### 1. Keep the Phoenix control plane and externalize execution boundaries

Scoria should stay the embedded Phoenix product layer while treating any future agent runtime integration as a separate execution plane. That keeps the library composable, portable, and aligned with the current architecture.

### 2. Make session and actor identity explicit

Borrow the AgentCore lesson that session IDs, actor IDs, and auth are separate concerns. Scoria should keep durable session state in Ecto and never rely on process-local memory as the source of truth.

### 3. Treat tool access as governed infrastructure

AgentCore’s Gateway/Identity split reinforces Scoria’s MCP boundary work: tool access should be policy-backed, auditable, and scoped at the boundary, not scattered through agent code.

### 4. Keep observability core to the contract

Scoria should continue treating traces, span kinds, token streaming, and replay as core product behavior. AgentCore confirms that operator trust depends on explicit observability.

### 5. Prefer deterministic paths for deterministic work

AgentCore’s harness and code-interpreter ergonomics are useful, but they also show how quickly an agent runtime can become a catch-all. Scoria should keep deterministic tasks out of the agent loop when ordinary Elixir code is sufficient.

## Anti-Patterns To Avoid

- Building an AWS-shaped control plane inside Scoria.
- Letting runtime session state masquerade as durable product state.
- Assuming IAM defaults or sandbox isolation are sufficient security boundaries.
- Making every capability a built-in runtime service instead of keeping the core library small and embedded.
- Copying the managed harness pattern into Scoria’s core architecture.

## Scoria Design Implications

- Preserve `scoria_observe`, `scoria_eval`, and MCP governance as the center of gravity.
- Keep future agent-hosting integrations behind adapters and configuration, not as the default architecture.
- Treat any browser/code-execution style feature as opt-in and policy-gated.
- Strengthen docs around session mapping, auth boundaries, and least-privilege defaults.

## Sources

- [What is Amazon Bedrock AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html)
- [AgentCore harness](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/harness.html)
- [Runtime sessions](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-sessions.html)
- [Identity overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html)
- [Gateway docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html)
- [Runtime security best practices](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-security-best-practices.html)
- [Observability config](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability-configure.html)
- [Python SDK repo](https://github.com/aws/bedrock-agentcore-sdk-python)
- [TypeScript samples](https://github.com/awslabs/bedrock-agentcore-samples-typescript)
- [Public discussion and issue tracker](https://github.com/aws/bedrock-agentcore-sdk-python/issues)


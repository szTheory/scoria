# Connectors and MCP

Scoria registers remote MCP connectors inside your Phoenix app. Scoria owns connector records, discovery, auth storage, tool policy, approvals, and audit evidence. Your host app owns routing, session, tenant identity, business-specific allowlists, and the decision to expose a tool to a workflow.

Use this guide with [Default Runtime](guides/capabilities/default-runtime.md), [Reviewer Verification](guides/reviewer-verification.md), [Support Copilot Gallery](guides/capabilities/support-copilot-gallery.md), and the [glossary](guides/reference/glossary.md).

Connectors are optional. Use remote connectors after the default runtime capability is green with `$ mix test.adoption`. They add tool surfaces; they do not replace core runtime, identity, reviewer trace, approval, or verification suite contracts.

## When to use connectors

Choose this capability when:

- you need durable connector records, grants, and health state inside your Phoenix app
- reviewer fleet trace details matter for integration review
- remote MCP tools are part of your product workflow
- you have already proven the default runtime capability

Skip connectors on first adoption if you only need durable runs, reviewer traces, approvals, and bounded handoffs.

## Embedded boundary

| Your app owns | Scoria owns |
|---------------|-------------|
| Host routing, session, and tenant identity | Connector records, grants, and health state |
| When to escalate to human review | Tool policy, approval gates, and invocation audit |
| Business-specific tool allowlists | Curated connector profiles and boring install defaults |
| Product meaning of a tool result | Reviewer trace projection and durable audit evidence |

Scoria does not run connectors as a multi-tenant SaaS. Each connector invocation stays on your BEAM with your Ecto data.

## Public surfaces

The connector capability centers on these public surfaces:

- `Scoria.Connectors` for connector registration, lookup, health, and fleet behavior.
- `Scoria.Connectors.Auth` for host-owned auth handoff into connector records.
- `Scoria.MCP.Tool` for MCP tool metadata and invocation shape.

Keep tool grants narrow at first. Prove one read path before widening to write paths or broader connector scopes.

## Recommended path

1. Complete `$ mix scoria.install` and `$ mix test.adoption` on a branch that matches production constraints.
2. Register one connector through the Scoria dashboard or public API with the smallest grant set that proves the integration.
3. Run one approved invocation and confirm reviewer trace details: health, scopes, approval lineage, and audit evidence.
4. Add host-side guards for write paths before widening grants.

## Verification

- Default runtime verification suite: `$ mix test.adoption` - no connector setup required.
- Connector verification suite: `$ mix test.connector` - register -> fleet list -> reviewer drawer trace details using SupportJourney fixture identities, including the `billing` Billing MCP connector profile.
- Optional knowledge base verification suite: `$ mix test.knowledge` - only when grounding and retrieval are in scope.
- Semantic cache verification suite: `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path` - read-only cache profiles only.

Maintainer CI topology and verification-suite ordering live in [Reviewer Verification](guides/reviewer-verification.md).

## Further reading

- [Support Copilot Gallery](guides/capabilities/support-copilot-gallery.md) shows the repository-local connector scenario with `lookup_support_ticket` and `issue_refund` tools.
- [Semantic Cache](guides/capabilities/semantic-cache.md) is orthogonal to connectors; it handles safe read-only answer reuse, not remote tool registration.
- The old `docs/connector_adoption.md` source path remains compatibility material while this canonical guide ladder becomes the public path.

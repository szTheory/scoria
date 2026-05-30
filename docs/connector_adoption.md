# Remote connector adoption

Scoria registers **remote MCP connectors** inside your Phoenix app. Scoria owns discovery, auth storage, tool policy, approvals, and audit evidence — not a hosted connector platform.

## When to use connectors

Use remote connectors after the **default runtime lane** is green (`mix test.adoption`). Connectors add optional tool surfaces; they do not replace core runtime, identity, or approval contracts.

Skip connectors on first adoption if you only need durable runs, operator evidence, and bounded handoff.

## Embedded boundary

| Your app owns | Scoria owns |
|---------------|-------------|
| Host routing, session, and tenant identity | Connector records, grants, and health state |
| When to escalate to human review | Tool policy, approval gates, and invocation audit |
| Business-specific tool allowlists | Curated connector profiles and boring install defaults |

Scoria does **not** run connectors as a multi-tenant SaaS. Each connector invocation stays on your BEAM with your Ecto data.

## Recommended path

1. Complete `mix scoria.install` and `mix test.adoption` on a branch that matches production constraints.
2. Register one connector through the Scoria dashboard or public API with the smallest grant set that proves the integration.
3. Run one approved invocation and confirm operator evidence (health, scopes, approval lineage) in `/scoria`.
4. Add host-side guards for write paths before widening grants.

## Verification

- **Default:** `mix test.adoption` — no connector setup required.
- **Connector proof:** `mix test.connector` — register → fleet list → operator drawer evidence using SupportJourney fixture identities.
- **Optional knowledge:** `mix test.knowledge` — only when grounding/retrieval is in scope.
- **Semantic fast-path:** `mix test.semantic_fast_path` — read-only cache lanes only; see [semantic_fast_path.md](semantic_fast_path.md).

Maintainer CI topology and lane ordering: [MAINTAINERS.md#ci-gate-map-maintainers](MAINTAINERS.md#ci-gate-map-maintainers).

## Further reading

- Operator verification (approvals, evidence, lane boundaries): [operator_verification.md](operator_verification.md)
- Adoption lane ordering: [adoption_lanes.md](adoption_lanes.md)
- Semantic troubleshooting (orthogonal to connectors): [semantic_fast_path.md](semantic_fast_path.md)

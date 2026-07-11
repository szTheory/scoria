# Ownership Boundary

Scoria records, gates, surfaces, and reconstructs AI work inside your Phoenix app. Your app owns identity, authorization, tenant membership, policy values, prompts, expected outputs, corpus, and business meaning.

Use this guide with [Getting Started](guides/getting-started.md), [Golden Path](guides/golden-path.md), and the [Glossary](guides/reference/glossary.md) before adding optional capabilities.

## What Scoria owns vs what your app owns

| Boundary | Scoria owns | Your Phoenix app owns | Why this boundary exists | Example / verification |
|----------|-------------|-----------------------|--------------------------|------------------------|
| Run records and traces | Durable run records, trace projection, exact `run_id` readback, and reviewer inspection. | Ticket, order, customer, domain truth, and host IDs. | Scoria records execution without becoming your business database. | `Scoria.get_run/1` and `/scoria/workflows/:run_id`. |
| Reviewer dashboard scope | `/scoria`, the dashboard scope seam, trusted scope reads, and generic fail-closed copy. | Authentication, authorization, tenant membership, and role values. | Scoria can inspect only the tenant scope your app has already trusted. | `scoria_dashboard "/scoria", on_mount: ..., scope_resolver: ...`. |
| Governance gates | Approval, budget, breaker, eval-gate, and tool-policy mechanisms. | Thresholds, policy values, escalation rules, and business risk interpretation. | Scoria supplies gates; your app decides what risk means. | Approval pauses, budget checks, breaker evidence, and eval gates. |
| Eval and release proof | Scorer execution, persisted score evidence, fail-closed verdict posture, and verification-suite commands. | Prompts, product success definitions, expected outputs, and release intent. | Scoria proves the check ran; your app defines useful output. | `$ mix test.adoption`, eval runs, and release gates. |
| Knowledge retrieval and grounding | Tenant-scoped retrieval filtering, citation validation, grounding checks, and persisted evidence. | Tenant/actor identity, corpus, business meaning, metadata semantics, and end-user answer surface. | Retrieval proof is only safe inside host-owned meaning and identity. | `$ mix test.knowledge` and citation scope evidence. |
| Bounded handoff scoped context | Same-run handoff records, scoped-context validation, queued delegation, and delegated lineage readback. | Which facts may be passed and which role should receive them. | Delegation stays narrow instead of copying broad runtime state. | `Scoria.start_handoff_run/3` and `Scoria.get_run_detail/1`. |
| Remote connectors and tools | Registration, grants, health state, trace evidence, and approval pauses. | Which tools exist, what credentials mean, and whether a side effect is allowed. | Tool governance can pause work, but product authority stays with the host. | `$ mix test.connector` and connector trace details. |
| Phoenix/BEAM infrastructure | Library defaults, Ecto migrations, Telemetry/PubSub/Oban-friendly integration points, and dashboard assets. | Deployment topology, repo config, secrets, app supervision, and non-Scoria UI. | Scoria fits into Phoenix instead of replacing the host application. | `$ mix scoria.install`, migrations, and host supervision. |

## Dashboard Scope

The dashboard tenant scope is host-authenticated. Scoria does not use query params as tenant authority.

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

Return tenant and actor values only after your app has authenticated the reviewer, checked tenant membership, and applied its own authorization policy.

## Policy And Business Meaning

Scoria can enforce approval pauses, budget checks, breaker checks, eval gates, scoped-context validation, connector grants, and audit sinks. Your app still decides:

- which role values exist
- which policy values matter
- which thresholds represent unacceptable risk
- which prompts are allowed to ship
- which expected outputs count as useful
- which corpus is authoritative
- what business meaning a run result has

This is the practical rule: Scoria owns the mechanism; your app owns the noun and the decision value.

## Common Footguns

- `session_id` is not `run_id`. `session_id` groups host turns; `run_id` resumes or inspects one exact Scoria execution.
- Semantic cache is not a knowledge base. Semantic cache reuses safe read-only answers; the optional knowledge base owns retrieval, citations, and grounding.
- Dashboard scope is not selected by URL params. The host app authenticates and authorizes the reviewer first.
- Default runtime adoption does not require knowledge, semantic cache, or connector setup.

## Related Guides

- [Golden Path](guides/golden-path.md)
- [JTBD and User Flows](guides/jtbd-and-user-flows.md)
- [Reviewer Verification](guides/reviewer-verification.md)
- [Glossary](guides/reference/glossary.md)

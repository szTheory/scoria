# Scoria vs external LLM-ops platforms

This guide helps a Phoenix adopter decide when Scoria's embedded governance model is the right fit, and when an external LLM-ops platform may be a better first choice or complement.

Read this with the [README](../README.md), the [capability guide](adoption_lanes.md), the [reviewer verification guide](operator_verification.md), and the [glossary](glossary.md). Repository paths: `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, and `docs/glossary.md`.

## When Scoria fits

Scoria fits when the AI/LLM work already belongs inside a Phoenix app and the team wants durable execution, review, approval, recovery, and verification records inside the same BEAM and database boundary.

Use Scoria when the default question is:

- Can one Phoenix engineer add inspectable AI work without adopting a separate control plane?
- Can the app keep identity, authorization, policy values, and business truth in the host system?
- Can reviewers inspect run traces, approvals, eval evidence, and knowledge grounding from `/scoria`?
- Can package and release confidence stay tied to executable verification suites?

External LLM-ops platforms can still be useful beside Scoria. The distinction is ownership: Scoria embeds the runtime governance record in the app that owns the product decision.

## What Scoria currently owns

Scoria currently makes these claims:

- Scoria runs inside your Phoenix app.
- Scoria records governance and runtime data in the host Postgres/Ecto boundary.
- Scoria ships an embedded LiveView reviewer dashboard at `/scoria`.
- The host app owns identity, authorization, role values, and business truth.
- Scoria supports durable runs, reviewer-visible traces, approvals, fail-closed eval posture, tenant-scoped knowledge retrieval, and upgrade-safe verification suites.
- Scoria requires no separate Scoria-hosted control plane.
- Scoria requires no required egress for Scoria governance records beyond model or tool providers the host app already calls.

Those are current package and docs claims. They do not depend on a Scoria-hosted service or a cross-service data warehouse.

## What your Phoenix app still owns

Your app still owns the product nouns:

- authenticated actor, tenant, session, and role values
- tenant membership and authorization decisions
- prompts, expected outputs, domain success definitions, and release intent
- policy thresholds, escalation rules, side-effect permissions, and business risk interpretation
- end-user UI, product workflow, support workflow, and business database truth
- model-provider and tool-provider calls that the host app chooses to make

Scoria owns mechanisms: record, gate, surface, and reconstruct. The host owns meaning and authority.

## Where external platforms may be stronger

An external platform may be stronger when the team needs:

- cross-language SDK coverage across Python, JavaScript, Go, Java, and other stacks
- managed warehouse-scale analytics across many products or services
- hosted dashboards across many services with centralized operational ownership
- mature prompt playgrounds and experiment workspaces
- broad eval collaboration for larger teams, annotators, or research workflows
- non-Phoenix stacks where the product runtime is not an Elixir/Phoenix application

These are ceded strengths, not weaknesses to hide. Scoria is intentionally narrow: embedded Phoenix governance for teams that want the control record inside their app boundary.

## Peer deployment posture and sources

The comparison should not flatten peers into one deployment model. Official docs describe multiple postures:

| Platform | Source-linked posture to account for |
|----------|--------------------------------------|
| LangSmith | LangSmith documents self-hosted deployment for enterprise use: <https://docs.langchain.com/langsmith/self-hosted>. |
| Langfuse | Langfuse documents self-hosting and cloud deployment options: <https://langfuse.com/self-hosting>. |
| Braintrust | Braintrust documents self-hosting and data-plane deployment: <https://www.braintrust.dev/docs/admin/self-hosting>. |
| Arize Phoenix | Arize Phoenix documents self-hosting for Phoenix observability and eval workflows: <https://arize.com/docs/phoenix/self-hosting>. |

Use the peer names respectfully and exactly. Write **Arize Phoenix** when referring to that LLM-ops tool so it is not confused with the Phoenix web framework.

## Not current Scoria claims

The following are future or deferred work. They must not be presented as current Scoria capabilities:

- OpenInference export is not a current Scoria claim. Scoria uses trace vocabulary, but export compatibility belongs to the future trace-foundation seed.
- Rule-of-Two/lethal-trifecta enforcement is not a current Scoria claim. Today Scoria has governance mechanisms; the dedicated agent-security policy layer is deferred.
- deeper scorer calibration is not a current Scoria claim. Current eval posture is fail-closed and evidence-backed, not a mature calibration suite.
- richer retrieval evals are not current Scoria claims. Precision, NDCG, faithfulness, rerank, and abstention depth remain deferred.
- retention, masking, purge, and feedback governance are not current Scoria claims. Privacy and feedback governance need their owning future seed.
- persistent AI feature grouping is not a current Scoria claim. Feature cockpits and durable feature grouping remain part of the later operator-IA work.

The safe comparison is simple: Scoria is embedded Phoenix governance with durable records, reviewer-visible traces, approvals, tenant-scoped knowledge retrieval, fail-closed eval posture, and package verification. External platforms often bring broader language coverage, managed collaboration, and cross-service analytics.

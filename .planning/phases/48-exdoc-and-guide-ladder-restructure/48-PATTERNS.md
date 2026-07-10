# Phase 48: ExDoc and guide ladder restructure - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 63
**Analogs found:** 63 / 63

## Project Context

- Root `AGENTS.md`: not present.
- Project-local `.codex/skills/` or `.agents/skills/`: not present.
- Primary in-repo analogs: `mix.exs`, current `docs/*.md`, `README.md`, package/release-preview contracts, adopter-doc contract helpers, and public moduledocs.
- Secondary local exemplar analogs named by phase context: `/Users/jon/projects/lattice_stripe/mix.exs`, `/Users/jon/projects/scrypath/mix.exs`, `/Users/jon/projects/mailglass/mix.exs`, and `/Users/jon/projects/lattice_stripe/guides/*.md`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | transform, batch | `mix.exs`; `/Users/jon/projects/lattice_stripe/mix.exs`; `/Users/jon/projects/mailglass/mix.exs` | exact plus target-shape exemplar |
| `README.md` | guide/docs | transform | `README.md` | exact |
| `lib/mix/tasks/scoria.release_preview.ex` | mix task | batch, file-I/O | `lib/mix/tasks/scoria.release_preview.ex` | exact |
| `lib/scoria/hex_consumer_contract.ex` | utility/contract | batch, file-I/O | `lib/scoria/hex_consumer_contract.ex` | exact |
| `lib/scoria/adopter_doc_contract.ex` | utility/contract | batch, transform | `lib/scoria/adopter_doc_contract.ex` | exact |
| `guides/getting-started.md` | guide/docs | transform | `README.md`; `docs/phoenix_runtime_example.md`; `/Users/jon/projects/lattice_stripe/guides/getting-started.md` | role-match |
| `guides/golden-path.md` | guide/docs | transform | `README.md`; `docs/adoption_lanes.md`; `docs/phoenix_runtime_example.md` | role-match |
| `guides/jtbd-and-user-flows.md` | guide/docs | transform | `README.md`; `docs/adoption_lanes.md` | role-match |
| `guides/ownership-boundary.md` | guide/docs | transform | `README.md`; `docs/adoption_lanes.md`; `docs/operator_verification.md` | role-match |
| `guides/capabilities/default-runtime.md` | guide/docs | transform | `docs/adoption_lanes.md`; `docs/phoenix_runtime_example.md`; `docs/operator_verification.md` | exact concept |
| `guides/capabilities/bounded-handoffs.md` | guide/docs | transform | `docs/bounded_handoffs.md` | exact concept |
| `guides/capabilities/semantic-cache.md` | guide/docs | transform | `docs/semantic_fast_path.md` | exact concept |
| `guides/capabilities/connectors-and-mcp.md` | guide/docs | transform | `docs/connector_adoption.md` | exact concept |
| `guides/capabilities/support-copilot-gallery.md` | guide/docs | transform | `docs/support_copilot_gallery.md` | exact concept |
| `guides/reviewer-verification.md` | guide/docs | transform | `docs/operator_verification.md` | exact concept |
| `guides/troubleshooting.md` | guide/docs | transform | `docs/operator_verification.md`; `docs/semantic_fast_path.md`; `docs/MAINTAINERS.md` | role-match |
| `guides/scoria-vs-external-llm-ops.md` | guide/docs | transform | `docs/scoria_vs_external_llm_ops.md` | exact concept |
| `guides/cheatsheet.cheatmd` | guide/docs | transform | `/Users/jon/projects/lattice_stripe/guides/cheatsheet.cheatmd` | format-match |
| `guides/reference/glossary.md` | guide/docs | transform | `docs/glossary.md` | exact concept |
| `guides/maintainers.md` | guide/docs | transform | `docs/MAINTAINERS.md` | exact concept |
| `docs/glossary.md` | compatibility stub/docs | file-I/O, transform | `docs/glossary.md` current source | partial |
| `docs/adoption_lanes.md` | compatibility stub/docs | file-I/O, transform | `docs/adoption_lanes.md` current source | partial |
| `docs/scoria_vs_external_llm_ops.md` | compatibility stub/docs | file-I/O, transform | `docs/scoria_vs_external_llm_ops.md` current source | partial |
| `docs/phoenix_runtime_example.md` | compatibility stub/docs | file-I/O, transform | `docs/phoenix_runtime_example.md` current source | partial |
| `docs/bounded_handoffs.md` | compatibility stub/docs | file-I/O, transform | `docs/bounded_handoffs.md` current source | partial |
| `docs/semantic_fast_path.md` | compatibility stub/docs | file-I/O, transform | `docs/semantic_fast_path.md` current source | partial |
| `docs/operator_verification.md` | compatibility stub/docs | file-I/O, transform | `docs/operator_verification.md` current source | partial |
| `docs/connector_adoption.md` | compatibility stub/docs | file-I/O, transform | `docs/connector_adoption.md` current source | partial |
| `docs/support_copilot_gallery.md` | compatibility stub/docs | file-I/O, transform | `docs/support_copilot_gallery.md` current source | partial |
| `docs/MAINTAINERS.md` | compatibility stub/docs | file-I/O, transform | `docs/MAINTAINERS.md` current source | partial |
| `test/scoria/package_surface_test.exs` | test | batch, file-I/O | `test/scoria/package_surface_test.exs` | exact |
| `test/mix/tasks/scoria.release_preview_test.exs` | test | batch | `test/mix/tasks/scoria.release_preview_test.exs` | exact |
| `test/scoria/terminology_contract_test.exs` | test | batch, file-I/O | `test/scoria/terminology_contract_test.exs` | exact |
| `test/scoria/adoption_surface_test.exs` | test | batch, file-I/O | `test/scoria/adoption_surface_test.exs` | exact |
| `test/scoria/glossary_contract_test.exs` | test | batch, file-I/O | `test/scoria/glossary_contract_test.exs` | exact |
| `test/scoria/scope_doctrine_contract_test.exs` | test | batch, file-I/O | `test/scoria/scope_doctrine_contract_test.exs` | exact |
| `lib/scoria.ex` | facade | request-response | `lib/scoria.ex` | exact |
| `lib/scoria/identity.ex` | model/utility | transform | `lib/scoria/identity.ex` | exact |
| `lib/scoria/runtime.ex` | service | CRUD, event-driven | `lib/scoria/runtime.ex` | exact |
| `lib/scoria/runtime/run_summary.ex` | model/DTO | transform | `lib/scoria/runtime/run_summary.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model/DTO | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `lib/scoria/prompt_policy.ex` | service | transform | `lib/scoria.ex`; `lib/scoria/identity.ex` | role-match |
| `lib/scoria_web/router.ex` | route | request-response | `lib/scoria_web/router.ex` | exact |
| `lib/scoria_web/dashboard_scope.ex` | provider/hook | request-response | `lib/scoria_web/dashboard_scope.ex` | exact |
| `lib/scoria_web/reviewer_surface.ex` | provider | transform | `lib/scoria_web/dashboard_scope.ex`; `lib/scoria_web/router.ex` | role-match |
| `lib/scoria/observe/reviewer_broadcast.ex` | service | pub-sub | `lib/scoria/observe/reviewer_broadcast.ex`; `lib/scoria/verification_suites.ex` for public contract style | exact |
| `lib/scoria/verification_suites.ex` | utility/contract | transform | `lib/scoria/verification_suites.ex` | exact |
| `lib/scoria/semantic_cache/profile.ex` | provider/behaviour | transform | `lib/scoria/semantic_cache/profile.ex` | exact |
| `lib/scoria/semantic_cache.ex` | service | CRUD, transform | `lib/scoria/runtime.ex`; `lib/scoria/semantic_cache/profile.ex` | role-match |
| `lib/scoria/knowledge.ex` | service | CRUD, transform | `lib/scoria/connectors.ex`; `lib/scoria/runtime.ex` | role-match |
| `lib/scoria/connectors.ex` | service | CRUD, transform | `lib/scoria/connectors.ex` | exact |
| `lib/scoria/connectors/auth.ex` | service | request-response | `lib/scoria/connectors.ex`; `lib/scoria_web/dashboard_scope.ex` | role-match |
| `lib/scoria/mcp/tool.ex` | model/provider | request-response | `lib/scoria/semantic_cache/profile.ex`; `lib/scoria/runtime/run_summary.ex` | role-match |
| `lib/scoria/req/steps.ex` | utility/provider | request-response | `lib/scoria/semantic_cache/profile.ex`; `lib/scoria/verification_suites.ex` | role-match |
| `lib/scoria/eval.ex` | service | CRUD, batch | `lib/scoria/runtime.ex`; `lib/scoria/connectors.ex` | role-match |
| `lib/scoria/prompt_registry.ex` | service | CRUD | `lib/scoria/connectors.ex`; `lib/scoria/runtime.ex` | role-match |
| `lib/scoria/sre.ex` | service | event-driven | `lib/scoria/runtime.ex`; `lib/scoria/verification_suites.ex` | role-match |
| `lib/scoria/sre/alert_sink.ex` | provider/behaviour | event-driven | `lib/scoria/semantic_cache/profile.ex`; `lib/scoria/sre/alert_sink.ex` hidden fallback | role-match |
| `lib/scoria/sre/audit_sink.ex` | provider/behaviour | event-driven | `lib/scoria/semantic_cache/profile.ex`; `lib/scoria/sre/audit_sink.ex` hidden fallback | role-match |
| `lib/scoria/semantic_lane.ex` | compatibility alias | transform | `docs/glossary.md`; `lib/scoria/semantic_cache/profile.ex` | role-match |
| `lib/scoria/verification_lanes.ex` | compatibility alias | transform | `docs/glossary.md`; `lib/scoria/verification_suites.ex` | role-match |
| `lib/scoria_web/operator_surface.ex` | compatibility alias | transform | `docs/glossary.md`; `lib/scoria_web/reviewer_surface.ex` | role-match |
| `lib/scoria/observe/operator_broadcast.ex` | compatibility alias | pub-sub | `docs/glossary.md`; `lib/scoria/observe/reviewer_broadcast.ex` | role-match |

## Pattern Assignments

### `mix.exs` (config, transform/batch)

**Primary analog:** `mix.exs`

**Current docs config to replace** (lines 123-142):
```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    extras: [
      "README.md",
      "LICENSE",
      "CHANGELOG.md",
      "docs/glossary.md",
      "docs/adoption_lanes.md",
      "docs/scoria_vs_external_llm_ops.md",
      "docs/phoenix_runtime_example.md",
      "docs/bounded_handoffs.md",
      "docs/semantic_fast_path.md",
      "docs/operator_verification.md",
      "docs/connector_adoption.md",
      "docs/support_copilot_gallery.md",
      "docs/MAINTAINERS.md"
    ]
  ]
end
```

**Current package file allow-list to keep explicit** (lines 145-183):
```elixir
defp package do
  [
    name: "scoria",
    files: [
      "lib",
      "priv/fixtures",
      "priv/host_app_proof",
      "priv/repo/migrations",
      "priv/repo/knowledge_migrations",
      "priv/static",
      "mix.exs",
      ".formatter.exs",
      "CHANGELOG.md",
      "README.md",
      "LICENSE",
      "docs/glossary.md",
      "docs/adoption_lanes.md",
      "docs/scoria_vs_external_llm_ops.md",
      "docs/phoenix_runtime_example.md",
      "docs/bounded_handoffs.md",
      "docs/semantic_fast_path.md",
      "docs/operator_verification.md",
      "docs/connector_adoption.md",
      "docs/support_copilot_gallery.md",
      "docs/MAINTAINERS.md"
    ],
```

**Target ExDoc grouping shape from LatticeStripe** (`/Users/jon/projects/lattice_stripe/mix.exs` lines 18-107):
```elixir
docs: [
  main: "getting-started",
  source_url: @source_url,
  source_ref: docs_source_ref(),
  extras: [
    "guides/getting-started.md",
    "guides/user-flows-and-jtbd.md",
    "guides/scope.md",
    "guides/checkout-signup-and-portal.md",
    "guides/connect-platform-flow.md",
    "guides/metering-runtime-and-reconciliation.md",
    "guides/quote-to-billing-operator.md",
    "guides/client-configuration.md",
    "guides/production-checklist.md",
    "guides/event-debugging.md",
    "guides/performance.md",
    "guides/circuit-breaker.md",
    "guides/opentelemetry.md",
    "guides/payments.md",
    "guides/checkout.md",
    "guides/credit_notes.md",
    "guides/invoices.md",
    "guides/metering.md",
    "guides/tax.md",
    "guides/subscriptions.md",
    "guides/connect.md",
    "guides/connect-accounts.md",
    "guides/connect-money-movement.md",
    "guides/customer-portal.md",
    "guides/webhooks.md",
    "guides/webhooks-thin-events.md",
    "guides/error-handling.md",
    "guides/testing.md",
    "guides/recipes.md",
    "guides/telemetry.md",
    "guides/api_stability.md",
    "guides/extending-lattice-stripe.md",
    "guides/cheatsheet.cheatmd",
    "CHANGELOG.md"
  ],
  groups_for_extras: [
    {"Start Here",
     [
       "guides/getting-started.md",
       "guides/user-flows-and-jtbd.md",
       "guides/scope.md",
       "guides/recipes.md"
     ]},
```

**Target logo/favicon and module grouping shape from Mailglass** (`/Users/jon/projects/mailglass/mix.exs` lines 419-535):
```elixir
defp docs do
  [
    main: "getting-started",
    homepage_url: @source_url,
    source_url: @source_url,
    source_ref: "v#{@version}",
    logo: "brandbook/assets/logo-mark.svg",
    favicon: "brandbook/assets/favicon.svg",
    extras: [
      "README.md",
      "docs/api_stability.md",
      "guides/compatibility-and-deprecations.md",
      "guides/upgrading-to-v1_0.md",
      "guides/upgrading-to-v2_0.md",
      "guides/getting-started.md",
      "guides/learning-path.md",
      "guides/jobs.md",
      "guides/authoring-mailables.md",
      "guides/components.md",
      "guides/preview.md",
      "guides/webhooks.md",
      "guides/unsubscribe.md",
      "guides/dkim-setup.md",
      "guides/multi-tenancy.md",
      "guides/telemetry.md",
      "guides/testing.md",
      "guides/upgrading-from-v0_1.md",
      "guides/migration-from-swoosh.md",
      "guides/production-go-live-checklist.md",
      "guides/errors-and-troubleshooting.md",
      "docs/upgrade-from-0.x.md",
      "MAINTAINING.md",
      "CONTRIBUTING.md",
      "SECURITY.md",
      "CODE_OF_CONDUCT.md"
    ],
    groups_for_extras: [
      Overview: ["README.md"],
      Contract: [
        "docs/api_stability.md",
        "guides/compatibility-and-deprecations.md"
      ],
      Guides: [
        "guides/upgrading-to-v1_0.md",
        "guides/upgrading-to-v2_0.md",
        "guides/getting-started.md",
```

**Source URL constants pattern from Scrypath** (`/Users/jon/projects/scrypath/mix.exs` lines 4-8):
```elixir
@version "0.3.10"
@source_url "https://github.com/szTheory/scrypath"
@source_ref "v#{@version}"
@hexdocs_url "https://hexdocs.pm/scrypath"
@release_docs_url "#{@hexdocs_url}/#{@version}"
```

**Apply to `mix.exs`:**
- Add `@source_url`, `@hexdocs_url`, `@release_docs_url`, and `docs_source_ref/0`.
- Keep Scoria's package `files:` allow-list explicit; add `guides/**` canonical docs and required brand assets.
- Configure ExDoc with `main: "getting-started"`, `source_url: @source_url`, `source_ref: docs_source_ref()`, `extra_section: "Guides"`, `formatters: ["html", "markdown"]`, `logo: "brandbook/logo-mark.svg"`, `favicon: "brandbook/favicon.svg"`, `groups_for_extras`, `groups_for_modules`, and `redirects`.
- Do not add custom `source_url_pattern` for GitHub.

### Guide Ladder Files (guide/docs, transform)

**New files:**
`guides/getting-started.md`, `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `guides/ownership-boundary.md`, `guides/capabilities/default-runtime.md`, `guides/capabilities/bounded-handoffs.md`, `guides/capabilities/semantic-cache.md`, `guides/capabilities/connectors-and-mcp.md`, `guides/capabilities/support-copilot-gallery.md`, `guides/reviewer-verification.md`, `guides/troubleshooting.md`, `guides/scoria-vs-external-llm-ops.md`, `guides/reference/glossary.md`, `guides/maintainers.md`.

**Source mapping:**

| Target Guide | Copy/Adapt From |
|---|---|
| `guides/getting-started.md` | `README.md` lines 77-173 plus `docs/phoenix_runtime_example.md` lines 17-24 |
| `guides/golden-path.md` | `README.md` lines 131-173, `docs/phoenix_runtime_example.md` lines 26-95 |
| `guides/jtbd-and-user-flows.md` | `README.md` lines 24-30 and `docs/adoption_lanes.md` lines 10-220 |
| `guides/ownership-boundary.md` | `README.md` lines 30-45 plus `docs/adoption_lanes.md` lines 36-68 |
| `guides/capabilities/default-runtime.md` | `docs/adoption_lanes.md` lines 12-89 plus `docs/phoenix_runtime_example.md` lines 1-24 |
| `guides/capabilities/bounded-handoffs.md` | `docs/bounded_handoffs.md` lines 1-144 |
| `guides/capabilities/semantic-cache.md` | `docs/semantic_fast_path.md` lines 1-120 |
| `guides/capabilities/connectors-and-mcp.md` | `docs/connector_adoption.md` lines 1-43 |
| `guides/capabilities/support-copilot-gallery.md` | `docs/support_copilot_gallery.md` lines 1-90 |
| `guides/reviewer-verification.md` | `docs/operator_verification.md` lines 1-287 |
| `guides/troubleshooting.md` | `docs/operator_verification.md` lines 73-152 and 231-287; `docs/semantic_fast_path.md` lines 101-120 |
| `guides/scoria-vs-external-llm-ops.md` | `docs/scoria_vs_external_llm_ops.md` lines 1-84 |
| `guides/reference/glossary.md` | `docs/glossary.md` lines 1-152 |
| `guides/maintainers.md` | `docs/MAINTAINERS.md` lines 1-241 and maintainer-only sections as needed |

**Getting-started opening pattern from local exemplar** (`/Users/jon/projects/lattice_stripe/guides/getting-started.md` lines 1-7):
```markdown
# Getting Started

LatticeStripe is a production-grade Elixir SDK for the Stripe API. This guide walks you
through installation, setup, and your first API call - from zero to a working PaymentIntent
in just a few minutes.

## Installation
```

**Scoria README intro to copy into getting started** (`README.md` lines 14-22):
```markdown
Scoria is an Elixir/Phoenix library you add to an existing Phoenix app to run AI/LLM work durably and inspectably. Every run - one execution such as a prompt render, model call, tool call, retrieval, approval, or eval score - is recorded as a queryable Postgres/Ecto trace. A mounted LiveView dashboard at `/scoria` lets a human reviewer inspect, debug, approve, and resume that work. Scoria runs inside your app's BEAM and database boundary; it is not a hosted SaaS agent platform.

Scoria is for Phoenix teams where one engineer may need to ship prompts, inspect runs, approve risky tool calls, run evals, and debug incidents without adopting a separate hosted control plane. The reviewer is a role one engineer may wear, not a department.

- **Core:** Phoenix AI/product engineers, backend/platform engineers, SRE/devops hats, reviewers/approvers, prompt writers, eval checkers, and MCP/workflow configurators.
- **Adjacent:** security, privacy/legal, Trust and Safety, domain experts, PMs, and support teams consume hooks, docs, exported proof, or review outputs, but are not the first dedicated Scoria surface.
- **Not Scoria's surface:** end users of host AI flows, host product designers, finance or executive dashboards, general data warehouses, and host auth or policy administration.

Use [the ownership table below](#what-scoria-owns-vs-what-your-app-owns) to check the boundary before you add a capability. For peer-tradeoff framing, see the [Scoria vs external LLM-ops platforms](docs/scoria_vs_external_llm_ops.md) guide.
```

**Default runtime guide pattern** (`docs/phoenix_runtime_example.md` lines 17-24):
```markdown
## Core rule: `session_id` is not `run_id`

Use `session_id` to group related turns in your host app. Use `run_id` to inspect or resume one exact Scoria execution.

- same conversation, new turn: reuse `session_id`, create a fresh run
- paused run: resume only by its exact `run_id`

That distinction is the main contract to preserve in your Phoenix app.
```

**Bounded handoff guide pattern** (`docs/bounded_handoffs.md` lines 20-35):
```markdown
## Host and Scoria ownership boundary

The host app owns identity, escalation policy, prompt or draft selection, and scoped-context selection.
Scoria owns durable run creation, scoped-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.
Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.

Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`: the root role that is delegating
- the delegated role argument: the role that should own the child step
- `delegated_kind`: the child step kind that host handlers should execute
- `handoff_input`: the exact host-supplied work brief Scoria should persist
- `scoped_context`: the exact scoped context slice that is safe to pass down
```

**Semantic cache guide pattern** (`docs/semantic_fast_path.md` lines 18-33):
````markdown
## Safety rule: only explicitly safe read-only profiles

The semantic cache is opt-in and profile-based.

Define one profile for work that is safe to reuse:

```elixir
defmodule MyApp.AI.AccountFaqCache do
  use Scoria.SemanticCache.Profile,
    cache_key: "account_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end
```

`Scoria.SemanticLane`, `lane:`, and `lane_key` remain accepted as legacy 0.1.x compatibility aliases; new public examples should use `Scoria.SemanticCache.Profile`, `profile:`, and `cache_key:`.
````

**Reviewer verification guide pattern** (`docs/operator_verification.md` lines 24-71):
````markdown
## Dashboard auth and scope proof

The host app authenticates the reviewer and asserts dashboard tenant scope. Query params do not choose tenants for the dashboard. Authorization remains delegated to the host; Scoria does not introduce a role model.

Dashboard proof follows the scope doctrine: authorization remains delegated to the host while Scoria ships the seam and records trusted scope.

Use Phoenix auth and membership checks before Scoria's dashboard scope gate:

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```
````

**Glossary pattern** (`docs/glossary.md` lines 125-152):
```markdown
## Legacy and industry equivalents

| Legacy or adjacent term | Final Scoria term | Compatibility note |
|-------------------------|-------------------|--------------------|
| operator | reviewer | Legacy/persona alias in 0.1.x; use reviewer in new public copy. |
| projected context | scoped context | `projected_context:` remains accepted as a compatibility alias. |
| semantic fast path | semantic cache | Existing guide filename may remain during migration; new concept language is semantic cache. |
| optional knowledge | optional knowledge base | Use knowledge base when naming the optional retrieval/grounding capability. |
| adoption/capability lane | capability | Use capability for adopter-facing optional surfaces. |
| proof/verification lane | verification suite | Use verification suite for proof commands. |
| surface-sense evidence | trace | Use trace for reviewer-facing run inspection surfaces. |
| RAG/citation evidence | unchanged evidence | Evidence remains correct for citations, grounding, and `evidence_refs`. |
```

### `guides/cheatsheet.cheatmd` (guide/docs, transform)

**Analog:** `/Users/jon/projects/lattice_stripe/guides/cheatsheet.cheatmd`

**Cheatmd column pattern** (lines 1-15):
````markdown
# LatticeStripe Cheatsheet

## Setup
{: .col-2}

### Add dependency

```elixir
# mix.exs
def deps do
  [
    {:lattice_stripe, "~> 1.7"}
  ]
end
```
````

**Apply to Scoria:** Use short two-column sections for install, dashboard mount, default runtime, bounded handoff, semantic cache, verification suites, and docs links. Keep examples pure copy/paste snippets; avoid deep prose.

### `docs/*.md` Compatibility Stubs (compatibility docs, file-I/O)

**Files:** `docs/glossary.md`, `docs/adoption_lanes.md`, `docs/scoria_vs_external_llm_ops.md`, `docs/phoenix_runtime_example.md`, `docs/bounded_handoffs.md`, `docs/semantic_fast_path.md`, `docs/operator_verification.md`, `docs/connector_adoption.md`, `docs/support_copilot_gallery.md`, `docs/MAINTAINERS.md`.

**Analog:** current same files for concept identity; no existing thin-stub file exists in Scoria. Use RESEARCH.md compatibility-stub pattern and ExDoc redirects.

**Current old-path evidence** (`README.md` lines 60-69):
```markdown
Docs:

- [Glossary](docs/glossary.md)
- [Capability guide](docs/adoption_lanes.md)
- [Phoenix runtime example](docs/phoenix_runtime_example.md)
- [Bounded handoffs](docs/bounded_handoffs.md)
- [Semantic cache](docs/semantic_fast_path.md)
- [Reviewer verification](docs/operator_verification.md)
- [Remote connector adoption](docs/connector_adoption.md)
- [Support copilot gallery](docs/support_copilot_gallery.md) - clone repo for `examples/support_copilot`
```

**Stub policy:**
- Keep the old file path in git for copied GitHub links.
- Replace body with a thin pointer to the canonical `guides/` target and a short compatibility note.
- Exclude these old `docs/*.md` stubs from ExDoc `extras`.
- Add `redirects` in `mix.exs` for old generated HexDocs page IDs.

### Package and Release Inventory Contracts

**Files:** `test/scoria/package_surface_test.exs`, `lib/mix/tasks/scoria.release_preview.ex`, `test/mix/tasks/scoria.release_preview_test.exs`, `lib/scoria/hex_consumer_contract.ex`.

**Package test analog:** `test/scoria/package_surface_test.exs`

**Current docs/package lists** (lines 6-39):
```elixir
@docs_extras [
  "README.md",
  "LICENSE",
  "CHANGELOG.md",
  "docs/glossary.md",
  "docs/adoption_lanes.md",
  "docs/scoria_vs_external_llm_ops.md",
  "docs/phoenix_runtime_example.md",
  "docs/bounded_handoffs.md",
  "docs/semantic_fast_path.md",
  "docs/operator_verification.md",
  "docs/connector_adoption.md",
  "docs/support_copilot_gallery.md",
  "docs/MAINTAINERS.md"
]
@required_package_paths [
  "README.md",
  "LICENSE",
  "mix.exs",
  "CHANGELOG.md",
  "lib/scoria.ex",
  "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
  "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
```

**Metadata assertion pattern to update** (`test/scoria/package_surface_test.exs` lines 41-58):
```elixir
test "project metadata describes one publish surface" do
  project = Mix.Project.config()

  assert project[:source_url] == "https://github.com/szTheory/scoria"
  assert project[:homepage_url] == "https://hexdocs.pm/scoria"
  assert project[:docs][:main] == "readme"
  assert project[:docs][:source_ref] == "v#{project[:version]}"
  assert project[:docs][:extras] == @docs_extras
  assert project[:package][:links]["GitHub"] == project[:source_url]
  assert project[:package][:licenses] == ["MIT"]
  assert project[:version] == HexConsumerContract.published_version()
end
```

**Release preview task pattern** (`lib/mix/tasks/scoria.release_preview.ex` lines 29-63):
```elixir
@impl Mix.Task
def run(_args) do
  Mix.Task.run("loadpaths")

  output_dir = release_preview_output_dir()
  File.rm_rf!(output_dir)

  Mix.shell().info("==> Building publish-facing docs")
  Mix.Task.reenable("docs")
  Mix.Task.run("docs")

  Mix.shell().info("==> Building unpacked Hex preview")

  {output, status} =
    System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
      cd: File.cwd!(),
      stderr_to_stdout: true
    )

  if status != 0 do
    Mix.raise("hex preview failed:\n#{output}")
  end

  unpack_root = unpack_root!(output_dir)

  case missing_required_paths(unpack_root) do
    [] ->
      Mix.shell().info("==> Release preview passed")

    missing ->
      Mix.raise("""
      release preview is missing required package paths:
      #{Enum.map_join(missing, "\n", &"* #{&1}")}
      """)
  end
end
```

**Release preview test shape** (`test/mix/tasks/scoria.release_preview_test.exs` lines 27-35):
```elixir
assert Code.ensure_loaded?(Mix.Tasks.Scoria.ReleasePreview)
assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :run, 1)
assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :required_package_paths, 0)
assert function_exported?(Mix.Tasks.Scoria.ReleasePreview, :release_preview_output_dir, 0)
assert Mix.Task.get("scoria.release_preview")
assert Mix.Tasks.Scoria.ReleasePreview.required_package_paths() == expected_required_paths

assert Mix.Tasks.Scoria.ReleasePreview.release_preview_output_dir() ==
         "tmp/scoria-release-preview"
```

**Contract helper pattern:** `lib/scoria/hex_consumer_contract.ex`

**Single-source-of-truth doc helper shape** (lines 115-138):
```elixir
@doc """
Adopter doc surfaces for executable drift guards - README and adoption lanes only.

Maintainer gate-map topology lives in `ci_policy_contract_test`, not here (D-96, D-98).
"""
def adopter_doc_surfaces do
  adoption_cmd = Scoria.VerificationLanes.command(:adoption)

  %{
    "README.md" => [
      adoption_cmd,
      "mix hex.build --unpack",
      "{:scoria, path: unpack_root}",
      "Scoria.HexConsumerContract",
      "docs/operator_verification.md"
    ],
    "docs/adoption_lanes.md" => [
      adoption_cmd,
      "mix hex.build --unpack",
      "packaged tarball",
      "operator_verification.md"
    ]
  }
end
```

**File hash/package inventory pattern** (`lib/scoria/hex_consumer_contract.ex` lines 225-242):
```elixir
@doc """
Content hash of packaged file inventory plus published version (12-char hex suffix).
"""
def package_fingerprint do
  version = published_version()
  package_files = Mix.Project.config()[:package][:files]

  hash_lines =
    package_files
    |> Enum.flat_map(&package_path_hash_lines/1)
    |> Enum.sort()

  payload = Enum.join([version | hash_lines], "\n")

  :crypto.hash(:sha256, payload)
  |> Base.encode16(case: :lower)
  |> String.slice(0, 12)
end
```

**Apply to Phase 48:**
- Prefer one canonical path helper/list or a contract that compares `docs[:extras]`, package `files`, release-preview required paths, and docs contract tests.
- Replace flat `docs/*.md` expectations with canonical `guides/` extras, old stubs excluded from extras, and package inclusion of canonical guides plus required brand assets.
- Add assertions for `main`, `extra_section`, `formatters`, `logo`, `favicon`, `groups_for_extras`, `groups_for_modules`, `redirects`, and dynamic source-ref branches.

### Adopter and Terminology Contract Tests

**Files:** `test/scoria/terminology_contract_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/glossary_contract_test.exs`, `test/scoria/scope_doctrine_contract_test.exs`, `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/verification_suites.ex`.

**Terminology stable doc list to update** (`test/scoria/terminology_contract_test.exs` lines 10-20):
```elixir
@stable_adopter_docs [
  "README.md",
  "docs/adoption_lanes.md",
  "docs/scoria_vs_external_llm_ops.md",
  "docs/bounded_handoffs.md",
  "docs/phoenix_runtime_example.md",
  "docs/semantic_fast_path.md",
  "docs/operator_verification.md",
  "docs/connector_adoption.md",
  "docs/support_copilot_gallery.md"
]
```

**Corpus assertion pattern** (`test/scoria/terminology_contract_test.exs` lines 68-88):
```elixir
test "stable adopter docs expose final vocabulary and preferred public examples" do
  corpus = stable_doc_corpus() <> "\n" <> File.read!(@scoria_facade)

  for example <- @preferred_public_examples do
    assert corpus =~ example,
           "expected stable docs or public facade docs to include #{inspect(example)}"
  end

  for term <- ["reviewer", "trace", "capability", "verification suite", "semantic cache"] do
    assert String.downcase(corpus) =~ term
  end
end

test "stable adopter docs link back to the glossary" do
  for path <- @stable_adopter_docs do
    content = File.read!(path)

    assert content =~ "glossary",
           "expected #{path} to link or refer to the terminology glossary"
  end
end
```

**Adoption contract generated-test pattern** (`test/scoria/adoption_surface_test.exs` lines 7-16):
```elixir
for {path, fragments} <- HexConsumerContract.adopter_doc_surfaces() do
  test "adopter doc #{path} stays aligned with HexConsumerContract surface SSOT" do
    content = File.read!(unquote(path))

    for fragment <- unquote(Macro.escape(fragments)) do
      assert content =~ fragment,
             "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
    end
  end
end
```

**Public module docs test pattern** (`test/scoria/adoption_surface_test.exs` lines 525-540):
```elixir
test "public modules expose compiled moduledocs on current Elixir" do
  for mod <- [Scoria, Scoria.Runtime, Scoria.Identity, Scoria.PromptPolicy] do
    assert {:docs_v1, _, :elixir, _, moduledoc, _, _} = Code.fetch_docs(mod)

    assert moduledoc not in [nil, :none], "#{inspect(mod)} is missing moduledoc"

    moduledoc_text =
      case moduledoc do
        %{"en" => text} -> text
        text when is_binary(text) -> text
      end

    assert is_binary(moduledoc_text)
    assert String.trim(moduledoc_text) != ""
  end
end
```

**Verification suite SSOT pattern** (`lib/scoria/verification_suites.ex` lines 1-8 and 17-84):
```elixir
defmodule Scoria.VerificationSuites do
  @moduledoc """
  Canonical verification suite contract for adopter-facing and maintainer-facing proofs.

  Each verification suite maps one command contract to its environment,
  prerequisites, and explicit exclusions so docs, tests, and CI can share one
  source of truth.
  """
```

```elixir
@suites [
  %{
    id: :release_preview,
    name: "Release preview verification suite",
    command: "mix scoria.release_preview",
    ci_command: "MIX_ENV=dev mix scoria.release_preview",
    env: :dev,
    prerequisites: [],
    exclusions: []
  },
```

**Apply to tests:**
- Update path constants from `docs/*.md` to canonical `guides/*.md`.
- Keep assertions that old vocabulary appears only as compatibility notes.
- Add or update assertions that old stub paths are not ExDoc extras.
- Keep pure examples in doctests only; runtime/dashboard/DB examples stay in ExUnit contract tests.

### README.md (guide/docs, transform)

**Analog:** `README.md`

**First-screen positioning pattern** (lines 1-22):
```markdown
<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg"><img src="brandbook/logo-primary-light.svg" alt="Scoria" width="360"></picture></p>

# Scoria

AI ops for Phoenix apps.

[![CI](https://github.com/szTheory/scoria/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scoria/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/scoria.svg)](https://hex.pm/packages/scoria)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/scoria)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.19%2B-4B275F.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7%2B-FD4F00.svg)](https://www.phoenixframework.org/)
```

**Docs links pattern to rewrite to `guides/`** (lines 60-69):
```markdown
Docs:

- [Glossary](docs/glossary.md)
- [Capability guide](docs/adoption_lanes.md)
- [Phoenix runtime example](docs/phoenix_runtime_example.md)
- [Bounded handoffs](docs/bounded_handoffs.md)
- [Semantic cache](docs/semantic_fast_path.md)
- [Reviewer verification](docs/operator_verification.md)
- [Remote connector adoption](docs/connector_adoption.md)
- [Support copilot gallery](docs/support_copilot_gallery.md) - clone repo for `examples/support_copilot`
```

**Quickstart pattern** (lines 131-173):
````markdown
## Quickstart

The host app entrypoint is `Scoria`.

Keep the canonical order boring: `identity -> start -> inspect -> resume`.

```elixir
identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :chat_session_id)
  })

{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
  )

store_run_id_somewhere(started.run_id)
```
````

**Apply to README:**
- Keep README as GitHub/package front door.
- Rewrite links to canonical `guides/` paths.
- Keep old compatibility notes only where helpful; do not turn README into the HexDocs first page.

### Public Moduledocs and API Reference

**Files:** `lib/scoria.ex`, `lib/scoria/identity.ex`, `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex`, `lib/scoria/prompt_policy.ex`, `lib/scoria_web/router.ex`, `lib/scoria_web/dashboard_scope.ex`, `lib/scoria_web/reviewer_surface.ex`, `lib/scoria/observe/reviewer_broadcast.ex`, `lib/scoria/verification_suites.ex`, `lib/scoria/semantic_cache/profile.ex`, `lib/scoria/semantic_cache.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/connectors.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/mcp/tool.ex`, `lib/scoria/req/steps.ex`, `lib/scoria/eval.ex`, `lib/scoria/prompt_registry.ex`, `lib/scoria/sre.ex`, `lib/scoria/sre/alert_sink.ex`, `lib/scoria/sre/audit_sink.ex`.

**Facade moduledoc pattern** (`lib/scoria.ex` lines 1-31):
```elixir
defmodule Scoria do
  @moduledoc """
  Public facade for Phoenix-hosted Scoria runtime integration.

  Start here when wiring Scoria into an application. The happy path is:

  1. Normalize request or session context with `identity/1`
  2. Start a durable run with `start_run/2`
  3. Persist the returned `run_id`
  4. Inspect or resume that exact run through the same module

  `session_id` is the host-owned continuity key that groups related turns.
  `run_id` is Scoria's exact durable handle for one run. Reuse a `session_id`
  across turns, but resume only by `run_id`.

  For edge normalization details, see `Scoria.Identity`. For deeper lifecycle
  APIs behind this facade, see `Scoria.Runtime`.
```

**Function docs and compatibility note pattern** (`lib/scoria.ex` lines 45-60):
```elixir
@doc """
Starts a bounded delegated run with one explicit handoff and scoped context.

Prefer `scoped_context:` for the host-curated context slice passed to the
delegated role:

    Scoria.start_handoff_run(identity, "critic",
      root_role_id: "planner",
      delegated_kind: "review",
      handoff_input: %{"brief" => "Review the draft answer"},
      scoped_context: %{"task" => "policy review"}
    )

`projected_context:` remains accepted as a legacy 0.1.x compatibility alias.
The stored field name is not renamed by the terminology migration.
"""
```

**Identity model docs and type pattern** (`lib/scoria/identity.ex` lines 1-47):
```elixir
defmodule Scoria.Identity do
  @moduledoc """
  Canonical runtime identity envelope and Phoenix-edge adapters.

  Use this module where request assigns, session values, or mount params cross
  into Scoria's runtime boundary. It normalizes those host-owned inputs into the
  public identity shape used by `Scoria.start_run/2`.

  `actor_id` and `tenant_id` identify who is acting and for whom. `session_id`
  is the host-owned continuity key that groups related turns. It is not a
  substitute for Scoria's durable `run_id`, which identifies one exact run for
  resume and operator evidence.
```

**Public DTO pattern** (`lib/scoria/runtime/run_summary.ex` lines 1-4 and 49-68):
```elixir
defmodule Scoria.Runtime.RunSummary do
  @moduledoc """
  Stable public summary DTO for lifecycle, polling, and resume flows.
  """
```

```elixir
@type t :: %__MODULE__{
        run_id: String.t(),
        session_id: String.t() | nil,
        status: String.t(),
        actor_id: String.t() | nil,
        tenant_id: String.t() | nil,
        source_run_id: Ecto.UUID.t() | nil,
        source_checkpoint_id: Ecto.UUID.t() | nil,
        execution_mode: String.t(),
        replay_posture: String.t(),
        live_tool_allowlist: [String.t()],
        any_seam_executed_live: boolean(),
        current_step_id: Ecto.UUID.t() | nil,
        latest_checkpoint_id: Ecto.UUID.t() | nil,
        awaiting_approval: boolean(),
        started_at: DateTime.t() | nil,
        completed_at: DateTime.t() | nil,
        inserted_at: DateTime.t() | nil,
        updated_at: DateTime.t() | nil
      }
```

**Dashboard scope public contract pattern** (`lib/scoria_web/dashboard_scope.ex` lines 1-8 and 33-47):
```elixir
defmodule ScoriaWeb.DashboardScope do
  @moduledoc """
  Host-asserted tenant scope for the embedded Scoria dashboard.

  The dashboard scope is resolved at the LiveView mount boundary. Host apps own
  authentication and authorization; Scoria normalizes the resulting tenant data
  and fails closed when no tenant is asserted.
  """
```

```elixir
defmodule Resolver do
  @moduledoc """
  Resolver contract for host-owned Scoria dashboard scope.

  A resolver receives public LiveView params, private session data, and the
  current socket. Params may be used as hints by host code, but Scoria's
  default resolver ignores params as tenant authority.
  """
```

**Apply to public modules:**
- First sentence should say what the module is for.
- Include when to use it, how it fits the ownership boundary, one small copyable example where feasible, and links to canonical guides.
- Use final Phase 46/47 vocabulary (`reviewer`, `trace`, `capability`, `verification suite`, `semantic cache`, `scoped context`).
- Keep old aliases visible only as compatibility notes.
- Avoid broad doctests where Repo, PubSub, router, DB, or LiveView setup is required.

### Compatibility Alias Modules

**Files:** `lib/scoria/semantic_lane.ex`, `lib/scoria/verification_lanes.ex`, `lib/scoria_web/operator_surface.ex`, `lib/scoria/observe/operator_broadcast.ex`.

**Terminology compatibility source:** `docs/glossary.md` lines 138-152:
```markdown
## Compatibility aliases

The following old names and options remain accepted during the 0.1.x compatibility window:

- `ScoriaWeb.OperatorSurface` delegates to `ScoriaWeb.ReviewerSurface`.
- `Scoria.Observe.OperatorBroadcast` delegates to `Scoria.Observe.ReviewerBroadcast`.
- `Scoria.VerificationLanes` delegates to `Scoria.VerificationSuites`.
- `Scoria.SemanticLane` remains accepted as a semantic cache profile compatibility surface.
- `lane:` remains accepted where new docs prefer `profile:`.
- `lane_key` remains the stored semantic cache key field and is not renamed.
- `projected_context:` remains accepted where new docs prefer `scoped_context:`.
```

**Apply to alias modules:**
- Keep modules visible under a small `Compatibility Aliases` ExDoc group.
- Add migration note in moduledoc.
- Do not add runtime `@deprecated` warnings in Phase 48.

### Internal Module Visibility

**Files affected through `mix.exs` `groups_for_modules`/`filter_modules` and possible `@moduledoc false`:** Ecto schemas, workers, LiveViews, controllers, components, copy helpers, asset/layout modules, `DevLab.*`, warning-ratchet/inventory helpers, adopter/Hex contract test helpers, support journey artifacts, UI critique artifacts, and test/support modules.

**Existing hidden module pattern** (`lib/scoria/application.ex` lines 1-6):
```elixir
defmodule Scoria.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
```

**Existing hidden service pattern** (`lib/scoria/eval/runner.ex` lines 1-9):
```elixir
defmodule Scoria.Eval.Runner do
  @moduledoc false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner
  alias Scoria.Eval.Scorers.ExactMatch
  alias Scoria.Eval.SubjectOutput
  alias Scoria.Eval.Timing
  alias Scoria.Eval.Verdict
```

**Apply to internals:**
- Prefer `@moduledoc false` for true internals.
- Use `groups_for_modules` and/or `filter_modules` in `mix.exs` to shape the public API reference.
- If a schema/struct appears in a public return type, keep only minimal public typedoc/moduledoc that frames it as a returned public DTO rather than persistence internals.

## Shared Patterns

### ExDoc Config

**Source:** `mix.exs` lines 123-142 plus local exemplars above.
**Apply to:** `mix.exs`.

Use explicit helpers for:
- `docs_extras/0`
- `docs_extra_groups/0`
- `docs_module_groups/0`
- `docs_redirects/0`
- `docs_source_ref/0`
- package docs/brand file inventory if the planner chooses helper extraction.

### Dynamic Source Ref

**Source:** Phase 48 D-07 and RESEARCH.md Pattern 3.
**Apply to:** `mix.exs`, package surface tests.

Expected behavior:
- `SCORIA_DOCS_SOURCE_REF` wins when non-empty.
- exact matching git tag `v#{@version}` returns the version tag.
- all other builds return `"main"`.

### Host Authentication Boundary

**Source:** `docs/operator_verification.md` lines 24-71; `lib/scoria_web/dashboard_scope.ex` lines 1-8.
**Apply to:** README, getting-started, ownership-boundary, default-runtime, reviewer-verification, `ScoriaWeb.Router`, `ScoriaWeb.DashboardScope`, reviewer-surface moduledocs.

Core wording to preserve:
- Host authenticates the reviewer.
- Host asserts tenant scope.
- Query params do not choose tenants.
- Scoria records/normalizes trusted scope and fails closed.

### Public Vocabulary

**Source:** `docs/glossary.md` lines 125-152; `test/scoria/terminology_contract_test.exs` lines 21-37.
**Apply to:** all new guides, README links, public moduledocs, compatibility alias docs.

Use final terms first:
- reviewer
- trace
- capability
- verification suite
- scoped context
- semantic cache
- optional knowledge base

Legacy terms appear only in compatibility notes.

### Docs Contract Testing

**Source:** `test/scoria/adoption_surface_test.exs` lines 7-16; `test/scoria/package_surface_test.exs` lines 41-58.
**Apply to:** package surface, adoption surface, terminology, glossary, scope doctrine, release-preview tests.

Prefer helper-driven generated tests for repeated path/fragment contracts. Keep assertions concrete and path-aware.

### Release Preview

**Source:** `lib/mix/tasks/scoria.release_preview.ex` lines 29-63.
**Apply to:** `lib/mix/tasks/scoria.release_preview.ex`, `test/mix/tasks/scoria.release_preview_test.exs`, package inventory tests.

Keep the command behavior:
- run `mix docs`
- build unpacked Hex preview
- discover unpack root
- fail with missing required package paths

### Brand Assets

**Source:** `brandbook/logo-mark.svg`, `brandbook/favicon.svg`, `brandbook/logo-primary.svg`, `brandbook/logo-primary-light.svg`; `README.md` line 1.
**Apply to:** `mix.exs`, README/package inventory contracts.

Use only these four package brand assets for Phase 48:
- `brandbook/logo-primary.svg`
- `brandbook/logo-primary-light.svg`
- `brandbook/logo-mark.svg`
- `brandbook/favicon.svg`

## No Analog Found

All requested file types have at least a role-match analog. Thin compatibility stubs do not have an exact existing Scoria stub implementation; use the current source files plus RESEARCH.md Pattern 2 for the stub shape.

## Metadata

**Analog search scope:** `mix.exs`, `README.md`, `docs/*.md`, `brandbook/*.svg`, `lib/scoria*.ex`, `lib/scoria_web/*.ex`, `lib/mix/tasks/*.ex`, `test/scoria/**/*_test.exs`, `test/mix/tasks/**/*_test.exs`, and named local exemplar repositories.

**Files scanned:** 40 primary files plus local exemplar docs/config files.

**Pattern extraction date:** 2026-07-10

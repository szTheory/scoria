# Support Copilot Gallery

The support-copilot gallery is repository-local example material that demonstrates Scoria in a realistic B2B support domain. It is not a hosted product surface, SaaS demo, or Hex package feature.

Use this guide with [Connectors and MCP](guides/capabilities/connectors-and-mcp.md), [Default Runtime](guides/capabilities/default-runtime.md), and the [glossary](guides/reference/glossary.md).

The gallery is the human-clickable companion to the merge-blocking generated-host adoption proof. Adopters evaluating from Hex should run `$ mix test.adoption` in their own host app. Clone the repository when you want the full interactive gallery.

## Clone the repository

The gallery lives at `examples/support_copilot` in the GitHub repository. It is not included in the Hex package tarball.

```bash
git clone https://github.com/szTheory/scoria.git
cd scoria/examples/support_copilot
mix setup
mix phx.server
```

This starts the separate gallery app under `examples/support_copilot`, not the Scoria repo dashboard. Visit the gallery host chat at:

```text
http://localhost:4010/
```

Visit the gallery-local Scoria reviewer surface at:

```text
http://localhost:4010/scoria
```

## Path dependency vs tarball consumer proof

| Surface | Dependency shape | Purpose |
|---------|------------------|---------|
| Gallery (`examples/support_copilot`) | `path: dependency` (`{:scoria, path: "../.."}`) | Human-clickable demo and advisory LiveView journey tests |
| Merge-blocking adoption (`$ mix test.adoption`) | Hex-shaped tarball from `$ mix hex.build --unpack` | Proves packaged artifact installs in a generated Phoenix host |

The gallery uses a path dependency because it is repository-local example material. The merge-blocking adoption verification suite uses a Hex-shaped tarball because it proves the packaged artifact.

## Persona

The scenario follows a Support Ops Lead at Acme Corp (`acme-corp` tenant). The support reviewer triages billing disputes, escalates refunds to a `billing_specialist` role, and inspects reviewer traces in Scoria.

## Advisory verification suite

Maintainers and adopters exploring the gallery can run:

```bash
mix scoria.test.support_copilot
```

This verification suite is advisory. It is not part of `Scoria.VerificationSuites.closeout_order/0`. Merge-blocking adoption proof remains `$ mix test.adoption`.

Optional verification suite commands exercised by gallery journeys run in the main repo, not inside the gallery app:

- `$ mix test.semantic_fast_path` - semantic FAQ journey
- `$ mix test.knowledge` - knowledge refund-policy journey
- `$ mix test.connector` - billing connector register -> fleet -> drawer journey

## Journey fixtures

Shared identities, ticket data, and handler logic live in `Scoria.SupportJourney`, SupportJourney handlers, and `priv/fixtures/support_journey/`. The gallery, host-proof overlay, and this guide must stay aligned via source contract tests.

### Default capability

1. Host starts a durable run with `Scoria.start_run/2` for session `support-session-42`.
2. An approval step pauses with `waiting_for_approval` while a refund is reviewed.
3. Reviewer approves and the host calls `Scoria.resume_run/2` until status is `completed`.
4. The reviewer trace is visible at `/scoria/workflows/:run_id`.

### Handoff capability

1. Host escalates with `Scoria.start_handoff_run/3` to `billing_specialist` with `billing_review` delegated kind.
2. Reviewer inspects delegated lineage via `Scoria.get_run_detail/1` on `/scoria/workflows/:run_id`.

### Semantic FAQ capability

1. Gallery starts a read-only semantic cache run with a support FAQ cache profile.
2. Reviewer inspects semantic cache trace details on the workflow detail surface.

### Knowledge base capability

1. Gallery seeds `Acme refund policy` knowledge source from journey fixtures.
2. Host runs a grounded answer step; evidence references the knowledge corpus.

### Connector capability

1. Gallery registers a `billing` connector for tenant `acme-corp`.
2. Host runs a connector lookup step; reviewer fleet view lists the connector.

## Tools in the scenario

- `lookup_support_ticket` - read ticket `TKT-1042` ("Duplicate charge on Pro plan")
- `issue_refund` - approval-gated refund for the disputed charge

## Shared handlers

Overlay smokes and the gallery delegate to the shared SupportJourney handlers so approval, lookup, and capability handlers cannot drift between merge-blocking proof and the reference demo.

# Support Copilot Gallery

The support-copilot gallery is a committed Phoenix example app that demonstrates Scoria in a realistic B2B support domain. It is the human-clickable companion to the merge-blocking generated-host overlay proof.

## Clone the repository

The gallery lives at `examples/support_copilot` in the GitHub repository. It is **not** included in the Hex package tarball — **clone the repository** to run it locally:

```bash
git clone https://github.com/szTheory/scoria.git
cd scoria/examples/support_copilot
mix setup
mix phx.server
```

Visit the host chat at `/` and the Scoria operator surface at `/scoria`.

## Path dependency vs tarball consumer proof

| Surface | Dependency shape | Purpose |
|---------|------------------|---------|
| **Gallery** (`examples/support_copilot`) | `path: dependency` (`{:scoria, path: "../.."}`) | Human-clickable demo + advisory LiveView journey tests |
| **Merge-blocking adoption** (`mix test.adoption`) | Hex-shaped tarball from `mix hex.build --unpack` | Proves packaged artifact installs in a generated Phoenix host |

Adopters evaluating from Hex should run `mix test.adoption` in their host app. Clone the repo when you want the full interactive gallery.

## Persona

**Support Ops Lead** at **Acme Corp** (`acme-corp` tenant) triages billing disputes, escalates refunds to a `billing_specialist` role, and inspects operator evidence in Scoria.

## Advisory verification lane

Maintainers and adopters exploring the gallery can run:

```bash
mix scoria.test.support_copilot
```

This lane is **advisory** — it is not part of `VerificationLanes.closeout_order/0`. Merge-blocking adoption proof remains `mix test.adoption`.

Optional lane commands exercised by gallery journeys (run in the main repo, not inside the gallery app):

- `mix test.semantic_fast_path` — semantic FAQ journey
- `mix test.knowledge` — knowledge refund-policy journey
- `mix test.connector` — billing connector register → fleet → drawer journey

## Journey fixtures

Shared identities, ticket data, and handler logic live in `Scoria.SupportJourney`, `Scoria.SupportJourney.Handlers`, and `priv/fixtures/support_journey/`. The gallery, host-proof overlay, and this guide must stay aligned via source contract tests.

### Default lane

1. Host starts a durable run with `Scoria.start_run/2` for session `support-session-42`.
2. An approval step pauses with `waiting_for_approval` while a refund is reviewed.
3. Operator approves and the host calls `Scoria.resume_run/2` until status is `completed`.
4. Evidence is visible at `/scoria/workflows/:run_id`.

### Handoff lane

1. Host escalates with `Scoria.start_handoff_run/3` to `billing_specialist` with `billing_review` delegated kind.
2. Operator inspects delegated lineage via `Scoria.get_run_detail/1` on `/scoria/workflows/:run_id`.

### Semantic FAQ lane

1. Gallery starts a read-only semantic run with `SupportCopilot.SemanticLane`.
2. Operator inspects semantic evidence on the workflow detail surface.

### Knowledge lane

1. Gallery seeds `Acme refund policy` knowledge source from journey fixtures.
2. Host runs a grounded answer step; evidence references the knowledge corpus.

### Connector lane

1. Gallery registers a `billing` connector for tenant `acme-corp`.
2. Host runs a connector lookup step; operator fleet view lists the connector.

## Tools in the scenario

- `lookup_support_ticket` — read ticket `TKT-1042` ("Duplicate charge on Pro plan")
- `issue_refund` — approval-gated refund for the disputed charge

## Shared handlers

Overlay smokes and the gallery delegate to `Scoria.SupportJourney.Handlers` so approval, lookup, and lane handlers cannot drift between merge-blocking proof and the reference demo.

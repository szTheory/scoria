# Support Copilot Gallery

The support-copilot gallery is a committed Phoenix example app that demonstrates Scoria in a realistic B2B support domain. It is the human-clickable companion to the merge-blocking generated-host overlay proof.

## Persona

**Support Ops Lead** at **Acme Corp** (`acme-corp` tenant) triages billing disputes, escalates refunds to a `billing_specialist` role, and inspects operator evidence in Scoria.

## Spin up locally

```bash
cd examples/support_copilot
mix setup
mix phx.server
```

Visit the host chat at `/` and the Scoria operator surface at `/scoria`.

## Advisory verification lane

Maintainers and adopters exploring the gallery can run:

```bash
mix scoria.test.support_copilot
```

This lane is **advisory** — it is not part of `VerificationLanes.closeout_order/0`. Merge-blocking adoption proof remains `mix test.adoption`.

## Journey fixtures

Shared identities, ticket data, and doc fragments live in `Scoria.SupportJourney` and `priv/fixtures/support_journey/`. The gallery, host-proof overlay, and this guide must stay aligned via source contract tests.

### Default lane

1. Host starts a durable run with `Scoria.start_run/2` for session `support-session-42`.
2. An approval step pauses with `waiting_for_approval` while a refund is reviewed.
3. Operator approves and the host calls `Scoria.resume_run/2` until status is `completed`.
4. Evidence is visible at `/scoria/workflows/:run_id`.

### Handoff lane

1. Host escalates with `Scoria.start_handoff_run/3` to `billing_specialist` with `billing_review` delegated kind.
2. Operator inspects delegated lineage via `Scoria.get_run_detail/1` on `/scoria/workflows/:run_id`.

## Tools in the scenario

- `lookup_support_ticket` — read ticket `TKT-1042` ("Duplicate charge on Pro plan")
- `issue_refund` — approval-gated refund for the disputed charge

# Support Copilot Gallery

Human-clickable Scoria demo for a B2B support-copilot domain. Shared journey fixtures live in `Scoria.SupportJourney`.

## Quick start

```bash
cd examples/support_copilot
mix setup
mix phx.server
```

- Host chat: http://localhost:4010/
- Scoria operator dashboard: http://localhost:4010/scoria

## Verify

```bash
mix test
```

From the Scoria repo root (advisory lane):

```bash
mix scoria.test.support_copilot
```

See also [docs/support_copilot_gallery.md](../../docs/support_copilot_gallery.md).

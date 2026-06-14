#!/usr/bin/env bash
# Dev container entrypoint: ensure deps + DB are ready (idempotent), print a
# helpful banner of URLs/routes, then start the Phoenix dev server.
set -euo pipefail

echo "==> [scoria dev] fetching deps (cached in the deps volume after first run)"
mix deps.get >/dev/null

echo "==> [scoria dev] setting up database (create + core/knowledge migrations + seed; idempotent)"
mix dev.setup

HOST="${PHX_HOST:-scoria.localhost}"
INSTANCE="${COMPOSE_PROJECT_NAME:-scoria}"

cat <<BANNER

────────────────────────────────────────────────────────────────────
  Scoria dashboard — dev harness is up   (instance: ${INSTANCE})
────────────────────────────────────────────────────────────────────
  Open:  http://${HOST}/scoria        (via Traefik; *.localhost resolves
                                        automatically in Chrome/Chromium)
         host fallback: run \`make url\` for the ephemeral 127.0.0.1 port

  Demo data is seeded on boot (idempotent). Reseed any time with \`make seed\`;
  for a clean slate use \`make reseed\`. Demo deep-links (run / replay / prompt
  release ids) are printed in the seed output above.

  Screens:
    /scoria              Home (Status Home)
    /scoria/approvals    Approvals
    /scoria/reviews      Review Queue
    /scoria/workflows    Workflows
    /scoria/incidents    Incidents
    /scoria/connectors   Connectors
    /scoria/eval_specs   Eval Specs
    /scoria/prompts      Prompt Registry
    /scoria/prompts/:id/release   Prompt Release Workbench

  Screenshot + critique harness (from the host):
    docker compose --profile shots run --rm shots        # screenshots only
    docker compose --profile shots run --rm critique     # + LLM critique (needs ANTHROPIC_API_KEY)
    → outputs land in priv/shots/ (gap_register.md committed; captures gitignored)
────────────────────────────────────────────────────────────────────

BANNER

exec mix phx.server

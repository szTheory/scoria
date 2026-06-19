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

ROUTES="$(mix phx.routes ScoriaWeb.DevRouter 2>/dev/null \
  | awk '$2 == "GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ { print $3 }' \
  | sort -u \
  | sed 's/^/    /')" || true
if [ -z "$ROUTES" ]; then
  ROUTES="    (route list unavailable — run \`mix phx.routes ScoriaWeb.DevRouter\` or open http://${HOST}/scoria)"
fi

cat <<BANNER

────────────────────────────────────────────────────────────────────
  Scoria dashboard — dev harness is up   (instance: ${INSTANCE})
────────────────────────────────────────────────────────────────────
  Open:  http://${HOST}/scoria        (via Traefik; *.localhost resolves
                                        automatically in Chrome/Chromium)
         host fallback: run \`make url\` for the ephemeral 127.0.0.1 port

  Traefik admin (which app is routed where):  http://localhost:8080

  Native dev server: make dev → http://localhost:4799/scoria
  Host diagnostics:  make url | make fleet | make doctor

  Demo data is seeded on boot (idempotent). Reseed any time with \`make seed\`;
  for a clean slate use \`make reseed\`. Demo deep-links (run / replay / prompt
  release ids) are printed in the seed output above.

  Key routes (derived live from the router):
${ROUTES}

  Screenshot + critique harness (from the host):
    docker compose --profile shots run --rm shots        # screenshots only
    op run --env-file "\${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
      # + LLM critique (ANTHROPIC_API_KEY is mounted as a Compose secret)
    → outputs land in priv/shots/ (gap_register.md committed; captures gitignored)
────────────────────────────────────────────────────────────────────

BANNER

exec mix phx.server

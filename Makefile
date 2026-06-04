# Scoria dev DX shortcuts. See docs/docker_dev_dx.md for the full story.
.PHONY: proxy up up-d down logs url open dev shots critique shots-native

# --- Per-instance identity ---------------------------------------------------
# The project name + Traefik host are derived from the current git branch so two
# checkouts/branches run side by side without port or route collisions:
#   branch `main`        -> scoria-main  -> http://scoria-main.localhost/scoria
#   branch `feat/x-y`    -> scoria-feat-x-y
# Override explicitly with: `make up INSTANCE=scoria-foo`.
BRANCH   := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/A-Z' '-a-z' | sed 's/[^a-z0-9-]//g')
INSTANCE ?= scoria-$(if $(BRANCH),$(BRANCH),local)
export COMPOSE_PROJECT_NAME = $(INSTANCE)
export SCORIA_HOST          = $(INSTANCE).localhost

## proxy: start the shared Traefik proxy + create its network (run once)
proxy:
	-docker network create proxy
	docker compose -f docker/traefik/compose.yml up -d
	@echo "Traefik dashboard: http://localhost:8080"

## up: build + start this instance (foreground; prints its URL banner)
up:
	docker compose up --build

## up-d: build + start detached, then print the URL
up-d:
	docker compose up --build -d
	@$(MAKE) --no-print-directory url

## down: stop this instance's stack
down:
	docker compose down

## logs: tail the web container
logs:
	docker compose logs -f web

## url: print this instance's Traefik URL + the ephemeral loopback fallback
url:
	@echo "Instance:  $(COMPOSE_PROJECT_NAME)"
	@echo "Traefik:   http://$(SCORIA_HOST)/scoria"
	@echo "Fallback:  http://$$(docker compose port web 4000 2>/dev/null)/scoria"

## open: open this instance's dashboard in the default browser (macOS)
open:
	open "http://$(SCORIA_HOST)/scoria"

## dev: native host server with live browser reload (for CSS/JS iteration;
##      the asset watcher rebuilds the bundle, live reload refreshes the page)
dev:
	SCORIA_DEV_LIVE_RELOAD=1 mix phx.server

## shots: capture screenshots in Docker (no API key needed)
shots:
	docker compose --profile shots run --rm shots

## critique: capture (via shots) then LLM-critique -> priv/shots/gap_register.md
critique:
	docker compose --profile shots run --rm critique

## shots-native: run the harness on the host against a local mix phx.server
shots-native:
	mix scoria.ui.shots --url http://localhost:4000/scoria

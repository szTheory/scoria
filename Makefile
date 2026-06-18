# Scoria dev DX shortcuts. See docs/docker_dev_dx.md for the full story.
.DEFAULT_GOAL := help
.PHONY: proxy up up-d down logs url open dev seed reseed shots critique shots-native help fleet clean nuke

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

## help: print this help (the default target)
help:
	@echo "Scoria dev DX — each branch runs as its own instance at scoria-<branch>.localhost"
	@echo ""
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  \033[36m%-14s\033[0m %s\n", substr(line, 1, i-1), substr(line, i+2) }' $(MAKEFILE_LIST)

## fleet: list running scoria-* instances (spot a stale one shadowing your route)
fleet:
	@names=$$(docker ps --filter name=scoria- --filter label=traefik.enable=true -q); \
	if [ -z "$$names" ]; then \
		echo "No scoria instances running."; \
	else \
		echo "Running scoria instances (open at http://<project>.localhost/scoria):"; \
		docker ps --filter name=scoria- --filter label=traefik.enable=true \
			--format 'table {{.Label "com.docker.compose.project"}}\t{{.Status}}\t{{.Ports}}'; \
	fi

PORT ?= 4799

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

## clean: stop this instance's stack (keeps named volumes/caches)
clean:
	docker compose down

## down: alias of clean
down: clean

## logs: tail the web container
logs:
	docker compose logs -f web

## seed: re-run the idempotent dev seed against the running instance (no downtime)
seed:
	docker compose exec web mix run priv/repo/dev_seed.exs

## reseed: fast DB slate — drop pgdata only, rebuild + reseed (keeps caches)
reseed:
	docker compose down
	-docker volume rm $(COMPOSE_PROJECT_NAME)_pgdata
	@$(MAKE) --no-print-directory up-d

## nuke: stop + WIPE all of this instance's named volumes (cold rebuild next boot)
nuke:
	@echo "NUKE: irreversibly deleting ALL named volumes for instance '$(COMPOSE_PROJECT_NAME)':"
	@docker compose config --volumes | sed 's/^/         - $(COMPOSE_PROJECT_NAME)_/'
	@echo "       Destroys this instance's DB data + wipes deps/build/hex/mix caches (next 'make up' = cold recompile)."
	@echo "       Other branches/instances are NOT affected."
	docker compose down -v

## url: print this instance's Traefik URL + the ephemeral loopback fallback
url:
	@echo "Instance:  $(COMPOSE_PROJECT_NAME)"
	@echo "Traefik:   http://$(SCORIA_HOST)/scoria"
	@echo "Fallback:  http://$$(docker compose port web 4000 2>/dev/null)/scoria"

## open: open this instance's dashboard in the default browser (macOS)
open:
	open "http://$(SCORIA_HOST)/scoria"

## dev: native host server with live reload (PORT=4799 by default)
dev:
	@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"
	SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server

## shots: capture screenshots in Docker (no API key needed)
shots:
	docker compose --profile shots run --rm shots

## critique: capture (via shots) then LLM-critique -> priv/shots/gap_register.md
critique:
	docker compose --profile shots run --rm critique

## shots-native: run the harness on the host against a local mix phx.server
shots-native:
	mix scoria.ui.shots --url http://localhost:$(PORT)/scoria

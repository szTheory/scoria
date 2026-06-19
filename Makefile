# Scoria dev DX shortcuts. See docs/docker_dev_dx.md for the full story.
.DEFAULT_GOAL := help
.PHONY: proxy build up up-build up-d up-d-build down logs url open dev native-db native-db-status native-db-down doctor seed reseed shots critique shots-native help fleet clean nuke

# --- Per-instance identity ---------------------------------------------------
# The project name + Traefik host include a stable checkout hash so two clones on
# the same branch can run side by side without route, container, or volume clashes:
#   main at /projects/scoria-a -> scoria-main-a1b2c3d4.localhost
#   main at /projects/scoria-b -> scoria-main-e5f6a7b8.localhost
# Override explicitly with: `make up INSTANCE=scoria-foo`.
APP        := scoria
BRANCH     := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/A-Z' '-a-z' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$$//')
WORKTREE   := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)
WORKTREE_ID := $(shell root='$(WORKTREE)'; if command -v shasum >/dev/null 2>&1; then printf '%s' "$$root" | shasum | awk '{print substr($$1,1,8)}'; else printf '%s' "$$root" | cksum | awk '{print $$1}'; fi)
INSTANCE ?= $(APP)-$(if $(BRANCH),$(BRANCH),local)-$(WORKTREE_ID)
export COMPOSE_PROJECT_NAME = $(INSTANCE)
export SCORIA_HOST          = $(INSTANCE).localhost
PORT ?= 4799
SCORIA_DB_PORT ?= 55432
SCORIA_DB_POOL_SIZE ?= 5
NATIVE_PROJECT_NAME ?= $(COMPOSE_PROJECT_NAME)-native

## help: print this help (the default target)
help:
	@echo "Scoria dev DX — each checkout runs as its own instance at scoria-<branch>-<hash>.localhost"
	@echo ""
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  \033[36m%-14s\033[0m %s\n", substr(line, 1, i-1), substr(line, i+2) }' $(MAKEFILE_LIST)

## fleet: list Traefik-routed Docker demo containers across all local repos
fleet:
	@ids=$$(docker ps --filter label=traefik.enable=true -q); \
	if [ -z "$$ids" ]; then \
		echo "No Traefik-routed demo containers running."; \
	else \
		echo "Traefik-routed demo containers:"; \
		docker ps --filter label=traefik.enable=true \
			--format 'table {{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'; \
	fi

## proxy: start the shared Traefik proxy + create its network (run once)
proxy:
	-docker network create proxy
	docker compose -f docker/traefik/compose.yml up -d
	@echo "Traefik dashboard: http://localhost:8080"

## build: build this instance's dev images
build:
	docker compose build

## up: start this instance without rebuilding (daily source/style loop)
up:
	docker compose up --no-build

## up-build: build + start this instance (first run or dependency/config changes)
up-build:
	docker compose up --build

## up-d: start detached without rebuilding, then print the URL
up-d:
	docker compose up --no-build -d
	@$(MAKE) --no-print-directory url

## up-d-build: build + start detached, then print the URL
up-d-build:
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
	@echo "       Destroys this instance's DB data + wipes deps/build/hex/mix caches (next 'make up-build' = cold recompile)."
	@echo "       Other branches/instances are NOT affected."
	docker compose down -v

## url: print this instance's Traefik URL + the ephemeral loopback fallback
url:
	@echo "Instance:  $(COMPOSE_PROJECT_NAME)"
	@echo "Traefik:   http://$(SCORIA_HOST)/scoria"
	@fallback=$$(docker compose port web 4000 2>/dev/null || true); \
	if [ -n "$$fallback" ]; then \
		echo "Fallback:  http://$$fallback/scoria"; \
	else \
		echo "Fallback:  (not running; run 'make up-d' or 'make up-d-build')"; \
	fi
	@echo "Traefik admin: http://localhost:8080"

## open: open this instance's dashboard in the default browser (macOS)
open:
	open "http://$(SCORIA_HOST)/scoria"

## native-db: start pgvector for native make dev/test on SCORIA_DB_PORT
native-db:
	SCORIA_DB_PORT=$(SCORIA_DB_PORT) docker compose -p $(NATIVE_PROJECT_NAME) -f dev/pgvector-compose.yml up -d

## native-db-status: show native pgvector status
native-db-status:
	SCORIA_DB_PORT=$(SCORIA_DB_PORT) docker compose -p $(NATIVE_PROJECT_NAME) -f dev/pgvector-compose.yml ps

## native-db-down: stop the native pgvector helper
native-db-down:
	SCORIA_DB_PORT=$(SCORIA_DB_PORT) docker compose -p $(NATIVE_PROJECT_NAME) -f dev/pgvector-compose.yml down

## doctor: print Docker routing, proxy, and native DB diagnostics
doctor:
	@echo "==> Current Scoria instance"
	@$(MAKE) --no-print-directory url
	@echo ""
	@echo "==> Shared proxy network"
	@docker network inspect proxy --format 'proxy network exists ({{.Name}})' 2>/dev/null || echo "proxy network missing; run: make proxy"
	@echo ""
	@echo "==> Traefik-routed containers"
	@$(MAKE) --no-print-directory fleet
	@echo ""
	@echo "==> Native pgvector helper"
	@SCORIA_DB_PORT=$(SCORIA_DB_PORT) docker compose -p $(NATIVE_PROJECT_NAME) -f dev/pgvector-compose.yml ps
	@echo ""
	@echo "==> Host Postgres connection pressure"
	@if command -v lsof >/dev/null 2>&1; then \
		count=$$(lsof -nP -iTCP:5432 -sTCP:ESTABLISHED 2>/dev/null | tail -n +2 | wc -l | tr -d ' '); \
		echo "Established TCP connections on 127.0.0.1:5432-ish listeners: $$count"; \
	else \
		echo "lsof not installed; skipping host connection count"; \
	fi

## dev: native host server with live reload (PORT=4799, SCORIA_DB_PORT=55432)
dev: native-db
	@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"
	@echo "==> Native DB → 127.0.0.1:$(SCORIA_DB_PORT) (pool $(SCORIA_DB_POOL_SIZE))"
	SCORIA_DEV_LIVE_RELOAD=1 SCORIA_DB_PORT=$(SCORIA_DB_PORT) SCORIA_DB_POOL_SIZE=$(SCORIA_DB_POOL_SIZE) PORT=$(PORT) mix phx.server

## shots: capture screenshots in Docker (no API key needed)
shots:
	docker compose --profile shots run --rm shots

## critique: capture (via shots) then LLM-critique -> priv/shots/gap_register.md
critique:
	docker compose --profile shots run --rm critique

## shots-native: run the harness on the host against a local mix phx.server
shots-native:
	SCORIA_DB_PORT=$(SCORIA_DB_PORT) mix scoria.ui.shots --url http://localhost:$(PORT)/scoria

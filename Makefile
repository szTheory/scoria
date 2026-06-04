# Scoria dev DX shortcuts. See docs/MAINTAINERS.md for the full story.
.PHONY: proxy up down logs url shots critique shots-native

## proxy: start the shared Traefik proxy + create its network (run once)
proxy:
	-docker network create proxy
	docker compose -f docker/traefik/compose.yml up -d
	@echo "Traefik dashboard: http://localhost:8080"

## up: build + start the dashboard (http://scoria.localhost/scoria)
up:
	docker compose up --build

## down: stop the dashboard stack
down:
	docker compose down

## logs: tail the web container
logs:
	docker compose logs -f web

## url: print the ephemeral loopback URL (fallback when not using Traefik)
url:
	@echo "Traefik:   http://scoria.localhost/scoria"
	@echo "Fallback:  http://$$(docker compose port web 4000 2>/dev/null)/scoria"

## shots: capture screenshots in Docker (no API key needed)
shots:
	docker compose --profile shots run --rm shots

## critique: capture (via shots) then LLM-critique -> priv/shots/gap_register.md
critique:
	docker compose --profile shots run --rm critique

## shots-native: run the harness on the host against a local mix phx.server
shots-native:
	mix scoria.ui.shots --url http://localhost:4000/scoria

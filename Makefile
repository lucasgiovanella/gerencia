.PHONY: setup-vm homolog-up homolog-down prod-up prod-down test lint logs-homolog logs-prod

setup-vm:
	@chmod +x scripts/setup-vm.sh scripts/reset-vm.sh scripts/common.sh
	@./scripts/setup-vm.sh

homolog-up:
	docker compose -f docker-compose.homolog.yml up -d --build

homolog-down:
	docker compose -f docker-compose.homolog.yml down

prod-up:
	docker compose -f docker-compose.prod.yml up -d --build

prod-down:
	docker compose -f docker-compose.prod.yml down

test:
	bun test --env-file .env

lint:
	bunx biome lint src/
	bunx biome format src/ --diagnostic-level=error

logs-homolog:
	docker compose -f docker-compose.homolog.yml logs -f

logs-prod:
	docker compose -f docker-compose.prod.yml logs -f

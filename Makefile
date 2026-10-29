.PHONY: help setup db-up db-down db-reset install migrate seed tracks backend test mobile-web mobile-chrome mobile-android mobile-device mobile-waydroid tiles-proxy waydroid-start waydroid-stop emulator emulator-stop clean

BACKEND := /home/andre/kumpas/backend
MOBILE  := /home/andre/kumpas/mobile

# Navegador Chromium-based para o Flutter web (Helium). Override: make mobile-chrome CHROME=/path/to/chrome
CHROME ?= /usr/bin/helium-browser

# CARTO Voyager (opcional). Obter free key em https://carto.com/basemaps/
# Atenção: a variável usa underscore (CARTO_KEY), não hífen.
# Uso: make mobile-android CARTO_KEY=xxx
CARTO_KEY ?=
MAP_TILE_URL ?=
MAP_DEFINES := --dart-define=CARTO_KEY=$(CARTO_KEY) --dart-define=MAP_TILE_URL=$(MAP_TILE_URL)

# Telemóvel físico: deteta automaticamente o primeiro dispositivo USB
# (ignora emuladores e o Waydroid). Override: make mobile-device DEVICE=<serial>
DEVICE ?= $(shell PATH="$(ANDROID_PATH)" adb devices 2>/dev/null | awk 'NR>1 && $$2=="device" && $$1 !~ /^emulator-/ && $$1 !~ /^192\.168\./ {print $$1; exit}')

# Android SDK / emulador
ANDROID_HOME ?= $(HOME)/Android/Sdk
ANDROID_PATH := $(ANDROID_HOME)/emulator:$(ANDROID_HOME)/platform-tools:$(PATH)
AVD ?= kumpas

help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

setup: install db-up migrate seed ## Setup completo (install + db + migrate + seed)

db-up: ## Sobe o Postgres local (Docker)
	docker compose up -d

db-down: ## Para o Postgres local
	docker compose down

db-reset: ## Apaga dados e recria a BD do zero
	docker compose down -v
	docker compose up -d
	@sleep 3
	$(MAKE) migrate seed

install: ## Instala dependências do backend
	npm --prefix $(BACKEND) install

migrate: ## Aplica migrações Prisma
	npm --prefix $(BACKEND) run prisma:migrate

seed: ## Popula a BD com dados de exemplo
	npm --prefix $(BACKEND) run seed

tracks: ## Gera tracks reais via Overpass API (OpenStreetMap)
	npm --prefix $(BACKEND) run tracks

content: ## Enriquece os POIs com histórias reais (Wikipédia/Wikidata/Commons)
	npm --prefix $(BACKEND) run tracks
	npm --prefix $(BACKEND) run content

backend: ## Arranca o backend em modo dev (porta 3000)
	npm --prefix $(BACKEND) run dev

test: ## Smoke test end-to-end da API
	bash $(BACKEND)/scripts/smoke-test.sh

mobile-web: ## Corre o app Flutter em modo web-server (abre em qualquer navegador)
	cd $(MOBILE) && flutter run -d web-server --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000 $(MAP_DEFINES)

mobile-chrome: ## Corre o app Flutter no Helium/Chromium (auto-abre o navegador)
	cd $(MOBILE) && CHROME_EXECUTABLE=$(CHROME) flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 $(MAP_DEFINES)

emulator: ## Arranca o emulador Android (AVD 'kumpas')
	PATH="$(ANDROID_PATH)" emulator -avd $(AVD) -no-snapshot -gpu swiftshader_indirect -no-boot-anim &

emulator-stop: ## Para o emulador Android
	PATH="$(ANDROID_PATH)" adb emu kill || true

mobile-android: ## Corre o app Flutter no emulador Android (API em 10.0.2.2:3000)
	@PATH="$(ANDROID_PATH)" adb devices | grep -q 'emulator-5554' || { echo "Emulador não está a correr. Corre 'make emulator' noutro terminal."; exit 1; }
	cd $(MOBILE) && PATH="$(ANDROID_PATH)" flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 $(MAP_DEFINES)

waydroid-start: ## Arranca o Waydroid (precisa sudo; corre no teu terminal)
	bash scripts/waydroid-start.sh

waydroid-stop: ## Para o Waydroid
	waydroid session stop || true

mobile-device: ## Corre no telemóvel físico (USB). Uso: make mobile-device CARTO_KEY=... [DEVICE=<serial>]
	@test -n "$(DEVICE)" || { echo "Nenhum telemóvel USB detetado. Ativa a Depuração USB e aceita o prompt RSA; confirma com 'adb devices'."; exit 1; }
	@echo "Telemóvel: $(DEVICE)"
	PATH="$(ANDROID_PATH)" adb -s $(DEVICE) reverse tcp:3000 tcp:3000 || true
	cd $(MOBILE) && PATH="$(ANDROID_PATH)" flutter run -d $(DEVICE) --dart-define=API_BASE_URL=http://127.0.0.1:3000 $(MAP_DEFINES)

mobile-waydroid: ## Corre o app Flutter no Waydroid (API via adb reverse -> localhost:3000)
	PATH="$(ANDROID_PATH)" adb -s 192.168.240.112:5555 reverse tcp:3000 tcp:3000 || true
	PATH="$(ANDROID_PATH)" adb -s 192.168.240.112:5555 reverse tcp:3001 tcp:3001 || true
	cd $(MOBILE) && PATH="$(ANDROID_PATH)" flutter run -d 192.168.240.112:5555 --dart-define=API_BASE_URL=http://127.0.0.1:3000 $(MAP_DEFINES)

tiles-proxy: ## Proxy local de tiles CARTO para Waydroid sem internet (precisa CARTO_KEY)
	CARTO_KEY="$(CARTO_KEY)" node scripts/carto-proxy.mjs

clean: ## Limpa artefactos de build
	rm -rf $(BACKEND)/dist $(MOBILE)/build

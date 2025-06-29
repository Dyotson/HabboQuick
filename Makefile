.PHONY: setup start stop clean logs help

# Variables
COMPOSE_FILE = compose.yaml
COMPOSE_TRAEFIK_FILE = compose.traefik.yaml

help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Configurar el entorno automáticamente
	@echo "🚀 Configurando entorno de Habbo Quick..."
	@chmod +x setup.sh
	@./setup.sh
	@echo ""
	@echo "✅ Configuración completada!"
	@echo "Ahora ejecuta: make start"

start: setup ## Iniciar todos los servicios
	@echo "🚀 Iniciando servicios de Habbo Quick..."
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo ""
	@echo "🎉 ¡Servicios iniciados!"
	@echo ""
	@echo "📝 Servicios disponibles:"
	@echo "   🎮 Nitro Client: http://localhost:3000"
	@echo "   📦 Assets Server: http://localhost:8080"
	@echo "   🌐 CMS: http://localhost:8081"
	@echo "   🗄️  Base de datos: localhost:3310"
	@echo ""
	@echo "📊 Para ver logs: make logs"
	@echo "🛑 Para parar: make stop"

start-traefik: setup ## Iniciar con configuración de Traefik
	@echo "🚀 Iniciando servicios con Traefik..."
	@docker compose -f $(COMPOSE_FILE) -f $(COMPOSE_TRAEFIK_FILE) up -d

stop: ## Parar todos los servicios
	@echo "🛑 Parando servicios..."
	@docker compose -f $(COMPOSE_FILE) down

restart: ## Reiniciar todos los servicios
	@make stop
	@make start

logs: ## Ver logs de todos los servicios
	@docker compose -f $(COMPOSE_FILE) logs -f

logs-arcturus: ## Ver logs solo del emulador Arcturus
	@docker compose -f $(COMPOSE_FILE) logs -f arcturus

logs-nitro: ## Ver logs solo del cliente Nitro
	@docker compose -f $(COMPOSE_FILE) logs -f nitro

logs-db: ## Ver logs solo de la base de datos
	@docker compose -f $(COMPOSE_FILE) logs -f db

clean: ## Limpiar contenedores, imágenes y volúmenes
	@echo "🧹 Limpiando..."
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@docker system prune -f

clean-data: ## ⚠️ CUIDADO: Limpiar TODOS los datos (base de datos incluida)
	@echo "⚠️ ¿Estás seguro de que quieres eliminar TODOS los datos?"
	@echo "Esto incluye la base de datos y todos los assets descargados."
	@read -p "Escribe 'yes' para confirmar: " confirm && [ "$$confirm" = "yes" ]
	@make clean
	@sudo rm -rf db/data assets/swf assets/assets atomcms/storage atomcms/logs
	@echo "🗑️ Todos los datos han sido eliminados"

clean-generated: ## Limpiar todos los archivos generados automáticamente
	@echo "🧹 Limpiando archivos generados automáticamente..."
	@echo "📁 Eliminando assets descargados..."
	@rm -rf assets/swf assets/assets assets/usercontent/avatar/* assets/usercontent/camera/* assets/usercontent/badgeparts/generated/*
	@echo "📁 Eliminando datos de base de datos..."
	@rm -rf db/data/* db/dumps/* db/backup/*
	@echo "📁 Eliminando logs..."
	@rm -rf logs/* atomcms/logs/* *.log
	@echo "📁 Eliminando backups..."
	@rm -rf backups/*
	@echo "📁 Eliminando archivos de configuración generados..."
	@rm -f .env .cms.env nitro/renderer-config.json nitro/ui-config.json
	@echo "✅ Archivos generados eliminados. El repositorio está limpio."

status: ## Ver estado de los servicios
	@docker compose -f $(COMPOSE_FILE) ps

build: ## Reconstruir todas las imágenes
	@echo "🔨 Reconstruyendo imágenes..."
	@docker compose -f $(COMPOSE_FILE) build --no-cache

update: ## Actualizar y reconstruir
	@make stop
	@make build
	@make start

shell-arcturus: ## Abrir shell en el contenedor Arcturus
	@docker compose -f $(COMPOSE_FILE) exec arcturus bash

shell-db: ## Abrir shell MySQL
	@docker compose -f $(COMPOSE_FILE) exec db mysql -u arcturus_user -p arcturus

backup-db: ## Hacer backup de la base de datos
	@echo "💾 Creando backup de la base de datos..."
	@mkdir -p backups
	@docker compose -f $(COMPOSE_FILE) exec db mysqldump -u arcturus_user -p arcturus > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup creado en backups/"

dev: ## Modo desarrollo con live reload
	@echo "🔧 Iniciando en modo desarrollo..."
	@docker compose -f $(COMPOSE_FILE) up --build

install: ## Instalación completa desde cero
	@echo "📦 Instalación completa de Habbo Quick..."
	@make setup
	@make build
	@make start
	@echo ""
	@echo "🎉 ¡Instalación completada!"
	@echo "Tu servidor de Habbo está listo en: http://localhost:3000"

monitor: ## Monitorear el estado de todos los servicios
	@echo "🔍 Monitoreando servicios..."
	@chmod +x init/monitor-services.sh
	@./init/monitor-services.sh

full-install: ## Instalación completa automatizada con monitoreo
	@echo "🚀 Instalación completamente automatizada de Habbo Quick..."
	@make install
	@make monitor
	@echo ""
	@echo "🎉 ¡Todo está listo! Disfruta tu servidor de Habbo!"

quick-start: ## Inicio rápido (solo docker compose up)
	@echo "⚡ Inicio rápido con docker compose..."
	@docker compose up --build -d
	@echo ""
	@echo "⏳ Los servicios se están iniciando..."
	@echo "🔍 Usa 'make monitor' para verificar el estado"
	@echo "📊 Usa 'make logs' para ver los logs"

force-rebuild: ## Forzar reconstrucción completa
	@echo "🔨 Reconstruyendo todo desde cero..."
	@docker compose down -v --rmi all
	@docker system prune -f
	@make install

test: ## Ejecutar pruebas de integración
	@echo "🧪 Ejecutando pruebas de integración..."
	@chmod +x test-integration.sh
	@./test-integration.sh

dev-start: ## Iniciar en modo desarrollo con logs centralizados
	@echo "🔧 Iniciando en modo desarrollo..."
	@make setup
	@docker compose -f compose.yaml -f compose.dev.yaml up --build -d
	@echo ""
	@echo "🔧 Servicios de desarrollo disponibles:"
	@echo "   📊 Log Viewer: http://localhost:9999"
	@echo "   🎮 Nitro Client: http://localhost:3000"
	@echo "   📦 Assets Server: http://localhost:8080"
	@echo "   🌐 CMS: http://localhost:8081"

dev-logs: ## Ver logs de desarrollo centralizados
	@echo "📊 Abriendo visor de logs..."
	@echo "🔗 Visita: http://localhost:9999"

dev-stop: ## Parar servicios de desarrollo
	@echo "🛑 Parando servicios de desarrollo..."
	@docker compose -f compose.yaml -f compose.dev.yaml down

git-status: ## Verificar estado de git después de limpiar
	@echo "📊 Estado de git después de ejecutar setup:"
	@git status --porcelain | head -20
	@echo ""
	@echo "💡 Tip: Ejecuta 'make clean-generated' para limpiar archivos generados"

check-gitignore: ## Verificar que gitignore funciona correctamente
	@chmod +x verify-gitignore.sh
	@./verify-gitignore.sh

verify-repo-clean: ## Verificar que el repositorio está limpio después del setup
	@echo "🔍 Verificando limpieza del repositorio..."
	@echo "📊 Ejecutando setup y verificando archivos generados..."
	@make clean-generated > /dev/null 2>&1 || true
	@./verify-gitignore.sh

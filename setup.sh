#!/bin/bash
set -e

echo "⚙️ Configurando entorno automáticamente..."

# Función para mostrar progress
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    echo "📊 [$current/$total] $message"
}

# Función para copiar archivos de ejemplo
copy_example_files() {
    show_progress 1 6 "Copiando archivos de configuración de ejemplo..."
    
    # Copiar .env si no existe
    if [ ! -f ".env" ]; then
        if [ -f "example-.env" ]; then
            cp "example-.env" ".env"
            echo "✅ Archivo .env creado desde example-.env"
        fi
    fi
    
    # Copiar .cms.env si no existe
    if [ ! -f ".cms.env" ]; then
        if [ -f "example-.cms.env" ]; then
            cp "example-.cms.env" ".cms.env"
            echo "✅ Archivo .cms.env creado desde example-.cms.env"
        fi
    fi
    
    # Copiar archivos de configuración de Nitro
    if [ ! -f "nitro/renderer-config.json" ]; then
        if [ -f "nitro/example-renderer-config.json" ]; then
            cp "nitro/example-renderer-config.json" "nitro/renderer-config.json"
            echo "✅ Archivo nitro/renderer-config.json creado"
        fi
    fi
    
    if [ ! -f "nitro/ui-config.json" ]; then
        if [ -f "nitro/example-ui-config.json" ]; then
            cp "nitro/example-ui-config.json" "nitro/ui-config.json"
            echo "✅ Archivo nitro/ui-config.json creado"
        fi
    fi
}

# Función para crear directorios necesarios
create_directories() {
    show_progress 2 6 "Creando directorios necesarios..."
    
    directories=(
        "assets/swf"
        "assets/assets"
        "assets/usercontent/avatar"
        "assets/usercontent/camera"
        "assets/usercontent/camera/thumbnail"
        "assets/usercontent/imageproxy/cache"
        "assets/usercontent/badgeparts/generated"
        "db/data"
        "db/conf.d"
        "db/dumps"
        "db/backup"
        "atomcms/storage"
        "atomcms/logs"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "✅ Directorio $dir creado"
        fi
    done
}

# Función para configurar permisos
set_permissions() {
    show_progress 3 6 "Configurando permisos..."
    
    # Permisos para directorios de assets
    if [ -d "assets" ]; then
        chmod -R 755 assets/
    fi
    
    # Permisos para directorios de base de datos
    if [ -d "db" ]; then
        chmod -R 755 db/
    fi
    
    # Permisos para directorios de CMS
    if [ -d "atomcms" ]; then
        chmod -R 755 atomcms/
    fi
    
    # Permisos para scripts
    chmod +x init/*.sh 2>/dev/null || true
}

# Función para verificar dependencias
check_dependencies() {
    show_progress 4 6 "Verificando dependencias..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado. Por favor instala Docker primero."
        echo "🔗 https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose no está instalado. Por favor instala Docker Compose primero."
        echo "🔗 https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    echo "✅ Docker y Docker Compose están disponibles"
}

# Función para optimizar configuración
optimize_configuration() {
    show_progress 5 6 "Optimizando configuración..."
    
    # Configurar variables de entorno para mejor rendimiento
    if [ -f ".env" ]; then
        # Agregar configuraciones optimizadas si no existen
        if ! grep -q "COMPOSE_PARALLEL_LIMIT" .env; then
            echo "COMPOSE_PARALLEL_LIMIT=10" >> .env
        fi
        
        if ! grep -q "COMPOSE_HTTP_TIMEOUT" .env; then
            echo "COMPOSE_HTTP_TIMEOUT=300" >> .env
        fi
        
        echo "✅ Configuración optimizada"
    fi
}

# Función para mostrar información final
show_final_info() {
    show_progress 6 6 "Configuración completada"
    
    echo ""
    echo "🎉 Configuración automática completada!"
    echo ""
    echo "🚀 Comandos disponibles:"
    echo "   docker compose up       # Inicio automático completo"
    echo "   make install           # Instalación con make"
    echo "   make full-install      # Instalación + monitoreo"
    echo "   make quick-start       # Inicio rápido"
    echo ""
    echo "📝 Los servicios estarán disponibles en:"
    echo "   - 🎮 Nitro Client: http://localhost:3000"
    echo "   - 📦 Assets Server: http://localhost:8080"
    echo "   - 🌐 CMS: http://localhost:8081"
    echo "   - 🗄️ Base de datos: localhost:3310"
    echo ""
    echo "⚡ Para monitorear: make monitor"
    echo "📊 Para ver logs: make logs"
}

# Ejecutar funciones
echo "🔧 Iniciando configuración automatizada de Habbo Quick..."
echo ""

check_dependencies
copy_example_files
create_directories
set_permissions
optimize_configuration
show_final_info

echo ""
echo "✨ ¡Todo listo! Tu entorno está configurado para funcionar automáticamente."

#!/bin/bash
set -e

echo "🌐 Iniciando configuración automática del CMS..."

# Esperar a que el CMS esté disponible
echo "⏳ Esperando a que el CMS esté disponible..."
while ! curl -f http://cms:80 >/dev/null 2>&1; do
    sleep 5
    echo "⏳ Esperando CMS..."
done

echo "✅ CMS está disponible!"

# Esperar un poco más para asegurar que todo esté listo
sleep 10

# Generar APP_KEY si no existe
echo "🔑 Generando clave de aplicación..."
if ! docker compose exec cms php artisan key:generate --force; then
    echo "⚠️ Error generando la clave, reintentando..."
    sleep 5
    docker compose exec cms php artisan key:generate --force || true
fi

# Ejecutar migraciones si es necesario
echo "📊 Ejecutando migraciones..."
docker compose exec cms php artisan migrate --force || true

# Limpiar cache
echo "🧹 Limpiando cache..."
docker compose exec cms php artisan cache:clear || true
docker compose exec cms php artisan config:clear || true
docker compose exec cms php artisan route:clear || true
docker compose exec cms php artisan view:clear || true

# Optimizar para producción
echo "⚡ Optimizando para producción..."
docker compose exec cms php artisan config:cache || true
docker compose exec cms php artisan route:cache || true

echo "✅ Configuración del CMS completada!"
echo "🌐 El CMS está disponible en: http://localhost:8081"

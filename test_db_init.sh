#!/bin/bash
set -e

echo "🧪 Script de prueba para verificar inicialización de base de datos"

# Configurar variables de entorno si no existen
export DB_HOSTNAME=${DB_HOSTNAME:-"db"}
export MYSQL_USER=${MYSQL_USER:-"arcturus_user"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"arcturus_pw"}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"arcturus"}

echo "📋 Configuración de prueba:"
echo "   - DB_HOSTNAME: $DB_HOSTNAME"
echo "   - MYSQL_USER: $MYSQL_USER"
echo "   - MYSQL_DATABASE: $MYSQL_DATABASE"
echo ""

# Verificar conexión
echo "🔌 Probando conexión a base de datos..."
if mysqladmin ping -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
    echo "✅ Conexión exitosa"
else
    echo "❌ No se pudo conectar a la base de datos"
    echo "💡 Asegúrate de que el contenedor 'db' esté ejecutándose"
    exit 1
fi

# Verificar tablas críticas
echo ""
echo "🔍 Verificando tablas críticas..."

CRITICAL_TABLES="emulator_settings emulator_texts users permission_groups"

for table in $CRITICAL_TABLES; do
    if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -q "$table"; then
        
        # Contar registros
        COUNT=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table;" 2>/dev/null | tail -1)
        
        if [ $? -eq 0 ]; then
            echo "✅ Tabla $table: $COUNT registros"
        else
            echo "⚠️ Tabla $table: existe pero hay problemas de acceso"
        fi
    else
        echo "❌ Tabla $table: no encontrada"
    fi
done

# Verificar configuraciones específicas
echo ""
echo "🔧 Verificando configuraciones específicas..."

# Configuraciones del emulador
CONFIGS_TO_CHECK="camera.url;rcon.host;rcon.port;websockets.whitelist"

echo "Configuraciones del emulador:"
IFS=';' read -ra CONFIG_ARRAY <<< "$CONFIGS_TO_CHECK"
for config in "${CONFIG_ARRAY[@]}"; do
    VALUE=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT value FROM emulator_settings WHERE \`key\`='$config';" 2>/dev/null | tail -1)
    if [ -n "$VALUE" ] && [ "$VALUE" != "value" ]; then
        echo "  ✅ $config = $VALUE"
    else
        echo "  ❌ $config = no configurado"
    fi
done

echo ""
echo "🎉 Verificación completada"
echo ""
echo "💡 Para ejecutar este script:"
echo "   bash test_db_init.sh"
echo ""
echo "💡 Para reiniciar el inicializador de base de datos:"
echo "   docker compose up db-initializer --force-recreate"

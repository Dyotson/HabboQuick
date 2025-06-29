#!/bin/bash
set -e

echo "🗄️ Iniciando configuración automática de base de datos..."

# Esperar a que MySQL esté disponible
echo "⏳ Esperando a que MySQL esté disponible..."
while ! mysqladmin ping -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    sleep 2
done

echo "✅ MySQL está disponible!"

# Verificar si la base de datos ya está inicializada
TABLES_COUNT=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES;" 2>/dev/null | wc -l)

if [ "$TABLES_COUNT" -lt 10 ]; then
    echo "📊 Inicializando base de datos..."
    
    # Importar base de datos base
    if [ -f "/sql/arcturus_3.0.0-stable_base_database--compact.sql" ]; then
        echo "📊 Importando base de datos base..."
        mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /sql/arcturus_3.0.0-stable_base_database--compact.sql
    fi
    
    # Importar catálogo
    if [ -f "/sql/catalog_2022.sql" ]; then
        echo "📊 Importando catálogo..."
        mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /sql/catalog_2022.sql
    fi
    
    # Importar permisos (verificar si la tabla existe primero)
    if [ -f "/sql/perms_groups.sql" ]; then
        echo "📊 Importando permisos..."
        # Verificar si las tablas necesarias existen
        TABLE_EXISTS=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE 'permission_group_commands';" 2>/dev/null | wc -l)
        
        if [ "$TABLE_EXISTS" -gt 0 ]; then
            mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < /sql/perms_groups.sql
        else
            echo "⚠️  Tabla 'permission_group_commands' no existe, saltando importación de permisos..."
        fi
    fi
    
    # Ejecutar script de permisos Python si existe
    if [ -f "/sql/perms_sql.py" ] && [ -f "/sql/perms.xlsx" ]; then
        echo "📊 Ejecutando script de permisos Python..."
        cd /sql
        python3 perms_sql.py
        if [ -f "permissions_output.sql" ]; then
            mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < permissions_output.sql
        fi
    fi
    
    echo "✅ Base de datos inicializada correctamente!"
else
    echo "✅ Base de datos ya está inicializada, saltando..."
fi

# Configurar automáticamente todas las configuraciones de emulator_settings
echo "⚙️ Configurando settings del emulador automáticamente..."

mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" << 'EOF'
-- Configuraciones para el módulo de cámara
UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/usercontent/camera/' WHERE `key`='camera.url';
UPDATE emulator_settings SET `value`='/app/assets/usercontent/camera/' WHERE `key`='imager.location.output.camera';
UPDATE emulator_settings SET `value`='/app/assets/usercontent/camera/thumbnail/' WHERE `key`='imager.location.output.thumbnail';

-- Proxy para imágenes de YouTube usando microservicio
UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/api/imageproxy/0x0/http://img.youtube.com/vi/%video%/default.jpg' WHERE `key`='imager.url.youtube';

-- Deshabilitar modo consola para Docker
UPDATE emulator_settings SET `value`='0' WHERE `key`='console.mode';

-- Configuración para badges generados dinámicamente
UPDATE emulator_settings SET `value`='/app/assets/usercontent/badgeparts/generated/' WHERE `key`='imager.location.output.badges';
UPDATE emulator_settings SET `value`='/app/assets/swf/c_images/Badgeparts' WHERE `key`='imager.location.badgeparts';

-- Configuración de websockets
UPDATE emulator_settings SET `value`='*' WHERE `key`='websockets.whitelist';

-- Configuraciones de paths para assets
UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/swf/' WHERE `key`='camera.extradata.url';
UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/assets/' WHERE `key`='assets.url';

-- Configuraciones de RCON para CMS
UPDATE emulator_settings SET `value`='0.0.0.0' WHERE `key`='rcon.host';
UPDATE emulator_settings SET `value`='3001' WHERE `key`='rcon.port';
UPDATE emulator_settings SET `value`='arcturus' WHERE `key`='rcon.password';

-- Configuraciones adicionales para estabilidad
UPDATE emulator_settings SET `value`='30' WHERE `key`='hotel.max.users.per.room';
UPDATE emulator_settings SET `value`='5000' WHERE `key`='hotel.max.rooms.per.user';
UPDATE emulator_settings SET `value`='1' WHERE `key`='hotel.beta.enabled';
EOF

echo "✅ Settings del emulador configurados!"

# Configurar website_settings para AtomCMS si la tabla existe
if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE 'website_settings';" | grep -q website_settings; then
    echo "⚙️ Configurando settings del CMS automáticamente..."
    
    mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" << 'EOF'
-- Configuraciones para AtomCMS
UPDATE website_settings SET `value` = 'http://127.0.0.1:8080/api/imager/?figure=' WHERE `key` = 'avatar_imager';
UPDATE website_settings SET `value` = 'http://127.0.0.1:8080/swf/c_images/album1584' WHERE `key` = 'badges_path';
UPDATE website_settings SET `value` = 'http://127.0.0.1:8080/usercontent/badgeparts/generated' WHERE `key` = 'group_badge_path';
UPDATE website_settings SET `value` = 'http://127.0.0.1:8080/swf/dcr/hof_furni' WHERE `key` = 'furniture_icons_path';

-- Configuraciones RCON para CMS
UPDATE website_settings SET `value` = 'arcturus' WHERE `key` = 'rcon_ip';
UPDATE website_settings SET `value` = '3001' WHERE `key` = 'rcon_port';

-- Configuraciones de permisos (asumiendo perms_groups.sql)
UPDATE website_settings SET `value` = '4' WHERE `key` = 'min_staff_rank';

-- URLs y paths del hotel
UPDATE website_settings SET `value` = 'http://127.0.0.1:3000' WHERE `key` = 'hotel_url';
UPDATE website_settings SET `value` = 'ws://127.0.0.1:2096' WHERE `key` = 'websocket_url';
UPDATE website_settings SET `value` = 'http://127.0.0.1:8080' WHERE `key` = 'assets_url';
EOF
    
    echo "✅ Settings del CMS configurados!"
else
    echo "ℹ️ Tabla website_settings no encontrada, saltando configuración del CMS..."
fi

echo "🎉 Configuración de base de datos completada!"
echo "📊 Resumen de configuración:"
echo "   - ✅ Base de datos inicializada"
echo "   - ✅ Configuraciones del emulador aplicadas"
echo "   - ✅ Configuraciones del CMS aplicadas (si aplica)"
echo "   - ✅ Websockets configurados"
echo "   - ✅ RCON configurado"

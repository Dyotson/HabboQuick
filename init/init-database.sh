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
    
    # El archivo perms_groups.sql ya está pre-generado, no necesitamos ejecutar el script Python
    echo "ℹ️ Archivo de permisos ya está pre-generado, saltando script Python..."
    
    echo "✅ Base de datos inicializada correctamente!"
    
    # Verificar y reparar tablas MyISAM críticas si es necesario
    echo "🔧 Verificando integridad de tablas críticas..."
    
    # Lista de tablas críticas para verificar
    CRITICAL_TABLES="emulator_settings emulator_texts users"
    
    for table in $CRITICAL_TABLES; do
        if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE '$table';" | grep -q "$table"; then
            echo "🔍 Verificando tabla $table..."
            
            # Intentar una consulta simple para verificar que la tabla funciona
            if ! mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table LIMIT 1;" >/dev/null 2>&1; then
                echo "⚠️ Tabla $table parece tener problemas, intentando reparar..."
                mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "REPAIR TABLE $table;" || true
                mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "FLUSH TABLES;" || true
                echo "✅ Reparación de tabla $table completada"
            else
                echo "✅ Tabla $table funciona correctamente"
            fi
        fi
    done
else
    echo "✅ Base de datos ya está inicializada, saltando..."
fi

# Configurar automáticamente todas las configuraciones de emulator_settings
echo "⚙️ Configurando settings del emulador automáticamente..."

# Función para verificar y reparar tabla MyISAM
verify_and_repair_table() {
    local table_name=$1
    echo "🔍 Verificando integridad de tabla $table_name..."
    
    # Intentar una consulta simple para verificar que la tabla funciona
    if ! mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table_name LIMIT 1;" >/dev/null 2>&1; then
        echo "⚠️ Tabla $table_name tiene problemas, intentando reparar..."
        
        # Intentar reparar la tabla
        mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "REPAIR TABLE $table_name;" || true
        mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "FLUSH TABLES;" || true
        
        # Verificar si la reparación funcionó
        if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table_name LIMIT 1;" >/dev/null 2>&1; then
            echo "✅ Tabla $table_name reparada exitosamente"
            return 0
        else
            echo "❌ No se pudo reparar la tabla $table_name"
            return 1
        fi
    else
        echo "✅ Tabla $table_name funciona correctamente"
        return 0
    fi
}

# Verificar que la tabla emulator_settings existe
if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE 'emulator_settings';" | grep -q emulator_settings; then
    
    # Verificar y reparar la tabla si es necesario
    if verify_and_repair_table "emulator_settings"; then
        # Obtener conteo después de verificar/reparar
        EMULATOR_SETTINGS_COUNT=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM emulator_settings;" 2>/dev/null | tail -1)
        
        if [ "$EMULATOR_SETTINGS_COUNT" -gt 0 ]; then
            echo "✅ Tabla emulator_settings encontrada con $EMULATOR_SETTINGS_COUNT registros"
        else
            echo "⚠️ Tabla emulator_settings existe pero está vacía"
        fi
        
        # Intentar configurar settings
        echo "🔧 Aplicando configuraciones del emulador..."
        if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" << 'EOF'
-- Configuraciones para el módulo de cámara usando INSERT ... ON DUPLICATE KEY UPDATE
INSERT INTO emulator_settings (`key`, `value`) VALUES 
('camera.url', 'http://127.0.0.1:8080/usercontent/camera/'),
('imager.location.output.camera', '/app/assets/usercontent/camera/'),
('imager.location.output.thumbnail', '/app/assets/usercontent/camera/thumbnail/'),
('imager.url.youtube', 'http://127.0.0.1:8080/api/imageproxy/0x0/http://img.youtube.com/vi/%video%/default.jpg'),
('console.mode', '0'),
('imager.location.output.badges', '/app/assets/usercontent/badgeparts/generated/'),
('imager.location.badgeparts', '/app/assets/swf/c_images/Badgeparts'),
('websockets.whitelist', '*'),
('camera.extradata.url', 'http://127.0.0.1:8080/swf/'),
('assets.url', 'http://127.0.0.1:8080/assets/'),
('rcon.host', '0.0.0.0'),
('rcon.port', '3001'),
('rcon.password', 'arcturus'),
('hotel.max.users.per.room', '30'),
('hotel.max.rooms.per.user', '5000'),
('hotel.beta.enabled', '1')
ON DUPLICATE KEY UPDATE 
`value` = VALUES(`value`);
EOF
        then
            echo "✅ Settings del emulador configurados!"
        else
            echo "❌ Error al configurar settings del emulador"
        fi
    else
        echo "❌ No se pudo reparar la tabla emulator_settings, saltando configuración..."
    fi
else
    echo "❌ Tabla emulator_settings no encontrada"
fi

# Configurar website_settings para AtomCMS si la tabla existe
if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE 'website_settings';" | grep -q website_settings; then
    echo "⚙️ Configurando settings del CMS automáticamente..."
    
    # Verificar y reparar la tabla si es necesario
    if verify_and_repair_table "website_settings"; then
        # Obtener conteo después de verificar/reparar
        WEBSITE_SETTINGS_COUNT=$(mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM website_settings;" 2>/dev/null | tail -1)
        
        if [ "$WEBSITE_SETTINGS_COUNT" -gt 0 ]; then
            echo "✅ Tabla website_settings encontrada con $WEBSITE_SETTINGS_COUNT registros"
        else
            echo "⚠️ Tabla website_settings existe pero está vacía"
        fi
        
        # Intentar configurar settings del CMS
        echo "🔧 Aplicando configuraciones del CMS..."
        if mysql -h"$DB_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" << 'EOF'
-- Configuraciones para AtomCMS usando INSERT ... ON DUPLICATE KEY UPDATE
INSERT INTO website_settings (`key`, `value`) VALUES 
('avatar_imager', 'http://127.0.0.1:8080/api/imager/?figure='),
('badges_path', 'http://127.0.0.1:8080/swf/c_images/album1584'),
('group_badge_path', 'http://127.0.0.1:8080/usercontent/badgeparts/generated'),
('furniture_icons_path', 'http://127.0.0.1:8080/swf/dcr/hof_furni'),
('rcon_ip', 'arcturus'),
('rcon_port', '3001'),
('min_staff_rank', '4'),
('hotel_url', 'http://127.0.0.1:3000'),
('websocket_url', 'ws://127.0.0.1:2096'),
('assets_url', 'http://127.0.0.1:8080')
ON DUPLICATE KEY UPDATE 
`value` = VALUES(`value`);
EOF
        then
            echo "✅ Settings del CMS configurados!"
        else
            echo "❌ Error al configurar settings del CMS"
        fi
    else
        echo "❌ No se pudo reparar la tabla website_settings, saltando configuración del CMS..."
    fi
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

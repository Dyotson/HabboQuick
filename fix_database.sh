#!/bin/bash
set -e

echo "🔧 Script de reparación de base de datos HabboQuick"
echo "=================================================="

# Configurar variables de entorno si no existen
export DB_HOSTNAME=${DB_HOSTNAME:-"localhost"}
export MYSQL_USER=${MYSQL_USER:-"arcturus_user"}
export MYSQL_PASSWORD=${MYSQL_PASSWORD:-"arcturus_pw"}
export MYSQL_DATABASE=${MYSQL_DATABASE:-"arcturus"}
export MYSQL_PORT=${MYSQL_PORT:-"3310"}

echo "📋 Configuración:"
echo "   - DB_HOSTNAME: $DB_HOSTNAME"
echo "   - MYSQL_USER: $MYSQL_USER"
echo "   - MYSQL_DATABASE: $MYSQL_DATABASE"
echo "   - MYSQL_PORT: $MYSQL_PORT"
echo ""

# Función para verificar conexión
check_connection() {
    echo "🔌 Verificando conexión a base de datos..."
    
    if mysqladmin ping -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
        echo "✅ Conexión exitosa"
        return 0
    else
        echo "❌ No se pudo conectar a la base de datos"
        echo "💡 Asegúrate de que el contenedor 'db' esté ejecutándose"
        return 1
    fi
}

# Función para verificar y reparar tabla MyISAM
verify_and_repair_table() {
    local table_name=$1
    echo "🔍 Verificando integridad de tabla $table_name..."
    
    # Verificar si la tabla existe
    if ! mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES LIKE '$table_name';" | grep -q "$table_name"; then
        echo "❌ Tabla $table_name no existe"
        return 1
    fi
    
    # Intentar una consulta simple para verificar que la tabla funciona
    if ! mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table_name LIMIT 1;" >/dev/null 2>&1; then
        echo "⚠️ Tabla $table_name tiene problemas, intentando reparar..."
        
        # Mostrar información sobre el motor de la tabla
        ENGINE=$(mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLE STATUS LIKE '$table_name';" | tail -1 | awk '{print $2}')
        echo "ℹ️ Motor de tabla: $ENGINE"
        
        # Intentar reparar la tabla
        echo "🔧 Ejecutando REPAIR TABLE $table_name..."
        mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "REPAIR TABLE $table_name;" || true
        
        echo "🧹 Ejecutando FLUSH TABLES..."
        mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "FLUSH TABLES;" || true
        
        # Verificar si la reparación funcionó
        if mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table_name LIMIT 1;" >/dev/null 2>&1; then
            echo "✅ Tabla $table_name reparada exitosamente"
            return 0
        else
            echo "❌ No se pudo reparar la tabla $table_name"
            
            # Intentar como último recurso convertir a InnoDB
            echo "🔄 Intentando convertir tabla $table_name a InnoDB como último recurso..."
            if mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "ALTER TABLE $table_name ENGINE=InnoDB;" 2>/dev/null; then
                echo "✅ Tabla $table_name convertida a InnoDB exitosamente"
                return 0
            else
                echo "❌ Conversión a InnoDB falló"
                return 1
            fi
        fi
    else
        # Obtener conteo de registros
        COUNT=$(mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tail -1)
        echo "✅ Tabla $table_name funciona correctamente ($COUNT registros)"
        return 0
    fi
}

# Función para aplicar configuraciones del emulador
apply_emulator_settings() {
    echo "⚙️ Aplicando configuraciones del emulador..."
    
    mysql -h"$DB_HOSTNAME" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" << 'EOF'
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
    
    if [ $? -eq 0 ]; then
        echo "✅ Configuraciones del emulador aplicadas exitosamente"
        return 0
    else
        echo "❌ Error al aplicar configuraciones del emulador"
        return 1
    fi
}

# Función principal
main() {
    echo "🚀 Iniciando reparación de base de datos..."
    echo ""
    
    # Verificar conexión
    if ! check_connection; then
        exit 1
    fi
    
    echo ""
    echo "🔧 Verificando y reparando tablas críticas..."
    
    # Lista de tablas críticas para verificar
    CRITICAL_TABLES="emulator_settings emulator_texts users permission_groups"
    
    for table in $CRITICAL_TABLES; do
        echo ""
        verify_and_repair_table "$table"
    done
    
    echo ""
    echo "⚙️ Aplicando configuraciones..."
    
    # Aplicar configuraciones del emulador
    if verify_and_repair_table "emulator_settings"; then
        apply_emulator_settings
    else
        echo "❌ No se pueden aplicar configuraciones del emulador debido a problemas con la tabla"
    fi
    
    echo ""
    echo "🎉 Proceso de reparación completado!"
    echo ""
    echo "💡 Para verificar que todo funciona correctamente, ejecuta:"
    echo "   bash test_db_init.sh"
    echo ""
    echo "💡 Para reiniciar el inicializador de base de datos:"
    echo "   docker compose up db-initializer --force-recreate"
}

# Ejecutar función principal
main "$@"

#!/bin/bash
set -e

echo "🆘 Script de emergencia para arreglar db-initializer"
echo "================================================="

# Configurar variables
DB_CONTAINER="db"
DB_USER="arcturus_user"
DB_PASSWORD="arcturus_pw"
DB_NAME="arcturus"

echo "🔧 Pasos para arreglar el problema:"
echo "1. Parar el db-initializer que está fallando"
echo "2. Reparar la tabla emulator_settings directamente"
echo "3. Aplicar configuraciones necesarias"
echo "4. Reiniciar el inicializador"
echo ""

# Paso 1: Parar el inicializador
echo "🛑 Paso 1: Parando db-initializer..."
docker compose stop db-initializer 2>/dev/null || true
docker compose rm -f db-initializer 2>/dev/null || true
echo "✅ db-initializer parado"

# Paso 2: Verificar que la base de datos está funcionando
echo "🔍 Paso 2: Verificando conexión a base de datos..."
if docker compose exec db mysqladmin ping -u"$DB_USER" -p"$DB_PASSWORD" --silent; then
    echo "✅ Base de datos funcionando correctamente"
else
    echo "❌ Error: Base de datos no responde"
    exit 1
fi

# Paso 3: Reparar la tabla emulator_settings
echo "🔧 Paso 3: Reparando tabla emulator_settings..."
docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "REPAIR TABLE emulator_settings;" || true
docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "FLUSH TABLES;" || true

# Verificar si la reparación funcionó
echo "🔍 Verificando reparación..."
if docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM emulator_settings LIMIT 1;" >/dev/null 2>&1; then
    echo "✅ Tabla emulator_settings reparada exitosamente"
else
    echo "⚠️ Reparación básica falló, intentando conversión a InnoDB..."
    docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "ALTER TABLE emulator_settings ENGINE=InnoDB;" || true
    
    if docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM emulator_settings LIMIT 1;" >/dev/null 2>&1; then
        echo "✅ Tabla convertida a InnoDB exitosamente"
    else
        echo "❌ Error: No se pudo reparar la tabla"
        exit 1
    fi
fi

# Paso 4: Aplicar configuraciones básicas
echo "⚙️ Paso 4: Aplicando configuraciones básicas..."
docker compose exec db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
INSERT INTO emulator_settings (`key`, `value`) VALUES 
('camera.url', 'http://127.0.0.1:8080/usercontent/camera/'),
('imager.location.output.camera', '/app/assets/usercontent/camera/'),
('imager.location.output.thumbnail', '/app/assets/usercontent/camera/thumbnail/'),
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
    echo "✅ Configuraciones aplicadas exitosamente"
else
    echo "❌ Error aplicando configuraciones"
    exit 1
fi

# Paso 5: Reiniciar el inicializador
echo "🚀 Paso 5: Reiniciando db-initializer..."
docker compose up db-initializer -d

# Paso 6: Verificar que funciona
echo "🔍 Paso 6: Verificando funcionamiento..."
sleep 5

# Verificar logs del inicializador
echo "📋 Logs del db-initializer:"
docker compose logs db-initializer --tail=20

echo ""
echo "🎉 Proceso de reparación completado!"
echo ""
echo "💡 Comandos útiles:"
echo "   make test-db        # Verificar base de datos"
echo "   make logs-db        # Ver logs de base de datos"
echo "   make fix-db         # Ejecutar reparación completa"
echo ""
echo "🔗 Si el problema persiste, contacta al equipo de desarrollo"

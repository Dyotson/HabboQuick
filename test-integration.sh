#!/bin/bash

echo "🧪 Ejecutando pruebas de integración..."

# Función para mostrar resultados
show_result() {
    local test_name=$1
    local result=$2
    if [ $result -eq 0 ]; then
        echo "✅ $test_name: PASÓ"
    else
        echo "❌ $test_name: FALLÓ"
    fi
}

# Test 1: Verificar que docker compose esté funcionando
echo "🔍 Test 1: Verificando docker compose..."
docker compose ps > /dev/null 2>&1
show_result "Docker Compose Status" $?

# Test 2: Verificar conectividad a la base de datos
echo "🔍 Test 2: Verificando base de datos..."
timeout 10 bash -c "while ! nc -z localhost 3310; do sleep 1; done" 2>/dev/null
show_result "MySQL Database Connection" $?

# Test 3: Verificar Assets Server
echo "🔍 Test 3: Verificando Assets Server..."
curl -s -f http://localhost:8080 > /dev/null 2>&1
show_result "Assets Server HTTP Response" $?

# Test 4: Verificar Nitro Client
echo "🔍 Test 4: Verificando Nitro Client..."
curl -s -f http://localhost:3000 > /dev/null 2>&1
show_result "Nitro Client HTTP Response" $?

# Test 5: Verificar CMS
echo "🔍 Test 5: Verificando CMS..."
curl -s -f http://localhost:8081 > /dev/null 2>&1
show_result "CMS HTTP Response" $?

# Test 6: Verificar WebSocket Arcturus
echo "🔍 Test 6: Verificando WebSocket Arcturus..."
timeout 5 bash -c "while ! nc -z localhost 2096; do sleep 1; done" 2>/dev/null
show_result "Arcturus WebSocket Connection" $?

# Test 7: Verificar que los assets existen
echo "🔍 Test 7: Verificando assets descargados..."
if [ -f "assets/swf/gamedata/external_variables.txt" ] && [ -d "assets/assets" ]; then
    show_result "Assets Download" 0
else
    show_result "Assets Download" 1
fi

# Test 8: Verificar configuración de la base de datos
echo "🔍 Test 8: Verificando configuración de base de datos..."
tables_count=$(docker compose exec -T db mysql -u arcturus_user -parcturus_pw arcturus -e "SHOW TABLES;" 2>/dev/null | wc -l)
if [ "$tables_count" -gt 10 ]; then
    show_result "Database Configuration" 0
else
    show_result "Database Configuration" 1
fi

echo ""
echo "🧪 Pruebas de integración completadas!"
echo ""
echo "📊 Resumen:"
echo "   - Si todos los tests pasaron: ✅ Tu servidor está funcionando perfectamente"
echo "   - Si algún test falló: ❌ Revisa los logs con 'make logs'"
echo ""
echo "🚀 ¡Disfruta tu servidor de Habbo!"

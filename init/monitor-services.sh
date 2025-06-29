#!/bin/bash
set -e

echo "🔍 Iniciando monitoreo de servicios..."

# Función para verificar servicio
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo "🔍 Verificando $service_name en $url..."
    
    for i in {1..30}; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
            echo "✅ $service_name está funcionando correctamente"
            return 0
        fi
        echo "⏳ Esperando $service_name... (intento $i/30)"
        sleep 10
    done
    
    echo "❌ $service_name no responde después de 5 minutos"
    return 1
}

# Función para verificar puerto
check_port() {
    local service_name=$1
    local host=$2
    local port=$3
    
    echo "🔍 Verificando puerto $port para $service_name..."
    
    for i in {1..30}; do
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "✅ $service_name puerto $port está abierto"
            return 0
        fi
        echo "⏳ Esperando puerto $port para $service_name... (intento $i/30)"
        sleep 10
    done
    
    echo "❌ $service_name puerto $port no responde después de 5 minutos"
    return 1
}

# Esperar un poco para que los servicios se inicien
echo "⏳ Esperando que los servicios se inicialicen..."
sleep 60

echo "🔍 Verificando servicios principales..."

# Verificar base de datos
if check_port "MySQL Database" "localhost" "3310"; then
    echo "✅ Base de datos MySQL funcionando"
else
    echo "❌ Error en base de datos MySQL"
    exit 1
fi

# Verificar Assets Server
if check_service "Assets Server" "http://localhost:8080"; then
    echo "✅ Servidor de Assets funcionando"
else
    echo "❌ Error en servidor de Assets"
    exit 1
fi

# Verificar Websocket Arcturus
if check_port "Arcturus WebSocket" "localhost" "2096"; then
    echo "✅ Arcturus WebSocket funcionando"
else
    echo "❌ Error en Arcturus WebSocket"
    exit 1
fi

# Verificar Cliente Nitro
if check_service "Nitro Client" "http://localhost:3000"; then
    echo "✅ Cliente Nitro funcionando"
else
    echo "❌ Error en Cliente Nitro"
    exit 1
fi

# Verificar CMS
if check_service "AtomCMS" "http://localhost:8081"; then
    echo "✅ CMS funcionando"
else
    echo "❌ Error en CMS"
    exit 1
fi

echo ""
echo "🎉 ¡Todos los servicios están funcionando correctamente!"
echo ""
echo "📝 Servicios disponibles:"
echo "   🎮 Nitro Client: http://localhost:3000"
echo "   📦 Assets Server: http://localhost:8080"
echo "   🌐 CMS: http://localhost:8081"
echo "   🗄️ Base de datos: localhost:3310"
echo ""
echo "🚀 ¡Tu servidor de Habbo está listo para usar!"

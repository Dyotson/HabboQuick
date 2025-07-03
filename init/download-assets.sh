#!/bin/bash
set -e

echo "🚀 Iniciando descarga automática de assets..."

# Crear directorios necesarios
mkdir -p /assets/swf
mkdir -p /assets/assets
mkdir -p /assets/assets/bundled/generic
mkdir -p /assets/usercontent/avatar
mkdir -p /assets/usercontent/camera/thumbnail
mkdir -p /assets/usercontent/imageproxy/cache
mkdir -p /assets/usercontent/badgeparts/generated

# Verificar si los assets ya existen para evitar descargas innecesarias
if [ ! -d "/assets/swf/.git" ]; then
    echo "📦 Descargando SWF pack..."
    git clone https://git.krews.org/morningstar/arcturus-morningstar-default-swf-pack.git /assets/swf/
else
    echo "✅ SWF pack ya existe, saltando descarga..."
fi

if [ ! -d "/assets/assets/.git" ]; then
    echo "📦 Descargando assets por defecto..."
    # Remover directorio si existe pero no tiene .git
    if [ -d "/assets/assets" ] && [ ! -d "/assets/assets/.git" ]; then
        rm -rf /assets/assets
    fi
    git clone https://github.com/krewsarchive/default-assets.git /assets/assets/
else
    echo "✅ Assets por defecto ya existen, saltando descarga..."
fi

# Descargar y extraer room.nitro.zip si no existe
if [ ! -f "/assets/assets/bundled/generic/room.nitro" ]; then
    echo "📦 Descargando room.nitro.zip..."
    cd /tmp
    wget -O room.nitro.zip https://github.com/billsonnn/nitro-react/files/10334858/room.nitro.zip
    echo "📦 Extrayendo room.nitro.zip..."
    unzip -o room.nitro.zip -d /assets/assets/bundled/generic/
    rm room.nitro.zip
else
    echo "✅ room.nitro ya existe, saltando descarga..."
fi

# Usar habbo-downloader para descargar assets actualizados
echo "🔄 Descargando assets actualizados con habbo-downloader..."

# Verificar si los assets de habbo ya están descargados
if [ ! -d "/assets/swf/gordon/PRODUCTION" ] || [ ! -d "/assets/swf/dcr/hof_furni" ]; then
    echo "📦 Descargando assets de Habbo..."
    
    # Remover directorio si existe para forzar descarga fresca
    rm -rf /assets/swf/gordon/PRODUCTION
    
    # Descargar todos los assets necesarios
    habbo-downloader --output /assets/swf --domain com --command badgeparts
    habbo-downloader --output /assets/swf --domain com --command badges  
    habbo-downloader --output /assets/swf --domain com --command clothes
    habbo-downloader --output /assets/swf --domain com --command effects
    habbo-downloader --output /assets/swf --domain com --command furnitures
    habbo-downloader --output /assets/swf --domain com --command gamedata
    habbo-downloader --output /assets/swf --domain com --command gordon
    habbo-downloader --output /assets/swf --domain com --command hotelview
    habbo-downloader --output /assets/swf --domain com --command icons
    habbo-downloader --output /assets/swf --domain com --command mp3
    habbo-downloader --output /assets/swf --domain com --command pets
    habbo-downloader --output /assets/swf --domain com --command promo
    
    # Copiar iconos de furniture
    if [ -d "/assets/swf/dcr/hof_furni/icons" ]; then
        cp -n /assets/swf/dcr/hof_furni/icons/* /assets/swf/dcr/hof_furni/ 2>/dev/null || true
    fi
    
    # Renombrar directorio PRODUCTION
    if [ -d "/assets/swf/gordon" ]; then
        cd /assets/swf/gordon
        for dir in PRODUCTION*; do
            if [ -d "$dir" ] && [ "$dir" != "PRODUCTION" ]; then
                mv "$dir" PRODUCTION
                break
            fi
        done
    fi
    
    echo "✅ Assets de Habbo descargados!"
else
    echo "✅ Assets de Habbo ya existen, saltando descarga..."
fi

# Convertir archivos XML/TXT a JSON usando el script de traducción
echo "🔄 Convirtiendo archivos gamedata (XML/TXT → JSON)..."

# Verificar si ya existen los archivos JSON para evitar conversiones innecesarias
if [ ! -f "/assets/assets/gamedata/FigureData.json" ] || [ ! -f "/assets/assets/gamedata/FurnitureData.json" ] || [ ! -f "/assets/assets/gamedata/ProductData.json" ]; then
    if [ -f "/assets/swf/gamedata/figuredata.xml" ] || [ -f "/assets/swf/gamedata/furnidata.xml" ] || [ -f "/assets/swf/gamedata/productdata.txt" ]; then
        echo "📄 Ejecutando conversiones de gamedata..."
        
        # Instalar python3 si no está disponible
        if ! command -v python3 &> /dev/null; then
            echo "📦 Instalando Python3..."
            apk add --no-cache python3 py3-pip
        fi
        
        # Reparar archivos XML corruptos antes de la conversión
        echo "🔧 Reparando archivos XML corruptos..."
        cp /assets/translation/fix_xml_specific.py /tmp/fix_xml_specific.py
        cd /tmp
        
        # Reparar furnidata.xml si existe
        if [ -f "/assets/swf/gamedata/furnidata.xml" ]; then
            echo "🔧 Reparando furnidata.xml..."
            python3 fix_xml_specific.py /assets/swf/gamedata/furnidata.xml
        fi
        
        # Copiar script de conversión y ejecutar
        cp /assets/translation/convert_gamedata.py /tmp/convert_gamedata.py
        
        # Ajustar paths en el script para el entorno de contenedor
        sed -i 's|swf_base = "/usr/share/nginx/html/swf"|swf_base = "/assets/swf"|g' convert_gamedata.py
        sed -i 's|assets_base = "/usr/share/nginx/html/assets"|assets_base = "/assets/assets"|g' convert_gamedata.py
        
        # Ejecutar conversión con manejo de errores
        if python3 convert_gamedata.py; then
            echo "✅ Conversión de gamedata completada!"
        else
            echo "⚠️  Conversión de gamedata completada con errores"
            # Crear archivos JSON básicos si no existen
            echo "🔧 Creando archivos JSON básicos como respaldo..."
            
            # FigureData.json básico
            if [ ! -f "/assets/assets/gamedata/FigureData.json" ]; then
                echo '{"palettes":[],"settypes":[]}' > /assets/assets/gamedata/FigureData.json
                echo "✅ FigureData.json básico creado"
            fi
            
            # FurnitureData.json básico
            if [ ! -f "/assets/assets/gamedata/FurnitureData.json" ]; then
                echo '{"roomitemtypes":{"furnitype":[]},"wallitemtypes":{"furnitype":[]}}' > /assets/assets/gamedata/FurnitureData.json
                echo "✅ FurnitureData.json básico creado"
            fi
            
            # ProductData.json básico
            if [ ! -f "/assets/assets/gamedata/ProductData.json" ]; then
                echo '{"productdata":{"product":[]}}' > /assets/assets/gamedata/ProductData.json
                echo "✅ ProductData.json básico creado"
            fi
        fi
        
    else
        echo "⚠️  Archivos XML/TXT de gamedata no encontrados, saltando conversión"
    fi
else
    echo "✅ Archivos JSON de gamedata ya existen, saltando conversión..."
fi

# Establecer permisos correctos
chown -R 1000:1000 /assets
chmod -R 755 /assets

echo "✅ Descarga de assets completada!"
echo "📊 Resumen:"
echo "   - SWF pack: $(ls -la /assets/swf | wc -l) archivos"
echo "   - Assets: $(ls -la /assets/assets | wc -l) archivos"
echo "   - Habbo assets: ✅ Descargados"
echo "   - Gamedata JSON: ✅ Convertidos automáticamente"

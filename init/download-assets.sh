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

# Establecer permisos correctos
chown -R 1000:1000 /assets
chmod -R 755 /assets

echo "✅ Descarga de assets completada!"
echo "📊 Resumen:"
echo "   - SWF pack: $(ls -la /assets/swf | wc -l) archivos"
echo "   - Assets: $(ls -la /assets/assets | wc -l) archivos"
echo "   - Habbo assets: ✅ Descargados"

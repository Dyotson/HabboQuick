#!/bin/bash

# Script para verificar que el .gitignore funciona correctamente
# después de ejecutar el setup completo

echo "🔍 Verificando que .gitignore funciona correctamente después del setup..."
echo ""

# Verificar archivos que NO deberían aparecer en git status
echo "❌ Verificando archivos que NO deberían aparecer en git status:"

# Lista de patrones que deben estar ignorados
IGNORED_PATTERNS=(
    "assets/swf"
    "assets/assets"
    "assets/usercontent/.*\.png"
    "assets/usercontent/.*\.jpg" 
    "assets/usercontent/imageproxy"
    "assets/usercontent/cache"
    "assets/bundled"
    "assets/cache"
    "db/data"
    "db/dumps"
    "db/backup"
    "logs/"
    "\.log$"
    "atomcms/cache/.*"
    "atomcms/storage/.*"
    "atomcms/logs/.*"
    "backups/"
    "\.env$"
    "nitro/.*\.json$"
    "tmp/"
    "temp/"
    "\.tmp/"
    "export/"
    "\.tar$"
)

# Verificar si algún archivo ignorado aparece en git status
git_status_output=$(git status --porcelain)
found_issues=0

for pattern in "${IGNORED_PATTERNS[@]}"; do
    # Excluir .gitkeep de las verificaciones
    matching_files=$(echo "$git_status_output" | grep -E "$pattern" | grep -v "\.gitkeep")
    if [ ! -z "$matching_files" ]; then
        echo "❌ Encontrados archivos que deberían estar ignorados: $pattern"
        echo "$matching_files"
        found_issues=1
    fi
done

if [ $found_issues -eq 0 ]; then
    echo "✅ Ningún archivo ignorado aparece en git status"
else
    echo ""
    echo "💡 Para limpiar archivos generados, ejecuta: make clean-generated"
fi

echo ""
echo "📊 Resumen del estado actual de git:"
git status --porcelain | wc -l | xargs printf "Total de archivos modificados: %s\n"

echo ""
echo "📁 Archivos modificados más relevantes:"
git status --porcelain | grep -v "\.gitkeep\|\.gitignore\|Makefile\|README\.md\|Dockerfile" | head -10

echo ""
echo "✅ Verificación completada"

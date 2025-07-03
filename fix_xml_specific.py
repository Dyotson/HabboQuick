#!/usr/bin/env python3
"""
Script para corregir errores específicos en furnidata.xml
"""

import sys
import re


def fix_specific_xml_errors(file_path):
    """
    Corrige errores específicos conocidos en el XML
    """
    print(f"🔧 Corrigiendo errores específicos en {file_path}...")

    # Leer el archivo
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Crear backup
    with open(file_path + ".backup2", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"💾 Backup creado: {file_path}.backup2")

    # Contadores de correcciones
    corrections = 0

    # 1. Corregir el error específico en customparams
    # Patrón: <customparams>...="value</customparams>
    # Corrección: <customparams>...="value"</customparams>

    # Buscar patrones problemáticos
    pattern1 = r'<customparams>([^<]*="[^"]*)</customparams>'
    matches = re.findall(pattern1, content)

    if matches:
        print(f"🔍 Encontrados {len(matches)} patrones problemáticos en customparams")
        for match in matches:
            print(f"   - {match}")

        # Corregir cada match
        def fix_customparams(match):
            inner_content = match.group(1)
            # Si termina con una comilla sin cerrar, agregar la comilla de cierre
            if inner_content.count('"') % 2 == 1:  # número impar de comillas
                fixed_content = inner_content + '"'
                return f"<customparams>{fixed_content}</customparams>"
            return match.group(0)

        content = re.sub(pattern1, fix_customparams, content)
        corrections += len(matches)

    # 2. Corregir comillas mal cerradas en general
    # Buscar patrones como ="value sin comilla de cierre
    pattern2 = r'="([^"]*)</([^>]+)>'
    matches2 = re.findall(pattern2, content)

    if matches2:
        print(f"🔍 Encontrados {len(matches2)} patrones de comillas mal cerradas")
        for match in matches2:
            print(f"   - Value: {match[0]}, Tag: {match[1]}")

        # Corregir comillas mal cerradas
        def fix_quotes(match):
            value = match.group(1)
            tag = match.group(2)
            return f'="{value}"></{tag}>'

        content = re.sub(pattern2, fix_quotes, content)
        corrections += len(matches2)

    # 3. Corregir caracteres especiales problemáticos
    # Buscar caracteres que no sean XML válidos
    invalid_chars = re.findall(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", content)
    if invalid_chars:
        print(f"🔍 Encontrados {len(invalid_chars)} caracteres inválidos")
        content = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", content)
        corrections += len(invalid_chars)

    # 4. Corregir entidades XML malformadas
    # Escapar & que no son parte de entidades válidas
    def fix_ampersands(match):
        char = match.group(0)
        # Solo reemplazar si no es parte de una entidad válida
        return "&amp;"

    # Primero proteger las entidades válidas
    content = content.replace("&amp;", "___TEMP_AMP___")
    content = content.replace("&lt;", "___TEMP_LT___")
    content = content.replace("&gt;", "___TEMP_GT___")
    content = content.replace("&quot;", "___TEMP_QUOT___")
    content = content.replace("&apos;", "___TEMP_APOS___")

    # Escapar & restantes
    amp_count = content.count("&")
    content = content.replace("&", "&amp;")
    if amp_count > 0:
        corrections += amp_count
        print(f"🔍 Escapados {amp_count} caracteres &")

    # Restaurar entidades protegidas
    content = content.replace("___TEMP_AMP___", "&amp;")
    content = content.replace("___TEMP_LT___", "&lt;")
    content = content.replace("___TEMP_GT___", "&gt;")
    content = content.replace("___TEMP_QUOT___", "&quot;")
    content = content.replace("___TEMP_APOS___", "&apos;")

    # 5. Corregir tags de cierre con comillas y > extra
    # Patrón: </tag"> donde debería ser </tag>
    pattern3 = r'</([^>]+)"\s*>\s*"?\s*>'
    matches3 = re.findall(pattern3, content)

    if matches3:
        print(f"🔍 Encontrados {len(matches3)} tags de cierre con comillas extra")
        for match in matches3:
            print(f"   - Tag: {match}")

        # Corregir tags de cierre malformados
        def fix_closing_tags(match):
            tag = match.group(1)
            return f"</{tag}>"

        content = re.sub(pattern3, fix_closing_tags, content)
        corrections += len(matches3)

    # 6. Corregir patrón específico: </customparams">
    pattern4 = r'</customparams"\s*>\s*"?\s*>'
    matches4 = re.findall(pattern4, content)

    if matches4:
        print(
            f"🔍 Encontrados {len(matches4)} patrones específicos de customparams malformados"
        )
        content = re.sub(pattern4, "</customparams>", content)
        corrections += len(matches4)

    # 7. Corregir cualquier tag de cierre que tenga comillas extra
    pattern5 = r'</([^>]+)"\s*>'
    matches5 = re.findall(pattern5, content)

    if matches5:
        print(f"🔍 Encontrados {len(matches5)} tags de cierre con comillas")
        for match in matches5:
            print(f"   - Tag: {match}")

        def fix_closing_tags_simple(match):
            tag = match.group(1)
            return f"</{tag}>"

        content = re.sub(pattern5, fix_closing_tags_simple, content)
        corrections += len(matches5)

    # Escribir archivo corregido
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"✅ Correcciones aplicadas: {corrections}")
    print(f"✅ Archivo corregido: {file_path}")

    return corrections > 0


def main():
    if len(sys.argv) != 2:
        print("Uso: python3 fix_xml_specific.py <archivo.xml>")
        sys.exit(1)

    file_path = sys.argv[1]

    if fix_specific_xml_errors(file_path):
        print("🎉 Correcciones aplicadas exitosamente!")
    else:
        print("ℹ️  No se encontraron errores para corregir")


if __name__ == "__main__":
    main()

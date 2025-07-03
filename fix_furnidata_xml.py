#!/usr/bin/env python3
"""
Script para reparar el archivo furnidata.xml corrupto
Identifica y corrige problemas específicos en el XML
"""

import re
import sys
import os
from xml.etree import ElementTree as ET


def analyze_xml_error(xml_file_path):
    """
    Analiza el archivo XML línea por línea para encontrar errores específicos
    """
    print(f"🔍 Analizando errores en {xml_file_path}...")

    try:
        with open(xml_file_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        print(f"📊 Total de líneas: {len(lines)}")

        # Verificar línea 42403 específicamente
        if len(lines) >= 42403:
            problem_line = lines[42402]  # índice 0-based
            print(f"📍 Línea 42403 (problemática): {repr(problem_line[:100])}...")

            # Buscar caracteres problemáticos
            for i, char in enumerate(problem_line):
                if ord(char) < 32 and char not in ["\t", "\n", "\r"]:
                    print(
                        f"❌ Caracter problemático en posición {i+1}: {repr(char)} (código {ord(char)})"
                    )

                    # Mostrar contexto
                    start = max(0, i - 10)
                    end = min(len(problem_line), i + 10)
                    context = problem_line[start:end]
                    print(f"🔍 Contexto: {repr(context)}")

                    return i + 1, char

        return None, None

    except Exception as e:
        print(f"❌ Error analizando: {e}")
        return None, None


def fix_xml_content(content):
    """
    Aplica múltiples estrategias para limpiar el contenido XML
    """
    print("🔧 Aplicando correcciones XML...")

    # Contador de correcciones
    corrections = 0

    # 1. Remover caracteres de control inválidos
    original_len = len(content)
    content = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", content)
    if len(content) != original_len:
        corrections += 1
        print(f"✅ Removidos {original_len - len(content)} caracteres de control")

    # 2. Corregir entidades XML malformadas
    entity_fixes = [
        (r"&(?!amp;|lt;|gt;|quot;|apos;)", "&amp;"),  # & no seguido de entidad válida
        (r"&amp;amp;", "&amp;"),  # doble escape
        (r"&amp;lt;", "&lt;"),  # escape incorrecto
        (r"&amp;gt;", "&gt;"),  # escape incorrecto
        (r"&amp;quot;", "&quot;"),  # escape incorrecto
        (r"&amp;apos;", "&apos;"),  # escape incorrecto
    ]

    for pattern, replacement in entity_fixes:
        old_content = content
        content = re.sub(pattern, replacement, content)
        if content != old_content:
            corrections += 1
            print(f"✅ Corregidas entidades XML: {pattern}")

    # 3. Corregir atributos malformados
    # Buscar atributos sin comillas
    attr_pattern = r'(\w+)=([^"\s>]+)(?=\s|>)'
    matches = re.findall(attr_pattern, content)
    if matches:
        for attr, value in matches:
            # Solo corregir si el valor no está ya entre comillas
            if not (value.startswith('"') and value.endswith('"')):
                old_attr = f"{attr}={value}"
                new_attr = f'{attr}="{value}"'
                content = content.replace(old_attr, new_attr)
                corrections += 1
        print(f"✅ Corregidos {len(matches)} atributos sin comillas")

    # 4. Corregir tags malformados
    # Buscar tags que no cierran correctamente
    tag_fixes = [
        (r"<([^/>]+)(?<!/)>", r"<\1>"),  # asegurar que tags normales estén bien
        (r"<([^/>]+)/\s*>", r"<\1/>"),  # corregir self-closing tags
    ]

    for pattern, replacement in tag_fixes:
        old_content = content
        content = re.sub(pattern, replacement, content)
        if content != old_content:
            corrections += 1
            print(f"✅ Corregidos tags malformados")

    # 5. Verificar estructura básica
    if not content.strip().startswith("<?xml"):
        print("⚠️  Agregando declaración XML")
        content = '<?xml version="1.0" encoding="UTF-8"?>\n' + content
        corrections += 1

    print(f"📊 Total de correcciones aplicadas: {corrections}")
    return content


def repair_furnidata_xml(xml_file_path):
    """
    Repara el archivo furnidata.xml corrupto
    """
    print(f"🔧 Reparando {xml_file_path}...")

    # Crear backup
    backup_path = xml_file_path + ".backup"
    try:
        with open(xml_file_path, "r", encoding="utf-8", errors="ignore") as f:
            original_content = f.read()

        with open(backup_path, "w", encoding="utf-8") as f:
            f.write(original_content)
        print(f"💾 Backup creado: {backup_path}")

    except Exception as e:
        print(f"❌ Error creando backup: {e}")
        return False

    # Analizar el error específico
    error_pos, error_char = analyze_xml_error(xml_file_path)

    # Aplicar correcciones
    try:
        fixed_content = fix_xml_content(original_content)

        # Probar que el XML sea válido
        print("🧪 Validando XML corregido...")
        try:
            ET.fromstring(fixed_content)
            print("✅ XML válido después de correcciones")
        except ET.ParseError as e:
            print(f"❌ XML aún tiene errores: {e}")
            # Intentar una corrección más agresiva
            print("🔧 Aplicando corrección más agresiva...")

            # Dividir en líneas y procesar línea por línea
            lines = fixed_content.split("\n")
            fixed_lines = []

            for i, line in enumerate(lines, 1):
                try:
                    # Verificar si la línea tiene caracteres problemáticos
                    cleaned_line = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", line)

                    # Si es la línea problemática, aplicar corrección adicional
                    if i == 42403:
                        print(f"🔧 Corrección especial para línea {i}")
                        # Buscar y corregir problemas específicos
                        if error_pos and error_pos <= len(cleaned_line):
                            # Remover caracter problemático
                            cleaned_line = (
                                cleaned_line[: error_pos - 1] + cleaned_line[error_pos:]
                            )
                            print(
                                f"✅ Caracter problemático removido en posición {error_pos}"
                            )

                    fixed_lines.append(cleaned_line)

                except Exception as e:
                    print(f"⚠️  Error procesando línea {i}: {e}")
                    fixed_lines.append("")  # Línea vacía si hay error

            fixed_content = "\n".join(fixed_lines)

            # Validar nuevamente
            try:
                ET.fromstring(fixed_content)
                print("✅ XML válido después de corrección agresiva")
            except ET.ParseError as e:
                print(f"❌ XML aún tiene errores después de corrección agresiva: {e}")
                return False

        # Escribir archivo corregido
        with open(xml_file_path, "w", encoding="utf-8") as f:
            f.write(fixed_content)

        print(f"✅ Archivo reparado exitosamente: {xml_file_path}")
        return True

    except Exception as e:
        print(f"❌ Error durante la reparación: {e}")
        # Restaurar backup
        try:
            with open(backup_path, "r", encoding="utf-8") as f:
                original_content = f.read()
            with open(xml_file_path, "w", encoding="utf-8") as f:
                f.write(original_content)
            print("🔄 Backup restaurado")
        except:
            pass
        return False


def main():
    if len(sys.argv) != 2:
        print("Uso: python3 fix_furnidata_xml.py <ruta_al_furnidata.xml>")
        sys.exit(1)

    xml_file_path = sys.argv[1]

    if not os.path.exists(xml_file_path):
        print(f"❌ Archivo no encontrado: {xml_file_path}")
        sys.exit(1)

    print("🔧 Iniciando reparación de furnidata.xml...")

    if repair_furnidata_xml(xml_file_path):
        print("🎉 ¡Reparación completada exitosamente!")
        sys.exit(0)
    else:
        print("❌ Reparación falló")
        sys.exit(1)


if __name__ == "__main__":
    main()

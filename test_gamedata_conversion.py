#!/usr/bin/env python3
"""
Script para probar la conversión de gamedata localmente
"""

import os
import sys
import json
import xml.etree.ElementTree as ET
import re


def test_xml_parsing(xml_file_path):
    """
    Prueba el parsing de un archivo XML
    """
    if not os.path.exists(xml_file_path):
        print(f"❌ Archivo no encontrado: {xml_file_path}")
        return False

    try:
        print(f"🔍 Analizando {xml_file_path}...")

        # Leer el archivo
        with open(xml_file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        print(f"📊 Tamaño del archivo: {len(content)} caracteres")

        # Buscar caracteres problemáticos
        control_chars = re.findall(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", content)
        if control_chars:
            print(f"⚠️  Caracteres de control encontrados: {len(control_chars)}")

        # Intentar parsing directo
        try:
            tree = ET.parse(xml_file_path)
            print("✅ Parsing XML exitoso")

            root = tree.getroot()
            print(f"📄 Elemento raíz: {root.tag}")

            # Contar elementos
            total_elements = len(list(root.iter()))
            print(f"📊 Total de elementos: {total_elements}")

            return True

        except ET.ParseError as e:
            print(f"❌ Error de parsing XML: {e}")
            print(f"📍 Línea: {e.lineno}, Posición: {e.offset}")

            # Mostrar contexto del error
            lines = content.split("\n")
            if e.lineno and e.lineno <= len(lines):
                error_line = lines[e.lineno - 1]
                print(f"📝 Línea problemática: {error_line[:100]}...")

            return False

    except Exception as e:
        print(f"❌ Error general: {e}")
        return False


def test_txt_parsing(txt_file_path):
    """
    Prueba el parsing de un archivo TXT
    """
    if not os.path.exists(txt_file_path):
        print(f"❌ Archivo no encontrado: {txt_file_path}")
        return False

    try:
        print(f"🔍 Analizando {txt_file_path}...")

        # Leer el archivo
        with open(txt_file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        print(f"📊 Tamaño del archivo: {len(content)} caracteres")

        # Buscar caracteres problemáticos
        control_chars = re.findall(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", content)
        if control_chars:
            print(f"⚠️  Caracteres de control encontrados: {len(control_chars)}")

        # Analizar líneas
        lines = content.strip().split("\n")
        print(f"📊 Líneas encontradas: {len(lines)}")

        # Probar parsing de las primeras líneas
        valid_lines = 0
        error_lines = 0

        for i, line in enumerate(lines[:10]):  # Solo las primeras 10 líneas
            if line.strip():
                try:
                    data = json.loads(line)
                    valid_lines += 1
                    if i == 0:
                        print(f"📝 Ejemplo de línea válida: {len(data)} elementos")
                except json.JSONDecodeError:
                    error_lines += 1
                    if error_lines <= 3:  # Solo mostrar primeros 3 errores
                        print(f"⚠️  Error en línea {i+1}: {line[:50]}...")

        print(f"✅ Líneas válidas (muestra): {valid_lines}")
        print(f"❌ Líneas con errores (muestra): {error_lines}")

        return True

    except Exception as e:
        print(f"❌ Error general: {e}")
        return False


def main():
    """
    Función principal para probar la conversión
    """
    print("🧪 Iniciando prueba de conversión de gamedata...")

    # Rutas a verificar
    base_path = "assets/swf/gamedata"

    files_to_test = [
        ("figuredata.xml", test_xml_parsing),
        ("furnidata.xml", test_xml_parsing),
        ("productdata.txt", test_txt_parsing),
    ]

    success_count = 0

    for filename, test_func in files_to_test:
        filepath = os.path.join(base_path, filename)
        print(f"\n{'='*60}")
        print(f"🔧 Probando: {filename}")
        print(f"{'='*60}")

        if test_func(filepath):
            success_count += 1

    print(f"\n{'='*60}")
    print(f"📊 Resumen de pruebas:")
    print(f"   ✅ Exitosas: {success_count}/{len(files_to_test)}")
    print(f"   ❌ Fallidas: {len(files_to_test) - success_count}/{len(files_to_test)}")
    print(f"{'='*60}")

    return success_count == len(files_to_test)


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

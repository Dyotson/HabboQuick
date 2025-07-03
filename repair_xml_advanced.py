#!/usr/bin/env python3
"""
Script avanzado para reparar archivos XML corruptos
Identifica y corrige múltiples problemas XML
"""

import re
import sys
import os
from xml.etree import ElementTree as ET
from xml.parsers import expat


def find_all_xml_errors(xml_file_path):
    """
    Encuentra todos los errores XML en el archivo
    """
    print(f"🔍 Buscando todos los errores XML en {xml_file_path}...")
    errors = []

    try:
        with open(xml_file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        # Usar el parser expat para encontrar errores específicos
        parser = expat.ParserCreate()

        try:
            parser.Parse(content, True)
            print("✅ No se encontraron errores XML")
            return []
        except expat.ExpatError as e:
            line_num = e.lineno
            col_num = e.offset
            error_msg = str(e)

            print(f"❌ Error encontrado - Línea: {line_num}, Columna: {col_num}")
            print(f"📄 Mensaje: {error_msg}")

            # Obtener línea específica
            lines = content.split("\n")
            if line_num <= len(lines):
                problem_line = lines[line_num - 1]
                print(f"📍 Línea problemática: {repr(problem_line[:100])}...")

                # Mostrar contexto alrededor del error
                if col_num <= len(problem_line):
                    start = max(0, col_num - 20)
                    end = min(len(problem_line), col_num + 20)
                    context = problem_line[start:end]
                    print(f"🔍 Contexto (posición {col_num}): {repr(context)}")

                errors.append(
                    {
                        "line": line_num,
                        "column": col_num,
                        "message": error_msg,
                        "content": problem_line,
                    }
                )

            return errors

    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return []


def aggressive_xml_clean(content):
    """
    Limpieza agresiva de contenido XML
    """
    print("🔧 Aplicando limpieza agresiva...")

    original_len = len(content)

    # 1. Remover todos los caracteres de control problemáticos
    content = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", content)
    print(f"✅ Removidos {original_len - len(content)} caracteres de control")

    # 2. Corregir entidades XML
    entity_replacements = [
        # Primero, proteger las entidades válidas
        ("&amp;", "___AMP___"),
        ("&lt;", "___LT___"),
        ("&gt;", "___GT___"),
        ("&quot;", "___QUOT___"),
        ("&apos;", "___APOS___"),
        # Luego, escapar todos los & restantes
        ("&", "&amp;"),
        # Finalmente, restaurar las entidades protegidas
        ("___AMP___", "&amp;"),
        ("___LT___", "&lt;"),
        ("___GT___", "&gt;"),
        ("___QUOT___", "&quot;"),
        ("___APOS___", "&apos;"),
    ]

    for old, new in entity_replacements:
        content = content.replace(old, new)

    # 3. Corregir atributos malformados
    # Buscar patrones como attribute=value (sin comillas)
    def quote_attributes(match):
        attr_name = match.group(1)
        attr_value = match.group(2)
        # No tocar si ya tiene comillas
        if attr_value.startswith('"') and attr_value.endswith('"'):
            return match.group(0)
        # Agregar comillas
        return f'{attr_name}="{attr_value}"'

    content = re.sub(r'(\w+)=([^"\s>]+)(?=\s|>)', quote_attributes, content)

    # 4. Corregir caracteres especiales en texto
    # Escapar < y > que no son parte de tags
    lines = content.split("\n")
    fixed_lines = []

    for line in lines:
        # Si la línea no parece ser un tag XML completo, escapar caracteres especiales
        if "<" in line and ">" in line:
            # Verificar si es un tag válido
            if not re.match(r"^\s*<[^>]+>\s*$", line.strip()) and not re.match(
                r"^\s*<[^>]+/>\s*$", line.strip()
            ):
                # Podría tener contenido mixto, ser más cuidadoso
                # Solo escapar < y > que no son parte de tags
                in_tag = False
                result = []
                i = 0
                while i < len(line):
                    char = line[i]
                    if char == "<":
                        # Verificar si es inicio de tag válido
                        tag_end = line.find(">", i)
                        if tag_end != -1:
                            # Es un tag válido
                            result.append(line[i : tag_end + 1])
                            i = tag_end + 1
                        else:
                            # < sin cierre, escapar
                            result.append("&lt;")
                            i += 1
                    elif char == ">" and not in_tag:
                        # > sin apertura, escapar
                        result.append("&gt;")
                        i += 1
                    else:
                        result.append(char)
                        i += 1
                line = "".join(result)

        fixed_lines.append(line)

    content = "\n".join(fixed_lines)

    # 5. Verificar estructura básica
    if not content.strip().startswith("<?xml"):
        content = '<?xml version="1.0" encoding="UTF-8"?>\n' + content
        print("✅ Agregada declaración XML")

    return content


def repair_xml_iteratively(xml_file_path, max_iterations=10):
    """
    Repara XML iterativamente hasta que no haya errores
    """
    print(f"🔧 Reparando {xml_file_path} iterativamente...")

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

    content = original_content

    for iteration in range(max_iterations):
        print(f"\n🔄 Iteración {iteration + 1}/{max_iterations}")

        # Aplicar limpieza agresiva
        content = aggressive_xml_clean(content)

        # Probar parseo
        try:
            ET.fromstring(content)
            print("✅ XML válido!")
            break
        except ET.ParseError as e:
            print(f"❌ Error XML: {e}")

            # Extraer información del error
            error_line = getattr(e, "lineno", None)
            error_col = getattr(e, "offset", None)

            if error_line and error_col:
                print(f"📍 Error en línea {error_line}, columna {error_col}")

                # Intentar corrección específica
                lines = content.split("\n")
                if error_line <= len(lines):
                    problem_line = lines[error_line - 1]
                    print(f"📄 Línea problemática: {repr(problem_line[:100])}")

                    # Correcciones específicas basadas en el error
                    if "not well-formed" in str(e):
                        # Remover caracter problemático
                        if error_col <= len(problem_line):
                            char_before = problem_line[: error_col - 1]
                            char_after = problem_line[error_col:]
                            fixed_line = char_before + char_after
                            lines = (
                                lines[: error_line - 1]
                                + [fixed_line]
                                + lines[error_line:]
                            )
                            print(
                                f"✅ Caracter problemático removido en posición {error_col}"
                            )

                    elif "mismatched tag" in str(e):
                        # Intentar corregir tag malformado
                        fixed_line = re.sub(r"<([^/>]+)(?<!/)>", r"<\1/>", problem_line)
                        if fixed_line != problem_line:
                            lines = (
                                lines[: error_line - 1]
                                + [fixed_line]
                                + lines[error_line:]
                            )
                            print("✅ Tag malformado corregido")

                    content = "\n".join(lines)

            # Si es la última iteración, intentar estrategia más drástica
            if iteration == max_iterations - 1:
                print("🔧 Aplicando estrategia drástica: remover líneas problemáticas")
                lines = content.split("\n")
                cleaned_lines = []

                for i, line in enumerate(lines, 1):
                    # Verificar si la línea tiene problemas obvios
                    if any(ord(c) < 32 and c not in ["\t", "\n", "\r"] for c in line):
                        print(f"⚠️  Saltando línea {i} (caracteres inválidos)")
                        continue

                    # Verificar si es una línea XML válida básica
                    if line.strip() and not line.strip().startswith("<?xml"):
                        try:
                            # Intentar crear un fragmento XML válido
                            test_xml = f"<root>{line}</root>"
                            ET.fromstring(test_xml)
                        except:
                            # Si falla, limpiar la línea más agresivamente
                            line = re.sub(r"[^\x09\x0A\x0D\x20-\x7E]", "", line)

                    cleaned_lines.append(line)

                content = "\n".join(cleaned_lines)

    # Escribir archivo reparado
    try:
        with open(xml_file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"✅ Archivo reparado: {xml_file_path}")
        return True
    except Exception as e:
        print(f"❌ Error escribiendo archivo: {e}")
        return False


def main():
    if len(sys.argv) != 2:
        print("Uso: python3 repair_xml_advanced.py <ruta_al_archivo.xml>")
        sys.exit(1)

    xml_file_path = sys.argv[1]

    if not os.path.exists(xml_file_path):
        print(f"❌ Archivo no encontrado: {xml_file_path}")
        sys.exit(1)

    print("🔧 Iniciando reparación avanzada de XML...")

    # Encontrar errores primero
    errors = find_all_xml_errors(xml_file_path)

    if not errors:
        print("✅ No se encontraron errores XML")
        sys.exit(0)

    # Reparar iterativamente
    if repair_xml_iteratively(xml_file_path):
        print("🎉 ¡Reparación completada exitosamente!")
        sys.exit(0)
    else:
        print("❌ Reparación falló")
        sys.exit(1)


if __name__ == "__main__":
    main()

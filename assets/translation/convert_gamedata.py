#!/usr/bin/env python3
"""
Script principal para convertir todos los archivos XML/TXT a JSON
Diseñado para ejecutarse dentro del contenedor assets
Incluye reparación automática de XML corrupto
"""

import json
import os
import sys
import subprocess
import xml.etree.ElementTree as ET
import re


def figuredata_xml_to_json(xml_file_path, json_file_path):
    """
    Convierte figuredata.xml a FigureData.json
    """
    try:
        # Parse the XML file
        tree = ET.parse(xml_file_path)
        root = tree.getroot()

        # Initialize the result dictionary
        result = {"palettes": [], "settypes": []}

        # Process colors/palettes
        colors_element = root.find("colors")
        if colors_element is not None:
            for palette in colors_element.findall("palette"):
                palette_data = {"id": int(palette.get("id", 0)), "colors": []}

                for color in palette.findall("color"):
                    color_data = {
                        "id": int(color.get("id", 0)),
                        "index": int(color.get("index", 0)),
                        "club": int(color.get("club", 0)),
                        "selectable": color.get("selectable") == "1",
                        "preselectable": color.get("preselectable") == "1",
                        "hexCode": color.text,
                    }
                    palette_data["colors"].append(color_data)

                result["palettes"].append(palette_data)

        # Process sets/settypes
        sets_element = root.find("sets")
        if sets_element is not None:
            for settype in sets_element.findall("settype"):
                settype_data = {
                    "type": settype.get("type"),
                    "paletteid": int(settype.get("paletteid", 0)),
                    "mand_m_0": int(settype.get("mand_m_0", 0)),
                    "mand_f_0": int(settype.get("mand_f_0", 0)),
                    "mand_m_1": int(settype.get("mand_m_1", 0)),
                    "mand_f_1": int(settype.get("mand_f_1", 0)),
                    "sets": [],
                }

                for set_elem in settype.findall("set"):
                    set_data = {
                        "id": int(set_elem.get("id", 0)),
                        "gender": set_elem.get("gender", "U"),
                        "club": int(set_elem.get("club", 0)),
                        "colorable": set_elem.get("colorable") == "1",
                        "selectable": set_elem.get("selectable") == "1",
                        "preselectable": set_elem.get("preselectable") == "1",
                        "parts": [],
                    }

                    for part in set_elem.findall("part"):
                        part_data = {
                            "id": int(part.get("id", 0)),
                            "type": part.get("type"),
                            "colorable": part.get("colorable") == "1",
                            "index": int(part.get("index", 0)),
                            "colorindex": int(part.get("colorindex", 1)),
                        }
                        set_data["parts"].append(part_data)

                    settype_data["sets"].append(set_data)

                result["settypes"].append(settype_data)

        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))

        print(f"✅ FigureData.json generado exitosamente!")
        return True

    except Exception as e:
        print(f"❌ Error al convertir figuredata.xml: {e}")
        return False


def repair_xml_file(xml_file_path):
    """
    Repara archivos XML corruptos antes de procesarlos
    """
    try:
        # Check if repair script exists
        current_dir = os.getcwd()
        repair_script = os.path.join(current_dir, "fix_xml_specific.py")

        # If repair script doesn't exist, look for it in the assets directory
        if not os.path.exists(repair_script):
            repair_script = "/assets/translation/fix_xml_specific.py"

        if os.path.exists(repair_script):
            print("🛠️  Ejecutando reparación automática de XML...")
            result = subprocess.run(
                ["python3", repair_script, xml_file_path],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                print("✅ XML reparado exitosamente")
                return True
            else:
                print(f"⚠️  Advertencia en reparación: {result.stderr}")
                return False
        else:
            print(
                "⚠️  Script de reparación no encontrado, continuando sin reparación..."
            )
            return False
    except Exception as e:
        print(f"❌ Error durante la reparación: {e}")
        return False


def furnidata_xml_to_json(xml_file_path, json_file_path):
    """
    Convierte furnidata.xml a FurnitureData.json
    """
    try:
        print("🔧 Reparando y procesando archivo XML...")

        # Try to repair the XML file first
        repair_xml_file(xml_file_path)

        # Parse the XML
        print("🔍 Parseando archivo XML...")
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
        print("✅ XML parsing exitoso")

        # Initialize the result dictionary
        result = {
            "roomitemtypes": {"furnitype": []},
            "wallitemtypes": {"furnitype": []},
        }

        # Process roomitemtypes
        roomitemtypes = root.find("roomitemtypes")
        if roomitemtypes is not None:
            for furnitype in roomitemtypes.findall("furnitype"):
                furni_data = {
                    "id": int(furnitype.get("id", 0)),
                    "classname": furnitype.get("classname", ""),
                    "revision": int(furnitype.findtext("revision", 0)),
                    "category": furnitype.findtext("category", ""),
                    "defaultdir": int(furnitype.findtext("defaultdir", 0)),
                    "xdim": int(furnitype.findtext("xdim", 1)),
                    "ydim": int(furnitype.findtext("ydim", 1)),
                    "name": furnitype.findtext("name", ""),
                    "description": furnitype.findtext("description", ""),
                    "adurl": furnitype.findtext("adurl", ""),
                    "offerid": int(furnitype.findtext("offerid", -1)),
                    "buyout": int(furnitype.findtext("buyout", 0)),
                    "rentofferid": int(furnitype.findtext("rentofferid", -1)),
                    "rentbuyout": int(furnitype.findtext("rentbuyout", 0)),
                    "bc": int(furnitype.findtext("bc", 0)),
                    "excludeddynamic": int(furnitype.findtext("excludeddynamic", 0)),
                    "customparams": furnitype.findtext("customparams", ""),
                    "specialtype": int(furnitype.findtext("specialtype", 1)),
                    "canstandon": int(furnitype.findtext("canstandon", 0)),
                    "cansiton": int(furnitype.findtext("cansiton", 0)),
                    "canlayon": int(furnitype.findtext("canlayon", 0)),
                    "furniline": furnitype.findtext("furniline", ""),
                    "environment": furnitype.findtext("environment", ""),
                    "rare": int(furnitype.findtext("rare", 0)),
                }
                result["roomitemtypes"]["furnitype"].append(furni_data)

        # Process wallitemtypes
        wallitemtypes = root.find("wallitemtypes")
        if wallitemtypes is not None:
            for furnitype in wallitemtypes.findall("furnitype"):
                furni_data = {
                    "id": int(furnitype.get("id", 0)),
                    "classname": furnitype.get("classname", ""),
                    "revision": int(furnitype.findtext("revision", 0)),
                    "category": furnitype.findtext("category", ""),
                    "name": furnitype.findtext("name", ""),
                    "description": furnitype.findtext("description", ""),
                    "adurl": furnitype.findtext("adurl", ""),
                    "offerid": int(furnitype.findtext("offerid", -1)),
                    "buyout": int(furnitype.findtext("buyout", 0)),
                    "rentofferid": int(furnitype.findtext("rentofferid", -1)),
                    "rentbuyout": int(furnitype.findtext("rentbuyout", 0)),
                    "bc": int(furnitype.findtext("bc", 0)),
                    "excludeddynamic": int(furnitype.findtext("excludeddynamic", 0)),
                    "customparams": furnitype.findtext("customparams", ""),
                    "specialtype": int(furnitype.findtext("specialtype", 1)),
                    "furniline": furnitype.findtext("furniline", ""),
                    "environment": furnitype.findtext("environment", ""),
                    "rare": int(furnitype.findtext("rare", 0)),
                }
                result["wallitemtypes"]["furnitype"].append(furni_data)

        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))

        print(f"✅ FurnitureData.json generado exitosamente!")
        return True

    except Exception as e:
        print(f"❌ Error al convertir furnidata.xml: {e}")
        return False


def productdata_txt_to_json(txt_file_path, json_file_path):
    """
    Convierte productdata.txt a ProductData.json
    """
    try:
        # Initialize the result dictionary
        result = {"productdata": {"product": []}}

        # Read the text file with better error handling
        with open(txt_file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        # Clean content from control characters
        import re

        content = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", content)

        # Parse each line as a JSON array
        lines = content.strip().split("\n")
        processed_count = 0
        error_count = 0

        for line_num, line in enumerate(lines, 1):
            if line.strip():
                try:
                    # Clean the line further
                    line = line.strip()

                    # Parse the line as JSON array
                    products_array = json.loads(line)

                    # Process each product in the array
                    for product_info in products_array:
                        if len(product_info) >= 3:
                            # Clean the product data
                            product_data = {
                                "code": str(product_info[0]).strip(),
                                "name": str(product_info[1]).strip(),
                                "description": str(product_info[2]).strip(),
                            }
                            result["productdata"]["product"].append(product_data)
                            processed_count += 1

                except json.JSONDecodeError as e:
                    error_count += 1
                    if error_count <= 5:  # Only show first 5 errors
                        print(f"⚠️  Error línea {line_num}: {str(e)}")
                except Exception as e:
                    error_count += 1
                    if error_count <= 5:
                        print(f"⚠️  Error procesando línea {line_num}: {str(e)}")

        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))

        print(f"✅ ProductData.json generado exitosamente!")
        print(f"📊 Productos procesados: {processed_count}")
        if error_count > 0:
            print(f"⚠️  Errores encontrados: {error_count} (productos omitidos)")

        return True

    except Exception as e:
        print(f"❌ Error al convertir productdata.txt: {e}")
        return False


def main():
    print("🔄 Iniciando conversión de archivos XML/TXT a JSON...")

    # Base paths
    swf_base = "/usr/share/nginx/html/swf"
    assets_base = "/usr/share/nginx/html/assets"

    # Ensure output directory exists
    gamedata_dir = f"{assets_base}/gamedata"
    os.makedirs(gamedata_dir, exist_ok=True)

    success_count = 0
    total_conversions = 3

    # Convert figuredata.xml to FigureData.json
    print("\n📄 Convirtiendo figuredata.xml...")
    if figuredata_xml_to_json(
        f"{swf_base}/gamedata/figuredata.xml", f"{gamedata_dir}/FigureData.json"
    ):
        success_count += 1

    # Convert furnidata.xml to FurnitureData.json
    print("\n📄 Convirtiendo furnidata.xml...")
    if furnidata_xml_to_json(
        f"{swf_base}/gamedata/furnidata.xml", f"{gamedata_dir}/FurnitureData.json"
    ):
        success_count += 1

    # Convert productdata.txt to ProductData.json
    print("\n📄 Convirtiendo productdata.txt...")
    if productdata_txt_to_json(
        f"{swf_base}/gamedata/productdata.txt", f"{gamedata_dir}/ProductData.json"
    ):
        success_count += 1

    # Summary
    print(f"\n📊 Resumen de conversiones:")
    print(f"   ✅ Exitosas: {success_count}/{total_conversions}")
    print(f"   ❌ Fallidas: {total_conversions - success_count}/{total_conversions}")

    if success_count == total_conversions:
        print("🎉 ¡Todas las conversiones completadas exitosamente!")
        return 0
    else:
        print("⚠️  Algunas conversiones fallaron")
        return 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Script para convertir figuredata.xml a FigureData.json
"""

import xml.etree.ElementTree as ET
import json
import os
import sys


def xml_to_json(xml_file_path, json_file_path):
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

        print(f"✅ Archivo {json_file_path} generado exitosamente!")
        return True

    except Exception as e:
        print(f"❌ Error al convertir XML a JSON: {e}")
        return False


def main():
    # Paths
    xml_file = "../swf/gamedata/figuredata.xml"
    json_file = "../assets/gamedata/FigureData.json"

    # Check if XML file exists
    if not os.path.exists(xml_file):
        print(f"❌ Archivo XML no encontrado: {xml_file}")
        return 1

    # Ensure output directory exists
    os.makedirs(os.path.dirname(json_file), exist_ok=True)

    # Convert XML to JSON
    if xml_to_json(xml_file, json_file):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())

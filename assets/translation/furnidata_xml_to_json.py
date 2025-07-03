#!/usr/bin/env python3
"""
Script para convertir furnidata.xml a FurnitureData.json
"""

import xml.etree.ElementTree as ET
import json
import os
import sys


def xml_to_json(xml_file_path, json_file_path):
    """
    Convierte furnidata.xml a FurnitureData.json
    """
    try:
        # Parse the XML file
        tree = ET.parse(xml_file_path)
        root = tree.getroot()

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

        print(f"✅ Archivo {json_file_path} generado exitosamente!")
        return True

    except Exception as e:
        print(f"❌ Error al convertir XML a JSON: {e}")
        return False


def main():
    # Paths
    xml_file = "../swf/gamedata/furnidata.xml"
    json_file = "../assets/gamedata/FurnitureData.json"

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

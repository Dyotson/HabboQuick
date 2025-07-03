#!/usr/bin/env python3
"""
Script para convertir productdata.txt a ProductData.json
"""

import json
import os
import sys
import ast


def txt_to_json(txt_file_path, json_file_path):
    """
    Convierte productdata.txt a ProductData.json
    """
    try:
        # Initialize the result dictionary
        result = {"productdata": {"product": []}}

        # Read the text file
        with open(txt_file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Parse each line as a JSON array
        lines = content.strip().split("\n")
        for line in lines:
            if line.strip():
                try:
                    # Parse the line as JSON array
                    products_array = json.loads(line)

                    # Process each product in the array
                    for product_info in products_array:
                        if len(product_info) >= 3:
                            product_data = {
                                "code": product_info[0],
                                "name": product_info[1],
                                "description": product_info[2],
                            }
                            result["productdata"]["product"].append(product_data)

                except json.JSONDecodeError as e:
                    print(f"⚠️  Error al parsear línea: {line[:50]}... - {e}")
                    continue

        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))

        print(f"✅ Archivo {json_file_path} generado exitosamente!")
        print(f"📊 Productos procesados: {len(result['productdata']['product'])}")
        return True

    except Exception as e:
        print(f"❌ Error al convertir TXT a JSON: {e}")
        return False


def main():
    # Paths
    txt_file = "../swf/gamedata/productdata.txt"
    json_file = "../assets/gamedata/ProductData.json"

    # Check if TXT file exists
    if not os.path.exists(txt_file):
        print(f"❌ Archivo TXT no encontrado: {txt_file}")
        return 1

    # Ensure output directory exists
    os.makedirs(os.path.dirname(json_file), exist_ok=True)

    # Convert TXT to JSON
    if txt_to_json(txt_file, json_file):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())

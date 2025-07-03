#!/usr/bin/env python3
"""
Script principal para convertir todos los archivos XML/TXT a JSON
Diseñado para ejecutarse dentro del contenedor assets
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


def furnidata_xml_to_json(xml_file_path, json_file_path):
    """
    Convierte furnidata.xml a FurnitureData.json
    """
    try:
        print("🔧 Limpiando y reparando archivo XML...")
        
        # First, try to repair the XML file using our advanced repair script
        import subprocess
        import os
        
        # Get the current directory
        current_dir = os.getcwd()
        
        # Run the repair script
        repair_script = os.path.join(current_dir, 'repair_xml_advanced.py')
        if os.path.exists(repair_script):
            print("🛠️  Ejecutando reparación avanzada de XML...")
            result = subprocess.run([
                'python3', repair_script, xml_file_path
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ XML reparado exitosamente")
            else:
                print(f"⚠️  Advertencia en reparación: {result.stderr}")
        
        # Now try to parse the (hopefully) repaired XML
        print("🔍 Intentando parsing del XML...")
        
        # Read and clean the content
        with open(xml_file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Apply additional cleaning
        import re
        
        # Remove control characters except tab, newline, and carriage return
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)
        
        # Fix XML entities more carefully
        # First, protect already correct entities
        content = content.replace('&amp;', '___PROTECTED_AMP___')
        content = content.replace('&lt;', '___PROTECTED_LT___')
        content = content.replace('&gt;', '___PROTECTED_GT___')
        content = content.replace('&quot;', '___PROTECTED_QUOT___')
        content = content.replace('&apos;', '___PROTECTED_APOS___')
        
        # Then escape remaining & characters
        content = content.replace('&', '&amp;')
        
        # Restore protected entities
        content = content.replace('___PROTECTED_AMP___', '&amp;')
        content = content.replace('___PROTECTED_LT___', '&lt;')
        content = content.replace('___PROTECTED_GT___', '&gt;')
        content = content.replace('___PROTECTED_QUOT___', '&quot;')
        content = content.replace('___PROTECTED_APOS___', '&apos;')
        
        # Write to temporary file
        temp_file = xml_file_path + '.temp'
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # Try to parse with error handling
        try:
            tree = ET.parse(temp_file)
            root = tree.getroot()
            print("✅ XML parsing exitoso")
        except ET.ParseError as e:
            print(f"❌ Error de parsing: {e}")
            print("🔧 Intentando parsing con estrategia alternativa...")
            
            # Try to parse with a more permissive approach
            try:
                from xml.etree.ElementTree import XMLParser
                
                class PermissiveXMLParser(XMLParser):
                    def _handle_error(self, error):
                        # Log the error but continue parsing
                        print(f"⚠️  Error XML ignorado: {error}")
                        return True
                
                parser = PermissiveXMLParser()
                tree = ET.parse(temp_file, parser=parser)
                root = tree.getroot()
                print("✅ XML parsing exitoso con parser permisivo")
            except Exception as e2:
                print(f"❌ Error con parser permisivo: {e2}")
                # If all else fails, try to extract data manually
                print("🔧 Intentando extracción manual de datos...")
                return furnidata_manual_extraction(xml_file_path, json_file_path)
        
        # If we get here, we have a valid XML tree
        print("📊 Procesando datos XML...")

        # Initialize the result dictionary
        result = {
            "roomitemtypes": {"furnitype": []},
            "wallitemtypes": {"furnitype": []},
        }

        # Process roomitemtypes
        roomitemtypes = root.find("roomitemtypes")
        if roomitemtypes is not None:
            for furnitype in roomitemtypes.findall("furnitype"):
                try:
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
                except Exception as e:
                    print(f"⚠️  Error procesando room item ID {furnitype.get('id', 'desconocido')}: {e}")
                    continue

        # Process wallitemtypes
        wallitemtypes = root.find("wallitemtypes")
        if wallitemtypes is not None:
            for furnitype in wallitemtypes.findall("furnitype"):
                try:
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
                except Exception as e:
                    print(f"⚠️  Error procesando wall item ID {furnitype.get('id', 'desconocido')}: {e}")
                    continue

        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))

        print(f"✅ FurnitureData.json generado exitosamente!")
        print(f"📊 Elementos procesados: {len(result['roomitemtypes']['furnitype'])} room items, {len(result['wallitemtypes']['furnitype'])} wall items")
        
        # Clean up temporary file
        import os
        if os.path.exists(temp_file):
            os.remove(temp_file)
        
        return True

    except Exception as e:
        print(f"❌ Error al convertir furnidata.xml: {e}")
        # Clean up temporary file on error
        import os
        temp_file = xml_file_path + '.temp'
        if os.path.exists(temp_file):
            os.remove(temp_file)
        return False


def productdata_txt_to_json(txt_file_path, json_file_path):
    """
    Convierte productdata.txt a ProductData.json
    """
    try:
        # Initialize the result dictionary
        result = {"productdata": {"product": []}}

        # Read the text file with better error handling
        with open(txt_file_path, "r", encoding="utf-8", errors='ignore') as f:
            content = f.read()

        # Clean content from control characters
        import re
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)

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


def furnidata_manual_extraction(xml_file_path, json_file_path):
    """
    Extrae datos manualmente del XML cuando el parser falla
    """
    try:
        print("🔧 Extrayendo datos manualmente...")
        
        with open(xml_file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Initialize result
        result = {
            "roomitemtypes": {"furnitype": []},
            "wallitemtypes": {"furnitype": []},
        }
        
        # Use regex to extract furnitype blocks
        import re
        
        # Find roomitemtypes section
        roomitem_pattern = r'<roomitemtypes>(.*?)</roomitemtypes>'
        roomitem_match = re.search(roomitem_pattern, content, re.DOTALL)
        
        if roomitem_match:
            roomitem_content = roomitem_match.group(1)
            # Extract individual furnitype entries
            furnitype_pattern = r'<furnitype[^>]*id="(\d+)"[^>]*classname="([^"]*)"[^>]*>(.*?)</furnitype>'
            
            for match in re.finditer(furnitype_pattern, roomitem_content, re.DOTALL):
                furni_id = int(match.group(1))
                classname = match.group(2)
                furni_content = match.group(3)
                
                # Extract basic fields
                furni_data = {
                    "id": furni_id,
                    "classname": classname,
                    "revision": extract_field(furni_content, "revision", 0),
                    "category": extract_field(furni_content, "category", ""),
                    "defaultdir": extract_field(furni_content, "defaultdir", 0),
                    "xdim": extract_field(furni_content, "xdim", 1),
                    "ydim": extract_field(furni_content, "ydim", 1),
                    "name": extract_field(furni_content, "name", ""),
                    "description": extract_field(furni_content, "description", ""),
                    "adurl": extract_field(furni_content, "adurl", ""),
                    "offerid": extract_field(furni_content, "offerid", -1),
                    "buyout": extract_field(furni_content, "buyout", 0),
                    "rentofferid": extract_field(furni_content, "rentofferid", -1),
                    "rentbuyout": extract_field(furni_content, "rentbuyout", 0),
                    "bc": extract_field(furni_content, "bc", 0),
                    "excludeddynamic": extract_field(furni_content, "excludeddynamic", 0),
                    "customparams": extract_field(furni_content, "customparams", ""),
                    "specialtype": extract_field(furni_content, "specialtype", 1),
                    "canstandon": extract_field(furni_content, "canstandon", 0),
                    "cansiton": extract_field(furni_content, "cansiton", 0),
                    "canlayon": extract_field(furni_content, "canlayon", 0),
                    "furniline": extract_field(furni_content, "furniline", ""),
                    "environment": extract_field(furni_content, "environment", ""),
                    "rare": extract_field(furni_content, "rare", 0),
                }
                
                result["roomitemtypes"]["furnitype"].append(furni_data)
        
        # Find wallitemtypes section  
        wallitem_pattern = r'<wallitemtypes>(.*?)</wallitemtypes>'
        wallitem_match = re.search(wallitem_pattern, content, re.DOTALL)
        
        if wallitem_match:
            wallitem_content = wallitem_match.group(1)
            # Extract individual furnitype entries
            furnitype_pattern = r'<furnitype[^>]*id="(\d+)"[^>]*classname="([^"]*)"[^>]*>(.*?)</furnitype>'
            
            for match in re.finditer(furnitype_pattern, wallitem_content, re.DOTALL):
                furni_id = int(match.group(1))
                classname = match.group(2)
                furni_content = match.group(3)
                
                furni_data = {
                    "id": furni_id,
                    "classname": classname,
                    "revision": extract_field(furni_content, "revision", 0),
                    "category": extract_field(furni_content, "category", ""),
                    "name": extract_field(furni_content, "name", ""),
                    "description": extract_field(furni_content, "description", ""),
                    "adurl": extract_field(furni_content, "adurl", ""),
                    "offerid": extract_field(furni_content, "offerid", -1),
                    "buyout": extract_field(furni_content, "buyout", 0),
                    "rentofferid": extract_field(furni_content, "rentofferid", -1),
                    "rentbuyout": extract_field(furni_content, "rentbuyout", 0),
                    "bc": extract_field(furni_content, "bc", 0),
                    "excludeddynamic": extract_field(furni_content, "excludeddynamic", 0),
                    "customparams": extract_field(furni_content, "customparams", ""),
                    "specialtype": extract_field(furni_content, "specialtype", 1),
                    "furniline": extract_field(furni_content, "furniline", ""),
                    "environment": extract_field(furni_content, "environment", ""),
                    "rare": extract_field(furni_content, "rare", 0),
                }
                
                result["wallitemtypes"]["furnitype"].append(furni_data)
        
        # Write JSON file
        with open(json_file_path, "w", encoding="utf-8") as f:
            json.dump(result, f, separators=(",", ":"))
        
        print(f"✅ FurnitureData.json generado exitosamente (extracción manual)!")
        print(f"📊 Elementos procesados: {len(result['roomitemtypes']['furnitype'])} room items, {len(result['wallitemtypes']['furnitype'])} wall items")
        
        return True
        
    except Exception as e:
        print(f"❌ Error en extracción manual: {e}")
        return False

def extract_field(content, field_name, default_value):
    """
    Extrae un campo específico del contenido XML
    """
    import re
    
    # Try to find the field
    pattern = f'<{field_name}>(.*?)</{field_name}>'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        value = match.group(1).strip()
        # Convert to appropriate type
        if isinstance(default_value, int):
            try:
                return int(value)
            except:
                return default_value
        else:
            return value
    
    return default_value


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

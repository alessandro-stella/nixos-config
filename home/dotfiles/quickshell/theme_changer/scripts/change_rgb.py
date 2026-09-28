#!/usr/bin/env python3

import sys
import os
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

CONFIG = {
    "controller_name": "Lian Li", 
    "zones": [
        {
            "name": "Border",
            "channels": [1, 3, 5, 7],
            "brightness": 0.65,
            "color_arg": 1 
        },
        {
            "name": "Center",
            "channels": [0, 2, 4, 6],
            "brightness": 0.40,
            "color_arg": 2
        }
    ]
}

def hex_to_rgb(hex_color, brightness):
    hex_color = hex_color.strip().lstrip('#')
    r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    r = int(r * brightness)
    g = int(g * brightness)
    b = int(b * brightness)
    
    return (r, g, b)

def get_colors():
    max_arg_needed = max([z["color_arg"] for z in CONFIG["zones"]])
    args = sys.argv[1:]
    
    home_dir = os.path.expanduser("~")
    themes_base = os.path.join(home_dir, ".config", "themes")
    
    theme_folder_name = None
    
    if len(args) >= max_arg_needed:
        print("[INFO] Using colors passed via arguments.")
        colors = {}
        for zone in CONFIG["zones"]:
            colors[zone["color_arg"]] = args[zone["color_arg"] - 1]
        return colors
    elif len(args) == 1:
        print(f"[INFO] Theme name provided as argument: {args[0]}")
        theme_folder_name = args[0]
    elif len(args) == 0:
        current_theme_file = os.path.join(themes_base, "current_theme", "name")
        print(f"[INFO] Reading current theme from: {current_theme_file}")
        if not os.path.exists(current_theme_file):
            print(f"[ERROR] Current theme file not found: {current_theme_file}")
            sys.exit(1)
        try:
            with open(current_theme_file, "r") as f:
                theme_folder_name = f.read().strip()
            print(f"[INFO] Current theme name: {theme_folder_name}")
        except Exception as e:
            print(f"[ERROR] Failed to read current theme file: {e}")
            sys.exit(1)
    else:
        print("[ERROR] Invalid number of arguments.")
        sys.exit(1)
        
    if not theme_folder_name:
        print("[ERROR] Theme folder name is empty.")
        sys.exit(1)
        
    file_path = os.path.join(themes_base, theme_folder_name, "fan-accents.txt")
    print(f"[INFO] Looking for fan accents file at: {file_path}")
    
    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        sys.exit(1)
        
    try:
        with open(file_path, "r") as f:
            lines = [line.strip() for line in f if line.strip()]
            
        if len(lines) < max_arg_needed:
            print("[ERROR] Not enough colors found in fan-accents.txt.")
            sys.exit(1)
            
        colors = {}
        for zone in CONFIG["zones"]:
            arg_idx = zone["color_arg"]
            colors[arg_idx] = lines[arg_idx - 1]
            
        return colors
    except Exception as e:
        print(f"[ERROR] Failed to read file {file_path}: {e}")
        sys.exit(1)

def main():
    colors_dict = get_colors()
    
    print("[INFO] Connecting to OpenRGB server...")
    client = OpenRGBClient()
    
    controller = None
    target_name = CONFIG["controller_name"]
    
    for device in client.devices:
        if target_name in device.name:
            controller = device
            break
            
    if not controller:
        print(f"[ERROR] Controller '{target_name}' not found")
        sys.exit(1)
        
    print(f"[INFO] Controller found: {controller.name}")
    
    for zone in CONFIG["zones"]:
        zone_name = zone["name"]
        brightness = zone["brightness"]
        hex_color = colors_dict[zone["color_arg"]]
        channels = zone["channels"]
        
        rgb_color = hex_to_rgb(hex_color, brightness)
        print(f"[INFO] Applying ({int(brightness * 100)}% lum): RGB{rgb_color} to {zone_name} (Color: {hex_color})")
        
        for zone_idx in channels:
            if zone_idx < len(controller.zones):
                num_leds = len(controller.zones[zone_idx].colors)
                controller.zones[zone_idx].set_colors([RGBColor(*rgb_color)] * num_leds)
                
    print("[✓] RGB updated!")

if __name__ == "__main__":
    main()

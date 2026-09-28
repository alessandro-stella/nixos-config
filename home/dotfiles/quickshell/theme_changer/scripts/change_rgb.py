#!/usr/bin/env python3

import sys
import colorsys
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
    hex_color = hex_color.lstrip('#')
    r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    r = int(r * brightness)
    g = int(g * brightness)
    b = int(b * brightness)
    
    return (r, g, b)

def main():
    max_arg_needed = max([z["color_arg"] for z in CONFIG["zones"]])
    if len(sys.argv) <= max_arg_needed:
        print(f"Usage: change-rgb.py <colore_1_HEX> ... <colore_{max_arg_needed}_HEX>")
        sys.exit(1)
    
    print(f"[INFO] Connecting to OpenRGB server...")
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
        hex_color = sys.argv[zone["color_arg"]]
        channels = zone["channels"]
        
        rgb_color = hex_to_rgb(hex_color, brightness)
        print(f"[INFO] Applying ({int(brightness * 100)}% lum): RGB{rgb_color} to {zone_name}")
        
        for zone_idx in channels:
            if zone_idx < len(controller.zones):
                num_leds = len(controller.zones[zone_idx].colors)
                controller.zones[zone_idx].set_colors([RGBColor(*rgb_color)] * num_leds)
    
    print(f"[✓] RGB updated!")

if __name__ == "__main__":
    main()

#!/usr/bin/env bash

IMAGE_PATH="${1:-$HOME/.config/background.png}"

if [ ! -f "$IMAGE_PATH" ]; then
    echo '{"accent1": "#E0D0B0", "accent2": "#E0D0B0"}'
    exit 1
fi

python3 - "$IMAGE_PATH" << 'EOF'
import sys
import subprocess
import colorsys
import json

image_path = sys.argv[1]

try:
    # 1. Preparazione dell'immagine
    #
    # Manteniamo esattamente il preprocessing della versione
    # originale che funziona con i layer QML:
    #   - resize a 60x60
    #   - blur
    #   - velatura nera al 40%
    #
    cmd = [
        "magick", image_path,
        "-resize", "60x60!",
        "-blur", "0x3",
        "-fill", "black",
        "-colorize", "40%",
        "-depth", "8",
        "rgb:-"
    ]

    proc = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Fallback per ImageMagick versione legacy
    if proc.returncode != 0:
        cmd = [
            "convert", image_path,
            "-resize", "60x60!",
            "-blur", "0x3",
            "-fill", "black",
            "-colorize", "40%",
            "-depth", "8",
            "rgb:-"
        ]

        proc = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

    raw_data = proc.stdout

except Exception:
    print(json.dumps({
        "accent1": "#E0D0B0",
        "accent2": "#E0D0B0"
    }))
    sys.exit(0)


if not raw_data:
    print(json.dumps({
        "accent1": "#E0D0B0",
        "accent2": "#E0D0B0"
    }))
    sys.exit(0)


# ============================================================
# 2. ESTRAZIONE DEL COLORE PRINCIPALE
# ============================================================
#
# La logica è equivalente al QML:
#
#   if (hsvValue < 0.15) continue;
#   score = hsvValue + hsvSaturation * 0.5;
#   bestColor = colore con score massimo;
#
# Non cerchiamo più un secondo pixel con hue differente.
# Entrambi gli accent derivano dallo stesso colore principale.

best_color = None
max_score = -1.0


for i in range(0, len(raw_data), 3):

    r = raw_data[i] / 255.0
    g = raw_data[i + 1] / 255.0
    b = raw_data[i + 2] / 255.0

    # Conversione RGB -> HSV
    h, s, v = colorsys.rgb_to_hsv(r, g, b)

    # Come nel QML:
    # ignoriamo soltanto il nero profondo
    if v < 0.15:
        continue

    # Identico al QML
    score = v + (s * 0.5)

    if score > max_score:
        max_score = score
        best_color = (h, s, v)


# ============================================================
# 3. FALLBACK
# ============================================================

if best_color is None:
    print(json.dumps({
        "accent1": "#E0D0B0",
        "accent2": "#E0D0B0"
    }))
    sys.exit(0)


# ============================================================
# 4. GENERAZIONE DEI DUE ACCENT
# ============================================================

h, original_s, original_v = best_color

# Manteniamo il valore alto come nel QML
v = max(0.85, original_v)


# Accent 1: più saturo
s1 = max(0.15, min(0.70, original_s + 0.20))


# Accent 2: più desaturato
s2 = max(0.05, min(0.30, original_s - 0.10))


# ============================================================
# 5. HSV -> HEX
# ============================================================

def hsv_to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)

    return "#{:02X}{:02X}{:02X}".format(
        int(round(r * 255)),
        int(round(g * 255)),
        int(round(b * 255))
    )


accent1 = hsv_to_hex(h, s1, v)
accent2 = hsv_to_hex(h, s2, v)


# ============================================================
# 6. OUTPUT JSON
# ============================================================

print(json.dumps({
    "accent1": accent1,
    "accent2": accent2
}))
EOF

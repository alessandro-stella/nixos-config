#!/usr/bin/env bash

WALLPAPER="$1"
THEME_DIR="$2"
WAL_CACHE="$HOME/.cache/wallust"
WAL_COLORS_JSON="$WAL_CACHE/colors.json"
KITTY_CONF="$WAL_CACHE/colors-kitty.conf"
FOOT_CONF="$WAL_CACHE/colors-foot.ini"
ROFI_CONF="$WAL_CACHE/colors-rofi.rasi"

HYPR_CONF="$THEME_DIR/dynamic-border.lua"
TEMPLATE="$HOME/.config/wlogout/template.css"
OUTPUT="$THEME_DIR/wlogout_style.css"

OPACITY="ee"
BRIGHT_MIN=80
BRIGHT_MAX=235
MIN_CONTRAST=6
MIN_LUMINANCE_DELTA=0.28

# Dependencies
for cmd in wallust jq awk sed grep; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd"; exit 1; }
done

# Generate palette
rm -rf "$WAL_CACHE"
wallust run "$WALLPAPER" || exit 1

TERMINAL_BG=$(grep -E "^background" "$KITTY_CONF" | awk '{print $2}')
[[ "$TERMINAL_BG" =~ ^#[0-9a-fA-F]{6}$ ]] || { echo "Background detection failed"; exit 1; }

# Utility functions
hex_to_rgb() {
    local h=${1#"#"}
    echo "$((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2}))"
}

hex_to_brightness() {
    local h=${1#"#"}
    local r=$((16#${h:0:2}))
    local g=$((16#${h:2:2}))
    local b=$((16#${h:4:2}))
    echo $(( (299*r + 587*g + 114*b) / 1000 ))
}

dominant_channel() {
    local r=$1 g=$2 b=$3
    ((r>=g && r>=b)) && echo R && return
    ((g>=r && g>=b)) && echo G && return
    echo B
}

hex_to_luminance() {
    local h=${1#"#"}
    local r=$(printf "%d" 0x${h:0:2})
    local g=$(printf "%d" 0x${h:2:2})
    local b=$(printf "%d" 0x${h:4:2})
    awk -v r=$r -v g=$g -v b=$b '
    function f(v){
        v/=255
        return (v<=0.03928)? v/12.92 : ((v+0.055)/1.055)^2.4
    }
    BEGIN{
        R=f(r);G=f(g);B=f(b)
        print 0.2126*R + 0.7152*G + 0.0722*B
    }'
}

contrast_ratio() {
    local L1=$(hex_to_luminance "$1")
    local L2=$(hex_to_luminance "$2")
    awk -v a=$L1 -v b=$L2 '
    BEGIN{
        if(a<b){t=a;a=b;b=t}
        print (a+0.05)/(b+0.05)
    }'
}

# Color correction
adjust_color() {
    local color=$1
    read r g b <<< $(hex_to_rgb "$color")
    local bg_l=$(hex_to_luminance "$TERMINAL_BG")

    for ((i=0;i<32;i++)); do
        current=$(printf "#%02x%02x%02x" $r $g $b)
        contrast=$(contrast_ratio "$current" "$TERMINAL_BG")
        col_l=$(hex_to_luminance "$current")

        ok=$(awk -v c=$contrast -v l=$col_l -v bg=$bg_l \
        -v mc=$MIN_CONTRAST -v md=$MIN_LUMINANCE_DELTA \
        'BEGIN{print (c>=mc && (l-bg)>=md)}')

        [[ $ok -eq 1 ]] && { echo "$current"; return; }

        ((r+=12)); ((g+=12)); ((b+=12))
        ((r>255)) && r=255; ((g>255)) && g=255; ((b>255)) && b=255
    done
    printf "#%02x%02x%02x\n" $r $g $b
}

# Load palette
mapfile -t COLORS_ARRAY < <(jq -r '.[]' "$WAL_COLORS_JSON")
declare -A color_info

for hex in "${COLORS_ARRAY[@]}"; do
    [[ "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
    contrast=$(contrast_ratio "$hex" "$TERMINAL_BG")
    awk -v c=$contrast -v m=$MIN_CONTRAST 'BEGIN{exit !(c<m)}'
    if [[ $? == 0 ]]; then
        hex=$(adjust_color "$hex")
    fi
    brightness=$(hex_to_brightness "$hex")
    ((brightness < BRIGHT_MIN || brightness > BRIGHT_MAX)) && continue
    read r g b <<< $(hex_to_rgb "$hex")
    dominant=$(dominant_channel "$r" "$g" "$b")
    color_info["$hex"]="$brightness|$dominant"
done

(( ${#color_info[@]} < 2 )) && { echo "Palette too small"; exit 1; }

# Select accent colors
sorted_colors=($(for c in "${!color_info[@]}"; do
    echo "$c ${color_info[$c]%%|*}"
done | sort -k2 -nr | awk '{print $1}'))

color1=${sorted_colors[0]}
dominant1=${color_info[$color1]##*|}
read r1 g1 b1 <<< $(hex_to_rgb "$color1")

min_dist=9999
color2=""
for c in "${sorted_colors[@]:1}"; do
    dom=${color_info[$c]##*|}
    [[ "$dom" == "$dominant1" ]] && continue
    read r2 g2 b2 <<< $(hex_to_rgb "$c")
    dist=$(( (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2) + (b1-b2)*(b1-b2) ))
    (( dist < min_dist )) && { min_dist=$dist; color2=$c; }
done
[[ -z "$color2" ]] && color2=${sorted_colors[1]}


# Save files in theme folder
cp "$WAL_COLORS_JSON" "$THEME_DIR/colors.json"
cp "$KITTY_CONF" "$THEME_DIR/colors-kitty.conf"
cp "$FOOT_CONF" "$THEME_DIR/colors-foot.ini"
cp "$ROFI_CONF" "$THEME_DIR/colors-rofi.rasi"
# --------------------------------------------------------------

# Wlogout Output
hex=${color2#"#"}
r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
sed "s/__BUTTON_ACCENT__/$r, $g, $b/g" "$TEMPLATE" > "$OUTPUT"

# Call other scripts to generate theme
"$(dirname "$0")/waybar_changer.sh" "$color1" "$THEME_DIR"
"$(dirname "$0")/oh_my_posh_changer.sh" "$color1" "$THEME_DIR"
"$(dirname "$0")/swaync_changer.sh" "$color1" "$THEME_DIR"

# Hyprland Output
hex_with_opacity() { echo "${1#"#"}$OPACITY"; }
cat > "$HYPR_CONF" <<EOF
-- Dynamic border color used for theming

hl.config({
    general = {
        col = {
            active_border = { colors = { "rgba($(hex_with_opacity "$color1"))", "rgba($(hex_with_opacity "$color2"))" }, angle = 45 },
        },
    },
})
EOF

echo "Theme files created in $THEME_DIR"

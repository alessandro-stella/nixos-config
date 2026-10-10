#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# Theme Creation Script for Quickshell
# Input: wallpaper path, palette JSON, accent1, accent2
# Output: Complete theme folder in ~/.config/themes/THEME_NAME/
# ==============================================================================

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ==============================================================================
# Utility functions
# ==============================================================================

strip_hash() {
    echo "${1#\#}"
}

is_valid_hex() {
    [[ "$1" =~ ^#[0-9a-fA-F]{6}$ ]]
}

hex_to_rgb() {
    local h=${1#"#"}
    echo "$((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2}))"
}

convert_to_rgba() {
    local hex="${1#\#}"
    local alpha="${2:-1.0}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    LC_NUMERIC=C printf "rgba(%d, %d, %d, %.2f)" "$r" "$g" "$b" "$alpha"
}

# Media per canale tra due colori #RRGGBB
mix_hex() {
    local a="${1#\#}" b="${2#\#}"
    printf '#%02x%02x%02x' \
        $(( (16#${a:0:2} + 16#${b:0:2}) / 2 )) \
        $(( (16#${a:2:2} + 16#${b:2:2}) / 2 )) \
        $(( (16#${a:4:2} + 16#${b:4:2}) / 2 ))
}

# Mix pesato tra due colori #RRGGBB: t in per mille (0 -> a, 1000 -> b)
mix_hex_ratio() {
    local a="${1#\#}" b="${2#\#}" t="$3"
    printf '#%02x%02x%02x' \
        $(( (16#${a:0:2} * (1000 - t) + 16#${b:0:2} * t + 500) / 1000 )) \
        $(( (16#${a:2:2} * (1000 - t) + 16#${b:2:2} * t + 500) / 1000 )) \
        $(( (16#${a:4:2} * (1000 - t) + 16#${b:4:2} * t + 500) / 1000 ))
}

# Aumenta la luminosita' (L in HSL) di un valore assoluto (es. 0.10 = +10 punti)
lighten_hsl() {
    local hex="${1#\#}" delta="$2"
    LC_NUMERIC=C awk \
        -v r="$((16#${hex:0:2}))" -v g="$((16#${hex:2:2}))" -v b="$((16#${hex:4:2}))" \
        -v d="$delta" '
    function max(a, b) { return a > b ? a : b }
    function min(a, b) { return a < b ? a : b }
    function hue2rgb(p, q, t) {
        if (t < 0) t += 1
        if (t > 1) t -= 1
        if (t < 1/6) return p + (q - p) * 6 * t
        if (t < 1/2) return q
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
        return p
    }
    BEGIN {
        r /= 255; g /= 255; b /= 255
        mx = max(r, max(g, b)); mn = min(r, min(g, b))
        l = (mx + mn) / 2
        if (mx == mn) { h = 0; s = 0 }
        else {
            dd = mx - mn
            s = (l > 0.5) ? dd / (2 - mx - mn) : dd / (mx + mn)
            if (mx == r)      h = (g - b) / dd + (g < b ? 6 : 0)
            else if (mx == g) h = (b - r) / dd + 2
            else              h = (r - g) / dd + 4
            h /= 6
        }
        l = min(1, l + d)
        if (s == 0) { r = l; g = l; b = l }
        else {
            q = (l < 0.5) ? l * (1 + s) : l + s - l * s
            p = 2 * l - q
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        }
        printf "#%02x%02x%02x", int(r * 255 + 0.5), int(g * 255 + 0.5), int(b * 255 + 0.5)
    }'
}

# ==============================================================================
# Argument parsing
# ==============================================================================

usage() {
    cat << 'EOF'
Usage: create_theme.sh [OPTIONS]

OPTIONS:
    --wallpaper PATH          Path to wallpaper image
    --palette JSON            JSON array of 16 hex colors
    --accent1 COLOR          First accent color (hex)
    --accent2 COLOR          Second accent color (hex)
    --name NAME              Theme name (default: wallpaper file name without extension)
    --apply                  Apply theme immediately (symlink to current_theme)
    --help                   Show this help message

EXAMPLE:
    create_theme.sh \
        --wallpaper /path/to/wallpaper.png \
        --palette '["#1e1e2e","#f38ba8",...]' \
        --accent1 "#a6e3a1" \
        --accent2 "#89b4fa" \
        --apply

EOF
    exit 0
}

WALLPAPER=""
PALETTE_JSON=""
ACCENT1=""
ACCENT2=""
THEME_NAME=""
APPLY_THEME=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --wallpaper)
            WALLPAPER="$2"
            shift 2
            ;;
        --palette)
            PALETTE_JSON="$2"
            shift 2
            ;;
        --accent1)
            ACCENT1="$2"
            shift 2
            ;;
        --accent2)
            ACCENT2="$2"
            shift 2
            ;;
        --name)
            THEME_NAME="$2"
            shift 2
            ;;
        --apply)
            APPLY_THEME=1
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# ==============================================================================
# Input validation
# ==============================================================================

if [[ -z "$WALLPAPER" ]] || [[ -z "$PALETTE_JSON" ]] || [[ -z "$ACCENT1" ]] || [[ -z "$ACCENT2" ]]; then
    log_error "Missing required arguments"
    usage
fi

if [[ ! -f "$WALLPAPER" ]]; then
    log_error "Wallpaper file not found: $WALLPAPER"
    exit 1
fi

if ! is_valid_hex "$ACCENT1" || ! is_valid_hex "$ACCENT2"; then
    log_error "Invalid accent colors (must be hex format #RRGGBB)"
    exit 1
fi

log_info "Validating palette JSON..."
if ! echo "$PALETTE_JSON" | jq empty 2>/dev/null; then
    log_error "Invalid palette JSON"
    exit 1
fi

mapfile -t COLORS < <(echo "$PALETTE_JSON" | jq -r '.[]')

if (( ${#COLORS[@]} < 8 )); then
    log_error "Palette must contain at least 8 colors (got ${#COLORS[@]})"
    exit 1
fi

# Se la palette ha meno di 16 colori, i bright ripetono i colori normali
if (( ${#COLORS[@]} < 16 )); then
    log_warn "Palette has ${#COLORS[@]} colors, bright colors will duplicate the normal ones"
    for i in {8..15}; do
        COLORS[$i]="${COLORS[$((i - 8))]}"
    done
fi

for i in {0..15}; do
    if ! is_valid_hex "${COLORS[$i]}"; then
        log_error "Invalid palette color at index $i: ${COLORS[$i]}"
        exit 1
    fi
done

# ==============================================================================
# Setup paths
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$MODULE_DIR/templates"
THEME_BASE_DIR="$HOME/.config/themes"
CURRENT_THEME_DIR="$THEME_BASE_DIR/current_theme"

WALLPAPER_BASENAME=$(basename "$WALLPAPER")
WALLPAPER_NAME="${WALLPAPER_BASENAME%.*}"

# Nome tema: --name se fornito, altrimenti il nome del wallpaper senza estensione
THEME_NAME="${THEME_NAME//\//_}"
THEME_NAME="$(echo "$THEME_NAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
if [[ -z "$THEME_NAME" || "$THEME_NAME" == "." || "$THEME_NAME" == ".." ]]; then
    THEME_NAME="$WALLPAPER_NAME"
fi
if [[ "$THEME_NAME" == "current_theme" ]]; then
    log_error "Theme name 'current_theme' is reserved"
    exit 1
fi

THEME_DIR="$THEME_BASE_DIR/$THEME_NAME"

log_info "Creating theme directory: $THEME_DIR"
mkdir -p "$THEME_DIR"

# ==============================================================================
# Check dependencies
# ==============================================================================

log_info "Checking dependencies..."
for cmd in jq; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

if ! command -v magick &>/dev/null; then
    log_warn "ImageMagick not found - thumbnail generation will be skipped"
fi

# ==============================================================================
# Copy and optimize wallpaper
# ==============================================================================

log_info "Processing wallpaper..."
cp "$WALLPAPER" "$THEME_DIR/wallpaper.png"
log_success "Copied wallpaper to $THEME_DIR/wallpaper.png"

if command -v magick &>/dev/null; then
    log_info "Generating thumbnail..."
    if magick "$WALLPAPER" \
        -resize "320x180^" \
        -gravity center \
        -extent "320x180" \
        -quality 80 \
        "$THEME_DIR/thumbnail.png"; then
        log_success "Created thumbnail: $THEME_DIR/thumbnail.png"
    else
        log_warn "Failed to create thumbnail, skipping"
    fi
fi

# ==============================================================================
# Generate colors-foot.ini
# ==============================================================================

WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
WAL_FOOT="$WAL_CACHE/colors-foot-dark.ini"

if [[ -f "$WAL_FOOT" ]]; then
    log_info "Copying colors-foot.ini from $WAL_FOOT..."
    cp "$WAL_FOOT" "$THEME_DIR/colors-foot.ini"

    # Riapplica regular0-7 / bright0-7 dalla palette ricevuta: se i colori sono
    # stati modificati nel widget le modifiche arrivano anche al terminale.
    # Con palette non modificata i valori restano identici a quelli di wal.
    for i in {0..15}; do
        if (( i < 8 )); then
            key="regular$i"
        else
            key="bright$((i - 8))"
        fi
        sed -i -E "s/^(${key}[[:space:]]*=[[:space:]]*).*/\1$(strip_hash "${COLORS[$i]}")/" \
            "$THEME_DIR/colors-foot.ini"
    done

    log_success "Copied colors-foot.ini"
else
    log_warn "$WAL_FOOT not found, generating colors-foot.ini from palette"

cat > "$THEME_DIR/colors-foot.ini" << EOF
[colors-dark]
foreground=EEFAF9
background=121212
cursor=$(strip_hash "$ACCENT1") EEFAF9 
selection-foreground=121212
selection-background=EEFAF9

# Standard colors
regular0=$(strip_hash "${COLORS[0]}")
regular1=$(strip_hash "${COLORS[1]}")
regular2=$(strip_hash "${COLORS[2]}")
regular3=$(strip_hash "${COLORS[3]}")
regular4=$(strip_hash "${COLORS[4]}")
regular5=$(strip_hash "${COLORS[5]}")
regular6=$(strip_hash "${COLORS[6]}")
regular7=$(strip_hash "${COLORS[7]}")

# Bright colors
bright0=$(strip_hash "${COLORS[8]}")
bright1=$(strip_hash "${COLORS[9]}")
bright2=$(strip_hash "${COLORS[10]}")
bright3=$(strip_hash "${COLORS[11]}")
bright4=$(strip_hash "${COLORS[12]}")
bright5=$(strip_hash "${COLORS[13]}")
bright6=$(strip_hash "${COLORS[14]}")
bright7=$(strip_hash "${COLORS[15]}")
EOF

    log_success "Generated colors-foot.ini (fallback)"
fi

# ==============================================================================
# Colori UI derivati dalla palette di wal (usati da swaync.css e Accents.qml)
# ==============================================================================

# Colori UI derivati dalla palette di wal
UI_BG="${COLORS[0]}"

# colFg = colore del cursore di wal (special.cursor); fallback: color7
UI_FG=""
if [[ -f "$WAL_CACHE/colors.json" ]]; then
    UI_FG="$(jq -r '.special.cursor // empty' "$WAL_CACHE/colors.json" 2>/dev/null || true)"
fi
if ! is_valid_hex "$UI_FG"; then
    log_warn "Cursor color not found in $WAL_CACHE/colors.json, using color7"
    UI_FG="${COLORS[7]}"
fi

UI_MUTED="$(mix_hex "$UI_BG" "$UI_FG")"
UI_LIGHT_BG="$(lighten_hsl "$UI_BG" 0.10)"
# Testo secondario (es. corpo delle notifiche): 77.7% tra sfondo e testo,
# la stessa posizione sulla rampa usata per la barra
UI_FG_DIM="$(mix_hex_ratio "$UI_BG" "$UI_FG" 777)"

# ==============================================================================
# Generate swaync.css from template
# ==============================================================================

log_info "Generating swaync.css..."

if [[ ! -f "$TEMPLATES_DIR/swaync.css.j2" ]]; then
    log_error "Template not found: $TEMPLATES_DIR/swaync.css.j2"
    exit 1
fi

# Replace template placeholders
sed -e "s/__ACCENT_COLOR__/$ACCENT1/g" \
    -e "s/__BG_COLOR__/$UI_BG/g" \
    -e "s/__FG_COLOR__/$UI_FG/g" \
    -e "s/__FG_DIM__/$UI_FG_DIM/g" \
    "$TEMPLATES_DIR/swaync.css.j2" > "$THEME_DIR/swaync.css"

log_success "Generated swaync.css"

# ==============================================================================
# Generate theme.omp.json from template
# ==============================================================================

log_info "Generating theme.omp.json..."

if [[ ! -f "$TEMPLATES_DIR/theme.omp.json.j2" ]]; then
    log_error "Template not found: $TEMPLATES_DIR/theme.omp.json.j2"
    exit 1
fi

# Copy template to output
cp "$TEMPLATES_DIR/theme.omp.json.j2" "$THEME_DIR/theme.omp.json"

# Replace color placeholders
for i in {0..15}; do
    sed -i "s/__COLOR${i}__/${COLORS[$i]}/g" "$THEME_DIR/theme.omp.json"
done

log_success "Generated theme.omp.json"

# ==============================================================================
# Generate Accents.qml
# ==============================================================================

log_info "Generating Accents.qml..."

cat > "$THEME_DIR/Accents.qml" << EOF
pragma Singleton
import QtQuick

QtObject {
  readonly property color accent1: "$ACCENT1"
  readonly property color accent2: "$ACCENT2"

  readonly property color colBg: "$UI_BG"
  readonly property color colFg: "$UI_FG"
  readonly property color colMuted: "$UI_MUTED"

  readonly property color widgetDarkBackground: "$UI_BG"
  readonly property color widgetLightBackground: "$UI_LIGHT_BG"
}
EOF

log_success "Generated Accents.qml"

# ==============================================================================
# Generate AccentsSDDM.qml
# ==============================================================================

log_info "Generating AccentsSDDM.qml..."

cat > "$THEME_DIR/AccentsSDDM.qml" << EOF
import QtQuick

QtObject {
    readonly property color accent1: "$ACCENT1"
    readonly property color accent2: "$ACCENT2"
}
EOF

log_success "Generated AccentsSDDM.qml"

# ==============================================================================
# Generate dynamic-border.lua from template
# ==============================================================================

log_info "Generating dynamic-border.lua..."

if [[ ! -f "$TEMPLATES_DIR/dynamic-border.lua.j2" ]]; then
    log_error "Template not found: $TEMPLATES_DIR/dynamic-border.lua.j2"
    exit 1
fi

# Add opacity to colors
ACCENT1_HEX=$(strip_hash "$ACCENT1")ee
ACCENT2_HEX=$(strip_hash "$ACCENT2")ee

# Replace template placeholders
sed -e "s/__ACCENT1__/$ACCENT1_HEX/g" \
    -e "s/__ACCENT2__/$ACCENT2_HEX/g" \
    "$TEMPLATES_DIR/dynamic-border.lua.j2" > "$THEME_DIR/dynamic-border.lua"

log_success "Generated dynamic-border.lua"

# ==============================================================================
# Generate fan_accents.txt
# ==============================================================================

log_info "Generating fan-accents.txt..."

cat > "$THEME_DIR/fan-accents.txt" << EOF
$ACCENT1
$ACCENT2
EOF

log_success "Generated fan-accents.txt"

# ==============================================================================
# Summary
# ==============================================================================

log_success "Theme created successfully!"
echo ""
log_info "Theme location: $THEME_DIR"
log_info "Files created:"
echo "  ✓ wallpaper.png"
echo "  ✓ thumbnail.png (optional)"
echo "  ✓ colors-foot.ini"
echo "  ✓ swaync.css"
echo "  ✓ theme.omp.json"
echo "  ✓ Accents.qml"
echo "  ✓ AccentsSDDM.qml"
echo "  ✓ dynamic-border.lua"
echo "  ✓ fan-accents.txt"

# ==============================================================================
# Apply theme (if --apply flag)
# ==============================================================================

if [[ $APPLY_THEME -eq 1 ]]; then
    log_info "Applying theme via apply_theme.sh..."
    nohup "$SCRIPT_DIR/apply_theme.sh" "$THEME_NAME" >/dev/null 2>&1 &
    disown
fi

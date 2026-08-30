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

CORRECTED_COLORS=(
    "${COLORS[0]}"  # color0
    "${COLORS[1]}"  # color1
    "${COLORS[2]}"  # color2
    "${COLORS[3]}"  # color3
    "${COLORS[4]}"  # color4
    "${COLORS[5]}"  # color5
    "${COLORS[6]}"  # color6
    "${COLORS[7]}"  # color7
    "${COLORS[0]}"  # color8
    "${COLORS[1]}"  # color9
    "${COLORS[2]}"  # color10
    "${COLORS[3]}"  # color11
    "${COLORS[4]}"  # color12
    "${COLORS[5]}"  # color13
    "${COLORS[6]}"  # color14
    "${COLORS[7]}"  # color15

)
COLORS=("${CORRECTED_COLORS[@]}")

# ==============================================================================
# Setup paths
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
THEME_BASE_DIR="$HOME/.config/themes"
CURRENT_THEME_DIR="$THEME_BASE_DIR/current_theme"

WALLPAPER_BASENAME=$(basename "$WALLPAPER")
WALLPAPER_NAME="${WALLPAPER_BASENAME%.*}"
THEME_DIR="$THEME_BASE_DIR/$WALLPAPER_NAME"

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
# Generate colors.json (palette backup)
# ==============================================================================

log_info "Generating colors.json..."

cat > "$THEME_DIR/colors.json" << EOF
{
  "accent1": "$ACCENT1",
  "accent2": "$ACCENT2",
  "palette": [
    $(printf '"%s", ' "${COLORS[@]}" | sed 's/, $//')
  ]
}
EOF

log_success "Generated colors.json"

# ==============================================================================
# Generate colors-foot.ini
# ==============================================================================

log_info "Generating colors-foot.ini..."

cat > "$THEME_DIR/colors-foot.ini" << EOF
[colors-dark]
foreground=EEFAF9
background=242223
cursor=$(strip_hash "$ACCENT1") EEFAF9 
selection-foreground=242223
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

log_success "Generated colors-foot.ini"

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
}
EOF

log_success "Generated Accents.qml"

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
# Summary
# ==============================================================================

log_success "Theme created successfully!"
echo ""
log_info "Theme location: $THEME_DIR"
log_info "Files created:"
echo "  ✓ wallpaper.png"
echo "  ✓ thumbnail.png (optional)"
echo "  ✓ colors-foot.ini"
echo "  ✓ colors.json"
echo "  ✓ swaync.css"
echo "  ✓ theme.omp.json"
echo "  ✓ Accents.qml"
echo "  ✓ dynamic-border.lua"

# ==============================================================================
# Apply theme (if --apply flag)
# ==============================================================================

if [[ $APPLY_THEME -eq 1 ]]; then
    log_info "Applying theme via apply_theme.sh..."
    "$SCRIPT_DIR/apply_theme.sh" "$WALLPAPER_NAME"
fi

#!/usr/bin/env bash
#
# Generate alacritty/.config/alacritty/colors.toml from theme/palette.sh.
# Not stowed (see --ignore in install.sh). Run via theme/generate.sh or directly.
#
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../theme/palette.sh
. "$PKG_DIR/../theme/palette.sh"

out="$PKG_DIR/.config/alacritty/colors.toml"
mkdir -p "$(dirname "$out")"

cat > "$out" <<EOF
# GENERATED from theme/palette.sh by alacritty/generate-theme.sh — DO NOT EDIT.

[colors.primary]
background = "$C_BG"
foreground = "$C_FG"

[colors.cursor]
text   = "$C_BG"
cursor = "$C_FG"

[colors.selection]
text       = "CellForeground"
background = "$C_BG_HIGHLIGHT"

[colors.normal]
black   = "$C_ANSI0"
red     = "$C_ANSI1"
green   = "$C_ANSI2"
yellow  = "$C_ANSI3"
blue    = "$C_ANSI4"
magenta = "$C_ANSI5"
cyan    = "$C_ANSI6"
white   = "$C_ANSI7"

[colors.bright]
black   = "$C_ANSI8"
red     = "$C_ANSI9"
green   = "$C_ANSI10"
yellow  = "$C_ANSI11"
blue    = "$C_ANSI12"
magenta = "$C_ANSI13"
cyan    = "$C_ANSI14"
white   = "$C_ANSI15"
EOF

echo "wrote $out"

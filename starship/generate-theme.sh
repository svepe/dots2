#!/usr/bin/env bash
#
# Sync the starship palette to theme/palette.sh. Unlike other packages this
# edits color_* lines IN PLACE (rather than regenerating the whole file) because
# starship.toml is full of Nerd Font glyphs that must be preserved verbatim.
# Not stowed (see --ignore in install.sh).
#
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../theme/palette.sh
. "$PKG_DIR/../theme/palette.sh"

f="$PKG_DIR/.config/starship.toml"

sed -i \
  -e "s|^color_fg0 = .*|color_fg0 = '$C_FG_DIM'|" \
  -e "s|^color_bg1 = .*|color_bg1 = '$C_BG'|" \
  -e "s|^color_bg3 = .*|color_bg3 = '$C_GREY'|" \
  -e "s|^color_blue = .*|color_blue = '$C_BLUE'|" \
  -e "s|^color_aqua = .*|color_aqua = '$C_CYAN'|" \
  -e "s|^color_green = .*|color_green = '$C_GREEN'|" \
  -e "s|^color_orange = .*|color_orange = '$C_ORANGE'|" \
  -e "s|^color_purple = .*|color_purple = '$C_PURPLE'|" \
  -e "s|^color_red = .*|color_red = '$C_RED'|" \
  -e "s|^color_yellow = .*|color_yellow = '$C_YELLOW'|" \
  "$f"

echo "synced palette in $f"

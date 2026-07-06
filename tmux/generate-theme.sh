#!/usr/bin/env bash
#
# Generate tmux/.config/tmux/theme.conf from theme/palette.sh — colors, styles,
# and the powerline status bar. Reproduces the old tmux-powerline layout:
#   left:  session name          (blue)
#   mid:   window list           (current highlighted; hard+soft separators)
#   right: cpu/mem · disk / · host
# Sourced by tmux.conf. Not stowed (see --ignore in install.sh).
#
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../theme/palette.sh
. "$PKG_DIR/../theme/palette.sh"

out="$PKG_DIR/.config/tmux/theme.conf"
mkdir -p "$(dirname "$out")"

# Powerline separators (Nerd Font), by codepoint so the glyph bytes are reliable.
# Hard = solid, soft = thin. Left side points right (E0B0/E0B1); right side left
# (E0B2/E0B3). To spice things up, swap codepoints: rounded E0B4/E0B6, flame
# E0C0/E0C2, trapezoid E0D4/E0D2, pixel E0C4/E0C6.
L_HARD=$(printf ''); L_SOFT=$(printf '')
R_HARD=$(printf ''); R_SOFT=$(printf '')

# Right-side segment data sources. $HOME stays literal so it's per-user at runtime.
MEMCPU='#($HOME/.config/tmux/plugins/tmux-mem-cpu-load/tmux-mem-cpu-load --interval 2 --averages-count 0 --graph-lines 0)'
DISK="#(df -h / | awk 'NR==2{print \$5}')"

cat > "$out" <<EOF
# GENERATED from theme/palette.sh by tmux/generate-theme.sh — DO NOT EDIT.

# --- base styles ------------------------------------------------------------
set -g mode-style "fg=$C_FG,bg=$C_BG_HIGHLIGHT"
set -g message-style "fg=$C_BG,bg=$C_YELLOW"
set -g message-command-style "fg=$C_BG,bg=$C_YELLOW"
set -g copy-mode-match-style "fg=$C_BG,bg=$C_FG_DIM"
set -g copy-mode-current-match-style "fg=$C_BG,bg=$C_YELLOW"
set -g copy-mode-mark-style "fg=$C_FG,bg=$C_HOTPINK"
set -g pane-border-style "fg=$C_GREY"
set -g pane-active-border-style "fg=$C_GREEN"

# --- status bar -------------------------------------------------------------
set -g status on
set -g status-interval 2
set -g status-justify left
set -g status-style "fg=$C_GREEN,bg=$C_BG"
set -g status-left-length 60
set -g status-right-length 90

# left: session (blue) tapering via a blue arrow onto the black window area
set -g status-left "#[fg=$C_BLACK,bg=$C_BLUE] #S #[fg=$C_BLUE,bg=$C_BG]${L_HARD}#[fg=$C_GREEN,bg=$C_BG]"

# windows: current = green pill with a black-on-green leading cap and a
# green-on-black trailing cap; inactive = green text on black, soft index│name divider.
set -g window-status-separator ""
set -g window-status-format "#[fg=$C_GREEN,bg=$C_BG] #I#{?window_flags,#F, }#[fg=$C_GREY]${L_SOFT}#[fg=$C_GREEN] #W "
set -g window-status-current-format "#[fg=$C_BG,bg=$C_GREEN]${L_HARD}#[fg=$C_BLACK,bg=$C_GREEN] #I#F #[fg=$C_BLACK]${L_SOFT}#[fg=$C_BLACK] #W #[fg=$C_GREEN,bg=$C_BG]${L_HARD}#[fg=$C_GREEN,bg=$C_BG]"

# right: cpu/mem (grey) · disk / (green) · host (blue), hard separators
set -g status-right "#[fg=$C_GREY,bg=$C_BG]${R_HARD}#[fg=$C_GREEN,bg=$C_GREY] ${MEMCPU} #[fg=$C_GREEN,bg=$C_GREY]${R_HARD}#[fg=$C_BLACK,bg=$C_GREEN] ${DISK} #[fg=$C_BLUE,bg=$C_GREEN]${R_HARD}#[fg=$C_BLACK,bg=$C_BLUE] #h #[default]"
EOF

echo "wrote $out"

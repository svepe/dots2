#!/usr/bin/env bash
#
# KDE (Plasma 6) global keyboard shortcuts — declarative and idempotent.
# Not stowed (Plasma rewrites its config in place); applied by install.sh.
# Writes ~/.config/kglobalshortcutsrc via kwriteconfig6.
#
# Shortcut value format: "active,default,friendly name" (use "none" to disable).
#
set -euo pipefail

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping KDE shortcuts"
  exit 0
fi

FILE=kglobalshortcutsrc
SRC="$HOME/.config/$FILE"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- backup before touching anything ----------------------------------------
if [ -f "$SRC" ]; then
  bak="$SRC.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$SRC" "$bak"
  log "backed up $FILE -> $(basename "$bak")"
fi

# --- remap the KWin actions that own Meta+T / Meta+W onto Meta+Alt+<key> -----
# Value is "active,default,friendly": active moves to Meta+Alt+<key>, KWin's
# default (2nd field) is preserved. This keeps the actions usable and frees the
# bare Meta+<key> for the launchers below.
kwriteconfig6 --file "$FILE" --group kwin --key "Edit Tiles" "Meta+Alt+T,Meta+T,Toggle Tiles Editor"
kwriteconfig6 --file "$FILE" --group kwin --key "Overview"   "Meta+Alt+W,Meta+W,Toggle Overview"

# --- preference remaps -------------------------------------------------------
# Add Meta+Return for Maximize, keeping the default Meta+PgUp active too.
kwriteconfig6 --file "$FILE" --group kwin --key "Window Maximize" \
  "$(printf 'Meta+Return\tMeta+PgUp,Meta+PgUp,Maximize Window')"

# Lock screen on Ctrl+Alt+O (+ Screensaver key). Meta+L is intentionally dropped
# here — it is reused below for vim-style Quick Tile Right.
kwriteconfig6 --file "$FILE" --group ksmserver --key "Lock Session" \
  "$(printf 'Ctrl+Alt+O\tScreensaver,Meta+L\tScreensaver,Lock Session')"

# --- vim-style window tiling -------------------------------------------------
# Meta+H/J/K/L mirror Meta+Left/Down/Up/Right for Quick Tile, added as extra
# bindings (tab-separated) alongside the arrow keys.
kwriteconfig6 --file "$FILE" --group kwin --key "Window Quick Tile Left" \
  "$(printf 'Meta+Left\tMeta+H,Meta+Left,Quick Tile Window to the Left')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window Quick Tile Bottom" \
  "$(printf 'Meta+Down\tMeta+J,Meta+Down,Quick Tile Window to the Bottom')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window Quick Tile Top" \
  "$(printf 'Meta+Up\tMeta+K,Meta+Up,Quick Tile Window to the Top')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window Quick Tile Right" \
  "$(printf 'Meta+Right\tMeta+L,Meta+Right,Quick Tile Window to the Right')"

# Close window on Alt+Q as well as the default Alt+F4.
kwriteconfig6 --file "$FILE" --group kwin --key "Window Close" \
  "$(printf 'Alt+F4\tAlt+Q,Alt+F4,Close Window')"

# --- free Meta+Alt+K / Meta+Alt+L for the spatial-focus KWin script ----------
# Layout switching lives on Alt+Shift (grp:alt_shift_toggle, see 45-kde-keyboard.sh),
# so these kglobalaccel layout switchers are redundant — disable their active
# binding to free Meta+Alt+K/L for spatial focus (up/right).
kwriteconfig6 --file "$FILE" --group "KDE Keyboard Layout Switcher" \
  --key "Switch to Next Keyboard Layout" "none,Meta+Alt+K,Switch to Next Keyboard Layout"
kwriteconfig6 --file "$FILE" --group "KDE Keyboard Layout Switcher" \
  --key "Switch to Last-Used Keyboard Layout" "none,Meta+Alt+L,Switch to Last-Used Keyboard Layout"

# --- vim-style desktop navigation --------------------------------------------
# Switch the active desktop with Ctrl+Alt+<h/j/k/l or arrow>. The KDE defaults
# (Meta+Ctrl+<arrow>) are disabled — active holds only our combos; the default
# is kept in the 2nd field for reference.
kwriteconfig6 --file "$FILE" --group kwin --key "Switch One Desktop to the Left" \
  "$(printf 'Ctrl+Alt+H\tCtrl+Alt+Left,Meta+Ctrl+Left,Switch One Desktop to the Left')"
kwriteconfig6 --file "$FILE" --group kwin --key "Switch One Desktop Down" \
  "$(printf 'Ctrl+Alt+J\tCtrl+Alt+Down,Meta+Ctrl+Down,Switch One Desktop Down')"
kwriteconfig6 --file "$FILE" --group kwin --key "Switch One Desktop Up" \
  "$(printf 'Ctrl+Alt+K\tCtrl+Alt+Up,Meta+Ctrl+Up,Switch One Desktop Up')"
kwriteconfig6 --file "$FILE" --group kwin --key "Switch One Desktop to the Right" \
  "$(printf 'Ctrl+Alt+L\tCtrl+Alt+Right,Meta+Ctrl+Right,Switch One Desktop to the Right')"

# Move the window to another desktop with Meta+Ctrl+Alt+<h/j/k/l or arrow>. KDE
# defaults (Meta+Ctrl+Shift+<arrow>) disabled the same way.
kwriteconfig6 --file "$FILE" --group kwin --key "Window One Desktop to the Left" \
  "$(printf 'Meta+Ctrl+Alt+H\tMeta+Ctrl+Alt+Left,Meta+Ctrl+Shift+Left,Window One Desktop to the Left')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window One Desktop Down" \
  "$(printf 'Meta+Ctrl+Alt+J\tMeta+Ctrl+Alt+Down,Meta+Ctrl+Shift+Down,Window One Desktop Down')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window One Desktop Up" \
  "$(printf 'Meta+Ctrl+Alt+K\tMeta+Ctrl+Alt+Up,Meta+Ctrl+Shift+Up,Window One Desktop Up')"
kwriteconfig6 --file "$FILE" --group kwin --key "Window One Desktop to the Right" \
  "$(printf 'Meta+Ctrl+Alt+L\tMeta+Ctrl+Alt+Right,Meta+Ctrl+Shift+Right,Window One Desktop to the Right')"

# --- spatial-focus KWin script bindings --------------------------------------
# The spatial-focus script registers these actions, but kglobalaccel autoloads
# whatever is saved here and ignores the script's built-in default. If a key was
# momentarily unavailable at first registration (e.g. Meta+Alt+K/L held by the
# layout switcher during login) it gets saved empty and stays broken. Writing
# them explicitly makes the bindings deterministic regardless of login timing.
kwriteconfig6 --file "$FILE" --group kwin --key "Focus Window Left"  "Meta+Alt+H,none,Focus Window Left"
kwriteconfig6 --file "$FILE" --group kwin --key "Focus Window Down"  "Meta+Alt+J,none,Focus Window Down"
kwriteconfig6 --file "$FILE" --group kwin --key "Focus Window Up"    "Meta+Alt+K,none,Focus Window Up"
kwriteconfig6 --file "$FILE" --group kwin --key "Focus Window Right" "Meta+Alt+L,none,Focus Window Right"
for i in 1 2 3 4 5 6 7 8 9; do
  kwriteconfig6 --file "$FILE" --group kwin --key "Focus Window $i" "Alt+$i,none,Focus Window $i"
done

# --- application launch shortcuts on the freed keys -------------------------
# Under [services][<desktop-id>.desktop], _launch MUST be a BARE key sequence,
# exactly as System Settings writes it. The 3-field "key,default,friendly" form
# shows in the UI but the grab is never installed — this was the original bug.
#   Meta+T       -> alacritty running tmux (alacritty-tmux.desktop, stowed)
#   Ctrl+Alt+T   -> plain alacritty (freed from Konsole's default launcher)
kwriteconfig6 --file "$FILE" --group services --group "alacritty-tmux.desktop" --key "_launch" "Meta+T"
kwriteconfig6 --file "$FILE" --group services --group "Alacritty.desktop"      --key "_launch" "Ctrl+Alt+T"
kwriteconfig6 --file "$FILE" --group services --group "firefox.desktop"        --key "_launch" "Meta+W"
# Free Ctrl+Alt+T from Konsole's built-in launcher default.
kwriteconfig6 --file "$FILE" --group services --group "org.kde.konsole.desktop" --key "_launch" "none"

log "wrote shortcuts to $SRC — take effect at next login"

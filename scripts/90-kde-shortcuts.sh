#!/usr/bin/env bash
#
# KDE (Plasma 6) global keyboard shortcuts — declarative and idempotent.
# Not stowed (Plasma rewrites its config in place); applied by install.sh.
#
# Shortcuts live in two places and BOTH have to agree:
#
#   1. ~/.config/kglobalshortcutsrc, which the shortcuts daemon reads at login.
#   2. The daemon's in-memory table, which it writes back over that file when
#      the session ends.
#
# Writing only the file loses the race: the daemon saves its (unchanged) copy
# on logout and the file is back to defaults by the next boot. So each binding
# is written to the config AND pushed into the running daemon over D-Bus, which
# is what System Settings does and what makes the change stick.
#
# On Plasma >= 6.5 Wayland the daemon is kwin_wayland itself — it owns the
# org.kde.kglobalaccel name and the standalone kglobalacceld exits immediately
# at login. There is therefore no separate process to restart or kill; talking
# to the D-Bus name is the only way to reach whichever one is in charge.
#
# Run with --check to assert instead of apply: every binding below is read back
# from the running daemon and compared, writing nothing and registering nothing.
# After a reboot that verifies what the *config* alone produced, which is the
# regression that made a fresh install come up with stock defaults.
#
set -euo pipefail

CHECK=0
case "${1:-}" in
  --check) CHECK=1 ;;
  "")      ;;
  *)       echo "usage: $(basename "$0") [--check]" >&2; exit 2 ;;
esac

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping KDE shortcuts"
  exit 0
fi

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSEQ="$DOTS_DIR/scripts/lib/qt-keyseq.py"
FILE=kglobalshortcutsrc
SRC="$HOME/.config/$FILE"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- backup before touching anything ----------------------------------------
if [ "$CHECK" = "0" ] && [ -f "$SRC" ]; then
  bak="$SRC.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$SRC" "$bak"
  log "backed up $FILE -> $(basename "$bak")"
fi

# --- is a shortcuts daemon actually running? --------------------------------
# False during an install from a TTY or over SSH, where the config write is
# both necessary and sufficient — nothing is live to clobber it.
live_daemon() {
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || return 1
  command -v busctl >/dev/null 2>&1 || return 1
  [ "$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus NameHasOwner s org.kde.kglobalaccel 2>/dev/null)" = "b true" ]
}
if live_daemon; then LIVE=1; else LIVE=0; fi
if [ "$CHECK" = "1" ] && [ "$LIVE" = "0" ]; then
  echo "no shortcuts daemon on the session bus — run --check from inside a Plasma session" >&2
  exit 2
fi

# --- appliers ----------------------------------------------------------------
# Config format is "active,default,friendly name"; alternative key sequences are
# tab-separated. The table below uses ";" for those so the entries stay readable.
write_config() {
  local component="$1" action="$2" active="$3" default="$4" friendly="$5"
  kwriteconfig6 --file "$FILE" --group "$component" --key "$action" \
    "${active//;/$'\t'},${default//;/$'\t'},$friendly"
}

# Push into the running daemon. Only ever affects components that have already
# registered their actions; for anything else it is a silent no-op (see the
# application launchers below).
set_live() {
  local component="$1" action="$2" active="$3" encoded
  encoded="$(python3 "$KEYSEQ" "$active")" || return 1
  # $encoded is a pre-split busctl argument list, so it must stay unquoted.
  # shellcheck disable=SC2086
  busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
    setForeignShortcutKeys 'asa(ai)' 4 "$component" "$action" "" "" $encoded >/dev/null
}

# Read a binding back out of the daemon and compare it with what we intended.
# Deliberately does not register anything first, so --check after a reboot
# reports what the config produced on its own.
FAILED=0
CHECKED=0
check_live() {
  local component="$1" action="$2" active="$3" want got
  want="$(python3 "$KEYSEQ" "$active")"
  got="$(busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
          shortcutKeys as 4 "$component" "$action" "" "" 2>/dev/null | sed 's/^a(ai) //')"
  CHECKED=$((CHECKED + 1))
  if [ "$got" != "$want" ]; then
    FAILED=$((FAILED + 1))
    printf '\033[1;31m  ✗\033[0m %-34s want %-28s got %s\n' \
      "$action" "${active:-none}" "$(python3 "$KEYSEQ" --decode "$got" 2>/dev/null || echo "$got")"
  fi
}

apply() {
  local component="$1" action="$2" active="$3" default="$4" friendly="$5"
  if [ "$CHECK" = "1" ]; then
    check_live "$component" "$action" "$active"
    return 0
  fi
  write_config "$component" "$action" "$active" "$default" "$friendly"
  [ "$LIVE" = "1" ] && set_live "$component" "$action" "$active"
  return 0
}

# --- the bindings ------------------------------------------------------------
# component | action | active | default | friendly name
# "none" as the active binding disables the shortcut. Defaults are preserved as
# written by KWin so System Settings can still offer "reset to default".
SHORTCUTS=(
  # Layout switching lives on Alt+Shift (grp:alt_shift_toggle, see
  # 45-kde-keyboard.sh), so these are redundant. Disable them FIRST: they hold
  # Meta+Alt+K/L, which spatial focus claims further down, and the daemon drops
  # a binding that is still taken when it is applied.
  # These two carry an empty friendly name because that is what Plasma itself
  # stores for them; writing a label here just gets rewritten on the next save.
  "KDE Keyboard Layout Switcher|Switch to Next Keyboard Layout|none|Meta+Alt+K|"
  "KDE Keyboard Layout Switcher|Switch to Last-Used Keyboard Layout|none|Meta+Alt+L|"

  # Free the bare Meta+T / Meta+W for the launchers below by moving the KWin
  # actions that own them onto Meta+Alt+<key>.
  "kwin|Edit Tiles|Meta+Alt+T|Meta+T|Toggle Tiles Editor"
  "kwin|Overview|Meta+Alt+W|Meta+W|Toggle Overview"

  # Preference remaps. Meta+L is intentionally dropped from Lock Session — it is
  # reused just below for vim-style Quick Tile Right.
  "kwin|Window Maximize|Meta+Return;Meta+PgUp|Meta+PgUp|Maximize Window"
  "ksmserver|Lock Session|Ctrl+Alt+O;Screensaver|Meta+L;Screensaver|Lock Session"
  "kwin|Window Close|Alt+F4;Alt+Q|Alt+F4|Close Window"

  # vim-style window tiling: Meta+H/J/K/L alongside the arrow keys.
  "kwin|Window Quick Tile Left|Meta+Left;Meta+H|Meta+Left|Quick Tile Window to the Left"
  "kwin|Window Quick Tile Bottom|Meta+Down;Meta+J|Meta+Down|Quick Tile Window to the Bottom"
  "kwin|Window Quick Tile Top|Meta+Up;Meta+K|Meta+Up|Quick Tile Window to the Top"
  "kwin|Window Quick Tile Right|Meta+Right;Meta+L|Meta+Right|Quick Tile Window to the Right"

  # vim-style desktop navigation. The KDE defaults (Meta+Ctrl+<arrow>) are
  # dropped from the active set but kept in the default field for reference.
  "kwin|Switch One Desktop to the Left|Ctrl+Alt+H;Ctrl+Alt+Left|Meta+Ctrl+Left|Switch One Desktop to the Left"
  "kwin|Switch One Desktop Down|Ctrl+Alt+J;Ctrl+Alt+Down|Meta+Ctrl+Down|Switch One Desktop Down"
  "kwin|Switch One Desktop Up|Ctrl+Alt+K;Ctrl+Alt+Up|Meta+Ctrl+Up|Switch One Desktop Up"
  "kwin|Switch One Desktop to the Right|Ctrl+Alt+L;Ctrl+Alt+Right|Meta+Ctrl+Right|Switch One Desktop to the Right"

  # Move the window to another desktop, same scheme one modifier up.
  "kwin|Window One Desktop to the Left|Meta+Ctrl+Alt+H;Meta+Ctrl+Alt+Left|Meta+Ctrl+Shift+Left|Window One Desktop to the Left"
  "kwin|Window One Desktop Down|Meta+Ctrl+Alt+J;Meta+Ctrl+Alt+Down|Meta+Ctrl+Shift+Down|Window One Desktop Down"
  "kwin|Window One Desktop Up|Meta+Ctrl+Alt+K;Meta+Ctrl+Alt+Up|Meta+Ctrl+Shift+Up|Window One Desktop Up"
  "kwin|Window One Desktop to the Right|Meta+Ctrl+Alt+L;Meta+Ctrl+Alt+Right|Meta+Ctrl+Shift+Right|Window One Desktop to the Right"

  # Move the window to the previous/next screen with Meta+Shift+<h/l or arrow>.
  # H/L follow the usual left/right convention (H = previous/left, L = next/right).
  "kwin|Window to Previous Screen|Meta+Shift+H;Meta+Shift+Left|Meta+Shift+Left|Move Window to Previous Screen"
  "kwin|Window to Next Screen|Meta+Shift+L;Meta+Shift+Right|Meta+Shift+Right|Move Window to Next Screen"

  # Bindings for the spatial-focus KWin script. It registers these actions with
  # no default of its own, so writing them here is what gives them keys at all.
  "kwin|Focus Window Left|Meta+Alt+H|none|Focus Window Left"
  "kwin|Focus Window Down|Meta+Alt+J|none|Focus Window Down"
  "kwin|Focus Window Up|Meta+Alt+K|none|Focus Window Up"
  "kwin|Focus Window Right|Meta+Alt+L|none|Focus Window Right"
)
for i in 1 2 3 4 5 6 7 8 9; do
  SHORTCUTS+=("kwin|Focus Window $i|Alt+$i|none|Focus Window $i")
done

for entry in "${SHORTCUTS[@]}"; do
  IFS='|' read -r component action active default friendly <<<"$entry"
  apply "$component" "$action" "$active" "$default" "$friendly"
done

# --- application launch shortcuts on the freed keys -------------------------
# Under [services][<desktop-id>.desktop], _launch MUST be a BARE key sequence,
# exactly as System Settings writes it — the 3-field "key,default,friendly" form
# shows up in the UI but the grab is never installed.
#
# The daemon builds a component per [services] entry at startup, so a launcher
# that is not in the file yet cannot be pushed live and needs the next login.
# Resolve the desktop id first: the same app ships under different ids depending
# on packaging (Firefox is firefox.desktop as a deb, firefox_firefox.desktop as
# a snap), and a shortcut on an id that resolves to nothing silently does nothing.
IFS=':' read -r -a XDG_APP_DIRS \
  <<<"${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

desktop_path() {
  local dir
  for dir in "${XDG_APP_DIRS[@]}"; do
    [ -e "$dir/applications/$1" ] && { printf '%s\n' "$dir/applications/$1"; return 0; }
  done
  return 1
}

desktop_id() {
  local candidate
  for candidate in "$@"; do
    desktop_path "$candidate" >/dev/null && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

# The entry's Name=, which is how Plasma labels both the component and its
# _launch action in the shortcuts UI. Done in one awk so no pipe can trip
# pipefail on an early exit.
desktop_name() {
  local path
  path="$(desktop_path "$1")" || return 1
  awk '/^\[Desktop Entry\]/ { in_entry = 1; next }
       /^\[/               { in_entry = 0 }
       in_entry && /^Name=/ { print substr($0, 6); exit }' "$path"
}

launcher() {
  local keys="$1"; shift
  local id candidate name
  if ! id="$(desktop_id "$@")"; then
    if [ "$CHECK" = "1" ]; then
      FAILED=$((FAILED + 1)); CHECKED=$((CHECKED + 1))
      printf '\033[1;31m  ✗\033[0m %-34s no desktop entry among: %s\n' "$keys" "$*"
    else
      log "no desktop entry found for $* — skipping its $keys shortcut"
    fi
    return 0
  fi
  if [ "$CHECK" = "1" ]; then
    check_live "$id" "_launch" "$keys"
    return 0
  fi
  # Clear any binding left on a candidate we did not pick, so re-running after a
  # repackaging (snap <-> deb changes the id) cannot leave two entries fighting
  # over the same key.
  for candidate in "$@"; do
    [ "$candidate" = "$id" ] && continue
    kwriteconfig6 --file "$FILE" --group services --group "$candidate" \
      --key "_launch" --delete 2>/dev/null || true
  done
  kwriteconfig6 --file "$FILE" --group services --group "$id" --key "_launch" "$keys"
  if [ "$LIVE" = "1" ]; then
    # The daemon builds its launcher components from the [services] entries it
    # saw at startup, so one added just now is unknown to it and setting a key
    # on it would silently do nothing. doRegister builds the component from the
    # desktop id first; the daemon reads the entry itself, so this stays a real
    # launcher (it runs the app) rather than a stub bound to our D-Bus call.
    name="$(desktop_name "$id")" || name="$id"
    busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel \
      doRegister as 4 "$id" "_launch" "$name" "$name" >/dev/null 2>&1 || true
    set_live "$id" "_launch" "$keys"
  fi
  return 0
}

launcher "Meta+T"     alacritty-tmux.desktop           # alacritty running tmux (stowed)
launcher "Ctrl+Alt+T" Alacritty.desktop alacritty.desktop
launcher "Meta+W"     firefox_firefox.desktop firefox.desktop firefox-esr.desktop
# Free Ctrl+Alt+T from Konsole's built-in launcher default.
launcher "none"       org.kde.konsole.desktop

if [ "$CHECK" = "1" ]; then
  if [ "$FAILED" = "0" ]; then
    log "all $CHECKED shortcuts are live in this session"
  else
    printf '\033[1;31m!!\033[0m %s of %s shortcuts are not active in this session\n' \
      "$FAILED" "$CHECKED" >&2
    exit 1
  fi
elif [ "$LIVE" = "1" ]; then
  log "wrote shortcuts to $SRC and applied them to the running session"
else
  log "wrote shortcuts to $SRC — they load at the next login"
fi

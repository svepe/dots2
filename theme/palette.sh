# shellcheck shell=bash disable=SC2034
#
# Color palette — single source of truth for the whole repo.
#
# Neutral (untinted) greys for backgrounds and foregrounds, with Tokyo Night
# hues used only for accents. Carries over the old setup's real intent: neutral
# surfaces (#1c1c1c / #121212) rather than Tokyo Night's blue-tinted #1a1b26,
# and drops the leftover warm Monokai foreground (#f8f8f2) for a neutral white.
#
# BUILD-TIME / REFERENCE ONLY. Do NOT source this from .bashrc/.profile — it is
# meant to be read by humans and sourced only by theme/generator scripts (e.g.
# tmux-powerline), always in their own process. Variables are intentionally NOT
# exported, so they never leak into child processes or your interactive shell.

# --- neutral surfaces (backgrounds) -----------------------------------------
C_BG="#1c1c1c"          # main background
C_BG_DARK="#121212"     # darker surface (window bg, inactive panes)
C_BG_HIGHLIGHT="#3a3a3a" # selection / highlighted line
C_GREY="#4e4e4e"        # borders, subtle separators, dim segments

# --- neutral foregrounds ----------------------------------------------------
C_FG="#f8f8f8"          # main foreground (neutral white)
C_FG_DIM="#cccccc"      # secondary text
C_MUTED="#a0a0a0"       # muted / bold-dim
C_COMMENT="#6c6c6c"     # comments, disabled text

# --- accents (Tokyo Night hues) ---------------------------------------------
C_RED="#f7768e"
C_ORANGE="#ff9e64"
C_YELLOW="#e0af68"
C_GREEN="#9ece6a"
C_CYAN="#7dcfff"
C_BLUE="#7aa2f7"
C_PURPLE="#9d7cd8"
C_MAGENTA="#bb9af7"
C_HOTPINK="#ff007c"     # strong accent (marks, errors)

# --- ANSI 16 (terminal emulators) -------------------------------------------
# Neutral black/white, Tokyo Night accents, distinct bright variants.
C_ANSI0="#1c1c1c"   # black          (neutral)
C_ANSI1="#f7768e"   # red
C_ANSI2="#9ece6a"   # green
C_ANSI3="#e0af68"   # yellow
C_ANSI4="#7aa2f7"   # blue
C_ANSI5="#bb9af7"   # magenta
C_ANSI6="#7dcfff"   # cyan
C_ANSI7="#cccccc"   # white          (neutral)
C_ANSI8="#4e4e4e"   # bright black    (neutral grey)
C_ANSI9="#ff899d"   # bright red
C_ANSI10="#9fe044"  # bright green
C_ANSI11="#faba4a"  # bright yellow
C_ANSI12="#8db0ff"  # bright blue
C_ANSI13="#c7a9ff"  # bright magenta
C_ANSI14="#a4daff"  # bright cyan
C_ANSI15="#f8f8f8"  # bright white    (neutral)

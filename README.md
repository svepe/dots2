# dots2

My dotfiles, managed with [GNU stow](https://www.gnu.org/software/stow/).
Desktop-specific bits (KDE) are applied only where available.

## Fresh machine

```
curl -fsSL https://raw.githubusercontent.com/svepe/dots2/main/bootstrap.sh | bash
```

Installs deps, clones to `~/Projects/dots2`, runs `install.sh`. Safe to re-run.

## Status

| # | Task | Status |
|---|------|--------|
| 1 | Repo structure + bootstrap/install | ✅ done |
| 2 | Color theme (carry over from old config) | ✅ done |
| 3 | Bash shell config | ✅ done |
| 4 | Git config | 🚫 won't do |
| 5 | Fonts (incl. MonoLisa) | ✅ done |
| 6 | Terminal emulator config (alacritty/ghostty) | ✅ done |
| 7 | Tmux + prompt (starship) | ✅ done |
| 8 | Neovim config from scratch | ✅ done |
| 9 | Atuin (shell history) | ☐ todo |
| 10 | Keyboard shortcuts (KDE global) | ✅ done |
| 11 | Desktop environment appearance (KDE/Plasma) | 🔨 wip |

## Tasks

### 1. Repo structure + bootstrap/install
Decide the dotfiles management approach and lay out the repo. Write a bootstrap/install path for a fresh machine.

_Decisions:_
- **GNU stow** for symlink management — each app is a package directory mirroring `$HOME`; `stow <pkg>` links it into place. Chosen over bare-repo / chezmoi as a low-overhead middle ground.
- `bootstrap.sh` — curl-able fresh-machine entry: installs deps (git, stow, curl), clones the repo, runs `install.sh`.
- `install.sh` — stows the packages in `STOW_PACKAGES[]`, then runs every `scripts/*.sh` in order. Idempotent (`stow --restow`).
- `scripts/` — imperative installers for what symlinks can't do (fonts, atuin, KDE import); `NN-` prefix controls order.
- `system/` — root-owned config drop-ins, not stowed; each installed with `sudo` by its script (validated first): keyd (`system/keyd/`, `scripts/70-keyd.sh`) and sudoers (`system/sudoers.d/`, `scripts/75-sudoers.sh`).
- Scripts use `apt-get`, not `apt` (apt's CLI isn't script-stable).
- KDE/Plasma configs (#10, #11) will use export/import, not stow — Plasma rewrites those files in place and clobbers symlinks.

### 2. Color theme (carry over from old config)
Define the core palette as a single source of truth referenced by every tool.

_Decisions:_
- **Neutral surfaces + Tokyo Night accents.** The old repo's real intent was neutral backgrounds (`#1c1c1c` / `#121212`), not Tokyo Night's blue-tinted `#1a1b26`; and its foreground was a leftover warm Monokai `#f8f8f2`. We keep neutral bg and switch to a neutral fg (`#f8f8f8`), with Tokyo Night hues for accents only.
- **`theme/palette.sh`** — the single source of truth. Plain (non-exported) shell vars; build-time/reference only, never sourced from `.bashrc`.
- **Generated, not hand-copied.** `theme/generate.sh` is a thin driver that runs each package's `generate-theme.sh` (colocated with the tool), which sources the palette and emits the tool's color file (e.g. `alacritty/.config/alacritty/colors.toml`). Generated files are committed and carry a DO-NOT-EDIT header.
- `install.sh` regenerates themed configs before stowing; per-package `generate-theme.sh` is excluded from stow via `--ignore`.
- Applied to alacritty as the first consumer (see #6).

### 3. Bash shell config
Base shell setup: aliases, PATH, env vars, shell options, history. Separate from the prompt. Currently mostly stock Kubuntu `.bashrc` + a `.local/bin` PATH line.

_Decisions:_
- Stock `~/.bashrc` is left intact; customizations live in a sourced fragment **`bash/.config/bash/dots.bash`** (stow package `bash`), wired in by **`scripts/10-bash.sh`** via a guarded source line.
- **vi mode** (`set -o vi`); the prompt shows vi normal mode via starship's character (#7).
- **History**: `HISTSIZE`/`HISTFILESIZE=1000000`, `HISTCONTROL=ignoreboth`, `histappend` + `cmdhist` + `checkwinsize`, and `PROMPT_COMMAND='history -a'` so each command is written to the history file immediately — history survives crashes / non-clean exits, not just clean logouts.
- The starship + bash-preexec wiring (start-time preexec hook + `starship init`) lives here, moved out of #7's stopgap `.bashrc` block; `scripts/35-starship.sh` now only installs the binaries.

### 4. Git config
Won't do — git identity/config is managed outside the dotfiles (multiple
accounts, set per-machine/per-repo).

### 5. Fonts (incl. MonoLisa)
Install and configure fonts: MonoLisa for coding, plus a Nerd Font for icons/powerline glyphs. Reference old dots `install_fonts.sh` + `fonts.conf`.

_Decisions:_
- **MonoLisa is patched with Nerd Font glyphs** rather than paired with a fallback font. A fallback (e.g. Symbols Nerd Font Mono) renders the extra glyphs at *text* height — the rounded/pixel powerline separators come out too small — whereas a patched font draws them at full cell height. Only MonoLisa's built-in arrow separators (`E0B0`–`E0B3`) were full-size before patching.
- MonoLisa is licensed, so the originals and the patched output live in **`private/`** (fetched by **`scripts/20-private.sh`** from a private repo; never committed here).
- **Patch workflow:** drop static MonoLisaCode weights (Regular/Bold/Italic/BoldItalic) in `private/monolisa-src/`, patch with [`daylinmorgan/monolisa-nerdfont-patch`](https://github.com/daylinmorgan/monolisa-nerdfont-patch) (needs `fontforge`; `make patch`), output to `private/fonts/patched/`. Resulting family: **MonoLisaCode Nerd Font**.
- **`scripts/30-fonts.sh`** installs `private/fonts/patched/*` into `~/.local/share/fonts` and sets the KDE monospace font (`kdeglobals fixed`) to the patched family when present. alacritty (#6) points at the same family.

### 6. Terminal emulator config (alacritty/ghostty)
Configure the primary terminal (alacritty and/or ghostty, both installed). Applies color theme, font, and keybindings. Decide which terminal is primary.

_Decisions:_
- **Alacritty** is primary. Stow package `alacritty/.config/alacritty/`; colors from the generated `colors.toml` (see #2), font **MonoLisaCode Nerd Font** (see #5) at alacritty's default size. No fallback font needed — the patched font is self-contained.

### 7. Tmux + prompt (starship)
Set up tmux (refresh `tmux.conf` from old dots). Research and decide on prompt: starship vs tmux-powerline vs other. Old config used starship + tmux-powerline.

_Decisions:_
- **tmux** — stow package `tmux` (XDG `~/.config/tmux/`): prefix `C-a`, vi mode + vi copy bindings. **`scripts/40-tmux.sh`** installs it via `apt` (not the old appimage) plus tpm, plugins, and the compiled `tmux-mem-cpu-load`.
  - Plugins: tpm, sensible, yank, pain-control, vim-tmux-navigator, extrakto, tmux-mem-cpu-load, resurrect + continuum (periodic auto-save, **no** auto-restore on start).
  - **Status bar is hand-rolled** and palette-themed (`tmux/generate-theme.sh` → `theme.conf`): `session │ windows │ cpu·mem · disk / · host` with powerline separators — replacing the slow, fork-per-segment tmux-powerline.
- **starship** — stow package `starship`; **`scripts/35-starship.sh`** installs it to `~/.local/bin` and bash-preexec, and appends a guarded `.bashrc` block (stopgap until #3 owns `.bashrc`). Palette synced in place by `starship/generate-theme.sh` (its glyphs are preserved, only `color_*` lines are rewritten).
  - Replaced the wall-clock `time` module with the **command start time** — a `bash-preexec` hook stamps `STARSHIP_CMD_START` at the moment a command runs. bash has no native preexec, which is exactly why this wasn't possible before.
  - Added **`cmd_duration`** (with `show_milliseconds`) for how long the last command took.

### 8. Neovim config from scratch
Build a fresh nvim config using **lazy.nvim** (not packer — unmaintained; old config already used lazy). `init.lua` + `lua/` modules. Reference old config but start clean. Apply shared color theme.

_Decisions:_ TBD

### 9. Atuin (shell history)
Install and configure atuin for shell history (search, sync). Integrate with bash. Consider companion CLI tools (fzf, zoxide, ripgrep, fd, bat, eza) here or separately.

_Decisions:_ TBD

### 10. Keyboard shortcuts (KDE global)
Version and configure KDE global keyboard shortcuts (`kglobalshortcutsrc`) and custom key bindings. Decide how to reproducibly apply them on a fresh machine.

_Decisions:_
- Applied imperatively by **`scripts/50-kde-shortcuts.sh`** (via `kwriteconfig6`), not stowed — Plasma rewrites `kglobalshortcutsrc` in place.
- **App-launch shortcuts are the tricky part:** under `[services][<desktop-id>.desktop]`, `_launch` **must** be a **bare** key sequence (e.g. `_launch=Meta+T`), byte-for-byte matching what System Settings writes. The 3-field `active,default,friendly` form shows in the UI but the grab is **never installed** — this was the original bug.
- **When a launcher key collides with a built-in KWin action** (e.g. `Meta+T` = Edit Tiles), remap that action's **active** field (1st of the `active,default,friendly` triple) to a free key — `Edit Tiles=Meta+Alt+T,Meta+T,…` (keep KWin's default in the 2nd field). Disabling it instead (`none,Meta+T,…`) also works if you don't want the action at all.
- Confirmed reproducible from a clean boot: `kwriteconfig6` alone installs the grabs at session start — no GUI/D-Bus step needed.
- **Keyboard input** (input-level, not global shortcuts, but related):
  - `scripts/45-kde-keyboard.sh` → XKB options in `kxkbrc`: `caps:escape`; layouts `us,bg` (Bulgarian phonetic) with `grp:alt_shift_toggle` so `Alt+Shift` cycles them; and `plasmarc [OSD] kbdLayoutChangedEnabled=false` to suppress the layout-change popup.
  - `scripts/70-keyd.sh` → installs `system/keyd/default.conf` to `/etc/keyd/` (needs `sudo`; not stowed, `/etc` is root-owned). Provides what XKB can't on Wayland: dual-role **Caps** (tap Esc / hold Ctrl — supersedes the XKB `caps:escape` fallback) and a **grave nav layer** (hold `` ` `` then `hjkl` / `1..9` → the focus shortcuts, home-row ergonomic). keyd remaps at the evdev layer, so tap/hold works.
  - `Meta+Alt+K/L` are freed for focus by disabling the (single-layout-useless) `Switch to Next/Last-Used Keyboard Layout` shortcuts in `kglobalshortcutsrc`.

_Shortcuts:_

Application launchers
| Shortcut | Launches | Desktop id |
|----------|----------|------------|
| `Meta+T` | Alacritty | `Alacritty.desktop` |
| `Meta+W` | Firefox | `firefox.desktop` |

Window & desktop actions — my binding vs the KDE default. "Default kept?" = whether
the original default still works too (added) or was replaced (its active binding removed).
| Action | My shortcut | KDE default | Default kept? |
|--------|-------------|-------------|:-------------:|
| Quick Tile left | `Meta+H` | `Meta+Left` | ✅ added |
| Quick Tile down | `Meta+J` | `Meta+Down` | ✅ added |
| Quick Tile up | `Meta+K` | `Meta+Up` | ✅ added |
| Quick Tile right | `Meta+L` | `Meta+Right` | ✅ added |
| Maximize window | `Meta+Return` | `Meta+PgUp` | ✅ added |
| Close window | `Alt+Q` | `Alt+F4` | ✅ added |
| Switch desktop L/D/U/R | `Ctrl+Alt+H/J/K/L` or `Ctrl+Alt+<arrow>` | `Meta+Ctrl+<arrow>` | ❌ disabled |
| Move window to desktop L/D/U/R | `Meta+Ctrl+Alt+H/J/K/L` or `Meta+Ctrl+Alt+<arrow>` | `Meta+Ctrl+Shift+<arrow>` | ❌ disabled |
| Edit Tiles (tiling editor) | `Meta+Alt+T` | `Meta+T` | ❌ replaced (freed for Alacritty) |
| Overview | `Meta+Alt+W` | `Meta+W` | ❌ replaced (freed for Firefox) |

Desktop actions use the 3×3 virtual-desktop grid, wrapping around (`kwinrc`: `Number=9`, `Rows=3`, `RollOverDesktops=true`).

Window focus — from the `spatial-focus` KWin script (task 11); the `` ` `` variants come from keyd
| Keys | Action |
|------|--------|
| `Alt+1..9` or hold `` ` ``+`1..9` | Focus the N-th window (left→right, x then y, across all monitors) |
| `Meta+Alt+H/J/K/L` or hold `` ` ``+`hjkl` | Focus the nearest window left/down/up/right |

Session
| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+O` | Lock screen (replaced `Meta+L`, freed for Quick Tile right) |

### 11. Desktop environment appearance (KDE/Plasma)
Capture and reproducibly apply KDE/Plasma appearance: theme, colors, kwin, kdeglobals, panels/applets, gtk theming. Tie into the shared color theme.

_Decisions:_
- **KWin scripts** live in the **`kwin`** stow package (`kwin/.local/share/kwin/scripts/<id>/`, static files → safe to symlink) and are enabled by **`scripts/55-kwin-scripts.sh`** (`kwriteconfig6` sets `[Plugins] <id>Enabled=true` in `kwinrc`). A newly-enabled script only loads on next login (or a manual `loadScript` over the `/Scripting` D-Bus).
- **`borderless-tiled`** — removes window decorations while a window is quick-tiled / maximized / fullscreen, restores them when floating. Plasma 6.6 gotcha: there's no scriptable `quickTileMode` property (only the signal), so tiling is detected via the window's `tile` (non-null leaf tile); maximize via `maximizeMode === 3`. Floating windows report `tile === null`.
- **`spatial-focus`** — keyboard window focus: `Alt+1..9` jumps to the N-th window (spatial order, x then y, across all monitors); `Meta+Alt+H/J/K/L` focuses the nearest window in a direction. Gotcha: kglobalaccel **autoloads** a script shortcut's saved key from `kglobalshortcutsrc` and ignores the code default — so if a key is unavailable at first registration it's saved empty and stays broken. `scripts/50-kde-shortcuts.sh` therefore writes the `Focus Window *` keys explicitly to make them deterministic.
- **Appearance / effects** in **`scripts/60-kde-appearance.sh`** (kwinrc via `kwriteconfig6`), separate from the script-enabler above: **Translucency** (inactive windows 90%, `[Effect-translucency] Inactive=90`); **virtual desktops** (3×3 grid, wrap-around, text-only switch OSD at 400ms).
- **Dolphin** in **`scripts/65-dolphin.sh`** (dolphinrc): no remembered tabs, full-width status bar, hidden menu bar, places-icon size — skipping volatile/env-specific keys.

## Reference

Old dots repo lives at `~/Documents/dots` — mostly obsolete (GNOME-terminal era, zsh-less) but useful as reference for tmux, nvim, starship, and font install scripts.

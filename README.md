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
| 3 | Bash shell config | ☐ todo |
| 4 | Git config | ☐ todo |
| 5 | Fonts (incl. MonoLisa) | ☐ todo |
| 6 | Terminal emulator config (alacritty/ghostty) | ☐ todo |
| 7 | Tmux + prompt (starship?) | ☐ todo |
| 8 | Neovim config from scratch | ☐ todo |
| 9 | Atuin (shell history) | ☐ todo |
| 10 | Keyboard shortcuts (KDE global) | ☐ todo |
| 11 | Desktop environment appearance (KDE/Plasma) | ☐ todo |

## Tasks

### 1. Repo structure + bootstrap/install
Decide the dotfiles management approach and lay out the repo. Write a bootstrap/install path for a fresh machine.

_Decisions:_
- **GNU stow** for symlink management — each app is a package directory mirroring `$HOME`; `stow <pkg>` links it into place. Chosen over bare-repo / chezmoi as a low-overhead middle ground.
- `bootstrap.sh` — curl-able fresh-machine entry: installs deps (git, stow, curl), clones the repo, runs `install.sh`.
- `install.sh` — stows the packages in `STOW_PACKAGES[]`, then runs every `scripts/*.sh` in order. Idempotent (`stow --restow`).
- `scripts/` — imperative installers for what symlinks can't do (fonts, atuin, KDE import); `NN-` prefix controls order.
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

_Decisions:_ TBD

### 4. Git config
Set up `~/.gitconfig`: user identity, aliases, sensible defaults, and a diff pager (e.g. delta). No global gitconfig exists currently.

_Decisions:_ TBD

### 5. Fonts (incl. MonoLisa)
Install and configure fonts: MonoLisa for coding, plus a Nerd Font for icons/powerline glyphs. Reference old dots `install_fonts.sh` + `fonts.conf`.

_Decisions:_ TBD

### 6. Terminal emulator config (alacritty/ghostty)
Configure the primary terminal (alacritty and/or ghostty, both installed). Applies color theme, font, and keybindings. Decide which terminal is primary.

_Decisions:_ TBD

### 7. Tmux + prompt (starship?)
Set up tmux (refresh `tmux.conf` from old dots). Research and decide on prompt: starship vs tmux-powerline vs other. Old config used starship + tmux-powerline.

_Decisions:_ TBD

### 8. Neovim config from scratch
Build a fresh nvim config using **lazy.nvim** (not packer — unmaintained; old config already used lazy). `init.lua` + `lua/` modules. Reference old config but start clean. Apply shared color theme.

_Decisions:_ TBD

### 9. Atuin (shell history)
Install and configure atuin for shell history (search, sync). Integrate with bash. Consider companion CLI tools (fzf, zoxide, ripgrep, fd, bat, eza) here or separately.

_Decisions:_ TBD

### 10. Keyboard shortcuts (KDE global)
Version and configure KDE global keyboard shortcuts (`kglobalshortcutsrc`) and custom key bindings. Decide how to reproducibly apply them on a fresh machine.

_Decisions:_ TBD

### 11. Desktop environment appearance (KDE/Plasma)
Capture and reproducibly apply KDE/Plasma appearance: theme, colors, kwin, kdeglobals, panels/applets, gtk theming. Tie into the shared color theme.

_Decisions:_ TBD

## Reference

Old dots repo lives at `~/Documents/dots` — mostly obsolete (GNOME-terminal era, zsh-less) but useful as reference for tmux, nvim, starship, and font install scripts.

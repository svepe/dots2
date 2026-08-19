# Test VM

A throwaway Kubuntu VM (QEMU/KVM) for running the **complete** dots2 install end
to end and visually inspecting the result — Plasma theme, panel, cursor, fonts,
alacritty, tmux, starship, nvim, keyd, everything. Matches the host: **Kubuntu
26.04 LTS + Plasma 6 Wayland**.

Nothing here is committed except the scripts — the ISO and disk image live in
`test/var/` (gitignored).

## Prerequisites

- QEMU + KVM (`qemu-system-x86_64`, `qemu-img`) and `ovmf` (UEFI firmware).
- Read/write on `/dev/kvm`. On this host your desktop session already gets an
  ACL; if `vm.sh` complains, add yourself once: `sudo usermod -aG kvm "$USER"`
  then re-login.
- ~10 GB free for the ISO + disk (grows to the `DISK_SIZE`, default 40 GB).

## One-time: install the OS

```bash
./test/vm.sh iso        # download + checksum-verify the Kubuntu 26.04 ISO
./test/vm.sh install    # opens a QEMU window; click through Calamares
```

In the installer: pick **Minimal installation**, skip third-party drivers, use
the whole (virtual) disk. Create a user you'll remember. When it finishes,
**power the guest off** (don't reboot into the live session).

Then make the shared repo auto-mount so you never hand-mount it. Boot once with
the share attached (`./test/vm.sh run`) and, in the guest:

```bash
sudo mkdir -p /mnt/dots
echo 'dots  /mnt/dots  9p  trans=virtio,version=9p2000.L,ro,nofail,x-systemd.automount  0  0' \
  | sudo tee -a /etc/fstab
sudo systemctl daemon-reload && sudo mount -a
ls /mnt/dots/test    # sanity check
```

`nofail` keeps boot from hanging if the share isn't attached; `x-systemd.automount`
mounts on first access, dodging any boot-order race with the virtio device.

Power the guest off, then freeze this clean, auto-mounting install as the golden
image you return to between test runs:

```bash
./test/vm.sh snapshot golden     # VM must be off; re-run to refresh it
```

## Each test run: install the dotfiles

```bash
./test/vm.sh run        # boots the install; shares this repo over 9p (read-only)
```

Inside the guest, open Konsole and run:

```bash
/mnt/dots/test/guest-setup.sh
```

That mounts the share, copies the repo to `~/.dots2` (guest-local, so the
host tree is never touched), and runs `./install.sh --private`. The private
MonoLisa fonts ride along in the copy, so no SSH/GitHub access is needed. It will
prompt for `sudo` (apt, keyd, sudoers) — that's expected.

Log out and back into a **Plasma (Wayland)** session to see the appearance/panel
changes, then inspect:

- alacritty (borderless when tiled *and* floating), MonoLisa Nerd Font glyphs
- tmux status bar (icons, RAM in MB, cpu/disk/battery, clock, hostname)
- starship prompt, atuin (`Ctrl+R`)
- nvim: `:checkhealth`, LSP, treesitter highlight, which-key (`<leader>`)
- keyd: Caps → Ctrl/Esc dual-role
- KDE: dark theme, 5×3 virtual desktops, cursor size, custom panel

## Re-testing the installer

To run the install again from a pristine system (VM off):

```bash
./test/vm.sh revert golden
./test/vm.sh run
```

## Clean-room variant (test the real one-liner)

Instead of the 9p share, test exactly what a stranger cloning the public repo
gets. Inside the guest:

```bash
curl -fsSL https://raw.githubusercontent.com/svepe/dots2/main/bootstrap.sh | bash
```

This clones from GitHub. The private fonts step needs SSH access to
`dots2-private`; without a key in the guest it's skipped (fonts fall back to
whatever the font step can do). Use the 9p flow above when you want the fonts.

## Commands

```
./test/vm.sh iso                 download + verify the ISO
./test/vm.sh install             one-time GUI install
./test/vm.sh snapshot [name]     snapshot the disk (VM off; default 'golden')
./test/vm.sh run                 boot the guest, share the repo over 9p
./test/vm.sh revert [name]       roll back to a snapshot (VM off)
./test/vm.sh snapshots           list snapshots
./test/vm.sh clean               delete test/var (ISO + disk)
```

Tunables (env): `RELEASE`, `CPUS`, `RAM_MB`, `DISK_SIZE`, `SSH_PORT`.

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

## Preparing the golden snapshot (one-time)

Build a reusable base image once. After this, every test is just `revert golden`
→ `run` → one command in the guest (see "Each test run"). To recreate the setup
later on a different machine, follow these same steps.

**1. Fetch the ISO** (downloaded + checksum-verified into `test/var/`):

```bash
./test/vm.sh iso
```

**2. Install Kubuntu** — opens a QEMU window running the Calamares installer:

```bash
./test/vm.sh install
```

In the installer: choose **Minimal installation**, skip third-party drivers,
**erase the whole (virtual) disk**, and create a user you'll remember. When it
finishes, **power the guest off** — do not reboot into the live session.

**3. Wire the repo share to auto-mount.** `vm.sh run` shares this repo over 9p
under the mount tag `dots`; a one-line fstab entry mounts it at `/mnt/dots` on
every boot, so testing never hand-mounts. Boot with the share attached:

```bash
./test/vm.sh run
```

then, **in the guest**:

```bash
sudo mkdir -p /mnt/dots
echo 'dots  /mnt/dots  9p  trans=virtio,version=9p2000.L,ro,nofail,x-systemd.automount  0  0' \
  | sudo tee -a /etc/fstab
sudo systemctl daemon-reload && sudo mount -a
ls /mnt/dots/test        # sanity check → lists vm.sh, guest-setup.sh, README.md
```

- `dots` — the 9p `mount_tag` set by `vm.sh run`.
- `ro` — read-only, so the guest can never mutate the host repo.
- `nofail` — don't hang boot if the share isn't attached (e.g. a plain `run`).
- `x-systemd.automount` — mount on first access, avoiding a boot-order race with
  the virtio device.

**4. (Optional) SSH server** — install it now if you want to paste into the guest
from the host (`ssh -p 2222 <user>@localhost`, port forwarded by `vm.sh`):

```bash
sudo apt install -y openssh-server
```

**5. Power off and snapshot** — freeze this clean, auto-mounting install as
`golden`:

```bash
# in the guest:
sudo poweroff
# on the host, once the QEMU window closes:
./test/vm.sh snapshot golden     # VM must be off; re-run any time to refresh it
```

`golden` now holds a pristine Kubuntu with the share wired to auto-mount — you
never touch fstab again.

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

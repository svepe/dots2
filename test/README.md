# Test VM

A throwaway Kubuntu VM (QEMU/KVM) for running the **complete** dots2 install end
to end and visually inspecting the result — Plasma theme, panel, cursor, fonts,
alacritty, tmux, starship, nvim, keyd, everything. Matches the host: **Kubuntu
26.04 LTS + Plasma 6 Wayland**.

Nothing here is committed except the scripts — the ISO and disk image live in
`test/var/` (gitignored).

## Prerequisites

- QEMU + KVM (`qemu-system-x86_64`, `qemu-img`) and `ovmf` (UEFI firmware).
- Read/write on `/dev/kvm`. A desktop session normally gets this through an ACL
  already (`getfacl /dev/kvm` should list you), so group membership is usually
  unnecessary; if `vm.sh` complains, `sudo usermod -aG kvm "$USER"` and re-login.
- `ssh` on the host — the harness drives the guest over it.
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
**erase the whole (virtual) disk**, and create the user **`test`** (that's what
`vm.sh` expects; override with `GUEST_USER=` if you pick another). When it
finishes, **power the guest off** — do not reboot into the live session.

**3. Make the guest drivable from the host.** Everything after this point is
typed commands, so authorize the host to run them over SSH and the rest of the
prep — and every later test run — needs no clicking. **In the guest:**

```bash
sudo apt install -y openssh-server
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-test-nopasswd
```

`vm.sh` forwards host `2222` → guest `22`. NOPASSWD is what lets an unattended
`install.sh` run over SSH: it shells out to sudo repeatedly (apt, keyd, sudoers)
and each call would otherwise block on a password prompt. This is a throwaway
guest with user-mode networking and no port exposed beyond localhost, so the
trade is fine — but it *is* a deviation from a real install, and it lands in the
`golden` snapshot. Nothing in `install.sh` exercises sudo prompting, so it does
not weaken what the run tests.

Then authorize the harness key. `vm.sh` generates it on first use into
`test/var/id_vm` (gitignored, never committed). Mount the share by hand this
once — the permanent fstab entry comes next, over SSH:

```bash
sudo mkdir -p /mnt/dots
sudo mount -t 9p -o trans=virtio,version=9p2000.L,ro dots /mnt/dots
mkdir -p ~/.ssh && cat /mnt/dots/test/var/id_vm.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

Reading the key off the share beats typing 68 characters of base64 — a typo
there fails in a way that looks like a broken VM.

**4. Prepare the guest** — from the *host* now, no guest typing:

```bash
./test/vm.sh prepare
```

That does two things. It wires the 9p share into the guest's fstab, so testing
never hand-mounts again; `vm.sh run` shares this repo under the mount tag `dots`
and the entry mounts it at `/mnt/dots` on every boot. And it sets SDDM to log
straight into a Plasma Wayland session, so a reboot brings up KWin — and with it
the shortcuts daemon — with nobody at the screen. Without autologin an
SSH-driven check after a reboot has no session bus to talk to and cannot tell a
real regression from "nobody has logged in yet".

- `dots` — the 9p `mount_tag` set by `vm.sh run`.
- `ro` — read-only, so the guest can never mutate the host repo.
- `nofail` — don't hang boot if the share isn't attached (e.g. a plain `run`).
- `x-systemd.automount` — mount on first access, avoiding a boot-order race with
  the virtio device.

**5. Power off and snapshot** — freeze this clean, drivable install as `golden`:

```bash
./test/vm.sh ssh sudo poweroff     # or 'sudo poweroff' in the guest
./test/vm.sh snapshot golden       # VM must be off; re-run any time to refresh it
```

`golden` now holds a pristine Kubuntu that auto-mounts the share and accepts the
harness key — you never touch fstab, sshd or the installer again.


## Each test run: install the dotfiles

From the host, start to finish:

```bash
./test/vm.sh run &                               # boot the guest (opens a QEMU window)
./test/vm.sh wait                                # block until it answers SSH
./test/vm.sh ssh /mnt/dots/test/guest-setup.sh   # the full install, unattended
./test/vm.sh ssh sudo reboot; ./test/vm.sh wait  # cold boot
./test/vm.sh check                               # assert the KDE shortcuts are live
```

`guest-setup.sh` copies the repo to `~/.dots2` (guest-local, so the host tree is
never touched) and runs `./install.sh --private`. The private MonoLisa fonts ride
along in the copy, so no GitHub or SSH access is needed. It sudoes freely —
that's what the NOPASSWD line from step 3 buys.

**The reboot before `check` is the point, not a formality.** `check` reads every
binding back out of the shortcuts daemon and exits non-zero naming any that
isn't active. Run against a cold boot it proves the config survived the daemon
writing its in-memory copy over `kglobalshortcutsrc` on the way out — the
regression that once shipped a host with stock defaults everywhere, invisibly,
because nothing asserted it. Run it before the reboot and it passes for the
wrong reason: the installer had just pushed the bindings into the live session.

Then look at the QEMU window for the things a script can't judge:

- alacritty (borderless when tiled *and* floating), MonoLisa Nerd Font glyphs
- tmux status bar (icons, RAM in MB, cpu/disk/battery, clock, hostname)
- starship prompt, atuin (`Ctrl+R`)
- nvim: `:checkhealth`, LSP, treesitter highlight, which-key (`<leader>`)
- keyd: Caps → Ctrl/Esc dual-role
- KDE: dark theme, 5×3 virtual desktops, cursor size, custom panel
- and press a few shortcuts yourself, since `check` only proves the daemon
  agrees — `Meta+T` (alacritty+tmux), `Ctrl+Alt+T` (plain alacritty), `Meta+W`
  (Firefox), `Meta+H`/`Meta+L` (quick tile), `Alt+1` (focus window 1)

## Re-testing the installer

To run the install again from a pristine system (VM off):

```bash
./test/vm.sh revert golden
./test/vm.sh run & ./test/vm.sh wait
```

`golden` already has sshd, the harness key, the automount and autologin baked in,
so this drops you straight back at the "each test run" chain above with nothing
to click.

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
./test/vm.sh wait                block until the guest answers SSH
./test/vm.sh ssh [cmd...]        run a command in the guest (or open a shell)
./test/vm.sh prepare             9p automount + Plasma autologin (over SSH)
./test/vm.sh check               assert the KDE shortcuts are live in the guest
./test/vm.sh revert [name]       roll back to a snapshot (VM off)
./test/vm.sh snapshots           list snapshots
./test/vm.sh clean               delete test/var (ISO + disk)
```

Tunables (env): `RELEASE`, `CPUS`, `RAM_MB`, `DISK_SIZE`, `SSH_PORT`, `GUEST_USER`
(defaults to `test` — the user you create in step 2).

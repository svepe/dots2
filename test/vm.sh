#!/usr/bin/env bash
#
# Kubuntu test VM harness (QEMU/KVM) for exercising the full dots2 install and
# eyeballing the result — theme, panel, fonts, alacritty, tmux, nvim, keyd, etc.
#
# Workflow (see test/README.md for the long version):
#   ./test/vm.sh iso                 # download + verify the Kubuntu ISO
#   ./test/vm.sh install             # click through Calamares once (GUI window)
#   ./test/vm.sh snapshot golden     # freeze the fresh install (VM off)
#   ./test/vm.sh run                 # boot it; shares this repo over 9p
#     ... in the guest: run  /mnt/dots/test/guest-setup.sh  (mount+copy+install)
#   ./test/vm.sh revert golden       # roll back to retest the installer (VM off)
#
# No libvirt/vagrant needed — raw qemu-system-x86_64 with UEFI (OVMF) and an
# accelerated virtio-gpu so the Plasma Wayland guest renders properly.
#
set -euo pipefail

# --- config (override via env) ----------------------------------------------
RELEASE="${RELEASE:-26.04}"          # match the host (Ubuntu/Kubuntu 26.04 LTS)
CPUS="${CPUS:-4}"
RAM_MB="${RAM_MB:-8192}"
DISK_SIZE="${DISK_SIZE:-40G}"
SSH_PORT="${SSH_PORT:-2222}"          # host:2222 -> guest:22 (guest runs sshd)
GUEST_USER="${GUEST_USER:-test}"      # the user created during the Calamares install
VM_NAME="kubuntu-dots-test"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"   # shared into the guest (read-only) over 9p
VAR="$HERE/var"                       # big artifacts live here (gitignored)
DISK="$VAR/disk.qcow2"
NVRAM="$VAR/OVMF_VARS.fd"
SSH_KEY="$VAR/id_vm"                  # harness keypair; authorized once, rides in golden
KNOWN_HOSTS="$VAR/known_hosts"        # per-VM, so reinstalls never trip the host-key check
BASE_URL="https://cdimage.ubuntu.com/kubuntu/releases/${RELEASE}/release"

OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.fd"
OVMF_VARS_TMPL="/usr/share/OVMF/OVMF_VARS_4M.fd"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

iso_path() { ls "$VAR"/kubuntu-*-desktop-amd64.iso 2>/dev/null | head -1; }

require() { command -v "$1" >/dev/null 2>&1 || die "missing '$1' — install it first"; }

preflight() {
  require qemu-system-x86_64; require qemu-img; require curl
  [ -e /dev/kvm ] || die "/dev/kvm missing — enable virtualization (VT-x) in BIOS"
  [ -r /dev/kvm ] && [ -w /dev/kvm ] || err "can't r/w /dev/kvm — add yourself to the 'kvm' group and re-login"
  [ -f "$OVMF_CODE" ] || die "OVMF firmware missing: $OVMF_CODE (sudo apt install ovmf)"
  [ -f "$OVMF_VARS_TMPL" ] || die "OVMF vars template missing: $OVMF_VARS_TMPL"
  mkdir -p "$VAR"
  ensure_key
}

# The guest authorizes this key once during prep (see README step 3) by reading
# the .pub off the 9p share, so it has to exist before the guest first boots.
ensure_key() {
  mkdir -p "$VAR"
  [ -f "$SSH_KEY" ] && return 0
  log "generating harness SSH key: $SSH_KEY"
  ssh-keygen -t ed25519 -N '' -C 'dots2-vm-harness' -f "$SSH_KEY" >/dev/null
}

# BatchMode: we only ever authenticate with the key above, so a guest that has
# not authorized it should fail immediately rather than sit on a password prompt.
guest_ssh() {
  ssh -p "$SSH_PORT" -i "$SSH_KEY" \
      -o IdentitiesOnly=yes -o BatchMode=yes \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile="$KNOWN_HOSTS" \
      -o ConnectTimeout=10 -o LogLevel=ERROR \
      "$GUEST_USER@127.0.0.1" "$@"
}
ssh_preflight() { require ssh; ensure_key; }

# --- subcommands ------------------------------------------------------------
cmd_iso() {
  preflight
  local sums="$VAR/SHA256SUMS"
  log "fetching checksums: $BASE_URL/SHA256SUMS"
  curl -fSL "$BASE_URL/SHA256SUMS" -o "$sums" \
    || die "couldn't fetch SHA256SUMS — is Kubuntu $RELEASE released? try RELEASE=25.10 ./test/vm.sh iso"
  local name
  # Point releases are listed alongside the GA image; take the newest, which is
  # what a fresh install would actually be and keeps the guest's Plasma close to
  # the host's (KDE shortcut behaviour is version-sensitive — see 90-kde-shortcuts.sh).
  name="$(grep -oE '[a-f0-9]{64} \*?kubuntu-[^ ]*-desktop-amd64\.iso' "$sums" \
          | sed -E 's/.*\*?(kubuntu-.*)/\1/' | sort -V | tail -1)"
  [ -n "$name" ] || die "no desktop-amd64 ISO listed in SHA256SUMS"
  local dest="$VAR/$name"
  if [ -f "$dest" ]; then log "ISO already present: $dest"; else
    log "downloading $name (~4-5 GB, resumable)"
    curl -fL -C - "$BASE_URL/$name" -o "$dest"
  fi
  log "verifying sha256"
  ( cd "$VAR" && grep " \*\?$name\$" SHA256SUMS | sha256sum -c - ) \
    || die "checksum FAILED — delete $dest and re-run"
  log "ISO ready: $dest"
}

ensure_disk() {
  if [ ! -f "$DISK" ]; then
    log "creating $DISK_SIZE disk: $DISK"
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE" >/dev/null
  fi
  [ -f "$NVRAM" ] || { log "seeding UEFI NVRAM"; cp "$OVMF_VARS_TMPL" "$NVRAM"; }
}

# Shared qemu args as an array; callers append install-/run-specific bits.
base_qemu() {
  QEMU=(
    qemu-system-x86_64
    -name "$VM_NAME"
    -machine q35,accel=kvm
    -cpu host -smp "$CPUS" -m "$RAM_MB"
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$NVRAM"
    -device virtio-vga-gl -display gtk,gl=on
    -device qemu-xhci -device usb-tablet
    -device virtio-net-pci,netdev=net0
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
    -drive "if=virtio,format=qcow2,file=$DISK"
  )
}

cmd_install() {
  preflight; ensure_disk
  local iso; iso="$(iso_path)" || true
  [ -n "$iso" ] && [ -f "$iso" ] || die "no ISO — run './test/vm.sh iso' first"
  base_qemu
  QEMU+=(-cdrom "$iso" -boot menu=on)
  log "booting installer — click through Calamares, then power off the guest"
  log "  (tip: 'Minimal installation', skip third-party drivers to keep it quick)"
  exec "${QEMU[@]}"
}

cmd_run() {
  preflight; ensure_disk
  base_qemu
  # Share this repo read-only over 9p (mount_tag 'dots'); guest copies it out.
  QEMU+=(-virtfs "local,path=$REPO_ROOT,mount_tag=dots,security_model=none,readonly=on")
  log "booting installed guest (repo shared read-only as 9p tag 'dots')"
  log "  in the guest, run:  /mnt/dots/test/guest-setup.sh"
  exec "${QEMU[@]}"
}

cmd_ssh() {
  ssh_preflight
  if [ "$#" -eq 0 ]; then guest_ssh; else guest_ssh "$@"; fi
}

cmd_wait() {
  ssh_preflight
  local i
  for i in $(seq 1 60); do
    guest_ssh true 2>/dev/null && { log "guest reachable over ssh"; return 0; }
    sleep 5
  done
  die "guest not reachable on :$SSH_PORT after 5 min — is it booted, and has it
authorized $SSH_KEY.pub? (README step 3)"
}

# Make the guest self-sufficient, from the host. Idempotent: re-running after a
# revert, or against an already-prepared guest, changes nothing.
#
#   fstab     — the 9p share auto-mounts at /mnt/dots on every boot
#   autologin — SDDM boots straight into a Plasma Wayland session, so a reboot
#               brings up KWin (and with it the shortcuts daemon) with nobody at
#               the screen. Without this, an SSH-driven check after a reboot has
#               no session bus to talk to and cannot tell "broken" from "nobody
#               logged in yet".
cmd_prepare() {
  ssh_preflight
  local entry='dots  /mnt/dots  9p  trans=virtio,version=9p2000.L,ro,nofail,x-systemd.automount  0  0'
  log "preparing the guest (9p automount + Plasma autologin)"
  guest_ssh "set -e
    sudo mkdir -p /mnt/dots
    if grep -qF ' /mnt/dots ' /etc/fstab; then echo 'fstab entry already present'
    else printf '%s\n' '$entry' | sudo tee -a /etc/fstab >/dev/null; echo 'fstab entry added'; fi
    sudo systemctl daemon-reload
    sudo mount -a
    ls /mnt/dots/test >/dev/null && echo 'share mounted: /mnt/dots'

    sudo mkdir -p /etc/sddm.conf.d
    printf '[Autologin]\nUser=%s\nSession=plasma\n' \"\$USER\" \
      | sudo tee /etc/sddm.conf.d/99-autologin.conf >/dev/null
    echo \"autologin set for \$USER (plasma wayland)\""
}

# The shortcut assertion needs the guest's *session* bus, which an SSH login
# does not inherit — point at it explicitly. Requires a logged-in Plasma
# session, which autologin above guarantees after a reboot.
cmd_check() {
  ssh_preflight
  guest_ssh 'export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
             ~/.dots2/scripts/90-kde-shortcuts.sh --check'
}

require_off() {
  # qemu-img refuses to touch a disk a running qemu has open; give a clear hint.
  if pgrep -af "name $VM_NAME" >/dev/null 2>&1; then
    die "the VM is running — power it off before snapshot/revert"
  fi
}

cmd_snapshot() { preflight; require_off; local n="${1:-golden}"
  [ -f "$DISK" ] || die "no disk yet — install first"
  # qemu-img won't replace an existing name — drop it first so re-snapshotting
  # (e.g. after baking the fstab automount into golden) is a single command.
  qemu-img snapshot -l "$DISK" 2>/dev/null | awk '{print $2}' | grep -qx "$n" \
    && { log "replacing existing snapshot '$n'"; qemu-img snapshot -d "$n" "$DISK"; }
  log "snapshot '$n'"; qemu-img snapshot -c "$n" "$DISK"; cmd_snapshots; }

cmd_revert()   { preflight; require_off; local n="${1:-golden}"
  [ -f "$DISK" ] || die "no disk yet"
  log "reverting to '$n'"; qemu-img snapshot -a "$n" "$DISK"; }

cmd_snapshots() { [ -f "$DISK" ] && qemu-img snapshot -l "$DISK" || echo "(no disk)"; }

cmd_clean() {
  read -rp "Delete $VAR (ISO + disk + nvram)? [y/N] " a
  [[ "$a" =~ ^[Yy] ]] && { rm -rf "$VAR"; log "removed $VAR"; } || log "kept $VAR"
}

usage() {
  cat <<EOF
Kubuntu test VM harness

  ./test/vm.sh iso                 download + verify the Kubuntu $RELEASE ISO
  ./test/vm.sh install             boot the installer (one-time GUI install)
  ./test/vm.sh snapshot [name]     snapshot the disk (VM off; default 'golden')
  ./test/vm.sh run                 boot the installed guest, share repo over 9p
  ./test/vm.sh wait                block until the guest answers SSH
  ./test/vm.sh ssh [cmd...]        run a command in the guest (or open a shell)
  ./test/vm.sh prepare             9p automount + Plasma autologin (over SSH)
  ./test/vm.sh check               assert the KDE shortcuts are live in the guest
  ./test/vm.sh revert [name]       roll the disk back to a snapshot (VM off)
  ./test/vm.sh snapshots           list snapshots
  ./test/vm.sh clean               delete test/var (ISO + disk)

Env overrides: RELEASE=$RELEASE CPUS=$CPUS RAM_MB=$RAM_MB DISK_SIZE=$DISK_SIZE
               GUEST_USER=$GUEST_USER SSH_PORT=$SSH_PORT
EOF
}

case "${1:-}" in
  iso)        cmd_iso ;;
  install)    cmd_install ;;
  run)        cmd_run ;;
  wait)       cmd_wait ;;
  ssh)        shift; cmd_ssh "$@" ;;
  prepare)    cmd_prepare ;;
  check)      cmd_check ;;
  snapshot)   shift; cmd_snapshot "$@" ;;
  revert)     shift; cmd_revert "$@" ;;
  snapshots)  cmd_snapshots ;;
  clean)      cmd_clean ;;
  ""|-h|--help|help) usage ;;
  *) err "unknown command: $1"; usage; exit 1 ;;
esac

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
SSH_PORT="${SSH_PORT:-2222}"          # host:2222 -> guest:22 (if you add sshd)
VM_NAME="kubuntu-dots-test"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"   # shared into the guest (read-only) over 9p
VAR="$HERE/var"                       # big artifacts live here (gitignored)
DISK="$VAR/disk.qcow2"
NVRAM="$VAR/OVMF_VARS.fd"
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
}

# --- subcommands ------------------------------------------------------------
cmd_iso() {
  preflight
  local sums="$VAR/SHA256SUMS"
  log "fetching checksums: $BASE_URL/SHA256SUMS"
  curl -fSL "$BASE_URL/SHA256SUMS" -o "$sums" \
    || die "couldn't fetch SHA256SUMS — is Kubuntu $RELEASE released? try RELEASE=25.10 ./test/vm.sh iso"
  local name
  name="$(grep -oE '[a-f0-9]{64} \*?kubuntu-[^ ]*-desktop-amd64\.iso' "$sums" \
          | sed -E 's/.*\*?(kubuntu-.*)/\1/' | head -1)"
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
  ./test/vm.sh revert [name]       roll the disk back to a snapshot (VM off)
  ./test/vm.sh snapshots           list snapshots
  ./test/vm.sh clean               delete test/var (ISO + disk)

Env overrides: RELEASE=$RELEASE CPUS=$CPUS RAM_MB=$RAM_MB DISK_SIZE=$DISK_SIZE
EOF
}

case "${1:-}" in
  iso)        cmd_iso ;;
  install)    cmd_install ;;
  run)        cmd_run ;;
  snapshot)   shift; cmd_snapshot "$@" ;;
  revert)     shift; cmd_revert "$@" ;;
  snapshots)  cmd_snapshots ;;
  clean)      cmd_clean ;;
  ""|-h|--help|help) usage ;;
  *) err "unknown command: $1"; usage; exit 1 ;;
esac

# Maintenance

Periodic upkeep that can't be fully automated. Check in now and then.

## Retire the custom wl-clipboard build

`scripts/15-wl-clipboard.sh` builds **wl-clipboard ≥ 2.3** from source into
`/usr/local/bin` because Ubuntu 26.04 LTS froze at 2.2.1. Versions < 2.3 lack
`ext-data-control-v1`, so on KWin/Wayland they grab the clipboard by spawning a
hidden "fake window" that briefly steals activation — a one-frame flash of the
focused window under any inactive-window effect (translucency/dim). 2.3 uses the
surfaceless protocol, so no window and no flash. Full rationale is in the script
header.

Once the distro archive catches up to ≥ 2.3, the source build is redundant and
should be removed so it isn't carried forever.

**Check** the distro candidate version:

```sh
apt-cache policy wl-clipboard      # look at "Candidate:"
```

**When the candidate is ≥ 2.3:**

1. Remove the source-built copy from `/usr/local`:
   ```sh
   sudo ninja -C <build-dir> uninstall          # if the build tree still exists
   # otherwise remove by hand:
   sudo rm -f /usr/local/bin/wl-copy /usr/local/bin/wl-paste \
              /usr/local/share/man/man1/wl-copy.1 \
              /usr/local/share/man/man1/wl-paste.1
   ```
2. Install the distro package:
   ```sh
   sudo apt install wl-clipboard
   ```
3. Confirm the distro binary is active and new enough:
   ```sh
   hash -r
   command -v wl-copy    # expect /usr/bin/wl-copy
   wl-copy --version     # expect >= 2.3
   ```
4. Delete `scripts/15-wl-clipboard.sh` and remove this section. (The script
   self-skips once `wl-copy` is ≥ 2.3, so leaving it is harmless — but removing
   it keeps the repo honest.)

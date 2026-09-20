# dots

Arch + Hyprland + Quickshell. One repo, every machine.

## Fresh machine

1. Boot Arch ISO. `iwctl` for wifi. `pacman -Sy archlinux-keyring` if packages fail to verify.
2. `archinstall`: btrfs + LUKS on root only, systemd-boot, zram, Minimal profile,
   pipewire, NetworkManager, multilib, extra packages `git base-devel networkmanager vim`.
   No UKI. Hostname must match a folder in `hosts/` (or defaults are used).
3. Reboot. **Before anything else:** `blkid` — root must say `TYPE="crypto_LUKS"`.
   If it says btrfs, archinstall skipped encryption; reinstall.
4. Connect wifi: `nmcli device wifi connect "SSID" password "..."`
5. `git clone https://github.com/paulhmurray/dots.git ~/dots && ~/dots/install.sh`
   HTTPS on purpose: the repo is public, so cloning needs no credentials and a brand new
   machine does not need an SSH key before it can fetch the repo that sets it up.
6. `~/dots/theme/apply.sh` then log out and back in on tty1.

Pulling stays anonymous forever. Pushing needs auth once — see Committing below.

## Committing from a new machine

Reads are anonymous; only writes need credentials. One-time setup:

1. Create a fine-grained token at <https://github.com/settings/personal-access-tokens>,
   scoped to **this repository only**, permission **Contents: Read and write**.
2. `dots auth` — sets `credential.helper=store` for this repo only, not globally,
   so no other repo on the machine starts saving credentials.
3. Push once. Git asks for a username and password: give the username and paste the
   token as the password. It is saved to `~/.git-credentials` and never asked again.

The token is stored in the clear there, so `docs/backup-excludes.txt` keeps that file
out of backups. Losing it costs nothing — make another token.

`dots add <pkg>` then commits and pushes on its own with no prompt.

Scoped deliberately: a token limited to this repo can only ever touch this repo. Do not
use an account-wide token or an SSH key here — this repo is public and nothing in it
should hold credentials that reach anything else.

## Mail

Thunderbird on the `special:mail` scratchpad — `Super+E` shows and hides it, so
it runs in the background and never takes a workspace. Its own notifications are
off; the bar's envelope carries an unread count instead, and nothing else
interrupts.

`theme/apply.sh` writes `userChrome.css` into the Thunderbird profile, so the
mail client follows the machine's theme like everything else. It needs a
Thunderbird restart to take effect.

The unread count comes from `bin/mail-count`, which reads IMAP directly with its
own app password rather than asking Thunderbird — so it is right whether
Thunderbird is running or not, and a Thunderbird upgrade cannot break it. Run
`mail setup` once to create the credential file.

## Machine-local, never committed

- `~/.bashrc.local` — anything naming hosts, IPs or secrets; sourced by `home/.bashrc`
- `~/.config/current-theme` — which theme this machine chose
- `~/.config/dots/location` — one line, the city for the weather widget. Without it
  wttr.in geolocates by IP, which follows a laptop but resolves to the ISP's city.
- `~/.config/dots/mail-account` — IMAP host, address and app password for the
  unread count. Mode 0600. `mail setup` creates it. It is per machine and never
  committed: a public repo cannot hold a credential. An account can use
  `passcmd=pass show mail/you@gmail.com` instead of `pass=`, which leaves no
  secret in the file.

## Music

The bar's play button shuffles the whole library; right-click it (or `Super+M`)
to search and play anything. `Super+N` skips. `Super+Shift+M` shows and hides
Tauon itself over whatever you are doing — it lives on a scratchpad, so it never
takes one of the nine workspaces and never moves you off the one you are on.

`bin/music-art` fills in missing album art as `folder.jpg`, matching the name
the library already uses. It only ever adds — never touches an audio file, skips
folders that already have art, and `music-art --undo` removes everything it
wrote. Compilations, bootlegs and "Unknown Album" folders are deliberately left
alone: a confidently wrong cover is worse than none.

Tauon exposes no MPRIS TrackList or Playlists interface, so it cannot be told
"play my library". `bin/music-index` reads tags with mutagen into
`~/.cache/dots/music.json` (a few seconds for ~2900 tracks) and the bar plays
one track at a time over MPRIS `OpenUri`, handing over just before each track
ends. Re-run `music-index` after adding music.

## Layout

- `packages/`  pacman lists (desktop, system, dev) and `aur.txt`
- `dotfiles/`  symlinked into `~/.config/<name>`
- `home/`      symlinked into `~`
- `hosts/<hostname>/`  packages, monitor config, setup script per machine
- `theme/`     palettes; `apply.sh <name>` regenerates every colour file; `wall.sh` wallpaper
- `wallpapers/<theme>/`  images; empty means solid colour
- `scripts/`   system setup, run by install.sh, must be idempotent

## Snapshots

`snap-pac` snapshots before/after every pacman transaction; `snapper-timeline` hourly.
Snapshots live in a top-level `@snapshots` subvolume mounted at `/.snapshots`, so
swapping the root subvolume never touches them. `sudo snapper list` to see them.

### Something broke but the system boots

    sudo snapper list                       # find the pre-snapshot number N
    sudo snapper -c root undochange N..0    # revert files changed since N

### System won't boot  (tested 16 Sep 2026 on the T470s)

Boot the Arch ISO. Root partition below is the T470s; check `lsblk` elsewhere.

    cryptsetup open /dev/nvme0n1p2 root         # skip on an unencrypted disk
    mount -o subvolid=5 /dev/mapper/root /mnt   # /dev/nvme0n1p2 if unencrypted
    ls /mnt/@snapshots                          # pick snapshot number N
    grep -E "description|date" /mnt/@snapshots/N/info.xml

    mv /mnt/@ /mnt/@broken
    btrfs subvolume snapshot /mnt/@snapshots/N/snapshot /mnt/@
    umount /mnt
    reboot

Do not try to `mv` subvolumes between other subvolumes — btrfs refuses.
The new `@` contains an empty `.snapshots` directory; that is the mount point, leave it.

If a kernel upgrade caused the breakage, the kernel in the EFI partition is
newer than the modules you rolled back to. Before rebooting:

    mount -o subvol=@ /dev/mapper/root /mnt
    mount /dev/nvme0n1p1 /mnt/boot
    arch-chroot /mnt
    pacman -U /var/cache/pacman/pkg/linux-<old version>.pkg.tar.zst
    exit; umount -R /mnt

Once booted and happy, from the running system. systemd creates two nested
subvolumes on first boot; they must go before the parent:

    sudo mount -o subvolid=5 /dev/mapper/root /mnt
    sudo btrfs subvolume delete /mnt/@broken/var/lib/portables /mnt/@broken/var/lib/machines
    sudo btrfs subvolume delete /mnt/@broken
    sudo umount /mnt

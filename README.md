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

Relay, the Flatpak `app.relay.Relay`, on the `special:mail` scratchpad —
`Super+E` shows and hides it, so it runs in the background and never takes a
workspace. Relay only syncs, notifies and fires reminders while its window
exists and has no tray icon, so `mail ensure` starts it hidden at login. Its
notifications are silenced in mako, reminders included; the bar's envelope
carries an unread count instead, and nothing else interrupts.

`mail show` is what the launcher entry and `mailto:` links run: it brings the
scratchpad into view and hands the link to the running window. Relay itself is
installed and kept current by `dots apps` — see below.

The unread count comes from `bin/mail-count`, which reads IMAP directly with its
own app password rather than asking Relay — so it is right whether Relay is
running or not, and a Relay upgrade cannot break it. Run `mail setup` once to
create the credential file.

## Your own apps

Apps you build yourself — Relay now, Cadence next — are part of the machine,
not separate installs. Each is one line in `apps/list`: its private repo, the
release asset, and how to install it. `dots apps` reads each repo's latest
GitHub release, compares it with the tag recorded in
`~/.local/state/dots/apps/`, and downloads and installs only what is newer or
missing. Every `dots sync` runs it, whether or not any dots file changed — a
new release changes nothing in this repo — and so does `install.sh`.

Builds never go in this repo: it is public, and a bundle can carry an OAuth
client. They live in the releases of each app's private repo (Relay publishes
with `make release`). Nothing per machine is shared either: accounts, keyring
entries and app data stay where they are, and each machine signs in once.

Restarting is never automatic. An app updated while its window is open keeps
running the old build; the bar counts that, the Dashboard names the app, and
`dots apps` prints the restart command (for Relay,
`flatpak kill app.relay.Relay && mail`). It clears itself once restarted.

The status timer checks for new releases too, so the bar shows one before you
sync.

### A new machine

Private releases need a credential. Give each machine a read-only token rather
than `gh auth login`, which would hand it every private repo you have:

1. https://github.com/settings/personal-access-tokens — Repository access:
   only the app repos (`paulhmurray/relay`, …); Permissions: Contents →
   Read-only.
2. `dots apps token`, paste it, Ctrl-D. It is stored in
   `~/.config/dots/github-token`, mode 600, never in this repo.
3. `dots apps`.

Until then `dots sync` says so and leaves its window open, rather than
skipping your apps without a word. Adding an app later means adding its repo
to the token as well as a line to `apps/list`.

## Wallpapers

`Super+Shift+T` picks a new one. Images live in `~/Pictures/wallpapers`, not in
this repo — it is public and meant to stay small, and `~/Pictures` is already
carried between machines by Syncthing, so wallpapers follow you for free.

    ~/Pictures/wallpapers/<theme>/   used only while that theme is active
    ~/Pictures/wallpapers/           used whatever the theme

Both are pooled, so an image you like everywhere stays in rotation after you add
theme-specific ones. Consecutive presses never repeat the current image, and an
empty folder says so once rather than silently doing nothing.

Hyprland ships three wallpapers in `/usr/share/hypr/`. They are copied into the
shared folder rather than read from there, so a Hyprland upgrade cannot replace
or remove them, and Syncthing carries them to the other machine.

## News

`Super+N` opens newsboat on its own scratchpad; the Dashboard carries the
latest headlines. Feeds are in `dotfiles/newsboat/urls`, grouped by region.

Most feeds carry only a 100-500 character teaser rather than the article —
that is the publisher driving traffic to their own site, not a setting. Of the
eleven here only The Conversation ships full text. So:

- `o` opens the story in Firefox, hiding the reader first so it is not sitting
  over what you wanted to read
- `v` renders the article as text in the terminal, via Firefox's Reader View as
  a command line tool. Needs `rdrview` (AUR) and `w3m`.

`v` is bound only in the article list and article view, so it cannot fire on the
feed list — there the selection is the publication's front page, not a story.
Press `q` to leave the article and return to newsboat.

`bin/news-read` passes w3m `confirm_qq=false`, and that is not cosmetic. Without
it w3m answers `q` with "Do you want to exit w3m? (y/n)" on the bottom line
only. `q` is not `y`, so holding down `q` never exits and the reader looks
frozen — newsboat is fine underneath, waiting on a prompt that is easy to miss.
It also runs rdrview under `timeout 25`, because rdrview has none of its own and
newsboat has already blanked its UI by the time the fetch starts.

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

MPD plays (a user service; `dotfiles/mpd/mpd.conf`, music in `~/Music`), so
music never depends on a window. mpd-mpris puts it on MPRIS, so media keys and
the bar see it.

Cadence is the window: a Flutter front-end with Relay's look and keys, built
from `~/Projects/cadence` (`make install`, not packaged). `Super+M` shows or
hides it over whatever you are doing with the search box focused;
`Super+Shift+M` pulls it onto this workspace as a tile, and `Super+M` puts it
back. Like Relay it lives on a scratchpad, so it never takes one of the nine
workspaces. `bin/music` is the shell side: `window`, `pane`, `show`, `toggle`,
`next`, `status`.

The bar's play button plays or pauses; with nothing queued it shuffles the
whole library. Right-click opens Cadence's search. `Super+Shift+N` skips and
`Super+Shift+P` plays or pauses.

`bin/music-art` fills in missing album art as `folder.jpg`, matching the name
the library already uses. It only ever adds — never touches an audio file, skips
folders that already have art, and `music-art --undo` removes everything it
wrote. Compilations, bootlegs and "Unknown Album" folders are deliberately left
alone: a confidently wrong cover is worse than none.

Cadence uses those `folder.jpg` files directly, and falls back to art embedded
in the files (fetched once through MPD and cached in `~/.cache/cadence/art`).

## Layout

- `packages/`  pacman lists (desktop, system, dev) and `aur.txt`
- `dotfiles/`  symlinked into `~/.config/<name>`
- `home/`      symlinked into `~`
- `hosts/<hostname>/`  packages, monitor config, setup script per machine
- `theme/`     palettes; `apply.sh <name>` regenerates every colour file; `wall.sh` wallpaper
- `theme/wall.sh`  picks a wallpaper; images live outside the repo (see below)
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

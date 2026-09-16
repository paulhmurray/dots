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
5. `git clone git@github.com:USER/dots.git ~/dots && ~/dots/install.sh`
6. `~/dots/theme/apply.sh` then log out and back in on tty1.

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

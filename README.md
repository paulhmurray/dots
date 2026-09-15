# dots

Arch + Hyprland + Quickshell. One repo, every machine.

## Fresh machine

1. Boot Arch ISO. `iwctl` for wifi. `pacman -Sy archlinux-keyring` if packages fail to verify.
2. `archinstall`: btrfs + LUKS on root only, systemd-boot, zram, Minimal profile,
   pipewire, NetworkManager, multilib, extra packages `git base-devel networkmanager vim`.
   No UKI. Hostname must match a folder in `hosts/` (or defaults are used).
3. Reboot, log in, connect wifi:
   `nmcli device wifi connect "SSID" password "..."`
4. `git clone git@github.com:USER/dots.git ~/dots && ~/dots/install.sh`
5. `~/dots/theme/apply.sh` then log out and back in on tty1.

## Layout

- `packages/`  pacman lists (desktop, system, dev) and `aur.txt`
- `dotfiles/`  symlinked into `~/.config/<name>`
- `home/`      symlinked into `~`
- `hosts/<hostname>/`  packages, monitor config, setup script per machine
- `theme/`     palettes; `apply.sh <name>` regenerates every colour file
- `scripts/`   system setup, run by install.sh, must be idempotent

## Rollback (btrfs + snapper)

Snapshots are taken before/after every pacman transaction (`snap-pac`) and
hourly (`snapper-timeline`). List them: `sudo snapper list`.

### Something broke but the system boots

    sudo snapper list                       # find the pre-snapshot number N
    sudo snapper -c root undochange N..0    # revert files changed since N

### System won't boot

Boot the Arch ISO, then:

    cryptsetup open /dev/nvme0n1p2 root
    mount -o subvolid=5 /dev/mapper/root /mnt
    ls /mnt/@/.snapshots                    # pick snapshot number N
    cat /mnt/@/.snapshots/N/info.xml        # confirm it's the one you want

    mv /mnt/@ /mnt/@broken
    btrfs subvolume snapshot /mnt/@broken/.snapshots/N/snapshot /mnt/@
    mv /mnt/@broken/.snapshots /mnt/@/.snapshots

    umount /mnt
    reboot

If the breakage was a kernel upgrade, the kernel in the EFI partition is
newer than the modules you just rolled back to. Before rebooting:

    mount -o subvol=@ /dev/mapper/root /mnt
    mount /dev/nvme0n1p1 /mnt/boot
    arch-chroot /mnt
    pacman -U /var/cache/pacman/pkg/linux-<old version>.pkg.tar.zst
    exit; umount -R /mnt

Once booted and happy: `sudo btrfs subvolume delete /.snapshots/../@broken`
— or from the ISO, `btrfs subvolume delete /mnt/@broken`.

The disk names above are the T470s. Check with `lsblk` on other machines.

#!/usr/bin/env bash
set -euo pipefail

# A config file proves a config was created, not that this machine is actually
# rollback-safe. The point of the setup below is that /.snapshots is the
# TOP-LEVEL @snapshots subvolume, so swapping the root subvolume leaves the
# snapshots alone. Check for that, not just for the file — otherwise a first
# run that died between create-config and the subvolume swap reports "already
# configured" forever, and the README's recovery procedure quietly does not
# work on this machine.
if [ -f /etc/snapper/configs/root ] \
   && findmnt -n -o SOURCE /.snapshots 2>/dev/null | grep -q '\[/@snapshots\]'; then
    echo "snapper already configured, skipping"
    exit 0
fi

if [ -f /etc/snapper/configs/root ]; then
    cat >&2 <<'WARN'

    WARNING: snapper has a config, but /.snapshots is not the top-level
    @snapshots subvolume. A previous run did not finish.

    Snapshots taken now live inside the root subvolume, so rolling root back
    would take them with it and the recovery procedure in the README will not
    work on this machine. To repair, remove the config and re-run:

        sudo snapper -c root delete-config
        ~/dots/scripts/snapper-setup.sh

WARN
    exit 0
fi

ROOT_DEV=$(findmnt -n -o SOURCE / | sed 's/\[.*//')

# a top-level @snapshots subvolume mounted at /.snapshots survives root rollbacks
if ! findmnt /.snapshots >/dev/null; then
    sudo mount -o subvolid=5 "$ROOT_DEV" /mnt
    [ -d /mnt/@snapshots ] || sudo btrfs subvolume create /mnt/@snapshots
    sudo umount /mnt
    sudo mkdir -p /.snapshots
    grep -q ' /.snapshots ' /etc/fstab || \
        echo "$ROOT_DEV /.snapshots btrfs subvol=/@snapshots 0 0" | sudo tee -a /etc/fstab >/dev/null
    sudo mount /.snapshots
fi

# snapper insists on creating .snapshots itself; let it, then swap ours back in
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount /.snapshots
sudo chmod 750 /.snapshots

sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/;
             s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/;
             s/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/;
             s/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/;
             s/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo snapper -c root create -d "baseline after install"
echo "snapper ready"

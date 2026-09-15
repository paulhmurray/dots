#!/usr/bin/env bash
set -euo pipefail

if [ -f /etc/snapper/configs/root ]; then
    echo "snapper already configured, skipping"
    exit 0
fi

# archinstall mounts @snapshots at /.snapshots; snapper insists on creating it itself
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots

# keep timeline snapshots modest
sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/;
             s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/;
             s/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/;
             s/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/;
             s/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo snapper -c root create -d "baseline after install"
echo "snapper ready"

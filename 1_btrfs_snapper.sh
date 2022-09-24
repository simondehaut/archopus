#!/usr/bin/env bash

PURPLE_LIGHT="\e[1;35m"
PURPLE="\e[35m"
YELLOW="\e[33m"
RED="\e[31m"
GREEN="\e[32m"
RESET_COLOR="\e[0m"

echo "installing snapper..."
pacman -S --noconfirm snapper

echo "configuring snapper..."
umount /.snapshots
rm -rf /.snapshots

snapper -c root create-config /
snapper -c root set-config 'ALLOW_USERS=nomis'

snapper -c root set-config 'TIMELINE_LIMIT_HOURLY=2'
snapper -c root set-config 'TIMELINE_LIMIT_DAILY=7'
snapper -c root set-config 'TIMELINE_LIMIT_WEEKLY=0'
snapper -c root set-config 'TIMELINE_LIMIT_MONTHLY=6'
snapper -c root set-config 'TIMELINE_LIMIT_YEARLY=2'

chmod a+rx /.snapshots/

echo "enabling snapper timeline and cleanup service..."
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

echo "installing snap-pac..."
pacman -S snap-pac

echo "setting up pacman hook to backup /boot before kernel/grub update..."
cat <<EOF > /etc/pacman.d/hooks/50-bootbackup.hook
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = boot/*

[Action]
Depends = rsync
Description = Backing up /boot...
When = PreTransaction
Exec = /usr/bin/rsync -avzq --delete /boot /.bootbackup
EOF

echo -e "$PURPLE"
echo "-- BTRFS SNAPPER OK --"
echo -e "$PURPLE_LIGHT"
echo "YOU SHOULD:"
echo " - check global looking of snapper config in /etc/..."
echo -e "$RESET_COLOR"

#!/usr/bin/env bash

echo "make first snapper snapshot with /boot backup..."
/usr/bin/rsync -avzq --delete /boot /.bootbackup
snapper -c root create --description "afterFirstArchInstall"

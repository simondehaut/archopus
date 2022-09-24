#!/usr/bin/env bash

PURPLE_LIGHT="\e[1;35m"
PURPLE="\e[35m"
YELLOW="\e[33m"
RED="\e[31m"
GREEN="\e[32m"
RESET_COLOR="\e[0m"

echo -e "$PURPLE_LIGHT"
echo "-------------------------------------------------------------------"
echo ""
echo "      ██████████████████████████████████████████████████████"
echo "      ██████████████████████████████████████████████████████"
echo "      ██████████████████████████████████████████████████████"
echo "      █████████▀▄─██▄─▄▄▀█─▄▄▄─█─█─█─▄▄─█▄─▄▄─█▄─██─▄█─▄▄▄▄█"
echo "      █████████─▀─███─▄─▄█─███▀█─▄─█─██─██─▄▄▄██─██─██▄▄▄▄─█"
echo "      ████████▄▄█▄▄█▄▄█▄▄█▄▄▄▄▄█▄█▄█▄▄▄▄█▄▄▄████▄▄▄▄██▄▄▄▄▄█"
echo -e "$PURPLE"
echo ""
echo "nomis arch installer"
echo " - asus ux302l"
echo " - uefi, btrfs root, ext4 home, plasma, nvidia drivers"
echo " - 500GB SSD"
echo ""
echo "-------------------------------------------------------------------"
echo -e "$RESET_COLOR"

echo "loading fr keyboard..."
loadkeys fr

echo "enabling network time synchronization..."
timedatectl set-ntp true

# ask if installation type
echo -e "$YELLOW"
echo "wipe all and clean install (wipe) or" 
echo "reinstall without touching home (reinstall)"
echo "[wipe/resinstall] ?"
echo -e "$RESET_COLOR"
read -r -p "-->" RESPONSE_INSTALL_TYPE
if [[ ! "$RESPONSE_INSTALL_TYPE" =~ ^(wipe|reinstall)$ ]]
then
    echo -e "$RED \n ABORT: choice '$RESPONSE_INSTALL_TYPE' no match \n $RESET_COLOR"
    exit 0
fi

# display partitions
echo ""
lsblk

# ask disk to format
echo ""
echo -e "$YELLOW"
echo "Please enter disk: (example /dev/sda)"
echo -e "$RESET_COLOR"
read -r -p "-->" DISK
if ! [[ "$DISK" =~ ^\/dev\/sd[a-z]$ ]]
then
    echo -e "$RED \n ABORT: '$DISK' wrong pattern \n $RESET_COLOR"
    exit 0
fi

echo "backing up mirrorlist to /etc/pacman.d/mirrorlist.backup for liveusb"
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo "setting up mirrors for optimal download - FR only for liveusb"
pacman -S --noconfirm pacman-contrib
curl -s "https://www.archlinux.org/mirrorlist/?country=FR&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

pacman -Syy

create_new_partition_table () {
    echo "creating new partition table..."
    # disk prep
    sgdisk -Z ${DISK} # destroy gpt partition
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1:0:+1000M ${DISK} # partition 1 (UEFI SYS), default start block, 512MB
    sgdisk -n 2:0:+100G ${DISK} # partition 2 (Root), default start, 100GB
    sgdisk -n 3:0:+8G ${DISK} # partition 3 (Swap), default start, 8GB
    sgdisk -n 4:0:0 ${DISK} # partition 4 (Home), default start, remaining

    # set partition types
    sgdisk -t 1:ef00 ${DISK}
    sgdisk -t 2:8300 ${DISK}
    sgdisk -t 3:8200 ${DISK}
    sgdisk -t 4:8300 ${DISK}

    # label partitions
    sgdisk -c 1:"UEFISYS" ${DISK}
    sgdisk -c 2:"ROOT" ${DISK}
    sgdisk -c 3:"SWAP" ${DISK}
    sgdisk -c 4:"HOME" ${DISK}
}

do_only_root_install () {
    echo "resinstall !!!"
}

# "are you sure" and then partition or abort
if [[ "$RESPONSE_INSTALL_TYPE" =~ ^wipe$ ]]
then
    echo ""
    echo -e "$YELLOW"
    echo "WIPE ALL DISK AND PARTITION TABLE on $DISK,"
    echo "Are you sure? [yes/N]"
    read -r -p "-->" _response
    echo -e "$RESET_COLOR"
    if [[ "$_response" =~ ^yes$ ]]
    then
        create_new_partition_table
    else
        echo -e "$RED \n ABORT \n $RESET_COLOR"
        exit 0
    fi
elif [[ "$RESPONSE_INSTALL_TYPE" =~ ^reinstall$ ]]
then
    echo ""
    echo -e "$YELLOW"
    echo "WIPE ROOT PARTITION AND CLEAN INSTALL, on $DISK"
    echo "Are you sure? [yes/N]"
    read -r -p "-->" _response
    echo -e "$RESET_COLOR"
    if [[ "$_response" =~ ^yes$ ]]
    then
        do_only_root_install
    else
        echo -e "$RED \n ABORT \n $RESET_COLOR"
    exit 0
    fi
fi

# here we assuming to have the right partitions of the right format

echo "formating ${DISK}1 (efi) as fat32..."
mkfs.fat -F32 -n "UEFISYS" /dev/sda1

echo "formating and enabling ${DISK}3 (swap) as swap..."
mkswap /dev/sda3
swapon /dev/sda3

echo "formating ${DISK}2 (home) as btrfs..."
mkfs.btrfs -L "ROOT" /dev/sda2

if [[ "$RESPONSE_INSTALL_TYPE" =~ ^wipe$ ]]
then
    echo "formating ${DISK}4 (home) as ext4..."
    mkfs.ext4 -L "HOME" /dev/sda4
fi

mkdir -p /mnt

echo "temporary mounting root partition to /mnt..."
mount /dev/sda2 /mnt

echo "create btrfs subvolume (@,@var,@opt,@tmp,@.snapshots)..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots

echo "unmounting /mnt..."
umount /mnt

echo "mounting btrfs root subvolume (noatime,compress=zstd,subvol=@)..."
mount -o defaults,ssd,noatime,nodiratime,compress=zstd,subvol=@ /dev/sda2 /mnt

echo "creating boot,home,var,opt,tmp,.snaphots,boot/efi dir..."
mkdir /mnt/{boot,home,var,opt,tmp,.snapshots}
mkdir /mnt/boot/efi

echo "mounting btrfs other subvolumes..."
mount -o defaults,ssd,noatime,nodiratime,compress=zstd,subvol=@opt /dev/sda2 /mnt/opt
mount -o defaults,ssd,noexec,nosuid,nodev,noatime,nodiratime,compress=zstd,subvol=@tmp /dev/sda2 /mnt/tmp
mount -o defaults,ssd,noatime,nodiratime,compress=zstd,subvol=@.snapshots /dev/sda2 /mnt/.snapshots
mount -o defaults,ssd,nodatacow,noatime,nodiratime,compress=zstd,subvol=@var /dev/sda2 /mnt/var

echo "mounting efi partition..."
mount -o ssd,noatime,nodiratime /dev/sda1 /mnt/boot

echo "/home partition..."
mount -o defaults,ssd,noatime,nodiratime /dev/sda4 /mnt/home

echo "pacstraping..."
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo btrfs-progs --noconfirm --needed

echo "generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "chrooting..."
arch-chroot /mnt

echo "setting localtime to Europe/Paris..."
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

echo "setting hardware clock from system clock..."
hwclock --systohc

echo "uncommenting 'en_US.UTF-8 UTF-8' in /etc/locale.gen..."
sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen

echo "uncommenting 'fr_FR.UTF-8 UTF-8' in /etc/locale.gen..."
sed -i '/fr_FR.UTF-8 UTF-8/s/^#//g' /etc/locale.gen

echo "generating locale..."
locale-gen

echo "setting LANG to 'fr_FR.UTF-8'..."
echo 'LANG=fr_FR.UTF-8' >> /etc/locale.conf

echo "setting KEYMAP to 'fr-latin9'..."
echo 'KEYMAP=fr-latin9' >> /etc/vconsole.conf

echo "setting host name to 'arch-nomis'..."
echo 'arch-nomis' >> /etc/hostname

echo "writing in /etc/hosts..."
cat <<EOF >> /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.0.1 arch-nomis.localdomain arch-nomis
EOF

echo "preventing IP spoofs..."
cat <<EOF > /etc/host.conf
order bind,hosts
multi on
EOF

echo "uncommenting '[multilib]' and 'Include ...' in /etc/pacman.conf..."
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo "installing grub, efibootmgr, os-prober..."
pacman -S grub efibootmgr os-prober

echo "grub-install to /boot/efi..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

echo "grub-mkconfig..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "installing some basic pkg and tools..."
# network
pacman -S --noconfirm networkmanager network-manager-applet dhclient
# wifi
pacman -S --noconfirm wireless_tools wpa_supplicant
# linux headers
pacman -S --noconfirm linux-headers 
# bluetooth
pacman -S --noconfirm bluez bluez-utils
# xdg
pacman -S --noconfirm xdg-utils xdg-user-dirs
# miscs
pacman -S --noconfirm dialog reflector rsync

echo "installing tlp..."
pacman -S --noconfirm tlp
echo "starting and enabling tlp.service..."
systemctl start tlp.service
systemctl enable tlp.service

echo "adding kernel parameters to grub..."
# ascii charcode for [!,',"] -> [\x21,\x27,\x22]
KPARAMREPLACEMENTPRE="GRUB_CMDLINE_LINUX_DEFAULT=\x22acpi_osi=\x21Linux acpi_osi=\x27Windows 2013\x27 loglevel=3\x22"
KPARAMREPLACEMENT=$(echo -e "$KPARAMREPLACEMENTPRE")
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/$KPARAMREPLACEMENT/" /etc/default/grub
echo "rebuilbing /boot/grub/grub.cfg after adding kernel params..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "backuping /etc/mkinitcpio.conf to /etc/mkinitcpio.conf.backup"
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
echo "adding 'btrfs' and 'i915' to ramdisk modules..."
sed -i 's/MODULES=()/MODULES=(btrfs i915)/g' /etc/mkinitcpio.conf
echo "mkinitcpio -p linux..."
mkinitcpio -p linux

echo "enabling NetworkManager service..."
system enable NetworkManager

echo "enabling bluetooth service..."
system enable bluetooth

echo "installing firewall..."
pacman -S --noconfirm --needed ufw
echo "enabling ufw.service..."
ufw enable
systemctl enable ufw.service
echo "configuring firewall..."
ufw default deny incoming
ufw default allow outgoing

echo "starting and enabling fstrim.timer for periodic TRIM...."
systemctl start fstrim.timer
systemctl enable fstrim.timer

echo "backing up mirrorlist to /etc/pacman.d/mirrorlist.backup"
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo "setting up mirrors for optimal download - FR only"
curl -s "https://www.archlinux.org/mirrorlist/?country=FR&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

echo "setting swap to init at >= 90% ram filled..."
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf

# asking password for root
echo -e "$YELLOW"
passwd root
echo -e "$RESET_COLOR"

echo "creating 'nomis' user..."
useradd -m -g wheel -c 'nomis' -s /bin/bash nomis
# asking password for 'nomis' user
echo -e "$YELLOW"
passwd nomis
echo -e "$RESET_COLOR"

echo "backuping /etc/sudoers to /etc/sudoers.backup"
cp /etc/sudoers /etc/sudoers.backup
echo "adding wheel group to sudoers..."
# EDITOR=nano visudo
# -> uncomment "#%wheel ALL=(ALL) All"
sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers

# ask if user want 'pacman -Syyu'
echo -e "$YELLOW"
echo "proceed to update and upgrading system ? [yes/NO]"
echo -e "$RESET_COLOR"
read -r -p "-->" RESPONSE_SETUP_WIFI
if [[ ! "$RESPONSE_INSTALL_TYPE" =~ ^yes$ ]]
then
    echo "starting NetworkManager service..."
    system start NetworkManager
    nmtui
fi

echo "enabling syntax highlighting for nano..."
echo 'include "/usr/share/nano/*.nanorc"' >> /etc/nanorc

# ask if user want 'pacman -Syyu'
echo -e "$YELLOW"
echo "proceed to update and upgrading system ? [yes/NO]"
echo -e "$RESET_COLOR"
read -r -p "-->" RESPONSE_UPDATE_UPGRADE
if [[ ! "$RESPONSE_UPDATE_UPGRADE" =~ ^yes$ ]]
then
    pacman -Syyu
fi

echo "exiting chroot..."
exit

echo "unmounting /mnt"
umount -R /mnt

echo -e "$GREEN"
echo "-- INSTALL SETUP OK --"
echo -e "$RESET_COLOR"

echo -e "$PURPLE_LIGHT"
echo "YOU SHOULD:"
echo " - check global looking of /etc/fstab"
echo " - check if 'discard' is NOT a present as mount flag in /etc/fstab"
echo " - check if any in /etc/pacman.d/mirrorlist"
echo " - check quick overview of lsblk"
echo " - check if multilib is properly uncommented in /etc/pacman.conf"
echo " - check kernel boot parameters in /etc/default/grub"
echo " - check MODULES=() in /etc/mkinitcpio.conf"
echo " - check if wheel are sudoers in /etc/sudoers"
echo -e "$PURPLE"
echo "-- SYSTEM READY FOR FIRST BOOT --"
echo -e "$RESET_COLOR"

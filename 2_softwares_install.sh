#!/usr/bin/env bash

PURPLE_LIGHT="\e[1;35m"
PURPLE="\e[35m"
YELLOW="\e[33m"
RED="\e[31m"
GREEN="\e[32m"
RESET_COLOR="\e[0m"

echo "installing linux-lts..."
pacman -S --noconfirm linux-lts linux-lts-headers

echo "installing intel-ucode..."
pacman -S --noconfirm intel-ucode

echo "update grub and initramfs for linux-lts ans intel-ucode..."
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux-lts

echo "installing some utils..."
pacman -S --noconfirm man-db pacman-contrib lsb-release bash-completion git ethtool dos2unix neofetch wget htop traceroute openssh rsync

echo "installing archive relative pkg..."
pacman -S --noconfirm zip unzip p7zip unrar

echo "installing some windows fs relative utils..."
pacman -S --noconfirm ntfs-3g mtools dosfstools exfat-utils

echo "installing audio relative pkg..."
pacman -S --noconfirm alsa-utils
pacman -S --noconfirm gst-plugins-{base,good,bad,ugly} gst-libav
pacman -S --noconfirm pulseaudio pulseaudio-alsa lib32-libpulse
pacman -S --noconfirm lib32-alsa-plugins pulseaudio-bluetooth phonon-qt5

echo "configuring bluetooth..."
usermod -aG lp nomis
echo 'load-module module-bluetooth-policy' >> /etc/pulse/system.pa
echo 'load-module module-bluetooth-discover' >> /etc/pulse/system.pa

echo "installing fonts relative pkg..."
pacman -S --noconfirm ttf-{bitstream-vera,liberation,freefont,dejavu} freetype2
pacman -S --noconfirm bdf-unifont ttf-ubuntu-font-family ttf-roboto ttf-b612
pacman -S --noconfirm ttf-dejavu ttf-liberation ttf-inconsolata texlive-core

#echo "installing printer relative pkg..."
#pacman -S --noconfirm cups 
#pacman -S --noconfirm foomatic-{db,db-ppds,db-gutenprint-ppds,db-nonfree,db-nonfree-ppds} gutenprint
#pacman -S --noconfirm python-pyqt5 hplip

echo "installing intel drivers and utils..."
pacman -S --noconfirm mesa vulkan-intel vulkan-tools mesa-demos
pacman -S --noconfirm lib32-mesa lib32-mesa-demos lib32-vulkan-intel

echo "installing X..."
pacman -S --noconfirm xorg-{server,xinit,apps,xinput} xf86-input-libinput
localectl set-x11-keymap fr

echo "installing nvidia drivers and utils..."
pacman -S --noconfirm xorg-server-devel nvidia-lts
pacman -S --noconfirm nvidia-utils lib32-nvidia-utils
pacman -S --noconfirm opencl-nvidia lib32-opencl-nvidia
pacman -S --noconfirm nvidia-settings nvidia-prime

echo "installing minimal plasma environnement..."
pacman -S --noconfirm plasma-desktop
touch /home/nomis/.xinitrc
echo 'export DESKTOP_SESSION=plasma' >> /home/nomis/.xinitrc
echo 'exec startplasma-x11' >> /home/nomis/.xinitrc
chown nomis /home/nomis/.xinitrc

echo "installing some softwares from plasma environnement..."
pacman -S --noconfirm powerdevil plasma-nm bluedevil plasma-pa kscreen
pacman -S --noconfirm kinfocenter spectacle kate kwrite 
pacman -S --noconfirm dolphin ark konsole kfind plasma-browser-integration
pacman -S --noconfirm xdg-desktop-portal-kde
pacman -S --noconfirm filelight partitionmanager

echo "installing some office and media softwares..."
pacman -S --noconfirm vlc dolphin-emu steam
pacman -S --noconfirm libreoffice-still libreoffice-still-fr
pacman -S --noconfirm gimp kolourpaint inkscape
pacman -S --noconfirm blender ktorrent
pacman -S --noconfirm ghostwriter

echo  "installing node, npm, peerflix..."
pacman -S --noconfirm node-lts-fermium npm
npm -g install --quiet peerflix

echo "installing youtube-dl..."
pacman -S --noconfirm youtube-dl

echo "installing firefox and extensions..."
pacman -S --noconfirm firefox firefox-i18n-fr firefox-adblock-plus firefox-extension-https-everywhere firefox-extension-privacybadger

#echo "installing chromium..."
#pacman -S --noconfirm chromium

echo "installing android tools (adb)..."
pacman -S --noconfirm android-tools

echo "preparing system for E-sync for lutris..."
sed -i 's/# End of file/nomis hard nofile 524288\n#End of file/' /etc/security/limits.conf
echo 'DefaultLimitNOFILE=524288' >> /etc/systemd/system.conf
echo 'DefaultLimitNOFILE=524288' >> /etc/systemd/user.conf

echo "installing gamemode..."
pacman -S --noconfirm gamemode lib32-gamemode
echo "installing lutris..."
pacman -S --noconfirm lutris

#echo "installing wine and gallium nine..."
#pacman -S --noconfirm wine-staging winetricks wine-mono wine-gecko
#pacman -S --noconfirm wine-nine
# check: wine ninewinecfg

echo "pacman: removing orphans pkg..."
pacman --noconfirm -Rns $(pacman -Qtdq)

echo -e "$PURPLE"
echo "-- SOFTWARES INSTALL OK --"
echo -e "$PURPLE_LIGHT"
echo "YOU SHOULD:"
echo " - check end of /etc/security/limits.conf..."
echo -e "$RESET_COLOR"

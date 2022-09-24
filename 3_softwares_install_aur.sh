#!/usr/bin/env bash

PURPLE_LIGHT="\e[1;35m"
PURPLE="\e[35m"
YELLOW="\e[33m"
RED="\e[31m"
GREEN="\e[32m"
RESET_COLOR="\e[0m"

echo "installing yay..."
pacman -S --needed git base-devel
cd /home/nomis/
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

#echo "installing dxvk..."
#yay -S dxvk-bin
#setup_dxvk install

echo "installing scrcpy for android (aur)..."
yay -S scrcpy

echo "installing qview image viewer (aur)..."
yay -S qview

echo "installing some fonts (aur)..."
yay -S ttf-ms-fonts ttf-vista-fonts

echo "installing brave (aur)..."
yay -S brave-bin

echo "installing vscodium and extensions (aur)..."
yay -S vscodium-bin
vscodium --install-extension wayou.vscode-todo-highlight
vscodium --install-extension svelte.svelte-vscode

echo "installing ventoy (aur)..."
yay -S ventoy-bin

echo -e "$PURPLE"
echo "-- SOFTWARES INSTALL AUR OK --"
echo -e "$RESET_COLOR"

#! /usr/bin/bash

pacman -Syu linux-lts linux-lts-headers mkinitcpio openssh systemd-resolvconf

pacman -S nvidia nvidia-dkms nvidia-utils nvidia-settings

sudo cp nvidia/grub /etc/default/grub
sudo cp nvidia/mkinitcpio /etc/mkinitcpio.conf

sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo pacman -S pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber

mkdir ~/.dotfiles
cp -R dotfiles/* ~/.dotfiles

sudo pacman -S hyprland neovim kitty fish rofi swww waybar stow

cd ~/.dotfiles

stow fish kitty nvim rofi wp neofetch hyprland waybar

chsh -s $(which fish)

sudo pacman -S dolphin zip unzip htop locate fuse3 rclone obsidian wl-clipboard syncthing gnome-calculator openvpn gnome-keyring libsecret seahorse lxqt-sudo ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji nodejs npm docker docker-compose nvidia-container-toolkit python-pip dunst libnotify

sudo cp keyring/login /etc/pam.d/login

git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

sudo reboot now

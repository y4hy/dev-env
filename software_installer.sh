#! /usr/bin/bash

sudo pacman -S hyprland neovim kitty fish rofi swww wl-clipboard stow

mkdir ~/.dotfies
cp -R dotfiles/* ~/.dotfiles/

stow fish kitty nvim rofi wp neofetch hyprland

sudo pacman zen-browser dolphin zip unzip htop locate fuse3 rclone obsidian syncthing gnome-calculator openvpn gnome-keyring libsecret seahorse

sudo pacman nodejs npm docker docker-compose nvidia-container-toolkit python-pip

sudo pacman -S ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji



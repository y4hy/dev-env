#! /usr/bin/bash

sudo pacman nvidia-dkms

sudo pacman -S nvidia nvidia-utils nvidia-settings

sudo cp nvidia/grub /etc/default/grub
sudo cp nvidia/mkinitcpio /etc/mkinitcpio.conf

sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo pacman -S pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber

sudo reboot now

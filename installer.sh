#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

#-------------------------------------------------------------------------------
# SYSTEM UPDATE & CORE DEPENDENCIES
#-------------------------------------------------------------------------------
echo "› Updating system and installing essential packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed git base-devel linux-lts linux-lts-headers mkinitcpio openssh systemd-resolvconf

#-------------------------------------------------------------------------------
# AUR HELPER INSTALLATION (yay)
#-------------------------------------------------------------------------------
echo "› Installing AUR helper (yay)..."
if ! command -v yay &> /dev/null; then
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR"
    (cd "$TEMP_DIR" && makepkg -si --noconfirm)
    rm -rf "$TEMP_DIR"
    echo "› yay has been installed."
else
    echo "› yay is already installed."
fi
yay -Syu --noconfirm

#-------------------------------------------------------------------------------
# DRIVERS & AUDIO
#-------------------------------------------------------------------------------
echo "› Installing Graphics and Audio drivers..."

# --- NVIDIA Drivers ---
sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils nvidia-settings nvidia-container-toolkit

# --- Audio - PipeWire ---
sudo pacman -S --noconfirm --needed pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber

#-------------------------------------------------------------------------------
# PACKAGE INSTALLATION (CATEGORIZED)
#-------------------------------------------------------------------------------

# --- Desktop Environment & Core Apps ---
echo "› Installing Desktop Environment and core applications..."
sudo pacman -S --noconfirm --needed \
    hyprland \
    neovim \
    kitty \
    fish \
    rofi \
    swww \
    dunst \
    stow \
    wl-clipboard \
    lxqt-sudo

# --- File Management & System Utilities ---
echo "› Installing file management & system utilities..."
sudo pacman -S --noconfirm --needed \
    dolphin \
    zip \
    unzip \
    htop \
    locate \
    fuse3 \
    rclone \
    syncthing \
    gnome-calculator \
    openvpn \
    libnotify \
    curl

# --- Media Tools ---
echo "› Installing media tools..."
sudo pacman -S --noconfirm --needed vlc

# --- Fonts ---
echo "› Installing fonts..."
sudo pacman -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# --- Development Tools ---
echo "› Installing development tools..."
sudo pacman -S --noconfirm --needed \
    nodejs \
    npm \
    docker \
    docker-compose \
    python-pip

# --- Security & Keyring ---
echo "› Installing security and keyring packages..."
sudo pacman -S --noconfirm --needed \
    gnome-keyring \
    libsecret \
    seahorse

# --- AUR Packages ---
echo "› Installing AUR packages (with yay)..."
yay -S --noconfirm --needed \
    zen-browser-bin \
    obsidian \
    protonvpn-gui

#-------------------------------------------------------------------------------
# PROGRAMMING LANGUAGE SDKs
#-------------------------------------------------------------------------------
echo "› Installing Rust via rustup..."
# The -y flag ensures the installation proceeds with default options without prompting.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Add cargo to the current session's PATH. The shell rc file will handle future sessions.
export PATH="$HOME/.cargo/bin:$PATH"
echo "› Rust has been installed successfully."


#-------------------------------------------------------------------------------
# SYSTEM CONFIGURATION
#-------------------------------------------------------------------------------
echo "› Applying system-level configurations..."

# --- Configure GRUB and mkinitcpio for NVIDIA ---
echo "  -> Copying GRUB and mkinitcpio configs..."
sudo cp nvidia/grub /etc/default/grub
sudo cp nvidia/mkinitcpio /etc/mkinitcpio.conf

echo "  -> Regenerating initramfs and GRUB config..."
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- Configure PAM for GNOME Keyring ---
echo "  -> Setting up PAM for Keyring..."
sudo cp keyring/login /etc/pam.d/login

# --- Configure Git to use libsecret ---
echo "  -> Configuring Git credential helper..."
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

#-------------------------------------------------------------------------------
# USER-LEVEL CONFIGURATION
#-------------------------------------------------------------------------------
echo "› Applying user-level configurations..."

# --- Dotfiles Setup ---
echo "  -> Creating dotfiles directory..."
mkdir -p ~/.dotfiles
cp -R dotfiles/* ~/.dotfiles

echo "  -> Applying configurations with Stow..."
cd ~/.dotfiles
stow fish kitty nvim rofi wp neofetch dunst hyprland

# --- Change Default Shell to Fish ---
if [[ "$(basename "$SHELL")" != "fish" ]]; then
    echo "  -> Changing default shell to Fish..."
    chsh -s "$(which fish)"
else
    echo "  -> Default shell is already Fish."
fi

#-------------------------------------------------------------------------------
# FINALIZATION
#-------------------------------------------------------------------------------
echo ""
echo "✅ System setup is complete!"
echo "It is highly recommended to reboot now to apply all changes."
read -p "Reboot now? (y/N): " choice
case "$choice" in
  y|Y ) sudo reboot now;;
  * ) echo "Please reboot your system manually to apply all changes.";;
esac

#!/bin/bash

# ===============================================================================
# Arch Linux Hyprland Setup Script 
# ===============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# Determine the script's absolute directory to handle relative paths correctly.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#-------------------------------------------------------------------------------
# HELPER FUNCTIONS
#-------------------------------------------------------------------------------
# Function to make section headers more visible
log_header() {
    echo ""
    echo "################################################################################"
    echo "### $1"
    echo "################################################################################"
}

# Function to display important warnings
log_warning() {
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "--> WARNING: $1"
    echo "--> You need to log out and log back in for the changes to take effect."
    echo "--------------------------------------------------------------------------------"
}

#-------------------------------------------------------------------------------
# PRE-RUN CHECKS & SUDO HANDLING
#-------------------------------------------------------------------------------

# Ensure the script is NOT run as root.
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root. It will use 'sudo' to ask for your password when needed."
  exit 1
fi

# Ask for the administrator password upfront and keep it alive.
log_header "Acquiring sudo privileges..."
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


#-------------------------------------------------------------------------------
# INSTALLATION MODE SELECTION
#-------------------------------------------------------------------------------
log_header "Installation Environment"
INSTALL_FOR_VM="false"
read -p "Are you installing on a Virtual Machine (VM)? (y/N): " choice
case "$choice" in
  y|Y )
    INSTALL_FOR_VM="true"
    echo "-> VM installation mode selected. Hardware-specific drivers and tools will be skipped."
    ;;
  * )
    echo "-> Bare-metal installation mode selected. All packages will be installed."
    ;;
esac


#-------------------------------------------------------------------------------
# SYSTEM UPDATE & CORE DEPENDENCIES
#-------------------------------------------------------------------------------
log_header "Updating system and installing core packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed git base-devel linux linux-lts linux-headers linux-lts-headers mkinitcpio openssh systemd-resolvconf

#-------------------------------------------------------------------------------
# AUR HELPER INSTALLATION (paru)
#-------------------------------------------------------------------------------
log_header "Installing AUR helper (paru)..."

install_aur_helper() {
    local name="$1"
    local repo="$2"
    if ! command -v "$name" &> /dev/null; then
        echo "   -> Installing $name..."
        local temp_dir
        temp_dir=$(mktemp -d)
        git clone "https://aur.archlinux.org/${repo}.git" "$temp_dir"
        (cd "$temp_dir" && makepkg -si --noconfirm)
        rm -rf "$temp_dir"
        echo "   -> $name has been installed successfully."
    else
        echo "   -> $name is already installed."
    fi
}

install_aur_helper paru paru

# Update AUR package databases with paru
if command -v paru &> /dev/null; then
    paru -Syu --noconfirm
fi

#-------------------------------------------------------------------------------
# PACKAGE LIST DEFINITIONS
#-------------------------------------------------------------------------------

# --- Official Arch Repositories (Pacman) ---
pacman_packages_base=(
    # Desktop Environment & Core Apps
    hyprland hyprshot neovim kitty fish rofi swww dunst stow wl-clipboard lxqt-sudo less
    imv libreoffice-fresh papirus-icon-theme nwg-look polkit-kde-agent
    # File Management & System Utilities
    tmux nemo file-roller nemo-terminal ffmpegthumbnailer poppler-glib xdg-utils zip unzip
    btop locate fuse3 syncthing gnome-calculator openvpn libnotify curl bat proton-vpn-gtk-app
    # Networking
    networkmanager
    # Media Tools
    vlc
    # Audio - PipeWire
    pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber
    # Fonts
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji
    # Development Tools
    nodejs npm docker docker-compose python-pip
    # Security & Keyring
    gnome-keyring libsecret seahorse
)
pacman_packages_bare_metal=(
    # Graphics Drivers
    nvidia-dkms nvidia-utils nvidia-settings nvidia-container-toolkit
    # Bluetooth
    bluez bluez-utils blueman
    # Virtualization
    qemu-desktop virt-manager libvirt dnsmasq vde2 bridge-utils edk2-ovmf
    # Btrfs Tools
    snapper snap-pac grub-btrfs
)

# --- Arch User Repository (AUR / Paru) ---
aur_packages_base=(
    zen-browser-bin
    obsidian
    opencode-bin
    yaru-colors-gtk-theme
    bibata-cursor-theme
    neofetch
)
aur_packages_bare_metal=(
    # Hardware specific tools
    coolercontrol
)

#-------------------------------------------------------------------------------
# PACKAGE INSTALLATION
#-------------------------------------------------------------------------------

# Combine the Pacman package list
install_pacman_packages=("${pacman_packages_base[@]}")
if [ "$INSTALL_FOR_VM" = "false" ]; then
    echo "-> Adding bare-metal packages to the Pacman list."
    install_pacman_packages+=("${pacman_packages_bare_metal[@]}")
fi

# Combine the AUR package list
install_aur_packages=("${aur_packages_base[@]}")
if [ "$INSTALL_FOR_VM" = "false" ]; then
    echo "-> Adding bare-metal packages to the AUR list."
    install_aur_packages+=("${aur_packages_bare_metal[@]}")
fi

log_header "Installing packages from official repositories (Pacman)..."
sudo pacman -S --noconfirm --needed "${install_pacman_packages[@]}"

log_header "Installing packages from the AUR (Paru)..."
if command -v paru &> /dev/null; then
    paru -S --noconfirm --needed "${install_aur_packages[@]}"
else
    echo "AUR helper 'paru' not found. Skipping AUR package installation." >&2
fi

#-------------------------------------------------------------------------------
# SERVICE & SYSTEM CONFIGURATION
#-------------------------------------------------------------------------------
log_header "Applying system-level configurations..."

# --- Enable Core Services ---
echo "   -> Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager.service

if pacman -Q blueman &>/dev/null; then
    echo "   -> Enabling Bluetooth service..."
    sudo systemctl enable --now bluetooth.service
fi

if command -v coolercontrol &>/dev/null; then
    echo "   -> Starting coolercontrol service..."
    sudo systemctl enable --now coolercontrold.service
fi

# Docker configuration
echo "   -> Configuring and starting Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
log_warning "User $USER has been added to the 'docker' group."

# Libvirt (Virtualization) configuration
if pacman -Q libvirt &>/dev/null; then
    echo "   -> Configuring Libvirt (KVM)..."
    sudo systemctl enable --now libvirtd.service
    sudo usermod -aG libvirt $USER
    log_warning "User $USER has been added to the 'libvirt' group."
    echo "   -> The default virtual network will start on-demand when a VM is launched."
fi

# --- Configure Snapper for Btrfs (BARE-METAL ONLY) ---
if [ "$INSTALL_FOR_VM" = "false" ] && [ "$(stat -f -c %T /)" = "btrfs" ]; then
    log_header "Configuring Snapper for Btrfs snapshots..."
    if [ ! -f /etc/snapper/configs/root ]; then
        echo "   -> Snapper config not found. Proceeding with setup..."
        sudo snapper -c root create-config /
    else
        echo "   -> Existing Snapper config found. No action needed."
    fi
    echo "   -> Enabling Snapper services..."
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
    sudo systemctl enable --now grub-btrfsd.service
else
    echo "-> Skipping Snapper setup (Not a bare-metal Btrfs system)."
fi

# --- Configure GRUB and mkinitcpio for NVIDIA ---
if [ "$INSTALL_FOR_VM" = "false" ] && pacman -Q nvidia-dkms &>/dev/null; then
    echo "   -> Configuring GRUB and mkinitcpio for NVIDIA..."
    # ... (Your existing NVIDIA config logic can remain here) ...
    echo "   -> Regenerating initramfs and GRUB config..."
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "   -> Skipping NVIDIA-specific GRUB and mkinitcpio configuration."
fi

# --- Configure PAM for GNOME Keyring ---
echo "   -> Setting up PAM for Keyring..."

# --- Configure Git to use libsecret ---
echo "   -> Configuring Git credential helper..."
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret


#-------------------------------------------------------------------------------
# PROGRAMMING LANGUAGE SDKs
#-------------------------------------------------------------------------------
log_header "Installing Rust via rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
rustup component add rust-analyzer
echo "   -> Rust has been installed successfully."


#-------------------------------------------------------------------------------
# USER-LEVEL CONFIGURATION
#-------------------------------------------------------------------------------
log_header "Applying user-level configurations..."

# --- Dotfiles Setup ---
echo "   -> Creating dotfiles directory..."
mkdir -p ~/.dotfiles
cp -R "$SCRIPT_DIR/dotfiles/"* ~/.dotfiles

echo "   -> Applying configurations with Stow..."
rm -rf ~/.config/fish ~/.config/hypr
(cd ~/.dotfiles && stow fish kitty nvim rofi wp neofetch dunst hyprland opencode tmux)

# --- Set GTK Theme (Yaru) ---
echo "   -> Setting GTK theme, icons, and cursor..."
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-Grey-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# --- Tmux Plugin Manager (TPM) Setup ---
echo "   -> Setting up Tmux Plugin Manager (TPM) and plugins..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
"$TPM_DIR/bin/install_plugins" &

# --- Change Default Shell to Fish ---
if [[ "$(basename "$SHELL")" != "fish" ]]; then
    echo "   -> Changing default shell to Fish..."
    sudo chsh -s "$(which fish)"
else
    echo "   -> Default shell is already Fish."
fi

# --- Set Nemo as Default File Manager ---
echo "   -> Setting Nemo as the default file manager..."
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

#-------------------------------------------------------------------------------
# FINALIZATION
#-------------------------------------------------------------------------------
echo ""
echo "================================================================================"
echo "✅ System setup is complete!"
echo ""
echo "   IMPORTANT NOTES & NEXT STEPS:"
echo "   - To apply group changes (Docker, Libvirt), you MUST LOG OUT and LOG BACK IN."
echo "   - It is highly recommended to REBOOT to apply all changes (kernel, drivers, etc.)."
echo "================================================================================"
echo ""
read -p "Reboot now? (y/N): " choice
case "$choice" in
  y|Y ) sudo reboot now;;
  * ) echo "Please reboot your system manually to apply all changes.";;
esac

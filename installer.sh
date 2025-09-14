#!/bin/bash

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
# SYSTEM UPDATE & CORE DEPENDENCIES
#-------------------------------------------------------------------------------
log_header "Updating system and installing core packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed git base-devel linux linux-lts linux-headers linux-lts-headers mkinitcpio openssh systemd-resolvconf

#-------------------------------------------------------------------------------
# AUR HELPERS INSTALLATION (yay & paru)
#-------------------------------------------------------------------------------
log_header "Installing AUR helpers (yay / paru)..."

install_aur_helper() {
    local name="$1"
    local repo="$2"
    if ! command -v "$name" &> /dev/null; then
        echo "  -> Installing $name..."
        local temp_dir
        temp_dir=$(mktemp -d)
        git clone "https://aur.archlinux.org/${repo}.git" "$temp_dir"
        (cd "$temp_dir" && makepkg -si --noconfirm)
        rm -rf "$temp_dir"
        echo "  -> $name has been installed successfully."
    else
        echo "  -> $name is already installed."
    fi
}

install_aur_helper yay yay
install_aur_helper paru paru

# Update AUR package databases (prefer paru if present)
if command -v paru &> /dev/null; then
    paru -Syu --noconfirm
elif command -v yay &> /dev/null; then
    yay -Syu --noconfirm
fi

#-------------------------------------------------------------------------------
# DRIVERS & AUDIO
#-------------------------------------------------------------------------------
log_header "Installing Graphics and Audio drivers..."

# --- NVIDIA Drivers ---
sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils nvidia-settings nvidia-container-toolkit

# --- Audio - PipeWire ---
sudo pacman -S --noconfirm --needed pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber

#-------------------------------------------------------------------------------
# PACKAGE INSTALLATION (CATEGORIZED)
#-------------------------------------------------------------------------------

# --- Desktop Environment & Core Apps ---
log_header "Installing Desktop Environment and core applications..."
sudo pacman -S --noconfirm --needed \
    hyprland hyprshot \
    neovim \
    kitty \
    fish \
    rofi \
    swww \
    dunst \
    stow \
    wl-clipboard \
    lxqt-sudo \
    less \
    imv \
    libreoffice-fresh

# --- File Management & System Utilities ---
log_header "Installing file management & system utilities..."
sudo pacman -S --noconfirm --needed \
    tmux \
    nemo \
    xdg-utils \
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
    curl \
    bat \
    proton-vpn-gtk-app

# --- Snapshot & Backup (Snapper for Btrfs) ---
log_header "Installing Snapper for Btrfs snapshots..."
sudo pacman -S --noconfirm --needed snapper snap-pac grub-btrfs

# --- Virtualization ---
log_header "Installing Virtualization tools (KVM/QEMU/Libvirt)..."
sudo pacman -S --noconfirm --needed \
    qemu-desktop \
    virt-manager \
    libvirt \
    dnsmasq \
    vde2 \
    bridge-utils \
    edk2-ovmf

# --- Media Tools ---
log_header "Installing media tools..."
sudo pacman -S --noconfirm --needed vlc

# --- Fonts ---
log_header "Installing fonts..."
sudo pacman -S --noconfirm --needed \
    ttf-dejavu \
    ttf-liberation \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# --- Development Tools ---
log_header "Installing development tools..."
sudo pacman -S --noconfirm --needed \
    nodejs \
    npm \
    docker \
    docker-compose \
    python-pip

# --- Security & Keyring ---
log_header "Installing security and keyring packages..."
sudo pacman -S --noconfirm --needed \
    gnome-keyring \
    libsecret \
    seahorse

# --- AUR Packages ---
log_header "Installing AUR packages (with paru/yay)..."
AUR_HELPER=""
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    echo "No AUR helper available (yay/paru). Skipping AUR package install." >&2
fi

if [ -n "$AUR_HELPER" ]; then
    $AUR_HELPER -S --noconfirm --needed \
        zen-browser-bin \
        obsidian \
        nordic-theme \
        neofetch \
        opencode
fi

#-------------------------------------------------------------------------------
# SERVICE & SYSTEM CONFIGURATION
#-------------------------------------------------------------------------------
log_header "Applying system-level configurations..."

# --- Configure Docker ---
echo "  -> Configuring and starting Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
log_warning "User $USER has been added to the 'docker' group."

# --- Configure Libvirt for Virtualization ---
echo "  -> Configuring Libvirt (KVM)..."
sudo systemctl enable --now libvirtd.service
sudo usermod -aG libvirt $USER
log_warning "User $USER has been added to the 'libvirt' group."
echo "  -> The default virtual network will start on-demand when a VM is launched."

# --- Configure Snapper for Btrfs Snapshots ---
echo "  -> Setting up Snapper..."
# Check if the root filesystem is Btrfs before proceeding
if [ "$(stat -f -c %T /)" = "btrfs" ]; then
    # Create a default configuration for the root filesystem if it doesn't exist
    if [ ! -f /etc/snapper/configs/root ]; then
        echo "  -> Creating Snapper config for '/'..."
        sudo snapper -c root create-config /
    else
        echo "  -> Snapper config for '/' already exists."
    fi

    # Enable and start the services/timers for automatic snapshots and cleanup
    echo "  -> Enabling Snapper services..."
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
    sudo systemctl enable --now grub-btrfsd.service
else
    echo "  -> Skipping Snapper setup: '/' is not a Btrfs filesystem."
fi

# --- Configure GRUB and mkinitcpio for NVIDIA ---
echo "  -> Copying GRUB and mkinitcpio configs..."
sudo cp "$SCRIPT_DIR/nvidia/grub" /etc/default/grub
sudo cp "$SCRIPT_DIR/nvidia/mkinitcpio" /etc/mkinitcpio.conf

echo "  -> Regenerating initramfs and GRUB config..."
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- Configure PAM for GNOME Keyring ---
echo "  -> Setting up PAM for Keyring..."
sudo cp "$SCRIPT_DIR/keyring/login" /etc/pam.d/login

# --- Configure Git to use libsecret ---
echo "  -> Configuring Git credential helper..."
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret


#-------------------------------------------------------------------------------
# PROGRAMMING LANGUAGE SDKs
#-------------------------------------------------------------------------------
log_header "Installing Rust via rustup..."
# The -y flag ensures the installation proceeds with default options without prompting.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Add cargo to the current session's PATH. The shell rc file will handle future sessions.
export PATH="$HOME/.cargo/bin:$PATH"
rustup component add rust-analyzer
echo "  -> Rust has been installed successfully."


#-------------------------------------------------------------------------------
# USER-LEVEL CONFIGURATION
#-------------------------------------------------------------------------------
log_header "Applying user-level configurations..."

# --- Dotfiles Setup ---
echo "  -> Creating dotfiles directory..."
mkdir -p ~/.dotfiles
cp -R "$SCRIPT_DIR/dotfiles/"* ~/.dotfiles

echo "  -> Applying configurations with Stow..."
# Remove potential conflicts before stowing
rm -rf ~/.config/fish
rm -rf ~/.config/hypr
# Run stow safely from within the dotfiles directory
(cd ~/.dotfiles && stow fish kitty nvim rofi wp neofetch dunst hyprland opencode tmux)

# --- Tmux Plugin Setup (TPM, Resurrect, Continuum) ---
echo "  -> Setting up Tmux Plugin Manager (TPM) and plugins..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "  -> Cloning TPM repository..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "  -> TPM repository already exists."
fi

# Note: Assumes .tmux.conf is managed by stow and includes resurrect/continuum
echo "  -> Installing Tmux plugins specified in .tmux.conf..."
# Execute the plugin install script
"$TPM_DIR/bin/install_plugins"

# --- Change Default Shell to Fish ---
if [[ "$(basename "$SHELL")" != "fish" ]]; then
    echo "  -> Changing default shell to Fish..."
    chsh -s "$(which fish)"
else
    echo "  -> Default shell is already Fish."
fi

# --- Set Nemo as Default File Manager ---
echo "  -> Setting Nemo as the default file manager..."
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

#-------------------------------------------------------------------------------
# FINALIZATION
#-------------------------------------------------------------------------------
echo ""
echo "================================================================================"
echo "✅ System setup is complete!"
echo ""
echo "   IMPORTANT NOTES:"
echo "   - To apply group changes (Docker, Libvirt), you MUST LOG OUT and LOG BACK IN."
echo "   - After logging back in, you can start 'Virtual Machine Manager' from your application menu."
echo "   - It is highly recommended to REBOOT your system to apply all changes (like kernel and drivers)."
echo "================================================================================"
echo ""
read -p "Reboot now? (y/N): " choice
case "$choice" in
  y|Y ) sudo reboot now;;
  * ) echo "Please reboot your system manually to apply all changes.";;
esac



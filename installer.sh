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
# PRE-RUN CHECKS & SUDO HANDLING
#-------------------------------------------------------------------------------

# Ensure the script is NOT run as root
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
# ### NEW ### INSTALLATION MODE SELECTION
#-------------------------------------------------------------------------------
log_header "Installation Environment"
INSTALL_FOR_VM="false"
read -p "Are you installing on a Virtual Machine (VM)? (y/N): " choice
case "$choice" in
  y|Y )
    INSTALL_FOR_VM="true"
    echo "-> VM installation mode selected. NVIDIA drivers will be skipped."
    ;;
  * )
    echo "-> Bare-metal installation mode selected. NVIDIA drivers will be installed."
    ;;
esac


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

# This function should be run as a normal user. `makepkg` will fail if run as root.
# It will call `sudo` internally when it needs to install packages.
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

# uncomment if yay is needed
# install_aur_helper yay yay
install_aur_helper paru paru

# Update AUR package databases (prefer paru if present)
# AUR helpers should not be run with sudo. They will prompt for a password if needed.
if command -v paru &> /dev/null; then
    paru -Syu --noconfirm
elif command -v yay &> /dev/null; then
    yay -Syu --noconfirm
fi

#-------------------------------------------------------------------------------
# ### MODIFIED ### DRIVERS & AUDIO
#-------------------------------------------------------------------------------
log_header "Installing Graphics and Audio drivers..."

if [ "$INSTALL_FOR_VM" = "false" ]; then
    # --- NVIDIA Drivers (Bare-metal only) ---
    echo " -> Installing NVIDIA drivers for bare-metal system..."
    sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils nvidia-settings nvidia-container-toolkit
else
    echo " -> Skipping NVIDIA drivers (VM installation)."
fi

# --- Audio - PipeWire (Install for both VM and bare-metal) ---
echo " -> Installing audio services (PipeWire)..."
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
    libreoffice-fresh \
    papirus-icon-theme \
    nwg-look

# --- File Management & System Utilities ---
log_header "Installing file management & system utilities..."
sudo pacman -S --noconfirm --needed \
    tmux \
    nemo file-roller nemo-terminal ffmpegthumbnailer poppler-glib \
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
        neofetch \
        opencode \
        catppuccin-gtk-theme-mocha \
        bibata-modern-ice-cursor-theme
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
log_header "Configuring Snapper for Btrfs snapshots..."

if [ "$(stat -f -c %T /)" = "btrfs" ]; then
    # Only proceed if the Snapper config for root doesn't already exist.
    if [ ! -f /etc/snapper/configs/root ]; then
        echo "  -> Snapper config not found. Proceeding with setup..."

        # WORKAROUND: Handle case where archinstall creates /.snapshots but not the config file.
        # This is the cause of the "Device or resource busy" and "file exists" errors.
        if [ -d "/.snapshots" ]; then
            echo "  -> Detected existing /.snapshots. Applying workaround for archinstall bug..."
            sudo umount /.snapshots
            sudo mv /.snapshots /.snapshots.bak
        fi

        # Create the Snapper config. This will now succeed.
        sudo snapper -c root create-config /

        # If we applied the workaround, clean up and restore the original subvolume.
        if [ -d "/.snapshots.bak" ]; then
            echo "  -> Cleaning up and restoring original snapshot subvolume..."
            sudo btrfs subvolume delete /.snapshots
            sudo mv /.snapshots.bak /.snapshots
            sudo mount -a # Remount the correct subvolume from /etc/fstab
        fi
    else
        echo "  -> Existing Snapper config found. No action needed."
    fi

    # Ensure the services are enabled and running.
    echo "  -> Enabling Snapper services..."
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
    sudo systemctl enable --now grub-btrfsd.service
else
    echo "  -> Skipping Snapper setup: '/' is not a Btrfs filesystem."
fi

# --- ### MODIFIED ### Configure GRUB and mkinitcpio for NVIDIA ---
if [ "$INSTALL_FOR_VM" = "false" ]; then
    echo "  -> Configuring GRUB and mkinitcpio for NVIDIA..."
    sudo cp "$SCRIPT_DIR/nvidia/grub" /etc/default/grub
    sudo cp "$SCRIPT_DIR/nvidia/mkinitcpio" /etc/mkinitcpio.conf

    echo "  -> Regenerating initramfs and GRUB config..."
    sudo mkinitcpio -P
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "  -> Skipping NVIDIA-specific GRUB and mkinitcpio configuration."
fi

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
# rustup should be installed as the user, not root.
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

# --- Set GTK Theme (Catppuccin) ---
echo "  -> Setting GTK theme, icons, and cursor..."
gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha-Standard-Blue-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# --- Configure Hyprland to use the GTK Theme ---
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
THEME_ENV="env = GTK_THEME,Catppuccin-Mocha-Standard-Blue-Dark"
if [ -f "$HYPR_CONF" ] && ! grep -q "GTK_THEME" "$HYPR_CONF"; then
    echo "  -> Appending GTK_THEME environment variable to hyprland.conf..."
    # Add a newline and the comment/variable to the end of the file
    echo -e "\n# Set GTK theme for the session\n$THEME_ENV" >> "$HYPR_CONF"
fi

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
    # Note: chsh will prompt for your user password. This is a security feature and is expected.
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
echo "    IMPORTANT NOTES:"
echo "    - To apply group changes (Docker, Libvirt), you MUST LOG OUT and LOG BACK IN."
echo "    - After logging back in, you can start 'Virtual Machine Manager' from your application menu."
echo "    - It is highly recommended to REBOOT your system to apply all changes (like kernel and drivers)."
echo "================================================================================"
echo ""
read -p "Reboot now? (y/N): " choice
case "$choice" in
  y|Y ) sudo reboot now;;
  * ) echo "Please reboot your system manually to apply all changes.";;
esac

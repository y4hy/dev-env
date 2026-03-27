#!/bin/bash

# ===============================================================================
# Arch Linux — Hyprland Setup Script
# ===============================================================================

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ── Colors & symbols ────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
GRAY="\033[90m"

OK="${GREEN}✓${RESET}"
WARN="${YELLOW}!${RESET}"
ERR="${RED}✗${RESET}"
ARROW="${CYAN}›${RESET}"

# ── Logging helpers ─────────────────────────────────────────────────────────────
section() {
    echo ""
    echo -e "${BOLD}  $1${RESET}"
    echo -e "${GRAY}  $(printf '─%.0s' {1..60})${RESET}"
}

step() {
    echo -e "  ${ARROW} $1"
}

ok() {
    echo -e "  ${OK} $1"
}

warn() {
    echo ""
    echo -e "  ${WARN}  ${YELLOW}$1${RESET}"
    echo -e "  ${GRAY}  $2${RESET}"
    echo ""
}

die() {
    echo -e "  ${ERR} ${RED}Error:${RESET} $1" >&2
    exit 1
}

run_quiet() {
    # Run a command, only showing output if it fails
    local desc="$1"; shift
    step "$desc"
    local tmp
    tmp=$(mktemp)
    if ! "$@" >"$tmp" 2>&1; then
        echo -e "  ${ERR} Failed. Output:"
        cat "$tmp"
        rm -f "$tmp"
        exit 1
    fi
    rm -f "$tmp"
}

run_quiet_sudo() {
    local desc="$1"; shift
    step "$desc"
    local tmp
    tmp=$(mktemp)
    if ! sudo "$@" >"$tmp" 2>&1; then
        echo -e "  ${ERR} Failed. Output:"
        cat "$tmp"
        rm -f "$tmp"
        exit 1
    fi
    rm -f "$tmp"
}

# ── Preflight checks ────────────────────────────────────────────────────────────
[ "$EUID" -eq 0 ] && die "Do not run this script as root."

# ── Sudo keepalive ──────────────────────────────────────────────────────────────
section "Privileges"
step "Requesting sudo..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
ok "Sudo acquired"

# ── Environment selection ───────────────────────────────────────────────────────
section "Environment"
echo ""
echo -e "  ${DIM}Select your installation target:${RESET}"
echo ""
echo -e "    ${BOLD}[1]${RESET}  Bare-metal  ${GRAY}(NVIDIA, Bluetooth, KVM, Btrfs snapshots)${RESET}"
echo -e "    ${BOLD}[2]${RESET}  Virtual Machine  ${GRAY}(skips hardware-specific packages)${RESET}"
echo ""
read -rp "  Choice [1/2]: " _choice
case "$_choice" in
    2) INSTALL_FOR_VM="true";  echo -e "\n  ${OK} VM mode selected" ;;
    *) INSTALL_FOR_VM="false"; echo -e "\n  ${OK} Bare-metal mode selected" ;;
esac

# ── Package lists ───────────────────────────────────────────────────────────────
pacman_packages_base=(
    hyprland hyprshot neovim kitty fish rofi awww dunst stow wl-clipboard lxqt-sudo less
    imv libreoffice-fresh papirus-icon-theme nwg-look polkit-kde-agent xdg-desktop-portal-hyprland
    zathura tmux nemo file-roller nemo-terminal ffmpegthumbnailer poppler-glib xdg-utils zip unzip
    btop locate fuse3 syncthing gnome-calculator openvpn libnotify curl bat proton-vpn-gtk-app
    networkmanager vlc playerctl brightnessctl cliphist
    pipewire pipewire-jack pipewire-alsa pipewire-pulse wireplumber
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-nerd-fonts-symbols
    nodejs npm docker docker-compose python-pip
    gnome-keyring libsecret seahorse
)
pacman_packages_bare_metal=(
    intel-ucode
    nvidia-dkms nvidia-utils nvidia-settings nvidia-container-toolkit
    bluez bluez-utils blueman
    qemu-desktop virt-manager libvirt dnsmasq vde2 edk2-ovmf
    snapper snap-pac limine efibootmgr
)
aur_packages_base=(
    zen-browser-bin obsidian opencode-bin yaru-colors-gtk-theme neofetch
    rofi-bluetooth-git ttf-0xproto-nerd
)
aur_packages_bare_metal=(
    coolercontrol limine-entry-tool limine-snapper-sync bridge-utils
)

install_pacman_packages=("${pacman_packages_base[@]}")
install_aur_packages=("${aur_packages_base[@]}")
if [ "$INSTALL_FOR_VM" = "false" ]; then
    install_pacman_packages+=("${pacman_packages_bare_metal[@]}")
    install_aur_packages+=("${aur_packages_bare_metal[@]}")
fi

# ── Phase 1 — System update ─────────────────────────────────────────────────────
section "Phase 1 — System update"
run_quiet_sudo "Updating package databases and upgrading system..." pacman -Syu --noconfirm
run_quiet_sudo "Installing build dependencies..." pacman -S --noconfirm --needed \
    git base-devel linux linux-headers linux-lts linux-lts-headers mkinitcpio openssh systemd-resolvconf
ok "System up to date"

# ── Phase 2 — AUR helper ────────────────────────────────────────────────────────
section "Phase 2 — AUR helper (paru)"
if ! command -v paru &>/dev/null; then
    step "Building paru from AUR..."
    _tmp=$(mktemp -d)
    git clone "https://aur.archlinux.org/paru.git" "$_tmp" -q
    (cd "$_tmp" && makepkg -si --noconfirm -q) || die "paru build failed"
    rm -rf "$_tmp"
    ok "paru installed"
else
    ok "paru already installed"
fi
step "Syncing AUR databases..."
paru -Syu --noconfirm -q &>/dev/null
ok "AUR databases synced"

# ── Phase 3 — Packages ──────────────────────────────────────────────────────────
section "Phase 3 — Package installation"
step "Installing official packages (${#install_pacman_packages[@]} packages)..."
sudo pacman -S --noconfirm --needed "${install_pacman_packages[@]}" &>/dev/null \
    || die "pacman installation failed"
ok "Official packages installed"

step "Installing AUR packages (${#install_aur_packages[@]} packages)..."
paru -S --noconfirm --needed "${install_aur_packages[@]}" &>/dev/null \
    || die "AUR package installation failed"
ok "AUR packages installed"

# ── Phase 4 — Services & system config ─────────────────────────────────────────
section "Phase 4 — Services & system config"

run_quiet_sudo "Enabling NetworkManager..." systemctl enable --now NetworkManager.service

if pacman -Q blueman &>/dev/null; then
    run_quiet_sudo "Enabling Bluetooth..." systemctl enable --now bluetooth.service
fi

if command -v coolercontrold &>/dev/null; then
    run_quiet_sudo "Enabling CoolerControl..." systemctl enable --now coolercontrold.service
fi

step "Configuring Docker..."
sudo systemctl enable --now docker &>/dev/null
sudo usermod -aG docker "$USER" &>/dev/null
warn "docker group" "Log out and back in for Docker access to take effect."

if pacman -Q libvirt &>/dev/null; then
    step "Configuring Libvirt..."
    sudo systemctl enable --now libvirtd.service &>/dev/null
    sudo usermod -aG libvirt "$USER" &>/dev/null
    warn "libvirt group" "Log out and back in for KVM/QEMU access to take effect."
fi

# GNOME Keyring PAM
step "Configuring GNOME Keyring (PAM)..."
PAM_LOGIN="/etc/pam.d/login"
if [ -f "$PAM_LOGIN" ]; then
    sudo cp "$PAM_LOGIN" "$PAM_LOGIN.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
fi
if ! grep -q "pam_gnome_keyring\.so" "$PAM_LOGIN" 2>/dev/null; then
    if grep -q "^auth.*system-local-login" "$PAM_LOGIN" 2>/dev/null; then
        sudo sed -i '/^auth[[:space:]]\+include[[:space:]]\+system-local-login/a auth        optional    pam_gnome_keyring.so' "$PAM_LOGIN"
    else
        echo "auth        optional    pam_gnome_keyring.so" | sudo tee -a "$PAM_LOGIN" >/dev/null
    fi
fi
if ! grep -q "pam_gnome_keyring\.so auto_start" "$PAM_LOGIN" 2>/dev/null; then
    if grep -q "^session.*system-local-login" "$PAM_LOGIN" 2>/dev/null; then
        sudo sed -i '/^session[[:space:]]\+include[[:space:]]\+system-local-login/a session      optional    pam_gnome_keyring.so auto_start' "$PAM_LOGIN"
    else
        echo "session     optional    pam_gnome_keyring.so auto_start" | sudo tee -a "$PAM_LOGIN" >/dev/null
    fi
fi

step "Configuring Git credential helper..."
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

ok "Services configured"

# ── Phase 5 — NVIDIA & Limine (bare-metal only) ─────────────────────────────────
if [ "$INSTALL_FOR_VM" = "false" ] && pacman -Q nvidia-dkms &>/dev/null; then
    section "Phase 5 — NVIDIA & Limine config"
    _ts=$(date +%Y%m%d%H%M%S)

    if [ -f /etc/kernel/cmdline ]; then
        step "Patching kernel cmdline..."
        sudo cp /etc/kernel/cmdline "/etc/kernel/cmdline.backup.$_ts"
        grep -Eq 'nvidia-drm\.modeset=1' /etc/kernel/cmdline \
            || sudo sed -i 's/$/ nvidia-drm.modeset=1/' /etc/kernel/cmdline
        grep -Eq 'modprobe\.blacklist=nouveau' /etc/kernel/cmdline \
            || sudo sed -i 's/$/ modprobe.blacklist=nouveau/' /etc/kernel/cmdline
    else
        warn "kernel cmdline" "/etc/kernel/cmdline not found — add NVIDIA params to limine.conf manually."
    fi

    if [ -f /etc/mkinitcpio.conf ]; then
        step "Patching mkinitcpio modules..."
        sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.backup.$_ts"
        if grep -q '^MODULES=' /etc/mkinitcpio.conf; then
            for _mod in nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
                grep -Eq "^MODULES=.*\b${_mod}\b" /etc/mkinitcpio.conf && continue
                sudo sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 ${_mod})/" /etc/mkinitcpio.conf
                sudo sed -i 's/^MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
            done
        fi
    fi

    step "Regenerating initramfs..."
    if command -v limine-mkinitcpio &>/dev/null; then
        sudo limine-mkinitcpio &>/dev/null
    else
        sudo mkinitcpio -P &>/dev/null
    fi

    if command -v limine-update &>/dev/null; then
        step "Updating Limine boot entries..."
        sudo limine-update &>/dev/null
    fi

    ok "NVIDIA & Limine configured"
fi

# ── Phase 6 — Snapper / Btrfs (bare-metal only) ────────────────────────────────
if [ "$INSTALL_FOR_VM" = "false" ] && [ "$(stat -c %T /)" = "btrfs" ]; then
    section "Phase 6 — Btrfs snapshots (Snapper)"

    if [ ! -f /etc/snapper/configs/root ]; then
        run_quiet_sudo "Creating Snapper root config..." snapper -c root create-config /
    else
        ok "Snapper config already exists"
    fi

    run_quiet_sudo "Enabling snapshot timers..." systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

    if command -v limine-snapper-sync &>/dev/null; then
        run_quiet_sudo "Enabling Limine snapshot sync..." systemctl enable --now limine-snapper-sync.service
    fi

    ok "Snapper configured"
fi

# ── Phase 7 — Rust toolchain ────────────────────────────────────────────────────
section "Phase 7 — Rust toolchain"
if ! command -v rustup &>/dev/null; then
    run_quiet_sudo "Installing rustup..." pacman -S --noconfirm --needed rustup
fi
step "Setting stable toolchain..."
rustup default stable &>/dev/null
step "Adding rust-analyzer..."
rustup component add rust-analyzer &>/dev/null
ok "Rust configured"

# ── Phase 8 — User environment ──────────────────────────────────────────────────
section "Phase 8 — User environment"

step "Deploying dotfiles..."
mkdir -p ~/.dotfiles
cp -R "$SCRIPT_DIR/dotfiles/"* ~/.dotfiles
rm -rf ~/.config/fish ~/.config/hypr
(cd ~/.dotfiles && stow fish kitty nvim rofi wp neofetch dunst hyprland opencode tmux)
ok "Dotfiles applied"

step "Setting GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-Grey-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
ok "Theme applied"

step "Setting up Tmux Plugin Manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
[ ! -d "$TPM_DIR" ] && git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" -q
"$TPM_DIR/bin/install_plugins" &>/dev/null
ok "Tmux plugins installed"

if [[ "$(basename "$SHELL")" != "fish" ]]; then
    step "Changing default shell to Fish..."
    sudo chsh -s "$(which fish)" "$USER" &>/dev/null
    ok "Default shell set to Fish"
else
    ok "Default shell already Fish"
fi

step "Setting Nemo as default file manager..."
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search &>/dev/null
ok "Nemo set as default"

# ── Done ────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  ✓ Setup complete${RESET}"
echo ""
echo -e "  ${GRAY}Next steps:${RESET}"
echo -e "  ${ARROW} Log out and back in to apply group changes (docker, libvirt)"
echo -e "  ${ARROW} Reboot to apply kernel, driver, and shell changes"
echo ""
read -rp "  Reboot now? [y/N]: " _reboot
case "$_reboot" in
    y|Y) sudo reboot now ;;
    *)   echo -e "\n  ${GRAY}Reboot skipped. Run ${RESET}sudo reboot${GRAY} when ready.${RESET}\n" ;;
esac

#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
_SCRIPT_START=$SECONDS

# ── ANSI ────────────────────────────────────────────────────────────────────────
R="\033[0m"
B="\033[1m"
DIM="\033[2m"
GREEN="\033[38;5;114m"
YELLOW="\033[38;5;221m"
RED="\033[38;5;203m"
BLUE="\033[38;5;110m"
GRAY="\033[38;5;242m"
WHITE="\033[38;5;252m"

# ── Spinner ──────────────────────────────────────────────────────────────────────
_SPINNER_PID=""
_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

spinner_start() {
    local msg="$1"
    (
        local i=0
        while true; do
            printf "\r  \033[38;5;110m${_SPINNER_FRAMES[$i]}\033[0m  %s " "$msg"
            i=$(( (i+1) % 10 ))
            sleep 0.08
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID"
}

spinner_stop() {
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null || true
        _SPINNER_PID=""
        printf "\r\033[2K"
    fi
}

# ── Phase progress bar ────────────────────────────────────────────────────────────
_TOTAL_PHASES=8

_phasebar() {
    local current=$1 total=$2
    local filled=$(( current * 24 / total ))
    local empty=$(( 24 - filled ))
    local bar
    bar="${BLUE}["
    bar+="$(printf '█%.0s' $(seq 1 $filled) 2>/dev/null)"
    bar+="${GRAY}$(printf '░%.0s' $(seq 1 $empty) 2>/dev/null)"
    bar+="${BLUE}]${R}"
    echo -e "  $bar ${GRAY}$current / $total${R}"
}

# ── Helpers ───────────────────────────────────────────────────────────────────────
_elapsed() {
    local s=$(( SECONDS - _SCRIPT_START ))
    printf "%dm%02ds" $(( s / 60 )) $(( s % 60 ))
}

section() {
    local num="$1" title="$2" badge="${3:-}"
    echo ""
    echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
    if [[ -n "$badge" ]]; then
        echo -e "  ${B}${WHITE}Phase $num — $title${R}  ${YELLOW}$badge${R}"
    else
        echo -e "  ${B}${WHITE}Phase $num — $title${R}"
    fi
    _phasebar "$num" "$_TOTAL_PHASES"
    echo ""
}

step()  { echo -e "  ${BLUE}·${R}  $1"; }
ok()    { echo -e "  ${GREEN}✓${R}  $1"; }
skip()  { echo -e "  ${GRAY}–  $1 (skipped)${R}"; }

warn() {
    echo ""
    echo -e "  ${YELLOW}▲${R}  ${B}${YELLOW}$1${R}"
    echo -e "     ${GRAY}$2${R}"
    echo ""
}

die() {
    spinner_stop
    echo ""
    echo -e "  ${RED}✗${R}  ${B}${RED}Error:${R} $1" >&2
    echo -e "     ${GRAY}elapsed: $(_elapsed)${R}" >&2
    echo ""
    exit 1
}

# task "Description" [sudo] cmd [args...]
task() {
    local desc="$1"; shift
    local use_sudo=false
    [[ "$1" == "sudo" ]] && { use_sudo=true; shift; }

    spinner_start "$desc"
    local tmp rc=0
    tmp=$(mktemp)

    if $use_sudo; then
        sudo "$@" >"$tmp" 2>&1 || rc=$?
    else
        "$@" >"$tmp" 2>&1 || rc=$?
    fi

    spinner_stop

    if [[ $rc -ne 0 ]]; then
        echo -e "  ${RED}✗${R}  ${B}Failed:${R} $desc"
        echo ""
        sed 's/^/      /' "$tmp"
        echo ""
        rm -f "$tmp"
        exit 1
    fi

    rm -f "$tmp"
    ok "$desc"
}

# ── Banner ────────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "  ${B}${WHITE}Arch Linux — Hyprland setup${R}"
echo -e "  ${GRAY}$_TOTAL_PHASES phases  ·  output is suppressed, errors will be shown${R}"
echo ""

# ── Preflight ─────────────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && die "Do not run this script as root."

# ── Sudo ──────────────────────────────────────────────────────────────────────────
echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
echo -e "  ${B}${WHITE}Privileges${R}"
echo ""
step "Enter your password to grant sudo access for this session"
sudo -v || die "sudo authentication failed"
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
ok "Sudo active"
echo ""

# ── Environment ───────────────────────────────────────────────────────────────────
echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
echo -e "  ${B}${WHITE}Environment${R}"
echo ""
echo -e "  ${B}[1]${R}  Bare-metal"
echo -e "       ${GRAY}NVIDIA · Bluetooth · KVM/QEMU · Btrfs snapshots · CoolerControl${R}"
echo ""
echo -e "  ${B}[2]${R}  Virtual Machine"
echo -e "       ${GRAY}Skips all hardware-specific packages and services${R}"
echo ""
read -rp "  › Choice [1/2]: " _choice
echo ""
case "$_choice" in
    2)
        INSTALL_FOR_VM="true"
        _TOTAL_PHASES=6
        ok "VM mode — phases 5 and 6 will be skipped"
        ;;
    *)
        INSTALL_FOR_VM="false"
        ok "Bare-metal mode — all 8 phases will run"
        ;;
esac

# ── Package lists ─────────────────────────────────────────────────────────────────
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
if [[ "$INSTALL_FOR_VM" == "false" ]]; then
    install_pacman_packages+=("${pacman_packages_bare_metal[@]}")
    install_aur_packages+=("${aur_packages_bare_metal[@]}")
fi

# ── Phase 1 — System update ───────────────────────────────────────────────────────
section 1 "System update"
task "Upgrading system packages" sudo pacman -Syu --noconfirm
task "Installing build dependencies" sudo pacman -S --noconfirm --needed \
    git base-devel linux linux-headers linux-lts linux-lts-headers mkinitcpio openssh systemd-resolvconf

# ── Phase 2 — AUR helper ──────────────────────────────────────────────────────────
section 2 "AUR helper — paru"
if ! command -v paru &>/dev/null; then
    _tmp=$(mktemp -d)
    spinner_start "Cloning paru from AUR"
    git clone "https://aur.archlinux.org/paru.git" "$_tmp" -q 2>/dev/null
    spinner_stop; ok "Repository cloned"
    spinner_start "Building and installing paru"
    (cd "$_tmp" && makepkg -si --noconfirm -q 2>/dev/null) || die "paru build failed"
    spinner_stop; ok "paru installed"
    rm -rf "$_tmp"
else
    ok "paru already installed"
fi
task "Syncing AUR databases" paru -Syu --noconfirm -q

# ── Phase 3 — Packages ────────────────────────────────────────────────────────────
section 3 "Package installation"
echo -e "  ${GRAY}pacman: ${#install_pacman_packages[@]} packages  ·  AUR: ${#install_aur_packages[@]} packages${R}"
echo ""
task "Installing official packages (${#install_pacman_packages[@]})" sudo pacman -S --noconfirm --needed "${install_pacman_packages[@]}"
task "Installing AUR packages (${#install_aur_packages[@]})" paru -S --noconfirm --needed "${install_aur_packages[@]}"

# ── Phase 4 — Services & config ───────────────────────────────────────────────────
section 4 "Services & system config"
task "Enabling NetworkManager" sudo systemctl enable --now NetworkManager.service

if pacman -Q blueman &>/dev/null; then
    task "Enabling Bluetooth" sudo systemctl enable --now bluetooth.service
else
    skip "Bluetooth"
fi

if command -v coolercontrold &>/dev/null; then
    task "Enabling CoolerControl" sudo systemctl enable --now coolercontrold.service
else
    skip "CoolerControl"
fi

task "Enabling Docker" sudo systemctl enable --now docker
sudo usermod -aG docker "$USER" &>/dev/null
warn "docker group" "Log out and back in for Docker access to take effect."

if pacman -Q libvirt &>/dev/null; then
    task "Enabling Libvirt" sudo systemctl enable --now libvirtd.service
    sudo usermod -aG libvirt "$USER" &>/dev/null
    warn "libvirt group" "Log out and back in for KVM/QEMU access to take effect."
else
    skip "Libvirt"
fi

step "Configuring GNOME Keyring (PAM)..."
PAM_LOGIN="/etc/pam.d/login"
[[ -f "$PAM_LOGIN" ]] && sudo cp "$PAM_LOGIN" "$PAM_LOGIN.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
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
ok "GNOME Keyring configured"

step "Configuring Git credential helper..."
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret
ok "Git credential helper set"

# ── Phase 5 — NVIDIA & Limine ─────────────────────────────────────────────────────
if [[ "$INSTALL_FOR_VM" == "false" ]] && pacman -Q nvidia-dkms &>/dev/null; then
    section 5 "NVIDIA & Limine config" "bare-metal only"
    _ts=$(date +%Y%m%d%H%M%S)

    if [[ -f /etc/kernel/cmdline ]]; then
        step "Patching kernel cmdline..."
        sudo cp /etc/kernel/cmdline "/etc/kernel/cmdline.backup.$_ts"
        grep -Eq 'nvidia-drm\.modeset=1' /etc/kernel/cmdline \
            || sudo sed -i 's/$/ nvidia-drm.modeset=1/' /etc/kernel/cmdline
        grep -Eq 'modprobe\.blacklist=nouveau' /etc/kernel/cmdline \
            || sudo sed -i 's/$/ modprobe.blacklist=nouveau/' /etc/kernel/cmdline
        ok "Kernel cmdline patched"
    else
        warn "kernel cmdline not found" "Add nvidia-drm.modeset=1 and modprobe.blacklist=nouveau to limine.conf manually."
    fi

    if [[ -f /etc/mkinitcpio.conf ]]; then
        step "Patching mkinitcpio modules..."
        sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.backup.$_ts"
        if grep -q '^MODULES=' /etc/mkinitcpio.conf; then
            for _mod in nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
                grep -Eq "^MODULES=.*\b${_mod}\b" /etc/mkinitcpio.conf && continue
                sudo sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 ${_mod})/" /etc/mkinitcpio.conf
                sudo sed -i 's/^MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
            done
        fi
        ok "mkinitcpio modules patched"
    fi

    if command -v limine-mkinitcpio &>/dev/null; then
        task "Regenerating initramfs" sudo limine-mkinitcpio
    else
        task "Regenerating initramfs" sudo mkinitcpio -P
    fi

    if command -v limine-update &>/dev/null; then
        task "Updating Limine boot entries" sudo limine-update
    else
        skip "limine-update (not found)"
    fi
elif [[ "$INSTALL_FOR_VM" == "true" ]]; then
    echo ""
    echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
    skip "Phase 5 — NVIDIA & Limine (VM mode)"
fi

# ── Phase 6 — Snapper ────────────────────────────────────────────────────────────
if [[ "$INSTALL_FOR_VM" == "false" ]] && [[ "$(stat -c %T /)" == "btrfs" ]]; then
    section 6 "Btrfs snapshots — Snapper" "bare-metal only"

    if [[ ! -f /etc/snapper/configs/root ]]; then
        task "Creating Snapper root config" sudo snapper -c root create-config /
    else
        ok "Snapper config already exists"
    fi

    task "Enabling snapshot timers" sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

    if command -v limine-snapper-sync &>/dev/null; then
        task "Enabling Limine snapshot sync" sudo systemctl enable --now limine-snapper-sync.service
    else
        skip "limine-snapper-sync (not installed)"
    fi
elif [[ "$INSTALL_FOR_VM" == "true" ]]; then
    skip "Phase 6 — Snapper (VM mode)"
fi

# ── Phase 7 — Rust ───────────────────────────────────────────────────────────────
section 7 "Rust toolchain"
if ! command -v rustup &>/dev/null; then
    task "Installing rustup" sudo pacman -S --noconfirm --needed rustup
else
    ok "rustup already installed"
fi
task "Setting stable toolchain" rustup default stable
task "Adding rust-analyzer component" rustup component add rust-analyzer

# ── Phase 8 — User environment ────────────────────────────────────────────────────
section 8 "User environment"

step "Deploying dotfiles..."
mkdir -p ~/.dotfiles
cp -R "$SCRIPT_DIR/dotfiles/"* ~/.dotfiles
rm -rf ~/.config/fish ~/.config/hypr
(cd ~/.dotfiles && stow fish kitty nvim rofi wp neofetch dunst hyprland opencode tmux) \
    || die "stow failed — check for pre-existing config conflicts"
ok "Dotfiles applied via stow"

step "Applying GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-Grey-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
ok "Theme: Yaru-Grey-dark  ·  Icons: Papirus-Dark"

step "Setting up Tmux Plugin Manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    spinner_start "Cloning TPM"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" -q
    spinner_stop
fi
"$TPM_DIR/bin/install_plugins" &>/dev/null
ok "Tmux plugins installed"

if [[ "$(basename "$SHELL")" != "fish" ]]; then
    task "Changing default shell to Fish" sudo chsh -s "$(which fish)" "$USER"
else
    ok "Default shell already Fish"
fi

step "Setting Nemo as default file manager..."
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search &>/dev/null
ok "Nemo set as default"

# ── Done ──────────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
echo ""
echo -e "  ${GREEN}${B}✓  Setup complete${R}  ${GRAY}($(_elapsed))${R}"
echo ""
echo -e "  ${GRAY}Next steps:${R}"
echo -e "  ${BLUE}·${R}  Log out and back in  ${GRAY}→ apply docker / libvirt group changes${R}"
echo -e "  ${BLUE}·${R}  Reboot               ${GRAY}→ apply kernel, driver, and shell changes${R}"
echo ""
echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
echo ""
read -rp "  Reboot now? [y/N] › " _reboot
case "$_reboot" in
    y|Y)
        echo -e "\n  ${GRAY}Rebooting in 3 seconds…${R}"
        sleep 3
        sudo reboot now
        ;;
    *)
        echo -e "\n  ${GRAY}Run ${R}sudo reboot${GRAY} when you're ready.${R}"
        echo ""
        ;;
esac

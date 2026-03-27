#!/bin/bash

set -o pipefail

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
            printf "\r  \033[38;5;110m${_SPINNER_FRAMES[$i]}\033[0m  %b " "$msg"
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
        _SPINNER_PID=""
        printf "\r\033[2K"
    fi
}

# ── Phase progress bar ────────────────────────────────────────────────────────────
_TOTAL_PHASES=9
_PHASE_NUM=1

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
    local title="$1" badge="${2:-}"
    echo ""
    echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
    if [[ -n "$badge" ]]; then
        echo -e "  ${B}${WHITE}Phase $_PHASE_NUM — $title${R}  ${YELLOW}$badge${R}"
    else
        echo -e "  ${B}${WHITE}Phase $_PHASE_NUM — $title${R}"
    fi
    _phasebar "$_PHASE_NUM" "$_TOTAL_PHASES"
    ((_PHASE_NUM++))
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

    set +e
    if $use_sudo; then
        sudo "$@" >"$tmp" 2>&1
        rc=$?
    else
        "$@" >"$tmp" 2>&1
        rc=$?
    fi
    set -o pipefail

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

# ── Cleanup trap ─────────────────────────────────────────────────────────────────
trap 'kill $(jobs -p) 2>/dev/null; exit' EXIT INT TERM

# ── Banner ────────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "  ${B}${WHITE}We are here to alleviate your suffer, but not thoroughly${R}"
echo -e "  ${GRAY}Output is suppressed, errors will be shown${R}"
echo ""

# ── Preflight ─────────────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && die "Do not run this script as root."
[[ -d "$SCRIPT_DIR/dotfiles" ]] || die "dotfiles directory not found at $SCRIPT_DIR/dotfiles"

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
echo -e "       ${GRAY}NVIDIA · Bluetooth · KVM/QEMU · Btrfs snapshots · CoolerControl · Limine${R}"
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
        ok "VM mode selected — hardware phases will be skipped"
        ;;
    *)
        INSTALL_FOR_VM="false"
        _TOTAL_PHASES=9
        ok "Bare-metal mode selected — all 9 phases will run"
        ;;
esac

# ── Package lists ─────────────────────────────────────────────────────────────────
pacman_packages_base=(
    hyprland hyprshot neovim tree-sitter tree-sitter-cli kitty fish rofi awww dunst stow wl-clipboard lxqt-sudo less
    imv libreoffice-fresh papirus-icon-theme nwg-look polkit-kde-agent xdg-desktop-portal-hyprland
    zathura zathura-pdf-mupdf tmux nemo file-roller nemo-terminal ffmpegthumbnailer poppler-glib xdg-utils zip unzip
    btop locate fuse3 syncthing gnome-calculator openvpn libnotify curl bat proton-vpn-gtk-app
    networkmanager vlc playerctl brightnessctl cliphist xdg-user-dirs
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
    snapper snap-pac limine efibootmgr b3sum inotify-tools
)
aur_packages_base=(
    zen-browser-bin obsidian opencode-bin yaru-colors-gtk-theme fastfetch
    rofi-bluetooth-git ttf-0xproto-nerd
)
aur_packages_bare_metal=(
    coolercontrol limine-snapper-sync bridge-utils limine-mkinitcpio-hook
)

install_pacman_packages=("${pacman_packages_base[@]}")
install_aur_packages=("${aur_packages_base[@]}")
if [[ "$INSTALL_FOR_VM" == "false" ]]; then
    install_pacman_packages+=("${pacman_packages_bare_metal[@]}")
    install_aur_packages+=("${aur_packages_bare_metal[@]}")
fi

# ── Phase 1 — System update ───────────────────────────────────────────────────────
section "System update"
task "Upgrading system packages ${DIM}(fetching latest OS updates, ~1-2m)${R}" sudo pacman -Syu --noconfirm
task "Installing build dependencies ${DIM}(compilers & headers)${R}" sudo pacman -S --noconfirm --needed \
    git base-devel linux linux-headers linux-lts linux-lts-headers mkinitcpio openssh systemd-resolvconf

# ── Phase 2 — Rust ───────────────────────────────────────────────────────────────
section "Rust toolchain"

if ! command -v rustup &>/dev/null; then
    step "Fetching official rustup installer..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup-init.sh
    chmod +x /tmp/rustup-init.sh
    task "Installing Rust via rustup ${DIM}(required for paru, ~30s)${R}" /tmp/rustup-init.sh -y --no-modify-path --profile default --default-toolchain stable
    rm -f /tmp/rustup-init.sh
else
    ok "rustup already installed"
fi

export PATH="$HOME/.cargo/bin:$PATH"
task "Adding rust-analyzer component ${DIM}(for Neovim LSP)${R}" rustup component add rust-analyzer

# ── Phase 3 — AUR helper ──────────────────────────────────────────────────────────
section "AUR helper — paru"
if ! command -v paru &>/dev/null; then
    _tmp=$(mktemp -d)
    task "Cloning paru from AUR ${DIM}(pre-compiled binary)${R}" git clone "https://aur.archlinux.org/paru.git" "$_tmp"
    task "Building and installing paru ${DIM}(~30s)${R}" bash -c "cd '$_tmp' && makepkg -si --noconfirm"
    rm -rf "$_tmp"
else
    ok "paru already installed"
fi
task "Syncing AUR databases" paru -Sy --noconfirm

# ── Phase 4 — Packages ────────────────────────────────────────────────────────────
section "Package installation"
echo -e "  ${GRAY}pacman: ${#install_pacman_packages[@]} packages  ·  AUR: ${#install_aur_packages[@]} packages${R}"
echo ""
task "Installing official packages ${DIM}(~2-5m depending on network)${R}" sudo pacman -S --noconfirm --needed "${install_pacman_packages[@]}"
task "Installing AUR packages ${DIM}(compiling sources, ~5-10m)${R}" paru -S --noconfirm --needed "${install_aur_packages[@]}"

# ── Phase 5 — Services & config ───────────────────────────────────────────────────
section "Services & system config"
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

task "Enabling Docker ${DIM}(adds user to docker group)${R}" sudo systemctl enable --now docker
task "Adding $USER to docker group" sudo usermod -aG docker "$USER"
warn "docker group" "Log out and back in for Docker access to take effect."

if pacman -Q libvirt &>/dev/null; then
    task "Enabling Libvirt ${DIM}(for KVM/QEMU)${R}" sudo systemctl enable --now libvirtd.service
    task "Adding $USER to libvirt group" sudo usermod -aG libvirt "$USER"
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
        echo "session      optional    pam_gnome_keyring.so auto_start" | sudo tee -a "$PAM_LOGIN" >/dev/null
    fi
fi
ok "GNOME Keyring configured"

step "Configuring Git credential helper..."
if command -v git-credential-libsecret &>/dev/null; then
    git config --global credential.helper "$(command -v git-credential-libsecret)"
else
    git config --global credential.helper libsecret
fi
ok "Git credential helper set"

# ── Phase 6 — Limine Installation ─────────────────────────────────────────────────
if [[ "$INSTALL_FOR_VM" == "false" ]]; then
    section "Limine Installation" "bare-metal only"
    
    step "Detecting EFI System Partition (ESP)..."
    ESP=$(findmnt -n -r -o TARGET -t vfat | grep -E '^/boot|^/efi' | head -n 1)
    if [[ -z "$ESP" ]]; then
        ESP="/boot"
        warn "ESP Detection" "Could not strictly detect a FAT32 ESP via findmnt, defaulting to $ESP"
    else
        ok "Found ESP at $ESP"
    fi

    task "Deploying Limine EFI to UEFI fallback path" sudo bash -c "mkdir -p \"$ESP/EFI/BOOT\" && cp /usr/share/limine/BOOTX64.EFI \"$ESP/EFI/BOOT/BOOTX64.EFI\""

    if [[ ! -f "$ESP/limine.conf" ]]; then
        step "Creating base limine.conf with snapshot support..."
        printf "timeout: 5\n//Snapshots\n" | sudo tee "$ESP/limine.conf" >/dev/null
        ok "Base limine.conf created"
    else
        if ! grep -q "//Snapshots" "$ESP/limine.conf"; then
            echo "//Snapshots" | sudo tee -a "$ESP/limine.conf" >/dev/null
            ok "Appended //Snapshots marker to existing limine.conf"
        else
            ok "limine.conf already configured for snapshots"
        fi
    fi
fi

# ── Phase 7 — NVIDIA & mkinitcpio ─────────────────────────────────────────────────
if [[ "$INSTALL_FOR_VM" == "false" ]]; then
    section "NVIDIA & Kernel Config" "bare-metal only"
    _ts=$(date +%Y%m%d%H%M%S)

    if pacman -Q nvidia-dkms &>/dev/null; then
        if [[ -f /etc/kernel/cmdline ]]; then
            step "Patching kernel cmdline... ${DIM}(adding DRM modeset)${R}"
            sudo cp /etc/kernel/cmdline "/etc/kernel/cmdline.backup.$_ts"
            grep -Eq 'nvidia-drm\.modeset=1' /etc/kernel/cmdline \
                || sudo sed -i 's/$/ nvidia-drm.modeset=1/' /etc/kernel/cmdline
            grep -Eq 'modprobe\.blacklist=nouveau' /etc/kernel/cmdline \
                || sudo sed -i 's/$/ modprobe.blacklist=nouveau/' /etc/kernel/cmdline
            ok "Kernel cmdline patched"
        else
            step "Creating new kernel cmdline..."
            echo "nvidia-drm.modeset=1 modprobe.blacklist=nouveau" | sudo tee /etc/kernel/cmdline >/dev/null
            ok "Kernel cmdline created with NVIDIA flags"
            warn "ACTION REQUIRED" "Created /etc/kernel/cmdline, but you MUST manually add your root=... parameter before rebooting!"
        fi
    fi

    if [[ -f /etc/mkinitcpio.conf ]]; then
        step "Patching mkinitcpio modules & hooks... ${DIM}(injecting early KMS and Btrfs overlay)${R}"
        sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.backup.$_ts"
        
        # Inject NVIDIA modules
        if pacman -Q nvidia-dkms &>/dev/null && grep -q '^MODULES=' /etc/mkinitcpio.conf; then
            for _mod in nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
                grep -Eq "^MODULES=.*\b${_mod}\b" /etc/mkinitcpio.conf && continue
                sudo sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 ${_mod})/" /etc/mkinitcpio.conf
                sudo sed -i 's/^MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
            done
        fi
        
        # Inject Snapper btrfs-overlayfs hook
        if grep -q '^HOOKS=' /etc/mkinitcpio.conf; then
            if ! grep -Eq '\bbtrfs-overlayfs\b' /etc/mkinitcpio.conf; then
                sudo sed -i 's/\(filesystems\)/\1 btrfs-overlayfs/' /etc/mkinitcpio.conf
            fi
        fi
        ok "mkinitcpio configured"
    fi

    if command -v limine-mkinitcpio &>/dev/null; then
        task "Regenerating initramfs ${DIM}(~30s)${R}" sudo limine-mkinitcpio
    else
        task "Regenerating initramfs ${DIM}(~30s)${R}" sudo mkinitcpio -P
    fi

    if command -v limine-update &>/dev/null; then
        task "Updating Limine boot entries" sudo limine-update
    fi
fi

# ── Phase 8 — Snapper ────────────────────────────────────────────────────────────
if [[ "$INSTALL_FOR_VM" == "false" ]]; then
    if [[ "$(stat -c %T /)" == "btrfs" ]]; then
        section "Btrfs snapshots — Snapper" "bare-metal only"

        # ── Discover mounted Btrfs subvolumes ─────────────────────────────────
        step "Detecting mounted Btrfs subvolumes..."
        declare -A _subvol_map  # mountpoint → subvolume name
        while IFS= read -r line; do
            local_mp=$(echo "$line" | awk '{print $1}')
            local_sv=$(echo "$line" | awk '{print $2}')
            # skip the top-level subvol (id 5 / path /)
            [[ "$local_sv" == "/" ]] && continue
            _subvol_map["$local_mp"]="$local_sv"
        done < <(findmnt -n -r -t btrfs -o TARGET,SOURCE \
                 | sed 's|.*\[||;s|\]||' \
                 | awk '{mp=$1; sv=$2; if (sv != "") print mp, sv}')

        if [[ ${#_subvol_map[@]} -eq 0 ]]; then
            warn "Subvolume detection" "No named Btrfs subvolumes found. Falling back to root-only config."
            _subvol_map["/"]="@"
        else
            echo -e "  ${GRAY}Found ${#_subvol_map[@]} subvolume(s):${R}"
            for _mp in "${!_subvol_map[@]}"; do
                echo -e "    ${BLUE}·${R}  ${_subvol_map[$_mp]}  ${GRAY}→  $_mp${R}"
            done
            echo ""
        fi

        # ── Subvolumes that should NOT get their own snapper config ───────────
        # Snapshots dirs, efi, boot, swap are not useful to snapshot
        _skip_patterns=('*.snapshots*' '*/efi*' '*/boot*' '*swap*' '*tmp*')

        _snapper_configs=()

        for _mp in "${!_subvol_map[@]}"; do
            _sv="${_subvol_map[$_mp]}"
            _skip=false
            for _pat in "${_skip_patterns[@]}"; do
                # shellcheck disable=SC2254
                case "$_mp" in $_pat) _skip=true; break;; esac
            done
            [[ "$_skip" == "true" ]] && { skip "Skipping snapper config for $_sv ($_mp)"; continue; }

            # Derive a short config name from the subvolume (strip leading @)
            _cfg_name="${_sv##*/}"           # last path component
            _cfg_name="${_cfg_name#@}"       # strip leading @
            _cfg_name="${_cfg_name:-root}"   # fallback to "root" for bare "@"
            _cfg_name="${_cfg_name//_/-}"    # underscores → hyphens

            if [[ ! -f "/etc/snapper/configs/$_cfg_name" ]]; then
                task "Creating snapper config '$_cfg_name' ${DIM}($_sv → $_mp)${R}" \
                    sudo snapper -c "$_cfg_name" create-config "$_mp"
            else
                ok "Snapper config '$_cfg_name' already exists"
            fi

            # ── Per-config timeline & cleanup tuning ──────────────────────────
            # root/@  gets generous limits; secondary subvols get tighter ones
            if [[ "$_cfg_name" == "root" ]] || [[ "$_mp" == "/" ]]; then
                _hourly=5; _daily=7; _weekly=2; _monthly=2; _yearly=0
            else
                _hourly=3; _daily=5; _weekly=1; _monthly=1; _yearly=0
            fi

            step "Tuning retention for '$_cfg_name'..."
            sudo snapper -c "$_cfg_name" set-config \
                TIMELINE_CREATE=yes \
                TIMELINE_CLEANUP=yes \
                NUMBER_CLEANUP=yes \
                NUMBER_MIN_AGE=1800 \
                NUMBER_LIMIT=50 \
                NUMBER_LIMIT_IMPORTANT=10 \
                TIMELINE_MIN_AGE=1800 \
                TIMELINE_LIMIT_HOURLY="$_hourly" \
                TIMELINE_LIMIT_DAILY="$_daily" \
                TIMELINE_LIMIT_WEEKLY="$_weekly" \
                TIMELINE_LIMIT_MONTHLY="$_monthly" \
                TIMELINE_LIMIT_YEARLY="$_yearly" \
                2>/dev/null \
                || warn "snapper set-config" "Could not tune '$_cfg_name' — you can adjust it later in /etc/snapper/configs/$_cfg_name"
            ok "Retention tuned for '$_cfg_name'"

            _snapper_configs+=("$_cfg_name")
        done

        # ── Fix .snapshots permissions so non-root can list snapshots ─────────
        for _cfg in "${_snapper_configs[@]}"; do
            _cfg_mp=$(snapper -c "$_cfg" get-config 2>/dev/null | awk '/^SUBVOLUME/{print $3}')
            if [[ -d "${_cfg_mp}/.snapshots" ]]; then
                sudo chmod 750 "${_cfg_mp}/.snapshots" 2>/dev/null || true
                sudo chown root:"$USER" "${_cfg_mp}/.snapshots" 2>/dev/null || true
            fi
        done
        ok ".snapshots permissions set"

        # ── Enable timers ─────────────────────────────────────────────────────
        task "Enabling snapshot timers ${DIM}(timeline + cleanup)${R}" \
            sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

        # snap-pac triggers a pre/post snapshot around every pacman transaction
        if pacman -Q snap-pac &>/dev/null; then
            ok "snap-pac installed — pacman transactions will be snapshotted automatically"
        else
            skip "snap-pac (not installed — pacman hooks won't trigger snapshots)"
        fi

        # ── Limine snapshot sync ───────────────────────────────────────────────
        if command -v limine-snapper-sync &>/dev/null; then
            task "Enabling Limine snapshot sync ${DIM}(bootable snapshots)${R}" \
                sudo systemctl enable --now limine-snapper-sync.service
        else
            skip "limine-snapper-sync (not installed)"
        fi

    else
        skip "Btrfs snapshots — Snapper (root filesystem is not Btrfs)"
    fi
fi

# ── Phase 9 — User environment ────────────────────────────────────────────────────
section "User environment"

step "Initializing XDG user directories..."
xdg-user-dirs-update
ok "XDG user directories created"

step "Deploying dotfiles... ${DIM}(creating symlinks via stow)${R}"
mkdir -p ~/.dotfiles
cp -R "$SCRIPT_DIR/dotfiles/"* ~/.dotfiles 2>/dev/null || true
rm -rf ~/.config/fish ~/.config/hypr
(cd ~/.dotfiles && stow fish kitty nvim rofi wp fastfetch dunst hyprland opencode tmux) \
    || die "stow failed — check for pre-existing config conflicts"
ok "Dotfiles applied via stow"

step "Applying GTK theme... ${DIM}(Yaru-Grey-dark & Papirus)${R}"
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-Grey-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# Write GTK3 and GTK4 settings explicitly for Wayland/Hyprland (gsettings may not persist)
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat > ~/.config/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Yaru-Grey-dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=true
EOF
cat > ~/.config/gtk-4.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=Yaru-Grey-dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=true
EOF
ok "Theme: Yaru-Grey-dark  ·  Icons: Papirus-Dark"

step "Setting up Tmux Plugin Manager..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    task "Cloning TPM" git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
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

step "Initializing locate database..."
sudo updatedb
ok "locate database built"

# ── Done ──────────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GRAY}──────────────────────────────────────────────────────${R}"
echo ""
echo -e "  ${GREEN}${B}✓  Setup complete${R}  ${GRAY}($(_elapsed))${R}"
echo ""
echo -e "  ${GRAY}Next steps:${R}"
echo -e "  ${BLUE}·${R}  Log out and back in  ${GRAY}→ apply docker / libvirt group changes${R}"
echo -e "  ${BLUE}·${R}  Reboot               ${GRAY}→ apply kernel, driver, and shell changes${R}"
if pacman -Q opencode-bin &>/dev/null; then
    echo -e "  ${BLUE}·${R}  Configure OpenCode   ${GRAY}→ add your API keys before first use${R}"
fi
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

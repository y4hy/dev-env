# Function to start Hyprland with proper environment setup
function start-hyprland --description "Start Hyprland with NVIDIA and keyring support"
    # Ensure XDG directories are set
    set -gx XDG_SESSION_TYPE wayland
    set -gx XDG_CURRENT_DESKTOP Hyprland
    set -gx XDG_SESSION_DESKTOP Hyprland

    # NVIDIA-specific environment variables for Wayland
    set -gx LIBVA_DRIVER_NAME nvidia
    set -gx GBM_BACKEND nvidia-drm
    set -gx __GLX_VENDOR_LIBRARY_NAME nvidia
    set -gx WLR_NO_HARDWARE_CURSORS 1
    set -gx NVD_BACKEND direct

    # Qt/GTK Wayland support
    set -gx QT_QPA_PLATFORM "wayland;xcb"
    set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
    set -gx GDK_BACKEND "wayland,x11"
    set -gx MOZ_ENABLE_WAYLAND 1
    set -gx ELECTRON_OZONE_PLATFORM_HINT auto

    # Start Hyprland
    exec Hyprland
end

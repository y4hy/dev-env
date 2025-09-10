# =====================================================================
# GREETING
# =====================================================================
# Disable the default welcome message for a cleaner start.
set -g fish_greeting

# Look up to Oh My Fish !!!!

# Add last current directory

# =====================================================================
# KEY BINDINGS & EDITOR
# =====================================================================
# Enable Vi key bindings. Use 'i' for insert mode and 'Escape' for command mode.
fish_vi_key_bindings

# Set your default command-line editor (e.g., for `funced`).
# Options: 'nvim', 'vim', 'nano', 'code'
set -x EDITOR nvim

# Cursor's theme and shape
if status is-interactive
    set fish_cursor_default block
    set fish_cursor_insert block
    set fish_cursor_replace_one block
    set fish_cursor_visual block
end

# =====================================================================
# PATH VARIABLES
# =====================================================================
# Use the modern 'fish_add_path' to safely add directories to your PATH.
# This function prevents duplicate entries.

fish_add_path /home/y4hy/go/bin
fish_add_path /home/y4hy/tools
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

# =====================================================================
# ENVIRONMENT VARIABLES
# =====================================================================
# Use 'set -x' to export variables for other programs to access.

set -x SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"
set -x SSH_ASKPASS /usr/bin/lxqt-openssh-askpass
set -x BROWSER 'zen-browser'

# =====================================================================
# ALIASES
# =====================================================================
# Define shortcuts for frequently used commands.

alias ls 'ls --color=auto --hyperlink=auto'
alias ll 'ls -l'
alias la 'ls -la'
alias cat 'bat --paging=never' # Requires 'bat' to be installed
alias update 'sudo pacman -Syu' # For Debian/Ubuntu based systems

# =====================================================================
# CUSTOM FUNCTIONS
# =====================================================================
# A simple function to create a directory and change into it.
function mkcd
    mkdir -p $argv[1]
    and cd $argv[1]
end

function c
    clear
end

function gs
    git status
end

function gpl
    git pull
end

function gf
    git fetch
end

# =====================================================================
# OTOMATİK BAŞLATMA MANTIĞI (HYPRLAND veya TMUX)
# =====================================================================
# Bu mantık, bir TTY'den giriş yapıldığında Hyprland'in,
# Hyprland içinde Kitty terminali açıldığında ise tmux'ın
# birbirini engellemeden başlamasını sağlar.

# Grafik bir oturumun çalışmadığını (-z "$DISPLAY") ve TTY1'de olduğumuzu kontrol et.
if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
    # Eğer koşul doğruysa, mevcut shell işlemini Hyprland ile değiştir.
    # Bu komuttan sonra bu script'teki hiçbir şey çalışmaz.
    exec Hyprland
end

# # İlk olarak, sistemde 'tmux' komutunun var olup olmadığını kontrol et (quiet mode)
# if command -q tmux
#     # İkinci olarak, zaten bir tmux oturumunun içinde OLMADIĞIMIZI kontrol et.
#     # Bu, iç içe oturum (nested session) hatasını önleyen en kritik adımdır.
#     if not set -q TMUX
#         # 'main' isminde bir oturum var mı diye kontrol et (hata mesajlarını gizle)
#         if tmux has-session -t main ^/dev/null
#             # Varsa, 'main' oturumuna bağlan
#             tmux attach-session -t main
#         else
#             # 'main' yoksa, başka herhangi bir oturum var mı diye bak.
#             # `test -n` komutu, parantez içindeki komutun bir çıktı üretip üretmediğini kontrol eder.
#             if test -n (tmux list-sessions -F '#{session_name}' ^/dev/null)
#                 # Varsa, ilk oturumun ismini 'session' değişkenine ata
#                 set session (tmux list-sessions -F '#{session_name}' | head -n1)
#                 # Ve o oturuma bağlan
#                 tmux attach-session -t "$session"
#             else
#                 # Hiç oturum yoksa, 'main' isminde yeni bir tane oluştur
#                 tmux new-session -s main -c "$HOME"
#             end
#         end
#     end
# end

if status is-interactive; and not set -q TMUX
    tmux attach-session 2>/dev/null || tmux new-session -s main
end

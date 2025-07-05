
# disable fish greeting
set -g fish_greeting

# set fish prompt
if status is-interactive
    set fish_cursor_default block
    set fish_cursor_insert block
    set fish_cursor_replace_one block
    set fish_cursor_visual block
end

# enable last working directory
set -q fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && cd "$fish_most_recent_dir"

function save_dir --on-variable PWD
    set -U fish_most_recent_dir $PWD
end

# enable fish vi key bindings
fish_vi_key_bindings

# launchin fish after tty1 login
if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
    exec Hyprland
end

# path variables
fish_add_path /home/y4hy/go/bin
fish_add_path /home/y4hy/tools

# environment variables
set -x SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"
set -x SSH_ASKPASS /usr/bin/lxqt-openssh-askpass

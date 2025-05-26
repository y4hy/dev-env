if status is-interactive
    set fish_cursor_default block
    set fish_cursor_insert block
    set fish_cursor_replace_one block
    set fish_cursor_visual block
end

set -q fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && cd "$fish_most_recent_dir"

function save_dir --on-variable PWD
    set -U fish_most_recent_dir $PWD
end

fish_vi_key_bindings

if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
    exec Hyprland
end

fish_add_path /home/y4hy/go/bin
fish_add_path /home/y4hy/tools

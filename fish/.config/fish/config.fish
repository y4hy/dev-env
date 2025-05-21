# Sadece interaktif oturumlar için ayarlar
if status is-interactive
    set fish_cursor_default block
    set fish_cursor_insert block
    set fish_cursor_replace_one block
    set fish_cursor_visual block
end

# Kayıtlı dizine dön
set -q fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && cd "$fish_most_recent_dir"

# Dizin değişimini kaydet
function save_dir --on-variable PWD
    set -U fish_most_recent_dir $PWD
end

#vim keybindings
fish_vi_key_bindings


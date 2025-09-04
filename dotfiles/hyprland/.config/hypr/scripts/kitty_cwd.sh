#!/bin/sh

# Use the full path for each command to avoid PATH issues.
# Replace the paths below with the output from YOUR 'which' commands.
HYPRCTL_PATH="/usr/bin/hyprctl"
JQ_PATH="/usr/bin/jq"
KITTY_PATH="/usr/bin/kitty" # Or /home/your_user/.local/bin/kitty, etc.
READLINK_PATH="/usr/bin/readlink"


active_window_json=$($HYPRCTL_PATH activewindow -j)
active_pid=$(echo "$active_window_json" | $JQ_PATH -r '.pid // empty')
active_class=$(echo "$active_window_json" | $JQ_PATH -r '.class // empty')

if [ -n "$active_pid" ] && [ "$active_class" = "kitty" ]; then
    target_cwd=$($READLINK_PATH "/proc/${active_pid}/cwd")
    
    if [ -n "$target_cwd" ]; then
        $KITTY_PATH --directory "$target_cwd"
        exit 0
    fi
fi

$KITTY_PATH

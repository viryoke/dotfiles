#!/usr/bin/env bash
# Emoji picker — managed by chezmoi
# Uses rofi-emoji plugin for Wayland emoji selection

pkill rofi && exit 0

export ROFI_CLIPBOARD="wl-copy"

ROFI_THEME="$HOME/.config/rofi-wayland/themes/shared"

rofi -modi emoji -show emoji \
    -theme "$ROFI_THEME" \
    -theme-str "window { width: 30em; height: 30em; }" \
    -theme-str "listview { columns: 8; lines: 10; }" \
    -theme-str "element-icon { size: 2em; }" \
    -theme-str "element { padding: 4px; border-radius: 8px; }"

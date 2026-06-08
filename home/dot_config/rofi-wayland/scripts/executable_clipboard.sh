#!/usr/bin/env bash
# Clipboard history browser — managed by chezmoi
# Uses cliphist for Wayland clipboard history management

pkill rofi && exit 0

ROFI_THEME="$HOME/.config/rofi-wayland/themes/shared"

selected=$(cliphist list | rofi -dmenu -i -p "Clipboard" \
    -theme "$ROFI_THEME" \
    -theme-str "window { width: 30em; height: 30em; }" \
    -theme-str "listview { lines: 15; }")

if [ -n "$selected" ]; then
    cliphist decode "$selected" | wl-copy
fi

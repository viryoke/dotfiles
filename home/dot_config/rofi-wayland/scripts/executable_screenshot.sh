#!/usr/bin/env bash
set -uo pipefail
# Screenshot menu — managed by chezmoi
# Uses grim + slurp for Wayland-native capture (Niri compatible)

pkill rofi && exit 0

ROFI_THEME="$HOME/.config/rofi-wayland/themes/shared"

options="Fullscreen\nArea\nWindow\nTimed (5s)"

selected=$(echo -e "$options" | rofi -dmenu -i -p "Screenshot" \
    -theme "$ROFI_THEME" \
    -theme-str "window { width: 25em; height: 15em; }" \
    -theme-str "listview { lines: 4; }")

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
FILENAME="$(date +%Y-%m-%d-%H-%M-%S).png"

case "$selected" in
    "Fullscreen")
        grim "$SCREENSHOT_DIR/$FILENAME"
        ;;
    "Area")
        slurp | grim -g - "$SCREENSHOT_DIR/$FILENAME"
        ;;
    "Window")
        # Niri-specific: use built-in screenshot-window action
        if command -v niri &>/dev/null; then
            niri msg action screenshot-window
        else
            # Fallback: select window area manually
            slurp | grim -g - "$SCREENSHOT_DIR/$FILENAME"
        fi
        ;;
    "Timed (5s)")
        sleep 5
        grim "$SCREENSHOT_DIR/$FILENAME"
        ;;
esac

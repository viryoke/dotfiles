#!/usr/bin/env bash
# Wallpaper selector — managed by chezmoi
# Browse wallpapers with rofi, apply with swww (Wayland-native)

pkill rofi && exit 0

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/dotfiles"
ROFI_THEME="$HOME/.config/rofi-wayland/themes/shared"

mkdir -p "$CACHE_DIR"

# Ensure swww daemon is running
swww query &> /dev/null || swww-daemon --format xrgb &

# Check wallpaper directory
if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

wallpapers=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) | sort)

if [ -z "$wallpapers" ]; then
    notify-send "Wallpaper" "No image files found in $WALLPAPER_DIR"
    exit 1
fi

# Show filenames only in rofi
selected=$(echo "$wallpapers" | while read -r f; do basename "$f"; done | \
    rofi -dmenu -i -p "Wallpapers" \
    -theme "$ROFI_THEME" \
    -theme-str "window { width: 35em; height: 30em; }" \
    -theme-str "listview { lines: 15; }")

if [ -n "$selected" ]; then
    # Reconstruct path directly (grep with filenames containing regex chars is fragile)
    wallpaper_path="$WALLPAPER_DIR/$selected"

    if [ -f "$wallpaper_path" ]; then
        # Apply wallpaper with swww transition
        swww img "$wallpaper_path" \
            --transition-type random \
            --transition-duration 0.4 \
            --transition-fps 60

        # Cache current wallpaper path
        echo "$wallpaper_path" > "$CACHE_DIR/wallpaper.cache"
    fi
fi

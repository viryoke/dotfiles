# Wayland Launcher, Input Method & Notifications — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add rofi-wayland application launcher with 5 menu scripts, Rime input method via fcitx5, and mako notification daemon — all themed in Gruvbox Material Dark and Wayland-native.

**Architecture:** All new configs live under chezmoi source state (`home/`). Rofi-wayland gets its own config directory with subdirectories for themes and scripts. Rime/fcitx5 uses chezmoi externals to pull rime-ice data, overlaid with custom config. Mako gets a single config file. Package lists are updated in both chezmoi data (pacman/AUR) and Nix (home-manager). Platform-specific entries are gated with `{{ if eq .chezmoi.os "linux" }}` templates and `.chezmoiignore`.

**Tech Stack:** chezmoi, Nix home-manager, rofi-wayland, fcitx5-rime, mako, grim+slurp, cliphist, swww, wlogout, JetBrainsMono Nerd Font, Gruvbox Material Dark palette.

---

## File Structure

### New Files (14 total)

| File | Responsibility |
|------|---------------|
| `home/dot_config/rofi-wayland/config.rasi` | Main rofi config: drun mode, font, theme import |
| `home/dot_config/rofi-wayland/themes/gruvbox-dark.rasi` | Gruvbox Material Dark color variables |
| `home/dot_config/rofi-wayland/themes/shared.rasi` | Shared layout/sizing defaults |
| `home/dot_config/rofi-wayland/scripts/clipboard.sh` | Clipboard history picker via cliphist |
| `home/dot_config/rofi-wayland/scripts/screenshot.sh` | Screenshot menu via grim+slurp |
| `home/dot_config/rofi-wayland/scripts/emoji.sh` | Emoji picker via rofi-emoji |
| `home/dot_config/rofi-wayland/scripts/powermenu.sh` | Power menu via wlogout |
| `home/dot_config/rofi-wayland/scripts/wallpaper.sh` | Wallpaper selector via swww |
| `home/dot_config/fcitx5/profile` | Fcitx5 input method profile |
| `home/dot_config/fcitx5/conf/classicui.conf` | Fcitx5 classic UI config |
| `home/dot_local/share/fcitx5/rime/default.yaml` | Rime schema/keybinding overlay |
| `home/dot_local/bin/executable_rime-build.sh` | Rime build/deploy script |
| `home/.chezmoiscripts/run_onchange_rime-build.sh.tmpl` | Auto-build Rime on config change |
| `home/dot_config/mako/config` | Mako notification daemon config |

### Modified Files (5 total)

| File | Change |
|------|--------|
| `home/.chezmoidata/packages.yaml` | Add 11 pacman + 1 AUR packages |
| `modules/linux/packages.nix` | Add cliphist to Nix packages |
| `home/.chezmoiignore` | Add Linux-only config ignores for macOS |
| `home/dot_zshrc.tmpl` | Add 6 Linux-only aliases for rofi menus |
| `home/.chezmoiexternal.yaml` | Add rime-ice as external git repo |

---

## Gruvbox Material Dark — Color Reference

All configs reference this exact palette. Do NOT substitute Catppuccin values.

| Name | Hex | Usage |
|------|-----|-------|
| dark0_hard | `#1d2021` | Deepest background |
| dark0 | `#282828` | Primary background |
| dark1 | `#3c3836` | Secondary background / progress |
| dark2 | `#504945` | Tertiary background |
| dark3 | `#665c54` | Borders (muted) |
| light1 | `#ebdbb2` | Primary foreground / text |
| light2 | `#d5c4a1` | Secondary foreground |
| light4 | `#a89984` | Muted foreground |
| bright_red | `#fb4934` | Errors, urgent |
| bright_green | `#b8bb26` | Success markers |
| bright_yellow | `#fabd2f` | Accent, borders, highlights |
| bright_blue | `#83a598` | Selection highlight |
| bright_purple | `#d3869b` | Unset / special |
| bright_orange | `#fe8019` | Warnings |

---

### Task 1: Update Package Lists

**Files:**
- Modify: `home/.chezmoidata/packages.yaml`
- Modify: `modules/linux/packages.nix`

- [ ] **Step 1: Add new pacman packages to `packages.yaml`**

In `home/.chezmoidata/packages.yaml`, append these entries under `linux.pacman` (after the existing `btop` and `tree` entries, before the closing of the `pacman` list):

```yaml
      - "rofi-wayland"
      - "cliphist"
      - "grim"
      - "slurp"
      - "mako"
      - "wlogout"
      - "swww"
      - "imagemagick"
      - "papirus-icon-theme"
      - "fcitx5-gtk"
      - "fcitx5-chinese-addons"
```

The full `linux.pacman` section should now read:

```yaml
  linux:
    pacman:
      - "git"
      - "neovim"
      - "flatpak"
      - "fcitx5"
      - "fcitx5-rime"
      - "fcitx5-configtool"
      - "lazygit"
      - "ripgrep"
      - "fd"
      - "fzf"
      - "eza"
      - "zoxide"
      - "bat"
      - "yazi"
      - "zellij"
      - "jq"
      - "curl"
      - "wget"
      - "unzip"
      - "htop"
      - "btop"
      - "tree"
      - "rofi-wayland"
      - "cliphist"
      - "grim"
      - "slurp"
      - "mako"
      - "wlogout"
      - "swww"
      - "imagemagick"
      - "papirus-icon-theme"
      - "fcitx5-gtk"
      - "fcitx5-chinese-addons"
```

- [ ] **Step 2: Add AUR package to `packages.yaml`**

Append under `linux.aur` (after `baidunetdisk-bin`):

```yaml
      - "rofi-emoji"
```

The full `aur` section should now read:

```yaml
    aur:
      - "clash-verge-rev-bin"
      - "baidunetdisk-bin"
      - "rofi-emoji"
```

- [ ] **Step 3: Add cliphist to Nix `modules/linux/packages.nix`**

Replace the entire file content with:

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    yazi
    zellij
    cliphist
  ];
}
```

- [ ] **Step 4: Verify package data renders correctly**

Run: `chezmoi execute-template '{{ range .packages.linux.pacman }}{{ . }}\n{{ end }}' < /dev/null`
Expected: All 34 package names printed, including `rofi-wayland`, `cliphist`, `grim`, `slurp`, `mako`, `wlogout`, `swww`, `imagemagick`, `papirus-icon-theme`, `fcitx5-gtk`, `fcitx5-chinese-addons`.

Run: `chezmoi execute-template '{{ range .packages.linux.aur }}{{ . }}\n{{ end }}' < /dev/null`
Expected: `clash-verge-rev-bin`, `baidunetdisk-bin`, `rofi-emoji`.

- [ ] **Step 5: Commit**

```bash
git add home/.chezmoidata/packages.yaml modules/linux/packages.nix
git commit -m "feat(packages): add rofi-wayland, mako, grim/slurp, cliphist, swww, fcitx5 addons

Add Wayland-native tools for application launcher (rofi-wayland),
notification daemon (mako), screenshot (grim+slurp), clipboard
history (cliphist), wallpaper (swww), logout menu (wlogout),
and Chinese input support (fcitx5-gtk, fcitx5-chinese-addons).
Add rofi-emoji to AUR. Add cliphist to Nix home-manager packages."
```

---

### Task 2: Create Rofi-Wayland Configuration

**Files:**
- Create: `home/dot_config/rofi-wayland/config.rasi`
- Create: `home/dot_config/rofi-wayland/themes/shared.rasi`
- Create: `home/dot_config/rofi-wayland/themes/gruvbox-dark.rasi`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p home/dot_config/rofi-wayland/themes
mkdir -p home/dot_config/rofi-wayland/scripts
```

- [ ] **Step 2: Create shared layout defaults at `home/dot_config/rofi-wayland/themes/shared.rasi`**

```css
/* Shared layout defaults for rofi-wayland
 * Imported by config.rasi — override per-theme as needed */

configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
    display-drun: " Apps ";
    display-run: " Run ";
    display-window: " Wins ";
}

* {
    font: "JetBrainsMono Nerd Font 14";
}

window {
    location: center;
    anchor: center;
    width: 680px;
    height: 480px;
    border-radius: 12px;
}

mainbox {
    spacing: 8px;
    padding: 12px;
}

inputbar {
    spacing: 8px;
    padding: 8px 12px;
    border-radius: 8px;
}

listview {
    spacing: 4px;
    scrollbar: false;
    dynamic: true;
    lines: 8;
}

element {
    spacing: 8px;
    padding: 8px 12px;
    border-radius: 8px;
}

element-icon {
    size: 28px;
}

element-text {
    vertical-align: 0.5;
}

message {
    padding: 8px 12px;
    border-radius: 8px;
}
```

- [ ] **Step 3: Create Gruvbox Material Dark theme at `home/dot_config/rofi-wayland/themes/gruvbox-dark.rasi`**

```css
/* Gruvbox Material Dark — rofi-wayland theme
 * Palette: sainnhe/gruvbox-material */

* {
    main-bg: #282828e6;
    main-fg: #ebdbb2ff;
    main-br: #fabd2fff;
    main-ex: #d5c4a1ff;
    select-bg: #83a598ff;
    select-fg: #282828ff;
    alt-bg: #3c3836ff;
    urgent-fg: #fb4934ff;
}

window {
    background-color: @main-bg;
    border: 2px solid;
    border-color: @main-br;
}

inputbar {
    background-color: @alt-bg;
    text-color: @main-fg;
}

prompt {
    text-color: @main-br;
}

entry {
    text-color: @main-fg;
}

element {
    text-color: @main-fg;
}

element normal normal {
    text-color: @main-fg;
}

element normal urgent {
    text-color: @urgent-fg;
}

element normal active {
    text-color: @main-ex;
}

element selected normal {
    background-color: @select-bg;
    text-color: @select-fg;
}

element selected urgent {
    background-color: @select-bg;
    text-color: @urgent-fg;
}

element selected active {
    background-color: @select-bg;
    text-color: @select-fg;
}

element alternate normal {
    text-color: @main-ex;
}

element alternate urgent {
    text-color: @urgent-fg;
}

element alternate active {
    text-color: @main-ex;
}

element-icon {
    text-color: @main-fg;
}

message {
    background-color: @alt-bg;
    border: 1px solid;
    border-color: @main-br;
}

message-text {
    text-color: @main-fg;
}
```

- [ ] **Step 4: Create main config at `home/dot_config/rofi-wayland/config.rasi`**

```css
/* rofi-wayland main configuration
 * Gruvbox Material Dark theme */

@theme "shared"
@theme "gruvbox-dark"

configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    drun-display-format: "{name}";
    display-drun: " Apps ";
    display-run: " Run ";
    display-window: " Wins ";
    sidebar-mode: false;
    hover-select: true;
    me-select-entry: "";
    me-accept-entry: "MousePrimary";
}
```

- [ ] **Step 5: Commit**

```bash
git add home/dot_config/rofi-wayland/
git commit -m "feat(rofi): add rofi-wayland config with Gruvbox Material Dark theme

Main config (drun mode, JetBrainsMono Nerd Font 14, Papirus icons),
shared layout defaults, and Gruvbox Material Dark color theme.
Uses 6-color palette: dark0 bg, light1 fg, bright_yellow border,
light2 extra, bright_blue selection, dark0 selection fg."
```

---

### Task 3: Create Rofi Menu Scripts

**Files:**
- Create: `home/dot_config/rofi-wayland/scripts/clipboard.sh`
- Create: `home/dot_config/rofi-wayland/scripts/screenshot.sh`
- Create: `home/dot_config/rofi-wayland/scripts/emoji.sh`
- Create: `home/dot_config/rofi-wayland/scripts/powermenu.sh`
- Create: `home/dot_config/rofi-wayland/scripts/wallpaper.sh`

- [ ] **Step 1: Create clipboard history script at `home/dot_config/rofi-wayland/scripts/clipboard.sh`**

The chezmoi naming convention requires the `executable_` prefix for scripts that should be executable:

Create file `home/dot_config/rofi-wayland/scripts/executable_clipboard.sh`:

```bash
#!/bin/bash
# Clipboard history picker — Wayland-native via cliphist + wl-paste
# Managed by chezmoi

set -euo pipefail

if ! command -v cliphist &>/dev/null; then
    notify-send "Error" "cliphist not installed" --urgency=critical
    exit 1
fi

# Show clipboard history in rofi, decode and copy to clipboard
cliphist list | rofi -dmenu \
    -theme-str 'window { width: 680px; height: 480px; }' \
    -theme-str 'configuration { display-dmenu: " Clipboard "; }' \
    -p "" | cliphist decode | wl-copy
```

- [ ] **Step 2: Create screenshot script at `home/dot_config/rofi-wayland/scripts/executable_screenshot.sh`**

```bash
#!/bin/bash
# Screenshot menu — Wayland-native via grim + slurp
# Managed by chezmoi

set -euo pipefail

if ! command -v grim &>/dev/null; then
    notify-send "Error" "grim not installed" --urgency=critical
    exit 1
fi

SCREENSHOTS_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"
FILENAME="$SCREENSHOTS_DIR/$(date +%Y-%m-%d_%H-%m-%S).png"

CHOICE=$(printf "Full Screen\nSelect Area\nActive Window" | rofi -dmenu \
    -theme-str 'window { width: 400px; height: 180px; }' \
    -theme-str 'configuration { display-dmenu: " Screenshot "; }' \
    -p "")

case "$CHOICE" in
    "Full Screen")
        grim "$FILENAME"
        ;;
    "Select Area")
        grim -g "$(slurp)" "$FILENAME"
        ;;
    "Active Window")
        # Niri WM: get active window geometry via niri msg
        if command -v niri &>/dev/null; then
            GEOM=$(niri msg action do-screen-capture 2>/dev/null && echo "" || \
                   niri msg --json focused-window 2>/dev/null | jq -r '
                     "\(.x),\(.y) \(.width)x\(.height)"' 2>/dev/null)
            if [ -n "$GEOM" ]; then
                grim -g "$GEOM" "$FILENAME"
            else
                grim "$FILENAME"
            fi
        else
            grim "$FILENAME"
        fi
        ;;
    *)
        exit 0
        ;;
esac

if [ -f "$FILENAME" ]; then
    wl-copy < "$FILENAME"
    notify-send "Screenshot saved" "$(basename "$FILENAME")" --icon=camera-photo
fi
```

- [ ] **Step 3: Create emoji picker script at `home/dot_config/rofi-wayland/scripts/executable_emoji.sh`**

```bash
#!/bin/bash
# Emoji picker via rofi-emoji
# Managed by chezmoi

set -euo pipefail

if ! command -v rofi-emoji &>/dev/null; then
    notify-send "Error" "rofi-emoji not installed" --urgency=critical
    exit 1
fi

rofi -modi emoji -show emoji \
    -theme-str 'window { width: 680px; height: 480px; }' \
    -theme-str 'configuration { display-emoji: " Emoji "; }'
```

- [ ] **Step 4: Create power menu script at `home/dot_config/rofi-wayland/scripts/executable_powermenu.sh`**

```bash
#!/bin/bash
# Power menu via wlogout — Wayland-native
# Managed by chezmoi

set -euo pipefail

if command -v wlogout &>/dev/null; then
    wlogout --protocol layer-shell -b 3 -T 0.3
else
    # Fallback: rofi-based power menu
    CHOICE=$(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | rofi -dmenu \
        -theme-str 'window { width: 400px; height: 260px; }' \
        -theme-str 'configuration { display-dmenu: " Power "; }' \
        -p "")

    case "$CHOICE" in
        "Lock")
            if command -v swaylock &>/dev/null; then swaylock -f; fi
            ;;
        "Logout")
            if command -v niri &>/dev/null; then niri msg action do-quit; fi
            ;;
        "Suspend")
            systemctl suspend
            ;;
        "Reboot")
            systemctl reboot
            ;;
        "Shutdown")
            systemctl poweroff
            ;;
    esac
fi
```

- [ ] **Step 5: Create wallpaper selector script at `home/dot_config/rofi-wayland/scripts/executable_wallpaper.sh`**

```bash
#!/bin/bash
# Wallpaper selector via swww — Wayland-native
# Managed by chezmoi

set -euo pipefail

WALLPAPER_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"

if ! command -v swww &>/dev/null; then
    notify-send "Error" "swww not installed" --urgency=critical
    exit 1
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Error" "Wallpaper directory not found: $WALLPAPER_DIR" --urgency=critical
    exit 1
fi

# Build list of wallpapers with preview names
WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
    -printf "%f\n" | sort)

if [ -z "$WALLPAPERS" ]; then
    notify-send "No wallpapers found" "Add images to $WALLPAPER_DIR"
    exit 0
fi

SELECTED=$(echo "$WALLPAPERS" | rofi -dmenu \
    -theme-str 'window { width: 680px; height: 480px; }' \
    -theme-str 'configuration { display-dmenu: " Wallpaper "; }' \
    -p "" \
    -show-icons \
    -icon-theme "Papirus-Dark")

if [ -n "$SELECTED" ]; then
    FULL_PATH="$WALLPAPER_DIR/$SELECTED"

    # Detect image luminance to adjust bar/text colors if needed
    if command -v identify &>/dev/null; then
        LUMINANCE=$(identify -format "%[fx:mean]" "$FULL_PATH" 2>/dev/null || echo "0.5")
        # luminance > 0.5 = light image, < 0.5 = dark image
    fi

    swww img "$FULL_PATH" \
        --transition-type grow \
        --transition-angle 135 \
        --transition-step 20 \
        --transition-duration 1

    notify-send "Wallpaper set" "$SELECTED" --icon=image
fi
```

- [ ] **Step 6: Commit**

```bash
git add home/dot_config/rofi-wayland/scripts/
git commit -m "feat(rofi): add 5 Wayland-native menu scripts

clipboard.sh: cliphist + wl-copy (Wayland clipboard history)
screenshot.sh: grim + slurp (full/area/window capture)
emoji.sh: rofi-emoji picker
powermenu.sh: wlogout with rofi fallback
wallpaper.sh: swww with luminance detection via imagemagick"
```

---

### Task 4: Add Mako Notification Daemon Config

**Files:**
- Create: `home/dot_config/mako/config`

- [ ] **Step 1: Create directory**

```bash
mkdir -p home/dot_config/mako
```

- [ ] **Step 2: Create mako config at `home/dot_config/mako/config`**

```ini
# mako — Wayland-native notification daemon
# Gruvbox Material Dark theme
# Managed by chezmoi

# === Global defaults ===
font=JetBrainsMono Nerd Font 13
background-color=#282828e0
text-color=#ebdbb2
border-color=#fabd2f
border-size=3
border-radius=8
progress-color=over #3c3836
padding=12
max-width=380
max-height=200
width=380
height=200
margin=10
format=<b>%s</b>\n%b
default-timeout=5000
ignore-timeout=0
layer=top
sort=-time

# === Urgency: low ===
[urgency=low]
border-color=#665c54
text-color=#d5c4a1
default-timeout=3000

# === Urgency: normal ===
[urgency=normal]
border-color=#fabd2f
default-timeout=5000

# === Urgency: critical ===
[urgency=critical]
border-color=#fb4934
text-color=#fb4934
default-timeout=0
```

- [ ] **Step 3: Commit**

```bash
git add home/dot_config/mako/
git commit -m "feat(mako): add notification daemon config with Gruvbox Dark theme

Wayland-native notification daemon. Gruvbox Material Dark colors:
dark0 bg, light1 fg, bright_yellow border (normal), bright_red
(critical), dark3 (low). JetBrainsMono Nerd Font 13."
```

---

### Task 5: Configure Rime Input Method via chezmoi External

**Files:**
- Modify: `home/.chezmoiexternal.yaml`
- Create: `home/dot_config/fcitx5/profile`
- Create: `home/dot_config/fcitx5/conf/classicui.conf`
- Create: `home/dot_local/share/fcitx5/rime/default.yaml`
- Create: `home/dot_local/bin/executable_rime-build.sh`
- Create: `home/.chezmoiscripts/run_onchange_rime-build.sh.tmpl`

- [ ] **Step 1: Add rime-ice as chezmoi external in `home/.chezmoiexternal.yaml`**

Replace the entire file content with:

```yaml
# External dependencies managed by chezmoi

# rime-ice: Chinese input method data for Rime
# Cloned to ~/.local/share/fcitx5/rime/ — custom configs overlay on top
".local/share/fcitx5/rime":
  type: "git-repo"
  url: "https://github.com/iDvel/rime-ice.git"
  refreshPeriod: "168h"
  clone:
    args: ["--depth=1"]
  pull:
    args: ["--ff-only"]
```

- [ ] **Step 2: Create fcitx5 profile at `home/dot_config/fcitx5/profile`**

```bash
mkdir -p home/dot_config/fcitx5/conf
```

```ini
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=rime

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
Layout=

[Groups/0/Items/1]
# Name
Name=rime
# Layout
Layout=

[GroupOrder]
0=Default
```

- [ ] **Step 3: Create fcitx5 classicui config at `home/dot_config/fcitx5/conf/classicui.conf`**

```ini
# Fcitx5 Classic UI — Gruvbox-friendly settings
# Managed by chezmoi
# NOTE: Uses neutral theme name (not catppuccin). Font and colors
# are configured via the system fcitx5 theme or GTK theme.

# Font
Font="JetBrainsMono Nerd Font 14"
# Menu Font
MenuFont="JetBrainsMono Nerd Font 13"
# Tray Font
TrayFont="JetBrainsMono Nerd Font 12"

# Use system theme (Gruvbox Material Dark via GTK theme)
Theme=default

# Vertical candidate list
Vertical Candidate List=True
# Wheel speed
WheelSpeed=3
# Per screen DPI
PerScreenDPI=True
# Force font DPI (0 = auto)
ForceFontDPI=0
```

- [ ] **Step 4: Create Rime default.yaml overlay at `home/dot_local/share/fcitx5/rime/default.yaml`**

This file overlays on top of the rime-ice external. Rime merges user `default.yaml` with the base.

```yaml
# Rime default configuration — user overlay
# Managed by chezmoi (overlays on top of rime-ice external)
#
# rime-ice provides the base schemas; this file customizes
# the schema list and keybindings.

patch:
  schema_list:
    - schema: rime_ice          # 雾凇拼音 (primary)
    - schema: double_pinyin_flypy  # 小鹤双拼
    - schema: luna_pinyin       # 朙月拼音 (fallback)

  switcher/hotkeys:
    - "Control+grave"           # Ctrl+` to open schema switcher
    - "F4"

  menu/page_size: 7             # Candidates per page

  ascii_composer/good_old_caps_lock: true
  ascii_composer/switch_key:
    Caps_Lock: clear
    Shift_L: commit_code
    Shift_R: commit_code
    Control_L: noop
    Control_R: noop
```

- [ ] **Step 5: Create Rime build script at `home/dot_local/bin/executable_rime-build.sh`**

```bash
#!/bin/bash
# Build/deploy Rime input method tables
# Managed by chezmoi
#
# This script:
# 1. Symlinks system rime-data (if available) for shared schemas
# 2. Runs rime_deployer to compile user schemas

set -euo pipefail

RIME_USER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/rime"
RIME_SYSTEM_DIR="/usr/share/rime-data"

echo "=== Rime Build ==="
echo "User dir: $RIME_USER_DIR"

# Symlink system rime-data schemas if they exist and aren't already linked
if [ -d "$RIME_SYSTEM_DIR" ]; then
    echo "Linking system rime-data..."
    for f in "$RIME_SYSTEM_DIR"/*.yaml; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        target="$RIME_USER_DIR/$base"
        # Only link if user dir doesn't have its own version
        if [ ! -e "$target" ]; then
            ln -sf "$f" "$target"
        fi
    done
fi

# Run rime_deployer to compile
if command -v rime_deployer &>/dev/null; then
    echo "Running rime_deployer..."
    rime_deployer --compile "$RIME_USER_DIR" "$RIME_SYSTEM_DIR"
    echo "=== Rime build complete ==="
elif command -v librime-data &>/dev/null; then
    echo "Running librime-data deployer..."
    /usr/lib/rime/rime_deployer --compile "$RIME_USER_DIR" "$RIME_SYSTEM_DIR"
    echo "=== Rime build complete ==="
else
    echo "WARNING: rime_deployer not found. Install rime-data or librime."
    echo "You can also trigger a deploy from fcitx5-configtool."
    exit 1
fi
```

- [ ] **Step 6: Create auto-build chezmoi script at `home/.chezmoiscripts/run_onchange_rime-build.sh.tmpl`**

```bash
#!/bin/bash
set -euo pipefail

{{ if eq .chezmoi.os "linux" -}}
# Auto-build Rime after chezmoi apply changes rime config
# This script runs when rime config files change (chezmoi onchange)

echo "=== Auto-building Rime input method ==="

RIME_BUILD="$HOME/.local/bin/rime-build.sh"
if [ -x "$RIME_BUILD" ]; then
    "$RIME_BUILD"
else
    echo "WARNING: rime-build.sh not found or not executable at $RIME_BUILD"
fi

echo "=== Rime auto-build complete ==="
{{ end -}}
```

- [ ] **Step 7: Commit**

```bash
git add home/.chezmoiexternal.yaml \
    home/dot_config/fcitx5/ \
    home/dot_local/share/fcitx5/ \
    home/dot_local/bin/executable_rime-build.sh \
    home/.chezmoiscripts/run_onchange_rime-build.sh.tmpl
git commit -m "feat(rime): add Rime input method via chezmoi external

- chezmoi external pulls rime-ice repo to ~/.local/share/fcitx5/rime/
- fcitx5 profile: keyboard-us + rime input methods
- fcitx5 classicui: JetBrainsMono Nerd Font, neutral theme
- Rime default.yaml: rime_ice + double_pinyin_flypy schemas
- rime-build.sh: symlinks system rime-data, runs rime_deployer
- Auto-build on chezmoi config change via onchange script"
```

---

### Task 6: Update chezmoiignore for Linux-Only Configs

**Files:**
- Modify: `home/.chezmoiignore`

- [ ] **Step 1: Append Linux-only ignores to `home/.chezmoiignore`**

Add the following block at the end of the file (after the existing `{{ if ne .chezmoi.os "linux" }}` block that has `dot_config/waybar/` and `dot_config/swaylock/`):

```
{{ if ne .chezmoi.os "linux" }}
dot_config/rofi-wayland/
dot_config/mako/
dot_config/fcitx5/
dot_local/share/fcitx5/
dot_local/bin/executable_rime-build.sh
{{ end }}
```

The full file should now read:

```
README.md
LICENSE
flake.nix
flake.lock
hosts/
modules/
overlays/
pkgs/
secrets/
scripts/
docs/

{{ if ne .chezmoi.os "darwin" }}
dot_config/karabiner/
{{ end }}

{{ if ne .chezmoi.os "linux" }}
dot_config/waybar/
dot_config/swaylock/
{{ end }}

{{ if ne .chezmoi.os "linux" }}
dot_config/rofi-wayland/
dot_config/mako/
dot_config/fcitx5/
dot_local/share/fcitx5/
dot_local/bin/executable_rime-build.sh
{{ end }}
```

- [ ] **Step 2: Verify chezmoi parses the ignore file correctly**

Run: `chezmoi status`
Expected: No errors about unknown paths. On macOS, the new paths should appear as ignored.

- [ ] **Step 3: Commit**

```bash
git add home/.chezmoiignore
git commit -m "chore(chezmoi): ignore Linux-only configs on macOS

Add conditional ignores for rofi-wayland, mako, fcitx5,
rime data, and rime-build.sh when not on Linux."
```

---

### Task 7: Add Zsh Aliases for Rofi Menus

**Files:**
- Modify: `home/dot_zshrc.tmpl`

- [ ] **Step 1: Append Linux-only rofi aliases to `home/dot_zshrc.tmpl`**

Add the following block at the end of the file (after the existing auto-launch zellij block):

```bash
{{ if eq .chezmoi.os "linux" }}

# === Rofi Menus (Wayland) ===
alias launcher='rofi -show drun'
alias cliphist='~/.config/rofi-wayland/scripts/clipboard.sh'
alias screenshot='~/.config/rofi-wayland/scripts/screenshot.sh'
alias emoji='~/.config/rofi-wayland/scripts/emoji.sh'
alias powermenu='~/.config/rofi-wayland/scripts/powermenu.sh'
alias wallpaper='~/.config/rofi-wayland/scripts/wallpaper.sh'
{{ end }}
```

The block should be placed after the zellij auto-launch block (after line 75 of the current file) and before the final newline.

- [ ] **Step 2: Verify template renders correctly for Linux**

Run: `chezmoi execute-template < home/dot_zshrc.tmpl | tail -20`
Expected: On Linux, the last lines should show the 6 alias definitions. On macOS, the `{{ if }}` block should be empty (aliases omitted).

- [ ] **Step 3: Commit**

```bash
git add home/dot_zshrc.tmpl
git commit -m "feat(zsh): add Linux-only aliases for rofi menu scripts

launcher: rofi drun app launcher
cliphist: clipboard history picker
screenshot: grim+slurp screenshot menu
emoji: rofi-emoji picker
powermenu: wlogout power menu
wallpaper: swww wallpaper selector"
```

---

### Task 8: Verify Full chezmoi Apply (Dry Run)

**Files:** None (verification only)

- [ ] **Step 1: Run chezmoi diff to see all pending changes**

```bash
chezmoi diff
```

Expected output should show:
- New files under `~/.config/rofi-wayland/` (config.rasi, themes/, scripts/)
- New files under `~/.config/mako/config`
- New files under `~/.config/fcitx5/` (profile, conf/classicui.conf)
- New file `~/.local/share/fcitx5/rime/default.yaml`
- New executable `~/.local/bin/rime-build.sh`
- Modified `~/.zshrc` with new aliases (Linux only)
- New chezmoi external for rime-ice

- [ ] **Step 2: Run chezmoi apply in verbose mode**

```bash
chezmoi apply --verbose
```

Expected: All files deployed without errors. On macOS, Linux-only configs should be skipped (per `.chezmoiignore`).

- [ ] **Step 3: Verify file permissions on scripts**

```bash
ls -la ~/.config/rofi-wayland/scripts/
ls -la ~/.local/bin/rime-build.sh
```

Expected: All `.sh` scripts should have execute permission (`-rwxr-xr-x`), because they were created with the `executable_` prefix in chezmoi source state.

- [ ] **Step 4: Verify rofi can parse its config**

```bash
rofi -dump-config 2>/dev/null | head -20
```

Expected: No parse errors. Config should show drun mode, JetBrainsMono font, theme loaded.

- [ ] **Step 5: Verify mako can parse its config**

```bash
mako --config ~/.config/mako/config --validate 2>&1 || true
```

Expected: No validation errors (or mako starts and shows test notification).

- [ ] **Step 6: No commit needed (verification only)**

---

## Summary of Commits

| # | Commit Message |
|---|---------------|
| 1 | `feat(packages): add rofi-wayland, mako, grim/slurp, cliphist, swww, fcitx5 addons` |
| 2 | `feat(rofi): add rofi-wayland config with Gruvbox Material Dark theme` |
| 3 | `feat(rofi): add 5 Wayland-native menu scripts` |
| 4 | `feat(mako): add notification daemon config with Gruvbox Dark theme` |
| 5 | `feat(rime): add Rime input method via chezmoi external` |
| 6 | `chore(chezmoi): ignore Linux-only configs on macOS` |
| 7 | `feat(zsh): add Linux-only aliases for rofi menu scripts` |

---

## Post-Implementation Checklist

After all tasks are complete and chezmoi apply succeeds:

1. **Install packages**: Run `chezmoi apply` then trigger the linux-packages onchange script (or run `sudo pacman -S` manually for the new packages)
2. **Rime first build**: Run `~/.local/bin/rime-build.sh` manually after packages are installed
3. **Fcitx5 environment variables**: Ensure these are set in your session (add to Niri or shell env if missing):
   ```
   GTK_IM_MODULE=fcitx
   QT_IM_MODULE=fcitx
   XMODIFIERS=@im=fcitx
   ```
4. **Test rofi**: Run `rofi -show drun` — should show app launcher with Gruvbox theme
5. **Test mako**: Run `notify-send "Test" "Gruvbox notification"` — should show styled notification
6. **Test scripts**: Run each alias (`launcher`, `cliphist`, `screenshot`, `emoji`, `powermenu`, `wallpaper`)
7. **macOS verification**: Run `chezmoi apply` on MacBook — confirm Linux-only configs are skipped

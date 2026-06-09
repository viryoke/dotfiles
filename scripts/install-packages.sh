#!/usr/bin/env bash
# Manual package installer for CachyOS/Arch Linux
# Run this once after 'chezmoi apply' to install all packages
# This allows interactive conflict resolution (e.g., nvidia driver conflicts)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_YAML="${DOTFILES_DIR}/home/.chezmoidata/packages.yaml"

if [ ! -f "$PACKAGES_YAML" ]; then
  echo "Error: $PACKAGES_YAML not found"
  exit 1
fi

echo "=== Linux Package Installer ==="
echo "This script installs packages interactively, allowing you to resolve conflicts."
echo ""

# Extract packages from YAML (simple grep-based parser)
get_pacman_packages() {
  awk '/^    pacman:$/,/^    [a-z]/' "$PACKAGES_YAML" | grep '^      - ' | sed 's/.*"\(.*\)"/\1/' | tr '\n' ' '
}

get_pacman_amd64_packages() {
  awk '/^    pacman_amd64:$/,/^    [a-z]/' "$PACKAGES_YAML" | grep '^      - ' | sed 's/.*"\(.*\)"/\1/' | tr '\n' ' '
}

get_aur_packages() {
  awk '/^    aur:$/,/^  [a-z]/' "$PACKAGES_YAML" | grep '^      - ' | sed 's/.*"\(.*\)"/\1/' | tr '\n' ' '
}

get_flatpak_packages() {
  awk '/^    flatpak:$/,/^    [a-z]/' "$PACKAGES_YAML" | grep '^      - ' | sed 's/.*"\(.*\)"/\1/'
}

# Step 1: Pacman packages
PACMAN_PKGS=$(get_pacman_packages)
if [ -n "$PACMAN_PKGS" ]; then
  echo "=== Step 1: Installing pacman packages ==="
  echo "Packages: $PACMAN_PKGS"
  echo ""
  sudo pacman -S --needed $PACMAN_PKGS
  echo ""
fi

# Step 2: Pacman amd64-specific packages
if [ "$(uname -m)" = "x86_64" ]; then
  PACMAN_AMD64_PKGS=$(get_pacman_amd64_packages)
  if [ -n "$PACMAN_AMD64_PKGS" ]; then
    echo "=== Step 2: Installing amd64-specific packages ==="
    echo "Packages: $PACMAN_AMD64_PKGS"
    echo ""
    sudo pacman -S --needed $PACMAN_AMD64_PKGS
    echo ""
  fi
fi

# Step 3: AUR packages
AUR_PKGS=$(get_aur_packages)
if [ -n "$AUR_PKGS" ]; then
  echo "=== Step 3: Installing AUR packages ==="
  if command -v yay &>/dev/null; then
    yay -S --needed $AUR_PKGS
  elif command -v paru &>/dev/null; then
    paru -S --needed $AUR_PKGS
  else
    echo "WARNING: No AUR helper found (yay/paru). Skipping: $AUR_PKGS"
  fi
  echo ""
fi

# Step 4: Flatpak packages
FLATPAK_PKGS=$(get_flatpak_packages)
if [ -n "$FLATPAK_PKGS" ] && command -v flatpak &>/dev/null; then
  echo "=== Step 4: Installing Flatpak packages ==="
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  for pkg in $FLATPAK_PKGS; do
    echo "Installing $pkg..."
    flatpak install --user -y flathub "$pkg"
  done
  echo ""
fi

echo "=== Package installation complete ==="

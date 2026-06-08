#!/bin/bash
set -euo pipefail

DOTFILES_REPO="viryoke/dotfiles"
DOTFILES_DIR="${HOME}/.local/share/chezmoi"

echo "=== viryoke/dotfiles Bootstrap ==="
echo ""

echo "--- Phase 0: Environment Detection ---"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
HOSTNAME="$(hostname)"
echo "OS: $OS | Arch: $ARCH | Hostname: $HOSTNAME"

if [ "$OS" = "linux" ] && [ -f /etc/os-release ]; then
  DISTRO=$(. /etc/os-release && echo "$ID")
  echo "Distro: $DISTRO"
fi

echo ""
echo "--- Phase 1: Installing Minimal Dependencies ---"
if [ "$OS" = "linux" ]; then
  if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm git chezmoi
  else
    echo "ERROR: Only Arch-based systems (CachyOS) are supported for Linux."
    exit 1
  fi
elif [ "$OS" = "darwin" ]; then
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "Complete Xcode CLI tools installation and re-run."
    exit 1
  fi
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew install chezmoi
fi

if ! command -v nix &>/dev/null; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  if [ -f /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
  elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi

echo ""
echo "--- Phase 2: chezmoi Initialization ---"
chezmoi init "$DOTFILES_REPO"
chezmoi apply

echo ""
echo "--- Phase 3: Nix home-manager Deployment ---"
if command -v nix &>/dev/null; then
  cd "$DOTFILES_DIR"
  nix run home-manager -- switch --flake ".#viryoke@${HOSTNAME}" --impure || {
    echo "WARNING: home-manager switch failed. Try manually after fixing issues."
  }
fi

echo ""
echo "--- Phase 4: Verification ---"
if [ -f "$DOTFILES_DIR/scripts/doctor.sh" ]; then
  bash "$DOTFILES_DIR/scripts/doctor.sh"
fi

echo ""
echo "=== Bootstrap Complete ==="
echo "Next: 1) Import age identity key  2) Configure SSH keys  3) Restart terminal"

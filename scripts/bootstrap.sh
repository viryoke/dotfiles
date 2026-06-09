#!/bin/bash
set -euo pipefail

DOTFILES_REPO="https://github.com/viryoke/dotfiles.git"
DOTFILES_DIR="${HOME}/dotfiles"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     viryoke/dotfiles Bootstrap           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- Phase 0: Environment Detection ---
echo "--- Phase 0: Environment Detection ---"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
RAW_HOSTNAME="$(hostname)"

if echo "$RAW_HOSTNAME" | grep -qi "macbook"; then
  HOSTNAME="macbook"
else
  HOSTNAME="$RAW_HOSTNAME"
fi
echo "OS: $OS | Arch: $ARCH | Hostname: $HOSTNAME"

if [ "$OS" = "linux" ] && [ -f /etc/os-release ]; then
  DISTRO=$(. /etc/os-release && echo "$ID")
  echo "Distro: $DISTRO"
fi
echo ""

# --- Phase 1: Install Dependencies ---
echo "--- Phase 1: Installing Dependencies ---"
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
    echo "Complete Xcode CLI tools installation and re-run this script."
    exit 1
  fi
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew install git chezmoi
fi
echo ""

# --- Phase 2: Install Nix (single-user) ---
echo "--- Phase 2: Nix Package Manager ---"
if ! command -v nix &>/dev/null; then
  echo "Installing Nix (single-user mode)..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi
# Load Nix into current shell
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
if command -v nix &>/dev/null; then
  echo "Nix $(nix --version)"
fi
echo ""

# --- Phase 3: Clone Repository ---
echo "--- Phase 3: Clone Repository ---"
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Repository already exists at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only || git -C "$DOTFILES_DIR" fetch origin && git -C "$DOTFILES_DIR" reset --hard origin/main
elif [ -d "$DOTFILES_DIR" ]; then
  echo "$DOTFILES_DIR exists but is not a git repo, removing..."
  rm -rf "$DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  echo "Cloning to $DOTFILES_DIR..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi
echo ""

# --- Phase 4: Configure chezmoi ---
echo "--- Phase 4: Configure chezmoi ---"
CHEZMOI_CONFIG_DIR="${HOME}/.config/chezmoi"
mkdir -p "$CHEZMOI_CONFIG_DIR"

# Check if chezmoi config already exists (yaml or toml)
EXISTING_CONFIG=""
for ext in toml yaml yml; do
  if [ -f "$CHEZMOI_CONFIG_DIR/chezmoi.$ext" ]; then
    EXISTING_CONFIG="$CHEZMOI_CONFIG_DIR/chezmoi.$ext"
    break
  fi
done

if [ -n "$EXISTING_CONFIG" ]; then
  echo "chezmoi config already exists: $EXISTING_CONFIG (skipping)"
else
  # Ask for git info
  GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

  if [ -z "$GIT_NAME" ]; then
    read -rp "Git user.name: " GIT_NAME < /dev/tty
  fi
  if [ -z "$GIT_EMAIL" ]; then
    read -rp "Git user.email: " GIT_EMAIL < /dev/tty
  fi

  cat > "$CHEZMOI_CONFIG_DIR/chezmoi.toml" << EOF
sourceDir = "${DOTFILES_DIR}/home"
workingTree = "${DOTFILES_DIR}"

[data.git]
name = "${GIT_NAME}"
email = "${GIT_EMAIL}"
EOF
  echo "chezmoi config written to $CHEZMOI_CONFIG_DIR/chezmoi.toml"
fi
echo ""

# --- Phase 5: Deploy Dotfiles ---
echo "--- Phase 5: Deploy Dotfiles ---"
chezmoi apply --force || true
echo ""

# --- Phase 6: Nix home-manager ---
echo "--- Phase 6: Nix home-manager ---"
if command -v nix &>/dev/null; then
  # Enable flakes
  mkdir -p "$HOME/.config/nix"
  if ! grep -q "flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
  fi

  echo "Running home-manager switch for viryoke@${HOSTNAME}..."
  cd "$DOTFILES_DIR"
  nix run home-manager -- switch --flake ".#viryoke@${HOSTNAME}" --impure || {
    echo "WARNING: home-manager switch failed. Run manually:"
    echo "  cd ~/dotfiles && nix run home-manager -- switch --flake \".#viryoke@${HOSTNAME}\" --impure"
  }
fi
echo ""

# --- Phase 7: Set Default Shell ---
echo "--- Phase 7: Default Shell ---"
if command -v zsh &>/dev/null; then
  ZSH_PATH="$(which zsh)"

  if [ "$OS" = "linux" ]; then
    if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
  fi

  if [ "$OS" = "linux" ]; then
    CURRENT_SHELL=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
  else
    CURRENT_SHELL=$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')
  fi
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH" || echo "Set zsh manually: sudo chsh -s $ZSH_PATH $USER"
  else
    echo "zsh is already the default shell."
  fi
fi
echo ""

# --- Phase 8: Verification ---
echo "--- Phase 8: Verification ---"
bash "$DOTFILES_DIR/scripts/doctor.sh" || true

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Bootstrap Complete!                  ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Next steps:                             ║"
echo "║  1. Import age identity key              ║"
echo "║  2. Restart terminal                     ║"
echo "║  3. cd ~/dotfiles && git push (first time║"
echo "╚══════════════════════════════════════════╝"

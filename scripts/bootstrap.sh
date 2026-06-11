#!/bin/bash
set -euo pipefail

DOTFILES_REPO="https://github.com/viryoke/dotfiles.git"
DOTFILES_REPO_MIRROR="https://gitcode.com/viryoke/dotfiles.git"
DOTFILES_DIR="${HOME}/dotfiles"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       dotfiles Bootstrap                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- Phase 0: Environment Detection ---
echo "--- Phase 0: Environment Detection ---"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
RAW_HOSTNAME="$(hostname)"
echo "OS: $OS | Arch: $ARCH | System Hostname: $RAW_HOSTNAME"

if [ "$OS" = "linux" ] && [ -f /etc/os-release ]; then
  DISTRO=$(. /etc/os-release && echo "$ID")
  echo "Distro: $DISTRO"
fi
echo ""

# --- Phase 1: Collect User Info ---
echo "--- Phase 1: User Configuration ---"

# Check if chezmoi config already exists
CHEZMOI_CONFIG_DIR="${HOME}/.config/chezmoi"
EXISTING_CONFIG=""
for ext in toml yaml yml; do
  if [ -f "$CHEZMOI_CONFIG_DIR/chezmoi.$ext" ]; then
    EXISTING_CONFIG="$CHEZMOI_CONFIG_DIR/chezmoi.$ext"
    break
  fi
done

if [ -n "$EXISTING_CONFIG" ]; then
  echo "chezmoi config already exists: $EXISTING_CONFIG"
  echo "Skipping user configuration (delete the file to reconfigure)"
  echo ""
else
  echo "--- Auto-detecting configuration ---"

  # Username: auto-detect from $USER
  USERNAME="$USER"
  echo "  Username:  $USERNAME (auto-detected)"

  # Git name: try git config, prompt if missing
  GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
  if [ -z "$GIT_NAME" ]; then
    read -rp "Git user.name: " GIT_NAME < /dev/tty
  else
    echo "  Git name:  $GIT_NAME (from git config)"
  fi

  # Git email: try git config, prompt if missing
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
  if [ -z "$GIT_EMAIL" ]; then
    read -rp "Git user.email: " GIT_EMAIL < /dev/tty
  else
    echo "  Git email: $GIT_EMAIL (from git config)"
  fi

  # Hostname: show detected value and available configs, let user confirm
  echo ""
  echo "Hostname is used to select the Nix home-manager configuration."
  echo "Detected system hostname: $RAW_HOSTNAME"
  echo "Available configurations in flake.nix:"
  echo "  - cachyos-desktop (CachyOS Linux, x86_64)"
  echo "  - arch-arm (Arch Linux ARM, aarch64)"
  echo "  - macbook (macOS, aarch64)"
  echo ""
  
  # Smart default based on detected OS and architecture
  DEFAULT_HOST="$RAW_HOSTNAME"
  if [ "$OS" = "linux" ] && [ "$ARCH" = "aarch64" ]; then
    DEFAULT_HOST="arch-arm"
  elif [ "$OS" = "linux" ] && [ "$ARCH" = "x86_64" ]; then
    DEFAULT_HOST="cachyos-desktop"
  elif [ "$OS" = "darwin" ]; then
    DEFAULT_HOST="macbook"
  fi
  
  read -rp "Which configuration to use? [cachyos-desktop/arch-arm/macbook] (default: $DEFAULT_HOST): " HOSTNAME < /dev/tty
  HOSTNAME="${HOSTNAME:-$DEFAULT_HOST}"

  echo ""
  echo "Configuration summary:"
  echo "  Username:  $USERNAME"
  echo "  Git name:  $GIT_NAME"
  echo "  Git email: $GIT_EMAIL"
  echo "  Hostname:  $HOSTNAME"
  echo ""

  mkdir -p "$CHEZMOI_CONFIG_DIR"
  cat > "$CHEZMOI_CONFIG_DIR/chezmoi.toml" << EOF
sourceDir = "${DOTFILES_DIR}/home"
workingTree = "${DOTFILES_DIR}"

[data]
username = "${USERNAME}"
hostname = "${HOSTNAME}"

[data.git]
name = "${GIT_NAME}"
email = "${GIT_EMAIL}"
EOF
  echo "chezmoi config written to $CHEZMOI_CONFIG_DIR/chezmoi.toml"
  echo ""
fi

# --- Phase 2: Install Dependencies ---
echo "--- Phase 2: Installing Dependencies ---"
if [ "$OS" = "linux" ]; then
  if command -v pacman &>/dev/null; then
    # Configure Arch Linux ARM mirrors for China (aarch64 only)
    if [ "$ARCH" = "aarch64" ] && [ -f /etc/pacman.d/mirrorlist ]; then
      if ! grep -q "tuna.tsinghua.edu.cn" /etc/pacman.d/mirrorlist 2>/dev/null; then
        echo "Configuring Arch Linux ARM mirrors (TUNA)..."
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
        sudo sed -i '1iServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$os/$arch' /etc/pacman.d/mirrorlist
        sudo sed -i '2iServer = https://mirrors.ustc.edu.cn/archlinuxarm/$os/$arch' /etc/pacman.d/mirrorlist
        echo "✓ Arch Linux ARM mirrors configured"
      fi
    fi
    sudo pacman -S --needed --noconfirm git chezmoi age
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
  brew install git chezmoi age
fi
echo ""

# --- Phase 3: Install Nix (single-user) ---
echo "--- Phase 3: Nix Package Manager ---"
if ! command -v nix &>/dev/null; then
  echo "Installing Nix (single-user mode)..."
  # Use TUNA mirror for Nix binary download (China network optimization)
  export NIX_BINARY_CACHE="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi
# Load Nix into current shell
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
if command -v nix &>/dev/null; then
  echo "Nix $(nix --version)"
fi

# Single-user Nix requires /nix to be owned by the current user.
# If /nix exists but is owned by root (leftover from multi-user install),
# fix ownership so nix build/home-manager can write to the store.
if [ -d /nix ] && [ "$(stat -c '%u' /nix 2>/dev/null || stat -f '%u' /nix 2>/dev/null)" != "$(id -u)" ]; then
  echo "/nix is owned by root — fixing ownership for single-user mode..."
  sudo chown -R "$(whoami)" /nix
fi
echo ""
echo "--- Phase 4: Clone Repository ---"
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Repository already exists at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only || { git -C "$DOTFILES_DIR" fetch origin && git -C "$DOTFILES_DIR" reset --hard origin/main; }
elif [ -d "$DOTFILES_DIR" ]; then
  echo "$DOTFILES_DIR exists but is not a git repo, removing..."
  rm -rf "$DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || git clone "$DOTFILES_REPO_MIRROR" "$DOTFILES_DIR"
else
  echo "Cloning to $DOTFILES_DIR..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || git clone "$DOTFILES_REPO_MIRROR" "$DOTFILES_DIR"
fi

# Configure dual push (GitHub + GitCode)
git -C "$DOTFILES_DIR" remote set-url --add --push origin "$DOTFILES_REPO"
git -C "$DOTFILES_DIR" remote set-url --add --push origin "$DOTFILES_REPO_MIRROR"

# Configure Nix mirrors (shared script, now available after clone)
bash "$DOTFILES_DIR/scripts/configure-nix-mirrors.sh"
echo ""

# --- Phase 5: Deploy Dotfiles ---
echo "--- Phase 5: Deploy Dotfiles ---"
chezmoi apply --force || true
echo ""

# --- Phase 6: Nix home-manager (fallback) ---
# The orchest script (Phase 2) already runs home-manager switch during
# chezmoi apply. This is a safety net in case the orchest script was skipped.
echo "--- Phase 6: Nix home-manager (fallback) ---"
if command -v nix &>/dev/null; then
  # Ensure nix.conf has flakes enabled (orchest script normally handles this)
  mkdir -p "$HOME/.config/nix"
  if ! grep -q "flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
  fi

  # Inject GitHub token to avoid API rate limits
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
    echo "[nix-hm] ✓ GitHub token from \$GITHUB_TOKEN"
  fi

  echo "Running home-manager switch..."
  cd "$DOTFILES_DIR"
  chezmoi execute-template '{{ .username }}@{{ .hostname }}' | xargs -I{} \
    nix run --accept-flake-config home-manager -- switch --flake ".#{}" --impure || {
    echo "WARNING: home-manager switch failed. Run manually:"
    echo "  GITHUB_TOKEN=your_token cd ~/dotfiles && nix run --accept-flake-config home-manager -- switch --flake \".#\$(chezmoi execute-template '{{ .username }}@{{ .hostname }}')\" --impure"
  }
  unset NIX_CONFIG
fi
echo ""

# --- Phase 7: Verification ---
# Default shell (fish) is set by orchest script Phase 4
echo "--- Phase 7: Verification ---"
bash "$DOTFILES_DIR/scripts/doctor.sh" || true

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Bootstrap Complete!                  ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Restart terminal to apply changes.      ║"
echo "╚══════════════════════════════════════════╝"

#!/bin/bash
set -euo pipefail

DOTFILES_REPO="https://github.com/viryoke/dotfiles.git"
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
  echo "  - cachyos-desktop (CachyOS Linux)"
  echo "  - macbook (macOS)"
  echo ""
  read -rp "Which configuration to use? [cachyos-desktop/macbook]: " HOSTNAME < /dev/tty
  HOSTNAME="${HOSTNAME:-$RAW_HOSTNAME}"

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

# --- Phase 3: Install Nix (single-user) ---
echo "--- Phase 3: Nix Package Manager ---"
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

# Single-user Nix requires /nix to be owned by the current user.
# If /nix exists but is owned by root (leftover from multi-user install),
# fix ownership so nix build/home-manager can write to the store.
if [ -d /nix ] && [ "$(stat -c '%u' /nix 2>/dev/null || stat -f '%u' /nix 2>/dev/null)" != "$(id -u)" ]; then
  echo "/nix is owned by root — fixing ownership for single-user mode..."
  sudo chown -R "$(whoami)" /nix
fi

# Configure system-level /etc/nix/nix.conf (daemon level — always respected)
# Uses sed to replace existing lines (not grep+append) so wrong values get corrected.
NIX_SUBSTITUTERS="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org"
NIX_TRUSTED_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

if [ ! -f /etc/nix/nix.conf ]; then
  sudo mkdir -p /etc/nix
  sudo tee /etc/nix/nix.conf > /dev/null 2>&1 << SYSCONF
trusted-users = root $USER
substituters = ${NIX_SUBSTITUTERS}
trusted-public-keys = ${NIX_TRUSTED_KEYS}
SYSCONF
  echo "Created /etc/nix/nix.conf (trusted-users + substituters + keys)"
else
  # Determine sed in-place flag (macOS: -i '', Linux: -i)
  if [ "$OS" = "darwin" ]; then SED_INPLACE=(sed -i ''); else SED_INPLACE=(sed -i); fi

  # trusted-users: append user if not already present
  if ! grep -q "trusted-users.*$USER" /etc/nix/nix.conf 2>/dev/null; then
    if grep -q "^trusted-users" /etc/nix/nix.conf 2>/dev/null; then
      sudo "${SED_INPLACE[@]}" "s/^trusted-users.*/& $USER/" /etc/nix/nix.conf 2>/dev/null && \
        echo "Updated trusted-users (added $USER)"
    else
      echo "trusted-users = root $USER" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1 && \
        echo "Added trusted-users = root $USER"
    fi
  fi
  # substituters: replace existing line or append
  if grep -q "^substituters" /etc/nix/nix.conf 2>/dev/null; then
    sudo "${SED_INPLACE[@]}" "s|^substituters.*|substituters = ${NIX_SUBSTITUTERS}|" /etc/nix/nix.conf 2>/dev/null && \
      echo "Updated substituters"
  else
    echo "substituters = ${NIX_SUBSTITUTERS}" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1 && \
      echo "Added substituters"
  fi
  # trusted-public-keys: replace existing line or append
  if grep -q "^trusted-public-keys" /etc/nix/nix.conf 2>/dev/null; then
    sudo "${SED_INPLACE[@]}" "s|^trusted-public-keys.*|trusted-public-keys = ${NIX_TRUSTED_KEYS}|" /etc/nix/nix.conf 2>/dev/null && \
      echo "Updated trusted-public-keys"
  else
    echo "trusted-public-keys = ${NIX_TRUSTED_KEYS}" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1 && \
      echo "Added trusted-public-keys"
  fi
fi

# Restart Nix daemon to pick up /etc/nix/nix.conf changes (if daemon exists)
if [ "$OS" = "darwin" ]; then
  if launchctl print system/org.nixos.nix-daemon &>/dev/null; then
    sudo launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null && echo "Nix daemon restarted"
  else
    echo "No Nix daemon (single-user mode) — config applied immediately"
  fi
else
  if systemctl is-enabled nix-daemon.service &>/dev/null || systemctl is-enabled nix-daemon.socket &>/dev/null; then
    sudo systemctl restart nix-daemon.service 2>/dev/null && echo "Nix daemon restarted" \
      || sudo systemctl restart nix-daemon.socket 2>/dev/null && echo "Nix daemon socket restarted" \
      || echo "⚠ daemon restart failed"
  else
    # Single-user mode: no daemon. Remove stale socket if present
    # (leftover from previous multi-user install causes "Connection refused")
    if [ -S /nix/var/nix/daemon-socket/socket ] 2>/dev/null; then
      echo "Removing stale Nix daemon socket..."
      sudo rm -f /nix/var/nix/daemon-socket/socket 2>/dev/null && echo "✓ Stale socket removed" \
        || echo "⚠ Run manually: sudo rm -f /nix/var/nix/daemon-socket/socket"
    fi
    echo "No Nix daemon (single-user mode) — config applied immediately"
  fi
fi
echo ""
echo "--- Phase 4: Clone Repository ---"
if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Repository already exists at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only || { git -C "$DOTFILES_DIR" fetch origin && git -C "$DOTFILES_DIR" reset --hard origin/main; }
elif [ -d "$DOTFILES_DIR" ]; then
  echo "$DOTFILES_DIR exists but is not a git repo, removing..."
  rm -rf "$DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  echo "Cloning to $DOTFILES_DIR..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi
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

  echo "Running home-manager switch..."
  cd "$DOTFILES_DIR"
  chezmoi execute-template '{{ .username }}@{{ .hostname }}' | xargs -I{} \
    nix run --accept-flake-config home-manager -- switch --flake ".#{}" --impure || {
    echo "WARNING: home-manager switch failed. Run manually:"
    echo "  cd ~/dotfiles && nix run --accept-flake-config home-manager -- switch --flake \".#\$(chezmoi execute-template '{{ .username }}@{{ .hostname }}')\" --impure"
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
echo "║  Restart terminal to apply changes.      ║"
echo "╚══════════════════════════════════════════╝"

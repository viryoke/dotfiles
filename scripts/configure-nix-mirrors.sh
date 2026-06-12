#!/bin/bash
set -uo pipefail

# Configure Nix binary cache mirrors (TUNA + SJTU) for China network.
# Writes both user-level and system-level nix.conf, then restarts nix-daemon.
# Usage: source this script or call it directly.

NIX_SUBSTITUTERS="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org"
NIX_TRUSTED_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

# --- User-level ~/.config/nix/nix.conf ---
mkdir -p "$HOME/.config/nix"
cat > "$HOME/.config/nix/nix.conf" << 'NIXCONF'
experimental-features = nix-command flakes
substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
NIXCONF

# --- System-level /etc/nix/nix.conf ---
NIX_CONF_CHANGED=false
SED_INPLACE=()
if [ "$OS" = "darwin" ]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

if [ ! -f /etc/nix/nix.conf ]; then
  sudo mkdir -p /etc/nix
  sudo tee /etc/nix/nix.conf > /dev/null 2>&1 << SYSCONF
trusted-users = root $(whoami)
substituters = ${NIX_SUBSTITUTERS}
trusted-public-keys = ${NIX_TRUSTED_KEYS}
SYSCONF
  echo "[nix] ✓ /etc/nix/nix.conf created"
  NIX_CONF_CHANGED=true
else
  # trusted-users
  if ! grep -q "trusted-users.*$(whoami)" /etc/nix/nix.conf 2>/dev/null; then
    if grep -q "^trusted-users" /etc/nix/nix.conf 2>/dev/null; then
      sudo sed "${SED_INPLACE[@]}" "s/^trusted-users.*/& $(whoami)/" /etc/nix/nix.conf 2>/dev/null
    else
      echo "trusted-users = root $(whoami)" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1
    fi
    echo "[nix] ✓ trusted-users updated"
    NIX_CONF_CHANGED=true
  fi
  # substituters
  if grep -q "^substituters" /etc/nix/nix.conf 2>/dev/null; then
    sudo sed "${SED_INPLACE[@]}" "s|^substituters.*|substituters = ${NIX_SUBSTITUTERS}|" /etc/nix/nix.conf 2>/dev/null
    echo "[nix] ✓ substituters updated"
    NIX_CONF_CHANGED=true
  else
    echo "substituters = ${NIX_SUBSTITUTERS}" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1
    echo "[nix] ✓ substituters added"
    NIX_CONF_CHANGED=true
  fi
  # trusted-public-keys
  if grep -q "^trusted-public-keys" /etc/nix/nix.conf 2>/dev/null; then
    sudo sed "${SED_INPLACE[@]}" "s|^trusted-public-keys.*|trusted-public-keys = ${NIX_TRUSTED_KEYS}|" /etc/nix/nix.conf 2>/dev/null
    echo "[nix] ✓ trusted-public-keys updated"
    NIX_CONF_CHANGED=true
  else
    echo "trusted-public-keys = ${NIX_TRUSTED_KEYS}" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1
    echo "[nix] ✓ trusted-public-keys added"
    NIX_CONF_CHANGED=true
  fi
fi

# --- Restart nix-daemon if config changed ---
if [ "$NIX_CONF_CHANGED" = true ]; then
  if [ "$OS" = "darwin" ]; then
    sudo launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null && echo "[nix] ✓ daemon restarted" \
      || { sudo pkill -HUP nix-daemon 2>/dev/null && echo "[nix] ✓ daemon reloaded (SIGHUP)" \
        || echo "[nix] ⚠ daemon restart failed — run: sudo launchctl kickstart -k system/org.nixos.nix-daemon"; }
  else
    if systemctl list-unit-files nix-daemon.service 2>/dev/null | grep -q nix-daemon; then
      sudo systemctl restart nix-daemon.service 2>/dev/null && echo "[nix] ✓ daemon restarted" \
        || echo "[nix] ⚠ daemon restart failed — run: sudo systemctl restart nix-daemon"
    else
      echo "[nix] ✓ single-user mode, no daemon restart needed"
    fi
  fi
  sleep 2
fi

echo "[nix] ✓ mirrors: TUNA + SJTU"

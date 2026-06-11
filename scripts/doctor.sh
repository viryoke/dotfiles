#!/bin/bash
set -uo pipefail

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo "  [OK] $name"
    ((PASS++))
  else
    echo "  [FAIL] $name"
    ((FAIL++))
  fi
}

warn() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo "  [OK] $name"
    ((PASS++))
  else
    echo "  [WARN] $name"
    ((WARN++))
  fi
}

echo "=== Environment Health Check ==="
echo ""

echo "--- Core Tools ---"
check "chezmoi" "command -v chezmoi"
check "nix" "command -v nix"
check "git" "command -v git"

echo ""
echo "--- Shell ---"
check "fish" "command -v fish"
check "starship" "command -v starship"
check "zellij" "command -v zellij"

echo ""
echo "--- Editor ---"
check "neovim" "command -v nvim"
check "lazygit" "command -v lazygit"

echo ""
echo "--- Dev Tools ---"
check "go" "command -v go"
check "python3" "command -v python3"
check "uv" "command -v uv"
check "pixi" "command -v pixi"
check "rustc" "command -v rustc"
check "cargo" "command -v cargo"
check "java" "command -v java"
check "bun" "command -v bun"
check "node" "command -v node"
check "lua" "command -v lua"

echo ""
echo "--- CLI Utilities ---"
check "ripgrep" "command -v rg"
check "fd" "command -v fd"
check "fzf" "command -v fzf"
check "eza" "command -v eza"
check "zoxide" "command -v zoxide"
check "bat" "command -v bat"
check "yazi" "command -v yazi"
check "jq" "command -v jq"

echo ""
echo "--- Git Configuration ---"
check "git user.name" "git config user.name"
check "git user.email" "git config user.email"
warn "SSH key exists" "test -f ~/.ssh/id_ed25519"

OS="$(uname -s)"

echo ""
if [ "$OS" = "Linux" ]; then
  echo "--- Wayland Utilities (Linux) ---"
  warn "rofi-wayland" "command -v rofi"
  warn "cliphist" "command -v cliphist"
  warn "grim" "command -v grim"
  warn "slurp" "command -v slurp"
  warn "mako" "command -v mako"
  warn "wlogout" "command -v wlogout"
  warn "swww" "command -v swww"
  warn "fcitx5" "command -v fcitx5"
elif [ "$OS" = "Darwin" ]; then
  echo "--- macOS Utilities ---"
  warn "homebrew" "command -v brew"
  warn "xcode cli tools" "xcode-select -p"
fi

echo ""
echo "--- chezmoi Status ---"
check "chezmoi source dir" "test -d ~/dotfiles/home"
if command -v chezmoi &>/dev/null; then
  DIFF_COUNT=$(chezmoi diff 2>/dev/null | grep -c '^diff' || true)
  if [ "$DIFF_COUNT" -eq 0 ]; then
    echo "  [OK] No pending changes"
    ((PASS++))
  else
    echo "  [WARN] $DIFF_COUNT files differ from source"
    ((WARN++))
  fi
fi

echo ""
echo "--- Secrets ---"
SECRETS_DIR="$HOME/dotfiles/secrets"
if [ -d "$SECRETS_DIR" ]; then
  for age_file in "$SECRETS_DIR"/*.age; do
    if [ -f "$age_file" ]; then
      filename=$(basename "$age_file")
      # Get file modification time in seconds since epoch (GNU stat vs BSD stat)
      file_mtime=$(stat -c %Y "$age_file" 2>/dev/null || stat -f %m "$age_file" 2>/dev/null)
      if [ -n "$file_mtime" ]; then
        now=$(date +%s)
        age_days=$(( (now - file_mtime) / 86400 ))
        if [ "$age_days" -gt 90 ]; then
          echo "  [WARN] $filename is $age_days days old (consider rotating)"
          ((WARN++))
        else
          echo "  [OK] $filename ($age_days days old)"
          ((PASS++))
        fi
      else
        echo "  [WARN] $filename (could not determine age)"
        ((WARN++))
      fi
    fi
  done
else
  echo "  [WARN] secrets directory not found"
  ((WARN++))
fi

echo ""
echo "==============================="
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "==============================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

#!/bin/bash
set -euo pipefail

# Rime build script — managed by chezmoi
# Symlinks rime-ice data files and runs rime_deployer

RIME_DIR="$HOME/.local/share/fcitx5/rime"
RIME_ICE_DIR="$HOME/.local/share/fcitx5/rime-ice"
BUILD_DIR="$RIME_DIR/build"

if ! command -v rime_deployer &>/dev/null; then
    echo "rime_deployer not found — install fcitx5-rime first"
    exit 1
fi

if [ ! -d "$RIME_ICE_DIR" ]; then
    echo "rime-ice data not found at $RIME_ICE_DIR"
    echo "Run 'chezmoi apply' to fetch externals first"
    exit 1
fi

echo "Building Rime schemas..."

# Ensure rime user directory exists
mkdir -p "$RIME_DIR" "$BUILD_DIR"

# Symlink rime-ice data files (schemas, dicts, Lua, opencc, etc.)
# Skip: .git, README, LICENSE, build/, and our custom default.yaml
for f in "$RIME_ICE_DIR"/*; do
    base=$(basename "$f")
    # Skip git metadata and build artifacts
    case "$base" in
        .git|build|README*|LICENSE*) continue ;;
    esac
    # Don't overwrite chezmoi-managed files
    if [ ! -e "$RIME_DIR/$base" ] && [ ! -L "$RIME_DIR/$base" ]; then
        ln -sf "$f" "$RIME_DIR/$base"
    fi
done

# Symlink system rime-data as fallback (for base schemas)
SYS_DATA_DIR="/usr/share/rime-data"
if [ -d "$SYS_DATA_DIR" ]; then
    for f in "$SYS_DATA_DIR"/*.yaml "$SYS_DATA_DIR"/*.txt; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        if [ ! -e "$RIME_DIR/$base" ] && [ ! -L "$RIME_DIR/$base" ]; then
            ln -sf "$f" "$RIME_DIR/$base"
        fi
    done
fi

# Run rime_deployer to compile schemas
rime_deployer --build "$RIME_DIR" "$BUILD_DIR" 2>/dev/null
echo "Rime build complete"

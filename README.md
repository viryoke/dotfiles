<div align="center">

# ~/dotfiles

**Cross-platform development environment — declarative, reproducible, opinionated.**

*One repo to rule two machines, eight languages, and every config in between.*

[![Nix Flakes](https://img.shields.io/badge/Nix-Flakes-blue?logo=nixos&logoColor=white)](https://nixos.org)
[![home-manager](https://img.shields.io/badge/home--manager-enabled-blue?logo=nixos&logoColor=white)](https://github.com/nix-community/home-manager)
[![chezmoi](https://img.shields.io/badge/chezmoi-managed-orange?logo=git&logoColor=white)](https://www.chezmoi.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-CachyOS%20%7C%20macOS-lightgrey)]()

</div>

---

## Design Philosophy

This dotfiles repo treats the development environment as a **declarative system** with clear separation of concerns:

- **Nix home-manager** owns *what is installed* — language runtimes, CLI tools, dev dependencies — with atomic upgrades and rollback.
- **chezmoi** owns *how it's configured* — templated dotfiles with cross-platform conditionals and data-driven customization.
- **agenix** owns *what's secret* — age-encrypted tokens decrypted only at activation time, safe to commit alongside plaintext configs.

No `curl | sh` spaghetti. No `if [[ "$(uname)" == ...` scattered across files. One flake, one chezmoi source tree, one activation pipeline.

## Targets

| Machine | OS | Architecture | Hardware | Hostname |
|---------|-----|-------------|----------|----------|
| Desktop | CachyOS (Arch-based) | x86_64 | i9-14900KF · 64 GB | `cachyos-desktop` |
| Laptop | macOS Sequoia | aarch64 | Apple Silicon | `macbook` |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Activation Pipeline                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  bootstrap.sh ──► chezmoi apply ──► run_onchange_orchest.sh         │
│       │                │                     │                      │
│       │          Deploy dotfiles      ┌──────┴──────┐               │
│       │          to ~ via             │             │               │
│       │          templates       Phase 1-2      Phase 3-4           │
│       │                          (serial)       (parallel)          │
│       │                                                             │
│  ┌────┴─────┐  Mirrors ──► Nix HM ──► Packages ──► Post-config     │
│  │ Detect   │  Nix/npm      switch     pacman/      rime-build      │
│  │ OS/Arch  │  TUNA/SJTU    + agenix   brew/flat    claude-code     │
│  │ Collect  │  npmmirror    secrets    AUR/casks    zsh default     │
│  │ user info│               + clash    parallel     shell           │
│  └──────────┘               verge                                   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   Nix Flake (flake.nix)                      │    │
│  ├─────────────┬───────────────────┬────────────────────────────┤    │
│  │  overlays/  │  hosts/           │  modules/                  │    │
│  │  custom     │  cachyos-desktop/ │  shared/  linux/  darwin/  │    │
│  │  pkgs       │  macbook/         │  dev-*    secrets  brew    │    │
│  └─────────────┴───────────────────┴────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                 chezmoi Source (home/)                       │    │
│  │  dot_zshrc.tmpl · dot_gitconfig.tmpl · dot_config/          │    │
│  │  ghostty · nvim · zellij · starship · yazi · fcitx5         │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Responsibility Layers

| Layer | Tool | Responsibility | Scope |
|-------|------|----------------|-------|
| **L0** System | `pacman` / `brew` | Kernel, drivers, Wayland compositor, platform packages | OS-native |
| **L1** User | Nix `home-manager` | CLI tools, dev toolchains, language runtimes, fonts | `~/` |
| **L2** GUI | `flatpak` / `brew --cask` | Sandboxed GUI apps (browsers, messaging, media) | System |
| **L3** Config | `chezmoi` | All dotfiles with templating + cross-platform conditionals | `~/.config/` `~/.*` |
| **Secrets** | `agenix` | Age-encrypted secrets decrypted at activation time | `$XDG_RUNTIME_DIR/agenix/` |

## Quick Start

One command — works on both CachyOS and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/viryoke/dotfiles/main/scripts/bootstrap.sh | bash
```

The script will:

1. **Detect** OS, architecture, and existing configuration
2. **Collect** username, Git identity, and target hostname (auto-detect where possible)
3. **Install** `git`, `chezmoi`, and Nix (single-user mode)
4. **Clone** this repo to `~/dotfiles`
5. **Deploy** dotfiles via `chezmoi apply`
6. **Activate** home-manager + orchestrate packages (4-phase pipeline)
7. **Verify** environment health via `doctor.sh`

<details>
<summary>Manual installation</summary>

### CachyOS Linux

```bash
git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

# Install Nix (single-user)
sh <(curl -L https://nixos.org/nix/install) --no-daemon
source ~/.nix-profile/etc/profile.d/nix.sh

# Install chezmoi
sudo pacman -S --needed chezmoi

# Configure chezmoi
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
sourceDir = "~/dotfiles/home"
workingTree = "~/dotfiles"

[data]
username = "<your-username>"
hostname = "<your-hostname>"

[data.git]
name = "<your-name>"
email = "<your-email>"
EOF

# Deploy
chezmoi apply

# Optional: interactive package install
~/dotfiles/scripts/install-packages.sh
```

### macOS

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git chezmoi

git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

sh <(curl -L https://nixos.org/nix/install) --no-daemon
source ~/.nix-profile/etc/profile.d/nix.sh

mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
sourceDir = "~/dotfiles/home"
workingTree = "~/dotfiles"

[data]
username = "<your-username>"
hostname = "<your-hostname>"

[data.git]
name = "<your-name>"
email = "<your-email>"
EOF

chezmoi apply
```

</details>

## Repository Layout

```
~/dotfiles/
├── flake.nix                           Nix flake entry point (home-manager)
├── flake.lock                          Pinned dependency versions
│
├── hosts/                              Per-host home-manager configurations
│   ├── cachyos-desktop/
│   │   ├── default.nix                   Module imports + home config
│   │   └── hardware.nix                  Hardware-specific settings
│   └── macbook/
│       └── default.nix                   Module imports + home config
│
├── modules/                            Reusable Nix modules
│   ├── shared/                         Cross-platform modules
│   │   ├── shell.nix                     zsh plugins, starship, CLI tools
│   │   ├── editors.nix                   neovim, tree-sitter, ripgrep
│   │   ├── theme.nix                     JetBrains Mono + Noto CJK fonts
│   │   ├── packages.nix                  Core CLI utilities
│   │   ├── dev-rust.nix                  rustc, cargo, rust-analyzer
│   │   ├── dev-python.nix               uv, pixi, ruff
│   │   ├── dev-go.nix                    go, gopls, golangci-lint, delve
│   │   ├── dev-java.nix                  JDK 21, maven, gradle
│   │   ├── dev-js.nix                    bun, node, typescript
│   │   ├── dev-cc.nix                    gcc, clang, cmake
│   │   ├── dev-lua.nix                   lua, lua-language-server, stylua
│   │   ├── ai-ml.nix                     jupyter, ollama (Linux)
│   │   ├── ai-learning.nix               PyPI mirror config (pixi)
│   │   ├── exam-prep.nix                 pandoc, texlive
│   │   └── hermes-agent.nix              (placeholder — aliases in .zshrc)
│   ├── linux/
│   │   ├── packages.nix                  yazi, zellij, cliphist
│   │   ├── clash-verge.nix               Proxy client
│   │   └── secrets.nix                   agenix secret declarations
│   └── darwin/
│       └── packages.nix                  yazi, zellij
│
├── home/                               chezmoi source state → ~/
│   ├── dot_config/                     → ~/.config/
│   │   ├── ghostty/config.tmpl           Terminal (Gruvbox, platform keys)
│   │   ├── nvim/                         Neovim (LazyVim distro)
│   │   │   ├── init.lua                    Plugin spec + lazy.nvim bootstrap
│   │   │   └── lua/plugins/gruvbox.lua     Gruvbox Material theme
│   │   ├── zellij/                       Terminal multiplexer
│   │   │   ├── config.kdl                  Theme + behavior
│   │   │   ├── keybindings.kdl             Vim-style bindings
│   │   │   └── layouts/                    default.kdl, dev.kdl
│   │   ├── starship.toml                 Prompt (Gruvbox powerline)
│   │   ├── yazi/theme.toml               File manager theme
│   │   └── fcitx5/                       Input method (Linux only)
│   ├── dot_zshrc.tmpl                  → ~/.zshrc (templated)
│   ├── dot_zshenv.tmpl                 → ~/.zshenv (XDG, locale, PATH)
│   ├── dot_gitconfig.tmpl              → ~/.gitconfig (delta, gh auth)
│   ├── dot_bashrc.tmpl                 → ~/.bashrc (fallback)
│   ├── dot_local/                      → ~/.local/
│   │   ├── bin/                            User scripts (rime-build.sh)
│   │   └── share/fcitx5/rime/              Rime input method config
│   ├── .chezmoiscripts/                Lifecycle hooks
│   │   ├── run_once_before_...sh.tmpl     Phase 0: prereqs + Nix install
│   │   └── run_onchange_orchest.sh.tmpl   Phase 1–4: full orchestration
│   ├── .chezmoiignore                  Platform-conditional ignores
│   ├── .chezmoiexternal.yaml.tmpl      External deps (rime-ice)
│   └── .chezmoidata/packages.yaml      Package manifest (pacman/flatpak/brew)
│
├── overlays/                           Custom Nix overlays
│   └── default.nix
├── secrets/                            agenix-encrypted secrets (.age)
│   ├── secrets.nix                       Public key → secret mapping
│   ├── github_token.age                  GitHub CLI auth
│   └── clash_subscription.age            Proxy subscription URL
└── scripts/
    ├── bootstrap.sh                    One-command setup
    ├── doctor.sh                       Environment health check
    └── install-packages.sh             Interactive package installer (Linux)
```

## Managed Software

### Shell & Terminal

| Component | Description | Platform |
|-----------|-------------|----------|
| **zsh** | Primary shell with fzf, zoxide, starship, autosuggestions, syntax-highlighting | Cross |
| **starship** | Cross-shell prompt — Gruvbox Material Dark powerline style | Cross |
| **ghostty** | GPU-accelerated terminal emulator (platform-specific keybinds) | Cross |
| **zellij** | Terminal multiplexer with Vim-style keybinds + `default`/`dev` layouts | Cross |

### Editor & CLI Tools

| Component | Description | Platform |
|-----------|-------------|----------|
| **neovim** | Primary editor — LazyVim distro with multi-language LSP | Cross |
| **yazi** | Terminal file manager | Cross |
| **lazygit** | Git TUI | Cross |
| **git** | Configured with delta pager, gh credential helper, rebase defaults | Cross |
| **ripgrep / fd / fzf / eza / bat / zoxide** | Modern CLI replacements | Cross |

### Development Languages

Managed via Nix home-manager modules — each language is an independent, composable module:

| Module | Stack | Key Packages |
|--------|-------|-------------|
| `dev-rust` | Rust | rustc, cargo, rust-analyzer, clippy, rustfmt |
| `dev-python` | Python | uv, pixi, ruff |
| `dev-go` | Go | go, gopls, golangci-lint, delve |
| `dev-java` | Java | JDK 21, maven, gradle |
| `dev-js` | JS/TS | bun, node, typescript, typescript-language-server |
| `dev-lua` | Lua | lua, lua-language-server, stylua |
| `dev-cc` | C/C++ | gcc, clang-tools, cmake, gnumake, pkg-config |
| `ai-ml` | AI/ML | jupyter, ollama (Linux only) |
| `exam-prep` | Writing | pandoc, texlive (scheme-small) |

### Neovim Configuration

Based on [LazyVim](https://www.lazyvim.org/) with the following language extras enabled:

Python · Go · Rust · Java · TypeScript · JSON · YAML · Markdown · Docker · Terraform

Plus: `mini-files`, `outline`, `dap.core`, `test.core`. Theme: **gruvbox-material** (medium background, italic enabled).

### Wayland (Linux Only)

| Component | Description |
|-----------|-------------|
| **fcitx5 + rime** | Input method framework + Rime Pinyin (rime-ice schema, auto-refreshed) |
| **clash-verge-rev** | Proxy client with TUN mode, agenix-injected subscription, autostart |
| **cliphist** | Clipboard history manager |
| **grim + slurp** | Screenshot tools |
| **swww** | Wallpaper daemon |
| **wlogout** | Logout/lock/reboot menu |
| **mako** | Notification daemon (Gruvbox theme) |
| **rofi-wayland** | App launcher + menu scripts |

#### Rofi Menu Shortcuts

| Alias | Function |
|-------|----------|
| `launcher` | App launcher (drun) |
| `clipboard` | Clipboard history browser |
| `screenshot` | Screenshot menu (full/region/window/delay) |
| `emoji` | Emoji picker |
| `powermenu` | Power menu (wlogout) |
| `wallpaper` | Wallpaper selector (swww) |

### GUI Applications

**Linux (Flatpak):** Firefox · Telegram · Spotify · Discord · Anki · Obsidian

**Linux (AUR):** Baidu Netdisk

**macOS (Homebrew Cask):** Chrome · Ghostty · Telegram · Clash Verge Rev · Baidu Netdisk · Obsidian · Raycast · Stats

## Orchestration Pipeline

When `chezmoi apply` runs, the `run_onchange_orchest.sh` hook executes a 4-phase pipeline:

```
Phase 1  Mirrors          Configure Nix binary cache (TUNA/SJTU), npm registry (npmmirror)
   │                      Runs first — subsequent downloads use domestic CDN
   ▼
Phase 2  Nix + Secrets    home-manager switch (serial) → agenix decrypts secrets
   │     + Proxy          → gh auth from token → clash-verge autostart with TUN
   │                      → proxy readiness check before bulk downloads
   ▼
Phase 3  Packages         pacman + AUR + flatpak (Linux)  ─┐
   │     (parallel)       brew formulae + casks  (macOS)   ─┘─ all run concurrently
   ▼
Phase 4  Post-install     rime-build (Linux) + claude-code (npm) + zsh default shell
         (parallel)       All run concurrently
```

## Secrets

Encrypted with [agenix](https://github.com/ryantm/agenix) (age encryption). Decrypted to `$XDG_RUNTIME_DIR/agenix/` at `home-manager` activation time. `.age` files are safe to commit — only the holder of the corresponding SSH private key can decrypt them.

| Secret | Purpose | Decrypted Path |
|--------|---------|----------------|
| `github_token.age` | GitHub CLI authentication | `$XDG_RUNTIME_DIR/agenix/github_token` |
| `clash_subscription.age` | Proxy subscription URL | `$XDG_RUNTIME_DIR/agenix/clash_subscription` |

Both secrets are accessible from either machine (desktop + laptop SSH keys).

### Managing Secrets

```bash
# Edit a secret (requires age identity)
cd ~/dotfiles/secrets
agenix -e github_token.age

# Add a new secret
# 1. Create plaintext file, encrypt it:
echo "secret-value" | agenix -e new_secret.age
# 2. Add to secrets/secrets.nix
# 3. Reference in a module via age.secrets.new_secret.file
# 4. Delete the plaintext file
```

## China Network Optimization

This environment is configured for optimal network access from mainland China:

| Component | Mirror | Configured In |
|-----------|--------|---------------|
| Nix binary cache | TUNA + SJTU | `run_onchange_orchest.sh` |
| npm registry | npmmirror | `run_onchange_orchest.sh` |
| PyPI (pixi) | TUNA | `ai-learning.nix` |
| Claude Code | npm (via npmmirror) | `run_onchange_orchest.sh` |

## Scripts

| Script | Description |
|--------|-------------|
| `bootstrap.sh` | One-command setup: detect OS → collect identity → install deps → clone → deploy → verify |
| `doctor.sh` | Health check: core tools, shell, editor, dev tools, CLI utilities, git, Wayland, chezmoi status |
| `install-packages.sh` | Interactive package installer with GPU driver conflict handling (Linux only) |

## Daily Workflow

```bash
# Edit a config file
chezmoi edit ~/.config/ghostty/config

# Preview what would change
chezmoi diff

# Apply changes locally
chezmoi apply

# Commit & sync
cd ~/dotfiles && git add -A && git commit -m "update: ..." && git push

# On the other machine: pull & apply
cd ~/dotfiles && git pull && chezmoi apply
```

### Useful Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ll` | `eza -la --icons --git` | Detailed file listing with git status |
| `la` | `eza -a --icons` | All files listing |
| `lt` | `eza --tree --icons --level=2` | Tree view (2 levels) |
| `lg` | `lazygit` | Git TUI |
| `v` / `vi` | `nvim` | Editor |
| `z` | `zellij attach -c main` | Attach to main zellij session |

## Theme

**Gruvbox Material Dark** — applied consistently across every visual component:

```
Terminal (Ghostty) · Editor (Neovim) · Shell prompt (Starship)
Multiplexer (Zellij) · File manager (Yazi) · Launcher (Rofi)
Notifications (Mako) · Input method (fcitx5)
```

Font: **JetBrains Mono Nerd Font** (14pt, thickened) + **Noto Sans CJK** for Chinese/Japanese/Korean coverage.

## License

[MIT](LICENSE) — Copyright (c) 2026 Zhou Mingjun (viryoke)

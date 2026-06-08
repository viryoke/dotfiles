# dotfiles

Cross-platform personal environment configuration using chezmoi + Nix home-manager + Flatpak + pacman.

## Targets

| Machine | OS | Architecture |
|---------|-----|-------------|
| cachyos-desktop | CachyOS (Arch-based) | amd64 (14900KF + 64GB) |
| macbook | macOS | arm64 (Apple Silicon) |

## Quick Start

### CachyOS Linux

```bash
# 1. 克隆仓库到统一目录
git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

# 2. 配置 chezmoi 指向本地仓库
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.yaml << 'EOF'
sourceDir: ~/dotfiles/home
workingTree: ~/dotfiles
data:
  git:
    name: <your-name>
    email: <your-email>
EOF

# 3. 安装 chezmoi 并部署
sudo pacman -S --needed chezmoi
chezmoi apply
```

### macOS

```bash
# 1. 安装 Xcode CLI tools（如未安装）
xcode-select --install

# 2. 安装 Homebrew + git + chezmoi
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git chezmoi

# 3. 克隆仓库到统一目录
git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

# 4. 配置 chezmoi 指向本地仓库
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.yaml << 'EOF'
sourceDir: ~/dotfiles/home
workingTree: ~/dotfiles
data:
  git:
    name: <your-name>
    email: <your-email>
EOF

# 5. 部署 dotfiles
chezmoi apply
```

> **说明**：`chezmoi.yaml` 中的 `sourceDir` 指向仓库的 `home/` 目录（chezmoi 模板所在位置），`workingTree` 指向仓库根目录（`flake.nix` 所在位置）。`data.git` 需要替换为你的 Git 用户名和邮箱。

## Architecture

```
~/dotfiles/              ← Git 仓库
├── flake.nix                      ← Nix flake 入口 (home-manager + nix-darwin)
├── hosts/                         ← 各主机 home-manager 配置
│   ├── cachyos-desktop/
│   └── macbook/
├── modules/                       ← 可复用 Nix 模块
│   ├── shared/                    ← 跨平台 (shell, editors, dev-*, theme)
│   ├── linux/
│   └── darwin/
├── home/                          ← chezmoi source state (模板 + 脚本)
│   ├── dot_config/                → ~/.config/
│   ├── dot_zshrc.tmpl             → ~/.zshrc
│   ├── .chezmoiscripts/           → 生命周期脚本
│   ├── .chezmoiignore             → 平台条件忽略
│   └── .chezmoidata/packages.yaml → 包清单 (pacman/flatpak/brew)
├── secrets/                       ← agenix 加密密钥
└── scripts/                       ← 辅助脚本 (bootstrap, doctor)
```

**四层包管理：**

| 层 | 工具 | 职责 |
|---|------|------|
| L0 系统内核 | pacman | 内核、驱动、Wayland 合成器、CachyOS 优化包 |
| L1 用户环境 | Nix home-manager | CLI 工具、开发工具链、语言运行时 |
| L2 GUI 应用 | Flatpak / brew cask | 浏览器、通讯、媒体等沙箱化应用 |
| L3 配置文件 | chezmoi | 所有 dotfiles，支持模板化 + 平台检测 |

## Daily Workflow

```bash
# 编辑配置文件
chezmoi edit ~/.config/ghostty/config

# 查看变更
chezmoi diff

# 部署变更
chezmoi apply

# 提交
cd ~/dotfiles && git add -A && git commit -m "update: ..."
```

## Theme

Gruvbox Material Dark across all components.

## License

MIT

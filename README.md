# dotfiles

Cross-platform personal environment configuration using chezmoi + Nix home-manager + Flatpak + pacman.

## Targets

| Machine | OS | Architecture |
|---------|-----|-------------|
| cachyos-desktop | CachyOS (Arch-based) | amd64 (14900KF + 64GB) |
| macbook | macOS | arm64 (Apple Silicon) |

## Quick Start

**一键安装（CachyOS 和 macOS 通用）：**

```bash
curl -fsSL https://raw.githubusercontent.com/viryoke/dotfiles/main/scripts/bootstrap.sh | bash
```

脚本会自动：
1. 交互式配置：用户名、Git 信息、主机名（用于选择 Nix 配置）
2. 安装 git、chezmoi、Nix（单用户模式，不创建 build users）
3. 克隆仓库到 `~/dotfiles`
4. 部署 dotfiles 并运行 home-manager
5. 设置 zsh 为默认 shell 并运行健康检查

> **手动安装**：如需逐步控制，参见下方分步指南。

### 手动安装（可选）

#### CachyOS Linux

```bash
# 1. 克隆仓库
git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

# 2. 安装 Nix（单用户模式）
sh <(curl -L https://nixos.org/nix/install) --no-daemon
source ~/.nix-profile/etc/profile.d/nix.sh

# 3. 安装 chezmoi
sudo pacman -S --needed chezmoi

# 4. 配置 chezmoi（如果还没有 ~/.config/chezmoi/ 下的配置文件）
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

# 5. 部署
chezmoi apply

# 6. 安装系统包（可选，支持交互式冲突解决）
~/dotfiles/scripts/install-packages.sh
```

#### macOS

```bash
# 1. 安装 Xcode CLI tools（如未安装）
xcode-select --install

# 2. 安装 Homebrew + git + chezmoi
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git chezmoi

# 3. 克隆仓库
git clone https://github.com/viryoke/dotfiles.git ~/dotfiles

# 4. 安装 Nix（单用户模式）
sh <(curl -L https://nixos.org/nix/install) --no-daemon
source ~/.nix-profile/etc/profile.d/nix.sh

# 5. 配置 chezmoi（如果还没有 ~/.config/chezmoi/ 下的配置文件）
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

# 6. 部署
chezmoi apply
```

## Architecture

```
~/dotfiles/                          ← Git 仓库
├── flake.nix                        ← Nix flake 入口 (home-manager)
├── hosts/                           ← 各主机 home-manager 配置
│   ├── cachyos-desktop/
│   └── macbook/
├── modules/                         ← 可复用 Nix 模块
│   ├── shared/                      ← 跨平台 (shell, editors, dev-*, theme)
│   ├── linux/                       ← Linux 专属包
│   └── darwin/                      ← macOS 专属包
├── home/                            ← chezmoi source state
│   ├── dot_config/                  → ~/.config/
│   │   ├── ghostty/                 → 终端模拟器配置
│   │   ├── nvim/                    → Neovim 编辑器
│   │   ├── yazi/                    → 文件管理器
│   │   ├── zellij/                  → 终端复用器布局
│   │   ├── clash-verge-rev/         → 代理客户端
│   │   ├── rofi-wayland/            → 应用启动器 + 菜单 (Linux only)
│   │   ├── mako/                    → 通知守护进程 (Linux only)
│   │   └── fcitx5/                  → 输入法框架 (Linux only)
│   ├── dot_zshrc.tmpl               → ~/.zshrc (模板化)
│   ├── dot_gitconfig.tmpl           → ~/.gitconfig (模板化)
│   ├── .chezmoiscripts/             → 生命周期脚本
│   ├── .chezmoiignore               → 平台条件忽略
│   ├── .chezmoiexternal.yaml        → 外部依赖 (rime-ice)
│   └── .chezmoidata/packages.yaml   → 包清单 (pacman/flatpak/brew)
├── secrets/                         ← agenix 加密密钥
├── scripts/                         ← 辅助脚本
│   ├── bootstrap.sh                 → 一键安装
│   ├── doctor.sh                    → 环境健康检查
│   └── install-packages.sh          → 交互式包安装 (Linux)
└── docs/                            ← 设计文档与规范
```

**四层包管理：**

| 层 | 工具 | 职责 |
|---|------|------|
| L0 系统内核 | pacman | 内核、驱动、Wayland 合成器、CachyOS 优化包 |
| L1 用户环境 | Nix home-manager | CLI 工具、开发工具链、语言运行时 |
| L2 GUI 应用 | Flatpak / brew cask | 浏览器、通讯、媒体等沙箱化应用 |
| L3 配置文件 | chezmoi | 所有 dotfiles，支持模板化 + 平台检测 |

## Managed Configs

### Shell & Terminal

| 组件 | 说明 | 平台 |
|------|------|------|
| **zsh** | 主 shell，含 fzf/zoxide/starship 集成 | 跨平台 |
| **starship** | 跨 shell 提示符（Gruvbox 主题） | 跨平台 |
| **ghostty** | GPU 加速终端模拟器 | 跨平台 |
| **zellij** | 终端复用器（default + dev 布局） | 跨平台 |

### Editor & Tools

| 组件 | 说明 | 平台 |
|------|------|------|
| **neovim** | 主编辑器 | 跨平台 |
| **yazi** | 终端文件管理器 | 跨平台 |
| **lazygit** | Git TUI | 跨平台 |

### Wayland (Linux Only)

| 组件 | 说明 |
|------|------|
| **rofi-wayland** | 应用启动器 + 5 个菜单脚本 |
| **mako** | 通知守护进程（Gruvbox 主题） |
| **fcitx5 + rime** | 输入法框架 + 雾凇拼音方案 |
| **cliphist** | Wayland 剪贴板历史 |
| **grim + slurp** | Wayland 截图工具 |
| **swww** | Wayland 壁纸守护进程 |
| **wlogout** | 登出/锁屏/重启菜单 |

### Rofi 菜单快捷键

| 别名 | 功能 |
|------|------|
| `launcher` | 应用启动器 (drun) |
| `clipboard` | 剪贴板历史浏览器 |
| `screenshot` | 截图菜单（全屏/区域/窗口/延时） |
| `emoji` | 表情符号选择器 |
| `powermenu` | 电源菜单 (wlogout) |
| `wallpaper` | 壁纸选择器 (swww) |

### 输入法

- **Fcitx5** 作为输入法框架
- **Rime (雾凇拼音)** 通过 chezmoi external 自动克隆 `rime-ice`
- 支持全拼 + 小鹤双拼，`rime-build.sh` 自动编译方案
- 环境变量 (`GTK_IM_MODULE`, `QT_IM_MODULE` 等) 已配置

## Scripts

| 脚本 | 说明 |
|------|------|
| `bootstrap.sh` | 一键安装：交互式配置 → 安装依赖 → 部署 |
| `doctor.sh` | 环境健康检查：核心工具、开发环境、Wayland 工具 |
| `install-packages.sh` | Linux 交互式包安装（支持 GPU 驱动冲突解决） |

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
git push
```

## Theme

Gruvbox Material Dark across all components: terminal, editor, launcher, notifications, shell prompt.

## License

MIT

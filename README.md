# dotfiles

Cross-platform personal environment configuration using chezmoi + Nix home-manager + Flatpak + pacman.

## Targets

| Machine | OS | Architecture |
|---------|-----|-------------|
| cachyos-desktop | CachyOS (Arch-based) | amd64 (14900KF + 64GB) |
| macbook | macOS | arm64 (Apple Silicon) |

## Quick Start

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply viryoke/dotfiles
```

## Architecture

- **chezmoi**: Top-level orchestrator, dotfile templating, platform detection
- **Nix home-manager**: Declarative CLI tools, dev toolchains, language runtimes
- **Flatpak**: Sandboxed GUI applications (Linux)
- **pacman**: System-level CachyOS packages

## Theme

Gruvbox Material Dark across all components.

## License

MIT

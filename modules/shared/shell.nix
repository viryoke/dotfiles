{ pkgs, lib, isLinux, isDarwin, ... }: {
  # NOTE: zsh, starship, zoxide, fzf, eza, bat are configured entirely via chezmoi
  # (home/dot_zshrc.tmpl). We only install packages here — no programs.*.enable
  # to avoid home-manager generating a conflicting ~/.zshrc.

  home.packages = with pkgs; [
    # Zsh plugins (sourced manually in .zshrc)
    zsh-autosuggestions
    zsh-syntax-highlighting

    # CLI tools managed by chezmoi .zshrc
    starship
    zoxide
    fzf
    eza
    bat

    # Other packages
    lazygit
    htop
    btop
    tree
    jq
    curl
    wget
    unzip
    delta
    bc
    opencode
  ];
}

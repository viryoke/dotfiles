{ pkgs, lib, isLinux, isDarwin, ... }: {
  home.packages = with pkgs; [
    # Search & navigation
    ripgrep
    fd
    fzf
    zoxide

    # File & text viewing
    eza
    bat
    tree
    jq

    # Network
    curl
    wget

    # System & process
    htop
    btop
    unzip

    # Git
    lazygit
    gh
    delta

    # Shell (configured via chezmoi, only packages installed here)
    fish
    starship

    # Crypto
    age

    # Misc
    bc
  ] ++ lib.optionals isLinux [
    wl-clipboard
    xdg-utils
  ] ++ lib.optionals isDarwin [
    m-cli
    coreutils
    gnused
  ];
}

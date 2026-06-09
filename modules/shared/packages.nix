{ pkgs, lib, isLinux, isDarwin, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    eza
    zoxide
    bat
    jq
    curl
    wget
    unzip
    tree
    htop
    btop
    lazygit
    gh
    delta
    age
  ] ++ lib.optionals isLinux [
    wl-clipboard
    xdg-utils
  ] ++ lib.optionals isDarwin [
    m-cli
    coreutils
    gnused
  ];
}

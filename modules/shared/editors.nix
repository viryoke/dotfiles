{ pkgs, lib, isLinux, ... }: {
  # NOTE: neovim config is managed entirely by chezmoi (home/dot_config/nvim/).
  # We only install the neovim package here — no programs.neovim.enable
  # to avoid home-manager generating a conflicting ~/.config/nvim/init.lua.

  home.packages = with pkgs; [
    neovim
    gcc
    ripgrep
    fd
    lazygit
    nodejs
    tree-sitter
  ] ++ lib.optionals isLinux [
    wl-clipboard
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}

{ pkgs, lib, isLinux, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
    extraPackages = with pkgs; [
      gcc
      ripgrep
      fd
      lazygit
      nodejs
      python3
      tree-sitter
    ] ++ lib.optionals isLinux [
      wl-clipboard
    ];
  };
}
